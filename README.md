# Park & Ride Sri Lanka

Park at a Metro bus terminal, book a seat on a live-tracked bus, and board and alight by QR scan. Built in Jac 0.37 (full-stack: walkers + client components).

## Run it

```bash
# Jac 0.37.25 native binary (Linux, macOS, or WSL on Windows)
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash -s -- --version 0.37.25
jac install
jac run --dev main.jac      # http://localhost:8000
```

Routes: `/` passenger, `/admin` admin panel, `/driver/MB-101` driver view, `/dev/core` walker console. Demo logins: `passenger` / `demo-passenger`, `admin` / `demo-admin`.

Accounts live in `docs/data/users.csv` (passwords stored only as salted hashes). Add a user or change a password with `python scripts/add_user.py <username> [passenger|admin]` (asks for the password); list them with `python scripts/add_user.py --list`. The server picks changes up on the next login.

- Spec: `docs/sow.md` (section 0 = today). Walker API: `docs/contracts.md`. Jac syntax: `docs/jac-reference.md`. Decisions: `docs/decisions.md`. Agent rules: `AGENTS.md`.
- Tests: `jac test`. Jac share: `python scripts/jac_share.py`.
- `jac install` fails on the venue Wi-Fi inside WSL? See D-13 in `docs/decisions.md`.
