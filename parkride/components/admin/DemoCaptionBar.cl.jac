"""DemoCaptionBar Component.

Docked interactive caption bar across the bottom of the Admin Control Room screen.
Displays:
- Current simulation step & total count
- Step hypothesis & proof narrative ("What this step proves")
- Play / Pause, Next, and Restart controls
- Connects to run_demo simulation walker
"""

obj DemoStepInfo {
    has step_index: int = 1,
        total_steps: int = 6,
        title: str = "System Boot & Graph Topology Initialization",
        proves: str = "Demonstrates Object-Spatial graph loading 10 multimodal hubs, road edges, and expressway shuttle fleet.";
}

def:pub DemoCaptionBar(
    step: DemoStepInfo,
    isPlaying: bool = False,
    onPlayPause: Callable[[], None] = None,
    onNext: Callable[[], None] = None,
    onRestart: Callable[[], None] = None
) -> JsxElement {
    play_label = "⏸ PAUSE" if isPlaying else "▶ PLAY DEMO";
    step_indicator = "STEP " + str(step.step_index) + " OF " + str(step.total_steps);

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
                        {step.title}
                    </span>
                    <span style={{"fontSize": "14px", "color": "#94a3b8"}}>
                        <span style={{"color": "#38bdf8", "fontWeight": "700"}}>{"WHAT IT PROVES: "}</span>
                        {step.proves}
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
