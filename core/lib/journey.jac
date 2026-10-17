"""Bus journey rules: seats per segment (SOW 9.2), bookings (9.3), scans (9.4), alighting check (9.5).

A bus serves its trip's stops in order. arrive_stop opens a StopVisit with a QR valid for that
visit only; depart_stop closes it, auto-cancels pending pickups and raises the mismatch alert.
Every change runs under WORLD_LOCK, so two scans arriving together are processed one by one.
"""

import from core.models.nodes { World, Bus, Trip, StopVisit, Booking, Scan, Alert, Passenger, Junction }
import from core.lib.world { new_id, get_clock, current_trip, junction_names, get_junctions }
import from core.lib.clock { now_hms, sim_seconds }
import from core.lib.qr { sign_token, verify_token }
import from core.lib.locks { WORLD_LOCK }
import from core.lib.geo { bearing }
import from core.lib.rules { STOP_QR_TTL_S }

"""Seats free on each segment s (stop s -> s+1) of the trip."""
def seats_by_segment(bus: Bus, trip: Trip) -> list[int] {
    n = len(trip.stop_codes);
    occ = [0] * max(n - 1, 0);
    for b in [trip -->[?:Booking]] {
        if b.state not in ["Pending", "OnBoard"] {
            continue;
        }
        p = trip.stop_codes.index(b.pickup);
        d = trip.stop_codes.index(b.drop);
        for s in range(p, d) {
            occ[s] = occ[s] + 1;
        }
    }
    return [bus.capacity - o for o in occ];
}

"""Fewest seats free on any segment from stop index p up to (not including) d."""
def seats_between(bus: Bus, trip: Trip, p: int, d: int) -> int {
    seats = seats_by_segment(bus, trip);
    return min(seats[p:d]) if d > p else 0;
}

def open_visit(trip: Trip) -> StopVisit | None {
    found = [trip -->[?:StopVisit, departed_at == ""]];
    return found[0] if found else None;
}

def alert(world: World, kind: str, message: str, bus_id: str, stop_code: str) -> Alert {
    a = Alert(
        id=new_id(world, "AL"), kind=kind, message=message, bus_id=bus_id,
        stop_code=stop_code, at=now_hms(get_clock(world))
    );
    world ++> a;
    return a;
}

"""Book a seat from pickup to drop on the bus's current trip. Returns (error_code, booking)."""
def book_seat_rule(world: World, prof: Passenger, bus: Bus, pickup: str, drop: str) -> tuple[str, any] {
    with WORLD_LOCK {
        trip = current_trip(bus);
        if trip is None or pickup not in trip.stop_codes or drop not in trip.stop_codes {
            return ("INVALID_INPUT", None);
        }
        p = trip.stop_codes.index(pickup);
        d = trip.stop_codes.index(drop);
        if d <= p {
            return ("INVALID_INPUT", None);
        }
        if p <= trip.last_departed {
            return ("PASSED_STOP", None);
        }
        mine = [b for b in [trip -->[?:Booking]] if b.username == prof.username and b.state in ["Pending", "OnBoard"]];
        if mine {
            return ("ALREADY_BOOKED", mine[0]);
        }
        if seats_between(bus, trip, p, d) <= 0 {
            return ("NO_SEAT", None);
        }
        b = Booking(
            id=new_id(world, "BK"), username=prof.username, bus_id=bus.id, trip_id=trip.id,
            route=bus.route, pickup=pickup, drop=drop, state="Pending",
            created_at=now_hms(get_clock(world))
        );
        trip ++> b;
        return ("", b);
    }
}

"""Signed QR for a visit: bus, stop, visit number and expiry in simulated seconds."""
def visit_token(world: World, sv: StopVisit) -> str {
    return sign_token({
        "t": "stop", "bus": sv.bus_id, "stop": sv.stop_code, "visit": sv.visit_no,
        "exp": int(sim_seconds(get_clock(world))) + STOP_QR_TTL_S
    });
}

