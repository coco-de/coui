/// Per-instance style for `Avatar`.
library;

import 'dart:math' as math;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/alignment.dart';
import 'package:coui_core/src/component/contracts/avatar/avatar_badge_placement.dart';
import 'package:coui_core/src/component/contracts/avatar/avatar_badge_style.dart';
import 'package:coui_core/src/component/contracts/avatar/avatar_shape.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Avatar` should render.
///
/// `CoreAvatarStyle` carries chrome / dimensional flat fields plus a
/// nested `fallbackTextStyle` slot for the initials fallback.
///
/// **Semantic enums (`size`, `shape`) and behaviour (`ring`) live on the
/// widget, not on this style** (Epic #1302 원칙 6/7). All 시각 chrome —
/// including composite-layout insets / alignment such as [badgeInset] and
/// [badgeAlignment] — lives here (the former composite-layout
/// exception is abolished per verify.md 7-6).
///
/// Every default lives here as `static const` so Flutter and Web share one
/// source of truth:
///
/// - [defaultsBySize] — the step's diameter, initials role, rounded tile
///   corner, badge size and child icon size.
/// - [defaultsByShape] — what the shape changes on top of the step: the
///   pill a disc takes, and where each shape puts its badge.
///
/// ```text
/// defaultsBySize[size] → defaultsByShape[shape] → CoreAvatarStyle.defaultX
///   → CoreAvatarTheme.style                         // 프로젝트 공통
///   → parent component slot override
///   → widget.avatarStyle                            // 인스턴스별
/// ```
@immutable
class CoreAvatarStyle implements CoreStyle<CoreAvatarStyle> {
  /// Creates a [CoreAvatarStyle].
  const CoreAvatarStyle({
    this.backgroundColor,
    this.diameter,
    this.borderRadius,
    this.ringColor,
    this.ringWidth,
    this.ringOffset,
    this.badgeInset,
    this.badgeAlignment,
    this.badgePlacement,
    this.initialsFontRatio,
    this.fallbackTextStyle,
    this.badgeStyle,
    this.childIconStyle,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────
  // Variant-independent defaults live as static const here so Flutter
  // and Web resolvers share one source of truth.

  /// Default fill background colour (`primaryContainer`) — a tinted disc
  /// that stays distinct from a card face (`surfaceContainer`), where a
  /// neutral fill disappears. The initials sit on it in
  /// `onPrimaryContainer`.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  /// Default initials fallback text style — the part every size shares:
  /// the foreground colour (`onPrimaryContainer`) and the 600 weight,
  /// carried via [CoreTextStyle.color] / [CoreTextStyle.fontWeight]. Matches
  /// the
  /// [fallbackTextStyle] slot field (1:1:1:1) so the resolver reads the
  /// foreground fallback through this single slot default instead of a raw
  /// orphan colour const.
  ///
  /// It states no role: the role is the size's (each row of
  /// [defaultsBySize] states one — `labelXs` at 24 up to `headlineLarge`
  /// at 96), so the resolver lays that role over this default and the
  /// size, tracking and leading come with it. 600 is the avatar's own
  /// statement — the roles are 500 (label) and 700 (title, headline).
  static const CoreTextStyle defaultFallbackTextStyle = CoreTextStyle(
    fontWeight: CoreFontWeight.semiBold,
    color: CoreColor.token(CoreColors.onPrimaryContainer),
  );

  /// Default ring colour when `ring: true` (`primary`).
  static const CoreColor defaultRingColor = CoreColor.token(CoreColors.primary);

  /// Default ring stroke width (`stroke2` = 2px).
  static const double defaultRingWidth = CoreStrokeWidth.stroke2;

  /// Default ring offset (gap between ring and avatar fill, `stroke2` = 2px).
  static const double defaultRingOffset = CoreStrokeWidth.stroke2;

  /// The pill corner — what a disc ([CoreAvatarShape.circle]) takes
  /// whatever its step: on a square box it clamps to a perfect circle.
  ///
  /// [CoreAvatarShape.rounded] does not take it: a tile's corner is per
  /// step in [defaultsBySize]. `resolveAvatar` reads the pill through
  /// [defaultsByShape], not directly; the status dot of `AvatarBadge` is a
  /// separate surface that borrows the pill on its own.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default badge inset (`space0`) — none: a disc's badge centres on the
  /// outline itself and a tile's badge sits flush in its corner. See
  /// [CoreAvatarBadgePlacement] for what the inset is measured from.
  static const double defaultBadgeInset = CoreSpace.space0;

  /// Default badge corner — overlaid at the top-end of the avatar.
  static const CoreAlignment defaultBadgeAlignment = .topEnd;

  /// The placement a shape's row in [defaultsByShape] leaves unstated —
  /// the box corner, the same member as
  /// [CoreAvatarBadgePlacement.defaultPlacement].
  static const CoreAvatarBadgePlacement defaultBadgePlacement =
      CoreAvatarBadgePlacement.corner;

  /// Ratio of initials fontSize to avatar diameter the size-less style
  /// used (0.4).
  @Deprecated(
    'Nothing reads it (since 0.162) — the initials take their size from the '
    'per-size role in defaultsBySize. Pass initialsFontRatio to size them '
    'from the diameter.',
  )
  static const double defaultInitialsFontRatio = 0.4;

  /// Per-size default style — the diameter (logical px) and the initials
  /// role. Single source of truth for the size-variant table: Flutter
  /// reads the `double` diameter directly, Web maps it to a Tailwind size
  /// key via the `core_to_css.dart` adapter, and the Figma export reads
  /// both columns.
  ///
  /// Ladder confirmed by CoUI_Size_Token_Specification §3-4 (Avatar,
  /// v1.1 2026-08-07): 24/32/40/48/64/96. A diameter is an element
  /// dimension, so entries reference [CoreSize] — spacing and size are
  /// separate namespaces. The spec's `display` step (128, standalone
  /// profile-header use) is deliberately not an enum tier — callers
  /// pass `CoreSize.size128` explicitly for that one-off.
  ///
  /// The initials role follows the diameter in steps the type scale
  /// already has — 11 · 13 · 15 · 18 · 24 · 32 — rather than a fixed share
  /// of it, so the letters land on the scale's sizes, tracking and leading
  /// instead of a fraction (9.6 · 12.8 · 16 …) no role states. The role is
  /// each row's [fallbackTextStyle]; [defaultFallbackTextStyle] adds the
  /// colour and weight they share.
  ///
  /// The corner ([borderRadius]) is the rounded tile's
  /// ([CoreAvatarShape.rounded]): a quarter of the diameter, every value on
  /// the radius ladder (24 → 6, 32 → 8, 40 → 10, 48 → 12, 64 → 16,
  /// 96 → 24). It is written here rather than computed from the diameter
  /// so both platforms read one value, and a stated [diameter] keeps the
  /// step's corner — the step decides the corner, not the drawn size. A
  /// disc replaces it with the pill in [defaultsByShape].
  ///
  /// The status badge ([badgeStyle]) grows with the step — 8 · 10 · 12 · 14
  /// · 16 · 20 — so it reads as the same mark beside a 24 avatar and a 96
  /// one; a fixed 12 swallowed the smallest avatars and vanished on the
  /// largest. Its inner ring is `stroke1` at `xs` and `sm`, where a 2px
  /// ring would eat half the dot, and the badge's own `stroke2` above. The
  /// avatar hands this to the `AvatarBadge` in its `badge` slot; a size or a
  /// border the badge states itself still wins.
  ///
  /// The child icon ([childIconStyle]) is about half the diameter — 12 · 16
  /// · 20 · 24 · 32 · 48 — the size an `Icon` handed as `child` draws at
  /// when it states none (an ambient icon size around the slot). A fixed 20
  /// filled the 24 avatar and was a speck in the 96 one.
  ///
  /// Named `defaultsBySize` (the shared 7-name dispatch-registry
  /// convention `core/style-contract.md` reader census expects) rather
  /// than `sizeDiameters` — a name that doesn't start with `default`
  /// is invisible to `defaultsBy*` prefix-matching coverage tooling.
  static const Map<CoreComponentSize, CoreAvatarStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreAvatarStyle(
      diameter: CoreSize.size24,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      fallbackTextStyle: CoreTextStyle.token(CoreTextStyles.labelXs),
      badgeStyle: CoreAvatarBadgeStyle(
        size: CoreSize.size8,
        borderWidth: CoreStrokeWidth.stroke1,
      ),
      childIconStyle: CoreIconStyle(size: CoreIconSize.size12),
    ),
    CoreComponentSize.sm: CoreAvatarStyle(
      diameter: CoreSize.size32,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      fallbackTextStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
      badgeStyle: CoreAvatarBadgeStyle(
        size: CoreSize.size10,
        borderWidth: CoreStrokeWidth.stroke1,
      ),
      childIconStyle: CoreIconStyle(size: CoreIconSize.size16),
    ),
    CoreComponentSize.md: CoreAvatarStyle(
      diameter: CoreSize.size40,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
      fallbackTextStyle: CoreTextStyle.token(CoreTextStyles.labelXl),
      badgeStyle: CoreAvatarBadgeStyle(size: CoreSize.size12),
      childIconStyle: CoreIconStyle(size: CoreIconSize.size20),
    ),
    CoreComponentSize.lg: CoreAvatarStyle(
      diameter: CoreSize.size48,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      fallbackTextStyle: CoreTextStyle.token(CoreTextStyles.titleMedium),
      badgeStyle: CoreAvatarBadgeStyle(size: CoreSize.size14),
      childIconStyle: CoreIconStyle(size: CoreIconSize.size24),
    ),
    CoreComponentSize.xl: CoreAvatarStyle(
      diameter: CoreSize.size64,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      fallbackTextStyle: CoreTextStyle.token(CoreTextStyles.headlineSmall),
      badgeStyle: CoreAvatarBadgeStyle(size: CoreSize.size16),
      childIconStyle: CoreIconStyle(size: CoreIconSize.size32),
    ),
    CoreComponentSize.xl2: CoreAvatarStyle(
      diameter: CoreSize.size96,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
      fallbackTextStyle: CoreTextStyle.token(CoreTextStyles.headlineLarge),
      badgeStyle: CoreAvatarBadgeStyle(size: CoreSize.size20),
      childIconStyle: CoreIconStyle(size: CoreIconSize.size48),
    ),
  };

  /// What each shape changes on top of its step in [defaultsBySize].
  ///
  /// Merged over the size row, so a field a shape leaves null keeps the
  /// step's value:
  ///
  /// - [CoreAvatarShape.circle] takes the pill ([defaultBorderRadius]) and
  ///   centres its badge on the outline
  ///   ([CoreAvatarBadgePlacement.outline]) — a disc has no corner, so a
  ///   badge in its box corner floats off the edge.
  /// - [CoreAvatarShape.rounded] keeps the step's corner and tucks its badge
  ///   into it ([CoreAvatarBadgePlacement.corner]).
  ///
  /// A corner stated on the theme or the instance (`borderRadius`) wins
  /// over both rows, so a project that sets `CoreAvatarTheme.style
  /// .borderRadius` draws every shape with that corner.
  static const Map<CoreAvatarShape, CoreAvatarStyle> defaultsByShape = {
    CoreAvatarShape.circle: CoreAvatarStyle(
      borderRadius: defaultBorderRadius,
      badgePlacement: CoreAvatarBadgePlacement.outline,
    ),
    CoreAvatarShape.rounded: CoreAvatarStyle(
      badgePlacement: CoreAvatarBadgePlacement.corner,
    ),
  };

  // ── Chrome (flat) ────────────────────────────

  /// Avatar fill background colour. Drives both the image placeholder
  /// and the initials fallback. `null` → [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Avatar diameter (logical px). `null` → the diameter the widget's
  /// `size` names in [defaultsBySize]; a value here replaces it for this
  /// instance only (a one-off such as the 128 profile header).
  final double? diameter;

  /// Border radius. `null` → the shape's corner: the pill
  /// ([defaultBorderRadius], through [defaultsByShape]) for a disc, the
  /// step's corner in [defaultsBySize] for a rounded tile. A value here
  /// wins over both shapes.
  final CoreBorderRadius? borderRadius;

  /// Ring (outer border) colour when the widget's `ring` parameter is
  /// `true`. `null` → [defaultRingColor].
  final CoreColor? ringColor;

  /// Ring (outer border) width (logical px) when the widget's `ring`
  /// parameter is `true`. `null` → [defaultRingWidth].
  final double? ringWidth;

  /// Ring offset (gap between ring and avatar fill, logical px) when
  /// the widget's `ring` parameter is `true`. `null` →
  /// [defaultRingOffset].
  final double? ringOffset;

  /// Inset of the badge toward the avatar's centre (logical px,
  /// pre-scaling) — from the box edges for
  /// [CoreAvatarBadgePlacement.corner], from the outline for
  /// [CoreAvatarBadgePlacement.outline]. `null` → [defaultBadgeInset].
  final double? badgeInset;

  /// Corner the badge is overlaid at, relative to the avatar.
  /// Platform-neutral [CoreAlignment] — Flutter maps it to an
  /// `AlignmentGeometry`, Web maps it to CSS edge offsets.
  /// `null` → [defaultBadgeAlignment] (top-end).
  final CoreAlignment? badgeAlignment;

  /// How the badge sits against [badgeAlignment]'s corner — in the box
  /// corner or on the outline. `null` → the shape's row in
  /// [defaultsByShape], then [defaultBadgePlacement].
  final CoreAvatarBadgePlacement? badgePlacement;

  /// Ratio of the initials fallback fontSize to the avatar diameter —
  /// a single-axis behaviour scalar (`fontSize = diameter * ratio`). Only
  /// an instance that states it is sized this way; `null` → the per-size
  /// role in [defaultsBySize], whose size, tracking and leading stand.
  final double? initialsFontRatio;

  // ── Slot Styles (nested) ─────────────────────

  /// Initials fallback text style (rendered when neither image nor
  /// custom child is supplied). Text colour is carried via
  /// [CoreTextStyle.color] inside this slot. `null` → the size's role laid
  /// over [defaultFallbackTextStyle].
  final CoreTextStyle? fallbackTextStyle;

  /// The style the avatar hands the `AvatarBadge` in its `badge` slot —
  /// the badge's own `avatarBadgeStyle` is laid over it, so a size or a
  /// colour the badge states wins. `null` → the size's row in
  /// [defaultsBySize].
  final CoreAvatarBadgeStyle? badgeStyle;

  /// Icon style inherited by the `child` slot — an `Icon` you pass as
  /// `child` without a size of its own is drawn at this one. `null` → the
  /// size's row in [defaultsBySize].
  final CoreIconStyle? childIconStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested fallbackTextStyle
  /// merges recursively.
  @override
  CoreAvatarStyle merge(CoreAvatarStyle? other) {
    if (other == null) return this;
    return CoreAvatarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      diameter: other.diameter ?? diameter,
      borderRadius: other.borderRadius ?? borderRadius,
      ringColor: other.ringColor ?? ringColor,
      ringWidth: other.ringWidth ?? ringWidth,
      ringOffset: other.ringOffset ?? ringOffset,
      badgeInset: other.badgeInset ?? badgeInset,
      badgeAlignment: other.badgeAlignment ?? badgeAlignment,
      badgePlacement: other.badgePlacement ?? badgePlacement,
      initialsFontRatio: other.initialsFontRatio ?? initialsFontRatio,
      fallbackTextStyle: _mergeText(fallbackTextStyle, other.fallbackTextStyle),
      badgeStyle: badgeStyle?.merge(other.badgeStyle) ?? other.badgeStyle,
      childIconStyle:
          childIconStyle?.merge(other.childIconStyle) ?? other.childIconStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreAvatarStyle copyWith({
    CoreColor? backgroundColor,
    double? diameter,
    CoreBorderRadius? borderRadius,
    CoreColor? ringColor,
    double? ringWidth,
    double? ringOffset,
    double? badgeInset,
    CoreAlignment? badgeAlignment,
    CoreAvatarBadgePlacement? badgePlacement,
    double? initialsFontRatio,
    CoreTextStyle? fallbackTextStyle,
    CoreAvatarBadgeStyle? badgeStyle,
    CoreIconStyle? childIconStyle,
  }) {
    return CoreAvatarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      diameter: diameter ?? this.diameter,
      borderRadius: borderRadius ?? this.borderRadius,
      ringColor: ringColor ?? this.ringColor,
      ringWidth: ringWidth ?? this.ringWidth,
      ringOffset: ringOffset ?? this.ringOffset,
      badgeInset: badgeInset ?? this.badgeInset,
      badgeAlignment: badgeAlignment ?? this.badgeAlignment,
      badgePlacement: badgePlacement ?? this.badgePlacement,
      initialsFontRatio: initialsFontRatio ?? this.initialsFontRatio,
      fallbackTextStyle: fallbackTextStyle ?? this.fallbackTextStyle,
      badgeStyle: badgeStyle ?? this.badgeStyle,
      childIconStyle: childIconStyle ?? this.childIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAvatarStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          diameter == other.diameter &&
          borderRadius == other.borderRadius &&
          ringColor == other.ringColor &&
          ringWidth == other.ringWidth &&
          ringOffset == other.ringOffset &&
          badgeInset == other.badgeInset &&
          badgeAlignment == other.badgeAlignment &&
          badgePlacement == other.badgePlacement &&
          initialsFontRatio == other.initialsFontRatio &&
          fallbackTextStyle == other.fallbackTextStyle &&
          badgeStyle == other.badgeStyle &&
          childIconStyle == other.childIconStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    diameter,
    borderRadius,
    ringColor,
    ringWidth,
    ringOffset,
    badgeInset,
    badgeAlignment,
    badgePlacement,
    initialsFontRatio,
    fallbackTextStyle,
    badgeStyle,
    childIconStyle,
  );

  /// Returns the avatar diameter (logical px) for [size].
  static double diameterFor(CoreComponentSize size) =>
      defaultsBySize[size]!.diameter!;

  /// Returns the badge style the avatar hands its `badge` slot at [size].
  static CoreAvatarBadgeStyle badgeStyleFor(CoreComponentSize size) =>
      defaultsBySize[size]!.badgeStyle!;

  /// Returns the ambient icon style around the `child` slot at [size].
  static CoreIconStyle childIconStyleFor(CoreComponentSize size) =>
      defaultsBySize[size]!.childIconStyle!;

  /// Returns the badge placement [shape] states, or
  /// [defaultBadgePlacement] when its row states none.
  static CoreAvatarBadgePlacement badgePlacementFor(CoreAvatarShape shape) =>
      defaultsByShape[shape]?.badgePlacement ?? defaultBadgePlacement;

  /// Where the badge goes on an avatar of [diameter] — the one statement of
  /// the placement geometry both platforms read.
  ///
  /// Returns an anchor point (`x`, `y`, from the avatar box's top-left) and
  /// the point of the badge's own box that sits on it (`alignX`, `alignY`,
  /// as fractions of the badge's width and height: 0 its left / top edge,
  /// 1 its right / bottom edge). Neither depends on the badge's size, so a
  /// badge that states its own size lands in the same place.
  ///
  /// - [CoreAvatarBadgePlacement.corner] — the anchor is [inset] in from
  ///   the corner [alignment] names, and the badge's matching corner sits
  ///   on it.
  /// - [CoreAvatarBadgePlacement.outline] — the anchor is on the disc's
  ///   outline in [alignment]'s direction (`topEnd` is 45° up and out),
  ///   [inset] in from it toward the centre, and the badge's centre sits
  ///   on it. [CoreAlignment.center] has no direction and anchors at the
  ///   centre.
  ///
  /// All lengths are logical px in, logical px out; a platform that scales
  /// the avatar scales [diameter] and [inset] first.
  static ({double x, double y, double alignX, double alignY}) badgeAnchorFor({
    required double diameter,
    required double inset,
    required CoreAlignment alignment,
    required CoreAvatarBadgePlacement placement,
  }) {
    final half = diameter / 2;
    switch (placement) {
      case CoreAvatarBadgePlacement.corner:
        return (
          x: half + alignment.x * (half - inset),
          y: half + alignment.y * (half - inset),
          alignX: (1 + alignment.x) / 2,
          alignY: (1 + alignment.y) / 2,
        );
      case CoreAvatarBadgePlacement.outline:
        return (
          x: half + _unitAlong(alignment.x, alignment.y) * (half - inset),
          y: half + _unitAlong(alignment.y, alignment.x) * (half - inset),
          alignX: 0.5,
          alignY: 0.5,
        );
    }
  }

  /// The [along] component of the unit vector (`along`, `across`) — the
  /// direction an alignment points from the centre. Zero for
  /// [CoreAlignment.center], which points nowhere.
  static double _unitAlong(double along, double across) =>
      along == 0 && across == 0
      ? 0
      : along / math.sqrt(along * along + across * across);

  /// Returns the initials role for [size] (colour and weight come from
  /// [defaultFallbackTextStyle]).
  static CoreTextStyle fallbackRoleFor(CoreComponentSize size) =>
      defaultsBySize[size]!.fallbackTextStyle!;

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
