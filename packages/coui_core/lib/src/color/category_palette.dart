/// Category colours — nine hues that tell things apart without saying
/// anything about them: tags, avatars, labels, calendar entries, chart
/// legends.
///
/// Four things hold for everything in this file:
///
/// - **No meaning, no brand.** A category hue never stands for success,
///   error or a brand colour, so every brand renders the same values.
///   Meaning belongs to the status colours.
/// - **Outside every brand vocabulary.** The 117 primitives are kept out of
///   every `CoreSchemeSource.primitives` on purpose. That vocabulary is
///   per-brand and every value in it must be unique, and gray's
///   `light-container` equals CoUI's `neutral/200` — merged in, it would
///   collide with the neutral ramp and break the counts each brand
///   vocabulary is pinned to. They
///   live under the brand-less [CoreCategoryPalette.namespace] instead, and
///   a semantic slot reaches them by name, never by value.
/// - **High contrast is stated, not derived.** A mapping writes the
///   high-contrast values inside its own raise, through
///   [CoreCategoryPalette.applyTo], reading them from this table. Nothing
///   here is computed from a palette.
/// - **A source that leaves them out keeps the normal values.** A raise
///   that does not call [CoreCategoryPalette.applyTo] leaves the category
///   slots as the normal scheme had them, so high contrast silently shows
///   the normal colours.
library;

import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// The nine category hues, in the order every list of them is written —
/// the primitive vocabulary, the slot names and every emitter that walks
/// them.
enum CoreCategoryColor {
  /// Red.
  red(
    fill: CoreColors.categoryRed,
    onFill: CoreColors.onCategoryRed,
    container: CoreColors.categoryRedContainer,
    onContainer: CoreColors.onCategoryRedContainer,
    outline: CoreColors.categoryRedOutline,
  ),

  /// Orange.
  orange(
    fill: CoreColors.categoryOrange,
    onFill: CoreColors.onCategoryOrange,
    container: CoreColors.categoryOrangeContainer,
    onContainer: CoreColors.onCategoryOrangeContainer,
    outline: CoreColors.categoryOrangeOutline,
  ),

  /// Yellow.
  yellow(
    fill: CoreColors.categoryYellow,
    onFill: CoreColors.onCategoryYellow,
    container: CoreColors.categoryYellowContainer,
    onContainer: CoreColors.onCategoryYellowContainer,
    outline: CoreColors.categoryYellowOutline,
  ),

  /// Green.
  green(
    fill: CoreColors.categoryGreen,
    onFill: CoreColors.onCategoryGreen,
    container: CoreColors.categoryGreenContainer,
    onContainer: CoreColors.onCategoryGreenContainer,
    outline: CoreColors.categoryGreenOutline,
  ),

  /// Blue.
  blue(
    fill: CoreColors.categoryBlue,
    onFill: CoreColors.onCategoryBlue,
    container: CoreColors.categoryBlueContainer,
    onContainer: CoreColors.onCategoryBlueContainer,
    outline: CoreColors.categoryBlueOutline,
  ),

  /// Purple.
  purple(
    fill: CoreColors.categoryPurple,
    onFill: CoreColors.onCategoryPurple,
    container: CoreColors.categoryPurpleContainer,
    onContainer: CoreColors.onCategoryPurpleContainer,
    outline: CoreColors.categoryPurpleOutline,
  ),

  /// Pink.
  pink(
    fill: CoreColors.categoryPink,
    onFill: CoreColors.onCategoryPink,
    container: CoreColors.categoryPinkContainer,
    onContainer: CoreColors.onCategoryPinkContainer,
    outline: CoreColors.categoryPinkOutline,
  ),

  /// Brown.
  brown(
    fill: CoreColors.categoryBrown,
    onFill: CoreColors.onCategoryBrown,
    container: CoreColors.categoryBrownContainer,
    onContainer: CoreColors.onCategoryBrownContainer,
    outline: CoreColors.categoryBrownOutline,
  ),

