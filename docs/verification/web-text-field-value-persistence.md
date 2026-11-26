# Web TextField value persistence — 2026-10-27

## Trigger and cause

Enter `2025550199` into a PhoneInput seeded with `2025550151`, then open its
country picker. The edited number reverted to the seed. A plain TextField seeded
with `seed` similarly changed `edited seed` back to `seed` on a parent rebuild;
its selection moved from offset 2 to 4.

The actual Web TextField emitted `component.value ?? component.initialValue` on
every build. Jaspr writes the input's value property from that attribute, so the
initial seed became a repeated assignment. The widget already tracks `_lastValue`
for form reporting, clear features and validation. Uncontrolled builds now emit
that current value; controlled builds continue to use the parent's `value`.

Every input now listens for edits, including a plain field without callbacks.
Otherwise its cache would remain empty and a rebuild would erase unseeded input.
This adds one input listener to previously passive fields; it does not setState
on each edit. Existing feature/range changes retain their existing rebuild rules.
An initially empty uncontrolled field now emits `value=""`, rather than omitting
the attribute. No style, default appearance, Flutter behavior or public API changed.

## Tests and real-browser evidence

SDK Flutter 3.47.5; independent worktree based on main
`6a1a6a93a44bd40f8de0fb21b559c5a0b0c14bde`. This PR is independent of PhoneInput's
number-field style slot PR.

| Command/check | Expected | Evidence | Result |
| --- | --- | --- | --- |
| Web `dart test test/components/form/text_field_value_persistence_test.dart` before fix | Exposes seed reuse | Parent changes seed to `second`; expected retained `first`, got `second` | Negative reproduced |
| Web `dart test test/components/form/text_field*_test.dart test/components/form/phone_input*_test.dart` | Seed-once, controlled parent update, listener routing and existing behavior | 144 passed | PASS |
| Web `dart test test/components/form` | Composed form controls, validation, formatters and reporting remain valid | 793 passed | PASS |
| Changed-file `dart analyze --fatal-infos` | No issues | No issues found | PASS |
| Changed-file `dart format --output=none --set-exit-if-changed` | No drift | 0 changed | PASS |
| `git diff --check` | No whitespace errors | Exit 0 | PASS |

Ego Lite TaskSpace 8/p1 exercised before/after real components compiled using
`dart compile js -O2`, with the same isolated client harness and synthetic data.
The slot branch provided the before TextField implementation, which is identical
to main; the harness does not use the new PhoneInput slot. The after harness uses
this worktree. `before.html` and `/` were served on `127.0.0.1:49802`.

| Scenario | Before | Final after |
| --- | --- | --- |
| Seeded field, edit then parent rebuild | `edited seed` → `seed`; selection 2 → 4 | `edited seed`; selection 2 retained |
| Unseeded field with no onChanged, edit then rebuild | Separate final regression check | `unseeded edit`; selection 1 retained |
| Controlled field, edit and rebuild | Existing behavior retained | `controlled edit` remains |
| Controlled field, external parent update | Existing behavior retained | `updated` |
| Clear feature then parent rebuild | Previously seeded value could be re-emitted | Empty text retained |
| Phone number, open country picker | `2025550199` → `2025550151` | `2025550199` retained |
| Phone country selection +1 → +44 | Separate final regression check | +44 with `2025550199` retained |

The final snapshot and DOM value/selection extraction agree; screenshot
`/tmp/coui-uncontrolled-final.png` was inspected. This is a release-compiled
functional probe, not a full documentation-site appearance or Figma approval.
The probe does not load every docs-site chrome style. No alternate browser,
original Figma edit, golden rewrite or protection bypass was used.

The VM cannot synthesize a real HTMLInputElement target; input and selection were
therefore checked in Ego Lite. A first VM attempt to click clear hit that known
platform limitation and was replaced by the actual browser check, not counted as
a passing VM assertion. The first fix candidate also exposed the missing listener
for plain inputs; the final implementation and regression test cover that path.
The old form-wiring assertion expecting no listener outside a form was updated
to require value tracking while preserving absence of a form-only id.
