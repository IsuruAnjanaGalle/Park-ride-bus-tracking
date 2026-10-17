"""Demo walkers (contracts.md 3.16, 3.21). Admin login required.

demo_control clock actions (status, speed, pause, resume) and reset_demo are real.
run_demo removed (D-C01).
"""

import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, get_clock, reset_world }
import from core.lib.clock { clock_dict, set_speed, set_paused }
import from core.lib.profiles { admin_error }
import from core.lib.rules { SPEEDS }

walker:protect demo_control {
    has action: str = "status",
        speed: float = 0.0,
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
        } else {
            report fail("INVALID_INPUT", "action must be status, speed, pause, or resume.");
            return;
        }
        report ok({"clock": clock_dict(clock), "message": message});
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
