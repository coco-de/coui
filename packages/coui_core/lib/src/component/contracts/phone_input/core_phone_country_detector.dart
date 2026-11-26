import 'package:coui_core/src/component/contracts/phone_input/core_country.dart';

/// Platform-independent typing detection for the [CoreCountry] a phone
/// number's dial code belongs to.
///
/// Lives here — beside [CoreCountry] — rather than in either platform's
/// `PhoneInput` so Flutter and Web read the same match instead of each
/// carrying its own hand-copied version.
abstract final class CorePhoneCountryDetector {
  /// Detects the [CoreCountry] whose dial code the typed [input] starts
  /// with, searching only inside [countries] (never the full
  /// [CoreCountry.all] — a caller who narrowed the list on purpose should
  /// not have detection reach past it).
  ///
  /// Returns `null` — meaning "leave the current selection untouched" —
  /// when:
  ///
  /// - [input] does not start with `+`. Detection is `+`-triggered only:
  ///   without it, digits the typist writes are the national number, not a
  ///   dial code, and matching them would flip the country out from under
  ///   someone typing their own local number.
  /// - no dial code in [countries] is a prefix of [input].
  /// - more than one country in [countries] has a dial code of the same
  ///   longest matching length (e.g. `+7` is both Kazakhstan and Russia).
  ///   Choosing between them needs a tie-break table this function
  ///   deliberately does not carry, so an ambiguous match is treated the
  ///   same as no match — the caller's current country stands.
  ///
  /// Matching is **longest-prefix**, not "first `startsWith` hit": `+1` is
  /// itself a dial code (US / Canada) but is also a strict prefix of dozens
  /// of longer ones (`+1242` Bahamas, `+1809` Dominican Republic, …).
  /// Picking the first match by list order would resolve every `+1xxx`
  /// number to whichever of those happens to come first, and the Caribbean
  /// countries the longer codes belong to would never be detected.
  ///
  /// Rows that are not real ISO-3166 countries (satellite / international
  /// network allocations, whose [CoreCountry.code] is 3 letters rather than
  /// 2) are never matched — [CoreCountry.flagEmoji] only knows how to
  /// render a 2-letter code, so selecting one of these would hand the
  /// caller a country whose flag can't be drawn.
  static CoreCountry? detect(String input, List<CoreCountry> countries) {
    if (!input.startsWith('+')) return null;

    CoreCountry? best;
    var matchesAtBestLength = 0;
    for (final country in countries) {
      if (country.code.length != 2) continue;
      if (!input.startsWith(country.dialCode)) continue;

      final length = country.dialCode.length;
      if (best == null || length > best.dialCode.length) {
        best = country;
        matchesAtBestLength = 1;
      } else if (length == best.dialCode.length) {
        matchesAtBestLength += 1;
      }
    }

    return matchesAtBestLength == 1 ? best : null;
  }
}
