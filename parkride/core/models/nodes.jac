"""Data models and graph nodes for ParkRide system."""

enum SlotType: str {
    STANDARD = "standard",
    EV = "ev",
    HANDICAP = "handicap",
    MOTORCYCLE = "motorcycle"
}

enum SlotStatus: str {
    AVAILABLE = "available",
    RESERVED = "reserved",
    OCCUPIED = "occupied",
    MAINTENANCE = "maintenance"
}

enum BusStatus: str {
    ON_ROUTE = "on_route",
    AT_STOP = "at_stop",
    DELAYED = "delayed",
    OUT_OF_SERVICE = "out_of_service"
}

enum BookingStatus: str {
    PENDING = "pending",
    CONFIRMED = "confirmed",
    CHECKED_IN = "checked_in",
    COMPLETED = "completed",
    CANCELLED = "cancelled"
}

node SystemHub {
    has name: str = "ParkRide Central Hub";
    has version: str = "1.0.0";
    has created_at: str = "";
}

node TerminalNode {
    has id: str;
    has name: str;
    has code: str;
    has latitude: float;
    has longitude: float;
    has city: str = "Colombo";
    has total_slots: int = 0;
    has available_slots: int = 0;
}

node StopNode {
    has id: str;
    has name: str;
    has code: str;
    has latitude: float;
    has longitude: float;
    has is_terminal: bool = False;
    has zone: str = "Zone 1";
}

node ParkingSlotNode {
    has id: str;
    has terminal_id: str;
    has slot_number: str;
    has slot_type: SlotType = SlotType.STANDARD;
    has status: SlotStatus = SlotStatus.AVAILABLE;
    has floor_or_zone: str = "Zone A";
    has distance_to_exit_m: float = 50.0;
    has current_reservation_id: str = "";
    has updated_at: str = "";
}

node BusNode {
    has id: str;
    has route_number: str;
    has plate_number: str;
    has capacity: int = 50;
    has current_passengers: int = 0;
    has status: BusStatus = BusStatus.ON_ROUTE;
    has current_stop_id: str = "";
    has next_stop_id: str = "";
    has speed_kmh: float = 40.0;
    has latitude: float = 0.0;
    has longitude: float = 0.0;
    has heading_deg: float = 0.0;
}

node BookingNode {
    has id: str;
    has user_id: str;
    has user_phone: str;
    has vehicle_number: str;
    has terminal_id: str;
    has slot_id: str;
    has bus_route: str = "";
    has status: BookingStatus = BookingStatus.PENDING;
    has start_time: str = "";
    has end_time: str = "";
    has qr_token: str = "";
    has fare_lkr: float = 0.0;
    has check_in_time: str = "";
    has check_out_time: str = "";
}

node TrafficReportNode {
    has id: str;
    has road_name: str;
    has from_stop_id: str;
    has to_stop_id: str;
    has congestion_level: str = "normal";
    has delay_minutes: float = 0.0;
    has reported_at: str = "";
}
