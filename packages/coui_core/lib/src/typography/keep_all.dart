/// Word-level line breaking — CSS `word-break: keep-all` — decided once
/// for both platforms.
///
/// The Web reaches keep-all through the CSS property itself and never
/// calls this. Flutter has no API that chooses a line-breaking mode, so it
/// draws a display string instead: a U+2060 WORD JOINER wherever keep-all
/// removes a break opportunity, which every UAX #14 line breaker honours
/// (LB11). Which pairs those are is the whole job of this class — kept
/// here so the two platforms cannot disagree about it, and pinned by one
/// vector table (`test/fixtures/keep_all_vectors.json`) that the Core,
/// Flutter and Web tests all read.
library;

import 'package:characters/characters.dart';

/// Where keep-all forbids a line break, and the display string that
/// forbids it on a renderer without a keep-all mode.
///
/// The pairs follow Chromium's keep-all, judged the way Chromium judges
/// them: a break is removed when the character before it and the
/// character after it are both letters or numbers — a combining mark
/// standing for the letter it sits on — and neither belongs to a script
/// broken by dictionary (Thai and its neighbours). Every other opportunity
/// stays: at a space, after punctuation, around symbols and emoji, at an
/// explicit zero-width space.
///
/// Chromium reads each side as one UTF-16 code unit, so a character
/// outside the Basic Multilingual Plane — a rare ideograph, a
/// supplementary variation selector — is never a letter to it, and keeps
/// its break opportunities under keep-all. The same reading is kept here:
/// holding together what Chrome breaks would make the two platforms
/// disagree. A second combining mark is a mark, not a letter, for the same
/// reason.
///
/// A joiner goes only where one side is an East Asian letter (Hangul,
/// Han, kana, Bopomofo, Yi and the fullwidth Latin letters and digits).
/// Those are the pairs the default rules break — UAX #14 lets a line end
/// between any two Hangul syllables, ideographs or kana and on either
/// side of them — and the reason a Korean word splits mid-syllable in the
/// first place. Between two Latin letters or digits the default rules
/// already hold the pair together, so a joiner there would change the
/// string and nothing else.
abstract final class CoreKeepAll {
  const CoreKeepAll._();

  /// U+2060 WORD JOINER — zero width, forbids a line break on either side.
  static const String wordJoiner = '\u2060';

  /// Letters and numbers — the units keep-all holds together.
  static final RegExp _letterOrNumber = RegExp(
    r'^[\p{L}\p{N}]$',
    unicode: true,
  );

  /// Combining marks — they stand for the letter before them.
  static final RegExp _mark = RegExp(r'^\p{M}$', unicode: true);

  /// Scripts whose words a line breaker finds by dictionary. Chromium
  /// leaves their opportunities alone under keep-all, so a joiner never
  /// lands next to them.
  static final RegExp _dictionaryBroken = RegExp(
    r'^[\p{sc=Thai}\p{sc=Lao}\p{sc=Myanmar}\p{sc=Khmer}\p{sc=Tai_Le}'
    r'\p{sc=New_Tai_Lue}\p{sc=Tai_Tham}\p{sc=Tai_Viet}\p{sc=Ahom}]$',
    unicode: true,
  );

  /// East Asian letters — the ones UAX #14 lets a line end beside.
  /// `scx` rather than `sc` so a mark of the script written in the
  /// Common script (the katakana prolonged-sound mark `ー`) still counts.
  static const String _eastAsianClass =
      r'[\p{scx=Hangul}\p{scx=Han}\p{scx=Hiragana}\p{scx=Katakana}'
      r'\p{scx=Bopomofo}\p{sc=Yi}\uFF01-\uFF60]';

  static final RegExp _eastAsian = RegExp('^$_eastAsianClass\$', unicode: true);

  static final RegExp _containsEastAsian = RegExp(
    _eastAsianClass,
    unicode: true,
  );

  /// The offsets in [text] (UTF-16 code units, ascending) where keep-all
  /// removes a break opportunity.
  ///
  /// Each offset sits between two grapheme clusters, so a joiner inserted
  /// there never splits a character, a combining sequence or a syllable
  /// built from conjoining jamo.
  static List<int> joinOffsets(String text) {
    if (!_containsEastAsian.hasMatch(text)) return const [];

    final offsets = <int>[];
    var offset = 0;
    String? previous;
    for (final cluster in text.characters) {
      if (previous != null && _holdsTogether(previous, cluster)) {
        offsets.add(offset);
      }
      offset += cluster.length;
      previous = cluster;
    }

    return offsets;
  }

  /// [text] with a [wordJoiner] inserted at each of [offsets] — offsets
  /// into [text], ascending, as [joinOffsets] returns them.
  static String joinAt(String text, List<int> offsets) {
    if (offsets.isEmpty) return text;

    final buffer = StringBuffer();
    var start = 0;
    for (final offset in offsets) {
      buffer
        ..write(text.substring(start, offset))
        ..write(wordJoiner);
      start = offset;
    }
    buffer.write(text.substring(start));

    return buffer.toString();
  }

  /// The string a renderer without a keep-all mode draws to break lines
  /// where keep-all would.
  ///
  /// A display string only: what is announced, copied or edited stays
  /// [text].
  static String join(String text) => joinAt(text, joinOffsets(text));

  /// Whether keep-all removes the break between the clusters [left] and
  /// [right] — read from the code unit on each side of it, as Chromium
  /// reads them.
  static bool _holdsTogether(String left, String right) {
    final before = _unitBefore(left);
    final after = String.fromCharCode(right.codeUnitAt(0));

    return _isWordUnit(before) &&
        _isWordUnit(after) &&
        (_eastAsian.hasMatch(before) || _eastAsian.hasMatch(after));
  }

  /// The code unit Chromium judges on the left of a break: the last one
  /// of [cluster], or the one before it when the last is a combining mark.
  static String _unitBefore(String cluster) {
    final last = String.fromCharCode(cluster.codeUnitAt(cluster.length - 1));
    if (cluster.length < 2 || !_mark.hasMatch(last)) return last;

    return String.fromCharCode(cluster.codeUnitAt(cluster.length - 2));
  }

  /// A lone surrogate is neither a letter nor a number, so a character
  /// outside the Basic Multilingual Plane never is one here.
  static bool _isWordUnit(String unit) =>
      _letterOrNumber.hasMatch(unit) && !_dictionaryBroken.hasMatch(unit);
}
