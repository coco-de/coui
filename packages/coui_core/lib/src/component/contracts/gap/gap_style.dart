/// Per-instance style for `Gap`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Per-instance style for the unified `Gap` layout primitive.
///
/// Bundles the chrome scalars that decide the gap's main-axis size,
/// cross-axis size, and fill colour into a single `CoreStyle` so the
/// merge chain (`design-system default` → `CoreGapTheme.style` →
/// `widget.gapStyle`) can be folded by `resolveStyleChain`.
@immutable
class CoreGapStyle implements CoreStyle<CoreGapStyle> {
  /// Creates a [CoreGapStyle].
  const CoreGapStyle({this.size, this.crossAxisExtent, this.color});

  /// Gap size along the parent's main axis (logical px). `null`
  /// inherits from the theme or the design-system default
  /// ([defaultSize]).
  final double? size;

  /// Gap size along the parent's cross axis (logical px). `null` leaves the
  /// cross axis to the parent — Web stretches (`align-self: stretch`),
  /// Flutter passes `RenderGap` a `0` extent the parent may stretch.
  ///
  /// No paired `default*`: both platforms branch on it being unset, so a
  /// default flips both — the stretch class goes away and every gap claims
  /// cross-axis space, painting a band wherever [color] is set. Cross-axis
  /// fill is opt-in through `Gap.expand` (`double.infinity`).
  ///
  /// **Deliberately has no `default*` — absence is the design.** Both
  /// platforms branch on absence, in opposite directions: Web emits
  /// `align-self: stretch` ONLY when null; Flutter passes RenderGap a 0
  /// cross extent so the gap claims no cross-axis space. A default
  /// removes the stretch class and makes every gap in the kit claim space
  /// (painting a band wherever `color` is set). Cross-axis fill is opt-in
  /// via Gap.expand(double.infinity).
  final double? crossAxisExtent;

  /// Fill colour painted across the gap's rectangle. `null` keeps the
  /// gap transparent.
  ///
  /// No paired `default*`: Flutter returns early from `paint` and Web emits
  /// no `background-color`. A default would paint a rectangle in every gap
  /// in the kit — `Gap` is the spacer every other component composes.
  ///
  /// **Deliberately has no `default*` — absence is the design.**
  /// RenderGap.paint returns early on null (`if (fill == null) return`)
  /// and Web omits background-color. A default paints a rectangle in
  /// every gap in the kit — Gap is the spacer every other component
  /// composes.
  final CoreColor? color;

  /// Design-system default gap size (logical px) used when neither the
  /// widget nor `CoreGapTheme.style` supplies a value.
  ///
  /// Single source of truth shared by Flutter and Web resolvers.
  static const double defaultSize = CoreSpace.space4;

  @override
  CoreGapStyle merge(CoreGapStyle? other) {
    if (other == null) return this;
    return CoreGapStyle(
      size: other.size ?? size,
      crossAxisExtent: other.crossAxisExtent ?? crossAxisExtent,
      color: other.color ?? color,
    );
  }

  /// Returns a copy of this style with the given fields replaced.
  CoreGapStyle copyWith({
    double? size,
    double? crossAxisExtent,
    CoreColor? color,
  }) {
    return CoreGapStyle(
      size: size ?? this.size,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreGapStyle &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          crossAxisExtent == other.crossAxisExtent &&
          color == other.color;

  @override
  int get hashCode => Object.hash(size, crossAxisExtent, color);
}
