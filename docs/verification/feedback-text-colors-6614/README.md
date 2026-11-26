# Feedback text color precedence (#6614)

Banner descriptions, Alert titles/descriptions and Toast descriptions now honor an explicitly authored nested `CoreTextStyle.color` ahead of the component foreground or variant fallback. The existing root foreground, icon/action colors, public constructors/resolvers and default design values remain unchanged. Only the three Web style implementations and one public SSR regression file change.

The original unmodified products at `84df6e14` failed 10 of the final 24 public SSR checks. The identical fixture passes all 24 after the fix; 59 existing related Web tests, touched-file analysis and formatting also pass. Root independently observed 24 public CSS cases across light/dark: the explicit token/raw/transparent colors recover, while root/action colors and all six default controls remain unchanged. A preliminary setup error and a corrected test expectation (Toast default opacity is 75%, not 70%) remain in the external evidence.

The actual capture/build source is `2915cc026b58d666681b405afe5c3e0532f745c1`, after the unrelated main integration. The four verified source files remain byte exact. The official manifest derives **170 styles / 34 default keys**. Both platforms were freshly captured; the 34 JSON + 34 PNG files per platform are all byte identical to the corresponding source-566 historical controls. All 68 PNG RGBA payloads and 68 JSON role payloads also match. Historical data was used for comparison, not substituted into the new capture.

| Unmodified official command | Actual exit | PASS | FAIL | Infra / skip |
| --- | --- | --- | --- | --- |
| Pixel regression against real Git base `35786c4fedce` | 1 | 0 | 34 | 0 / 0 |
| Native/Web pixel parity | 1 | 32 | 2 | 0 / 0 |
| Native/Web property parity | 1 | 0 | 34 | 0 / 0 |

The actual historical parity subset has the same key/role verdicts and complete property differences. The remaining pixel failures are `banner-narrow` light/dark. The 34 committed-baseline mismatches and 34 property failures remain visible; this change does not claim to fix those existing comparison differences. No before-regression command was rerun. Baseline inputs are 136 genuine Git blobs plus the unchanged allowlist, not copies of fresh controls.

The actual pinned Jaspr build passed in 100.04s (361 routes, 363 Jaspr HTML files / 365 total HTML files). All 25,145 tracked files/modes/links remain exact after restoring only the known generated client-options preimage. CLI-internal Flutter dependency preflight occurred and rewrote package-config representation; all 232 package identities, declared versions, effective roots, package fields and graph edges remain equivalent, with graph/lock bytes unchanged. The isolated CLI's complete 81-package metadata is retained. Only the output hash manifest and three representative HTML files remain; the generated build was reclaimed.

An owned SSR Dart VM served the three public controls with HTTP200, loaded the three actual style libraries, then reloaded three selectively copied library files after comment-only edits. The reload report records `loadedLibraryCount:3`; the public control attributes remain identical. The whole HTML differs only in an automatic interceptor ID (`0` to `1`). This is an SSR VM reload, not a Native-app or browser-client hot reload. The source worktree was never edited by the reload witness, and all owned ports/processes/jobboxes closed.

Actual browser observations/captures use Root-owned Ego space26, managed Chrome156. Software rasterization and equivalence to the old Chrome150 renderer are not asserted; no color, probe, normalizer, criterion, baseline or allowlist changes were made.

See [verification.json](verification.json) for the exact source hashes, commands, report counts and immutable external evidence references. Verification-only documentation does not change the tested runtime files.
