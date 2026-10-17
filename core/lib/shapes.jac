"""Serializers: graph nodes -> the exact JSON shapes in docs/contracts.md section 2."""

import from core.models.nodes {
    World, Terminal, Slot, ParkingBooking, Junction, Route, Bus, Trip, Booking, Alert, Scan
}
import from core.models.edges { Road }
import from core.lib.geo { haversine_km }
import from core.lib.world { get_junctions, terminal_slots, current_trip, find_route }
import from core.lib.sim { stop_etas }
import from core.lib.routing { build_adj }

glob SPEED_KMH: dict[str, float] = {"A": 30.0, "B": 22.0, "E": 60.0};
glob LEVEL_FACTOR: list[float] = [1.0, 0.55, 0.25, 0.0];

"""Minutes to drive a road at its class speed and traffic level (closed -> crawl 5 km/h)."""
def road_minutes(km: float, cls: str, level: int) -> float {
    f = LEVEL_FACTOR[level] if 0 <= level < len(LEVEL_FACTOR) else 1.0;
    kmh = SPEED_KMH.get(cls, 30.0) * f if f > 0 else 5.0;
    return round(km / kmh * 60.0, 2);
}

"""StopRef: {code, name}."""
def stop_ref(code: str, names: dict[str, str]) -> dict[str, any] {
    return {"code": code, "name": names.get(code, code)};
}

def slot_dict(s: Slot) -> dict[str, any] {
    return {
        "code": s.code,
        "terminal": s.terminal,
        "type": s.kind,
        "zone": s.zone,
        "nn": s.nn,
        "state": s.state,
        "accessible": s.accessible,
        "charger_kw": s.charger_kw,
        "charger_type": s.charger_type
    };
}

"""Per-type counts {B: {total, free, booked, occupied}, ...} for a terminal."""
def slot_counts(term: Terminal) -> dict[str, any] {
    counts: dict[str, any] = {};
    for k in ["B", "M", "C", "E"] {
        counts[k] = {"total": 0, "free": 0, "booked": 0, "occupied": 0};
    }
    for s in terminal_slots(term) {
        c = counts[s.kind];
        c["total"] = c["total"] + 1;
        c[s.state] = c[s.state] + 1;
    }
    return counts;
}

def terminal_dict(t: Terminal) -> dict[str, any] {
    return {
        "code": t.code,
        "name": t.name,
        "junction": t.junction,
        "lat": t.lat,
        "lng": t.lng,
        "full_grid": t.full_grid,
        "chargers": t.chargers,
        "counts": slot_counts(t)
    };
}

def parking_booking_dict(pb: ParkingBooking, slot: Slot | None) -> dict[str, any] {
    return {
        "id": pb.id,
        "terminal": pb.terminal,
        "slot_code": pb.slot_code,
        "type": slot.kind if slot else "",
        "zone": slot.zone if slot else "",
        "arrival": pb.arrival,
        "return_by": pb.return_by,
        "state": pb.state,
        "qr": pb.qr_token
    };
}

def booking_dict(b: Booking, names: dict[str, str]) -> dict[str, any] {
    return {
        "id": b.id,
        "bus_id": b.bus_id,
        "route": b.route,
        "pickup": stop_ref(b.pickup, names),
        "drop": stop_ref(b.drop, names),
        "state": b.state,
        "walk_in": b.walk_in,
        "created_at": b.created_at
    };
}

def alert_dict(a: Alert) -> dict[str, any] {
    return {
        "id": a.id,
        "kind": a.kind,
        "message": a.message,
        "bus_id": a.bus_id,
        "stop_code": a.stop_code,
        "at": a.at,
        "resolved": a.resolved
    };
}

"""Mask a username for the admin scan feed: 'passenger' -> 'pa*****er'."""
def mask_name(name: str) -> str {
    if len(name) <= 4 {
        return name[0] + "***";
    }
    return name[:2] + "*" * (len(name) - 4) + name[-2:];
}

def scan_dict(s: Scan, names: dict[str, str]) -> dict[str, any] {
    return {
        "at": s.at,
        "passenger": mask_name(s.username),
        "scan_id": s.scan_id,
        "type": s.result,
        "stop": stop_ref(s.stop_code, names),
        "bus_id": s.bus_id
    };
}

"""Riders on board and pending bookings of a trip."""
def trip_bookings(trip: Trip) -> list[Booking] {
    return [trip -->[?:Booking]];
}

