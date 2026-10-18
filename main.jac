"""Park & Ride Sri Lanka - entry point.

Server: the walker modules below are the API (POST /walker/<name>, see docs/contracts.md).
Client: file-based routing from pages/ - / passenger, /admin, /driver/:busId, /dev/core.
"""

import from core.walkers.profile { get_profile, verify_login }
import from core.walkers.parking { get_terminals, get_slots, recommend_slots, book_slot, mark_parked, release_slot }
import from core.walkers.buses { get_map, get_buses, book_seat, get_trip }
import from core.walkers.scans { process_scan }
import from core.walkers.admin { admin_bus_list, admin_bus_account, admin_next_stop, admin_feed }
import from core.walkers.traffic { set_traffic, report_incident, get_driver_view }
import from core.walkers.demo { demo_control, reset_demo }

cl {
    import from "@jac/runtime" { Router, Routes, Route }
    import from pages.index { PassengerHome }
    import from pages.admin.index { AdminPage }
    import from driver.DriverApp { DriverApp }
    import from pages.dev.core { CoreConsolePage }
    import from pages.login { LoginPage }

    import "./styles/main.css";
    import "./styles/tokens.css";
    import "./styles/motion.css";

    def:pub app -> JsxElement {
        return <Router>
            <Routes>
                <Route path="/" element={<PassengerHome />} />
                <Route path="/admin" element={<AdminPage />} />
                <Route path="/driver/:busId" element={<DriverApp />} />
                <Route path="/dev/core" element={<CoreConsolePage />} />
                <Route path="/login" element={<LoginPage />} />
            </Routes>
        </Router>;
    }
}
