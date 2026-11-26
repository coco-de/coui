# ColorPicker disabled input (#6548)

`enabled: false` promises a visible panel that accepts no user input (`docs_core/content/components/color-picker.md:395`). Both renderers previously blocked pointer hits while leaving composed mode tabs and recent-colour actions keyboard-active. The Web eyedropper was keyboard-active too.

The fix forwards the existing enabled state to ToggleGroup, Clickable and Button. Genuine panel owners remain stable across enabled changes, and user-edit entry points check current mounted/enabled state. Native eyedropper completion belongs to the existing stateful shell. External colour and history updates still refresh the panel without emitting user callbacks. Disabled values and labels remain accessible; the panel is not hidden from accessibility.

Public constructors, const/copyWith/style-chain surfaces, Core defaults, resolvers, styles, dependencies and exported helpers are unchanged. Existing disabled chrome is used without new colours or panel opacity. Web capability handling from #6546 is preserved.

## Measured validation

Tested implementation: `3c040112f312e84268f1984f5d1cdddf4dc9bb82`, including main `c08cbc7289`. The implementation/test hashes are in [verification.json](verification.json).

| Check | Actual result |
|---|---|
| Original keyboard negatives | Web disabled light/dark fail; Native enabled control passes and disabled case fails |
| Native tests | 25 PASS: new 5 + existing 20 |
| Web/Core tests | 49 PASS: new 4 + capability 5 + Core 20 + existing Web 20 |
| Changed Dart analysis/format | Six files: fatal analysis 0, format drift 0 |
| Fresh canonical captures | Native 6 + Web 6, default/inline/chain × light/dark |
| Committed-baseline regression | 6 PASS, 0 FAIL, 0 infrastructure failures; actual exit 0 |
| Cross-platform pixel/property | Each 4 PASS, 2 FAIL, 0 infrastructure failures; actual exit 1 |
| Local docs build | Exit 0; 361 routes, 363 SSR HTML (+2 Flutter HTML) |
| Owned Native hot reload | Standard `app.restart`, success; 0 libraries/80 ms, frames both 272×549 |

The one existing Web browser test that timed out after its runner omitted the pinned Chrome path passed in a bounded one-test recovery. Earlier harness/setup failures and their original logs remain separate from successful runs. New interaction tests cover disabled focus and keyboard/pointer rejection, readable accessibility values, external colour/history updates, preserved state and stale UI callbacks. Web additionally checks controlled pending eyedropper results after disable/removal and input selection preservation.

Regression inputs were extracted directly from Git `57e30c22` (24 PNG/JSON blobs plus the unchanged allowlist). The report uses the existing criterion. Native PNGs differ from those committed baseline bytes but pass that criterion. Separately, all 12 fresh platform PNGs and all six Native JSONs are byte-identical to the full `6882d1d4` captures. Four Web JSONs are byte-identical; the other two differ only in embedded generated scope text at `/captureContext/text`. These are separate comparisons.

The existing inline differences remain, including host-capability-dependent height (Native 466 / Web 472) and normalized padding fields. This change does not claim cross-platform equality or reduce the last full sweep's 228 failures.

## Environment and evidence

Flutter 3.50.0 / Dart 3.14.0, owned Chromium 150, and the pinned Jaspr CLI 0.24.0-beta.1 were used. The docs builder invokes Flutter's automatic Pub preflight: package-config URI spelling changed, while all 232 package tuples, effective roots, dependency edges, graph and lock stayed equivalent (graph/lock bytes exact). Internal solver/download counts were not measured. The owned reload project rebound one package root to its source-identical private runtime project; it did not change product dependencies.

Native VM eyedropper support is false. No physical OS sampling, Native pending OS result, desktop plugin or Figma canvas validation is claimed. The Web pending cases use an owned supported-host stub. No source was changed between reload frames; the command verifies actual reload/reassembly of the current app.

[verification.json](verification.json) binds raw reports, source hashes, independent reviews, retained failures, original screenshots and build/reload receipts to SHA-256. Eight original light/dark images are linked in PR #6550; they expire after three days. No capture, baseline, probe, normalizer, comparison criterion or Figma contract/default was modified.

Long-running work used the official job runner with task-owned process groups and temporary storage. The 5,046 regenerated build files were reclaimed after their hash manifest and three representative HTML files were retained. Raw capture/test evidence remains outside the worktree. The last full measurement is still source `6882d1d4` (834 default-style keys); these scoped captures are not a new full-main measurement.
