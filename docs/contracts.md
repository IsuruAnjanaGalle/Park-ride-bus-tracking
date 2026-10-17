# Walker contracts — Park & Ride Sri Lanka

Owner: Dev A. Changing an input or output needs a PR labelled `contract-change` approved by Dev A and the developer who calls it. Adding a new optional field is not a change.

Screens never call walkers directly: they call the function with the same name in `components/shared/api.jac`. Every function returns the envelope in section 1. A full real example of every response is in `docs/samples/<walker>.json`, and the same data is what the mocks return.

## Status

`stub` = returns correctly shaped data from the seed but does not change anything yet. `real` = full logic, tested. When a walker becomes `real`, Dev A flips its `USE_MOCK` entry in `api.jac` to `False` and tells B and C.

| Walker | Auth | Status | Milestone |
| --- | --- | --- | --- |
| get_profile | login | real | 0 |
| get_terminals | public | real | 1 |
| get_slots | public | real | 1 |
| recommend_slots | public | real | 1 |
| book_slot | login | real | 1 |
| mark_parked | login | real | 1 |
| release_slot | login | real | 1 |
| get_map | public | real | 2 |
| get_buses | public | real | 2–3 |
| book_seat | login | real | 2 |
| get_trip | login | real | 2–3 |
| process_scan | login | real | 2 |
| admin_bus_list | admin | stub (Dev C) | 2 |
| admin_bus_account | admin | stub (Dev C) | 2 |
| admin_next_stop | admin | stub (Dev C); `qr`, `stop`, `visit_no` are real | 2 |
| admin_feed | admin | stub (Dev C); scans, alerts, decisions are real | 2 |
| demo_control | admin | real | 3 |
| set_traffic | admin | real | 3 |
| report_incident | public (driver) | real | 3 |
| get_driver_view | public (driver) | real | 3 |
| run_demo | admin | hidden (not used) — demo mode cancelled by the lead; code kept | – |
| run_demo | admin | real | 4 |
| reset_demo | admin | real | 0 |

Auth: **public** = `walker:pub`, no login. **login** = `walker:protect`; call `login()` in `api.jac` first (it also calls `get_profile`). **admin** = `walker:protect` plus the caller's profile role must be `admin`; otherwise `FORBIDDEN`.

> Jac 0.37 note: the SOW says `walker:priv` for admin walkers. In Jac 0.37 `:priv` means *not served at all*, so admin walkers are `walker:protect` with a role check inside (see docs/decisions.md D-04).

## 1. Envelope and errors

Every walker reports exactly one value:

```json
{"ok": true,  "data": { ... },  "error": null}
{"ok": false, "data": null,     "error": {"code": "NOT_FOUND", "message": "No bus MB-999."}}
```

| Code | Meaning |
| --- | --- |
| `INVALID_INPUT` | A field is missing or out of range; the message names it |
| `NOT_FOUND` | Unknown terminal, slot, bus, booking or preset |
| `FORBIDDEN` | Admin walker called without the admin role, or a username claimed by another login |
| `NO_PROFILE` | Logged in, but `get_profile` was never called for this login |
| `CONFLICT` | The slot or seat was taken in the meantime (milestone 1+) |
| `NO_SEAT` | No free seat on some segment between pickup and drop (milestone 2+) |
| `PASSED_STOP` | Pickup is a stop the bus has already left (milestone 2+) |
| `ALREADY_BOOKED` | The passenger already has an active booking of this kind (milestone 1+) |
| `UNAUTHORIZED` | Added by `api.jac` when the server refuses a call without a session |
| `NETWORK`, `EMPTY` | Added by `api.jac` when the call itself failed |
| `MOCK_ERROR` | Returned by every mock when `MOCK_MODE` is `"error"` |

Scan outcomes (duplicate, rejected, …) are **not** errors: `process_scan` returns `ok: true` with a `result` field (3.11).

## 2. Shared shapes

