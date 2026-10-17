"""Simulated Clock utility for deterministic simulation and live time tracking."""

import time;
import from datetime { datetime, timezone, timedelta }

obj SimClock {
    has sim_epoch: float = 1773000000.0;
    has is_simulated: bool = False;

    def now_epoch -> float {
        if self.is_simulated {
            return self.sim_epoch;
        }
        return time.time();
    }

    def now_iso -> str {
        epoch = self.now_epoch();
        # Colombo is UTC+05:30
        tz = timezone(timedelta(hours=5, minutes=30));
        dt = datetime.fromtimestamp(epoch, tz=tz);
        return dt.isoformat();
    }

    def now_hour -> int {
        epoch = self.now_epoch();
        tz = timezone(timedelta(hours=5, minutes=30));
        dt = datetime.fromtimestamp(epoch, tz=tz);
        return dt.hour;
    }

    def advance_minutes(minutes: float) -> str {
        self.sim_epoch += minutes * 60.0;
        self.is_simulated = True;
        return self.now_iso();
    }

    def set_epoch(epoch: float) {
        self.sim_epoch = epoch;
        self.is_simulated = True;
    }

    def reset_to_realtime {
        self.is_simulated = False;
    }
}

glob global_clock: SimClock = SimClock();

def get_current_time_iso -> str {
    return global_clock.now_iso();
}

def get_current_epoch -> float {
    return global_clock.now_epoch();
}

def advance_sim_time(minutes: float) -> str {
    return global_clock.advance_minutes(minutes);
}
