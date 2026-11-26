/// Per-instance style for `EmptyState`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/empty_state/empty_state_tone.dart';
import 'package:coui_core/src/component/contracts/empty_state/empty_state_variant.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/layout.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

// ─── Empty-state redesign (2026-09-14 spec) — chromeless content stack ──

/// Immutable style describing how a `EmptyState` should render.
///
/// The redesign drops the bordered/filled panel the previous version
/// drew — `EmptyState` states no box of its own any more (no border, no
/// radius, no background), just a centred content stack. The style
/// carries the stack's flat dimensional fields plus nested slot styles
/// for the icon, title, and description.
///
/// ```text
/// CoreEmptyStateStyle.defaults*
///   → CoreEmptyStateStyle.defaultsByVariant[variant]
///   → CoreEmptyStateTheme.style                     // project-wide
///   → CoreEmptyStateTheme.variantStyles[variant]
///   → widget.emptyStateStyle                        // per-instance
/// ```
@immutable
class CoreEmptyStateStyle implements CoreStyle<CoreEmptyStateStyle> {
  /// Creates a [CoreEmptyStateStyle].
  const CoreEmptyStateStyle({
    this.padding,
    this.minHeight,
    this.maxTextWidth,
    this.iconTitleGapStyle,
    this.titleDescriptionGapStyle,
    this.descriptionActionGapStyle,
    this.iconStyle,
    this.iconBoxSize,
    this.iconBoxColor,
    this.iconBoxBorderRadius,
    this.titleTextStyle,
    this.descriptionTextStyle,
  });

  // ── Chrome (flat) ────────────────────────────

  /// Inner padding around the empty-state content (pre-scaling).
  final CoreEdgeInsets? padding;

  /// Minimum height of the empty-state stack (logical px, pre-scaling)
  /// — keeps a region from collapsing when its results vanish. `null` →
  /// the variant's [CoreEmptyStateVariantStyle.minHeight].
  final double? minHeight;

  /// Maximum width of the title + description text block (logical px,
  /// pre-scaling). The stack itself fills whatever width its host
  /// gives it; only the text is capped so long labels wrap instead of
  /// stretching edge to edge.
  final double? maxTextWidth;

  // ── Slot Styles (nested) ─────────────────────

  /// Space between the icon and the title, passed as is to
  /// `Gap(gapStyle: …)`. Laid over the variant's default (see
  /// [defaultsByVariant]).
  final CoreGapStyle? iconTitleGapStyle;

  /// Space between the title and the description, passed as is to
  /// `Gap(gapStyle: …)`. Laid over the variant's default (see
  /// [defaultsByVariant]).
  final CoreGapStyle? titleDescriptionGapStyle;

  /// Space above the action — below the description, or below the title
  /// when the description is hidden. Passed as is to `Gap(gapStyle: …)`
  /// and laid over the variant's default (see [defaultsByVariant]).
  final CoreGapStyle? descriptionActionGapStyle;

  /// Size and colour of the icon, applied to the icon widget you pass the
  /// same way `Button` styles its leading / trailing icon. The icon sits
  /// centred in the icon box ([iconBoxSize]). `null` size uses the
  /// variant's entry in [defaultsByVariant]; `null` colour uses the tone's
  /// entry in [defaultsByTone] ([defaultIconColor] for `neutral`).
  final CoreIconStyle? iconStyle;

  /// Edge length of the circular icon box the icon sits in (logical px,
  /// pre-scaling). `null` → the variant's
  /// [CoreEmptyStateVariantStyle.iconBoxSize].
  final double? iconBoxSize;

  /// Fill of the icon box. `null` → the tone's entry in [defaultsByTone].
  final CoreColor? iconBoxColor;

  /// Corner radius of the icon box. `null` → [defaultIconBoxBorderRadius]
  /// (fully rounded — a circle).
  final CoreBorderRadius? iconBoxBorderRadius;

  /// Title text style override, merged on top of the variant's title
  /// role (`titleMedium` normal / `titleSmall` compact). The role sets
  /// the weight; a weight stated here replaces it.
  final CoreTextStyle? titleTextStyle;

  /// Description text style override.
  final CoreTextStyle? descriptionTextStyle;

  // ─── Design-system defaults (single source, Flutter ↔ Web) ──────

