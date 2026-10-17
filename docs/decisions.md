# Decisions log (Dev A)

| # | Date | Decision | Why |
| --- | --- | --- | --- |
| D-01 | 17 Oct | Replaced the nested `parkride/` prototype (different design, different walkers) with a root-level project built from the SOW. Old code is in git history (`7054082`). | Approved by the lead; brief says no nested project. |
| D-02 | 17 Oct | Jac **0.37.25** (native binary, `install.sh --version 0.37.25`), not `pip install jaseci` (PyPI stops at jaclang 0.16). CI installs the same binary. | Only distribution of 0.37. |
| D-03 | 17 Oct | No `.cl.jac` files: `components/shared/api.jac`, `mock/mocks.jac`. `jac start` → `jac run --dev main.jac`. `jac create --use client` → `--kind web-app`. Tailwind via `[client.vite]`, not `[plugins.client.configs]`. | All retired in 0.37. |
| D-04 | 17 Oct | Auth: passenger booking/scan walkers are `walker:protect`; admin walkers are `walker:protect` + a role check on the caller's `Passenger` profile. Read walkers are `walker:pub`. | In 0.37 `:priv` means "not an endpoint". |
| D-05 | 17 Oct | One shared world: a `World` node on `root.shared`; all node types inherit `PublicNode` (`__jac_access__` → WRITE), so every login reads and writes the same graph. Seeded lazily on first call from `docs/data/*.json`. | `:protect` endpoints otherwise run on each user's private root. |
| D-06 | 17 Oct | Identity: `get_profile(username)` binds the caller's root id to a `Passenger` (first claim wins). `api.login()` signs the demo user up on first use, logs in, then calls it. Known limit: a logged-in user could claim an unclaimed username — fine for the demo, not for production. | No server API for the caller's username found in the 0.37 docs. |
| D-07 | 17 Oct | Every walker reports one envelope `{ok, data, error}`; scan outcomes are data, not errors. | One error path for B and C. |
| D-08 | 17 Oct | Mocks are generated from real stub responses (`DUMP_SAMPLES=1 jac test tests/contract_tests.jac` → `docs/samples/` → `python scripts/gen_mocks.py`). | Mocks can never drift from the contract. |
| D-09 | 17 Oct | Tests are `tests/*_tests.jac` and run serially. | `test_*.jac` breaks the runner; tests share the persisted world. |
| D-10 | 17 Oct | Road traffic levels apply to both directions of a road; `get_map` returns 53 undirected roads. | Presets list each road once. |
| D-11 | 17 Oct | Stop QR = signed `{t: "stop", bus, stop, visit, exp}`; parking QR = signed `{t: "parking", id, slot, terminal, return_by}`. Secret from `PARKRIDE_QR_SECRET` (dev fallback for local demos). | SOW 7 and P-08. |
| D-12 | 17 Oct | `process_scan` adds result `already_on_board` (scan at the pickup again with a new scan_id) — the judge script's "Already on board, ignored". `park-ride-domain/references/scan-and-booking-rules.md` was not in the repo; SOW 9.4 is used until it lands. | Missing file. |
| D-13 | 17 Oct | Dev setup on the venue Wi-Fi: inside WSL run `sudo ip link set dev eth0 mtu 1350` (or `wsl -u root ip link set dev eth0 mtu 1350`) if `jac install` fails with IntegrityCheckFailed / "No version matching"; then delete `~/.bun/install/cache/*.npm`. | Large TLS downloads were truncated at MTU 1500. |
| D-14 | 17 Oct | Speed mode (lead, 17 Oct): critical path only; tests only for process_scan, seat counting, auto-cancel/mismatch, plan_route; read-only admin walkers stay stubs for Dev C. | Lead's instruction. |
| D-15 | 17 Oct | Dev C's PR #2 (merged to main on the old `parkride/` tree, `.cl.jac`) is kept as-is in `legacy/dev-c/`, excluded from `jac check` (`[check] exclude`) and the bundle (`.jacignore`). Dev C ports each screen into `admin/`, `driver/`, `components/admin/` as plain `.jac` (0.37 has no `.cl.jac`; `jac fix placement` helps) and deletes the legacy copy. | Keeps Dev C's work without breaking the 0.37 build. |