"""The bus arrives at a stop of its trip: open a StopVisit and put the bus there."""
def arrive_stop(world: World, bus: Bus, trip: Trip, code: str) -> StopVisit {
    earlier = 0;
    for t in [bus -->[?:Trip]] {
        earlier += len([v for v in [t -->[?:StopVisit]] if v.stop_code == code]);
    }
    sv = StopVisit(
        trip_id=trip.id, bus_id=bus.id, stop_code=code, visit_no=earlier + 1,
        arrived_at=now_hms(get_clock(world))
    );
    sv.qr_token = visit_token(world, sv);
    trip ++> sv;
    coords = {j.code: j for j in get_junctions(world)};
    i = trip.stop_codes.index(code);
    here_j = coords[code];
    bus.lat = here_j.lat;
    bus.lng = here_j.lng;
    bus.from_stop = code;
    bus.road_from = code;
    bus.progress = 0.0;
    bus.state = "dwelling";
    if i + 1 < len(trip.stop_codes) {
        nxt = trip.stop_codes[i + 1];
        bus.next_stop = nxt;
        bus.road_to = nxt;
        bus.path = [code, nxt];
        bus.heading = bearing(here_j.lat, here_j.lng, coords[nxt].lat, coords[nxt].lng);
    } else {
        bus.next_stop = code;
        bus.road_to = code;
        bus.path = [code];
    }
    return sv;
}

"""Start the bus's next trip in the opposite direction from the stop it is at."""
def turn_around(world: World, bus: Bus, done: Trip) -> Trip {
    done.status = "done";
    stops = list(reversed(done.stop_codes));
    bus.direction = "reverse" if done.direction == "forward" else "forward";
    n = len([t for t in [bus -->[?:Trip]]]) + 1;
    fresh = Trip(
        id=f"T-{bus.id}-{n}", bus_id=bus.id, route=bus.route, direction=bus.direction,
        stop_codes=stops, last_departed=-1, status="running"
    );
    bus ++> fresh;
    return fresh;
}

"""The bus leaves its current stop: auto-cancel (9.3), alighting check (9.5), maybe turn around.

Returns a short list of what happened, for logs and the demo captions.
"""
def depart_stop(world: World, bus: Bus) -> list[str] {
    events: list[str] = [];
    trip = current_trip(bus);
    if trip is None {
        return events;
    }
    sv = open_visit(trip);
    if sv is None {
        return events;
    }
    code = sv.stop_code;
    names = junction_names(world);
    stop_name = names.get(code, code);
    bookings = [trip -->[?:Booking]];
    for b in bookings {
        if b.state == "Pending" and b.pickup == code {
            b.state = "Cancelled";
            alert(world, "auto_cancel", f"{b.username}'s booking {b.id} cancelled: not scanned at {stop_name}.", bus.id, code);
            events.append(f"auto-cancelled {b.id}");
        }
    }
    missing = [b for b in bookings if b.state == "OnBoard" and b.drop == code];
    extra = [
        b for b in bookings
        if b.state == "Alighted" and b.alight_stop == code and b.alight_visit == sv.visit_no and b.drop != code
    ];
    expected = len(missing) + len([
        b for b in bookings
        if b.state == "Alighted" and b.alight_stop == code and b.alight_visit == sv.visit_no and b.drop == code
    ]);
    if missing or extra {
        parts: list[str] = [];
        if missing {
            parts.append("missing " + ", ".join([b.username for b in missing]));
        }
        if extra {
            parts.append("extra " + ", ".join([b.username for b in extra]));
        }
        actual = expected - len(missing) + len(extra);
        alert(world, "mismatch", f"{stop_name}: {expected} due off, {actual} scanned off - " + "; ".join(parts) + ".", bus.id, code);
        for b in missing {
            b.flagged = True;
        }
        events.append("mismatch alert");
    }
    sv.departed_at = now_hms(get_clock(world));
    i = trip.stop_codes.index(code);
    trip.last_departed = i;
    bus.state = "moving";
    if i == len(trip.stop_codes) - 1 {
        fresh = turn_around(world, bus, trip);
        arrive_stop(world, bus, fresh, fresh.stop_codes[0]);
        events.append(f"turned around at {stop_name}");
    }
    return events;
}

