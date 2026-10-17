"""Button component for Park & Ride Sri Lanka UI Kit."""

def:pub Button(
    label: str,
    onClick: Callable[[], None] = lambda {},
    variant: str = "primary",
    size: str = "md",
    disabled: bool = False,
    fullWidth: bool = False,
    icon: JsxElement | None = None
) -> JsxElement {
    baseCls = "inline-flex items-center justify-center font-semibold rounded-xl transition-all duration-200 cursor-pointer select-none active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100 min-h-[44px]";
    
    varCls = "bg-[#FFC21A] text-[#0F1B2D] hover:bg-[#e5ad16] shadow-md shadow-[#FFC21A]/20" if variant == "primary"
        else ("bg-[#0F1B2D] text-white hover:bg-[#1A2C42] border border-white/10" if variant == "secondary"
        else ("bg-white/10 text-white backdrop-blur-md hover:bg-white/20 border border-white/20" if variant == "glass"
        else ("bg-transparent text-gray-400 hover:text-white hover:bg-white/5" if variant == "ghost"
        else ("bg-red-500/20 text-red-400 border border-red-500/30 hover:bg-red-500/30" if variant == "danger"
        else "bg-[#FFC21A] text-[#0F1B2D]"))));

    szCls = "px-3 py-1.5 text-xs" if size == "sm"
        else ("px-6 py-3 text-base" if size == "lg"
        else "px-4 py-2.5 text-sm");

    widthCls = "w-full" if fullWidth else "";
    cls = f"{baseCls} {varCls} {szCls} {widthCls}".strip();

    return <button
        className={cls}
        {onClick}
        {disabled}
    >
        {<span className="mr-2 inline-flex items-center">{icon}</span> if icon else None}
        <span>{label}</span>
    </button>;
}
