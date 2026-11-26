/// Per-instance style for `PhoneInput`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/item_picker/item_picker_style.dart';
import 'package:coui_core/src/component/contracts/popover/popover_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `PhoneInput` should render.
///
/// `CorePhoneInputStyle` carries chrome flat fields (border
/// radius / max width / padding) used by both the country
/// selector and the inline phone-number field. Inter-child spacers
/// (flag↔dial-code, country-selector↔input, dropdown flag↔name) are
/// nested [CoreGapStyle] slots ([flagGapStyle] / [countryGapStyle] /
/// [dropdownItemGapStyle]).
///
/// Variant-independent dimensional defaults (popup size,
/// dropdown item padding, icon sizes …) live here as `static const`
/// fields — the single source of truth shared by Flutter and Web
/// resolvers — and are mirrored 1:1 as `final` instance fields below
/// so callers can override any of them through the merge chain.
///
/// ```text
/// design system default
///   → CorePhoneInputTheme (legacy flat fields)
///   → CorePhoneInputTheme.style                     // 프로젝트 공통
///   → parent component slot override
///   → widget.phoneInputStyle                        // 인스턴스별
/// ```
@immutable
class CorePhoneInputStyle implements CoreStyle<CorePhoneInputStyle> {
  /// Creates a [CorePhoneInputStyle].
  const CorePhoneInputStyle({
    this.borderRadius,
    this.flagGapStyle,
    this.countryGapStyle,
    this.maxWidth,
    this.padding,
    this.height,
    this.borderWidth,
    this.inputFieldPadding,
    this.selectorPadding,
    this.dropdownItemPadding,
    this.dropdownItemGapStyle,
    this.popupMaxWidth,
    this.popupMaxHeight,
    this.popoverTopOffset,
    this.chevronIconStyle,
    this.flagSize,
    this.dropdownFlagSize,
    this.disabledOpacity,
    this.popupBorderRadius,
    this.dropdownDialCodeTextStyle,
    this.backgroundColor,
    this.borderColor,
    this.focusBorderColor,
    this.hoverBorderColor,
    this.hoverColor,
    this.separatorColor,
    this.placeholderColor,
    this.chevronColor,
    this.disabledChevronColor,
    this.dialCodeTextStyle,
    this.disabledDialCodeColor,
    this.bodyTextStyle,
    this.numberFieldStyle,
    this.searchFieldStyle,
    this.popoverStyle,
    this.flagBorderRadius,
    this.separatorHeight,
    this.disabledBackgroundColor,
    this.disabledBorderColor,
    this.disabledPlaceholderColor,
    this.dropdownListPadding,
    this.dropdownItemBorderRadius,
    this.dropdownCheckIconStyle,
    this.searchIconStyle,
  });

  // ── Defaults (single source of truth) ───────

