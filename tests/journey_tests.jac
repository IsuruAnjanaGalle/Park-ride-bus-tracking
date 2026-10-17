"""Bus journey rules: per-segment seats (9.2), passed stops (9.3), scan table (9.4), auto-cancel and mismatch (9.5)."""

import from core.models.nodes { World, Bus, Passenger, Booking, Alert }
import from core.lib.world { reset_world, get_world, must_bus, must_trip }
import from core.lib.journey {
    book_seat_rule, scan_rule, jump_to, depart_stop, open_visit, visit_token, spawn_riders, seats_between
}

def setup -> World {
    reset_world();
    return get_world();
}

def rider(world: World, name: str) -> Passenger {
    p = Passenger(username=name, role="passenger");
    world ++> p;
    return p;
}

"""QR of the bus's current stop visit."""
def stop_qr(world: World, bus: Bus) -> str {
    sv = open_visit(must_trip(bus));
    if sv is None {
        return "";
    }
    return visit_token(world, sv);
}

test "a full segment refuses a booking across it, a later segment still accepts" {
    world = setup();
    bus = must_bus(world, "MB-102");
    bus.capacity = 2;
    spawn_riders(world, bus, "KOT", "BAT", 2);
    (code, _) = book_seat_rule(world, rider(world, "amal"), bus, "KOT", "BOR");
    assert code == "NO_SEAT", code;
    (code2, b2) = book_seat_rule(world, rider(world, "bimal"), bus, "BOR", "TWH");
    assert code2 == "" and b2.state == "Pending", code2;
}

test "a stop the bus has left cannot be the pickup" {
    world = setup();
    bus = must_bus(world, "MB-102");
    (code, _) = book_seat_rule(world, rider(world, "amal"), bus, "MKB", "BOR");
    assert code == "PASSED_STOP", code;
    (code2, _) = book_seat_rule(world, rider(world, "amal"), bus, "BOR", "KOT");
    assert code2 == "INVALID_INPUT", code2;
}

test "board, duplicate scan_id, already on board, alight, already alighted" {
    world = setup();
    bus = must_bus(world, "MB-102");
    amal = rider(world, "amal");
    (code, b) = book_seat_rule(world, amal, bus, "KOT", "BOR");
    assert code == "";
    assert jump_to(world, bus, "KOT");
    qr = stop_qr(world, bus);
    assert scan_rule(world, amal, "s-1", qr, "")["result"] == "boarded";
    assert b.state == "OnBoard";
    assert scan_rule(world, amal, "s-1", qr, "")["result"] == "duplicate";
    assert scan_rule(world, amal, "s-2", qr, "")["result"] == "already_on_board";
    assert jump_to(world, bus, "BOR");
    assert scan_rule(world, amal, "s-3", stop_qr(world, bus), "")["result"] == "alighted";
    assert b.state == "Alighted";
    assert scan_rule(world, amal, "s-4", stop_qr(world, bus), "")["result"] == "already_alighted";
}

test "a walk-in must choose a destination, then boards" {
    world = setup();
    bus = must_bus(world, "MB-102");
    assert jump_to(world, bus, "BAT");
    kumar = rider(world, "kumar");
    qr = stop_qr(world, bus);
    assert scan_rule(world, kumar, "w-1", qr, "")["result"] == "walk_in_needs_drop";
    out = scan_rule(world, kumar, "w-2", qr, "TWH");
    assert out["result"] == "boarded";
    assert out["booking"].walk_in and out["booking"].pickup == "BAT";
}

test "stale, foreign and fake QRs are rejected" {
    world = setup();
    bus = must_bus(world, "MB-102");
    amal = rider(world, "amal");
    book_seat_rule(world, amal, bus, "BOR", "TWH");
    assert jump_to(world, bus, "KOT");
    old_qr = stop_qr(world, bus);
    assert scan_rule(world, amal, "r-1", old_qr, "")["result"] == "rejected";
    assert jump_to(world, bus, "BAT");
    assert scan_rule(world, amal, "r-2", old_qr, "")["result"] == "rejected";
    assert scan_rule(world, amal, "r-3", "not-a-token", "")["result"] == "rejected";
    other = must_bus(world, "MB-103");
    assert jump_to(world, other, "BOR");
    assert scan_rule(world, amal, "r-4", stop_qr(world, other), "")["result"] == "rejected";
}

test "a pending booking not scanned at departure is cancelled and frees the seat" {
    world = setup();
    bus = must_bus(world, "MB-102");
    nimal = rider(world, "nimal");
    (_, b) = book_seat_rule(world, nimal, bus, "KOT", "BOR");
    trip = must_trip(bus);
    before = seats_between(bus, trip, 1, 3);
    assert jump_to(world, bus, "KOT");
    depart_stop(world, bus);
    assert b.state == "Cancelled";
    assert seats_between(bus, trip, 2, 3) == before + 1;
    assert len([a for a in [world -->[?:Alert]] if a.kind == "auto_cancel"]) == 1;
}

test "fewer get-off scans than riders due off raises a mismatch naming the missing rider" {
    world = setup();
    bus = must_bus(world, "MB-102");
    assert jump_to(world, bus, "KOT");
    names = spawn_riders(world, bus, "KOT", "BOR", 3);
    assert len(names) == 3;
    assert jump_to(world, bus, "BOR");
    trip = must_trip(bus);
    riders = [b for b in [trip -->[?:Booking]] if b.username in names];
    qr = stop_qr(world, bus);
    for (i, b) in enumerate(riders[:2]) {
        p = rider(world, b.username);
        assert scan_rule(world, p, f"m-{i}", qr, "")["result"] == "alighted";
    }
    depart_stop(world, bus);
    alerts = [a for a in [world -->[?:Alert]] if a.kind == "mismatch"];
    assert len(alerts) == 1;
    assert riders[2].username in alerts[0].message;
    assert riders[2].state == "OnBoard" and riders[2].flagged;
}
