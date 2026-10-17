"""BusCard component displaying real-time bus telemetry (Milestone 2).

Shows bus ID, route badge, destination, next stop ETA, and live seats left.
"""

def:pub BusCard(
    bus: dict[str, any],
    isSelected: bool = False,
    onSelect: any = None
) -> JsxElement {
    bDict: dict[str, any] = dict(bus);
    bid = str(bDict.get("id", "MB-101"));
    plate = str(bDict.get("plate", "NB-4101"));
    route = str(bDict.get("route", "R1"));
    routeName = str(bDict.get("route_name", "Metro Express"));
    colorName = str(bDict.get("color", "blue"));
    seatsLeft = int(str(bDict.get("seats_left", "40")));
    capacity = int(str(bDict.get("capacity", "40")));
    etaMin = float(str(bDict.get("eta_min", "5.0")));
    alert = bool(bDict.get("alert", False));

    nextStopDict: dict[str, any] = dict(bDict.get("next_stop", {}));
    nextStopName = str(nextStopDict.get("name", "Next Stop"));

    routeBg = "#A855F7" if (colorName == "violet" or colorName == "purple") else ("#14B8A6" if colorName == "teal" else "#3B82F6");
    seatColor = "text-emerald-400 bg-emerald-500/10 border-emerald-500/30" if seatsLeft > 15 else ("text-amber-400 bg-amber-500/10 border-amber-500/30" if seatsLeft > 5 else "text-rose-400 bg-rose-500/10 border-rose-500/30");

    cardBorder = "border-[#FFC21A] bg-[#0F1B2D] ring-2 ring-[#FFC21A]/30 shadow-xl shadow-[#FFC21A]/10" if isSelected else "border-white/10 bg-[#0F1B2D]/90 hover:border-white/20";

    return (
        <div
            onClick={lambda (_e: MouseEvent) { if onSelect { onSelect(bDict); } }}
            className={f"p-4 rounded-2xl border transition-all cursor-pointer relative overflow-hidden {cardBorder}"}
        >
            <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                    <span
                        className="px-2.5 py-1 rounded-lg text-white font-black text-xs shadow-sm"
                        style={{"backgroundColor": routeBg}}
                    >
                        {route}
                    </span>
                    <div>
                        <span className="font-extrabold text-white text-sm block tracking-tight font-mono">{bid}</span>
                        <span className="text-[10px] text-gray-400 block font-mono">{plate}</span>
                    </div>
                </div>

                <div className={f"px-2.5 py-1 rounded-full text-xs font-bold border flex items-center gap-1.5 {seatColor}"}>
                    <span className="w-1.5 h-1.5 rounded-full bg-current animate-pulse" />
                    <span>{f"{seatsLeft} / {capacity} seats"}</span>
                </div>
            </div>

            <div className="mt-2 text-xs font-medium text-gray-300 truncate">
                {routeName}
            </div>

            <div className="mt-3 pt-3 border-t border-white/5 flex items-center justify-between text-xs">
                <div className="flex items-center gap-1.5 text-gray-300">
                    <span className="text-cyan-400">📍</span>
                    <span className="text-gray-400 text-[11px]">Next:</span>
                    <span className="font-bold text-white truncate max-w-[140px]">{nextStopName}</span>
                </div>
                <div className="flex items-center gap-1 text-[11px] font-bold text-amber-300 bg-amber-500/10 px-2 py-0.5 rounded-md border border-amber-500/20">
                    <span>⏱️</span>
                    <span>{f"{etaMin:.1f}m"}</span>
                </div>
            </div>

            {if alert {
                <div className="mt-2.5 px-2.5 py-1 rounded-lg bg-amber-500/20 border border-amber-500/40 text-[10px] text-amber-300 font-bold flex items-center gap-1.5">
                    <span>⚠️</span>
                    <span>Traffic reroute in effect</span>
                </div>;
            }}
        </div>
    );
}
