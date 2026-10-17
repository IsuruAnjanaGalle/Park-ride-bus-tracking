"""Traffic, incident and driver walkers (contracts.md 3.17-3.19). Status: stub."""

import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, find_bus, current_trip, junction_names, get_clock }
import from core.lib.clock { now_hms }
import from core.lib.shapes { bus_dict, junction_coords, stop_ref, trip_bookings }
import from core.lib.profiles { admin_error }
import from core.seed.seed { load_json }
import from core.lib.rules { INCIDENT_KINDS, SEVERITIES }

walker:protect set_traffic {
    has preset: str = "",
        a: str = "",
        b: str = "",
        level: int = -1,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = admin_error(world);
        if err {
            report err;
            return;
        }
        roads: list[dict[str, any]] = [];
        if self.preset {
            presets = {p["id"]: p for p in load_json("road-network.json")["presets"]};
            if self.preset not in presets {
                report fail("NOT_FOUND", f"No preset {self.preset}.");
                return;
            }
            roads = [{"a": r["from"], "b": r["to"], "level": r["level"]} for r in presets[self.preset]["roads"]];
        } elif self.a and self.b and 0 <= self.level <= 3 {
            roads = [{"a": self.a, "b": self.b, "level": self.level}];
        } else {
            report fail("INVALID_INPUT", "Give a preset, or a, b and level 0-3.");
            return;
        }
        report ok({"preset": self.preset, "roads": roads, "decisions": []});
    }
}

walker:pub report_incident {
    has bus_id: str,
        kind: str,
        severity: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        bus = find_bus(world, self.bus_id);
        if bus is None {
            report fail("NOT_FOUND", f"No bus {self.bus_id}.");
            return;
        }
        if self.kind not in INCIDENT_KINDS or self.severity not in SEVERITIES {
            report fail("INVALID_INPUT", "Unknown incident kind or severity.");
            return;
        }
        report ok({
            "incident": {
                "id": "IN-0001", "kind": self.kind, "severity": self.severity,
                "road": {"a": bus.road_from, "b": bus.road_to, "level": SEVERITIES[self.severity]},
                "bus_id": bus.id, "at": now_hms(get_clock(world))
            },
            "decisions": []
        });
    }
}

walker:pub get_driver_view {
    has bus_id: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        bus = find_bus(world, self.bus_id);
        trip = current_trip(bus) if bus else None;
        if bus is None or trip is None {
            report fail("NOT_FOUND", f"No running trip for bus {self.bus_id}.");
            return;
        }
        names = junction_names(world);
        coords = junction_coords(world);
        summary = bus_dict(world, bus, names, coords);
        waiting = [b for b in trip_bookings(trip) if b.state == "Pending" and b.pickup == bus.next_stop];
        toward = names.get(bus.road_to, bus.road_to);
        report ok({
            "bus": summary,
            "instruction": {"text": f"Continue toward {toward}", "turn": "straight", "toward": toward, "km": 1.0},
            "next_stop": summary["next_stop"],
            "eta_min": summary["eta_min"],
            "waiting_at_next": len(waiting),
            "road": {"a": bus.road_from, "b": bus.road_to, "level": 0},
            "path": bus.path,
            "rerouted": bus.rerouted,
            "reroute_reason": bus.reroute_reason
        });
    }
}
