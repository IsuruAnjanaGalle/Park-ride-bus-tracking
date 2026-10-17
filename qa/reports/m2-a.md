# M2 bus journey — Dev A local check

Run: 17 Oct 2026, Dev A, branch `a/m2-m4-core` merged with `origin/main`, jac 0.37.25, `jac run --dev main.jac` (WSL).
Method: one pass of the /dev/core sequence over the same walkers via HTTP with real logins (`parkride-passenger`, `parkride-admin`); no Playwright (lead's instruction).
Also: `jac check` (whole project) PASS · `jac test` 23/23 PASS · `python scripts/jac_share.py` 93.9 % PASS · routes `/`, `/login`, `/admin`, `/driver/MB-101`, `/dev/core` serve 200.

| Step | Result | Detail |
| --- | --- | --- |
| reset_demo | PASS | 1.05 s, counts {'terminals': 4, 'slots': 850, 'junctions': 34, 'roads': 53, 'routes': 3, 'buses': 9, 'users': 2} |
| jump MB-101 to MKB | PASS | MB-101 is at MKB and waits there until depart. |
| book_seat MB-101 MKB->BOR | PASS | BK-0002, seats on segment 39 |
| process_scan board | PASS | Confirmed, you are on board. |
| process_scan same scan_id | PASS | Already counted - this scan was processed before. |
| process_scan alight | PASS | Alighted. Thanks for riding. |
| depart BOR | PASS | MB-101 departed: mismatch alert. |
| auto-cancel | PASS | rider-007's booking BK-0007 cancelled: not scanned at Kottawa. |
| mismatch alert | PASS | Borella: 4 due off, 1 scanned off - missing rider-004, rider-005, rider-006. |
| set_traffic crash -> reroute | PASS | decisions ['Rerouted']; driver: Turn right toward Nawala · 1.8 km / Borella – Rajagiriya closed · only open road / path ['BOR', 'RAJ', 'NAL', 'BAT'] |

Overall: **PASS**

Note: after this run the reroute reason was fixed to name the closed road (Rajagiriya – Battaramulla) rather than the first changed road; routing tests re-run 7/7 PASS.
