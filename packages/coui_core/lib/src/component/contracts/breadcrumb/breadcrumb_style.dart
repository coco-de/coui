/// Per-instance style for `Breadcrumb`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Breadcrumb` should render.
///
/// Carries chrome flat fields plus nested item-text / separator-icon
/// slot styles. Platform-neutral (Epic #1415 option D) — colour fields
/// use [CoreColor]; nested [CoreTextStyle] / [CoreIconStyle] /
/// [CoreGapStyle] remain the shared platform-neutral token types.
///
/// All design-system defaults live here as `static const` fields so the
/// Flutter and Web resolvers share a single source of truth.
@immutable
class CoreBreadcrumbStyle implements CoreStyle<CoreBreadcrumbStyle> {
  /// Creates a [CoreBreadcrumbStyle].
  const CoreBreadcrumbStyle({
    this.itemSeparatorGapStyle,
    this.itemColor,
    this.currentItemColor,
    this.itemHoverColor,
    this.disabledColor,
    this.itemTextStyle,
    this.currentItemTextStyle,
    this.itemPadding,
    this.separatorIconStyle,
    this.hoverDuration,
    this.clickableStyle,
  });

  // ─── Design-system defaults (Epic #1415 option D) ─────────────────

  /// Default size of the chevron separator icon (logical px).
  static const double defaultSeparatorIconSize = CoreIconSize.size16;

  /// Default colour of inactive (link) breadcrumb items.
  static const CoreColor defaultItemColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default colour of the current (last) breadcrumb item.
  static const CoreColor defaultCurrentItemColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default colour of the chevron separator icon — the decorative-glyph
  /// step (`onSurfaceSubtle`), one step quieter than the link text it sits
  /// between.
  static const CoreColor defaultSeparatorColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default colour of every item label and of the chevron separator while
  /// the breadcrumb is disabled (`enabled: false`). One colour for both: a
  /// disabled trail is a single muted unit, so the link, current and
  /// separator steps collapse onto it.
  static const CoreColor defaultDisabledColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default nested [CoreIconStyle] for the chevron separator — carries
  /// the design-system size + colour as a single slot so resolvers can
  /// merge the per-instance [separatorIconStyle] override in one step
  /// and forward the result straight to `Icon(iconStyle: …)`.
  static const CoreIconStyle defaultSeparatorIconStyle = CoreIconStyle(
    size: defaultSeparatorIconSize,
    color: defaultSeparatorColor,
  );