  /// Gray.
  gray(
    fill: CoreColors.categoryGray,
    onFill: CoreColors.onCategoryGray,
    container: CoreColors.categoryGrayContainer,
    onContainer: CoreColors.onCategoryGrayContainer,
    outline: CoreColors.categoryGrayOutline,
  );

  const CoreCategoryColor({
    required this.fill,
    required this.onFill,
    required this.container,
    required this.onContainer,
    required this.outline,
  });

  /// The `category-{c}` token — [CoreCategorySlot.fill].
  final CoreColorToken fill;

  /// The `on-category-{c}` token — [CoreCategorySlot.onFill].
  final CoreColorToken onFill;

  /// The `category-{c}-container` token — [CoreCategorySlot.container].
  final CoreColorToken container;

  /// The `on-category-{c}-container` token —
  /// [CoreCategorySlot.onContainer].
  final CoreColorToken onContainer;

  /// The `category-{c}-outline` token — [CoreCategorySlot.outline].
  final CoreColorToken outline;

  /// This hue's token for [slot] — what a component names to colour with
  /// a hue chosen at run time: `CoreColor.token(hue.token(.container))`.
  CoreColorToken token(CoreCategorySlot slot) => switch (slot) {
    .fill => fill,
    .onFill => onFill,
    .container => container,
    .onContainer => onContainer,
    .outline => outline,
  };
}

/// The five semantic slots every [CoreCategoryColor] has.
enum CoreCategorySlot {
  /// `category-{c}` — the strong chip's fill, a chart series, a legend dot.
  fill,

  /// `on-category-{c}` — the label on [fill]. Reads the mapping's own white,
  /// or its black in high-contrast dark, rather than a category tone.
  onFill,

  /// `category-{c}-container` — the soft chip, avatar and calendar-block
  /// background.
  container,

  /// `on-category-{c}-container` — the label on [container], and every
  /// coloured text in every mode. [fill] is never a text colour: on white
  /// it falls as low as 3.55:1.
  onContainer,

  /// `category-{c}-outline` — the soft chip, avatar and calendar-block
  /// border. In light mode it reads the container tone, so it does not show.
  outline;

  /// The primitive tone this slot reads in one mode, or `null` for
  /// [onFill], which reads the mapping's own white or black instead.
  ///
  /// | slot | Light | Dark |
  /// |---|---|---|
  /// | [fill] | `light-fill` | `dark-fill` |
  /// | [onFill] | white | white |
  /// | [container] | `light-container` | `dark-container` |
  /// | [onContainer] | `light-on-container` | `dark-on-container` |
  /// | [outline] | `light-container` | `dark-outline` |
  ///
  /// | slot | HCLight | HCDark |
  /// |---|---|---|
  /// | [fill] | `hc-light-fill` | `hc-dark-fill` |
  /// | [onFill] | white | black |
  /// | [container] | `light-container` | `hc-dark-container` |
  /// | [onContainer] | `hc-light-on-container` | `hc-dark-on-container` |
  /// | [outline] | `hc-light-fill` | `hc-dark-outline` |
  ///
  /// Every cell is written out rather than read off a tone's `light-` /
  /// `dark-` / `hc-` prefix: high-contrast light reuses `light-container`
  /// for [container] and borrows `hc-light-fill` for [outline], so a prefix
  /// rule would pick a tone that does not exist.
  CoreCategoryTone? toneIn(
    CoreBrightness brightness, {
    required bool highContrast,
  }) => switch ((this, brightness, highContrast)) {
    (.fill, .light, false) => .lightFill,
    (.fill, .dark, false) => .darkFill,
    (.fill, .light, true) => .hcLightFill,
    (.fill, .dark, true) => .hcDarkFill,
    (.onFill, _, _) => null,
    (.container, .light, false) => .lightContainer,
    (.container, .dark, false) => .darkContainer,
    (.container, .light, true) => .lightContainer,
    (.container, .dark, true) => .hcDarkContainer,
    (.onContainer, .light, false) => .lightOnContainer,
    (.onContainer, .dark, false) => .darkOnContainer,
    (.onContainer, .light, true) => .hcLightOnContainer,
    (.onContainer, .dark, true) => .hcDarkOnContainer,
    (.outline, .light, false) => .lightContainer,
    (.outline, .dark, false) => .darkOutline,
    (.outline, .light, true) => .hcLightFill,
    (.outline, .dark, true) => .hcDarkOutline,
  };

