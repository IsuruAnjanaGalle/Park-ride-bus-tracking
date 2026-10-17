"""Graph edge definitions linking ParkRide nodes."""

import from core.models.nodes {
    StopNode,
    TerminalNode,
    ParkingSlotNode,
    BusNode,
    BookingNode,
    SystemHub
}

edge RoadEdge: StopNode --> StopNode {
    has road_name: str;
    has distance_km: float;
    has base_travel_time_min: float;
    has current_travel_time_min: float;
    has congestion_factor: float = 1.0;
    has is_expressway: bool = False;
}

edge TerminalSlotEdge: TerminalNode --> ParkingSlotNode {
    has walking_distance_m: float = 30.0;
}

edge RouteStopEdge: StopNode --> StopNode {
    has route_number: str;
    has stop_order: int;
    has avg_wait_time_min: float = 5.0;
}

edge BusAtStopEdge: BusNode --> StopNode {
    has arrival_time: str = "";
}

edge TerminalBookingEdge: TerminalNode --> BookingNode {
    has created_at: str = "";
}

edge SystemEdge: SystemHub --> any {}
