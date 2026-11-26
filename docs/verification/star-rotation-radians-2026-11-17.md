# Star rotation: adapt documented radians to the SDK degree input

Part of #6131. Base main `45db75a9de944bc9eb8f2311ad81f7e98b628d0c` includes merged #6334 (head89a6320, identical full tree89db220a3f05c0209d173550670ac733915cd344, Release44005458651 succeeded).

The existing public Star/StarRating Dartdoc and the product page specify radians. Web's CoreStarPath uses that value directly in trigonometry. Flutter passed it unchanged into SDK StarBorder, whose constructor accepts degrees. Consequently `starRotation: pi/2` rotated the Native star about1.57degrees rather than90degrees.

The sole production change converts radians to degrees at the SDK constructor boundary. No public constructor, field, function declaration, default, Core token, shape option, callback, export or Web source changes. Existing nonzero inputs now behave as documented; zero/default renders are preserved. There is no offset, shape substitute, crop, font/AA flag, extra wrapper or gate/baseline change.

## Evidence

- Eight public-widget cases cover Star and StarRating at0, pi/2, pi and -pi/4. They sample actual SDK shape paths and verify the points against rotating the unrotated path about its center (float path-metric tolerance0.001logical px; this is not the pixel gate). Exact main source fails6nonzero cases;2zero controls pass. The corrected Native suite passes38tests, including these8. Web's existing direction/DOM suites pass16tests.
- Actual light/dark public Star fixture: zero then pi/2, both explicitly filled, identical64×24 scene. The zero star has exactly0changed pixels; the rotated star changes212pixels in each theme. The current Web reference uses the same two public inputs; its different existing contour is not presented as pixel equality. An initial reference with unspecified state was corrected to explicit filled before accepted evidence.
- A separately launched headless Chrome Flutter debug app uses the actual package and pi/2 input. DTD hot reload succeeded and get_runtime_errors returned “No runtime errors found.” Only that owned app was connected/reloaded; it was quit after verification.
- Analyze of the touched legacy implementation has15existing infos on both exact main and accepted source; diagnostic code/message multisets are identical, net new0. The new test has no issues. No ignores or public-parameter reorder was added to hide the pre-existing infos. Format2files0changes; diff check clean. Public declaration AST SHA256b81ec92ac51ca249cdfbb68fda3129d78137bdabcefdb23dbfa99c69b41a04cd matches main.
- Both engines' catalog8keys were freshly captured before editing; Native8were freshly captured after; unchanged Web was reused. All16platform/probe images have identical dimensions and exact RGBA. Existing cross-platform result remains0pass/8fail; own-baseline16pass. This is the unchanged generated manifest (four represented surface styles after existing pruning), not a new hand-selected denominator.

The last full default748 result remains461pass/287fail from #6330; a new full748 sweep, full CI or deployment is not claimed. Zero/default Star rendering is unchanged; other render/capture inputs are unchanged. Thresholds remain DPR1,5%, regression0.1%, channel delta32, dimensions fail; no baseline promotion.

## Designer reference and remaining contour disagreement

Read-only Figma inspection of [Star source8049:478](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0?node-id=8049-478), specifically filled lg8049:286, shows a24px Lucide star instance with about2px vector inset and1.5px stroke. The current Native StarBorder and Web CoreStarPath are mathematical stars with differing curves/scaling. This existing contour disagreement is not fixed by changing an angle unit, and exact default Figma/profile parity is not claimed. No canvas node was modified. Geometry-option compatibility must be considered separately before replacing that default profile; this PR does not silently replace custom shapes or reinterpret public CoreStarPath.

[Raw measurements and verification facts](star-rotation-radians-2026-11-17.json). Actual before/after/reference screenshots are temporary private PR-evidence assets, not committed baselines.
