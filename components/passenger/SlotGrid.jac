"""SlotGrid component for Park & Ride Sri Lanka.
Renders an interactive parking bay grid with Zone grouping, status filtering, and EV indicators.
"""

def:pub SlotGrid(
    slots: list[dict[str, any]],
    selectedSlotCode: str,
    recommendedSlotCode: str = "",
    terminalName: str = "",
    onSelectSlot: Callable[[str], None] = lambda (_code: str) {}
) -> JsxElement {
    has activeZone: str = "ALL";
    has activeState: str = "ALL";
    has viewMode: str = "2d";

    # Loop handlers get their slot code as a parameter: Jac 0.37 compiles loop locals to one
    # variable per component, so a handler reading them would pick the last bay (D-30).
    def select_handler(code: str, free: bool) -> any {
        return lambda (_e: MouseEvent) { if free { onSelectSlot(code); } };
    }

    """Short bay name without the terminal, e.g. C-F-07."""
    def bay_label(s: dict[str, any]) -> str {
        nn = int(s.get("nn", 0));
        return str(s.get("type", "")) + "-" + str(s.get("zone", "")) + "-" + ("0" if nn < 10 else "") + str(nn);
    }

    # 3D yard: the first 8 real bays of each zone (front, middle, rear rows).
    yard: list[dict[str, any]] = [];
    yardRow = 0;
    for z in ["F", "M", "R"] {
        yardCol = 0;
        for s in [s for s in slots if str(s.get("zone", "")) == z][:8] {
            yard.append({"slot": s, "col": yardCol, "row": yardRow});
            yardCol = yardCol + 1;
        }
        yardRow = yardRow + 1;
    }

    return <div className="flex flex-col gap-4 rounded-3xl bg-[#0F1B2D]/90 border border-white/10 p-5 backdrop-blur-xl">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-white/10 pb-4">
            <div>
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                    <span>{(terminalName + " " if terminalName else "") + "Parking Bays"}</span>
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#FFC21A]/20 text-[#FFC21A]">
                        Live Grid
                    </span>
                </h3>
                <p className="text-xs text-gray-400 mt-0.5">Select a free bay to reserve your parking.</p>
            </div>

            <div className="flex flex-wrap items-center gap-2">
                <div className="flex items-center gap-1 p-1 rounded-xl bg-white/[0.04] border border-white/10 text-xs">
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { viewMode = "2d"; }}
                        className={f"px-2.5 py-1 rounded-lg font-bold transition-colors {'bg-[#FFC21A] text-[#0F1B2D]' if viewMode == '2d' else 'text-gray-400 hover:text-white'}"}
                    >
                        2D Bays
                    </button>
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { viewMode = "3d"; }}
                        className={f"px-2.5 py-1 rounded-lg font-bold transition-colors {'bg-[#FFC21A] text-[#0F1B2D]' if viewMode == '3d' else 'text-gray-400 hover:text-white'}"}
                    >
                        3D Yard
                    </button>
                </div>

                <div className="flex items-center gap-1.5 p-1 rounded-xl bg-white/[0.04] border border-white/10 text-xs">
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { activeZone = "ALL"; }}
                        className={f"px-2.5 py-1 rounded-lg font-bold transition-colors {'bg-[#FFC21A] text-[#0F1B2D]' if activeZone == 'ALL' else 'text-gray-400 hover:text-white'}"}
                    >
                        All
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
        </div>

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

        {if viewMode == "3d" {
            <div className="relative w-full rounded-2xl overflow-hidden bg-[#070D1A] border border-white/10 p-4 shadow-inner">
                <div className="flex items-center justify-between text-xs text-gray-400 mb-2">
                    <span className="font-mono text-[#FFC21A] flex items-center gap-1.5 font-bold">
                        <span className="w-2 h-2 rounded-full bg-[#FFC21A] animate-pulse" />
                        3D Terminal Yard View (P-09)
                    </span>
                    <span className="text-[11px] text-gray-400">Dashed line guides walking route from Terminal Gate</span>
                </div>
                <svg viewBox="0 0 640 330" className="w-full h-auto max-h-[320px] select-none rounded-xl">
                    <rect width="640" height="330" fill="#080F1D" rx="12" />

                    <rect x="260" y="300" width="120" height="18" fill="#FFC21A" rx="4" />
                    <text x="320" y="312" fill="#0F1B2D" fontSize="9" fontWeight="bold" textAnchor="middle" fontFamily="monospace">
                        TERMINAL ENTRANCE GATE
                    </text>

                    {for bay in yard {
                        ySlot: dict[str, any] = dict(bay["slot"]);
                        sCode = str(ySlot.get("code", ""));
                        yState = str(ySlot.get("state", "free"));
                        bx = 36 + int(bay["col"]) * 72;
                        bay_y = 25 + int(bay["row"]) * 84;
                        isSel = (sCode == selectedSlotCode);
                        yFree = yState == "free";
                        isOcc = yState == "occupied";

                        # Bay outline & interactive click (free bays only)
                        <g
                            key={sCode}
                            role="button"
                            aria-label={f"Bay {sCode}, {yState}"}
                            aria-disabled={not yFree}
                            onClick={select_handler(sCode, yFree)}
                            className={"cursor-pointer" if yFree else "cursor-not-allowed"}
                        >
                            <rect
                                x={bx}
                                y={bay_y}
                                width="62"
                                height="68"
                                rx="6"
                                fill={"#FFC21A33" if isSel else ("#10B98115" if yFree else ("#EF444422" if isOcc else "#F59E0B22"))}
                                stroke={"#FFC21A" if isSel else ("#10B981" if yFree else ("#EF4444" if isOcc else "#F59E0B"))}
                                strokeWidth={"2.5" if isSel else "1"}
                            />

                            # Bay label
                            <text x={bx + 31} y={bay_y + 14} fill="#FFFFFF" fontSize="8" fontWeight="bold" textAnchor="middle" fontFamily="monospace">
                                {bay_label(ySlot)}
                            </text>

                            {if isOcc {
                                <g>
                                    <rect x={bx + 11} y={bay_y + 20} width="40" height="40" rx="4" fill="#334155" />
                                    <rect x={bx + 15} y={bay_y + 24} width="32" height="20" rx="3" fill="#64748B" />
                                    <rect x={bx + 18} y={bay_y + 27} width="26" height="10" rx="2" fill="#0B1320" />
                                </g>;
                            }}

                            {if isSel {
                                <rect x={bx - 2} y={bay_y - 2} width="66" height="72" rx="8" fill="none" stroke="#FFC21A" strokeWidth="2" strokeDasharray="3 3" />;
                            }}
                        </g>;
                    }}

                    <path
                        d="M 320 300 L 320 185 L 180 185 L 180 95"
                        fill="none"
                        stroke="#FFC21A"
                        strokeWidth="2.5"
                        strokeDasharray="4 4"
                    />
                </svg>
            </div>;
        } else {
            # Slot grid items (2D)
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

                            <button
                                key={code}
                                type="button"
                                disabled={not isFree}
                                aria-pressed={isSelected}
                                aria-label={f"Bay {code}, {state}"}
                                onClick={select_handler(code, isFree)}
                                className={f"relative min-h-[44px] text-left flex flex-col justify-between p-2.5 rounded-xl border text-xs transition-all {bgBorder}"}
                            >
                                <div className="flex items-center justify-between">
                                    <span className="font-extrabold tracking-tight text-[11px] truncate">
                                        {bay_label(s)}
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
                            </button>;
                        }
                    }}
                </div>
            </div>;
        }}
    </div>;
}
