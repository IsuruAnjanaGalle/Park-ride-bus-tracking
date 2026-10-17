"""Graph model for Park & Ride Sri Lanka (SOW sections 5, 8A and 9.6).

Every node lives under one `World` node hung off `root.shared`, so passengers,
admins and anonymous visitors all read and write the same graph. Nodes inherit
`PublicNode`, which opens every instance to every user (app-owned public data).
"""

"""Base for app-owned shared nodes: every user may read and write them."""
node PublicNode {
    def __jac_access__ -> AccessLevel {
        return AccessLevel.WRITE;
    }
}

"""Anchor of the shared demo world; one per graph, under root.shared."""
node World(PublicNode) {
    has seeded_at: str = "",
        seed_source: str = "",
        next_id: int = 1;
}

"""Simulated clock. Every walker reads time through now() on this node."""
node DemoClock(PublicNode) {
    has start: str = "08:00:00",
        speed: float = 30.0,
        offset: float = 0.0,
        paused: bool = False,
        anchor_real: float = 0.0;
}

"""Park-and-ride hub. `junction` is its code on the road map."""
node Terminal(PublicNode) {
    has code: str,
        name: str,
        junction: str,
        lat: float = 0.0,
        lng: float = 0.0,
        full_grid: bool = False,
        chargers: list[dict[str, any]] = [];
}

"""One parking bay, code TERMINAL-TYPE-ZONE-NN (e.g. MKB-C-F-07).

type: B foot cycle, M motorcycle, C car, E EV charging.
zone: F front (near exit), M middle, R rear.
state: free, booked, occupied.
"""
node Slot(PublicNode) {
    has code: str,
        terminal: str,
        kind: str,
        zone: str,
        nn: int,
        state: str = "free",
        accessible: bool = False,
        charger_kw: int = 0,
        charger_type: str = "";
}

"""A parking reservation and its signed QR. state: booked, parked, released."""
node ParkingBooking(PublicNode) {
    has id: str,
        username: str,
        slot_code: str,
        terminal: str,
        arrival: str,
        return_by: str,
        qr_token: str = "",
        state: str = "booked",
        created_at: str = "";
}

"""A point on the road map: a stop, a terminal or a plain junction."""
node Junction(PublicNode) {
    has code: str,
        name: str,
        lat: float,
        lng: float,
        kind: str = "junction";
}

"""A bus stop on at least one route (terminals are stops too)."""
node Stop(Junction) {
    has is_terminal: bool = False;
}

"""A Metro bus route with its ordered stops (via OnRoute edges)."""
node Route(PublicNode) {
    has id: str,
        name: str,
        color: str,
        stop_codes: list[str] = [];
}

"""A simulated bus. Position and plan are advanced by the DemoClock."""
node Bus(PublicNode) {
    has id: str,
        route: str,
        plate: str,
        capacity: int = 40,
        driver: str = "",
        conductor: str = "",
        direction: str = "forward",
        from_stop: str = "",
        next_stop: str = "",
        progress: float = 0.0,
        lat: float = 0.0,
        lng: float = 0.0,
        heading: float = 0.0,
        road_from: str = "",
        road_to: str = "",
        path: list[str] = [],
        state: str = "moving",
        rerouted: bool = False,
        reroute_reason: str = "";
}

"""One run of a bus along its route in one direction."""
node Trip(PublicNode) {
    has id: str,
        bus_id: str,
        route: str,
        direction: str,
        stop_codes: list[str] = [],
        last_departed: int = -1,
        status: str = "running";
}

"""A bus's visit to a stop; its QR token is valid for this visit only."""
node StopVisit(PublicNode) {
    has trip_id: str,
        bus_id: str,
        stop_code: str,
        visit_no: int,
        qr_token: str = "",
        arrived_at: str = "",
        departed_at: str = "";
}

"""A seat booking. state: Pending, OnBoard, Alighted, Cancelled."""
node Booking(PublicNode) {
    has id: str,
        username: str,
        bus_id: str,
        trip_id: str,
        route: str,
        pickup: str,
        drop: str,
        state: str = "Pending",
        walk_in: bool = False,
        created_at: str = "";
}

"""One processed QR scan; scan_id is unique and makes scans idempotent."""
node Scan(PublicNode) {
    has scan_id: str,
        username: str,
        bus_id: str,
        stop_code: str,
        visit_no: int = 0,
        result: str = "",
        at: str = "";
}

"""App-level profile: links a login to its role (passenger or admin)."""
node Passenger(PublicNode) {
    has username: str,
        role: str = "passenger",
        root_id: str = "";
}

"""Operator alert: mismatch, auto_cancel, duplicate_scan, reroute, incident."""
node Alert(PublicNode) {
    has id: str,
        kind: str,
        message: str,
        bus_id: str = "",
        stop_code: str = "",
        at: str = "",
        resolved: bool = False;
}

"""A driver-reported incident on one road. severity: slow, jammed, closed."""
node Incident(PublicNode) {
    has id: str,
        kind: str,
        severity: str,
        road_from: str,
        road_to: str,
        reporter: str = "",
        bus_id: str = "",
        at: str = "",
        confirmed: bool = False;
}
