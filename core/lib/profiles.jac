"""Who is calling: binds a login (the caller's own root) to a Passenger profile and role.

Authenticated (:protect) endpoints run on the caller's own root, so jid(root) identifies
the caller. get_profile binds that root to a username once; later calls find it by root id.
"""

import from core.models.nodes { World, Passenger }
import from core.lib.envelope { fail }
import from core.lib.accounts { find_account, check_password }

"""The id of the caller's own root (stable per login)."""
def caller_root_id -> str {
    return jid(root);
}

"""The caller's profile, or None if this login has not called get_profile yet."""
def caller_profile(world: World) -> Passenger | None {
    rid = caller_root_id();
    found = [world -->[?:Passenger, root_id == rid]];
    return found[0] if found else None;
}

"""Bind the caller to `username` (first claim wins) and return the profile."""
def claim_profile(world: World, name: str) -> Passenger | None {
    rid = caller_root_id();
    mine = [world -->[?:Passenger, root_id == rid]];
    if mine {
        return mine[0] if mine[0].username == name else None;
    }
    named = [world -->[?:Passenger, username == name]];
    if named {
        prof = named[0];
        if prof.root_id and prof.root_id != rid {
            return None;
        }
        prof.root_id = rid;
        return prof;
    }
    fresh = Passenger(username=name, role="passenger", root_id=rid);
    world ++> fresh;
    return fresh;
}

"""Bind the caller to `name` even if another login holds it (the password was checked)."""
def bind_profile(world: World, name: str) -> Passenger {
    rid = caller_root_id();
    for other in [world -->[?:Passenger, root_id == rid]] {
        if other.username != name {
            other.root_id = "";
        }
    }
    named = [world -->[?:Passenger, username == name]];
    if named {
        prof = named[0];
        prof.root_id = rid;
        return prof;
    }
    fresh = Passenger(username=name, role="passenger", root_id=rid);
    world ++> fresh;
    return fresh;
}

"""get_profile's rule (docs/decisions.md D-29): `name` must be in users.csv. A login without a
profile, or any call that sends a password, needs the right password; the right password also moves
the profile to this login. The role always follows users.csv.
Returns (error_code, profile); error_code is "" on success, else BAD_LOGIN or FORBIDDEN."""
def login_profile(world: World, name: str, password: str) -> tuple[str, any] {
    acct = find_account(name);
    if acct is None {
        return ("BAD_LOGIN", None);
    }
    prof: Passenger | None = None;
    if password or caller_profile(world) is None {
        if not check_password(password, acct.password_hash) {
            return ("BAD_LOGIN", None);
        }
        prof = bind_profile(world, name);
    } else {
        prof = claim_profile(world, name);
    }
    if prof is None {
        return ("FORBIDDEN", None);
    }
    if prof.role != acct.role {
        prof.role = acct.role;
    }
    return ("", prof);
}

"""None when the caller is an admin, else the FORBIDDEN envelope to report."""
def admin_error(world: World) -> dict[str, any] | None {
    prof = caller_profile(world);
    if prof is None or prof.role != "admin" {
        return fail("FORBIDDEN", "Admin login required.");
    }
    return None;
}

"""None when the caller has a profile, else the NO_PROFILE envelope to report."""
def profile_error(world: World) -> dict[str, any] | None {
    if caller_profile(world) is None {
        return fail("NO_PROFILE", "Call get_profile after logging in.");
    }
    return None;
}
