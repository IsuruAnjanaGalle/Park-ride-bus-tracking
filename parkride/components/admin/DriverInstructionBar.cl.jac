"""DriverInstructionBar Component.

High-contrast, non-glass solid instruction bar for in-cab driver navigation.
Features:
- Solid dark green background (optimal daylight/night in-cab legibility)
- Clear turn-by-turn guidance instruction
- High-visibility distance remaining chip
"""

def:pub DriverInstructionBar(
    instruction: str = "Turn right toward Nawala",
    distanceKm: float = 1.3,
    maneuver: str = "right"
) -> JsxElement {
    arrow = "➜";
    if maneuver == "left" {
        arrow = "↰";
    } elif maneuver == "right" {
        arrow = "↱";
    } elif maneuver == "straight" {
        arrow = "↑";
    }

    dist_str = str(distanceKm) + " km";

    return
        <div className="driver-bar-solid" id="driver-instruction-bar">
            <div style={{"display": "flex", "alignItems": "center", "gap": "18px"}}>
                <span style={{"fontSize": "36px", "color": "#34d399", "lineHeight": "1"}}>
                    {arrow}
                </span>
                <span className="driver-instruction-text">
                    {instruction}
                </span>
            </div>

            <div className="driver-dist-badge">
                {dist_str}
            </div>
        </div>;
}
