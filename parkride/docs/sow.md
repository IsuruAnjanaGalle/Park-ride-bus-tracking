# Statement of Work (SOW): ParkRide Multimodal Transit System

## 1. Executive Summary

**Project Name:** ParkRide (Smart Multimodal Parking & Bus Tracking System)  
**Target Domain:** Colombo Metropolitan Area & Western Province Transit Corridors, Sri Lanka  
**Core Technologies:** Jaclang (Object-Spatial Programming, Graph Architecture, Walkers), TypeScript, Three.js  

The **ParkRide** platform addresses traffic gridlock across major Colombo arterial corridors (High Level Road A4, Baseline Road, Galle Road, and Expressway networks) by providing an integrated, frictionless Park-and-Ride (P&R) multimodal transit experience. Commuters drive private vehicles (electric, standard, motorcycle) to multimodal hubs (e.g., Makumbura MMC, Kadawatha Hub, Katunayake Airport Hub), park in pre-allocated slots, scan tamper-proof cryptographic QR tokens at automated barriers, and transition directly onto express transit shuttles into central Colombo.

---

## 2. Problem Statement & Objectives

### 2.1 Problems Addressed
- **Arterial Congestion:** Over 250,000 private vehicles enter Colombo daily, causing severe bottlenecks and high fuel waste.
- **First-Mile/Last-Mile Friction:** Commuters hesitate to use express transit hubs due to unpredictable parking availability and manual ticketing queues.
- **Fragmented Information:** Lack of live bus telemetry integrated with parking occupancy and dynamic arrival forecasts.
- **Language Barriers:** Inability of existing systems to provide seamless trilingual accessibility (English, Sinhala, Tamil).

### 2.2 Core Objectives
1. **Zero-Friction Park & Ride:** Enable end-to-end reservation, slot allocation, and barrier validation under 30 seconds.
2. **Deterministic Graph Routing:** Implement Dijkstra shortest-path calculations factoring real-time road congestion and expressway links.
3. **Cryptographic Security:** Provide HMAC-SHA256 authenticated QR gate passes immune to spoofing and unauthorized duplication.
4. **Predictive Operations:** Offer machine-modeled occupancy forecasts and arrival estimates across peak commute hours.

---

## 3. System Architecture & Topology

### 3.1 Object-Spatial Architecture in Jac
The core graph is structured around nodes and edges:
- **`SystemHub`**: Root topology anchor managing system-wide metadata and health feeds.
- **`TerminalNode`**: Multimodal transit hubs (Makumbura MMC, Kadawatha, Katunayake).
- **`StopNode`**: City and corridor transit stops (Pettah/Fort, Borella, Town Hall, Maharagama, etc.).
- **`ParkingSlotNode`**: Individual parking bays categorized by type (`standard`, `ev`, `handicap`, `motorcycle`).
- **`BusNode`**: Public transit and expressway fleet vehicles with live coordinates and occupancy.
- **`BookingNode`**: Multimodal combo reservations with digital lifecycle status.
- **`RoadEdge`**: Weighted transit links containing distance (km), baseline travel time, and real-time congestion factors.
- **`TerminalSlotEdge`**: Walking distance connection from terminal building to parking bays.

### 3.2 Walkers Hierarchy
- **`parking.jac`**: Inspects terminal bays, evaluates availability, allocates nearest slots.
- **`booking.jac`**: Issues reservations, assigns slots, mints cryptographic QR tokens.
- **`scans.jac`**: Validates QR entry/exit scans, triggers automated barrier controls, transitions states.
- **`routing.jac`**: Calculates optimal transit paths using Dijkstra algorithm.
- **`traffic.jac`**: Ingests real-time congestion updates and re-weights road edges.
- **`buses.jac`**: Updates fleet positions, calculates ETAs, tracks occupancy.
- **`admin.jac`**: Provides aggregated telemetry and manual slot overrides.
- **`demo.jac`**: Executes complete automated simulation walkthroughs.

---

## 4. User Personas & Requirements

| Persona | Needs & Goals | Core System Interaction |
|---|---|---|
| **Commuter** | Fast booking, guaranteed EV/handicap slot, live bus arrival time, single QR pass for gate & bus. | `find_available_slot`, `create_booking`, `find_multimodal_route` |
| **Gate / Barrier Operator** | Sub-second offline QR scan validation, automated barrier lift, duplicate entry rejection. | `scan_gate_entry`, `scan_gate_exit` |
| **Bus Driver / Dispatcher** | Telemetry ingestion, route delay reporting, passenger occupancy broadcast. | `update_bus_position`, `track_bus` |
| **System Admin** | Real-time terminal utilization, fleet efficiency, revenue tracking, maintenance overrides. | `get_system_overview`, `override_slot_status` |

---

## 5. Security & Verification Contract

- **Token Signing:** HMAC-SHA256 signature using 256-bit server secret key.
- **Tamper Resistance:** Payload Base64 URL-safe encoding paired with deterministic message digest.
- **Expiration Enforcement:** Cryptographic epoch check with strict gate rejection for expired passes.
- **Single-Use Gate Transition:** Slot and booking states transition atomically (`RESERVED` -> `CHECKED_IN` -> `COMPLETED`).

---

## 6. Deliverables & Scope

1. **Jac Core Graph & Scaffolding:** Validated models, edges, walkers, and libraries.
2. **Seed Data:** Western Province stops, road network, bus fleet, and parking slots.
3. **Glue Modules:** Three.js 3D visualization loop and HTML5 camera QR scanner integration.
4. **Trilingual Localization:** Complete English (`en`), Sinhala (`si`), and Tamil (`ta`) translations.
5. **Quality Assurance:** 100% type-checked Jac code with comprehensive unit and regression tests.
6. **Documentation:** SOW, Walker interface contracts, Jac syntax references, and demonstration script.
