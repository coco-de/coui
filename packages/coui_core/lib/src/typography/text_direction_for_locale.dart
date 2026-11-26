import 'package:coui_core/src/component/contracts/stacks/core_text_direction.dart';

/// Which way text runs in a given language.
///
/// One list, read by both platforms. The alternative — Flutter asking
/// its localization package and the Web asking a table of its own —
/// gives the two sides different answers for the same locale the moment
/// either list is edited, and the disagreement shows up as a page whose
/// root says one thing and whose widgets do another.
///
/// This is the direction *of the language*, not of a subtree. A
/// component that takes an explicit `textDirection` still wins over it;
/// this is only what the root starts from when nothing says otherwise.
abstract final class CoreTextDirectionForLocale {
  const CoreTextDirectionForLocale._();

  /// Language codes written right-to-left.
  ///
  /// The list is short because the set is: Arabic, Hebrew, Persian,
  /// Urdu, and the smaller languages that borrow their scripts. Listing
  /// right-to-left is the right way round — the left-to-right set is
  /// open-ended and a new language should default to it rather than
  /// disappear from the list and silently flip.
  static const Set<String> rightToLeftLanguages = {
    'ar', // Arabic
    'arc', // Aramaic
    'ckb', // Central Kurdish
    'dv', // Divehi
    'fa', // Persian
    'ha', // Hausa (Ajami script)
    'he', // Hebrew
    'khw', // Khowar
    'ks', // Kashmiri
    'ps', // Pashto
    'sd', // Sindhi
    'ur', // Urdu
    'uz_AF', // Uzbek (Afghanistan)
    'yi', // Yiddish
  };

  /// The direction [languageCode] is written in.
  ///
  /// Accepts a bare code (`ar`) or a full tag (`ar-EG`) — the tag is cut
  /// at the first separator, because direction is a property of the
  /// language and not of the region it is spoken in.
  static CoreTextDirection of(String languageCode) {
    if (languageCode.isEmpty) return .ltr;

    final normalized = languageCode.replaceAll('_', '-');
    final language = normalized.split('-').first.toLowerCase();

    // Checked before the bare language so `uz-AF` does not resolve to
    // Uzbek's usual left-to-right.
    if (rightToLeftLanguages.contains(normalized.replaceAll('-', '_'))) {
      return .rtl;
    }

    return rightToLeftLanguages.contains(language) ? .rtl : .ltr;
  }
}
