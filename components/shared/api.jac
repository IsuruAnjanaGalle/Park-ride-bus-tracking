"""The only way screens talk to the backend: one function per walker in docs/contracts.md.

Every function returns the contract envelope {ok, data, error}. With USE_MOCK[name] True
it returns the sample from mock/mocks.jac; with False it spawns the real walker.
Dev A flips a walker to False when contracts.md marks it `real`. Owner: Dev A.
"""

import from "@jac/runtime" { jacLogin, jacSignup, jacLogout, jacIsLoggedIn, SignupResult }
import from core.walkers.profile { get_profile as w_get_profile }
import from core.walkers.parking {
    get_terminals as w_get_terminals,
    get_slots as w_get_slots,
    recommend_slots as w_recommend_slots,
    book_slot as w_book_slot,
    mark_parked as w_mark_parked,
    release_slot as w_release_slot
}
import from core.walkers.buses {
    get_map as w_get_map,
    get_buses as w_get_buses,
    book_seat as w_book_seat,
    get_trip as w_get_trip
}
import from core.walkers.scans { process_scan as w_process_scan }
import from core.walkers.admin {
    admin_bus_list as w_admin_bus_list,
    admin_bus_account as w_admin_bus_account,
    admin_next_stop as w_admin_next_stop,
    admin_feed as w_admin_feed
}
import from core.walkers.traffic {
    set_traffic as w_set_traffic,
    report_incident as w_report_incident,
    get_driver_view as w_get_driver_view
}
import from core.walkers.demo {
    demo_control as w_demo_control,
    reset_demo as w_reset_demo
}
# Walkers are called by name: importing them would compile each into a class named like
# the function below and clash (see docs/decisions.md D-24).
import from "@jac/runtime" { jacLogin, jacSignup, jacLogout, jacIsLoggedIn, jacSpawn, SignupResult }
import from mock.mocks {
    mock_get_profile, mock_get_terminals, mock_get_slots, mock_recommend_slots, mock_book_slot,
    mock_mark_parked, mock_release_slot, mock_get_map, mock_get_buses, mock_book_seat,
    mock_get_trip, mock_process_scan, mock_admin_bus_list, mock_admin_bus_account,
    mock_admin_next_stop, mock_admin_feed, mock_demo_control, mock_set_traffic,
    mock_report_incident, mock_get_driver_view, mock_run_demo, mock_reset_demo
}

"""Per-walker mock switch. Set an entry to False once the walker is `real` in contracts.md."""
glob USE_MOCK: dict[str, bool] = {
    "get_profile": False,
    "get_terminals": False,
    "get_slots": False,
    "recommend_slots": False,
    "book_slot": False,
    "mark_parked": False,
    "release_slot": False,
    "get_map": False,
    "get_buses": False,
    "book_seat": False,
    "get_trip": False,
    "process_scan": False,
    "admin_bus_list": True,
    "admin_bus_account": True,
    "admin_next_stop": False,  # qr, stop and visit_no are real (docs/contracts.md); the rest is seed data
    "admin_feed": True,
    "demo_control": False,
    "set_traffic": False,
    "report_incident": False,
    "get_driver_view": False,
    "reset_demo": False
};