"""Move the bus one stop event forward: depart its open visit, or arrive at the next stop."""
def step_bus(world: World, bus: Bus) -> list[str] {
    trip = current_trip(bus);
    if trip is None {
        return [];
    }
    if open_visit(trip) {
        return depart_stop(world, bus);
    }
    nxt = trip.last_departed + 1;
    if nxt < len(trip.stop_codes) {
        arrive_stop(world, bus, trip, trip.stop_codes[nxt]);
        return [f"arrived {trip.stop_codes[nxt]}"];
    }
    return [];
}

"""Demo console jump: step the bus stop by stop until it is at `code` and can depart from it."""
def jump_to(world: World, bus: Bus, code: str) -> bool {
    with WORLD_LOCK {
        for _ in range(40) {
            trip = current_trip(bus);
            sv = open_visit(trip) if trip else None;
            if sv and trip and sv.stop_code == code and trip.stop_codes.index(code) < len(trip.stop_codes) - 1 {
                return True;
            }
            step_bus(world, bus);
        }
        return False;
    }
}

"""Most relevant booking of a passenger on a trip: OnBoard, then Pending, then Alighted."""
def booking_on_trip(trip: Trip, username: str) -> Booking | None {
    mine = [b for b in [trip -->[?:Booking]] if b.username == username];
    for state in ["OnBoard", "Pending", "Alighted"] {
        hits = [b for b in mine if b.state == state];
        if hits {
            return hits[-1];
        }
    }
    return None;
}

"""Process one stop-QR scan exactly per SOW 9.4. Returns {result, message, booking, stop, bus_id}."""
def scan_rule(world: World, prof: Passenger, scan_id: str, qr: str, drop: str) -> dict[str, any] {
    with WORLD_LOCK {
        out: dict[str, any] = {"result": "", "message": "", "booking": None, "stop": "", "bus_id": ""};
        seen = [s for s in [world -->[?:Scan]] if s.scan_id == scan_id];
        check = verify_token(qr);
        payload = check["payload"];
        out["stop"] = payload.get("stop", "") if check["valid"] else "";
        out["bus_id"] = payload.get("bus", "") if check["valid"] else "";
        if seen {
            out["result"] = "duplicate";
            out["message"] = "Already counted - this scan was processed before.";
            out["booking"] = None;
            _log_scan(world, prof, scan_id, out, 0);
            alert(world, "duplicate_scan", f"Duplicate scan {scan_id} from {prof.username} ignored.", out["bus_id"], out["stop"]);
            return out;
        }
        if not check["valid"] or payload.get("t") != "stop" {
            return _reject(world, prof, scan_id, out, "This is not a valid stop QR.", 0);
        }
        if payload.get("exp", 0) < sim_seconds(get_clock(world)) {
            return _reject(world, prof, scan_id, out, "This stop QR has expired. Scan the one on the screen now.", 0);
        }
        buses = [x for x in [world -->[?:Bus]] if x.id == payload.get("bus")];
        trip = current_trip(buses[0]) if buses else None;
        sv = open_visit(trip) if trip else None;
        visit_no = int(payload.get("visit", 0));
        code = payload.get("stop", "");
        if trip is None or sv is None or sv.stop_code != code or sv.visit_no != visit_no {
            return _reject(world, prof, scan_id, out, "The bus is not at this stop right now.", visit_no);
        }
        bus = buses[0];
        idx = trip.stop_codes.index(code);
        b = booking_on_trip(trip, prof.username);
        if b is None {
            elsewhere = [
                x for x in [world -->[?:Bus]] for t in [x -->[?:Trip]] if t.status == "running"
                for x2 in [t -->[?:Booking]] if x2.username == prof.username and x2.state in ["Pending", "OnBoard"]
            ];
            if elsewhere {
                return _reject(world, prof, scan_id, out, "Your booking is for another bus.", visit_no);
            }
            if not drop {
                out["result"] = "walk_in_needs_drop";
                out["message"] = "No booking found. Choose where you are going, then scan again.";
                _log_scan(world, prof, scan_id, out, visit_no);
                return out;
            }
            if drop not in trip.stop_codes or trip.stop_codes.index(drop) <= idx {
                return _reject(world, prof, scan_id, out, "Choose a stop after this one.", visit_no);
            }
            if seats_between(bus, trip, idx, trip.stop_codes.index(drop)) <= 0 {
                return _reject(world, prof, scan_id, out, "The bus is full on that part of the route.", visit_no);
            }
            b = Booking(
                id=new_id(world, "BK"), username=prof.username, bus_id=bus.id, trip_id=trip.id,
                route=bus.route, pickup=code, drop=drop, state="OnBoard", walk_in=True,
                created_at=now_hms(get_clock(world))
            );
            trip ++> b;
            out["result"] = "boarded";
            out["message"] = "Walk-in confirmed, you are on board.";
        } elif b.state == "Pending" {
            if b.pickup != code {
                return _reject(world, prof, scan_id, out, f"Your booking starts at {b.pickup}, not here.", visit_no);
            }
            b.state = "OnBoard";
            out["result"] = "boarded";
            out["message"] = "Confirmed, you are on board.";
        } elif b.state == "OnBoard" {
            if idx <= trip.stop_codes.index(b.pickup) {
                out["result"] = "already_on_board";
                out["message"] = "Already on board, ignored.";
            } else {
                b.state = "Alighted";
                b.alight_stop = code;
                b.alight_visit = visit_no;
                out["result"] = "alighted";
                out["message"] = "Alighted. Thanks for riding.";
            }
        } else {
            out["result"] = "already_alighted";
            out["message"] = "Already counted - you have alighted.";
        }
        out["booking"] = b;
        _log_scan(world, prof, scan_id, out, visit_no);
        return out;
    }
}

