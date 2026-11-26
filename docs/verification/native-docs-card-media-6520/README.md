# Native docs Card media composition — #6520

Preview stages now use the existing unpadded `Card.media` slot, with the original caption Column in `Card.body`. Previously the stage was inside the padded custom child. Cards without a preview retain the same custom-child tree. Empty captions omit the body slot.

The designer's #6416 source (`b3c031a7cee92f75b5cb4d87f02364e6e3a20740`, `docs-shell.css:907–913`) explicitly places the stage across the card top and clips overflow. Native's original comment points to that same rule. The repair uses the existing Card contract; Core, library Card, public signatures/constructors/const, callbacks, and comparison criteria are unchanged. Figma canvas verification was not performed.

The caption keeps its original order, typography, conditional branches and internal spacing8. The stage-to-caption gap changes from Column spacing8 to resolved Card body top padding (default20). Native body padding remains24H/20V, including theme overrides/scaling; it is not changed to Web's20H/16top. Media activates Card's existing default clip promotion from none to antiAlias. Actual Card-owned clips and edge bounds were verified.

## Source and artifacts

- Actual capture/build source: `aa8a77d02c60433f27bf13c0f812d37fd8511aaf`, based on `cd01397c02fc4af73786eb41eb2996935c125fe9`.
- Only production path: `docs_core/lib/internal/preview/flutter_card_view.dart` (SHA256 `0df811852368279149704779584d5934a4f9d2ee57032129caab07ef4632c5df`). One permanent regression file accompanies it.
- Evidence pointer: `/tmp/weever-6520-native-docs-card-path`; its phase holds the full logs, manifests, raw originals, source/metadata protection and artifact index. These later verification documents do not change the measured runtime source.
- Original4499 captures are explicitly historical, with the fourteen relevant source blobs bound to the pre-fix base in the batch handoff. Both post-fix platforms were freshly captured. They are not labelled as fresh pre-fix captures.

## Verification

| Check | Actual result |
|---|---|
| Original meaningful regression at canonical scale1 | 2 failures (media inset25/21; empty-caption height182 instead of142), 2 controls passed |
| Permanent focused suite | 54/54 passed: all21 authored Card references ×L/D plus edge/padding/clip/empty/nonpreview, all caption branches, theme padding at scale1/1.5, two-card400/600 layouts, nested links, keyboard activation and null callback |
| Existing docs scene suite | 9/9 passed |
| Existing Card/spacing/shadow-radius suites | 35/35 passed |
| Fatal analysis / format | 2 files, exit0 / unchanged |
| Source-derived manifest | 3894 all-style /832 default descriptors; all42 whole-document Card keys plus6 ordinary Card controls, descriptors exact to the reviewed selection |
| Fresh actual captures | Native48 exit0/12.33s; Web48 exit0/54.44s; Chrome150.0.7871.24; 96 JSON +96 PNG validated |
| Official cross-platform pixel report | Actual exit1: 6PASS/42FAIL/0infra/0skip, unchanged from selected original4499 counts |
| Official cross-platform property report | Actual exit1: 6PASS/42FAIL/0infra/0skip, unchanged from selected original4499 counts |
| Existing own-baseline report | Actual exit0;6 ordinary Card keys ×2 platforms =12 comparable images passed,0 failed;42 docs Card keys ×2 =84 images have no baseline and are first captures, not regression passes |
| Pinned actual docs build | CLI0.24.0-beta.1, O2 default, exit0/130.46s,361 generated routes/363 HTML files |
| Relevant owned Native debug app | Actual helper library loaded; CLI exit0, hot reload76ms, before/after media insets1/1/1; own CLI/VM PIDs and port closed |
| Source/metadata protection | 22760 tracked source files/modes unchanged through verification;232 package identities and raw config/graph/lock bytes exact;192 origin/combined artifact hashes exact |

The focused original/final RenderBox measurements restore stage left/top insets25/21 to1/1, while caption left25 and bottom21 remain. Empty-caption height182 becomes142. The default Card subtree gains two antiAlias clips. Themed12/18/10/14 padding scales exactly once, and nonpreview Body geometry is identical.

Web48 PNGs and byRole values are byte/value identical to original4499. Ordinary Card6 PNGs and full raw JSONs are identical on both platforms. Native42 whole-card images change as intended. Web42 raw JSONs differ in source-origin paths; sixteen also differ in `captureContext.text` because it includes existing SSR style-node IDs allocated in a different subset-capture order. Original text/raw values were preserved, without normalizing or changing the comparator.

## Limits and preserved failures

This restores the authored full-bleed composition; it does not claim that42 whole-card failures were solved. Web caption spacing, border/tone and typography differences remain. Root property probes do not separately identify every stage/caption paint owner; the owner-specific stage restoration is proved by the real RenderBox regressions. No all-context, physical-device or complete interactive parity claim is made.

All first attempts remain intact: the initial fixture accidentally used preset sizeScaling1.15 while expecting scale1 (corrected fixture then proved the two real negatives); candidate1 left Clickable's normal100ms keyboard pulse pending after its callback assertions (candidate2 pumps the normal duration, with product bytes unchanged); an external comparison assumption that only origin paths changed rejected the sixteen SSR-style-ID text records; and the first successful95ms Native reload had a post-quit driver cleanup PermissionError. Its app-finished log and closed port were preserved. The separately owned second attempt uses live-Popen-only cleanup and provides a complete exit0 receipt. No unrelated process was killed or attached to.

The docs build was run once because its embedded Flutter client imports the changed helper; a WebDOM-only reuse claim would have been insufficient. Its5017 output files were renamed outside the worktree and verified byte/mode exact. No baseline promotion, dependency resolution, criteria changes, SDK/browser copies or remote writes were performed by this worker.
