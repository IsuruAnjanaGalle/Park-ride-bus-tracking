"""The one response envelope every walker reports (docs/contracts.md section 1)."""

def ok(data: dict[str, any]) -> dict[str, any] {
    return {"ok": True, "data": data, "error": None};
}

def fail(code: str, message: str) -> dict[str, any] {
    return {"ok": False, "data": None, "error": {"code": code, "message": message}};
}
