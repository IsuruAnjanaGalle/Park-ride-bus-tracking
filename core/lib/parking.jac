"""Parking rules (SOW 9.1, P-05..P-13, F-21..F-23): recommendations and the booking lifecycle.

All state changes run under WORLD_LOCK so two passengers cannot take the same slot.
"""

import from core.models.nodes { World, Terminal, Slot, ParkingBooking, Passenger }
import from core.lib.world { find_terminal, new_id, get_clock }
import from core.lib.slots { SlotView, slot_views, slot_node, set_slot_state }
import from core.lib.clock { now_hms }
import from core.lib.qr { sign_token, verify_token }
import from core.lib.locks { WORLD_LOCK }
import from core.lib.rules { zone_for_stay }

glob ZONE_NAMES: dict[str, str] = {"F": "front line", "M": "middle", "R": "rear"};

"""The zone next to `zone` that best fits the stay (rank 3 option)."""
def neighbour_zone(zone: str, hours: float) -> str {
    if zone == "F" {
        return "M";
    }
    if zone == "R" {
        return "M";
    }
    return "R" if hours > 5.5 else "F";
}

def _reason(slot: SlotView, zone: str, rank: int) -> str {
    where = ZONE_NAMES.get(slot.zone, slot.zone);
    if slot.kind == "E" {
        return f"EV charger {slot.charger_kw} kW {slot.charger_type}, {where}, bay {slot.nn} from the exit.";
    }
    if slot.accessible {
        return f"Accessible wide bay in the {where}, nearest the gate.";
    }
    if rank == 1 {
        return f"Best match: {where} suits your stay; bay {slot.nn} from the exit.";
    }
    if slot.zone == zone {
        return f"Same zone ({where}), bay {slot.nn} from the exit.";
    }
    return f"Neighbouring zone ({where}), bay {slot.nn} from the exit.";
}

def _option(slot: SlotView, zone: str, rank: int) -> dict[str, any] {
    zone_match = 1 if slot.zone == zone else 0;
    return {
        "rank": rank,
        "slot": {
            "code": slot.code, "terminal": slot.terminal, "type": slot.kind, "zone": slot.zone,
            "nn": slot.nn, "state": slot.state, "accessible": slot.accessible,
            "charger_kw": slot.charger_kw, "charger_type": slot.charger_type
        },
        "zone": slot.zone,
        "score": 100 * zone_match - 5 * slot.nn,
        "reason": _reason(slot, zone, rank)
    };
}

"""Up to 3 ranked options: best in zone, next in zone, best in the neighbouring zone."""
def recommend(term: Terminal, vehicle: str, ev: str, accessible: bool, hours: float) -> dict[str, any] {
    zone = zone_for_stay(hours);
    kind = "E" if vehicle == "C" and ev == "needs_charging" else vehicle;
    fallback: str | None = None;
    slots = slot_views(term);
    free = sorted([s for s in slots if s.kind == kind and s.state == "free"], key=lambda (s: SlotView) { s.nn; });
    if kind == "E" and not free {
        kind = "C";
        fallback = "All EV charging slots are taken; these are normal car slots.";
        free = sorted([s for s in slots if s.kind == "C" and s.state == "free"], key=lambda (s: SlotView) { s.nn; });
    }
    picks: list[SlotView] = [];
    if kind == "E" {
        picks = free[:3];
    } else {
        if kind == "C" and accessible {
            picks = [s for s in free if s.accessible][:2];
        }
        pool = [s for s in free if not s.accessible];
        in_zone = [s for s in pool if s.zone == zone];
        near = [s for s in pool if s.zone == neighbour_zone(zone, hours)];
        for s in in_zone[:max(2 - len(picks), 0)] + near[:1] + in_zone + near + pool {
            if len(picks) >= 3 {
                break;
            }
            if s not in picks {
                picks.append(s);
            }
        }
    }
    if not picks and fallback is None {
        fallback = "No free slot of this type at this terminal.";
    }
    return {
        "terminal": term.code,
        "zone": zone,
        "stay_hours": hours,
        "slot_type": kind,
        "options": [_option(s, zone, i + 1) for (i, s) in enumerate(picks)],
        "fallback": fallback
    };
}

def find_parking(world: World, booking_id: str) -> ParkingBooking | None {
    found = [world -->[?:ParkingBooking, id == booking_id]];
    return found[0] if found else None;
}

def slot_by_code(world: World, terminal: str, code: str) -> Slot | None {
    term = find_terminal(world, terminal);
    if term is None {
        return None;
    }
    return slot_node(term, code);
}

"""Book a free slot. Returns (error_code, booking); error_code is "" on success."""
def book(world: World, prof: Passenger, term: Terminal, code: str, arrival: str, return_by: str) -> tuple[str, any] {
    with WORLD_LOCK {
        slot = slot_node(term, code);
        if slot is None {
            return ("NOT_FOUND", None);
        }
        active = [
            pb for pb in [world -->[?:ParkingBooking]]
            if pb.username == prof.username and pb.state in ["booked", "parked"]
        ];
        if active {
            return ("ALREADY_BOOKED", active[0]);
        }
        if slot.state != "free" {
            return ("CONFLICT", None);
        }
        pb = ParkingBooking(
            id=new_id(world, "PB"), username=prof.username, slot_code=slot.code, terminal=term.code,
            arrival=arrival, return_by=return_by, state="booked", created_at=now_hms(get_clock(world))
        );
        pb.qr_token = sign_token({
            "t": "parking", "id": pb.id, "slot": slot.code, "terminal": term.code, "return_by": return_by
        });
        world ++> pb;
        set_slot_state(term, slot, "booked");
        return ("", pb);
    }
}

"""booked -> parked; the slot turns occupied."""
def park(world: World, pb: ParkingBooking) -> str {
    with WORLD_LOCK {
        if pb.state != "booked" {
            return "INVALID_INPUT";
        }
        term = find_terminal(world, pb.terminal);
        slot = slot_node(term, pb.slot_code) if term else None;
        pb.state = "parked";
        if term and slot {
            set_slot_state(term, slot, "occupied");
        }
        return "";
    }
}

"""booked/parked -> released; the slot turns free."""
def release(world: World, pb: ParkingBooking) -> str {
    with WORLD_LOCK {
        if pb.state not in ["booked", "parked"] {
            return "INVALID_INPUT";
        }
        term = find_terminal(world, pb.terminal);
        slot = slot_node(term, pb.slot_code) if term else None;
        pb.state = "released";
        if term and slot {
            set_slot_state(term, slot, "free");
        }
        return "";
    }
}

"""The parking booking id inside a parking QR, or "" if the QR is not a valid parking QR."""
def booking_id_from_qr(qr: str) -> str {
    check = verify_token(qr);
    if not check["valid"] or check["payload"].get("t") != "parking" {
        return "";
    }
    return check["payload"].get("id", "");
}
