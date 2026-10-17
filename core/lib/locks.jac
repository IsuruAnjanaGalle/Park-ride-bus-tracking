"""One re-entrant lock around every change to the shared world (bookings, scans, traffic)."""

import from threading { RLock }

glob WORLD_LOCK: RLock = RLock();
import threading;

glob WORLD_LOCK: any = threading.RLock();