  /// This slot's kebab-case semantic name for [color] — for red,
  /// `category-red`, `on-category-red`, `category-red-container`,
  /// `on-category-red-container` and `category-red-outline`.
  String cssName(CoreCategoryColor color) => switch (this) {
    .fill => 'category-${color.name}',
    .onFill => 'on-category-${color.name}',
    .container => 'category-${color.name}-container',
    .onContainer => 'on-category-${color.name}-container',
    .outline => 'category-${color.name}-outline',
  };
}

/// The thirteen primitive roles every [CoreCategoryColor] has — one per row
/// of the value table, in that order.
///
/// Named by role rather than by a numbered step: the values sit on no
/// shared lightness ladder (a `light-on-container` and a `dark-outline` can
/// share a lightness and differ only in chroma), so a step number would
/// have to be invented for each.
enum CoreCategoryTone {
  /// [CoreCategorySlot.fill] in light mode.
  lightFill('light-fill'),

  /// [CoreCategorySlot.container] in light and high-contrast light, and
  /// [CoreCategorySlot.outline] in light.
  lightContainer('light-container'),

  /// [CoreCategorySlot.onContainer] in light mode.
  lightOnContainer('light-on-container'),

  /// [CoreCategorySlot.fill] in dark mode.
  darkFill('dark-fill'),

  /// [CoreCategorySlot.container] in dark mode.
  darkContainer('dark-container'),

  /// [CoreCategorySlot.onContainer] in dark mode.
  darkOnContainer('dark-on-container'),

  /// [CoreCategorySlot.outline] in dark mode.
  darkOutline('dark-outline'),

  /// [CoreCategorySlot.fill] and [CoreCategorySlot.outline] in
  /// high-contrast light.
  hcLightFill('hc-light-fill'),

  /// [CoreCategorySlot.onContainer] in high-contrast light.
  hcLightOnContainer('hc-light-on-container'),

  /// [CoreCategorySlot.fill] in high-contrast dark.
  hcDarkFill('hc-dark-fill'),

  /// [CoreCategorySlot.container] in high-contrast dark.
  hcDarkContainer('hc-dark-container'),

  /// [CoreCategorySlot.onContainer] in high-contrast dark.
  hcDarkOnContainer('hc-dark-on-container'),

  /// [CoreCategorySlot.outline] in high-contrast dark.
  hcDarkOutline('hc-dark-outline');

  const CoreCategoryTone(this.key);

  /// The last segment of the primitive name — `category/red/<key>`.
  final String key;
}

/// The category colour table — the one place a category value or a
/// slot-per-mode decision is written.
///
/// Fixed hex, as the designer authored it: the values are not read off any
/// ramp, and two tones of one hue may coincide on purpose (yellow's
/// `light-on-container` is its `dark-outline`). Every reader reaches a tone
/// by its name, so a coincidence is harmless — do not fold equal cells
/// together.
abstract final class CoreCategoryPalette {
  /// The brand-less namespace the primitives live under —
  /// `category/<hue>/<tone>`. Reserved: no brand may use it as its id.
  static const String namespace = 'category';

