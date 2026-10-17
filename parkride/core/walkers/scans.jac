"""Walkers for automated gate QR entry and exit scanning."""

import from core.models.nodes {
    TerminalNode,
    ParkingSlotNode,
    BookingNode,
    SlotStatus,
    BookingStatus
}
import from core.models.edges {
    TerminalSlotEdge,
    TerminalBookingEdge,
    SystemEdge
}
import from core.lib.qr_sign { verify_qr_token }
import from core.lib.clock { get_current_time_iso, get_current_epoch }

walker scan_gate_entry {
    has qr_token: str;
    has gate_id: str = "GATE_IN_01";

    can run with Root entry {
        verify_res = verify_qr_token(self.qr_token);
        if not verify_res.get("valid", False) {
            report {
                "status": "denied",
                "gate_action": "BARRIER_LOCKED",
                "reason": verify_res.get("reason", "Invalid QR token"),
                "booking": None
            };
            disengage;
        }

        payload = verify_res.get("payload", {});
        booking_id = payload.get("booking_id", "");
        terminal_id = payload.get("terminal_id", "");
        slot_id = payload.get("slot_id", "");
        now_str = get_current_time_iso();

        terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
        if len(terminals) == 0 {
            terminals = [here --> [?:TerminalNode]];
        }

        found_booking: BookingNode | None = None;
        found_slot: ParkingSlotNode | None = None;
        found_terminal: TerminalNode | None = None;

        for t in terminals {
            if t.id == terminal_id or terminal_id == "" {
                bookings = [t ->:TerminalBookingEdge:-> [?:BookingNode]];
                for b in bookings {
                    if b.id == booking_id {
                        found_booking = b;
                        found_terminal = t;
                        break;
                    }
                }
                if found_booking is not None {
                    slots = [t ->:TerminalSlotEdge:-> [?:ParkingSlotNode]];
                    for s in slots {
                        if s.id == slot_id {
                            found_slot = s;
                            break;
                        }
                    }
                    break;
                }
            }
        }

        if found_booking is None {
            report {
                "status": "denied",
                "gate_action": "BARRIER_LOCKED",
                "reason": f"Active booking '{booking_id}' not found in system",
                "booking": None
            };
            disengage;
        }

        # Transition state
        found_booking.status = BookingStatus.CHECKED_IN;
        found_booking.check_in_time = now_str;

        if found_slot is not None {
            found_slot.status = SlotStatus.OCCUPIED;
            found_slot.updated_at = now_str;
        }

        report {
            "status": "granted",
            "gate_action": "BARRIER_OPENED",
            "gate_id": self.gate_id,
            "booking_id": found_booking.id,
            "vehicle_number": found_booking.vehicle_number,
            "allocated_slot": found_slot.slot_number if found_slot is not None else "A-01",
            "floor_or_zone": found_slot.floor_or_zone if found_slot is not None else "Zone A",
            "check_in_time": now_str,
            "message": "Welcome to ParkRide! Barrier opened."
        };
    }
}

walker scan_gate_exit {
    has qr_token: str;
    has gate_id: str = "GATE_OUT_01";

    can run with Root entry {
        verify_res = verify_qr_token(self.qr_token);
        if not verify_res.get("valid", False) {
            report {
                "status": "denied",
                "gate_action": "BARRIER_LOCKED",
                "reason": verify_res.get("reason", "Invalid QR token"),
                "booking": None
            };
            disengage;
        }

        payload = verify_res.get("payload", {});
        booking_id = payload.get("booking_id", "");
        slot_id = payload.get("slot_id", "");
        now_str = get_current_time_iso();

        terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
        if len(terminals) == 0 {
            terminals = [here --> [?:TerminalNode]];
        }

        found_booking: BookingNode | None = None;
        found_slot: ParkingSlotNode | None = None;

        for t in terminals {
            bookings = [t ->:TerminalBookingEdge:-> [?:BookingNode]];
            for b in bookings {
                if b.id == booking_id {
                    found_booking = b;
                    slots = [t ->:TerminalSlotEdge:-> [?:ParkingSlotNode]];
                    for s in slots {
                        if s.id == slot_id {
                            found_slot = s;
                            break;
                        }
                    }
                    break;
                }
            }
            if found_booking is not None {
                break;
            }
        }

        if found_booking is None {
            report {
                "status": "denied",
                "gate_action": "BARRIER_LOCKED",
                "reason": f"Active booking '{booking_id}' not found for checkout",
                "booking": None
            };
            disengage;
        }

        # Transition state
        found_booking.status = BookingStatus.COMPLETED;
        found_booking.check_out_time = now_str;

        if found_slot is not None {
            found_slot.status = SlotStatus.AVAILABLE;
            found_slot.current_reservation_id = "";
            found_slot.updated_at = now_str;
        }

        report {
            "status": "granted",
            "gate_action": "BARRIER_OPENED",
            "gate_id": self.gate_id,
            "booking_id": found_booking.id,
            "vehicle_number": found_booking.vehicle_number,
            "check_in_time": found_booking.check_in_time,
            "check_out_time": now_str,
            "fare_paid_lkr": found_booking.fare_lkr,
            "message": "Thank you for riding with ParkRide! Have a safe journey."
        };
    }
}
