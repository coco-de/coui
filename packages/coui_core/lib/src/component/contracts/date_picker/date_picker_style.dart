/// Per-instance style for `DatePicker` / `DateRangePicker`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/calendar/calendar_style.dart';
import 'package:coui_core/src/component/contracts/dialog/dialog_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/popover/popover_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `DatePicker` /
/// `DateRangePicker` should render.
///
/// `CoreDatePickerStyle` is a composite Style: it
/// nests the Style of every sub-component DatePicker uses
/// (popover for the trigger + panel mode, dialog for the modal
/// mode, calendar inside both modes) plus nested text styles for
/// label / description / error.
///
/// **Semantic enums (`mode` / `selectionMode`) and behaviour
/// fields (`minDate` / `maxDate` / `onChanged` …) live on the
/// widget, not on this style** (Epic #1302 원칙 6/7).
///
/// To change the **trigger button's variant** or use a custom
/// dialog action button, inject the widget directly via the
/// dedicated slot (asChild pattern, Epic #1302 원칙 8).
///
/// ```text
/// design system default
///   → CoreDatePickerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.datePickerStyle                          // 인스턴스별
/// ```
///
/// ### Type parameters
///
/// - `Clr` — colour type (Flutter `Color`, Web `String`).
/// - `Shadow` — shadow type
///   (Flutter `List<BoxShadow>`, Web `String`).
@immutable
class CoreDatePickerStyle implements CoreStyle<CoreDatePickerStyle> {
  /// Creates a [CoreDatePickerStyle].
  const CoreDatePickerStyle({
    this.triggerStyle,
    this.popoverStyle,
    this.dialogStyle,
    this.calendarStyle,
    this.labelStyle,
    this.descriptionStyle,
    this.errorStyle,
    this.contentColor,
    this.descriptionColor,
    this.errorColor,
    this.disabledErrorColor,
    this.disabledDescriptionColor,
    this.labelBottomGapStyle,
    this.descriptionTopGapStyle,
    this.valueTypography,
    this.placeholderColor,
    this.trailingIconStyle,
    @Deprecated(
      'Use triggerStyle: CoreTextFieldStyle(errorBorderColor: …) '
      '(since 0.173).',
    )
    this.errorTriggerStyle,
  });

  /// Default popover style — field-trigger convention: the trigger
  /// fills the available inline axis instead of shrink-wrapping (each
  /// platform would otherwise settle on a different "natural" input
  /// width). Partial on purpose — the panel box flows through
  /// `Popup`'s own defaults; the per-instance [popoverStyle] merges on
  /// top. The trigger's own chrome is [triggerStyle], not
  /// `popoverStyle.triggerStyle` (a `CoreButtonStyle`, which a
  /// read-only `TextField` trigger does not read).
  static const CorePopoverStyle defaultPopoverStyle = CorePopoverStyle(
    triggerSizing: .expand,
  );

  /// Default trigger field slot — the trigger is a read-only `TextField`
  /// (the TimePicker / Select input look: height 40, corner 10, an
  /// `outline-variant` edge that turns `primary` on focus and `error` while
  /// the picker holds an error, a Regular 14 value and a trailing calendar),
  /// so the field's own `md` row supplies all of that and this default states
  /// only the one thing the picker diverges in — `stateLayer`: pressed only.
  /// Hover is the border stepping to `outline` and focus is the ring; a fill
  /// under either would say the same thing twice (the same decision
  /// `CoreSelectStyle.defaultTriggerStyle` and
  /// `CoreTimePickerStyle.defaultTriggerStyle` record). Raw-forwarded to the
  /// composed field.
  static const CoreTextFieldStyle defaultTriggerStyle = CoreTextFieldStyle(
    stateLayer: CoreStateLayer(
      hover: CoreOpacity.opacity0,
      focus: CoreOpacity.opacity0,
      pressed: CoreOpacity.pressed,
    ),
  );