  /// One row per [CoreCategoryTone], in declaration order. Each row lists
  /// the hues in [CoreCategoryColor] order: red, orange, yellow, green,
  /// blue, purple, pink, brown, gray.
  static const Map<CoreCategoryTone, List<CoreColor>> _byTone = {
    CoreCategoryTone.lightFill: [
      CoreColor(0xFFE35B57),
      CoreColor(0xFFD86810),
      CoreColor(0xFFB07E21),
      CoreColor(0xFF129C4A),
      CoreColor(0xFF3488EC),
      CoreColor(0xFF9E70E3),
      CoreColor(0xFFD75C9D),
      CoreColor(0xFFB5795E),
      CoreColor(0xFF7E848A),
    ],
    CoreCategoryTone.lightContainer: [
      CoreColor(0xFFFEDEDA),
      CoreColor(0xFFFEDFCE),
      CoreColor(0xFFF5E4C7),
      CoreColor(0xFFD3EFD9),
      CoreColor(0xFFD7E8FE),
      CoreColor(0xFFEAE1FE),
      CoreColor(0xFFFDDBEA),
      CoreColor(0xFFF4E2DA),
      CoreColor(0xFFE4E6E7),
    ],
    CoreCategoryTone.lightOnContainer: [
      CoreColor(0xFF822B2A),
      CoreColor(0xFF773A08),
      CoreColor(0xFF644708),
      CoreColor(0xFF0B5D2E),
      CoreColor(0xFF154D8C),
      CoreColor(0xFF583A84),
      CoreColor(0xFF7A2B56),
      CoreColor(0xFF6D402C),
      CoreColor(0xFF3C4249),
    ],
    CoreCategoryTone.darkFill: [
      CoreColor(0xFFBC4945),
      CoreColor(0xFFB2540B),
      CoreColor(0xFF93670B),
      CoreColor(0xFF0D803B),
      CoreColor(0xFF266FC4),
      CoreColor(0xFF825BBD),
      CoreColor(0xFFB34981),
      CoreColor(0xFF96634C),
      CoreColor(0xFF676D74),
    ],
    CoreCategoryTone.darkContainer: [
      CoreColor(0xFF44211E),
      CoreColor(0xFF422410),
      CoreColor(0xFF3B2906),
      CoreColor(0xFF14341F),
      CoreColor(0xFF192D47),
      CoreColor(0xFF312644),
      CoreColor(0xFF412030),
      CoreColor(0xFF392820),
      CoreColor(0xFF2C2F33),
    ],
    CoreCategoryTone.darkOnContainer: [
      CoreColor(0xFFFDA19A),
      CoreColor(0xFFFDA573),
      CoreColor(0xFFF5AF20),
      CoreColor(0xFF66DA85),
      CoreColor(0xFF92C1FD),
      CoreColor(0xFFC9ADFD),
      CoreColor(0xFFFD99CA),
      CoreColor(0xFFEFAC8D),
      CoreColor(0xFFC4C7CB),
    ],
    CoreCategoryTone.darkOutline: [
      CoreColor(0xFF753935),
      CoreColor(0xFF713E1C),
      CoreColor(0xFF644708),
      CoreColor(0xFF225A35),
      CoreColor(0xFF2B4E7A),
      CoreColor(0xFF544174),
      CoreColor(0xFF6F3854),
      CoreColor(0xFF624539),
      CoreColor(0xFF4B4F54),
    ],
    CoreCategoryTone.hcLightFill: [
      CoreColor(0xFFA12F2F),
      CoreColor(0xFF8F4207),
      CoreColor(0xFF765107),
      CoreColor(0xFF08662E),
      CoreColor(0xFF0757A9),
      CoreColor(0xFF6B43A3),
      CoreColor(0xFF973069),
      CoreColor(0xFF804B33),
      CoreColor(0xFF54595F),
    ],
    CoreCategoryTone.hcLightOnContainer: [
      CoreColor(0xFF832C2A),
      CoreColor(0xFF793705),
      CoreColor(0xFF634405),
      CoreColor(0xFF065726),
      CoreColor(0xFF124A8A),
      CoreColor(0xFF583A84),
      CoreColor(0xFF7A2B56),
      CoreColor(0xFF69402E),
      CoreColor(0xFF464A4F),
    ],
    CoreCategoryTone.hcDarkFill: [
      CoreColor(0xFFFEB1AA),
      CoreColor(0xFFFDB48B),
      CoreColor(0xFFFBB841),
      CoreColor(0xFF70DA8A),
      CoreColor(0xFF9CC7FD),
      CoreColor(0xFFD0B9FD),
      CoreColor(0xFFFEACD2),
      CoreColor(0xFFF4B79C),
      CoreColor(0xFFBFC5CC),
    ],
    CoreCategoryTone.hcDarkContainer: [
      CoreColor(0xFF361715),
      CoreColor(0xFF341A09),
      CoreColor(0xFF2F1E01),
      CoreColor(0xFF0D2814),
      CoreColor(0xFF102239),
      CoreColor(0xFF251C36),
      CoreColor(0xFF331725),
      CoreColor(0xFF2C1E18),
      CoreColor(0xFF1F2226),
    ],
    CoreCategoryTone.hcDarkOnContainer: [
      CoreColor(0xFFF1A79F),
      CoreColor(0xFFEDAC88),
      CoreColor(0xFFDDB67A),
      CoreColor(0xFF97D1A1),
      CoreColor(0xFF97C1F7),
      CoreColor(0xFFC6B1F0),
      CoreColor(0xFFEAA5C5),
      CoreColor(0xFFD8B4A3),
      CoreColor(0xFFC4C7CB),
    ],
    CoreCategoryTone.hcDarkOutline: [
      CoreColor(0xFFD25C57),
      CoreColor(0xFFC96621),
      CoreColor(0xFFA87820),
      CoreColor(0xFF23944A),
      CoreColor(0xFF3B83D9),
      CoreColor(0xFF946ED2),
      CoreColor(0xFFC75C92),
      CoreColor(0xFFAB745A),
      CoreColor(0xFF7D8288),
    ],
  };

