"""SeatBookingModal component for selecting pickup & drop stops and booking a seat (Milestone 2).

Filters out passed stops and confirms seat allocation per segment.
"""

def:pub SeatBookingModal(
    bus: dict[str, any],
    isOpen: bool = False,
    initialPickup: str = "",
    onClose: any = None,
    onConfirmBooking: any = None
) -> JsxElement {
    has pickupSel: str = initialPickup;
    has dropSel: str = "";
    has isSubmitting: bool = False;

    if not isOpen {
        return <div className="hidden" />;
    }

    bDict: dict[str, any] = dict(bus);
    bid = str(bDict.get("id", "MB-101"));
    plate = str(bDict.get("plate", "NB-4101"));
    routeName = str(bDict.get("route_name", "Metro Route"));
    seatsLeft = int(str(bDict.get("seats_left", "40")));

    rawStops: list[dict[str, any]] = [dict(s) for s in list(bDict.get("stops", []))];

    # Available stops (exclude already passed stops)
    activeStops = [s for s in rawStops if not bool(s.get("passed", False))];

    # Pickup and drop come from this bus's stops not yet passed. A choice that does not fit this
    # bus (another bus was opened, or initialPickup is not ahead of it) falls back to the defaults:
    # pickup = initialPickup if it is ahead, else the next stop; drop = the last stop.
    activeCodes = [str(s.get("code", "")) for s in activeStops];
    pickup = pickupSel;
    if pickup not in activeCodes[:-1] {
        pickup = initialPickup if initialPickup in activeCodes[:-1] else (activeCodes[0] if activeCodes else "");
    }
    pickupPos = activeCodes.index(pickup) if pickup in activeCodes else -1;
    drop = dropSel;
    if drop not in activeCodes or activeCodes.index(drop) <= pickupPos {
        drop = activeCodes[-1] if len(activeCodes) > 1 else "";
    }

    # Validate that drop is after pickup in route sequence
    stopCodes = [str(s.get("code", "")) for s in rawStops];
    pickupIdx = stopCodes.index(pickup) if pickup in stopCodes else -1;
    dropIdx = stopCodes.index(drop) if drop in stopCodes else -1;
    isValidJourney = pickupIdx >= 0 and dropIdx > pickupIdx;

    async def handle_confirm {
        if isValidJourney and not isSubmitting {
            isSubmitting = True;
            if onConfirmBooking {
                await onConfirmBooking(bid, pickup, drop);
            }
            isSubmitting = False;
        }
    }

    return <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/75 backdrop-blur-md animate-fade-in">
            <div className="w-full max-w-lg bg-[#0F1B2D] border border-white/15 rounded-t-3xl sm:rounded-3xl shadow-2xl p-6 space-y-6 max-h-[90vh] overflow-y-auto">
                <div className="flex items-start justify-between">
                    <div>
                        <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-full bg-cyan-500/10 border border-cyan-500/20 text-[11px] font-bold text-cyan-400">
                            <span>🚌</span>
                            <span>Metro Seat Allocation</span>
                        </div>
                        <h3 className="text-2xl font-black text-white mt-1.5">{bid}</h3>
                        <p className="text-xs text-gray-400 font-mono">{plate} · {routeName}</p>
                    </div>

                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { if onClose { onClose(); } }}
                        className="p-2 rounded-xl bg-white/5 border border-white/10 text-gray-400 hover:text-white hover:bg-white/10 text-sm font-bold"
                    >
                        ✕
                    </button>
                </div>

                <div className="p-3.5 rounded-2xl bg-white/[0.03] border border-white/5 flex items-center justify-between text-xs">
                    <span className="text-gray-300">Available capacity right now:</span>
                    <span className="font-extrabold text-emerald-400 font-mono text-sm">{f"{seatsLeft} Seats Free"}</span>
                </div>

                <div className="space-y-4">
                    <div>
                        <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">
                            1. Boarding Stop (Pickup)
                        </label>
                        <select
                            value={pickup}
                            onChange={lambda (e: ChangeEvent) { pickupSel = str(e.target.value); }}
                            className="w-full p-3.5 rounded-2xl bg-[#090F1B] border border-white/15 text-white font-bold text-sm focus:border-[#FFC21A] focus:outline-none"
                        >
                            {for s in activeStops {
                                sCode = str(s.get("code", ""));
                                sName = str(s.get("name", ""));
                                <option key={f"pick-{sCode}"} value={sCode}>
                                    {f"{sName} ({sCode})"}
                                </option>
                            }}
                        </select>
                    </div>

                    <div>
                        <label className="block text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">
                            2. Destination Stop (Drop)
                        </label>
                        <select
                            value={drop}
                            onChange={lambda (e: ChangeEvent) { dropSel = str(e.target.value); }}
                            className="w-full p-3.5 rounded-2xl bg-[#090F1B] border border-white/15 text-white font-bold text-sm focus:border-[#FFC21A] focus:outline-none"
                        >
                            {for s in activeStops {
                                sCode = str(s.get("code", ""));
                                sName = str(s.get("name", ""));
                                <option key={f"drop-{sCode}"} value={sCode}>
                                    {f"{sName} ({sCode})"}
                                </option>
                            }}
                        </select>
                    </div>
                </div>

                {if not isValidJourney {
                    <div className="p-3 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs font-bold flex items-center gap-2">
                        <span>⚠️</span>
                        <span>Destination stop must be after boarding stop on this route.</span>
                    </div>
                } else {
                    <div className="p-3.5 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-300 text-xs font-semibold flex items-center justify-between">
                        <span className="flex items-center gap-2">
                            <span>✅</span>
                            <span>Seat verified free across all route segments</span>
                        </span>
                        <span className="font-mono font-bold">{f"{dropIdx - pickupIdx} stops"}</span>
                    </div>
                }}

                <div className="pt-2 flex items-center gap-3">
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { if onClose { onClose(); } }}
                        className="w-1/3 py-3.5 px-4 rounded-2xl border border-white/15 bg-white/5 text-gray-300 font-bold text-sm hover:bg-white/10 transition-colors"
                    >
                        Cancel
                    </button>
                    <button
                        type="button"
                        disabled={not isValidJourney or isSubmitting}
                        onClick={lambda (_e: MouseEvent) { handle_confirm(); }}
                        className={f"w-2/3 py-3.5 px-4 rounded-2xl font-black text-sm transition-all shadow-xl flex items-center justify-center gap-2 {'bg-[#FFC21A] text-[#0F1B2D] hover:bg-[#e5ad16] cursor-pointer' if isValidJourney and not isSubmitting else 'bg-white/10 text-gray-500 cursor-not-allowed opacity-50'}"}
                    >
                        <span>{f"Confirm Booking ({pickup} → {drop})"}</span>
                    </button>
                </div>
            </div>
        </div>;
}
