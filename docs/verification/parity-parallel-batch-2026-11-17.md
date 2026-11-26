# Parallel parity batch — 2026-11-17

Part of #6131. Three isolated writer worktrees implemented typography compatibility, primitive motion, and component layout; the lead integrated and cross-reviewed them. The original provider session was read-only. PR #6343.

Baseline main `8d1831f8e462c77da20aa49c665f6fda25a909c9` includes designer-owned warning background change #6340 and its baselines. That upstream change is outside this PR's diff. Final render source is `a571ec9d05bce5f65dee6724d940be7c457db7d7`. Web capture started at `59992833a47adfec48eb4acb002523a9177b518b`; the only later production change was Native Loading, so the Web source is identical. Source hashes are in the adjacent JSON.

## Actual changes

- **TabPane:** pass the existing resolved Core slot icon size into ambient Web IconTheme. A leading icon now draws16px instead of20px. Both leading/trailing preserve caller ambient color and explicit/nested/CoreIconTheme precedence, as Native IconTheme.merge already does. Internal, non-exported ResolvedTabPane gains an optional style field. Public TabPane/Core/barrel declarations are unchanged.
- **Typography compatibility:** restore the22 existing public `--coui-text-ROLE-line-box` flags removed by #6336. Keep a role's rounded rendering expression with its current typography CSS block, so replacing ThemeConfig.typographyCssBlock updates multiplier/fixed-length mode without rebuilding Tailwind. Existing source variables remain live. No typed channel registrations, typed division, trigonometric unit conversion, observers, or new Dart API.
- **Loading:** restart a repeating simulation when the existing resolved duration changes, preserving its current phase. Initial/live zero periods stop at the existing Web static pose; positive periods resume. Core reduced-motion policy and default display loops are unchanged. Four variants are covered, including repeated off/on toggles, zero/positive transitions and disposal.
- **Capture truthfulness:** remove nearest1/64px pre-quantization. Real Chrome captures a CSS request187.499496px as187columns, while the previous helper returned188. Round each engine's actual laid-out length independently. The separate fractional-height crop matching Chrome remains. A sidebar whose actual Native/Web widths are187.4995/187.5 therefore correctly fails187/188.

Core defaults/tokens/colors, supported external Dart API, callbacks, SDK, examples, Figma canvas/components.json, pixel thresholds, allowlists and baselines have no changes in this PR. No per-key offsets, font/AA flags, masks or padding adjustments. The supported export graph's public AST signatures match main; the internal resolver field is explicitly excluded from that external-API statement.

## Fresh measurements

Both baseline main and accepted Native/Web were newly captured for all748 default keys. The regenerated entries/probes are identical to the previous manifest. Related Loading/TabPane52keys cover every registered style, with12default keys overlapping the full matrix.

| Scope | Before pass/fail | After pass/fail |
|---|---:|---:|
| Default748 keys |567 /181|567 /181|
| Related52 keys |34 /18|44 /8|

Default TabPane editor-strip light/dark now pass:8.09375%→3.19097% and7.89236%→3.34028%. Across all registered styles, ten TabPane keys change from fail to pass, with no related new failures. The default total is unchanged because two NavigationBar failures previously hidden by pre-quantization are restored. These are test-capture corrections, not product layout regressions. Remaining default181 consist of4dimensions and177same-size pixel failures; they are not waived or all classified as inevitable renderer differences.

Against the earlier, separately captured461/287 matrix, the current failure set has106improvements and0new failures. This historical comparison includes upstream #6336/#6337/#6338; those gains are not all credited to this batch.

All1520default platform/probe images were compared as decoded RGBA:1516are exact, only two Web TabPane and two Native sidebar images change. Related104platform images have94exact matches and ten changed Web TabPane images. All related Native images and all default Loading images remain exact.

### Own-baseline is a separate signal

