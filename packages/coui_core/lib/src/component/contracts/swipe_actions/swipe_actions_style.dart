/// Per-instance style for `SwipeActions`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how the actions behind a `SwipeActions` row
/// are drawn.
///
/// The row slides over a **platter** — the strip at one edge that holds the
/// actions. Each action is a **cell** of a fixed [actionWidth] holding a
/// composed `Button` and, under it, the action's label; the cells sit
/// [actionSpacing] apart and [platterInset] in from each end of the platter.
/// The cell width is a number rather than a measurement on purpose: it is
/// what lets Core say how far the row opens ([extentFor]) and both seats
/// agree on it without laying text out.
///
/// ```text
/// design system default
///   → CoreSwipeActionsTheme.style
///   → widget.swipeActionsStyle
/// ```
///
/// Behaviour — thresholds, the fling speed, the settle — is not here; it is
/// on `CoreSwipeActionsContract`.
@immutable
class CoreSwipeActionsStyle implements CoreStyle<CoreSwipeActionsStyle> {
  /// Creates a [CoreSwipeActionsStyle].
  const CoreSwipeActionsStyle({
    this.actionWidth,
    this.actionSpacing,
    this.platterInset,
    this.platterColor,
    this.labelGapStyle,
    this.labelStyle,
    this.fullSwipeScale,
    this.actionButtonStyle,
  });

  // ─── Design-system defaults ────────────────────

  /// The width of one action cell (logical px) — the `lg` rung of the control
  /// ladder, which is also the diameter of the circular button inside it
  /// (`CoreSwipeActionsContract.actionButtonSize`).
  ///
  /// Designer-judgement value: the platform list this behaviour comes from
  /// draws a 50-point circle, which is off the ladder; the nearest rung is
  /// 48. `heightXl` (56) is the alternative.
  static const double defaultActionWidth = CoreControlSize.heightLg;

  /// The space between two neighbouring cells (logical px).
  ///
  /// Designer-judgement value: `CoreSpace.space12`, the step the platform
  /// list uses between its circles.
  static const double defaultActionSpacing = CoreSpace.space12;

  /// The space between an end of the platter and the cell next to it (logical
  /// px) — at the row's edge and at the platter's inner end alike.
  ///
  /// Designer-judgement value: `CoreSpace.space12`, as [defaultActionSpacing].
  static const double defaultPlatterInset = CoreSpace.space12;

  /// The platter's fill. Transparent: the page shows between the cells and
  /// the buttons carry the colour.
  ///
  /// Designer-judgement value: the most conservative tint, none — a tonal
  /// container colour is the alternative if the cells should read as one
  /// strip.
  static const CoreColor defaultPlatterColor = CoreColor.transparent;

  /// The space between a cell's button and its label.
  static const CoreGapStyle defaultLabelGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// The label under a button: the `labelSmall` role in the muted content
  /// colour, so the button — not its caption — is what the eye lands on.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// The scale the first action's cell grows to while the row is pulled past
  /// the full-swipe threshold, as a factor — the cue that releasing now runs
  /// it. `1` draws no cue.
  ///
  /// Designer-judgement value: the most conservative scale, none — the
  /// platform list this behaviour comes from grows it to 1.08.
  static const double defaultFullSwipeScale = 1;

  /// How wide a platter holding [count] cells is — how far the row has to
  /// move to uncover all of them (logical px). `0` for no cells.
  ///
  /// `2 × inset + count × width + (count − 1) × spacing`. The one definition
  /// of "how far does this row open": both seats' resolvers and every test
  /// read it, so the row's travel is the platter's width by construction.
  static double extentFor(
    int count, {
    required double actionWidth,
    required double actionSpacing,
    required double platterInset,
  }) {
    if (count <= 0) return 0;

    return 2 * platterInset + count * actionWidth + (count - 1) * actionSpacing;
  }

  // ─── Fields ────────────────────────────────────

  /// The width of one action cell (logical px). `null` →
  /// [defaultActionWidth].
  final double? actionWidth;

  /// The space between neighbouring cells (logical px). `null` →
  /// [defaultActionSpacing].
  final double? actionSpacing;

  /// The space between a platter end and the cell next to it (logical px).
  /// `null` → [defaultPlatterInset].
  final double? platterInset;

  /// The platter's fill. `null` → [defaultPlatterColor].
  final CoreColor? platterColor;

  /// The space between a cell's button and its label. `null` →
  /// [defaultLabelGapStyle].
  final CoreGapStyle? labelGapStyle;

  /// The label's type and colour. `null` → [defaultLabelStyle].
  final CoreTextStyle? labelStyle;

  /// The first action's scale during a full-swipe pull, as a factor. `null` →
  /// [defaultFullSwipeScale].
  final double? fullSwipeScale;

  /// Look of the action buttons, passed to each `Button` as is.
  ///
  /// Deliberately has no default: each action is a circular `Button` of the
  /// `lg` rung in the variant its action asks for, and the chrome of that
  /// variant is the button's own to design. An empty partial here would only
  /// restate it, so `null` forwards nothing and the button resolves its own
  /// defaults.
  final CoreButtonStyle? actionButtonStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slots merge recursively.
  @override
  CoreSwipeActionsStyle merge(CoreSwipeActionsStyle? other) {
    if (other == null) return this;
    return CoreSwipeActionsStyle(
      actionWidth: other.actionWidth ?? actionWidth,
      actionSpacing: other.actionSpacing ?? actionSpacing,
      platterInset: other.platterInset ?? platterInset,
      platterColor: other.platterColor ?? platterColor,
      labelGapStyle: _mergeGap(labelGapStyle, other.labelGapStyle),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      fullSwipeScale: other.fullSwipeScale ?? fullSwipeScale,
      actionButtonStyle:
          actionButtonStyle?.merge(other.actionButtonStyle) ??
          other.actionButtonStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSwipeActionsStyle copyWith({
    double? actionWidth,
    double? actionSpacing,
    double? platterInset,
    CoreColor? platterColor,
    CoreGapStyle? labelGapStyle,
    CoreTextStyle? labelStyle,
    double? fullSwipeScale,
    CoreButtonStyle? actionButtonStyle,
  }) {
    return CoreSwipeActionsStyle(
      actionWidth: actionWidth ?? this.actionWidth,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      platterInset: platterInset ?? this.platterInset,
      platterColor: platterColor ?? this.platterColor,
      labelGapStyle: labelGapStyle ?? this.labelGapStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      fullSwipeScale: fullSwipeScale ?? this.fullSwipeScale,
      actionButtonStyle: actionButtonStyle ?? this.actionButtonStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwipeActionsStyle &&
          runtimeType == other.runtimeType &&
          actionWidth == other.actionWidth &&
          actionSpacing == other.actionSpacing &&
          platterInset == other.platterInset &&
          platterColor == other.platterColor &&
          labelGapStyle == other.labelGapStyle &&
          labelStyle == other.labelStyle &&
          fullSwipeScale == other.fullSwipeScale &&
          actionButtonStyle == other.actionButtonStyle;

  @override
  int get hashCode => Object.hash(
    actionWidth,
    actionSpacing,
    platterInset,
    platterColor,
    labelGapStyle,
    labelStyle,
    fullSwipeScale,
    actionButtonStyle,
  );

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
