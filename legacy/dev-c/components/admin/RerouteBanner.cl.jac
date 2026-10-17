"""RerouteBanner Component.

High-priority emergency reroute alert banner for driver and dispatch consoles.
Features:
- Solid amber warning background
- Dispatch detour rationale
- Accessibility: role="alert", aria-live="assertive"
"""

def:pub RerouteBanner(
    reason: str = "High Level Road Jam · Detour via Baseline Expressway",
    active: bool = True
) -> JsxElement {
    if not active or not reason {
        return <div aria-live="assertive" id="driver-reroute-banner"/>;
    }

    return
        <div
            className="reroute-banner-solid"
            role="alert"
            aria-live="assertive"
            id="driver-reroute-banner"
        >
            <div style={{"fontSize": "30px", "lineHeight": "1"}}>
                {"⚠️"}
            </div>

            <div style={{"display": "flex", "flexDirection": "column"}}>
                <span style={{"fontSize": "13px", "fontWeight": "800", "color": "#fef08a", "textTransform": "uppercase", "letterSpacing": "0.08em"}}>
                    {"NEW ROUTE ASSIGNED BY DISPATCH"}
                </span>
                <span style={{"fontSize": "20px", "fontWeight": "800", "color": "#ffffff"}}>
                    {reason}
                </span>
            </div>
        </div>;
}
