"""AlertFeed Component.

Live stream of operational system alerts.
Categories:
- mismatch: Passenger booking route/vehicle discrepancy
- auto-cancel: Unclaimed parking bay or expired reservation
- reroute: Dynamic traffic diversion along transit corridor
- incident: Road closure, vehicle breakdown, or bottleneck report
"""

import from .LocalUI { LocalBadge }

obj AlertEvent {
    has id: str,
        time: str,
        category: str,
        title: str,
        details: str,
        severity: str = "warning";
}

def render_alert_item(alt: AlertEvent) -> JsxElement {
    badge_var = "warning";
    if alt.severity == "danger" or alt.category == "incident" {
        badge_var = "danger";
    } elif alt.category == "reroute" {
        badge_var = "warning";
    } elif alt.category == "mismatch" {
        badge_var = "purple";
    }

    border_color = "#ef4444" if badge_var == "danger" else "#f59e0b";

    return
        <div
            key={alt.id}
            className="feed-item"
            style={{"borderLeft": "4px solid " + border_color, "flexDirection": "column", "gap": "6px"}}
        >
            <div style={{"display": "flex", "alignItems": "center", "justifyContent": "space-between", "width": "100%"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                    <LocalBadge label={alt.category} variant={badge_var}/>
                    <span style={{"fontSize": "15px", "fontWeight": "700", "color": "#f8fafc"}}>
                        {alt.title}
                    </span>
                </div>
                <span style={{"fontSize": "13px", "fontFamily": "var(--mono-font)", "color": "#94a3b8"}}>
                    {alt.time}
                </span>
            </div>

            <div style={{"fontSize": "13px", "color": "#cbd5e1", "paddingLeft": "4px"}}>
                {alt.details}
            </div>
        </div>;
}

def:pub AlertFeed(alerts: list[AlertEvent]) -> JsxElement {
    return
        <div
            className="feed-box"
            aria-live="polite"
            aria-atomic="false"
            id="admin-alert-feed"
        >
            <div style={{"display": "flex", "alignItems": "center", "justifyContent": "space-between", "marginBottom": "16px"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                    <span style={{"fontSize": "18px", "fontWeight": "800", "color": "#ffffff"}}>
                        {"INCIDENT & DISPATCH ALERTS"}
                    </span>
                    <LocalBadge label="MONITOR" variant="danger" pulse={True}/>
                </div>
                <span style={{"fontSize": "14px", "color": "#94a3b8"}}>
                    {str(len(alerts)) + " active notices"}
                </span>
            </div>

            <div style={{"display": "flex", "flexDirection": "column", "gap": "8px", "maxHeight": "420px", "overflowY": "auto"}}>
                {[render_alert_item(alt) for alt in alerts]}
            </div>
        </div>;
}