  /// Default nested [CoreGapStyle] slot for the gap on either side of
  /// the chevron separator — carries the design-system size as a
  /// single slot so resolvers can merge the per-instance
  /// [itemSeparatorGapStyle] override in one step and forward straight
  /// to `Gap(gapStyle: …)`. The receiving `Gap` runs its own
  /// resolve / scaling step so this slot stays in pre-scaling units.
  static const CoreGapStyle defaultItemSeparatorGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default inset around each item label — 2 above and below, 4 to either
  /// side. The focus ring wraps the item *with* this inset, so the inset is
  /// also what keeps the ring off the glyphs.
  static const CoreEdgeInsets defaultItemPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space2,
    horizontal: CoreSpace.space4,
  );

  /// Default hover colour applied to an interactive link item.
  static const CoreColor defaultItemHoverColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default text style of the link items — the `bodyMedium` role (14 /
  /// Regular / 150% line). Token-backed so the Flutter resolver can
  /// materialise the slot through `.toValue(theme:)` and the Web resolver
  /// through `emitTypography` without losing the role. Colour is
  /// intentionally unset; each item's foreground (link / hover / disabled) is
  /// layered downstream.
  static const CoreTextStyle defaultItemTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// Default text style of the current (last) item — the `labelLarge` role
  /// (14 / Medium / 140% line), the one step heavier than the links so the
  /// current location reads as the end of the trail. Colour is unset for the
  /// same reason as [defaultItemTextStyle].
  static const CoreTextStyle defaultCurrentItemTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  /// Default colour-transition duration for link hover.
  static const Duration defaultHoverDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default nested [CoreClickableStyle] slot for the composed per-item
  /// `Clickable` — a partial that states two things and leaves everything
  /// else on the Clickable's own defaults (cursor / focus ring colour and
  /// width / keyboard activation):
  ///
  /// * `pressedScale: 1.0` disables the press-shrink. Breadcrumb items are
  ///   inline text links, so the Clickable's standard scale-down feedback
  ///   reads as an awkward wobble on plain text; a caller can re-enable it
  ///   via `clickableStyle: CoreClickableStyle(pressedScale: …)`.
  /// * `borderRadius: radius6` is the item's corner — the corner the focus
  ///   ring is drawn around (the ring is that corner plus the ring's own
  ///   4px reach, so 10). The item carries no fill, so the focus ring is the
  ///   only place the corner is visible.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    pressedScale: 1,
  );

  // ─── Fields ───────────────────────────────────────────────────────

  /// Style of the `Gap` between an item, its separator and the next item.
  /// `null` defers to [defaultItemSeparatorGapStyle].
  final CoreGapStyle? itemSeparatorGapStyle;

  /// Override colour applied to inactive (link) items. `null` defers to
  /// [itemTextStyle]'s colour, then [defaultItemColor].
  final CoreColor? itemColor;

  /// Override colour applied to the current (last) item.
  final CoreColor? currentItemColor;

  /// Override hover colour applied to an interactive link item. `null`
  /// defers to [defaultItemHoverColor].
  final CoreColor? itemHoverColor;

  /// Override colour of every item label and of the separator while the
  /// breadcrumb is disabled. `null` defers to [defaultDisabledColor].
  final CoreColor? disabledColor;

  /// Item text style — applies to every breadcrumb item (link and current).
  /// `null` defers to [defaultItemTextStyle] for the links.
  final CoreTextStyle? itemTextStyle;

  /// Text style of the current (last) item, layered on top of
  /// [itemTextStyle]. `null` defers to [defaultCurrentItemTextStyle].
  final CoreTextStyle? currentItemTextStyle;

  /// Inset around each item label (inside the focus ring). `null` defers to
  /// [defaultItemPadding].
  final CoreEdgeInsets? itemPadding;

  /// Separator icon style (size / colour of the chevron glyph).
  final CoreIconStyle? separatorIconStyle;

  /// Override colour-transition duration for link hover. `null` defers
  /// to [defaultHoverDuration].
  final Duration? hoverDuration;

  /// Style of the `Clickable` that wraps each link item (interactive items
  /// only). Merged on top of [defaultClickableStyle] and passed to
  /// `Clickable(clickableStyle:)` as is.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreBreadcrumbStyle merge(CoreBreadcrumbStyle? other) {
    if (other == null) return this;
    return CoreBreadcrumbStyle(
      itemSeparatorGapStyle: _mergeGap(
        itemSeparatorGapStyle,
        other.itemSeparatorGapStyle,
      ),
      itemColor: other.itemColor ?? itemColor,
      currentItemColor: other.currentItemColor ?? currentItemColor,
      itemHoverColor: other.itemHoverColor ?? itemHoverColor,
      disabledColor: other.disabledColor ?? disabledColor,
      itemTextStyle: _mergeText(itemTextStyle, other.itemTextStyle),
      currentItemTextStyle: _mergeText(
        currentItemTextStyle,
        other.currentItemTextStyle,
      ),
      itemPadding: other.itemPadding ?? itemPadding,
      separatorIconStyle: _mergeIcon(
        separatorIconStyle,
        other.separatorIconStyle,
      ),
      hoverDuration: other.hoverDuration ?? hoverDuration,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy with the supplied non-null fields overridden.
  CoreBreadcrumbStyle copyWith({
    CoreGapStyle? itemSeparatorGapStyle,
    CoreColor? itemColor,
    CoreColor? currentItemColor,
    CoreColor? itemHoverColor,
    CoreColor? disabledColor,
    CoreTextStyle? itemTextStyle,
    CoreTextStyle? currentItemTextStyle,
    CoreEdgeInsets? itemPadding,
    CoreIconStyle? separatorIconStyle,
    Duration? hoverDuration,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreBreadcrumbStyle(
      itemSeparatorGapStyle:
          itemSeparatorGapStyle ?? this.itemSeparatorGapStyle,
      itemColor: itemColor ?? this.itemColor,
      currentItemColor: currentItemColor ?? this.currentItemColor,
      itemHoverColor: itemHoverColor ?? this.itemHoverColor,
      disabledColor: disabledColor ?? this.disabledColor,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      currentItemTextStyle: currentItemTextStyle ?? this.currentItemTextStyle,
      itemPadding: itemPadding ?? this.itemPadding,
      separatorIconStyle: separatorIconStyle ?? this.separatorIconStyle,
      hoverDuration: hoverDuration ?? this.hoverDuration,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBreadcrumbStyle &&
          runtimeType == other.runtimeType &&
          itemSeparatorGapStyle == other.itemSeparatorGapStyle &&
          itemColor == other.itemColor &&
          currentItemColor == other.currentItemColor &&
          itemHoverColor == other.itemHoverColor &&
          disabledColor == other.disabledColor &&
          itemTextStyle == other.itemTextStyle &&
          currentItemTextStyle == other.currentItemTextStyle &&
          itemPadding == other.itemPadding &&
          separatorIconStyle == other.separatorIconStyle &&
          hoverDuration == other.hoverDuration &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hash(
    itemSeparatorGapStyle,
    itemColor,
    currentItemColor,
    itemHoverColor,
    disabledColor,
    itemTextStyle,
    currentItemTextStyle,
    itemPadding,
    separatorIconStyle,
    hoverDuration,
    clickableStyle,
  );

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreIconStyle? _mergeIcon(CoreIconStyle? base, CoreIconStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
