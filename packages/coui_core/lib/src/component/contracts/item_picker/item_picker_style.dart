/// Per-instance style for `ItemPicker`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/outlined_container/core_outlined_container_elevation.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ItemPicker` should render.
///
/// `CoreItemPickerStyle` carries chrome / dimensional flat fields for
/// the picker container, the search field and each option row.
/// Behavioural / semantic fields (`items`, `selectedValue`,
/// `showSearch`, `enabled`, `layout`, `gridColumns`, `title`, callbacks)
/// stay flat on the widget / contract.
///
/// ```text
/// design system default
///   → CoreItemPickerTheme.style                   // 프로젝트 공통
///   → parent component slot override
///   → widget.itemPickerStyle                      // 인스턴스별
/// ```
@immutable
class CoreItemPickerStyle implements CoreStyle<CoreItemPickerStyle> {
  /// Creates a [CoreItemPickerStyle].
  const CoreItemPickerStyle({
    this.backgroundColor,
    this.borderColor,
    this.hoverBorderColor,
    this.borderRadius,
    this.borderWidth,
    this.elevation,
    this.maxHeight,
    this.selectedColor,
    this.optionTextStyle,
    this.selectedTextStyle,
    this.optionHoverColor,
    this.optionHoverTextStyle,
    this.titleTextStyle,
    this.emptyTextStyle,
    this.titlePadding,
    this.itemsPadding,
    this.optionPadding,
    this.optionSpacing,
    this.optionBorderRadius,
    this.emptyPadding,
    this.clickableStyle,
    this.checkIconSize,
    this.checkColor,
    this.disabledForegroundColor,
    this.searchHeight,
    this.searchFieldStyle,
    this.searchIconStyle,
    this.searchDividerStyle,
  });

  // ─── Design-system defaults ────────────────────

