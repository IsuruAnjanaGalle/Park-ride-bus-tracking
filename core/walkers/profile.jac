"""Profile walkers (contracts.md 3.0, 3.0a): accounts come from docs/data/users.csv. Status: real."""

import from core.lib.envelope { ok, fail }
import from core.lib.world { get_world }
import from core.lib.profiles { login_profile }
import from core.lib.accounts { check_login, platform_account }

walker:protect get_profile {
    has username: str,
        password: str = "",
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        world = get_world();
        if not self.username {
            report fail("INVALID_INPUT", "username is required.");
            return;
        }
        (code, prof) = login_profile(world, self.username, self.password);
        if code == "BAD_LOGIN" {
            report fail("BAD_LOGIN", "Wrong username or password.");
            return;
        }
        if code or prof is None {
            report fail("FORBIDDEN", f"{self.username} is bound to another login.");
            return;
        }
        report ok({"username": prof.username, "role": prof.role});
    }
}

"""Check a username and password against users.csv before the app signs in to the platform."""
walker:pub verify_login {
    has username: str,
        password: str,
        reports: list[dict[str, any]] = [];

    can run with Root entry {
        acct = check_login(self.username, self.password);
        if acct is None {
            report fail("BAD_LOGIN", "Wrong username or password.");
            return;
        }
        report ok({"username": acct.username, "role": acct.role, "account": platform_account(acct)});
    }
}
