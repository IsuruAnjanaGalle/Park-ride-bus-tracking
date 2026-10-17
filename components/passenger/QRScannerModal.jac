"""QRScannerModal component for scanning bus stop QRs (Milestone 2).

Supports camera scanning, manual token entry, and seeded demo buttons
for testing boarding, alighting, and duplicate detection.
"""

import time;

def:pub QRScannerModal(
    isOpen: bool = False,
    onClose: any = None,
    onProcessScan: any = None
) -> JsxElement {
    has inputToken: str = "";
    has dropTarget: str = "";
    has scanResult: dict[str, any] = {};
    has lastScanId: str = "";
    has isProcessing: bool = False;

    if not isOpen {
        return <div className="hidden" />;
    }

    def do_scan(token: str, reuseScanId: bool = False, dropCode: str = "") {
        if isProcessing {
            return;
        }
        isProcessing = True;

        # Generate unique scan ID or reuse for duplicate testing
        currentScanId = lastScanId if reuseScanId and len(lastScanId) > 0 else f"scan-{int(time.time() * 1000)}";
        lastScanId = currentScanId;

        if onProcessScan {
            res = onProcessScan(currentScanId, token, dropCode);
            if res {
                scanResult = dict(res);
            }
        }
        isProcessing = False;
    }

    resDict: dict[str, any] = dict(scanResult);
    resStatus = str(resDict.get("result", ""));
    resMsg = str(resDict.get("message", ""));

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fade-in">
            <div className="w-full max-w-md bg-[#0F1B2D] border border-white/15 rounded-3xl shadow-2xl p-6 space-y-6">
                # Modal Header
                <div className="flex items-center justify-between pb-3 border-b border-white/10">
                    <div className="flex items-center gap-2.5">
                        <span className="p-2 rounded-xl bg-[#FFC21A]/10 text-[#FFC21A] text-lg font-bold">
                            📷
                        </span>
                        <div>
                            <h3 className="font-extrabold text-white text-base">Stop QR Scanner</h3>
                            <span className="text-[10px] text-gray-400">Scan at entrance pole to board / alight</span>
                        </div>
                    </div>
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { if onClose { onClose(); } }}
                        className="p-2 rounded-xl bg-white/5 text-gray-400 hover:text-white text-xs font-bold"
                    >
                        ✕
                    </button>
                </div>

                # Camera Viewport Scanner Simulation
                <div className="relative aspect-square max-h-52 w-full mx-auto rounded-2xl bg-black border-2 border-dashed border-cyan-400/50 flex flex-col items-center justify-center overflow-hidden">
                    <div className="absolute inset-4 border border-white/20 rounded-xl pointer-events-none" />
                    <div className="w-full h-0.5 bg-gradient-to-r from-transparent via-cyan-400 to-transparent absolute top-1/2 -translate-y-1/2 animate-bounce" />

                    <span className="text-3xl mb-1 opacity-70">📷</span>
                    <span className="text-[11px] text-cyan-300 font-bold">Point camera at Stop QR</span>
                    <span className="text-[9px] text-gray-500 mt-1">Camera auto-detect active</span>
                </div>

                # Result Banner if scanned
                {if len(resStatus) > 0 {
                    isSuccess = (resStatus == "boarded" or resStatus == "alighted");
                    isDuplicate = (resStatus == "duplicate" or resStatus == "already_on_board");
                    badgeColor = "bg-emerald-500/20 border-emerald-500/40 text-emerald-200" if isSuccess else ("bg-amber-500/20 border-amber-500/40 text-amber-200" if isDuplicate else "bg-rose-500/20 border-rose-500/40 text-rose-200");

                    <div className={f"p-3.5 rounded-2xl border text-xs font-bold flex items-center justify-between {badgeColor}"}>
                        <div>
                            <span className="uppercase text-[10px] tracking-wider block opacity-75">{resStatus}</span>
                            <span>{resMsg if len(resMsg) > 0 else "Scan processed successfully"}</span>
                        </div>
                        <span className="text-xl">{"✅" if isSuccess else ("⚠️" if isDuplicate else "❌")}</span>
                    </div>;
                }}

                # Walk-In Destination Prompt if triggered
                {if resStatus == "walk_in_needs_drop" {
                    <div className="p-3.5 rounded-2xl bg-cyan-500/10 border border-cyan-500/30 space-y-2 text-xs">
                        <span className="text-cyan-300 font-bold block">Walk-In Passenger: Choose Drop Stop</span>
                        <div className="flex gap-2">
                            <input
                                type="text"
                                placeholder="e.g. BOR or PET"
                                value={dropTarget}
                                onChange={lambda (e: ChangeEvent) { dropTarget = str(e.target.value); }}
                                className="flex-1 px-3 py-2 rounded-xl bg-black/40 border border-white/10 text-white font-mono text-xs uppercase"
                            />
                            <button
                                type="button"
                                onClick={lambda (_e: MouseEvent) { do_scan(inputToken, False, dropTarget); }}
                                className="px-4 py-2 rounded-xl bg-cyan-400 text-[#0F1B2D] font-bold text-xs"
                            >
                                Confirm
                            </button>
                        </div>
                    </div>;
                }}

                # One-Click Demo Presets (for judging & laptop testing)
                <div>
                    <span className="text-[10px] font-bold uppercase tracking-wider text-gray-400 block mb-2">
                        Demo Testing Presets (Section 9.4)
                    </span>
                    <div className="grid grid-cols-2 gap-2 text-xs">
                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { do_scan("STP.MKB.VISIT_1.TOKEN_MKB_VALID", False); }}
                            className="p-2.5 rounded-xl border border-white/10 bg-white/5 hover:bg-white/10 text-left font-bold text-white transition-colors"
                        >
                            <span className="block text-emerald-400 text-[10px]">1. Boarding</span>
                            <span>Makumbura (MKB)</span>
                        </button>

                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { do_scan("STP.BOR.VISIT_1.TOKEN_BOR_VALID", False); }}
                            className="p-2.5 rounded-xl border border-white/10 bg-white/5 hover:bg-white/10 text-left font-bold text-white transition-colors"
                        >
                            <span className="block text-cyan-400 text-[10px]">2. Alighting</span>
                            <span>Borella (BOR)</span>
                        </button>

                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { do_scan("STP.MKB.VISIT_1.TOKEN_MKB_VALID", True); }}
                            className="p-2.5 rounded-xl border border-amber-500/30 bg-amber-500/10 hover:bg-amber-500/20 text-left font-bold text-amber-300 transition-colors"
                        >
                            <span className="block text-[10px]">3. Duplicate Test</span>
                            <span>Resend Same ID</span>
                        </button>

                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { do_scan("STP.WALK_IN.TOKEN_UNKNOWN", False); }}
                            className="p-2.5 rounded-xl border border-purple-500/30 bg-purple-500/10 hover:bg-purple-500/20 text-left font-bold text-purple-300 transition-colors"
                        >
                            <span className="block text-[10px]">4. Walk-In Pass</span>
                            <span>Unbooked Passenger</span>
                        </button>
                    </div>
                </div>

                # Manual Token Entry
                <div className="pt-2 border-t border-white/10 space-y-2">
                    <span className="text-[10px] text-gray-400 font-bold block uppercase tracking-wider">
                        Manual Token Entry
                    </span>
                    <div className="flex gap-2">
                        <input
                            type="text"
                            placeholder="Enter QR Token..."
                            value={inputToken}
                            onChange={lambda (e: ChangeEvent) { inputToken = str(e.target.value); }}
                            className="flex-1 p-2.5 rounded-xl bg-black/40 border border-white/15 text-white font-mono text-xs focus:border-[#FFC21A] focus:outline-none"
                        >
                        </input>
                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { if len(inputToken) > 0 { do_scan(inputToken, False); } }}
                            className="px-4 py-2.5 rounded-xl bg-[#FFC21A] text-[#0F1B2D] font-black text-xs hover:bg-[#e5ad16] transition-colors"
                        >
                            Submit
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