- **StopRef** `{code, name}` — e.g. `{"code": "BOR", "name": "Borella"}`.
- **Clock** `{time: "HH:MM:SS", sim_seconds, speed, paused}` — simulated time from the DemoClock.
- **Slot** `{code, terminal, type, zone, nn, state, accessible, charger_kw, charger_type}` — `type` B foot cycle, M motorcycle, C car, E EV charging; `zone` F front, M middle, R rear; `state` free, booked, occupied; `charger_kw` 0 unless `type` is E.
- **Counts** `{B: {total, free, booked, occupied}, M: {…}, C: {…}, E: {…}}`.
- **Terminal** `{code, name, junction, lat, lng, full_grid, chargers: [{n, kw, type}], counts: Counts}` — `full_grid` is true only for Makumbura (the only grid drawn today).
- **ParkingBooking** `{id, terminal, slot_code, type, zone, arrival, return_by, state, qr}` — `state` booked, parked, released; `qr` is the signed token to render with qrcode.react.
- **Booking** `{id, bus_id, route, pickup: StopRef, drop: StopRef, state, walk_in, created_at}` — `state` Pending, OnBoard, Alighted, Cancelled.
- **Bus** (BusSummary) `{id, route, route_name, color, plate, lat, lng, heading, direction, state, from_stop: StopRef, next_stop: StopRef, eta_min, on_board, capacity, seats_left, segment_seats: [int], stops: [{code, name, passed, eta_min}], rerouted, reroute_reason, alert}`
  - `heading` degrees, 0 = north, clockwise. `state` moving, dwelling, waiting. `direction` forward or reverse along the route.
  - `stops` is the current trip in travel order; `passed: true` stops cannot be chosen as pickup (hide them). `eta_min` is null for passed stops.
  - `segment_seats[i]` = seats free between `stops[i]` and `stops[i+1]`. Seats for a pickup→drop booking = min over the segments from pickup up to (not including) drop. `seats_left` = seats on the segment the bus is on now.
  - `alert` = the bus has an unresolved alert (show the alert dot).
- **Alert** `{id, kind, message, bus_id, stop_code, at, resolved}` — `kind` mismatch, auto_cancel, duplicate_scan, reroute, incident.
- **ScanRow** `{at, passenger, scan_id, type, stop: StopRef, bus_id}` — `passenger` is masked (`pa*****er`); `type` is the scan `result`.
- **Decision** `{at, bus_id, decision, reason}` — `decision` Rerouted, Kept route, Waiting, Moving again (milestone 3).

## 3. Walkers

