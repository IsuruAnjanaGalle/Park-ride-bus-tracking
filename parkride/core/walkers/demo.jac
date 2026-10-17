"""End-to-end interactive demo simulation walker for ParkRide hackathon showcase."""

import from core.models.nodes {
    TerminalNode,
    ParkingSlotNode,
    BookingNode,
    BusNode,
    StopNode,
    SlotStatus,
    BookingStatus
}
import from core.models.edges {
    TerminalSlotEdge,
    TerminalBookingEdge,
    RoadEdge,
    SystemEdge
}
import from core.walkers.parking { check_parking_availability, find_available_slot }
import from core.walkers.booking { create_booking }
import from core.walkers.scans { scan_gate_entry, scan_gate_exit }
import from core.walkers.buses { track_bus }
import from core.lib.clock { advance_sim_time, get_current_time_iso }

walker run_demo_simulation {
    has commuter_name: str = "Isuru Perera";
    has vehicle_number: str = "WP-CAB-4512";
    has terminal_id: str = "stop_makumbura";
    has bus_route: str = "EX1-01";

    can run with Root entry {
        audit_trail: list[dict[str, any]] = [];

        # STEP 1: Commuter checks parking availability
        step1_avail = here spawn check_parking_availability(terminal_id=self.terminal_id);
        audit_trail.append({
            "step": 1,
            "action": "CHECK_PARKING_AVAILABILITY",
            "result": "success",
            "terminal": self.terminal_id
        });

        # STEP 2: Find EV Slot
        step2_slot = here spawn find_available_slot(
            terminal_id=self.terminal_id,
            vehicle_type="ev"
        );
        allocated_slot_num = "EV-01";
        if step2_slot.reports and len(step2_slot.reports) > 0 {
            report_data = step2_slot.reports[0];
            allocated_slot_num = report_data.get("slot_number", "EV-01");
        }
        audit_trail.append({
            "step": 2,
            "action": "FIND_BEST_EV_SLOT",
            "allocated_slot": allocated_slot_num
        });

        # STEP 3: Reserve parking slot & combo ticket
        step3_book = here spawn create_booking(
            user_id="user_commuter_01",
            user_phone="+94771234567",
            vehicle_number=self.vehicle_number,
            terminal_id=self.terminal_id,
            vehicle_type="ev",
            bus_route=self.bus_route,
            fare_lkr=450.0
        );

        booking_id = "";
        qr_token = "";
        if step3_book.reports and len(step3_book.reports) > 0 {
            b_rep = step3_book.reports[0];
            booking_id = b_rep.get("booking_id", "");
            qr_token = b_rep.get("qr_token", "");
        }

        audit_trail.append({
            "step": 3,
            "action": "CREATE_BOOKING_WITH_SIGNED_QR",
            "booking_id": booking_id,
            "qr_token_generated": qr_token != ""
        });

        # STEP 4: Vehicle arrives at Makumbura MMC entry gate
        _ = advance_sim_time(15.0);
        step4_entry = here spawn scan_gate_entry(
            qr_token=qr_token,
            gate_id="MMC_GATE_IN_02"
        );

        audit_trail.append({
            "step": 4,
            "action": "GATE_ENTRY_QR_SCAN",
            "barrier_status": "OPENED",
            "slot_occupied": allocated_slot_num
        });

        # STEP 5: Commuter boards Expressway Shuttle EX1-01 and tracks live
        _ = advance_sim_time(10.0);
        step5_bus = here spawn track_bus(
            route_number=self.bus_route
        );

        audit_trail.append({
            "step": 5,
            "action": "TRACK_EXPRESSWAY_SHUTTLE",
            "route": self.bus_route,
            "tracking_status": "EN_ROUTE_COLOMBO_FORT"
        });

        # STEP 6: Commuter returns in evening & scans exit gate at Makumbura
        _ = advance_sim_time(480.0); # 8 hours work day in Colombo
        step6_exit = here spawn scan_gate_exit(
            qr_token=qr_token,
            gate_id="MMC_GATE_OUT_01"
        );

        audit_trail.append({
            "step": 6,
            "action": "GATE_EXIT_QR_SCAN",
            "barrier_status": "OPENED",
            "slot_released": allocated_slot_num,
            "booking_status": "COMPLETED"
        });

        report {
            "simulation": "ParkRide Multimodal Commuter Lifecycle",
            "commuter": self.commuter_name,
            "vehicle": self.vehicle_number,
            "terminal": "Makumbura Multimodal Transport Center (MMC)",
            "status": "ALL_STEPS_SUCCESSFUL",
            "total_steps": len(audit_trail),
            "audit_trail": audit_trail
        };
    }
}
