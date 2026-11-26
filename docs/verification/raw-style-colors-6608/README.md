# Raw selection and Command panel colors — #6608

Raw `CoreColor` overrides now reach SelectableText selection and Command panel paint. Previously, raw `selectionColor` threw in a token-only class builder; Command omitted raw fill and border color, including transparent borders with a positive width. The fix changes only two Web style implementations: a root-only Tailwind selection rule receives the existing raw serializer value, and Command reuses existing `emitColor` inline output. Token classes, transparent-background no-fill, border geometry, surface variables and the widget's final caller-CSS merge stay intact. Public types, resolver signatures, Core/Native defaults, global helpers, precision and comparison criteria are unchanged.

## Executed checks

The same immutable original SSR fixtures change from 14 pass / 8 fail to 22 pass. They record local renderer exceptions or missing declarations, not observed HTTP server responses. The permanent public regression file passes 21 tests and four existing related files pass 61. These executions overlap in intent; they are not 104 independent scenarios. Touched-file fatal analysis and format exit 0. Twelve whole default/token/transparent-background SSR controls remain byte-identical; this SSR set is distinct from the canonical 12-key matrix.

Actual EgoLite/Chrome156 checks cover 31 public cases and 34 real owners. All five Command raw-color omissions now have the authored computed fill or four-side border color. Three formerly throwing selection cases expose the actual raw `::selection` color. The vendor CSSOM rule is root-only with no descendant wildcard or `!important`; rich descendants inherit the raw tint, and token/raw nested roots keep their own values. Fourteen prior controls retain computed colors, styles, widths and geometry. One raw caller-border inline declaration changes ordering only, so entire observation-object identity is not claimed.

Normal caller selection utilities leave the component's value in these actual controls; class argument order is not a promised cascade priority. The important raw caller class changes 18,85,170 to 42,43,44, and explicit caller-ID selection rules win with 7,8,9. The token important-color control is non-discriminating because primary and tertiary both resolve to 42,43,44. Live CSS checks restore the browser environment and are separate from screenshots/canonical parity.

Fresh Native and Web each derive 56 all / 12 default entries and produce 12 JSON plus 12 PNG. All 48 files match the corresponding historical source-566 originals byte-for-byte; Web also verifies decoded RGBA, whole JSON, roles and layout. These are fresh candidate executions, not reused captures or a claim that the entire upstream Native closure is unchanged. Native dialog L/D retain two structural `no-root-chrome` observations.

| Official scoped report | Key result | Actual exit |
| --- | --- | --- |
| Own baseline pixel | 4 pass / 8 fail; Native 12 pass, Web 4 pass / 8 fail | 1 |
| Cross-platform pixel | 6 pass / 6 fail | 1 |
| Cross-platform property | 4 pass / 6 fail / 2 structural skips | 1 |

All three reports have zero infrastructure failures. Baseline 48 Git blobs match source566, base9424 and candidatebaf7; actual parity matrices equal the selected source-566 full-run results. The before regression command was not rerun. Existing default differences are retained without promotion, waivers, filters or guessed renderer causes. No historical default failure reduction is claimed.

The owned SSR Dart VM actually loads both target style libraries, serves HTTP200 for six public raw/token controls, reports `reloadSources.success=true`, then serves HTTP200 with the same six class/CSS observations. Product/test/helper/lock hashes stay exact; both ports, the PID and jobbox close. This is server VM reload evidence, not browser client or Native app hot reload.

The candidate documentation build exits 0 in 97.971450833 seconds: 361 routes, 363 Jaspr + 2 Flutter HTML, 5,044 output hashes and three representative HTML. All 25,142 tracked entries remain exact. Package232 fields, decoded physical roots, graph and lock match; 19 URI spellings differ, including encoded `+` and trailing slashes. Root's initial literal-URI proof assertion is preserved as a setup correction, not a product/build failure. Automatic root/example Pub preflight is observed; direct worker Pub is zero, not total Pub. Build/port cleanup is verified. Four owned source-test compiler bootstraps were separately archived, checked idle, and removed by exact SHA/mtime; candidate files were untouched.

## Source and limits

Original negatives bind `566b1c55`. Functional checks bind `9424d111` plus the exact three frozen files subsequently committed as `baf7ee47570df22b4d2e55876d28760e09e55273`; fresh canonical capture, additional live SSR controls, docs and owned reload bind that commit. The original22 live bodies retain their earlier explicit SHA binding. The source-566 full Web reference is the retained actual first795 + manual43 dataset, not a new before feature run.

Existing Web alpha serialization remains two decimals. Arbitrary raw Native/Web RGBA identity is not claimed. The raw custom caller fixes do not change default tokens or imply a fresh full-library audit. Historical original fixtures remain unchanged; their retired full-WT absolute imports must not be executed again.

`verification.json` records repository source paths, exact commits and artifact-relative paths with SHA-256 under artifact root `weever-raw-style-original-pqay393r`. Evidence remains identifiable after worktree retirement without relying on machine-only links.