"""Turn every mock on or off at once (the MOCK toggle on /dev/core)."""
def set_all_mocks(on: bool) {
    for name in USE_MOCK.keys() {
    "run_demo": False,
    "reset_demo": False
};

"""Turn every mock on or off at once (the MOCK toggle on /dev/core).

Still mocked (Dev C finishes them): admin_bus_list, admin_bus_account, admin_next_stop, admin_feed.
"""
def:pub mock_on(name: str) -> bool {
    return USE_MOCK[name] if name in USE_MOCK else False;
}

def:pub set_all_mocks(on: bool) -> None {
    for name in Object.keys(USE_MOCK) {
        if name != "get_profile" {
            USE_MOCK[name] = on;
        }
    }
}

def _err(code: str, message: str) -> dict[str, any] {
    return {"ok": False, "data": None, "error": {"code": code, "message": message}};
}

"""First report of a spawn result, or an error envelope when the call failed."""
def _first(result: any) -> dict[str, any] {
    reports: list[any] = list(getattr(result, "reports", [])) if result else [];
    if len(reports) > 0 {
        rep: dict[str, any] = dict(reports[0]);
        return rep;
    }
    return _err("EMPTY", "The server sent no report.");
}

"""Spawn a walker by name; first report as the envelope. A write conflict (409 WRITE_CONFLICT, or
a 500 carrying Postgres serialization failure 40001) means another request saved the same nodes
first and nothing of this one was saved, so it is retried up to 3 times."""
async def _call(name: str, fields: dict[str, any]) -> dict[str, any] {
    tries = 0;
    while True {
        try {
            return _first(await jacSpawn(name, "", fields));
        } except Exception as e {
            tries += 1;
            text = String(e);
            if tries < 3 and ("WRITE_CONFLICT" in text or "409" in text or "40001" in text or "serialize" in text) {
                continue;
            }
            return _thrown(e);
        }
    }
}

"""Map a thrown error (e.g. no session) to an envelope."""
def _thrown(e: any) -> dict[str, any] {
    text: str = str(e);
    if "UNAUTHORIZED" in text or "401" in text {
        return _err("UNAUTHORIZED", "Please log in first.");
    }
    return _err("NETWORK", text);
}

# ---- session ------------------------------------------------------------------

"""Log in (creating the demo account on first use), bind the profile, remember username and role.

The platform account is "parkride-<username>" so app users never collide with platform accounts
such as the built-in "admin" (docs/decisions.md D-21).
"""
async def:pub login(username: str, password: str) -> dict[str, any] {
    ok: bool = False;
    signup: any = None;
    result: any = None;
    account = "parkride-" + username;
    try {
        ok = await jacLogin(account, password);
        if not ok {
            signup = await jacSignup(username, password);
            if signup and getattr(signup, "success", False) {
                ok = await jacLogin(username, password);
            signup = await jacSignup(account, password);
            if signup and signup.success {
                ok = await jacLogin(account, password);
            }
        }
        if not ok {
            return _err("BAD_LOGIN", "Wrong username or password.");
        }
        result = await jacSpawn("get_profile", "", {"username": username});
        env = _first(result);
        if env.get("ok") {
            data: dict = dict(env.get("data", {}));
            localStorage.setItem("parkride_user", str(data.get("username", "")));
            localStorage.setItem("parkride_role", str(data.get("role", "")));
        }
        return env;
    } except Exception as e {
        return _thrown(e);
    }
}

def logout {
def:pub logout -> None {
    jacLogout();
    localStorage.removeItem("parkride_user");
    localStorage.removeItem("parkride_role");
}

"""{username, role} of the current session, or None when logged out."""
def:pub current_user -> dict[str, any] | None {
    if not jacIsLoggedIn() {
        return None;
    }
    name = localStorage.getItem("parkride_user");
    if not name {
        return None;
    }
    return {"username": name, "role": localStorage.getItem("parkride_role") or "passenger"};
}

def:pub is_admin -> bool {
    user = current_user();
    return user is not None and user["role"] == "admin";
}

async def:pub get_profile(username: str) -> dict[str, any] {
    if USE_MOCK["get_profile"] {
        return mock_get_profile();
    }
    try {
        return await _call("get_profile", {"username": username});
    } except Exception as e {
        return _thrown(e);
    }
}

# ---- parking ------------------------------------------------------------------

async def:pub get_terminals -> dict[str, any] {
    if USE_MOCK["get_terminals"] {
        return mock_get_terminals();
    }
    try {
        return await _call("get_terminals", {});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub get_slots(terminal: str) -> dict[str, any] {
    if USE_MOCK["get_slots"] {
        return mock_get_slots();
    }
    try {
        return await _call("get_slots", {"terminal": terminal});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub recommend_slots(
    terminal: str, vehicle: str, ev: str = "no", accessible: bool = False,
    arrival: str = "08:00", return_by: str = "10:00"
) -> dict[str, any] {
    if USE_MOCK["recommend_slots"] {
        return mock_recommend_slots();
    }
    try {
        return await _call("recommend_slots", {"terminal": terminal, "vehicle": vehicle, "ev": ev, "accessible": accessible, "arrival": arrival, "return_by": return_by});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub book_slot(terminal: str, slot_code: str, arrival: str, return_by: str) -> dict[str, any] {
    if USE_MOCK["book_slot"] {
        return mock_book_slot();
    }
    try {
        return await _call("book_slot", {"terminal": terminal, "slot_code": slot_code, "arrival": arrival, "return_by": return_by});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub mark_parked(booking_id: str) -> dict[str, any] {
    if USE_MOCK["mark_parked"] {
        return mock_mark_parked();
    }
    try {
        return await _call("mark_parked", {"booking_id": booking_id});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub release_slot(booking_id: str = "", qr: str = "") -> dict[str, any] {
    if USE_MOCK["release_slot"] {
        return mock_release_slot();
    }
    try {
        return await _call("release_slot", {"booking_id": booking_id, "qr": qr});
    } except Exception as e {
        return _thrown(e);
    }
}

# ---- map, buses, seats, scans -------------------------------------------------

async def:pub get_map -> dict[str, any] {
    if USE_MOCK["get_map"] {
        return mock_get_map();
    }
    try {
        return await _call("get_map", {});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub get_buses(route: str = "") -> dict[str, any] {
    if USE_MOCK["get_buses"] {
        return mock_get_buses();
    }
    try {
        return await _call("get_buses", {"route": route});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub book_seat(bus_id: str, pickup: str, drop: str) -> dict[str, any] {
    if USE_MOCK["book_seat"] {
        return mock_book_seat();
    }
    try {
        return await _call("book_seat", {"bus_id": bus_id, "pickup": pickup, "drop": drop});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub get_trip(booking_id: str = "") -> dict[str, any] {
    if USE_MOCK["get_trip"] {
        return mock_get_trip();
    }
    try {
        return await _call("get_trip", {"booking_id": booking_id});
    } except Exception as e {
        return _thrown(e);
    }
}

"""Send a scan. Make a fresh scan_id per physical scan (e.g. crypto.randomUUID())."""
async def:pub process_scan(scan_id: str, qr: str, drop: str = "") -> dict[str, any] {
    if USE_MOCK["process_scan"] {
        return mock_process_scan();
    }
    try {
        return await _call("process_scan", {"scan_id": scan_id, "qr": qr, "drop": drop});
    } except Exception as e {
        return _thrown(e);
    }
}

# ---- admin --------------------------------------------------------------------

async def:pub admin_bus_list -> dict[str, any] {
    if USE_MOCK["admin_bus_list"] {
        return mock_admin_bus_list();
    }
    try {
        return await _call("admin_bus_list", {});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub admin_bus_account(bus_id: str) -> dict[str, any] {
    if USE_MOCK["admin_bus_account"] {
        return mock_admin_bus_account();
    }
    try {
        return await _call("admin_bus_account", {"bus_id": bus_id});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub admin_next_stop(bus_id: str) -> dict[str, any] {
    if USE_MOCK["admin_next_stop"] {
        return mock_admin_next_stop();
    }
    try {
        return await _call("admin_next_stop", {"bus_id": bus_id});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub admin_feed(limit: int = 50) -> dict[str, any] {
    if USE_MOCK["admin_feed"] {
        return mock_admin_feed();
    }
    try {
        return await _call("admin_feed", {"limit": limit});
    } except Exception as e {
        return _thrown(e);
    }
}

# ---- demo, traffic, driver ----------------------------------------------------

async def demo_control(action: str = "status", speed: float = 0.0) -> dict[str, any] {
async def:pub demo_control(
    action: str = "status", speed: float = 0.0, bus_id: str = "", stop: str = "",
    count: int = 1, drop: str = ""
) -> dict[str, any] {
    if USE_MOCK["demo_control"] {
        return mock_demo_control();
    }
    try {
        return _first(root spawn w_demo_control(
            action=action, speed=speed
        ));
        return await _call("demo_control", {"action": action, "speed": speed, "bus_id": bus_id, "stop": stop, "count": count, "drop": drop});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub set_traffic(preset: str = "", a: str = "", b: str = "", level: int = -1) -> dict[str, any] {
    if USE_MOCK["set_traffic"] {
        return mock_set_traffic();
    }
    try {
        return await _call("set_traffic", {"preset": preset, "a": a, "b": b, "level": level});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub report_incident(bus_id: str, kind: str, severity: str) -> dict[str, any] {
    if USE_MOCK["report_incident"] {
        return mock_report_incident();
    }
    try {
        return await _call("report_incident", {"bus_id": bus_id, "kind": kind, "severity": severity});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub get_driver_view(bus_id: str) -> dict[str, any] {
    if USE_MOCK["get_driver_view"] {
        return mock_get_driver_view();
    }
    try {
        return await _call("get_driver_view", {"bus_id": bus_id});
    } except Exception as e {
        return _thrown(e);
    }
}

async def reset_demo -> dict[str, any] {
async def:pub run_demo(action: str = "status") -> dict[str, any] {
    if USE_MOCK["run_demo"] {
        return mock_run_demo();
    }
    try {
        return await _call("run_demo", {"action": action});
    } except Exception as e {
        return _thrown(e);
    }
}

async def:pub reset_demo -> dict[str, any] {
    if USE_MOCK["reset_demo"] {
        return mock_reset_demo();
    }
    try {
        return await _call("reset_demo", {});
    } except Exception as e {
        return _thrown(e);
    }
}
