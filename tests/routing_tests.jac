"""Traffic routing checks (SOW 9.6 and 13): the 7 self-checks of the rerouting prototype."""

import from core.models.nodes { World, Bus, Decision }
import from core.lib.world { reset_world, get_world, must_bus, must_trip }
import from core.lib.routing { build_adj, plan_route, set_road_level, INF }
import from core.lib.sim { replan_all, advance, depart_now, jump_and_hold, instruction }

def setup -> World {
    reset_world();
    return get_world();
}

"""Put MB-101 on Borella -> Rajagiriya, heading for Battaramulla (the SOW traffic case)."""
def on_borella_road(world: World) -> Bus {
    bus = must_bus(world, "MB-101");
    bus.state = "moving";
    bus.road_from = "BOR";
    bus.road_to = "RAJ";
    bus.next_stop = "BAT";
    bus.path = ["BOR", "RAJ", "BAT"];
    bus.progress = 0.3;
    return bus;
}

test "1 free roads: Borella to Battaramulla goes through Rajagiriya" {
    world = setup();
    (path, minutes) = plan_route(build_adj(world), "BOR", "BAT");
    assert path == ["BOR", "RAJ", "BAT"], path;
    assert 11.0 < minutes < 12.5, minutes;
}

test "2 a closed road is never planned" {
    world = setup();
    set_road_level(world, "RAJ", "BAT", 3);
    (path, _) = plan_route(build_adj(world), "RAJ", "BAT");
    assert path == ["RAJ", "NAL", "BAT"], path;
}

test "3 crash near Rajagiriya: reroute via Nawala from the end of the current road" {
    world = setup();
    bus = on_borella_road(world);
    set_road_level(world, "RAJ", "BAT", 3);
    decisions = replan_all(world, ["RAJ|BAT"]);
    assert len(decisions) == 1 and decisions[0]["decision"] == "Rerouted", decisions;
    assert bus.path == ["BOR", "RAJ", "NAL", "BAT"], bus.path;
    assert bus.road_from == "BOR" and bus.road_to == "RAJ";
    assert bus.rerouted and "closed" in bus.reroute_reason;
    assert instruction(world, bus)["toward"] == "Nawala", instruction(world, bus);
}

test "4 same road only slow: keeps its route, ETA rises" {
    world = setup();
    bus = on_borella_road(world);
    set_road_level(world, "RAJ", "BAT", 1);
    decisions = replan_all(world, ["RAJ|BAT"]);
    assert decisions[0]["decision"] == "Kept route", decisions;
    assert bus.path == ["BOR", "RAJ", "BAT"];
    assert not bus.rerouted;
}

test "5 no U-turn: a bus on a road that closes finishes it at crawl speed" {
    world = setup();
    bus = on_borella_road(world);
    set_road_level(world, "BOR", "RAJ", 3);
    replan_all(world, ["BOR|RAJ"]);
    assert bus.road_from == "BOR" and bus.road_to == "RAJ";
    before = bus.progress;
    advance(world, build_adj(world), bus, 1.0e7, 60.0);
    assert bus.road_from == "BOR" and bus.progress > before;
}

test "6 Makumbura cut off: the bus waits, then moves again when a road reopens" {
    world = setup();
    bus = must_bus(world, "MB-101");
    assert jump_and_hold(world, bus, "KOT");
    set_road_level(world, "KOT", "MKB", 3);
    set_road_level(world, "ATH", "MKB", 3);
    depart_now(world, bus);
    assert bus.state == "waiting", bus.state;
    set_road_level(world, "KOT", "MKB", 0);
    advance(world, build_adj(world), bus, 1.0e7, 5.0);
    assert bus.state == "moving", bus.state;
    kinds = [d.decision for d in [world -->[?:Decision]] if d.bus_id == "MB-101"];
    assert "Waiting" in kinds and "Moving again" in kinds, kinds;
}

test "7 a bus reaches its next stop and dwells there" {
    world = setup();
    bus = on_borella_road(world);
    advance(world, build_adj(world), bus, 1.0e7, 3600.0);
    assert bus.state == "dwelling", bus.state;
    assert bus.from_stop == "BAT";
}
