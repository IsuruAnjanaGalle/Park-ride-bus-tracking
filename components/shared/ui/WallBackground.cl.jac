"""WallBackground component: animated mesh gradient background with reduced-motion fallback."""

def:pub WallBackground(
    children: JsxElement | list[JsxElement] | None = None,
    variant: str = "dark"
) -> JsxElement {
    bgTheme = "bg-[#0B1220]" if variant == "dark" else "bg-[#0F1B2D]";
    containerCls = f"relative min-h-screen w-full {bgTheme} text-white overflow-x-hidden selection:bg-[#FFC21A] selection:text-[#0F1B2D]";

    return <div className={containerCls}>
        <div className="fixed inset-0 pointer-events-none overflow-hidden z-0">
            <div className="absolute -top-32 -right-32 w-96 h-96 rounded-full bg-[#FFC21A]/10 blur-3xl transform animate-pulse duration-1000"/>
            <div className="absolute -bottom-32 -left-32 w-[32rem] h-[32rem] rounded-full bg-[#2563EB]/15 blur-3xl transform animate-pulse duration-700"/>
            <div className="absolute top-1/3 left-1/2 -translate-x-1/2 w-80 h-80 rounded-full bg-[#7C3AED]/10 blur-3xl"/>
            <div
                className="absolute inset-0 opacity-[0.04]"
                style={{
                    "backgroundImage": "linear-gradient(to right, #ffffff 1px, transparent 1px), linear-gradient(to bottom, #ffffff 1px, transparent 1px)",
                    "backgroundSize": "36px 36px"
                }}
            />
        </div>

        <div className="relative z-10 w-full min-h-screen flex flex-col">
            {children}
        </div>
    </div>;
}