Inputs are keyword arguments of the `api.jac` function (the walker's `has` fields). Defaults shown after `=`.

### 3.0 get_profile — login
Binds the logged-in user to a username (first claim wins) and returns the role. `api.login()` calls it for you.
- In: `username: str`
- Out: `{username, role}` — `role` passenger or admin.
- Errors: `INVALID_INPUT`, `FORBIDDEN` (the username belongs to another login).

### 3.1 get_terminals — public
- In: none
- Out: `{terminals: [Terminal]}` — the 4 terminals with live counts per slot type.

### 3.2 get_slots — public
- In: `terminal: str = "MKB"`
- Out: `{terminal, slots: [Slot]}` — every slot of the terminal (310 at Makumbura).
- Errors: `NOT_FOUND`.

### 3.3 recommend_slots — public
Zone by expected stay (SOW 9.1): under 3 h → F, 3 h to 8 h → M, over 8 h or overnight → R. Cars with `ev = "needs_charging"` get only `E` slots; `"park_only"` and `"no"` get `C` slots. `accessible = true` offers the 2 accessible front car slots first.
- In: `terminal: str`, `vehicle: str` (B, M or C), `ev: str = "no"` (no, needs_charging, park_only), `accessible: bool = false`, `arrival: str = "08:00"`, `return_by: str = "10:00"` (HH:MM; earlier than arrival = next day)
- Out: `{terminal, zone, stay_hours, slot_type, options: [{rank, slot: Slot, zone, score, reason}], fallback}`
  - Up to 3 options: rank 1 = recommendation, rank 2 = next best in the same zone, rank 3 = best in the neighbouring zone. `reason` is one plain sentence.
  - `fallback` is null, or a sentence when no slot of the right type is free (e.g. EV slots full → car slots offered).
- Errors: `NOT_FOUND`, `INVALID_INPUT`.

### 3.4 book_slot — login
Books a free slot and signs its parking QR (HMAC-SHA256).
- In: `terminal: str`, `slot_code: str`, `arrival: str`, `return_by: str`
- Out: `{booking: ParkingBooking}` — slot becomes `booked`.
- Errors: `NOT_FOUND`, `CONFLICT` (slot not free), `ALREADY_BOOKED` (one active parking booking per passenger), `INVALID_INPUT`.

### 3.5 mark_parked — login
- In: `booking_id: str`
- Out: `{booking: ParkingBooking, slot: Slot}` — booking `parked`, slot `occupied`.
- Errors: `NOT_FOUND`, `INVALID_INPUT` (not in state booked).

### 3.6 release_slot — login
Releases the slot on return (scanning the parking QR again, P-13). Give either field.
- In: `booking_id: str = ""`, `qr: str = ""`
- Out: `{booking: ParkingBooking, slot: Slot}` — booking `released`, slot `free`.
- Errors: `NOT_FOUND`, `INVALID_INPUT`.

### 3.7 get_map — public
The app's own map (no Google Maps).
- In: none
- Out: `{junctions: [{code, name, lat, lng, kind}], roads: [{a, b, km, cls, level, minutes}], routes: [{id, name, color, stops: [code]}], bounds: {min_lat, max_lat, min_lng, max_lng}}`
  - 34 junctions; `kind` terminal, stop or junction.
  - 53 roads, one entry per two-way road. `cls` A main, B local, E expressway. `level` 0 free (grey), 1 slow (amber), 2 jammed (red), 3 closed (dark, dashed). `minutes` = current travel time.
  - Route colours: R1 blue, R2 violet, R3 teal.

### 3.8 get_buses — public
Poll every 2 s.
- In: `route: str = ""` (empty = all)
- Out: `{clock: Clock, buses: [Bus]}` — 9 buses.

### 3.9 book_seat — login
Per-segment seat check (SOW 9.2): accepted only if a seat is free on every segment from pickup to drop. Pickup must be a stop the bus has not left.
- In: `bus_id: str`, `pickup: str`, `drop: str` (stop codes on the bus's current trip, pickup before drop)
- Out: `{booking: Booking, seats_left_on_segment: int}` — booking `Pending`; the driver's waiting count at pickup goes up.
- Errors: `NOT_FOUND`, `INVALID_INPUT` (not on the trip, or drop not after pickup), `PASSED_STOP`, `NO_SEAT`, `ALREADY_BOOKED`.

### 3.10 get_trip — login
The passenger's trip card. Poll every 2 s.
- In: `booking_id: str = ""` (empty = the passenger's active booking)
- Out: `{booking: Booking, bus: Bus, stops: [{code, name, status, eta_min, is_pickup, is_drop}], stops_remaining, alert, alert_message, delay}`
  - `status` passed, next, upcoming.
  - `alert` is true from 2 stops before the drop stop (banner + `navigator.vibrate`); `alert_message` e.g. "Your stop is 2 stops away".
  - `delay` is null or `{minutes, reason}` e.g. `{"minutes": 6, "reason": "Accident on Rajagiriya – Battaramulla"}`.
- Errors: `NOT_FOUND` (no active booking).

### 3.11 process_scan — login
The passenger scans the stop QR shown on the admin next-stop panel. Send a fresh `scan_id` (UUID) per physical scan; resending the same `scan_id` is safe. If `result` is `walk_in_needs_drop`, ask for a destination and call again with the same `qr`, a new `scan_id` and `drop`.
- In: `scan_id: str`, `qr: str`, `drop: str = ""`
- Out: `{result, message, scan_id, booking: Booking | null, stop: StopRef | null, bus_id}`

| `result` | When (SOW 9.4) | Show |
| --- | --- | --- |
| `boarded` | Pending booking, this stop is the pickup — or a walk-in that gave `drop` | "Confirmed, you are on board" |
| `alighted` | On board, this stop is after pickup; seat freed | "Alighted" |
| `walk_in_needs_drop` | No booking and not on board | Destination picker, then rescan |
| `duplicate` | This `scan_id` was already processed | "Already counted" |
| `already_on_board` | On board and scanning at the pickup again | "Already on board, ignored" |
| `already_alighted` | Booking already alighted | "Already counted" |
| `rejected` | Bad or expired QR, or a booking for a different bus or stop | `message` |

- Errors: `INVALID_INPUT` (missing `scan_id` or `qr`).

### 3.12 admin_bus_list — admin
- In: none
- Out: `{clock: Clock, buses: [Bus]}` — same shape as `get_buses`.

### 3.13 admin_bus_account — admin
- In: `bus_id: str`
- Out: `{bus: {id, plate, route, route_name, color, driver, conductor, capacity, on_board, seats_left}, position: {lat, lng, heading}, path: [code], next_stop: StopRef, eta_min, trips_today: [{id, direction, status, stops: [code], last_departed}]}`
  - `path` = junction codes of the planned route to the next stop (draw it on the map).
- Errors: `NOT_FOUND`.

### 3.14 admin_next_stop — admin
Poll every 2 s. Render `qr` large enough to scan from 1 m. `qr` is empty (`""`) while the bus is between stops: show "Bus on the way" instead of a QR.
- In: `bus_id: str`
- Out: `{bus_id, stop: StopRef, eta_min, visit_no, getting_off, getting_off_names: [str], bookings_to_board, walk_ins, seats_left_after, qr, qr_expires_in_s}`
  - The QR encodes bus, stop, visit number and expiry, signed; it changes on every visit.
- Errors: `NOT_FOUND`.

### 3.15 admin_feed — admin
Poll every 2 s. Newest first.
- In: `limit: int = 50`
- Out: `{scans: [ScanRow], alerts: [Alert], decisions: [Decision]}`

### 3.16 demo_control — admin
- In: `action: str = "status"`, `speed: float = 0`, `bus_id: str = ""`, `stop: str = ""`, `count: int = 1`, `drop: str = ""`
  - `status`; `speed` (1, 5, 10 or 30); `pause`; `resume`.
  - `jump` (`bus_id`, `stop`): the bus drives stop by stop to `stop` (skipped stops run their departure rules), arrives, and **waits there** so its stop QR can be scanned. Jumping to a route's final terminal turns the bus around there, ready for the trip back.
  - `depart` (`bus_id`): the waiting bus leaves now — pending pickups are auto-cancelled and the alighting mismatch check runs.
  - `spawn_passenger` (`bus_id`, `stop`, `count`, `drop`): test riders booked from `stop` to `drop` (already on board if the bus is at `stop`).
- Out: `{clock: Clock, message}`
- Errors: `INVALID_INPUT`.

### 3.17 set_traffic — admin
- In: `preset: str = ""` (clear, rush, crash, hlr, cut) **or** `a: str`, `b: str`, `level: int` (0–3, applies to both directions)
- Out: `{preset, roads: [{a, b, level}], decisions: [Decision]}` — the roads changed and what each affected bus decided.
- Errors: `NOT_FOUND` (preset), `INVALID_INPUT`.

### 3.18 report_incident — public (driver)
Closes or slows the bus's current road and re-plans buses.
- In: `bus_id: str`, `kind: str` (accident, breakdown, flooding, road_works, road_closed), `severity: str` (slow, jammed, closed)
- Out: `{incident: {id, kind, severity, road: {a, b, level}, bus_id, at}, decisions: [Decision]}`
- Errors: `NOT_FOUND`, `INVALID_INPUT`.

### 3.19 get_driver_view — public (driver)
Poll every 2 s.
- In: `bus_id: str`
- Out: `{bus: Bus, instruction: {text, turn, toward, km}, next_stop: StopRef, eta_min, waiting_at_next, road: {a, b, level}, path: [code], rerouted, reroute_reason}`
  - `turn` left, right, straight, arrive. `text` e.g. "Turn right toward Nawala". `waiting_at_next` = pending bookings at the next stop. `reroute_reason` e.g. "Rajagiriya – Battaramulla closed · saves 6 min".
- Errors: `NOT_FOUND`.

### 3.20 run_demo — admin — hidden (not used)
Demo mode is cancelled for today. The walker still works but no screen may call it.

- In: `action: str = "status"` (status, play, pause, next, restart)
- Out: `{step, total, caption, playing, finished, last}` — `step` = steps done (0 before Play); `caption` describes the step just run; `last` = its result. While `playing`, poll `status` every 2 s: each poll runs the next step once 4 s have passed. `restart` resets the world to the seed (`last.reset_seconds`).
- Errors: `INVALID_INPUT`.

### 3.21 reset_demo — admin
Rebuilds the world from `docs/data/` (target under 5 s).
- In: none
- Out: `{seconds, counts: {terminals, slots, junctions, roads, routes, buses, users}}`
