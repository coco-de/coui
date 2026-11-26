# Radio card selected padding verification

This opt-in layout slot addresses a measured consumer design while preserving the default stable card geometry. It is not an application Figma acceptance claim.

## Design and contract

BottariFX original Figma `89ryJgV5reXIPgQqzmo4tX`, frame `58:1541`: selected row `58:1560` is 362×52, normal row `58:1564` is 362×51. Both use horizontal 16 / vertical 14 padding; inside borders are respectively 1.5 and 1. The original is unchanged. The existing consumer uses these dimensions, but the default CoUI selected stroke compensation keeps both rows at 51.

`CoreRadioGroupStyle.tileSelectedPadding` is nullable and applies only to card selections, including disabled selections. Null keeps existing compensation. Explicit padding is measured inside the selected border and may change layout. Flutter resolves geometry/scaling once; Web retains the existing resting border plus inset shadow for null and uses the selected physical border only for opt-in. Selected border widths smaller than resting remain clamped as before. No selection, focus, semantics, colors or default tokens change.

## Executed checks

- Core style suite: 60 passed; null/merge/copy/equality/hash included.
- Flutter card suite: 49 passed, including enabled/disabled, narrow 320px, text and theme scaling, selected vs resting geometry, keyboard Space activation and existing default geometry/semantics tests.
- Web card suite: 48 passed, including enabled/disabled selected padding and border output; existing default inset shadow assertions remain.
- Changed source/test files: `dart analyze --fatal-infos` reports no issues.
- Contract, Flutter resolver and Web resolver guards: pass. No baseline images regenerated.

## Ego Lite inspection

TaskSpace 8 / p1 only. Flutter release preview used actual RadioGroup widgets, light/dark and null/explicit padding. Selecting the second option updated all groups; keyboard focus was visibly retained. Automated widget test verifies Space activation.

Web preview renders actual Jaspr RadioGroup SSR using the official offline Tailwind harness and docs site reset. Computed card heights in both light/dark: default selected/resting 49.59375/49.59375; opt-in selected/resting 50.59375/49.59375. Border widths: default 1/1 (selected extra inset shadow); opt-in 1.5/1 with no additional shadow. Browser text metrics are not asserted equal to Flutter.

Initial local harness omitted the site's box-sizing reset and produced misleading selected heights. This was corrected with `docsContentTheme().styles` and `docsPreviewStyles()` before final measurement. It is not evidence of a production RadioGroup regression. Web preview is SSR-only; it does not establish hydrated keyboard behavior.

Local evidence: `/tmp/radio-padding-flutter-{initial,selected,keyboard}.png`, `/tmp/radio-padding-web-{light,dark}-reset.png`; test logs `/tmp/radio-padding-{core,flutter-scaled,web-final}.log`. These local artifacts are not portable CI artifacts.

## Pending

Protected required CI and official golden validation remain authoritative. No stored golden comparison or application-level strict Figma <2% result is claimed by this change. The app may adopt the slot only after upstream merge and dependency pin validation.
