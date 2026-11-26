/// Pure locale-negotiation logic shared by `CoUIWeb`'s browser locale
/// resolution (the `navigator.languages` read lives in the web DOM
/// helper; the matching rule lives here so it is unit-testable without a
/// DOM).
library;

/// Picks the best entry from [supportedTags] (BCP 47 strings) for the
/// browser's [browserPrefs] (also BCP 47, highest priority first).
///
/// Mirrors Flutter `WidgetsApp.supportedLocales` resolution: walking the
/// browser preferences in priority order, an exact `lang-REGION` match
/// wins, then a language-only match. Casing / region of the returned
/// value is taken from [supportedTags] (the app's own list). Returns
/// `null` when nothing matches (or either list is empty).
String? matchLocale(List<String> browserPrefs, List<String> supportedTags) {
  if (supportedTags.isEmpty) return null;
  for (final pref in browserPrefs) {
    final prefLower = pref.toLowerCase();
    final prefLang = prefLower.split('-').first;
    // 1. Exact language + region match.
    for (final tag in supportedTags) {
      if (tag.toLowerCase() == prefLower) return tag;
    }
    // 2. Language-only fallback.
    for (final tag in supportedTags) {
      if (tag.toLowerCase().split('-').first == prefLang) return tag;
    }
  }
  return null;
}
