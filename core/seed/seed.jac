"""Seed the shared world exactly from docs/data/seed.json and docs/data/road-network.json.

Run `jac run core/seed/seed.jac` to check the files load, or press Reset on /dev/core
(reset_demo) to rebuild the served world.
"""

import os;
import json;
import time;
import from core.models.nodes {
    World, DemoClock, Terminal, Slot, Junction, Stop, Route, Bus, Trip, Passenger
}
import from core.models.edges { Road, OnRoute }
import from core.lib.geo { bearing, lerp }

"""Folder holding the seed files; PARKRIDE_DATA_DIR overrides it."""
def data_dir() -> str {
    return os.environ.get("PARKRIDE_DATA_DIR", os.path.join(os.getcwd(), "docs", "data"));
}

def load_json(name: str) -> dict[str, any] {
    with open(os.path.join(data_dir(), name), encoding="utf-8") as fh {
        return json.load(fh);
    }
}

"""Stop codes of a route in the order a bus travelling in `direction` serves them."""
def ordered_stops(stops: list[str], direction: str) -> list[str] {
    return list(reversed(stops)) if direction == "reverse" else list(stops);
}

"""Build every node and edge of the demo world under `world`. Returns counts."""
def seed_world(world: World) -> dict[str, int] {
    seed = load_json("seed.json");
    net = load_json("road-network.json");

    clock_cfg = seed["demo_clock"];
    world ++> DemoClock(
        start=clock_cfg["start"],
        speed=float(clock_cfg["speed"]),
        offset=0.0,
        paused=False,
        anchor_real=time.time()
    );

    junctions: dict[str, Junction] = {};
    for j in net["junctions"] {
        if j["kind"] == "junction" {
            jn = Junction(code=j["code"], name=j["name"], lat=j["lat"], lng=j["lng"], kind="junction");
        } else {
            jn = Stop(
                code=j["code"], name=j["name"], lat=j["lat"], lng=j["lng"],
                kind=j["kind"], is_terminal=(j["kind"] == "terminal")
            );
        }
        world ++> jn;
        junctions[j["code"]] = jn;
    }

    road_count = 0;
    for r in net["roads"] {
        ja = junctions[r["from"]];
        jb = junctions[r["to"]];
        ja +>:Road(a=r["from"], b=r["to"], km=float(r["km"]), cls=r["cls"], level=0):+> jb;
        jb +>:Road(a=r["to"], b=r["from"], km=float(r["km"]), cls=r["cls"], level=0):+> ja;
        road_count += 1;
    }

    routes: dict[str, Route] = {};
    for rt in seed["routes"] {
        codes = [s["code"] for s in rt["stops"]];
        route = Route(id=rt["id"], name=rt["name"], color=rt["color"], stop_codes=codes);
        world ++> route;
        for (seq, code) in enumerate(codes) {
            stop_node = junctions[code];
            if isinstance(stop_node, Stop) {
                route +>:OnRoute(seq=seq):+> stop_node;
            }
        }
        routes[rt["id"]] = route;
    }

    terminals: dict[str, Terminal] = {};
    for t in seed["terminals"] {
        jn = junctions[t["junction"]];
        term = Terminal(
            code=t["code"], name=t["name"], junction=t["junction"],
            lat=jn.lat, lng=jn.lng, full_grid=t["full_grid_in_ui"], chargers=t["chargers"]
        );
        world ++> term;
        terminals[t["code"]] = term;
    }

    slot_count = 0;
    for s in seed["slots"] {
        terminals[s["terminal"]] ++> Slot(
            code=s["code"], terminal=s["terminal"], kind=s["type"], zone=s["zone"],
            nn=s["nn"], state=s["state"], accessible=s["accessible"],
            charger_kw=s.get("charger_kw", 0) or 0, charger_type=s.get("charger_type", "") or ""
        );
        slot_count += 1;
    }

    bus_count = 0;
    for b in seed["buses"] {
        start = b["start"];
        a = junctions[start["from_stop"]];
        z = junctions[start["next_stop"]];
        t = float(start["progress_on_first_road"]);
        bus = Bus(
            id=b["id"], route=b["route"], plate=b["plate"], capacity=b["capacity"],
            driver=b["driver"], conductor=b["conductor"], direction=start["direction"],
            from_stop=start["from_stop"], next_stop=start["next_stop"], progress=t,
            lat=round(lerp(a.lat, z.lat, t), 6), lng=round(lerp(a.lng, z.lng, t), 6),
            heading=bearing(a.lat, a.lng, z.lat, z.lng),
            road_from=start["from_stop"], road_to=start["next_stop"],
            path=[start["from_stop"], start["next_stop"]], state="moving"
        );
        world ++> bus;
        stops = ordered_stops(routes[b["route"]].stop_codes, start["direction"]);
        bus ++> Trip(
            id=f"T-{b['id']}-1", bus_id=b["id"], route=b["route"], direction=start["direction"],
            stop_codes=stops, last_departed=stops.index(start["from_stop"]), status="running"
        );
        bus_count += 1;
    }

    for u in seed["users"] {
        world ++> Passenger(username=u["username"], role=u["role"]);
    }

    world.seed_source = "docs/data/seed.json + docs/data/road-network.json";
    world.seeded_at = time.strftime("%Y-%m-%dT%H:%M:%S");
    return {
        "terminals": len(terminals),
        "slots": slot_count,
        "junctions": len(junctions),
        "roads": road_count,
        "routes": len(routes),
        "buses": bus_count,
        "users": len(seed["users"])
    };
}

with entry:__main__ {
    world = World();
    counts = seed_world(world);
    print(f"Seed files load cleanly: {counts}");
}