  /// The value of [tone] for [color].
  static CoreColor tone(CoreCategoryColor color, CoreCategoryTone tone) =>
      _byTone[tone]![color.index];

  /// The primitive name of [tone] for [color] — `category/red/light-fill`.
  ///
  /// Three segments, kept apart: the hue and the role are never joined
  /// into one dash-separated segment.
  static String primitiveName(CoreCategoryColor color, CoreCategoryTone tone) =>
      '$namespace/${color.name}/${tone.key}';

  /// All 117 primitives, [primitiveName] → value — hue by hue, each hue's
  /// tones in table order.
  ///
  /// Never merged into any `CoreSchemeSource.primitives`; see the library
  /// documentation for why.
  static Map<String, CoreColor> get primitives => {
    for (final color in CoreCategoryColor.values)
      for (final categoryTone in CoreCategoryTone.values)
        primitiveName(color, categoryTone): tone(color, categoryTone),
  };

  /// Every slot that reads a category tone in one mode, as
  /// [CoreCategorySlot.cssName] → [primitiveName] — 36 entries, hue by hue.
  ///
  /// [CoreCategorySlot.onFill] is absent: it reads the mapping's own white
  /// or black. The key set is the same in every mode; only the tones the
  /// keys point at change.
  static Map<String, String> primitiveLinks(
    CoreBrightness brightness, {
    required bool highContrast,
  }) => {
    for (final color in CoreCategoryColor.values)
      for (final slot in CoreCategorySlot.values)
        if (slot.toneIn(brightness, highContrast: highContrast)
            case final categoryTone?)
          slot.cssName(color): primitiveName(color, categoryTone),
  };

