#!/usr/bin/env python3
"""
ParkRide CLI and Jac Interop Utility Script.

Provides programmatic interaction with the ParkRide Jac graph, walker triggering,
cryptographic QR token generation, and local testing routines.
"""

import sys
import os
import json
import argparse
import time
import hmac
import hashlib
import base64
from pathlib import Path

DEFAULT_SECRET = "parkride_secret_key_2026"

def generate_qr_token(booking_id: str, vehicle_number: str, terminal_id: str, slot_id: str, valid_hours: float = 24.0, secret: str = DEFAULT_SECRET) -> str:
    """Generates an HMAC-SHA256 signed QR pass token."""
    exp_epoch = time.time() + (valid_hours * 3600.0)
    payload = {
        "booking_id": booking_id,
        "vehicle_number": vehicle_number,
        "terminal_id": terminal_id,
        "slot_id": slot_id,
        "exp": exp_epoch
    }
    payload_str = json.dumps(payload, sort_keys=True)
    payload_b64 = base64.urlsafe_b64encode(payload_str.encode("utf-8")).decode("utf-8")
    sig = hmac.new(secret.encode("utf-8"), payload_b64.encode("utf-8"), hashlib.sha256).hexdigest()
    return f"{payload_b64}.{sig}"

def verify_qr_token(token: str, secret: str = DEFAULT_SECRET) -> dict:
    """Validates an HMAC-SHA256 signed QR pass token."""
    parts = token.strip().split(".")
    if len(parts) != 2:
        return {"valid": False, "reason": "Malformed token structure"}
    
    payload_b64, provided_sig = parts
    expected_sig = hmac.new(secret.encode("utf-8"), payload_b64.encode("utf-8"), hashlib.sha256).hexdigest()
    
    if not hmac.compare_digest(provided_sig, expected_sig):
        return {"valid": False, "reason": "Invalid cryptographic signature"}
    
    try:
        data_bytes = base64.urlsafe_b64decode(payload_b64.encode("utf-8"))
        payload = json.loads(data_bytes.decode("utf-8"))
    except Exception as e:
        return {"valid": False, "reason": f"Corrupt payload: {e}"}
    
    if time.time() > payload.get("exp", 0.0):
        return {"valid": False, "reason": "Pass has expired", "payload": payload}
    
    return {"valid": True, "reason": "Valid pass", "payload": payload}

def inspect_seed_data():
    """Prints a summary of the Western Province seed dataset."""
    seed_dir = Path(__file__).resolve().parent.parent / "core" / "seed" / "data"
    print("==================================================")
    print("       PARKRIDE WESTERN PROVINCE SEED DATA        ")
    print("==================================================")
    for fname in ["stops.json", "roads.json", "buses.json", "slots.json"]:
        fpath = seed_dir / fname
        if fpath.exists():
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
                print(f" - {fname:<12}: {len(data):>3} items loaded")
        else:
            print(f" - {fname:<12}: NOT FOUND")
    print("==================================================")

def main():
    parser = argparse.ArgumentParser(description="ParkRide Jac Interop & Token Utility")
    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    # Command: token
    p_token = subparsers.add_parser("token", help="Generate an HMAC QR pass token")
    p_token.add_argument("--booking-id", default="bk_demo_01", help="Booking identifier")
    p_token.add_argument("--vehicle", default="WP-CAB-4512", help="Vehicle plate number")
    p_token.add_argument("--terminal", default="stop_makumbura", help="Terminal identifier")
    p_token.add_argument("--slot", default="slot_mmc_ev01", help="Slot identifier")
    p_token.add_argument("--hours", type=float, default=24.0, help="Validity duration in hours")

    # Command: verify
    p_verify = subparsers.add_parser("verify", help="Verify a QR pass token")
    p_verify.add_argument("token", help="Token string to verify")

    # Command: data
    subparsers.add_parser("data", help="Inspect seed datasets")

    args = parser.parse_args()

    if args.command == "token":
        t = generate_qr_token(args.booking_id, args.vehicle, args.terminal, args.slot, args.hours)
        print("\nGenerated ParkRide Signed Token:")
        print(t)
        print("\nVerification Preview:")
        print(json.dumps(verify_qr_token(t), indent=2))
    elif args.command == "verify":
        res = verify_qr_token(args.token)
        print(json.dumps(res, indent=2))
    elif args.command == "data":
        inspect_seed_data()
    else:
        inspect_seed_data()
        parser.print_help()

if __name__ == "__main__":
    main()
