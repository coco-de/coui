# Component chrome strings

The built-in strings CoUI components draw themselves — button labels, form
validation messages, picker placeholders, calendar month and weekday names,
screen-reader labels — for `CoUILocalizations` (Flutter) and
`CouiLocalizations` (Web). App content does not belong here.

`i18n/<locale>.i18n.json` is the single source. Both platforms' locale
classes are generated from it; edit the JSON, never the generated Dart.

| Locale | Source | Status |
| --- | --- | --- |
| `ko` | written by hand (slang base locale) | reviewed |
| `en` | `DefaultCoUILocalizations` / `DefaultCouiLocalizations` | reviewed |
| `zh-Hans` `ja` `de` `fr` `es` `pt` `it` `ru` `ar` | AI translation (slang_gpt, gpt-4.1) + manual fixes | **AI-translated — awaiting native-speaker review** |

Month names, weekday abbreviations, AM/PM markers and date word order are
checked against CLDR (`intl` `DateSymbols`), not taken from the AI output.
`zh-Hans` serves every Chinese locale (`zh`); digits stay Latin in every
language.

## Workflow (from `packages/coui_i10n`)

```sh
# 1. edit i18n/ko.i18n.json (and en.i18n.json + the Default classes for English)
# 2. translate new / changed keys into the other languages
OPENAI_API_KEY=... dart run tool/translate_chrome.dart   # all 9, or --target=ja
# 3. review the diff (CLDR values, terminology), then generate both platforms
dart run tool/gen_chrome_localizations.dart
dart run tool/gen_chrome_localizations.dart --check     # CI-style staleness check
```

`english_identical.json` lists keys whose translation is intentionally the
same as English (acronyms, coinciding CLDR names, loanwords); the platform
tests treat any other English value in a translated locale as a leak.

The rules behind this layout live in
`.claude/rules/cross-platform/localization.md` ("번역 파이프라인").
