/// Per-instance style for `Select`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_style.dart';
import 'package:coui_core/src/component/contracts/popover/popover_style.dart';
import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/contracts/select/select_size.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Select` should render.
///
/// `CoreSelectStyle` is a composite Style: it nests the Style of every
/// component Select composes — the trigger is a `TextField`
/// ([triggerStyle]), the panel a `Popover` ([popoverStyle]), each row a
/// `MenuItem` ([optionStyle]) — plus the flat chrome of the one thing
/// Select draws itself, the empty-state copy.
///
/// Select diverges from its children in little: the trigger *is* the
/// field ladder (32 / 40 / 48, insets 10 / 12 / 14, error border, hover
/// border), the rows *are* the menu ladder. The field's own `sm` / `md` /
/// `lg` rungs already read at 14px `body-medium` (400, the role's own 150%
/// — the field's value line), so [defaultTriggerStyle] states only the one
/// thing that still diverges: a pressed-only wash — hover is a border
/// step and focus is the ring, neither paints a fill. Over the row it
/// states nothing. What it owns outright is the panel — a column of rows
/// the width of its trigger, inset 6, corner 12, rows 2 apart, 4 below
/// the field — and the chevron's size per rung ([defaultsBySize]).
///
/// **Semantic enums (`variant` / `size`) and behaviour (`placement` /
/// `collision` / `closeOnScroll`) live on the widget, not on this style.**
///
/// ```text
/// design system default
///   → CoreSelectTheme.style                       // 프로젝트 공통
///   → CoreSelectTheme.variantStyles[variant]
///   → widget.selectStyle                          // 인스턴스별
/// ```
@immutable
class CoreSelectStyle implements CoreStyle<CoreSelectStyle> {
  /// Creates a [CoreSelectStyle].
  const CoreSelectStyle({
    this.triggerStyle,
    this.popoverStyle,
    this.optionStyle,
    this.emptyStateStyle,
    this.optionsPanelMaxHeight,
    this.optionSpacing,
    this.trailingIconStyle,
    this.placeholderColor,
    this.selectedIconColor,
    this.emptyStateInsets,
    this.emptyStateColor,
    this.contentColor,
  });

  // ─── Design-system defaults ───────────────────

  /// Empty-state text colour.
  static const CoreColor defaultEmptyStateColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Trigger content (selected value) text colour.
  static const CoreColor defaultContentColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Trigger placeholder text colour (when no value selected). The
  /// dedicated placeholder token — the one `TextField` should read too
  /// (Select 코드 인계 통합본 §10-a).
  static const CoreColor defaultPlaceholderColor = CoreColor.token(
    CoreColors.placeholder,
  );

  /// Selected-option mark colour — **neutral**, not the accent. No
  /// surveyed system paints a single-select mark in its accent (Fluent
  /// `currentColor`, Primer unstated, SEED `fg.neutral`); the accent is
  /// for the checkbox of a multi-select, which this is not (§6-3).
  static const CoreColor defaultSelectedIconColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Empty-state surface padding (around the "no results" text). 12/8
  /// matches `CoreItemPickerStyle.defaultTitlePadding` so the empty
  /// state visually aligns with the title row.
  static const CoreEdgeInsets defaultEmptyStateInsets =
      CoreEdgeInsets.symmetric(
        horizontal: CoreSpace.space12,
        vertical: CoreSpace.space8,
      );

  /// Default options-panel maximum height (logical px). Mirrors
  /// `CorePopoverStyle.defaultFormPopoverMaxHeight` so dropdowns don't
  /// outgrow the viewport on small screens.
  static const double defaultOptionsPanelMaxHeight =
      CorePopoverStyle.defaultFormPopoverMaxHeight;

  /// Gap between consecutive option rows — 2, the menu's own rhythm
  /// (Fluent `rowGap` 2, `CoreMenuStyle.defaultPopupStyle.spacing` 2).
  static const double defaultOptionSpacing = CoreSpace.space2;

