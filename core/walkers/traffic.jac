"""Traffic, incident and driver walkers (contracts.md 3.17-3.19). Real implementation."""

import from core.lib.envelope { ok, fail }
import from core.models.nodes { Incident, Alert }
import from core.lib.world { get_world, find_bus, must_bus, current_trip, must_trip, junction_names, get_clock, new_id }
import from core.lib.clock { now_hms }
import from core.lib.shapes { bus_dict, junction_coords, trip_bookings }
import from core.lib.profiles { admin_error }
import from core.seed.seed { load_json }
import from core.lib.rules { INCIDENT_KINDS, SEVERITIES }
import from core.lib.static { road_key }
import from core.lib.routing { build_adj, set_road_level, clear_roads }
import from core.lib.sim { tick, replan_all, instruction, stop_etas }

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
        changed_keys: list[str] = [];

        if self.preset == "clear" {
            clear_roads(world);
            decisions = replan_all(world, []);
            report ok({"preset": "clear", "roads": [], "decisions": decisions});
            return;
        } elif self.preset {
            presets = {p["id"]: p for p in load_json("road-network.json")["presets"]};
            if self.preset not in presets {
                report fail("NOT_FOUND", f"No preset {self.preset}.");
                return;
            }
            clear_roads(world);
            for r in presets[self.preset]["roads"] {
                a_code = str(r["from"]);
                b_code = str(r["to"]);
                lvl = int(r["level"]);
                set_road_level(world, a_code, b_code, lvl);
                roads.append({"a": a_code, "b": b_code, "level": lvl});
                changed_keys.append(f"{a_code}|{b_code}");
            }
            decisions = replan_all(world, changed_keys);
            report ok({"preset": self.preset, "roads": roads, "decisions": decisions});
            return;
        } elif self.a and self.b and 0 <= self.level <= 3 {
            set_road_level(world, self.a, self.b, self.level);
            roads = [{"a": self.a, "b": self.b, "level": self.level}];
            decisions = replan_all(world, [f"{self.a}|{self.b}"]);
            report ok({"preset": "", "roads": roads, "decisions": decisions});
            return;
        } else {
            report fail("INVALID_INPUT", "Give a preset, or a, b and level 0-3.");
            return;
        }
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
        lvl = int(SEVERITIES[self.severity]);
        a = bus.road_from;
        b = bus.road_to;
        set_road_level(world, a, b, lvl);

        now_str = now_hms(get_clock(world));
        inc_id = new_id(world, "IN");
        inc = Incident(
            id=inc_id, kind=self.kind, severity=self.severity,
            road_from=a, road_to=b, bus_id=bus.id, at=now_str, confirmed=True
        );
        world ++> inc;

        al_id = new_id(world, "AL");
        world ++> Alert(
            id=al_id, kind="incident",
            message=f"Bus {bus.id} reported {self.kind} ({self.severity}) on {a} - {b}",
            bus_id=bus.id, at=now_str
        );

        decisions = replan_all(world, [f"{a}|{b}"]);
        report ok({
            "incident": {
                "id": inc_id, "kind": self.kind, "severity": self.severity,
                "road": {"a": a, "b": b, "level": lvl},
                "bus_id": bus.id, "at": now_str
            },
            "decisions": decisions
        });
    }
}

walker:pub get_driver_view {
    has bus_id: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        tick(world);
        bus = find_bus(world, self.bus_id);
        if bus is None {
            report fail("NOT_FOUND", f"No bus {self.bus_id}.");
            return;
        }
        the_bus = must_bus(world, self.bus_id);
        trip = current_trip(the_bus);
        if trip is None {
            report fail("NOT_FOUND", f"No running trip for bus {self.bus_id}.");
            return;
        }
        the_trip = must_trip(the_bus);
        names = junction_names(world);
        coords = junction_coords(world);
        adj = build_adj(world);
        etas = stop_etas(world, adj, the_bus, the_trip);
        eta_min = etas.get(the_bus.next_stop, 0.0);

        summary = bus_dict(world, the_bus, names, coords);
        summary["eta_min"] = eta_min;

        waiting = [b for b in trip_bookings(the_trip) if b.state == "Pending" and b.pickup == the_bus.next_stop];
        levels = dict(world.road_levels);
        road_lvl = levels.get(road_key(the_bus.road_from, the_bus.road_to), 0);

        report ok({
            "bus": summary,
            "instruction": instruction(world, the_bus),
            "next_stop": summary["next_stop"],
            "eta_min": eta_min,
            "waiting_at_next": len(waiting),
            "road": {"a": the_bus.road_from, "b": the_bus.road_to, "level": road_lvl},
            "path": the_bus.path,
            "rerouted": the_bus.rerouted,
            "reroute_reason": the_bus.reroute_reason
        });
    }
}
