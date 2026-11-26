# Web stage raw properties — 2026-11-18

#6429 fixes capture serialization: `captureWebEntry` collected each role's full actual CSSmap, then overwrote the `stage` map with width/height only while producing its PNG. The shared normalizer requires CSS strings such as `borderTopWidth`, so twelve valid stage captures became property infrastructure errors. Removing those four overwrite lines retains the actual map already measured. Renderers, root selection, crop math, bodyBounds and PNG output are untouched.

Product checkpoint`41ded85b9`; measured source`4211557e140b5aa8904602a9c019b65cb6bfd41e` integrates latestmain`e8ef2531` (Frame#6430). The later verification commit changes no capture executable. All3814/default816 manifest descriptors remain identical to#6427, with MatrixEntry7fields and original probes intact.

| Default816 matrix keys | pass | fail | infra | structural skip |
|---|---:|---:|---:|---:|
| Property before |402|356|12|46|
| Property after |402|368|0|46|
| Pixel before/after |582|234|0|0|

Both official reports exit1. Twelve stage roles now load and expose their actual existing17-field comparison failures; this is **not twelve property passes or twelve CoUI component fixes**. Every existing root property result remains equal. Pixel top-level passedCount593 counts roles and is not the582passed matrix keys above.

## Actual capture and source binding

Web all816 were freshly captured at421 after the global upstream Frame fix: first attempt816/816, failure0/retry0,416.438seconds capture loop. No default scene is certified by a limited Frame sample. Native816 explicitly reuse actual309 captures: the conservative workspace import/export/part closure1990files has identical blobs, existing232package tuples/versions and lock are unchanged, and WebFrame is outside that Native closure. Native was not rerun or relabeled fresh421.

The final dataset has JSON1632+PNG1656=3288files, missing0. All newly captured Web828PNG (including12supplementary stage images) are byte identical to the previous canonical dataset. Web root raw properties816/816 are unchanged; the changed role maps are exactlystage12. All12bodyBounds/layout records are unchanged. Original#6427mixed309/2c3d captures/reports, read-only audit maps, selected12captures and negative logs remain separately preserved.

The12roles are phone/tablet/landscape Mockup, default/flat MockupDevice and ResponsiveContainer default, each light/dark. Actual selectors uniquely identify their stage/boxRoot, computed dimensions equal stageBox, and actual fullMap31keys is retained exactly. Those rawCSSkeys were already measured before the overwrite; retaining them is not an expansion of the existing17-field comparator.

## Validation

- New real-loader regression first fails on the old producer with the original InfraFailure. After the four-line removal, existing capture_state21browser tests pass, retaining six shapes×400/800 loader/geometry and body-vs-stage pixel assertions. Root independently reran six stage tests/two widths12actual at421, allpass.
- Final touched2Dart files: fatal diagnostic0, format0changes. Official full contract guard exit0/78.21sec; seven pre-existing non-enforced migration warnings remain.
- Actual owned backend debug VM: HTTP200→reloadSources success→HTTP200, stage31keys before/after, identical body/stage PNG hashes. HTTP/VM/browser/PID closed. No shared DTD/app/SDK touched.
- No additional docs359build: the own delta is in capture-tool result serialization and its test; production site/app/Core libraries do not import the backend. Docs CSS/JS/Markdown, component renderer/default/API, SDK/dependencies/locks, model, manifest/probes, normalizer/comparator/thresholds/filters/skips/baselines are unchanged against integratedmain. UpstreamFrame validation remains a separate source-bound proof.

## Remaining contract boundary

Stage ProbeSpec.fields remains width/height2. Existing report→compareEntry ignores that declared subset and compares17fields, while Native stage has size-only values. This mismatch is unchanged and disclosed; no filtering, fabricated Native style, forced skip or comparator relaxation is used to obtain a pass. The immediate producer data-loss defect is separate from #6374's IndexedSwitcher root paint ownership; neither is solved by guessing a child representative.

All3814surface-style combinations and allcontrol states were not captured. The task restores valid raw protocol data and removes infrastructure errors; it does not resolve the remaining234pixel/368property differences.

Detailed ledger, exact commands, PIDs/exits, source hashes and independent review evidence: [parity-stage-raw-properties-2026-11-18.json](parity-stage-raw-properties-2026-11-18.json). Local immutable proof phase: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6429-stage-implementation-20261118._uj4pk2r`.
