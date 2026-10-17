"""The judge story (run_demo) plays end to end twice, with a reset in between (F-28..F-30)."""

import from core.lib.demo_engine { control, CAPTIONS }

def play_once -> list[dict[str, any]] {
    first = control("restart");
    assert first["step"] == 0;
    assert first["last"]["reset_seconds"] < 5.0, first["last"];
    lasts: list[dict[str, any]] = [];
    for _ in CAPTIONS {
        lasts.append(control("next")["last"]);
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
        assert len(s[5]["riders"]) == 3, s[5];
        assert s[6]["alert"], s[6];
        assert s[7]["rerouted"] and "NAL" in s[7]["path"], s[7];
        assert s[8]["scans"] == ["alighted", "alighted", "alighted"], s[8];
        assert "mismatch alert" in s[9]["events"], s[9];
    }
}
