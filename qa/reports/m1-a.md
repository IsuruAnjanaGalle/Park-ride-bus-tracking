# M1 parking — Dev A local check

Run: 17 Oct 2026, Dev A, branch `a/m2-m4-core` merged with `origin/main`, jac 0.37.25, `jac run --dev main.jac` (WSL).
Method: one pass of the /dev/core sequence over the same walkers via HTTP with real logins (`parkride-passenger`, `parkride-admin`); no Playwright (lead's instruction).
Also: `jac check` (whole project) PASS · `jac test` 23/23 PASS · `python scripts/jac_share.py` 93.9 % PASS · routes `/`, `/login`, `/admin`, `/driver/MB-101`, `/dev/core` serve 200.

| Step | Result | Detail |
| --- | --- | --- |
| reset_demo | PASS | 1.05 s, counts {'terminals': 4, 'slots': 850, 'junctions': 34, 'roads': 53, 'routes': 3, 'buses': 9, 'users': 2} |
| get_map | PASS | 34 junctions, 53 roads (0.09 s) |
| get_buses | PASS | 9 buses, clock 08:00:51 (0.3 s) |
| recommend_slots EV | PASS | needs charging -> only E slots ['MKB-E-F-01', 'MKB-E-F-02', 'MKB-E-F-03'] |
| recommend_slots zone | PASS | 2 h stay -> zone F, 3 options |
| book_slot | PASS | PB-0001 MKB-C-F-05, signed QR |
| mark_parked | PASS | MKB-C-F-05 occupied |
| admin walker refuses passenger | PASS | FORBIDDEN |

Overall: **PASS**
