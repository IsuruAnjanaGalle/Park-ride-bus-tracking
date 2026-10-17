"""Modal3D component: 3D perspective pop-up dialog with glass overlay."""

def:pub Modal3D(
    isOpen: bool,
    title: str = "",
    children: JsxElement | list[JsxElement] | None = None,
    footer: JsxElement | None = None,
    onClose: Callable[[], None] = lambda {}
) -> JsxElement {
    if not isOpen {
        return <div className="hidden"/>;
    }

    return <div
        className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-md animate-fade-in"
        style={{"perspective": "1200px"}}
        onClick={onClose}
    >
        <div
            className="relative w-full max-w-lg bg-[#0F1B2D]/95 border border-white/20 rounded-3xl p-6 shadow-2xl shadow-black/70 transform transition-all duration-300 ease-out [transform:rotateX(2deg)_translateZ(20px)]"
            onClick={lambda e: MouseEvent { e.stopPropagation(); }}
        >
            <div className="flex items-center justify-between pb-4 border-b border-white/10">
                <h3 className="text-xl font-bold text-white tracking-wide">{title}</h3>
                <button
                    className="w-9 h-9 inline-flex items-center justify-center rounded-xl text-gray-400 hover:text-white hover:bg-white/10 transition-colors"
                    onClick={onClose}
                    aria-label="Close dialog"
                >
                    <span className="text-xl font-bold leading-none">×</span>
                </button>
            </div>

            <div className="py-5 text-gray-200 overflow-y-auto max-h-[70vh]">
                {children}
            </div>

            {<div className="pt-4 border-t border-white/10 flex justify-end gap-3">
                {footer}
            </div> if footer else None}
        </div>
    </div>;
}
