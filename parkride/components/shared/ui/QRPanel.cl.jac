"""QRPanel component: cryptographic HMAC QR gate pass with fallback code & details."""

def:pub QRPanel(
    qrToken: str,
    slotCode: str = "",
    vehiclePlate: str = "",
    terminalName: str = "",
    expiryText: str = "",
    verified: bool = True
) -> JsxElement {
    statusBadgeCls = "bg-emerald-500/15 text-emerald-300 border-emerald-500/30" if verified
        else "bg-amber-500/15 text-amber-300 border-amber-500/30";
    statusText = "HMAC Authenticated Pass" if verified else "Unsigned Mock Pass";

    shortToken = (qrToken[:16] + "..." + qrToken[-12:]) if len(qrToken) > 28 else (qrToken if qrToken else "MOCK-QR-PASS-2026");
    pillCls = f"inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold border mb-4 {statusBadgeCls}";

    return <div className="flex flex-col items-center p-6 rounded-3xl bg-[#0F1B2D]/90 border border-white/20 backdrop-blur-xl shadow-2xl max-w-sm mx-auto text-center">
        <div className={pillCls}>
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"/>
            <span>{statusText}</span>
        </div>

        <div className="p-4 bg-white rounded-2xl shadow-xl shadow-black/40 border-4 border-[#FFC21A]/60 flex flex-col items-center justify-center">
            <svg
                className="w-48 h-48 sm:w-56 sm:h-56 text-[#0F1B2D]"
                viewBox="0 0 100 100"
            >
                <path
                    d="M 5 5 h 25 v 25 h -25 z M 9 9 v 17 h 17 v -17 z M 13 13 h 9 v 9 h -9 z M 70 5 h 25 v 25 h -25 z M 74 9 v 17 h 17 v -17 z M 78 13 h 9 v 9 h -9 z M 5 70 h 25 v 25 h -25 z M 9 74 v 17 h 17 v -17 z M 13 78 h 9 v 9 h -9 z M 36 8 h 6 v 6 h -6 z M 48 8 h 6 v 6 h -6 z M 58 8 h 6 v 6 h -6 z M 36 20 h 6 v 6 h -6 z M 50 20 h 6 v 6 h -6 z M 8 36 h 6 v 6 h -6 z M 20 44 h 6 v 6 h -6 z M 8 52 h 6 v 6 h -6 z M 72 36 h 6 v 6 h -6 z M 84 42 h 6 v 6 h -6 z M 76 52 h 6 v 6 h -6 z M 36 74 h 6 v 6 h -6 z M 48 80 h 6 v 6 h -6 z M 60 74 h 6 v 6 h -6 z M 72 84 h 6 v 6 h -6 z M 84 76 h 6 v 6 h -6 z"
                    fill="#0F1B2D"
                />
                <path
                    d="M 42 42 h 16 v 16 h -16 z"
                    fill="#FFC21A"
                />
            </svg>
            <span className="mt-2 text-[10px] uppercase font-bold tracking-widest text-gray-500">Scan at Gate Barrier</span>
        </div>

        {<div className="mt-5 w-full bg-white/5 border border-white/10 rounded-2xl p-3 flex items-center justify-around">
            {<div>
                <span className="block text-[10px] uppercase tracking-wider text-gray-400">Allocated Bay</span>
                <span className="text-xl font-black font-mono text-[#FFC21A]">{slotCode}</span>
            </div> if slotCode else None}

            {<div>
                <span className="block text-[10px] uppercase tracking-wider text-gray-400">Vehicle</span>
                <span className="text-base font-bold font-mono text-white">{vehiclePlate}</span>
            </div> if vehiclePlate else None}
        </div> if slotCode or vehiclePlate else None}

        {<p className="mt-3 text-xs text-gray-300 font-medium truncate max-w-xs">{terminalName}</p> if terminalName else None}
        {<p className="mt-1 text-[11px] text-[#FFC21A] font-semibold">{expiryText}</p> if expiryText else None}

        <div className="mt-4 pt-3 border-t border-white/10 w-full flex items-center justify-between text-left">
            <div>
                <span className="block text-[9px] uppercase tracking-wider text-gray-500 font-mono">Pass Signature</span>
                <code className="text-[11px] text-gray-300 font-mono tracking-tight">{shortToken}</code>
            </div>
            <button
                className="px-2.5 py-1 text-xs rounded-lg bg-white/10 hover:bg-white/20 text-gray-300 hover:text-white transition-colors cursor-pointer"
                onClick={lambda { print("Copied token"); }}
                title="Copy Token"
            >
                Copy
            </button>
        </div>
    </div>;
}
