"""UI Kit Preview Page for Park & Ride Sri Lanka.

Interactive showcase displaying all 17 shared UI components across
mobile (390px), tablet (768px), and desktop viewports.
"""

import from components.shared.ui.Button { Button }
import from components.shared.ui.IconButton { IconButton }
import from components.shared.ui.GlassCard { GlassCard }
import from components.shared.ui.Modal3D { Modal3D }
import from components.shared.ui.Tilt { Tilt }
import from components.shared.ui.BottomSheet { BottomSheet }
import from components.shared.ui.Chip { Chip }
import from components.shared.ui.StatTile { StatTile }
import from components.shared.ui.Skeleton { Skeleton }
import from components.shared.ui.EmptyState { EmptyState }
import from components.shared.ui.ErrorState { ErrorState }
import from components.shared.ui.Toast { Toast }
import from components.shared.ui.SegmentedControl { SegmentedControl }
import from components.shared.ui.QRPanel { QRPanel }
import from components.shared.ui.WallBackground { WallBackground }
import from components.shared.ui.WallBackground3D { WallBackground3D }
import from components.shared.ui.useWalker { WalkerLoader }

def:pub UiPreviewPage -> JsxElement {
    has isModalOpen: bool = False,
        isSheetOpen: bool = False,
        isToastOpen: bool = True,
        selectedTerminal: str = "stop_makumbura",
        selectedVehicle: str = "car",
        activeViewport: str = "responsive";

    terminalOptions = [
        {"key": "stop_makumbura", "label": "Makumbura (MMC)", "badge": "42 free"},
        {"key": "stop_kadawatha", "label": "Kadawatha", "badge": "28 free"},
        {"key": "stop_kesbewa", "label": "Kesbewa", "badge": "19 free"},
        {"key": "stop_pettah", "label": "Pettah Fort", "badge": "8 free"}
    ];

    vehicleOptions = [
        {"key": "car", "label": "Car / EV", "icon": "🚗"},
        {"key": "motorcycle", "label": "Motorcycle", "icon": "🏍️"},
        {"key": "bicycle", "label": "Foot Cycle", "icon": "🚲"}
    ];

    viewportClass = "w-full" if activeViewport == "responsive"
        else ("max-w-[390px] mx-auto border-x border-white/20 shadow-2xl bg-[#0B1220]/95" if activeViewport == "mobile"
        else ("max-w-[768px] mx-auto border-x border-white/20 shadow-2xl bg-[#0B1220]/95" if activeViewport == "tablet"
        else "max-w-[1440px] mx-auto"));

    modalFooter = <div className="flex gap-2">
        <Button label="Close" variant="ghost" onClick={lambda { isModalOpen = False; }}/>
        <Button label="Proceed to Bus Map" variant="primary" onClick={lambda { isModalOpen = False; }}/>
    </div>;

    modalContent = <div className="space-y-4">
        <p className="text-sm text-gray-300">
            Welcome to the multimodal transit terminal. Select your next step to guarantee seamless parking and bus boarding.
        </p>
        <div className="grid grid-cols-2 gap-3">
            <div className="p-3 rounded-xl bg-white/5 border border-white/10 text-center">
                <span className="text-2xl mb-1 block">🅿️</span>
                <span className="font-bold text-white text-xs block">Smart Bay</span>
                <span className="text-[10px] text-emerald-400">EV Fast Charging</span>
            </div>
            <div className="p-3 rounded-xl bg-white/5 border border-white/10 text-center">
                <span className="text-2xl mb-1 block">🚌</span>
                <span className="font-bold text-white text-xs block">Express Bus</span>
                <span className="text-[10px] text-blue-400">Route EX1-01</span>
            </div>
        </div>
    </div>;

    sheetContent = <div className="space-y-4">
        <div className="flex items-center justify-between p-3 rounded-2xl bg-white/5 border border-white/10">
            <div>
                <span className="text-xs text-gray-400 block font-mono">Bus Fleet #</span>
                <span className="text-base font-bold text-white">MB-101 (ND-8821)</span>
            </div>
            <Chip label="On Route" variant="success" pulse={True}/>
        </div>
        <div className="grid grid-cols-2 gap-2 text-xs">
            <div className="p-2.5 rounded-xl bg-white/5 border border-white/10">
                <span className="text-gray-400 block">Next Stop</span>
                <span className="font-bold text-white">Kottawa Junction</span>
            </div>
            <div className="p-2.5 rounded-xl bg-white/5 border border-white/10">
                <span className="text-gray-400 block">ETA</span>
                <span className="font-bold text-[#FFC21A]">4.5 mins</span>
            </div>
        </div>
        <Button label="Reserve Seat on this Bus" fullWidth={True} onClick={lambda { isSheetOpen = False; }}/>
    </div>;

    return <WallBackground3D enableParticles={True}>
        <header className="sticky top-0 z-40 bg-[#0B1220]/90 backdrop-blur-xl border-b border-white/10 px-4 py-3">
            <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                    <span className="w-9 h-9 rounded-xl bg-[#FFC21A] text-[#0F1B2D] flex items-center justify-center font-black text-lg shadow-md shadow-[#FFC21A]/30">
                        PR
                    </span>
                    <div>
                        <h1 className="text-base font-bold text-white tracking-tight leading-none">
                            Park & Ride Sri Lanka
                        </h1>
                        <span className="text-[11px] text-[#FFC21A] font-mono">
                            UI Kit & Design System (Dev B Preview)
                        </span>
                    </div>
                </div>

                <div className="flex items-center gap-1.5 bg-[#0F1B2D] p-1 rounded-xl border border-white/10">
                    <button
                        className={"px-2.5 py-1 text-xs font-semibold rounded-lg transition-colors " + ("bg-[#FFC21A] text-[#0F1B2D]" if activeViewport == "responsive" else "text-gray-400 hover:text-white")}
                        onClick={lambda { activeViewport = "responsive"; }}
                    >
                        Auto (100%)
                    </button>
                    <button
                        className={"px-2.5 py-1 text-xs font-semibold rounded-lg transition-colors " + ("bg-[#FFC21A] text-[#0F1B2D]" if activeViewport == "mobile" else "text-gray-400 hover:text-white")}
                        onClick={lambda { activeViewport = "mobile"; }}
                    >
                        390px (Mobile)
                    </button>
                    <button
                        className={"px-2.5 py-1 text-xs font-semibold rounded-lg transition-colors " + ("bg-[#FFC21A] text-[#0F1B2D]" if activeViewport == "tablet" else "text-gray-400 hover:text-white")}
                        onClick={lambda { activeViewport = "tablet"; }}
                    >
                        768px (Tablet)
                    </button>
                </div>
            </div>
        </header>

        <main className="flex-1 py-8 px-4 sm:px-6">
            <div className={viewportClass}>
                <div className="space-y-10">

                    <section className="space-y-4">
                        <div className="text-center sm:text-left">
                            <Chip label="Milestone 1 Preview" variant="ev" pulse={True}/>
                            <h2 className="text-2xl sm:text-3xl font-extrabold text-white mt-2 tracking-tight">
                                Transit Flow & Landing Choices
                            </h2>
                            <p className="text-sm text-gray-400 max-w-xl">
                                3D Perspective interactive cards designed for fast commuter onboard flow.
                            </p>
                        </div>

                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <Tilt onClick={lambda { isModalOpen = True; }}>
                                <GlassCard variant="glow" className="h-full p-6 text-left border-l-4 border-l-[#FFC21A]">
                                    <div className="w-12 h-12 rounded-2xl bg-[#FFC21A]/20 text-[#FFC21A] flex items-center justify-center text-2xl mb-4 shadow-md shadow-[#FFC21A]/10">
                                        🚗
                                    </div>
                                    <h3 className="text-xl font-bold text-white mb-1">Park & Ride</h3>
                                    <p className="text-xs text-gray-300 leading-relaxed mb-4">
                                        Reserve an EV or standard parking bay with automated QR barrier access, then transition to bus.
                                    </p>
                                    <span className="text-xs font-bold text-[#FFC21A] flex items-center">
                                        <span>Tap to Test Modal3D</span>
                                        <span className="ml-1">→</span>
                                    </span>
                                </GlassCard>
                            </Tilt>

                            <Tilt onClick={lambda { isSheetOpen = True; }}>
                                <GlassCard variant="accent" className="h-full p-6 text-left border-l-4 border-l-blue-500">
                                    <div className="w-12 h-12 rounded-2xl bg-blue-500/20 text-blue-400 flex items-center justify-center text-2xl mb-4 shadow-md shadow-blue-500/10">
                                        🚌
                                    </div>
                                    <h3 className="text-xl font-bold text-white mb-1">Get into Bus</h3>
                                    <p className="text-xs text-gray-300 leading-relaxed mb-4">
                                        Skip parking and jump straight into live Colombo expressway bus tracking and seat reservation.
                                    </p>
                                    <span className="text-xs font-bold text-blue-400 flex items-center">
                                        <span>Tap to Test BottomSheet</span>
                                        <span className="ml-1">→</span>
                                    </span>
                                </GlassCard>
                            </Tilt>
                        </div>
                    </section>

                    <section className="space-y-4">
                        <h3 className="text-lg font-bold text-white border-b border-white/10 pb-2">
                            Tactile Segmented Controls
                        </h3>
                        <div>
                            <span className="text-xs text-gray-400 mb-1.5 block font-semibold">Select Multimodal Terminal:</span>
                            <SegmentedControl
                                options={terminalOptions}
                                selectedKey={selectedTerminal}
                                onChange={lambda k: str { selectedTerminal = k; }}
                            />
                        </div>

                        <div>
                            <span className="text-xs text-gray-400 mb-1.5 block font-semibold">Vehicle Type Category:</span>
                            <SegmentedControl
                                options={vehicleOptions}
                                selectedKey={selectedVehicle}
                                onChange={lambda v: str { selectedVehicle = v; }}
                                size="sm"
                            />
                        </div>
                    </section>

                    <section className="space-y-4">
                        <h3 className="text-lg font-bold text-white border-b border-white/10 pb-2">
                            Telemetry Stat Tiles
                        </h3>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                            <StatTile
                                label="Free Bays"
                                value="42 / 50"
                                subtext="Makumbura MMC"
                                trend="84%"
                                trendPositive={True}
                                color="yellow"
                            />
                            <StatTile
                                label="Next Bus"
                                value="3.8 min"
                                subtext="Route EX1-01"
                                trend="On Time"
                                trendPositive={True}
                                color="green"
                            />
                            <StatTile
                                label="Bus Capacity"
                                value="32 / 54"
                                subtext="59.3% load"
                                trend="22 Left"
                                trendPositive={True}
                                color="blue"
                            />
                            <StatTile
                                label="EV Chargers"
                                value="3 Free"
                                subtext="50 kW DC Fast"
                                trend="Ready"
                                trendPositive={True}
                                color="purple"
                            />
                        </div>
                    </section>

                    <section className="space-y-4">
                        <h3 className="text-lg font-bold text-white border-b border-white/10 pb-2">
                            Buttons, Route Chips & Badges
                        </h3>
                        <div className="flex flex-wrap gap-2 items-center">
                            <Chip label="R1: Makumbura → Pettah" variant="r1"/>
                            <Chip label="R2: Makumbura → Kadawatha" variant="r2"/>
                            <Chip label="R3: Kesbewa → Pettah" variant="r3"/>
                            <Chip label="EV Charging" variant="ev" pulse={True}/>
                            <Chip label="Confirmed" variant="success"/>
                            <Chip label="Heavy Traffic" variant="danger"/>
                        </div>

                        <div className="flex flex-wrap gap-3 items-center pt-2">
                            <Button label="Primary Action (#FFC21A)" variant="primary" onClick={lambda { isToastOpen = True; }}/>
                            <Button label="Secondary Navy" variant="secondary"/>
                            <Button label="Translucent Glass" variant="glass"/>
                            <Button label="Ghost Action" variant="ghost"/>
                            <Button label="Danger Incident" variant="danger"/>
                            <IconButton icon={<span>🔍</span>} ariaLabel="Search transit network"/>
                            <IconButton icon={<span>🔔</span>} ariaLabel="Notifications" badge="3" variant="primary"/>
                        </div>
                    </section>

                    <section className="space-y-4">
                        <h3 className="text-lg font-bold text-white border-b border-white/10 pb-2">
                            Cryptographic HMAC QR Gate Pass
                        </h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 items-center">
                            <QRPanel
                                qrToken="eyJib29raW5nX2lkIjoiYmstOThmNDEyIiwic2xvdF9pZCI6InNsb3RfbW1jX2V2MDEifQ.7f8b9a2c3d4e5f6a1b2c3d4e5f6a7b8c"
                                slotCode="EV-01"
                                vehiclePlate="WP-CAB-4512"
                                terminalName="Makumbura Multimodal Transport Center (MMC)"
                                expiryText="Hold Window: 30 minutes until 10:15 AM"
                                verified={True}
                            />
                            <div className="space-y-3 text-sm text-gray-300 bg-[#0F1B2D]/60 p-5 rounded-3xl border border-white/10 backdrop-blur-md">
                                <h4 className="font-bold text-white text-base flex items-center gap-2">
                                    <span className="text-emerald-400">🛡️</span>
                                    <span>Gate Barrier Security Spec</span>
                                </h4>
                                <p className="text-xs text-gray-400 leading-relaxed">
                                    Conforms to Section 2.2 of contracts.md. Tokens are signed with HMAC-SHA256 to prevent pass forgery and screenshot duplication.
                                </p>
                                <ul className="text-xs space-y-1.5 list-disc pl-4 text-gray-300">
                                    <li>High contrast 56px SVG markers for 1-meter phone camera scanning</li>
                                    <li>Instant single-use state transition upon barrier lift</li>
                                    <li>Human-readable fallback signature for manual conductor check</li>
                                </ul>
                                <div className="pt-2">
                                    <Button
                                        label="Trigger Pass Verified Toast"
                                        variant="glass"
                                        fullWidth={True}
                                        onClick={lambda { isToastOpen = True; }}
                                    />
                                </div>
                            </div>
                        </div>
                    </section>

                    <section className="space-y-4">
                        <h3 className="text-lg font-bold text-white border-b border-white/10 pb-2">
                            Async States & Placeholders
                        </h3>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <GlassCard className="p-4 space-y-3">
                                <span className="text-xs font-semibold text-gray-400 block">Loading Skeletons</span>
                                <Skeleton variant="rect" height="40px"/>
                                <Skeleton variant="text" width="80%"/>
                                <Skeleton variant="text" width="60%"/>
                                <div className="flex gap-2 pt-2">
                                    <Skeleton variant="circle" width="36px" height="36px"/>
                                    <div className="flex-1 space-y-1.5">
                                        <Skeleton variant="text" height="14px"/>
                                        <Skeleton variant="text" width="50%" height="12px"/>
                                    </div>
                                </div>
                            </GlassCard>

                            <EmptyState
                                title="No Buses Approaching"
                                message="There are currently no active express shuttles on Route EX1-02."
                                actionLabel="View Other Routes"
                            />

                            <ErrorState
                                title="Telemetry Offline"
                                message="Failed to reach GPS bus tracker feed. Retrying connection in 2s."
                                retryLabel="Reconnect Now"
                            />
                        </div>
                    </section>

                </div>
            </div>
        </main>

        <Modal3D
            isOpen={isModalOpen}
            title="Park & Ride — Makumbura Hub"
            children={modalContent}
            footer={modalFooter}
            onClose={lambda { isModalOpen = False; }}
        />

        <BottomSheet
            isOpen={isSheetOpen}
            title="Bus MB-101 Telemetry & Reservation"
            children={sheetContent}
            onClose={lambda { isSheetOpen = False; }}
        />

        <Toast
            message="Parking bay EV-01 reserved successfully. QR pass active!"
            type="success"
            isVisible={isToastOpen}
            onClose={lambda { isToastOpen = False; }}
        />
    </WallBackground3D>;
}
