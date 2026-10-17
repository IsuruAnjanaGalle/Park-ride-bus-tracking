# Park & Ride — rules for every coding agent

## 0. How we work today (17 Oct 2026)
- Build only what section 0 of `docs/sow.md` marks **Today**. Data in `docs/data/` wins over any summary.
- Dev A works autonomously: decisions go in `docs/decisions.md`, QA failures are fixed, and milestones are self-merged when `jac check`, `jac test` and CI pass. Stop only for credentials, GitHub permissions or paid services.
- Critical path first; cut any task that is stuck instead of holding up a milestone.

## 1. Rules
- Before coding, read the SOW section for your task in `docs/sow.md` and the walker contracts in `docs/contracts.md`.
- Language is Jac (0.37.25). New logic goes in `.jac`. A `.ts` file is allowed only in `glue/`, under 80 lines.
- Stay in your folders:
  - Dev A: `core/`, `tests/`, `scripts/`, `mock/`, `dev/`, `.github/`, `docs/`, `components/shared/api.jac`, `pages/dev/`
  - Dev B: `pages/` (except `pages/admin/`, `pages/driver/`, `pages/dev/`), `components/passenger/`, `components/shared/CityMap.jac`, `components/shared/ui/`, `glue/`, `i18n/`
  - Dev C: `admin/`, `driver/`, `components/admin/`, `pages/admin/`, `pages/driver/`
- Never change a walker's inputs or outputs without a `contract-change` PR approved by Dev A.
- Screens call the backend only through `components/shared/api.jac` (it spawns walkers with `root spawn`). No fetch or axios.
- Every visible string comes from `i18n/en.json` (English only today).
- Accessibility: real buttons and labels, 44 px touch targets, 4.5:1 contrast, respect reduced motion.
- No Google Maps, no real payments, no secrets or API keys in code.
- Run `jac check` (and `jac build` after touching anything the client imports) and `jac test` before every commit. Commit messages: `feat(P-03): slot grid refresh`, `fix(core): ...`.
- Jac syntax: check `docs/jac-reference.md` or `jac guide <topic>`; do not guess. Jac 0.37 has no `.cl.jac` files — client code is plain `.jac` with JSX, placement is inferred.

## 2. Jac 0.37 traps we already hit
- `walker:priv` = not served at all. Login-only endpoints are `walker:protect`.
- Shared data lives under `root.shared` (the `World` node); every world node type inherits `PublicNode`.
- A plain helper `def` in a module the client imports breaks `jac build` (check still passes). Keep helpers in `core/lib/`.
- Never name a test file `test_*.jac`; use `*_tests.jac`. Tests run serially (`[dev] test_jobs = "0"`).
- `visit`, `node`, `edge`, `walker`, `entry`, `exit` are keywords — not variable names.
- In a filter, `[?:Slot, code == code]` compares the field with itself; name the parameter differently.
- Client polling: `useEffect` from `"react"` with `setInterval` and a cleanup lambda (see reference 6).
