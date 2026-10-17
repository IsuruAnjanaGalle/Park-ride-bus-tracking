"""Parking walkers (contracts.md 3.1-3.6). Status: stub - shaped responses from seed data."""

import from core.models.nodes { Slot, ParkingBooking }
import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, list_terminals, find_terminal, terminal_slots, get_clock }
import from core.lib.clock { now_hms }
import from core.lib.qr { sign_token }
import from core.lib.shapes { terminal_dict, slot_dict, parking_booking_dict }
import from core.lib.profiles { caller_profile, profile_error }
import from core.lib.rules { VEHICLES, EV_CHOICES, zone_for_stay, stay_hours, valid_hhmm }

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
        hours = stay_hours(self.arrival, self.return_by);
        zone = zone_for_stay(hours);
        kind = "E" if self.vehicle == "C" and self.ev == "needs_charging" else self.vehicle;
        free = [s for s in terminal_slots(term) if s.kind == kind and s.state == "free"];
        free = sorted(free, key=lambda (s: Slot) { (0 if s.zone == zone else 1, s.nn); });
        options: list[dict[str, any]] = [];
        for (i, s) in enumerate(free[:3]) {
            options.append({
                "rank": i + 1,
                "slot": slot_dict(s),
                "zone": s.zone,
                "score": 100 - 5 * s.nn,
                "reason": f"Zone {s.zone}, slot {s.nn} from the exit."
            });
        }
        report ok({"terminal": term.code, "zone": zone, "stay_hours": hours, "slot_type": kind, "options": options, "fallback": None});
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
        term = find_terminal(world, self.terminal);
        if term is None {
            report fail("NOT_FOUND", f"No terminal {self.terminal}.");
            return;
        }
        matches = [s for s in terminal_slots(term) if s.code == self.slot_code];
        if not matches {
            report fail("NOT_FOUND", f"No slot {self.slot_code}.");
            return;
        }
        slot = matches[0];
        prof = caller_profile(world);
        pb = ParkingBooking(
            id="PB-0001", username=prof.username if prof else "", slot_code=slot.code,
            terminal=term.code, arrival=self.arrival, return_by=self.return_by, state="booked",
            created_at=now_hms(get_clock(world))
        );
        pb.qr_token = sign_token({"t": "parking", "id": pb.id, "slot": slot.code, "terminal": term.code, "return_by": pb.return_by});
        report ok({"booking": parking_booking_dict(pb, slot)});
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
        term = find_terminal(world, "MKB");
        slot = [s for s in terminal_slots(term) if s.code == "MKB-C-F-03"][0] if term else None;
        pb = ParkingBooking(
            id=self.booking_id, username="passenger", slot_code="MKB-C-F-03", terminal="MKB",
            arrival="08:00", return_by="10:00", state="parked"
        );
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
        if not self.booking_id and not self.qr {
            report fail("INVALID_INPUT", "Give booking_id or qr.");
            return;
        }
        term = find_terminal(world, "MKB");
        slot = [s for s in terminal_slots(term) if s.code == "MKB-C-F-03"][0] if term else None;
        pb = ParkingBooking(
            id=self.booking_id or "PB-0001", username="passenger", slot_code="MKB-C-F-03",
            terminal="MKB", arrival="08:00", return_by="10:00", state="released"
        );
        report ok({"booking": parking_booking_dict(pb, slot), "slot": slot_dict(slot) if slot else None});
    }
}
