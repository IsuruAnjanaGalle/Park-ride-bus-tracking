"""The judge story (run_demo) plays end to end twice, with a reset in between (F-28..F-30)."""

import from core.lib.demo_engine { control, CAPTIONS }

def play_once -> list[dict[str, any]] {
    first = control("restart");
    assert first["step"] == 0;
    last_d: dict = dict(first["last"]);
    assert float(str(last_d.get("reset_seconds", 0))) < 5.0, first["last"];
    lasts: list[dict[str, any]] = [];
    for _ in CAPTIONS {
        nxt = control("next");
        lasts.append(dict(nxt["last"]));
    }
    assert control("status")["finished"];
    return lasts;
}

test "the judge story runs twice in a row" {
    for _ in range(2) {
        s = play_once();
        assert s[0]["zone"] == "F" and s[0]["error"] == "", s[0];
        assert s[1]["state"] == "parked", s[1];
        assert s[2]["error"] == "", s[2];
        assert s[3]["scan"] == "boarded", s[3];
        assert s[4]["scan"] == "duplicate", s[4];
        riders_list: list = list(s[5].get("riders", []));
        assert len(riders_list) == 3, s[5];
        assert s[6]["alert"], s[6];
        path_list: list = list(s[7].get("path", []));
        assert s[7]["rerouted"] and "NAL" in path_list, s[7];
        assert s[8]["scans"] == ["alighted", "alighted", "alighted"], s[8];
        events_list: list = list(s[9].get("events", []));
        assert "mismatch alert" in events_list, s[9];
    }
}
