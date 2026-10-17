"""Walkers for parking availability and slot inspection."""

import from core.models.nodes {
    TerminalNode,
    ParkingSlotNode,
    SlotType,
    SlotStatus
}
import from core.models.edges {
    TerminalSlotEdge,
    SystemEdge
}
import from core.lib.allocation {
    calculate_occupancy_stats,
    find_best_slot
}

walker check_parking_availability {
    has terminal_id: str = "";

    can inspect with Root entry {
        terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
        if len(terminals) == 0 {
            # Direct children fallback
            terminals = [here --> [?:TerminalNode]];
        }

        matched_terminals: list[TerminalNode] = [];
        for t in terminals {
            if self.terminal_id == "" or t.id == self.terminal_id {
                matched_terminals.append(t);
            }
        }

        if len(matched_terminals) == 0 {
            report {
                "status": "not_found",
                "message": f"Terminal '{self.terminal_id}' not found",
                "data": None
            };
            disengage;
        }

        results: list[dict[str, any]] = [];
        for t in matched_terminals {
            slots = [t ->:TerminalSlotEdge:-> [?:ParkingSlotNode]];
            stats = calculate_occupancy_stats(slots);
            results.append({
                "terminal_id": t.id,
                "name": t.name,
                "city": t.city,
                "total_slots": stats["total"],
                "available_slots": stats["available"],
                "reserved_slots": stats["reserved"],
                "occupied_slots": stats["occupied"],
                "maintenance_slots": stats["maintenance"],
                "ev_available": stats["ev_available"]
            });
        }

        report {
            "status": "success",
            "terminals": results
        };
    }
}

walker find_available_slot {
    has terminal_id: str;
    has vehicle_type: str = "standard"; # standard, ev, handicap, motorcycle
    has prefer_near_exit: bool = True;

    can search with Root entry {
        terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
        if len(terminals) == 0 {
            terminals = [here --> [?:TerminalNode]];
        }

        target_term: TerminalNode | None = None;
        for t in terminals {
            if t.id == self.terminal_id {
                target_term = t;
                break;
            }
        }

        if target_term is None {
            report {
                "status": "not_found",
                "message": f"Terminal '{self.terminal_id}' not found",
                "slot": None
            };
            disengage;
        }

        slots = [target_term ->:TerminalSlotEdge:-> [?:ParkingSlotNode]];
        requested_type = SlotType.STANDARD;
        if self.vehicle_type == "ev" {
            requested_type = SlotType.EV;
        } elif self.vehicle_type == "handicap" {
            requested_type = SlotType.HANDICAP;
        } elif self.vehicle_type == "motorcycle" {
            requested_type = SlotType.MOTORCYCLE;
        }

        best = find_best_slot(slots, requested_type, self.prefer_near_exit);
        if best is None {
            report {
                "status": "full",
                "message": f"No available {self.vehicle_type} slots in {target_term.name}",
                "slot": None
            };
            disengage;
        }

        report {
            "status": "available",
            "terminal_id": target_term.id,
            "terminal_name": target_term.name,
            "slot_id": best.id,
            "slot_number": best.slot_number,
            "slot_type": best.slot_type,
            "floor_or_zone": best.floor_or_zone,
            "distance_to_exit_m": best.distance_to_exit_m
        };
    }
}