  /// Default picker container background colour token — `surfaceBright`,
  /// the raised face of a panel that floats over the page.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceBright,
  );

  /// Default picker container border colour token — `outlineVariant`.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default picker container border colour token while the pointer is
  /// over the picker — `outline`, one step past the resting
  /// [defaultBorderColor]. A disabled picker has no hover step.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default picker container shadow rung — `lg`, the floating-panel cast
  /// every menu / popover / select panel takes.
  static const CoreOutlinedContainerElevation defaultElevation =
      CoreOutlinedContainerElevation.strong;

  /// Default selected option background colour token — transparent. The
  /// selection is stated by the check glyph alone; the only filled row is
  /// the one under the pointer or the keyboard ([defaultOptionHoverColor]).
  static const CoreColor defaultSelectedColor = CoreColor.transparent;

  /// Default selected-option check glyph colour token — `primary`, the one
  /// accent the picker carries.
  static const CoreColor defaultCheckColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default option label text style slot — token-backed reference to the
  /// `bodyMedium` role with the `onSurface` colour for the resting (neither
  /// selected nor hovered) option row. The selected / hover slots overlay
  /// their own colour on top of this same role. Web emits `text-body-medium`
  /// + `text-on-surface` from `token.name` / `color`; Flutter materialises
  /// the role through `.toValue(theme:)` then resolves the colour.
  static const CoreTextStyle defaultOptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default selected option text style slot — token-backed reference to
  /// the same `bodyMedium` role as [defaultOptionTextStyle], carrying the
  /// `onSurface` text colour — the text tone of the [defaultSelectedColor]
  /// fill — for the selected row through the nested [selectedTextStyle]
  /// slot (raw `defaultSelectedTextColor` folded in).
  ///
  /// The role is stated rather than inherited by merge order: both
  /// resolvers layer this slot on top of [defaultOptionTextStyle], so the
  /// effective role was already `bodyMedium` — spelling it here makes the
  /// slot self-describing (and token-backed, as `style-contract.md`
  /// requires of a text default) without changing what either platform
  /// resolves. Matches the sibling option-list components
  /// (`autocomplete` / `multiple_choice`), whose selected / hover text
  /// defaults state the role the same way.
  static const CoreTextStyle defaultSelectedTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default option hover background colour token — the same opaque
  /// `surfaceContainerHigh` tone as [defaultSelectedColor].
  static const CoreColor defaultOptionHoverColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default option hover text style slot — token-backed reference to the
  /// same `bodySmall` role as [defaultOptionTextStyle], carrying the
  /// `onSurface` text colour for the hovered row through the nested
  /// [optionHoverTextStyle] slot (raw `defaultOptionHoverTextColor` folded
  /// in). The role is stated for the same reason as in
  /// [defaultSelectedTextStyle].
  static const CoreTextStyle defaultOptionHoverTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default picker title slot text style — the list's section label:
  /// `labelSmall` (12 Medium, 140 %) in the `onSurfaceSubtle` colour, the
  /// role's own weight with no overlay.
  ///
  /// The label names the group of rows below it rather than heading the
  /// panel, so it sits in the quiet third text tier at the smallest label
  /// size instead of competing with the option labels.
  static const CoreTextStyle defaultTitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default empty-state slot text style — token-backed reference to the
  /// `bodySmall` slot with the `onSurfaceVariant` colour overlay. Web
  /// emits `text-body-small` from `token.name`; Flutter materialises the
  /// slot through `theme.coreTypography.resolve(...)` then applies the
  /// colour overlay.
  static const CoreTextStyle defaultEmptyTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default picker container border radius.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.panel,
  );

  /// Default picker container border width (logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default picker items scroll-area maximum height (logical px).
  static const double defaultMaxHeight = CoreSpace.space256;

  /// Default picker title padding — top 6 · bottom 4 · sides 8, a 27 row
  /// around the 16.8 `labelSmall` line box.
  ///
  /// Sides 8 on top of the list's own 6 inset put the label's left edge at
  /// 14, the same column as the search glyph and the option text. The
  /// narrower bottom attaches the label to the rows it names.
  static const CoreEdgeInsets defaultTitlePadding = CoreEdgeInsets.only(
    left: CoreSpace.space8,
    top: CoreSpace.space6,
    right: CoreSpace.space8,
    bottom: CoreSpace.space4,
  );

  /// Default search row height — the md control row
  /// ([CoreControlSize.heightMd]).
  ///
  /// The search is a `TextField` composed without a size, so its row is the
  /// field's own `md` row, and this states that rung rather than a length:
  /// a theme density moves it with every other `md` field (32 / 40 / 48)
  /// instead of holding 40 while they shrink. Flutter sizes the row with
  /// this rung moved by the density; Web forwards no height for it, so the
  /// composed field's own row variable carries the same move — which is
  /// why this has to stay equal to `CoreTextFieldStyle`'s `md` row, and a
  /// Core test pins the two together. A caller's own [searchHeight] is a
  /// statement and stays as stated on both.
  static const double defaultSearchHeight = CoreControlSize.heightMd;

  /// Default for [searchFieldStyle] — a partial that states the field's
  /// inset: the 14 the text field's `lg` row takes at the edges, over the
  /// `md` row's own vertical inset.
  ///
  /// The search is a `TextField` composed as the `plain` variant (no box of
  /// its own — the panel is the only boundary, and the divider below it
  /// separates the row from the list). `plain` insets nothing
  /// horizontally, so the inset is stated here. Everything else is left
  /// `null` for the field's own resolver to fill.
  static const CoreTextFieldStyle defaultSearchFieldStyle = CoreTextFieldStyle(
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space14,
      vertical: CoreSpace.space8,
    ),
  );

  /// Default for the search glyph in front of the search field — the 16
  /// `search` icon in the quiet affix tone (`onSurfaceSubtle`).
  static const CoreIconStyle defaultSearchIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default colour of the picker's foreground while it is disabled — the
  /// option text, the selected-option check, the title and the empty-state
  /// line — `disabledContent`. A disabled picker says so
  /// in its own token, not by dimming the enabled pair: an alpha is not a
  /// forced value in a colour-forcing mode.
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default colour of the search glyph while the picker is disabled —
  /// `disabledContent`.
  static const CoreColor defaultDisabledSearchIconColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default for [searchDividerStyle] — nothing stated: the `Divider`'s own
  /// defaults are the hairline (`stroke1`) in `outlineVariant` that closes
  /// the search row.
  static const CoreDividerStyle defaultSearchDividerStyle = CoreDividerStyle();

  /// Default picker items scroll-area padding.
  static const CoreEdgeInsets defaultItemsPadding = CoreEdgeInsets.all(
    CoreSpace.space6,
  );

  /// Default option row padding.
  static const CoreEdgeInsets defaultOptionPadding = CoreEdgeInsets.all(
    CoreSpace.space8,
  );

  /// Default inter-option spacing (logical px). Drives the grid
  /// `mainAxisSpacing` / `crossAxisSpacing` and the per-option row icon
  /// ↔ label gap.
  static const double defaultOptionSpacing = CoreSpace.space8;

  /// Default option row corner radius.
  static const CoreBorderRadius defaultOptionBorderRadius =
      CoreBorderRadius.all(CoreRadiusRole.control);

  /// Default selected-option check icon size (logical px).
  static const double defaultCheckIconSize = CoreIconSize.size16;

  /// Default empty-state padding.
  static const CoreEdgeInsets defaultEmptyPadding = CoreEdgeInsets.all(
    CoreSpace.space24,
  );

  /// Default nested [CoreClickableStyle] slot for the composed per-option
  /// `Clickable` — a partial that pins `pressedScale: 1.0`: each option is
  /// a full-width listbox row whose selection feedback is a background
  /// highlight, so the press-shrink scale that suits boxed controls would
  /// clash with the row highlight. Everything else stays null and resolves
  /// inside the Clickable's own resolver via
  /// `defaultClickableStyle.merge(merged.clickableStyle)`.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    pressedScale: 1,
  );

  /// Picker container background colour override.
  final CoreColor? backgroundColor;

  /// Picker container border colour override.
  final CoreColor? borderColor;

  /// Picker container border colour override while the pointer is over the
  /// picker. `null` → [defaultHoverBorderColor]. Never applied while the
  /// picker is disabled.
  final CoreColor? hoverBorderColor;

  /// Picker container border radius override.
  final CoreBorderRadius? borderRadius;

  /// Picker container border width override (logical px).
  final double? borderWidth;

  /// Picker container shadow rung override. `null` → [defaultElevation].
  final CoreOutlinedContainerElevation? elevation;

  /// Picker items scroll-area maximum height override (logical px).
  final double? maxHeight;

  /// Selected option background colour override.
  final CoreColor? selectedColor;

  /// Option label text style override applied in the resting (neither
  /// selected nor hovered) state. Layers onto the [defaultOptionTextStyle]
  /// token role; the resting colour is carried via [CoreTextStyle.color]
  /// inside this slot.
  final CoreTextStyle? optionTextStyle;

  /// Selected option text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `selectedTextColor` field removed).
  final CoreTextStyle? selectedTextStyle;

  /// Option hover background colour override.
  final CoreColor? optionHoverColor;

  /// Option text style override applied when the option is hovered.
  /// Text colour is carried via [CoreTextStyle.color] inside this slot
  /// (sb8 — raw `optionHoverTextColor` field removed).
  final CoreTextStyle? optionHoverTextStyle;

  /// Picker section label (title row) text style override. Layers onto
  /// the [defaultTitleTextStyle] token role; a weight or colour override
  /// rides [CoreTextStyle.fontWeight] / [CoreTextStyle.color] inside this
  /// slot.
  final CoreTextStyle? titleTextStyle;

  /// Empty-state text style override. Layers onto the
  /// [defaultEmptyTextStyle] token role; the placeholder's colour is
  /// carried via [CoreTextStyle.color] inside this slot.
  final CoreTextStyle? emptyTextStyle;

  /// Picker section label (title row) padding override.
  final CoreEdgeInsets? titlePadding;

  /// Picker items scroll-area padding override.
  final CoreEdgeInsets? itemsPadding;

  /// Option row padding override.
  final CoreEdgeInsets? optionPadding;

  /// Inter-option spacing (logical px). Drives the grid layout
  /// `mainAxisSpacing` / `crossAxisSpacing` (Flutter `GridView.count`) /
  /// `gap` inline CSS (Web grid container) and the per-option row icon ↔
  /// label gap. `null` defers to [defaultOptionSpacing].
  final double? optionSpacing;

  /// Option row corner radius override.
  final CoreBorderRadius? optionBorderRadius;

  /// Empty-state padding override.
  final CoreEdgeInsets? emptyPadding;

  // ─── Slot Styles (nested) ─────────────────────

  /// Style for each option's `Clickable` — press scale, durations, focus
  /// ring, disabled opacity. Laid over [defaultClickableStyle] and passed
  /// to the `Clickable` as is, which fills in the rest.
  final CoreClickableStyle? clickableStyle;

  /// Selected-option check-glyph icon size (logical/CSS px).
  /// `null` → [defaultCheckIconSize].
  final double? checkIconSize;

  /// Selected-option check glyph colour override. `null` →
  /// [defaultCheckColor].
  final CoreColor? checkColor;

  /// Foreground colour while the picker is disabled — the option text, the
  /// selected-option check, the title and the empty-state line. `null` →
  /// [defaultDisabledForegroundColor].
  final CoreColor? disabledForegroundColor;

  /// Search `<input>` row height (logical/CSS px).
  /// `null` → [defaultSearchHeight].
  ///
  /// A stated height fixes the row and stays as stated under every
  /// density — only [defaultSearchHeight], the control row, moves.
  final double? searchHeight;

  /// Look of the search `TextField`. Laid over [defaultSearchFieldStyle]
  /// and passed as is to `TextField(textFieldStyle: …)` on both
  /// platforms. The row height stays [searchHeight].
  ///
  /// Composed per child-component-composition.
  final CoreTextFieldStyle? searchFieldStyle;

  /// Look of the search glyph in front of the search field. Laid over
  /// [defaultSearchIconStyle] and passed to the `Icon` as is. A disabled
  /// picker swaps the colour to [defaultDisabledSearchIconColor] unless
  /// this states one.
  final CoreIconStyle? searchIconStyle;

  /// Look of the `Divider` that closes the search row. Laid over
  /// [defaultSearchDividerStyle] and passed as is to
  /// `Divider(dividerStyle: …)`.
  final CoreDividerStyle? searchDividerStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreItemPickerStyle merge(CoreItemPickerStyle? other) {
    if (other == null) return this;
    return CoreItemPickerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      elevation: other.elevation ?? elevation,
      maxHeight: other.maxHeight ?? maxHeight,
      selectedColor: other.selectedColor ?? selectedColor,
      optionTextStyle: _mergeText(optionTextStyle, other.optionTextStyle),
      selectedTextStyle: _mergeText(selectedTextStyle, other.selectedTextStyle),
      optionHoverColor: other.optionHoverColor ?? optionHoverColor,
      optionHoverTextStyle: _mergeText(
        optionHoverTextStyle,
        other.optionHoverTextStyle,
      ),
      titleTextStyle: _mergeText(titleTextStyle, other.titleTextStyle),
      emptyTextStyle: _mergeText(emptyTextStyle, other.emptyTextStyle),
      titlePadding: other.titlePadding ?? titlePadding,
      itemsPadding: other.itemsPadding ?? itemsPadding,
      optionPadding: other.optionPadding ?? optionPadding,
      optionSpacing: other.optionSpacing ?? optionSpacing,
      optionBorderRadius: other.optionBorderRadius ?? optionBorderRadius,
      emptyPadding: other.emptyPadding ?? emptyPadding,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
      checkIconSize: other.checkIconSize ?? checkIconSize,
      checkColor: other.checkColor ?? checkColor,
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
      searchHeight: other.searchHeight ?? searchHeight,
      searchFieldStyle:
          searchFieldStyle?.merge(other.searchFieldStyle) ??
          other.searchFieldStyle,
      searchIconStyle:
          searchIconStyle?.merge(other.searchIconStyle) ??
          other.searchIconStyle,
      searchDividerStyle:
          searchDividerStyle?.merge(other.searchDividerStyle) ??
          other.searchDividerStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreItemPickerStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? hoverBorderColor,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    CoreOutlinedContainerElevation? elevation,
    double? maxHeight,
    CoreColor? selectedColor,
    CoreTextStyle? optionTextStyle,
    CoreTextStyle? selectedTextStyle,
    CoreColor? optionHoverColor,
    CoreTextStyle? optionHoverTextStyle,
    CoreTextStyle? titleTextStyle,
    CoreTextStyle? emptyTextStyle,
    CoreEdgeInsets? titlePadding,
    CoreEdgeInsets? itemsPadding,
    CoreEdgeInsets? optionPadding,
    double? optionSpacing,
    CoreBorderRadius? optionBorderRadius,
    CoreEdgeInsets? emptyPadding,
    CoreClickableStyle? clickableStyle,
    double? checkIconSize,
    CoreColor? checkColor,
    CoreColor? disabledForegroundColor,
    double? searchHeight,
    CoreTextFieldStyle? searchFieldStyle,
    CoreIconStyle? searchIconStyle,
    CoreDividerStyle? searchDividerStyle,
  }) {
    return CoreItemPickerStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      elevation: elevation ?? this.elevation,
      maxHeight: maxHeight ?? this.maxHeight,
      selectedColor: selectedColor ?? this.selectedColor,
      optionTextStyle: optionTextStyle ?? this.optionTextStyle,
      selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
      optionHoverColor: optionHoverColor ?? this.optionHoverColor,
      optionHoverTextStyle: optionHoverTextStyle ?? this.optionHoverTextStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      emptyTextStyle: emptyTextStyle ?? this.emptyTextStyle,
      titlePadding: titlePadding ?? this.titlePadding,
      itemsPadding: itemsPadding ?? this.itemsPadding,
      optionPadding: optionPadding ?? this.optionPadding,
      optionSpacing: optionSpacing ?? this.optionSpacing,
      optionBorderRadius: optionBorderRadius ?? this.optionBorderRadius,
      emptyPadding: emptyPadding ?? this.emptyPadding,
      clickableStyle: clickableStyle ?? this.clickableStyle,
      checkIconSize: checkIconSize ?? this.checkIconSize,
      checkColor: checkColor ?? this.checkColor,
      disabledForegroundColor:
          disabledForegroundColor ?? this.disabledForegroundColor,
      searchHeight: searchHeight ?? this.searchHeight,
      searchFieldStyle: searchFieldStyle ?? this.searchFieldStyle,
      searchIconStyle: searchIconStyle ?? this.searchIconStyle,
      searchDividerStyle: searchDividerStyle ?? this.searchDividerStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreItemPickerStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          elevation == other.elevation &&
          maxHeight == other.maxHeight &&
          selectedColor == other.selectedColor &&
          optionTextStyle == other.optionTextStyle &&
          selectedTextStyle == other.selectedTextStyle &&
          optionHoverColor == other.optionHoverColor &&
          optionHoverTextStyle == other.optionHoverTextStyle &&
          titleTextStyle == other.titleTextStyle &&
          emptyTextStyle == other.emptyTextStyle &&
          titlePadding == other.titlePadding &&
          itemsPadding == other.itemsPadding &&
          optionPadding == other.optionPadding &&
          optionSpacing == other.optionSpacing &&
          optionBorderRadius == other.optionBorderRadius &&
          emptyPadding == other.emptyPadding &&
          clickableStyle == other.clickableStyle &&
          checkIconSize == other.checkIconSize &&
          checkColor == other.checkColor &&
          disabledForegroundColor == other.disabledForegroundColor &&
          searchHeight == other.searchHeight &&
          searchFieldStyle == other.searchFieldStyle &&
          searchIconStyle == other.searchIconStyle &&
          searchDividerStyle == other.searchDividerStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    hoverBorderColor,
    borderRadius,
    borderWidth,
    elevation,
    maxHeight,
    selectedColor,
    optionTextStyle,
    selectedTextStyle,
    optionHoverColor,
    optionHoverTextStyle,
    titleTextStyle,
    emptyTextStyle,
    titlePadding,
    itemsPadding,
    optionPadding,
    optionSpacing,
    optionBorderRadius,
    Object.hash(
      emptyPadding,
      clickableStyle,
      checkIconSize,
      checkColor,
      disabledForegroundColor,
      searchHeight,
      searchFieldStyle,
      searchIconStyle,
      searchDividerStyle,
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
}
