/// Per-instance style for `RefreshTrigger`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `RefreshTrigger` indicator
/// should render.
///
/// `CoreRefreshTriggerStyle` carries the indicator chrome / dimensional
/// / animation overrides as platform-neutral domain-typed fields, plus
/// a nested `CoreTextStyle` for the indicator label slot.
///
/// Variant-independent design-system defaults live as `static const`
/// on this class — Flutter and Web resolvers reference the same
/// `CoreRefreshTriggerStyle.defaultX` so the two platforms cannot
/// silently diverge. The refresh trigger has no visual variant.
///
/// ```text
/// design system default (CoreRefreshTriggerStyle.defaultX)
///   -> CoreRefreshTriggerTheme.style                  // 프로젝트 공통
///   -> parent component slot override
///   -> widget.refreshTriggerStyle                     // 인스턴스별
/// ```
@immutable
class CoreRefreshTriggerStyle implements CoreStyle<CoreRefreshTriggerStyle> {
  /// Creates a [CoreRefreshTriggerStyle].
  const CoreRefreshTriggerStyle({
    this.indicatorBackgroundColor,
    this.indicatorBorderRadius,
    this.indicatorPadding,
    this.pullingPadding,
    this.indicatorGapStyle,
    this.idleTextStyle,
    this.refreshingTextStyle,
    this.completedTextStyle,
    this.animationDuration,
    this.labelStyle,
  });

  // ── Design-system defaults (Epic #1696 Phase 5) ──
  //
  // Variant-independent defaults — single source of truth shared by
  // the Flutter and Web resolvers. The refresh trigger has no visual
  // variant so there is no `defaultsByVariant` map.

  /// Default indicator surface fill.
  static const CoreColor defaultIndicatorBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default indicator corner radius (16 logical px on all four
  /// corners — box level).
  static const CoreBorderRadius defaultIndicatorBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius16);

