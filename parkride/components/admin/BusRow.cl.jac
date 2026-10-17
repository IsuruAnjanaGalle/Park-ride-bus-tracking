"""BusRow Component.

Renders an individual transit vehicle row in the Admin Fleet Monitor.
"""

obj BusInfo {
    has id: str,
        route: str,
        plate: str,
        next_stop: str,
        eta: float,
        passengers: int,
        capacity: int,
        color: str = "#0284c7",
        alert: bool = False;
}

def:pub BusRow(
    bus: BusInfo,
    isSelected: bool = False,
    onClick: Callable[[str], None] = None
) -> JsxElement {
    pct = int((bus.passengers / bus.capacity) * 100) if bus.capacity > 0 else 0;

    load_color = "#10b981";
    if pct > 85 {
        load_color = "#ef4444";
    } elif pct > 65 {
        load_color = "#f59e0b";
    }

    eta_str = str(int(bus.eta)) + " min";
    load_str = str(bus.passengers) + " / " + str(bus.capacity) + " (" + str(pct) + "%)";
    row_cls = "bus-row bus-row-active" if isSelected else "bus-row";
    bus_id = bus.id;

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
            aria-label={"Bus " + bus.plate + " Route " + bus.route}
        >
            <div style={{"display": "flex", "alignItems": "center", "gap": "16px"}}>
                <span
                    className="bus-route-badge"
                    style={{"backgroundColor": bus.color}}
                >
                    {bus.route}
                </span>

                <div style={{"display": "flex", "flexDirection": "column"}}>
                    <span className="bus-plate">{bus.plate}</span>
                    <span style={{"fontSize": "13px", "color": "#94a3b8"}}>
                        {"Next: "}
                        <span style={{"color": "#f1f5f9", "fontWeight": "700"}}>{bus.next_stop}</span>
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
                    {<div className="alert-dot" title="Active Alert"/> if bus.alert else None}
                </div>
            </div>
        </div>;
}
