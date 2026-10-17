"""Per-terminal slot cache (docs/decisions.md D-26).

Reading a terminal's 300+ Slot nodes from the store took 1-4 s per request, and get_terminals,
get_slots and recommend_slots all did it. The cache keeps plain SlotView copies per terminal,
keyed by Terminal.rev: every slot state change goes through set_slot_state, which bumps rev
and patches the cached copy, so readers never see a stale state.
"""

import from core.models.nodes { Terminal, Slot }
import from core.lib.world { terminal_slots }

"""Read-only copy of a Slot; field names match the node."""
obj SlotView {
    has code: str,
        terminal: str,
        kind: str,
        zone: str,
        nn: int,
        state: str,
        accessible: bool,
        charger_kw: int,
        charger_type: str,
        sid: str;
}

"""One cached terminal: the Terminal.rev it was built at, its slots, and code -> slot."""
obj SlotCache {
    has rev: int,
        views: list[SlotView],
        by_code: dict[str, SlotView];
}

glob _CACHE: dict[str, SlotCache] = {};

def _view(s: Slot) -> SlotView {
    return SlotView(
        code=s.code, terminal=s.terminal, kind=s.kind, zone=s.zone, nn=s.nn, state=s.state,
        accessible=s.accessible, charger_kw=s.charger_kw, charger_type=s.charger_type, sid=jid(s)
    );
}

def _load(term: Terminal) -> SlotCache {
    key = jid(term);
    hit = _CACHE.get(key);
    if hit is not None and hit.rev == term.rev {
        return hit;
    }
    views = sorted([_view(s) for s in terminal_slots(term)], key=lambda (v: SlotView) { v.code; });
    fresh = SlotCache(rev=term.rev, views=views, by_code={v.code: v for v in views});
    _CACHE[key] = fresh;
    return fresh;
}

"""Every slot of a terminal (cached copies, sorted by code)."""
def slot_views(term: Terminal) -> list[SlotView] {
    return _load(term).views;
}

"""The cached copy of one slot, or None."""
def slot_view(term: Terminal, code: str) -> SlotView | None {
    return _load(term).by_code.get(code);
}

"""The Slot node itself (for writes), or None."""
def slot_node(term: Terminal, code: str) -> Slot | None {
    v = slot_view(term, code);
    if v is None {
        return None;
    }
    s = jobj(v.sid);
    return s if isinstance(s, Slot) else None;
}

"""Change a slot's state: the node, the terminal revision and the cached copy."""
def set_slot_state(term: Terminal, s: Slot, state: str) -> None {
    cached = _load(term);
    s.state = state;
    term.rev = term.rev + 1;
    v = cached.by_code.get(s.code);
    if v is not None {
        v.state = state;
    }
    cached.rev = term.rev;
}

"""Contract shape of a slot (docs/contracts.md get_slots)."""
def slot_row(v: SlotView) -> dict[str, any] {
    return {
        "code": v.code,
        "terminal": v.terminal,
        "type": v.kind,
        "zone": v.zone,
        "nn": v.nn,
        "state": v.state,
        "accessible": v.accessible,
        "charger_kw": v.charger_kw,
        "charger_type": v.charger_type
    };
}