  /// The panel — the one surface Select states chrome for, because it
  /// diverges from a bare `Popup`: inset 6 (the kit's menu 6),
  /// corner 12, rows 2 apart, and 4 below the trigger. Width is the
  /// trigger's by default — set by the widget as the popover's width
  /// constraint,
  /// because "as wide as its anchor" is a relation, not a number a style
  /// can hold.
  ///
  /// The corner is pinned at 12 on its own rung, not written as a sum of
  /// the control corner and the inset: the control corner is per size
  /// (8 · 10 · 12 for `sm` · `md` · `lg`), so a sum would make the
  /// panel follow the trigger's size, and the panel is the same panel at
  /// every size. The rows inside it are 6 on every size
  /// ([defaultOptionStyle]), and 6 plus the inset is this 12 — the
  /// concentric pair holds by value, pinned by a Core test.
  ///
  /// The trigger fills the available inline axis (`triggerSizing:
  /// .expand`) — the field-trigger convention every `Popover` that wraps a
  /// `TextField` states (Autocomplete, DatePicker, TimePicker, PhoneInput),
  /// and what the canvas draws: the field is `FILL` inside the select. The
  /// default `intrinsic` would leave the width to each platform's natural
  /// input size — the web `<input>`'s own width (≈200) against Flutter's
  /// placeholder-hugging one (≈126) — so the same `Select` would be a
  /// different width on each. A caller that wants a hugging trigger states
  /// `popoverStyle: CorePopoverStyle(triggerSizing: .intrinsic)`.
  ///
  /// The width belongs to the parent. Where the parent leaves the axis
  /// unbounded — a Flutter `Row` — there is nothing to fill and the trigger
  /// takes its natural width, so a bare `Select` in a `Row` still lays out;
  /// `Expanded` or a `SizedBox` states one.
  static const CorePopoverStyle defaultPopoverStyle = CorePopoverStyle(
    triggerSizing: .expand,
    placementOffset: CoreSpace.space4,
    panelStyle: CorePopupStyle(
      padding: CorePopupStyle.defaultListPadding,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      spacing: CoreSpace.space2,
    ),
  );

  /// Default trigger slot — the two places Select diverges from the
  /// `TextField` it composes; everything else — the 32 / 40 / 48 ladder,
  /// the 10 / 12 / 14 insets that keep its text on the line of the field
  /// stacked above it, the error border kept through focus and over hover,
  /// the hover border step, the disabled trio — is the field's own and its
  /// resolver fills it.
  ///
  /// `baseTextStyle` is stated nowhere here on purpose (2026-09-11 재검토):
  /// the field's own `sm` / `md` / `lg` rungs read at 14px `body-medium`
  /// at the role's own 150% themselves (`CoreTextFieldStyle.defaultsBySize`
  /// — the value line a field draws), and a Select's value is that same
  /// field value text. Stating
  /// it again here would be the "flat default equals child default"
  /// duplicate `core/style-contract.md` forbids — the value the row under the trigger reads at is now the
  /// field's own default, not a Select-specific override.
  ///
  /// `stateLayer` — pressed only. Hover is the border stepping from
  /// `outline` to `on-surface` and focus is the ring; a fill under
  /// either would make the field say the same thing twice, and the canvas
  /// keeps both layers hidden. Pressed paints the 12% the field's own ramp
  /// ends on, so a held trigger reads as held (Select 코드 인계 통합본
  /// 2026-09-09 §4 — the §7 `3 / 8 / 12` line is the earlier draft).
  static const CoreTextFieldStyle defaultTriggerStyle = CoreTextFieldStyle(
    stateLayer: CoreStateLayer(
      hover: CoreOpacity.opacity0,
      focus: CoreOpacity.opacity0,
      pressed: CoreOpacity.pressed,
    ),
  );

