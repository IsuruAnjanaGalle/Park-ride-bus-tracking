"""ErrorState component: graceful error presentation with retry action."""

def:pub ErrorState(
    title: str = "Something went wrong",
    message: str = "Please try again later.",
    retryLabel: str = "Try Again",
    onRetry: Callable[[], None] = lambda {}
) -> JsxElement {
    return <div className="flex flex-col items-center justify-center text-center p-8 rounded-3xl bg-rose-950/20 border border-rose-500/20 backdrop-blur-md">
        <div className="w-16 h-16 mb-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 flex items-center justify-center text-rose-400 text-2xl shadow-inner">
            <span>⚠️</span>
        </div>
        <h4 className="text-lg font-bold text-white mb-1.5">{title}</h4>
        <p className="text-sm text-gray-300 max-w-sm mb-5 leading-relaxed">{message}</p>
        <button
            className="inline-flex items-center justify-center font-semibold rounded-xl bg-rose-500/20 text-rose-300 border border-rose-500/40 hover:bg-rose-500/30 px-5 py-2.5 text-sm transition-all shadow-md cursor-pointer min-h-[44px]"
            onClick={onRetry}
        >
            <span>🔄</span>
            <span className="ml-2">{retryLabel}</span>
        </button>
    </div>;
}
