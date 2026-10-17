# CLAUDE.md - Developer Guide for ParkRide

This guide outlines essential commands, conventions, and architectural guidelines for engineers and AI assistants working on the `parkride` repository.

---

## 1. Quick Command Reference

All commands should be executed from the `parkride/` directory:

```bash
# 1. Run the ParkRide application
jac run main.jac

# 2. Run the full test suite
jac test tests/test_core.jac

# 3. Type check specific Jac module
jac check core/models/nodes.jac

# 4. Run Python utility script for token generation
python scripts/jac_share.py token --vehicle "WP-CAB-4512"

# 5. Clean compiler build artifacts and cache
jac clean
```

---

## 2. Code Architecture & Layout

```text
parkride/
├── jac.toml                 # Jac project configuration
├── main.jac                 # Main entry point & service bootstrap
├── core/
│   ├── models/              # Graph schema: nodes.jac, edges.jac
│   ├── lib/                 # Core algorithms: dijkstra, allocation, forecast, qr_sign, clock
│   ├── seed/                # Graph initializer & Western Province JSON datasets
│   └── walkers/             # Domain walkers: parking, booking, scans, routing, buses, etc.
├── glue/                    # TypeScript interfaces for Three.js & QR camera scanner
├── i18n/                    # Trilingual catalogs: en.json, si.json, ta.json
├── tests/                   # Test suite: test_core.jac
└── scripts/                 # Python CLI helper: jac_share.py
```

---

## 3. Jaclang Conventions

1. **Endpoint Constraints:** Every `edge` definition must include typed endpoints (`edge E: Src --> Tgt {}`).
2. **Brace Imports:** Never put a semicolon after closing brace in `import from X { Y }`.
3. **Module Globals:** Always declare module-level variables with `glob var_name: type = value;`.
4. **Traversal Arrows:** Use `[src ->:EdgeType:->]` (single arrow) for typed traversal filtering.
5. **No `pass`:** Empty code blocks must use empty braces `{}`.
6. **Explicit Generics:** Never use bare `dict` or `list` in type annotations; use `dict[str, any]`, `list[StopNode]`.

---

## 4. Testing Guidelines

- Tests use the native `test "test name" { ... }` construct.
- Tests should instantiate isolated graph fixtures or seed the test root explicitly.
- Verify both positive and negative cases (e.g. valid QR token vs. tampered/expired token).
