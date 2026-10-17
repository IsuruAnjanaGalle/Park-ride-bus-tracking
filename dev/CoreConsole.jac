"""Dev A's core console: call any walker through components/shared/api.jac and see its JSON.

Plain on purpose (no design system): it is a test bench, not a product screen.
"""

import from ..components.shared.api {
    mock_on, set_all_mocks, login, logout, current_user,
    get_profile, get_terminals, get_slots, recommend_slots, book_slot, mark_parked, release_slot,
    get_map, get_buses, book_seat, get_trip, process_scan,
    admin_bus_list, admin_bus_account, admin_next_stop, admin_feed,
    demo_control, set_traffic, report_incident, get_driver_view, reset_demo
}

glob WALKERS: list[str] = [
    "get_profile", "get_terminals", "get_slots", "recommend_slots", "book_slot", "mark_parked",
    "release_slot", "get_map", "get_buses", "book_seat", "get_trip", "process_scan",
    "admin_bus_list", "admin_bus_account", "admin_next_stop", "admin_feed", "demo_control",
    "set_traffic", "report_incident", "get_driver_view", "reset_demo"
];

def:pub CoreConsole -> JsxElement {
    has output: str = "Press a walker button.",
        title: str = "",
        mocks_on: bool = True,
        user_label: str = "",
        booking_id: str = "",
        stop_qr: str = "",
        busy: bool = False,
        scan_count: int = 0;

    def refresh_user {
        user = current_user();
        user_label = (user["username"] + " (" + user["role"] + ")") if user else "not logged in";
    }

    can with entry {
        refresh_user();
    }

    def show(name: str, env: dict[str, any]) {
        title = name + (" (mock)" if mock_on(name) else " (real)");
        output = JSON.stringify(env, None, 2);
        if env and env["ok"] and env["data"] {
            data = env["data"];
            if data["booking"] and data["booking"]["id"] {
                booking_id = data["booking"]["id"];
            }
            if data["qr"] and data["stop"] {
                stop_qr = data["qr"];
            }
        }
    }

    async def run(name: str) {
        env: dict[str, any] = {};
        busy = True;
        user = current_user();
        uname = user["username"] if user else "passenger";
        if name == "get_profile" {
            env = await get_profile(uname);
        } elif name == "get_terminals" {
            env = await get_terminals();
        } elif name == "get_slots" {
            env = await get_slots("MKB");
        } elif name == "recommend_slots" {
            env = await recommend_slots("MKB", "C", "no", False, "08:00", "10:00");
        } elif name == "book_slot" {
            env = await book_slot("MKB", "MKB-C-F-03", "08:00", "10:00");
        } elif name == "mark_parked" {
            env = await mark_parked(booking_id or "PB-0001");
        } elif name == "release_slot" {
            env = await release_slot(booking_id or "PB-0001", "");
        } elif name == "get_map" {
            env = await get_map();
        } elif name == "get_buses" {
            env = await get_buses("");
        } elif name == "book_seat" {
            env = await book_seat("MB-101", "BAT", "MKB");
        } elif name == "get_trip" {
            env = await get_trip(booking_id);
        } elif name == "process_scan" {
            scan_count = scan_count + 1;
            env = await process_scan("console-" + str(scan_count) + "-" + user_label, stop_qr or "not-a-qr", "");
        } elif name == "admin_bus_list" {
            env = await admin_bus_list();
        } elif name == "admin_bus_account" {
            env = await admin_bus_account("MB-101");
        } elif name == "admin_next_stop" {
            env = await admin_next_stop("MB-101");
        } elif name == "admin_feed" {
            env = await admin_feed(50);
        } elif name == "demo_control" {
            env = await demo_control("status", 0.0, "", "", 1, "");
        } elif name == "set_traffic" {
            env = await set_traffic("crash", "", "", -1);
        } elif name == "report_incident" {
            env = await report_incident("MB-101", "accident", "closed");
        } elif name == "get_driver_view" {
            env = await get_driver_view("MB-101");
        } elif name == "reset_demo" {
            env = await reset_demo();
        }
        show(name, env);
        busy = False;
    }

    async def do_login(username: str) {
        env: dict[str, any] = {};
        env = await login(username, "demo-" + username);
        show("login " + username, env);
        refresh_user();
    }

    def do_logout(_e: MouseEvent) {
        logout();
        refresh_user();
        output = "Logged out.";
    }

    def toggle_mocks(_e: MouseEvent) {
        mocks_on = not mocks_on;
        set_all_mocks(mocks_on);
        output = "Mocks " + ("ON" if mocks_on else "OFF") + " for every walker except get_profile and reset_demo.";
    }

    return <main className="p-4 flex flex-col gap-4" style={{"fontFamily": "var(--font-mono)"}}>
        <h1 className="text-2xl font-bold">/dev/core - walker console</h1>
        <section className="flex flex-wrap items-center gap-2" aria-label="Session and mode">
            <span>{"Session: " + user_label}</span>
            <button className="min-h-11 px-3 rounded border" onClick={lambda (_e: MouseEvent) { do_login("passenger"); }}>Log in passenger</button>
            <button className="min-h-11 px-3 rounded border" onClick={lambda (_e: MouseEvent) { do_login("admin"); }}>Log in admin</button>
            <button className="min-h-11 px-3 rounded border" onClick={do_logout}>Log out</button>
            <button className="min-h-11 px-3 rounded border" aria-pressed={mocks_on} onClick={toggle_mocks}>{"MOCK: " + ("ON" if mocks_on else "OFF")}</button>
            <button className="min-h-11 px-3 rounded border" onClick={lambda (_e: MouseEvent) { run("reset_demo"); }}>Reset</button>
        </section>
        <section className="flex flex-wrap gap-2" aria-label="Walkers">
            {for name in WALKERS {
                <button key={name} className="min-h-11 px-3 rounded border" disabled={busy} onClick={lambda (_e: MouseEvent) { run(name); }}>{name}</button>
            }}
        </section>
        <p className="text-sm">{"booking_id: " + (booking_id or "-") + "  |  stop QR: " + ("set" if stop_qr else "- (run admin_next_stop first)")}</p>
        <h2 className="text-lg font-bold">{title}</h2>
        <pre className="text-xs overflow-auto rounded border p-3" style={{"maxHeight": "70dvh"}} aria-live="polite">{output}</pre>
    </main>;
}
