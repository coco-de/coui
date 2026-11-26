# Menubar caller label priority — #6637

Native Menubar previously ignored `triggerButtonStyle.labelStyle` when painting its label. The resolver now combines each caller layer's label and trigger-label intents using the existing typed Core merge, combines theme → variant → instance, then applies the named Core default. The existing open-label overlays remain in order.

Only the Native resolver, two regression tests and these verification documents change. Public fields/signatures, Core contracts/defaults, Widget construction, Web, probes, captures, baselines and comparator criteria are unchanged. A raw style without a role retains its size/line box when a role is added; mixed caller layers retain instance precedence.

## Source and functional evidence

- Original source: `94d2fe93158a25f294aeec102891a88f0a33926d`; final code commit: `20060fc72385972da13abdadd632c5a636351253`.
- Final identical external fixture: original **6 PASS / 8 FAIL**, candidate **14 PASS**; separate label-only role boundary **2 PASS on each**. All seven public recipes include closed and actually opened menus, direct RenderParagraph fields, sibling labels and retained State.
- Related existing Native-package28 + Core9: **37 PASS**, command exits0. These ran on resolver97e6; the final814e change is comments only, with exact noncomment bytes.
- Permanent repo-port tests: **16 PASS**, exit0, on final814e. Only relative imports differ from the external fixtures. Final source3 fatal analysis and format: exit0/no changes. This port rerun duplicates the same16 logical cases.
- Earlier original14 had10 successes/4 failures, but4 cells asserted lifecycle only and recorded unresolved typography. First refined candidate was12P2F because bodyLarge was incorrectly expected as16. The final fixture corrects those two expectations to the declared Core15 and reruns both sources. All prior fixtures/results remain unchanged; an earlier unmeasured Web16/1.5 numerical target is withdrawn.

## Default Native images and committed baseline

The current source-derived Menubar manifest has10 entries; defaultStyle light/dark select2. Actual original/candidate capture tests each passed2, producing4 PNG +4 JSON, all before/after pairs byte-identical (152×48). This is separate from baseline regression.

A Native-only CLI invokes unchanged canonical `comparePixels` against two PNG blobs extracted from Git94d: **2 PASS / 0 FAIL / 0 infra**, actualexit0/1.531s, existing channel32 and regression0.001. Each differs by1/7296 pixels from its committed baseline (max37/44), so baseline byte equality is not claimed. No baseline promotion or allowance was applied.

## Resident hot reload

The standard Flutter machine `app.restart(fullRestart:false)` reloaded1/4905 libraries, code0. The real default Menubar and one custom caller kept PID, State, input and paragraph-render identities; the default observation stayed exact. The custom text changed from Pretendard14/400/1.4/−0.14/default ink to the caller's GeistMono20/600/1.2/0.4/#336699. Its natural width changed203→329; its two actual PNGs are intentionally different.

The first resident attempt stopped at7 harness INFOs before UI runtime; original input and logs remain, but its formatted shadow was not retained. The successful attempt retained two unused FFI startup warnings (`dir_picker`, `file_saver_ffi`); no file capability or blanket console-error0 claim is made. Native PID and both ports closed; official jobs were reclaimed.

## Boundaries

Metadata232 preserves all fields/versions/dependencies; only own12 roots were rebound and external220 remain literal-exact. Config/graph/lock were unchanged during verification; no solve/get/download. Unversioned SDK declarations and graph sentinels are distinguished.

This is Native-only behavior verification, not Web/SSR, cross-platform parity or a fresh full838 audit. No old static failure-count improvement is claimed. Root scoped unchanged Web/docs-site builds N/A. The separate #6619 collection-contract question is not changed.

`verification.json` binds portable evidence paths and SHA256 digests. Full raw data and earlier failures remain under the external evidence root recorded there.
