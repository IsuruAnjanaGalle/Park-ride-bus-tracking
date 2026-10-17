"""Bus simulator on the DemoClock (SOW 9.6, SimulatorFeed).

tick(world) advances every bus by the simulated time since the last tick: buses drive their
planned roads at class speed x traffic factor, dwell 30 s at stops (depart_stop runs the 9.3 and
9.5 rules), finish the road they are on (no U-turns), switch routes only when the new one saves
at least 1 min or 10 %, and wait at a junction when no road is open.
"""

import from core.models.nodes { World, Bus, Trip, Decision, Junction }
import from core.lib.world { get_clock, list_buses, current_trip, get_junctions, junction_names }
import from core.lib.clock { sim_seconds, now_hms }
import from core.lib.locks { WORLD_LOCK }
import from core.lib.geo { bearing, lerp }
import from core.lib.journey { depart_stop, arrive_stop, jump_to }
import from core.lib.routing { build_adj, plan_route, path_cost, road_kmh, INF }

glob DWELL_S: float = 30.0;
glob MAX_TICK_S: float = 180.0;
glob MIN_SAVING_MIN: float = 1.0;
glob MIN_SAVING_RATIO: float = 0.1;

def log_decision(world: World, bus: Bus, decision: str, reason: str) -> dict[str, any] {
    at = now_hms(get_clock(world));
    world ++> Decision(bus_id=bus.id, decision=decision, reason=reason, at=at);
    return {"at": at, "bus_id": bus.id, "decision": decision, "reason": reason};
}

def jmap_of(world: World) -> dict[str, Junction] {
    return {j.code: j for j in get_junctions(world)};
}

"""Place the bus on the map from its current road and progress."""
def place(jmap: dict[str, Junction], bus: Bus) -> None {
    a = jmap.get(bus.road_from);
    b = jmap.get(bus.road_to);
    if a is None {
        return;
    }
    if b is None or b.code == a.code {
        bus.lat = a.lat;
        bus.lng = a.lng;
        return;
    }
    t = max(0.0, min(bus.progress, 1.0));
    bus.lat = round(lerp(a.lat, b.lat, t), 6);
    bus.lng = round(lerp(a.lng, b.lng, t), 6);
    bus.heading = bearing(a.lat, a.lng, b.lat, b.lng);
}

"""Plan the roads from `here` to the trip's next stop and start driving (or wait)."""
def start_leg(world: World, adj: dict[str, dict[str, list[any]]], bus: Bus, trip: Trip, here: str) -> None {
    nxt_i = trip.last_departed + 1;
    if nxt_i >= len(trip.stop_codes) {
        return;
    }
    bus.next_stop = trip.stop_codes[nxt_i];
    (path, _) = plan_route(adj, here, bus.next_stop);
    bus.road_from = here;
    bus.progress = 0.0;
    if len(path) < 2 {
        if bus.state != "waiting" {
            log_decision(world, bus, "Waiting", f"No open road from {junction_names(world).get(here, here)}.");
        }
        bus.state = "waiting";
        bus.road_to = here;
        bus.path = [here];
        return;
    }
    if bus.state == "waiting" {
        log_decision(world, bus, "Moving again", "A road reopened.");
    }
    bus.state = "moving";
    bus.path = path;
    bus.road_to = path[1];
    free: dict[str, dict[str, list[any]]] = {};
    for (a, outs) in adj.items() {
        free[a] = {b: [v[0], v[1], 0] for (b, v) in outs.items()};
    }
    (usual, usual_min) = plan_route(free, here, bus.next_stop);
    if usual and usual != path {
        names = junction_names(world);
        blocked = [f"{usual[i]}|{usual[i + 1]}" for i in range(len(usual) - 1) if adj[usual[i]][usual[i + 1]][2] > 0];
        cause = _road_label(names, blocked[0]) if blocked else "Traffic";
        level = adj[blocked[0].split("|")[0]][blocked[0].split("|")[1]][2] if blocked else 1;
        via = names.get(path[1], path[1]);
        bus.rerouted = True;
        bus.reroute_reason = cause + (" closed" if level >= 3 else " slow") + f" · new route via {via}";
        log_decision(world, bus, "Rerouted", bus.reroute_reason);
    }
}

def _road_label(names: dict[str, str], key: str) -> str {
    parts = key.split("|");
    return names.get(parts[0], parts[0]) + " – " + names.get(parts[1], parts[1]);
}

def _uses(path: list[str], key: str) -> bool {
    parts = key.split("|");
    for i in range(len(path) - 1) {
        if (path[i] == parts[0] and path[i + 1] == parts[1]) or (path[i] == parts[1] and path[i + 1] == parts[0]) {
            return True;
        }
    }
    return False;
}