  /// Default option-row slot — a partial that diverges from the row's own
  /// defaults in one field, the corner. Each row is a `MenuItem` and keeps
  /// that component's own ladder otherwise (the trigger's rung, handed
  /// down). See [effectiveOptionStyle] for what the row is actually
  /// handed.
  ///
  /// The corner is 6 on every size: an option is a row the panel hosts,
  /// and the `MenuItem` size ladder (the row height × 0.25) is for a row
  /// that stands on its own — read here, a `lg` select would draw 12 six
  /// pixels inside the panel's 12, a corner rounder than the one it nests
  /// in (the concentric row is 12 − 6 = 6).
  static const CoreMenuItemStyle defaultOptionStyle = CoreMenuItemStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
  );

  /// The chevron per rung — 14 · 16 · 18 for `sm` · `md` · `lg`, the control
  /// icon ladder the `TextField` suffix seat steps through at the same
  /// rungs (`CoreTextFieldStyle.defaultsBySize`), so a select's chevron sits
  /// on the same size as the icon a field of that height would carry. Stated
  /// here rather than left to the field because the chevron is Select's
  /// glyph: a caller who restyles the trigger's suffix icons should not move
  /// the chevron by accident.
  static const Map<CoreSelectSize, CoreSelectStyle> defaultsBySize = {
    CoreSelectSize.sm: CoreSelectStyle(
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size14),
    ),
    CoreSelectSize.md: CoreSelectStyle(
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size16),
    ),
    CoreSelectSize.lg: CoreSelectStyle(
      trailingIconStyle: CoreIconStyle(size: CoreIconSize.size18),
    ),
  };

  // ── Slot Styles (nested) ─────────────────────

  /// Look of the trigger field, passed as is to the `TextField` inside.
  /// `null` uses [defaultTriggerStyle].
  final CoreTextFieldStyle? triggerStyle;

  /// Style for the popover: the look of the options panel and its gap from
  /// the trigger. `null` uses [defaultPopoverStyle].
  final CorePopoverStyle? popoverStyle;

  /// Look of each option row, passed as is to its `MenuItem`. `null` uses
  /// [defaultOptionStyle].
  final CoreMenuItemStyle? optionStyle;

  /// Empty-state text style (rendered when the list is empty).
  ///
  /// Deliberately without a `default*`: this slot is an overlay, and what
  /// it overlays is the ambient text style of the panel it sits in — a
  /// `DefaultTextStyle.merge` on Flutter, plain CSS inheritance on Web.
  /// No `CoreTextStyle` constant can name "whatever the panel inherits",
  /// so a default would have to pin a role and would stop the empty-state
  /// copy from tracking the surrounding option rows. The one axis the
  /// design system does own here is the colour, and that has its own
  /// field and default ([emptyStateColor] / [defaultEmptyStateColor]);
  /// both resolvers seed this overlay on top of exactly that.
  final CoreTextStyle? emptyStateStyle;

  // ── Options panel ────────────────────────────

  /// Maximum height of the option list in the panel before it scrolls
  /// (logical px). It limits the list, Select's own scroll area, not the
  /// panel box; set the panel's look (background / border / radius /
  /// padding / shadow) through [popoverStyle]`.panelStyle`
  /// (a `CorePopupStyle`).
  ///
  /// The options panel is the composed `Popover`'s panel box, so its chrome
  /// is not declared here: [popoverStyle]`.panelStyle` is the single source
  /// of truth for it.
  final double? optionsPanelMaxHeight;

  /// Gap between consecutive option rows. `null` → [defaultOptionSpacing].
  final double? optionSpacing;

  // ── Trigger / icon chrome (flat) ─────────────

  /// Icon style of the trigger's chevron. `null` uses the size ladder
  /// ([defaultsBySize]). The colour follows [placeholderColor].
  final CoreIconStyle? trailingIconStyle;

  /// Trigger placeholder text colour override (shown when no value is
  /// selected). Defaults to [defaultPlaceholderColor]. Also the chevron
  /// colour.
  final CoreColor? placeholderColor;

  /// Selected-option mark colour override. Defaults to
  /// [defaultSelectedIconColor].
  final CoreColor? selectedIconColor;

  // ── Empty-state chrome (flat) ────────────────

  /// Empty-state surface padding override (around the "no results"
  /// text). Defaults to [defaultEmptyStateInsets].
  final CoreEdgeInsets? emptyStateInsets;

  /// Empty-state text colour override. Defaults to
  /// [defaultEmptyStateColor].
  final CoreColor? emptyStateColor;

  /// Trigger content (selected value) text colour override.
  /// `null` → [defaultContentColor].
  final CoreColor? contentColor;

  /// The field chrome the select forwards to its trigger `TextField`:
  /// [triggerStyle] over [defaultTriggerStyle], with the two colours that
  /// are Select's own decision folded in underneath — the chosen value's
  /// [contentColor] as the field's `valueStyle` colour and the
  /// [placeholderColor] as its `placeholderStyle` colour (the chevron takes
  /// the same one). One function so both platforms fold identically; the
  /// field resolver fills what is still `null`.
  CoreTextFieldStyle get effectiveTriggerStyle {
    final colours = CoreTextFieldStyle(
      valueStyle: CoreTextStyle(color: contentColor ?? defaultContentColor),
      placeholderStyle: CoreTextStyle(
        color: placeholderColor ?? defaultPlaceholderColor,
      ),
    );
    return defaultTriggerStyle.merge(colours).merge(triggerStyle);
  }

  /// The same trigger chrome for a disabled select — without the two
  /// colours [effectiveTriggerStyle] folds in. An explicit colour on the
  /// field's `valueStyle` / `placeholderStyle` wins over the field's own
  /// disabled tone, so a disabled select that kept them read `placeholder`
  /// and `onSurface` where a disabled field reads `disabledContent`.
  /// Leaving them out hands the colour back to the field.
  CoreTextFieldStyle get effectiveDisabledTriggerStyle =>
      defaultTriggerStyle.merge(triggerStyle);

  /// The row chrome the select forwards to each `MenuItem`: [optionStyle]
  /// over [defaultOptionStyle], with the mark tinted in
  /// [selectedIconColor] — the one thing about a row that is Select's
  /// decision rather than the row's. One function so both platforms fold
  /// identically; the row resolver fills what is still `null`.
  CoreMenuItemStyle get effectiveOptionStyle {
    final mark = CoreMenuItemStyle(
      markIconStyle: CoreIconStyle(
        color: selectedIconColor ?? defaultSelectedIconColor,
      ),
    );
    return defaultOptionStyle.merge(mark).merge(optionStyle);
  }

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreSelectStyle merge(CoreSelectStyle? other) {
    if (other == null) return this;
    return CoreSelectStyle(
      triggerStyle:
          triggerStyle?.merge(other.triggerStyle) ?? other.triggerStyle,
      popoverStyle:
          popoverStyle?.merge(other.popoverStyle) ?? other.popoverStyle,
      optionStyle: optionStyle?.merge(other.optionStyle) ?? other.optionStyle,
      emptyStateStyle:
          emptyStateStyle?.merge(other.emptyStateStyle) ??
          other.emptyStateStyle,
      optionsPanelMaxHeight:
          other.optionsPanelMaxHeight ?? optionsPanelMaxHeight,
      optionSpacing: other.optionSpacing ?? optionSpacing,
      trailingIconStyle:
          trailingIconStyle?.merge(other.trailingIconStyle) ??
          other.trailingIconStyle,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      selectedIconColor: other.selectedIconColor ?? selectedIconColor,
      emptyStateInsets: other.emptyStateInsets ?? emptyStateInsets,
      emptyStateColor: other.emptyStateColor ?? emptyStateColor,
      contentColor: other.contentColor ?? contentColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSelectStyle copyWith({
    CoreTextFieldStyle? triggerStyle,
    CorePopoverStyle? popoverStyle,
    CoreMenuItemStyle? optionStyle,
    CoreTextStyle? emptyStateStyle,
    double? optionsPanelMaxHeight,
    double? optionSpacing,
    CoreIconStyle? trailingIconStyle,
    CoreColor? placeholderColor,
    CoreColor? selectedIconColor,
    CoreEdgeInsets? emptyStateInsets,
    CoreColor? emptyStateColor,
    CoreColor? contentColor,
  }) {
    return CoreSelectStyle(
      triggerStyle: triggerStyle ?? this.triggerStyle,
      popoverStyle: popoverStyle ?? this.popoverStyle,
      optionStyle: optionStyle ?? this.optionStyle,
      emptyStateStyle: emptyStateStyle ?? this.emptyStateStyle,
      optionsPanelMaxHeight:
          optionsPanelMaxHeight ?? this.optionsPanelMaxHeight,
      optionSpacing: optionSpacing ?? this.optionSpacing,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      selectedIconColor: selectedIconColor ?? this.selectedIconColor,
      emptyStateInsets: emptyStateInsets ?? this.emptyStateInsets,
      emptyStateColor: emptyStateColor ?? this.emptyStateColor,
      contentColor: contentColor ?? this.contentColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSelectStyle &&
          runtimeType == other.runtimeType &&
          triggerStyle == other.triggerStyle &&
          popoverStyle == other.popoverStyle &&
          optionStyle == other.optionStyle &&
          emptyStateStyle == other.emptyStateStyle &&
          optionsPanelMaxHeight == other.optionsPanelMaxHeight &&
          optionSpacing == other.optionSpacing &&
          trailingIconStyle == other.trailingIconStyle &&
          placeholderColor == other.placeholderColor &&
          selectedIconColor == other.selectedIconColor &&
          emptyStateInsets == other.emptyStateInsets &&
          emptyStateColor == other.emptyStateColor &&
          contentColor == other.contentColor;

  @override
  int get hashCode => Object.hashAll([
    triggerStyle,
    popoverStyle,
    optionStyle,
    emptyStateStyle,
    optionsPanelMaxHeight,
    optionSpacing,
    trailingIconStyle,
    placeholderColor,
    selectedIconColor,
    emptyStateInsets,
    emptyStateColor,
    contentColor,
  ]);
}
