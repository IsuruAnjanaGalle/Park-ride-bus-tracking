"""VehicleFilter component for Park & Ride Sri Lanka.
Handles vehicle selection, EV charging status, accessible parking, and stay timing with Zone prediction.
"""

def:pub VehicleFilter(
    selectedVehicle: str,
    evChoice: str,
    accessible: bool,
    arrival: str,
    returnBy: str,
    onChangeVehicle: Callable[[str], None] = lambda (_v: str) {},
    onChangeEv: Callable[[str], None] = lambda (_e: str) {},
    onToggleAccessible: Callable[[bool], None] = lambda (_a: bool) {},
    onChangeArrival: Callable[[str], None] = lambda (_t: str) {},
    onChangeReturnBy: Callable[[str], None] = lambda (_t: str) {}
) -> JsxElement {
    # Calculate stay duration
    arrParts = arrival.split(":") if ":" in arrival else ["8", "00"];
    retParts = returnBy.split(":") if ":" in returnBy else ["10", "00"];
    arrH = int(arrParts[0]) if len(arrParts) > 0 else 8;
    retH = int(retParts[0]) if len(retParts) > 0 else 10;
    diffH = retH - arrH if retH >= arrH else (24 - arrH + retH);
    durationHours = max(diffH, 1);

    zoneLetter = "F" if durationHours < 3 else ("M" if durationHours <= 8 else "R");
    zoneLabel = "Front Zone (Quick Stay)" if zoneLetter == "F"
        else ("Middle Zone (Standard)" if zoneLetter == "M" else "Rear Zone (Long Stay / Overnight)");

    return <div className="flex flex-col gap-5 rounded-2xl bg-[#0F1B2D]/80 border border-white/10 p-5 backdrop-blur-md">
        <div>
            <div className="flex items-center justify-between mb-2.5">
                <h4 className="text-xs font-bold uppercase tracking-wider text-gray-300">
                    2. Select Vehicle Type
                </h4>
                <span className="text-[11px] text-[#FFC21A] font-medium">Bicycles, Motorcycles &amp; Cars</span>
            </div>

            <div className="grid grid-cols-3 gap-2">
                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { onChangeVehicle("B"); }}
                    className={f"flex flex-col items-center justify-center p-3 rounded-xl border transition-all {'border-[#FFC21A] bg-[#FFC21A]/15 text-[#FFC21A]' if selectedVehicle == 'B' else 'border-white/10 bg-white/[0.03] text-gray-400 hover:text-white hover:bg-white/[0.06]'}"}
                >
                    <span className="text-2xl mb-1">🚲</span>
                    <span className="text-xs font-bold">Foot Cycle</span>
                    <span className="text-[10px] text-gray-500">Type B</span>
                </button>

                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { onChangeVehicle("M"); }}
                    className={f"flex flex-col items-center justify-center p-3 rounded-xl border transition-all {'border-[#FFC21A] bg-[#FFC21A]/15 text-[#FFC21A]' if selectedVehicle == 'M' else 'border-white/10 bg-white/[0.03] text-gray-400 hover:text-white hover:bg-white/[0.06]'}"}
                >
                    <span className="text-2xl mb-1">🛵</span>
                    <span className="text-xs font-bold">Motorbike</span>
                    <span className="text-[10px] text-gray-500">Type M</span>
                </button>

                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { onChangeVehicle("C"); }}
                    className={f"flex flex-col items-center justify-center p-3 rounded-xl border transition-all {'border-[#FFC21A] bg-[#FFC21A]/15 text-[#FFC21A]' if selectedVehicle == 'C' else 'border-white/10 bg-white/[0.03] text-gray-400 hover:text-white hover:bg-white/[0.06]'}"}
                >
                    <span className="text-2xl mb-1">🚗</span>
                    <span className="text-xs font-bold">Car / SUV</span>
                    <span className="text-[10px] text-gray-500">Type C / EV</span>
                </button>
            </div>
        </div>

        {if selectedVehicle == "C" {
            <div className="p-4 rounded-xl bg-white/[0.04] border border-white/10 flex flex-col gap-3">
                <div className="flex items-center gap-2">
                    <span className="text-base">⚡</span>
                    <span className="text-xs font-bold text-white">Is it an electric vehicle?</span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { onChangeEv("needs_charging"); }}
                        className={f"px-3 py-2.5 rounded-lg border text-left transition-all {'border-[#22D3EE] bg-[#22D3EE]/20 text-[#22D3EE] font-bold shadow-md shadow-[#22D3EE]/10' if evChoice == 'needs_charging' else 'border-white/10 bg-white/[0.02] text-gray-400 hover:text-white'}"}
                    >
                        <div className="text-xs font-semibold flex items-center justify-between">
                            <span>Needs charging</span>
                            {if evChoice == "needs_charging" { <span>✓</span> }}
                        </div>
                        <span className="text-[10px] text-gray-400 block mt-0.5">EV Charging bay (Type E)</span>
                    </button>

                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { onChangeEv("park_only"); }}
                        className={f"px-3 py-2.5 rounded-lg border text-left transition-all {'border-[#FFC21A] bg-[#FFC21A]/15 text-[#FFC21A] font-bold' if evChoice == 'park_only' else 'border-white/10 bg-white/[0.02] text-gray-400 hover:text-white'}"}
                    >
                        <div className="text-xs font-semibold flex items-center justify-between">
                            <span>Park only</span>
                            {if evChoice == "park_only" { <span>✓</span> }}
                        </div>
                        <span className="text-[10px] text-gray-400 block mt-0.5">Regular bay (Type C)</span>
                    </button>

                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { onChangeEv("no"); }}
                        className={f"px-3 py-2.5 rounded-lg border text-left transition-all {'border-white/40 bg-white/10 text-white font-bold' if evChoice == 'no' else 'border-white/10 bg-white/[0.02] text-gray-400 hover:text-white'}"}
                    >
                        <div className="text-xs font-semibold flex items-center justify-between">
                            <span>No</span>
                            {if evChoice == "no" { <span>✓</span> }}
                        </div>
                        <span className="text-[10px] text-gray-400 block mt-0.5">Standard petrol / diesel</span>
                    </button>
                </div>
            </div>
        }}

        <label className="flex items-center gap-3 p-3 rounded-xl bg-white/[0.02] border border-white/5 cursor-pointer hover:bg-white/[0.04]">
            <input
                type="checkbox"
                checked={accessible}
                onChange={lambda (e: ChangeEvent) { onToggleAccessible(bool(e.target.checked)); }}
                className="w-4 h-4 rounded border-gray-600 text-[#FFC21A] focus:ring-[#FFC21A] bg-transparent"
            />
            <div className="text-xs">
                <span className="font-semibold text-white flex items-center gap-1.5">
                    <span>♿</span>
                    <span>Accessible parking required</span>
                </span>
                <span className="text-gray-400 text-[11px] block mt-0.5">Reserved bays closest to terminal entrance (Front Zone)</span>
            </div>
        </label>

        <div className="pt-2 border-t border-white/10">
            <div className="flex items-center justify-between mb-2.5">
                <h4 className="text-xs font-bold uppercase tracking-wider text-gray-300">
                    3. Schedule &amp; Stay Duration
                </h4>
                <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-[#FFC21A]/20 text-[#FFC21A] text-[11px] font-bold">
                    <span>{durationHours} hrs</span>
                    <span>&rarr; {zoneLabel}</span>
                </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
                <div>
                    <label className="text-[11px] font-medium text-gray-400 mb-1 block">Arriving at</label>
                    <input
                        type="time"
                        value={arrival}
                        onChange={lambda (e: ChangeEvent) { onChangeArrival(str(e.target.value)); }}
                        className="w-full px-3 py-2.5 rounded-xl bg-white/[0.05] border border-white/15 text-white text-sm focus:border-[#FFC21A] focus:outline-none"
                    />
                </div>
                <div>
                    <label className="text-[11px] font-medium text-gray-400 mb-1 block">Returning by</label>
                    <input
                        type="time"
                        value={returnBy}
                        onChange={lambda (e: ChangeEvent) { onChangeReturnBy(str(e.target.value)); }}
                        className="w-full px-3 py-2.5 rounded-xl bg-white/[0.05] border border-white/15 text-white text-sm focus:border-[#FFC21A] focus:outline-none"
                    />
                </div>
            </div>

            <p className="text-[10px] text-gray-500 mt-2">
                Zone rule: under 3h &rarr; Front (F), 3–8h &rarr; Middle (M), over 8h &rarr; Rear (R). Optimizes terminal turnover.
            </p>
        </div>
    </div>;
}
