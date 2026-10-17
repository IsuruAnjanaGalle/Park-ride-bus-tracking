"""/ - passenger app. Placeholder from milestone 0; Dev B owns this page."""

import from "@jac/runtime" { Link }

def:pub PassengerHome -> JsxPage {
    <main className="mx-auto max-w-md p-4 flex flex-col gap-4">
        <h1 className="text-3xl font-bold">Park &amp; Ride Sri Lanka</h1>
        <p>Passenger app placeholder. Dev B builds the landing pop-up here.</p>
        <nav className="flex flex-wrap gap-3">
            <Link to="/login">Log in</Link>
            <Link to="/admin">Admin</Link>
            <Link to="/driver/MB-101">Driver MB-101</Link>
            <Link to="/dev/core">Core console</Link>
        </nav>
    </main>
"""/ - Passenger App for Park & Ride Sri Lanka.
Milestone 1: Landing Modal, Terminal Picker, EV Filtering, Slot Recommendation,
Interactive 2D Grid, and Gate Pass with 'Mark vehicle as parked'.
"""

import from "react" { useEffect }
import from "@jac/runtime" { Link, useNavigate }
import from components.shared.ui.Button { Button }
import from components.shared.ui.Toast { Toast }
import from components.shared.api {
    get_terminals,
    get_slots,
    recommend_slots,
    book_slot,
    mark_parked,
    release_slot,
    login,
    current_user
}
import from components.passenger.LandingModal { LandingModal }
import from components.passenger.TerminalPicker { TerminalPicker }
import from components.passenger.VehicleFilter { VehicleFilter }
import from components.passenger.SlotRecommendation { SlotRecommendation }
import from components.passenger.SlotGrid { SlotGrid }
import from components.passenger.ParkingPass { ParkingPass }

def:pub PassengerHome -> JsxPage {
    # App Mode & Modal State
    has showLandingModal: bool = True;
    has appMode: str = "park_and_ride";  # "park_and_ride" or "get_into_bus"
    has step: int = 1;                   # 1: Setup, 2: Slot Selection, 3: Gate Pass

    # Form configuration state
    has selectedTerminal: str = "MKB";
    has selectedVehicle: str = "C";
    has evChoice: str = "needs_charging";
    has accessible: bool = False;
    has arrival: str = "08:00";
    has returnBy: str = "10:00";
    has selectedSlotCode: str = "MKB-E-F-01";

    # Backend data state
    has terminals: list[dict] = [];
    has terminalSlots: list[dict] = [];
    has recommendation: dict = {};
    has activeBooking: dict = {};
    has loading: bool = False;
    has toastMsg: str = "";

    nav = useNavigate();

    async def init_data {
        loading = True;
        # Auto-login demo passenger if not logged in
        u = current_user();
        if not u {
            _ = await login("passenger", "pass123");
        }

        # Fetch terminals
        tRes = await get_terminals();
        if tRes.get("ok", False) {
            tData = dict(tRes.get("data", {}));
            terminals = list(tData.get("terminals", []));
        }

        # Fetch initial recommendation & slots for MKB
        await load_recommendations();
        loading = False;
    }

    async def load_recommendations {
        # Fetch recommendation
        rRes = await recommend_slots(
            terminal=selectedTerminal,
            vehicle=selectedVehicle,
            ev=evChoice,
            accessible=accessible,
            arrival=arrival,
            return_by=returnBy
        );
        if rRes.get("ok", False) {
            rData = dict(rRes.get("data", {}));
            recommendation = rData;
            opts = list(rData.get("options", []));
            if len(opts) > 0 {
                firstSlot = dict(opts[0].get("slot", {}));
                selectedSlotCode = str(firstSlot.get("code", "MKB-C-F-01"));
            }
        }

        # Fetch slots for grid
        sRes = await get_slots(terminal=selectedTerminal);
        if sRes.get("ok", False) {
            sData = dict(sRes.get("data", {}));
            terminalSlots = list(sData.get("slots", []));
        }
    }

    useEffect(lambda {
        init_data();
    }, []);

    # Handlers
    def handle_select_park_and_ride {
        appMode = "park_and_ride";
        showLandingModal = False;
        step = 1;
    }

    def handle_select_get_into_bus {
        appMode = "get_into_bus";
        showLandingModal = False;
    }

    async def handle_confirm_slot_step {
        loading = True;
        await load_recommendations();
        loading = False;
        step = 2;
    }

    async def handle_book_slot {
        loading = True;
        bRes = await book_slot(
            terminal=selectedTerminal,
            slot_code=selectedSlotCode,
            arrival=arrival,
            return_by=returnBy
        );
        if bRes.get("ok", False) {
            bData = dict(bRes.get("data", {}));
            activeBooking = dict(bData.get("booking", {}));
            step = 3;
            toastMsg = f"Slot {selectedSlotCode} booked successfully!";
        } else {
            err = dict(bRes.get("error", {}));
            toastMsg = str(err.get("message", "Booking failed"));
        }
        loading = False;
    }

    async def handle_mark_parked {
        bId = str(activeBooking.get("id", ""));
        loading = True;
        mRes = await mark_parked(booking_id=bId);
        if mRes.get("ok", False) {
            mData = dict(mRes.get("data", {}));
            activeBooking = dict(mData.get("booking", {}));
            toastMsg = "Vehicle successfully parked! Bay status: OCCUPIED";
        }
        loading = False;
    }

    async def handle_release_slot {
        bId = str(activeBooking.get("id", ""));
        loading = True;
        rRes = await release_slot(booking_id=bId);
        if rRes.get("ok", False) {
            toastMsg = "Slot released. Thank you for using Park & Ride!";
            step = 1;
        }
        loading = False;
    }

    user = current_user();
    userName = user["username"] if user else "guest";

    return <div className="min-h-screen bg-[#0B1220] text-white flex flex-col font-sans selection:bg-[#FFC21A] selection:text-[#0F1B2D]">
        # Landing Pop-up Modal
        <LandingModal
            isOpen={showLandingModal}
            onSelectParkAndRide={handle_select_park_and_ride}
            onSelectGetIntoBus={handle_select_get_into_bus}
            onClose={lambda { showLandingModal = False; }}
        />

        # Top Navigation Bar
        <header className="sticky top-0 z-40 bg-[#0F1B2D]/90 border-b border-white/10 backdrop-blur-xl px-4 py-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3">
                <button
                    onClick={lambda (_e: MouseEvent) { showLandingModal = True; }}
                    className="w-9 h-9 rounded-xl bg-[#FFC21A] text-[#0F1B2D] font-black text-sm flex items-center justify-center shadow-lg shadow-[#FFC21A]/20 cursor-pointer"
                >
                    PR
                </button>
                <div>
                    <div className="flex items-center gap-2">
                        <span className="font-extrabold text-sm sm:text-base text-white">Park &amp; Ride Sri Lanka</span>
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#FFC21A]/20 text-[#FFC21A]">
                            {("Park & Ride" if appMode == "park_and_ride" else "Bus Passenger")}
                        </span>
                    </div>
                    <span className="text-[11px] text-gray-400">Colombo Metro Transit · Makumbura Hub</span>
                </div>
            </div>

            <div className="flex items-center gap-3">
                <button
                    onClick={lambda (_e: MouseEvent) { showLandingModal = True; }}
                    className="text-xs text-gray-300 hover:text-[#FFC21A] transition-colors"
                >
                    Switch Mode
                </button>
                <div className="hidden sm:flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/[0.05] border border-white/10 text-xs">
                    <span className="w-2 h-2 rounded-full bg-emerald-400" />
                    <span className="text-gray-300 font-mono">{userName}</span>
                </div>
            </div>
        </header>

        # Main Page Container (Mobile-first 390px up to max-w-xl)
        <main className="flex-1 w-full max-w-2xl mx-auto p-4 sm:p-6 flex flex-col gap-6">
            # App Mode 1: Park & Ride Flow
            {if appMode == "park_and_ride" {
                <div className="flex flex-col gap-6">
                    # Step Progress Bar
                    <div className="flex items-center justify-between p-3 rounded-2xl bg-white/[0.03] border border-white/10 text-xs">
                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { step = 1; }}
                            className={f"flex items-center gap-1.5 font-bold transition-colors {'text-[#FFC21A]' if step == 1 else 'text-gray-400 hover:text-white'}"}
                        >
                            <span className={f"w-5 h-5 rounded-full flex items-center justify-center text-[10px] {'bg-[#FFC21A] text-[#0F1B2D]' if step == 1 else 'bg-white/10 text-gray-300'}"}>1</span>
                            <span>Setup</span>
                        </button>
                        <span className="text-gray-600">&rarr;</span>

                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { if len(recommendation) > 0 { step = 2; } }}
                            className={f"flex items-center gap-1.5 font-bold transition-colors {'text-[#FFC21A]' if step == 2 else 'text-gray-400 hover:text-white'}"}
                        >
                            <span className={f"w-5 h-5 rounded-full flex items-center justify-center text-[10px] {'bg-[#FFC21A] text-[#0F1B2D]' if step == 2 else 'bg-white/10 text-gray-300'}"}>2</span>
                            <span>Choose Slot</span>
                        </button>
                        <span className="text-gray-600">&rarr;</span>

                        <div className={f"flex items-center gap-1.5 font-bold {'text-[#FFC21A]' if step == 3 else 'text-gray-500'}"}>
                            <span className={f"w-5 h-5 rounded-full flex items-center justify-center text-[10px] {'bg-[#FFC21A] text-[#0F1B2D]' if step == 3 else 'bg-white/10 text-gray-500'}"}>3</span>
                            <span>Gate Pass</span>
                        </div>
                    </div>

                    # STEP 1: Terminal & Vehicle Filters
                    {if step == 1 {
                        <div className="flex flex-col gap-6">
                            <TerminalPicker
                                terminals={terminals}
                                selectedTerminal={selectedTerminal}
                                selectedVehicle={selectedVehicle}
                                onSelect={lambda (c: str) { selectedTerminal = c; }}
                            />

                            <VehicleFilter
                                selectedVehicle={selectedVehicle}
                                evChoice={evChoice}
                                accessible={accessible}
                                arrival={arrival}
                                returnBy={returnBy}
                                onChangeVehicle={lambda (v: str) { selectedVehicle = v; }}
                                onChangeEv={lambda (e: str) { evChoice = e; }}
                                onToggleAccessible={lambda (a: bool) { accessible = a; }}
                                onChangeArrival={lambda (t: str) { arrival = t; }}
                                onChangeReturnBy={lambda (t: str) { returnBy = t; }}
                            />

                            <button
                                type="button"
                                onClick={lambda (_e: MouseEvent) { handle_confirm_slot_step(); }}
                                className="w-full py-4 px-6 rounded-2xl bg-[#FFC21A] text-[#0F1B2D] font-extrabold text-base shadow-xl shadow-[#FFC21A]/20 hover:bg-[#e5ad16] active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
                            >
                                <span>Find Best Parking Slots</span>
                                <span>&rarr;</span>
                            </button>
                        </div>
                    }}

                    # STEP 2: Recommended Options & Interactive Bay Grid
                    {if step == 2 {
                        <div className="flex flex-col gap-6">
                            <div className="flex items-center justify-between">
                                <button
                                    type="button"
                                    onClick={lambda (_e: MouseEvent) { step = 1; }}
                                    className="text-xs text-gray-400 hover:text-white flex items-center gap-1"
                                >
                                    <span>&larr;</span>
                                    <span>Change Terminal / Vehicle</span>
                                </button>
                                <span className="text-xs text-[#FFC21A] font-bold">
                                    Selected: {selectedSlotCode}
                                </span>
                            </div>

                            # Algorithmic Recommendation Cards
                            <SlotRecommendation
                                recommendation={recommendation}
                                selectedSlotCode={selectedSlotCode}
                                onSelectSlot={lambda (code: str) { selectedSlotCode = code; }}
                            />

                            # Interactive 2D Grid (Makumbura)
                            <SlotGrid
                                slots={terminalSlots}
                                selectedSlotCode={selectedSlotCode}
                                recommendedSlotCode={str(dict(recommendation.get("options", [{}])[0].get("slot", {})).get("code", ""))}
                                onSelectSlot={lambda (code: str) { selectedSlotCode = code; }}
                            />

                            # Book Button
                            <button
                                type="button"
                                onClick={lambda (_e: MouseEvent) { handle_book_slot(); }}
                                className="w-full py-4 px-6 rounded-2xl bg-[#FFC21A] text-[#0F1B2D] font-black text-base shadow-xl shadow-[#FFC21A]/25 hover:bg-[#e5ad16] active:scale-95 transition-all flex items-center justify-center gap-2 cursor-pointer"
                            >
                                <span>Book Slot {selectedSlotCode}</span>
                                <span>&rarr;</span>
                            </button>
                        </div>
                    }}

                    # STEP 3: Confirmed Gate Pass & 'Mark vehicle as parked'
                    {if step == 3 {
                        <div className="flex flex-col gap-6">
                            <ParkingPass
                                booking={activeBooking}
                                onMarkParked={handle_mark_parked}
                                onReleaseSlot={handle_release_slot}
                                onProceedToBus={lambda { appMode = "get_into_bus"; }}
                            />
                        </div>
                    }}
                </div>
            } else {
                # App Mode 2: Get into Bus View (Milestone 2 Preview)
                <div className="flex flex-col gap-6 text-center py-8 p-6 rounded-3xl bg-[#0F1B2D] border border-white/10">
                    <div className="w-16 h-16 rounded-2xl bg-[#22D3EE]/20 border border-[#22D3EE]/40 text-3xl flex items-center justify-center mx-auto shadow-lg shadow-[#22D3EE]/20">
                        🚌
                    </div>
                    <div>
                        <h2 className="text-2xl font-black text-white">Live Metro Bus Tracking</h2>
                        <p className="text-xs text-gray-400 mt-2 max-w-sm mx-auto leading-relaxed">
                            Express buses connected to Makumbura Multimodal Hub. Real-time GPS tracking, seat reservations &amp; QR boarding.
                        </p>
                    </div>

                    <div className="p-4 rounded-2xl bg-white/[0.04] border border-white/10 text-left flex flex-col gap-3">
                        <span className="text-xs font-bold text-[#FFC21A]">Express Routes from Makumbura:</span>
                        <div className="flex flex-col gap-2 text-xs text-gray-300">
                            <div className="flex items-center justify-between p-2 rounded-lg bg-blue-500/10 border border-blue-500/20">
                                <span className="font-bold text-blue-300">Route 1: Makumbura &rarr; Pettah</span>
                                <span className="text-[11px] text-gray-400">Via Battaramulla</span>
                            </div>
                            <div className="flex items-center justify-between p-2 rounded-lg bg-purple-500/10 border border-purple-500/20">
                                <span className="font-bold text-purple-300">Route 2: Makumbura &rarr; Kadawatha</span>
                                <span className="text-[11px] text-gray-400">Via Kelaniya</span>
                            </div>
                        </div>
                    </div>

                    <button
                        type="button"
                        onClick={lambda (_e: MouseEvent) { appMode = "park_and_ride"; step = 1; }}
                        className="w-full py-3 px-4 rounded-xl border border-white/20 text-xs font-bold text-gray-300 hover:text-white hover:bg-white/10 transition-colors"
                    >
                        &larr; Back to Park &amp; Ride Parking
                    </button>
                </div>
            }}
        </main>

        # Toast notification
        {if toastMsg {
            <div className="fixed bottom-6 right-6 z-50">
                <Toast
                    message={toastMsg}
                    type="success"
                    onClose={lambda { toastMsg = ""; }}
                />
            </div>
        }}

        # Bottom Footer Bar
        <footer className="mt-auto border-t border-white/10 bg-[#0F1B2D]/50 p-4 text-center text-xs text-gray-500">
            <span>Park &amp; Ride Sri Lanka · Jac 0.37 Full-stack System</span>
        </footer>
    </div>;
}
