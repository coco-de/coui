/// Per-instance style for `Sortable`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Sortable` should render.
///
/// `CoreSortableStyle` carries chrome flat fields (item bg / hover
/// / border radius + handle / remove-button colours) plus the
/// spacing between items.
///
/// ```text
/// design system default
///   → CoreSortableTheme (legacy flat fields)
///   → CoreSortableTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.sortableStyle                          // 인스턴스별
/// ```
@immutable
class CoreSortableStyle implements CoreStyle<CoreSortableStyle> {
  /// Creates a [CoreSortableStyle].
  const CoreSortableStyle({
    this.itemBackgroundColor,
    this.itemHoverColor,
    this.itemBorderColor,
    this.disabledItemBackgroundColor,
    this.disabledItemBorderColor,
    this.handleColor,
    this.disabledHandleColor,
    this.disabledForegroundColor,
    this.removeButtonColor,
    this.itemBorderRadius,
    this.itemBorderWidth,
    this.itemMinHeight,
    this.removeButtonBorderRadius,
    this.itemSpacing,
    this.itemPadding,
    this.handlePadding,
    this.removeButtonSize,
    this.animationDuration,
    this.proxyScale,
    this.proxyElevation,
    this.itemTextStyle,
    this.iconStyle,
    this.removeButtonStyle,
    this.handleStyle,
  });

  // ─── Design-system defaults (Phase 6f option D) ──

  /// Default inner padding of each sortable item — 12 before the handle,
  /// 8 after the trailing control, none above or below (the row's
  /// [defaultItemMinHeight] and the content's own centring set the
  /// height). Horizontal-asymmetric, so it is stated as a reading-
  /// direction inset.
  static const CoreEdgeInsets defaultItemPadding = CoreEdgeInsets.directional(
    start: CoreSpace.space12,
    end: CoreSpace.space8,
  );

  /// Default minimum height of each sortable item — the `lg` control row
  /// (48), the same row a text field of the form beside it stands on. A
  /// floor, not a fixed height: taller content grows the row.
  static const double defaultItemMinHeight = CoreControlSize.heightLg;

  /// Default spacing between sortable items (logical px).
  static const double defaultItemSpacing = CoreSpace.space8;

  /// Default size of the drag handle / remove glyph icon (logical px).
  static const double defaultIconSize = CoreIconSize.size16;

