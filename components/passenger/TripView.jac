"""TripView component displaying the passenger's active journey (Milestone 2 & 3).

Shows live route progression, arrival alert (2 stops away), traffic delays,
and the button to trigger stop QR scanning.
"""

def:pub TripView(
    tripData: dict[str, any],
    onOpenScanner: any = None,
    onFinishTrip: any = None
) -> JsxElement {
    tDict: dict[str, any] = dict(tripData);
    booking: dict[str, any] = dict(tDict.get("booking", {}));
    bus: dict[str, any] = dict(tDict.get("bus", {}));
    alert = bool(tDict.get("alert", False));
    alertMessage = str(tDict.get("alert_message", "Your stop is 2 stops away"));
    stopsRemaining = int(str(tDict.get("stops_remaining", "2")));
    delayDict = tDict.get("delay");

    bid = str(bus.get("id", "MB-101"));
    plate = str(bus.get("plate", "NB-4101"));
    routeName = str(bus.get("route_name", "Metro Route"));
    bStatus = str(booking.get("status", "OnBoard"));
    pickupCode = str(booking.get("pickup", "MKB"));
    dropCode = str(booking.get("drop", "BOR"));

    rawStops: list[dict[str, any]] = [dict(s) for s in list(tDict.get("stops", []))];

    return (
        <div className="space-y-6">
            # 1. High Priority Arrival Alert Banner (2 stops away)
            {if alert {
                <div className="p-4 rounded-3xl bg-amber-500/20 border-2 border-amber-400 text-amber-200 shadow-2xl shadow-amber-500/20 animate-pulse flex items-center justify-between gap-3">
                    <div className="flex items-center gap-3">
                        <span className="text-2xl">🔔</span>
                        <div>
                            <span className="text-xs font-black uppercase tracking-wider block text-amber-300">Arrival Notice</span>
                            <span className="font-extrabold text-sm text-white block">{alertMessage}</span>
                        </div>
                    </div>
                    <span className="px-3 py-1 rounded-full bg-amber-400 text-[#0F1B2D] font-black text-xs">
                        {f"{stopsRemaining} Stops Left"}
                    </span>
                </div>;
            }}

            # 2. Traffic Delay Alert if present
            {if delayDict {
                dInfo: dict[str, any] = dict(delayDict);
                dMins = int(str(dInfo.get("minutes", "5")));
                dReason = str(dInfo.get("reason", "Heavy congestion"));
                <div className="p-3.5 rounded-2xl bg-rose-500/15 border border-rose-500/30 text-rose-300 text-xs font-semibold flex items-center gap-2.5">
                    <span>⚠️</span>
                    <span>{f"Traffic delay: +{dMins} min ({dReason})"}</span>
                </div>;
            }}

            # 3. Main Trip Card
            <div className="p-6 rounded-3xl bg-[#0F1B2D] border border-white/15 shadow-2xl space-y-6">
                # Trip Top Bar
                <div className="flex items-center justify-between pb-4 border-b border-white/10">
                    <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-2xl bg-[#FFC21A] text-[#0F1B2D] flex items-center justify-center font-black text-xl shadow-lg">
                            🚌
                        </div>
                        <div>
                            <div className="flex items-center gap-2">
                                <span className="font-black text-white text-lg font-mono">{bid}</span>
                                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                                    {bStatus}
                                </span>
                            </div>
                            <span className="text-xs text-gray-400 font-mono">{plate} · {routeName}</span>
                        </div>
                    </div>

                    <div className="text-right">
                        <span className="text-[10px] uppercase font-bold text-gray-500 block">Journey</span>
                        <span className="font-bold text-white text-xs font-mono">{f"{pickupCode} → {dropCode}"}</span>
                    </div>
                </div>

                # 4. Stop-by-Stop Stepper
                <div>
                    <h4 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-4">
                        Trip Progression
                    </h4>
                    <div className="space-y-3 relative before:absolute before:left-3 before:top-3 before:bottom-3 before:w-0.5 before:bg-white/10">
                        {for s in rawStops {
                            sCode = str(s.get("code", ""));
                            sName = str(s.get("name", ""));
                            sStatus = str(s.get("status", "upcoming"));
                            isPickup = bool(s.get("is_pickup", False));
                            isDrop = bool(s.get("is_drop", False));
                            etaVal = s.get("eta_min");

                            isPassed = (sStatus == "passed");
                            isNext = (sStatus == "next");

                            dotBg = "bg-emerald-400 text-[#0F1B2D]" if isPassed else ("bg-cyan-400 text-[#0F1B2D] ring-4 ring-cyan-400/20 animate-pulse" if isNext else ("bg-[#FFC21A] text-[#0F1B2D]" if isDrop else "bg-white/20 text-gray-400"));

                            <div key={f"step-{sCode}"} className="relative flex items-center justify-between pl-8 text-xs">
                                <span className={f"absolute left-1.5 w-3.5 h-3.5 rounded-full -translate-x-1/2 flex items-center justify-center text-[8px] font-bold {dotBg}"}>
                                    {"✓" if isPassed else ("▶" if isNext else ("🏁" if isDrop else "•"))}
                                </span>

                                <div className="flex items-center gap-2">
                                    <span className={f"font-bold {'text-white' if isNext or isDrop else ('text-gray-500 line-through' if isPassed else 'text-gray-300')}"}>
                                        {sName}
                                    </span>
                                    {if isPickup {
                                        <span className="px-1.5 py-0.5 rounded text-[9px] font-bold bg-blue-500/20 text-blue-300">Boarding</span>;
                                    }}
                                    {if isDrop {
                                        <span className="px-1.5 py-0.5 rounded text-[9px] font-bold bg-[#FFC21A]/20 text-[#FFC21A]">Destination</span>;
                                    }}
                                </div>

                                <div className="text-[11px] font-mono text-gray-400">
                                    {f"{float(str(etaVal)):.1f} min" if etaVal else ("Passed" if isPassed else "")}
                                </div>
                            </div>;
                        }}
                    </div>
                </div>

                # 5. Primary QR Scanner Button (Boarding or Alighting)
                <div className="pt-2 space-y-3">
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { if onOpenScanner { onOpenScanner(); } }}
                        className="w-full py-4 px-6 rounded-2xl bg-[#FFC21A] text-[#0F1B2D] font-black text-base shadow-xl shadow-[#FFC21A]/20 hover:bg-[#e5ad16] active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
                    >
                        <span>📷</span>
                        <span>Scan Bus Stop QR Code</span>
                    </button>

                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { if onFinishTrip { onFinishTrip(); } }}
                        className="w-full py-2.5 px-4 rounded-xl border border-white/10 bg-white/5 text-xs text-gray-400 font-bold hover:bg-white/10 transition-colors"
                    >
                        End Active Session / Return Home
                    </button>
                </div>
            </div>
        </div>
    );
}
