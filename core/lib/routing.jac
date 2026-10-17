"""Traffic-aware routing (SOW 9.6): Dijkstra on travel minutes.

minutes = km / (class speed x level factor) x 60; A 30, B 22, E 60 km/h; factors 1, 0.55, 0.25;
level 3 (closed) cannot be entered. Planning runs on a plain adjacency dict built from the
Road edges once per call site (Adj: code -> {neighbour code -> [km, cls, level]}).
"""

import heapq;
import from core.models.nodes { World, Junction }
import from core.models.edges { Road }
import from core.lib.world { get_junctions }
import from core.lib.static { static_roads, road_key }

glob SPEED: dict[str, float] = {"A": 30.0, "B": 22.0, "E": 60.0};
glob FACTOR: list[float] = [1.0, 0.55, 0.25, 0.0];
glob CRAWL_KMH: float = 5.0;
glob INF: float = 1.0e9;

"""Driving speed on a road now (a bus already on a closed road crawls at 5 km/h)."""
def road_kmh(cls: str, level: int) -> float {
    f = FACTOR[level] if 0 <= level <= 3 else 1.0;
    return SPEED.get(cls, 30.0) * f if f > 0 else CRAWL_KMH;
}

"""Minutes to drive a whole road at a level, INF if closed."""
def cost_minutes(km: float, cls: str, level: int) -> float {
    if level >= 3 {
        return INF;
    }
    return km / road_kmh(cls, level) * 60.0;
}

"""Adjacency of the road graph with current levels."""
def build_adj(world: World) -> dict[str, dict[str, list[any]]] {
    levels = world.road_levels;
    adj: dict[str, dict[str, list[any]]] = {};
    for (a, outs) in static_roads().items() {
        adj[a] = {b: [v[0], v[1], levels.get(road_key(a, b), 0)] for (b, v) in outs.items()};
    }
    return adj;
}

"""Fastest path from start to goal: (junction codes, minutes); ([], INF) when no open road."""
def plan_route(adj: dict[str, dict[str, list[any]]], start: str, goal: str) -> tuple[list[str], float] {
    if start == goal {
        return ([start], 0.0);
    }
    dist: dict[str, float] = {start: 0.0};
    prev: dict[str, str] = {};
    heap: list[tuple[float, str]] = [(0.0, start)];
    while heap {
        (d, u) = heapq.heappop(heap);
        if u == goal {
            break;
        }
        if d > dist.get(u, INF) {
            continue;
        }
        for (v, info) in adj.get(u, {}).items() {
            c = cost_minutes(info[0], info[1], info[2]);
            if c >= INF {
                continue;
            }
            nd = d + c;
            if nd < dist.get(v, INF) {
                dist[v] = nd;
                prev[v] = u;
                heapq.heappush(heap, (nd, v));
            }
        }
    }
    if goal not in dist {
        return ([], INF);
    }
    path = [goal];
    while path[-1] != start {
        path.append(prev[path[-1]]);
    }
    return (list(reversed(path)), round(dist[goal], 2));
}

"""Minutes to drive a path at current levels (INF if a road is closed or missing)."""
def path_cost(adj: dict[str, dict[str, list[any]]], path: list[str]) -> float {
    total = 0.0;
    for i in range(len(path) - 1) {
        info = adj.get(path[i], {}).get(path[i + 1]);
        if info is None {
            return INF;
        }
        c = cost_minutes(info[0], info[1], info[2]);
        if c >= INF {
            return INF;
        }
        total += c;
    }
    return round(total, 2);
}

"""Set a road's level in both directions. Returns False if there is no such road."""
def set_road_level(world: World, a: str, b: str, level: int) -> bool {
    if b not in static_roads().get(a, {}) {
        return False;
    }
    levels = dict(world.road_levels);
    if level == 0 {
        levels.pop(road_key(a, b), None);
    } else {
        levels[road_key(a, b)] = level;
    }
    world.road_levels = levels;
    found = False;
    for j in get_junctions(world) {
        if j.code != a and j.code != b {
            continue;
        }
        for e in [edge j ->:Road:->] {
            if (e.a == a and e.b == b) or (e.a == b and e.b == a) {
                e.level = level;
                found = True;
            }
        }
    }
    return found;
}

"""Every road back to level 0 (free)."""
def clear_roads(world: World) -> None {
    world.road_levels = {};
    for j in get_junctions(world) {
        for e in [edge j ->:Road:->] {
            e.level = 0;
        }
    }
}
