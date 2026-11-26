# DotIndicator Web instance style isolation

Issue [#6447](https://github.com/coco-de/coui/issues/6447), part of [#6131](https://github.com/coco-de/coui/issues/6131).

When one runtime DotIndicator configuration is mounted under two inherited styles, or valid local keys are equal in separate owners, the former per-instance CSS selectors can collide. Owner A's raw hover and focus-ring values then come from later owner B. A painted focus band can also leak into a bandless owner and overwrite its caller shadow.

The fix keeps instance values on each actual dot as CSS custom properties and uses shared selectors containing no instance values. It retains the public widget, resolver signatures, required `scopeId`, resolved const constructors and legacy scope classes. The painted-band marker is emitted only when the existing focus helper says that band paints. Existing token/class paths, precision, default values, hit geometry and widget events remain authoritative.

## Source binding

- Original actual four-case negative: `b5a18a24b38481f853cc4770137fa60dfbbd7a5d`, before product edits.
- Ordinary main integration: `64dd884831f12ee4d39aef9be3263481e94b168e` (#6446); incoming paths are disjoint and owned bytes were retained.
- Product/test freeze: `e9440417d104d0e241de0530242f25518d49fadf`.
- Product style SHA256: `b33687c37e160767033643f6e2c8fe18c3e1695ecf3c16075b970d145985756f`.
- Canonical before evidence uses an isolated copied library at integrated main, replacing only the style file with preserved old SHA `22f1093856dc0e36ac7249d9b552642c80bc99c114bfb9cd79fd70c363df2dc5`. It does not reset the worktree or duplicate the renderer.
- The follow-up changes after e944 are two test harness files plus these verification documents. Product, fixture and execution input bytes are unchanged. Build/UI/reload retain their actual e944 labels.

Only `packages/coui_web/lib/src/components/display/dot_indicator/dot_indicator_style.dart` changes production behavior. The widget file is byte exact at SHA `085ef17fa25fdf89907feaf21eebd956c49b0bcb1407802e9ce5f7922c36a73b`. Analyzer AST comparison confirms all 12 public style shapes, including const constructors and required parameters, are exact. Core, Flutter/Native, Join, global color/focus helpers, ThemeConfig, exports, examples, Markdown, docs CSS/JS, manifest/probes/models, comparator/normalizer, criteria, baseline, skips, SDK constraints, dependencies and locks have no branch diff. Package configuration retains the same 232 resolved tuples after normal workspace path rebasing.

## Validation

| Check | Result |
| --- | --- |
| Existing style/semantics plus SSR/runtime scope regressions | 33 passed |
| Follow-up with official foundation, including painted border assertions | 4 SSR + 6 optimized client tests passed; 68 client records, zero runtime errors |
| Touched five Dart files | `--fatal-infos` exit 0; format 0 changes |
| Follow-up two test files | `--fatal-infos` exit 0; format 0 changes |
| Official `scripts/guards/resolver/verify_contracts.sh` | Exit 0; existing non-enforced WARN backlog retained |
| Fresh optimized docs build at e944 | 359 routes, 109.72 seconds, 22,575 tracked byte/mode entries unchanged; owned group closed |
| Actual optimized docs page | 12 light/dark observations: default/vertical arrows and click, passive state, theme refresh, root identity; zero runtime errors/failed requests |
| Owned Dart debug reload | HTTP 200 before/after, `reloadSources` success, exact component HTML; VM/HTTP/PID closed |

The runtime regressions exercise repeated runtime configuration and equal local keys under different inherited styles; rebuild/reorder/remove/remount; raw and token hover/rings; painted and bandless focus bands; caller shadow/CSS/classes/attributes and explicit punctuation ID; forced colors; horizontal/vertical and RTL hit partition with long active markers. Caller callbacks remain active. No public constructor or runtime-ID seed changes are used.

## Canonical evidence and harness correction

The first evidence harness omitted the foundation used by the official capture. Its inactive index 1 was correctly hovered and its computed border color changed blue to red, but `border-style:none` made computed border width zero. These original unpainted hover controls are preserved. A separate explicit caller-solid contrast is also preserved and is not the primary evidence.

The final eight original PNGs mount `Style(styles: docsContentTheme().styles)` before the unchanged fixture, exactly as `tool/parity/src/web/web_capture_backend.dart:186` does. `ThemeConfig` intentionally disables Tailwind preflight; `docs_core/lib/site_head.dart` provides the shared content theme whose installed jaspr_content reset supplies solid borders and box sizing. No target CSS or DOM repair supplies these values. The permanent SSR and client harnesses now use that same foundation and assert actual solid, 2px borders.

Final hover captures assert inactive index 1, no `aria-current`, `:hover` true, solid 2px border and actual blue B before/red A after in the same browser frame, in both themes. The 2px value is the existing authored `inactiveBorderWidth` override, not a changed product default. Focus captures show the red A ring restored and the bandless B caller shadow retained. All eight selected originals were viewed; source hashes, dimensions, raw observations and exact captions are in `selected-evidence.json`. PNGs are unedited.

The declared helper precision is unchanged: existing alpha `.625` serializes as `.62`; Chrome computes declared 2.5px/3.75px outline geometry as 2px/3px. The tests compare exact declared values and existing unique-owner controls separately. Initial assumptions that ignored these existing conversions are retained as failed attempts, not hidden by tolerance changes.

## Limits and retained evidence

This is a Web style ownership repair, not a new cross-platform pixel measurement. Native axis/input issue #5327 and Join DOM-ID lifecycle remain separate. No default816 recapture, residual234 reduction, Native pixel equivalence or complete parity claim is made.

Initial compile/package-root/lint attempts, helper-expectation failures, original four-case collision failures, unpainted hover controls, caller-solid contrast and the first debug wrapper's unrelated ScrollView counter difference are retained. The successful reload helper renders the actual Dot component without that unrelated shell; it does not strip or normalize IDs.

All owned browser, HTTP, debug and build runtimes were closed. Four owned ports and three recorded server/build PIDs were independently checked closed. No evidence, branch, worktree or original log was deleted.

Local proof directory: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-dot-scope-20261119.965fx6jr` (pointer `/tmp/weever-dot-scope-path`). Start with `README.md`, `final-summary.json`, `final-source-protection.json`, `foundation-evidence/foundation-binding.json`, `selected-evidence.json` and `cleanup.json`. The companion JSON contains exact command receipts and source bindings. Publication and merge remain with the root agent.

## Retrospective correction: actual runtime removal/remount proof (#6451)

This section **supersedes the earlier remount coverage statement**. The historical runtime suite exited successfully, but its app anchor and toggle button both used `id="mount"`; `page.click('#mount')` selected the app wrapper. Those original passing logs and68 recorded observations remain preserved, and do not prove actual removal or remount. Original Dot source, worktree, screenshots and proof directories were not modified.

Test-only commit `5997c68e7748130874366773730c235fd56aa411` separates the anchor (`dot-app`), selects `button#mount`, waits for the build counter after each action and explicitly asserts absent/present and DOM identity. The6-test suite passes with78 records:10 lifecycle rows, including two actual removals where the old node is disconnected and two reinsertions with a genuinely new node. Rebuild/reorder retain the old node. The non-null legacy scope class remains the same, as this Dot fix intentionally retains that class; it is not used as new-owner evidence.

The remounted A inactive hover retains its actual solid2px red owner paint. Remounted focus declarations/computed geometry/style and bandless caller shadow match the unique A control exactly, including `rgb(40, 50, 60) 0px 0px 3px 0px`. Painted/mixed/bandless, forced-colors and hit controls were also rechecked by the suite on separate cold pages. They are not claimed as band owners themselves remounting or same-tree band-transition continuity. Error observation in this suite is `page.onError`; it is not a full console/network audit.

The test executed on fc7ca with the exact corrected test-file bytes as a working-tree change, then was committed unchanged as5997. Dot product hashes remain widget `085ef17fa25fdf89907feaf21eebd956c49b0bcb1407802e9ce5f7922c36a73b` and style `b33687c37e160767033643f6e2c8fe18c3e1695ecf3c16075b970d145985756f`. This corrects validation evidence; it adds no Dot product fix or global parity reduction. The existing dd602 docs build remains bound by unchanged product/docs/dependency input bytes; no new build/capture is relabelled.

New proof: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6451-join-scope-20261119.1jxn2eyk/corrected-dot-runtime/observed.json`, with exact test/source hashes and receipts in `dot-retrospective-correction.json`. Historical execution fields and receipts in the companion JSON are preserved; `retrospectiveLifecycleCorrection6451` is the overriding correction.
