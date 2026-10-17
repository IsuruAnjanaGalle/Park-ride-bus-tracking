"""Login accounts from docs/data/users.csv (docs/decisions.md D-29).

The file lists who may log in (there is no self sign-up, SOW section 0): username, role and
password_hash = "pbkdf2_sha256$<iterations>$<salt hex>$<hash hex>". Plain passwords are never
stored. Add a user or change a password with `python scripts/add_user.py <username> [role]`; this
module only reads the file, and re-reads it whenever it changes, so no restart is needed.

The platform account behind a user is "parkride-<username>-<first 8 salt chars>": a new password
gets a new salt, so the next login creates a fresh platform account with that password.
"""

import os;
import csv;
import hmac;
import hashlib;
import secrets;
import from core.seed.seed { data_dir }

glob USERS_FILE: str = "users.csv";
glob ROLES: list[str] = ["passenger", "admin"];
glob ITERATIONS: int = 200000;  # keep in step with scripts/add_user.py
# [path, file mtime, {username: Account}] of the last read.
glob _CACHE: list[any] = ["", -1.0, {}];

"""One row of users.csv."""
obj Account {
    has username: str,
        role: str,
        password_hash: str;
}

def users_path -> str {
    return os.path.join(data_dir(), USERS_FILE);
}

"""Salted PBKDF2-SHA256 hash in the users.csv format; a new random salt when `salt` is empty."""
def hash_password(password: str, salt: str = "", iterations: int = ITERATIONS) -> str {
    salt_hex = salt if salt else secrets.token_hex(16);
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), bytes.fromhex(salt_hex), iterations);
    return f"pbkdf2_sha256${iterations}${salt_hex}${digest.hex()}";
}

"""True when `password` matches a stored hash (constant-time compare)."""
def check_password(password: str, stored: str) -> bool {
    parts = stored.split("$");
    if len(parts) != 4 or parts[0] != "pbkdf2_sha256" or not parts[1].isdigit() {
        return False;
    }
    try {
        again = hash_password(password, parts[2], int(parts[1]));
    } except ValueError {
        return False;
    }
    return hmac.compare_digest(again, stored);
}

"""Every account in users.csv by username (cached until the file changes)."""
def load_accounts -> dict[str, Account] {
    path = users_path();
    mtime = os.path.getmtime(path) if os.path.exists(path) else 0.0;
    if path == _CACHE[0] and mtime == _CACHE[1] {
        return _CACHE[2];
    }
    accounts: dict[str, Account] = {};
    if os.path.exists(path) {
        with open(path, newline="", encoding="utf-8") as fh {
            for row in csv.DictReader(fh) {
                name = str(row.get("username") or "").strip();
                role = str(row.get("role") or "").strip();
                stored = str(row.get("password_hash") or "").strip();
                if name and role in ROLES and stored {
                    accounts[name] = Account(username=name, role=role, password_hash=stored);
                }
            }
        }
    }
    _CACHE[0] = path;
    _CACHE[1] = mtime;
    _CACHE[2] = accounts;
    return accounts;
}

def find_account(username: str) -> Account | None {
    return load_accounts().get(username);
}

"""The account when username and password match users.csv, else None."""
def check_login(username: str, password: str) -> Account | None {
    acct = find_account(username);
    if acct is None or not check_password(password, acct.password_hash) {
        return None;
    }
    return acct;
}

"""Platform (jacLogin) account name for a users.csv account; changes with every new password."""
def platform_account(acct: Account) -> str {
    parts = acct.password_hash.split("$");
    tag = parts[2][:8] if len(parts) == 4 else "0";
    return f"parkride-{acct.username}-{tag}";
}
