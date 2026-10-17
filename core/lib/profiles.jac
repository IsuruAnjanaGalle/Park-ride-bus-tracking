"""Who is calling: binds a login (the caller's own root) to a Passenger profile and role.

Authenticated (:protect) endpoints run on the caller's own root, so jid(root) identifies
the caller. get_profile binds that root to a username once; later calls find it by root id.
"""

import from core.models.nodes { World, Passenger }
import from core.lib.envelope { fail }

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
