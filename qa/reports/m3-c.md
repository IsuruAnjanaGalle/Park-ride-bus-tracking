# M3 C QA Report: Live Traffic & Bus Movement + Driver View

**Date**: 2026-10-17  
**Author**: Dev C  
**Status**: **PASS**  
**Jac Share**: 90.4% (Threshold: ≥ 85%)

---

## 1. Scope & Implementation

- **`core/lib/routing.jac`**:
  - Full graph built from `docs/data/road-network.json` (static junctions and road segments).
  - Dijkstra travel time calculation:
    $$\text{minutes} = \frac{\text{km}}{\text{speed}[\text{class}] \times \text{factor}[\text{level}]} \times 60$$
    (Class A: 30 km/h, B: 22 km/h, E: 60 km/h; levels: normal 1.0, slow 0.55, jam 0.25, closed = level 3 skipped).
  - `plan_bus_route(world, bus)`: Computes fastest route through remaining trip stops. Adheres to minimum saving threshold ($\ge 1\text{ min}$ or $\ge 10\%$) before switching routes.
  - Strict preservation of forward travel: buses finish their current road segment without mid-road U-turns.
  - When all forward paths are closed or unreachable, bus state cleanly transitions to `"waiting"`.

- **`core/lib/sim.jac`**:
  - Clock-driven simulation (`tick`, `advance_bus`) synchronized with `DemoClock`.
  - Realistic stop lifecycle: arrives at stop, dwells 30 simulated seconds, departs.
  - Automatic `replan_all` triggered upon any traffic change (presets or individual roads), logging operational decisions to `Decision` nodes.

- **`core/walkers/demo.jac`**:
  - Cancelled scripted demo runner (`run_demo` deleted, contract marked removed D-C01).
  - Preserved clock controls: `status`, `speed` ($1\times, 5\times, 10\times, 30\times$), `pause`, `resume`, and `reset_demo`.

- **`core/walkers/traffic.jac`**:
  - `set_traffic`: Sets presets (`normal`, `slow_all`, `crash`) or targeted road levels; triggers immediate bus replanning.
  - `report_incident`: Registers road incidents and logs driver alerts.
  - `get_driver_view`: Returns driver telemetry (next stop, ETA, turn instruction text, reroute flag, saving, and traffic level).

- **Driver View (`driver/DriverApp.jac`, `pages/driver/[busId].jac`)**:
  - In-cab optimized UI with high-contrast night palette, 44px+ touch targets, and clear typography.
  - `DriverInstructionBar`: Prominent next maneuver, target destination, and remaining distance.
  - `RerouteBanner`: Highlighted reroute notification showing cause and travel minutes saved.
  - Telemetry cards: Next stop code & name, live ETA, waiting passenger count, and route status.
  - Rapid 2-tap incident reporting modal for breakdowns, hazards, and delays.

---

## 2. Test Verification

- `tests/routing_tests.jac` passed all 8 test suites:
  1. **Free roads**: Borella to Battaramulla routes through Rajagiriya (11.0–12.5 min). [PASS]
  2. **Closed road avoidance**: Rajagiriya–Battaramulla closed road is excluded from Dijkstra planning. [PASS]
  3. **Crash near Rajagiriya**: MB-101 completes current road to Rajagiriya, then reroutes via Nawala to Battaramulla with "closed" reroute reason. [PASS]
  4. **Slow road stability**: Minor slowdown on Rajagiriya–Battaramulla does not trigger unnecessary rerouting (< 1 min saving threshold). [PASS]
  5. **No mid-road U-turns**: Bus on closing road finishes segment at crawl speed ($5\text{ km/h}$). [PASS]
  6. **Cut off destination**: MB-101 waits when destination is completely blocked, resumes moving once road reopens. [PASS]
  7. **Stop arrival and dwell**: Bus reaches stop and enters `"dwelling"` state. [PASS]
  8. **Walker end-to-end**: `set_traffic` with `crash` preset immediately updates `get_driver_view` with rerouted path and reason. [PASS]

---

## 3. Jac Code Share Verification

- Ran `python scripts/jac_share.py`:
  - Jac lines: 8,126 (90.4%)
  - CSS lines: 719 (8.0%)
  - Python lines: 143 (1.6%)
  - **Result: 90.4% $\ge$ 85% requirement.**

---

## 4. Final Verdict

**PASS** — M3 is complete, validated against all contracts and architecture rules, and ready for squash merge.
