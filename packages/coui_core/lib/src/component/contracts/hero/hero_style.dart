/// Per-instance style for the `Hero` block.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/hero/hero_layout.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/motion/easing_scale.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Hero` block should render.
///
/// `CoreHeroStyle` carries chrome / dimensional fields, including the
/// entrance recipe (duration, travel, easing) and the split gutter.
/// Whether that entrance runs is behaviour — `appear` stays flat on the
/// widget / contract. Which arrangement the caller asked for also stays
/// flat (`Hero.layout`); [layout] here is only the project default used
/// when that prop is null. Content fields (`child`, `media`, `imageUrl`,
/// `semanticLabel`) stay on the contract.
///
/// ```text
/// design system default (this class' `static const defaultX`)
///   → CoreHeroTheme.style                              // 프로젝트 공통
///   → parent component slot override
///   → widget.heroStyle                                 // 인스턴스별
/// ```
@immutable
class CoreHeroStyle implements CoreStyle<CoreHeroStyle> {
  /// Creates a [CoreHeroStyle].
  const CoreHeroStyle({
    this.backgroundColor,
    this.overlayColor,
    this.minHeight,
    this.padding,
    this.layout,
    this.splitGapStyle,
    this.appearDuration,
    this.appearOffset,
    this.appearCurve,
  });

  /// Default background colour token — the surface-container role.
  ///
  /// Single source of truth shared by Flutter and Web; each platform
  /// resolves the token through its own scheme path (Flutter
  /// `scheme.resolve(...).toValue()`, Web `bg-{token}` Tailwind class).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default minimum hero height in logical pixels.
  static const double defaultMinHeight = 400;

