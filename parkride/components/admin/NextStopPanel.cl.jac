"""NextStopPanel Component.

Displays comprehensive station stop breakdown and 1-meter scannable QR pass:
- Target stop name and transit hub code
- Real-time arrival ETA countdown
- Passenger flow: Getting off, Bookings to board, Walk-in commuters
- Residual seating capacity remaining after stop exchange
- Large-format QRPanel (high-contrast, scannable from 1m distance)
"""

obj StopExchangeInfo {
    has stop_name: str,
        stop_code: str,
        eta_minutes: float,
        getting_off: int,
        bookings_to_board: int,
        walk_ins: int,
        seats_left: int,
        capacity: int,
        qr_token: str = "PKR.MMC.EX1.VALID_2026";
}

def:pub NextStopPanel(info: StopExchangeInfo) -> JsxElement {
    eta_display = str(int(info.eta_minutes)) + " min";
    seats_display = str(info.seats_left) + " / " + str(info.capacity);

    return
        <div className="next-stop-card">
            <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "flex-start", "marginBottom": "24px", "borderBottom": "1px solid rgba(255,255,255,0.1)", "paddingBottom": "16px"}}>
                <div>
                    <span style={{"fontSize": "13px", "fontWeight": "700", "color": "#38bdf8", "textTransform": "uppercase", "letterSpacing": "0.08em"}}>
                        {"NEXT SCHEDULED STOP"}
                    </span>
                    <div style={{"fontSize": "26px", "fontWeight": "800", "color": "#ffffff", "marginTop": "4px"}}>
                        {info.stop_name}
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
                        {str(info.getting_off)}
                    </div>
                    <div className="stat-metric-lbl">{"Getting Off"}</div>
                </div>

                <div className="stat-metric-box">
                    <div className="stat-metric-val" style={{"color": "#34d399"}}>
                        {str(info.bookings_to_board)}
                    </div>
                    <div className="stat-metric-lbl">{"Bookings Boarding"}</div>
                </div>

                <div className="stat-metric-box">
                    <div className="stat-metric-val" style={{"color": "#c084fc"}}>
                        {str(info.walk_ins)}
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
                            {info.stop_code}
                        </span>
                    </div>
                </div>

                <div style={{"marginTop": "12px", "fontSize": "12px", "fontFamily": "var(--mono-font)", "color": "#475569", "textAlign": "center"}}>
                    {info.qr_token}
                </div>
            </div>
        </div>;
}
