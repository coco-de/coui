# FileInput: let the visual drop zone receive the caller's width

Part of #6131. Base: main `98e68ffe6e4daa3450ac95eafae36809b6f9f6b8` (2026-11-17 KST).

## Merged work and next defect

#6328 was squash-merged at the base above, pinned to verified head `d494b45a7ba9b8eea98517dc46bd5ed7e1402585`. Both full trees are `0225433ebcc151bedad5b99814a4eba6230a8303`. Release workflow 43990637960 succeeded and opened release PR #6329; a new deployment is not claimed.

The next defect is in Web FileInput's layout propagation: `css: width:600px` sets the Clickable host to 600px while the bordered visual drop zone inside remains about 138px wide. Its drop/highlight surface and click target no longer cover the same box. Flutter's existing child receives the caller's constraints and occupies all 600px.

The Web resolver now gives the visual root the existing structural `grow` and `min-w-0` classes. It fills the allocated clickable host and can shrink under a smaller parent; an intrinsic host keeps its existing size. No width constant, new design value, wrapper, widget callback or public parameter was added. One stale Dartdoc reference and the existing overlong class string were also cleaned up for analyze.

Core/defaults, Flutter library, public constructors/fields/functions, exports, themes, typography, colors, border values, Web event handlers and DOM structure remain unchanged. The resolver's declarations match base after function bodies are removed. These flex classes implement constraint propagation; they do not alter the design tokens.

## Evidence

- Public-widget light/dark fixture: host600/drop138.453125 → host600/drop600; disabled selected-file host320/drop138.453125 → host320/drop320. Native references occupy600/320. The existing cross-platform height difference remains visible; full-scene pixel equality is not asserted.
- Actual Chrome constraint tests: 16 pass, covering light/dark CSS width, percentage width, disabled, selected files, intrinsic sizing, four surface presets, smaller-parent clamping and live width changes.
- Mutation control: remove only the two added classes, run the original11-test subset unchanged: 9 fail / 2 intrinsic controls pass. Restore the exact accepted source SHA: all tests pass. Neither a JS fixture error nor a synthetic layout overflow is counted as a negative control.
- Web FileInput/Clickable suites plus the16 browser cases: 40 pass. Flutter FileInput caller suite plus8 public-widget border/host constraint cases: 44 pass. The constraint tests load the real parity fonts so a narrow host is not tested against Ahem's artificial metrics.
- `dart analyze --fatal-infos` on the three changed Dart files: no issues. `dart format --set-exit-if-changed --output=none`: 0 changed. `git diff --check`: clean.
- `jaspr build`: success,357/357 routes. Actual optimized `/embed/file-input/` DOM: parent allocation600 and448 both reach the visual border, focus remains, drag-enter changes dashed to solid and drag-leave restores dashed. A document-app error also occurs on drag: **MissingPluginException, method `entered`, channel `desktop_drop`**. The unchanged generated client options register that Flutter plugin globally; this source change does not change plugin/event registration. The app is not claimed error-free. Its integration requires separate follow-up.

The verified source SHA and raw fixture/release computed measurements are in the [JSON evidence](parity-file-input-constraints-2026-11-17.json).

## Fresh matrix and residuals

Both platforms were freshly captured on merged main before edits. Web was freshly captured again after restoring the accepted source following the mutation control. Flutter library/capture inputs are unchanged, so its fresh main captures were reused on the after side. Actual DPR1 and all capture/normalization/baseline policies remain unchanged.

The first after-Web sweep finished747/748 and exited2 after `accordion-default-light-defaultStyle` timed out waiting for a function at30000ms. That single unchanged key was retried once under the same conditions and succeeded. No timeout, key list, allowlist or threshold was altered; the initial failure remains recorded. The final dataset is complete.

| Scope | Before | After | Before/after raster result |
|---|---:|---:|---|
| Default748 | 461 pass /287 fail | 461 pass /287 fail | All1,520 platform/probe images have identical dimensions and RGBA |
| FileInput10 surface keys | 0 pass /10 fail | 0 pass /10 fail | All20 platform/probe images identical |

The default FileInput example supplies no width and does not exercise this repaired state. Its intrinsic201×224 vs201×223 size difference remains, so this repair does not reduce the287 total. Existing own-baseline results remain1,361 pass /135 differences /24 first-capture stage probes. The existing per-key matrix is the [unchanged #6328 matrix](parity-patterned-borders-2026-11-17-default.csv), confirmed by the fresh all-image comparison.

No crop, image offset, scaling, mask, font substitution, AA flag, threshold relaxation, baseline promotion or exception was used. Full CI, a new deployment, Figma changes or designer approval are not claimed.
