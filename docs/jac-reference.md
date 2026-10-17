# Jac Quick Reference (Park & Ride team)

> Verified with jac 0.37.25 via jac check on 2026-10-17. Every code block below compiled with
> `jac check` (0 errors); server blocks were also run with `jac run` / `jac test`, and the client
> blocks were built with `jac build` in a scratch `web-app` project. Anything not verified is marked **(unverified)**.
> Deeper docs: `jac guide <name>` (e.g. `jac guide jac-walker-patterns`, `jac guide reference/agent-patterns/jac-cl-components --sections`).

## 0. Ground rules

- Every statement ends with `;`, every block is `{ }`. **Exception:** `match`/`case` arms use `:` + indentation.
- Annotate every parameter, return type and `has` field. `True` / `False` / `None` are capitalized.
- Module variables: `glob NAME: T = ...;` (assignable from functions, no `global` keyword).
- `root` is a value (never `root()`); `Root` is its type. `with entry:__main__ { }` = script entry.
- Style lints (warnings, not errors): `def f() -> T` → write `def f -> T` (W3005); drop `-> None` (W3037).

## 1. Nodes, enums, edges

```jac
enum BusStatus: str {          # typed base -> StrEnum; members ARE strings (no .value needed)
    IDLE = "idle",
    EN_ROUTE = "en_route"
}
node Stop {
    has name: str;
    has lat: float = 0.0;      # non-defaulted fields must come before defaulted ones
}
node Bus {
    has plate: str;
    has status: BusStatus = BusStatus.IDLE;
    has seats_free: int = 40;
}
edge Road: Stop --> Stop {     # endpoint types are REQUIRED (bare `edge E {}` is E2086)
    has km: float = 0.0;
    has minutes: int = 0;
}
edge ServesStop: Bus --> Stop { has order: int = 0; }
```

`bus.status == BusStatus.IDLE` and `bus.status == "idle"` are both `True` at runtime.

## 2. Connect, query, delete

```jac
def build_graph -> Stop {
    a = root ++> Stop(name="Kadawatha");      # ++> returns the connected node (not a list)
    b = Stop(name="Kiribathgoda");
    a +>:Road(km=6.5, minutes=12):+> b;       # typed edge: fields go in the constructor parens
    bus = root ++> Bus(plate="NB-1234");
    bus +>:ServesStop(order=1):+> a;
    return a;
}
def queries(a: Stop) {
    nexts: list[Stop] = [a ->:Road:->];          # typed hop infers list[Stop]
    short = [a ->:Road:km < 10.0:->];            # edge-field predicate (edge type MUST be named)
    two_hops = [a ->:Road:-> ->:Road:->];        # multi-hop
    incoming = [a <-:ServesStop:<-];             # reverse direction
    buses = [root -->[?:Bus]];                   # node-type filter
    free = [b for b in buses if b.seats_free > 0];
    km_list = [e.km for e in [edge a ->:Road:->]];   # [edge ...] yields EDGE objects -> read edge fields
    print(nexts, short, two_hops, incoming, free, km_list);
    for (i, s) in enumerate(nexts) { print(i, s.name); }
}
def cleanup(a: Stop, b: Stop) {
    del [edge a ->:Road:-> b];     # delete a TYPED edge: del the edge query
    a del --> b;                   # untyped disconnect (works for plain ++> edges)
    gone = jid(b);                 # capture jid before deleting
    del b;                         # deleting a node cascades to all its edges
    print(gone);
}
```

- Field predicates (edge `[a ->:Road:km < 10.0:->]` or node `[root -->[?:Bus, seats_free > 0]]`) work
  at runtime but **warn W1051** on 0.37.25. A plain comprehension (like `free` above) is warning-free.
- Directions: `[n -->]` out, `[n <--]` in, `[n <-->]` both. No typed bidirectional form.
- Persistent node ids: `jid(node)` (string). Never Python `id()`.

## 3. Walkers

