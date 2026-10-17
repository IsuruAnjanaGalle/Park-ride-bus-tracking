"""Typed edges of the Park & Ride graph."""

import from core.models.nodes { Junction, Route, Stop }

"""One direction of a road. cls: A main, B local, E expressway.

level: 0 free, 1 slow, 2 jammed, 3 closed.
"""
edge Road: Junction --> Junction {
    has a: str,
        b: str,
        km: float,
        cls: str = "A",
        level: int = 0;

    def __jac_access__ -> AccessLevel {
        return AccessLevel.WRITE;
    }
}

"""Route membership with the stop's position (seq 0 = first stop)."""
edge OnRoute: Route --> Stop {
    has seq: int;

    def __jac_access__ -> AccessLevel {
        return AccessLevel.WRITE;
    }
}
