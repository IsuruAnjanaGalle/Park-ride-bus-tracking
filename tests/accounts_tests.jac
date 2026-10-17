"""Login accounts from docs/data/users.csv: hashing, re-reading the file, verify_login and get_profile (D-29)."""

import os;
import time;
import shutil;
import tempfile;
import from core.lib.world { get_world, reset_world }
import from core.lib.profiles { caller_profile }
import from core.lib.accounts {
    hash_password, check_password, find_account, check_login, platform_account, users_path
}
import from core.walkers.profile { get_profile, verify_login }
import from core.walkers.admin { admin_feed }

def first(rep: list[dict[str, any]]) -> dict[str, any] {
    assert len(rep) == 1, f"expected one report, got {len(rep)}";
    return rep[0];
}

def code_of(env: dict[str, any]) -> str {
    return "" if env["ok"] else env["error"]["code"];
}

test "passwords are salted, hashed and checked" {
    a = hash_password("correct horse");
    b = hash_password("correct horse");
    assert a != b, "each hash gets its own salt";
    assert a.startswith("pbkdf2_sha256$");
    assert check_password("correct horse", a);
    assert not check_password("correct horsE", a);
    assert not check_password("correct horse", "correct horse");
    assert not check_password("x", "pbkdf2_sha256$many$zz$00");
}

test "users.csv holds the demo accounts as hashes only" {
    with open(users_path(), encoding="utf-8") as fh {
        text = fh.read();
    }
    assert text.startswith("username,role,password_hash\n");
    assert "demo-admin" not in text and "demo-passenger" not in text;
    admin = find_account("admin");
    passenger = find_account("passenger");
    assert admin is not None and admin.role == "admin";
    assert passenger is not None and passenger.role == "passenger";
    assert check_login("admin", "demo-admin") is not None;
    assert check_login("passenger", "demo-passenger") is not None;
    assert check_login("admin", "demo-passenger") is None;
    assert check_login("nobody", "demo-admin") is None;
}

"""Write a users.csv the way scripts/add_user.py does, stamped `age` seconds in the future."""
def write_users(folder: str, rows: list[list[str]], age: int) -> None {
    path = os.path.join(folder, "users.csv");
    with open(path, "w", encoding="utf-8") as fh {
        fh.write("username,role,password_hash\n");
        for r in rows {
            fh.write(r[0] + "," + r[1] + "," + hash_password(r[2]) + "\n");
        }
    }
    stamp = time.time() + age;
    os.utime(path, (stamp, stamp));
}

test "a user added to users.csv can log in, and a new password replaces the old one" {
    tmp = tempfile.mkdtemp();
    before = os.environ.get("PARKRIDE_DATA_DIR");
    os.environ["PARKRIDE_DATA_DIR"] = tmp;
    try {
        write_users(tmp, [["kasun", "admin", "first-password"], ["ghost", "driver", "any-password"]], 1);
        acct = check_login("kasun", "first-password");
        assert acct is not None and acct.role == "admin";
        assert find_account("ghost") is None, "rows with an unknown role are ignored";
        old_account = platform_account(acct);
        assert old_account.startswith("parkride-kasun-");

        write_users(tmp, [["kasun", "passenger", "second-password"]], 2);
        assert check_login("kasun", "first-password") is None, "the file is re-read when it changes";
        changed = check_login("kasun", "second-password");
        assert changed is not None and changed.role == "passenger";
        assert platform_account(changed) != old_account, "a new password needs a new platform account";
    } finally {
        if before is None {
            del os.environ["PARKRIDE_DATA_DIR"];
        } else {
            os.environ["PARKRIDE_DATA_DIR"] = before;
        }
        shutil.rmtree(tmp, ignore_errors=True);
    }
    assert find_account("kasun") is None, "the real users.csv is untouched";
}

test "verify_login checks users.csv and names the platform account" {
    bad = first((root spawn verify_login(username="admin", password="nope")).reports);
    assert code_of(bad) == "BAD_LOGIN";
    unknown = first((root spawn verify_login(username="ghost", password="demo-admin")).reports);
    assert code_of(unknown) == "BAD_LOGIN";
    good = first((root spawn verify_login(username="admin", password="demo-admin")).reports);
    assert good["ok"], good["error"];
    assert good["data"]["role"] == "admin";
    admin = find_account("admin");
    assert admin is not None and good["data"]["account"] == platform_account(admin);
}

test "get_profile binds a login only with the users.csv password" {
    reset_world();
    world = get_world();
    assert caller_profile(world) is None;

    no_pw = first((root spawn get_profile(username="admin")).reports);
    assert code_of(no_pw) == "BAD_LOGIN", "an unbound login must send the password";
    wrong = first((root spawn get_profile(username="admin", password="wrong-password")).reports);
    assert code_of(wrong) == "BAD_LOGIN";
    ghost = first((root spawn get_profile(username="ghost", password="demo-admin")).reports);
    assert code_of(ghost) == "BAD_LOGIN";
    assert caller_profile(world) is None;

    admin = first((root spawn get_profile(username="admin", password="demo-admin")).reports);
    assert admin["ok"] and admin["data"]["role"] == "admin";
    again = first((root spawn get_profile(username="admin")).reports);
    assert again["ok"], "a bound login needs no password";
    assert first((root spawn admin_feed(limit=5)).reports)["ok"];

    switched = first((root spawn get_profile(username="passenger", password="demo-passenger")).reports);
    assert switched["ok"] and switched["data"]["role"] == "passenger";
    mine = caller_profile(world);
    assert mine is not None and mine.username == "passenger";
    assert code_of(first((root spawn admin_feed(limit=5)).reports)) == "FORBIDDEN";
}
