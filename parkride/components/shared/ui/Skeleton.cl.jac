"""Skeleton component: shimmering placeholder for async loading states."""

def:pub Skeleton(
    variant: str = "text",
    width: str = "100%",
    height: str = "20px",
    className: str = ""
) -> JsxElement {
    baseCls = "animate-pulse bg-white/10 relative overflow-hidden";

    shapeCls = "rounded-full" if variant == "circle"
        else ("rounded-2xl" if variant == "card"
        else ("rounded-lg" if variant == "rect"
        else "rounded-md"));

    actualHeight = ("44px" if height == "20px" and variant == "circle" else height);
    actualWidth = ("44px" if width == "100%" and variant == "circle" else width);

    cls = f"{baseCls} {shapeCls} {className}".strip();

    return <div
        className={cls}
        style={{"width": actualWidth, "height": actualHeight}}
    >
        <div className="absolute inset-0 -translate-x-full animate-[shimmer_1.5s_infinite] bg-gradient-to-r from-transparent via-white/10 to-transparent"/>
    </div>;
}
