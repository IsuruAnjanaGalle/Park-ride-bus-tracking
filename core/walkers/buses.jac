"""Map, bus and seat walkers (contracts.md 3.7-3.10). Status: real (positions move from milestone 3)."""

import from core.lib.envelope { ok, fail }
import from core.lib.world {
    get_world, get_clock, list_buses, find_bus, current_trip, get_routes, get_junctions, junction_names
}
import from core.lib.clock { clock_dict, now_hms }
import from core.lib.shapes { bus_dict, booking_dict, junction_coords, map_roads, stop_ref }
import from core.lib.profiles { caller_profile, profile_error }
import from core.lib.journey { book_seat_rule, seats_between, find_trip_booking }
import from core.lib.sim { tick, delay_to }

walker:pub get_map {
    has reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        junctions = get_junctions(world);
        lats = [j.lat for j in junctions];
        lngs = [j.lng for j in junctions];
        report ok({
            "junctions": [
                {"code": j.code, "name": j.name, "lat": j.lat, "lng": j.lng, "kind": j.kind}
                for j in junctions
            ],
            "roads": map_roads(world),
            "routes": [
                {"id": r.id, "name": r.name, "color": r.color, "stops": r.stop_codes}
                for r in get_routes(world)
            ],
            "bounds": {"min_lat": min(lats), "max_lat": max(lats), "min_lng": min(lngs), "max_lng": max(lngs)}
        });
    }
}

walker:pub get_buses {
    has route: str = "",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        tick(world);
        names = junction_names(world);
        coords = junction_coords(world);
        buses = [b for b in list_buses(world) if not self.route or b.route == self.route];
        report ok({
            "clock": clock_dict(get_clock(world)),
            "buses": [bus_dict(world, b, names, coords) for b in buses]
        });
    }
}

walker:protect book_seat {
    has bus_id: str,
        pickup: str,
        drop: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = profile_error(world);
        if err {
            report err;
            return;
        }
        tick(world);
        bus = find_bus(world, self.bus_id);
        if bus is None {
            report fail("NOT_FOUND", f"No bus {self.bus_id}.");
            return;
        }
        prof = caller_profile(world);
        if prof is None {
            report fail("NO_PROFILE", "Call get_profile after logging in.");
            return;
        }
        (code, b) = book_seat_rule(world, prof, bus, self.pickup, self.drop);
        if code == "INVALID_INPUT" {
            report fail(code, "pickup and drop must be stops on this bus's trip, drop after pickup.");
        } elif code == "PASSED_STOP" {
            report fail(code, f"The bus has already left {self.pickup}.");
        } elif code == "NO_SEAT" {
            report fail(code, "No free seat on part of that journey.");
        } elif code == "ALREADY_BOOKED" {
            report fail(code, f"You already have booking {b.id} on this bus.");
        } else {
            trip = current_trip(bus);
            left = 0;
            if trip {
                left = seats_between(bus, trip, trip.stop_codes.index(self.pickup), trip.stop_codes.index(self.drop));
            }
            report ok({"booking": booking_dict(b, junction_names(world)), "seats_left_on_segment": left});
        }
    }
}

walker:protect get_trip {
    has booking_id: str = "",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = profile_error(world);
        if err {
            report err;
            return;
        }
        tick(world);
        prof = caller_profile(world);
        if prof is None {
            report fail("NO_PROFILE", "Call get_profile after logging in.");
            return;
        }
        found = find_trip_booking(world, prof.username, self.booking_id);
        if found is None {
            report fail("NOT_FOUND", "No active booking.");
            return;
        }
        (b, bus, trip) = found;
        names = junction_names(world);
        coords = junction_coords(world);
        summary = bus_dict(world, bus, names, coords);
        stops: list[dict[str, any]] = [];
        for st in summary["stops"] {
            stops.append({
                "code": st["code"],
                "name": st["name"],
                "status": "passed" if st["passed"] else ("next" if st["code"] == bus.next_stop or st["code"] == bus.from_stop and bus.state == "dwelling" else "upcoming"),
                "eta_min": st["eta_min"],
                "is_pickup": st["code"] == b.pickup,
                "is_drop": st["code"] == b.drop
            });
        }
        remaining = max(trip.stop_codes.index(b.drop) - trip.last_departed, 0) if b.drop in trip.stop_codes else 0;
        alert = b.state == "OnBoard" and remaining <= 2;
        report ok({
            "booking": booking_dict(b, names),
            "bus": summary,
            "stops": stops,
            "stops_remaining": remaining,
            "alert": alert,
            "alert_message": f"Your stop is {remaining} stop{'s' if remaining != 1 else ''} away" if alert else "",
            "delay": delay_to(world, bus, trip, b.drop) if b.state in ["Pending", "OnBoard"] else None
        });
    }
}
