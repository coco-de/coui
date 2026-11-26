# Paint observation and capture verification

Part of #6131. This changes parity tooling and tests, not CoUI product libraries,
Core defaults, design tokens, Figma data, examples, supported APIs or dependencies.
No baseline, allowlist, numeric tolerance, pixel threshold or field roster changes.
The remaining parity failures are not waived.

Base is main `6db2278fdd5a8178502207a7bb8b7cd03f29bc7f`. Final Native capture
source is `96a42b5f2d6f99a6986b1c04cadbda28577f215d`. Fresh Web capture source is
`72c83304cfdde2ff76bbb6ba54d4895e26af8bcc`; every product/preview/Web-probe input
remains byte-identical at the final source. The paired artifacts cover all748
default-style keys, including their12 additional stage images. The adjacent
JSON records source hashes and the CSV retains every key, including infra/skip.

## Corrected observations

- Omit exactly zero-alpha shadow layers before color/ARGB rounding. Faint
  positive alpha, layer order, offsets, spread and visible blur remain checked.
- Capture Native blur in CSS-radius units, `2 * shadow.blurSigma`, using the
  actual SDK getter rather than treating `BoxShadow.blurRadius` as CSS radius.
  Core CSS-blur round trips, direct SDK shadows, zero and clamped-small radii
  have separate controls.
- Preserve CSS `inset` and non-normal SDK `BlurStyle` metadata. The comparator
  rejects different placements/masks without changing geometric tolerances.
- Observe raw computed `outlineColor`. An exactly transparent outline paints
  no width; retain its raw offset, which the existing absent-outline comparison
  already handles. Visible and faint outlines still expose wrong widths/offsets.
- Alpha observation supports actual computed Color4 spaces independently of
  RGB conversion. Independent review found that adding outlineColor initially
  made valid P3/OKLCH/out-of-gamut colors fail parsing. The corrected parser
  handles signed/exponent/percentage/missing alpha without rounding a positive
  coefficient into zero. Malformed/unsupported input still reports an error;
  RGB-channel conversion support is not broadened.

Internal capture JSON gains optional outlineColor, inset, blurStyle and the
fresh Native `shadowBlurUnit: css-radius` audit marker. This is an internal
measurement protocol change, not an external CoUI API change. Missing outline
color retains the old style-only interpretation. Missing layer metadata retains
normal/outset semantics. Legacy blur numbers round-trip unchanged; no decoder
migration, baseline rewrite or implicit conversion is performed. The raw unit
marker is not retained by PropertySnapshot's model round trip. Do not mix old
SDK-radius Native data with fresh CSS-radius data to infer a physical regression.
The CLI compares current paired property captures; its own-baseline regression
path reads PNGs, not stored property JSON. Both platforms were captured freshly
for this measurement transition.

## Runtime shadow masks

Independent actual-widget inspection found that the SDK's default automated
test binding sets `debugDisableShadows=true`; BoxShadow.toPaint then removes
its maskFilter. The previous property JSON described a Gaussian that the PNG
capture disabled. This predates the observation patch.

The two capture entrypoints now use an AutomatedTestWidgetsFlutterBinding
subclass with the supported `disableShadows => false` getter. Its painting
invariant remains active and teardown succeeds. Ordinary widget/golden tests
keep their existing binding. There is no global-flag override, image editing,
new padding, font/AA switch or product shadow change. Actual public Card paint
and a subsequent SDK outer-shadow capture exercise the enabled masks.

## Full measurements

| Signal | Main6db | Corrected capture/observation |
|---|---:|---:|
| Pixel parity pass/fail |567 /181|567 /181|
| Pixel dimension failures |4|4|
| Pixel infra/skip |0 /0|0 /0|
| Property comparable pass/fail |350 /340|416 /274|
| Property stage infra/structural skip |12 /46|12 /46|
| Failing fields in690 comparable keys |748|484|

Property66keys improve and0new keys fail. Shadow field failures190→10 and
outline-width/offset42each→0 account for264 corrected field comparisons.
Padding232, radius44, lineHeight64 and all other field results remain unchanged.
These are corrected measurements, not66 newly repaired product screens. The
12stage property infra and46structural skips remain explicit; valid root rows
from infra keys are kept in the CSV but not folded into the690 comparable count.

First, the observation-only change left all1520 Native/Web images RGBA-exact.
Then enabling real SDK masks changed70of760 Native images, with0size changes
and all748 Native JSON files byte-identical. Web760images are unchanged. The
pixel pass/fail status of every key remains unchanged. Existing own-baseline
differences, including the corrected shadow pixels, are retained without any
baseline promotion. Pixel/property reports exit1 because failures remain.

## Validation and limits

- Integrated model/comparator/parser/normalizer/codec tests146pass, including
  actual Chrome Color4 outline observations across72space/alpha combinations.
- Actual Chrome computed-style/shadow/outline probes46pass. Visible wrong blur,
  offset, spread, color, layer order, inset and SDK masks remain negative controls.
- Native snapshot/shadow/binding suites31pass; fresh Native matrix748pass.
  Fresh Web matrix748captures complete, with all declared PNG/JSON present.
- Before/after controls: old Native producer12fail→16pass; old comparator4fail
  among6→6pass; initial Color4 observation19fail→corrected checks pass; default
  SDK binding fails both new mask tests while the capture binding passes them.
- Analysis has0errors/warnings and the same7preexisting infos in the old
  single-Button capture file; new/changed lines add0diagnostics. Format17files,
  0changed. Diff check clean. Product/API/default/baseline/allowlist paths changed0.

Commands were run from the workspace root, except Flutter tests from
`packages/coui_flutter`:

```sh
PARITY_MANIFEST="$RUN/manifest.json" PARITY_OUT="$RUN/app-shadows-captured" \
  flutter test test/parity/flutter_capture_matrix_test.dart --tags parity --concurrency=1 --reporter expanded
dart run tool/parity/capture_web.dart --manifest="$RUN/manifest.json" --out="$RUN/captured"
dart run tool/parity/report.dart --manifest="$RUN/manifest.json" --captured="$RUN/app-shadows-captured" --signal=property --out="$RUN/app-property-diff" --report-json="$RUN/app-property-report.json" --comment-out="$RUN/app-property-comment.md" --vrt-out="$RUN/app-property-vrt.md"
dart test tool/parity/test/web/paint_observation_probe_test.dart tool/parity/test/web/computed_style_probe_test.dart --concurrency=1 --reporter expanded
flutter test test/parity/parity_capture_binding_test.dart test/parity/flutter_property_snapshot_test.dart test/parity/flutter_shadow_observation_test.dart test/theme/shadow_adapter_test.dart --concurrency=1 --reporter expanded
```

`RUN=/tmp/weever-paint-contract-20261117.mowprcg4` contains raw artifacts,
logs, negative controls, all-image deltas and before/after reports. A subsequent
Web-only inheritance candidate is measured separately under #6342 and is not
part of this change. No full manual CI, optimized docs build, deployment,
designer approval or live product-app hot reload is claimed for this tooling-only
batch; fresh widget-test processes verify the capture runtime.
