/// The language the docs site renders in.
///
/// The site is Korean-primary (`process/docs-site.md`), so every CoUI root
/// it mounts — the page root, each client island, the Web preview pane and
/// the embedded Flutter preview — states this one language. Left unstated,
/// each root negotiates on its own: the Web roots fall back to their
/// default `en-US` (and write it to `<html lang>`), and the Flutter preview
/// resolves to English, so the components' own text (weekday names,
/// previous / next, empty states) renders in English beside Korean pages.
///
/// Pure Dart so the jaspr site and the Flutter preview read the same value —
/// each wraps it in its own `Locale` type.
library;

/// ISO-639 language code of the docs site.
const String kDocsLanguageCode = 'ko';
