"""SlotGrid component for Park & Ride Sri Lanka.
Renders an interactive parking bay grid with Zone grouping, status filtering, and EV indicators.
"""

def:pub SlotGrid(
    slots: list[dict],
    selectedSlotCode: str,
    recommendedSlotCode: str = "",
    onSelectSlot: Callable[[str], None] = lambda (_code: str) {}
) -> JsxElement {
    has activeZone: str = "ALL";
    has activeState: str = "ALL";

    return <div className="flex flex-col gap-4 rounded-3xl bg-[#0F1B2D]/90 border border-white/10 p-5 backdrop-blur-xl">
        # Header and filters
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-white/10 pb-4">
            <div>
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                    <span>Makumbura Terminal Parking Bays</span>
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#FFC21A]/20 text-[#FFC21A]">
                        Live Grid
                    </span>
                </h3>
                <p className="text-xs text-gray-400 mt-0.5">Select a free bay to reserve your parking.</p>
            </div>

            # Zone switchers
            <div className="flex items-center gap-1.5 p-1 rounded-xl bg-white/[0.04] border border-white/10 text-xs">
                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { activeZone = "ALL"; }}
                    className={f"px-2.5 py-1 rounded-lg font-bold transition-colors {'bg-[#FFC21A] text-[#0F1B2D]' if activeZone == 'ALL' else 'text-gray-400 hover:text-white'}"}
                >
                    All Zones
                </button>
                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { activeZone = "F"; }}
                    className={f"px-2.5 py-1 rounded-lg font-bold transition-colors {'bg-[#FFC21A] text-[#0F1B2D]' if activeZone == 'F' else 'text-gray-400 hover:text-white'}"}
                >
                    Front (F)
                </button>
                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { activeZone = "M"; }}
                    className={f"px-2.5 py-1 rounded-lg font-bold transition-colors {'bg-[#FFC21A] text-[#0F1B2D]' if activeZone == 'M' else 'text-gray-400 hover:text-white'}"}
                >
                    Middle (M)
                </button>
                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { activeZone = "R"; }}
                    className={f"px-2.5 py-1 rounded-lg font-bold transition-colors {'bg-[#FFC21A] text-[#0F1B2D]' if activeZone == 'R' else 'text-gray-400 hover:text-white'}"}
                >
                    Rear (R)
                </button>
            </div>
        </div>

        # Legend bar
        <div className="flex flex-wrap items-center gap-3 text-[11px] text-gray-400 py-1">
            <span className="flex items-center gap-1">
                <span className="w-3 h-3 rounded bg-emerald-500/20 border border-emerald-500/50" />
                <span className="text-emerald-300">Free</span>
            </span>
            <span className="flex items-center gap-1">
                <span className="w-3 h-3 rounded bg-[#FFC21A]/20 border border-[#FFC21A]" />
                <span className="text-[#FFC21A]">Recommended</span>
            </span>
            <span className="flex items-center gap-1">
                <span className="w-3 h-3 rounded bg-amber-500/20 border border-amber-500/50" />
                <span className="text-amber-300">Booked</span>
            </span>
            <span className="flex items-center gap-1">
                <span className="w-3 h-3 rounded bg-white/5 border border-white/10 opacity-50" />
                <span>Occupied</span>
            </span>
            <span className="flex items-center gap-1">
                <span>⚡</span>
                <span className="text-cyan-300">EV Charger</span>
            </span>
            <span className="flex items-center gap-1">
                <span>♿</span>
                <span className="text-blue-300">Accessible</span>
            </span>
        </div>

        # Slot grid items
        <div className="max-h-80 overflow-y-auto pr-1">
            <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-2">
                {for s in slots {
                    code = str(s.get("code", ""));
                    sZone = str(s.get("zone", ""));
                    state = str(s.get("state", "free"));
                    sType = str(s.get("type", "C"));
                    accessible = bool(s.get("accessible", False));
                    chargerKw = int(s.get("charger_kw", 0));

                    matchesZone = activeZone == "ALL" or sZone == activeZone;
                    matchesState = activeState == "ALL" or state == activeState;

                    if matchesZone and matchesState {
                        isRecommended = code == recommendedSlotCode;
                        isSelected = code == selectedSlotCode;
                        isFree = state == "free";

                        bgBorder = "ring-2 ring-[#FFC21A] bg-[#FFC21A]/20 border-[#FFC21A] text-white shadow-lg shadow-[#FFC21A]/20" if isSelected
                            else ("border-[#FFC21A] bg-[#FFC21A]/10 text-amber-200 animate-pulse" if isRecommended
                            else ("border-emerald-500/40 bg-emerald-500/10 text-emerald-200 hover:border-emerald-400 hover:bg-emerald-500/20 cursor-pointer" if isFree
                            else ("border-amber-500/30 bg-amber-500/5 text-amber-400/60 cursor-not-allowed" if state == "booked"
                            else "border-white/5 bg-white/[0.02] text-gray-500 cursor-not-allowed opacity-60")));

                        <div
                            key={code}
                            onClick={lambda (_e: MouseEvent) { if isFree { onSelectSlot(code); } }}
                            className={f"relative flex flex-col justify-between p-2.5 rounded-xl border text-xs transition-all {bgBorder}"}
                        >
                            <div className="flex items-center justify-between">
                                <span className="font-extrabold tracking-tight text-[11px] truncate">
                                    {code.replace("MKB-", "")}
                                </span>
                                {if isRecommended {
                                    <span className="text-[10px]">⭐</span>
                                } elif chargerKw > 0 {
                                    <span className="text-[10px] text-cyan-300">⚡</span>
                                } elif accessible {
                                    <span className="text-[10px] text-blue-300">♿</span>
                                }}
                            </div>

                            <div className="mt-2 flex items-center justify-between text-[10px]">
                                <span className="text-gray-400 font-mono">Z-{sZone}</span>
                                <span className={f"font-semibold uppercase {'text-emerald-300' if isFree else ('text-amber-400' if state == 'booked' else 'text-gray-500')}"}>
                                    {state}
                                </span>
                            </div>
                        </div>;
                    }
                }}
            </div>
        </div>
    </div>;
}
