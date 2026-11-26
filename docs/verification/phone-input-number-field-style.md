# PhoneInput number field style slot — 2026-10-27

## Problem and scope

A consumer configured `bodyTextStyle` to 17px/600 expecting it to affect the
phone number. Inspection of the actual Flutter `EditableText` showed 14px/400:
that slot only paints country-name labels. Both platform resolvers constructed
the composed number `TextField` from the chromeless default and placeholder tone,
without a public nested override. The old contract documentation incorrectly
claimed `bodyTextStyle` also styled number/search inputs.

`CorePhoneInputStyle.numberFieldStyle` now provides that missing child-component
slot. It is nullable, recursively merged through theme/instance overrides, and
forwarded through the existing resolved field in Flutter and Web. The default is
the existing chromeless style. Nested placeholder style wins over the convenience
`placeholderColor`, as it does for the independent search field. No input handler,
country selection, validation, disabled state, theme default, or baseline changes.

## Verification

SDK: Flutter 3.47.5; base CoUI `6a1a6a93a44bd40f8de0fb21b559c5a0b0c14bde`.
Commands are run from the corresponding package unless a root path is stated.

| Command/check | Expected | Evidence | Result |
| --- | --- | --- | --- |
| Core `dart test test/phone_input_number_field_style_test.dart test/phone_input_style_test.dart` | Recursive merge, equality/hash/copy, independent search, unchanged default | 16 passed | PASS |
| Flutter `flutter test --no-pub test/components/form/phone_input_number_field_style_test.dart test/components/form/phone_input_test.dart test/components/form/phone_input_reading_test.dart` | Actual input receives typography; existing behavior remains | 40 passed before the additional scaling case | PASS |
| Flutter `flutter test --no-pub test/components/form/phone_input_number_field_style_test.dart` | Actual renderer applies 2× text scale, disabled state remains | 3 passed; rendered 17px scales to 34px | PASS |
| Web `dart test test/components/form/phone_input_number_field_style_test.dart test/components/form/phone_input_style_test.dart test/components/form/phone_input_test.dart` | Actual DOM receives CSS; existing behavior remains | 39 passed, including final resolver whitespace cleanup | PASS |
| Flutter `flutter test --no-pub test/theme/preset_snapshot/preset_render_snapshot_test.dart` | Existing four-preset render contracts unchanged | 295 passed without baseline regeneration | PASS |
| Root `dart analyze --fatal-infos` on the three changed style files and three new tests | No issues | No issues found | PASS |
| Root `dart format --output=none --set-exit-if-changed` on those six files | No drift | 0 changed | PASS |
| Root `bash scripts/guards/resolver/verify_contracts.sh` | Core/platform contract and style readers consistent | All checks passed; seven existing non-enforced backlog warnings outside PhoneInput | PASS |
| Root `dart run tool/generate_style_tables.dart --check phone-input` | Generated API table matches contract | 0 drifted | PASS |
| Docs Core `dart test test/registry/docs_api_sync_test.dart` | Documentation and API stay synchronized | 11 passed | PASS |
| `git diff --check` | No whitespace errors | Exit 0 | PASS |

## Actual render inspection and limits

Ego Lite TaskSpace 8/p1 opened the isolated Web preview compiled with
`dart compile js -O2` using this worktree's package configuration and the actual
CoUI `ThemeConfig` CSS variables/Tailwind configuration. Computed input styles:

| Input | Font size | Weight | Disabled |
| --- | --- | --- | --- |
| Existing default | 14px | 400 | false |
| Number-field override | 17px | 600 | false |
| Same override, disabled | 17px | 600 | true |
| Country search under overridden PhoneInput | 14px | 400 | false |

The overridden input accepted `2025550199` through real browser input; the country
search accepted `Canada` and filtered to its real option. All numbers are synthetic.
The minimal preview is a typography/interaction probe, not the full docs-site
SSR/chrome parity gate: it does not include all generated site styles. It therefore
does not establish whole-component cross-platform pixel parity. Browser evidence:
`/tmp/coui-phone-slot-web-themed.png`. Flutter RepaintBoundary captures load the
actual Pretendard font and render default/custom/disabled inputs; the light capture was viewed
in Ego Lite, and both final captures were inspected directly: `/tmp/coui-phone-slot-preview/{light,dark}.png`. The final
dark capture uses `ThemeData.fromCore(CoreThemePresets.dark)` rather than a dark
background alone. This is a component render probe, not an app golden approval.

An unrelated observation in the minimal Web probe: opening the country popup
restored the initial seeded number after editing. No event/widget code is changed
here; this needs a separate before/after reproduction before diagnosing it as a
library regression. It is not counted as a passing persistence check.

The rendered-scaling test first read nullable `EditableText.textScaler`, which is
null when inherited; the final assertion reads the actual renderer's resolved
text scaler. Initial probe setup errors were corrected before collecting the
listed passing evidence. No ignored lint, baseline rewrite, original-design
modification, or branch-protection exception was used.

## Applicability

The contract/default/merge/reader and public documentation checks apply. No new
component registry, theme component type, enum, alias, capability, generated
chain API, or example source was introduced, so their regeneration is unnecessary.
The existing generated style table was regenerated using its official tool.
BottariFX must consume this through a normally merged CoUI main pin with its own
sync/check and recapture; this library PR does not claim its Figma target achieved.
