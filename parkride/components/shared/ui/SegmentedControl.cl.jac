"""SegmentedControl component: tactile multi-option selector for terminals, vehicles, and filters."""

def:pub SegmentedControl(
    options: list[dict[str, str]],
    selectedKey: str,
    onChange: Callable[[str], None],
    size: str = "md"
) -> JsxElement {
    padCls = "p-1 gap-1" if size == "sm" else "p-1.5 gap-1.5";
    containerCls = f"inline-flex w-full items-center bg-[#0B1220]/80 border border-white/10 rounded-2xl backdrop-blur-md {padCls}";

    buttons: list[JsxElement] = [];
    for opt in options {
        k: str = str(opt.get("key", ""));
        lbl: str = str(opt.get("label", k));
        ic: str = str(opt.get("icon", ""));
        bdg: str = str(opt.get("badge", ""));
        isSelected = (k == selectedKey);

        activeCls = "bg-[#FFC21A] text-[#0F1B2D] shadow-md shadow-[#FFC21A]/20 scale-[1.02]"
            if isSelected
            else "text-gray-400 hover:text-white hover:bg-white/5";
        btnCls = f"flex-1 inline-flex items-center justify-center font-semibold rounded-xl transition-all duration-200 select-none min-h-[40px] px-3 py-2 text-xs sm:text-sm {activeCls}";

        btn = <button
            key={k}
            role="tab"
            aria-selected={isSelected}
            className={btnCls}
            onClick={lambda { onChange(k); }}
        >
            {<span className="mr-1.5">{ic}</span> if ic else None}
            <span>{lbl}</span>
            {<span className="ml-1.5 px-1.5 py-0.5 rounded-full text-[10px] bg-[#0F1B2D]/20 text-[#0F1B2D] font-bold">
                {bdg}
            </span> if bdg and isSelected else None}
        </button>;
        buttons.append(btn);
    }

    return <div className={containerCls} role="tablist">
        {buttons}
    </div>;
}
