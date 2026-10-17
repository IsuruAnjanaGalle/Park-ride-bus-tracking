"""DemoClock maths. Every walker reads time through these helpers, never the wall clock.

Simulated seconds since the clock's start = offset + (real seconds since anchor) x speed,
frozen while paused.
"""

import time;
import from core.models.nodes { DemoClock }

"""Simulated seconds elapsed since the clock's start time."""
def sim_seconds(clock: DemoClock) -> float {
    if clock.paused {
        return clock.offset;
    }
    return clock.offset + (time.time() - clock.anchor_real) * clock.speed;
}

"""Fold elapsed time into offset so a speed or pause change takes effect from now."""
def rebase(clock: DemoClock) -> None {
    clock.offset = sim_seconds(clock);
    clock.anchor_real = time.time();
}

def set_speed(clock: DemoClock, speed: float) -> None {
    rebase(clock);
    clock.speed = speed;
}

def set_paused(clock: DemoClock, paused: bool) -> None {
    rebase(clock);
    clock.paused = paused;
}

"""Move the clock forward by a number of simulated seconds."""
def advance(clock: DemoClock, seconds: float) -> None {
    rebase(clock);
    clock.offset = clock.offset + seconds;
}

"""Seconds since midnight for an HH:MM:SS string."""
def parse_hms(hms: str) -> int {
    parts = [int(p) for p in hms.split(":")];
    while len(parts) < 3 {
        parts.append(0);
    }
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
}

"""HH:MM:SS for seconds since midnight (wraps at 24 h)."""
def format_hms(seconds: float) -> str {
    total = int(seconds) % 86400;
    return f"{total // 3600:02d}:{(total % 3600) // 60:02d}:{total % 60:02d}";
}

"""The simulated time of day as HH:MM:SS."""
def now_hms(clock: DemoClock) -> str {
    return format_hms(parse_hms(clock.start) + sim_seconds(clock));
}

"""Clock state as reported by demo_control (contract: Clock)."""
def clock_dict(clock: DemoClock) -> dict[str, any] {
    return {
        "time": now_hms(clock),
        "sim_seconds": round(sim_seconds(clock), 1),
        "speed": clock.speed,
        "paused": clock.paused
    };
}
