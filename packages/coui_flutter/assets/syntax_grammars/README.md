# Additional TextMate grammars

`syntax_highlight_lite 0.0.1` embeds only Dart. These JSON, YAML, and SQL
grammars preserve CodeSnippet's existing language support through
`Highlighter.addLanguage`, without depending on the Flutter-only
`syntax_highlight` package or its editor/clipboard plugins.

Source: `syntax_highlight 0.4.0`, `grammars/{json,yaml,sql}.json`
([upstream](https://github.com/serverpod/syntax_highlight)).
JSON and YAML are unchanged. SQL's leading `(?i)` flags in match patterns
are expanded to explicit ASCII case pairs (`select` → `[sS][eE][lL][eE][cC][tT]`,
`a-z` → `a-zA-Z`), preserving case-insensitive keywords with Dart's RegExp,
which rejects inline flags. Capture groups and scopes are preserved.

These files are the one source for both platforms. Flutter loads them as
package assets; a Jaspr page has no asset bundle, so `coui_web` carries the
same bytes compiled in
(`packages/coui_web/lib/src/components/display/code_snippet/code_snippet_grammars.g.dart`).
After editing a grammar here, regenerate that file — a `coui_web` test fails
until the two match:

    dart run packages/coui_web/tool/gen_code_snippet_grammars.dart

Copyright 2023 The Serverpod authors;
BSD-3-Clause terms are reproduced in `../../LICENSE` and included in the
package's generated Flutter license bundle, and in `packages/coui_web/LICENSE`
for the compiled-in copy.
