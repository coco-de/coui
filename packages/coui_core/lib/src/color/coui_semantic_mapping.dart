import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/coui_palette.dart';
import 'package:coui_core/src/color/scheme_source.dart';
import 'package:coui_core/src/color/syntax_palette.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// CoUI's own Primitive → Semantic interpretation of [CouiPalette].
///
/// Four tables, every one of them complete — all 129 slots in each mode.
/// The tables are the designer's semantic export translated once (code is
/// the source from here on), so each can be laid next to the designer's
/// column and compared line for line, and the Figma export, which has no
/// cascade between modes, gets every slot of every mode from them.
///
/// What the tables say, in short:
///
/// - `primary` reads the neutral ramp in every mode: CoUI is the base other
///   products build on, so its own call to action carries no hue. The light
///   modes fill it with a near-black step, the dark modes with a near-white
///   one. [CouiPalette] has no primary ramp of its own — a ramp holding the
///   neutral's values would make two primitives share one colour, the case
///   the Figma export refuses. A brand theme brings its own primary ramp.
/// - `secondary` is neutral emphasis — the neutral ramp, one step lighter
///   than `primary` in the normal light mode.
/// - The `tertiary` family restates `primary` step for step, and so do
///   `CoreColors.accent` / `onAccent`, which read the tertiary slots. CoUI
///   has no second hue.
/// - The status families keep their hues and meet the legibility bars at
///   the neutral ramp's step numbers: `500` clears 3:1 against white, `600`
///   clears 4.5:1. The status indicators (`errorIcon` …) read the `500` step
///   in light mode for that reason.
/// - The category slots are not read off [CouiPalette] at all: each table
///   writes them through [CoreCategoryPalette.applyTo], the same values in
///   every brand. Keyword, type and string are the same through
///   [CoreSyntaxPalette.applyTo]; function names read CoUI's info ramp.
///
/// High contrast is not a set of hand-picked overrides: the high-contrast
/// tables are complete too, and [raiseContrast] lays over its base only the
/// slots where a high-contrast table disagrees with its normal table
/// ([CoreColorScheme.raiseByDelta]).
abstract final class CouiSemanticMapping {
  /// Light mode.
  static CoreColorScheme light(CouiPalette c) {
    final table = CoreColorScheme(
      // Surface
      surface: c.white,
      surfaceDim: c.neutral.s100,
      surfaceBright: c.white,
      surfaceContainerLowest: c.white,
      surfaceContainerLow: c.neutral.s50,
      surfaceContainer: c.neutral.s100,
      surfaceContainerHigh: c.neutral.s150,
      surfaceContainerHighest: c.neutral.s200,
      onSurface: c.neutral.s950,
      onSurfaceVariant: c.neutral.s700,
      // The body-text step, so a placeholder still reads on the white input it
      // sits on (4.67:1) while staying one step weaker than
      // `onSurfaceVariant`. Input fields are white / `surface`; on the
      // container tones it would measure 4.47 (`surfaceContainerLow`), 4.28
      // (`surfaceContainer`, `surfaceDim`), 4.05 (`surfaceContainerHigh`) and
      // 3.73 (`surfaceContainerHighest`) — pairings no input produces.
      placeholder: c.neutral.s600,
      // A link is read as text, so it owes 4.5:1 on every surface tone. The
      // status step (`600`) falls under that on three of the grey containers
      // (4.22 / 3.97 / 3.68); `700` clears all eight (worst 5.03).
      link: c.info.s700,
      // The third text step — the placeholder step, one weaker than
      // `onSurfaceVariant`.
      onSurfaceSubtle: c.neutral.s600,
      // The selected face that rises out of a grey track: the page white.
      surfaceRaised: c.white,
      surfaceTint: c.neutral.s800,
      // Primary — the neutral CTA. `900`, not `800`: at `800` the button
      // read lighter than the body text (`950`) beside it (designer decision
      // #6135); white on `900` is 14.2:1.
      primary: c.neutral.s900,
      onPrimary: c.white,
      primaryContainer: c.neutral.s200,
      onPrimaryContainer: c.neutral.s900,
      primaryFixed: c.neutral.s200,
      primaryFixedDim: c.neutral.s300,
      onPrimaryFixed: c.neutral.s1000,
      onPrimaryFixedVariant: c.neutral.s800,
      primaryText: c.neutral.s800,
      primaryTextLarge: c.neutral.s700,
      // Secondary — neutral emphasis
      secondary: c.neutral.s800,
      onSecondary: c.white,
      secondaryContainer: c.neutral.s100,
      onSecondaryContainer: c.neutral.s950,
      secondaryFixed: c.neutral.s100,
      secondaryFixedDim: c.neutral.s150,
      onSecondaryFixed: c.neutral.s950,
      onSecondaryFixedVariant: c.neutral.s700,
      // Tertiary — restates primary step for step
      // CoUI has no separate accent hue. `CoreColors.accent` / `onAccent`
      // read these two slots, so they restate primary as well.
      tertiary: c.neutral.s900,
      onTertiary: c.white,
      tertiaryContainer: c.neutral.s200,
      onTertiaryContainer: c.neutral.s900,
      tertiaryFixed: c.neutral.s200,
      tertiaryFixedDim: c.neutral.s300,
      onTertiaryFixed: c.neutral.s1000,
      onTertiaryFixedVariant: c.neutral.s800,
      // Error and interaction steps
      error: c.error.s600,
      onError: c.white,
      errorContainer: c.error.s100,
      onErrorContainer: c.error.s700,
      errorStrong: c.error.s700,
      focusRing: c.neutral.s800,
      // Hover and press step lighter from the `900` rest fill (white on
      // them is 10.2:1 and 7.0:1) — the darkest step is already the rest.
      primaryHover: c.neutral.s800,
      primaryPressed: c.neutral.s700,
      secondaryHover: c.neutral.s900,
      secondaryPressed: c.neutral.s950,
      // One step past `errorStrong` (700), which is the destructive hover
      // fill: at 700 a hover and a press were the same colour. `onError`
      // over 800 is 9.58 : 1.
      errorPressed: c.error.s800,
      // Status
      success: c.success.s600,
      onSuccess: c.white,
      successContainer: c.success.s100,
      onSuccessContainer: c.success.s700,
      warning: c.warning.s600,
      onWarning: c.white,
      warningContainer: c.warning.s100,
      onWarningContainer: c.warning.s700,
      info: c.info.s600,
      onInfo: c.white,
      infoContainer: c.info.s100,
      onInfoContainer: c.info.s700,
      // Status indicators — icons, status dots, progress bars, chart marks:
      // non-text, so they owe 3:1 against the page (WCAG 1.4.11), not the
      // 4.5:1 the `success` / `warning` / `info` / `error` text step owes.
      // `500` is the UI-boundary step.
      errorIcon: c.error.s500,
      successIcon: c.success.s500,
      warningIcon: c.warning.s500,
      infoIcon: c.info.s500,
      // Outline
      // Control boundaries clear 3:1 (WCAG 1.4.11) on every light tone
      // (worst 3.73 on `surfaceContainerHighest`); `outlineVariant` stays a
      // hairline — 1.4.11 does not cover decorative rules. It sits at 300,
      // not 200: at 200 the rule weighed about 60% of the dark one on
      // `surface` and matched `surfaceContainerHighest` outright; 300 keeps
      // a visible step on every grey tone.
      outline: c.neutral.s600,
      outlineVariant: c.neutral.s300,
      // The border of a floating panel: one step off the page, not a
      // control boundary, so — like `outlineVariant` — it is not held to 3:1.
      outlineSubtle: c.neutral.s150,
      // Inverse
      inverseSurface: c.neutral.s900,
      inverseOnSurface: c.white,
      inversePrimary: c.neutral.s200,
      // Special
      shadow: c.black,
      surfaceHighlight: c.white,
      scrim: c.black,
      // Disabled
      // `neutral/400`, two steps lighter than `placeholder` and `outline`
      // (600), so a field that cannot be used reads apart from one that can
      // (designer decision, #5748). It sits under the 3:1 floor on its own
      // container and on `surface`; the contrast audit records those pairs
      // as accepted — disabled content is not held to WCAG contrast (1.4.3 /
      // 1.4.11 exempt inactive components).
      disabledContent: c.neutral.s400,
      disabledContainer: c.neutral.s100,
      disabledOutline: c.neutral.s200,
    );

    // The category slots are not CoUI's own: every table hands them to the
    // brand-neutral category table, with CoUI's white and black for the
    // strong chip's label. The syntax slots go the same way, with CoUI's
    // `info/700` for function names.
    return CoreCategoryPalette.applyTo(
      CoreSyntaxPalette.applyTo(table, .light, function: c.info.s700),
      .light,
      highContrast: false,
      white: c.white,
      black: c.black,
    );
  }