def _reject(world: World, prof: Passenger, scan_id: str, out: dict[str, any], message: str, visit_no: int) -> dict[str, any] {
    out["result"] = "rejected";
    out["message"] = message;
    _log_scan(world, prof, scan_id, out, visit_no);
    return out;
}

def _log_scan(world: World, prof: Passenger, scan_id: str, out: dict[str, any], visit_no: int) -> None {
    world ++> Scan(
        scan_id=scan_id, username=prof.username, bus_id=out["bus_id"], stop_code=out["stop"],
        visit_no=visit_no, result=out["result"], at=now_hms(get_clock(world))
    );
}

"""A passenger's booking with its bus and trip: by id, else the latest Pending/OnBoard one."""
def find_trip_booking(world: World, username: str, booking_id: str) -> tuple[Booking, Bus, Trip] | None {
    best: tuple[Booking, Bus, Trip] | None = None;
    for bus in [world -->[?:Bus]] {
        for trip in [bus -->[?:Trip]] {
            for b in [trip -->[?:Booking]] {
                if b.username != username {
                    continue;
                }
                if booking_id and b.id == booking_id {
                    return (b, bus, trip);
                }
                if not booking_id and b.state in ["Pending", "OnBoard"] {
                    best = (b, bus, trip);
                }
            }
        }
    }
    return best;
}

"""Demo helper: `count` test riders booked on the bus from `pickup` to `drop` (on board if the bus is at pickup)."""
def spawn_riders(world: World, bus: Bus, pickup: str, drop: str, count: int) -> list[str] {
    with WORLD_LOCK {
        trip = current_trip(bus);
        if trip is None or pickup not in trip.stop_codes or drop not in trip.stop_codes {
            return [];
        }
        sv = open_visit(trip);
        here = sv is not None and sv.stop_code == pickup;
        names: list[str] = [];
        for _ in range(count) {
            n = world.next_id;
            world.next_id = n + 1;
            name = f"rider-{n:03d}";
            b = Booking(
                id=f"BK-{n:04d}", username=name, bus_id=bus.id, trip_id=trip.id, route=bus.route,
                pickup=pickup, drop=drop, state="OnBoard" if here else "Pending",
                created_at=now_hms(get_clock(world))
            );
            trip ++> b;
            names.append(name);
        }
        return names;
    }
}
