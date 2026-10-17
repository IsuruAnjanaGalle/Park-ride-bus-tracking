"""AlertFeed Component.

Live stream of operational system alerts.
"""

import from .LocalUI { LocalBadge }

def render_alert_item(alt: dict[str, object]) -> JsxElement {
    category = str(alt["category"]);
    severity = str(alt.get("severity", "warning"));
    alert_id = str(alt["id"]);
    time_str = str(alt["time"]);
    title = str(alt["title"]);
    details = str(alt["details"]);

    badge_var = "warning";
    if severity == "danger" or category == "incident" {
        badge_var = "danger";
    } elif category == "reroute" {
        badge_var = "warning";
    } elif category == "mismatch" {
        badge_var = "purple";
    }

    border_color = "#ef4444" if badge_var == "danger" else "#f59e0b";

    return
        <div
            key={alert_id}
            className="feed-item"
            style={{"borderLeft": "4px solid " + border_color, "flexDirection": "column", "gap": "6px"}}
        >
            <div style={{"display": "flex", "alignItems": "center", "justifyContent": "space-between", "width": "100%"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                    <LocalBadge label={category} variant={badge_var}/>
                    <span style={{"fontSize": "15px", "fontWeight": "700", "color": "#f8fafc"}}>
                        {title}
                    </span>
                </div>
                <span style={{"fontSize": "13px", "fontFamily": "var(--mono-font)", "color": "#94a3b8"}}>
                    {time_str}
                </span>
            </div>

            <div style={{"fontSize": "13px", "color": "#cbd5e1", "paddingLeft": "4px"}}>
                {details}
            </div>
        </div>;
}

def:pub AlertFeed(alerts: list[dict[str, object]]) -> JsxElement {
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
