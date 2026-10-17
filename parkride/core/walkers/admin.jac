"""Administrative inspection and maintenance walkers for ParkRide operations."""

import from core.models.nodes {
    TerminalNode,
    ParkingSlotNode,
    BusNode,
    BookingNode,
    SlotStatus,
    BookingStatus,
    BusStatus
}
import from core.models.edges {
    TerminalSlotEdge,
    TerminalBookingEdge,
    RoadEdge,
    SystemEdge
}
import from core.lib.clock { get_current_time_iso }

walker get_system_overview {
    can run with Root entry {
        terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
        if len(terminals) == 0 {
            terminals = [here --> [?:TerminalNode]];
        }

        buses = [here ->:SystemEdge:-> [?:BusNode]];
        if len(buses) == 0 {
            buses = [here --> [?:BusNode]];
        }

        total_terminals = len(terminals);
        total_slots = 0;
        available_slots = 0;
        occupied_slots = 0;
        reserved_slots = 0;
        total_revenue_lkr = 0.0;
        active_bookings_count = 0;

        for t in terminals {
            slots = [t ->:TerminalSlotEdge:-> [?:ParkingSlotNode]];
            total_slots += len(slots);
            for s in slots {
                if s.status == SlotStatus.AVAILABLE {
                    available_slots += 1;
                } elif s.status == SlotStatus.OCCUPIED {
                    occupied_slots += 1;
                } elif s.status == SlotStatus.RESERVED {
                    reserved_slots += 1;
                }
            }

            bookings = [t ->:TerminalBookingEdge:-> [?:BookingNode]];
            for b in bookings {
                if b.status == BookingStatus.CONFIRMED or b.status == BookingStatus.CHECKED_IN {
                    active_bookings_count += 1;
                }
                if b.status != BookingStatus.CANCELLED {
                    total_revenue_lkr += b.fare_lkr;
                }
            }
        }

        parking_occupancy_percent = 0.0;
        if total_slots > 0 {
            parking_occupancy_percent = round(((occupied_slots + reserved_slots) / total_slots) * 100.0, 1);
        }

        now_str = get_current_time_iso();

        report {
            "status": "healthy",
            "timestamp": now_str,
            "terminals_count": total_terminals,
            "parking": {
                "total_slots": total_slots,
                "available_slots": available_slots,
                "occupied_slots": occupied_slots,
                "reserved_slots": reserved_slots,
                "occupancy_rate_percent": parking_occupancy_percent
            },
            "transit": {
                "fleet_size": len(buses)
            },
            "bookings": {
                "active_count": active_bookings_count,
                "total_revenue_lkr": total_revenue_lkr
            }
        };
    }
}

walker override_slot_status {
    has slot_id: str;
    has new_status: str; # available, reserved, occupied, maintenance
    has reason: str = "Admin override";

    can run with Root entry {
        terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
        if len(terminals) == 0 {
            terminals = [here --> [?:TerminalNode]];
        }

        target_slot: ParkingSlotNode | None = None;
        target_term: TerminalNode | None = None;

        for t in terminals {
            slots = [t ->:TerminalSlotEdge:-> [?:ParkingSlotNode]];
            for s in slots {
                if s.id == self.slot_id {
                    target_slot = s;
                    target_term = t;
                    break;
                }
            }
            if target_slot is not None {
                break;
            }
        }

        if target_slot is None {
            report {
                "status": "not_found",
                "message": f"Parking slot '{self.slot_id}' not found"
            };
            disengage;
        }

        parsed_status = SlotStatus.AVAILABLE;
        if self.new_status == "reserved" {
            parsed_status = SlotStatus.RESERVED;
        } elif self.new_status == "occupied" {
            parsed_status = SlotStatus.OCCUPIED;
        } elif self.new_status == "maintenance" {
            parsed_status = SlotStatus.MAINTENANCE;
        }

        target_slot.status = parsed_status;
        target_slot.updated_at = get_current_time_iso();

        report {
            "status": "success",
            "slot_id": target_slot.id,
            "slot_number": target_slot.slot_number,
            "terminal": target_term.name if target_term is not None else "",
            "new_status": target_slot.status,
            "reason": self.reason
        };
    }
}
