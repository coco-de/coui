# Native Ego capture transport — #6587

The explicit [capture CLI](../../../tool/parity/capture_egolite.dart) now uses an existing agent-owned Ego task space/page. At implementation `961170ac1dcf883f5ebeed853a86316afc7fb073`, bounded acceptance A2 captured four canonical cases in **23.710 seconds**, exit **0**: four raw JSON files and five PNGs. This validates the transport boundaries below; the full default834 measurement remains unrun.

The seven changed paths are internal parity tooling and tests. Component implementations, Core/public component APIs, baselines, comparators, normalizers and thresholds are unchanged. Component UI evidence and a docs-site build are **N/A**. Five original diagnostic PNGs are retained outside Git and were viewed by Root; no baseline is promoted.

## Actual coverage

| Canonical light/default case | Actual boundary |
| --- | --- |
| RefreshTrigger | SSR root and raw property probe |
| NumberTicker | Client readiness; settled text `1234` |
| CardImage | One HTTP Image request fulfilled with the existing PNG fixture, then canonical decode readiness |
| Mockup phone | One native stage screenshot, 800×675; the existing Dart crop produces the 320×675 body |

All four used file navigation, actual offline mode and viewport800×1200/DPR1. Every selected role resolved. The body PNG equals stage columns240–559 across all675 rows. Fetch, offline state, remote handles and the entire observed desktop environment were restored in all four; no hard kill occurred. The owned job was reclaimed, and Root retains ownership of finishing the existing task space.

The raw computed-probe script is unchanged (`cbab7e45…c988b`). Existing readiness/context script literals, element-capture body, Dart clipping policy and body-crop math are preserved; shared helper **files** have extraction/addition changes. Real DOM border quads feed the pinned Puppeteer3.25.1 Dart rounding policy. No synthetic Page/ElementHandle or geometry fallback is used.

Six Dart files passed format and fatal-infos analysis;12 pure tests passed. Those receipts are bound by the same six file hashes at961, rather than relabeled as fresh961 runs. The later Node-only metrics correction has syntax exit0 and the fresh A2 execution. Pure tests cover geometry/crop/classification and two owned-process cancellation cases, not browser restoration.

## Preserved failure and recovery

A1 at `7f5bd713a332efa8fd77b0840d583c4510fc474c` exited2 after one attempted case: **0 successful cases**, three unattempted, zero official JSON/PNG. Strict cleanup detected `screen.availHeight`1050→1080. Its provisional worker PNG was reclaimed with scratch and was not retained, salvaged or regenerated.

A separate one-clear recovery restored the whole original observation, including1050. The Node correction clears metrics first, accepts only whole observed equality, and uses an explicit fallback only when necessary. A2 used the clear-first path; the explicit fallback and terminal native-stop paths were not induced live.

## Limits and evidence

Ego reported Chrome156.0.0.0. Historical Chrome150 outputs are not declared transport/raster equivalents. GPU/software mode and the cause of an earlier screenshot color discrepancy remain unknown. Live absent/null roles and arbitrary HTTP non-image requests were not exercised. The image200/PNG/CORS* policy is source-bound plus one successful fulfillment/decode, without a separate cross-origin canvas test. Observed restoration does not reconstruct hidden prior emulation identity.

[verification.json](verification.json) records all seven source SHA256s, raw/PNG hashes, exact cases and portable artifact-relative references. Retained bundle `weever-egolite-capture-boundary-476w4vdq` contains A2 handoff `8eaf0753…ca6f66`, main index `81a62a29…cddece` and32 nested worker artifacts. Independent A2 review `8c97fb7e…bdbf23` found no packet discrepancy; Root's original-image review is `c3e3e345…1fd66`. These are bounded acceptance findings, not an overall pixel/property parity verdict. This documentation task ran no tests, build or browser actions.

## Main integration

Normal integration `b8c1c7b2791ce5ee279d749c8d8666a554e14e70` includes main `705502b2811687829f872f202f17c9e6ff4e1872` (BottomActionBar summaryCompact and Figma Pagination/TextBlock). All seven implementation files remain byte-identical to the actual A2 source961. The capture closure review found no affected input; new upstream variants mean3904/834 must not be called the latest domain. A new full manifest and measurement are still required. The PR itself changes internal tooling and these verification documents only.
