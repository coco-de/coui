/// Per-instance style for `DotIndicator`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/dot_indicator/dot_indicator_size.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `DotIndicator` should render.
///
/// Platform-neutral (Epic #1415 option D). Behavioural fields
/// (`index` / `length` / `onChanged` / `direction`) and the semantic
/// `size` identifier stay on the widget.
@immutable
class CoreDotIndicatorStyle implements CoreStyle<CoreDotIndicatorStyle> {
  /// Creates a [CoreDotIndicatorStyle].
  const CoreDotIndicatorStyle({
    this.spacing,
    this.padding,
    this.dotSize,
    this.activeLength,
    this.borderRadius,
    this.activeColor,
    this.inactiveColor,
    this.inactiveBorderColor,
    this.inactiveBorderWidth,
    this.hoverBorderColor,
    this.transitionDuration,
    this.focusOutlineStyle,
  });

  // ─── Design-system defaults ─────────────────────────────────────

  /// Default uniform padding around the dot container. Does not vary by
  /// size — the designer's set binds `space/8` on every rung.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Default border radius (pill shape). Flutter 는 직접 (`BorderRadius.
  /// circular(...)`), Web 은 어댑터의 `tailwindRadius` extension 으로 매핑.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default inactive dot border width — **zero**.
  ///
  /// The designer's decision: an inactive dot is a filled disc, not a
  /// ring. A ring reads as *more* present than a fill at these sizes
  /// (the stroke catches the eye on the thing that is meant to recede),
  /// and it makes active-vs-inactive a difference of *shape* rather than
  /// of tone. With both states filled, the only difference left is
  /// lightness — [defaultActiveColor] against [defaultInactiveColor].
  ///
  /// The border fields stay on the class: a caller who wants rings back
  /// states a width here (and, if they want the fill gone too,
  /// `inactiveColor: CoreColor.transparent`).
  static const double defaultInactiveBorderWidth = CoreStrokeWidth.stroke0;

  /// Default transition duration for active / hover state changes, as a
  /// [Duration] for the [transitionDuration] override slot.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// The active marker stays circular by default, including when the
  /// caller overrides the dot diameter.
  static double defaultActiveLength(double dotSize) => dotSize;

  /// Default active dot colour — `onSurface` token.
  ///
  /// A dot indicator states *where you are*, not what to press, so it
  /// does not spend the accent: `primary` is reserved for the thing a
  /// person is meant to act on. `Tabs` draws its selection rule from the
  /// same reasoning.
  static const CoreColor defaultActiveColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default inactive dot fill — `outlineVariant` token.
  ///
  /// Both states are filled discs (see [defaultInactiveBorderWidth]), so
  /// the active dot is told apart by tone alone — [defaultActiveColor]
  /// against this.
  static const CoreColor defaultInactiveColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default inactive dot border colour — `outlineVariant` token.
  static const CoreColor defaultInactiveBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default hover border colour for clickable inactive dots — `primary` token.
  ///
  /// Invisible under the shipped defaults: [defaultInactiveBorderWidth] is
  /// zero, so there is no stroke to paint. It applies to callers who state
  /// a border width of their own. What a hovered dot shows by default is
  /// its scale step; a hover *fill* is the next change on this field's
  /// heels and needs a pose axis this set does not have yet.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default nested [CoreFocusOutlineStyle] partial for the selected dot's
  /// focus ring — empty: nothing about the dot's ring diverges from the
  /// focus-outline layer's own ring, so every field stays null and the
  /// focus outline fills its own defaults (`core/style-contract.md`'s
  /// partial-forward rule — a parent that reached into the child's
  /// defaults field by field would be a second copy of them). Named so
  /// the resolvers have one default to forward through instead of each
  /// passing the raw slot.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle();

  // ─── Size-keyed defaults ─────────────────────────────────────────
  //
  // Dot diameter and inter-dot gap are the two fields the designer's set
  // varies by size — every rung binds `size/N` on the dots and `space/N`
  // on the gap with the same `N` — so one entry per size carries both.
  // `CoreDotIndicatorSize` is a dedicated enum (not the shared
  // `CoreComponentSize`) because the ladder is exactly the three rungs
  // the canvas offers.

  /// Per-size default dot diameter + spacing — single source of truth
  /// shared by Flutter and Web. The map value is `CoreDotIndicatorStyle`
  /// itself (Progress / Fab pattern) so the flat [dotSize] / [spacing]
  /// slots stay 1:1 with the per-size defaults. Both resolvers read
  /// `CoreDotIndicatorStyle.defaultsBySize[size]!.dotSize!` /
  /// `.spacing!` when the merged slot is unset. `md` (8px / 8px) is the
  /// default rung; the previous unparameterized defaults carried 12px
  /// dots at 8px spacing, which no rung reproduces exactly.
  static const Map<CoreDotIndicatorSize, CoreDotIndicatorStyle> defaultsBySize =
      {
        CoreDotIndicatorSize.sm: CoreDotIndicatorStyle(
          dotSize: CoreSpace.space6,
          spacing: CoreSpace.space6,
        ),
        CoreDotIndicatorSize.md: CoreDotIndicatorStyle(
          dotSize: CoreSpace.space8,
          spacing: CoreSpace.space8,
        ),
        CoreDotIndicatorSize.lg: CoreDotIndicatorStyle(
          dotSize: CoreSpace.space12,
          spacing: CoreSpace.space12,
        ),
      };

