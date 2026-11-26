# PNG colour interpretation — #6620

The pixel tool subtracted encoded PNG samples without applying embedded ICC
profiles. Equal colours encoded in sRGB and Display P3 could fail, while equal
numeric triplets representing different colours could pass. Supported RGB
matrix/TRC profiles now use common extended sRGB coordinates before comparison.

The generic Dart implementation uses existing dependencies. It selects no
transform by profile name, hash, device, or colour value. Our changes leave CoUI
API/Core/defaults, capture producers, probe/normalizer code, original PNG/profile
bytes, baselines, allowlists, and numerical comparison thresholds untouched.
Colour-space interpretation deliberately changes the measurement calculation.

## Supported boundary

- ICC v2/v4 RGB display/input matrix profiles with XYZ PCS and identity,
  gamma/table curves or parametric TRCs 0–4.
- Source TRC range clipping follows ICC.1:2022. Target coordinates stay floating
  and unbounded; negative and >255 values preserve wide-gamut differences.
- Alpha keeps its original arithmetic. Two unmanaged PNGs keep original sample
  units, including grayscale/palette 1/2/4-bit and 16-bit inputs.
- ICC RGB uses 8-bit coordinates, including decoded indexed palettes. ICC16,
  mixed ICC8/non8-bit pairs, grayscale ICC, LUT/HDR, cICP, and standalone
  gAMA/cHRM transforms are explicit unsupported formats.
- Explicit sRGB overrides lower gAMA/cHRM interpretation. Untagged files retain
  the legacy numeric convention; their physical gamut is unknown.

Active unsupported comparisons use existing infra counts and exit precedence.
Mixed valid/unsupported controls exit 2 and retain other roles/pairs. Existing
mode/property logic still selects comparisons: unused baselines, cross-pairs,
and PNGs in property-only runs cannot create new failures. Schema is unchanged.

## Evidence

The primary execution source is 54417c1 plus the frozen patch. The pruned-CLI
follow-up ran against db52151 plus its two-file patch. Integration into main
4c28 preserves all 14 owned files; older executions are not relabelled fresh.
The external `weever-parallel-residual-jjrdof5a/pixel-cohorts/evidence` task is
bound by the SHA references and source hashes in verification.json.

Refined permanent original 17: 4 PASS/13 FAIL; same-fixture candidate 50: 50 PASS
(17 original, 23 depth/curve/float, 10 CLI cases). Original inactive-mode and
property-only controls: 6 PASS; unmanaged compatibility controls: 8 PASS.
Earlier tool suites: 66 PASS; related post-change suites: 17 PASS, with overlap.
The later pruned caller test reproduces child exit 255, then exit 2 with 3 valid
comparisons and 1 infra after the catch. Its 6 existing unit cases pass.
Touched-file fatal analysis and formatting have no remaining issues.

Independent installed Pillow 11.3.0/LittleCMS 2.17 references preserve floating
PCS and out-of-gamut values without installing packages. Sparse 16-bit tables
use 2/65535 PCS test precision; parametric source clipping has a separate
normative assertion. These are transform-test bounds, not changes to channel
32 or the 5%/0.1% pixel criteria. The 32.18173 control fails and reports max 33.

Initial setup/constructor failures and the 39 PASS/4 FAIL precision run remain.
Two diagnostic bounds changed explicitly from 2 to 3 because the measured green
error 2.075... is conservatively displayed with integer ceil; pass/diff criteria
and input colours did not change. A follow-up runner overwrote initial preflight
bindings; functional logs remain and an exact Git-overlay replay binds the original.

An owned pure-Dart resident VM reloaded the actual old comparator to the frozen
candidate: equal-colour FAIL→PASS, genuinely different wide-gamut PASS→FAIL,
and original Status566 FAIL→PASS (96/144→2/144 differing pixels). PID, state,
input buffers, thresholds and original PNG hashes stayed unchanged. This is
actual tool-library reload evidence; no Flutter/browser/UI reload is claimed.

Integration synchronizes only four workspace release-version graph labels.
Config bytes, 220 external packages, graph edges and lock stay exact; historical
execution metadata stays frozen. No package solve/get or cache copy was needed.
Encoded transition hex values remain source diagnostics, not common coordinates.

Historical metadata showed 524 ICC/326 untagged Web PNGs and 838 sRGB/12 untagged
Native PNGs, all 8-bit (850 RGB Web/850 RGBA Native). This does not explain every
failure or establish untagged gamut. Only the isolated Status pair was rejudged;
there is no full historical rerun, new capture/UI build, or component improvement credit.

Authority: [PNG3](https://www.w3.org/TR/png-3/#11iCCP),
[ICC.1:2022](https://www.color.org/specifications/ICC.1-2022-05.pdf),
[CSS Color4](https://www.w3.org/TR/css-color-4/#color-conversion-code).
