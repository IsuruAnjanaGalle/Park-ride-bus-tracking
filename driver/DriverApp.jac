"""Driver In-Cab View (/driver/:busId).

Specialized high-contrast, night-mode driver console.
Adheres strictly to the in-cab safety guidelines:
- Solid non-glass instruction bar (high-visibility emerald)
- Assertive aria-live reroute banner (solid amber)
- Large touch targets (44px+) for mobile in-cab mounts
- 2-tap incident reporting flow (type -> severity -> submit)
"""

cl import from "@jac/runtime" { useEffect, useState }
import from ..components.shared.api { get_driver_view, report_incident }
import from ..components.admin.DriverInstructionBar { DriverInstructionBar }
import from ..components.admin.RerouteBanner { RerouteBanner }
cl import "../components/admin/admin_tokens.css";

def:pub DriverApp(busId: str = "MB-101") -> JsxElement {
    has showModal: bool = False,
        incidentStep: int = 1,
        selectedKind: str = "",
        selectedSeverity: str = "",
        incidentNotice: str = "",
        instructionText: str = "Loading instruction...",
        distanceKm: float = 0.0,
        maneuver: str = "straight",
        rerouted: bool = False,
        rerouteReason: str = "",
        nextStopName: str = "",
        nextStopCode: str = "",
        etaMin: float = 0.0,
        waitingAtNext: int = 0,
        busPlate: str = "",
        routeName: str = "",
        seatsLeft: int = 0,
        loading: bool = True;

    async def fetch_view {
        view_res = await get_driver_view(busId);
        if view_res["ok"] {
            data: dict[str, any] = dict(view_res["data"]);
            inst: dict[str, any] = dict(data.get("instruction", {}));
            instructionText = str(inst.get("text", "Continue on path"));
            distanceKm = float(str(inst.get("km", "0.0")));
            maneuver = str(inst.get("turn", "straight"));
            rerouted = bool(data.get("rerouted", False));
            rerouteReason = str(data.get("reroute_reason", ""));
            etaMin = float(str(data.get("eta_min", "0.0")));
            waitingAtNext = int(str(data.get("waiting_at_next", "0")));

            bus_info: dict[str, any] = dict(data.get("bus", {}));
            busPlate = str(bus_info.get("plate", ""));
            routeName = str(bus_info.get("route_name", ""));
            seatsLeft = int(str(bus_info.get("seats_left", "0")));

            stp: dict[str, any] = dict(data.get("next_stop", {}));
            nextStopName = str(stp.get("name", stp.get("code", "")));
            nextStopCode = str(stp.get("code", ""));
            loading = False;
        }
    }

    # Poll every 2 s (docs/contracts.md 3.19).
    useEffect(lambda {
        fetch_view();
        timer = setInterval(lambda { fetch_view(); }, 2000);
        return lambda { clearInterval(timer); };
    }, [busId]);

    def open_modal {
        showModal = True;
        incidentStep = 1;
        selectedKind = "";
        selectedSeverity = "";
    }

    def close_modal {
        showModal = False;
    }

    def select_kind(k: str) {
        selectedKind = k;
        incidentStep = 2;
    }

    def select_severity(s: str) {
        selectedSeverity = s;
        incidentStep = 3;
    }

    async def submit_incident {
        res = await report_incident(busId, selectedKind, selectedSeverity);
        if res["ok"] {
            inc = res["data"]["incident"];
            incidentNotice = "Logged " + selectedKind + " (" + selectedSeverity + ") at " + str(inc["at"]) + ". Dispatch alerted.";
            showModal = False;
            await fetch_view();
        } else {
            incidentNotice = "Error: " + str(res["error"]["message"]);
        }
    }

    return (
        <main className="driver-shell" id="driver-app-root">
            <header style={{"display": "flex", "alignItems": "center", "justifyContent": "space-between", "padding": "16px 24px", "background": "#0f172a", "borderBottom": "1px solid rgba(255, 255, 255, 0.1)"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "14px"}}>
                    <span style={{"background": "#2563eb", "color": "#fff", "padding": "4px 10px", "borderRadius": "6px", "fontWeight": "800", "fontSize": "14px"}}>
                        {"BUS " + busId}
                    </span>
                    <span style={{"fontWeight": "700", "fontSize": "16px", "color": "#94a3b8"}}>
                        {busPlate + " · " + routeName}
                    </span>
                </div>
                <div style={{"display": "flex", "alignItems": "center", "gap": "12px"}}>
                    <span style={{"fontSize": "14px", "color": "#34d399", "fontWeight": "700"}}>
                        {str(seatsLeft) + " seats left"}
                    </span>
                    <button
                        id="btn-report-incident"
                        onClick={open_modal}
                        style={{"minHeight": "44px", "minWidth": "44px", "padding": "8px 18px", "background": "#ef4444", "color": "#ffffff", "border": "none", "borderRadius": "8px", "fontWeight": "800", "fontSize": "15px", "cursor": "pointer", "display": "flex", "alignItems": "center", "gap": "8px"}}
                    >
                        {"⚠️ REPORT INCIDENT"}
                    </button>
                </div>
            </header>

            <DriverInstructionBar
                instruction={instructionText}
                distanceKm={distanceKm}
                maneuver={maneuver}
            />

            <RerouteBanner
                reason={rerouteReason}
                active={rerouted}
            />

            {incidentNotice and (
                <div
                    id="incident-alert-notice"
                    role="alert"
                    aria-live="polite"
                    style={{"margin": "12px 24px 0 24px", "padding": "12px 18px", "background": "rgba(16, 185, 129, 0.2)", "border": "1px solid #10b981", "borderRadius": "8px", "color": "#34d399", "fontWeight": "700"}}
                >
                    {incidentNotice}
                </div>
            )}

            <div style={{"padding": "24px", "display": "grid", "gridTemplateColumns": "1fr 1fr", "gap": "16px", "flex": "1"}}>
                <div style={{"background": "rgba(30, 41, 59, 0.7)", "borderRadius": "14px", "padding": "24px", "border": "1px solid rgba(255, 255, 255, 0.12)", "display": "flex", "flexDirection": "column", "justifyContent": "center"}}>
                    <div style={{"fontSize": "14px", "textTransform": "uppercase", "color": "#94a3b8", "fontWeight": "800", "letterSpacing": "0.05em", "marginBottom": "6px"}}>
                        {"NEXT SCHEDULED STOP"}
                    </div>
                    <div id="driver-next-stop-name" style={{"fontSize": "28px", "fontWeight": "800", "color": "#f8fafc"}}>
                        {nextStopName if nextStopName else "En route"}
                    </div>
                    <div style={{"fontSize": "16px", "color": "#38bdf8", "fontWeight": "700", "marginTop": "4px"}}>
                        {"Stop code: " + nextStopCode}
                    </div>
                </div>

                <div style={{"display": "grid", "gridTemplateColumns": "1fr 1fr", "gap": "16px"}}>
                    <div style={{"background": "rgba(0, 0, 0, 0.4)", "borderRadius": "12px", "padding": "20px", "textAlign": "center", "border": "1px solid rgba(255, 255, 255, 0.08)"}}>
                        <div id="driver-eta-value" style={{"fontSize": "36px", "fontWeight": "800", "color": "#38bdf8", "fontFamily": "var(--mono-font)"}}>
                            {str(etaMin) + "m"}
                        </div>
                        <div style={{"fontSize": "13px", "color": "#94a3b8", "textTransform": "uppercase", "fontWeight": "700", "marginTop": "4px"}}>
                            {"ETA"}
                        </div>
                    </div>

                    <div style={{"background": "rgba(0, 0, 0, 0.4)", "borderRadius": "12px", "padding": "20px", "textAlign": "center", "border": "1px solid rgba(255, 255, 255, 0.08)"}}>
                        <div id="driver-waiting-value" style={{"fontSize": "36px", "fontWeight": "800", "color": "#ffc21a", "fontFamily": "var(--mono-font)"}}>
                            {str(waitingAtNext)}
                        </div>
                        <div style={{"fontSize": "13px", "color": "#94a3b8", "textTransform": "uppercase", "fontWeight": "700", "marginTop": "4px"}}>
                            {"WAITING TO BOARD"}
                        </div>
                    </div>
                </div>
            </div>

            {showModal and (
                <div style={{"position": "fixed", "inset": "0", "background": "rgba(0, 0, 0, 0.8)", "display": "flex", "alignItems": "center", "justifyContent": "center", "zIndex": "100", "padding": "20px"}}>
                    <div style={{"background": "#0f172a", "border": "2px solid #ef4444", "borderRadius": "16px", "padding": "24px", "maxWidth": "540px", "width": "100%"}}>
                        <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "20px"}}>
                            <span style={{"fontSize": "20px", "fontWeight": "800", "color": "#ef4444"}}>
                                {"⚠️ REPORT ROAD INCIDENT"}
                            </span>
                            <button
                                onClick={close_modal}
                                style={{"minHeight": "44px", "minWidth": "44px", "background": "transparent", "border": "none", "color": "#94a3b8", "fontSize": "22px", "cursor": "pointer"}}
                            >
                                {"✕"}
                            </button>
                        </div>

                        {incidentStep == 1 and (
                            <div>
                                <div style={{"fontSize": "15px", "color": "#f87171", "fontWeight": "800", "marginBottom": "14px", "letterSpacing": "0.04em"}}>
                                    {"STEP 1: SELECT INCIDENT KIND"}
                                </div>
                                <div style={{"display": "grid", "gridTemplateColumns": "1fr 1fr", "gap": "12px"}}>
                                    <button
                                        style={{"minHeight": "48px", "padding": "14px", "fontSize": "16px", "fontWeight": "700", "background": "rgba(255, 255, 255, 0.08)", "color": "#fff", "border": "1px solid rgba(255, 255, 255, 0.2)", "borderRadius": "10px", "cursor": "pointer"}}
                                        onClick={lambda { select_kind("accident"); }}
                                    >
                                        {"💥 Accident"}
                                    </button>
                                    <button
                                        style={{"minHeight": "48px", "padding": "14px", "fontSize": "16px", "fontWeight": "700", "background": "rgba(255, 255, 255, 0.08)", "color": "#fff", "border": "1px solid rgba(255, 255, 255, 0.2)", "borderRadius": "10px", "cursor": "pointer"}}
                                        onClick={lambda { select_kind("breakdown"); }}
                                    >
                                        {"🔧 Breakdown"}
                                    </button>
                                    <button
                                        style={{"minHeight": "48px", "padding": "14px", "fontSize": "16px", "fontWeight": "700", "background": "rgba(255, 255, 255, 0.08)", "color": "#fff", "border": "1px solid rgba(255, 255, 255, 0.2)", "borderRadius": "10px", "cursor": "pointer"}}
                                        onClick={lambda { select_kind("flooding"); }}
                                    >
                                        {"🌊 Flooding"}
                                    </button>
                                    <button
                                        style={{"minHeight": "48px", "padding": "14px", "fontSize": "16px", "fontWeight": "700", "background": "rgba(255, 255, 255, 0.08)", "color": "#fff", "border": "1px solid rgba(255, 255, 255, 0.2)", "borderRadius": "10px", "cursor": "pointer"}}
                                        onClick={lambda { select_kind("road_works"); }}
                                    >
                                        {"🚧 Road Works"}
                                    </button>
                                    <button
                                        style={{"minHeight": "48px", "padding": "14px", "fontSize": "16px", "fontWeight": "700", "background": "rgba(255, 255, 255, 0.08)", "color": "#fff", "border": "1px solid rgba(255, 255, 255, 0.2)", "borderRadius": "10px", "cursor": "pointer", "gridColumn": "span 2"}}
                                        onClick={lambda { select_kind("road_closed"); }}
                                    >
                                        {"🚫 Road Closed"}
                                    </button>
                                </div>
                            </div>
                        )}

                        {incidentStep == 2 and (
                            <div>
                                <div style={{"fontSize": "15px", "color": "#f87171", "fontWeight": "800", "marginBottom": "14px", "letterSpacing": "0.04em"}}>
                                    {"STEP 2: SELECT SEVERITY FOR " + selectedKind.upper()}
                                </div>
                                <div style={{"display": "flex", "flexDirection": "column", "gap": "12px"}}>
                                    <button
                                        style={{"minHeight": "52px", "padding": "14px", "fontSize": "16px", "fontWeight": "700", "background": "rgba(245, 158, 11, 0.2)", "color": "#fef08a", "border": "1px solid #f59e0b", "borderRadius": "10px", "cursor": "pointer"}}
                                        onClick={lambda { select_severity("slow"); }}
                                    >
                                        {"🟡 Slow · Level 1 Delay"}
                                    </button>
                                    <button
                                        style={{"minHeight": "52px", "padding": "14px", "fontSize": "16px", "fontWeight": "700", "background": "rgba(239, 68, 68, 0.2)", "color": "#fca5a5", "border": "1px solid #ef4444", "borderRadius": "10px", "cursor": "pointer"}}
                                        onClick={lambda { select_severity("jammed"); }}
                                    >
                                        {"🔴 Jammed · Level 2 Heavy Congestion"}
                                    </button>
                                    <button
                                        style={{"minHeight": "52px", "padding": "14px", "fontSize": "16px", "fontWeight": "700", "background": "rgba(185, 28, 28, 0.4)", "color": "#ffffff", "border": "2px solid #dc2626", "borderRadius": "10px", "cursor": "pointer"}}
                                        onClick={lambda { select_severity("closed"); }}
                                    >
                                        {"⛔ Closed · Level 3 Complete Blockage"}
                                    </button>
                                </div>
                            </div>
                        )}

                        {incidentStep == 3 and (
                            <div>
                                <div style={{"fontSize": "15px", "color": "#38bdf8", "fontWeight": "800", "marginBottom": "14px", "letterSpacing": "0.04em"}}>
                                    {"CONFIRM & SEND TO DISPATCH"}
                                </div>
                                <div style={{"background": "rgba(0, 0, 0, 0.4)", "padding": "16px", "borderRadius": "10px", "marginBottom": "20px", "border": "1px solid rgba(255, 255, 255, 0.1)"}}>
                                    <p style={{"margin": "0 0 8px 0", "fontSize": "16px", "color": "#f8fafc"}}>
                                        <span style={{"fontWeight": "700"}}>{"Bus: "}</span>{busId}
                                    </p>
                                    <p style={{"margin": "0 0 8px 0", "fontSize": "16px", "color": "#f8fafc"}}>
                                        <span style={{"fontWeight": "700"}}>{"Incident: "}</span>{selectedKind}
                                    </p>
                                    <p style={{"margin": "0", "fontSize": "16px", "color": "#f8fafc"}}>
                                        <span style={{"fontWeight": "700"}}>{"Severity: "}</span>{selectedSeverity}
                                    </p>
                                </div>
                                <button
                                    id="btn-confirm-incident"
                                    onClick={submit_incident}
                                    style={{"minHeight": "48px", "width": "100%", "padding": "14px", "background": "#ef4444", "color": "#ffffff", "border": "none", "borderRadius": "10px", "fontWeight": "800", "fontSize": "16px", "cursor": "pointer"}}
                                >
                                    {"SUBMIT INCIDENT & RE-ROUTE"}
                                </button>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </main>
    );
}
