"""QR scan walker (contracts.md 3.11). Status: real - rules in core/lib/journey.jac (SOW 9.4)."""

import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world, junction_names }
import from core.lib.shapes { booking_dict, stop_ref }
import from core.lib.profiles { caller_profile, profile_error }
import from core.lib.journey { scan_rule }
import from core.lib.sim { tick }

walker:protect process_scan {
    has scan_id: str,
        qr: str,
        drop: str = "",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        err = profile_error(world);
        if err {
            report err;
            return;
        }
        if not self.scan_id or not self.qr {
            report fail("INVALID_INPUT", "scan_id and qr are required.");
            return;
        }
        tick(world);
        prof = caller_profile(world);
        if prof is None {
            report fail("NO_PROFILE", "Call get_profile after logging in.");
            return;
        }
        out = scan_rule(world, prof, self.scan_id, self.qr, self.drop);
        names = junction_names(world);
        report ok({
            "result": out["result"],
            "message": out["message"],
            "scan_id": self.scan_id,
            "booking": booking_dict(out["booking"], names) if out["booking"] else None,
            "stop": stop_ref(out["stop"], names) if out["stop"] else None,
            "bus_id": out["bus_id"]
        });
    }
}
