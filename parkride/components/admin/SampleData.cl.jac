"""SampleData Module.

Provides realistic Western Province transit sample data for the Admin and Driver views.
Conforms to interface schemas in docs/contracts.md.
"""

import from .BusRow { BusInfo }
import from .NextStopPanel { StopExchangeInfo }
import from .ScanFeed { ScanEvent }
import from .AlertFeed { AlertEvent }

def:pub get_sample_fleet -> list[BusInfo] {
    return [
        BusInfo(
            id="bus_ex1_01",
            route="EX1-01",
            plate="ND-8821",
            next_stop="Makumbura MMC",
            eta=12.5,
            passengers=34,
            capacity=54,
            color="#0284c7",
            alert=False
        ),
        BusInfo(
            id="bus_ex1_02",
            route="EX1-02",
            plate="ND-9104",
            next_stop="Pettah - Fort",
            eta=7.0,
            passengers=49,
            capacity=54,
            color="#0284c7",
            alert=True
        ),
        BusInfo(
            id="bus_138_01",
            route="138",
            plate="WP-NB-5520",
            next_stop="Maharagama Town",
            eta=18.0,
            passengers=51,
            capacity=54,
            color="#10b981",
            alert=True
        ),
        BusInfo(
            id="bus_120_04",
            route="120",
            plate="WP-NC-1234",
            next_stop="Nugegoda Junction",
            eta=24.0,
            passengers=28,
            capacity=54,
            color="#a855f7",
            alert=False
        )
    ];
}

def:pub get_sample_stop_exchange -> StopExchangeInfo {
    return StopExchangeInfo(
        stop_name="Makumbura Multimodal Transport Center (MMC)",
        stop_code="MMC",
        eta_minutes=7.5,
        getting_off=8,
        bookings_to_board=16,
        walk_ins=4,
        seats_left=18,
        capacity=54,
        qr_token="PR-MMC-EX1-8821-20261017-V99"
    );
}

def:pub get_sample_scans -> list[ScanEvent] {
    return [
        ScanEvent(
            time="10:25:42",
            masked_passenger="WP-CAB-***2",
            scan_id="SCN-9042",
            action="boarded",
            stop_name="Makumbura MMC"
        ),
        ScanEvent(
            time="10:24:18",
            masked_passenger="WP-BC-***8",
            scan_id="SCN-9041",
            action="walk-in",
            stop_name="Makumbura MMC"
        ),
        ScanEvent(
            time="10:23:55",
            masked_passenger="WP-CAB-***2",
            scan_id="SCN-9040",
            action="duplicate ignored",
            stop_name="Makumbura MMC"
        ),
        ScanEvent(
            time="10:22:10",
            masked_passenger="usr_***77",
            scan_id="SCN-9039",
            action="alighted",
            stop_name="Nugegoda"
        ),
        ScanEvent(
            time="10:21:05",
            masked_passenger="WP-GA-***5",
            scan_id="SCN-9038",
            action="boarded",
            stop_name="Maharagama"
        )
    ];
}

def:pub get_sample_alerts -> list[AlertEvent] {
    return [
        AlertEvent(
            id="alt_01",
            time="10:25:10",
            category="reroute",
            title="A4 High Level Jam · Diversion Active",
            details="Congestion factor 2.4 between Maharagama & Nugegoda. Rerouting EX1 shuttles to Expressway.",
            severity="warning"
        ),
        AlertEvent(
            id="alt_02",
            time="10:23:45",
            category="incident",
            title="Accident near Rajagiriya Flyover",
            details="Right outbound lane blocked. Slow moving traffic with 15-minute expected transit delay.",
            severity="danger"
        ),
        AlertEvent(
            id="alt_03",
            time="10:20:12",
            category="mismatch",
            title="Zone Barrier Mismatch Detected",
            details="Token valid for Katunayake Hub scanned at Makumbura MMC Gate 02. Barrier hold enforced.",
            severity="purple"
        ),
        AlertEvent(
            id="alt_04",
            time="10:18:30",
            category="auto-cancel",
            title="Unclaimed EV Bay Auto-Released",
            details="Reservation bk_98f412 for bay EV-02 timed out after 15 min grace period. Slot restored to available.",
            severity="warning"
        )
    ];
}
