"""TerminalPicker component for Park & Ride Sri Lanka.
Allows passenger to choose between MKB, KDW, KSB, PTH with live slot counts.
"""

def:pub TerminalPicker(
    terminals: list[dict],
    selectedTerminal: str,
    selectedVehicle: str = "C",
    onSelect: Callable[[str], None] = lambda (_c: str) {}
) -> JsxElement {
    vehicleKey = "E" if selectedVehicle == "E" else ("B" if selectedVehicle == "B" else ("M" if selectedVehicle == "M" else "C"));

    return <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold uppercase tracking-wider text-gray-300">
                1. Select Terminal Hub
            </h3>
            <span className="text-xs text-[#FFC21A] font-medium">4 Metro Hubs Available</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {for t in terminals {
                tCode = str(t.get("code", ""));
                tName = str(t.get("name", ""));
                tJunction = str(t.get("junction", ""));
                isSel = tCode == selectedTerminal;
                hasFullGrid = bool(t.get("full_grid", False));
                
                counts = dict(t.get("counts", {}));
                vCounts = dict(counts.get(vehicleKey, {}));
                freeCount = int(vCounts.get("free", 0));
                totalCount = int(vCounts.get("total", 0));

                chargers = list(t.get("chargers", []));
                chargerCount = len(chargers);

                cardBorder = "border-[#FFC21A] bg-[#FFC21A]/10 shadow-lg shadow-[#FFC21A]/10" if isSel
                    else "border-white/10 bg-white/[0.03] hover:border-white/30 hover:bg-white/[0.06]";

                <div
                    key={tCode}
                    onClick={lambda (_e: MouseEvent) { onSelect(tCode); }}
                    className={f"relative cursor-pointer rounded-2xl border-2 p-4 transition-all duration-200 {cardBorder}"}
                >
                    <div className="flex items-start justify-between">
                        <div>
                            <div className="flex items-center gap-2">
                                <span className="text-base font-extrabold text-white">{tName}</span>
                                <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-white/10 text-gray-300">
                                    {tCode}
                                </span>
                            </div>
                            <span className="text-xs text-gray-400 mt-0.5 block">Junction: {tJunction}</span>
                        </div>
                        {if isSel {
                            <div className="w-6 h-6 rounded-full bg-[#FFC21A] text-[#0F1B2D] flex items-center justify-center text-xs font-black shadow-md">
                                ✓
                            </div>
                        } else {
                            <div className="w-6 h-6 rounded-full border border-white/20" />
                        }}
                    </div>

                    <div className="mt-4 flex items-center justify-between text-xs pt-3 border-t border-white/10">
                        <div className="flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                            <span className="font-bold text-emerald-300">{freeCount} Free</span>
                            <span className="text-gray-500">/ {totalCount} Total</span>
                        </div>
                        {if hasFullGrid {
                            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#22D3EE]/20 text-[#22D3EE] border border-[#22D3EE]/30">
                                Interactive Grid
                            </span>
                        } else {
                            <span className="text-[10px] text-gray-400">Standard Bay</span>
                        }}
                    </div>

                    {if chargerCount > 0 {
                        <div className="mt-2 text-[11px] text-amber-300/80 flex items-center gap-1">
                            <span>⚡</span>
                            <span>{chargerCount} EV Fast Charger Banks</span>
                        </div>
                    }}
                </div>
            }}
        </div>
    </div>;
}
