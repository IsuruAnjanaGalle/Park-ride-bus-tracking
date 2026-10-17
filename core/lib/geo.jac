"""Small geometry helpers for bus positions on the map."""

import math;

"""Compass bearing in degrees (0 = north, clockwise) from point 1 to point 2."""
def bearing(lat1: float, lng1: float, lat2: float, lng2: float) -> float {
    p1 = math.radians(lat1);
    p2 = math.radians(lat2);
    dl = math.radians(lng2 - lng1);
    x = math.sin(dl) * math.cos(p2);
    y = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl);
    return round((math.degrees(math.atan2(x, y)) + 360.0) % 360.0, 1);
}

"""Great-circle distance in km between two points."""
def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float {
    r = 6371.0;
    p1 = math.radians(lat1);
    p2 = math.radians(lat2);
    dp = p2 - p1;
    dl = math.radians(lng2 - lng1);
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2;
    return 2 * r * math.asin(math.sqrt(h));
}

"""Linear interpolation between a and b at fraction t (0..1)."""
def lerp(a: float, b: float, t: float) -> float {
    return a + (b - a) * t;
}
