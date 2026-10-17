"""HMAC Cryptographic signing and verification for ParkRide QR boarding/parking passes."""

import hmac;
import hashlib;
import json;
import base64;
import from core.lib.clock { get_current_epoch }

glob DEFAULT_SECRET: str = "parkride_secret_key_2026";

def generate_qr_token(
    booking_id: str,
    vehicle_number: str,
    terminal_id: str,
    slot_id: str,
    valid_hours: float = 24.0,
    secret: str = DEFAULT_SECRET
) -> str {
    expiry_epoch = get_current_epoch() + (valid_hours * 3600.0);
    payload = {
        "booking_id": booking_id,
        "vehicle_number": vehicle_number,
        "terminal_id": terminal_id,
        "slot_id": slot_id,
        "exp": expiry_epoch
    };
    payload_str = json.dumps(payload, sort_keys=True);
    payload_b64 = base64.urlsafe_b64encode(payload_str.encode("utf-8")).decode("utf-8");
    signature = hmac.new(
        secret.encode("utf-8"),
        payload_b64.encode("utf-8"),
        hashlib.sha256
    ).hexdigest();
    return f"{payload_b64}.{signature}";
}

def verify_qr_token(token: str, secret: str = DEFAULT_SECRET) -> dict[str, any] {
    parts = token.split(".");
    if len(parts) != 2 {
        return {"valid": False, "reason": "Malformed token structure", "payload": None};
    }
    payload_b64 = parts[0];
    provided_sig = parts[1];

    expected_sig = hmac.new(
        secret.encode("utf-8"),
        payload_b64.encode("utf-8"),
        hashlib.sha256
    ).hexdigest();

    if not hmac.compare_digest(provided_sig, expected_sig) {
        return {"valid": False, "reason": "Invalid cryptographic signature", "payload": None};
    }

    try {
        decoded_bytes = base64.urlsafe_b64decode(payload_b64.encode("utf-8"));
        payload = json.loads(decoded_bytes.decode("utf-8"));
    } except Exception {
        return {"valid": False, "reason": "Corrupt payload encoding", "payload": None};
    }

    cur_time = get_current_epoch();
    if cur_time > payload.get("exp", 0.0) {
        return {"valid": False, "reason": "Pass has expired", "payload": payload};
    }

    return {"valid": True, "reason": "Valid pass", "payload": payload};
}