  /// The earlier button trigger's chrome — the focus edge of an `outline`
  /// `Button`. It was `defaultTriggerStyle` until the trigger became a
  /// `TextField`, whose `triggerStyle` slot that name now pairs with.
  ///
  /// Not read: the field's own `md` row draws the `primary` focus edge.
  @Deprecated(
    'Not read — the trigger is a TextField; see defaultTriggerStyle '
    '(since 0.173).',
  )
  static const CoreButtonStyle defaultTriggerButtonStyle = CoreButtonStyle(
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// Default dialog style for the modal-mode picker. Empty on purpose —
  /// the picker states nothing about the modal surface, so every field
  /// comes from `Dialog`'s own defaults and the per-instance
  /// [dialogStyle] merges on top. Naming the (empty) partial is what
  /// keeps a future divergence a one-line edit here instead of a
  /// resolver reaching into `CoreDialogStyle.defaultX` field by field.
  static const CoreDialogStyle defaultDialogStyle = CoreDialogStyle();

  /// Default calendar style for the grid shown inline / in the popover /
  /// in the dialog. Empty for the same reason as [defaultDialogStyle] —
  /// the picker takes `Calendar`'s own chrome as-is.
  static const CoreCalendarStyle defaultCalendarStyle = CoreCalendarStyle();

  // ── Design-system defaults ───────────────────
  // Trigger/UI scheme + typography. Both Flutter and Web read these
  // constants. Colours flow as `CoreColor.token(...)` (Flutter resolves
  // via `scheme.resolve(...).toValue()`, Web emits `var(--coui-X)` via
  // `.toValue()`); typography flows as token-backed `CoreTextStyle.token`
  // so Flutter materialises through `.toValue(theme:)` and Web through
  // `emitTypography(...)` — a single canonical path on each platform.

  /// Trigger content text colour (active value).
  static const CoreColor defaultContentColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Trigger content text colour when no value selected (placeholder).
  static const CoreColor defaultPlaceholderColor = CoreColor.token(
    CoreColors.placeholder,
  );

  /// Default trailing (calendar) icon style — 16px, in the icon tone
  /// (`onSurfaceVariant`) rather than the placeholder text colour: the glyph
  /// is the control that opens the calendar, not a hint. Without a size the
  /// glyph falls back to the 24px `Icon` default and renders oversized for
  /// the trigger.
  static const CoreIconStyle defaultTrailingIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Trigger chrome while the picker holds an error — an `outline` button
  /// whose edge and focus ring turn `error`, the way a text field's error
  /// look does. The fill, the label colour and the hover / pressed wash
  /// stay the outline variant's own, so an invalid field reads as the same
  /// field with an error edge rather than as an action button.
  ///
  /// The trigger is a composed `Button`, which owns the fill, the wash and
  /// the disabled look; this states only what the error changes — the
  /// edge (idle and hovered; a pressed button takes the hover edge) and the
  /// focus ring. The per-instance [errorTriggerStyle] merges on top, and
  /// `popoverStyle.triggerStyle` (the chrome shared by every state) sits
  /// under both. The widgets hand this bundle to the button only while the
  /// picker is enabled: per-instance chrome outranks a variant's disabled
  /// colours, so a disabled picker takes the button's own disabled row.
  static const CoreButtonStyle defaultErrorTriggerStyle = CoreButtonStyle(
    borderColor: CoreColor.token(CoreColors.error),
    hoverBorderColor: CoreColor.token(CoreColors.error),
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// Description / helper text colour — `onSurfaceSubtle`, the same value
  /// [CoreTextFieldStyle.defaultDescriptionColor] states for the field's own
  /// description, so a picker's helper line reads like the field row it
  /// composes.
  static const CoreColor defaultDescriptionColor =
      CoreTextFieldStyle.defaultDescriptionColor;

  /// Error text colour.
  static const CoreColor defaultErrorColor = CoreColor.token(CoreColors.error);

  /// Error text colour while the picker is disabled — `disabledContent`, the
  /// same foreground the composed `outline` `Button` states for its disabled
  /// row. A disabled picker cannot be edited, so a live error colour would
  /// stress an error nobody can fix: disabled outranks the error.
  static const CoreColor defaultDisabledErrorColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Description text colour while the picker is disabled — `disabledContent`,
  /// the same foreground [defaultDisabledErrorColor] states: the helper line
  /// below a disabled field recedes with it instead of reading as live text.
  static const CoreColor defaultDisabledDescriptionColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Not read — the trigger is a `TextField`, whose own `md` row states the
  /// value as Regular 14 (`bodyMedium`). A per-instance [valueTypography]
  /// still reaches the field's `valueStyle` / `placeholderStyle`.
  ///
  /// This was `labelLarge`, the role the composed `Button` stated for its own
  /// label.
  @Deprecated(
    'Not read — the trigger TextField states its own value role '
    '(since 0.173).',
  )
  static const CoreTextStyle defaultValueTypography = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  /// Trigger label typography role — token-backed `labelLarge`.
  static const CoreTextStyle defaultLabelStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  /// Description helper text typography role — token-backed `bodyXs` (12),
  /// the same role `TextField`'s description / error text is written in
  /// (the trigger copies `TextField`'s shape, so its helper line matches).
  /// Split from the shared "helper" role so [descriptionStyle] and
  /// [errorStyle] each get an independent override entry point (both
  /// default to the same `bodyXs` role; only the colour differs).
  static const CoreTextStyle defaultDescriptionStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
  );

  /// Error helper text typography role — token-backed `bodyXs` (12), the
  /// role a field's helper text is written in (`TextField` / `TextArea`
  /// error text).
  static const CoreTextStyle defaultErrorStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
  );

