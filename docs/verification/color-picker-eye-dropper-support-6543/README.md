# ColorPicker: hide unsupported browser eyedropper

The documented `enableEyeDropper` contract exposes the button only on a supporting host. Web checked support in the click handler but always rendered the button. An owned browser realm with the API absent therefore exposed a control that did nothing.

The existing support getter now participates in the shared inline/popover enable value after the first client tree is finalized. A private readiness flag preserves server and first-client markup; its deferred callback checks `mounted`. Normal later builds read current support through the same getter. Public constructors, `copyWith`, resolver outputs, Core/default values, styles and the existing handler guard are unchanged. There is no geometry compensation or placeholder.

## Validation

Actual runs used base `6882d1d41c872b6285b5f12d169b5c3d9b21f59a` plus the five frozen files recorded in [verification.json](verification.json), before the publication commit.

- Original unsupported L/D tests fail with expected zero buttons versus actual one; the same frozen candidate passes five optimized browser tests. They cover supported/absent L/D, SSR/first-client identity, twelve public-enable transitions, root/State/input/focus/value and strict selection preservation, draft Cancel/Save behavior, and deferred-callback disposal. The original supported final control also passes.
- Existing Core20 and Web/parity20 tests pass: **45 final tests** including the new five. Fatal analysis of four changed Dart files and scoped format checks pass; earlier fixture/lint failures remain in the outside evidence packet.
- Six new official Web captures match main6882 PNG bytes, RGBA and `byRole` exactly. Native six are explicitly reused from that fresh full run: 5,401 reachable source files and fourteen assets are unchanged and the Web renderer is unreachable from the Native entry point. Two inline whole-JSON differences are only generated CSS scope IDs in `captureContext.text`, caused by full versus scoped capture order.
- Actual unmodified same-platform regression against Git6882 committed baseline blobs passes all six keys/twelve platform images (exit0/6.75s). Web six are byte/RGBA-exact; Native six differ in RGBA but pass the existing criterion. The earlier separate fresh-main before/after control is not the committed-baseline comparison. Official cross-platform pixel/property reports each remain four PASS/two FAIL, exit1/infra0. The two inline differences were not repaired or filtered.
- Actual `jaspr_cli 0.24.0-beta.1` docs build passes: 361 routes/363 HTML files in143.14s. An owned SSR VM reload succeeds in376.6ms with28 loaded libraries; optimized client restart/hydration was tested separately.

## Scope and evidence limits

Supported Web's32px eyedropper row and unsupported Native's26px comparison row remain a legitimate6px difference. API-absent tests use a controlled owned Chromium realm; they are not real Firefox/Safari or physical OS-picker sampling runs. Pure SSR retains its original markup because it cannot know a future browser's capabilities.

The disposal test verifies five disposed States and no console error. Pinned Jaspr retains seventeen DOM inputs on root detachment; this is not a DOM-removal claim. Original pointer/refocus selection behavior is preserved separately from strict property-only transition controls. Existing disabled-keyboard and pending OS-picker asynchronous disposal behavior remain separate issues.

The old temporary SDK was incomplete. Absolute commands use the already installed Flutter3.50.0: Dart/tester binaries match the surviving previous binaries; the Flutter-tools snapshot differs. An isolated tool package resolved cached CLI0.24 dependencies offline once; it did not replace the global CLI. The standard builder invokes Flutter web build with automatic Pub preflight; no manual project Pub command was run. Its ignored config/graph bytes were regenerated, while all232 package names/versions/effective roots/edges and the project lock remained equivalent. The actual internal solver/download count was not instrumented. Original and generated metadata are preserved. No baseline, comparison criterion, capture/probe/normalizer, SDK selection setting, or design value was changed.

The JSON binds source hashes, commands/results, tooling versions and six unmodified L/D before/after/control screenshots. Root and the independent reviewer examined the originals. Images are uploaded separately through the repository [team pr-evidence skill](https://github.com/coco-de/skills/blob/main/internal/coui/skills/pr-evidence/SKILL.md); no PNG is committed or baseline promoted. Outside evidence pointer: `/tmp/weever-6543-color-picker-support-path`.
