# DescriptionCard: existing title style forwarding (#6345)

`DescriptionCard` now applies the existing `titleTextStyle` setting through
the platform's shared Core text-style adapter. Native previously ignored
the setting. Web forwarded size, weight, tracking and color but omitted
family, leading and an explicit typography token. A caller requesting
17px bold mono text with fixed leading now receives those settings on
both platforms, using the existing Core line-box conversion.

This changes explicitly configured titles. It does not add an API or
change the card's default design, row typography, widget tree or Core
tokens. The supported declarations and internal Resolved fields stay
unchanged. The rejected #6342 generic CSS inheritance candidate and its
private paragraph helpers are absent.

## Source and toolchain

The base is main `d0fcdb80e15b4227e11b1b6ab0c5446f4258731a` (#6352).
The product capture head and the two production blob hashes are recorded
in [the JSON receipt](parity-description-title-2026-11-17.json).
Only the Native and Web DescriptionCard style files change in library
code. Three direct test files and explanatory documentation accompany
them. Package barrels, Core, ThemeConfig, SDK constraints, locks,
Figma emitters, baselines, allowlists and thresholds do not change in
this patch relative to that base.

Verification uses the official Flutter 3.50.0 tag
`ab2912035e160d9cad6306df307576da6128ebdb`, Dart 3.14.0 and
Jaspr 0.24.0-beta.1. The isolated SDK was selected with absolute commands
and per-command PATH. The global FVM default remains 3.47.9. Workspace
dependency resolution used `flutter pub get --no-example --offline
--enforce-lockfile`, without changing a lock. The excluded example is an
independent ignored package with an older lock, not the tested workspace.

Main's SDK/API changes in #6339 and stroke/geometry policy in #6351 are
inherited upstream work; they are not described as changes made by #6345.
The later main `37c6df6aca` (#6353) was also merged. Its two changes are
Figma emitter/self-test files; none intersects the 3,710 capture inputs.
The #6352 captures are reused on that explicit source-equivalence basis.

## Contract preserved

- Native merges the existing size-specific Core title fallback with the
  requested style before `toValue(theme:, color:)`. Existing explicit
  `titleColor` priority remains: titleColor, slot color, default color.
- Web keeps the existing reactive size-role class for unset/scalar
  overrides. Only an explicit token uses the existing `emitTypography`
  helper with the same Core fallback. Scalar fields use `toInlineCss`.
- Web's established slot-color priority over `titleColor` is preserved.
  When an explicit role owns its color, the canonical emitter alone
  supplies its token class or raw inline color. A conflicting titleColor
  is not emitted, so token color is not duplicated as inline CSS.
- The existing Native/Web precedence difference when both color fields
  are set is not silently harmonized. This patch makes no claim that
  every pre-existing cross-platform color policy is identical.
- A separately reproduced `showDivider: false` layout difference is
  tracked in #6355: Web drops a title gap that Native keeps. This title
  style patch preserves that pre-existing behavior; it does not claim
  complete parity for that configuration. Evidence images use the actual
  default `showDivider: true` on both platforms, without image editing.
- Existing Core token replacement, partial-field merge, fixed-vs-ratio
  leading and custom default-role behavior remain in force. No token
  value, font flag, per-entry offset or rendering threshold is introduced.

## Official visual comparisons

The canonical manifest produces 60 DescriptionCard entries: six
registered variants, light/dark and five supported surface styles.
Both platforms were freshly captured before and after the final product
change against the same #6352 base and Flutter 3.50 engine.

| Signal | Before | After |
|---|---:|---:|
| DescriptionCard cross-platform parity |60 pass / 0 fail|60 pass / 0 fail|
| Same-platform before/after exact RGBA |—|120 / 120 identical|
| Before/after property JSON |—|120 / 120 identical|
| Committed own-baseline, Native |10 pass / 50 fail|10 pass / 50 fail|
| Committed own-baseline, Web |0 pass / 60 fail|0 pass / 60 fail|

The committed-baseline report exits 1 for those 110 existing differences;
it is not reported as green. Exact before/after images show that this
patch does not introduce them. No baseline promotion or allowance was
made. [All 60 keys](parity-description-title-2026-11-17.csv) retain their
actual verdicts, dimensions and ratios.

The clean #6352 baseline also received a new full 748-key capture on both
engines, with no retry or missing artifact. All 1,520 PNGs decode, all
1,496 JSON files parse and all 3,710 recorded capture inputs remain
unchanged. The accepted full dataset replaces its 12 default-style
DescriptionCard keys with the new component captures and reuses the
other 736 keys after verifying that the only library input changes are
the two DescriptionCard style files. This is not claimed as a second
new full capture. All 1,520 resulting PNG files and 1,496 property JSONs
are identical to the fresh #6352 baseline. Official full reports were
run on that combined dataset as well.

| Full default-style signal | Fresh main #6352 | Accepted patch |
|---|---:|---:|
| Pixel pass / fail |568 / 180|568 / 180|
| Pixel dimension failures / infra / skip |4 / 0 / 0|4 / 0 / 0|
| Comparable property pass / fail |416 / 274|416 / 274|
| Property stage infra / structural skip |12 / 46|12 / 46|

These reports still exit 1. Four dimension failures remain: Badge status
light/dark (350 vs 351px) and NavigationBar sidebar light/dark (187 vs
188px). A rounded property snapshot value of 187.5 does not prove that
the underlying RenderBox or PNG width is identical.

The preceding #6341 main, `9c624d2eaf`, was separately recaptured on the
same new SDK: 567/181, with all failure keys and all 1,520 RGBA images
equal to the earlier #6344/Flutter 3.47.9 run. Updating from #6341 to
#6352 changes 28 images without changing their sizes and resolves only
`radio-group-default-light-defaultStyle`, with no new failed key. That
one improvement comes from upstream main, not this title-style fix.
[The full 748-key CSV](parity-main-sdk-2026-11-17.csv) records the latest
actual statuses without classifying the remaining 180 as unavoidable
engine differences. #6131 and #6342 remain open.

## Reproduction and receipts

Final verification on the #6352 product source passes Native 83 tests,
Web 8 unit tests and 2 actual Chrome tests (24 token/theme/control and
12 scalar observations). The three new files were then renamed without
content changes to `description_card_style_test.dart` and all 83/8/2
tests were executed again at those final paths in the root checkout.
Eight actual Native/Web token pairs agree on size, weight, primary
family, tracking and rendered line box. Five sizes in light/dark retain
all ten Native default RGBA pairs and all ten Web default DOM/RGBA pairs.

The optimized Jaspr 0.24.0-beta.1 build succeeds for 357/357 routes.
The CLI is isolated in a temporary tool package; global activation was
not changed. Its official embedded-Flutter metadata generation preserves
all four tracked generated files byte-for-byte. Final optimized browser
inspection covers eight configured/default title cases, two registered
default renders and two docs variant transitions, with zero runtime or
console errors. The configured evidence cards are both 420×100 with
the same text, fields and default divider setting.

The owner also runs the final Flutter 3.50 debug fixture, hot reloads
and restarts it, then quits. Process receipts and timings are retained
in the JSON-linked artifact directory; no unrelated running app is used.
The changed Dart files have zero analyzer issues. The broader historical
scoped analysis has the same five pre-existing infos, no new diagnosis;
format checks cover 36 files with zero changes. Design-token phases 1–6,
contract verification and the chrome-passthrough guard pass. Public
export closures and AST declaration/Resolved signatures are unchanged.

Use the recorded SDK on PATH. Canonical CLI commands are:

```sh
dart run tool/parity/manifest.dart --components=description-card --out="$RUN/manifest.json"
# From packages/coui_flutter:
PARITY_MANIFEST="$RUN/manifest.json" PARITY_OUT="$RUN/captured" \
  flutter test --no-pub --concurrency=1 --reporter=json \
  test/parity/flutter_capture_matrix_test.dart
# From the repository root:
dart run tool/parity/capture_web.dart --manifest="$RUN/manifest.json" --out="$RUN/captured"
dart run tool/parity/report.dart --manifest="$RUN/manifest.json" \
  --captured="$RUN/captured" --signal=pixel --mode=parity
dart run tool/parity/report.dart --manifest="$RUN/manifest.json" \
  --captured="$RUN/captured" --signal=pixel --mode=regression
```

The full #6131 manifest is derived from the canonical all-style manifest
by selecting `surfaceStyle == defaultStyle`, retaining all 748 entries
and probes. No failed key or field is pruned. Thresholds remain DPR 1,
5% parity, channel delta 32, 0.1% own regression and dimension mismatch
as failure.

Local raw artifacts and individual process exits are linked by path in
the JSON receipt. Temporary images are not committed. UI evidence is
posted through the repository's `pr-evidence` workflow as private draft
release assets with a three-day TTL. Figma is not an affected axis: no
design default or canvas input changes, and no designer approval or new
deployment is claimed. Full manual CI is not claimed.
