"""QRScannerModal component for scanning bus stop QRs (Milestone 2).

Supports camera scanning and manual token entry. Stop QRs are signed by the server, so a test
scan needs a real token: copy it from the admin Next-stop panel (/admin) or from /dev/core
(admin_next_stop) and paste it below.
"""

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

    async def do_scan(token: str, reuseScanId: bool = False, dropCode: str = "") {
        if isProcessing or len(token.strip()) == 0 {
            return;
        }
        isProcessing = True;

        # A fresh scan ID per physical scan; the same ID again tests duplicate handling
        currentScanId = lastScanId if reuseScanId and len(lastScanId) > 0 else f"scan-{globalThis.Date.now()}-{globalThis.Math.random().toString(36).slice(2, 10)}";
        lastScanId = currentScanId;

        if onProcessScan {
            res = await onProcessScan(currentScanId, token.strip(), dropCode);
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

                <div className="relative aspect-square max-h-52 w-full mx-auto rounded-2xl bg-black border-2 border-dashed border-cyan-400/50 flex flex-col items-center justify-center overflow-hidden">
                    <div className="absolute inset-4 border border-white/20 rounded-xl pointer-events-none" />
                    <div className="w-full h-0.5 bg-gradient-to-r from-transparent via-cyan-400 to-transparent absolute top-1/2 -translate-y-1/2 animate-bounce" />

                    <span className="text-3xl mb-1 opacity-70">📷</span>
                    <span className="text-[11px] text-cyan-300 font-bold">Point camera at Stop QR</span>
                    <span className="text-[9px] text-gray-500 mt-1">Camera auto-detect active</span>
                </div>

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

                <div className="pt-2 border-t border-white/10 space-y-2">
                    <span className="text-[10px] text-gray-400 font-bold block uppercase tracking-wider">
                        Manual Token Entry
                    </span>
                    <span className="text-[10px] text-gray-500 block">
                        Paste the stop QR token from the admin Next-stop panel (/admin) or /dev/core.
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
                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { do_scan(inputToken, True); }}
                        className="w-full p-2.5 rounded-xl border border-amber-500/30 bg-amber-500/10 hover:bg-amber-500/20 text-amber-300 font-bold text-xs"
                    >
                        Resend same scan_id (duplicate test)
                    </button>
                </div>
            </div>
        </div>
    );
}