"""Seats left on each segment s (stop s -> s+1) of a trip, in trip stop order (SOW 9.2)."""
def segment_seats(bus: Bus, trip: Trip) -> list[int] {
    n = len(trip.stop_codes);
    occ = [0] * max(n - 1, 0);
    for b in trip_bookings(trip) {
        if b.state not in ["Pending", "OnBoard"] {
            continue;
        }
        p = trip.stop_codes.index(b.pickup) if b.pickup in trip.stop_codes else 0;
        d = trip.stop_codes.index(b.drop) if b.drop in trip.stop_codes else n - 1;
        for s in range(p, d) {
            if 0 <= s < len(occ) {
                occ[s] = occ[s] + 1;
            }
        }
    }
    return [bus.capacity - o for o in occ];
}

"""Rough ETA in minutes from the bus to a stop along the trip (stub; plan_route in M3)."""
def eta_to(bus: Bus, trip: Trip, code: str, coords: dict[str, list[float]]) -> float {
    if code not in coords or bus.next_stop not in coords {
        return 0.0;
    }
    nxt = coords[bus.next_stop];
    km = haversine_km(bus.lat, bus.lng, nxt[0], nxt[1]) * 1.25;
    if code != bus.next_stop and code in trip.stop_codes and bus.next_stop in trip.stop_codes {
        i = trip.stop_codes.index(bus.next_stop);
        j = trip.stop_codes.index(code);
        for k in range(i, j) {
            a = coords[trip.stop_codes[k]];
            b = coords[trip.stop_codes[k + 1]];
            km += haversine_km(a[0], a[1], b[0], b[1]) * 1.25;
        }
    }
    return round(km / 30.0 * 60.0, 1);
}

"""Junction code -> [lat, lng]."""
def junction_coords(world: World) -> dict[str, list[float]] {
    return {j.code: [j.lat, j.lng] for j in get_junctions(world)};
}

"""BusSummary (contracts.md 2.6)."""
def bus_dict(world: World, bus: Bus, names: dict[str, str], coords: dict[str, list[float]]) -> dict[str, any] {
    trip = current_trip(bus);
    route = find_route(world, bus.route);
    on_board = 0;
    seats: list[int] = [];
    stops: list[dict[str, any]] = [];
    if trip {
        on_board = len([b for b in trip_bookings(trip) if b.state == "OnBoard"]);
        seats = segment_seats(bus, trip);
        etas = stop_etas(world, build_adj(world), bus, trip);
        for (i, code) in enumerate(trip.stop_codes) {
            passed = i <= trip.last_departed;
            stops.append({
                "code": code,
                "name": names.get(code, code),
                "passed": passed,
                "eta_min": None if passed else etas.get(code)
            });
        }
    }
    seg_now = 0;
    if trip and 0 <= trip.last_departed < len(seats) {
        seg_now = trip.last_departed;
    }
    alerts = [a for a in [world -->[?:Alert]] if a.bus_id == bus.id and not a.resolved];
    return {
        "id": bus.id,
        "route": bus.route,
        "route_name": route.name if route else bus.route,
        "color": route.color if route else "",
        "plate": bus.plate,
        "lat": bus.lat,
        "lng": bus.lng,
        "heading": bus.heading,
        "direction": bus.direction,
        "state": bus.state,
        "from_stop": stop_ref(bus.from_stop, names),
        "next_stop": stop_ref(bus.next_stop, names),
        "eta_min": ([s["eta_min"] for s in stops if s["code"] == bus.next_stop and not s["passed"]] + [None])[0],
        "on_board": on_board,
        "capacity": bus.capacity,
        "seats_left": seats[seg_now] if seats else bus.capacity - on_board,
        "segment_seats": seats,
        "stops": stops,
        "rerouted": bus.rerouted,
        "reroute_reason": bus.reroute_reason,
        "alert": len(alerts) > 0
    };
}

"""Undirected roads for the map: one entry per road, the worse of its two directions."""
def map_roads(world: World) -> list[dict[str, any]] {
    seen: dict[str, dict[str, any]] = {};
    for j in get_junctions(world) {
        for e in [edge j ->:Road:->] {
            key = "|".join(sorted([e.a, e.b]));
            if key in seen {
                if e.level > seen[key]["level"] {
                    seen[key]["level"] = e.level;
                    seen[key]["minutes"] = road_minutes(e.km, e.cls, e.level);
                }
            } else {
                seen[key] = {
                    "a": e.a,
                    "b": e.b,
                    "km": e.km,
                    "cls": e.cls,
                    "level": e.level,
                    "minutes": road_minutes(e.km, e.cls, e.level)
                };
            }
        }
    }
    return list(seen.values());
}
