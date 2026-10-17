"""Static road-network facts (names, coordinates, road geometry) cached from docs/data once per process.

Only traffic levels change at run time; they live on World.road_levels. Reading the static part
from this cache instead of the graph keeps every 2-second poll cheap.
"""

import from core.seed.seed { load_json }

glob _CACHE: dict[str, any] = {};

def _net -> dict[str, any] {
    if not _CACHE {
        net = load_json("road-network.json");
        _CACHE["names"] = {j["code"]: j["name"] for j in net["junctions"]};
        _CACHE["coords"] = {j["code"]: [j["lat"], j["lng"]] for j in net["junctions"]};
        base: dict[str, dict[str, list[any]]] = {j["code"]: {} for j in net["junctions"]};
        for r in net["roads"] {
            base[r["from"]][r["to"]] = [float(r["km"]), r["cls"]];
            base[r["to"]][r["from"]] = [float(r["km"]), r["cls"]];
        }
        _CACHE["base"] = base;
    }
    return _CACHE;
}

"""Junction code -> name."""
def static_names -> dict[str, str] {
    return _net()["names"];
}

"""Junction code -> [lat, lng]."""
def static_coords -> dict[str, list[float]] {
    return _net()["coords"];
}

"""Junction code -> {neighbour -> [km, cls]} for every road, both directions."""
def static_roads -> dict[str, dict[str, list[any]]] {
    return _net()["base"];
}

"""Key of a two-way road: the two codes sorted, joined by '|'."""
def road_key(a: str, b: str) -> str {
    return f"{a}|{b}" if a < b else f"{b}|{a}";
}
