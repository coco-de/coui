# Alpha observation precision — #6627

Typed Flutter colours already preserve floating `Color.a`; the Native capture
helper discarded it through `toARGB32()`. Real text and Core-colour decoration
witnesses observed actual alpha `.3` but recorded `.302` in four colour slots.
Root opacity was already measured as a continuous double.

The test-side collector now records `_roundAlpha(color.a)` and retains the
existing RGB byte extraction and JSON shape. The pure integer-ARGB normalizer
keeps its legitimate integer-input behaviour. Production CoUI code, Core,
public APIs, design defaults and rendering are unchanged.

The alpha/opacity tolerance intentionally tightens from `.0035` to its original
`.0005`: half the shared three-decimal step `.001`. Distinct canonical
observations remain distinguishable; this is a measurement-criterion correction.
Pixel thresholds `32` / `5%` / `.1%`, px tolerance `.5`, captured files,
profiles, baselines and allowlists are unchanged. No interval, platform/value
heuristic, legacy-byte inference, JSON coercion or expected-style injection was
introduced. An observed `.302` is not assumed to mean an authored `.3`.

Execution used source `b75eb124` plus the frozen patch, later committed unchanged
as `a9a11b1a71251b2923130fe240e33f6dfae49cd3`. No run is relabelled fresh at
that commit. The retained 232-package metadata and lock stayed exact.

- Real Native original8: 6PASS/2FAIL → the same fixture8PASS. RGB, actual raw
  alpha, ARGB6/7/0/255 and continuous-opacity controls are retained.
- Initial current-observation27: original12PASS/15FAIL → candidate26PASS/1FAIL.
  One inherited interval-era expectation incorrectly accepted `.024`/`.025`.
  Its explicit true→false refinement preserves input values and all old evidence.
- Refined27, identical fixture on both sides: Git-original11PASS/16FAIL →
  candidate27PASS; repository port27PASS. The separate legacy21/interval
  diagnostic remains unchanged and is not the current measurement contract.
- Related pure130 assertions passed. Native port8 plus related25 assertions
  passed in a command that still exited1 because a binding suite could not load.
  That load error and the author's premature whole-green summary are preserved
  and corrected. The omitted unchanged binding suite2 then passed with exit0.
  These are not a single35-case exit0 run; external/ported scenarios overlap.
- Final seven-file analysis/format coverage is bound by unchanged source hashes
  plus the final changed-file checks. Earlier setup, lint, asset and test failures
  remain separate artifacts; no ignored diagnostic or expected value bypass.

Actual official Flutter resident helper reload succeeded: code0, two libraries,
6.406s. The same State, render objects, geometry, RGB and actual `.a=.3` stayed
stable while the four recorded colour alphas changed `.302→.3`. Both owned ports
and the Native/CLI processes closed; only the owned clone was replaced.

A separate pure-Dart comparator reload succeeded in `.334s`, preserving PID,
state and inputs: three genuine differences PASS→FAIL; same-alpha, normalization
noise and padding controls PASS→PASS. Its observer retained an imported const
`.0035` after reload; no observer-constant refresh is claimed. Two earlier
harness-assertion failures are retained with this limitation.

Old JSON/capture files retain any already-lost alpha information; the authored
value cannot be recovered from their numeric shape. No historical566 dataset
was recaptured or rejudged for this change, no component improvement is credited,
and no browser operation or UI-site build is claimed. Separate production
CoreTextStyle alpha conversion findings are outside this patch.

`verification.json` binds the source7 and portable proof references under
`weever-alpha-contract-6627-20261124.l83j2cxd`.