"""Re-plan from the far end of the current road (no U-turns). Switch only if it saves >= 1 min
or 10 %. `changed` = road keys "A|B" whose level just changed. Returns a decision or None.
"""
def replan(world: World, adj: dict[str, dict[str, list[any]]], bus: Bus, changed: list[str]) -> dict[str, any] | None {
    if bus.state != "moving" {
        return None;
    }
    names = junction_names(world);
    end = bus.road_to;
    rest = bus.path[bus.path.index(end):] if end in bus.path else [end];
    touched = [k for k in changed if _uses(bus.path, k)];
    old = path_cost(adj, rest) if rest[-1] == bus.next_stop else INF;
    (fresh, new) = plan_route(adj, end, bus.next_stop);
    if not fresh {
        return log_decision(world, bus, "Waiting", f"No open road from {names.get(end, end)}; will wait there.") if touched else None;
    }
    saving = old - new;
    if fresh != rest and (old >= INF or saving >= MIN_SAVING_MIN or (old > 0 and saving / old >= MIN_SAVING_RATIO)) {
        bus.path = [bus.road_from] + fresh;
        cause = _road_label(names, touched[0]) if touched else "Traffic";
        bus.rerouted = True;
        bus.reroute_reason = cause + (" closed" if old >= INF else " slow") + (" · only open road" if old >= INF else f" · saves {round(saving)} min");
        return log_decision(world, bus, "Rerouted", bus.reroute_reason);
    }
    if touched {
        return log_decision(world, bus, "Kept route", f"{_road_label(names, touched[0])} slower, no faster road · {round(new, 1)} min to {names.get(bus.next_stop, bus.next_stop)}.");
    }
    return None;
}

"""Advance one bus by dt simulated seconds (now = simulated seconds at the end of the tick)."""
def advance(world: World, adj: dict[str, dict[str, list[any]]], bus: Bus, now: float, dt: float) -> None {
    left = dt;
    for _ in range(60) {
        trip = current_trip(bus);
        if trip is None or left <= 0 {
            return;
        }
        if bus.state == "dwelling" {
            if bus.hold or now < bus.dwell_until {
                return;
            }
            here = bus.from_stop;
            depart_stop(world, bus);
            if bus.state == "dwelling" {
                bus.dwell_until = now + DWELL_S;
                return;
            }
            nxt_trip = current_trip(bus);
            if nxt_trip {
                start_leg(world, adj, bus, nxt_trip, here);
            }
            continue;
        }
        if bus.state == "waiting" {
            start_leg(world, adj, bus, trip, bus.road_from);
            if bus.state == "waiting" {
                return;
            }
            continue;
        }
        info = adj.get(bus.road_from, {}).get(bus.road_to);
        if info is None {
            start_leg(world, adj, bus, trip, bus.road_from);
            if bus.state != "moving" {
                return;
            }
            continue;
        }
        kmh = road_kmh(info[1], info[2]);
        need = info[0] * (1.0 - bus.progress) / kmh * 3600.0;
        if left < need {
            bus.progress = bus.progress + left * kmh / 3600.0 / info[0];
            return;
        }
        left -= need;
        reached = bus.road_to;
        if reached == bus.next_stop {
            arrive_stop(world, bus, trip, reached);
            bus.dwell_until = now + DWELL_S;
            bus.rerouted = False;
            bus.reroute_reason = "";
            return;
        }
        rest = bus.path[bus.path.index(reached):] if reached in bus.path else [reached];
        (fresh, new) = plan_route(adj, reached, bus.next_stop);
        old = path_cost(adj, rest);
        if not fresh {
            bus.road_from = reached;
            bus.road_to = reached;
            bus.progress = 0.0;
            bus.state = "waiting";
            bus.path = [reached];
            log_decision(world, bus, "Waiting", f"No open road from {junction_names(world).get(reached, reached)}.");
            return;
        }
        if old >= INF or (old - new) >= MIN_SAVING_MIN or (old > 0 and (old - new) / old >= MIN_SAVING_RATIO) {
            rest = fresh;
        }
        bus.path = rest;
        bus.road_from = reached;
        bus.road_to = rest[1] if len(rest) > 1 else reached;
        bus.progress = 0.0;
    }
}

"""Advance the whole world to the DemoClock's current time. Safe to call on every read."""
def tick(world: World) -> None {
    with WORLD_LOCK {
        clock = get_clock(world);
        now = sim_seconds(clock);
        dt = min(max(now - clock.last_tick, 0.0), MAX_TICK_S);
        clock.last_tick = now;
        if dt <= 0 {
            return;
        }
        adj = build_adj(world);
        jmap = jmap_of(world);
        for bus in list_buses(world) {
            advance(world, adj, bus, now, dt);
            place(jmap, bus);
        }
    }
}

"""Re-plan every moving bus after a traffic change. Returns the decisions made."""
def replan_all(world: World, changed: list[str]) -> list[dict[str, any]] {
    with WORLD_LOCK {
        adj = build_adj(world);
        out: list[dict[str, any]] = [];
        for bus in list_buses(world) {
            d = replan(world, adj, bus, changed);
            if d {
                out.append(d);
            }
        }
        return out;
    }
}

