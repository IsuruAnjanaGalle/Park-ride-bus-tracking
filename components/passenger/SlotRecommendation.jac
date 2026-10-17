"""SlotRecommendation component for Park & Ride Sri Lanka.
Renders top 3 algorithmic slot recommendations with reasons and selection buttons.
"""

def:pub SlotRecommendation(
    recommendation: dict[str, any],
    selectedSlotCode: str,
    onSelectSlot: Callable[[str], None] = lambda (_code: str) {}
) -> JsxElement {
    rawOpts = recommendation.get("options", []);
    options: list[dict[str, any]] = [dict(o) for o in rawOpts] if rawOpts else [];
    fallbackMsg = recommendation.get("fallback");
    zone = str(recommendation.get("zone", "F"));
    stayHours = str(recommendation.get("stay_hours", "2"));
    slotType = str(recommendation.get("slot_type", "C"));

    slotTypeName = "EV Charging (Type E)" if slotType == "E"
        else ("Foot Cycle (Type B)" if slotType == "B"
        else ("Motorcycle (Type M)" if slotType == "M"
        else "Car (Type C)"));

    ruleText = "<3h front" if zone == "F" else ("3-8h mid" if zone == "M" else ">8h rear");

    return <div className="flex flex-col gap-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 p-3.5 rounded-2xl bg-gradient-to-r from-[#FFC21A]/15 to-transparent border border-[#FFC21A]/30">
            <div>
                <span className="text-[11px] font-bold uppercase tracking-wider text-[#FFC21A]">
                    Recommended Zone: Zone {zone}
                </span>
                <p className="text-xs text-white font-medium mt-0.5">
                    Optimized for {stayHours}h stay duration ({slotTypeName})
                </p>
            </div>
            <span className="text-[11px] text-gray-400">
                Rule: {ruleText}
            </span>
        </div>

        {if fallbackMsg {
            <div className="p-3 rounded-xl bg-amber-500/15 border border-amber-500/30 text-amber-200 text-xs flex items-center gap-2">
                <span>⚠️</span>
                <span>{str(fallbackMsg)}</span>
            </div>
        }}

        <div className="grid grid-cols-1 gap-3">
            {for opt in options {
                slot = dict(opt.get("slot", {}));
                code = str(slot.get("code", ""));
                rank = int(opt.get("rank", 1));
                optZone = str(opt.get("zone", zone));
                reason = str(opt.get("reason", ""));
                isSel = code == selectedSlotCode;
                accessible = bool(slot.get("accessible", False));
                chargerKw = int(slot.get("charger_kw", 0));
                chargerType = str(slot.get("charger_type", ""));

                rankTitle = "⭐ Top Recommendation" if rank == 1
                    else ("Alternative in Zone" if rank == 2 else "Nearby Zone Option");
                rankBadge = "bg-[#FFC21A] text-[#0F1B2D]" if rank == 1
                    else "bg-white/10 text-white";

                borderCls = "border-[#FFC21A] bg-[#FFC21A]/10 ring-2 ring-[#FFC21A]/30 shadow-lg" if isSel
                    else "border-white/10 bg-white/[0.03] hover:border-white/30 hover:bg-white/[0.06]";

                <div
                    key={code}
                    onClick={lambda (_e: MouseEvent) { onSelectSlot(code); }}
                    className={f"relative cursor-pointer rounded-2xl border-2 p-4 transition-all duration-200 {borderCls}"}
                >
                    <div className="flex items-start justify-between gap-3">
                        <div className="flex-1">
                            <div className="flex items-center gap-2">
                                <span className={f"px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider {rankBadge}"}>
                                    {rankTitle}
                                </span>
                                {if accessible {
                                    <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-blue-500/20 text-blue-300 border border-blue-500/30">
                                        ♿ Accessible
                                    </span>
                                }}
                                {if chargerKw > 0 {
                                    <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                                        ⚡ {chargerKw} kW {chargerType}
                                    </span>
                                }}
                            </div>

                            <div className="mt-2 flex items-baseline gap-2">
                                <span className="text-xl font-black tracking-tight text-white">{code}</span>
                                <span className="text-xs font-semibold text-gray-400">Zone {optZone}</span>
                            </div>

                            <p className="mt-1.5 text-xs text-gray-300 leading-relaxed">
                                {reason}
                            </p>
                        </div>

                        <div className="flex flex-col items-end gap-2">
                            {if isSel {
                                <div className="px-3 py-1.5 rounded-xl bg-[#FFC21A] text-[#0F1B2D] text-xs font-black flex items-center gap-1 shadow-md">
                                    <span>Selected</span>
                                    <span>✓</span>
                                </div>
                            } else {
                                <button
                                    type="button"
                                    className="px-3 py-1.5 rounded-xl border border-white/20 text-xs font-semibold text-white hover:bg-white/10 transition-colors"
                                >
                                    Select
                                </button>
                            }}
                        </div>
                    </div>
                </div>
            }}
        </div>
    </div>;
}
