"""Every walker answers with the contract envelope and the documented top-level fields.

With DUMP_SAMPLES=1 the responses are also written to docs/samples/<walker>.json;
scripts/gen_mocks.py turns those into mock/mocks.jac.
"""

import os;
import json;
import from core.lib.world { get_world, reset_world }
import from core.lib.profiles { claim_profile }
import from core.walkers.profile { get_profile }
import from core.walkers.parking { get_terminals, get_slots, recommend_slots, book_slot, mark_parked, release_slot }
import from core.walkers.buses { get_map, get_buses, book_seat, get_trip }
import from core.walkers.scans { process_scan }
import from core.walkers.admin { admin_bus_list, admin_bus_account, admin_next_stop, admin_feed }
import from core.walkers.traffic { set_traffic, report_incident, get_driver_view }
import from core.walkers.demo { demo_control, run_demo, reset_demo }

"""Check the envelope, optionally dump it, and return its data."""
def expect_ok(name: str, rep: list[dict[str, any]], keys: list[str]) -> dict[str, any] {
    assert len(rep) == 1, f"{name}: expected one report, got {len(rep)}";
    env = rep[0];
    assert env["ok"], f"{name}: {env['error']}";
    for k in keys {
        assert k in env["data"], f"{name}: missing {k}";
    }
    if os.environ.get("DUMP_SAMPLES") == "1" {
        os.makedirs("docs/samples", exist_ok=True);
        with open(f"docs/samples/{name}.json", "w", encoding="utf-8") as fh {
            json.dump(env, fh, indent=2, sort_keys=True);
        }
    }
    return env["data"];
}

test "every walker reports its contract shape" {
    reset_world();
    world = get_world();
    assert claim_profile(world, "admin") is not None;

    expect_ok("get_profile", (root spawn get_profile(username="admin")).reports, ["username", "role"]);
    expect_ok("get_terminals", (root spawn get_terminals()).reports, ["terminals"]);
    expect_ok("get_slots", (root spawn get_slots(terminal="MKB")).reports, ["terminal", "slots"]);
    rec = expect_ok(
        "recommend_slots",
        (root spawn recommend_slots(terminal="MKB", vehicle="C", ev="no", arrival="08:00", return_by="10:00")).reports,
        ["zone", "stay_hours", "slot_type", "options", "fallback"]
    );
    slot_code = rec["options"][0]["slot"]["code"];
    pb = expect_ok(
        "book_slot",
        (root spawn book_slot(terminal="MKB", slot_code=slot_code, arrival="08:00", return_by="10:00")).reports,
        ["booking"]
    );
    expect_ok("mark_parked", (root spawn mark_parked(booking_id=pb["booking"]["id"])).reports, ["booking", "slot"]);
    expect_ok("release_slot", (root spawn release_slot(booking_id=pb["booking"]["id"])).reports, ["booking", "slot"]);
    expect_ok("get_map", (root spawn get_map()).reports, ["junctions", "roads", "routes", "bounds"]);
    buses = expect_ok("get_buses", (root spawn get_buses()).reports, ["clock", "buses"]);
    assert len(buses["buses"]) == 9;
    expect_ok("book_seat", (root spawn book_seat(bus_id="MB-102", pickup="KOT", drop="BOR")).reports, ["booking", "seats_left_on_segment"]);
    expect_ok("get_trip", (root spawn get_trip()).reports, ["booking", "bus", "stops", "stops_remaining", "alert", "alert_message", "delay"]);
    expect_ok("admin_bus_list", (root spawn admin_bus_list()).reports, ["clock", "buses"]);
    expect_ok("admin_bus_account", (root spawn admin_bus_account(bus_id="MB-101")).reports, ["bus", "position", "path", "next_stop", "eta_min", "trips_today"]);
    nxt = expect_ok("admin_next_stop", (root spawn admin_next_stop(bus_id="MB-101")).reports, ["bus_id", "stop", "eta_min", "qr", "getting_off", "bookings_to_board", "walk_ins", "seats_left_after"]);
    expect_ok("process_scan", (root spawn process_scan(scan_id="scan-0001", qr=nxt["qr"])).reports, ["result", "message", "scan_id", "booking", "stop", "bus_id"]);
    expect_ok("admin_feed", (root spawn admin_feed()).reports, ["scans", "alerts", "decisions"]);
    expect_ok("demo_control", (root spawn demo_control(action="status")).reports, ["clock", "message"]);
    expect_ok("set_traffic", (root spawn set_traffic(preset="crash")).reports, ["preset", "roads", "decisions"]);
    expect_ok("report_incident", (root spawn report_incident(bus_id="MB-101", kind="accident", severity="closed")).reports, ["incident", "decisions"]);
    expect_ok("get_driver_view", (root spawn get_driver_view(bus_id="MB-101")).reports, ["bus", "instruction", "next_stop", "eta_min", "waiting_at_next", "road", "path", "rerouted", "reroute_reason"]);
    expect_ok("run_demo", (root spawn run_demo(action="status")).reports, ["step", "total", "caption", "playing", "finished"]);
    expect_ok("reset_demo", (root spawn reset_demo()).reports, ["seconds", "counts"]);
}

test "admin walkers refuse a passenger" {
    reset_world();
    world = get_world();
    assert claim_profile(world, "passenger") is not None;
    rep = (root spawn admin_bus_list()).reports;
    assert not rep[0]["ok"];
    assert rep[0]["error"]["code"] == "FORBIDDEN";
}

test "bad input gives an error envelope" {
    reset_world();
    rep = (root spawn get_slots(terminal="XXX")).reports;
    assert rep[0]["error"]["code"] == "NOT_FOUND";
    rep2 = (root spawn recommend_slots(terminal="MKB", vehicle="Z")).reports;
    assert rep2[0]["error"]["code"] == "INVALID_INPUT";
}
