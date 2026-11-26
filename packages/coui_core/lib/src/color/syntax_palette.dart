/// Syntax colours — the code-highlighting slots: keyword, type, function
/// and string.
///
/// Four things hold for everything in this file:
///
/// - **Three of the four are no brand's.** A keyword, a type and a string
///   read the same values in every brand: they tell the parts of code
///   apart and say nothing about the brand. Their six primitives — one
///   hue per slot, a tone for light mode and a tone for dark mode — live
///   here, and every mapping reads them through
///   [CoreSyntaxPalette.applyTo].
/// - **Function is the brand's.** [CoreSyntaxSlot.function] reads a step
///   of the brand's own info ramp, handed to [CoreSyntaxPalette.applyTo]
///   by the mapping. It has no primitive here, so it is linked to the
///   brand's vocabulary by value, never by name.
/// - **Outside every brand vocabulary.** The six primitives are kept out
///   of every `CoreSchemeSource.primitives` on purpose. That vocabulary is
///   per-brand, and a value that is the same in every brand does not
///   belong to any one of them. They live under the brand-less
///   [CoreSyntaxPalette.namespace] instead, and a semantic slot reaches
///   them by name.
/// - **High contrast keeps the normal values.** Each tone already clears
///   4.5:1 on the tones code is shown on, so a high-contrast table states
///   the same values as its normal table and a raise leaves the slots to
///   its base.
library;

import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// The three syntax hues that have primitives of their own, in the order
/// every list of them is written.
enum CoreSyntaxHue {
  /// Purple — [CoreSyntaxSlot.keyword].
  purple,

  /// Yellow — [CoreSyntaxSlot.type].
  yellow,

  /// Lime — [CoreSyntaxSlot.string].
  lime,
}

/// The two tones every [CoreSyntaxHue] has, named by the mode that reads
/// them: [light] is the darker tone a light page needs, [dark] the lighter
/// tone a dark page needs.
enum CoreSyntaxShade {
  /// Read in light mode and high-contrast light.
  light,

  /// Read in dark mode and high-contrast dark.
  dark;

  /// The tone [brightness] reads.
  static CoreSyntaxShade of(CoreBrightness brightness) => switch (brightness) {
    .light => light,
    .dark => dark,
  };
}

/// The four syntax slots.
enum CoreSyntaxSlot {
  /// `syntax-keyword` — keywords, storage and control words.
  keyword(CoreColors.syntaxKeyword, CoreSyntaxHue.purple),

  /// `syntax-type` — type names, classes and numeric constants.
  type(CoreColors.syntaxType, CoreSyntaxHue.yellow),

  /// `syntax-function` — function names. Reads the brand's info ramp, so it
  /// has no [hue].
  function(CoreColors.syntaxFunction, null),

  /// `syntax-string` — string literals.
  string(CoreColors.syntaxString, CoreSyntaxHue.lime);

  const CoreSyntaxSlot(this.token, this.hue);

  /// The slot's token.
  final CoreColorToken token;

  /// The brand-less hue the slot reads, or `null` for [function].
  final CoreSyntaxHue? hue;
}

/// The syntax colour table — the one place a brand-less syntax value is
/// written.
///
/// Fixed hex, as the designer authored it: the values are not read off
/// any ramp.
abstract final class CoreSyntaxPalette {
  /// The brand-less namespace the primitives live under —
  /// `syntax/<hue>/<shade>`. Reserved: no brand may use it as its id.
  static const String namespace = 'syntax';

  static const Map<CoreSyntaxHue, Map<CoreSyntaxShade, CoreColor>> _values = {
    CoreSyntaxHue.purple: {
      CoreSyntaxShade.light: CoreColor(0xFF8956A9),
      CoreSyntaxShade.dark: CoreColor(0xFFC792EA),
    },
    CoreSyntaxHue.yellow: {
      CoreSyntaxShade.light: CoreColor(0xFF8C650A),
      CoreSyntaxShade.dark: CoreColor(0xFFFFCB6B),
    },
    CoreSyntaxHue.lime: {
      CoreSyntaxShade.light: CoreColor(0xFF567516),
      CoreSyntaxShade.dark: CoreColor(0xFFC3E88D),
    },
  };

  /// The value of [shade] for [hue].
  static CoreColor tone(CoreSyntaxHue hue, CoreSyntaxShade shade) =>
      _values[hue]![shade]!;

  /// The primitive name of [shade] for [hue] — `syntax/purple/light`.
  static String primitiveName(CoreSyntaxHue hue, CoreSyntaxShade shade) =>
      '$namespace/${hue.name}/${shade.name}';

  /// All six primitives, [primitiveName] → value — hue by hue, each hue's
  /// shades in [CoreSyntaxShade] order.
  ///
  /// Never merged into any `CoreSchemeSource.primitives`; see the library
  /// documentation for why.
  static Map<String, CoreColor> get primitives => {
    for (final hue in CoreSyntaxHue.values)
      for (final shade in CoreSyntaxShade.values)
        primitiveName(hue, shade): tone(hue, shade),
  };

  /// Every slot that reads a brand-less tone in [brightness], as the slot's
  /// CSS key → [primitiveName] — three entries.
  ///
  /// [CoreSyntaxSlot.function] is absent: it reads the brand's own info
  /// step. High contrast reads the same tones as the normal mode of the
  /// same brightness, so this takes no high-contrast flag.
  static Map<String, String> primitiveLinks(CoreBrightness brightness) => {
    for (final slot in CoreSyntaxSlot.values)
      if (slot.hue case final hue?)
        slot.token.name: primitiveName(hue, CoreSyntaxShade.of(brightness)),
  };

  /// The value [slot] takes in [brightness] — [function] for
  /// [CoreSyntaxSlot.function], the table's tone for the other three.
  static CoreColor valueOf(
    CoreSyntaxSlot slot,
    CoreBrightness brightness, {
    required CoreColor function,
  }) => switch (slot.hue) {
    final hue? => tone(hue, CoreSyntaxShade.of(brightness)),
    null => function,
  };

  /// [scheme] with all four syntax slots written for [brightness], with
  /// [function] the mapping's own info step for function names.
  ///
  /// The one place a syntax slot is paired with its value. Every mapping
  /// calls it in each of its four builders, high contrast included, with
  /// the normal mode's values — so a raise built on [scheme] has nothing to
  /// move. A source of your own that never calls it shows CoUI's values,
  /// because an unset slot resolves to CoUI's normal one.
  static CoreColorScheme applyTo(
    CoreColorScheme scheme,
    CoreBrightness brightness, {
    required CoreColor function,
  }) {
    CoreColor value(CoreSyntaxSlot slot) =>
        valueOf(slot, brightness, function: function);

    return scheme.copyWith(
      syntaxKeyword: value(.keyword),
      syntaxType: value(.type),
      syntaxFunction: value(.function),
      syntaxString: value(.string),
    );
  }
}
