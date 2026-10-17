"""Walkers for real-time bus tracking, telemetry, and fleet operations."""

import from core.models.nodes {
    BusNode,
    StopNode,
    BusStatus
}
import from core.models.edges {
    BusAtStopEdge,
    RoadEdge,
    SystemEdge
}
import from core.lib.forecast { calculate_bus_arrival_eta }

walker track_bus {
    has bus_id: str = "";
    has route_number: str = "";

    can run with Root entry {
        buses = [here ->:SystemEdge:-> [?:BusNode]];
        if len(buses) == 0 {
            buses = [here --> [?:BusNode]];
        }

        matched: list[BusNode] = [];
        for b in buses {
            if self.bus_id != "" and b.id == self.bus_id {
                matched.append(b);
                break;
            } elif self.route_number != "" and b.route_number == self.route_number {
                matched.append(b);
            }
        }

        if len(matched) == 0 {
            report {
                "status": "not_found",
                "message": f"Bus matching id '{self.bus_id}' or route '{self.route_number}' not found",
                "telemetry": None
            };
            disengage;
        }

        results: list[dict[str, any]] = [];
        for bus in matched {
            # Calculate remaining ETA to next stop
            eta_min = 0.0;
            if bus.speed_kmh > 0 {
                # Typical remaining distance to next stop
                eta_min = calculate_bus_arrival_eta(bus.speed_kmh, 4.5, 1.1, 0);
            }

            occupancy_percent = round((bus.current_passengers / max(bus.capacity, 1)) * 100.0, 1);

            results.append({
                "bus_id": bus.id,
                "route_number": bus.route_number,
                "plate_number": bus.plate_number,
                "status": bus.status,
                "latitude": bus.latitude,
                "longitude": bus.longitude,
                "heading_deg": bus.heading_deg,
                "speed_kmh": bus.speed_kmh,
                "capacity": bus.capacity,
                "current_passengers": bus.current_passengers,
                "occupancy_percent": occupancy_percent,
                "current_stop_id": bus.current_stop_id,
                "next_stop_id": bus.next_stop_id,
                "estimated_arrival_minutes": eta_min
            });
        }

        report {
            "status": "success",
            "count": len(results),
            "telemetry": results
        };
    }
}

walker update_bus_position {
    has bus_id: str;
    has latitude: float;
    has longitude: float;
    has heading_deg: float = 0.0;
    has speed_kmh: float = 40.0;
    has current_stop_id: str = "";
    has next_stop_id: str = "";
    has passengers_delta: int = 0;

    can run with Root entry {
        buses = [here ->:SystemEdge:-> [?:BusNode]];
        if len(buses) == 0 {
            buses = [here --> [?:BusNode]];
        }

        target_bus: BusNode | None = None;
        for b in buses {
            if b.id == self.bus_id {
                target_bus = b;
                break;
            }
        }

        if target_bus is None {
            report {
                "status": "not_found",
                "message": f"Bus '{self.bus_id}' not found"
            };
            disengage;
        }

        target_bus.latitude = self.latitude;
        target_bus.longitude = self.longitude;
        target_bus.heading_deg = self.heading_deg;
        target_bus.speed_kmh = self.speed_kmh;

        if self.current_stop_id != "" {
            target_bus.current_stop_id = self.current_stop_id;
        }
        if self.next_stop_id != "" {
            target_bus.next_stop_id = self.next_stop_id;
        }

        new_count = target_bus.current_passengers + self.passengers_delta;
        target_bus.current_passengers = max(0, min(new_count, target_bus.capacity));

        report {
            "status": "updated",
            "bus_id": target_bus.id,
            "latitude": target_bus.latitude,
            "longitude": target_bus.longitude,
            "speed_kmh": target_bus.speed_kmh,
            "current_passengers": target_bus.current_passengers
        };
    }
}

walker get_fleet_status {
    can run with Root entry {
        buses = [here ->:SystemEdge:-> [?:BusNode]];
        if len(buses) == 0 {
            buses = [here --> [?:BusNode]];
        }

        total_passengers = 0;
        total_capacity = 0;
        active_buses = 0;
        fleet_list: list[dict[str, any]] = [];

        for b in buses {
            if b.status == BusStatus.ON_ROUTE or b.status == BusStatus.AT_STOP {
                active_buses += 1;
            }
            total_passengers += b.current_passengers;
            total_capacity += b.capacity;

            fleet_list.append({
                "bus_id": b.id,
                "route_number": b.route_number,
                "plate_number": b.plate_number,
                "status": b.status,
                "current_passengers": b.current_passengers,
                "capacity": b.capacity,
                "speed_kmh": b.speed_kmh,
                "current_stop_id": b.current_stop_id,
                "next_stop_id": b.next_stop_id
            });
        }

        fleet_occupancy_rate = 0.0;
        if total_capacity > 0 {
            fleet_occupancy_rate = round((total_passengers / total_capacity) * 100.0, 1);
        }

        report {
            "status": "success",
            "total_buses": len(buses),
            "active_buses": active_buses,
            "total_passengers": total_passengers,
            "total_capacity": total_capacity,
            "fleet_occupancy_rate_percent": fleet_occupancy_rate,
            "fleet": fleet_list
        };
    }
}
