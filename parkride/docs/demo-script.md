# ParkRide Interactive Demonstration Script

This script provides a step-by-step presentation narrative for demonstrating the `parkride` system to evaluators, judges, and stakeholders.

---

## Scenario: The Seamless Western Province Commute
- **Commuter:** Isuru Perera (driving electric vehicle from Homagama/Kottawa).
- **Origin Hub:** Makumbura Multimodal Transport Center (MMC), Kottawa.
- **Destination:** Colombo Fort Central Financial District.
- **Goal:** Park private EV at Makumbura MMC, charge vehicle, ride expressway express shuttle to Fort, and return in the evening with zero ticketing friction.

---

## Step 1: System Boot & Graph Initialization

Run the application:
```bash
cd parkride
jac run main.jac
```

**Presenter Highlights:**
- The system automatically loads Western Province transit graph topology: 10 multimodal stops, 17 road links, parking bays, and the active expressway shuttle fleet.
- Object-Spatial architecture maintains high-speed in-memory graph traversal with root persistence.

---

## Step 2: Commuter Checks Parking & Allocates EV Slot

Execute the availability search walker:
```jac
root spawn check_parking_availability(terminal_id="stop_makumbura");
```
Then find the optimal slot nearest to the pedestrian terminal entrance:
```jac
root spawn find_available_slot(
    terminal_id="stop_makumbura",
    vehicle_type="ev",
    prefer_near_exit=True
);
```

**Visual / Output:**
- Returns slot **`EV-01`** in `Zone EV - Fast Charging` (distance to exit: 25.0 meters).

---

## Step 3: Instant Booking & Cryptographic QR Token Issuance

Issue reservation:
```jac
booking = root spawn create_booking(
    user_id="commuter_isuru",
    user_phone="+94771234567",
    vehicle_number="WP-CAB-4512",
    terminal_id="stop_makumbura",
    vehicle_type="ev",
    bus_route="EX1-01",
    fare_lkr=450.0
);
```

**Presenter Highlights:**
- Demonstrates `core/lib/qr_sign.jac`: Generates a tamper-proof HMAC-SHA256 signature containing booking ID, vehicle plate, terminal ID, slot ID, and expiry epoch.
- Slot status immediately updates to `RESERVED`.

---

## Step 4: Automated Ingress Barrier QR Scan

Commuter arrives at the Makumbura MMC boom barrier gate:
```jac
root spawn scan_gate_entry(
    qr_token="<token_from_step_3>",
    gate_id="MMC_GATE_IN_02"
);
```

**Visual / Output:**
- Status: `GRANTED`, Action: `BARRIER_OPENED`.
- Displays allocated slot number (`EV-01`) and navigational guidance.
- Slot state transitions from `RESERVED` to `OCCUPIED`.

---

## Step 5: Expressway Shuttle Boarding & Real-Time Telemetry

Commuter boards Shuttle `EX1-01` towards Fort. Track live bus position:
```jac
root spawn track_bus(route_number="EX1-01");
```

**Presenter Highlights:**
- Displays live GPS coordinates, heading (`315°`), current speed (`68.5 km/h`), passenger load (`32/54`), and estimated arrival time (`18.2 min`).

---

## Step 6: Dynamic Congestion Re-Routing (Dijkstra)

Demonstrate traffic delay along High Level Road vs. Expressway:
```jac
# Update congestion on parallel arterial road
root spawn update_road_traffic(
    from_stop_id="stop_maharagama",
    to_stop_id="stop_nugegoda",
    congestion_factor=2.2
);

# Compute fastest path
root spawn find_multimodal_route(
    origin_stop_id="stop_makumbura",
    destination_stop_id="stop_pettah_fort",
    optimize_by="travel_time"
);
```

**Presenter Highlights:**
- Dijkstra algorithm compares High Level Road (congested) vs. E02 Expressway Shuttle (uncongested).
- System automatically routes commuter via the Expressway Shuttle, saving 35 minutes!

---

## Step 7: Return Journey & Barrier Egress

Evening return to Makumbura MMC. Commuter scans QR pass at exit boom barrier:
```jac
root spawn scan_gate_exit(
    qr_token="<token_from_step_3>",
    gate_id="MMC_GATE_OUT_01"
);
```

**Visual / Output:**
- Status: `GRANTED`, Action: `BARRIER_OPENED`.
- Slot `EV-01` is released back to `AVAILABLE`.
- Booking marked `COMPLETED`.

---

## Step 8: Complete Automated Simulation Walker

To demonstrate the full sequence end-to-end in a single command:
```jac
root spawn run_demo_simulation();
```
Prints an exhaustive 6-step audit trail validating the entire commuter workflow!
