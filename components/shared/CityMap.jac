"""Interactive SVG CityMap component for Colombo Bus Tracking (Milestone 2).

Renders road network from get_map with congestion levels, stops, terminals,
and live buses moving and rotating with heading from get_buses.
Shared across Passenger App (Dev B) and Admin/Driver views (Dev C).
"""

import from "react" { useState, useEffect }

def:pub CityMap(
    mapData: dict,
    buses: list[dict] = [],
    selectedBusId: str = "",
    highlightBusId: str = "",
    onBusClick: any = None,
    onStopClick: any = None,
    className: str = ""
) -> JsxElement {
    has hoveredBus: dict = {};
    has hoveredStop: dict = {};

    # Extract bounds with safe defaults
    rawBounds = dict(mapData.get("bounds", {}));
    minLat = float(rawBounds.get("min_lat", 6.796));
    maxLat = float(rawBounds.get("max_lat", 7.001));
    minLng = float(rawBounds.get("min_lng", 79.8495));
    maxLng = float(rawBounds.get("max_lng", 79.989));

    # Dimensions and padding for viewBox
    vbW = 900.0;
    vbH = 750.0;
    pad = 55.0;

    dLat = maxLat - minLat if maxLat > minLat else 0.205;
    dLng = maxLng - minLng if maxLng > minLng else 0.1395;

    # Project GPS coordinates to SVG coordinate system
    def to_svg_x(lng: float) -> float {
        ratio = (lng - minLng) / dLng;
        return pad + ratio * (vbW - 2.0 * pad);
    }

    def to_svg_y(lat: float) -> float {
        ratio = (maxLat - lat) / dLat;
        return pad + ratio * (vbH - 2.0 * pad);
    }

    # Build junction coordinate lookup dictionary
    rawJuncs = list(mapData.get("junctions", []));
    juncLookup: dict[str, dict] = {};
    for j in rawJuncs {
        jDict = dict(j);
        code = str(jDict.get("code", ""));
        if len(code) > 0 {
            juncLookup[code] = jDict;
        }
    }

    rawRoads = list(mapData.get("roads", []));

    # Helper for road level stroke color and style
    def road_color(level: int) -> str {
        if level == 1 {
            return "#F59E0B";  # Slow / Amber
        } elif level == 2 {
            return "#EF4444";  # Jammed / Red
        } elif level == 3 {
            return "#991B1B";  # Closed / Dark Red
        }
        return "#334155";      # Normal / Slate
    }

    def road_width(level: int, cls: str) -> str {
        if level == 2 or level == 3 {
            return "5";
        } elif level == 1 {
            return "4";
        } elif cls == "E" {
            return "4.5";
        }
        return "3";
    }

    # Helper for route badge color
    def route_color(c: str) -> str {
        if c == "violet" or c == "purple" {
            return "#A855F7";
        } elif c == "teal" {
            return "#14B8A6";
        }
        return "#3B82F6";  # Default blue
    }

    return (
        <div className={f"relative w-full h-full bg-[#0B1220] rounded-3xl overflow-hidden border border-white/10 shadow-2xl select-none {className}"}>
            {/* Map Top Bar Controls & Legend */}
            <div className="absolute top-4 left-4 z-10 flex flex-wrap items-center gap-2 pointer-events-none">
                <div className="px-3 py-1.5 rounded-full bg-[#0F1B2D]/90 backdrop-blur-md border border-white/10 text-[11px] font-bold text-white flex items-center gap-2 shadow-lg">
                    <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                    <span>Live Metro Network (Colombo)</span>
                </div>
                <div className="px-2.5 py-1.5 rounded-full bg-[#0F1B2D]/80 backdrop-blur-md border border-white/5 text-[10px] text-gray-300 flex items-center gap-2 shadow-sm">
                    <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-[#3B82F6]" /> R1</span>
                    <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-[#A855F7]" /> R2</span>
                    <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-[#14B8A6]" /> R3</span>
                </div>
            </div>

            {/* Traffic Status Legend */}
            <div className="absolute top-4 right-4 z-10 flex items-center gap-2 pointer-events-none">
                <div className="px-2.5 py-1.5 rounded-full bg-[#0F1B2D]/80 backdrop-blur-md border border-white/5 text-[10px] text-gray-300 flex items-center gap-2 shadow-sm">
                    <span className="flex items-center gap-1"><span className="w-2.5 h-1 bg-[#334155] rounded-full" /> Free</span>
                    <span className="flex items-center gap-1"><span className="w-2.5 h-1 bg-[#F59E0B] rounded-full" /> Slow</span>
                    <span className="flex items-center gap-1"><span className="w-2.5 h-1 bg-[#EF4444] rounded-full" /> Jam</span>
                </div>
            </div>

            {/* SVG Canvas */}
            <svg
                viewBox={`0 0 ${vbW} ${vbH}`}
                className="w-full h-full min-h-[440px]"
                style={{"backgroundColor": "#090F1B"}}
            >
                <defs>
                    {/* SVG Filters & Glows */}
                    <filter id="glow-bus" x="-50%" y="-50%" width="200%" height="200%">
                        <feGaussianBlur stdDeviation="3" result="blur" />
                        <feComposite in="SourceGraphic" in2="blur" operator="over" />
                    </filter>
                    <filter id="glow-terminal" x="-50%" y="-50%" width="200%" height="200%">
                        <feGaussianBlur stdDeviation="4" result="blur" />
                        <feComposite in="SourceGraphic" in2="blur" operator="over" />
                    </filter>
                    {/* Road patterns */}
                    <pattern id="grid-pattern" width="40" height="40" patternUnits="userSpaceOnUse">
                        <path d="M 40 0 L 0 0 0 40" fill="none" stroke="rgba(255,255,255,0.02)" strokeWidth="1" />
                    </pattern>
                </defs>

                {/* Background Grid */}
                <rect width={vbW} height={vbH} fill="url(#grid-pattern)" />

                {/* 1. Road Segments */}
                <g id="roads" className="transition-all duration-500">
                    {rawRoads.map(lambda (r: any) {
                        rDict = dict(r);
                        aCode = str(rDict.get("a", ""));
                        bCode = str(rDict.get("b", ""));
                        level = int(rDict.get("level", 0));
                        cls = str(rDict.get("cls", "A"));

                        aJunc = dict(juncLookup.get(aCode, {}));
                        bJunc = dict(juncLookup.get(bCode, {}));

                        if len(aJunc) == 0 or len(bJunc) == 0 {
                            return None;
                        }

                        x1 = to_svg_x(float(aJunc.get("lng", 0.0)));
                        y1 = to_svg_y(float(aJunc.get("lat", 0.0)));
                        x2 = to_svg_x(float(bJunc.get("lng", 0.0)));
                        y2 = to_svg_y(float(bJunc.get("lat", 0.0)));

                        strokeColor = road_color(level);
                        strokeW = road_width(level, cls);
                        isDashed = (level == 3);

                        return (
                            <line
                                key={f"road-{aCode}-{bCode}"}
                                x1={x1}
                                y1={y1}
                                x2={x2}
                                y2={y2}
                                stroke={strokeColor}
                                strokeWidth={strokeW}
                                strokeLinecap="round"
                                strokeDasharray={"6,4" if isDashed else "none"}
                                opacity={0.4 if level == 3 else 0.85}
                            />
                        );
                    })}
                </g>

                {/* 2. Junctions, Stops & Terminals */}
                <g id="junctions">
                    {rawJuncs.map(lambda (j: any) {
                        jDict = dict(j);
                        code = str(jDict.get("code", ""));
                        name = str(jDict.get("name", ""));
                        kind = str(jDict.get("kind", "junction"));
                        lat = float(jDict.get("lat", 0.0));
                        lng = float(jDict.get("lng", 0.0));

                        cx = to_svg_x(lng);
                        cy = to_svg_y(lat);

                        if kind == "terminal" {
                            return (
                                <g
                                    key={f"junc-{code}"}
                                    transform={f"translate({cx}, {cy})"}
                                    className="cursor-pointer group"
                                    onClick={lambda { if onStopClick { onStopClick(jDict); } }}
                                >
                                    {/* Terminal Diamond Outer Ring */}
                                    <circle r="14" fill="#FFC21A" fillOpacity="0.15" filter="url(#glow-terminal)" className="animate-pulse" />
                                    <rect
                                        x="-8"
                                        y="-8"
                                        width="16"
                                        height="16"
                                        rx="3"
                                        transform="rotate(45)"
                                        fill="#0F1B2D"
                                        stroke="#FFC21A"
                                        strokeWidth="2.5"
                                    />
                                    <circle r="3" fill="#FFC21A" />
                                    {/* Terminal Label */}
                                    <text
                                        y="22"
                                        textAnchor="middle"
                                        fill="#FFC21A"
                                        fontSize="10"
                                        fontWeight="900"
                                        fontFamily="monospace"
                                        className="drop-shadow-md select-none"
                                    >
                                        {code}
                                    </text>
                                    <text
                                        y="32"
                                        textAnchor="middle"
                                        fill="#94A3B8"
                                        fontSize="8"
                                        fontWeight="600"
                                        className="drop-shadow-sm select-none"
                                    >
                                        {name}
                                    </text>
                                </g>
                            );
                        } elif kind == "stop" {
                            return (
                                <g
                                    key={f"junc-{code}"}
                                    transform={f"translate({cx}, {cy})"}
                                    className="cursor-pointer group"
                                    onClick={lambda { if onStopClick { onStopClick(jDict); } }}
                                >
                                    <circle r="6" fill="#0F1B2D" stroke="#22D3EE" strokeWidth="2" />
                                    <circle r="2" fill="#22D3EE" />
                                    <text
                                        y="-10"
                                        textAnchor="middle"
                                        fill="#E2E8F0"
                                        fontSize="8"
                                        fontWeight="600"
                                        className="select-none opacity-80 group-hover:opacity-100 group-hover:scale-110 transition-all"
                                    >
                                        {name}
                                    </text>
                                </g>
                            );
                        } else {
                            # Junction
                            return (
                                <circle
                                    key={f"junc-{code}"}
                                    cx={cx}
                                    cy={cy}
                                    r="2.5"
                                    fill="#475569"
                                    opacity="0.6"
                                />
                            );
                        }
                    })}
                </g>

                {/* 3. Live Buses */}
                <g id="buses">
                    {buses.map(lambda (b: any) {
                        bDict = dict(b);
                        bid = str(bDict.get("id", ""));
                        route = str(bDict.get("route", "R1"));
                        bColor = str(bDict.get("color", "blue"));
                        lat = float(bDict.get("lat", 0.0));
                        lng = float(bDict.get("lng", 0.0));
                        heading = float(bDict.get("heading", 0.0));
                        seatsLeft = int(bDict.get("seats_left", 40));
                        nextStopDict = dict(bDict.get("next_stop", {}));
                        nextStopName = str(nextStopDict.get("name", ""));

                        bx = to_svg_x(lng);
                        by = to_svg_y(lat);

                        isSelected = (bid == selectedBusId);
                        isHighlighted = (bid == highlightBusId);
                        hexColor = route_color(bColor);

                        return (
                            <g
                                key={f"bus-{bid}"}
                                transform={f"translate({bx}, {by})"}
                                className="cursor-pointer transition-transform duration-700 ease-out"
                                onClick={lambda { if onBusClick { onBusClick(bDict); } }}
                            >
                                {/* Active Pulse Ring */}
                                {isSelected or isHighlighted ? (
                                    <g>
                                        <circle r="22" fill="none" stroke="#FFC21A" strokeWidth="2" opacity="0.8" className="animate-ping" />
                                        <circle r="16" fill="#FFC21A" fillOpacity="0.2" />
                                    </g>
                                ) : None}

                                {/* Rotated Bus Vehicle Icon */}
                                <g transform={f"rotate({heading})"}>
                                    {/* Shadow */}
                                    <rect
                                        x="-8"
                                        y="-13"
                                        width="16"
                                        height="26"
                                        rx="5"
                                        fill="#000000"
                                        fillOpacity="0.4"
                                        transform="translate(1, 2)"
                                    />
                                    {/* Bus Body */}
                                    <rect
                                        x="-8"
                                        y="-13"
                                        width="16"
                                        height="26"
                                        rx="5"
                                        fill={hexColor}
                                        stroke={isSelected ? "#FFC21A" : "#FFFFFF"}
                                        strokeWidth={isSelected ? "2.5" : "1.2"}
                                        filter="url(#glow-bus)"
                                    />
                                    {/* Windshield (Front orientation indicator) */}
                                    <rect
                                        x="-6"
                                        y="-11"
                                        width="12"
                                        height="5"
                                        rx="2"
                                        fill="#0F1B2D"
                                        fillOpacity="0.85"
                                    />
                                    {/* Headlights */}
                                    <circle cx="-5" cy="-12" r="1.5" fill="#FEF08A" />
                                    <circle cx="5" cy="-12" r="1.5" fill="#FEF08A" />
                                    {/* Rear lights */}
                                    <circle cx="-5" cy="11.5" r="1.2" fill="#EF4444" />
                                    <circle cx="5" cy="11.5" r="1.2" fill="#EF4444" />
                                </g>

                                {/* Fixed Orientation Floating Badge */}
                                <g transform="translate(0, -20)">
                                    <rect
                                        x="-26"
                                        y="-8"
                                        width="52"
                                        height="16"
                                        rx="8"
                                        fill="#0F1B2D"
                                        stroke={isSelected ? "#FFC21A" : hexColor}
                                        strokeWidth="1.5"
                                    />
                                    <text
                                        x="0"
                                        y="3.5"
                                        textAnchor="middle"
                                        fill="#FFFFFF"
                                        fontSize="8"
                                        fontWeight="800"
                                        fontFamily="monospace"
                                    >
                                        {bid} · {seatsLeft}s
                                    </text>
                                </g>
                            </g>
                        );
                    })}
                </g>
            </svg>

            {/* Bottom Status Ticker */}
            <div className="absolute bottom-3 left-4 right-4 z-10 flex items-center justify-between text-[11px] text-gray-400 bg-[#0F1B2D]/80 backdrop-blur-md px-3.5 py-2 rounded-2xl border border-white/5 pointer-events-none">
                <span>{buses.length} Metro Buses in Fleet</span>
                <span className="text-[10px] text-gray-500">Tap bus to view ETA & book seats</span>
            </div>
        </div>
    );
}
