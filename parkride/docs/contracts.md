# Interface Contracts & Walker API Specification

This document details the interface schemas, parameters, and response envelopes for all walkers and data models in the `parkride` architecture.

---

## 1. Node & Edge Archetype Schemas

### 1.1 `TerminalNode`
Represents a major multimodal transit hub.
```jac
node TerminalNode {
    has id: str;               # e.g., "stop_makumbura"
    has name: str;             # "Makumbura Multimodal Transport Center (MMC)"
    has code: str;             # "MMC"
    has latitude: float;       # 6.8407
    has longitude: float;      # 79.9984
    has city: str;             # "Kottawa"
    has total_slots: int;      # 50
    has available_slots: int;  # 42
}
```

### 1.2 `ParkingSlotNode`
Represents an individual parking space.
```jac
node ParkingSlotNode {
    has id: str;                           # "slot_mmc_a01"
    has terminal_id: str;                  # "stop_makumbura"
    has slot_number: str;                  # "A-01"
    has slot_type: SlotType;               # STANDARD, EV, HANDICAP, MOTORCYCLE
    has status: SlotStatus;                # AVAILABLE, RESERVED, OCCUPIED, MAINTENANCE
    has floor_or_zone: str;                # "Zone A - Ground Level"
    has distance_to_exit_m: float;         # 18.0
    has current_reservation_id: str;       # "bk_98f412" (empty if available)
    has updated_at: str;                   # ISO 8601 timestamp
}
```

### 1.3 `RoadEdge`
Connects two transit `StopNode`s with physical & congestion attributes.
```jac
edge RoadEdge: StopNode --> StopNode {
    has road_name: str;                    # "High Level Road (A4)"
    has distance_km: float;                # 4.5
    has base_travel_time_min: float;       # 9.0
    has current_travel_time_min: float;    # 12.0
    has congestion_factor: float;          # 1.33
    has is_expressway: bool;               # False
}
```

---

## 2. Walker Interface Contracts

### 2.1 `check_parking_availability`
Inspects terminals and reports aggregated parking capacity.
- **Parameters:**
  - `terminal_id: str` *(Optional)* — Specific terminal ID (e.g. `"stop_makumbura"`). If empty, returns all terminals.
- **Report Envelope:**
```json
{
  "status": "success",
  "terminals": [
    {
      "terminal_id": "stop_makumbura",
      "name": "Makumbura Multimodal Transport Center (MMC)",
      "city": "Kottawa",
      "total_slots": 50,
      "available_slots": 42,
      "reserved_slots": 2,
      "occupied_slots": 5,
      "maintenance_slots": 1,
      "ev_available": 3
    }
  ]
}
```

---

### 2.2 `create_booking`
Reserves a parking bay, links booking to the graph, and mints an HMAC QR pass.
- **Parameters:**
  - `user_id: str` *(Required)* — Unique identifier of commuter.
  - `user_phone: str` *(Required)* — Sri Lankan phone number (e.g. `"+94771234567"`).
  - `vehicle_number: str` *(Required)* — Vehicle plate (e.g. `"WP-CAB-4512"`).
  - `terminal_id: str` *(Required)* — Target terminal ID.
  - `slot_id: str` *(Optional)* — Specific slot (auto-allocated if empty).
  - `vehicle_type: str` *(Default: `"standard"`)* — `"standard"`, `"ev"`, `"handicap"`, `"motorcycle"`.
  - `bus_route: str` *(Default: `"EX1-01"`)* — Associated express bus connection.
  - `fare_lkr: float` *(Default: `350.0`)* — Combo fare in Sri Lankan Rupees.
- **Report Envelope:**
```json
{
  "status": "confirmed",
  "booking_id": "bk_a1b2c3d4",
  "terminal_name": "Makumbura Multimodal Transport Center (MMC)",
  "slot_number": "EV-01",
  "slot_type": "ev",
  "vehicle_number": "WP-CAB-4512",
  "bus_route": "EX1-01",
  "qr_token": "eyJib29raW5nX2lkIjoiYmst..." + "." + "7f8b9a2c...",
  "fare_lkr": 450.0,
  "created_at": "2026-10-17T09:30:00+05:30"
}
```

---

### 2.3 `scan_gate_entry`
Validates commuter entry at automated parking gates.
- **Parameters:**
  - `qr_token: str` *(Required)* — Cryptographic HMAC token presented to scanner.
  - `gate_id: str` *(Default: `"GATE_IN_01"`)* — Physical barrier gate ID.
