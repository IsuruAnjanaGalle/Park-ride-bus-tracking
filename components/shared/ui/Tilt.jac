"""Tilt component: interactive 3D perspective tilt container."""

def:pub Tilt(
    children: JsxElement | list[JsxElement] | None = None,
    className: str = "",
    maxTilt: float = 10.0,
    onClick: Callable[[], None] = lambda {}
) -> JsxElement {
    baseCls = "group perspective-1000 transform-gpu transition-all duration-300 ease-out hover:scale-[1.02] active:scale-[0.98] cursor-pointer";
    cls = f"{baseCls} {className}".strip();
    perspVal = f"{int(maxTilt * 100)}px";

    return <div
        className={cls}
        {onClick}
        style={{"perspective": perspVal}}
    >
        <div className="relative rounded-2xl transition-transform duration-300 ease-out group-hover:[transform:rotateX(4deg)_rotateY(-4deg)_translateZ(10px)]">
            <div className="absolute inset-0 bg-gradient-to-tr from-white/0 via-white/5 to-white/10 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"/>
            {children}
        </div>
    </div>;
}
