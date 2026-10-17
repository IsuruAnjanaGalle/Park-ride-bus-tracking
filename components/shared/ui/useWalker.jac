"""useWalker component / hook helper: simplifies executing walkers or mock data."""

def:pub WalkerLoader(
    loading: bool,
    error: str = "",
    children: JsxElement | None = None,
    onRetry: Callable[[], None] = lambda {}
) -> JsxElement {
    if loading {
        return <div className="flex flex-col items-center justify-center p-8 space-y-3">
            <div className="w-8 h-8 border-2 border-[#FFC21A] border-t-transparent rounded-full animate-spin"/>
            <span className="text-xs font-semibold text-gray-400 uppercase tracking-widest animate-pulse">
                Querying Transit Graph...
            </span>
        </div>;
    }

    if error {
        return <div className="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/20 text-rose-300 text-center my-3">
            <p className="text-sm font-semibold mb-2">{error}</p>
            <button
                className="px-3 py-1.5 rounded-xl bg-rose-500/20 hover:bg-rose-500/30 text-xs font-bold transition-colors cursor-pointer"
                onClick={onRetry}
            >
                Retry Request
            </button>
        </div>;
    }

    return <div>{children}</div>;
}
