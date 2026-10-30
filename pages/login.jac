"""/login - log in as a passenger or an admin, or open a driver view (docs/decisions.md D-29, D-30).

Passenger and admin accounts come from docs/data/users.csv. Drivers need no login in the demo, so
the Driver tab lists the buses and opens /driver/<bus>. ?next=/admin returns there after logging in
and opens on the Admin tab.
"""

import from "react" { useEffect }
import from "@jac/runtime" { Link, useNavigate, useLocation }
import from ..components.shared.api { login, logout, current_user, get_buses }

glob TABS: list[dict[str, str]] = [
    {"key": "passenger", "label": "Passenger", "icon": "🧳"},
    {"key": "admin", "label": "Admin", "icon": "🛡️"},
    {"key": "driver", "label": "Driver", "icon": "🚌"}
];
glob DEMO: dict[str, list[str]] = {
    "passenger": ["passenger", "demo-passenger"],
    "admin": ["admin", "demo-admin"]
};
glob HOME: dict[str, str] = {"passenger": "/", "admin": "/admin"};

def:pub LoginPage -> JsxPage {
    has tab: str = "passenger",
        username: str = "",
        password: str = "",
        message: str = "",
        isError: bool = False,
        busy: bool = False,
        buses: list[dict[str, any]] = [],
        busStatus: str = "idle";
    nav = useNavigate();
    location = useLocation();

    search: str = location.search or "";
    rawNext: str = search.split("next=")[1].split("&")[0] if "next=" in search else "";
    safeNext: str = rawNext if rawNext[:1] == "/" and rawNext[:2] != "//" else "";
    user = current_user();

    useEffect(lambda {
        if safeNext[:6] == "/admin" {
            tab = "admin";
        }
    }, []);

    async def load_buses {
        busStatus = "loading";
        env: dict[str, any] = await get_buses("");
        if env["ok"] {
            buses = [dict(b) for b in list(env["data"]["buses"])];
            busStatus = "ready" if len(buses) > 0 else "empty";
        } else {
            busStatus = "error";
        }
    }

    # Handlers made per tab or per bus get their value as a parameter (D-30).
    def tab_handler(key: str) -> any {
        return lambda (_e: MouseEvent) {
            tab = key;
            message = "";
            if key == "driver" and busStatus != "ready" {
                load_buses();
            }
        };
    }

    def driver_handler(busId: str) -> any {
        return lambda (_e: MouseEvent) { nav("/driver/" + busId); };
    }

    def fill_demo(_e: MouseEvent) {
        pair = DEMO.get(tab, ["", ""]);
        username = pair[0];
        password = pair[1];
        message = "";
    }

    async def do_login(e: FormEvent) {
        e.preventDefault();
        if busy {
            return;
        }
        if not username or not password {
            message = "Enter your username and password.";
            isError = True;
            return;
        }
        busy = True;
        message = "";
        env: dict[str, any] = await login(username, password);
        busy = False;
        if not env["ok"] {
            message = str(env["error"]["message"]);
            isError = True;
            return;
        }
        role = str(env["data"]["role"]);
        if tab == "admin" and role != "admin" {
            logout();
            message = username + " has no admin access. Use the Passenger tab.";
            isError = True;
            return;
        }
        password = "";
        nav(safeNext or HOME.get(role, "/"));
    }

    def do_logout(_e: MouseEvent) {
        logout();
        message = "You are logged out.";
        isError = False;
    }

    demoPair = DEMO.get(tab, ["", ""]);
    submitLabel = "Logging in..." if busy else ("Log in as admin" if tab == "admin" else "Log in as passenger");
    panelText = {"color": "var(--text-muted)"};
    field = {"background": "var(--surface)", "border": "1px solid var(--border)", "color": "var(--text)"};
    primary = {"background": "var(--accent)", "color": "var(--accent-ink)"};
    outline = {"border": "1px solid var(--border)", "color": "var(--text)"};

    <main data-theme="night" className="min-h-dvh flex items-start sm:items-center justify-center px-4 py-8" style={{"background": "var(--bg)", "color": "var(--text)"}}>
        <section className="glass w-full max-w-md rounded-3xl p-6 flex flex-col gap-5" aria-labelledby="login-title">
            <header className="flex items-center gap-3">
                <span aria-hidden="true" className="w-11 h-11 rounded-2xl flex items-center justify-center font-black" style={primary}>PR</span>
                <div>
                    <h1 id="login-title" className="text-2xl font-bold" style={{"fontFamily": "var(--font-display)"}}>Log in</h1>
                    <p className="text-sm" style={panelText}>Park &amp; Ride Sri Lanka</p>
                </div>
            </header>

            {if user {
                <div role="status" className="rounded-2xl p-3 flex flex-wrap items-center justify-between gap-2" style={{"background": "var(--surface-2)", "border": "1px solid var(--border)"}}>
                    <span className="text-sm">{"Signed in as " + user["username"] + " (" + user["role"] + ")"}</span>
                    <span className="flex gap-2">
                        <button type="button" className="min-h-11 px-4 rounded-xl font-semibold" style={primary} onClick={lambda (_e: MouseEvent) { nav(HOME.get(user["role"], "/")); }}>Continue</button>
                        <button type="button" className="min-h-11 px-4 rounded-xl" style={outline} onClick={do_logout}>Log out</button>
                    </span>
                </div>;
            }}

            <div role="tablist" aria-label="Log in as" className="grid grid-cols-3 gap-1.5 p-1.5 rounded-2xl" style={{"background": "var(--surface)", "border": "1px solid var(--border)"}}>
                {for t in TABS {
                    <button
                        key={t["key"]}
                        type="button"
                        role="tab"
                        id={"tab-" + t["key"]}
                        aria-selected={tab == t["key"]}
                        aria-controls="login-panel"
                        onClick={tab_handler(t["key"])}
                        className="min-h-11 rounded-xl text-sm font-semibold flex items-center justify-center gap-1.5 transition-colors"
                        style={primary if tab == t["key"] else panelText}
                    >
                        <span aria-hidden="true">{t["icon"]}</span>
                        <span>{t["label"]}</span>
                    </button>;
                }}
            </div>

            <div id="login-panel" role="tabpanel" aria-labelledby={"tab-" + tab} className="flex flex-col gap-4">
                {if tab == "driver" {
                    <div className="flex flex-col gap-3">
                        <p className="text-sm" style={panelText}>Drivers do not need a password in this demo. Choose your bus to open its driver view.</p>
                        {if busStatus == "error" {
                            <div role="alert" className="flex items-center justify-between gap-2 text-sm">
                                <span>Could not load the buses.</span>
                                <button type="button" className="min-h-11 px-4 rounded-xl" style={outline} onClick={lambda (_e: MouseEvent) { load_buses(); }}>Retry</button>
                            </div>;
                        } elif busStatus == "empty" {
                            <p className="text-sm">No buses are running right now.</p>;
                        } elif busStatus == "ready" {
                            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                                {for b in buses {
                                    <button
                                        key={b["id"]}
                                        type="button"
                                        onClick={driver_handler(str(b["id"]))}
                                        className="min-h-11 rounded-xl p-2 text-left flex flex-col"
                                        style={{"background": "var(--surface-2)", "border": "1px solid var(--border)", "color": "var(--text)"}}
                                    >
                                        <span className="font-bold" style={{"fontFamily": "var(--font-mono)"}}>{b["id"]}</span>
                                        <span className="text-xs" style={panelText}>{b["route_name"]}</span>
                                    </button>;
                                }}
                            </div>;
                        } else {
                            <p role="status" className="text-sm">Loading buses...</p>;
                        }}
                    </div>;
                } else {
                    <form onSubmit={do_login} className="flex flex-col gap-3" noValidate={True}>
                        <label className="flex flex-col gap-1">
                            <span className="text-sm font-semibold">Username</span>
                            <input
                                name="username"
                                className="min-h-11 rounded-xl px-3 text-base"
                                style={field}
                                value={username}
                                autoComplete="username"
                                autoCapitalize="none"
                                autoCorrect="off"
                                spellCheck={False}
                                onChange={lambda (e: ChangeEvent) { username = e.target.value; }}
                            />
                        </label>
                        <label className="flex flex-col gap-1">
                            <span className="text-sm font-semibold">Password</span>
                            <input
                                name="password"
                                className="min-h-11 rounded-xl px-3 text-base"
                                style={field}
                                type="password"
                                value={password}
                                autoComplete="current-password"
                                onChange={lambda (e: ChangeEvent) { password = e.target.value; }}
                            />
                        </label>
                        <button type="submit" disabled={busy} className="min-h-11 rounded-xl font-semibold disabled:opacity-60" style={primary}>
                            {submitLabel}
                        </button>
                        <button type="button" className="min-h-11 rounded-xl text-sm" style={outline} onClick={fill_demo}>
                            {"Use demo account (" + demoPair[0] + " / " + demoPair[1] + ")"}
                        </button>
                    </form>;
                }}
                <p role="status" aria-live="polite" className="text-sm min-h-5" style={{"color": "var(--bad)"} if isError else panelText}>{message}</p>
            </div>

            <nav aria-label="Other pages" className="flex flex-wrap justify-between gap-2 text-sm">
                <Link to="/" style={{"color": "var(--neon)"}}>Passenger app</Link>
                <Link to="/dev/core" style={{"color": "var(--neon)"}}>Developer console</Link>
            </nav>
        </section>
    </main>
}
