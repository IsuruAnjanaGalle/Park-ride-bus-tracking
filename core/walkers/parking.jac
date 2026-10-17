"""Parking walkers (contracts.md 3.1-3.6). Status: real."""

import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, list_terminals, find_terminal, terminal_slots }
import from core.lib.shapes { terminal_dict, slot_dict, parking_booking_dict }
import from core.lib.profiles { caller_profile, profile_error }
import from core.lib.rules { VEHICLES, EV_CHOICES, stay_hours, valid_hhmm }
import from core.lib.parking { recommend, book, park, release, find_parking, slot_by_code, booking_id_from_qr }

walker:pub get_terminals {
    has reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        report ok({"terminals": [terminal_dict(t) for t in list_terminals(world)]});
    }
}

walker:pub get_slots {
    has terminal: str = "MKB",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        term = find_terminal(world, self.terminal);
        if term is None {
            report fail("NOT_FOUND", f"No terminal {self.terminal}.");
            return;
        }
        report ok({"terminal": term.code, "slots": [slot_dict(s) for s in terminal_slots(term)]});
    }
}

walker:pub recommend_slots {
    has terminal: str = "MKB",
        vehicle: str = "C",
        ev: str = "no",
        accessible: bool = False,
        arrival: str = "08:00",
        return_by: str = "10:00",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        term = find_terminal(world, self.terminal);
        if term is None {
            report fail("NOT_FOUND", f"No terminal {self.terminal}.");
            return;
        }
        if self.vehicle not in VEHICLES or self.ev not in EV_CHOICES {
            report fail("INVALID_INPUT", "vehicle must be B, M or C; ev must be no, needs_charging or park_only.");
            return;
        }
        if not valid_hhmm(self.arrival) or not valid_hhmm(self.return_by) {
            report fail("INVALID_INPUT", "arrival and return_by must be HH:MM.");
            return;
        }
        report ok(recommend(term, self.vehicle, self.ev, self.accessible, stay_hours(self.arrival, self.return_by)));
    }
}

walker:protect book_slot {
    has terminal: str,
        slot_code: str,
        arrival: str,
        return_by: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = profile_error(world);
        if err {
            report err;
            return;
        }
        if not valid_hhmm(self.arrival) or not valid_hhmm(self.return_by) {
            report fail("INVALID_INPUT", "arrival and return_by must be HH:MM.");
            return;
        }
        term = find_terminal(world, self.terminal);
        if term is None {
            report fail("NOT_FOUND", f"No terminal {self.terminal}.");
            return;
        }
        (code, pb) = book(world, caller_profile(world), term, self.slot_code, self.arrival, self.return_by);
        if code == "NOT_FOUND" {
            report fail(code, f"No slot {self.slot_code} at {term.code}.");
        } elif code == "CONFLICT" {
            report fail(code, f"Slot {self.slot_code} was just taken. Pick another option.");
        } elif code == "ALREADY_BOOKED" {
            report fail(code, f"You already have parking booking {pb.id} ({pb.slot_code}).");
        } else {
            report ok({"booking": parking_booking_dict(pb, slot_by_code(world, pb.terminal, pb.slot_code))});
        }
    }
}

walker:protect mark_parked {
    has booking_id: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = profile_error(world);
        if err {
            report err;
            return;
        }
        pb = find_parking(world, self.booking_id);
        if pb is None {
            report fail("NOT_FOUND", f"No parking booking {self.booking_id}.");
            return;
        }
        if park(world, pb) {
            report fail("INVALID_INPUT", f"Booking {pb.id} is {pb.state}, not booked.");
            return;
        }
        slot = slot_by_code(world, pb.terminal, pb.slot_code);
        report ok({"booking": parking_booking_dict(pb, slot), "slot": slot_dict(slot) if slot else None});
    }
}

walker:protect release_slot {
    has booking_id: str = "",
        qr: str = "",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = profile_error(world);
        if err {
            report err;
            return;
        }
        bid = self.booking_id or booking_id_from_qr(self.qr);
        if not bid {
            report fail("INVALID_INPUT", "Give booking_id or a valid parking qr.");
            return;
        }
        pb = find_parking(world, bid);
        if pb is None {
            report fail("NOT_FOUND", f"No parking booking {bid}.");
            return;
        }
        if release(world, pb) {
            report fail("INVALID_INPUT", f"Booking {pb.id} is already {pb.state}.");
            return;
        }
        slot = slot_by_code(world, pb.terminal, pb.slot_code);
        report ok({"booking": parking_booking_dict(pb, slot), "slot": slot_dict(slot) if slot else None});
    }
}