Default own-baseline:1084pass/412fail plus24first-capture stage cells, both before and after. Equal totals do not mean equal failures: two Web TabPane cells intentionally become baseline differences when their incorrect20px icons are corrected; two Native sidebar cells return to the existing187px baseline after removing pre-quantization. Other410failing cells remain. Related own-baseline is26pass/78fail. No baseline was promoted. The official pixel report with both modes is281pass/467fail; the separate **parity-only** report is567pass/181fail,0infra/0skip and **exit1**. Neither report is all green.

## Validation and negative controls

- Core entire package7776pass; Native affected suites140pass; real Chrome integration51pass plus motion2pass. Optimized jaspr build357/357. The optimized docs' real example selector renders editor-strip icons16×16; real tab selection succeeds with no captured runtime errors. This is local optimized output, not a new deployment.
- Web full run passed8687tests, then27suites failed to load due to disk exhaustion. The test runner automatically reclaimed its own temporary kernel directory; no unrelated files were deleted. All27suites were rerun and266tests passed:8953distinct tests complete. The original infrastructure failure is retained in the evidence, not called an initially successful run.
- During that same disk event, main7and final14capture entries failed. Exact failed-key manifests were rerun with all related styles: main59/final66captures complete successfully. Final PNG/JSON inputs are complete. No timeout, skip, threshold or capture-condition relaxation.
- TabPane size wiring removed:24/32browser cases fail, restored78pass. Ambient color forwarding removed:36/40fail, restored40browser cases pass. Native counterpart93tests also passed in its worker.
- Loading old duration setter:4cases fail(.5instead of.375); corrected loops pass. Original live reduced-motion toggle fails all4variants; corrected expanded20cases pass. Worker related Native79/browser4pass. Owned debug runtime performed live toggles and hot reload, then app/browser and assigned ports were stopped.
- Typography original source fails runtime block type swaps; missing flags and zero-fallback prototype regressions were caught in cross-review and removed. Final10Chrome probes and306targeted Web tests pass.22roles×1/2/3lines, null/removal/restoration, fractional/variable/scaled inputs and nested roles are covered.
- Capture original pre-quantization fails the independently captured Chrome vector test(expected187, got188); accepted Native13and real Chrome1pass. Eight shared vectors include half ties, real distinct widths and fractional heights.
-16changed Dart files: format drift0, diff check clean. Scoped analyze has the same existing info1as exact main, identical diagnostic code/message; no new error/warning/info. No lint ignores were added.
- Cross-review found and fixed TabPane ambient-color loss and Loading zero-period restart. Final independent reviews found no new blocking issue. Full manual CI was not run; GitHub board movement is not code CI.

## Explicit remaining work

[#6342](https://github.com/coco-de/coui/issues/6342) tracks existing #6336 inheritance regressions: raw20px child under label14/1.4 inherits20px instead of28px; size-only Text after ordinary unitless/length CSS override receives stale leading; direct source-variable changes across kinds retain the initial mode unless the typography block is replaced. This batch does not claim these fixed. Newly released helpers from #6336/#6337 are retained; their earlier additions are not described as API-change0 for the whole session.

Star/Pulse diagnostics produced no admissible default shape patch. Figma's Lucide star differs from both mathematical implementations; replacing one with the other would change existing shape options. Exact-SVG pulse experiments did not improve the residual, so no raster/AA workaround was shipped. Separate font audit matches all13loaded font binaries/weights and1664tracked small-size advance comparisons; it found no shared input defect. These limits do not constitute designer approval or waiver of remaining pixels.

Actual light/dark Native/Web-before/Web-after screenshots are temporary private PR-evidence assets(3-day TTL), not committed images. See the PR comment. Data: [parity-parallel-batch-2026-11-17.json](parity-parallel-batch-2026-11-17.json), [default rows](parity-parallel-batch-2026-11-17-default.csv), [related rows](parity-parallel-batch-2026-11-17-related.csv).
