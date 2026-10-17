"""Traffic-aware routing (SOW 9.6): Dijkstra on travel minutes.

minutes = km / (class speed x level factor) x 60; A 30, B 22, E 60 km/h; factors 1, 0.55, 0.25;
level 3 (closed) cannot be entered. Planning runs on a plain adjacency dict built from the
Road edges once per call site (Adj: code -> {neighbour code -> [km, cls, level]}).
"""

import heapq;
import from core.models.nodes { World, Bus, Trip, Junction }
import from core.models.edges { Road }
import from core.lib.world { get_junctions, current_trip, junction_names }
import from core.models.nodes { World, Junction }
import from core.models.edges { Road }
import from core.lib.world { get_junctions }
import from core.lib.static { static_roads, road_key }

glob SPEED: dict[str, float] = {"A": 30.0, "B": 22.0, "E": 60.0};
glob FACTOR: list[float] = [1.0, 0.55, 0.25, 0.0];
glob CRAWL_KMH: float = 5.0;
glob INF: float = 1.0e9;

def round2(val: float) -> float {
    return float(round(val * 100.0)) / 100.0;
}

"""Driving speed on a road now (a bus already on a closed road crawls at 5 km/h)."""
def road_kmh(cls: any, level: any) -> float {
    lvl = int(str(level));
    f = FACTOR[lvl] if 0 <= lvl <= 3 else 1.0;
    c = str(cls);
    return SPEED.get(c, 30.0) * f if f > 0.0 else CRAWL_KMH;
}

"""Minutes to drive a whole road at a level, INF if closed."""
def cost_minutes(km: any, cls: any, level: any) -> float {
    lvl = int(str(level));
    if lvl >= 3 {
        return INF;
    }
    k = float(str(km));
    return k / road_kmh(cls, lvl) * 60.0;
}

