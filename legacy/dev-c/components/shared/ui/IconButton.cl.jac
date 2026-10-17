"""IconButton component for Park & Ride Sri Lanka UI Kit."""

def:pub IconButton(
    icon: JsxElement,
    ariaLabel: str,
    onClick: Callable[[], None] = lambda {},
    variant: str = "ghost",
    size: str = "md",
    disabled: bool = False,
    badge: str = ""
) -> JsxElement {
    baseCls = "relative inline-flex items-center justify-center rounded-xl transition-all duration-200 cursor-pointer select-none active:scale-90 disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100 min-w-[44px] min-h-[44px]";

    varCls = "bg-[#FFC21A] text-[#0F1B2D] hover:bg-[#e5ad16] shadow-md shadow-[#FFC21A]/20" if variant == "primary"
        else ("bg-[#0F1B2D] text-white hover:bg-[#1A2C42] border border-white/10" if variant == "secondary"
        else ("bg-white/10 text-white backdrop-blur-md hover:bg-white/20 border border-white/20" if variant == "glass"
        else "bg-transparent text-gray-300 hover:text-white hover:bg-white/10"));

    szCls = "w-10 h-10 text-sm" if size == "sm"
        else ("w-14 h-14 text-xl" if size == "lg"
        else "w-11 h-11 text-base");

    cls = f"{baseCls} {varCls} {szCls}".strip();

    return <button
        className={cls}
        aria-label={ariaLabel}
        title={ariaLabel}
        {onClick}
        {disabled}
    >
        <span className="inline-flex items-center justify-center">{icon}</span>
        {<span className="absolute -top-1 -right-1 bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full shadow-sm animate-pulse">
            {badge}
        </span> if badge else None}
    </button>;
}
