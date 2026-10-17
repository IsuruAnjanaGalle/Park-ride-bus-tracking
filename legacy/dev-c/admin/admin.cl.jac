"""Admin Control Room View.

The primary administrative interface for ParkRide dispatchers and operators.
Optimized for 1440px+ projector displays in high-contrast Night Theme.
"""

import from ..components.admin.LocalUI { LocalBadge, LocalButton, CityMapPlaceholder }
import from ..components.admin.AdminShell { AdminShell }
import from ..components.admin.BusRow { BusRow }
import from ..components.admin.NextStopPanel { NextStopPanel }
import from ..components.admin.ScanFeed { ScanFeed }
import from ..components.admin.AlertFeed { AlertFeed }
import from ..components.admin.DemoCaptionBar { DemoCaptionBar }
import from ..components.admin.SampleData {
    get_sample_fleet,
    get_sample_stop_exchange,
    get_sample_scans,
    get_sample_alerts
}
import "../components/admin/admin_tokens.css";

def render_fleet_row(
    b: dict[str, object],
    selectedId: str,
    onSelect: Callable[[str], None]
) -> JsxElement {
    b_id = str(b["id"]);
    return BusRow(
        bus=b,
        isSelected=(b_id == selectedId),
        onClick=onSelect
    );
}

def get_demo_steps -> list[dict[str, object]] {
    return [
        {
            "step_index": 1,
            "total_steps": 6,
            "title": "System Boot & Graph Topology Initialization",
            "proves": "Object-Spatial graph loads 10 multimodal stops, 17 road links, parking bays, and active shuttle fleet."
        },
        {
            "step_index": 2,
            "total_steps": 6,
            "title": "Commuter Checks Parking & Allocates EV Bay",
            "proves": "Smart allocation evaluates walking distance to terminal entrance, reserving optimal Bay EV-01 at Makumbura MMC."
        },
        {
            "step_index": 3,
            "total_steps": 6,
            "title": "Cryptographic QR Pass Minting (HMAC-SHA256)",
            "proves": "Mints tamper-proof combo pass encoding booking ID, vehicle plate, terminal, and epoch expiration."
        },
        {
            "step_index": 4,
            "total_steps": 6,
            "title": "Automated Barrier Validation & Slot Transition",
            "proves": "Sub-second cryptographic validation opens barrier gate and transitions bay status from RESERVED to OCCUPIED."
        },
        {
            "step_index": 5,
            "total_steps": 6,
            "title": "Expressway Shuttle Boarding & Real-Time Telemetry",
            "proves": "Live bus telemetry updates GPS coordinates (68.5 km/h, 315° NW), passenger load, and dynamic arrival ETA."
        },
        {
            "step_index": 6,
            "total_steps": 6,
            "title": "Dynamic Congestion Rerouting (Dijkstra Optimization)",
            "proves": "Arterial congestion factor re-weights edges, automatically routing commuters onto E02 Expressway shuttle saving 35m."
        }
    ];
}

