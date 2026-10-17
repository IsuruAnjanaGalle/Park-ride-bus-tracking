"""GlassCard component for Park & Ride Sri Lanka UI Kit."""

def:pub GlassCard(
    children: JsxElement | list[JsxElement] | None = None,
    className: str = "",
    variant: str = "default",
    padding: str = "md",
    onClick: Callable[[], None] = lambda {}
) -> JsxElement {
    baseCls = "rounded-2xl backdrop-blur-xl border transition-all duration-300 relative overflow-hidden";

    # Tokens: deep navy backdrop with translucent highlight
    varCls = "bg-[#0F1B2D]/70 border-white/10 shadow-xl shadow-black/30" if variant == "default"
        else ("bg-[#0F1B2D]/85 border-[#FFC21A]/30 shadow-2xl shadow-[#FFC21A]/10 ring-1 ring-[#FFC21A]/20" if variant == "glow"
        else ("bg-white/10 border-white/20 shadow-lg text-white" if variant == "light"
        else ("bg-[#0B1220]/90 border-white/5 shadow-inner" if variant == "sunken"
        else ("bg-gradient-to-br from-[#0F1B2D]/90 to-[#1E293B]/80 border-blue-500/20" if variant == "accent"
        else "bg-[#0F1B2D]/70 border-white/10"))));

    padCls = "p-2" if padding == "none"
        else ("p-3" if padding == "sm"
        else ("p-6" if padding == "lg"
        else "p-4"));

    hoverCls = "hover:border-white/25 hover:translate-y-[-2px] cursor-pointer" if onClick else "";
    combinedCls = f"{baseCls} {varCls} {padCls} {hoverCls} {className}".strip();

    return <div className={combinedCls} {onClick}>
        <div className="absolute -top-12 -right-12 w-32 h-32 bg-white/5 rounded-full blur-2xl pointer-events-none"/>
        <div className="relative z-10">{children}</div>
    </div>;
}
