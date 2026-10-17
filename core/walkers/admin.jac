"""Admin walkers (contracts.md 3.12-3.15). Admin login required. Status: stub."""

import from core.models.nodes { Alert, Scan, Trip, StopVisit, Decision }
import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, get_clock, list_buses, find_bus, current_trip, junction_names }
import from core.lib.clock { clock_dict, sim_seconds }
import from core.lib.qr { sign_token }
import from core.lib.shapes {
    bus_dict, junction_coords, stop_ref, trip_bookings, segment_seats, alert_dict, scan_dict, eta_to
}
import from core.lib.profiles { admin_error }
import from core.lib.rules { STOP_QR_TTL_S }
import from core.lib.journey { open_visit, visit_token }
import from core.lib.sim { tick }

walker:protect admin_bus_list {
    has reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = admin_error(world);
        if err {
            report err;
            return;
        }
        tick(world);
        names = junction_names(world);
        coords = junction_coords(world);
        report ok({
            "clock": clock_dict(get_clock(world)),
            "buses": [bus_dict(world, b, names, coords) for b in list_buses(world)]
        });
    }
}

walker:protect admin_bus_account {
    has bus_id: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = admin_error(world);
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
        names = junction_names(world);
        coords = junction_coords(world);
        summary = bus_dict(world, bus, names, coords);
        trips = [
            {
                "id": t.id, "direction": t.direction, "status": t.status,
                "stops": t.stop_codes, "last_departed": t.last_departed
            }
            for t in [bus -->[?:Trip]]
        ];
        report ok({
            "bus": {
                "id": bus.id, "plate": bus.plate, "route": bus.route, "route_name": summary["route_name"],
                "color": summary["color"], "driver": bus.driver, "conductor": bus.conductor,
                "capacity": bus.capacity, "on_board": summary["on_board"], "seats_left": summary["seats_left"]
            },
            "position": {"lat": bus.lat, "lng": bus.lng, "heading": bus.heading},
            "path": bus.path,
            "next_stop": summary["next_stop"],
            "eta_min": summary["eta_min"],
            "trips_today": trips
        });
    }
}

walker:protect admin_next_stop {
    has bus_id: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = admin_error(world);
        if err {
            report err;
            return;
        }
        tick(world);
        bus = find_bus(world, self.bus_id);
        trip = current_trip(bus) if bus else None;
        if bus is None or trip is None {
            report fail("NOT_FOUND", f"No running trip for bus {self.bus_id}.");
            return;
        }
        names = junction_names(world);
        coords = junction_coords(world);
        sv = open_visit(trip);
        stop = sv.stop_code if sv else bus.next_stop;
        bookings = trip_bookings(trip);
        getting_off = [b for b in bookings if b.state == "OnBoard" and b.drop == stop];
        to_board = [b for b in bookings if b.state == "Pending" and b.pickup == stop];
        walk_ins = [b for b in bookings if b.walk_in and b.pickup == stop];
        seats = segment_seats(bus, trip);
        idx = trip.stop_codes.index(stop) if stop in trip.stop_codes else -1;
        seats_after = seats[idx] if 0 <= idx < len(seats) else bus.capacity;
        visit_no = sv.visit_no if sv else 0;
        token = visit_token(world, sv) if sv else "";
        report ok({
            "bus_id": bus.id,
            "stop": stop_ref(stop, names),
            "eta_min": eta_to(bus, trip, stop, coords),
            "visit_no": visit_no,
            "getting_off": len(getting_off),
            "getting_off_names": [b.username for b in getting_off],
            "bookings_to_board": len(to_board),
            "walk_ins": len(walk_ins),
            "seats_left_after": seats_after,
            "qr": token,
            "qr_expires_in_s": STOP_QR_TTL_S
        });
    }
}

walker:protect admin_feed {
    has limit: int = 50,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = admin_error(world);
        if err {
            report err;
            return;
        }
        names = junction_names(world);
        scans: list[dict[str, any]] = [];
        for s in [world -->[?:Scan]] {
            scans.append(scan_dict(s, names));
        }
        alerts = [alert_dict(a) for a in [world -->[?:Alert]]];
        scans = sorted(scans, key=lambda (x: dict[str, any]) { x["at"]; }, reverse=True)[:self.limit];
        alerts = sorted(alerts, key=lambda (x: dict[str, any]) { x["at"]; }, reverse=True)[:self.limit];
        decisions = sorted(
            [{"at": d.at, "bus_id": d.bus_id, "decision": d.decision, "reason": d.reason} for d in [world -->[?:Decision]]],
            key=lambda (x: dict[str, any]) { x["at"]; }, reverse=True
        )[:self.limit];
        report ok({"scans": scans, "alerts": alerts, "decisions": decisions});
    }
}
