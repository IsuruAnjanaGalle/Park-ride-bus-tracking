"""HMAC-SHA256 signed QR tokens: payload JSON, base64url-encoded, then '.' and the hex signature.

The secret comes from PARKRIDE_QR_SECRET; the fallback is for local demos only.
"""

import os;
import hmac;
import hashlib;
import json;
import base64;

glob DEV_SECRET: str = "parkride-local-demo-only";

def _secret() -> bytes {
    return os.environ.get("PARKRIDE_QR_SECRET", DEV_SECRET).encode("utf-8");
}

def _sign(body: str) -> str {
    return hmac.new(_secret(), body.encode("utf-8"), hashlib.sha256).hexdigest();
}

"""Sign a payload dict into a compact token string."""
def sign_token(payload: dict[str, any]) -> str {
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"));
    body = base64.urlsafe_b64encode(raw.encode("utf-8")).decode("utf-8").rstrip("=");
    return f"{body}.{_sign(body)}";
}

"""Verify a token. Returns {valid, reason, payload}; payload is {} when invalid."""
def verify_token(token: str) -> dict[str, any] {
    parts = token.strip().split(".");
    if len(parts) != 2 {
        return {"valid": False, "reason": "malformed", "payload": {}};
    }
    body = parts[0];
    if not hmac.compare_digest(parts[1], _sign(body)) {
        return {"valid": False, "reason": "bad_signature", "payload": {}};
    }
    try {
        padded = body + "=" * (-len(body) % 4);
        payload = json.loads(base64.urlsafe_b64decode(padded.encode("utf-8")).decode("utf-8"));
    } except Exception {
        return {"valid": False, "reason": "corrupt", "payload": {}};
    }
    return {"valid": True, "reason": "ok", "payload": payload};
}
