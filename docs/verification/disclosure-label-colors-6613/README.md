# DisclosureBadge label colors — #6613

An explicitly authored `labelStyle.color` now wins over the shared foreground in the Web DisclosureBadge. Previously a raw foreground inline declaration masked a token label class on the same text owner. The fix withholds only that competing foreground class/inline fragment when the nested label states a color. The independently painted marker keeps its foreground, and the final caller-CSS merge remains intact. Public constructors/const/copyWith, Resolved shape, resolver signature, Core/Native defaults, widgets, global helpers and comparison criteria are unchanged. Existing anonymous-library/import/class-list lint issues were separately cleaned without changing the emitted layout string.

The final permanent eight-case public SSR fixture was executed against an original Git84df one-file style overlay and against the candidate, while the source WT stayed frozen. The original has **6 pass / 2 fail** (token and token-alpha labels); the identical candidate fixture has **8 pass**. The 22 existing DisclosureBadge tests, touched-file fatal analysis and format pass. Raw/alpha/transparent labels, marker color, no-override foreground/default and final caller CSS are retained controls. Earlier mixed-family 16-case runs and their setup/lint failures remain separate evidence and are not counted as extra independent scenarios.

Root independently observed 32 public CSS cases: original/candidate eight callers × light/dark. The four token/token-alpha observations recover their authored label colors, all 16 paired marker colors stay unchanged, and all 12 control pairs retain their computed values. These are actual managed Ego/Chrome156 computed-color checks, not a hydrated interaction or cross-renderer raster claim. Root's initial comparison-checker serialization mistake is preserved separately from product results.

The proposed Tag change is **held and excluded**. Its arbitrary child can contain an Icon that intentionally inherits `currentColor` on Web; changing its root color could recolor that child while Native changes only DefaultTextStyle. The owned Tag diff was archived then restored exactly to Git84df. No global Icon/Button inheritance policy was changed.

The executed capture/build/reload/report source is **1a555ee1644861c83cf1ca8bb2f6d8b9ed0b7ba1**, integrating main35786c4 after the own code commit da162f8c. Earlier functional tests remain bound to base84df plus the exact frozen two files; they are not relabeled as fresh integrated executions. The source-derived manifest has **24 style entries / 6 default keys**. Native and Web each freshly produce 6 JSON + 6 PNG, with no historical capture reuse. All 24 files, 12 decoded PNG RGBA payloads and 12 JSON role payloads are identical to the corresponding historical source-566 controls. Native has zero no-root observations.

| Existing official report | Key result | Actual exit |
| --- | --- | --- |
| Own-baseline pixel against real Git35786c4 | 0 pass / 6 fail | 1 |
| Native/Web pixel parity | 2 pass / 4 fail | 1 |
| Native/Web property parity | 0 pass / 6 fail | 1 |

All reports have zero infrastructure failures and zero skips. The baseline consists of 24 real Git blobs plus the unchanged allowlist; those blobs also match source566/current1a555. The actual source-566 parity subset has identical key/role verdicts and complete property-difference payloads. No before-regression command was rerun, no baseline was promoted and no existing default failure reduction is claimed.

The actual pinned Jaspr build exits0 in **100.957650167s**: 361 routes, 363 Jaspr + 2 Flutter HTML, 5,044 output hashes and three retained representative HTML files. All 25,145 tracked paths/modes/links remain exact. This run preserves raw config/graph/lock bytes as well as all232 package fields, versions, decoded physical roots and graph edges; URI representation changes are zero. Automatic root/example Flutter Pub preflight is observed; direct worker Pub is zero, which is not a total-Pub-zero claim. Generated output and owned links were reclaimed.

An owned SSR Dart VM loads the actual Disclosure style library, serves HTTP200 with eight public controls, successfully reloads sources, then serves HTTP200 with the same eight class/CSS observations. Entire HTML hashes differ. Source/test/helper/lock bytes remain exact; the PID, VM59621 and HTTP59634 ports close. This is server VM reload evidence, not browser-client or Native-app hot reload.

Original setup failures are preserved: the first existing-test shadow omitted its relative helper, and the first lint cleanup introduced an adjacent-string-list warning before the final class-list form passed. Test-runner bootstraps were confined to owned job shadows. No source, capture probe, normalizer, threshold, allowlist, dependency or default-design workaround was introduced. Existing Web alpha serialization remains unchanged, so custom raw Native/Web RGBA identity is not promised.

`verification.json` records exact source paths and artifact-relative SHA references under `weever-parallel-residual-jjrdof5a/badges`. Subsequent unrelated main integration preserves these executed-source labels and is documented by a separate source-closure receipt.
