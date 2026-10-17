"""WallBackground3D component: interactive 3D particle mesh background with static fallback."""

import from components.shared.ui.WallBackground { WallBackground }

def:pub WallBackground3D(
    children: JsxElement | list[JsxElement] | None = None,
    enableParticles: bool = True
) -> JsxElement {
    return <div className="relative min-h-screen w-full bg-[#080D1A] text-white overflow-x-hidden selection:bg-[#FFC21A] selection:text-[#0F1B2D]">
        <div
            className="fixed inset-0 pointer-events-none overflow-hidden z-0"
            style={{"perspective": "1000px"}}
        >
            <div
                className="absolute -inset-10 opacity-10 [transform:rotateX(25deg)] transform-gpu"
                style={{
                    "backgroundImage": "radial-gradient(circle at 50% 50%, #FFC21A 1px, transparent 1px), radial-gradient(circle at 50% 50%, #2563EB 1px, transparent 1px)",
                    "backgroundSize": "48px 48px, 96px 96px",
                    "backgroundPosition": "0 0, 24px 24px"
                }}
            />

            <div className="absolute top-10 right-10 w-80 h-80 rounded-full bg-gradient-to-br from-[#FFC21A]/20 to-transparent blur-3xl animate-pulse duration-1000"/>
            <div className="absolute bottom-10 left-10 w-96 h-96 rounded-full bg-gradient-to-tr from-[#2563EB]/25 to-transparent blur-3xl animate-pulse duration-700"/>
            <div className="absolute top-1/2 left-1/3 w-64 h-64 rounded-full bg-[#7C3AED]/15 blur-3xl"/>

            {<div className="absolute inset-0 opacity-20">
                <div className="absolute top-1/4 left-1/4 w-1.5 h-1.5 rounded-full bg-[#FFC21A] animate-ping"/>
                <div className="absolute top-1/3 right-1/3 w-2 h-2 rounded-full bg-[#2563EB] animate-pulse"/>
                <div className="absolute bottom-1/4 right-1/4 w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping"/>
                <div className="absolute bottom-1/3 left-1/3 w-2 h-2 rounded-full bg-[#7C3AED] animate-pulse"/>
            </div> if enableParticles else None}
        </div>

        <div className="relative z-10 w-full min-h-screen flex flex-col">
            {children}
        </div>
    </div>;
}