  /// Popover dismiss debounce delay (ms). Both Flutter and Web read
  /// this token — Flutter via `Duration(milliseconds: ...)`, Web via
  /// `tailwindDuration` adapter.
  static const int defaultPopoverDismissDelayMs = CoreDuration.fast;

  /// Default nested [CoreGapStyle] slot — `CoreGapStyle(size: 6)` — for
  /// the vertical gap between the label row and the trigger row. The
  /// whole nested [CoreGapStyle] slot is forwarded to the `Gap` widget
  /// that separates the label and the trigger so the receiving `Gap`
  /// owns its own scaling (Epic #2228 4-principle). Per-instance override
  /// flows through [labelBottomGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultLabelBottomGapStyle = CoreGapStyle(
    size: CoreSpace.space6,
  );

  /// Vertical gap between trigger and description / error text.
  static const double defaultDescriptionTopGap = CoreSpace.space6;

  /// Default nested [CoreGapStyle] slot — `CoreGapStyle(size: 6)` — for
  /// the vertical gap between the trigger row and the description / error
  /// text row. The whole nested [CoreGapStyle] slot is forwarded to the
  /// `Gap` widget so the receiving `Gap` owns its own scaling
  /// (Epic #2228 4-principle). Per-instance override flows through
  /// [descriptionTopGapStyle] (merged on top of this default).
  static const CoreGapStyle defaultDescriptionTopGapStyle = CoreGapStyle(
    size: defaultDescriptionTopGap,
  );

  // ── Slot Styles (nested) ─────────────────────

  /// Look of the trigger — the read-only `TextField` the picker shows. Laid
  /// over [defaultTriggerStyle] and passed to the field as is. The value
  /// colour ([contentColor]), placeholder tone ([placeholderColor]), value
  /// role ([valueTypography]) and error border ([errorTriggerStyle]'s
  /// border colour) sit under it, so this style wins over them. The
  /// calendar glyph is styled by [trailingIconStyle] alone. An explicit
  /// `popoverStyle.triggerStyle` styled the earlier button trigger and is
  /// not read.
  final CoreTextFieldStyle? triggerStyle;

  /// Popover style for the popover-mode picker — the look of its dropdown
  /// (its trigger part is not read; see [triggerStyle]).
  final CorePopoverStyle? popoverStyle;

  /// Dialog style for the modal-mode picker — the look of its panel, title
  /// and action buttons.
  final CoreDialogStyle? dialogStyle;

  /// Override of the trigger button's look while the picker holds an
  /// error. Merged on top of [defaultErrorTriggerStyle]; only its
  /// `borderColor` is read now — it becomes the trigger field's
  /// `errorBorderColor`. `null` takes the default alone.
  @Deprecated(
    'Use triggerStyle: CoreTextFieldStyle(errorBorderColor: …) '
    '(since 0.173).',
  )
  final CoreButtonStyle? errorTriggerStyle;

  /// Calendar style applied to the inline / popover / dialog
  /// calendar grid. Drives nav buttons / date cells / arrow icons /
  /// state tokens.
  final CoreCalendarStyle? calendarStyle;

  /// Label text style (text shown above the trigger).
  final CoreTextStyle? labelStyle;

  /// Description / helper text style (text shown below the trigger
  /// when no error).
  final CoreTextStyle? descriptionStyle;

  /// Error text style.
  final CoreTextStyle? errorStyle;

  /// Trigger value text style override (the role applied to both the
  /// selected-value text and the placeholder text — colour still comes
  /// from [contentColor] / [defaultPlaceholderColor]). `null` leaves the
  /// role to the trigger field's own row.
  final CoreTextStyle? valueTypography;

  // ── Flat chrome overrides ────────────────────

  /// Trigger / label content text colour override. `null` defers to
  /// [defaultContentColor]. The Web label row and the trigger field's
  /// `valueStyle` both read this slot — for the trigger value **while
  /// enabled** (in error or not: an error changes the trigger's edge, see
  /// [defaultErrorTriggerStyle], not its label); a disabled value takes the
  /// field's own disabled foreground, which this style does not restate.
  final CoreColor? contentColor;

  /// Description / helper text colour override. `null` defers to
  /// [defaultDescriptionColor].
  final CoreColor? descriptionColor;

  /// Error text colour override. `null` defers to [defaultErrorColor].
  final CoreColor? errorColor;

  /// Error text colour override while the picker is disabled. `null` defers to
  /// [defaultDisabledErrorColor].
  final CoreColor? disabledErrorColor;

  /// Description text colour override while the picker is disabled. `null`
  /// defers to [defaultDisabledDescriptionColor]. [descriptionColor] colours
  /// the enabled picker only.
  final CoreColor? disabledDescriptionColor;

  /// Trigger placeholder (no value selected) text colour override.
  /// `null` defers to [defaultPlaceholderColor].
  final CoreColor? placeholderColor;

  /// Trigger trailing (calendar) icon style override. `null` defers to
  /// [defaultTrailingIconStyle].
  final CoreIconStyle? trailingIconStyle;

  /// Style of the vertical `Gap` between the label row and the trigger
  /// row. `null` defers to [defaultLabelBottomGapStyle].
  final CoreGapStyle? labelBottomGapStyle;

  /// Style of the vertical `Gap` between the trigger row and the
  /// description / error text row. `null` defers to
  /// [defaultDescriptionTopGapStyle].
  final CoreGapStyle? descriptionTopGapStyle;

  /// The trigger field's chrome — [defaultTriggerStyle] with the error
  /// edge, the value / placeholder colours and the [valueTypography] role
  /// folded in, then the per-instance [triggerStyle] on top. Raw-forwarded to
  /// the composed read-only `TextField`, which resolves and scales it. One
  /// function so both platforms fold identically.
  CoreTextFieldStyle get effectiveTriggerStyle => _foldTrigger(enabled: true);

  /// The same trigger chrome for a disabled picker — without the two text
  /// colours [effectiveTriggerStyle] folds in, so the field's own disabled tone
  /// applies (an explicit colour on `valueStyle` / `placeholderStyle` would win
  /// over it). A [valueTypography] the caller wrote still reaches the field,
  /// without a colour.
  CoreTextFieldStyle get effectiveDisabledTriggerStyle =>
      _foldTrigger(enabled: false);

  CoreTextFieldStyle _foldTrigger({required bool enabled}) {
    final role = valueTypography ?? const CoreTextStyle();
    return defaultTriggerStyle
        .merge(
          CoreTextFieldStyle(
            errorBorderColor: defaultErrorTriggerStyle
                .merge(errorTriggerStyle)
                .borderColor,
            valueStyle: enabled
                ? role.merge(
                    CoreTextStyle(color: contentColor ?? defaultContentColor),
                  )
                : valueTypography,
            placeholderStyle: enabled
                ? role.merge(
                    CoreTextStyle(
                      color: placeholderColor ?? defaultPlaceholderColor,
                    ),
                  )
                : valueTypography,
          ),
        )
        .merge(triggerStyle);
  }

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreDatePickerStyle merge(
    CoreDatePickerStyle? other,
  ) {
    if (other == null) return this;
    return CoreDatePickerStyle(
      triggerStyle: _mergeTextField(triggerStyle, other.triggerStyle),
      popoverStyle: _mergePopover(popoverStyle, other.popoverStyle),
      dialogStyle: _mergeDialog(dialogStyle, other.dialogStyle),
      calendarStyle: _mergeCalendar(calendarStyle, other.calendarStyle),
      labelStyle: _mergeText(labelStyle, other.labelStyle),
      descriptionStyle: _mergeText(descriptionStyle, other.descriptionStyle),
      errorStyle: _mergeText(errorStyle, other.errorStyle),
      contentColor: other.contentColor ?? contentColor,
      descriptionColor: other.descriptionColor ?? descriptionColor,
      errorColor: other.errorColor ?? errorColor,
      disabledErrorColor: other.disabledErrorColor ?? disabledErrorColor,
      disabledDescriptionColor:
          other.disabledDescriptionColor ?? disabledDescriptionColor,
      labelBottomGapStyle: _mergeGap(
        labelBottomGapStyle,
        other.labelBottomGapStyle,
      ),
      descriptionTopGapStyle: _mergeGap(
        descriptionTopGapStyle,
        other.descriptionTopGapStyle,
      ),
      valueTypography: _mergeText(valueTypography, other.valueTypography),
      placeholderColor: other.placeholderColor ?? placeholderColor,
      trailingIconStyle: _mergeIcon(
        trailingIconStyle,
        other.trailingIconStyle,
      ),
      errorTriggerStyle: _mergeButton(
        errorTriggerStyle,
        other.errorTriggerStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreDatePickerStyle copyWith({
    CoreTextFieldStyle? triggerStyle,
    CorePopoverStyle? popoverStyle,
    CoreDialogStyle? dialogStyle,
    CoreCalendarStyle? calendarStyle,
    CoreTextStyle? labelStyle,
    CoreTextStyle? descriptionStyle,
    CoreTextStyle? errorStyle,
    CoreColor? contentColor,
    CoreColor? descriptionColor,
    CoreColor? errorColor,
    CoreColor? disabledErrorColor,
    CoreColor? disabledDescriptionColor,
    CoreGapStyle? labelBottomGapStyle,
    CoreGapStyle? descriptionTopGapStyle,
    CoreTextStyle? valueTypography,
    CoreColor? placeholderColor,
    CoreIconStyle? trailingIconStyle,
    CoreButtonStyle? errorTriggerStyle,
  }) {
    return CoreDatePickerStyle(
      triggerStyle: triggerStyle ?? this.triggerStyle,
      popoverStyle: popoverStyle ?? this.popoverStyle,
      dialogStyle: dialogStyle ?? this.dialogStyle,
      calendarStyle: calendarStyle ?? this.calendarStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      contentColor: contentColor ?? this.contentColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      errorColor: errorColor ?? this.errorColor,
      disabledErrorColor: disabledErrorColor ?? this.disabledErrorColor,
      disabledDescriptionColor:
          disabledDescriptionColor ?? this.disabledDescriptionColor,
      labelBottomGapStyle: labelBottomGapStyle ?? this.labelBottomGapStyle,
      descriptionTopGapStyle:
          descriptionTopGapStyle ?? this.descriptionTopGapStyle,
      valueTypography: valueTypography ?? this.valueTypography,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
      errorTriggerStyle: errorTriggerStyle ?? this.errorTriggerStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDatePickerStyle &&
          runtimeType == other.runtimeType &&
          triggerStyle == other.triggerStyle &&
          popoverStyle == other.popoverStyle &&
          dialogStyle == other.dialogStyle &&
          calendarStyle == other.calendarStyle &&
          labelStyle == other.labelStyle &&
          descriptionStyle == other.descriptionStyle &&
          errorStyle == other.errorStyle &&
          contentColor == other.contentColor &&
          descriptionColor == other.descriptionColor &&
          errorColor == other.errorColor &&
          disabledErrorColor == other.disabledErrorColor &&
          disabledDescriptionColor == other.disabledDescriptionColor &&
          labelBottomGapStyle == other.labelBottomGapStyle &&
          descriptionTopGapStyle == other.descriptionTopGapStyle &&
          valueTypography == other.valueTypography &&
          placeholderColor == other.placeholderColor &&
          trailingIconStyle == other.trailingIconStyle &&
          errorTriggerStyle == other.errorTriggerStyle;

  @override
  int get hashCode => Object.hash(
    triggerStyle,
    popoverStyle,
    dialogStyle,
    calendarStyle,
    labelStyle,
    descriptionStyle,
    errorStyle,
    contentColor,
    descriptionColor,
    errorColor,
    disabledErrorColor,
    disabledDescriptionColor,
    labelBottomGapStyle,
    descriptionTopGapStyle,
    Object.hash(
      valueTypography,
      placeholderColor,
      trailingIconStyle,
      errorTriggerStyle,
    ),
  );

  static CorePopoverStyle? _mergePopover(
    CorePopoverStyle? base,
    CorePopoverStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreDialogStyle? _mergeDialog(
    CoreDialogStyle? base,
    CoreDialogStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreCalendarStyle? _mergeCalendar(
    CoreCalendarStyle? base,
    CoreCalendarStyle? other,
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

  static CoreTextFieldStyle? _mergeTextField(
    CoreTextFieldStyle? base,
    CoreTextFieldStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

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
}