  /// Dark mode.
  static CoreColorScheme dark(CouiPalette c) {
    final table = CoreColorScheme(
      // Surface
      surface: c.neutral.s1000,
      surfaceDim: c.neutral.s1050,
      surfaceBright: c.neutral.s900,
      surfaceContainerLowest: c.neutral.s1050,
      surfaceContainerLow: c.neutral.s950,
      surfaceContainer: c.neutral.s900,
      surfaceContainerHigh: c.neutral.s850,
      surfaceContainerHighest: c.neutral.s800,
      onSurface: c.neutral.s100,
      onSurfaceVariant: c.neutral.s400,
      // Clears 4.5:1 on the `surface` the input fields sit on (5.97:1) and
      // on `surfaceBright` (4.72:1), the panel an input inside a popup sits
      // on. On `surfaceContainerHigh` (850) it would measure 4.09 and on
      // `surfaceContainerHighest` (800) 3.40 — accepted by the designer
      // (2026-10-07) on the ground that no input sits on a container tone.
      placeholder: c.neutral.s500,
      link: c.info.s400,
      onSurfaceSubtle: c.neutral.s500,
      // The topmost surface tone, above every track tone below it.
      surfaceRaised: c.neutral.s800,
      surfaceTint: c.neutral.s100,
      // Primary — the near-white neutral
      primary: c.neutral.s100,
      onPrimary: c.neutral.s1000,
      primaryContainer: c.neutral.s800,
      onPrimaryContainer: c.neutral.s100,
      primaryFixed: c.neutral.s200,
      primaryFixedDim: c.neutral.s300,
      onPrimaryFixed: c.neutral.s1000,
      onPrimaryFixedVariant: c.neutral.s800,
      primaryText: c.neutral.s300,
      primaryTextLarge: c.neutral.s400,
      // Secondary — neutral emphasis
      secondary: c.neutral.s200,
      onSecondary: c.neutral.s1000,
      secondaryContainer: c.neutral.s800,
      onSecondaryContainer: c.neutral.s100,
      secondaryFixed: c.neutral.s100,
      secondaryFixedDim: c.neutral.s150,
      onSecondaryFixed: c.neutral.s950,
      onSecondaryFixedVariant: c.neutral.s700,
      // Tertiary — restates primary step for step
      tertiary: c.neutral.s100,
      onTertiary: c.neutral.s1000,
      tertiaryContainer: c.neutral.s800,
      onTertiaryContainer: c.neutral.s100,
      tertiaryFixed: c.neutral.s200,
      tertiaryFixedDim: c.neutral.s300,
      onTertiaryFixed: c.neutral.s1000,
      onTertiaryFixedVariant: c.neutral.s800,
      // Error and interaction steps
      error: c.error.s400,
      onError: c.error.s1000,
      // The four status containers read the dark-only `950` step, low in
      // chroma (designer decision 2026-11-05, #6012): a saturated `900`
      // surface pulled the eye ahead of the content on the dark page, worst
      // on screens read at length such as a code diff. Radix Colors and
      // Primer keep their dark status surfaces as dedicated low-chroma steps
      // the same way, rather than reusing a light step.
      errorContainer: c.error.s950,
      // On-container text: `500` for info, `400` for success, error and
      // warning. Error stays at `400` because `onErrorContainer` is also
      // read off its container — Badge destructive outlined, a failed
      // StepItem's trailing note and the `invalid` syntax role sit on the
      // dark surfaces, where `500` measures 3.98 on surface container high,
      // under 4.5:1; `400` measures about 6.8 on the `950` container.
      // Warning's `500` was too close to `400` in lightness to earn a step.
      // Each clears 4.5:1 on its `950`.
      onErrorContainer: c.error.s400,
      errorStrong: c.error.s200,
      focusRing: c.neutral.s100,
      primaryHover: c.neutral.s200,
      primaryPressed: c.neutral.s300,
      secondaryHover: c.neutral.s300,
      secondaryPressed: c.neutral.s400,
      errorPressed: c.error.s300,
      // Status
      success: c.success.s400,
      onSuccess: c.success.s1000,
      successContainer: c.success.s950,
      onSuccessContainer: c.success.s400,
      warning: c.warning.s400,
      onWarning: c.warning.s1000,
      warningContainer: c.warning.s950,
      onWarningContainer: c.warning.s400,
      info: c.info.s400,
      onInfo: c.info.s1000,
      infoContainer: c.info.s950,
      onInfoContainer: c.info.s500,
      // Status indicators — `500` for success / info / error (designer
      // decision 2026-11-04): the `400` glyphs looked muddy on the dark page;
      // `500` clears 3:1 on every dark surface (5.6 on `surface`). Warning
      // was left at `400` in the same decision.
      errorIcon: c.error.s500,
      successIcon: c.success.s500,
      warningIcon: c.warning.s400,
      infoIcon: c.info.s500,
      // Outline
      // `500`, not the token export's `600` (designer decision 2026-10-07):
      // `600` measures 2.62:1 on the 850 tones and 2.19:1 on 800, under the
      // 3:1 a control boundary needs; `500` clears every dark tone (worst
      // 3.36 on 800).
      outline: c.neutral.s500,
      // `800`, one step up from `850` (designer decision, #5748): at 850 the
      // rule sat too close to the dark surface tones and card and field
      // edges disappeared.
      outlineVariant: c.neutral.s800,
      // One step lighter than the panel's own fill (`surfaceBright`, 900),
      // so a floating panel draws the line it states: 1.40:1 on the panel.
      // It is the same step as `outlineVariant` (800) in this mode.
      outlineSubtle: c.neutral.s800,
      // Inverse
      inverseSurface: c.neutral.s100,
      inverseOnSurface: c.neutral.s950,
      inversePrimary: c.neutral.s900,
      // Special
      // Black, as in every mode. A black cast on a near-black page is faint
      // at the light alpha, so the dark theme draws each cast layer at its
      // alpha × `CoreShadow.darkStrength` instead of turning the colour over
      // — the strength lives on the geometry seat
      // (`CoreSurfaceGeometryConstraint.shadow`), not in this slot. A dark
      // surface reads its height mainly from the surface tone ladder; the
      // cast only marks the floating panels.
      shadow: c.black,
      surfaceHighlight: c.neutral.s400,
      scrim: c.black,
      // Disabled
      disabledContent: c.neutral.s600,
      disabledContainer: c.neutral.s900,
      disabledOutline: c.neutral.s800,
    );

    return CoreCategoryPalette.applyTo(
      CoreSyntaxPalette.applyTo(table, .dark, function: c.info.s400),
      .dark,
      highContrast: false,
      white: c.white,
      black: c.black,
    );
  }

