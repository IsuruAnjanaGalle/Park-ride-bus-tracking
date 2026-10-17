# Agent Operating Instructions: `parkride` Repository

This document defines the architectural context, operational boundaries, and development rules for AI coding agents operating within the `parkride` codebase.

---

## 1. System Mission & Architecture Overview

`parkride` is an Object-Spatial Programming (OSP) application written in **Jaclang** (modern Jac compiler) designed to eliminate traffic congestion into Colombo by integrating multimodal smart parking terminals with real-time express bus tracking.

### Core Architectural Axioms
1. **Graph-Centric Domain Modeling:** All physical entities (Terminals, Bus Stops, Parking Bays, Buses, Bookings) exist as typed **nodes** on the Jac graph. Spatial connections (Road networks, Pedestrian transfers, Booking associations) exist as typed **edges**.
2. **Behavior Encapsulation via Walkers:** Business processes (Booking, QR gate validation, Dijkstra route optimization, Bus telemetry tracking) are implemented as **walkers** that traverse graph relationships.
3. **Cryptographic Assurance:** All access control tokens and QR gate passes are authenticated with HMAC-SHA256 signatures to prevent forgery.
4. **Deterministic Simulation:** The simulated clock (`core/lib/clock.jac`) enables reproducible testing and peak-hour traffic forecasting without dependence on wall-clock time.

---

## 2. Strict Jaclang Coding Standards for Agents

When generating or editing Jac source files (`.jac`), agents must adhere to the following rules without exception:

### 2.1 Graph & Edge Declarations
- **Edge Endpoints are Mandatory:** Every edge declaration must specify its source and destination node types:
  ```jac
  edge RoadEdge: StopNode --> StopNode { ... }
  ```
  *(Bare `edge E {}` without endpoints triggers compiler error `E2086`).*
- **Single-Arrow Traversal Filter:** When filtering traversals by edge archetype, use single arrows:
  ```jac
  [here ->:RoadEdge:->]   # Correct
  [here -->:RoadEdge:-->] # FAILS compiler parse error
  ```
- **Typed Edge Connect Operator:** When attaching typed edges, wrap the constructor in `+>`:
  ```jac
  src +>:RoadEdge(distance_km=5.0):+> target;
  ```

### 2.2 Variables & Scope
- **Module-Level Globals Require `glob`:**
  ```jac
  glob DEFAULT_SECRET: str = "secret";  # Correct
  DEFAULT_SECRET = "secret";             # FAILS compiler error E0005
  ```
- **Generic Type Annotations Require Parameters:**
  ```jac
  items: list[str] = [];           # Correct
  data: dict[str, any] = {};       # Correct
  raw: dict = {};                  # FAILS compiler error E1036
  ```
- **Import Semicolon Rules:**
  - Plain module imports take semicolons: `import json;`
  - Brace imports do NOT take trailing semicolons: `import from core.models.nodes { StopNode }` *(trailing semicolon causes `E0030`).*

### 2.3 Walker Design
- Abilities must specify entry targets: `can run with Root entry { ... }`.
- In walker abilities: `self` is the walker instance, `here` is the currently visited node.
- Early exit: Use `disengage;` to halt traversal immediately.

---

## 3. Directory & Module Responsibilities

- **`main.jac`**: System boot, auto-seeding, and runtime entry points.
- **`core/models/`**: Node (`nodes.jac`) and edge (`edges.jac`) schemas.
- **`core/lib/`**: Deterministic algorithms (`dijkstra.jac`, `allocation.jac`, `forecast.jac`, `qr_sign.jac`, `clock.jac`).
- **`core/seed/`**: Seed graph walker (`seed.jac`) and JSON datasets (`stops.json`, `roads.json`, `buses.json`, `slots.json`).
- **`core/walkers/`**: Functional walkers (`parking.jac`, `booking.jac`, `scans.jac`, `routing.jac`, `traffic.jac`, `buses.jac`, `admin.jac`, `demo.jac`).
- **`tests/`**: Test suite (`test_core.jac`).
- **`glue/`**: TypeScript bridges for Three.js 3D rendering (`three_loop.ts`) and QR camera scanner (`qr_scanner.ts`).
- **`i18n/`**: Localization catalogs for English (`en.json`), Sinhala (`si.json`), and Tamil (`ta.json`).

---

## 4. Verification & Testing

Before completing any task, agents must verify code correctness:
```bash
# Type check all Jac files
jac check main.jac

# Run complete test suite
jac test tests/test_core.jac
```
