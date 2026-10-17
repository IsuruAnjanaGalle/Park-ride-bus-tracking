"""EmptyState component: clear empty state view for empty lists or searches."""

def:pub EmptyState(
    title: str,
    message: str,
    icon: JsxElement | None = None,
    actionLabel: str = "",
    onAction: Callable[[], None] = lambda {}
) -> JsxElement {
    return <div className="flex flex-col items-center justify-center text-center p-8 rounded-3xl bg-[#0F1B2D]/50 border border-white/10 backdrop-blur-md">
        <div className="w-16 h-16 mb-4 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center text-gray-400 text-3xl shadow-inner">
            {icon if icon else <span>∅</span>}
        </div>
        <h4 className="text-lg font-bold text-white mb-1.5">{title}</h4>
        <p className="text-sm text-gray-400 max-w-xs mb-5 leading-relaxed">{message}</p>
        {<button
            className="inline-flex items-center justify-center font-semibold rounded-xl bg-[#FFC21A] text-[#0F1B2D] hover:bg-[#e5ad16] px-5 py-2.5 text-sm transition-all shadow-md shadow-[#FFC21A]/20 cursor-pointer min-h-[44px]"
            onClick={onAction}
        >
            <span>{actionLabel}</span>
        </button> if actionLabel else None}
    </div>;
}
