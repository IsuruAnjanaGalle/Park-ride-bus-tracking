# Jac Reference Guide for ParkRide Developers

This guide provides a rapid reference on the modern Jaclang language constructs, idioms, and compiler rules utilized across the `parkride` codebase.

---

## 1. Graph Abstractions & Operators

### 1.1 Declaring Nodes & Edges
```jac
node StopNode {
    has id: str;
    has name: str;
    has is_terminal: bool = False;
}

# Every edge MUST declare its endpoints!
edge RoadEdge: StopNode --> StopNode {
    has distance_km: float;
    has current_travel_time_min: float;
}
```

### 1.2 Graph Connection Operators
- **Untyped Connect:** `new_node = root ++> StopNode(id="s1");`
- **Typed Edge Connect:**
  ```jac
  stop_a +>:RoadEdge(distance_km=5.0, current_travel_time_min=10.0):+> stop_b;
  ```
  *(Note: `+>` on both sides of the edge constructor).*

### 1.3 Traversal & Edge Querying
- **All outgoing nodes:** `[here -->]`
- **Typed outgoing traversal (single arrow):**
  ```jac
  connected_stops = [here ->:RoadEdge:->];
  ```
- **Narrowed type query:**
  ```jac
  terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
  ```
- **Accessing Edge Objects & Weights:**
  ```jac
  edges = [edge here ->:RoadEdge:-> target_stop];
  if len(edges) > 0 {
      dist = edges[0].distance_km;
  }
  ```

---

## 2. Walkers & Execution

### 2.1 Anatomy of a Walker
```jac
walker inspect_terminal {
    has terminal_id: str;

    can run with Root entry {
        terminals = [here ->:SystemEdge:-> [?:TerminalNode]];
        for t in terminals {
            if t.id == self.terminal_id {
                report t;
                disengage; # halt walker traversal
            }
        }
    }
}
```

### 2.2 Keyword Rules
- Inside walker abilities (`can ... with ... entry`):
  - `self` refers to the **walker**.
  - `here` refers to the **current node/edge**.
- Flow control:
  - `report <expr>;` appends data to the walker's report list.
  - `disengage;` halts execution immediately.
  - `skip;` skips the current ability and continues traversal queue.

---

## 3. Scoping, Globals & Imports

### 3.1 Module-Level Globals (`glob`)
Module-level variables must be declared with `glob`:
```jac
glob DEFAULT_SECRET: str = "parkride_secret_key_2026";
glob global_clock: SimClock = SimClock();
```

### 3.2 Project Imports
No-dot imports resolve absolute to `jac.toml`:
```jac
import from core.models.nodes { StopNode, TerminalNode }
import from core.lib.clock { get_current_time_iso }
```
*(Note: Brace imports take NO trailing semicolon; plain module imports like `import json;` do).*

### 3.3 Explicit Generic Types
Generic types (`dict`, `list`) require explicit type arguments:
```jac
# Correct
results: list[dict[str, any]] = [];
legs: list[dict[str, float]] = [];

# Incorrect (triggers E1036)
results: dict = {};
```

---

## 4. Testing with Jac

Tests are declared with the first-class `test` block:
```jac
test "parking slot allocation nearest to exit" {
    slots = [
        ParkingSlotNode(id="s1", distance_to_exit_m=50.0),
        ParkingSlotNode(id="s2", distance_to_exit_m=15.0)
    ];
    best = find_best_slot(slots, SlotType.STANDARD, True);
    assert best.id == "s2";
}
```

Run tests from the project directory:
```bash
# Run all tests in verbose mode
jac test -v

# Run specific test file
jac test tests/test_core.jac
```

---

## 5. Common Compiler Diagnostics

| Code | Diagnostic | Resolution |
|---|---|---|
| `E0030` | Unexpected semicolon at module level | Remove trailing semicolon after `import from ... { ... }` or before declarations. |
| `E0005` | Unexpected token at module level | Prefix top-level variables with `glob name = value;`. |
| `E1036` | Generic type requires explicit type arguments | Specify type parameters (e.g., `dict[str, any]`, `list[StopNode]`). |
| `W2003` | Defined but never used | Prefix unused validation variables with `_` or drop assignment (`_ = ...`). |
| `W3005` | Empty parentheses can be removed | Change `def fn() -> str` to `def fn -> str` for zero-arg functions. |