  /// Default icon colour — flat `on-surface-variant`, no alpha multiplier:
  /// the glyph is a quiet mark above the title. Overridden per
  /// [CoreEmptyStateTone] by
  /// [defaultsByTone] — a `failure` empty state tints its icon `error`
  /// red on top of this neutral default. Tone changes both what is
  /// announced AND what is shown, per `widget/failure-surfaces.md`'s
  /// "톤이 통보 방식을 정한다" — a field that only changed the
  /// announcement would be half an axis.
  static const CoreColor defaultIconColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Icon box corner radius — fully rounded, so the box is a circle.
  static const CoreBorderRadius defaultIconBoxBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Chrome that depends on why the region is empty.
  ///
  /// Keyed the same way as [defaultsByVariant] because tone is the same
  /// kind of thing: a semantic identifier the caller states, not a
  /// theme axis. The neutral tone states nothing and falls through to
  /// [defaultIconColor] — the failure tone is the one that has
  /// something to say, tinting the icon `error` red on top of it.
  /// `neutral` restates [defaultIconColor] rather than leaving its entry
  /// empty to fall through to it. Both reach the same colour in Dart, but
  /// only the table reaches Figma: the export carries flat `default*`
  /// fields and the icon colour lives inside the `iconStyle` slot, so an
  /// empty `neutral` entry left the canvas with no neutral colour at all
  /// and the tone axis looked like it only moved on `failure`.
  static const Map<CoreEmptyStateTone, CoreEmptyStateStyle> defaultsByTone = {
    CoreEmptyStateTone.neutral: CoreEmptyStateStyle(
      iconStyle: CoreIconStyle(color: defaultIconColor),
      iconBoxColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    ),
    CoreEmptyStateTone.failure: CoreEmptyStateStyle(
      iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.error)),
      iconBoxColor: CoreColor.token(CoreColors.errorContainer),
    ),
    CoreEmptyStateTone.success: CoreEmptyStateStyle(
      iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.success)),
      iconBoxColor: CoreColor.token(CoreColors.successContainer),
    ),
  };

  /// Default title text style — matches the [titleTextStyle] nested
  /// slot. The base each [defaultsByVariant] entry's title role is merged
  /// onto: an entry states only its role (`titleMedium` / `titleSmall`)
  /// and takes its colour from here. Neither states a weight, so the
  /// title is drawn at the role's own (bold) — the same weight a card
  /// header or a footer section title takes from its title role.
  static const CoreTextStyle defaultTitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default description text style — matches the
  /// [descriptionTextStyle] nested slot. The `bodyMedium` role (the
  /// sentence under a title is copy, not a caption), `on-surface-variant`,
  /// flat — no alpha multiplier over the title's hue (the redesign states
  /// an explicit muted token instead of deriving one).
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default icon → title spacer, matching the [iconTitleGapStyle]
  /// nested slot. Also the `normal` entry of [defaultsByVariant];
  /// `compact` tightens it.
  static const CoreGapStyle defaultIconTitleGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
  );

  /// Default title → description spacer, matching the
  /// [titleDescriptionGapStyle] nested slot. Also the `normal` entry
  /// of [defaultsByVariant].
  static const CoreGapStyle defaultTitleDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default description → action spacer, matching the
  /// [descriptionActionGapStyle] nested slot. Also the `normal` entry
  /// of [defaultsByVariant].
  static const CoreGapStyle defaultDescriptionActionGapStyle = CoreGapStyle(
    size: CoreSpace.space24,
  );

  /// Minimum stack height of the `normal` variant — `CoreLayout.layout240`,
  /// the same bound `CoreLayout`'s own doc names as "an empty state's
  /// minimum height (so a panel does not collapse when its results
  /// vanish)". The variants state their own floor in
  /// [CoreEmptyStateVariantStyle.minHeight]: `normal` reads this value,
  /// `compact` has none — it sits inside a panel that already has its own
  /// height and should hug its content.
  static const double defaultMinHeight = CoreLayout.layout240;

  /// Default maximum text-block width — `CoreLayout.layout400`.
  /// Uniform across [CoreEmptyStateVariant].
  static const double defaultMaxTextWidth = CoreLayout.layout400;

  /// Per-variant chrome defaults — single source of truth shared by
  /// Flutter and Web.
  static const Map<CoreEmptyStateVariant, CoreEmptyStateVariantStyle>
  defaultsByVariant = {
    CoreEmptyStateVariant.normal: CoreEmptyStateVariantStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space32),
      minHeight: defaultMinHeight,
      iconSize: CoreSpace.space28,
      iconBoxSize: CoreSpace.space64,
      iconTitleGapStyle: defaultIconTitleGapStyle,
      titleDescriptionGapStyle: defaultTitleDescriptionGapStyle,
      descriptionActionGapStyle: defaultDescriptionActionGapStyle,
      titleTextStyle: CoreTextStyle.token(CoreTextStyles.titleMedium),
    ),
    // #6468: the glyph keeps the ~0.44 icon/box ratio `normal` (28/64)
    // and `large` (32/72) hold, the title sits close to its sentence and
    // the action steps further off, and the sentence reads one role
    // smaller than `normal` — a panel's empty slot, not a page's.
    CoreEmptyStateVariant.compact: CoreEmptyStateVariantStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space24),
      minHeight: CoreSpace.space0,
      iconSize: CoreSpace.space20,
      iconBoxSize: CoreSpace.space48,
      iconTitleGapStyle: CoreGapStyle(size: CoreSpace.space12),
      titleDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space6),
      descriptionActionGapStyle: CoreGapStyle(size: CoreSpace.space16),
      titleTextStyle: CoreTextStyle.token(CoreTextStyles.titleSmall),
      descriptionTextStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
    ),
    CoreEmptyStateVariant.large: CoreEmptyStateVariantStyle(
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space32,
        vertical: CoreSpace.space40,
      ),
      minHeight: defaultMinHeight,
      iconSize: CoreSpace.space32,
      iconBoxSize: CoreSpace.space72,
      iconTitleGapStyle: CoreGapStyle(size: CoreSpace.space20),
      titleDescriptionGapStyle: defaultTitleDescriptionGapStyle,
      descriptionActionGapStyle: defaultDescriptionActionGapStyle,
      titleTextStyle: CoreTextStyle.token(CoreTextStyles.titleLarge),
      descriptionTextStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
    ),
  };

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreEmptyStateStyle merge(CoreEmptyStateStyle? other) {
    if (other == null) return this;
    return CoreEmptyStateStyle(
      padding: other.padding ?? padding,
      minHeight: other.minHeight ?? minHeight,
      maxTextWidth: other.maxTextWidth ?? maxTextWidth,
      iconTitleGapStyle: _mergeGap(iconTitleGapStyle, other.iconTitleGapStyle),
      titleDescriptionGapStyle: _mergeGap(
        titleDescriptionGapStyle,
        other.titleDescriptionGapStyle,
      ),
      descriptionActionGapStyle: _mergeGap(
        descriptionActionGapStyle,
        other.descriptionActionGapStyle,
      ),
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      iconBoxSize: other.iconBoxSize ?? iconBoxSize,
      iconBoxColor: other.iconBoxColor ?? iconBoxColor,
      iconBoxBorderRadius: other.iconBoxBorderRadius ?? iconBoxBorderRadius,
      titleTextStyle: _mergeText(titleTextStyle, other.titleTextStyle),
      descriptionTextStyle: _mergeText(
        descriptionTextStyle,
        other.descriptionTextStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreEmptyStateStyle copyWith({
    CoreEdgeInsets? padding,
    double? minHeight,
    double? maxTextWidth,
    CoreGapStyle? iconTitleGapStyle,
    CoreGapStyle? titleDescriptionGapStyle,
    CoreGapStyle? descriptionActionGapStyle,
    CoreIconStyle? iconStyle,
    double? iconBoxSize,
    CoreColor? iconBoxColor,
    CoreBorderRadius? iconBoxBorderRadius,
    CoreTextStyle? titleTextStyle,
    CoreTextStyle? descriptionTextStyle,
  }) {
    return CoreEmptyStateStyle(
      padding: padding ?? this.padding,
      minHeight: minHeight ?? this.minHeight,
      maxTextWidth: maxTextWidth ?? this.maxTextWidth,
      iconTitleGapStyle: iconTitleGapStyle ?? this.iconTitleGapStyle,
      titleDescriptionGapStyle:
          titleDescriptionGapStyle ?? this.titleDescriptionGapStyle,
      descriptionActionGapStyle:
          descriptionActionGapStyle ?? this.descriptionActionGapStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      iconBoxSize: iconBoxSize ?? this.iconBoxSize,
      iconBoxColor: iconBoxColor ?? this.iconBoxColor,
      iconBoxBorderRadius: iconBoxBorderRadius ?? this.iconBoxBorderRadius,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreEmptyStateStyle &&
          runtimeType == other.runtimeType &&
          padding == other.padding &&
          minHeight == other.minHeight &&
          maxTextWidth == other.maxTextWidth &&
          iconTitleGapStyle == other.iconTitleGapStyle &&
          titleDescriptionGapStyle == other.titleDescriptionGapStyle &&
          descriptionActionGapStyle == other.descriptionActionGapStyle &&
          iconStyle == other.iconStyle &&
          iconBoxSize == other.iconBoxSize &&
          iconBoxColor == other.iconBoxColor &&
          iconBoxBorderRadius == other.iconBoxBorderRadius &&
          titleTextStyle == other.titleTextStyle &&
          descriptionTextStyle == other.descriptionTextStyle;

  @override
  int get hashCode => Object.hash(
    padding,
    minHeight,
    maxTextWidth,
    iconTitleGapStyle,
    titleDescriptionGapStyle,
    descriptionActionGapStyle,
    iconStyle,
    iconBoxSize,
    iconBoxColor,
    iconBoxBorderRadius,
    titleTextStyle,
    descriptionTextStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
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

/// Variant-dependent chrome (padding / minimum height / gaps / icon size /
/// title role).
///
/// Held in [CoreEmptyStateStyle.defaultsByVariant] as the single source
/// of truth shared by Flutter, Web, and the Figma export. `maxTextWidth`
/// is deliberately **not** here — it is one uniform bound
/// (`CoreEmptyStateStyle.defaultMaxTextWidth`), not a per-variant table.
@immutable
class CoreEmptyStateVariantStyle {
  /// Creates a [CoreEmptyStateVariantStyle].
  const CoreEmptyStateVariantStyle({
    required this.padding,
    required this.minHeight,
    required this.iconSize,
    required this.iconBoxSize,
    required this.iconTitleGapStyle,
    required this.titleDescriptionGapStyle,
    required this.descriptionActionGapStyle,
    this.titleTextStyle = CoreEmptyStateStyle.defaultTitleTextStyle,
    this.descriptionTextStyle = CoreEmptyStateStyle.defaultDescriptionTextStyle,
  });

  /// Default padding around the empty-state content.
  final CoreEdgeInsets padding;

  /// Default minimum height of the stack (logical px) — 240 `normal`
  /// (a page-level empty state must not collapse when its results vanish),
  /// `0` `compact` (it hugs its content inside a panel). A per-instance
  /// [CoreEmptyStateStyle.minHeight] replaces it.
  final double minHeight;

  /// Default icon size (logical px) — 28 `normal` / 20 `compact` / 32 `large`. Ambient-
  /// themed onto the caller-supplied icon widget the same way `Button`
  /// themes its leading/trailing slot.
  final double iconSize;

  /// Default icon box edge (logical px) — 64 `normal` / 48 `compact` /
  /// 72 `large`. The box is a circle
  /// ([CoreEmptyStateStyle.defaultIconBoxBorderRadius]).
  final double iconBoxSize;

  /// Default icon → title spacer — merged with any per-instance
  /// [CoreEmptyStateStyle.iconTitleGapStyle] override and forwarded raw
  /// to `Gap`, which self-scales.
  final CoreGapStyle iconTitleGapStyle;

  /// Default title → description spacer — merged with any per-instance
  /// [CoreEmptyStateStyle.titleDescriptionGapStyle] override.
  final CoreGapStyle titleDescriptionGapStyle;

  /// Default description → action spacer — merged with any per-instance
  /// [CoreEmptyStateStyle.descriptionActionGapStyle] override.
  final CoreGapStyle descriptionActionGapStyle;

  /// Default title text style for this density — merged onto
  /// [CoreEmptyStateStyle.defaultTitleTextStyle], so an entry that states
  /// only a role keeps the default colour. `normal` reads `titleMedium`,
  /// `compact` reads `titleSmall`.
  ///
  /// The role lives here rather than in the resolvers because the Figma
  /// export reads this table: a role a resolver picked on its own reached
  /// both platforms and never reached the canvas, which drew `compact`'s
  /// title at the `normal` size. The constructor default keeps a caller
  /// that states no role on the default title style.
  final CoreTextStyle titleTextStyle;

  /// Default description text style for this density — merged onto
  /// [CoreEmptyStateStyle.defaultDescriptionTextStyle]. `large` reads the
  /// `bodyLarge` role, `compact` the `bodySmall` role; `normal` states the
  /// default `bodyMedium`.
  final CoreTextStyle descriptionTextStyle;
}
