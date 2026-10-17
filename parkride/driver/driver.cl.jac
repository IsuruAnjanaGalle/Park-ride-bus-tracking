"""Driver In-Cab View (/driver/:busId).

Specialized high-contrast, night-mode driver console.
Adheres strictly to the in-cab safety guidelines:
- Solid non-glass instruction bar (high-visibility emerald)
- Assertive aria-live reroute banner (solid amber)
- Large touch targets for 390px mobile in-cab mounts
- 2-tap incident reporting flow (type -> severity -> confirm)
"""

import from ..components.admin.LocalUI { LocalBadge, LocalButton, CityMapPlaceholder }
import from ..components.admin.DriverInstructionBar { DriverInstructionBar }
import from ..components.admin.RerouteBanner { RerouteBanner }
import from ..components.admin.NextStopPanel { NextStopPanel }
import "../components/admin/admin_tokens.css";

def:pub DriverView(busId: str = "MB-101") -> JsxElement {
    has showIncidentModal: bool = False,
        incidentStep: int = 1,
        selectedType: str = "",
        selectedSeverity: str = "",
        hasReroute: bool = True,
        rerouteReason: str = "A4 High Level Jam · Diverting to Baseline Expressway",
        instruction: str = "Turn right toward Nawala",
        distanceKm: float = 1.3,
        maneuver: str = "right",
        incidentSubmitted: bool = False,
        stopInfo: dict[str, object] = {
            "stop_name": "Makumbura Multimodal Transport Center (MMC)",
            "stop_code": "MMC",
            "eta_minutes": 6.0,
            "getting_off": 8,
            "bookings_to_board": 14,
            "walk_ins": 2,
            "seats_left": 20,
            "capacity": 54,
            "qr_token": "DRV-PASS-MMC-2026"
        };

    active_bus_id = busId if busId else "MB-101";

    def open_incident_modal {
        showIncidentModal = True;
        incidentStep = 1;
        selectedType = "";
        selectedSeverity = "";
        incidentSubmitted = False;
    }

    def close_incident_modal {
        showIncidentModal = False;
    }

    def select_type_accident { selectedType = "accident"; incidentStep = 2; }
    def select_type_breakdown { selectedType = "breakdown"; incidentStep = 2; }
    def select_type_flooding { selectedType = "flooding"; incidentStep = 2; }
    def select_type_roadworks { selectedType = "road works"; incidentStep = 2; }
    def select_type_roadclosed { selectedType = "road closed"; incidentStep = 2; }

    def select_sev_slow { selectedSeverity = "slow"; incidentStep = 3; }
    def select_sev_jammed { selectedSeverity = "jammed"; incidentStep = 3; }
    def select_sev_closed { selectedSeverity = "closed"; incidentStep = 3; }

    def submit_incident {
        incidentSubmitted = True;
        showIncidentModal = False;
    }

    incident_notice = (
        <div
            style={{"margin": "12px 24px 0 24px", "padding": "12px 18px", "backgroundColor": "rgba(16, 185, 129, 0.2)", "border": "1px solid #10b981", "borderRadius": "8px", "color": "#34d399", "fontWeight": "700", "display": "flex", "justifyContent": "space-between", "alignItems": "center"}}
        >
            <span>{"Incident logged: " + selectedType + " (" + selectedSeverity + ") sent to Dispatch."}</span>
            <span style={{"fontSize": "13px", "color": "#a7f3d0"}}>{"ID: INC-9812"}</span>
        </div>
    );

    step1_view = (
        <div>
            <div style={{"fontSize": "16px", "color": "#f87171", "fontWeight": "700", "marginBottom": "14px", "textTransform": "uppercase"}}>
                {"TAP 1: SELECT INCIDENT TYPE"}
            </div>
            <div style={{"display": "grid", "gridTemplateColumns": "1fr 1fr", "gap": "12px"}}>
                <button
                    className="btn ghost"
                    style={{"padding": "18px", "fontSize": "18px", "justifyContent": "flex-start"}}
                    onClick={select_type_accident}
                >
                    {"💥 Accident"}
                </button>
                <button
                    className="btn ghost"
                    style={{"padding": "18px", "fontSize": "18px", "justifyContent": "flex-start"}}
                    onClick={select_type_breakdown}
                >
                    {"🔧 Breakdown"}
                </button>
                <button
                    className="btn ghost"
                    style={{"padding": "18px", "fontSize": "18px", "justifyContent": "flex-start"}}
                    onClick={select_type_flooding}
                >
                    {"🌊 Flooding"}
                </button>
                <button
                    className="btn ghost"
                    style={{"padding": "18px", "fontSize": "18px", "justifyContent": "flex-start"}}
                    onClick={select_type_roadworks}
                >
                    {"🚧 Road Works"}
                </button>
                <button
                    className="btn ghost"
                    style={{"padding": "18px", "fontSize": "18px", "justifyContent": "flex-start", "gridColumn": "span 2"}}
                    onClick={select_type_roadclosed}
                >
                    {"⛔ Road Closed"}
                </button>
            </div>
        </div>
    );

    step2_view = (
        <div>
            <div style={{"display": "flex", "alignItems": "center", "gap": "10px", "marginBottom": "12px"}}>
                <LocalBadge label={selectedType} variant="danger"/>
                <span style={{"fontSize": "16px", "color": "#fbbf24", "fontWeight": "700", "textTransform": "uppercase"}}>
                    {"TAP 2: SELECT SEVERITY"}
                </span>
            </div>

            <div style={{"display": "flex", "flexDirection": "column", "gap": "12px"}}>
                <button
                    className="btn ghost"
                    style={{"padding": "18px", "fontSize": "18px", "justifyContent": "space-between"}}
                    onClick={select_sev_slow}
                >
                    <span>{"🐢 Slow Traffic"}</span>
                    <span style={{"color": "#fbbf24", "fontSize": "14px"}}>{"Expect 5-10m delay"}</span>
                </button>
                <button
                    className="btn ghost"
                    style={{"padding": "18px", "fontSize": "18px", "justifyContent": "space-between"}}
                    onClick={select_sev_jammed}
                >
                    <span>{"🛑 Jammed (Gridlock)"}</span>
                    <span style={{"color": "#f87171", "fontSize": "14px"}}>{"Expect 20m+ delay"}</span>
                </button>
                <button
                    className="btn ghost"
                    style={{"padding": "18px", "fontSize": "18px", "justifyContent": "space-between"}}
                    onClick={select_sev_closed}
                >
                    <span>{"⛔ Road Fully Blocked"}</span>
                    <span style={{"color": "#ef4444", "fontSize": "14px"}}>{"Immediate detour required"}</span>
                </button>
            </div>
        </div>
    );

    step3_view = (
        <div>
            <div style={{"backgroundColor": "rgba(239, 68, 68, 0.15)", "border": "1px solid #ef4444", "borderRadius": "10px", "padding": "18px", "marginBottom": "20px"}}>
                <div style={{"fontSize": "14px", "color": "#f87171", "fontWeight": "700", "textTransform": "uppercase"}}>
                    {"CONFIRM REPORT BROADCAST"}
                </div>
                <div style={{"fontSize": "22px", "fontWeight": "800", "color": "#ffffff", "marginTop": "6px"}}>
                    {selectedType + " · " + selectedSeverity}
                </div>
                <div style={{"fontSize": "14px", "color": "#cbd5e1", "marginTop": "4px"}}>
                    {"Broadcasting to Central Dispatch and adjusting Dijkstra route weights for all following expressway buses."}
                </div>
            </div>

            <div style={{"display": "flex", "gap": "12px"}}>
                <button
                    className="btn danger"
                    style={{"flex": "1", "padding": "16px", "fontSize": "18px"}}
                    onClick={submit_incident}
                    id="btn-confirm-report-incident"
                >
                    {"CONFIRM & SEND TO DISPATCH"}
                </button>
                <button
                    className="btn ghost"
                    style={{"padding": "16px 24px", "fontSize": "18px"}}
                    onClick={close_incident_modal}
                >
                    {"CANCEL"}
                </button>
            </div>
        </div>
    );

    modal_element = (
        <div
            style={{"position": "fixed", "top": 0, "left": 0, "right": 0, "bottom": 0, "backgroundColor": "rgba(0,0,0,0.85)", "backdropFilter": "blur(8px)", "zIndex": 100, "display": "flex", "alignItems": "center", "justifyContent": "center", "padding": "20px"}}
            id="modal-incident"
        >
            <div
                style={{"backgroundColor": "#0f172a", "border": "2px solid #ef4444", "borderRadius": "16px", "padding": "28px", "maxWidth": "600px", "width": "100%", "boxShadow": "0 0 40px rgba(239, 68, 68, 0.4)"}}
            >
                <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "20px"}}>
                    <span style={{"fontSize": "22px", "fontWeight": "800", "color": "#ffffff"}}>
                        {"INCIDENT REPORT DISPATCH"}
                    </span>
                    <button
                        style={{"backgroundColor": "transparent", "border": "none", "color": "#94a3b8", "fontSize": "24px", "cursor": "pointer"}}
                        onClick={close_incident_modal}
                    >
                        {"✕"}
                    </button>
                </div>

                {step1_view if incidentStep == 1 else (step2_view if incidentStep == 2 else step3_view)}
            </div>
        </div>
    );

    return
        <div className="driver-shell">
            <div
                style={{"display": "flex", "alignItems": "center", "justifyContent": "space-between", "padding": "16px 24px", "backgroundColor": "#0b1120", "borderBottom": "2px solid rgba(255,255,255,0.1)"}}
            >
                <div style={{"display": "flex", "alignItems": "center", "gap": "14px"}}>
                    <span style={{"fontSize": "24px", "fontWeight": "800", "fontFamily": "var(--mono-font)", "color": "#38bdf8"}}>
                        {active_bus_id}
                    </span>
                    <span className="bus-route-badge" style={{"backgroundColor": "#0284c7"}}>
                        {"EX1-01 EXPRESS"}
                    </span>
                    <LocalBadge label="LIVE GPS" variant="success" pulse={True}/>
                </div>

                <div style={{"display": "flex", "alignItems": "center", "gap": "16px"}}>
                    <div style={{"textAlign": "right", "fontSize": "14px", "color": "#94a3b8"}}>
                        <div>{"SPEED: 64 km/h"}</div>
                        <div style={{"color": "#34d399", "fontWeight": "700"}}>{"HEADING: 315° NW"}</div>
                    </div>
                </div>
            </div>

            <RerouteBanner
                reason={rerouteReason}
                active={hasReroute}
            />

            <DriverInstructionBar
                instruction={instruction}
                distanceKm={distanceKm}
                maneuver={maneuver}
            />

            {incident_notice if incidentSubmitted else None}

            <div style={{"padding": "20px 24px", "display": "flex", "flexDirection": "column", "gap": "20px", "flex": "1"}}>
                <CityMapPlaceholder height="380px" busCount={1}/>

                <div style={{"display": "grid", "gridTemplateColumns": "1fr", "gap": "20px"}}>
                    <NextStopPanel info={stopInfo}/>
                </div>

                <div style={{"marginTop": "auto", "paddingTop": "16px"}}>
                    <button
                        style={{"width": "100%", "padding": "20px", "backgroundColor": "#dc2626", "color": "#ffffff", "fontSize": "22px", "fontWeight": "900", "borderRadius": "12px", "border": "3px solid #ef4444", "cursor": "pointer", "boxShadow": "0 0 24px rgba(220, 38, 38, 0.5)", "display": "flex", "alignItems": "center", "justifyContent": "center", "gap": "14px"}}
                        onClick={open_incident_modal}
                        id="btn-report-incident"
                    >
                        <span style={{"fontSize": "28px"}}>{"⚠️"}</span>
                        <span>{"REPORT INCIDENT (2-TAPS)"}</span>
                    </button>
                </div>
            </div>

            {modal_element if showIncidentModal else None}
        </div>;
}