"""Adjacency of the road graph with current levels."""
def build_adj(world: World) -> any {
    levels = dict(world.road_levels);
    roads: dict = dict(static_roads());
    adj: dict = {};
    for (a, outs) in roads.items() {
        adj[str(a)] = {str(b): [v[0], v[1], levels.get(road_key(str(a), str(b)), 0)] for (b, v) in dict(outs).items()};
"""Driving speed on a road now (a bus already on a closed road crawls at 5 km/h)."""
def road_kmh(cls: str, level: int) -> float {
    f = FACTOR[level] if 0 <= level <= 3 else 1.0;
    return SPEED.get(cls, 30.0) * f if f > 0 else CRAWL_KMH;
}

"""Minutes to drive a whole road at a level, INF if closed."""
def cost_minutes(km: float, cls: str, level: int) -> float {
    if level >= 3 {
        return INF;
    }
    return km / road_kmh(cls, level) * 60.0;
}

"""Adjacency of the road graph with current levels."""
def build_adj(world: World) -> dict[str, dict[str, list[any]]] {
    levels = world.road_levels;
    adj: dict[str, dict[str, list[any]]] = {};
    for (a, outs) in static_roads().items() {
        adj[a] = {b: [v[0], v[1], levels.get(road_key(a, b), 0)] for (b, v) in outs.items()};
    }
    return adj;
}

"""Fastest path from start to goal: (junction codes, minutes); ([], INF) when no open road."""
def plan_dijkstra(adj: any, start: str, goal: str) -> tuple[list[str], float] {
def plan_route(adj: dict[str, dict[str, list[any]]], start: str, goal: str) -> tuple[list[str], float] {
    if start == goal {
        return ([start], 0.0);
    }
    dist: dict[str, float] = {start: 0.0};
    prev: dict[str, str] = {};
    heap: list[tuple[float, str]] = [(0.0, start)];
    adj_dict: dict = dict(adj);
    while heap {
        (d, u) = heapq.heappop(heap);
        if u == goal {
            break;
        }
        if d > dist.get(u, INF) {
            continue;
        }
        neighbors: dict = dict(adj_dict.get(u, {}));
        for (v, info) in neighbors.items() {
        for (v, info) in adj.get(u, {}).items() {
            c = cost_minutes(info[0], info[1], info[2]);
            if c >= INF {
                continue;
            }
            nd = d + c;
            v_str = str(v);
            if nd < dist.get(v_str, INF) {
                dist[v_str] = nd;
                prev[v_str] = u;
                heapq.heappush(heap, (nd, v_str));
            if nd < dist.get(v, INF) {
                dist[v] = nd;
                prev[v] = u;
                heapq.heappush(heap, (nd, v));
            }
        }
    }
    if goal not in dist {
        empty_list: list[str] = [];
        return (empty_list, INF);
    }
    path: list[str] = [goal];
    while path[-1] != start {
        path.append(prev[path[-1]]);
    }
    res_path: list[str] = list(reversed(path));
    res_min: float = round2(dist[goal]);
    return (res_path, res_min);
}

"""Minutes to drive a path at current levels (INF if a road is closed or missing)."""
def path_cost(adj: any, path: list[str]) -> float {
    total = 0.0;
    adj_dict: dict = dict(adj);
    for i in range(len(path) - 1) {
        step_outs: dict = dict(adj_dict.get(path[i], {}));
        info = step_outs.get(path[i + 1]);
        return ([], INF);
    }
    path = [goal];
    while path[-1] != start {
        path.append(prev[path[-1]]);
    }
    return (list(reversed(path)), round(dist[goal], 2));
}

"""Minutes to drive a path at current levels (INF if a road is closed or missing)."""
def path_cost(adj: dict[str, dict[str, list[any]]], path: list[str]) -> float {
    total = 0.0;
    for i in range(len(path) - 1) {
        info = adj.get(path[i], {}).get(path[i + 1]);
        if info is None {
            return INF;
        }
        c = cost_minutes(info[0], info[1], info[2]);
        if c >= INF {
            return INF;
        }
        total += c;
    }
    return round2(total);
    return round(total, 2);
}

"""Set a road's level in both directions. Returns False if there is no such road."""
def set_road_level(world: World, a: str, b: str, level: int) -> bool {
    roads: dict = dict(static_roads());
    outs: dict = dict(roads.get(a, {}));
    if b not in outs {
    if b not in static_roads().get(a, {}) {
        return False;
    }
    levels = dict(world.road_levels);
    if level == 0 {
        levels.pop(road_key(a, b), None);
    } else {
        levels[road_key(a, b)] = level;
    }
    world.road_levels = levels;
    found = False;
    for j in get_junctions(world) {
        if j.code != a and j.code != b {
            continue;
        }
        for e in [edge j ->:Road:->] {
            if (e.a == a and e.b == b) or (e.a == b and e.b == a) {
                e.level = level;
                found = True;
            }
        }
    }
    return found;
}

"""Every road back to level 0 (free)."""
def clear_roads(world: World) {
def clear_roads(world: World) -> None {
    world.road_levels = {};
    for j in get_junctions(world) {
        for e in [edge j ->:Road:->] {
            e.level = 0;
        }
    }
}

"""Plan bus route through remaining stops in order, applying the >= 1 min or >= 10% switch rule."""
def plan_bus_route(world: World, bus: Bus) -> list[str] {
    adj = build_adj(world);
    trip = current_trip(bus);
    if trip is None {
        return list(bus.path);
    }
    start_pt: str = str(bus.road_to) if (bus.state == "moving" and bus.road_to) else str(bus.road_from);
    nxt_stop: str = str(bus.next_stop);
    if not nxt_stop or nxt_stop == "None" {
        return list(bus.path);
    }

    stop_idx = trip.stop_codes.index(nxt_stop) if nxt_stop in trip.stop_codes else 0;
    remaining_stops = trip.stop_codes[stop_idx:];

    full_fresh: list[str] = [];
    curr_pt: str = start_pt;
    for stp in remaining_stops {
        res = plan_dijkstra(adj, curr_pt, str(stp));
        leg: list[str] = res[0];
        if not leg {
            bus.state = "waiting";
            wait_path: list[str] = [start_pt];
            return wait_path;
        }
        if full_fresh and leg {
            full_fresh = full_fresh + leg[1:];
        } else {
            full_fresh = leg;
        }
        curr_pt = str(stp);
    }

    if not full_fresh {
        bus.state = "waiting";
        w_path: list[str] = [start_pt];
        return w_path;
    }

    b_path: list[str] = list(bus.path);
    rest: list[str] = b_path[b_path.index(start_pt):] if start_pt in b_path else [start_pt];
    old_c = path_cost(adj, rest);
    new_c = path_cost(adj, full_fresh);
    saving = old_c - new_c;

    if full_fresh != rest and (old_c >= INF or saving >= 1.0 or (old_c > 0 and saving / old_c >= 0.10)) {
        prefix: list[str] = [str(bus.road_from)] if (bus.state == "moving" and str(bus.road_from) != start_pt) else [];
        bus.path = prefix + full_fresh;
        bus.rerouted = True;
    }
    return list(bus.path);
}

"""Plan route through remaining stops in order."""
def plan_route(world: World, bus: Bus) -> list[str] {
    return plan_bus_route(world, bus);
}
