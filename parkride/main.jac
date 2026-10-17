"""ParkRide - Production-Grade Multimodal Park & Ride Bus Tracking System.

Main application entry point orchestrating graph models, walkers, and runtime services.
"""

import from core.models.nodes {
    SystemHub,
    TerminalNode,
    StopNode,
    ParkingSlotNode,
    BusNode,
    BookingNode
}
import from core.models.edges {
    RoadEdge,
    TerminalSlotEdge,
    BusAtStopEdge,
    TerminalBookingEdge,
    SystemEdge
}
import from core.seed.seed { seed_graph }
import from core.lib.clock { get_current_time_iso }
import from core.walkers.parking { check_parking_availability, find_available_slot }
import from core.walkers.booking { create_booking, cancel_booking }
import from core.walkers.scans { scan_gate_entry, scan_gate_exit }
import from core.walkers.routing { find_multimodal_route }
import from core.walkers.traffic { update_road_traffic, get_traffic_feed }
import from core.walkers.buses { track_bus, update_bus_position, get_fleet_status }
import from core.walkers.admin { get_system_overview, override_slot_status }
import from core.walkers.demo { run_demo_simulation }

with entry {
    print("==================================================================");
    print("      PARKRIDE MULTIMODAL TRANSIT & SMART PARKING SYSTEM          ");
    print("         Western Province / Colombo Transit Corridor              ");
    print("==================================================================");
    print(f"System Boot: {get_current_time_iso()}");

    # Automatically seed graph if not initialized
    seed_result = root spawn seed_graph();
    if seed_result.reports and len(seed_result.reports) > 0 {
        rep = seed_result.reports[0];
        print(f"Graph Status: {rep.get('message', 'Ready')}");
        if rep.get("stops_loaded", 0) > 0 {
            print(f"Loaded {rep.get('stops_loaded')} stops, {rep.get('terminals_loaded')} terminals, {rep.get('buses_loaded')} buses.");
        }
    }

    # Run system overview
    overview = root spawn get_system_overview();
    if overview.reports and len(overview.reports) > 0 {
        stats = overview.reports[0];
        p_stats = stats.get("parking", {});
        print(f"Active Terminals: {stats.get('terminals_count')}");
        print(f"Parking Bays: {p_stats.get('total_slots')} total, {p_stats.get('available_slots')} available");
    }
    print("==================================================================");
    print("Services active: Booking, QR Scanner, Bus Telemetry, Routing.");
}
