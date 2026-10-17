"""Add a login account, or set a new password, in docs/data/users.csv (docs/decisions.md D-29).

Usage, from the project root:
    python scripts/add_user.py <username> [passenger|admin]
    python scripts/add_user.py --list

The password is asked twice and never echoed; only a salted PBKDF2-SHA256 hash is written, in the
format core/lib/accounts.jac checks. Running it again for an existing username replaces the password
and role. The server re-reads the file on the next login; no restart needed.
"""

import csv
import getpass
import hashlib
import os
import secrets
import sys

FIELDS = ["username", "role", "password_hash"]
ROLES = ["passenger", "admin"]
ITERATIONS = 200_000  # keep in step with core/lib/accounts.jac
MIN_PASSWORD = 8


def users_path():
    data_dir = os.environ.get("PARKRIDE_DATA_DIR", os.path.join(os.getcwd(), "docs", "data"))
    return os.path.join(data_dir, "users.csv")


def hash_password(password):
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), bytes.fromhex(salt), ITERATIONS)
    return f"pbkdf2_sha256${ITERATIONS}${salt}${digest.hex()}"


def read_rows(path):
    if not os.path.exists(path):
        return {}
    with open(path, newline="", encoding="utf-8") as fh:
        return {row["username"]: row for row in csv.DictReader(fh) if row.get("username")}


def write_rows(path, rows):
    tmp = path + ".tmp"
    with open(tmp, "w", newline="", encoding="utf-8") as fh:
        out = csv.DictWriter(fh, fieldnames=FIELDS, lineterminator="\n", extrasaction="ignore")
        out.writeheader()
        for name in sorted(rows):
            out.writerow(rows[name])
    os.replace(tmp, path)


def main(argv):
    path = users_path()
    if argv == ["--list"]:
        for row in read_rows(path).values():
            print(f"{row['username']}\t{row['role']}")
        return 0
    if not 1 <= len(argv) <= 2 or argv[0].startswith("-"):
        print(__doc__.split("\n\n")[1])
        return 2
    username = argv[0]
    role = argv[1] if len(argv) == 2 else "passenger"
    if "," in username or username != username.strip():
        print("Username must not contain commas or surrounding spaces; nothing saved.")
        return 1
    if role not in ROLES:
        print(f"Role must be one of {', '.join(ROLES)}; nothing saved.")
        return 1
    password = getpass.getpass(f"Password for {username} (min {MIN_PASSWORD} characters): ")
    if len(password) < MIN_PASSWORD:
        print(f"Password must be at least {MIN_PASSWORD} characters; nothing saved.")
        return 1
    if getpass.getpass("Repeat password: ") != password:
        print("Passwords do not match; nothing saved.")
        return 1
    rows = read_rows(path)
    existed = username in rows
    rows[username] = {"username": username, "role": role, "password_hash": hash_password(password)}
    write_rows(path, rows)
    print(f"{'Updated' if existed else 'Added'} {username} ({role}) in {path}.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
