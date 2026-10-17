"""Local UI fallback primitives for Admin and Driver views."""

def:pub LocalBadge(label: str, variant: str = "", pulse: bool = False) -> JsxElement {
    cls = "badge" if not variant else ("badge " + variant);
    dot_cls = "pulse-dot live" if pulse else "pulse-dot";
    return
        <span className={cls}>
            {<span className={dot_cls}/> if pulse else None}{label}
        </span>;
}

def:pub LocalButton(
    label: str,
    onClick: Callable[[], None] = None,
    variant: str = "primary",
    disabled: bool = False
) -> JsxElement {
    cls = "btn " + variant;
    return <button className={cls} onClick={onClick} disabled={disabled}>{label}</button>;
}

def:pub CityMapPlaceholder(height: str = "450px", busCount: int = 4) -> JsxElement {
    return
        <div
            className="glass-panel"
            style={{"height": height, "display": "flex", "flexDirection": "column", "alignItems": "center", "justifyContent": "center", "textAlign": "center"}}
        >
            <div style={{"fontSize": "24px", "fontWeight": "800", "color": "#38bdf8", "marginBottom": "8px"}}>
                {"Live CityMap (Shared Component Placeholder)"}
            </div>
            <div style={{"fontSize": "16px", "color": "#94a3b8", "maxWidth": "600px"}}>
                {f"Simulating Colombo Metro Corridors · {str(busCount)} Fleet Vehicles Active (A4 High Level / E02 Expressway / Baseline Rd)"}
            </div>
            <div style={{"marginTop": "16px", "fontSize": "13px", "color": "#64748b"}}>
                {"Will automatically mount components/shared/CityMap.cl.jac when merged by Dev B"}
            </div>
        </div>;
}
