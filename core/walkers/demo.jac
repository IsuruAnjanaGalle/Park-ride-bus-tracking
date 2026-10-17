"""Demo walkers (contracts.md 3.16, 3.20, 3.21). Admin login required.

demo_control, run_demo and reset_demo are real.
"""

import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, get_clock, find_bus, reset_world }
import from core.lib.clock { clock_dict, set_speed, set_paused }
import from core.lib.profiles { admin_error }
import from core.lib.rules { SPEEDS }
import from core.lib.demo_engine { control }
import from core.lib.journey { spawn_riders }
import from core.lib.sim { tick, jump_and_hold, depart_now }

walker:protect demo_control {
    has action: str = "status",
        speed: float = 0.0,
        bus_id: str = "",
        stop: str = "",
        count: int = 1,
        drop: str = "",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = admin_error(world);
        if err {
            report err;
            return;
        }
        tick(world);
        clock = get_clock(world);
        message = "";
        if self.action == "status" {
            message = "Clock status.";
        } elif self.action == "speed" {
            if self.speed not in SPEEDS {
                report fail("INVALID_INPUT", "speed must be 1, 5, 10 or 30.");
                return;
            }
            set_speed(clock, self.speed);
            message = f"Speed set to {int(self.speed)}x.";
        } elif self.action == "pause" {
            set_paused(clock, True);
            message = "Clock paused.";
        } elif self.action == "resume" {
            set_paused(clock, False);
            message = "Clock running.";
        } elif self.action == "jump" {
            bus = find_bus(world, self.bus_id);
            if bus is None or not self.stop {
                report fail("INVALID_INPUT", "jump needs bus_id and stop.");
                return;
            }
            if not jump_and_hold(world, bus, self.stop) {
                report fail("INVALID_INPUT", f"{self.stop} is not on {bus.id}'s route.");
                return;
            }
            message = f"{bus.id} is at {self.stop} and waits there until depart.";
        } elif self.action == "depart" {
            bus = find_bus(world, self.bus_id);
            if bus is None {
                report fail("INVALID_INPUT", "depart needs bus_id.");
                return;
            }
            events = depart_now(world, bus);
            message = f"{bus.id} departed: " + (", ".join(events) if events else "nothing to do") + ".";
        } elif self.action == "spawn_passenger" {
            bus = find_bus(world, self.bus_id);
            if bus is None or not self.stop or not self.drop {
                report fail("INVALID_INPUT", "spawn_passenger needs bus_id, stop and drop.");
                return;
            }
            riders = spawn_riders(world, bus, self.stop, self.drop, max(self.count, 1));
            if not riders {
                report fail("INVALID_INPUT", "stop and drop must be on the bus's current trip.");
                return;
            }
            message = "Spawned " + ", ".join(riders) + ".";
        } else {
            report fail("INVALID_INPUT", "action must be status, speed, pause, resume, jump, depart or spawn_passenger.");
            return;
        }
        report ok({"clock": clock_dict(clock), "message": message});
    }
}

walker:protect run_demo {
    has action: str = "status",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = admin_error(world);
        if err {
            report err;
            return;
        }
        if self.action not in ["status", "play", "pause", "next", "restart"] {
            report fail("INVALID_INPUT", "action must be status, play, pause, next or restart.");
            return;
        }
        report ok(control(self.action));
    }
}

walker:protect reset_demo {
    has reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = admin_error(world);
        if err {
            report err;
            return;
        }
        report ok(reset_world());
    }
}
