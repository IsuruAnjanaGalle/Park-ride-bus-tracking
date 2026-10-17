"""Access to the one shared World under root.shared: lazy seeding, reset, lookups and ids."""

import threading;
import time;
import from core.models.nodes {
    World, DemoClock, Terminal, Slot, Junction, Stop, Route, Bus, Trip, Passenger
}
import from core.seed.seed { seed_world }
import from core.lib.static { static_names }

glob _seed_lock: any = threading.Lock();

def _find_world() -> World | None {
    worlds = [root.shared -->[?:World]];
    return worlds[0] if worlds else None;
}

"""The shared world, seeding it on first use (safe if two requests race)."""
def get_world() -> World {
    found = _find_world();
    if found {
        return found;
    }
    with _seed_lock {
        again = _find_world();
        if again {
            return again;
        }
        world = World();
        root.shared ++> world;
        seed_world(world);
        return world;
    }
}

"""Every node reachable from the world (breadth-first, each once)."""
def world_nodes(world: World) -> list[any] {
    seen: dict[str, bool] = {};
    queue: list[any] = [world];
    found: list[any] = [];
    while queue {
        current = queue.pop(0);
        key = jid(current);
        if key in seen {
            continue;
        }
        seen[key] = True;
        found.append(current);
        for nxt in [current -->] {
            if jid(nxt) not in seen {
                queue.append(nxt);
            }
        }
    }
    return found;
}

"""Replace the world with a fresh one from the seed files, keeping who is logged in as whom.

The old world is detached from root.shared (not deleted node by node) so a reset stays fast;
its nodes are unreachable afterwards. Returns timing and counts.
"""
def reset_world() -> dict[str, any] {
    started = time.time();
    with _seed_lock {
        bindings: dict[str, list[str]] = {};
        for old in [root.shared -->[?:World]] {
            for p in [old -->[?:Passenger]] {
                if p.root_id {
                    bindings[p.username] = [p.role, p.root_id];
                }
            }
            root.shared del --> old;
        }
        world = World();
        root.shared ++> world;
        counts = seed_world(world);
        for (name, info) in bindings.items() {
            found = [world -->[?:Passenger, username == name]];
            if found {
                found[0].root_id = info[1];
            } else {
                world ++> Passenger(username=name, role=info[0], root_id=info[1]);
            }
        }
    }
    return {"seconds": round(time.time() - started, 2), "counts": counts};
}

"""A new unique id with a prefix, e.g. new_id(world, "PB") -> "PB-0007"."""
def new_id(world: World, prefix: str) -> str {
    n = world.next_id;
    world.next_id = n + 1;
    return f"{prefix}-{n:04d}";
}

def get_clock(world: World) -> DemoClock {
    return [world -->[?:DemoClock]][0];
}

def list_terminals(world: World) -> list[Terminal] {
    return [world -->[?:Terminal]];
}

def find_terminal(world: World, terminal_code: str) -> Terminal | None {
    found = [world -->[?:Terminal, code == terminal_code]];
    return found[0] if found else None;
}

def terminal_slots(term: Terminal) -> list[Slot] {
    return [term -->[?:Slot]];
}

def list_buses(world: World) -> list[Bus] {
    return [world -->[?:Bus]];
}

def find_bus(world: World, bus_id: str) -> Bus | None {
    found = [world -->[?:Bus, id == bus_id]];
    return found[0] if found else None;
}

def current_trip(bus: Bus) -> Trip | None {
    trips = [bus -->[?:Trip, status == "running"]];
    return trips[0] if trips else None;
}

def get_routes(world: World) -> list[Route] {
    return [world -->[?:Route]];
}

def find_route(world: World, route_id: str) -> Route | None {
    found = [world -->[?:Route, id == route_id]];
    return found[0] if found else None;
}

def get_junctions(world: World) -> list[Junction] {
    return [world -->[?:Junction]];
}

"""Map of junction code -> name for every junction, stop and terminal."""
def junction_names(world: World) -> dict[str, str] {
    return static_names();
}

def find_passenger(world: World, name: str) -> Passenger | None {
    found = [world -->[?:Passenger, username == name]];
    return found[0] if found else None;
}

"""Lookups for seed data that must exist (raise if missing): used by the demo engine."""
def must_bus(world: World, bus_id: str) -> Bus {
    found = [world -->[?:Bus, id == bus_id]];
    if not found {
        raise ValueError(f"No bus {bus_id}");
    }
    return found[0];
}

def must_terminal(world: World, terminal_code: str) -> Terminal {
    found = [world -->[?:Terminal, code == terminal_code]];
    if not found {
        raise ValueError(f"No terminal {terminal_code}");
    }
    return found[0];
}

def must_trip(bus: Bus) -> Trip {
    trips = [bus -->[?:Trip, status == "running"]];
    if not trips {
        raise ValueError(f"No running trip for {bus.id}");
    }
    return trips[0];
}
