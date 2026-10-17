"""Walkers for live traffic updates and congestion monitoring."""

import from core.models.nodes {
    StopNode,
    TrafficReportNode
}
import from core.models.edges {
    RoadEdge,
    SystemEdge
}
import from core.lib.clock { get_current_time_iso }

walker update_road_traffic {
    has from_stop_id: str;
    has to_stop_id: str;
    has congestion_factor: float = 1.0;
    has delay_minutes: float = 0.0;

    can run with Root entry {
        stops = [here ->:SystemEdge:-> [?:StopNode]];
        if len(stops) == 0 {
            stops = [here --> [?:StopNode]];
        }

        u_node: StopNode | None = None;
        v_node: StopNode | None = None;

        for s in stops {
            if s.id == self.from_stop_id {
                u_node = s;
            }
            if s.id == self.to_stop_id {
                v_node = s;
            }
        }

        if u_node is None or v_node is None {
            report {
                "status": "not_found",
                "message": f"Stops not found for road segment {self.from_stop_id} -> {self.to_stop_id}"
            };
            disengage;
        }

        road_edges = [edge u_node ->:RoadEdge:-> v_node];
        if len(road_edges) == 0 {
            report {
                "status": "no_edge",
                "message": f"No road connection found from {u_node.name} to {v_node.name}"
            };
            disengage;
        }

        road = road_edges[0];
        road.congestion_factor = self.congestion_factor;
        new_time = (road.base_travel_time_min * self.congestion_factor) + self.delay_minutes;
        road.current_travel_time_min = round(new_time, 1);

        now_str = get_current_time_iso();

        report {
            "status": "updated",
            "road_name": road.road_name,
            "from_stop": u_node.name,
            "to_stop": v_node.name,
            "distance_km": road.distance_km,
            "base_travel_time_min": road.base_travel_time_min,
            "current_travel_time_min": road.current_travel_time_min,
            "congestion_factor": road.congestion_factor,
            "updated_at": now_str
        };
    }
}

walker get_traffic_feed {
    can run with Root entry {
        stops = [here ->:SystemEdge:-> [?:StopNode]];
        if len(stops) == 0 {
            stops = [here --> [?:StopNode]];
        }

        feed: list[dict[str, any]] = [];

        for s in stops {
            neighbors = [s ->:RoadEdge:->];
            for nbr in neighbors {
                edges = [edge s ->:RoadEdge:-> nbr];
                if len(edges) > 0 {
                    r = edges[0];
                    congestion_tag = "normal";
                    if r.congestion_factor >= 1.5 {
                        congestion_tag = "heavy";
                    } elif r.congestion_factor > 1.2 {
                        congestion_tag = "moderate";
                    }
                    feed.append({
                        "from_stop_id": s.id,
                        "from_stop_name": s.name,
                        "to_stop_id": nbr.id,
                        "to_stop_name": nbr.name,
                        "road_name": r.road_name,
                        "distance_km": r.distance_km,
                        "travel_time_min": r.current_travel_time_min,
                        "congestion_factor": r.congestion_factor,
                        "congestion_level": congestion_tag,
                        "is_expressway": r.is_expressway
                    });
                }
            }
        }

        report {
            "status": "success",
            "total_segments": len(feed),
            "feed": feed
        };
    }
}