  /// The value [slot] of [color] takes in one mode.
  ///
  /// [white] and [black] are the mapping's own pure white and pure black,
  /// read by [CoreCategorySlot.onFill] — black only in high-contrast dark.
  /// Pure, not an off-white: on the lowest light-mode fill the standard
  /// mapping's `neutral/white` (#FCFCFD) measures 3.47:1, below the 3.5:1
  /// the strong chip label is allowed.
  static CoreColor valueOf(
    CoreCategoryColor color,
    CoreCategorySlot slot,
    CoreBrightness brightness, {
    required bool highContrast,
    required CoreColor white,
    required CoreColor black,
  }) => switch (slot.toneIn(brightness, highContrast: highContrast)) {
    final categoryTone? => tone(color, categoryTone),
    null => switch ((brightness, highContrast)) {
      (.dark, true) => black,
      _ => white,
    },
  };

  /// [scheme] with all 45 category slots written for one mode — each
  /// [valueOf] the table for that mode, with [white] and [black] the
  /// mapping's own pure ends.
  ///
  /// The one place a category slot is paired with its value. Every mapping
  /// calls it in each of its four builders and inside its raise, so the
  /// high-contrast values arrive through whichever door high contrast
  /// comes in by — the builder or `CoreSchemeSource.raiseContrast`. A
  /// source of your own does the same: one that never calls it shows the
  /// normal values in high contrast, because an unset slot resolves to
  /// CoUI's normal one.
  static CoreColorScheme applyTo(
    CoreColorScheme scheme,
    CoreBrightness brightness, {
    required bool highContrast,
    required CoreColor white,
    required CoreColor black,
  }) {
    CoreColor value(CoreCategoryColor color, CoreCategorySlot slot) => valueOf(
      color,
      slot,
      brightness,
      highContrast: highContrast,
      white: white,
      black: black,
    );

    return scheme.copyWith(
      categoryRed: value(.red, .fill),
      onCategoryRed: value(.red, .onFill),
      categoryRedContainer: value(.red, .container),
      onCategoryRedContainer: value(.red, .onContainer),
      categoryRedOutline: value(.red, .outline),
      categoryOrange: value(.orange, .fill),
      onCategoryOrange: value(.orange, .onFill),
      categoryOrangeContainer: value(.orange, .container),
      onCategoryOrangeContainer: value(.orange, .onContainer),
      categoryOrangeOutline: value(.orange, .outline),
      categoryYellow: value(.yellow, .fill),
      onCategoryYellow: value(.yellow, .onFill),
      categoryYellowContainer: value(.yellow, .container),
      onCategoryYellowContainer: value(.yellow, .onContainer),
      categoryYellowOutline: value(.yellow, .outline),
      categoryGreen: value(.green, .fill),
      onCategoryGreen: value(.green, .onFill),
      categoryGreenContainer: value(.green, .container),
      onCategoryGreenContainer: value(.green, .onContainer),
      categoryGreenOutline: value(.green, .outline),
      categoryBlue: value(.blue, .fill),
      onCategoryBlue: value(.blue, .onFill),
      categoryBlueContainer: value(.blue, .container),
      onCategoryBlueContainer: value(.blue, .onContainer),
      categoryBlueOutline: value(.blue, .outline),
      categoryPurple: value(.purple, .fill),
      onCategoryPurple: value(.purple, .onFill),
      categoryPurpleContainer: value(.purple, .container),
      onCategoryPurpleContainer: value(.purple, .onContainer),
      categoryPurpleOutline: value(.purple, .outline),
      categoryPink: value(.pink, .fill),
      onCategoryPink: value(.pink, .onFill),
      categoryPinkContainer: value(.pink, .container),
      onCategoryPinkContainer: value(.pink, .onContainer),
      categoryPinkOutline: value(.pink, .outline),
      categoryBrown: value(.brown, .fill),
      onCategoryBrown: value(.brown, .onFill),
      categoryBrownContainer: value(.brown, .container),
      onCategoryBrownContainer: value(.brown, .onContainer),
      categoryBrownOutline: value(.brown, .outline),
      categoryGray: value(.gray, .fill),
      onCategoryGray: value(.gray, .onFill),
      categoryGrayContainer: value(.gray, .container),
      onCategoryGrayContainer: value(.gray, .onContainer),
      categoryGrayOutline: value(.gray, .outline),
    );
  }
}