  /// [light] with contrast raised — see [raiseContrast].
  static CoreColorScheme highContrastLight(CouiPalette c) =>
      raiseContrast(light(c), c, .light);

  /// [dark] with contrast raised — see [raiseContrast].
  static CoreColorScheme highContrastDark(CouiPalette c) =>
      raiseContrast(dark(c), c, .dark);

  /// Raises the contrast of an arbitrary [base] for [brightness].
  ///
  /// Only the slots whose high-contrast value differs from the normal
  /// table's are laid over [base]; every other slot keeps [base]'s value.
  /// That is what lets an axis applied earlier — a surface style bending
  /// the page — survive into high contrast on the slots high contrast has
  /// no opinion about, while the slots it does govern are decided here: a
  /// decorative axis must not be able to undo a contrast increase the user
  /// asked for. Because the governed set is computed from the tables, an
  /// edit to a table moves the raise with it.
  static CoreColorScheme raiseContrast(
    CoreColorScheme base,
    CouiPalette c,
    CoreBrightness brightness,
  ) => brightness == .dark
      ? CoreColorScheme.raiseByDelta(
          base,
          normal: dark(c),
          raised: _highContrastDarkTable(c),
        )
      : CoreColorScheme.raiseByDelta(
          base,
          normal: light(c),
          raised: _highContrastLightTable(c),
        );

