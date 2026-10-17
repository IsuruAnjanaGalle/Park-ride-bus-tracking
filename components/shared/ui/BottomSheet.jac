"""BottomSheet component: mobile-first slide-up drawer for 390px responsive views."""

def:pub BottomSheet(
    isOpen: bool,
    title: str = "",
    children: JsxElement | list[JsxElement] | None = None,
    peekHeight: str = "auto",
    onClose: Callable[[], None] = lambda {}
) -> JsxElement {
    if not isOpen {
        return <div className="hidden"/>;
    }

    return <div
        className="fixed inset-0 z-50 flex flex-col justify-end bg-black/60 backdrop-blur-sm animate-fade-in sm:items-center"
        onClick={onClose}
    >
        <div
            className="w-full sm:max-w-md bg-[#0F1B2D] border-t sm:border border-white/20 rounded-t-3xl sm:rounded-3xl p-5 shadow-2xl shadow-black/80 transition-transform duration-300 ease-out max-h-[85vh] flex flex-col"
            onClick={lambda e: MouseEvent { e.stopPropagation(); }}
            style={{"minHeight": peekHeight if peekHeight != "auto" else "240px"}}
        >
            <div className="w-12 h-1.5 bg-white/25 rounded-full mx-auto mb-4 cursor-grab active:cursor-grabbing"/>

            <div className="flex items-center justify-between pb-3 mb-2 border-b border-white/10">
                <h4 className="text-lg font-bold text-white tracking-tight">{title}</h4>
                <button
                    className="w-8 h-8 rounded-lg text-gray-400 hover:text-white hover:bg-white/10 flex items-center justify-center transition-colors"
                    onClick={onClose}
                    aria-label="Dismiss sheet"
                >
                    <span className="text-lg font-bold leading-none">×</span>
                </button>
            </div>

            <div className="flex-1 overflow-y-auto text-gray-200 py-2">
                {children}
            </div>
        </div>
    </div>;
}
