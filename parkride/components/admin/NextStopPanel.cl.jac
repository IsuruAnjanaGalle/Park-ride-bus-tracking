"""NextStopPanel Component.

Displays comprehensive station stop breakdown and 1-meter scannable QR pass.
"""

def:pub NextStopPanel(info: dict[str, object]) -> JsxElement {
    stop_name = str(info["stop_name"]);
    stop_code = str(info["stop_code"]);
    eta_minutes = float(info["eta_minutes"]);
    getting_off = int(info["getting_off"]);
    bookings_to_board = int(info["bookings_to_board"]);
    walk_ins = int(info["walk_ins"]);
    seats_left = int(info["seats_left"]);
    capacity = int(info["capacity"]);
    qr_token = str(info.get("qr_token", "PKR.MMC.EX1.VALID_2026"));

    eta_display = str(int(eta_minutes)) + " min";
    seats_display = str(seats_left) + " / " + str(capacity);

    return
        <div className="next-stop-card">
            <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "flex-start", "marginBottom": "24px", "borderBottom": "1px solid rgba(255,255,255,0.1)", "paddingBottom": "16px"}}>
                <div>
                    <span style={{"fontSize": "13px", "fontWeight": "700", "color": "#38bdf8", "textTransform": "uppercase", "letterSpacing": "0.08em"}}>
                        {"NEXT SCHEDULED STOP"}
                    </span>
                    <div style={{"fontSize": "26px", "fontWeight": "800", "color": "#ffffff", "marginTop": "4px"}}>
                        {stop_name}
                    </div>
                </div>

                <div style={{"textAlign": "right"}}>
                    <span style={{"fontSize": "13px", "color": "#94a3b8", "textTransform": "uppercase"}}>
                        {"ESTIMATED ARRIVAL"}
                    </span>
                    <div style={{"fontSize": "30px", "fontWeight": "800", "color": "#38bdf8", "fontFamily": "var(--mono-font)"}}>
                        {eta_display}
                    </div>
                </div>
            </div>

            <div style={{"display": "grid", "gridTemplateColumns": "repeat(4, 1fr)", "gap": "16px", "marginBottom": "24px"}}>
                <div className="stat-metric-box">
                    <div className="stat-metric-val" style={{"color": "#f87171"}}>
                        {str(getting_off)}
                    </div>
                    <div className="stat-metric-lbl">{"Getting Off"}</div>
                </div>

                <div className="stat-metric-box">
                    <div className="stat-metric-val" style={{"color": "#34d399"}}>
                        {str(bookings_to_board)}
                    </div>
                    <div className="stat-metric-lbl">{"Bookings Boarding"}</div>
                </div>

                <div className="stat-metric-box">
                    <div className="stat-metric-val" style={{"color": "#c084fc"}}>
                        {str(walk_ins)}
                    </div>
                    <div className="stat-metric-lbl">{"Walk-Ins"}</div>
                </div>

                <div className="stat-metric-box">
                    <div className="stat-metric-val" style={{"color": "#38bdf8"}}>
                        {seats_display}
                    </div>
                    <div className="stat-metric-lbl">{"Seats Left Post-Stop"}</div>
                </div>
            </div>

            <div className="qr-panel-wrap">
                <div className="qr-scan-title">
                    {"STOP QR PASS · SCANNABLE AT 1 METER"}
                </div>

                <div
                    style={{"width": "220px", "height": "220px", "backgroundColor": "#000000", "padding": "12px", "borderRadius": "8px", "display": "flex", "flexDirection": "column", "alignItems": "center", "justifyContent": "center", "position": "relative"}}
                >
                    <div style={{"position": "absolute", "top": "12px", "left": "12px", "width": "44px", "height": "44px", "border": "6px solid #ffffff"}}/>
                    <div style={{"position": "absolute", "top": "12px", "right": "12px", "width": "44px", "height": "44px", "border": "6px solid #ffffff"}}/>
                    <div style={{"position": "absolute", "bottom": "12px", "left": "12px", "width": "44px", "height": "44px", "border": "6px solid #ffffff"}}/>

                    <div style={{"width": "90px", "height": "90px", "backgroundColor": "#ffffff", "display": "flex", "alignItems": "center", "justifyContent": "center", "borderRadius": "4px"}}>
                        <span style={{"fontSize": "16px", "fontWeight": "900", "color": "#000000", "fontFamily": "var(--mono-font)"}}>
                            {stop_code}
                        </span>
                    </div>
                </div>

                <div style={{"marginTop": "12px", "fontSize": "12px", "fontFamily": "var(--mono-font)", "color": "#475569", "textAlign": "center"}}>
                    {qr_token}
                </div>
            </div>
        </div>;
}
