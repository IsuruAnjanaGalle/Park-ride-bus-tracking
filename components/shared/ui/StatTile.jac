"""StatTile component: metric & telemetry stat tile for parking, bus & terminal counts."""

def:pub StatTile(
    label: str,
    value: str,
    subtext: str = "",
    trend: str = "",
    trendPositive: bool = True,
    icon: JsxElement | None = None,
    color: str = "yellow"
) -> JsxElement {
    accentText = "text-[#FFC21A]" if color == "yellow"
        else ("text-emerald-400" if color == "green"
        else ("text-blue-400" if color == "blue"
        else ("text-purple-400" if color == "purple"
        else ("text-rose-400" if color == "red"
        else "text-white"))));

    glowBg = "bg-[#FFC21A]/10 border-[#FFC21A]/30" if color == "yellow"
        else ("bg-emerald-500/10 border-emerald-500/30" if color == "green"
        else ("bg-blue-500/10 border-blue-500/30" if color == "blue"
        else ("bg-purple-500/10 border-purple-500/30" if color == "purple"
        else "bg-white/5 border-white/10")));

    trendColor = "text-emerald-400" if trendPositive else "text-rose-400";
    trendArrow = "↑" if trendPositive else "↓";

    cardCls = f"relative p-4 rounded-2xl bg-[#0F1B2D]/80 backdrop-blur-md border {glowBg} shadow-lg transition-transform hover:-translate-y-0.5 duration-200 overflow-hidden";
    iconBoxCls = f"p-1.5 rounded-lg bg-white/5 {accentText}";
    valCls = f"text-2xl font-black tracking-tight font-mono {accentText}";
    trendCls = f"text-xs font-semibold {trendColor} flex items-center";

    return <div className={cardCls}>
        <div className="flex items-center justify-between mb-1.5">
            <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">{label}</span>
            {<div className={iconBoxCls}>
                {icon}
            </div> if icon else None}
        </div>

        <div className="flex items-baseline gap-2">
            <span className={valCls}>{value}</span>
            {<span className={trendCls}>
                <span>{trendArrow}</span>
                <span className="ml-0.5">{trend}</span>
            </span> if trend else None}
        </div>

        {<p className="mt-1 text-xs text-gray-400 font-medium truncate">{subtext}</p> if subtext else None}
    </div>;
}
