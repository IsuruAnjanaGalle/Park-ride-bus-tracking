"""/ - Passenger App for Park & Ride Sri Lanka (Milestones 1 & 2).

Includes:
- Milestone 1: Landing Modal, Terminal Picker, EV Filtering, Slot Recommendation,
  Interactive 310-Bay Grid, and Digital Gate Pass with 'Mark vehicle as parked'.
- Milestone 2: Interactive SVG CityMap with 9 live buses polled every 2s,
  fleet cards, seat booking modal with segment seat check, trip view with
  2-stop arrival alert banner, and stop QR camera/demo scanner with dedupe.
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
    get_map,
    get_buses,
    book_seat,
    get_trip,
    process_scan,
    login,
    current_user
}
import from components.passenger.LandingModal { LandingModal }
import from components.passenger.TerminalPicker { TerminalPicker }
import from components.passenger.VehicleFilter { VehicleFilter }
import from components.passenger.SlotRecommendation { SlotRecommendation }
import from components.passenger.SlotGrid { SlotGrid }
import from components.passenger.ParkingPass { ParkingPass }
import from components.shared.CityMap { CityMap }
import from components.passenger.BusCard { BusCard }
import from components.passenger.SeatBookingModal { SeatBookingModal }
import from components.passenger.TripView { TripView }
import from components.passenger.QRScannerModal { QRScannerModal }

def:pub PassengerHome -> JsxPage {
    # App Mode & Navigation
    has showLandingModal: bool = True;
    has appMode: str = "park_and_ride";  # "park_and_ride" or "get_into_bus"
    has step: int = 1;                   # 1: Setup, 2: Slot Selection, 3: Gate Pass

    # Parking configuration state
    has selectedTerminal: str = "MKB";
    has selectedVehicle: str = "C";
    has evChoice: str = "needs_charging";
    has accessible: bool = False;
    has arrival: str = "08:00";
    has returnBy: str = "10:00";
    has selectedSlotCode: str = "MKB-E-F-01";

    # Parking backend data
    has terminals: list[dict[str, any]] = [];
    has terminalSlots: list[dict[str, any]] = [];
    has recommendation: dict[str, any] = {};
    has activeParkingBooking: dict[str, any] = {};

    # Bus tracking & journey state (Milestone 2)
    has mapData: dict[str, any] = {};
    has buses: list[dict[str, any]] = [];
    has selectedRoute: str = "ALL";
    has selectedBus: dict[str, any] = {};
    has showBookingModal: bool = False;
    has showScannerModal: bool = False;
    has hasActiveTrip: bool = False;
    has activeTripData: dict[str, any] = {};

    # General UI state
    has loading: bool = False;
    has toastMsg: str = "";

    async def init_data {
        loading = True;
        # Auto-login demo passenger
        u = current_user();
        if not u {
            _ = await login("passenger", "demo-passenger");
        }

        # 1. Fetch parking terminals
        tRes = await get_terminals();
        if tRes.get("ok", False) {
            tData: dict[str, any] = dict(tRes.get("data", {}));
            terminals = list(tData.get("terminals", []));
        }

        # 2. Fetch initial recommendation & slots for MKB
        await load_recommendations();

        # 3. Fetch road network map for Colombo
        mRes = await get_map();
        if mRes.get("ok", False) {
            mData: dict[str, any] = dict(mRes.get("data", {}));
            mapData = mData;
        }

        # 4. Fetch initial live buses
        await refresh_buses();

        loading = False;
    }

    async def load_recommendations {
        rRes = await recommend_slots(
            terminal=selectedTerminal,
            vehicle=selectedVehicle,
            ev=evChoice,
            accessible=accessible,
            arrival=arrival,
            return_by=returnBy
        );
        if rRes.get("ok", False) {
            rData: dict[str, any] = dict(rRes.get("data", {}));
            recommendation = rData;
            opts = list(rData.get("options", []));
            if len(opts) > 0 {
                firstSlot: dict[str, any] = dict(opts[0].get("slot", {}));
                selectedSlotCode = str(firstSlot.get("code", "MKB-C-F-01"));
            }
        }

        sRes = await get_slots(terminal=selectedTerminal);
        if sRes.get("ok", False) {
            sData: dict[str, any] = dict(sRes.get("data", {}));
            terminalSlots = list(sData.get("slots", []));
        }
    }

    async def refresh_buses {
        rParam = "" if selectedRoute == "ALL" else selectedRoute;
        bRes = await get_buses(route=rParam);
        if bRes.get("ok", False) {
            bData: dict[str, any] = dict(bRes.get("data", {}));
            buses = [dict(b) for b in list(bData.get("buses", []))];
        }
    }

    async def refresh_trip {
        if hasActiveTrip {
            trRes = await get_trip();
            if trRes.get("ok", False) {
                trData: dict[str, any] = dict(trRes.get("data", {}));
                activeTripData = trData;
            }
        }
    }

    # Initial load
    useEffect(lambda {
        _started = init_data();  # not returned: React effects must not return a Promise
    }, []);

    # Live polling every 2s for buses and active trip telemetry
    useEffect(lambda {
        h = setInterval(lambda {
            refresh_buses();
            refresh_trip();
        }, 2000);
        return lambda {
            clearInterval(h);
        };
    }, [selectedRoute, hasActiveTrip]);

    # Mode 1 Handlers (Parking)
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
            bData: dict[str, any] = dict(bRes.get("data", {}));
            activeParkingBooking = dict(bData.get("booking", {}));
            step = 3;
            toastMsg = f"Slot {selectedSlotCode} booked successfully!";
        } else {
            err: dict[str, any] = dict(bRes.get("error", {}));
            toastMsg = str(err.get("message", "Booking failed"));
        }
        loading = False;
    }

    async def handle_mark_parked {
        bId = str(activeParkingBooking.get("id", ""));
        loading = True;
        mRes = await mark_parked(booking_id=bId);
        if mRes.get("ok", False) {
            mData: dict[str, any] = dict(mRes.get("data", {}));
            activeParkingBooking = dict(mData.get("booking", {}));
            toastMsg = "Vehicle successfully parked! Bay status: OCCUPIED";
        }
        loading = False;
    }

    async def handle_release_slot {
        bId = str(activeParkingBooking.get("id", ""));
        loading = True;
        rRes = await release_slot(booking_id=bId);
        if rRes.get("ok", False) {
            toastMsg = "Slot released. Thank you for using Park & Ride!";
            step = 1;
        }
        loading = False;
    }

    # Mode 2 Handlers (Bus Journey & Scans)
    def handle_open_bus_booking(busItem: dict[str, any]) {
        selectedBus = busItem;
        showBookingModal = True;
    }

    async def handle_confirm_seat_booking(busId: str, pickupCode: str, dropCode: str) {
        loading = True;
        showBookingModal = False;
        sRes = await book_seat(bus_id=busId, pickup=pickupCode, drop=dropCode);
        if sRes.get("ok", False) {
            hasActiveTrip = True;
            await refresh_trip();
            toastMsg = f"Seat reserved on {busId}! Boarding at {pickupCode}.";
        } else {
            err: dict[str, any] = dict(sRes.get("error", {}));
            toastMsg = str(err.get("message", "Seat booking failed"));
        }
        loading = False;
    }

    async def handle_process_scan(scanId: str, qrToken: str, dropCode: str) -> dict[str, any] {
        pRes = await process_scan(scan_id=scanId, qr=qrToken, drop=dropCode);
        if pRes.get("ok", False) {
            pData: dict[str, any] = dict(pRes.get("data", {}));
            resCode = str(pData.get("result", ""));
            if resCode == "boarded" {
                toastMsg = "Confirmed, you are on board!";
            } elif resCode == "alighted" {
                toastMsg = "Alighted successfully! Journey completed.";
            } elif resCode == "duplicate" {
                toastMsg = "Already counted (duplicate scan ignored).";
            }
            await refresh_trip();
            return pData;
        }
        err: dict[str, any] = dict(pRes.get("error", {}));
        toastMsg = str(err.get("message", "Scan rejected"));
        return {"result": "rejected", "message": toastMsg};
    }

    user = current_user();
    userName = user["username"] if user else "guest";

    # Filtered bus list
    filteredBuses = [b for b in buses if selectedRoute == "ALL" or str(b.get("route", "")) == selectedRoute];
    selBusId = str(selectedBus.get("id", ""));

    return <div className="min-h-screen bg-[#0B1220] text-white flex flex-col font-sans selection:bg-[#FFC21A] selection:text-[#0F1B2D]">
        <LandingModal
            isOpen={showLandingModal}
            onSelectParkAndRide={handle_select_park_and_ride}
            onSelectGetIntoBus={handle_select_get_into_bus}
            onClose={lambda { showLandingModal = False; }}
        />

        <SeatBookingModal
            bus={selectedBus}
            isOpen={showBookingModal}
            initialPickup={selectedTerminal}
            onClose={lambda { showBookingModal = False; }}
            onConfirmBooking={handle_confirm_seat_booking}
        />

        <QRScannerModal
            isOpen={showScannerModal}
            onClose={lambda { showScannerModal = False; }}
            onProcessScan={handle_process_scan}
        />

        <header className="sticky top-0 z-40 bg-[#0F1B2D]/90 border-b border-white/10 backdrop-blur-xl px-4 py-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3">
                <button
                    type="button"
                    onClick={lambda (_e: MouseEvent) { showLandingModal = True; }}
                    className="w-9 h-9 rounded-xl bg-[#FFC21A] text-[#0F1B2D] font-black text-sm flex items-center justify-center shadow-lg shadow-[#FFC21A]/20 cursor-pointer"
                >
                    PR
                </button>
                <div>
                    <div className="flex items-center gap-2">
                        <span className="font-extrabold text-sm sm:text-base text-white">Park &amp; Ride Sri Lanka</span>
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#FFC21A]/20 text-[#FFC21A]">
                            {("Park & Ride" if appMode == "park_and_ride" else "Bus Journey")}
                        </span>
                    </div>
                    <span className="text-[11px] text-gray-400">Colombo Metro Transit · Live Polling</span>
                </div>
            </div>

            <div className="flex items-center gap-3">
                <button
                    type="button"
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

        <main className="flex-1 w-full max-w-4xl mx-auto p-4 sm:p-6 flex flex-col gap-6">
            {if appMode == "park_and_ride" {
                <div className="flex flex-col gap-6 max-w-xl mx-auto w-full">
                    <div className="flex items-center justify-between p-3 rounded-2xl bg-white/[0.03] border border-white/10 text-xs">
                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { step = 1; }}
                            className={f"flex items-center gap-1.5 font-bold {'text-[#FFC21A]' if step == 1 else 'text-gray-400'}"}
                        >
                            <span className={f"w-5 h-5 rounded-full flex items-center justify-center text-[10px] {'bg-[#FFC21A] text-[#0F1B2D]' if step == 1 else 'bg-white/10'}"}>1</span>
                            <span>Vehicle</span>
                        </button>
                        <span className="text-gray-600">&rarr;</span>
                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { if step > 2 { step = 2; } }}
                            className={f"flex items-center gap-1.5 font-bold {'text-[#FFC21A]' if step == 2 else 'text-gray-400'}"}
                        >
                            <span className={f"w-5 h-5 rounded-full flex items-center justify-center text-[10px] {'bg-[#FFC21A] text-[#0F1B2D]' if step == 2 else 'bg-white/10'}"}>2</span>
                            <span>Slot Grid</span>
                        </button>
                        <span className="text-gray-600">&rarr;</span>
                        <div className={f"flex items-center gap-1.5 font-bold {'text-[#FFC21A]' if step == 3 else 'text-gray-500'}"}>
                            <span className={f"w-5 h-5 rounded-full flex items-center justify-center text-[10px] {'bg-[#FFC21A] text-[#0F1B2D]' if step == 3 else 'bg-white/10'}"}>3</span>
                            <span>Gate Pass</span>
                        </div>
                    </div>

                    {if step == 1 {
                        <div className="flex flex-col gap-6">
                            <TerminalPicker
                                terminals={terminals}
                                selectedTerminal={selectedTerminal}
                                selectedVehicle={selectedVehicle}
                                onSelect={lambda (code: str) { selectedTerminal = code; }}
                            />

                            <VehicleFilter
                                selectedVehicle={selectedVehicle}
                                evChoice={evChoice}
                                accessible={accessible}
                                arrival={arrival}
                                returnBy={returnBy}
                                onChangeVehicle={lambda (t: str) { selectedVehicle = t; }}
                                onChangeEv={lambda (e: str) { evChoice = e; }}
                                onToggleAccessible={lambda (a: bool) { accessible = a; }}
                                onChangeArrival={lambda (t: str) { arrival = t; }}
                                onChangeReturnBy={lambda (t: str) { returnBy = t; }}
                            />

                            <Button
                                label="Find Best Slots & Continue →"
                                fullWidth={True}
                                disabled={loading}
                                onClick={lambda { handle_confirm_slot_step(); }}
                            />
                        </div>;
                    }}

                    {if step == 2 {
                        <div className="flex flex-col gap-6">
                            <SlotRecommendation
                                recommendation={recommendation}
                                selectedSlotCode={selectedSlotCode}
                                onSelectSlot={lambda (code: str) { selectedSlotCode = code; }}
                            />

                            <SlotGrid
                                slots={[s for s in terminalSlots if str(s.get("type", "")) == ("E" if selectedVehicle == "C" and evChoice == "needs_charging" else selectedVehicle)]}
                                selectedSlotCode={selectedSlotCode}
                                recommendedSlotCode={str(dict(recommendation.get("options", [{}])[0].get("slot", {})).get("code", ""))}
                                onSelectSlot={lambda (code: str) { selectedSlotCode = code; }}
                            />

                            <div className="flex items-center gap-3">
                                <button
                                    type="button"
                                    onClick={lambda (_e: MouseEvent) { step = 1; }}
                                    className="w-1/3 py-3 px-4 rounded-xl border border-white/20 text-xs font-bold text-gray-300 hover:text-white hover:bg-white/10 transition-colors"
                                >
                                    ← Back
                                </button>
                                <div className="w-2/3">
                                    <Button
                                        label={f"Book Slot {selectedSlotCode} →"}
                                        fullWidth={True}
                                        disabled={loading or len(selectedSlotCode) == 0}
                                        onClick={lambda { handle_book_slot(); }}
                                    />
                                </div>
                            </div>
                        </div>;
                    }}

                    {if step == 3 {
                        <div className="flex flex-col gap-6">
                            <ParkingPass
                                booking={activeParkingBooking}
                                onMarkParked={handle_mark_parked}
                                onReleaseSlot={handle_release_slot}
                                onProceedToBus={lambda { appMode = "get_into_bus"; }}
                            />
                        </div>;
                    }}
                </div>;
            }}

            {if appMode == "get_into_bus" {
                <div className="flex flex-col gap-6">
                    <div className="flex items-center justify-between p-3.5 rounded-2xl bg-[#0F1B2D] border border-white/10 text-xs">
                        <div className="flex items-center gap-2.5">
                            <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse" />
                            <span className="font-extrabold text-white">Colombo Metro Live Fleet</span>
                            <span className="text-gray-400 text-[11px]">(Polling every 2s)</span>
                        </div>
                        <button
                            type="button"
                            onClick={lambda (_e: MouseEvent) { appMode = "park_and_ride"; step = 1; }}
                            className="text-gray-400 hover:text-[#FFC21A] font-bold text-[11px] transition-colors"
                        >
                            &larr; Return to Parking
                        </button>
                    </div>

                    {if hasActiveTrip and len(activeTripData) > 0 {
                        <TripView
                            tripData={activeTripData}
                            onOpenScanner={lambda { showScannerModal = True; }}
                            onFinishTrip={lambda { hasActiveTrip = False; }}
                        />;
                    } else {
                        # Main Bus Tracking & Map View
                        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                            <div className="lg:col-span-7 flex flex-col gap-3">
                                <CityMap
                                    mapData={mapData}
                                    buses={buses}
                                    selectedBusId={selBusId}
                                    onBusClick={handle_open_bus_booking}
                                    className="h-[460px] sm:h-[540px]"
                                />
                            </div>

                            <div className="lg:col-span-5 flex flex-col gap-4">
                                <div className="grid grid-cols-4 gap-1.5 p-1.5 rounded-2xl bg-[#0F1B2D] border border-white/10 text-xs">
                                    <button
                                        type="button"
                                        onClick={lambda (_e: MouseEvent) { selectedRoute = "ALL"; }}
                                        className={f"py-2 rounded-xl font-bold transition-all {'bg-[#FFC21A] text-[#0F1B2D] shadow' if selectedRoute == 'ALL' else 'text-gray-400 hover:text-white'}"}
                                    >
                                        All
                                    </button>
                                    <button
                                        type="button"
                                        onClick={lambda (_e: MouseEvent) { selectedRoute = "R1"; }}
                                        className={f"py-2 rounded-xl font-bold transition-all {'bg-[#3B82F6] text-white shadow' if selectedRoute == 'R1' else 'text-gray-400 hover:text-white'}"}
                                    >
                                        R1
                                    </button>
                                    <button
                                        type="button"
                                        onClick={lambda (_e: MouseEvent) { selectedRoute = "R2"; }}
                                        className={f"py-2 rounded-xl font-bold transition-all {'bg-[#A855F7] text-white shadow' if selectedRoute == 'R2' else 'text-gray-400 hover:text-white'}"}
                                    >
                                        R2
                                    </button>
                                    <button
                                        type="button"
                                        onClick={lambda (_e: MouseEvent) { selectedRoute = "R3"; }}
                                        className={f"py-2 rounded-xl font-bold transition-all {'bg-[#14B8A6] text-white shadow' if selectedRoute == 'R3' else 'text-gray-400 hover:text-white'}"}
                                    >
                                        R3
                                    </button>
                                </div>

                                <div className="space-y-3 max-h-[460px] overflow-y-auto pr-1">
                                    {for b in filteredBuses {
                                        bid = str(b.get("id", ""));
                                        isSel = (bid == selBusId);
                                        <BusCard
                                            key={bid}
                                            bus={b}
                                            isSelected={isSel}
                                            onSelect={handle_open_bus_booking}
                                        />;
                                    }}
                                </div>

                                <button
                                    type="button"
                                    onClick={lambda (_e: MouseEvent) { showScannerModal = True; }}
                                    className="w-full py-3 px-4 rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 font-bold text-xs text-gray-300 flex items-center justify-center gap-2 transition-colors"
                                >
                                    <span>📷</span>
                                    <span>Scan Stop QR at Station</span>
                                </button>
                            </div>
                        </div>;
                    }}
                </div>;
            }}
        </main>

        {if toastMsg {
            <div className="fixed bottom-6 right-6 z-50">
                <Toast
                    message={toastMsg}
                    type="success"
                    onClose={lambda { toastMsg = ""; }}
                />
            </div>;
        }}

        <footer className="mt-auto border-t border-white/10 bg-[#0F1B2D]/50 p-4 text-center text-xs text-gray-500">
            <span>Park &amp; Ride Sri Lanka · Jac 0.37 Full-stack System</span>
        </footer>
    </div>;
}
