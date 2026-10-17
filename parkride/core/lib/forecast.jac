"""Demand forecasting and transit arrival estimation algorithms for ParkRide."""

import from core.models.nodes {
    BusNode,
    StopNode
}

def calculate_bus_arrival_eta(
    bus_speed_kmh: float,
    distance_km: float,
    congestion_factor: float = 1.0,
    intermediate_stops: int = 0
) -> float {
    # Effective speed considering traffic congestion
    effective_speed = max(bus_speed_kmh / max(congestion_factor, 0.5), 10.0);
    travel_time_hours = distance_km / effective_speed;
    travel_time_minutes = travel_time_hours * 60.0;
    # Each intermediate stop adds average 1.5 minutes dwell time
    dwell_time_minutes = intermediate_stops * 1.5;
    return round(travel_time_minutes + dwell_time_minutes, 1);
}

def forecast_terminal_occupancy(total_slots: int, hour_of_day: int) -> dict[str, float] {
    # Colombo Multimodal P&R diurnal demand profile
    rate = 0.15;
    if 6 <= hour_of_day < 7 {
        rate = 0.35;
    } elif 7 <= hour_of_day < 9 {
        # Morning peak arrival
        rate = 0.88;
    } elif 9 <= hour_of_day < 12 {
        rate = 0.92;
    } elif 12 <= hour_of_day < 16 {
        rate = 0.85;
    } elif 16 <= hour_of_day < 19 {
        # Evening departures
        rate = 0.60;
    } elif 19 <= hour_of_day < 22 {
        rate = 0.30;
    } else {
        rate = 0.12;
    }

    predicted_occupied = round(total_slots * rate);
    predicted_available = max(total_slots - predicted_occupied, 0);

    return {
        "occupancy_rate": rate,
        "predicted_occupied": float(predicted_occupied),
        "predicted_available": float(predicted_available)
    };
}
