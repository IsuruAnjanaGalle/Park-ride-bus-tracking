"""Parking slot allocation and optimization algorithms for ParkRide."""

import from core.models.nodes {
    ParkingSlotNode,
    SlotType,
    SlotStatus
}

def find_best_slot(
    slots: list[ParkingSlotNode],
    requested_type: SlotType = SlotType.STANDARD,
    prefer_near_exit: bool = True
) -> ParkingSlotNode | None {
    # Filter for available slots of matching type
    matching_slots: list[ParkingSlotNode] = [];
    for slot in slots {
        if slot.status == SlotStatus.AVAILABLE and slot.slot_type == requested_type {
            matching_slots.append(slot);
        }
    }

    # If no strict match and requesting standard, can check if standard is empty
    if len(matching_slots) == 0 {
        return None;
    }

    if prefer_near_exit {
        # Sort by distance to exit
        sorted_slots = sorted(matching_slots, key=lambda (s: ParkingSlotNode) -> float { return s.distance_to_exit_m; });
        return sorted_slots[0];
    }

    return matching_slots[0];
}

def calculate_occupancy_stats(slots: list[ParkingSlotNode]) -> dict[str, int] {
    total = len(slots);
    available = 0;
    reserved = 0;
    occupied = 0;
    maintenance = 0;
    ev_available = 0;

    for s in slots {
        if s.status == SlotStatus.AVAILABLE {
            available += 1;
            if s.slot_type == SlotType.EV {
                ev_available += 1;
            }
        } elif s.status == SlotStatus.RESERVED {
            reserved += 1;
        } elif s.status == SlotStatus.OCCUPIED {
            occupied += 1;
        } elif s.status == SlotStatus.MAINTENANCE {
            maintenance += 1;
        }
    }

    return {
        "total": total,
        "available": available,
        "reserved": reserved,
        "occupied": occupied,
        "maintenance": maintenance,
        "ev_available": ev_available
    };
}
