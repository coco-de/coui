# Composed Web control paint — #6476

The session-wide health check found seven new Web assertion failures after
#6449 and #6457. The four unchanged test files passed all 45 cases at the
session-start commit `1e5fa174`; at renderer source `54851a80`, seven failed.
They assumed a particular CSS serialization after private state/focus rules
had changed. Missing these composition tests before merging was a validation
gap, not a preexisting failure.

This repair changes tests only. SwitchField, MultipleChoice, Chip and Carousel
checks now verify the actual composed public child inputs. SwitchField's
existing material-surface assertion is retained. The Chip ramp test retains
numeric 3/8/12 expectations and a differing caller-ramp negative control.
The permanent browser regression additionally verifies actual rendered paint
and real input states, rather than just replacing expected CSS strings.

## Actual browser coverage

`tool/parity/test/web/composed_control_paint_test.dart` renders the same seven
public callers under the official docs theme in light/dark SSR and optimized
hydration. It checks:

- SwitchField off/on: highest-container/primary track paint, 40×24 geometry
  and an inert inner track.
- MultipleChoice's deprecated public flat-color slots: selected red and
  unselected green, both radio faces, and real hover/press/keyboard focus.
- A transparent resting Chip: semantic ink and independent source-over
  calculations for 3% hover, 8% focus and 12% pressed paint.
- Carousel slide/banner/caller override: the focused selected dot's ring and
  surface/transparent gap, actual axis-arrow selection and endpoint clamping.
- SSR/O2 rest roles and geometry, with console/runtime errors and external
  requests required to remain empty.

Expected state colors use independent arithmetic and semantic palette values,
not the production wash helper or a parser for private CSS variables. Numeric
computed-color precision is accounted for; parity thresholds and golden
baselines are not changed. The test uses Core's existing focus-ring token and
existing axis-arrow keyboard contract; Home/End selection is not required.

Independent review recalculated 36 state-color checks, 42 focus-band
observations and 30 arrow-selection checks from the first successful browser
record. Maximum RGB serialization difference was 0.000115 on a 0–255 channel;
alpha difference was zero. This is bounded coverage, not a claim about all
possible CoUI callers or browsers.

## Executed checks

The seven Dart test/fixture files were frozen before the complete run.

| Source and scope | Result | Wall time |
|---|---|---:|
| `a59c6a86` + final four VM test files; complete existing Web VM directory | 450 files, 9,283 visible passes, 0 failures, 0 skips | 1,159.20 s |
| Frozen browser test/fixtures; Chrome 150, SSR/O2 light/dark | 2 passes | 67.60 s |
| All seven changed Dart files; fatal warnings/infos | exit 0 | 27.63 s |
| Format all seven Dart files | exit 0, no files changed | 0.03 s |
| `02787f3d`, normal integration of main `5efd1caf`; affected VM tests | 45 passes, 0 failures/skips | 18.37 s |
| Same integrated source; permanent SSR/O2 browser tests | 2 passes | 69.61 s |
| Same integrated source; existing AppBar Chrome test | 1 pass | 7.33 s |

The full run's 450 hidden loading events are excluded from 9,283. The earlier
15.96-second focused run preceded two lint-only test edits; the complete run
and integrated 45-case run verify the final frozen files. The full run at
`a59c6a86` is not relabeled as a full run at the later integration commit.
Main #6478's NavigationBar changes were integrated without modifying this
repair's seven test-file hashes. All recorded owned test/browser groups closed.

## Reproduction

Use the project's resolved package configuration, pinned SDK and existing
`test` 1.32.0 entry point. Set `COUI_TEST_DART`, `COUI_PACKAGE_CONFIG` and
`COUI_TEST_ENTRY` to those absolute paths. No dependency refresh is required.

From `packages/coui_web`, the full VM command was:

```sh
"$COUI_TEST_DART" --packages="$COUI_PACKAGE_CONFIG" "$COUI_TEST_ENTRY" \
  --reporter=json --timeout 2m --concurrency 4 --compiler source
```

From the repository root, set `COUI_COMPOSED_PAINT_CHROME` to the verified
Chrome executable and optionally `COUI_COMPOSED_PAINT_EVIDENCE` to an output
directory. The permanent browser command was:

```sh
"$COUI_TEST_DART" --packages="$COUI_PACKAGE_CONFIG" "$COUI_TEST_ENTRY" \
  --reporter=json --timeout 2m --compiler source --concurrency 1 \
  tool/parity/test/web/composed_control_paint_test.dart
```

The supported source compiler avoids retaining a copied kernel for every test
file. The initial broad health run's disk-exhaustion logs remain preserved;
only its verified, closed, owned compiler-temp directory was reclaimed.

## Scope and limits

This PR changes no runtime source, public API, Core design value, dependency,
parity comparator, capture helper, committed PNG or expected JSON. A new docs
build and Figma changes are not applicable to this test-only repair.

The broader health run at `54851a80` recorded 29,578 passes, 14 assertion
failures and four existing skips. Separate session-start controls proved that
Core's one Figma-staleness failure and Native's six golden/preset failures
already existed, with identical recorded outputs. They are not repaired or
hidden here. The last renderer parity measurement (582 pixel passes / 234
differences) remains a separate `54851a80` result, with explicit earlier Web
capture reuse; it is not a fresh whole-main measurement after #6478. #6131
continues to track incomplete parity work. These results do not prove that
CoUI has no bugs.
