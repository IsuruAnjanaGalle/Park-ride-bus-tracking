"""Seed loads docs/data exactly: counts, road directions, unique crews, accessible and EV slots."""

import from core.models.nodes { World, Terminal, Slot, Junction, Stop, Route, Bus, Trip, Passenger, DemoClock }
import from core.models.edges { Road, OnRoute }
import from core.seed.seed { seed_world }

def fresh_world -> World {
    world = World();
    seed_world(world);
    return world;
}

test "seed counts match the data files" {
    world = fresh_world();
    terminals = [world -->[?:Terminal]];
    assert len(terminals) == 4;
    slots: list[Slot] = [];
    for t in terminals {
        slots = slots + [t -->[?:Slot]];
    }
    assert len(slots) == 850, f"slots {len(slots)}";
    assert len([world -->[?:Junction]]) == 34;
    assert len([world -->[?:Route]]) == 3;
    assert len([world -->[?:Bus]]) == 9;
    assert len([world -->[?:Passenger]]) == 2;
    assert len([world -->[?:DemoClock]]) == 1;
}

test "every road exists in both directions" {
    world = fresh_world();
    edges = 0;
    for j in [world -->[?:Junction]] {
        edges += len([edge j ->:Road:->]);
    }
    assert edges == 106, f"road edges {edges}";
}

test "routes list their stops in order" {
    world = fresh_world();
    r1 = [world -->[?:Route, id == "R1"]][0];
    assert r1.stop_codes == ["MKB", "KOT", "BAT", "BOR", "TWH", "PET"];
    seqs = sorted([e.seq for e in [edge r1 ->:OnRoute:->]]);
    assert seqs == [0, 1, 2, 3, 4, 5];
}

test "each bus has its own driver and conductor" {
    world = fresh_world();
    buses = [world -->[?:Bus]];
    assert len(set([b.driver for b in buses])) == 9;
    assert len(set([b.conductor for b in buses])) == 9;
    assert all([b.capacity == 40 for b in buses]);
    for b in buses {
        assert len([b -->[?:Trip]]) == 1;
    }
}

test "accessible and EV slots follow the seed notes" {
    world = fresh_world();
    mkb = [world -->[?:Terminal, code == "MKB"]][0];
    slots = [mkb -->[?:Slot]];
    accessible = sorted([s.code for s in slots if s.accessible]);
    assert accessible == ["MKB-C-F-01", "MKB-C-F-02"];
    ev = [s for s in slots if s.kind == "E"];
    assert len(ev) == 8;
    assert all([s.zone == "F" and s.charger_kw > 0 for s in ev]);
}
