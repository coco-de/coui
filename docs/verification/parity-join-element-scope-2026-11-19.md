# Join CSS Element ownership — 2026-11-19

Issue #6451, Part of #6131. Product freeze `dd60229991e45686ef4ae5e1a7d21849b41cc393`, base `ad1ba78e9dc2f7c33b8f5dd41c511cac4b312d38`. Production changes only Join `join.dart` and `join_style.dart`. Root owns publication.

A reused runtime Join configuration, or equal local keys under distinct parents, retains the same generated legacy DOM id. Previously later ID-only rules could override another parent's inherited radius/count/axis values. Four actual old-source SSR/Chrome failures show a4px owner painting16px child corners, and a single4px item taking the other vertical3-item strip's bottom-only16px corners.

Each actual Join now carries an Element-owned rule class. Existing ID selectors receive a zero-specificity `:where(.guard)`, preserving their original specificity. The existing first style child, div first/last-of-type rules, count0/1/multiple behavior, axis-only cross-fill, important radius and focus-within overflow/relative/z-index policy are shared unchanged through one selector-aware composer. No new div or hidden metadata node is added. Legacy `resolveJoinCss` remains ID-only with exact prior output; the new function remains outside the public barrel.

The public generative constructor and const ResolvedJoin parameter/const contracts remain unchanged. A private empty payload/public const constructor plus private scoped constructor supports rendering ownership. Strict analysis also exposed the old constructor's long string interpolation. A scratch whitespace-only wrap was legally formatted back to the same long line; the real ID generation was therefore extracted to a private helper, preserving key-hash/radix or eager counter evaluation and genuine _scopeId DOM fallback. **Constructor bytes/initializer text changed; public shape and semantics did not.** Eight actual old/new ID-sequence cases, key-read counts and external subclasses calling `super(...)` compile/render identically. The radius0 getter uses equivalent canonical CoreBorderRadius.zero. No factory/const API change, dummy runtime state, ignore or lint-rule change is used.

## Source and API evidence

- Existing widget/class/extension method AST and style resolver/const signatures are exact.
- Export closure membership is unchanged: default361/all conditional alternatives365. The exported Join library has the disclosed implementation/comments change; other exported libraries are byte exact. join_style remains outside the barrel.
- Exact preserved old resolver versus new legacy output:128 combinations of theme, axis, count, normal/punctuation ID and uniform/nonuniform radii.
-232 dependency tuples match the exact ad1 measurement worktree after workspace-root rebasing; hosted/SDK paths, language/package URIs and lockfile are exact.
- Core, Flutter/Native, shared scope/color helpers, ThemeConfig, design/default tokens, source Markdown/docs CSS/JS, manifest/probes/models/comparator/normalizer/criteria/skip/baseline and dependencies have no production diff.

## Validation and correction of lifecycle evidence

| Check | Result |
| --- | --- |
| Original new browser regression on old source |4 actual failures, runtime errors0 |
| Focused current unit/focus/SSR/runtime suite |35 passed |
| Changed6 Dart files |fatal infos0, formatted |
| Full contract guard |exit0; existing non-enforced WARN backlog retained |
| Corrected affected Join runtime suite |6 passed,30 records including two actual absence rows |
| Corrected runtime analysis/format |exit0 |
| Fresh optimized docs build at dd602 |359 routes,105.35s,22,584 tracked byte/mode entries unchanged |
| Actual optimized docs page |14 L/D default/vertical/focus/click/refresh records, runtime/console/failed requests0 |
| Owned real Dart VM reload |success, HTTP200 before/after, correct owner/guard mapping, unchanged legacy DOM ids; ports/PID closed |

The original35 passed, but its runtime harness anchor and toggle control both used id mount. Immediate reads and the wrong selector did not establish removal/remount. Those old30 records and the build-wait timeout attempt are preserved as **insufficient lifecycle evidence**. Test-only commit `fc7ca504f7371278b4f74b28e79f8eb3c7dc0df7` separates anchor join-app, targets button#mount, waits for completed builds and asserts absent/present plus a new private scope. Corrected L/D traces show A web-8→absent→web-1v while B web-c and the genuine legacy id remain stable. The6 corrected cases replace the old lifecycle claim and are not added to the35 as new distinct cases.

Actual O2 checks also retain counts0/1/2/3, caller min-width on horizontal/min-height on vertical, same-specificity later caller!important priority, nested Join's separate child corners, caller IDs/CSS/classes/attributes/events, and actual focused middle outline pixels outside the clipped wrapper with overflow visible/relative/z1. The first focus-readiness attempt read transparent before the actual style applied; its raw failures/PNGs are preserved. The final predicate waits for the authored color and completed transition before sampling, with no tolerance, timeout increase or positional correction. Permanent runtime suites observe page.onError only; they are not labelled full console/network audits.

## Retrospective Dot validation correction

The same old harness/control id collision existed in the already merged Dot runtime test. Test-only commit `5997c68e7748130874366773730c235fd56aa411` corrects that test in this isolated worktree; old Dot worktree/proofs remain untouched. Its6 affected cases pass with78 records/10 actual lifecycle rows, old DOM disconnection, genuine new node and intentionally unchanged legacy classes. Remounted inactive hover and focused outline/style/bandless caller shadow match their own unique control. Painted/mixed/bandless and forced-color/hit controls are successful separate cold-page checks, not claims of band owners themselves remounting. The existing Dot verification MD/JSON append an explicit overriding retrospective correction while preserving all historical execution fields and receipts. Dot product bytes remain unchanged.

## Original evidence and limits

`selected-evidence8.json` selects8 unedited originals, all viewed by the worker: L/D before/after shared-owner rest and single-item focus. They use the same final fixture and official `Style(styles:docsContentTheme().styles)` foundation. Before uses the exact ad1 Web library snapshot; after uses dd602. Initial negative images/logs remain separate. The evidence capture also observes console and request failures/external requests; these lists are empty.

This is CSS isolation only. Generated public DOM IDs can still collide; full document-wide uniqueness remains the explicit nonconst/API boundary. Unescaped punctuation caller IDs remain unsupported as before. Existing #5155 and #5547 are separate. No Native render update, full816 capture, global parity completion, designer approval or residual-count reduction is claimed.

The only changes after the dd602 build are runtime tests and verification documents. Product/docs/capture/dependency input bytes are exact, so the single build is reused with its real source label. The actual reload renders fresh SSR contexts, whose private owners differ; raw HTML is retained without stripping identities or pretending byte equality.

All owned build, browser, HTTP and VM runtimes are closed. No evidence/worktree/branch/file was deleted. Proof root: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6451-join-scope-20261119.1jxn2eyk` (pointer `/tmp/weever-6451-join-scope-path`). Start with README.md, final-summary.json, selected-evidence8.json, corrected-join-runtime/observed.json, dot-retrospective-correction.json and cleanup.json. The companion JSON retains exact source hashes, commands, observations and boundaries.
