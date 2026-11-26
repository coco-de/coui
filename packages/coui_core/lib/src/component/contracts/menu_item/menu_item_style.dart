/// Chrome contract for `MenuItem`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_size.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_tone.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Every chrome value a `MenuItem` row draws, on both platforms.
///
/// Three default tables, one per axis, plus the axis-free defaults:
///
/// - [defaultsBySize] — the size ladder: minimum height (32 / 36 / 48),
///   insets, gap, leading icon, label and secondary text roles. The `md`
///   row is 36 — a height that is not a rung of the control ladder
///   (`CoreControlSize.steps`), so a density does not move it.
/// - [defaultsByTone] — foreground only: `neutral` reads in `onSurface`,
///   `critical` in `error`.
/// - the rest — the mark / chevron glyphs (16, an optical band that does
///   not scale with the row), the corner, the fills, the state-layer ramp,
///   the composed `Clickable` chrome.
///
/// Fills and the wash are the ones the row's `Button(variant: .menu)`
/// predecessor carried, restated here so the row can stop composing a
/// button: transparent at rest, `onSurface` washed over it on hover /
/// focus / press through [stateLayer], `primary` / `onPrimary` when
/// selected.
@immutable
class CoreMenuItemStyle implements CoreStyle<CoreMenuItemStyle> {
  /// Creates a style. Every field is nullable — a partial override.
  const CoreMenuItemStyle({
    this.minHeight,
    this.padding,
    this.contentGapStyle,
    this.labelDescriptionGapStyle,
    this.borderRadius,
    this.leadingIconStyle,
    this.markIconStyle,
    this.chevronIconStyle,
    this.labelStyle,
    this.descriptionStyle,
    this.shortcutTextStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.selectedBackgroundColor,
    this.selectedForegroundColor,
    this.disabledForegroundColor,
    this.hoverBackgroundColor,
    this.pressedBackgroundColor,
    this.activeForegroundColor,
    this.stateLayer,
    this.clickableStyle,
  });

  // ─── Axis-free defaults ───────────────────────────────────────────

