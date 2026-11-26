import 'package:coui_core/src/color/color_contrast.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/theme/brightness.dart';

/// The contract a brand mapping keeps for its selected face —
/// `primaryContainer` — against the page (`surface`).
///
/// The standard mapping (`CoreSemanticMapping`) reads `primaryContainer` off
/// a fixed step of the primary ramp, and for some hues that step lands too
/// close to the page: a light-hued brand's `lightest` all but disappears on
/// the light page, a dark-hued brand's `darker` on the dark one. Badge tonal
/// faces and FileInput icon boxes melt into the page there. The fix lives in
/// the generator, not in the components that draw the face — the lightness
/// direction is opposite from one brand to the next, so swapping tokens in a
/// component repairs one brand and breaks another.
///
/// **Luminance contrast only.** The gap is judged by WCAG contrast, not by
/// ΔE: a pair can differ a lot in hue (Unibook Dark, ΔE 14) and still be
/// 1.09:1 in luminance, which is no separation at all to a reader with a
/// colour-vision deficiency. Luminance holds whatever the hue — Material 3
/// keeps its container gap the same way, by tone step.
///
/// **What the generator does with it.** When the default step falls short,
/// [pick] walks `primaryContainer` one step at a time *away from the page*
/// (darker on light, lighter on dark), at most [maxSteps] steps. If even
/// that falls short it does not move at all — a palette that needs more is
/// too light or too dark as a whole, and a person has to look. A move that
/// would cost the text drawn on the face its contrast is not taken either:
/// text on the face outranks the gap.
///
/// A brand that states its own `primaryContainer` is outside [pick] — the
/// contract test reports a shortfall there and does not fail on it.
abstract final class CorePrimaryContainerGap {
  /// The least contrast `primaryContainer` keeps from `surface` in light
  /// mode.
  ///
  /// Between the brands that melted (1.06–1.08) and CoUI's own mapping
  /// (1.25), 0.05 below CoUI so rounding cannot push CoUI under it.
  static const double minLight = 1.20;

  /// The least contrast `primaryContainer` keeps from `surface` in dark
  /// mode.
  ///
  /// The same lightness difference reads as a larger contrast number on a
  /// dark page, and Material keeps the dark gap wider too — so between the
  /// brands that melted (1.09–1.13) and CoUI (1.76).
  static const double minDark = 1.40;

  /// How many ramp steps [pick] may move `primaryContainer` away from its
  /// default.
  ///
  /// A palette that needs more than two is too light or too dark as a whole;
  /// moving further would hide that instead of showing it to a person.
  static const int maxSteps = 2;

  /// What `onPrimaryContainer` owes on the face — body text, 4.5:1.
  static const CoreContrastLevel onContainerLevel =
      CoreContrastLevel.aaNormalText;

  /// What `onPrimaryContainer` owes on the face in a high-contrast mode —
  /// CoUI's high-contrast text bar, 7:1 (WCAG 1.4.6).
  ///
  /// A high-contrast mode exists for readers who need more than the normal
  /// bar. A step move that kept the gap but left the text at the normal
  /// 4.5:1 would give that mode back the legibility it was turned on to
  /// raise, so the move is checked against this bar there instead.
  static const CoreContrastLevel highContrastOnContainerLevel =
      CoreContrastLevel.aaaNormalText;

  /// What `primaryText` owes on the face — it draws the focus boundary
  /// there, a non-text indicator, 3:1.
  static const CoreContrastLevel primaryTextLevel = CoreContrastLevel.nonText;

  /// The least face-to-page contrast for [brightness].
  static double minimumFor(CoreBrightness brightness) =>
      brightness == .dark ? minDark : minLight;

  /// Whether [container] keeps the gap from [surface] in [brightness].
  static bool keepsGap(
    CoreColor container,
    CoreColor surface,
    CoreBrightness brightness,
  ) => CoreContrast.ratio(container, surface) >= minimumFor(brightness);

  /// Whether the text drawn on [container] keeps its contrast — against
  /// [highContrastOnContainerLevel] when [highContrast] is set, otherwise
  /// [onContainerLevel].
  static bool keepsText(
    CoreColor container, {
    required CoreColor onContainer,
    required CoreColor primaryText,
    bool highContrast = false,
  }) =>
      CoreContrast.meets(
        onContainer,
        container,
        highContrast ? highContrastOnContainerLevel : onContainerLevel,
      ) &&
      CoreContrast.meets(primaryText, container, primaryTextLevel);

  /// The `primaryContainer` step the standard mapping draws.
  ///
  /// [ladder] is the ramp ordered from the default step away from
  /// [surface] — `[lightest, lighter, light]` on light, `[darker, dark, base]`
  /// on dark. Returns `ladder.first` when it keeps the gap; otherwise the
  /// first of the next [maxSteps] steps that keeps it, provided the text on
  /// it ([onContainer], [primaryText]) still keeps its contrast. When no
  /// step within reach keeps the gap, or the step that does would cost the
  /// text its contrast, returns `ladder.first` unmoved. [highContrast] holds
  /// the text on a moved step to [highContrastOnContainerLevel] — the bar a
  /// high-contrast mode's text owes.
  static CoreColor pick(
    List<CoreColor> ladder, {
    required CoreColor surface,
    required CoreColor onContainer,
    required CoreColor primaryText,
    required CoreBrightness brightness,
    bool highContrast = false,
  }) {
    final unmoved = ladder.first;
    if (keepsGap(unmoved, surface, brightness)) return unmoved;
    final reach = ladder.length - 1 < maxSteps ? ladder.length - 1 : maxSteps;
    for (var step = 1; step <= reach; step++) {
      final candidate = ladder[step];
      if (!keepsGap(candidate, surface, brightness)) continue;

      return keepsText(
            candidate,
            onContainer: onContainer,
            primaryText: primaryText,
            highContrast: highContrast,
          )
          ? candidate
          : unmoved;
    }

    return unmoved;
  }
}
