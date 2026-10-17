"""Toast component: floating feedback banner with auto/manual dismissal."""

def:pub Toast(
    message: str,
    type: str = "info",
    isVisible: bool = True,
    onClose: Callable[[], None] = lambda {}
) -> JsxElement {
    if not isVisible {
        return <div className="hidden"/>;
    }

    borderCls = "border-emerald-500/40 bg-emerald-950/80 text-emerald-200" if type == "success"
        else ("border-rose-500/40 bg-rose-950/80 text-rose-200" if type == "error"
        else ("border-amber-500/40 bg-amber-950/80 text-amber-200" if type == "warning"
        else "border-blue-500/40 bg-[#0F1B2D]/90 text-blue-200"));

    iconSymbol = "✓" if type == "success"
        else ("✕" if type == "error"
        else ("⚠" if type == "warning"
        else "ℹ"));

    combinedCls = f"fixed bottom-6 right-6 z-50 flex items-center gap-3 px-4 py-3 rounded-2xl border shadow-2xl backdrop-blur-xl animate-bounce-subtle max-w-sm {borderCls}";

    return <div
        className={combinedCls}
        role="alert"
        aria-live="polite"
    >
        <span className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center text-xs font-bold shrink-0">
            {iconSymbol}
        </span>
        <p className="text-sm font-medium leading-snug flex-1">{message}</p>
        <button
            className="w-7 h-7 rounded-lg hover:bg-white/15 flex items-center justify-center transition-colors shrink-0 text-white/70 hover:text-white"
            onClick={onClose}
            aria-label="Dismiss toast"
        >
            <span className="text-base font-bold leading-none">×</span>
        </button>
    </div>;
}
