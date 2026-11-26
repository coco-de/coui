# Stateful Web owner isolation - #6404 / PR #6413

The ten affected types are Tree, Scrollbar, OverflowMarquee, Loading, FormField, TextArea, RichEditor, FormattedInput, ObjectInput and ItemPicker. Different parents may use equal local keys. Previously key hashes became global DOM/CSS IDs, sending document initialization, ARIA, focus, geometry and scoped styles to the wrong instance. Private IDs now belong to each State lifetime, with separate server/client namespaces.

Worker product13ce was cherry-picked as61bf. All11 changed files are byte-identical. Source c122 integrates main e2, including its independent NavigationBar itemMaxWidth96/API/Figma/baseline change. This PR preserves public constructors/defaults/Root ID/Key/root classes/Styles.combine/events, Core/Native/resolver/SDK/locks and comparator/baselines. Generated private IDs, ARIA refs and selectors change. FormattedInput actual backing input ID is deliberately unchanged. Existing catch-all syntax and CoreBorderRadius.zero aliases are equivalent cleanup.

| Verification | Actual result |
|---|---|
| Permanent negatives | Actual before9b: ten primary observable failures, three controls pass. Bare-counter prototype: separate SSR RichEditor A becomes B's document; the namespace correction passes. Setup/load errors are preserved separately and not counted as product negatives. |
| Worker tests | Actual O2 Chrome13 and direct existing units142 pass. Final11 blobs, fatal0/format0, public10/export1296 unchanged; owned SSR reload/HTTP200 to200 then closed. Repeated runs are not summed. |
| Root integrated source c122 | New stateful13 + existing Fade Chrome/SSR9 =22 tests pass, stable source hashes. Changed11 files strict/format0; new main Nav feature is inherited separately. |
| Independent review and actual O2 | e2 before vs c122 after, actual light/dark RichEditor/FormField8 rows, runtime0. Rich before Beta/empty -> after Alpha/Beta; editing B preserves A. B FormField AX Alpha label/description -> Beta, refs now point inside B. Root/public IDs, nodes, raw Core palettes and callback routing retained. |
| Full fresh matrix | c122 Native752 and Web752 all freshly captured, missing0/retry0. Compared to prior7fc render-equivalent4b7, PNG1524/1528 byte same. Four changed NavigationBar default Native/Web L/D images belong to inherited #6410. JSON1348/1504 byte same; Nav2 layout-sidecar changes and other captureContext.text changes remain raw. All key/role/property diff/infra/skip verdicts same. |
| Reports | pixel572/180, property416/278+12infra/46skip, both exit1. No threshold, field, producer, baseline or forced-skip change. |
| Docs | Optimized359 routes and actual ten component routes110 records, L/D/variants/input/refresh, JS/action errors0. Source c122 is explicit; later Nav-only integration is separately bound. |
| Inputs/cleanup | Tracked22482/generated/locks hashes unchanged, clean at snapshot. All owned capture/report/browser processes closed; docs server SIGTERM/reaped143 and ports closed. |

Seeded FormattedInput reset on owner rebuild matches the baseline and is not fixed. Unseeded node/value/selection and relevant ID lifetimes are tested separately. Conditional hover IDs are not promised always present. TextArea sizing, general partial hydration, all document IDs, all engines/AT, #6366 and all parity differences remain outside this claim.

Eight raw PR images show fresh Native/Web default Tree L/D and independent RichEditor before/after L/D. Images are unedited/uncommitted, kept only in a private unpublished temporary release, and expire after three days. Figma contract/canvas and new designer approval are not claimed. Full manual CI/deployment are not claimed.

Detailed source hashes/commands/origins are in the paired JSON. Raw root artifacts: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6404-integration-20261118.h0_a3h5u`; worker: `/tmp/weever-stateful-keyscope-20261118.ji8oyp7d`; independent: `/tmp/weever-6404-independent-review-20261118.4ke4e6iz`.

Latest main integration `978b21c6651cc620380192bfd7bb72db8b1bf98e` includes main ce6 plus independent docs v2 #6416. All11 owned blobs remain c122-identical. Final stateful13 + Fade9 + caption-gap2 =24 tests pass; full official SDK contracts exit0, changed-file fatal0/format0. The historical c122 matrix/docs snapshots above are not relabelled as this newer execution. Fresh new-docs build/runtime receipts are recorded separately.

Latest-main optimized docs build exited0 with 359 unique routes. Actual ten routes produced 110 records with JS/action errors0. All 22501 tracked files/generated/locks stayed byte-identical and owned browser/server were closed. These are fresh978 execution receipts, distinct from historical c122.

Paired machine evidence: [JSON](parity-stateful-scope-2026-11-18.json).
