"""Traffic, incident and driver walkers (contracts.md 3.17-3.19). Status: real."""

import from core.models.nodes { Incident }
import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, find_bus, current_trip, junction_names, get_clock, new_id }
import from core.lib.clock { now_hms }
import from core.lib.shapes { bus_dict, junction_coords, trip_bookings }
import from core.lib.profiles { admin_error }
import from core.lib.locks { WORLD_LOCK }
import from core.lib.routing { set_road_level, clear_roads, build_adj }
import from core.lib.sim { tick, replan_all, instruction }
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
        tick(world);
        roads: list[dict[str, any]] = [];
        changed: list[str] = [];
        with WORLD_LOCK {
            if self.preset {
                presets = {p["id"]: p for p in load_json("road-network.json")["presets"]};
                if self.preset not in presets {
                    report fail("NOT_FOUND", f"No preset {self.preset}.");
                    return;
                }
                before = build_adj(world);
                clear_roads(world);
                for r in presets[self.preset]["roads"] {
                    set_road_level(world, r["from"], r["to"], r["level"]);
                    roads.append({"a": r["from"], "b": r["to"], "level": r["level"]});
                }
                after = build_adj(world);
                for (x, outs) in before.items() {
                    for (y, info) in outs.items() {
                        if x < y and info[2] != after[x][y][2] {
                            changed.append(f"{x}|{y}");
                        }
                    }
                }
            } elif self.a and self.b and 0 <= self.level <= 3 {
                if not set_road_level(world, self.a, self.b, self.level) {
                    report fail("NOT_FOUND", f"No road {self.a} - {self.b}.");
                    return;
                }
                roads = [{"a": self.a, "b": self.b, "level": self.level}];
                changed = [f"{self.a}|{self.b}"];
            } else {
                report fail("INVALID_INPUT", "Give a preset, or a, b and level 0-3.");
                return;
            }
        }
        report ok({"preset": self.preset, "roads": roads, "decisions": replan_all(world, changed)});
    }
}

walker:pub report_incident {
    has bus_id: str,
        kind: str,
        severity: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        tick(world);
        bus = find_bus(world, self.bus_id);
        if bus is None {
            report fail("NOT_FOUND", f"No bus {self.bus_id}.");
            return;
        }
        if self.kind not in INCIDENT_KINDS or self.severity not in SEVERITIES {
            report fail("INVALID_INPUT", "Unknown incident kind or severity.");
            return;
        }
        if bus.road_from == bus.road_to {
            report fail("INVALID_INPUT", "The bus is not on a road right now.");
            return;
        }
        level = SEVERITIES[self.severity];
        with WORLD_LOCK {
            set_road_level(world, bus.road_from, bus.road_to, level);
            inc = Incident(
                id=new_id(world, "IN"), kind=self.kind, severity=self.severity,
                road_from=bus.road_from, road_to=bus.road_to, reporter=f"driver {bus.id}",
                bus_id=bus.id, at=now_hms(get_clock(world))
            );
            world ++> inc;
        }
        decisions = replan_all(world, [f"{bus.road_from}|{bus.road_to}"]);
        report ok({
            "incident": {
                "id": inc.id, "kind": inc.kind, "severity": inc.severity,
                "road": {"a": inc.road_from, "b": inc.road_to, "level": level},
                "bus_id": bus.id, "at": inc.at
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
        trip = current_trip(bus) if bus else None;
        if bus is None or trip is None {
            report fail("NOT_FOUND", f"No running trip for bus {self.bus_id}.");
            return;
        }
        names = junction_names(world);
        summary = bus_dict(world, bus, names, junction_coords(world));
        nxt = bus.from_stop if bus.state == "dwelling" else bus.next_stop;
        waiting = [b for b in trip_bookings(trip) if b.state == "Pending" and b.pickup == nxt];
        info = build_adj(world).get(bus.road_from, {}).get(bus.road_to);
        report ok({
            "bus": summary,
            "instruction": instruction(world, bus),
            "next_stop": summary["next_stop"],
            "eta_min": summary["eta_min"],
            "waiting_at_next": len(waiting),
            "road": {"a": bus.road_from, "b": bus.road_to, "level": info[2] if info else 0},
            "path": bus.path,
            "rerouted": bus.rerouted,
            "reroute_reason": bus.reroute_reason
        });
    }
}
