"""Business-rule constants and pure helpers shared by the walkers.

Kept out of core/walkers/ on purpose: client code imports the walker modules, and a
plain helper inside such a module breaks `jac build` (see docs/jac-reference.md).
"""

glob VEHICLES: list[str] = ["B", "M", "C"];
glob EV_CHOICES: list[str] = ["no", "needs_charging", "park_only"];
glob STOP_QR_TTL_S: int = 600;
glob INCIDENT_KINDS: list[str] = ["accident", "breakdown", "flooding", "road_works", "road_closed"];
glob SEVERITIES: dict[str, int] = {"slow": 1, "jammed": 2, "closed": 3};
glob SPEEDS: list[float] = [1.0, 5.0, 10.0, 30.0];
glob DEMO_STEPS: list[str] = [
    "Book a car slot at Makumbura for 2 hours: front-line recommendation and parking QR.",
    "Mark the vehicle as parked: the slot turns occupied.",
    "Book MB-101 from Makumbura to Borella: the driver's waiting count goes up.",
    "Jump MB-101 to Makumbura and scan the stop QR: confirmed, on board.",
    "Scan the same QR again: duplicate, ignored and logged.",
    "Crash near Rajagiriya: MB-101 reroutes via Nawala.",
    "Two stops before Borella: the arrival alert fires.",
    "Get-off scans at Borella with one rider missing.",
    "The bus departs Borella: the mismatch alert names the missing rider."
];

"""Zone for an expected stay: under 3 h front, 3-8 h middle, over 8 h rear (SOW 9.1)."""
def zone_for_stay(hours: float) -> str {
    if hours < 3.0 {
        return "F";
    }
    if hours <= 8.0 {
        return "M";
    }
    return "R";
}

"""Hours between two HH:MM times; a return earlier than arrival means overnight."""
def stay_hours(arrival: str, return_by: str) -> float {
    a = arrival.split(":");
    r = return_by.split(":");
    start = int(a[0]) * 60 + int(a[1]);
    end = int(r[0]) * 60 + int(r[1]);
    if end <= start {
        end += 24 * 60;
    }
    return round((end - start) / 60.0, 2);
}

def valid_hhmm(t: str) -> bool {
    parts = t.split(":");
    if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit() {
        return False;
    }
    return 0 <= int(parts[0]) < 24 and 0 <= int(parts[1]) < 60;
}
