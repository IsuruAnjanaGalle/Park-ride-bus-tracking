"""LandingModal component for Park & Ride Sri Lanka.
Allows the commuter to choose between 'Park & Ride' and 'Get into Bus'.
"""

import from components.shared.ui.Button { Button }
import from components.shared.ui.GlassCard { GlassCard }
import from components.shared.api { current_user, login }

def:pub LandingModal(
    isOpen: bool,
    onSelectParkAndRide: Callable[[], None],
    onSelectGetIntoBus: Callable[[], None],
    onClose: Callable[[], None] = lambda {}
) -> JsxElement {
    if not isOpen {
        return <></>;
    }

    user = current_user();

    def handle_demo_login {
        login("passenger", "pass123");
    }

    return <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-fade-in">
        <div className="relative w-full max-w-lg overflow-hidden rounded-3xl bg-[#0F1B2D] border border-white/15 p-6 sm:p-8 shadow-2xl text-white">
            # Glowing background gradient orb
            <div className="absolute -top-24 -right-24 w-64 h-64 bg-[#FFC21A]/20 rounded-full blur-3xl pointer-events-none" />
            <div className="absolute -bottom-24 -left-24 w-64 h-64 bg-[#22D3EE]/20 rounded-full blur-3xl pointer-events-none" />

            <div className="relative z-10 flex flex-col gap-6">
                # Header
                <div className="flex items-center justify-between border-b border-white/10 pb-4">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-2xl bg-[#FFC21A] flex items-center justify-center text-[#0F1B2D] font-black text-xl shadow-lg shadow-[#FFC21A]/30">
                            PR
                        </div>
                        <div>
                            <h2 className="text-xl font-bold tracking-tight text-white">Park &amp; Ride Sri Lanka</h2>
                            <p className="text-xs text-gray-400">Metro Multimodal Transit Hub</p>
                        </div>
                    </div>
                    {if user {
                        <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                            {user["username"]}
                        </span>
                    } else {
                        <button
                            onClick={handle_demo_login}
                            className="text-xs text-[#FFC21A] hover:underline"
                        >
                            Quick Login (Demo)
                        </button>
                    }}
                </div>

                # Subtitle prompt
                <div className="text-center">
                    <h3 className="text-lg font-semibold text-white">How are you commuting today?</h3>
                    <p className="text-xs text-gray-400 mt-1">Select an option below to plan your trip.</p>
                </div>

                # Two large primary cards
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    # Card 1: Park & Ride
                    <div
                        onClick={onSelectParkAndRide}
                        className="group relative cursor-pointer rounded-2xl border-2 border-white/10 hover:border-[#FFC21A] bg-white/[0.03] hover:bg-[#FFC21A]/[0.08] p-5 transition-all duration-200 flex flex-col justify-between gap-4"
                    >
                        <div className="w-12 h-12 rounded-xl bg-[#FFC21A]/20 border border-[#FFC21A]/40 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform">
                            🅿️
                        </div>
                        <div>
                            <h4 className="text-base font-bold text-white group-hover:text-[#FFC21A] transition-colors">
                                Park &amp; Ride
                            </h4>
                            <p className="text-xs text-gray-400 mt-1 leading-relaxed">
                                Park your car or bike at a terminal hub and board the express bus.
                            </p>
                        </div>
                        <div className="inline-flex items-center text-xs font-semibold text-[#FFC21A] group-hover:translate-x-1 transition-transform">
                            Reserve slot &rarr;
                        </div>
                    </div>

                    # Card 2: Get into Bus
                    <div
                        onClick={onSelectGetIntoBus}
                        className="group relative cursor-pointer rounded-2xl border-2 border-white/10 hover:border-[#22D3EE] bg-white/[0.03] hover:bg-[#22D3EE]/[0.08] p-5 transition-all duration-200 flex flex-col justify-between gap-4"
                    >
                        <div className="w-12 h-12 rounded-xl bg-[#22D3EE]/20 border border-[#22D3EE]/40 flex items-center justify-center text-2xl group-hover:scale-110 transition-transform">
                            🚌
                        </div>
                        <div>
                            <h4 className="text-base font-bold text-white group-hover:text-[#22D3EE] transition-colors">
                                Get into Bus
                            </h4>
                            <p className="text-xs text-gray-400 mt-1 leading-relaxed">
                                Walk straight to a bus stop, track live GPS, and book an on-board seat.
                            </p>
                        </div>
                        <div className="inline-flex items-center text-xs font-semibold text-[#22D3EE] group-hover:translate-x-1 transition-transform">
                            View live bus &rarr;
                        </div>
                    </div>
                </div>

                # Footer note
                <div className="flex items-center justify-between text-[11px] text-gray-500 pt-2 border-t border-white/10">
                    <span>Makumbura · Kadawatha · Kesbewa · Pettah</span>
                    <button onClick={onClose} className="hover:text-gray-300">Close</button>
                </div>
            </div>
        </div>
    </div>;
}
