"""DemoCaptionBar Component.

Docked interactive caption bar across the bottom of the Admin Control Room screen.
"""

def:pub DemoCaptionBar(
    step: dict[str, object],
    isPlaying: bool = False,
    onPlayPause: Callable[[], None] = None,
    onNext: Callable[[], None] = None,
    onRestart: Callable[[], None] = None
) -> JsxElement {
    step_index = int(step["step_index"]);
    total_steps = int(step["total_steps"]);
    title = str(step["title"]);
    proves = str(step["proves"]);

    play_label = "⏸ PAUSE" if isPlaying else "▶ PLAY DEMO";
    step_indicator = "STEP " + str(step_index) + " OF " + str(total_steps);

    return
        <div
            className="admin-glass-panel"
            style={{"position": "sticky", "bottom": "16px", "marginTop": "24px", "padding": "16px 28px", "display": "flex", "alignItems": "center", "justifyContent": "space-between", "gap": "24px", "backgroundColor": "rgba(11, 17, 32, 0.94)", "border": "2px solid #0284c7", "boxShadow": "0 0 30px rgba(2, 132, 199, 0.4)", "zIndex": 40}}
            id="admin-demo-caption-bar"
        >
            <div style={{"display": "flex", "alignItems": "center", "gap": "18px", "flex": "1"}}>
                <span
                    className="brand-tag"
                    style={{"backgroundColor": "#0284c7", "fontSize": "14px", "padding": "6px 14px"}}
                >
                    {step_indicator}
                </span>

                <div style={{"display": "flex", "flexDirection": "column", "gap": "2px"}}>
                    <span style={{"fontSize": "18px", "fontWeight": "800", "color": "#ffffff"}}>
                        {title}
                    </span>
                    <span style={{"fontSize": "14px", "color": "#94a3b8"}}>
                        <span style={{"color": "#38bdf8", "fontWeight": "700"}}>{"WHAT IT PROVES: "}</span>
                        {proves}
                    </span>
                </div>
            </div>

            <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                <button
                    className={"btn " + ("success" if isPlaying else "primary")}
                    style={{"padding": "10px 22px", "fontSize": "15px"}}
                    onClick={onPlayPause}
                    id="btn-demo-play-pause"
                >
                    {play_label}
                </button>

                <button
                    className="btn ghost"
                    style={{"padding": "10px 20px", "fontSize": "15px"}}
                    onClick={onNext}
                    id="btn-demo-next"
                >
                    {"NEXT ❯"}
                </button>

                <button
                    className="btn ghost"
                    style={{"padding": "10px 16px", "fontSize": "15px"}}
                    onClick={onRestart}
                    id="btn-demo-restart"
                    title="Restart Demo"
                >
                    {"↺ RESTART"}
                </button>
            </div>
        </div>;
}