  /// Default indicator content padding in the resting state
  /// (12 logical px horizontal, 4 logical px vertical).
  static const CoreEdgeInsets defaultIndicatorPadding =
      CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space4,
      );

  /// Default indicator content padding in the compact `pulling`
  /// state (4 logical px on all sides).
  static const CoreEdgeInsets defaultPullingPadding = CoreEdgeInsets.all(
    CoreSpace.space4,
  );

  /// Default nested [CoreGapStyle] slot for the gap between indicator
  /// elements (icon and label) — size matches the historical
  /// `CoreSpace.space8` scalar. Both Flutter and Web resolvers merge
  /// per-instance [indicatorGapStyle] on top of this default and
  /// forward the resulting slot to the `Gap` siblings rendered
  /// between the indicator row children.
  static const CoreGapStyle defaultIndicatorGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default per-stage text style for the `idle` / `pulling` stages —
  /// `labelLarge` typography carrying the `onSurfaceVariant` foreground
  /// colour inline. The role token is materialised through the
  /// canonical `.toValue(theme:)` / `emitTypography` path so the role
  /// survives into the rendered label (raw `idleTextColor` field
  /// replaced by this nested [CoreTextStyle] slot).
  static const CoreTextStyle defaultIdleTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default per-stage text style for the `refreshing` stage —
  /// `labelLarge` typography carrying the `primary` foreground colour
  /// inline (raw `refreshingTextColor` field replaced by the nested
  /// [CoreTextStyle] slot).
  static const CoreTextStyle defaultRefreshingTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.primary),
  );

  /// Default per-stage text style for the `completed` stage —
  /// `labelLarge` typography carrying the `success` foreground colour
  /// inline (raw `completedTextColor` field replaced by the nested
  /// [CoreTextStyle] slot).
  static const CoreTextStyle defaultCompletedTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.success),
  );

  /// Default slide / cross-fade animation duration (300 ms).
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default completion-hold duration before returning to idle
  /// (500 ms). Behaviour constant — not chrome.
  static const Duration defaultCompleteDuration = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// Default minimum pull extent required to trigger refresh
  /// (75 logical px). Behaviour constant — feeds the widget's flat
  /// `minExtent` parameter default and is not part of [merge].
  static const double defaultMinExtent = 75;

  /// Default maximum allowed pull extent (150 logical px). Behaviour
  /// constant — feeds the widget's flat `maxExtent` parameter default
  /// and is not part of [merge].
  static const double defaultMaxExtent = 150;

  // ── Indicator chrome (flat) ──────────────────────

  /// Indicator surface fill colour override.
  final CoreColor? indicatorBackgroundColor;

  /// Indicator corner radius override.
  final CoreBorderRadius? indicatorBorderRadius;

  /// Indicator content padding override for the resting state.
  final CoreEdgeInsets? indicatorPadding;

  /// Indicator content padding override for the compact `pulling`
  /// state.
  final CoreEdgeInsets? pullingPadding;

  /// Style of the `Gap`s between the indicator's elements (icon and
  /// label). Merged on top of [defaultIndicatorGapStyle].
  final CoreGapStyle? indicatorGapStyle;

  /// Per-stage text style override for the `idle` / `pulling` stages.
  /// Text colour is carried via [CoreTextStyle.color] inside this slot
  /// (sb8 — raw `idleTextColor` field removed). Defaults to
  /// [defaultIdleTextStyle].
  final CoreTextStyle? idleTextStyle;

  /// Per-stage text style override for the `refreshing` stage. Text
  /// colour is carried via [CoreTextStyle.color] inside this slot
  /// (sb8 — raw `refreshingTextColor` field removed). Defaults to
  /// [defaultRefreshingTextStyle].
  final CoreTextStyle? refreshingTextStyle;

  /// Per-stage text style override for the `completed` stage. Text
  /// colour is carried via [CoreTextStyle.color] inside this slot
  /// (sb8 — raw `completedTextColor` field removed). Defaults to
  /// [defaultCompletedTextStyle].
  final CoreTextStyle? completedTextStyle;

  /// Slide / cross-fade animation duration override.
  final Duration? animationDuration;

  // ── Slot Styles (nested) ─────────────────────────

  /// Indicator label text style override.
  ///
  /// **No `defaultLabelStyle`, deliberately — this field's baseline is
  /// stage-keyed and already exists under three other names.** It is a
  /// cross-stage *overlay*, not a stage's own style: Flutter merges it
  /// last onto each per-stage slot
  /// ([defaultIdleTextStyle] / [defaultRefreshingTextStyle] /
  /// [defaultCompletedTextStyle], each already a `default*`), and Web
  /// passes the active stage's slot as `emitTypography`'s *default*
  /// argument with this field as its *value*. Because the overlay is
  /// merged last, any non-null constant here wins over all three stage
  /// defaults at once — their `labelLarge` role would become unreachable
  /// on both platforms while the stage colours (forced separately) kept
  /// working, so the regression would read as "the label is the wrong
  /// size" with nothing nearby to explain it.
  final CoreTextStyle? labelStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested labelStyle and
  /// indicatorGapStyle are merged recursively.
  @override
  CoreRefreshTriggerStyle merge(CoreRefreshTriggerStyle? other) {
    if (other == null) return this;
    return CoreRefreshTriggerStyle(
      indicatorBackgroundColor:
          other.indicatorBackgroundColor ?? indicatorBackgroundColor,
      indicatorBorderRadius:
          other.indicatorBorderRadius ?? indicatorBorderRadius,
      indicatorPadding: other.indicatorPadding ?? indicatorPadding,
      pullingPadding: other.pullingPadding ?? pullingPadding,
      indicatorGapStyle: _mergeGap(
        indicatorGapStyle,
        other.indicatorGapStyle,
      ),
      idleTextStyle: _mergeText(idleTextStyle, other.idleTextStyle),
      refreshingTextStyle: _mergeText(
        refreshingTextStyle,
        other.refreshingTextStyle,
      ),
      completedTextStyle: _mergeText(
        completedTextStyle,
        other.completedTextStyle,
      ),
      animationDuration: other.animationDuration ?? animationDuration,
      labelStyle: _mergeText(labelStyle, other.labelStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreRefreshTriggerStyle copyWith({
    CoreColor? indicatorBackgroundColor,
    CoreBorderRadius? indicatorBorderRadius,
    CoreEdgeInsets? indicatorPadding,
    CoreEdgeInsets? pullingPadding,
    CoreGapStyle? indicatorGapStyle,
    CoreTextStyle? idleTextStyle,
    CoreTextStyle? refreshingTextStyle,
    CoreTextStyle? completedTextStyle,
    Duration? animationDuration,
    CoreTextStyle? labelStyle,
  }) {
    return CoreRefreshTriggerStyle(
      indicatorBackgroundColor:
          indicatorBackgroundColor ?? this.indicatorBackgroundColor,
      indicatorBorderRadius:
          indicatorBorderRadius ?? this.indicatorBorderRadius,
      indicatorPadding: indicatorPadding ?? this.indicatorPadding,
      pullingPadding: pullingPadding ?? this.pullingPadding,
      indicatorGapStyle: indicatorGapStyle ?? this.indicatorGapStyle,
      idleTextStyle: idleTextStyle ?? this.idleTextStyle,
      refreshingTextStyle: refreshingTextStyle ?? this.refreshingTextStyle,
      completedTextStyle: completedTextStyle ?? this.completedTextStyle,
      animationDuration: animationDuration ?? this.animationDuration,
      labelStyle: labelStyle ?? this.labelStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreRefreshTriggerStyle &&
          runtimeType == other.runtimeType &&
          indicatorBackgroundColor == other.indicatorBackgroundColor &&
          indicatorBorderRadius == other.indicatorBorderRadius &&
          indicatorPadding == other.indicatorPadding &&
          pullingPadding == other.pullingPadding &&
          indicatorGapStyle == other.indicatorGapStyle &&
          idleTextStyle == other.idleTextStyle &&
          refreshingTextStyle == other.refreshingTextStyle &&
          completedTextStyle == other.completedTextStyle &&
          animationDuration == other.animationDuration &&
          labelStyle == other.labelStyle;

  @override
  int get hashCode => Object.hash(
    indicatorBackgroundColor,
    indicatorBorderRadius,
    indicatorPadding,
    pullingPadding,
    indicatorGapStyle,
    idleTextStyle,
    refreshingTextStyle,
    completedTextStyle,
    animationDuration,
    labelStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