  /// Default icon slot style shared by the drag-handle and the remove
  /// glyphs — carries [defaultIconSize] so the resolver can absorb the
  /// design-system default and forward a non-null [CoreIconStyle] to
  /// both icon use sites.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: defaultIconSize,
  );

  /// Default corner radius of each sortable item (the `lg` control row's
  /// 48 × 0.25).
  static const CoreBorderRadius defaultItemBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius12,
  );

  /// Default item border colour — the quiet line a resting text field
  /// draws.
  static const CoreColor defaultItemBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default item border width (logical px).
  static const double defaultItemBorderWidth = CoreStrokeWidth.stroke1;

  /// Default item background colour while the list is disabled — the
  /// dedicated disabled container token, not a faded enabled fill.
  static const CoreColor defaultDisabledItemBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default item border colour while the list is disabled.
  static const CoreColor defaultDisabledItemBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default colour of the item text and the remove button's glyph while
  /// the list is disabled — `disabledContent`, the same token the drag
  /// handle takes ([defaultDisabledHandleColor]). A disabled list says so in
  /// its own token, not by dimming the enabled pair.
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default drag-handle glyph colour while the list is disabled.
  static const CoreColor defaultDisabledHandleColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default item background colour token (`surface`). Single source for
  /// both platforms — Flutter `scheme.resolve(...)`, Web `bg-${...}`.
  static const CoreColor defaultItemBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default item hover background colour token — the opaque
  /// `surfaceContainerHigh` tone, a neutral step off the item's `surface`
  /// fill. Opaque like the other option-list hovers (Pagination,
  /// Autocomplete, ItemPicker, PhoneInput), so a hovered item reads the
  /// same on whatever the list sits on.
  static const CoreColor defaultItemHoverColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default drag-handle glyph colour (`onSurfaceSubtle`) — the value the
  /// resolvers already fell back to via
  /// [defaultHandleStyle]`.foregroundColor`, named here because
  /// [handleColor] is its own override slot and needs its own default
  /// (1:1:1:1:1:1). Restated rather than read off [defaultHandleStyle]: a
  /// `const` initializer cannot access another const's property
  /// (`const_eval_property_access`), so the two must be edited together.
  static const CoreColor defaultHandleColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default drag-handle padding — none, so the handle is exactly the
  /// glyph's width. Same value as [defaultHandleStyle]`.padding`, named for
  /// [handlePadding] (see [defaultHandleColor] for why it is restated).
  static const CoreEdgeInsets defaultHandlePadding = CoreEdgeInsets.zero;

  /// Default remove-glyph colour (`onSurfaceVariant`) — one step stronger
  /// than the drag handle (`onSurfaceSubtle`), since the remove control is
  /// an action the user aims at rather than a grip. Same value as
  /// [defaultRemoveButtonStyle]`.foregroundColor`, named for
  /// [removeButtonColor] (see [defaultHandleColor] for why it is
  /// restated).
  @Deprecated(
    'Nothing reads it (since 0.177) — the fallback is '
    'defaultRemoveButtonStyle.foregroundColor.',
  )
  static const CoreColor defaultRemoveButtonColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default remove-button corner radius — the `sm` row's 32 × 0.25,
  /// the corner a `Button(size: .sm)` draws. Same value as
  /// [defaultRemoveButtonStyle]`.borderRadius`, named for
  /// [removeButtonBorderRadius].
  @Deprecated(
    'Nothing reads it (since 0.177) — the fallback is '
    'defaultRemoveButtonStyle.borderRadius.',
  )
  static const CoreBorderRadius defaultRemoveButtonBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius8);

  /// Default remove-button square extent (logical px) — the `sm` control
  /// row. Same value as [defaultRemoveButtonStyle]`.width`, named for
  /// [removeButtonSize].
  @Deprecated(
    'Nothing reads it (since 0.177) — the fallback is '
    'defaultRemoveButtonStyle.width.',
  )
  static const double defaultRemoveButtonSize = CoreControlSize.heightSm;

  /// Default drag-handle button-style chrome — `onSurfaceSubtle`
  /// foreground + no padding so the handle hugs the icon. Single source
  /// for the handle chrome on both platforms; the resolver extracts the
  /// `foregroundColor` / `padding` scalars because the handle renders as
  /// a `Icon` (not a `Button`). Mirrors carousel's
  /// `defaultPrevNextButtonStyle`.
  static const CoreButtonStyle defaultHandleStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurfaceSubtle),
    padding: CoreEdgeInsets.zero,
  );

  /// Default remove-button button-style chrome — raw-forwarded to
  /// `Button(variant: .plain, size: .sm, shape: .square, buttonStyle: …)`
  /// on both platforms. The `plain` variant owns the quiet idle content
  /// and the hover, `square` the equal sides; this slot pins the 32
  /// logical-px square, the zero padding (the square centres the glyph),
  /// the `sm` corner, the `onSurfaceVariant` foreground and the 16
  /// logical-px close glyph.
  static const CoreButtonStyle defaultRemoveButtonStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    height: CoreControlSize.heightSm,
    width: CoreControlSize.heightSm,
    padding: CoreEdgeInsets.zero,
    leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
  );

  /// Default sortable-item label style — the `bodyLarge` typography role
  /// fields plus the `onSurface` foreground colour, folded into the single
  /// nested slot that matches the [itemTextStyle] field
  /// (sb-text-style-repackage). The resolver re-resolves the colour through
  /// the active scheme (dark-mode aware) and overlays the per-instance
  /// `itemTextStyle` slot. `static final` since `CoreTypography.coui`
  /// record-field access can't be const-eval'd; `CoreTypography.coui` is
  /// itself const so there is no runtime cost.
  static final CoreTextStyle defaultItemTextStyle = CoreTypography
      .coui
      .bodyLarge
      .copyWith(color: const CoreColor.token(CoreColors.onSurface));

  /// Default duration of the reorder shift animation. Both platforms
  /// convert this to their native unit — Flutter passes the `Duration`
  /// straight through, Web emits a CSS millisecond value.
  /// 250ms matches the `ReorderableListView` engine's internal (and
  /// non-configurable) gap-shift / drop-settle duration, so the Web
  /// reorder motion paces identically to the Flutter one.
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: CoreDuration.ms250,
  );

  /// Default Material elevation of the floating proxy while dragging
  /// (logical px). Flutter passes this straight to `Material.elevation`;
  /// Web maps it to a Tailwind shadow utility class.
  static const double defaultProxyElevation = 6;

  /// Default scale multiplier of the floating proxy while dragging
  /// (1.0 = no change). A subtle lift to communicate "picked up".
  static const double defaultProxyScale = 1.02;

  // ── Chrome (flat) ────────────────────────────

  /// Item background colour.
  final CoreColor? itemBackgroundColor;

  /// Item hover background colour.
  final CoreColor? itemHoverColor;

  /// Item border colour.
  final CoreColor? itemBorderColor;

  /// Item background colour while the list is disabled.
  final CoreColor? disabledItemBackgroundColor;

  /// Item border colour while the list is disabled.
  final CoreColor? disabledItemBorderColor;

  /// Drag handle colour.
  final CoreColor? handleColor;

  /// Drag handle colour while the list is disabled.
  final CoreColor? disabledHandleColor;

  /// Item text and remove-button glyph colour while the list is disabled.
  /// `null` → [defaultDisabledForegroundColor].
  final CoreColor? disabledForegroundColor;

  /// Remove button colour.
  final CoreColor? removeButtonColor;

  /// Item border radius.
  final CoreBorderRadius? itemBorderRadius;

  /// Item border width (logical px).
  final double? itemBorderWidth;

  /// Minimum item height (logical px).
  final double? itemMinHeight;

  /// Remove button corner radius.
  final CoreBorderRadius? removeButtonBorderRadius;

  /// Spacing between items (logical px).
  final double? itemSpacing;

  /// Inner padding of each sortable item.
  final CoreEdgeInsets? itemPadding;

  /// Padding around the drag handle.
  final CoreEdgeInsets? handlePadding;

  /// Size of the remove button hit area (logical px, square).
  final double? removeButtonSize;

  /// How long the reorder shift and the colour change take.
  ///
  /// Both platforms convert this to their native unit — Flutter passes the
  /// `Duration` straight through, Web writes a CSS millisecond value.
  final Duration? animationDuration;

  /// Drag-proxy peak scale multiplier (`1.0` = no change). `null` →
  /// [defaultProxyScale]. Flutter feeds `Transform.scale`; Web (no proxy
  /// yet) leaves it unconsumed.
  final double? proxyScale;

  /// Drag-proxy peak Material elevation. `null` → [defaultProxyElevation].
  /// Flutter feeds `Material.elevation`; Web (no proxy yet) unconsumed.
  final double? proxyElevation;

  // ── Slot Styles (nested) ─────────────────────

  /// Text style of each item's label. Laid over [defaultItemTextStyle]
  /// (`bodyLarge` role + `onSurface` colour); the text colour is set via
  /// [CoreTextStyle.color] in this style, so both platforms take the label
  /// typography and colour from this one field.
  ///
  /// (sb-text-style-repackage)
  final CoreTextStyle? itemTextStyle;

  /// Shared icon slot style (size + colour) for both the drag-handle
  /// and the remove glyphs.
  final CoreIconStyle? iconStyle;

  /// Remove (dismiss) button style override.
  ///
  /// Mirrors the [removeButtonSize] / [removeButtonBorderRadius] /
  /// [removeButtonColor] flat fields as a nested `CoreButtonStyle` slot.
  /// When both flat and nested are set the resolver prefers
  /// `removeButtonStyle.X`, then falls back to the flat field, then to
  /// the design-system default.
  final CoreButtonStyle? removeButtonStyle;

  /// Drag handle style override.
  ///
  /// Mirrors the [handlePadding] / [handleColor] flat fields as a nested
  /// `CoreButtonStyle` slot. When both flat and nested are set the
  /// resolver prefers `handleStyle.X`, then falls back to the flat
  /// field, then to the design-system default.
  final CoreButtonStyle? handleStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreSortableStyle merge(CoreSortableStyle? other) {
    if (other == null) return this;
    return CoreSortableStyle(
      itemBackgroundColor: other.itemBackgroundColor ?? itemBackgroundColor,
      itemHoverColor: other.itemHoverColor ?? itemHoverColor,
      itemBorderColor: other.itemBorderColor ?? itemBorderColor,
      disabledItemBackgroundColor:
          other.disabledItemBackgroundColor ?? disabledItemBackgroundColor,
      disabledItemBorderColor:
          other.disabledItemBorderColor ?? disabledItemBorderColor,
      handleColor: other.handleColor ?? handleColor,
      disabledHandleColor: other.disabledHandleColor ?? disabledHandleColor,
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
      removeButtonColor: other.removeButtonColor ?? removeButtonColor,
      itemBorderRadius: other.itemBorderRadius ?? itemBorderRadius,
      itemBorderWidth: other.itemBorderWidth ?? itemBorderWidth,
      itemMinHeight: other.itemMinHeight ?? itemMinHeight,
      removeButtonBorderRadius:
          other.removeButtonBorderRadius ?? removeButtonBorderRadius,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      itemPadding: other.itemPadding ?? itemPadding,
      handlePadding: other.handlePadding ?? handlePadding,
      removeButtonSize: other.removeButtonSize ?? removeButtonSize,
      animationDuration: other.animationDuration ?? animationDuration,
      proxyScale: other.proxyScale ?? proxyScale,
      proxyElevation: other.proxyElevation ?? proxyElevation,
      itemTextStyle: _mergeText(itemTextStyle, other.itemTextStyle),
      iconStyle: _mergeIcon(iconStyle, other.iconStyle),
      removeButtonStyle: _mergeButton(
        removeButtonStyle,
        other.removeButtonStyle,
      ),
      handleStyle: _mergeButton(handleStyle, other.handleStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSortableStyle copyWith({
    CoreColor? itemBackgroundColor,
    CoreColor? itemHoverColor,
    CoreColor? itemBorderColor,
    CoreColor? disabledItemBackgroundColor,
    CoreColor? disabledItemBorderColor,
    CoreColor? handleColor,
    CoreColor? disabledHandleColor,
    CoreColor? disabledForegroundColor,
    CoreColor? removeButtonColor,
    CoreBorderRadius? itemBorderRadius,
    double? itemBorderWidth,
    double? itemMinHeight,
    CoreBorderRadius? removeButtonBorderRadius,
    double? itemSpacing,
    CoreEdgeInsets? itemPadding,
    CoreEdgeInsets? handlePadding,
    double? removeButtonSize,
    Duration? animationDuration,
    double? proxyScale,
    double? proxyElevation,
    CoreTextStyle? itemTextStyle,
    CoreIconStyle? iconStyle,
    CoreButtonStyle? removeButtonStyle,
    CoreButtonStyle? handleStyle,
  }) {
    return CoreSortableStyle(
      itemBackgroundColor: itemBackgroundColor ?? this.itemBackgroundColor,
      itemHoverColor: itemHoverColor ?? this.itemHoverColor,
      itemBorderColor: itemBorderColor ?? this.itemBorderColor,
      disabledItemBackgroundColor:
          disabledItemBackgroundColor ?? this.disabledItemBackgroundColor,
      disabledItemBorderColor:
          disabledItemBorderColor ?? this.disabledItemBorderColor,
      handleColor: handleColor ?? this.handleColor,
      disabledHandleColor: disabledHandleColor ?? this.disabledHandleColor,
      disabledForegroundColor:
          disabledForegroundColor ?? this.disabledForegroundColor,
      removeButtonColor: removeButtonColor ?? this.removeButtonColor,
      itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
      itemBorderWidth: itemBorderWidth ?? this.itemBorderWidth,
      itemMinHeight: itemMinHeight ?? this.itemMinHeight,
      removeButtonBorderRadius:
          removeButtonBorderRadius ?? this.removeButtonBorderRadius,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      itemPadding: itemPadding ?? this.itemPadding,
      handlePadding: handlePadding ?? this.handlePadding,
      removeButtonSize: removeButtonSize ?? this.removeButtonSize,
      animationDuration: animationDuration ?? this.animationDuration,
      proxyScale: proxyScale ?? this.proxyScale,
      proxyElevation: proxyElevation ?? this.proxyElevation,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      removeButtonStyle: removeButtonStyle ?? this.removeButtonStyle,
      handleStyle: handleStyle ?? this.handleStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSortableStyle &&
          runtimeType == other.runtimeType &&
          itemBackgroundColor == other.itemBackgroundColor &&
          itemHoverColor == other.itemHoverColor &&
          itemBorderColor == other.itemBorderColor &&
          disabledItemBackgroundColor == other.disabledItemBackgroundColor &&
          disabledItemBorderColor == other.disabledItemBorderColor &&
          handleColor == other.handleColor &&
          disabledHandleColor == other.disabledHandleColor &&
          disabledForegroundColor == other.disabledForegroundColor &&
          removeButtonColor == other.removeButtonColor &&
          itemBorderRadius == other.itemBorderRadius &&
          itemBorderWidth == other.itemBorderWidth &&
          itemMinHeight == other.itemMinHeight &&
          removeButtonBorderRadius == other.removeButtonBorderRadius &&
          itemSpacing == other.itemSpacing &&
          itemPadding == other.itemPadding &&
          handlePadding == other.handlePadding &&
          removeButtonSize == other.removeButtonSize &&
          animationDuration == other.animationDuration &&
          proxyScale == other.proxyScale &&
          proxyElevation == other.proxyElevation &&
          itemTextStyle == other.itemTextStyle &&
          iconStyle == other.iconStyle &&
          removeButtonStyle == other.removeButtonStyle &&
          handleStyle == other.handleStyle;

  @override
  int get hashCode => Object.hash(
    itemBackgroundColor,
    itemHoverColor,
    itemBorderColor,
    disabledItemBackgroundColor,
    disabledItemBorderColor,
    handleColor,
    disabledHandleColor,
    disabledForegroundColor,
    removeButtonColor,
    itemBorderRadius,
    itemBorderWidth,
    Object.hash(
      itemMinHeight,
      removeButtonBorderRadius,
      itemSpacing,
      itemPadding,
      handlePadding,
      removeButtonSize,
      animationDuration,
      proxyScale,
      proxyElevation,
      itemTextStyle,
      iconStyle,
      removeButtonStyle,
      handleStyle,
    ),
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

  static CoreButtonStyle? _mergeButton(
    CoreButtonStyle? base,
    CoreButtonStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