- **Report Envelope:**
```json
{
  "status": "granted",
  "gate_action": "BARRIER_OPENED",
  "gate_id": "GATE_IN_01",
  "booking_id": "bk_a1b2c3d4",
  "vehicle_number": "WP-CAB-4512",
  "allocated_slot": "EV-01",
  "floor_or_zone": "Zone EV - Fast Charging",
  "check_in_time": "2026-10-17T09:45:00+05:30",
  "message": "Welcome to ParkRide! Barrier opened."
}
```

---

### 2.4 `scan_gate_exit`
Validates commuter departure, releases parking bay, and finalizes combo fare.
- **Parameters:**
  - `qr_token: str` *(Required)* — Cryptographic QR token presented at exit gate.
  - `gate_id: str` *(Default: `"GATE_OUT_01"`)* — Physical exit gate ID.
- **Report Envelope:**
```json
{
  "status": "granted",
  "gate_action": "BARRIER_OPENED",
  "gate_id": "GATE_OUT_01",
  "booking_id": "bk_a1b2c3d4",
  "vehicle_number": "WP-CAB-4512",
  "check_in_time": "2026-10-17T09:45:00+05:30",
  "check_out_time": "2026-10-17T17:45:00+05:30",
  "fare_paid_lkr": 450.0,
  "message": "Thank you for riding with ParkRide! Have a safe journey."
}
```

---

### 2.5 `find_multimodal_route`
Dijkstra shortest path algorithm calculating optimal multimodal transit route.
- **Parameters:**
  - `origin_stop_id: str` *(Required)* — Origin stop ID.
  - `destination_stop_id: str` *(Required)* — Destination stop ID.
  - `optimize_by: str` *(Default: `"travel_time"`)* — `"travel_time"` or `"distance"`.
- **Report Envelope:**
```json
{
  "status": "success",
  "origin": { "id": "stop_makumbura", "name": "Makumbura MMC" },
  "destination": { "id": "stop_pettah_fort", "name": "Pettah - Fort" },
  "optimize_by": "travel_time",
  "total_distance_km": 21.5,
  "total_travel_time_min": 26.0,
  "hops_count": 1,
  "path_names": ["Makumbura MMC", "Pettah - Fort"],
  "legs": [
    {
      "from_stop_id": "stop_makumbura",
      "to_stop_id": "stop_pettah_fort",
      "road_name": "Direct Expressway P&R Shuttle",
      "distance_km": 21.5,
      "travel_time_min": 26.0,
      "is_expressway": true
    }
  ],
  "park_and_ride_terminal": "Makumbura Multimodal Transport Center (MMC)",
  "recommended_shuttle": "EX1-01 Expressway Direct Shuttle"
}
```

---

### 2.6 `track_bus`
Fetches live telemetry, passenger load, and arrival ETA.
- **Parameters:**
  - `bus_id: str` *(Optional)* — e.g. `"bus_ex1_01"`.
  - `route_number: str` *(Optional)* — e.g. `"EX1-01"`.
- **Report Envelope:**
```json
{
  "status": "success",
  "count": 1,
  "telemetry": [
    {
      "bus_id": "bus_ex1_01",
      "route_number": "EX1-01",
      "plate_number": "ND-8821",
      "status": "on_route",
      "latitude": 6.8850,
      "longitude": 79.9400,
      "heading_deg": 315.0,
      "speed_kmh": 68.5,
      "capacity": 54,
      "current_passengers": 32,
      "occupancy_percent": 59.3,
      "current_stop_id": "stop_makumbura",
      "next_stop_id": "stop_pettah_fort",
      "estimated_arrival_minutes": 18.2
    }
  ]
}
```

---

## 3. Cryptographic Token Format

QR passes encode an HMAC-signed token using the format:
```text
<base64_encoded_json_payload>.<hex_encoded_sha256_hmac>
```
### JSON Payload Structure:
```json
{
  "booking_id": "bk_a1b2c3d4",
  "vehicle_number": "WP-CAB-4512",
  "terminal_id": "stop_makumbura",
  "slot_id": "slot_mmc_ev01",
  "exp": 1773086400.0
}
```
Validation fails if:
1. Suffix HMAC does not match SHA256(payload, secret).
2. Current epoch timestamp exceeds `exp`.
3. Token structure is corrupted or missing delimiter.
