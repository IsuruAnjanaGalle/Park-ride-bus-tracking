"""Multimodal routing and itinerary generation walker."""

import from core.models.nodes {
    StopNode,
    TerminalNode
}
import from core.models.edges {
    RoadEdge,
    SystemEdge
}
import from core.lib.dijkstra { find_shortest_path }

walker find_multimodal_route {
    has origin_stop_id: str;
    has destination_stop_id: str;
    has optimize_by: str = "travel_time";
    has include_parking_transfer: bool = True;

    can run with Root entry {
        # Collect all stops
        all_stops = [here ->:SystemEdge:-> [?:StopNode]];
        if len(all_stops) == 0 {
            all_stops = [here --> [?:StopNode]];
        }

        origin: StopNode | None = None;
        target: StopNode | None = None;

        for s in all_stops {
            if s.id == self.origin_stop_id {
                origin = s;
            }
            if s.id == self.destination_stop_id {
                target = s;
            }
        }

        if origin is None or target is None {
            report {
                "status": "not_found",
                "message": f"Could not find origin ({self.origin_stop_id}) or destination ({self.destination_stop_id})",
                "route": None
            };
            disengage;
        }

        # Execute Dijkstra shortest path
        path_res = find_shortest_path(origin, target, all_stops, self.optimize_by);

        if not path_res.get("found", False) {
            report {
                "status": "unreachable",
                "message": f"No connected transit route between {origin.name} and {target.name}",
                "route": None
            };
            disengage;
        }

        # Check for Park & Ride transfer potential
        park_and_ride_terminal: str = "";
        recommended_shuttle: str = "";
        if origin.is_terminal {
            park_and_ride_terminal = origin.name;
            if "makumbura" in origin.id and "fort" in target.id {
                recommended_shuttle = "EX1-01 Expressway Direct Shuttle";
            } elif "kadawatha" in origin.id and "fort" in target.id {
                recommended_shuttle = "EX2-01 Kadawatha - Fort Express";
            }
        }

        report {
            "status": "success",
            "origin": {
                "id": origin.id,
                "name": origin.name,
                "is_terminal": origin.is_terminal
            },
            "destination": {
                "id": target.id,
                "name": target.name,
                "is_terminal": target.is_terminal
            },
            "optimize_by": self.optimize_by,
            "total_distance_km": path_res.get("total_distance_km", 0.0),
            "total_travel_time_min": path_res.get("total_travel_time_min", 0.0),
            "hops_count": len(path_res.get("path_ids", [])) - 1,
            "path_names": path_res.get("path_names", []),
            "legs": path_res.get("legs", []),
            "park_and_ride_terminal": park_and_ride_terminal,
            "recommended_shuttle": recommended_shuttle
        };
    }
}