```jac
walker FindRoute {
    has dest: str;
    has path: list[str] = [];
    has reports: list[list[str]] = [];   # typed report channel; the `= []` is REQUIRED
    can start with Root entry {
        visit [-->[?:Stop]];
    }
    can step with Stop entry {           # self = walker, here = current node
        self.path.append(here.name);
        if here.name == self.dest {
            report self.path;
            disengage;                   # stop the whole traversal
        }
        visit [here ->:Road:->];
    }
}
with entry:__main__ {
    res = root spawn FindRoute(dest="Fort");          # kwargs fill `has` fields
    route: list[str] = res.reports[0] if res.reports else [];
    print(route);
}
```

- `visit` is a statement (not `self.visit`); `skip;` ends the current ability only; `report` also prints.
- Spawning on a node runs that node's matching entry too (off-by-one trap); spawn on `root`.
- Inside a **node** ability (`can x with FindRoute entry`) `self` = node, `visitor` = walker.
- A walker that never `visit`s should be a `def:pub`/`def:protect` function instead.

## 4. Visibility / auth / shared data

| Declaration | Endpoint? | Who can call | `root` inside |
|---|---|---|---|
| `def:pub` / `walker:pub` | yes | anyone (no login) | anonymous: guest graph (= `root.shared`); with a token: caller's own root |
| `def:protect` / `walker:protect` | yes | logged-in only (401 otherwise) | caller's own isolated root |
| plain `def` / `walker` (or `:priv`) | **no** | server code only | n/a |

(Syntax below verified by check/build; the runtime auth semantics in this table come from the official guides
and were not exercised against a live multi-user server.)

```jac
def:pub get_stops -> list[Stop] {
    return [root.shared -->[?:Stop]];            # app-wide public data hangs off root.shared
}
def:protect add_bus(plate: str) -> Bus {
    return root ++> Bus(plate=plate);            # per-user data under the caller's root
}
def:pub stats -> dict[str, int] {                # bare `-> dict` is E1036
    return {"stops": len([root.shared -->[?:Stop]])};
}
walker:protect my_buses {
    can run with Root entry { visit [-->[?:Bus]]; }
    can at_bus with Bus entry { report here; }
}
node PublicStop {                                # app-owned public node: open every instance
    has name: str;
    has published: bool = False;
    def __jac_access__ -> AccessLevel | None {
        return AccessLevel.READ if self.published else None;   # None = fall through to grants
    }
}
def:pub seed_public_stop(name: str) -> PublicStop {
    s = root.shared ++> PublicStop(name=name, published=True);
    grant(s, level=AccessLevel.READ);            # per-instance alternative to __jac_access__
    return s;
}
def secret_count -> int {                        # plain def = private helper
    return len([root -->[?:Bus]]);
}
```

(Put plain helpers like `secret_count` in a separate module from client-imported endpoints - see section 5.)

Shared-root rule: nodes created by user A under A's `root` are invisible to user B. Put
app-wide data (stops, routes, live bus positions) under `root.shared` and open it with
`grant(...)` or `__jac_access__`. `AccessLevel`: `NO_ACCESS < READ < CONNECT < WRITE` (ambient).
Outside a server (`jac run`, `jac test`) there is only one root: `jid(root.shared) == jid(root)`
(verified: `True`), so cross-user access can only be tested against a running server.

## 5. Imports

```jac
import json;                                  # module import: takes `;`
import from datetime { datetime }             # brace import: NO trailing `;` (E0030)
import from buses.store { Bus, list_buses }   # server code: no-dot = project-root absolute
```

```jac
import from "react" { useEffect }                         # npm package: quoted string
import from "@jac/runtime" { Link, useNavigate }          # Jac client runtime
import from ..buses.store { Bus, BusStatus, list_buses }  # client: dotted, relative to THIS file
import from ..components.BusCard { BusCard }              # (each leading dot = one folder up from file dir)
import "./assets/main.css";                               # CSS side-effect import (in main.jac)
```