def:pub AdminView -> JsxElement {
    has activeTab: str = "home",
        selectedBusId: str = "bus_ex1_01",
        simSpeed: str = "1x",
        simPaused: bool = False,
        trafficPreset: str = "Clear",
        fleet: list[dict[str, object]] = get_sample_fleet(),
        stopInfo: dict[str, object] = get_sample_stop_exchange(),
        scans: list[dict[str, object]] = get_sample_scans(),
        alerts: list[dict[str, object]] = get_sample_alerts(),
        demoSteps: list[dict[str, object]] = get_demo_steps(),
        demoStepIdx: int = 0,
        demoPlaying: bool = False;

    def select_tab(tab_name: str) {
        activeTab = tab_name;
    }

    def select_bus(bus_id: str) {
        selectedBusId = bus_id;
        activeTab = "bus_account";
    }

    def set_speed_1x { simSpeed = "1x"; }
    def set_speed_10x { simSpeed = "10x"; }
    def set_speed_30x { simSpeed = "30x"; }

    def toggle_pause {
        simPaused = not simPaused;
    }

    def set_preset_clear { trafficPreset = "Clear"; }
    def set_preset_rush { trafficPreset = "Morning rush"; }
    def set_preset_crash { trafficPreset = "Crash near Rajagiriya"; }
    def set_preset_jam { trafficPreset = "High Level Road jam"; }
    def set_preset_cutoff { trafficPreset = "Makumbura cut off"; }

    def demo_play_pause {
        demoPlaying = not demoPlaying;
    }

    def demo_next {
        demoStepIdx = (demoStepIdx + 1) % len(demoSteps);
    }

    def demo_restart {
        demoStepIdx = 0;
        demoPlaying = False;
    }

    # Find selected bus or default to first
    active_bus = fleet[0];
    for b in fleet {
        if str(b["id"]) == selectedBusId {
            active_bus = b;
        }
    }

    clock_status = "10:26:00 +05:30 (" + ("PAUSED" if simPaused else ("Sim " + simSpeed)) + ")";
    current_demo_step = demoSteps[demoStepIdx];

    home_content = (
        <div style={{"display": "flex", "flexDirection": "column", "gap": "24px"}}>
            <div style={{"display": "grid", "gridTemplateColumns": "repeat(4, 1fr)", "gap": "16px"}}>
                <div className="glass-panel" style={{"padding": "16px 20px"}}>
                    <span style={{"fontSize": "13px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                        {"FLEET IN SERVICE"}
                    </span>
                    <div style={{"fontSize": "32px", "fontWeight": "800", "color": "#38bdf8", "fontFamily": "var(--mono-font)"}}>
                        {str(len(fleet)) + " Buses"}
                    </div>
                </div>

                <div className="glass-panel" style={{"padding": "16px 20px"}}>
                    <span style={{"fontSize": "13px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                        {"MAKUMBURA MMC PARKING"}
                    </span>
                    <div style={{"fontSize": "32px", "fontWeight": "800", "color": "#34d399", "fontFamily": "var(--mono-font)"}}>
                        {"42 / 50 Bays"}
                    </div>
                </div>

                <div className="glass-panel" style={{"padding": "16px 20px"}}>
                    <span style={{"fontSize": "13px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                        {"ACTIVE COMBO PASSES"}
                    </span>
                    <div style={{"fontSize": "32px", "fontWeight": "800", "color": "#c084fc", "fontFamily": "var(--mono-font)"}}>
                        {"162 Active"}
                    </div>
                </div>

                <div className="glass-panel" style={{"padding": "16px 20px"}}>
                    <span style={{"fontSize": "13px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                        {"TRAFFIC STATUS"}
                    </span>
                    <div style={{"fontSize": "32px", "fontWeight": "800", "color": "#fbbf24", "fontFamily": "var(--mono-font)"}}>
                        {trafficPreset}
                    </div>
                </div>
            </div>

            <div style={{"display": "grid", "gridTemplateColumns": "1.2fr 0.8fr", "gap": "24px"}}>
                <div style={{"display": "flex", "flexDirection": "column", "gap": "20px"}}>
                    <CityMapPlaceholder height="440px" busCount={len(fleet)}/>

                    <div className="glass-panel">
                        <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "16px"}}>
                            <span style={{"fontSize": "20px", "fontWeight": "800", "color": "#ffffff"}}>
                                {"ACTIVE FLEET MONITOR"}
                            </span>
                            <span style={{"fontSize": "13px", "color": "#94a3b8"}}>
                                {"Click bus to inspect account"}
                            </span>
                        </div>

                        <div>
                            {[
                                render_fleet_row(b, selectedBusId, select_bus)
                                for b in fleet
                            ]}
                        </div>
                    </div>
                </div>

                <div style={{"display": "flex", "flexDirection": "column", "gap": "20px"}}>
                    <NextStopPanel info={stopInfo}/>
                    <ScanFeed events={scans}/>
                    <AlertFeed alerts={alerts}/>
                </div>
            </div>
        </div>
    );

    active_route = str(active_bus["route"]);
    active_plate = str(active_bus["plate"]);
    active_color = str(active_bus.get("color", "#0284c7"));
    active_passengers = int(active_bus["passengers"]);
    active_capacity = int(active_bus["capacity"]);

    account_content = (
        <div style={{"display": "flex", "flexDirection": "column", "gap": "24px"}}>
            <div className="glass-panel">
                <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "20px"}}>
                    <div>
                        <div style={{"display": "flex", "alignItems": "center", "gap": "14px"}}>
                            <span className="bus-route-badge" style={{"backgroundColor": active_color, "fontSize": "20px", "padding": "8px 18px"}}>
                                {active_route}
                            </span>
                            <span style={{"fontSize": "28px", "fontWeight": "800", "fontFamily": "var(--mono-font)"}}>
                                {active_plate}
                            </span>
                            <LocalBadge label="IN-TRANSIT" variant="success" pulse={True}/>
                        </div>
                        <div style={{"fontSize": "15px", "color": "#94a3b8", "marginTop": "6px"}}>
                            {"Direct Expressway P&R Shuttle · Makumbura MMC ⇄ Colombo Fort"}
                        </div>
                    </div>

                    <div style={{"display": "flex", "gap": "10px"}}>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if selectedBusId == "bus_ex1_01" else "")}
                            onClick={lambda { select_bus("bus_ex1_01"); }}
                        >
                            {"EX1-01"}
                        </button>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if selectedBusId == "bus_ex1_02" else "")}
                            onClick={lambda { select_bus("bus_ex1_02"); }}
                        >
                            {"EX1-02"}
                        </button>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if selectedBusId == "bus_138_01" else "")}
                            onClick={lambda { select_bus("bus_138_01"); }}
                        >
                            {"138"}
                        </button>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if selectedBusId == "bus_120_04" else "")}
                            onClick={lambda { select_bus("bus_120_04"); }}
                        >
                            {"120"}
                        </button>
                    </div>
                </div>

                <div style={{"display": "grid", "gridTemplateColumns": "repeat(4, 1fr)", "gap": "16px", "padding": "16px 0", "borderTop": "1px solid rgba(255,255,255,0.1)", "borderBottom": "1px solid rgba(255,255,255,0.1)"}}>
                    <div>
                        <span style={{"fontSize": "12px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                            {"ASSIGNED DRIVER"}
                        </span>
                        <div style={{"fontSize": "18px", "fontWeight": "700", "color": "#ffffff", "marginTop": "4px"}}>
                            {"Kamal Gunaratne"}
                        </div>
                        <span style={{"fontSize": "12px", "color": "#64748b"}}>{"ID: DRV-4412"}</span>
                    </div>

                    <div>
                        <span style={{"fontSize": "12px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                            {"CONDUCTOR"}
                        </span>
                        <div style={{"fontSize": "18px", "fontWeight": "700", "color": "#ffffff", "marginTop": "4px"}}>
                            {"Sunil Perera"}
                        </div>
                        <span style={{"fontSize": "12px", "color": "#64748b"}}>{"ID: CND-1088"}</span>
                    </div>

                    <div>
                        <span style={{"fontSize": "12px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                            {"ON BOARD / CAPACITY"}
                        </span>
                        <div style={{"fontSize": "22px", "fontWeight": "800", "color": "#38bdf8", "fontFamily": "var(--mono-font)", "marginTop": "2px"}}>
                            {str(active_passengers) + " / " + str(active_capacity)}
                        </div>
                    </div>

                    <div>
                        <span style={{"fontSize": "12px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                            {"BATTERY / SPEED"}
                        </span>
                        <div style={{"fontSize": "18px", "fontWeight": "700", "color": "#34d399", "marginTop": "4px"}}>
                            {"94% · 68 km/h"}
                        </div>
                    </div>
                </div>
            </div>

            <div style={{"display": "grid", "gridTemplateColumns": "1fr 1fr", "gap": "24px"}}>
                <NextStopPanel info={stopInfo}/>
                <ScanFeed events={scans}/>
            </div>
        </div>
    );

    demo_content = (
        <div style={{"display": "flex", "flexDirection": "column", "gap": "24px"}}>
            <div className="glass-panel">
                <span style={{"fontSize": "22px", "fontWeight": "800", "color": "#ffffff"}}>
                    {"SIMULATION CONTROLS"}
                </span>
                <div style={{"fontSize": "14px", "color": "#94a3b8", "marginTop": "4px", "marginBottom": "20px"}}>
                    {"Adjust system clock multiplier and traffic incident scenarios in real-time."}
                </div>

                <div style={{"display": "flex", "alignItems": "center", "gap": "16px", "marginBottom": "28px"}}>
                    <span style={{"fontWeight": "700", "color": "#cbd5e1"}}>{"Simulation Speed:"}</span>
                    <button
                        className={"nav-tab-btn " + ("nav-tab-active" if simSpeed == "1x" else "")}
                        onClick={set_speed_1x}
                    >
                        {"1x Realtime"}
                    </button>
                    <button
                        className={"nav-tab-btn " + ("nav-tab-active" if simSpeed == "10x" else "")}
                        onClick={set_speed_10x}
                    >
                        {"10x Accelerated"}
                    </button>
                    <button
                        className={"nav-tab-btn " + ("nav-tab-active" if simSpeed == "30x" else "")}
                        onClick={set_speed_30x}
                    >
                        {"30x Fast Forward"}
                    </button>

                    <LocalButton
                        label={"RESUME SIMULATION" if simPaused else "PAUSE SIMULATION"}
                        variant={"success" if simPaused else "ghost"}
                        onClick={toggle_pause}
                    />
                </div>

                <div style={{"borderTop": "1px solid rgba(255,255,255,0.1)", "paddingTop": "20px"}}>
                    <span style={{"fontSize": "18px", "fontWeight": "800", "color": "#ffffff"}}>
                        {"TRAFFIC PRESETS (set_traffic)"}
                    </span>
                    <div style={{"display": "flex", "flexWrap": "wrap", "gap": "12px", "marginTop": "14px"}}>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if trafficPreset == "Clear" else "")}
                            onClick={set_preset_clear}
                        >
                            {"Clear"}
                        </button>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if trafficPreset == "Morning rush" else "")}
                            onClick={set_preset_rush}
                        >
                            {"Morning rush"}
                        </button>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if trafficPreset == "Crash near Rajagiriya" else "")}
                            onClick={set_preset_crash}
                        >
                            {"Crash near Rajagiriya"}
                        </button>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if trafficPreset == "High Level Road jam" else "")}
                            onClick={set_preset_jam}
                        >
                            {"High Level Road jam"}
                        </button>
                        <button
                            className={"nav-tab-btn " + ("nav-tab-active" if trafficPreset == "Makumbura cut off" else "")}
                            onClick={set_preset_cutoff}
                        >
                            {"Makumbura cut off"}
                        </button>
                    </div>
                </div>
            </div>

            <AlertFeed alerts={alerts}/>
        </div>
    );

    return
        <AdminShell
            activeTab={activeTab}
            onSelectTab={select_tab}
            simClock={clock_status}
            systemHealth="OPTIMAL"
        >
            <div style={{"display": "flex", "flexDirection": "column", "gap": "16px"}}>
                {home_content if activeTab == "home" else (account_content if activeTab == "bus_account" else demo_content)}

                <DemoCaptionBar
                    step={current_demo_step}
                    isPlaying={demoPlaying}
                    onPlayPause={demo_play_pause}
                    onNext={demo_next}
                    onRestart={demo_restart}
                />
            </div>
        </AdminShell>;
}
