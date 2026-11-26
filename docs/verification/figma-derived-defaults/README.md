# Derived default verification — DotIndicator

`CoreDotIndicatorStyle.defaultActiveLength(double dotSize) => dotSize` is an
identity fallback to a sibling's resolved value. The earlier exporter recorded
`activeLength` as absent: this is not an absence and not a host-injected value.
The reader now exports an identity relationship under `derivedDefaults` only
when method body, argument, return type and same-style source field are
recognized. An unrecognized method is `dynamic-default-unresolved`, not
`absent`. This does not interpret arbitrary functions or validate a runtime
resolver's use of the method.

The Figma plugin refuses to build DotIndicator if this relationship no longer
says `dotSize`. Its fidelity reader compares selected and inactive marker
geometry on every size/selection variant, both the selected wrapper and the
actual painted rectangle. Missing nodes or unknown relationships are reported
as unchecked. Regression injections exercise a changed wrapper, changed paint,
a missing marker and changed metadata. The fidelity check proves equality on
the test canvas; it does not prove variable binding or an overridden pill style.

Read-only inspection of the [original CoUI component set](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ?node-id=3557:276)
checked all 15 variants (3 sizes × 5 selected positions). Selected and inactive
markers both measured 6×6, 8×8, or 12×12 for sm, md and lg respectively.
The original document was not changed. This is geometry only: the previous
88×24 pixel comparison still differs by 8.712% Web / 17.992% Flutter.

On the #5737 base (`14cab0bb4`):

- `dart test test/export_figma_components_test.dart test/figma_reader_test.dart`:
  38 passed, including unresolved expressions and committed export determinism.
- `dart test --exclude-tags perf --concurrency 2` in coui_core: 5,732 passed.
- `dart analyze . --fatal-warnings`: no errors/warnings (2,716 info findings).
- `npm run typecheck` and `npm run selftest`: passed. The full selftest included
  the visual relation and builder guard; the separately rerun fidelity test
  adds a guard-metadata corruption injection.
- The committed `components.json` was produced by the official exporter. 154
  components carry the additive map; only DotIndicator currently declares a
  relation. Existing fields, dispatches, absence and host-derived semantics are
  preserved. Plugin readback on the actual Figma document was not executed;
  only direct read-only layer measurements and local document-double tests
  were performed.

Latest CoUI main `deb49b5fe` has a separately reproduced reader-census failure
(228 > 227) and three Badge preview failures. Those existed before this branch;
no gate or baseline was changed to conceal them.

## Latest-main integration

Commit `5bd84049f` cherry-picks this change on the previous full DotIndicator
integration based on main `deb49b5fe`. The exporter/reader/census selection had
39 passes and one failure: the census still reports the exact clean-main
228 > 227 deficit. The exporter freshness/determinism checks pass, so its
metadata was regenerated correctly against the newer main as well. Plugin
`npm run typecheck` and the complete `npm run selftest` passed at this
integration commit. Targeted Dart analysis had no errors or warnings. No new
full Flutter suite was needed for this exporter/plugin-only change; earlier
DotIndicator test results remain tied to their actual commits. The actual
Figma plugin has not been executed against the live file.
