"""Dijkstra shortest path algorithm implementation for multimodal transit networks."""

import from core.models.nodes { StopNode }
import from core.models.edges { RoadEdge }

def find_shortest_path(
    start_node: StopNode,
    target_node: StopNode,
    all_stops: list[StopNode],
    optimize_by: str = "travel_time"
) -> dict[str, any] {
    if start_node.id == target_node.id {
        return {
            "found": True,
            "path_ids": [start_node.id],
            "path_names": [start_node.name],
            "total_distance_km": 0.0,
            "total_travel_time_min": 0.0,
            "legs": []
        };
    }

    # Map node id to StopNode
    node_map: dict[str, StopNode] = {};
    for stop in all_stops {
        node_map[stop.id] = stop;
    }
    node_map[start_node.id] = start_node;
    node_map[target_node.id] = target_node;

    # Distances & previous tracking
    distances: dict[str, float] = {};
    previous: dict[str, str] = {};
    edge_used: dict[str, RoadEdge] = {};
    unvisited: set[str] = set();

    for stop_id in node_map.keys() {
        distances[stop_id] = 999999999.0;
        unvisited.add(stop_id);
    }
    distances[start_node.id] = 0.0;

    while len(unvisited) > 0 {
        # Select unvisited node with lowest distance
        curr_id: str = "";
        min_dist: float = 999999999.0;
        for uid in unvisited {
            if distances[uid] < min_dist {
                min_dist = distances[uid];
                curr_id = uid;
            }
        }

        if curr_id == "" or min_dist >= 999999999.0 {
            break;
        }

        if curr_id == target_node.id {
            break;
        }

        unvisited.remove(curr_id);
        curr_node = node_map[curr_id];

        # Explore outgoing RoadEdges
        for neighbor in [curr_node ->:RoadEdge:->] {
            if neighbor.id in unvisited {
                road_edges = [edge curr_node ->:RoadEdge:-> neighbor];
                if len(road_edges) > 0 {
                    road = road_edges[0];
                    weight: float = road.current_travel_time_min;
                    if optimize_by == "distance" {
                        weight = road.distance_km;
                    }

                    alt = distances[curr_id] + weight;
                    if alt < distances[neighbor.id] {
                        distances[neighbor.id] = alt;
                        previous[neighbor.id] = curr_id;
                        edge_used[neighbor.id] = road;
                    }
                }
            }
        }
    }

    if target_node.id not in previous and start_node.id != target_node.id {
        return {
            "found": False,
            "path_ids": [],
            "path_names": [],
            "total_distance_km": 0.0,
            "total_travel_time_min": 0.0,
            "legs": []
        };
    }

    # Reconstruct path from target to start
    path_ids: list[str] = [];
    curr_step = target_node.id;
    while curr_step != "" {
        path_ids.insert(0, curr_step);
        curr_step = previous.get(curr_step, "");
    }

    path_names: list[str] = [];
    legs: list[dict[str, any]] = [];
    total_dist: float = 0.0;
    total_time: float = 0.0;

    for i in range(len(path_ids)) {
        pid = path_ids[i];
        p_node = node_map[pid];
        path_names.append(p_node.name);

        if i > 0 {
            e = edge_used[pid];
            total_dist += e.distance_km;
            total_time += e.current_travel_time_min;
            legs.append({
                "from_stop_id": path_ids[i - 1],
                "to_stop_id": pid,
                "road_name": e.road_name,
                "distance_km": e.distance_km,
                "travel_time_min": e.current_travel_time_min,
                "congestion_factor": e.congestion_factor,
                "is_expressway": e.is_expressway
            });
        }
    }

    return {
        "found": True,
        "path_ids": path_ids,
        "path_names": path_names,
        "total_distance_km": round(total_dist, 2),
        "total_travel_time_min": round(total_time, 2),
        "legs": legs
    };
}
