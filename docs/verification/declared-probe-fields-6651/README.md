# Compare only the fields declared for each probe (#6651)

`ProbeSpec.fields` already defines which normalized fields a role expects.
The two comparison CLIs discarded that declaration and compared all 17 fields.
A stage declaring only width/height therefore failed on undeclared Native-null
text and paint fields even when its two measured dimensions matched.

Both CLIs now pass the declared set through the existing comparator. Only
those field results contribute to its verdict. Full observations remain intact,
including width context used to decide whether a border/outline is painted.
Existing direct callers still default to all fields. Unknown JSON field names
still fail manifest parsing; unsupported comparator fields fail closed.

An empty declaration is now an input-format error when property comparison
actually runs, yielding the existing per-role infra/exit2 handling. Pixel-only
empty declarations remain valid. This is an internal measurement input-contract
correction; it is not a claim that every CLI behavior is unchanged. One existing
ICC property-only fixture now explicitly declares its intended all-fields set;
its pixel-only empty declarations and old source/hash remain preserved.

| Check | Actual result |
| --- | --- |
| Immutable original CLI4 | Original 3 PASS / 1 FAIL → same SHA candidate 4 PASS |
| Permanent regression8 | 8 PASS; includes both CLIs' active/inactive empty gates |
| Related13 files | 123 PASS / 0 FAIL / no load errors |
| Touched analysis / final fixture analysis | exit0 / exit0; no INFO ignored |
| Immutable J property rejudge | keys452 PASS / 338 FAIL / 50 structural, unchanged |
| Property role changes | stage12 FAIL→PASS; overall key changes0 |
| Immutable J pixel rejudge | keys559 PASS / 281 FAIL; all role verdicts unchanged |
| Both actual report command exits | 1 / 1; infra0 |

The rejudge uses capture source `a5a6b6f76e89e32d11df90ee9bcb4b50b5ff118d`
(J), with 840 keys/852 roles and all3,384 raw hashes/symlink targets unchanged.
Its original Git baselines, allowlist and manifest remain unchanged. All3,932
ALL entries and840 default entries have nonempty declarations (60/12 stages).
The 12 stages' dimension result objects equal their original payloads; only
15 undeclared result fields per stage are removed. All root verdicts and the
50 structural omissions remain unchanged. This is a historical tool rejudge,
not a fresh latest-main capture or 12 component fixes.

First analysis INFO4 and a repo test's nonexistent `failedCount` lookup are
preserved; the lookup was corrected to actual `matrix.counts.fail` without
changing the expected CLI2. External4 overlaps the first4 permanent cases.
Two rejudge setup attempts ran no comparison. Attempt3 ran both reports,
then its Python metadata-name collision caused outer exit1. A separate readback
verified the preserved reports, raw-after and frozen source/metadata without
rerunning comparison; the actual report exits remain1/1.

No CoUI public API, Core/defaults, capture/normalizer, raw JSON, manifest,
role keys, thresholds, baseline or allowlist changes. Existing px0.5,
alpha0.0005 and pixel32 thresholds/ratios remain. Images, UI builds and browser
verification are N/A for this tool-only change. Each CLI ran in a fresh owned
Dart process; no resident UI or browser hot-reload claim is made.

`verification.json` binds the executed working-file hashes and portable
artifact-relative evidence paths. It distinguishes historical capture J,
original reproduction, candidate runs and orchestration failures.
