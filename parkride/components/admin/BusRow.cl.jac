"""BusRow Component.

Renders an individual transit vehicle row in the Admin Fleet Monitor.
Accepts a dictionary representing telemetry data from track_bus / fleet walker.
"""

def:pub BusRow(
    bus: dict[str, object],
    isSelected: bool = False,
    onClick: Callable[[str], None] = None
) -> JsxElement {
    bus_id = str(bus["id"]);
    route = str(bus["route"]);
    plate = str(bus["plate"]);
    next_stop = str(bus["next_stop"]);
    color = str(bus.get("color", "#0284c7"));
    alert = bool(bus.get("alert", False));

    passengers = int(bus["passengers"]);
    capacity = int(bus["capacity"]);
    eta = float(bus["eta"]);

    pct = int((passengers / capacity) * 100) if capacity > 0 else 0;

    load_color = "#10b981";
    if pct > 85 {
        load_color = "#ef4444";
    } elif pct > 65 {
        load_color = "#f59e0b";
    }

    eta_str = str(int(eta)) + " min";
    load_str = str(passengers) + " / " + str(capacity) + " (" + str(pct) + "%)";
    row_cls = "bus-row bus-row-active" if isSelected else "bus-row";

    def handle_click {
        if onClick {
            onClick(bus_id);
        }
    }

    return
        <div
            className={row_cls}
            onClick={handle_click}
            id={"bus-row-" + bus_id}
            role="button"
            tabIndex={0}
            aria-label={"Bus " + plate + " Route " + route}
        >
            <div style={{"display": "flex", "alignItems": "center", "gap": "16px"}}>
                <span
                    className="bus-route-badge"
                    style={{"backgroundColor": color}}
                >
                    {route}
                </span>

                <div style={{"display": "flex", "flexDirection": "column"}}>
                    <span className="bus-plate">{plate}</span>
                    <span style={{"fontSize": "13px", "color": "#94a3b8"}}>
                        {"Next: "}
                        <span style={{"color": "#f1f5f9", "fontWeight": "700"}}>{next_stop}</span>
                    </span>
                </div>
            </div>

            <div style={{"display": "flex", "alignItems": "center", "gap": "28px"}}>
                <div style={{"textAlign": "right"}}>
                    <div style={{"fontSize": "12px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                        {"Arrival ETA"}
                    </div>
                    <span style={{"fontSize": "18px", "fontWeight": "700", "color": "#38bdf8", "fontFamily": "var(--mono-font)"}}>
                        {eta_str}
                    </span>
                </div>

                <div style={{"display": "flex", "flexDirection": "column", "gap": "4px"}}>
                    <div style={{"display": "flex", "justifyContent": "space-between", "fontSize": "12px", "color": "#94a3b8"}}>
                        <span>{"Load"}</span>
                        <span style={{"fontWeight": "700", "color": load_color}}>{load_str}</span>
                    </div>
                    <div className="load-bar-wrap">
                        <div
                            className="load-bar-fill"
                            style={{"width": str(min(pct, 100)) + "%", "backgroundColor": load_color}}
                        />
                    </div>
                </div>

                <div style={{"width": "20px", "display": "flex", "alignItems": "center", "justifyContent": "center"}}>
                    {<div className="alert-dot" title="Active Alert"/> if alert else None}
                </div>
            </div>
        </div>;
}
