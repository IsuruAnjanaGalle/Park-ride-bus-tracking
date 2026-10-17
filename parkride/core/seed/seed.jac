"""Graph initialization and seeding walker for ParkRide transit & parking network."""

import json;
import from pathlib { Path }
import from core.models.nodes {
    SystemHub,
    TerminalNode,
    StopNode,
    ParkingSlotNode,
    BusNode,
    SlotType,
    SlotStatus,
    BusStatus
}
import from core.models.edges {
    RoadEdge,
    TerminalSlotEdge,
    BusAtStopEdge,
    SystemEdge
}

walker seed_graph {
    has data_dir: str = "";

    can run with Root entry {
        # Check if already seeded
        existing_hubs = [here ->:SystemEdge:-> [?:SystemHub]];
        if len(existing_hubs) > 0 {
            report {
                "status": "already_seeded",
                "message": "Graph already contains SystemHub"
            };
            disengage;
        }

        # Resolve data directory
        base_path = Path("core/seed/data");
        if self.data_dir != "" {
            base_path = Path(self.data_dir);
        }

        # 1. Create SystemHub
        hub = here ++> SystemHub(
            name="ParkRide Western Province Central Hub",
            version="1.0.0"
        );

        # 2. Load Stops & Terminals
        stops_file = base_path / "stops.json";
        stops_map: dict[str, StopNode] = {};
        terminals_map: dict[str, TerminalNode] = {};

        with open(stops_file, "r", encoding="utf-8") as f {
            stops_raw = json.load(f);
            for item in stops_raw {
                stop = hub ++> StopNode(
                    id=item["id"],
                    name=item["name"],
                    code=item["code"],
                    latitude=float(item["latitude"]),
                    longitude=float(item["longitude"]),
                    is_terminal=bool(item.get("is_terminal", False)),
                    zone=item.get("zone", "Zone 1")
                );
                stops_map[stop.id] = stop;

                if stop.is_terminal {
                    terminal = hub ++> TerminalNode(
                        id=stop.id,
                        name=stop.name,
                        code=stop.code,
                        latitude=stop.latitude,
                        longitude=stop.longitude,
                        city=item.get("city", "Colombo"),
                        total_slots=int(item.get("total_slots", 0)),
                        available_slots=int(item.get("available_slots", 0))
                    );
                    terminals_map[terminal.id] = terminal;
                }
            }
        }

        # 3. Load Parking Slots
        slots_file = base_path / "slots.json";
        with open(slots_file, "r", encoding="utf-8") as f {
            slots_raw = json.load(f);
            for item in slots_raw {
                tid = item["terminal_id"];
                if tid in terminals_map {
                    t_node = terminals_map[tid];
                    st_str = item.get("slot_type", "standard");
                    slot_type = SlotType.STANDARD;
                    if st_str == "ev" {
                        slot_type = SlotType.EV;
                    } elif st_str == "handicap" {
                        slot_type = SlotType.HANDICAP;
                    } elif st_str == "motorcycle" {
                        slot_type = SlotType.MOTORCYCLE;
                    }

                    ss_str = item.get("status", "available");
                    slot_status = SlotStatus.AVAILABLE;
                    if ss_str == "reserved" {
                        slot_status = SlotStatus.RESERVED;
                    } elif ss_str == "occupied" {
                        slot_status = SlotStatus.OCCUPIED;
                    } elif ss_str == "maintenance" {
                        slot_status = SlotStatus.MAINTENANCE;
                    }

                    dist_walk = float(item.get("distance_to_exit_m", 30.0));
                    _ = t_node +>:TerminalSlotEdge(walking_distance_m=dist_walk):+> ParkingSlotNode(
                        id=item["id"],
                        terminal_id=tid,
                        slot_number=item["slot_number"],
                        slot_type=slot_type,
                        status=slot_status,
                        floor_or_zone=item.get("floor_or_zone", "Zone A"),
                        distance_to_exit_m=dist_walk
                    );
                }
            }
        }

        # 4. Load Road Network
        roads_file = base_path / "roads.json";
        roads_count = 0;
        with open(roads_file, "r", encoding="utf-8") as f {
            roads_raw = json.load(f);
            for r in roads_raw {
                from_id = r["from_stop_id"];
                to_id = r["to_stop_id"];
                if from_id in stops_map and to_id in stops_map {
                    u_node = stops_map[from_id];
                    v_node = stops_map[to_id];
                    u_node +>:RoadEdge(
                        road_name=r["road_name"],
                        distance_km=float(r["distance_km"]),
                        base_travel_time_min=float(r["base_travel_time_min"]),
                        current_travel_time_min=float(r["current_travel_time_min"]),
                        congestion_factor=float(r.get("congestion_factor", 1.0)),
                        is_expressway=bool(r.get("is_expressway", False))
                    ):+> v_node;
                    roads_count += 1;
                }
            }
        }

        # 5. Load Buses
        buses_file = base_path / "buses.json";
        buses_count = 0;
        with open(buses_file, "r", encoding="utf-8") as f {
            buses_raw = json.load(f);
            for b in buses_raw {
                bus_stat = BusStatus.ON_ROUTE;
                bs_str = b.get("status", "on_route");
                if bs_str == "at_stop" {
                    bus_stat = BusStatus.AT_STOP;
                } elif bs_str == "delayed" {
                    bus_stat = BusStatus.DELAYED;
                } elif bs_str == "out_of_service" {
                    bus_stat = BusStatus.OUT_OF_SERVICE;
                }

                bus = hub ++> BusNode(
                    id=b["id"],
                    route_number=b["route_number"],
                    plate_number=b["plate_number"],
                    capacity=int(b.get("capacity", 50)),
                    current_passengers=int(b.get("current_passengers", 0)),
                    status=bus_stat,
                    current_stop_id=b.get("current_stop_id", ""),
                    next_stop_id=b.get("next_stop_id", ""),
                    speed_kmh=float(b.get("speed_kmh", 40.0)),
                    latitude=float(b.get("latitude", 0.0)),
                    longitude=float(b.get("longitude", 0.0)),
                    heading_deg=float(b.get("heading_deg", 0.0))
                );

                # Connect to current stop if available
                cur_stop_id = bus.current_stop_id;
                if cur_stop_id in stops_map {
                    bus +>:BusAtStopEdge():+> stops_map[cur_stop_id];
                }
                buses_count += 1;
            }
        }

        report {
            "status": "success",
            "message": "ParkRide graph seeded successfully",
            "stops_loaded": len(stops_map),
            "terminals_loaded": len(terminals_map),
            "roads_loaded": roads_count,
            "buses_loaded": buses_count
        };
    }
}
