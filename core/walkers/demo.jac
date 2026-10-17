"""Demo walkers (contracts.md 3.16, 3.20, 3.21). Admin login required.

demo_control clock actions (status, speed, pause, resume) and reset_demo are real;
jump, spawn_passenger and run_demo are stubs until milestones 3 and 4.
"""

import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, get_clock, find_bus, reset_world }
import from core.lib.clock { clock_dict, set_speed, set_paused }
import from core.lib.profiles { admin_error }
import from core.lib.rules { SPEEDS, DEMO_STEPS }

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
            if find_bus(world, self.bus_id) is None or not self.stop {
                report fail("INVALID_INPUT", "jump needs bus_id and stop.");
                return;
            }
            message = f"(stub) {self.bus_id} would jump to {self.stop}.";
        } elif self.action == "spawn_passenger" {
            message = f"(stub) would spawn {self.count} test passenger(s).";
        } else {
            report fail("INVALID_INPUT", "action must be status, speed, pause, resume, jump or spawn_passenger.");
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
        report ok({
            "step": 0,
            "total": len(DEMO_STEPS),
            "caption": DEMO_STEPS[0],
            "playing": self.action == "play",
            "finished": False,
            "last": {}
        });
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