"""Minutes from the bus to every upcoming stop of its trip (traffic-aware, 30 s dwell per stop)."""
def stop_etas(world: World, adj: dict[str, dict[str, list[any]]], bus: Bus, trip: Trip) -> dict[str, float] {
    etas: dict[str, float] = {};
    t = 0.0;
    at = bus.from_stop;
    if bus.state == "dwelling" {
        t = max(bus.dwell_until - sim_seconds(get_clock(world)), 0.0) / 60.0;
    } elif bus.state == "moving" {
        info = adj.get(bus.road_from, {}).get(bus.road_to);
        if info {
            t = info[0] * (1.0 - bus.progress) / road_kmh(info[1], info[2]) * 60.0;
        }
        at = bus.road_to;
    } else {
        at = bus.road_from;
    }
    for i in range(trip.last_departed + 1, len(trip.stop_codes)) {
        code = trip.stop_codes[i];
        if bus.state == "dwelling" and code == bus.from_stop {
            etas[code] = 0.0;
            continue;
        }
        (_, m) = plan_route(adj, at, code);
        if m >= INF {
            break;
        }
        t += m;
        etas[code] = round(t, 1);
        t += DWELL_S / 60.0;
        at = code;
    }
    return etas;
}

"""Driver turn instruction at the end of the current road."""
def instruction(world: World, bus: Bus) -> dict[str, any] {
    names = junction_names(world);
    jmap = jmap_of(world);
    adj = build_adj(world);
    if bus.state == "dwelling" {
        return {"text": f"At {names.get(bus.from_stop, bus.from_stop)} - board and alight", "turn": "arrive", "toward": names.get(bus.from_stop, ""), "km": 0.0};
    }
    if bus.state == "waiting" {
        return {"text": f"Wait at {names.get(bus.road_from, bus.road_from)} - no open road", "turn": "straight", "toward": names.get(bus.road_from, ""), "km": 0.0};
    }
    info = adj.get(bus.road_from, {}).get(bus.road_to);
    km = round(info[0] * (1.0 - bus.progress), 1) if info else 0.0;
    if bus.road_to == bus.next_stop {
        return {"text": f"Arrive at {names.get(bus.next_stop, bus.next_stop)} · {km} km", "turn": "arrive", "toward": names.get(bus.next_stop, ""), "km": km};
    }
    i = bus.path.index(bus.road_to) if bus.road_to in bus.path else -1;
    nxt = bus.path[i + 1] if 0 <= i < len(bus.path) - 1 else bus.next_stop;
    a = jmap[bus.road_from];
    b = jmap[bus.road_to];
    c = jmap[nxt];
    h1 = bearing(a.lat, a.lng, b.lat, b.lng);
    h2 = bearing(b.lat, b.lng, c.lat, c.lng);
    delta = (h2 - h1 + 540.0) % 360.0 - 180.0;
    turn = "right" if delta > 30 else ("left" if delta < -30 else "straight");
    verb = "Continue" if turn == "straight" else f"Turn {turn}";
    return {"text": f"{verb} toward {names.get(nxt, nxt)} · {km} km", "turn": turn, "toward": names.get(nxt, nxt), "km": km};
}

"""Delay to a stop vs free-flowing roads: {minutes, reason} or None (under 1 min)."""
def delay_to(world: World, bus: Bus, trip: Trip, code: str) -> dict[str, any] | None {
    adj = build_adj(world);
    free: dict[str, dict[str, list[any]]] = {};
    for (a, outs) in adj.items() {
        free[a] = {b: [v[0], v[1], 0] for (b, v) in outs.items()};
    }
    now_eta = stop_etas(world, adj, bus, trip).get(code);
    base = stop_etas(world, free, bus, trip).get(code);
    if now_eta is None or base is None or now_eta - base < 1.0 {
        return None;
    }
    return {"minutes": round(now_eta - base), "reason": bus.reroute_reason or "Traffic on the route"};
}

"""Demo console: hold the bus at `code` (jump) so the stop QR stays valid for scanning."""
def jump_and_hold(world: World, bus: Bus, code: str) -> bool {
    with WORLD_LOCK {
        if not jump_to(world, bus, code) {
            return False;
        }
        bus.hold = True;
        bus.dwell_until = sim_seconds(get_clock(world)) + DWELL_S;
        return True;
    }
}

"""Demo console: release a held bus and leave its stop now (runs auto-cancel and the mismatch check)."""
def depart_now(world: World, bus: Bus) -> list[str] {
    with WORLD_LOCK {
        bus.hold = False;
        here = bus.from_stop;
        events = depart_stop(world, bus);
        now = sim_seconds(get_clock(world));
        if bus.state == "dwelling" {
            bus.dwell_until = now + DWELL_S;
        } else {
            trip = current_trip(bus);
            if trip {
                start_leg(world, build_adj(world), bus, trip, here);
            }
        }
        place(jmap_of(world), bus);
        return events;
    }
}
