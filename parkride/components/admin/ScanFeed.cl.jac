"""ScanFeed Component.

Live stream of commuter QR validation events.
"""

import from .LocalUI { LocalBadge }

def render_scan_item(ev: dict[str, object]) -> JsxElement {
    action = str(ev["action"]);
    scan_id = str(ev["scan_id"]);
    time_str = str(ev["time"]);
    masked = str(ev["masked_passenger"]);
    stop_name = str(ev.get("stop_name", ""));

    badge_var = "success";
    if action == "alighted" {
        badge_var = "";
    } elif action == "walk-in" {
        badge_var = "purple";
    } elif action == "duplicate ignored" {
        badge_var = "warning";
    }

    sub_text = "ID: " + scan_id + (" · " + stop_name if stop_name else "");

    return
        <div key={scan_id} className="feed-item">
            <div style={{"display": "flex", "alignItems": "center", "gap": "14px"}}>
                <span style={{"fontSize": "14px", "fontFamily": "var(--mono-font)", "color": "#38bdf8", "fontWeight": "700"}}>
                    {time_str}
                </span>
                <div style={{"display": "flex", "flexDirection": "column"}}>
                    <span style={{"fontSize": "15px", "fontWeight": "700", "color": "#f8fafc"}}>
                        {masked}
                    </span>
                    <span style={{"fontSize": "12px", "color": "#64748b", "fontFamily": "var(--mono-font)"}}>
                        {sub_text}
                    </span>
                </div>
            </div>

            <LocalBadge label={action} variant={badge_var}/>
        </div>;
}

def:pub ScanFeed(events: list[dict[str, object]]) -> JsxElement {
    return
        <div
            className="feed-box"
            aria-live="polite"
            aria-atomic="false"
            id="admin-scan-feed"
        >
            <div style={{"display": "flex", "alignItems": "center", "justifyContent": "space-between", "marginBottom": "16px"}}>
                <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                    <span style={{"fontSize": "18px", "fontWeight": "800", "color": "#ffffff"}}>
                        {"LIVE SCAN FEED"}
                    </span>
                    <LocalBadge label="REAL-TIME" variant="success" pulse={True}/>
                </div>
                <span style={{"fontSize": "14px", "color": "#94a3b8"}}>
                    {str(len(events)) + " scans recorded"}
                </span>
            </div>

            <div style={{"display": "flex", "flexDirection": "column", "gap": "8px", "maxHeight": "420px", "overflowY": "auto"}}>
                {[render_scan_item(ev) for ev in events]}
            </div>
        </div>;
}
