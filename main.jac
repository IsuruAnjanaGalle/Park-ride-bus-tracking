"""Park & Ride Sri Lanka - entry point.

Server: the walker modules below are the API (POST /walker/<name>, see docs/contracts.md).
Client: file-based routing from pages/ - / passenger, /admin, /driver/:busId, /dev/core.
"""

import from core.walkers.profile { get_profile }
import from core.walkers.parking { get_terminals, get_slots, recommend_slots, book_slot, mark_parked, release_slot }
import from core.walkers.buses { get_map, get_buses, book_seat, get_trip }
import from core.walkers.scans { process_scan }
import from core.walkers.admin { admin_bus_list, admin_bus_account, admin_next_stop, admin_feed }
import from core.walkers.traffic { set_traffic, report_incident, get_driver_view }
import from core.walkers.demo { demo_control, reset_demo }

import "./styles/main.css";

def:pub app(children: any) -> JsxElement {
    <>{children}</>
}