  /// Default for [labelDescriptionGapStyle] — the gap between the label
  /// and its description line.
  static const CoreGapStyle defaultLabelDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
    crossAxisExtent: 0,
  );

  /// A size-independent row corner (8), retired: a standalone row takes
  /// its size row's [borderRadius]
  /// (`defaultsBySize[size].borderRadius`: 8 · 8 · 12), and a
  /// row a panel hosts takes the corner the host states in its nested
  /// row slot (`CoreMenuStyle.defaultItemStyle`,
  /// `CoreSelectStyle.defaultOptionStyle`).
  @Deprecated(
    'Per-size now: read defaultsBySize[size].borderRadius instead (since '
    '0.156) — a standalone row corner is stated on the size row, and a row '
    'inside a panel takes the corner of the host row slot.',
  )
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default for [markIconStyle] — the toggle glyph. 16 on every size:
  /// an optical band; larger and the mark outweighs the leading icon.
  static const CoreIconStyle defaultMarkIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default for [chevronIconStyle] — the submenu chevron, 16 for the
  /// same reason as the mark.
  static const CoreIconStyle defaultChevronIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
  );

  /// Default for [backgroundColor] — a row paints nothing at rest; the
  /// panel behind it is the surface.
  static const CoreColor defaultBackgroundColor = CoreColor.transparent;

  /// Default for [selectedBackgroundColor].
  static const CoreColor defaultSelectedBackgroundColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default for [selectedForegroundColor].
  static const CoreColor defaultSelectedForegroundColor = CoreColor.token(
    CoreColors.onPrimary,
  );

  /// Default for [disabledForegroundColor] — the `disabledContent` slot, the
  /// floor every disabled label in the kit drops to. The label, the
  /// description, the shortcut hint and the glyphs all read this one field
  /// while the row is disabled.
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default for [stateLayer] — hover 8 / focus 8 / pressed 12. Focus
  /// matches hover because the ring is the focus indicator and the wash
  /// only a secondary cue; the pressed wash is the light-surface weight
  /// ([CoreOpacity.pressed]) rather than the heavier `standard` ramp, so a
  /// row held down deepens the hover without hiding the label under it.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer(
    hover: CoreOpacity.opacity8,
    focus: CoreOpacity.opacity8,
    pressed: CoreOpacity.pressed,
  );

  /// Default for [clickableStyle] — the composed `Clickable`'s own
  /// defaults (focus ring, press feedback).
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle();

  // ─── Size-keyed defaults ──────────────────────────────────────────

  /// The size ladder: 32 · 36 · 48.
  ///
  /// `borderRadius` is 8 · 8 · 12 for a row that stands on its own: the
  /// row height × 0.25 on a rung of the control ladder (32 → 8, 48 → 12),
  /// and the rung below 36 × 0.25 = 9 for the `md` row, since 9 is not a
  /// rung of the corner scale. A row a panel hosts does not read it: the
  /// panel's nested row slot states the corner
  /// (`CoreMenuStyle.defaultItemStyle`,
  /// `CoreSelectStyle.defaultOptionStyle`), so a lg row stays inside the
  /// panel's corner rather than rounding past it.
  static const Map<CoreMenuItemSize, CoreMenuItemStyle> defaultsBySize = {
    CoreMenuItemSize.sm: CoreMenuItemStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      minHeight: CoreControlSize.heightSm,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space8,
        vertical: CoreSpace.space6,
      ),
      contentGapStyle: CoreGapStyle(size: CoreSpace.space8, crossAxisExtent: 0),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
      descriptionStyle: CoreTextStyle.token(
        CoreTextStyles.bodyXs,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
      shortcutTextStyle: CoreTextStyle.token(
        CoreTextStyles.bodyXs,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
    CoreMenuItemSize.md: CoreMenuItemStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      minHeight: CoreSize.size36,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space10,
        vertical: CoreSpace.space8,
      ),
      contentGapStyle: CoreGapStyle(
        size: CoreSpace.space10,
        crossAxisExtent: 0,
      ),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size18),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
      descriptionStyle: CoreTextStyle.token(
        CoreTextStyles.bodySmall,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
      shortcutTextStyle: CoreTextStyle.token(
        CoreTextStyles.bodyXs,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
    CoreMenuItemSize.lg: CoreMenuItemStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      minHeight: CoreControlSize.heightLg,
      padding: CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space16,
        vertical: CoreSpace.space12,
      ),
      contentGapStyle: CoreGapStyle(
        size: CoreSpace.space12,
        crossAxisExtent: 0,
      ),
      leadingIconStyle: CoreIconStyle(size: CoreIconSize.size24),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelXl),
      descriptionStyle: CoreTextStyle.token(
        CoreTextStyles.bodyMedium,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
      shortcutTextStyle: CoreTextStyle.token(
        CoreTextStyles.bodySmall,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      ),
    ),
  };

  // ─── Tone-keyed defaults ──────────────────────────────────────────

  /// The resting foreground per tone; the selected fill is shared, so the
  /// two tones stay one ramp (§6-3 (c)).
  ///
  /// `neutral` is washed on hover / focus / press — its foreground over the
  /// resting fill at [defaultStateLayer]'s weight. `critical` is not: a wash
  /// of the error ink would be the error colour itself over a transparent
  /// fill, so its active state is a fill instead — `errorContainer` on hover
  /// and focus and on press. The inks do not change with it: the label stays
  /// `error` and the description and the shortcut keep their muted colour
  /// (designer decision 2026-11-05, #6012). `error` measures 4.55:1 on the
  /// light `errorContainer`, the lowest of the four modes.
  static const Map<CoreMenuItemTone, CoreMenuItemStyle> defaultsByTone = {
    CoreMenuItemTone.neutral: CoreMenuItemStyle(
      foregroundColor: CoreColor.token(CoreColors.onSurface),
    ),
    CoreMenuItemTone.critical: CoreMenuItemStyle(
      foregroundColor: CoreColor.token(CoreColors.error),
      hoverBackgroundColor: CoreColor.token(CoreColors.errorContainer),
      pressedBackgroundColor: CoreColor.token(CoreColors.errorContainer),
    ),
  };

  // ─── Fields ───────────────────────────────────────────────────────

  /// Minimum row height (logical px). A description line grows past it.
  /// `null` → the size ladder.
  final double? minHeight;

  /// Content insets. `null` → the size ladder.
  final CoreEdgeInsets? padding;

  /// Gap between the mark, leading, text, shortcut / chevron and trailing
  /// parts. `null` → the size ladder.
  final CoreGapStyle? contentGapStyle;

  /// Gap between the label and its description. `null` →
  /// [defaultLabelDescriptionGapStyle].
  final CoreGapStyle? labelDescriptionGapStyle;

  /// Corner radius. `null` → the size row's corner
  /// (`defaultsBySize[size].borderRadius`, the row height × 0.25). A panel
  /// that holds the rows sets their corner here, through its Style for
  /// the rows.
  final CoreBorderRadius? borderRadius;

  /// Leading icon style (size; colour follows the foreground). `null` →
  /// the size ladder.
  final CoreIconStyle? leadingIconStyle;

  /// Style of the mark (the toggle glyph). `null` →
  /// [defaultMarkIconStyle].
  final CoreIconStyle? markIconStyle;

  /// Style of the submenu chevron. `null` → [defaultChevronIconStyle].
  final CoreIconStyle? chevronIconStyle;

  /// Label typography (role; colour follows the foreground). `null` →
  /// the size ladder.
  final CoreTextStyle? labelStyle;

  /// Description typography and colour. `null` → the size ladder.
  final CoreTextStyle? descriptionStyle;

  /// Shortcut hint typography and colour. `null` → the size ladder.
  final CoreTextStyle? shortcutTextStyle;

  /// Resting fill. `null` → [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Resting label / glyph colour. `null` → the tone table.
  final CoreColor? foregroundColor;

  /// Fill while the row is `selected`. `null` →
  /// [defaultSelectedBackgroundColor].
  final CoreColor? selectedBackgroundColor;

  /// Foreground while selected. `null` → [defaultSelectedForegroundColor].
  final CoreColor? selectedForegroundColor;

  /// Foreground while disabled. `null` → [defaultDisabledForegroundColor].
  final CoreColor? disabledForegroundColor;

  /// Fill while the row is hovered or keyboard-focused. `null` → the row
  /// paints no fill of its own for the state and the foreground is washed
  /// over the resting fill at [stateLayer]'s weight instead.
  ///
  /// Only a tone whose active state is a fill rather than a wash states
  /// it — `defaultsByTone[critical]`, where the wash colour would be the
  /// error ink itself. A selected or disabled row never reads it.
  final CoreColor? hoverBackgroundColor;

  /// Fill while the row is pressed. `null` → as [hoverBackgroundColor]. It
  /// takes effect only together with [hoverBackgroundColor].
  final CoreColor? pressedBackgroundColor;

  /// Foreground while the row is hovered, focused or pressed — the label,
  /// the description, the shortcut and the glyphs. `null` → every ink keeps
  /// its resting colour (the label and the glyphs the resting foreground,
  /// the description and the shortcut their muted colour). Stated with
  /// [hoverBackgroundColor] and [pressedBackgroundColor], since the ink has
  /// to be chosen for the fill it sits on.
  final CoreColor? activeForegroundColor;

  /// How strongly the foreground is washed over the row on hover / focus /
  /// press. `null` → [defaultStateLayer]. A tone that states an active fill
  /// takes no wash.
  final CoreStateLayer? stateLayer;

  /// Style for the row's `Clickable` — focus ring, press feedback.
  /// `null` → [defaultClickableStyle]. Passed to the `Clickable` as is.
  final CoreClickableStyle? clickableStyle;

  @override
  CoreMenuItemStyle merge(CoreMenuItemStyle? other) {
    if (other == null) return this;
    return CoreMenuItemStyle(
      minHeight: other.minHeight ?? minHeight,
      padding: other.padding ?? padding,
      contentGapStyle:
          contentGapStyle?.merge(other.contentGapStyle) ??
          other.contentGapStyle,
      labelDescriptionGapStyle:
          labelDescriptionGapStyle?.merge(other.labelDescriptionGapStyle) ??
          other.labelDescriptionGapStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      leadingIconStyle:
          leadingIconStyle?.merge(other.leadingIconStyle) ??
          other.leadingIconStyle,
      markIconStyle:
          markIconStyle?.merge(other.markIconStyle) ?? other.markIconStyle,
      chevronIconStyle:
          chevronIconStyle?.merge(other.chevronIconStyle) ??
          other.chevronIconStyle,
      labelStyle: labelStyle?.merge(other.labelStyle) ?? other.labelStyle,
      descriptionStyle:
          descriptionStyle?.merge(other.descriptionStyle) ??
          other.descriptionStyle,
      shortcutTextStyle:
          shortcutTextStyle?.merge(other.shortcutTextStyle) ??
          other.shortcutTextStyle,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      selectedBackgroundColor:
          other.selectedBackgroundColor ?? selectedBackgroundColor,
      selectedForegroundColor:
          other.selectedForegroundColor ?? selectedForegroundColor,
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
      hoverBackgroundColor: other.hoverBackgroundColor ?? hoverBackgroundColor,
      pressedBackgroundColor:
          other.pressedBackgroundColor ?? pressedBackgroundColor,
      activeForegroundColor:
          other.activeForegroundColor ?? activeForegroundColor,
      stateLayer: other.stateLayer ?? stateLayer,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy with the given fields replaced.
  CoreMenuItemStyle copyWith({
    double? minHeight,
    CoreEdgeInsets? padding,
    CoreGapStyle? contentGapStyle,
    CoreGapStyle? labelDescriptionGapStyle,
    CoreBorderRadius? borderRadius,
    CoreIconStyle? leadingIconStyle,
    CoreIconStyle? markIconStyle,
    CoreIconStyle? chevronIconStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? descriptionStyle,
    CoreTextStyle? shortcutTextStyle,
    CoreColor? backgroundColor,
    CoreColor? foregroundColor,
    CoreColor? selectedBackgroundColor,
    CoreColor? selectedForegroundColor,
    CoreColor? disabledForegroundColor,
    CoreColor? hoverBackgroundColor,
    CoreColor? pressedBackgroundColor,
    CoreColor? activeForegroundColor,
    CoreStateLayer? stateLayer,
    CoreClickableStyle? clickableStyle,
  }) => CoreMenuItemStyle(
    minHeight: minHeight ?? this.minHeight,
    padding: padding ?? this.padding,
    contentGapStyle: contentGapStyle ?? this.contentGapStyle,
    labelDescriptionGapStyle:
        labelDescriptionGapStyle ?? this.labelDescriptionGapStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    leadingIconStyle: leadingIconStyle ?? this.leadingIconStyle,
    markIconStyle: markIconStyle ?? this.markIconStyle,
    chevronIconStyle: chevronIconStyle ?? this.chevronIconStyle,
    labelStyle: labelStyle ?? this.labelStyle,
    descriptionStyle: descriptionStyle ?? this.descriptionStyle,
    shortcutTextStyle: shortcutTextStyle ?? this.shortcutTextStyle,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    selectedBackgroundColor:
        selectedBackgroundColor ?? this.selectedBackgroundColor,
    selectedForegroundColor:
        selectedForegroundColor ?? this.selectedForegroundColor,
    disabledForegroundColor:
        disabledForegroundColor ?? this.disabledForegroundColor,
    hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
    pressedBackgroundColor:
        pressedBackgroundColor ?? this.pressedBackgroundColor,
    activeForegroundColor: activeForegroundColor ?? this.activeForegroundColor,
    stateLayer: stateLayer ?? this.stateLayer,
    clickableStyle: clickableStyle ?? this.clickableStyle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMenuItemStyle &&
          runtimeType == other.runtimeType &&
          minHeight == other.minHeight &&
          padding == other.padding &&
          contentGapStyle == other.contentGapStyle &&
          labelDescriptionGapStyle == other.labelDescriptionGapStyle &&
          borderRadius == other.borderRadius &&
          leadingIconStyle == other.leadingIconStyle &&
          markIconStyle == other.markIconStyle &&
          chevronIconStyle == other.chevronIconStyle &&
          labelStyle == other.labelStyle &&
          descriptionStyle == other.descriptionStyle &&
          shortcutTextStyle == other.shortcutTextStyle &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          selectedBackgroundColor == other.selectedBackgroundColor &&
          selectedForegroundColor == other.selectedForegroundColor &&
          disabledForegroundColor == other.disabledForegroundColor &&
          hoverBackgroundColor == other.hoverBackgroundColor &&
          pressedBackgroundColor == other.pressedBackgroundColor &&
          activeForegroundColor == other.activeForegroundColor &&
          stateLayer == other.stateLayer &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hashAll([
    minHeight,
    padding,
    contentGapStyle,
    labelDescriptionGapStyle,
    borderRadius,
    leadingIconStyle,
    markIconStyle,
    chevronIconStyle,
    labelStyle,
    descriptionStyle,
    shortcutTextStyle,
    backgroundColor,
    foregroundColor,
    selectedBackgroundColor,
    selectedForegroundColor,
    disabledForegroundColor,
    hoverBackgroundColor,
    pressedBackgroundColor,
    activeForegroundColor,
    stateLayer,
    clickableStyle,
  ]);
}