  /// The complete high-contrast light table. Read only through
  /// [raiseContrast], which keeps the slots it shares with [light] from
  /// overriding a bent base.
  static CoreColorScheme _highContrastLightTable(CouiPalette c) {
    final table = CoreColorScheme(
      // Surface
      // Surface tones are the normal table's, deliberately: components tell
      // cards, inputs and popovers apart by background tone and only some
      // draw a border, so flattening the tones toward white would erase
      // boundaries and leave nothing in their place.
      surface: c.white,
      surfaceDim: c.neutral.s100,
      surfaceBright: c.white,
      surfaceContainerLowest: c.white,
      surfaceContainerLow: c.neutral.s50,
      surfaceContainer: c.neutral.s100,
      surfaceContainerHigh: c.neutral.s150,
      surfaceContainerHighest: c.neutral.s200,
      onSurface: c.black,
      onSurfaceVariant: c.neutral.s800,
      placeholder: c.neutral.s700,
      link: c.info.s800,
      onSurfaceSubtle: c.neutral.s700,
      // The normal table's — a raised face is a tone, like the surfaces.
      surfaceRaised: c.white,
      surfaceTint: c.neutral.s1000,
      // Primary — the neutral ramp
      primary: c.neutral.s1000,
      onPrimary: c.white,
      primaryContainer: c.neutral.s200,
      onPrimaryContainer: c.neutral.s1000,
      primaryFixed: c.neutral.s200,
      primaryFixedDim: c.neutral.s300,
      onPrimaryFixed: c.neutral.s1000,
      onPrimaryFixedVariant: c.neutral.s800,
      primaryText: c.neutral.s1000,
      primaryTextLarge: c.neutral.s900,
      // Secondary — neutral emphasis
      secondary: c.neutral.s950,
      onSecondary: c.white,
      secondaryContainer: c.neutral.s150,
      onSecondaryContainer: c.black,
      secondaryFixed: c.neutral.s100,
      secondaryFixedDim: c.neutral.s150,
      onSecondaryFixed: c.neutral.s950,
      onSecondaryFixedVariant: c.neutral.s700,
      // Tertiary — restates primary step for step
      tertiary: c.neutral.s1000,
      onTertiary: c.white,
      tertiaryContainer: c.neutral.s200,
      onTertiaryContainer: c.neutral.s1000,
      tertiaryFixed: c.neutral.s200,
      tertiaryFixedDim: c.neutral.s300,
      onTertiaryFixed: c.neutral.s1000,
      onTertiaryFixedVariant: c.neutral.s800,
      // Error and interaction steps
      error: c.error.s800,
      onError: c.white,
      errorContainer: c.error.s100,
      onErrorContainer: c.error.s1000,
      errorStrong: c.error.s900,
      focusRing: c.neutral.s1000,
      primaryHover: c.neutral.s900,
      primaryPressed: c.neutral.s800,
      secondaryHover: c.neutral.s900,
      secondaryPressed: c.neutral.s850,
      errorPressed: c.error.s700,
      // Status
      success: c.success.s800,
      onSuccess: c.white,
      successContainer: c.success.s100,
      onSuccessContainer: c.success.s1000,
      warning: c.warning.s800,
      onWarning: c.white,
      warningContainer: c.warning.s100,
      onWarningContainer: c.warning.s1000,
      info: c.info.s800,
      onInfo: c.white,
      infoContainer: c.info.s100,
      onInfoContainer: c.info.s1000,
      // Status indicators — high contrast owes 4.5:1 for a UI mark too.
      errorIcon: c.error.s700,
      successIcon: c.success.s700,
      warningIcon: c.warning.s700,
      infoIcon: c.info.s700,
      // Outline
      outline: c.neutral.s800,
      outlineVariant: c.neutral.s500,
      // `600`, not the token export's `500` (designer decision 2026-10-08):
      // a floating panel leans on this line instead of its shadow in high
      // contrast, and `500` measures 3.04:1 on white — under the 4.5:1 a
      // high-contrast UI line owes. `600` measures 4.67:1.
      outlineSubtle: c.neutral.s600,
      // Inverse
      inverseSurface: c.black,
      inverseOnSurface: c.white,
      inversePrimary: c.neutral.s100,
      // Special
      shadow: c.black,
      surfaceHighlight: c.white,
      scrim: c.black,
      // Disabled
      disabledContent: c.neutral.s700,
      disabledContainer: c.neutral.s100,
      disabledOutline: c.neutral.s500,
    );

    // Stated in full here too: `raiseContrast` compares this table with
    // [light], so it governs exactly the category slots whose value moves.
    return CoreCategoryPalette.applyTo(
      CoreSyntaxPalette.applyTo(table, .light, function: c.info.s700),
      .light,
      highContrast: true,
      white: c.white,
      black: c.black,
    );
  }