  /// Default symmetric outer padding.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space32,
  );

  /// Default arrangement — centred copy, the historical hero.
  ///
  /// A [CoreHeroLayout] rather than a variant enum: the two members are
  /// one block arranged differently, not chrome sets a project would
  /// tone separately. The widget prop wins when it is non-null.
  static const CoreHeroLayout defaultLayout = CoreHeroLayout.center;

  /// Default gutter between copy and media on [CoreHeroLayout.split].
  ///
  /// [CoreSpace.space32], the same step as [defaultPadding], so the
  /// pair's internal gap matches the hero's outer inset. Forwarded raw
  /// to `Gap`; the gap's own resolver scales it.
  static const CoreGapStyle defaultSplitGapStyle = CoreGapStyle(
    size: CoreSpace.space32,
  );

  /// Default entrance duration — [CoreDuration.moderate], the alias for
  /// a medium element entering (modal entry, panel slide).
  ///
  /// An alias rather than a raw step so reduced motion, which only
  /// zeroes the transition tier, can reach this default on both
  /// platforms.
  static const Duration defaultAppearDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// Default upward travel of the foreground during the entrance, in
  /// logical pixels.
  ///
  /// [CoreSpace.space16] — short enough to read as an entrance, not a
  /// slide that covers the next section.
  static const double defaultAppearOffset = CoreSpace.space16;

  /// Default entrance easing — [CoreEasing.enter] (ease-out), the alias
  /// for something arriving and settling.
  static const CoreCubicBezier defaultAppearCurve = CoreEasing.enter;

  /// Background colour override.
  final CoreColor? backgroundColor;

  /// Semi-transparent overlay colour drawn on top of the background
  /// image.
  ///
  /// No `default*`, deliberately — this field's absence is not a missing
  /// value, it is the absence of the overlay layer itself. Both
  /// platforms treat it as a whole-node condition rather than a colour:
  /// Flutter renders `Positioned.fill(ColoredBox(...))` only inside
  /// `if (resolved.overlayColor != null)`, and Web leaves
  /// `ResolvedHero.overlay` null so the overlay `<div>` is never built
  /// (the one design-optional slot in that resolver — every other slot
  /// chrome is non-null).
  ///
  /// A default would therefore scrim every hero in the tree, including
  /// the ones with no background image to scrim, and would add a DOM
  /// node to markup that does not have one. [backgroundColor] next to it
  /// is defaulted for the opposite reason: the background is always
  /// painted, so it always needs a value.
  final CoreColor? overlayColor;

  /// Minimum height in logical pixels.
  final double? minHeight;

  /// Outer padding.
  final CoreEdgeInsets? padding;

  /// Project default for `Hero.layout`. `null` uses [defaultLayout]
  /// ([CoreHeroLayout.center]). The widget prop wins when it is set.
  final CoreHeroLayout? layout;

  /// Gutter between copy and media when the resolved layout is
  /// [CoreHeroLayout.split]. `null` uses [defaultSplitGapStyle].
  ///
  /// Nested [CoreGapStyle] forwarded raw to the inner `Gap`.
  final CoreGapStyle? splitGapStyle;

  /// Entrance duration. `null` uses [defaultAppearDuration]
  /// (`CoreDuration.moderate`). Read only when the widget's `appear`
  /// is true. Web publishes the value as a `--coui-duration-*` variable
  /// so `prefers-reduced-motion` can zero it; Flutter applies the same
  /// policy through `resolveMotionDuration`.
  final Duration? appearDuration;

  /// How far the foreground travels upward during the entrance, in
  /// logical pixels. `null` uses [defaultAppearOffset]
  /// (`CoreSpace.space16`). Read only when the widget's `appear` is
  /// true.
  final double? appearOffset;

  /// Entrance easing. `null` uses [defaultAppearCurve]
  /// (`CoreEasing.enter`). Read only when the widget's `appear` is
  /// true.
  final CoreCubicBezier? appearCurve;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreHeroStyle merge(CoreHeroStyle? other) {
    if (other == null) return this;
    return CoreHeroStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      overlayColor: other.overlayColor ?? overlayColor,
      minHeight: other.minHeight ?? minHeight,
      padding: other.padding ?? padding,
      layout: other.layout ?? layout,
      splitGapStyle: other.splitGapStyle ?? splitGapStyle,
      appearDuration: other.appearDuration ?? appearDuration,
      appearOffset: other.appearOffset ?? appearOffset,
      appearCurve: other.appearCurve ?? appearCurve,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreHeroStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? overlayColor,
    double? minHeight,
    CoreEdgeInsets? padding,
    CoreHeroLayout? layout,
    CoreGapStyle? splitGapStyle,
    Duration? appearDuration,
    double? appearOffset,
    CoreCubicBezier? appearCurve,
  }) {
    return CoreHeroStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      overlayColor: overlayColor ?? this.overlayColor,
      minHeight: minHeight ?? this.minHeight,
      padding: padding ?? this.padding,
      layout: layout ?? this.layout,
      splitGapStyle: splitGapStyle ?? this.splitGapStyle,
      appearDuration: appearDuration ?? this.appearDuration,
      appearOffset: appearOffset ?? this.appearOffset,
      appearCurve: appearCurve ?? this.appearCurve,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreHeroStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          overlayColor == other.overlayColor &&
          minHeight == other.minHeight &&
          padding == other.padding &&
          layout == other.layout &&
          splitGapStyle == other.splitGapStyle &&
          appearDuration == other.appearDuration &&
          appearOffset == other.appearOffset &&
          appearCurve == other.appearCurve;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    overlayColor,
    minHeight,
    padding,
    layout,
    splitGapStyle,
    appearDuration,
    appearOffset,
    appearCurve,
  );
}

/// Renamed to [CoreHeroStyle] (since 0.146).
///
/// Same fields. `layout` and `splitGapStyle` are new and default to the
/// centred hero with a `space32` gutter, so an existing
/// `CoreHeroSectionStyle(...)` call keeps its picture.
@Deprecated(
  'Renamed to CoreHeroStyle (since 0.146) — Hero is a Block. Same '
  'fields; layout defaults to center.',
)
typedef CoreHeroSectionStyle = CoreHeroStyle;

/// Widget prop, then the instance style, then the theme style, then
/// [CoreHeroStyle.defaultLayout].
///
/// Same order as `resolveStyleChain(const CoreHeroStyle(), [theme, widget])`
/// followed by the widget's `layout` prop. Both platforms call this so the
/// choice stays off `ResolvedHero` — that type is paint-ready chrome, and
/// [CoreHeroLayout] is not chrome.
CoreHeroLayout heroEffectiveLayout({
  CoreHeroLayout? layout,
  CoreHeroStyle? themeStyle,
  CoreHeroStyle? widgetStyle,
}) {
  return layout ??
      widgetStyle?.layout ??
      themeStyle?.layout ??
      CoreHeroStyle.defaultLayout;
}