  // ─── Fields ─────────────────────────────────────────────────────

  /// Spacing between individual dots (logical px). `null` defers to
  /// [defaultsBySize] for the active `CoreDotIndicatorSize`.
  final double? spacing;

  /// Uniform padding around the dot indicator container.
  final CoreEdgeInsets? padding;

  /// Dot size override (logical px). `null` defers to [defaultsBySize]
  /// for the active `CoreDotIndicatorSize`.
  final double? dotSize;

  /// Active indicator length along the layout axis, in logical pixels.
  /// When omitted, it uses the [dotSize] in effect and stays circular.
  final double? activeLength;

  /// Dot border radius override.
  final CoreBorderRadius? borderRadius;

  /// Active dot colour override.
  final CoreColor? activeColor;

  /// Inactive dot fill override. Defaults to [defaultInactiveColor] — a
  /// solid `outlineVariant` disc. `CoreColor.transparent` restores a ring
  /// (fill absent, [inactiveBorderColor] alone).
  final CoreColor? inactiveColor;

  /// Inactive dot border colour override.
  final CoreColor? inactiveBorderColor;

  /// Inactive dot border width override (logical px).
  final double? inactiveBorderWidth;

  /// Hover border colour override for clickable inactive dots. `null`
  /// defers to [defaultHoverBorderColor]. Only reaches the screen when a
  /// border width is stated — see [defaultInactiveBorderWidth].
  final CoreColor? hoverBorderColor;

  /// Transition duration override for active / hover state changes.
  /// `null` defers to [defaultTransitionDuration].
  final Duration? transitionDuration;

  // ── Slot Styles (nested) ─────────────────────

  /// Focus ring drawn around the selected dot while the indicator group
  /// has keyboard focus (like a radio group, the group is one tab stop and
  /// arrow keys move the selection). Passed on as is; fields left unset
  /// take the focus ring's own defaults.
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreDotIndicatorStyle merge(CoreDotIndicatorStyle? other) {
    if (other == null) return this;
    return CoreDotIndicatorStyle(
      spacing: other.spacing ?? spacing,
      padding: other.padding ?? padding,
      dotSize: other.dotSize ?? dotSize,
      activeLength: other.activeLength ?? activeLength,
      borderRadius: other.borderRadius ?? borderRadius,
      activeColor: other.activeColor ?? activeColor,
      inactiveColor: other.inactiveColor ?? inactiveColor,
      inactiveBorderColor: other.inactiveBorderColor ?? inactiveBorderColor,
      inactiveBorderWidth: other.inactiveBorderWidth ?? inactiveBorderWidth,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreDotIndicatorStyle copyWith({
    double? spacing,
    CoreEdgeInsets? padding,
    double? dotSize,
    double? activeLength,
    CoreBorderRadius? borderRadius,
    CoreColor? activeColor,
    CoreColor? inactiveColor,
    CoreColor? inactiveBorderColor,
    double? inactiveBorderWidth,
    CoreColor? hoverBorderColor,
    Duration? transitionDuration,
    CoreFocusOutlineStyle? focusOutlineStyle,
  }) {
    return CoreDotIndicatorStyle(
      spacing: spacing ?? this.spacing,
      padding: padding ?? this.padding,
      dotSize: dotSize ?? this.dotSize,
      activeLength: activeLength ?? this.activeLength,
      borderRadius: borderRadius ?? this.borderRadius,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      inactiveBorderColor: inactiveBorderColor ?? this.inactiveBorderColor,
      inactiveBorderWidth: inactiveBorderWidth ?? this.inactiveBorderWidth,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDotIndicatorStyle &&
          runtimeType == other.runtimeType &&
          spacing == other.spacing &&
          padding == other.padding &&
          dotSize == other.dotSize &&
          activeLength == other.activeLength &&
          borderRadius == other.borderRadius &&
          activeColor == other.activeColor &&
          inactiveColor == other.inactiveColor &&
          inactiveBorderColor == other.inactiveBorderColor &&
          inactiveBorderWidth == other.inactiveBorderWidth &&
          hoverBorderColor == other.hoverBorderColor &&
          transitionDuration == other.transitionDuration &&
          focusOutlineStyle == other.focusOutlineStyle;

  @override
  int get hashCode => Object.hash(
    spacing,
    padding,
    dotSize,
    activeLength,
    borderRadius,
    activeColor,
    inactiveColor,
    inactiveBorderColor,
    inactiveBorderWidth,
    hoverBorderColor,
    transitionDuration,
    focusOutlineStyle,
  );
}
