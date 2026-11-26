/// Text expansion for layout testing.
///
/// A design system with two locales — English and Korean — has never
/// been shown a string that got *longer* when translated. Korean runs
/// about half the length of its English source, so every layout in the
/// kit has only ever been asked to hold text that shrank.
///
/// Translation into European languages goes the other way: German
/// +20–35%, French +15–25%, Finnish +30–40%. A container sized to the
/// English string clips, wraps into its neighbour, or pushes a row past
/// its bounds, and none of that is visible until the locale ships.
///
/// This produces the longer string ahead of that, so the failure is a
/// red test rather than a bug report.
abstract final class CorePseudoLocale {
  const CorePseudoLocale._();

  /// The default growth: the top of the observed range, so a layout
  /// that survives this survives the languages the range came from.
  static const double defaultFactor = 1.35;

  /// Marks the start of an expanded string.
  ///
  /// The markers are the point. A clipped string with no marker is
  /// indistinguishable from a legitimately short one — "Save" and
  /// "Save changes to…" both look like ordinary labels. With the
  /// brackets, a missing `⟧` says the container ate the end.
  static const String startMarker = '⟦';

  /// Marks the end of an expanded string. See [startMarker].
  static const String endMarker = '⟧';

  /// Accented look-alikes, so an untranslated string stands out.
  ///
  /// Same letter shapes, so the text still reads and a reviewer can
  /// tell which control they are looking at — while a string that the
  /// component hardcoded instead of pulling from the locale stays
  /// plain ASCII and is immediately visible as the one that did not go
  /// through translation.
  static const Map<String, String> _accents = {
    'a': 'á',
    'b': 'ƀ',
    'c': 'ç',
    'd': 'ð',
    'e': 'é',
    'f': 'ƒ',
    'g': 'ģ',
    'h': 'ĥ',
    'i': 'í',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ļ',
    'm': 'ɱ',
    'n': 'ñ',
    'o': 'ó',
    'p': 'þ',
    'q': 'ɋ',
    'r': 'ŕ',
    's': 'š',
    't': 'ţ',
    'u': 'ú',
    'v': 'ṽ',
    'w': 'ŵ',
    'x': 'ẋ',
    'y': 'ý',
    'z': 'ž',
    'A': 'Á',
    'B': 'Ɓ',
    'C': 'Ç',
    'D': 'Ð',
    'E': 'É',
    'F': 'Ƒ',
    'G': 'Ģ',
    'H': 'Ĥ',
    'I': 'Í',
    'J': 'Ĵ',
    'K': 'Ķ',
    'L': 'Ļ',
    'M': 'Ṁ',
    'N': 'Ñ',
    'O': 'Ó',
    'P': 'Þ',
    'Q': 'Ɋ',
    'R': 'Ŕ',
    'S': 'Š',
    'T': 'Ţ',
    'U': 'Ú',
    'V': 'Ṽ',
    'W': 'Ŵ',
    'X': 'Ẋ',
    'Y': 'Ý',
    'Z': 'Ž',
  };

  /// [text] as it would look after translation into a longer language.
  ///
  /// Letters become accented look-alikes, the string grows to [factor]
  /// of its original length, and the result is bracketed so clipping is
  /// visible at either end.
  ///
  /// Padding is added as space-separated runs rather than one unbroken
  /// word. Real translations wrap, so a container that grows to fit is
  /// passing honestly; padding with an unbreakable run would fail every
  /// container that wraps correctly and report it as a layout bug.
  ///
  /// An empty string stays empty — a component that renders nothing
  /// should not start rendering brackets.
  static String expand(String text, {double factor = defaultFactor}) {
    if (text.isEmpty) return text;

    final accented = StringBuffer();
    for (final char in text.split('')) {
      accented.write(_accents[char] ?? char);
    }

    final target = (text.length * factor).ceil();
    final padding = target - text.length;
    if (padding <= 0) return '$startMarker$accented$endMarker';

    // Runs of this length plus a space, so the tail can wrap where a
    // translated sentence would.
    const runLength = 4;

    final pad = StringBuffer();
    for (var i = 0; i < padding; i++) {
      pad.write(i.isEven ? 'ẍ' : 'ŵ');
      if (i % runLength == runLength - 1 && i != padding - 1) pad.write(' ');
    }

    return '$startMarker$accented $pad$endMarker';
  }

  /// Whether [text] came out of [expand].
  ///
  /// A rendered string that is missing its end marker was cut off.
  static bool isComplete(String text) =>
      !text.startsWith(startMarker) || text.endsWith(endMarker);
}
