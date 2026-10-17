"""AdminShell Component.

Provides the top-level container for the ParkRide Admin Control Room.
Features:
- Projector-optimized typography (18px base text, high contrast)
- Night theme with CSS wall background
- Top bar with demo clock slot, system health badge, and tabs (Home / Bus account / Demo console)
"""

import from .LocalUI { LocalBadge }

def:pub AdminShell(
    activeTab: str = "home",
    onSelectTab: Callable[[str], None] = None,
    simClock: str = "10:20:00 +05:30 (Sim 1x)",
    systemHealth: str = "HEALTHY",
    children: JsxElement = None
) -> JsxElement {
    home_cls = "nav-tab-btn nav-tab-active" if activeTab == "home" else "nav-tab-btn";
    account_cls = "nav-tab-btn nav-tab-active" if activeTab == "bus_account" else "nav-tab-btn";
    demo_cls = "nav-tab-btn nav-tab-active" if activeTab == "demo_console" else "nav-tab-btn";

    def click_home {
        if onSelectTab {
            onSelectTab("home");
        }
    }

    def click_account {
        if onSelectTab {
            onSelectTab("bus_account");
        }
    }

    def click_demo {
        if onSelectTab {
            onSelectTab("demo_console");
        }
    }

    return
        <div className="admin-shell">
            <header className="admin-topbar">
                <div className="brand-section">
                    <div className="brand-title">
                        <span>{"PARKRIDE"}</span>
                        <span style={{"color": "#38bdf8"}}>{"CONTROL"}</span>
                    </div>
                    <span className="brand-tag">{"OPERATIONS"}</span>
                    <LocalBadge label={systemHealth} variant="success" pulse={True}/>
                </div>

                <div className="topbar-center">
                    <div className="clock-slot">
                        <span style={{"fontSize": "14px", "color": "#94a3b8"}}>{"SIM CLOCK"}</span>
                        <span style={{"fontWeight": "700", "color": "#38bdf8"}}>{simClock}</span>
                    </div>
                </div>

                <nav className="admin-nav-tabs" aria-label="Admin Navigation Tabs">
                    <button
                        className={home_cls}
                        onClick={click_home}
                        id="tab-home"
                    >
                        {"Home"}
                    </button>
                    <button
                        className={account_cls}
                        onClick={click_account}
                        id="tab-bus-account"
                    >
                        {"Bus account"}
                    </button>
                    <button
                        className={demo_cls}
                        onClick={click_demo}
                        id="tab-demo-console"
                    >
                        {"Demo console"}
                    </button>
                </nav>
            </header>

            <main style={{"padding": "32px", "maxWidth": "1800px", "margin": "0 auto"}}>
                {children}
            </main>
        </div>;
}
