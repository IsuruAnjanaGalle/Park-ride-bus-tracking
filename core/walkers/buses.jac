"""Map, bus and seat walkers (contracts.md 3.7-3.10). Status: stub - shaped responses from seed data."""

import from core.models.nodes { Booking }
import from core.lib.envelope { ok, fail }
import from core.lib.world {
    get_world, get_clock, list_buses, find_bus, current_trip, get_routes, get_junctions, junction_names
}
import from core.lib.clock { clock_dict, now_hms }
import from core.lib.shapes { bus_dict, booking_dict, junction_coords, map_roads, stop_ref }
import from core.lib.profiles { caller_profile, profile_error }

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
        bus = find_bus(world, self.bus_id);
        if bus is None {
            report fail("NOT_FOUND", f"No bus {self.bus_id}.");
            return;
        }
        trip = current_trip(bus);
        if trip is None or self.pickup not in trip.stop_codes or self.drop not in trip.stop_codes {
            report fail("INVALID_INPUT", "pickup and drop must be stops on this bus's trip.");
            return;
        }
        prof = caller_profile(world);
        names = junction_names(world);
        b = Booking(
            id="BK-0001", username=prof.username if prof else "", bus_id=bus.id, trip_id=trip.id,
            route=bus.route, pickup=self.pickup, drop=self.drop, state="Pending",
            created_at=now_hms(get_clock(world))
        );
        report ok({"booking": booking_dict(b, names), "seats_left_on_segment": bus.capacity - 1});
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
        bus = find_bus(world, "MB-102");
        trip = current_trip(bus) if bus else None;
        if bus is None or trip is None {
            report fail("NOT_FOUND", "No active booking.");
            return;
        }
        names = junction_names(world);
        coords = junction_coords(world);
        b = Booking(
            id=self.booking_id or "BK-0001", username="passenger", bus_id=bus.id, trip_id=trip.id,
            route=bus.route, pickup="KOT", drop="BOR", state="Pending"
        );
        summary = bus_dict(world, bus, names, coords);
        stops: list[dict[str, any]] = [];
        for st in summary["stops"] {
            stops.append({
                "code": st["code"],
                "name": st["name"],
                "status": "passed" if st["passed"] else ("next" if st["code"] == bus.next_stop else "upcoming"),
                "eta_min": st["eta_min"],
                "is_pickup": st["code"] == b.pickup,
                "is_drop": st["code"] == b.drop
            });
        }
        drop_i = trip.stop_codes.index(b.drop);
        remaining = max(drop_i - trip.last_departed, 0);
        report ok({
            "booking": booking_dict(b, names),
            "bus": summary,
            "stops": stops,
            "stops_remaining": remaining,
            "alert": remaining <= 2,
            "alert_message": "Your stop is 2 stops away" if remaining <= 2 else "",
            "delay": None
        });
    }
}
