"""Chip component: tag / badge with transit status tokens and route themes."""

def:pub Chip(
    label: str,
    variant: str = "default",
    icon: JsxElement | None = None,
    pulse: bool = False,
    removable: bool = False,
    onRemove: Callable[[], None] = lambda {}
) -> JsxElement {
    baseCls = "inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold tracking-wide border transition-all duration-200 select-none";

    varCls = "bg-emerald-500/15 text-emerald-300 border-emerald-500/30" if variant == "success"
        else ("bg-amber-500/15 text-amber-300 border-amber-500/30" if variant == "warning"
        else ("bg-rose-500/15 text-rose-300 border-rose-500/30" if variant == "danger"
        else ("bg-blue-500/15 text-blue-300 border-blue-500/30" if variant == "info"
        else ("bg-[#2563EB]/20 text-[#60A5FA] border-[#2563EB]/40 font-mono" if variant == "r1"
        else ("bg-[#7C3AED]/20 text-[#C084FC] border-[#7C3AED]/40 font-mono" if variant == "r2"
        else ("bg-[#0D9488]/20 text-[#2DD4BF] border-[#0D9488]/40 font-mono" if variant == "r3"
        else ("bg-[#FFC21A]/20 text-[#FFC21A] border-[#FFC21A]/40" if variant == "ev"
        else "bg-white/10 text-gray-300 border-white/15")))))));

    dotColor = "bg-emerald-400" if variant == "success"
        else ("bg-amber-400" if variant == "warning"
        else ("bg-rose-400" if variant == "danger"
        else ("bg-[#FFC21A]" if variant == "ev"
        else "bg-blue-400")));

    cls = f"{baseCls} {varCls}".strip();
    dotCls = f"relative inline-flex rounded-full h-2 w-2 {dotColor}";
    pingCls = f"animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 {dotColor}";

    return <span className={cls}>
        {<span className="relative flex h-2 w-2 mr-0.5">
            <span className={pingCls}/>
            <span className={dotCls}/>
        </span> if pulse else None}
        {<span className="inline-flex items-center text-sm">{icon}</span> if icon else None}
        <span>{label}</span>
        {<button
            className="ml-1 -mr-1 w-4 h-4 rounded-full inline-flex items-center justify-center hover:bg-white/20 transition-colors"
            onClick={onRemove}
            aria-label="Remove tag"
        >
            <span className="text-xs font-bold leading-none">×</span>
        </button> if removable else None}
    </span>;
}
