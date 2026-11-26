import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/contracts/badge/badge_form.dart';
import 'package:coui_core/src/component/contracts/badge/badge_style.dart';
import 'package:coui_core/src/component/contracts/badge/badge_tone.dart';
import 'package:coui_core/src/component/contracts/badge/badge_variant.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:meta/meta.dart';

/// One [CoreBadgeTone]'s colours — what it paints at each strength and as
/// a dot.
///
/// Seven colours, all platform-neutral ([CoreColor]); each renderer
/// converts at use-site (Flutter via `scheme.resolve(...).toValue()`, Web
/// via `'bg-${color}'` / `var(--coui-*)`).
@immutable
class CoreBadgeToneStyle {
  /// Creates a badge tone style.
  const CoreBadgeToneStyle({
    required this.filledBackgroundColor,
    required this.filledForegroundColor,
    required this.tonalBackgroundColor,
    required this.tonalForegroundColor,
    required this.outlinedBorderColor,
    required this.outlinedForegroundColor,
    required this.dotColor,
    this.outlinedMarkColor,
  });

  /// [CoreBadgeVariant.filled] fill.
  final CoreColor filledBackgroundColor;

  /// [CoreBadgeVariant.filled] label / icon / leading-dot colour.
  final CoreColor filledForegroundColor;

  /// [CoreBadgeVariant.tonal] fill.
  final CoreColor tonalBackgroundColor;

  /// [CoreBadgeVariant.tonal] label / icon / leading-dot colour.
  final CoreColor tonalForegroundColor;

  /// [CoreBadgeVariant.outlined] line. The fill under it is
  /// [CoreBadgeStyle.defaultOutlinedBackgroundColor].
  final CoreColor outlinedBorderColor;

  /// [CoreBadgeVariant.outlined] label colour — and the icon and leading
  /// dot's too, unless [outlinedMarkColor] states them.
  final CoreColor outlinedForegroundColor;

  /// [CoreBadgeVariant.outlined] icon and leading-dot colour, when they are
  /// not the label's. The status tones set them in the tone's own colour,
  /// the line's, while the label keeps its container text: the label is
  /// text and needs 4.5 : 1 on whatever surface the badge sits on, which
  /// the tone colour does not clear on every surface; an icon and a dot
  /// are marks beside it. `null` leaves them in [outlinedForegroundColor].
  ///
  /// It deliberately has no default of its own: a constant mark colour would
  /// paint every tone's icon and dot the same, and the tones without a mark
  /// of their own (`neutral`, `primary`) are meant to keep the label's.
  final CoreColor? outlinedMarkColor;

  /// [CoreBadgeForm.dot] fill, at every variant.
  final CoreColor dotColor;

  /// The colours a badge of this tone paints at rest, as a [CoreBadgeStyle]
  /// the resolvers merge under the caller's override.
  ///
  /// A dot paints [dotColor] whatever the [variant] — it has no label to
  /// keep legible, so the strengths have nothing to differ in. The other
  /// forms take the [variant]'s pair; only [CoreBadgeVariant.outlined]
  /// states a border.
  ///
  /// Lives here rather than in each resolver so the variant × form choice
  /// is made once for both platforms.
  CoreBadgeStyle restingStyleFor(
    CoreBadgeVariant variant,
    CoreBadgeForm form,
  ) {
    if (form == CoreBadgeForm.dot) {
      return CoreBadgeStyle(backgroundColor: dotColor);
    }
    return switch (variant) {
      CoreBadgeVariant.filled => CoreBadgeStyle(
        backgroundColor: filledBackgroundColor,
        foregroundColor: filledForegroundColor,
      ),
      CoreBadgeVariant.tonal => CoreBadgeStyle(
        backgroundColor: tonalBackgroundColor,
        foregroundColor: tonalForegroundColor,
      ),
      CoreBadgeVariant.outlined => CoreBadgeStyle(
        backgroundColor: CoreBadgeStyle.defaultOutlinedBackgroundColor,
        foregroundColor: outlinedForegroundColor,
        borderColor: outlinedBorderColor,
        iconStyle: outlinedMarkColor == null
            ? null
            : CoreIconStyle(color: outlinedMarkColor),
        leadingDotColor: outlinedMarkColor,
      ),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBadgeToneStyle &&
          filledBackgroundColor == other.filledBackgroundColor &&
          filledForegroundColor == other.filledForegroundColor &&
          tonalBackgroundColor == other.tonalBackgroundColor &&
          tonalForegroundColor == other.tonalForegroundColor &&
          outlinedBorderColor == other.outlinedBorderColor &&
          outlinedForegroundColor == other.outlinedForegroundColor &&
          outlinedMarkColor == other.outlinedMarkColor &&
          dotColor == other.dotColor;

  @override
  int get hashCode => Object.hash(
    filledBackgroundColor,
    filledForegroundColor,
    tonalBackgroundColor,
    tonalForegroundColor,
    outlinedBorderColor,
    outlinedForegroundColor,
    outlinedMarkColor,
    dotColor,
  );
}
