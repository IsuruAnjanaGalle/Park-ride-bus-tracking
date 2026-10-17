"""ScanFeed Component.

Live stream of commuter QR validation events.
Features:
- Live region with aria-live="polite"
- Display fields: Timestamp, Masked Passenger, Scan ID, Event Action
- Action tags: boarded, alighted, walk-in, duplicate ignored
"""

import from .LocalUI { LocalBadge }

obj ScanEvent {
    has time: str,
        masked_passenger: str,
        scan_id: str,
        action: str,
        stop_name: str = "";
}

def render_scan_item(ev: ScanEvent) -> JsxElement {
    badge_var = "success";
    if ev.action == "alighted" {
        badge_var = "";
    } elif ev.action == "walk-in" {
        badge_var = "purple";
    } elif ev.action == "duplicate ignored" {
        badge_var = "warning";
    }

    sub_text = "ID: " + ev.scan_id + (" · " + ev.stop_name if ev.stop_name else "");

    return
        <div key={ev.scan_id} className="feed-item">
            <div style={{"display": "flex", "alignItems": "center", "gap": "14px"}}>
                <span style={{"fontSize": "14px", "fontFamily": "var(--mono-font)", "color": "#38bdf8", "fontWeight": "700"}}>
                    {ev.time}
                </span>
                <div style={{"display": "flex", "flexDirection": "column"}}>
                    <span style={{"fontSize": "15px", "fontWeight": "700", "color": "#f8fafc"}}>
                        {ev.masked_passenger}
                    </span>
                    <span style={{"fontSize": "12px", "color": "#64748b", "fontFamily": "var(--mono-font)"}}>
                        {sub_text}
                    </span>
                </div>
            </div>

            <LocalBadge label={ev.action} variant={badge_var}/>
        </div>;
}

def:pub ScanFeed(events: list[ScanEvent]) -> JsxElement {
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
