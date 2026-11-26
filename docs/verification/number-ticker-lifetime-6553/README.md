# NumberTicker deferred-start lifetime (#6553)

Web `NumberTicker(initialValue: ...)` queued its initial animation without checking whether its State still existed. A real public first-frame removal disposes the host and tickers before the queued callback runs. Plain, builder and explicit same-value initial cases then throw at State.context; the same host with initialValue omitted succeeds. Timer creation has not been reached, so this is not a measured timer leak.

The callback now checks mounted before reading State or starting animation. The existing discarded Future is explicitly marked unawaited; scheduling and error propagation are preserved. Public constructors/const/copyWith, builder/formatter/child, root CSS/attributes/events, duration/easing, Core, resolvers and defaults are unchanged by this PR. InitialValue equal to target still follows its existing mounted animation path.

Implementation a1c0d707 was integrated with upstream main a4416e4d as `26f213753baa92ea5a54834734fb57414572dff3`. Upstream #6551 changes Checkbox/RadioGroup contracts, related baselines and Figma metadata; those 178 paths are preserved and separate from this PR's five implementation/test/changelog paths. Our zero API/Core/default-change claim does not describe the unrelated upstream change.

## Actual validation

| Check | Result |
|---|---|
| Original public lifecycle test | Light/dark each fail with three uncaught State.context errors; no-initial control passes |
| Same-fixture first guard candidate | Five optimized browser tests pass; fixture/client/test bytes equal the original reproduction |
| Final candidate | Guard + unawaited; separate five pass after fixture64ms→CoreDuration.fast150ms/lint formatting |
| Integrated Web | New5 + existing6 PASS; four changed Dart files fatal/format pass |
| Native reference | Integrated external4 PASS; existing23 PASS at original7f18 are historical |
| Fresh canonical captures | Native2 + Web2, light/dark defaultStyle |
| Committed pixel regression | 1 PASS / 1 FAIL / infra0, actual exit1; existing Native dark failure |
| Historical control against same criterion | Same1PASS/1FAIL/exit1 using full6882 raw inputs |
| Platform comparison | Pixel0PASS/2FAIL/exit1; property2PASS/0FAIL/exit0; infra0 |
| Local docs build | Exit0,104.406s,361 routes,363 SSR HTML (+2Flutter HTML) |
| Owned SSR VM reload | Actual reloadSources success, loaded target library, HTTP200 and five roots before/after |

All eight fresh canonical PNG/JSON files are byte-identical to the original full6882 captures. The eight committed baseline blobs are also unchanged from Git6882 through a441. An additional official regression with the original full6882 raw data produces the same Native dark failure. No new static pixel difference is introduced. The failed regression remains a failure in the record; no baseline, threshold, probe, normalizer or comparison exception was added.

The original fixture callback-type compile failure is retained separately from the actual original negative. Its raw state observations distinguish real disposal (key cleared/retained State unmounted) from the pinned framework's retained DOM. The first guard candidate uses byte-identical reproduction fixtures; final fixture timing/lint adjustments are a separate tested stage. Positive cases cover active interpolation, formatter, builder/child State and DOM identity, root CSS/ARIA/events and disposal of an already-running timer.

Native's initial failed external assertion confused displayed target at800ms with binding animation scheduling; its corrected control separately observes800/816ms and callback-free disposal. The23 existing Native results remain from7f18; the same four external reference cases were actually repeated after the upstream Core merge. These comprise15 current integrated cases plus23 historical existing cases, not38 freshly rerun cases.

## Runtime and retained evidence

Flutter3.50.0/Dart3.14.0, pinned Jaspr CLI0.24.0-beta.1 and owned Chromium150 were used. Actual browser O2 runs establish the deferred client fix. The separate owned SSR Dart VM reload does not execute the browser-only startup branch and is not client hot reload. Source was unchanged between reload requests; both responses have5165 bytes and five expected roots, but different HTML SHA values. No byte-identical HTML claim is made.

The docs builder's automatic Flutter Pub preflight rewrote both package-config and graph bytes. All232 names/versions/effective roots/dependency edge sets stayed equivalent and lock bytes stayed exact. No direct project Pub-get command ran; internal solver/download counts were not measured. All24986 tracked files retain their bytes/modes/symlinks. Generated output stayed in official task-owned job boxes; only the5046-row hash manifest, three representative HTML files, raw captures/logs/source receipts and metadata pre/post images remain. Processes, profiles, VM/HTTP ports and temporary links were reclaimed.

[verification.json](verification.json) binds the tested source, raw reports, independent review, preserved failures and original images by SHA-256. PR #6554 contains four original Native/Web light/dark images, expiring after three days. No Figma contract/default/canvas change is included. Separate duration/reduced-motion/easing hypotheses and Countdown#6399 HOLD remain outside this fix. The last full sweep is still6882 (834 keys,606 pixelPASS/228FAIL); this scoped validation is not a new full-main measurement.
