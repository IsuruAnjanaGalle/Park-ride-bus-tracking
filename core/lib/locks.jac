"""One re-entrant lock around every change to the shared world (bookings, scans, traffic)."""

import threading;

glob WORLD_LOCK: any = threading.RLock();