- From `pages/index.jac`, `..buses.store` = `<root>/buses/store.jac`; from `pages/buses/[id].jac` it is `...buses.store`.
- A no-dot import (`import from buses.store {...}`) also passed `jac check` **and** `jac build` in a client page.
- Importing a plain (private) def into client code fails: `E5082 ... has no client-side presence`.
- **Build gotcha (passes `jac check`, fails `jac build`):** adding a plain `def secret_count` (reading
  `root`) to `buses/store.jac` made the client build fail with `runtime import(s) list_buses are not
  exported by buses/store.jac`, even though `list_buses` is `def:pub`. Fix that worked: keep private
  helpers in a separate server module (`buses/helpers.jac`) and import them into the endpoint module.
  Run `jac build` (not just `jac check`) after touching modules the client imports.
- Always import node/obj TYPES alongside the functions that return them.

## 6. Client components

```jac
import from ..buses.store { Bus, BusStatus }
def:pub BusCard(bus: Bus, onBook: Callable[[str], None]) -> JsxElement {
    def handle_book(_e: MouseEvent) {        # `_` prefix silences W2003 for unused params
        onBook(bus.plate);
    }
    <div className="rounded-xl border p-4 flex justify-between">
        <span className="font-semibold">{bus.plate}</span>
        {if bus.status == BusStatus.EN_ROUTE {
            <span className="text-green-600">On the way</span>
        } else {
            <span className="text-gray-500">Idle</span>
        }}
        <button onClick={handle_book}>Book</button>
    </div>
}
```

Page with state, mount fetch, 2-second polling with cleanup, list rendering, conditional rendering:

```jac
import from "react" { useEffect }
import from "@jac/runtime" { useNavigate }
import from ..buses.store { Bus, list_buses, book_trip }
import from ..components.BusCard { BusCard }
def:pub HomePage -> JsxPage {
    has buses: list[Bus] = [];               # reactive state: assign by bare name to re-render
    has loading: bool = True;
    has error: str = "";
    nav = useNavigate();                     # hooks + has BEFORE any conditional return
    async def refresh {
        try {
            buses = await list_buses();      # ALWAYS await server calls
        } except Exception as e {
            error = str(e);
        }
        loading = False;
    }
    useEffect(lambda {                       # manual useEffect = acquire + release in ONE closure
        refresh();
        timer = setInterval(lambda { refresh(); }, 2000);
        return lambda { clearInterval(timer); };
    }, []);
    async def handle_book(plate: str) {
        _ = await book_trip(plate);
        nav("/dashboard");
    }
    <section className="space-y-3">
        <h1 className="text-2xl font-bold">Live buses</h1>
        {if loading {
            <p>Loading...</p>
            skip;                            # ends this slot only
        }}
        {error and <p className="text-red-600">{error}</p>}
        {if len(buses) == 0 {
            <p>No buses yet.</p>
        }}
        {for b in buses {
            <BusCard key={jid(b)} bus={b} onBook={handle_book} />
        }}
    </section>
}
```

Effect forms (all compile): `can with entry { }` (mount), `async can with entry { }` (async mount),
`async can with [dep] entry { }` (re-run when `dep` changes). **Do not** create an interval in
`can with entry` and clear it in `can with exit` - they are separate closures; use `useEffect` as above.

