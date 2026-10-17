"""Test suite covering core models, algorithms, walkers, and end-to-end flows."""

import from core.models.nodes {
    SlotType,
    SlotStatus,
    BusStatus,
    BookingStatus,
    ParkingSlotNode,
    StopNode,
    TerminalNode
}
import from core.models.edges {
    RoadEdge,
    TerminalSlotEdge,
    TerminalBookingEdge
}
import from core.lib.qr_sign {
    generate_qr_token,
    verify_qr_token
}
import from core.lib.clock {
    get_current_time_iso,
    get_current_epoch,
    advance_sim_time
}
import from core.lib.allocation {
    find_best_slot,
    calculate_occupancy_stats
}
import from core.lib.forecast {
    calculate_bus_arrival_eta,
    forecast_terminal_occupancy
}
import from core.lib.dijkstra { find_shortest_path }
import from core.seed.seed { seed_graph }
import from core.walkers.parking { check_parking_availability, find_available_slot }
import from core.walkers.booking { create_booking, cancel_booking }
import from core.walkers.scans { scan_gate_entry, scan_gate_exit }
import from core.walkers.buses { track_bus, get_fleet_status }
import from core.walkers.admin { get_system_overview }
import from core.walkers.demo { run_demo_simulation }

test "slot and bus enum values" {
    assert SlotType.STANDARD == "standard";
    assert SlotType.EV == "ev";
    assert SlotStatus.AVAILABLE == "available";
    assert SlotStatus.OCCUPIED == "occupied";
    assert BusStatus.ON_ROUTE == "on_route";
    assert BookingStatus.CONFIRMED == "confirmed";
}

test "qr token generation and tamper detection" {
    token = generate_qr_token(
        booking_id="bk_test123",
        vehicle_number="WP-CAA-1122",
        terminal_id="stop_makumbura",
        slot_id="slot_mmc_a01",
        valid_hours=2.0
    );

    assert "." in token;
    parts = token.split(".");
    assert len(parts) == 2;

    # Verify authentic token
    res = verify_qr_token(token);
    assert res["valid"] == True;
    payload = res["payload"];
    assert payload["booking_id"] == "bk_test123";
    assert payload["vehicle_number"] == "WP-CAA-1122";

    # Tampered signature detection
    tampered_token = parts[0] + ".deadbeefbadsignature";
    tampered_res = verify_qr_token(tampered_token);
    assert tampered_res["valid"] == False;
    assert "Invalid cryptographic signature" in tampered_res["reason"];
}

test "simulated clock operations" {
    t_start = get_current_epoch();
    iso1 = get_current_time_iso();
    assert len(iso1) > 10;

    _ = advance_sim_time(30.0);
    t_after = get_current_epoch();
    assert t_after >= t_start + 1800.0;
}

test "smart parking slot allocation and stats" {
    slot1 = ParkingSlotNode(
        id="s1",
        terminal_id="t1",
        slot_number="A-01",
        slot_type=SlotType.STANDARD,
        status=SlotStatus.AVAILABLE,
        distance_to_exit_m=50.0
    );
    slot2 = ParkingSlotNode(
        id="s2",
        terminal_id="t1",
        slot_number="A-02",
        slot_type=SlotType.STANDARD,
        status=SlotStatus.AVAILABLE,
        distance_to_exit_m=15.0
    );
    slot3 = ParkingSlotNode(
        id="s3",
        terminal_id="t1",
        slot_number="EV-01",
        slot_type=SlotType.EV,
        status=SlotStatus.AVAILABLE,
        distance_to_exit_m=25.0
    );

    slots = [slot1, slot2, slot3];

    # Allocation nearest exit
    best_std = find_best_slot(slots, SlotType.STANDARD, prefer_near_exit=True);
    assert best_std is not None;
    assert best_std.slot_number == "A-02";

    # EV allocation
    best_ev = find_best_slot(slots, SlotType.EV, prefer_near_exit=True);
    assert best_ev is not None;
    assert best_ev.slot_number == "EV-01";

    # Occupancy statistics
    stats = calculate_occupancy_stats(slots);
    assert stats["total"] == 3;
    assert stats["available"] == 3;
    assert stats["ev_available"] == 1;
}

test "forecast calculations" {
    # 20km expressway at 60km/h with 1.0 congestion
    eta = calculate_bus_arrival_eta(60.0, 20.0, 1.0, 0);
    assert eta == 20.0;

    # Peak hour parking forecast
    morning_peak = forecast_terminal_occupancy(100, 8);
    assert morning_peak["occupancy_rate"] == 0.88;
    assert morning_peak["predicted_occupied"] == 88.0;

    night_calm = forecast_terminal_occupancy(100, 23);
    assert night_calm["occupancy_rate"] == 0.12;
}

test "dijkstra shortest transit path" {
    s1 = StopNode(id="stop1", name="Origin Station", code="S1", latitude=6.8, longitude=79.9);
    s2 = StopNode(id="stop2", name="Midpoint Station", code="S2", latitude=6.85, longitude=79.88);
    s3 = StopNode(id="stop3", name="Destination Terminal", code="S3", latitude=6.9, longitude=79.85);

    # Connect roads: s1 -> s2 (10 min), s2 -> s3 (15 min), direct s1 -> s3 (35 min)
    _ = s1 +>:RoadEdge(
        road_name="Local Link A",
        distance_km=5.0,
        base_travel_time_min=10.0,
        current_travel_time_min=10.0
    ):+> s2;

    _ = s2 +>:RoadEdge(
        road_name="Local Link B",
        distance_km=8.0,
        base_travel_time_min=15.0,
        current_travel_time_min=15.0
    ):+> s3;

    _ = s1 +>:RoadEdge(
        road_name="Slow Direct",
        distance_km=14.0,
        base_travel_time_min=35.0,
        current_travel_time_min=35.0
    ):+> s3;

    all_s = [s1, s2, s3];
    path = find_shortest_path(s1, s3, all_s, "travel_time");
    assert path["found"] == True;
    assert path["total_travel_time_min"] == 25.0;
    assert len(path["path_ids"]) == 3;
    assert path["path_ids"] == ["stop1", "stop2", "stop3"];
}

test "end-to-end demo walker simulation" {
    # Seed graph
    seed_res = root spawn seed_graph();
    assert len(seed_res.reports) > 0;

    # Run complete commuter lifecycle demo
    demo_res = root spawn run_demo_simulation();
    assert len(demo_res.reports) > 0;
    rep = demo_res.reports[0];
    assert rep["status"] == "ALL_STEPS_SUCCESSFUL";
    assert rep["total_steps"] == 6;

    # System overview verification
    overview = root spawn get_system_overview();
    assert len(overview.reports) > 0;
    ov_rep = overview.reports[0];
    assert ov_rep["status"] == "healthy";
}
