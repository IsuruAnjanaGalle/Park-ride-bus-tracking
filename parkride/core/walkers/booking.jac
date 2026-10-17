"""Walkers for booking parking slots and multimodal tickets."""

import uuid;
import from core.models.nodes {
    TerminalNode,
    ParkingSlotNode,
    BookingNode,
    SlotType,
    SlotStatus,
    BookingStatus
}
import from core.models.edges {
    TerminalSlotEdge,
    TerminalBookingEdge,
    SystemEdge
}
import from core.lib.allocation { find_best_slot }
import from core.lib.qr_sign { generate_qr_token }
import from core.lib.clock { get_current_time_iso }

walker create_booking {
    has user_id: str;
    has user_phone: str;
    has vehicle_number: str;
    has terminal_id: str;
    has slot_id: str = "";
    has vehicle_type: str = "standard";
    has bus_route: str = "EX1-01";
    has fare_lkr: float = 350.0;

    can run with Root entry {
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
                "status": "error",
                "message": f"Terminal '{self.terminal_id}' not found",
                "booking": None
            };
            disengage;
        }

        slots = [target_term ->:TerminalSlotEdge:-> [?:ParkingSlotNode]];
        allocated_slot: ParkingSlotNode | None = None;

        if self.slot_id != "" {
            for s in slots {
                if s.id == self.slot_id and s.status == SlotStatus.AVAILABLE {
                    allocated_slot = s;
                    break;
                }
            }
        } else {
            st = SlotType.STANDARD;
            if self.vehicle_type == "ev" {
                st = SlotType.EV;
            } elif self.vehicle_type == "handicap" {
                st = SlotType.HANDICAP;
            } elif self.vehicle_type == "motorcycle" {
                st = SlotType.MOTORCYCLE;
            }
            allocated_slot = find_best_slot(slots, st, True);
        }

        if allocated_slot is None {
            report {
                "status": "full",
                "message": "No suitable parking slot available to reserve",
                "booking": None
            };
            disengage;
        }

        # Generate unique booking ID
        booking_id = "bk_" + str(uuid.uuid4())[:8];
        now_str = get_current_time_iso();

        # Cryptographically signed QR token
        qr_token = generate_qr_token(
            booking_id=booking_id,
            vehicle_number=self.vehicle_number,
            terminal_id=target_term.id,
            slot_id=allocated_slot.id,
            valid_hours=24.0
        );

        # Transition slot state
        allocated_slot.status = SlotStatus.RESERVED;
        allocated_slot.current_reservation_id = booking_id;
        allocated_slot.updated_at = now_str;

        # Create Booking Node
        booking = target_term +>:TerminalBookingEdge(created_at=now_str):+> BookingNode(
            id=booking_id,
            user_id=self.user_id,
            user_phone=self.user_phone,
            vehicle_number=self.vehicle_number,
            terminal_id=target_term.id,
            slot_id=allocated_slot.id,
            bus_route=self.bus_route,
            status=BookingStatus.CONFIRMED,
            start_time=now_str,
            end_time="",
            qr_token=qr_token,
            fare_lkr=self.fare_lkr
        );

        report {
            "status": "confirmed",
            "booking_id": booking.id,
            "terminal_name": target_term.name,
            "slot_number": allocated_slot.slot_number,
            "slot_type": allocated_slot.slot_type,
            "vehicle_number": self.vehicle_number,
            "bus_route": self.bus_route,
            "qr_token": qr_token,
            "fare_lkr": self.fare_lkr,
            "created_at": now_str
        };
    }
}

walker cancel_booking {
    has booking_id: str;

    can run with Root entry {
        terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
        if len(terminals) == 0 {
            terminals = [here --> [?:TerminalNode]];
        }

        for t in terminals {
            bookings = [t ->:TerminalBookingEdge:-> [?:BookingNode]];
            for b in bookings {
                if b.id == self.booking_id {
                    b.status = BookingStatus.CANCELLED;
                    # Release parking slot
                    slots = [t ->:TerminalSlotEdge:-> [?:ParkingSlotNode]];
                    for s in slots {
                        if s.id == b.slot_id {
                            s.status = SlotStatus.AVAILABLE;
                            s.current_reservation_id = "";
                            s.updated_at = get_current_time_iso();
                            break;
                        }
                    }
                    report {
                        "status": "cancelled",
                        "booking_id": b.id,
                        "message": "Booking cancelled and slot released"
                    };
                    disengage;
                }
            }
        }

        report {
            "status": "not_found",
            "message": f"Booking '{self.booking_id}' not found"
        };
    }
}