- Lambdas: `lambda (e: ChangeEvent) { name = e.target.value; }`, zero-arg `lambda { refresh(); }`.
- Events: `MouseEvent`, `ChangeEvent`, `FormEvent` (`e.preventDefault()`), `KeyboardEvent` - ambient, no import.
- Never mutate state in place (`buses.append(x)` won't re-render) - rebind: `buses = buses + [x];`.
- No `.map()`: use `{for x in xs { <li key={...}>...</li> }}`. Ternary: `{A if cond else B}`. `style={{"color": "red"}}`.
- Optional child component prop: `children: any = None`.

## 7. Calling the server from the client

```jac
import from buses.store { Trip, MyTrips }
def:pub Dashboard -> JsxPage {
    has trips: list[Trip] = [];
    async can with entry {
        result = root spawn MyTrips();       # walker: kwargs only, read result.reports
        trips = result.reports;              # typed via `has reports: list[Trip] = [];`
    }
    <ul>
        {for (i, t) in enumerate(trips) {
            <li key={str(i)}>{t.plate}</li>
        }}
    </ul>
}
```

Function endpoints: `buses = await list_buses();`, `bus = await get_bus(bus_id);` (positional or kwargs).
Reads are cached client-side for 60 s; any write call invalidates the cache.

## 8. File-based routing

```
main.jac                 import "./assets/main.css";  + the `app` below
pages/layout.jac         -> JsxLayout, renders <Outlet />  (wraps all pages)
pages/index.jac          /            (export returning JsxPage; name is free)
pages/login.jac          /login
pages/buses/[id].jac     /buses/:id
pages/(auth)/dashboard.jac  /dashboard  - (auth) group = automatic AuthGuard, adds no URL segment
```

`main.jac` MUST be `def:pub app(children: any) -> JsxElement { <>{children}</> }` (W1037 on `any` is expected);
a no-arg `app()` silently drops every route.

```jac
import from "@jac/runtime" { Outlet, Link, useNavigate, jacLogout, jacIsLoggedIn }
def:pub Shell -> JsxLayout {
    nav = useNavigate();
    def handle_logout(_e: MouseEvent) {
        jacLogout();                         # sync - never await
        nav("/login");
    }
    <div className="min-h-screen">
        <nav className="flex gap-4 p-4">
            <Link to="/">Buses</Link>
            <Link to="/dashboard">My trips</Link>
            {jacIsLoggedIn() and <button onClick={handle_logout}>Logout</button>}
        </nav>
        <main className="p-4"><Outlet /></main>
    </div>
}
```

```jac
import from "@jac/runtime" { Link, useParams }
import from ...buses.store { Bus, get_bus }
def:pub BusDetail -> JsxPage {
    has bus: Bus | None = None;
    params = useParams();
    bus_id = params["id"];                   # subscript only; params.id is E1030
    async can with [bus_id] entry {
        if bus_id { bus = await get_bus(bus_id); }
    }
    if not bus_id { return <p>Not found</p>; }   # truthy check (catches JS undefined)
    <div>
        <Link to="/">Back</Link>
        {bus and <h1>{bus.plate}</h1>}
    </div>
}
```

- Use `<Link to=...>` for in-app links and `nav("/x")` in handlers (verified). `nav(-1)` and
  `<Navigate to="/login" replace={True} />` come from the guides **(unverified)**.
- Do not put a `layout.jac` inside `(auth)/` (collides with root layout / redirect loop).
- Unauthenticated redirect target: `[client.routing] auth_redirect = "/login"` in jac.toml.

## 9. Client auth

```jac
import from "@jac/runtime" { SignupResult, jacLogin, jacSignup, useNavigate }
def:pub LoginPage -> JsxPage {
    has email: str = "";
    has password: str = "";
    has msg: str = "";
    nav = useNavigate();
    async def do_login(e: FormEvent) {
        e.preventDefault();
        ok: bool = False;                    # pre-declare vars that hold await results
        ok = await jacLogin(email, password);    # async -> bool
        if ok { nav("/dashboard"); } else { msg = "Invalid credentials"; }
    }
    async def do_signup(_e: MouseEvent) {
        res: SignupResult | None = None;
        ok: bool = False;
        res = await jacSignup(email, password);  # async -> SignupResult; does NOT log in
        if res is None or not res.success { msg = "Signup failed"; return; }
        ok = await jacLogin(email, password);
        if ok { nav("/dashboard"); }
    }
    <form onSubmit={do_login} className="flex flex-col gap-2 max-w-sm">
        <input value={email} onChange={lambda (e: ChangeEvent) { email = e.target.value; }} />
        <input type="password" value={password} onChange={lambda (e: ChangeEvent) { password = e.target.value; }} />
        <button type="submit">Log in</button>
        <button type="button" onClick={do_signup}>Sign up</button>
        {msg and <p>{msg}</p>}
    </form>
}
```

`jacLogout()` / `jacIsLoggedIn()` are sync. Prefer the `pages/(auth)/` group to manual guards.
Manual alternative: `<AuthGuard redirect="/login"><Outlet /></AuthGuard>` from `@jac/runtime` **(unverified)**.

## 10. Tailwind v4

```toml
# jac.toml
[dependencies.npm.dev]
tailwindcss = "^4.1.0"
"@tailwindcss/vite" = "^4.1.0"
[client.vite]
plugins = ["tailwindcss()"]
lib_imports = ["import tailwindcss from '@tailwindcss/vite'"]
[client.routing]
auth_redirect = "/login"
```

`assets/main.css` contains just `@import "tailwindcss";` and `main.jac` does `import "./assets/main.css";`.
No `tailwind.config.js`; no `* { margin:0 }` reset (breaks Preflight). Add packages with
`jac install --npm --dev tailwindcss @tailwindcss/vite` or edit jac.toml then `jac install`.

## 11. Tests

```jac
import from buses.store { Bus, list_buses, MyTrips, Trip }
test "list buses sees shared root" {
    b = root.shared ++> Bus(plate="T-1");
    assert b in list_buses();
}
test "my trips walker" {
    root ++> Trip(plate="T-2");
    res = root spawn MyTrips();
    assert len(res.reports) >= 1;
}
def divide(x: int, y: int) -> float { return x / y; }
test "divide by zero raises" {
    with testraises(ZeroDivisionError) {     # ambient, no import
        divide(1, 0);
    }
}
```

- Run: `jac test file.jac`, `jac test -d tests/`, `jac test file.jac -t "name"`.
- **Never name a file `test_*.jac`** (collides with Python's test import machinery). Use `store_tests.jac`
  or an annex `store.test.jac` next to `store.jac` (run with `jac test store.jac`).
- Tests run **in parallel isolated workers, in no fixed order**: each test builds its own data. Data on
  `root` persists in `.jac/data` between runs, so assert on what the test created (`assert b in ...`), not
  on global counts. Serial: `JAC_TEST_JOBS=0 jac test ...`.

## 12. Pitfalls (each verified to produce the listed diagnostic)

| Wrong | Error | Right |
|---|---|---|
| `import from math { sqrt };` | E0030 | `import from math { sqrt }` |
| `lambda x: x + 1` | E0022 | `lambda (x: int) { x + 1; }` |
| `return false;` | E1002 (+ W2001 'false') | `return False;` |
| `def f { pass; }` | E0010 | `def f {}` |
| `for k, v in d.items() {` | E0001 | `for (k, v) in d.items() {` |
| `case 0 { ... }` | E0001 | `case 0:` + indented body |
| `n = int(s);` (unused) / `except ValueError as e` (unused) | W2003 | `_ = int(s);` / `except ValueError {` |
| `def f(visit: int)` | E0013 | rename, or escape: `` `visit `` |
| `def:pub f -> dict` | E1036 | `-> dict[str, int]` / `dict[str, any]` |
| `root() ++> A();` | E0049 | `root ++> A();` |
| `edge E {}` | E2086 | `edge E: Src --> Dst {}` |
| `cond ? a : b` | E0002 | `a if cond else b` |
| client imports a plain `def` | E5082 | make it `def:pub` / `def:protect` |

Also: `&&`/`||` don't exist (`and`/`or`/`not`); use `str(e)` when concatenating exceptions; Python
stdlib needs explicit import (`import from datetime { datetime }`); client server-calls must be `await`ed.

## 13. Known `jac check` noise on 0.37.25 client files (safe to ignore)

Even the minimal Counter component produces these warnings; `jac check` still passes and `jac build` succeeds:
- `W2001 Name 'div'/'button'/'p' may be undefined` on JSX tags.
- `W2003 'setCount' is defined but never used` for every component `has` field.
- `W1051 Expression type could not be resolved` on `useNavigate()` / `useParams()` results.
Treat **errors** (`✖ error[...]`) as blocking; review warnings outside this list.
