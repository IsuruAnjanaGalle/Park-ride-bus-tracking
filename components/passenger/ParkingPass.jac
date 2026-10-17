"""ParkingPass component for Park & Ride Sri Lanka.
Displays the confirmed parking booking with QR pass and the 'Mark vehicle as parked' action.
"""

import from components.shared.ui.QRPanel { QRPanel }
import from components.shared.ui.Button { Button }

def:pub ParkingPass(
    booking: dict,
    onMarkParked: Callable[[], None] = lambda {},
    onReleaseSlot: Callable[[], None] = lambda {},
    onProceedToBus: Callable[[], None] = lambda {}
) -> JsxElement {
    bId = str(booking.get("id", "BK-MOCK-001"));
    terminal = str(booking.get("terminal", "MKB"));
    slotCode = str(booking.get("slot_code", "MKB-C-F-01"));
    zone = str(booking.get("zone", "F"));
    arrival = str(booking.get("arrival", "08:00"));
    returnBy = str(booking.get("return_by", "10:00"));
    state = str(booking.get("state", "booked"));
    qrToken = str(booking.get("qr", "PKR.PARK.MKB.VALID_TOKEN_2026"));

    isParked = state == "parked";
    isBooked = state == "booked";

    return <div className="flex flex-col items-center gap-6 max-w-md mx-auto w-full animate-fade-in">
        # Status Alert Card
        <div className="w-full p-4 rounded-2xl bg-[#0F1B2D] border border-white/15 backdrop-blur-xl text-center shadow-xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-bold mb-3 border border-white/10 bg-white/5">
                {if isParked {
                    <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                } else {
                    <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" />
                }}
                <span className={f"uppercase tracking-wider {'text-emerald-300' if isParked else 'text-amber-300'}"}>
                    Status: {state}
                </span>
            </div>

            <h2 className="text-2xl font-black text-white tracking-tight">
                {slotCode}
            </h2>
            <p className="text-xs text-gray-400 mt-1">
                Terminal {terminal} · Zone {zone} Bay
            </p>

            <div className="mt-4 grid grid-cols-2 gap-3 p-3 rounded-xl bg-white/[0.03] border border-white/5 text-xs">
                <div>
                    <span className="text-gray-500 block text-[10px] uppercase font-semibold">Arrived</span>
                    <span className="font-bold text-white text-sm">{arrival}</span>
                </div>
                <div>
                    <span className="text-gray-500 block text-[10px] uppercase font-semibold">Return Window</span>
                    <span className="font-bold text-white text-sm">{returnBy}</span>
                </div>
            </div>
        </div>

        # Cryptographic QR Pass
        <QRPanel
            qrToken={qrToken}
            slotCode={slotCode}
            terminalName={terminal}
            expiryText={f"Valid until {returnBy}"}
            verified={True}
        />

        # Primary Action Buttons
        <div className="w-full flex flex-col gap-3">
            {if isBooked {
                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { onMarkParked(); }}
                    className="w-full py-3.5 px-6 rounded-2xl bg-[#FFC21A] text-[#0F1B2D] font-black text-base shadow-xl shadow-[#FFC21A]/20 hover:bg-[#e5ad16] active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
                >
                    <span>🚗</span>
                    <span>Mark vehicle as parked</span>
                </button>
            }}

            {if isParked {
                <div className="flex flex-col gap-2.5 w-full">
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { onProceedToBus(); }}
                        className="w-full py-3.5 px-6 rounded-2xl bg-[#22D3EE] text-[#0F1B2D] font-black text-base shadow-xl shadow-[#22D3EE]/20 hover:bg-[#1bb8cf] active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
                    >
                        <span>🚌</span>
                        <span>Proceed to Metro Bus Tracker &rarr;</span>
                    </button>

                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { onReleaseSlot(); }}
                        className="w-full py-2.5 px-4 rounded-xl border border-white/20 bg-white/5 text-xs text-gray-300 font-semibold hover:bg-white/10 hover:text-white transition-all cursor-pointer"
                    >
                        Release Slot &amp; Check Out
                    </button>
                </div>
            }}

            <p className="text-[11px] text-gray-400 text-center leading-relaxed">
                {("Show this QR pass at the boom barrier scanner to enter the terminal bay." if isBooked else "Your vehicle is registered as parked. Head towards Bay 1 for express bus departures.")}
            </p>
        </div>
    </div>;
}
