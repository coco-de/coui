# Patterned borders: OutlinedContainer, FileInput, empty ColorPicker

Base: `57d5196c49978134b8f1ba4d5351d381f07542f4` (2026-11-17 KST). Part of #6131.

#6318 was already squash-merged at `57bd843314a31e6b254ee44cbf120a51822e2079` when this follow-up began. Its verified head was `ff923b2cd32f9e821021e63002747aef9ba7f67b`. The full trees differ because main also contains #6325's Accordion/Alert/ColorPicker changes and releases; they are not claimed equal. Frame and the Web dashed-overlay implementation from #6318 are unchanged. Release runs 43857902950 / 43858646021 and Deploy 43858654527 succeeded.

## Change and existing design contract

- OutlinedContainer's private painter previously put half the stroke outside its box, started its dash sequence at the `addRRect` origin and drew dotted capsules. It now deflates the outer rounded rectangle by half the stroke, starts at the top-left tangent clockwise and draws circular dots every twice the stroke width.
- FileInput and the empty ColorPicker swatch previously inset the rectangle without reducing its radius. Their private painters now interpret the existing radius as the outside radius, matching solid Flutter borders and the existing Web SVG. FileInput's drag-over solid border uses the same corrected contour.
- Straight dashes use the line primitive; corner-crossing and full-contour spans retain path extraction, as in the already-merged Frame fix. Per-corner radii are retained and scaled to the available rectangle.

Core values/defaults, themes, resolvers, public constructors/fields/method signatures, exports, Web implementation and Figma data did not change. No new utility API was added. The three declaration comparisons against base pass after removing function bodies and private top-level declarations. Nine existing source lint infos and four existing FileInput test infos were also removed with equivalent syntax/defaults; no ignore was added and no hook was disabled.

No capture mask, offset, scaling, font substitution, AA flag, threshold change, allowlist or baseline promotion was used. Actual captures remain DPR 1. The 4x raster zoom in the unit tests only checks stroke containment and dot shape.

## Measurements

Both platforms were freshly captured on the base before edits. After the final source edits, Flutter was freshly captured again. Web after-results reuse the fresh base Web captures because all Web/Core/preview/capture code is unchanged. Additional public-widget light/dark fixtures were independently rendered in Chrome.

| Scope | Before | After | New failed keys |
|---|---:|---:|---:|
| Default, 748 keys | 461 pass / 287 fail | 461 pass / 287 fail | 0 |
| Related styles, 152 keys | 43 pass / 109 fail | 43 pass / 109 fail | 0 |

The related set is Button 90, Frame 32, OutlinedContainer 10, FileInput 10 and ColorPicker 10. Only eight FileInput Flutter images change (default/NeoBrutalism/claymorphism/neumorphism, both themes); zero Web images change. The default set changes only the two FileInput images. Their existing Flutter/Web size mismatches remain. Default OutlinedContainer is solid and default ColorPicker is filled, so those examples do not exercise the repaired opt-in states. Diagnostic fixtures are not added to the denominator, and their whitespace is not used to declare pixel parity.

Same-platform committed-baseline results: 1,361 pass / 135 differences / 24 first-capture stage probes. Two additional differences are the intentional FileInput border corrections; no baseline was promoted. Related before/after comparisons are 296 pass / 8 changed platform-probe images. The thresholds remain 5% cross-platform, 0.1% regression, channel delta >32; any dimension mismatch fails.

All 748 raw Flutter property JSON files are unchanged. Property reporting remains 300 pass / 390 fail / 12 infra / 46 skipped. These property limitations are not pixel infra: the pixel matrix has zero infra/skip. This is not a global parity pass.

## Validation and limits

- `flutter test --no-pub test/components/patterned_border_contract_test.dart`: 9 pass. On unmodified main, 7 fail: six contour/containment/dot checks and the drag-over radius check. The two already-correct containment checks also pass on main.
- Contract, FileInput, ColorPicker, OutlinedContainer, transparent-border, chrome-curve and geometry-transport suites together: 100 pass. The FileInput recording test still requires more than four dashes, counting both line and curved-path primitives.
- `dart test tool/parity/test/web/dashed_overlay_geometry_test.dart`: 6 pass, covering actual SVG radii under surface recipes and a live radius-variable override.
- Public-widget diagnostic light/dark captures: 2 pass before, 2 after. Chrome reads four actual SVG borders per theme with rx=15px and stroke=2px for outer radius=16 and width=2; dotted dasharray=0px,4px. The FileInput content width and empty ColorPicker layout still differ between platforms. These fixtures establish geometry and expose remaining layout differences; they do not assert full-scene parity.
- `dart analyze --fatal-infos` on all five changed Dart files: no issues. `dart format --set-exit-if-changed --output=none` on the same files: 0 changed. `git diff --check`: clean.
- The existing macOS OutlinedContainer golden test is **not green**: base already fails against its committed image by 255 pixels (0.57%); this branch fails by 1,410 pixels (3.13%). Actual base-to-branch change is 1,155 pixels, confined to the dashed/dotted scenarios and the old stroke's spill at their edges. Solid and elevated content regions have zero changed pixels. No golden image was updated or test disabled. This known result remains visible in the PR.
- No Web build is required for this Flutter-only source change under `pr-evidence`; no new release/hydrated interaction test, full CI, deployment or designer approval is claimed. Current main's nightly run 43924421830 failed on one Web font-readiness timeout before Flutter/comparison, so it is not a completed fresh full-matrix verdict.

The global 287 default mismatches and 15 remaining Frame style keys remain open in #6131. This batch fixes genuine private renderer defects without reclassifying those residuals.

[Source hashes and summary](parity-patterned-borders-2026-11-17.json) · [All default rows](parity-patterned-borders-2026-11-17-default.csv) · [Related rows](parity-patterned-borders-2026-11-17-related.csv).
