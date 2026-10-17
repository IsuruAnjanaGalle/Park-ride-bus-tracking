"""Profile walker (contracts.md 3.0): bind the logged-in user to a username and return the role. Status: real."""

import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world }
import from core.lib.profiles { claim_profile }

walker:protect get_profile {
    has username: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        if not self.username {
            report fail("INVALID_INPUT", "username is required.");
            return;
        }
        prof = claim_profile(world, self.username);
        if prof is None {
            report fail("FORBIDDEN", f"{self.username} is bound to another login.");
            return;
        }
        report ok({"username": prof.username, "role": prof.role});
    }
}