  /// The complete high-contrast dark table — see [_highContrastLightTable].
  static CoreColorScheme _highContrastDarkTable(CouiPalette c) {
    final table = CoreColorScheme(
      // Surface
      // Surface tones are the normal table's — see the light table.
      surface: c.neutral.s1000,
      surfaceDim: c.neutral.s1050,
      surfaceBright: c.neutral.s900,
      surfaceContainerLowest: c.neutral.s1050,
      surfaceContainerLow: c.neutral.s950,
      surfaceContainer: c.neutral.s900,
      surfaceContainerHigh: c.neutral.s850,
      surfaceContainerHighest: c.neutral.s800,
      onSurface: c.white,
      onSurfaceVariant: c.neutral.s200,
      placeholder: c.neutral.s400,
      link: c.info.s200,
      onSurfaceSubtle: c.neutral.s400,
      surfaceRaised: c.neutral.s800,
      surfaceTint: c.neutral.s50,
      // Primary — the near-white neutral, as in the dark table
      primary: c.neutral.s50,
      onPrimary: c.black,
      primaryContainer: c.neutral.s800,
      onPrimaryContainer: c.white,
      primaryFixed: c.neutral.s200,
      primaryFixedDim: c.neutral.s300,
      onPrimaryFixed: c.neutral.s1000,
      onPrimaryFixedVariant: c.neutral.s800,
      primaryText: c.neutral.s100,
      primaryTextLarge: c.neutral.s200,
      // Secondary — neutral emphasis
      secondary: c.neutral.s100,
      onSecondary: c.black,
      secondaryContainer: c.neutral.s800,
      onSecondaryContainer: c.white,
      secondaryFixed: c.neutral.s100,
      secondaryFixedDim: c.neutral.s150,
      onSecondaryFixed: c.neutral.s950,
      onSecondaryFixedVariant: c.neutral.s700,
      // Tertiary — restates primary step for step
      tertiary: c.neutral.s50,
      onTertiary: c.black,
      tertiaryContainer: c.neutral.s800,
      onTertiaryContainer: c.white,
      tertiaryFixed: c.neutral.s200,
      tertiaryFixedDim: c.neutral.s300,
      onTertiaryFixed: c.neutral.s1000,
      onTertiaryFixedVariant: c.neutral.s800,
      // Error and interaction steps
      error: c.error.s200,
      onError: c.black,
      errorContainer: c.error.s900,
      onErrorContainer: c.white,
      errorStrong: c.error.s100,
      focusRing: c.neutral.s50,
      primaryHover: c.neutral.s100,
      primaryPressed: c.neutral.s200,
      secondaryHover: c.neutral.s150,
      secondaryPressed: c.neutral.s200,
      errorPressed: c.error.s300,
      // Status
      success: c.success.s200,
      onSuccess: c.black,
      successContainer: c.success.s900,
      onSuccessContainer: c.white,
      warning: c.warning.s200,
      onWarning: c.black,
      warningContainer: c.warning.s900,
      onWarningContainer: c.white,
      info: c.info.s200,
      onInfo: c.black,
      infoContainer: c.info.s900,
      onInfoContainer: c.white,
      // Status indicators — see the high-contrast light table.
      errorIcon: c.error.s300,
      successIcon: c.success.s300,
      warningIcon: c.warning.s300,
      infoIcon: c.info.s300,
      // Outline
      outline: c.neutral.s300,
      outlineVariant: c.neutral.s500,
      // `400`, not the token export's `500` — see the high-contrast light
      // table (designer decision 2026-10-08).
      outlineSubtle: c.neutral.s400,
      // Inverse
      inverseSurface: c.white,
      inverseOnSurface: c.black,
      inversePrimary: c.neutral.s1000,
      // Special
      // Black, as in the dark table — see there.
      shadow: c.black,
      surfaceHighlight: c.neutral.s400,
      scrim: c.black,
      // Disabled
      disabledContent: c.neutral.s300,
      disabledContainer: c.neutral.s900,
      disabledOutline: c.neutral.s500,
    );

    return CoreCategoryPalette.applyTo(
      CoreSyntaxPalette.applyTo(table, .dark, function: c.info.s400),
      .dark,
      highContrast: true,
      white: c.white,
      black: c.black,
    );
  }
}

/// [CouiPalette] read through [CouiSemanticMapping] — the source every
/// default CoUI seat takes (`CouiColorPresets.source`).
@immutable
final class CouiSchemeSource implements CoreSchemeSource {
  /// Creates a [CouiSchemeSource].
  const CouiSchemeSource(this.palette);

  /// The fixed CoUI palette.
  final CouiPalette palette;

  @override
  CoreColorScheme light() => CouiSemanticMapping.light(palette);

  @override
  CoreColorScheme dark() => CouiSemanticMapping.dark(palette);

  @override
  CoreColorScheme highContrastLight() =>
      CouiSemanticMapping.highContrastLight(palette);

  @override
  CoreColorScheme highContrastDark() =>
      CouiSemanticMapping.highContrastDark(palette);

  @override
  CoreColorScheme raiseContrast(
    CoreColorScheme base,
    CoreBrightness brightness,
  ) => CouiSemanticMapping.raiseContrast(base, palette, brightness);

  /// The 67 fixed primitives (`neutral/50` … `base/black`).
  @override
  Map<String, CoreColor> get primitives => palette.primitives;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CouiSchemeSource && palette == other.palette);

  @override
  int get hashCode => palette.hashCode;
}
