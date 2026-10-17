"""QR scan walker (contracts.md 3.11). Status: stub - verifies the stop QR, then a shaped result."""

import from core.models.nodes { Booking }
import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, find_bus, current_trip, junction_names, get_clock }
import from core.lib.clock { now_hms }
import from core.lib.qr { verify_token }
import from core.lib.shapes { booking_dict, stop_ref }
import from core.lib.profiles { caller_profile, profile_error }

walker:protect process_scan {
    has scan_id: str,
        qr: str,
        drop: str = "",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = profile_error(world);
        if err {
            report err;
            return;
        }
        if not self.scan_id {
            report fail("INVALID_INPUT", "scan_id is required.");
            return;
        }
        names = junction_names(world);
        check = verify_token(self.qr);
        payload = check["payload"];
        if not check["valid"] or payload.get("t") != "stop" {
            report ok({
                "result": "rejected", "message": "This is not a valid stop QR.", "scan_id": self.scan_id,
                "booking": None, "stop": None, "bus_id": ""
            });
            return;
        }
        bus = find_bus(world, payload.get("bus", ""));
        trip = current_trip(bus) if bus else None;
        if bus is None or trip is None {
            report ok({
                "result": "rejected", "message": "Unknown bus.", "scan_id": self.scan_id,
                "booking": None, "stop": None, "bus_id": ""
            });
            return;
        }
        prof = caller_profile(world);
        stop_code = payload.get("stop", "");
        b = Booking(
            id="BK-0001", username=prof.username if prof else "", bus_id=bus.id, trip_id=trip.id,
            route=bus.route, pickup=stop_code, drop=trip.stop_codes[-1], state="OnBoard",
            created_at=now_hms(get_clock(world))
        );
        report ok({
            "result": "boarded",
            "message": "Confirmed, you are on board.",
            "scan_id": self.scan_id,
            "booking": booking_dict(b, names),
            "stop": stop_ref(stop_code, names),
            "bus_id": bus.id
        });
    }
}
