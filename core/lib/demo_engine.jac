"""One-click demo (F-28..F-30): the judge story as steps that call the real rules.

The engine keeps its place in a DemoRun node. play makes every status poll advance one step
after STEP_SECONDS; next runs one step now; restart resets the world to the seed.
"""

import time;
import from core.models.nodes { World, Passenger, DemoRun, Booking, ParkingBooking }
import from core.lib.world { must_terminal, must_bus, must_trip, reset_world, get_world }
import from core.lib.parking { recommend, book, park, find_parking }
import from core.lib.journey { book_seat_rule, scan_rule, open_visit, visit_token, spawn_riders, booking_on_trip }
import from core.lib.sim { jump_and_hold, depart_now, replan_all }
import from core.lib.routing { set_road_level, clear_roads }
import from core.seed.seed { load_json }

glob STEP_SECONDS: float = 4.0;
glob DEMO_USER: str = "demo-rider";
glob BUS: str = "MB-101";
glob CAPTIONS: list[str] = [
    "Park & Ride: a car arriving at Makumbura for 2 hours gets a front-line slot and a signed parking QR.",
    "Mark vehicle as parked: the slot turns occupied and the app moves to the bus map.",
    "MB-101 reaches Makumbura; the passenger books a seat Makumbura to Borella. The driver's waiting count goes up.",
    "The passenger scans the Makumbura stop QR: confirmed, on board.",
    "The same scan arrives again: duplicate scan_id, ignored and logged.",
    "Three more riders board for Borella and MB-101 leaves Makumbura.",
    "MB-101 leaves Kottawa: two stops before Borella, the arrival alert fires on the passenger's phone.",
    "Crash near Rajagiriya: Rajagiriya - Battaramulla closes, MB-101 reroutes via Nawala.",
    "MB-101 arrives at Borella: the passenger and two riders scan off; one rider does not.",
    "MB-101 departs Borella: 4 were due off but 3 scanned, so the mismatch alert names the missing rider."
];

def get_run(world: World) -> DemoRun {
    runs = [world -->[?:DemoRun]];
    if runs {
        return runs[0];
    }
    run = DemoRun();
    world ++> run;
    return run;
}

def demo_rider(world: World) -> Passenger {
    found = [world -->[?:Passenger, username == DEMO_USER]];
    if found {
        return found[0];
    }
    p = Passenger(username=DEMO_USER, role="passenger");
    world ++> p;
    return p;
}

def _stop_qr(world: World) -> str {
    bus = must_bus(world, BUS);
    sv = open_visit(must_trip(bus));
    return visit_token(world, sv) if sv else "";
}

"""Run step i of the story. Returns what happened (shown as `last`)."""
def run_step(world: World, i: int) -> dict[str, any] {
    me = demo_rider(world);
    bus = must_bus(world, BUS);
    if i == 0 {
        term = must_terminal(world, "MKB");
        rec = recommend(term, "C", "no", False, 2.0);
        code = rec["options"][0]["slot"]["code"];
        (err, pb) = book(world, me, term, code, "08:00", "10:00");
        return {"zone": rec["zone"], "slot": code, "error": err, "booking": pb.id if pb else ""};
    }
    if i == 1 {
        pbs = [x for x in [world -->[?:ParkingBooking]] if x.username == DEMO_USER];
        if pbs {
            park(world, pbs[-1]);
            return {"booking": pbs[-1].id, "state": pbs[-1].state};
        }
        return {"error": "no parking booking"};
    }
    if i == 2 {
        jump_and_hold(world, bus, "MKB");
        (err, b) = book_seat_rule(world, me, bus, "MKB", "BOR");
        return {"error": err, "booking": b.id if b else ""};
    }
    if i == 3 {
        return {"scan": scan_rule(world, me, "demo-scan-1", _stop_qr(world), "")["result"]};
    }
    if i == 4 {
        return {"scan": scan_rule(world, me, "demo-scan-1", _stop_qr(world), "")["result"]};
    }
    if i == 5 {
        riders = spawn_riders(world, bus, "MKB", "BOR", 3);
        events = depart_now(world, bus);
        return {"riders": riders, "events": events};
    }
    if i == 6 {
        jump_and_hold(world, bus, "KOT");
        events = depart_now(world, bus);
        trip = must_trip(bus);
        b = booking_on_trip(trip, DEMO_USER);
        remaining = trip.stop_codes.index("BOR") - trip.last_departed;
        return {"events": events, "stops_remaining": remaining, "alert": b is not None and b.state == "OnBoard" and remaining <= 2};
    }
    if i == 7 {
        jump_and_hold(world, bus, "BAT");
        clear_roads(world);
        for r in [p for p in load_json("road-network.json")["presets"] if p["id"] == "crash"][0]["roads"] {
            set_road_level(world, r["from"], r["to"], r["level"]);
        }
        events = depart_now(world, bus);
        return {"events": events, "path": bus.path, "rerouted": bus.rerouted, "reason": bus.reroute_reason};
    }
    if i == 8 {
        jump_and_hold(world, bus, "BOR");
        trip = must_trip(bus);
        qr = _stop_qr(world);
        results = [scan_rule(world, me, "demo-scan-2", qr, "")["result"]];
        onboard = [b for b in [trip -->[?:Booking]] if b.username.startswith("rider-") and b.state == "OnBoard"];
        for (k, b) in enumerate(onboard[:2]) {
            results.append(scan_rule(world, Passenger(username=b.username), f"demo-off-{k}", qr, "")["result"]);
        }
        return {"scans": results};
    }
    if i == 9 {
        events = depart_now(world, bus);
        clear_roads(world);
        replan_all(world, []);
        return {"events": events};
    }
    return {};
}

def status(run: DemoRun) -> dict[str, any] {
    total = len(CAPTIONS);
    return {
        "step": run.step,
        "total": total,
        "caption": CAPTIONS[min(run.step, total) - 1] if run.step > 0 else "Press Play to start the judge story.",
        "playing": run.playing,
        "finished": run.step >= total,
        "last": run.last
    };
}

"""Apply a run_demo action and return the status dict."""
def control(action: str) -> dict[str, any] {
    world = get_world();
    run = get_run(world);
    if action == "restart" {
        took = reset_world()["seconds"];
        world = get_world();
        run = get_run(world);
        run.last = {"reset_seconds": took};
        return status(run);
    }
    if action == "pause" {
        run.playing = False;
    } elif action == "play" {
        run.playing = True;
        if run.step >= len(CAPTIONS) {
            run.playing = False;
        }
    }
    due = action == "next" or (action in ["status", "play"] and run.playing and time.time() - run.last_at >= STEP_SECONDS);
    if due and run.step < len(CAPTIONS) {
        run.last = run_step(world, run.step);
        run.step = run.step + 1;
        run.last_at = time.time();
        if run.step >= len(CAPTIONS) {
            run.playing = False;
        }
    }
    return status(run);
}