  /// Default outer border radius — shared by Flutter
  /// (`.toValue()` → `BorderRadius`) and Web (`rounded-*`). The `lg`
  /// control corner (12) the text field takes at its default row, so the
  /// two read as one family.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.panel,
  );

  /// Default flag corner radius — the part role (4), shared by the flag in
  /// the selector and in the list rows.
  static const CoreBorderRadius defaultFlagBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.part,
  );

  /// Default gap between flag and dial code inside the selector —
  /// forwarded to `Gap(gapStyle: …)` (`crossAxisExtent: 0` so the
  /// spacer stays main-axis only).
  static const CoreGapStyle defaultFlagGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
    crossAxisExtent: 0,
  );

  /// Default gap between country selector and input field — forwarded
  /// to `Gap(gapStyle: …)` (`crossAxisExtent: 0` so the spacer stays
  /// main-axis only).
  static const CoreGapStyle defaultCountryGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
    crossAxisExtent: 0,
  );

  /// Default maximum width of the input row (logical px). The value the
  /// file-local `_kInputMaxWidth` carried, stated on the token scale so the
  /// single source is a `CoreSpace` step (a private file constant is
  /// unreachable from anything reading this class).
  static const double defaultMaxWidth = CoreSpace.space200;

  /// Default outer container height — the lg control row
  /// ([CoreControlSize.heightLg]), the row of the text field it sits
  /// beside.
  ///
  /// A row of the control ladder rather than a length. PhoneInput is a
  /// field — a country trigger and a chromeless number field inside one
  /// bordered box — and it has no Size axis, so its row is always `lg`, the
  /// text field's default row. Stating it as that rung is what lets a
  /// theme density move the box with the text field beside it. Both
  /// resolvers move this default and leave a caller's own [height] as
  /// stated.
  ///
  /// The corner does not follow the row: the height × 0.25 corner belongs
  /// to a control whose Size axis picks a rung, and this box picks none.
  static const double defaultHeight = CoreControlSize.heightLg;

  /// Default height of the hairline between the selector and the number
  /// (logical px) — shorter than the box, so the line reads as a divider
  /// inside the row rather than a second edge.
  static const double defaultSeparatorHeight = CoreSize.size20;

  /// Default outer border stroke width.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default horizontal padding of the country selector trigger — 14 on
  /// the side the text starts and 10 on the side the chevron closes, a
  /// statement about reading order.
  static const CoreEdgeInsets defaultSelectorPadding =
      CoreEdgeInsets.directional(
        start: CoreSpace.space14,
        end: CoreSpace.space10,
      );

  /// Default horizontal padding of the phone-number input field — 12 on
  /// both sides, so the text sits as far from the separator before it as
  /// from the box edge after it. Kept directional so the selector and the
  /// field state their insets the same way.
  static const CoreEdgeInsets defaultInputFieldPadding =
      CoreEdgeInsets.directional(
        start: CoreSpace.space12,
        end: CoreSpace.space12,
      );

  /// Default padding of a country row — the option row the item picker
  /// draws ([CoreItemPickerStyle.defaultOptionPadding]), so the two lists
  /// read as one panel.
  static const CoreEdgeInsets defaultDropdownItemPadding =
      CoreItemPickerStyle.defaultOptionPadding;

  /// Default padding of the country list inside the panel — the item
  /// picker's list inset ([CoreItemPickerStyle.defaultItemsPadding]).
  static const CoreEdgeInsets defaultDropdownListPadding =
      CoreItemPickerStyle.defaultItemsPadding;

  /// Default country row corner radius — the item picker's option corner
  /// ([CoreItemPickerStyle.defaultOptionBorderRadius]).
  static const CoreBorderRadius defaultDropdownItemBorderRadius =
      CoreItemPickerStyle.defaultOptionBorderRadius;

  /// Default selected-country check glyph — the item picker's check
  /// (16, `primary`).
  static const CoreIconStyle defaultDropdownCheckIconStyle = CoreIconStyle(
    size: CoreItemPickerStyle.defaultCheckIconSize,
    color: CoreItemPickerStyle.defaultCheckColor,
  );

  /// Default search glyph in front of the country search field — the item
  /// picker's ([CoreItemPickerStyle.defaultSearchIconStyle]).
  static const CoreIconStyle defaultSearchIconStyle =
      CoreItemPickerStyle.defaultSearchIconStyle;

  /// Default gap inside a dropdown item between flag and name —
  /// forwarded to `Gap(gapStyle: …)` (`crossAxisExtent: 0` so the
  /// spacer stays main-axis only).
  static const CoreGapStyle defaultDropdownItemGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
    crossAxisExtent: 0,
  );

  /// Default maximum width of the country picker popup (logical px).
  static const double defaultPopupMaxWidth = CoreSpace.space248;

  /// Default maximum height of the country picker popup (logical px).
  static const double defaultPopupMaxHeight = CoreSpace.space248;

  /// Default vertical offset between the trigger and the popup
  /// (logical px) — Flutter popover offset / Web `mt-*`.
  static const double defaultPopoverTopOffset = CoreSpace.space4;

  /// Default chevron icon style — `size` only. Per-instance override
  /// flows through [chevronIconStyle] (merged on top of this default).
  static const CoreIconStyle defaultChevronIconStyle = CoreIconStyle(
    size: _chevronIconSize,
  );

  /// Default chevron icon size (logical px) — mirrors Web SVG `width="12"`.
  ///
  /// A class member rather than a file-level const: the Figma exporter
  /// resolves a bare identifier against the class that wrote it, and a
  /// top-level const is in no class, so `chevronIconStyle.size` reached the
  /// canvas as `null` for as long as the value lived outside the class.
  static const double _chevronIconSize = 12;

  /// Default flag artwork extent in the selector (logical px) — the value
  /// the file-local `_kFlagSize` carried, stated on the token scale.
  static const double defaultFlagSize = CoreSize.size14;

  /// Default flag artwork extent inside dropdown items (logical px).
  /// Its own default (not [defaultFlagSize]) because
  /// [dropdownFlagSize] is its own override slot; the list row draws the
  /// flag at the selector's step, so a country reads as one size in both.
  static const double defaultDropdownFlagSize = CoreSize.size14;

  /// Default opacity applied to the whole component when disabled.
  /// A disabled field states its own tokens (`disabledContainer` fill,
  /// `disabledOutline` edge, `disabledContent` text and glyphs); dimming the
  /// whole component on top of them would make the result depend on the
  /// surface underneath.
  static const double defaultDisabledOpacity = CoreOpacity.opacity100;

  /// Default popup border radius — shared by Flutter and Web. The composed
  /// `Popup` panel's own corner (the panel role), named rather than
  /// restated so the country list stays the same shape as every other
  /// floating panel.
  static const CoreBorderRadius defaultPopupBorderRadius =
      CorePopupStyle.defaultBorderRadius;

  /// Default muted dropdown text style — `bodyMedium` typography role +
  /// muted `onSurfaceVariant` foreground colour. Drives the dropdown-item
  /// dial-code span and the "No results" empty hint (Flutter) and the
  /// dropdown-item dial-code span (Web); both are the same `bodyMedium`
  /// muted hint with no state branch, so this single nested slot carries
  /// both the role token and the colour. Overlaid with the per-instance
  /// [dropdownDialCodeTextStyle] slot.
  static const CoreTextStyle defaultDropdownDialCodeTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.bodyMedium,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      );

  /// Default outer container background fill — the `surface` token. Shared
  /// by Flutter (`scheme.resolve(...).toValue()`) and Web (`bg-{surface}`).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default outer container border colour — the `outlineVariant` token,
  /// the resting edge the text field takes (it steps to `outline` under the
  /// pointer, [defaultHoverBorderColor]).
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default outer container fill while disabled — `disabledContainer`.
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default outer container border colour while disabled —
  /// `disabledOutline`.
  static const CoreColor defaultDisabledBorderColor = CoreColor.token(
    CoreColors.disabledOutline,
  );

  /// Default number-field placeholder colour while disabled —
  /// `disabledContent`.
  static const CoreColor defaultDisabledPlaceholderColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default outer container border colour while any inner field is focused
  /// — the `primary` token (matches `FormattedInput` / `ObjectInput`). The
  /// outer container owns the single focus boundary; inner fields are
  /// chromeless so no ring is drawn (and clipped) inside.
  static const CoreColor defaultFocusBorderColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default outer container border colour while the pointer is over the
  /// field — the `outline` token, the same step the text field takes. Hover
  /// is a *border* step, not a fill: it never reaches the selector / row
  /// background ([defaultHoverColor]). The ladder is `disabled > focus >
  /// hover > rest`, so a focused field keeps [defaultFocusBorderColor] and a
  /// disabled one takes no hover step.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default hover background for the dropdown rows — the opaque
  /// `surfaceContainerHigh` tone (Flutter hover fill / Web
  /// `hover:bg-{surface-container-high}`), a neutral step off the panel
  /// rather than an accent fill. The selector trigger takes no fill; the
  /// selected row is marked by its check alone.
  static const CoreColor defaultHoverColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default divider colour between the selector and the input (and inside
  /// the picker) — the `outlineVariant` token. Forwarded into the
  /// `CoreDividerStyle` slot (Flutter) / emitted as the `border-r`/
  /// `border-b` colour token class (Web).
  static const CoreColor defaultSeparatorColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default placeholder text colour for the phone-number field and the
  /// dropdown search input — the `onSurfaceVariant` token. Emitted as a
  /// pseudo-state class (`placeholder:text-{onSurfaceVariant}`) on Web.
  static const CoreColor defaultPlaceholderColor = CoreColor.token(
    CoreColors.placeholder,
  );

  /// Default selector chevron icon colour — enabled state
  /// (`onSurfaceSubtle`, the quiet affix tone).
  static const CoreColor defaultChevronColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default selector chevron icon colour — disabled state
  /// (`onSurfaceVariant`).
  static const CoreColor defaultDisabledChevronColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default selector dial-code label text style — the `bodyLarge`
  /// typography role + the `onSurface` foreground colour (enabled state).
  /// Disabled state swaps the colour to [defaultDisabledDialCodeColor]; the
  /// role is shared.
  static const CoreTextStyle defaultDialCodeTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyLarge,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default selector dial-code label colour — disabled state
  /// (`disabledContent`). Overlaid on [defaultDialCodeTextStyle].
  static const CoreColor defaultDisabledDialCodeColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default body text style for country-name labels — the `bodyMedium`
  /// typography role, the item picker's option label.
  static const CoreTextStyle defaultBodyTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
  );

  /// Chromeless inner-field style shared by the phone-number field and the
  /// dropdown search field: transparent background / border / focus ring and
  /// zero padding, so the surrounding container (or dropdown panel) owns the
  /// single visible boundary. A single Core source of truth referenced by both
  /// the Flutter and Web widgets (no per-platform file-local copies).
  ///
  /// The hover step is silenced with the rest: `TextField` takes an
  /// `onSurface` border while hovered, and a zero-width Flutter border is a
  /// hairline rather than nothing, so an unstated hover colour would draw a
  /// second line inside the outer container's one boundary.
  static const CoreTextFieldStyle chromelessFieldStyle = CoreTextFieldStyle(
    backgroundColor: .transparent,
    borderColor: .transparent,
    hoverBorderColor: .transparent,
    focusBorderColor: .transparent,
    borderWidth: 0,
    // Square: the container (or dropdown panel) owns the corners. With no
    // padding the caret sits on the field's own left edge, and a browser
    // clips an `<input>`'s content to its rounded box — a corner left to the
    // size row's default (a quarter of the row height) is a pill around a
    // one-line field and shaves the 1px caret to a sliver.
    borderRadius: .zero,
    padding: .zero,
    // No floor: the outer frame is the box and sets the row height; the
    // field inside it is only the line it types on.
    minHeight: 0,
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: .transparent,
      borderWidth: 0,
      offsetColor: .transparent,
    ),
  );

  /// Default phone-number field style; the outer container owns its chrome.
  static final CoreTextFieldStyle defaultNumberFieldStyle = chromelessFieldStyle
      .merge(
        const CoreTextFieldStyle(
          // The number reads at the dial code's size (`bodyLarge`), not the
          // field's own row typography.
          baseTextStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
        ),
      );

  /// The `TextField` style that carries this component's one
  /// [placeholderColor] into both composed fields' placeholder slots.
  ///
  /// The colour has to ride the fields' own style: both `<input>`s — and on
  /// Web the `::placeholder` pseudo-element that paints them — belong to the
  /// composed `TextField`s, so a colour stated on the phone input's own
  /// elements reaches nothing. One Core function so both platforms lay the
  /// same overlay (the number field over [chromelessFieldStyle], the search
  /// field over [defaultSearchFieldStyle] and under the caller's
  /// [searchFieldStyle]).
  static CoreTextFieldStyle placeholderFieldStyle(CoreColor color) =>
      CoreTextFieldStyle(placeholderStyle: CoreTextStyle(color: color));

  /// Default dropdown search-field style — the item picker's
  /// ([CoreItemPickerStyle.defaultSearchFieldStyle]): the bare variant with
  /// the 14 inset, so the country panel's search row is the item picker's.
  /// Overridable through the [searchFieldStyle] slot.
  static const CoreTextFieldStyle defaultSearchFieldStyle =
      CoreItemPickerStyle.defaultSearchFieldStyle;

  /// Default country-dropdown popover style — a full-width trigger
  /// (`triggerSizing: expand`, matching the field width) placed below the
  /// field. Overridable through the [popoverStyle] slot.
  ///
  /// The panel is the item picker's: the popup's bright face and `lg` cast,
  /// the quiet `outlineVariant` line, and no inset of its own — the search
  /// row and its divider run edge to edge, the list carries its own inset
  /// ([defaultDropdownListPadding]).
  static const CorePopoverStyle defaultPopoverStyle = CorePopoverStyle(
    triggerSizing: .expand,
    panelStyle: CorePopupStyle(
      borderColor: CoreItemPickerStyle.defaultBorderColor,
      padding: CoreEdgeInsets.zero,
    ),
  );

  // ── Chrome (flat) ────────────────────────────

  /// Outer border radius override.
  final CoreBorderRadius? borderRadius;

  /// Gap between the flag and the dial code inside the selector, passed to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle? flagGapStyle;

  /// Gap between the country selector and the input field, passed to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle? countryGapStyle;

  /// Maximum width of the input row (logical px).
  final double? maxWidth;

  /// Inner padding override.
  ///
  /// No `default*`, deliberately: this is the OUTER row's padding, and a
  /// flush row is the design. The padding a phone input actually shows
  /// belongs to its parts, and each of those is stated —
  /// [defaultSelectorPadding], [defaultInputFieldPadding],
  /// [defaultDropdownItemPadding]. This field only exists so a caller
  /// can inset the assembled row, and Web emits it under
  /// `if (padding != null)`, so a default would add standing padding
  /// outside every phone input and shift the whole control against the
  /// three inner paddings that were measured for a flush row.
  final CoreEdgeInsets? padding;

  /// Outer container height override (logical px).
  ///
  /// A stated height stays as stated under every density — only
  /// [defaultHeight], the control row, moves.
  final double? height;

  /// Outer border stroke width override (logical px).
  final double? borderWidth;

  /// Inner padding of the phone-number input field.
  final CoreEdgeInsets? inputFieldPadding;

  /// Country selector trigger padding override.
  final CoreEdgeInsets? selectorPadding;

  /// Dropdown / search item padding override.
  final CoreEdgeInsets? dropdownItemPadding;

  /// Gap between a dropdown item's flag and its country name, passed to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle? dropdownItemGapStyle;

  /// Maximum width of the country picker popup (logical px).
  final double? popupMaxWidth;

  /// Maximum height of the country picker popup (logical px).
  final double? popupMaxHeight;

  /// Vertical offset between the trigger and the popup (logical px).
  final double? popoverTopOffset;

  /// Chevron icon style override — `size` defers to
  /// [defaultChevronIconStyle].
  final CoreIconStyle? chevronIconStyle;

  /// Flag emoji font size in the selector (logical px).
  final double? flagSize;

  /// Flag emoji font size inside dropdown items (logical px).
  final double? dropdownFlagSize;

  /// Opacity applied to the whole component when disabled.
  final double? disabledOpacity;

  /// Popup border radius override.
  final CoreBorderRadius? popupBorderRadius;

  /// Muted dropdown text style override — drives both the dropdown-item
  /// dial-code span and the "No results" empty hint (Flutter), and the
  /// dropdown-item dial-code span (Web). Both the typography role token and
  /// the text colour are carried inside this slot, overlaying
  /// [defaultDropdownDialCodeTextStyle].
  final CoreTextStyle? dropdownDialCodeTextStyle;

  /// Outer container background fill override — defers to
  /// [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Outer container border colour override — defers to
  /// [defaultBorderColor]. The popup panel border rides [popoverStyle] and
  /// the selector↔input divider rides [separatorColor].
  final CoreColor? borderColor;

  /// Outer container focused border colour override — defers to
  /// [defaultFocusBorderColor].
  final CoreColor? focusBorderColor;

  /// Outer container border colour override while the pointer is over the
  /// field — defers to [defaultHoverBorderColor]. Outranked by the focused
  /// border ([focusBorderColor]) and absent while the field is disabled.
  /// Not the selector / row hover *background* — that is [hoverColor].
  final CoreColor? hoverBorderColor;

  /// Hover background override (dropdown rows) — defers to
  /// [defaultHoverColor].
  final CoreColor? hoverColor;

  /// Selector↔input / picker divider colour override — defers to
  /// [defaultSeparatorColor].
  final CoreColor? separatorColor;

  /// Placeholder text colour override (phone field + search input) —
  /// defers to [defaultPlaceholderColor].
  final CoreColor? placeholderColor;

  /// Selector chevron icon colour override — enabled state, defers to
  /// [defaultChevronColor].
  final CoreColor? chevronColor;

  /// Selector chevron icon colour override — disabled state, defers to
  /// [defaultDisabledChevronColor].
  final CoreColor? disabledChevronColor;

  /// Selector dial-code label text style override — enabled state. Both the
  /// `labelLarge` role token and the `onSurface` colour live inside the
  /// slot, overlaying [defaultDialCodeTextStyle].
  final CoreTextStyle? dialCodeTextStyle;

  /// Selector dial-code label colour override — disabled state, defers to
  /// [defaultDisabledDialCodeColor].
  final CoreColor? disabledDialCodeColor;

  /// Country-name label text style override — defers to [defaultBodyTextStyle].
  final CoreTextStyle? bodyTextStyle;

  /// Style override for the phone-number `TextField`. The default remains
  /// chromeless; use this slot for input typography without changing the
  /// country selector or search field.
  final CoreTextFieldStyle? numberFieldStyle;

  /// Style override for the country-search `TextField` inside the dropdown.
  /// Defers to [defaultSearchFieldStyle], independently of [numberFieldStyle].
  final CoreTextFieldStyle? searchFieldStyle;

  /// Style for the country dropdown's `Popover` panel — its border,
  /// surface, corners and shadow are set through its `panelStyle`. Laid
  /// over [defaultPopoverStyle].
  final CorePopoverStyle? popoverStyle;

  /// Flag corner radius override — the flag glyph in the selector and in
  /// the list rows. `null` → [defaultFlagBorderRadius].
  final CoreBorderRadius? flagBorderRadius;

  /// Height override of the hairline between the selector and the number
  /// (logical px). `null` → [defaultSeparatorHeight].
  final double? separatorHeight;

  /// Outer container fill override while disabled. `null` →
  /// [defaultDisabledBackgroundColor].
  final CoreColor? disabledBackgroundColor;

  /// Outer container border colour override while disabled. `null` →
  /// [defaultDisabledBorderColor].
  final CoreColor? disabledBorderColor;

  /// Number-field placeholder colour override while disabled. `null` →
  /// [defaultDisabledPlaceholderColor].
  final CoreColor? disabledPlaceholderColor;

  /// Padding of the country list inside the panel override. `null` →
  /// [defaultDropdownListPadding].
  final CoreEdgeInsets? dropdownListPadding;

  /// Country row corner radius override. `null` →
  /// [defaultDropdownItemBorderRadius].
  final CoreBorderRadius? dropdownItemBorderRadius;

  /// Style of the check glyph beside the selected country, laid over
  /// [defaultDropdownCheckIconStyle].
  final CoreIconStyle? dropdownCheckIconStyle;

  /// Style of the search glyph in front of the country search field, laid
  /// over [defaultSearchIconStyle].
  final CoreIconStyle? searchIconStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CorePhoneInputStyle merge(CorePhoneInputStyle? other) {
    if (other == null) return this;
    return CorePhoneInputStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      flagGapStyle: _mergeGap(flagGapStyle, other.flagGapStyle),
      countryGapStyle: _mergeGap(countryGapStyle, other.countryGapStyle),
      maxWidth: other.maxWidth ?? maxWidth,
      padding: other.padding ?? padding,
      height: other.height ?? height,
      borderWidth: other.borderWidth ?? borderWidth,
      inputFieldPadding: other.inputFieldPadding ?? inputFieldPadding,
      selectorPadding: other.selectorPadding ?? selectorPadding,
      dropdownItemPadding: other.dropdownItemPadding ?? dropdownItemPadding,
      dropdownItemGapStyle: _mergeGap(
        dropdownItemGapStyle,
        other.dropdownItemGapStyle,
      ),
      popupMaxWidth: other.popupMaxWidth ?? popupMaxWidth,
      popupMaxHeight: other.popupMaxHeight ?? popupMaxHeight,
      popoverTopOffset: other.popoverTopOffset ?? popoverTopOffset,
      chevronIconStyle: _mergeIcon(chevronIconStyle, other.chevronIconStyle),
      flagSize: other.flagSize ?? flagSize,
      dropdownFlagSize: other.dropdownFlagSize ?? dropdownFlagSize,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
      popupBorderRadius: other.popupBorderRadius ?? popupBorderRadius,
      dropdownDialCodeTextStyle: _mergeText(
        dropdownDialCodeTextStyle,
        other.dropdownDialCodeTextStyle,
      ),
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      focusBorderColor: other.focusBorderColor ?? focusBorderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      hoverColor: other.hoverColor ?? hoverColor,
      separatorColor: other.separatorColor ?? separatorColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      chevronColor: other.chevronColor ?? chevronColor,
      disabledChevronColor: other.disabledChevronColor ?? disabledChevronColor,
      dialCodeTextStyle: _mergeText(
        dialCodeTextStyle,
        other.dialCodeTextStyle,
      ),
      disabledDialCodeColor:
          other.disabledDialCodeColor ?? disabledDialCodeColor,
      bodyTextStyle: _mergeText(bodyTextStyle, other.bodyTextStyle),
      numberFieldStyle: _mergeTextField(
        numberFieldStyle,
        other.numberFieldStyle,
      ),
      searchFieldStyle: _mergeTextField(
        searchFieldStyle,
        other.searchFieldStyle,
      ),
      popoverStyle: _mergePopover(popoverStyle, other.popoverStyle),
      flagBorderRadius: other.flagBorderRadius ?? flagBorderRadius,
      separatorHeight: other.separatorHeight ?? separatorHeight,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      disabledPlaceholderColor:
          other.disabledPlaceholderColor ?? disabledPlaceholderColor,
      dropdownListPadding: other.dropdownListPadding ?? dropdownListPadding,
      dropdownItemBorderRadius:
          other.dropdownItemBorderRadius ?? dropdownItemBorderRadius,
      dropdownCheckIconStyle: _mergeIcon(
        dropdownCheckIconStyle,
        other.dropdownCheckIconStyle,
      ),
      searchIconStyle: _mergeIcon(searchIconStyle, other.searchIconStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CorePhoneInputStyle copyWith({
    CoreBorderRadius? borderRadius,
    CoreGapStyle? flagGapStyle,
    CoreGapStyle? countryGapStyle,
    double? maxWidth,
    CoreEdgeInsets? padding,
    double? height,
    double? borderWidth,
    CoreEdgeInsets? inputFieldPadding,
    CoreEdgeInsets? selectorPadding,
    CoreEdgeInsets? dropdownItemPadding,
    CoreGapStyle? dropdownItemGapStyle,
    double? popupMaxWidth,
    double? popupMaxHeight,
    double? popoverTopOffset,
    CoreIconStyle? chevronIconStyle,
    double? flagSize,
    double? dropdownFlagSize,
    double? disabledOpacity,
    CoreBorderRadius? popupBorderRadius,
    CoreTextStyle? dropdownDialCodeTextStyle,
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? focusBorderColor,
    CoreColor? hoverBorderColor,
    CoreColor? hoverColor,
    CoreColor? separatorColor,
    CoreColor? placeholderColor,
    CoreColor? chevronColor,
    CoreColor? disabledChevronColor,
    CoreTextStyle? dialCodeTextStyle,
    CoreColor? disabledDialCodeColor,
    CoreTextStyle? bodyTextStyle,
    CoreTextFieldStyle? numberFieldStyle,
    CoreTextFieldStyle? searchFieldStyle,
    CorePopoverStyle? popoverStyle,
    CoreBorderRadius? flagBorderRadius,
    double? separatorHeight,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledBorderColor,
    CoreColor? disabledPlaceholderColor,
    CoreEdgeInsets? dropdownListPadding,
    CoreBorderRadius? dropdownItemBorderRadius,
    CoreIconStyle? dropdownCheckIconStyle,
    CoreIconStyle? searchIconStyle,
  }) {
    return CorePhoneInputStyle(
      borderRadius: borderRadius ?? this.borderRadius,
      flagGapStyle: flagGapStyle ?? this.flagGapStyle,
      countryGapStyle: countryGapStyle ?? this.countryGapStyle,
      maxWidth: maxWidth ?? this.maxWidth,
      padding: padding ?? this.padding,
      height: height ?? this.height,
      borderWidth: borderWidth ?? this.borderWidth,
      inputFieldPadding: inputFieldPadding ?? this.inputFieldPadding,
      selectorPadding: selectorPadding ?? this.selectorPadding,
      dropdownItemPadding: dropdownItemPadding ?? this.dropdownItemPadding,
      dropdownItemGapStyle: dropdownItemGapStyle ?? this.dropdownItemGapStyle,
      popupMaxWidth: popupMaxWidth ?? this.popupMaxWidth,
      popupMaxHeight: popupMaxHeight ?? this.popupMaxHeight,
      popoverTopOffset: popoverTopOffset ?? this.popoverTopOffset,
      chevronIconStyle: chevronIconStyle ?? this.chevronIconStyle,
      flagSize: flagSize ?? this.flagSize,
      dropdownFlagSize: dropdownFlagSize ?? this.dropdownFlagSize,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      popupBorderRadius: popupBorderRadius ?? this.popupBorderRadius,
      dropdownDialCodeTextStyle:
          dropdownDialCodeTextStyle ?? this.dropdownDialCodeTextStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      hoverColor: hoverColor ?? this.hoverColor,
      separatorColor: separatorColor ?? this.separatorColor,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      chevronColor: chevronColor ?? this.chevronColor,
      disabledChevronColor: disabledChevronColor ?? this.disabledChevronColor,
      dialCodeTextStyle: dialCodeTextStyle ?? this.dialCodeTextStyle,
      disabledDialCodeColor:
          disabledDialCodeColor ?? this.disabledDialCodeColor,
      bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
      numberFieldStyle: numberFieldStyle ?? this.numberFieldStyle,
      searchFieldStyle: searchFieldStyle ?? this.searchFieldStyle,
      popoverStyle: popoverStyle ?? this.popoverStyle,
      flagBorderRadius: flagBorderRadius ?? this.flagBorderRadius,
      separatorHeight: separatorHeight ?? this.separatorHeight,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledPlaceholderColor:
          disabledPlaceholderColor ?? this.disabledPlaceholderColor,
      dropdownListPadding: dropdownListPadding ?? this.dropdownListPadding,
      dropdownItemBorderRadius:
          dropdownItemBorderRadius ?? this.dropdownItemBorderRadius,
      dropdownCheckIconStyle:
          dropdownCheckIconStyle ?? this.dropdownCheckIconStyle,
      searchIconStyle: searchIconStyle ?? this.searchIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePhoneInputStyle &&
          runtimeType == other.runtimeType &&
          borderRadius == other.borderRadius &&
          flagGapStyle == other.flagGapStyle &&
          countryGapStyle == other.countryGapStyle &&
          maxWidth == other.maxWidth &&
          padding == other.padding &&
          height == other.height &&
          borderWidth == other.borderWidth &&
          inputFieldPadding == other.inputFieldPadding &&
          selectorPadding == other.selectorPadding &&
          dropdownItemPadding == other.dropdownItemPadding &&
          dropdownItemGapStyle == other.dropdownItemGapStyle &&
          popupMaxWidth == other.popupMaxWidth &&
          popupMaxHeight == other.popupMaxHeight &&
          popoverTopOffset == other.popoverTopOffset &&
          chevronIconStyle == other.chevronIconStyle &&
          flagSize == other.flagSize &&
          dropdownFlagSize == other.dropdownFlagSize &&
          disabledOpacity == other.disabledOpacity &&
          popupBorderRadius == other.popupBorderRadius &&
          dropdownDialCodeTextStyle == other.dropdownDialCodeTextStyle &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          focusBorderColor == other.focusBorderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          hoverColor == other.hoverColor &&
          separatorColor == other.separatorColor &&
          placeholderColor == other.placeholderColor &&
          chevronColor == other.chevronColor &&
          disabledChevronColor == other.disabledChevronColor &&
          dialCodeTextStyle == other.dialCodeTextStyle &&
          disabledDialCodeColor == other.disabledDialCodeColor &&
          bodyTextStyle == other.bodyTextStyle &&
          numberFieldStyle == other.numberFieldStyle &&
          searchFieldStyle == other.searchFieldStyle &&
          popoverStyle == other.popoverStyle &&
          flagBorderRadius == other.flagBorderRadius &&
          separatorHeight == other.separatorHeight &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledBorderColor == other.disabledBorderColor &&
          disabledPlaceholderColor == other.disabledPlaceholderColor &&
          dropdownListPadding == other.dropdownListPadding &&
          dropdownItemBorderRadius == other.dropdownItemBorderRadius &&
          dropdownCheckIconStyle == other.dropdownCheckIconStyle &&
          searchIconStyle == other.searchIconStyle;

  @override
  int get hashCode => Object.hashAll([
    borderRadius,
    flagGapStyle,
    countryGapStyle,
    maxWidth,
    padding,
    height,
    borderWidth,
    inputFieldPadding,
    selectorPadding,
    dropdownItemPadding,
    dropdownItemGapStyle,
    popupMaxWidth,
    popupMaxHeight,
    popoverTopOffset,
    chevronIconStyle,
    flagSize,
    dropdownFlagSize,
    disabledOpacity,
    popupBorderRadius,
    dropdownDialCodeTextStyle,
    backgroundColor,
    borderColor,
    focusBorderColor,
    hoverBorderColor,
    hoverColor,
    separatorColor,
    placeholderColor,
    chevronColor,
    disabledChevronColor,
    dialCodeTextStyle,
    disabledDialCodeColor,
    bodyTextStyle,
    numberFieldStyle,
    searchFieldStyle,
    popoverStyle,
    flagBorderRadius,
    separatorHeight,
    disabledBackgroundColor,
    disabledBorderColor,
    disabledPlaceholderColor,
    dropdownListPadding,
    dropdownItemBorderRadius,
    dropdownCheckIconStyle,
    searchIconStyle,
  ]);

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

  static CoreIconStyle? _mergeIcon(
    CoreIconStyle? base,
    CoreIconStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextFieldStyle? _mergeTextField(
    CoreTextFieldStyle? base,
    CoreTextFieldStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CorePopoverStyle? _mergePopover(
    CorePopoverStyle? base,
    CorePopoverStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}

/// Default opacity applied to the disabled component (Web `opacity-50`).
