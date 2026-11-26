/// Platform-independent contract for date picker components.
library;

import 'package:coui_core/src/component/contracts/calendar/calendar_contract.dart';
import 'package:coui_core/src/component/contracts/date_picker/core_prompt_mode.dart';
import 'package:coui_core/src/component/contracts/date_picker/date_picker_style.dart';
import 'package:coui_core/src/component/contracts/popover/core_popover_placement.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a single-date picker component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [datePickerStyle] field — see [CoreDatePickerStyle]
/// for the merge chain. Behaviour fields (placeholder / enabled /
/// onChanged / min / max / label / description / errorText / mode /
/// dialogTitle) stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [ChangedCb] — value change callback type.
abstract interface class CoreDatePickerContract<W, ChangedCb> {
  /// Placeholder text displayed when no date is selected.
  String? get placeholder;

  /// Whether the date picker is enabled for user interaction.
  bool get enabled;

  /// Callback when the selected date changes.
  ///
  /// A null payload means the selection was cleared — tapping the
  /// selected day deselects it — and is reported, not swallowed, so a
  /// host that mirrors this value never drifts out of step with what
  /// the picker shows.
  ChangedCb get onChanged;

  /// Minimum selectable date.
  Object? get min;

  /// Maximum selectable date.
  Object? get max;

  /// Label text displayed above the date picker.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Description / helper text displayed below the date picker.
  String? get description;

  /// Error message — when non-null, error styling is applied.
  String? get errorText;

  /// Render shape — anchored popover or centred modal dialog.
  CorePromptMode? get mode;

  /// Placement of the popover panel relative to the trigger
  /// (popover mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  CorePopoverPlacement get popoverPlacement;

  /// The weekday the calendar's weeks start on — a [DateTime] weekday
  /// (`DateTime.monday`…`DateTime.sunday`), Sunday when not stated. Handed
  /// to the calendar the picker opens; see
  /// [CoreCalendarContract.firstDayOfWeek] for what it decides and why it is
  /// not derived from the locale.
  int get firstDayOfWeek;

  /// Title widget rendered in the dialog header.
  W? get dialogTitle;

  /// Per-instance date-picker style covering popover / dialog /
  /// calendar slot styles plus label / description / error text
  /// styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreDatePickerTheme.style
  ///   → parent component slot override
  ///   → widget.datePickerStyle
  /// ```
  CoreDatePickerStyle? get datePickerStyle;

  /// Custom placeholder widget shown when no date is selected — takes
  /// precedence over the [placeholder] string. Cross-platform
  /// (`Widget` on Flutter, `Component` on Web).
  W? get placeholderWidget;
}

/// Contract for a date-range picker component.
abstract interface class CoreDateRangePickerContract<W, ChangedCb> {
  /// Placeholder widget displayed when no range is selected.
  W? get placeholder;

  /// Whether the picker is enabled for user interaction.
  bool get enabled;

  /// Callback when the selected range changes.
  ChangedCb get onChanged;

  /// Minimum selectable date.
  Object? get min;

  /// Maximum selectable date.
  Object? get max;

  /// Label text displayed above the trigger.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Description text displayed below the trigger.
  String? get description;

  /// Error message — when non-null, error styling is applied.
  String? get errorText;

  /// Render shape — popover or dialog.
  CorePromptMode? get mode;

  /// Placement of the popover panel relative to the trigger
  /// (popover mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  CorePopoverPlacement get popoverPlacement;

  /// The weekday the calendar's weeks start on — a [DateTime] weekday
  /// (`DateTime.monday`…`DateTime.sunday`), Sunday when not stated. Handed
  /// to the calendar the picker opens; see
  /// [CoreCalendarContract.firstDayOfWeek].
  int get firstDayOfWeek;

  /// Title widget rendered in the dialog header.
  W? get dialogTitle;

  /// Per-instance date-range-picker style covering popover / dialog
  /// / calendar slot styles plus label / description / error text
  /// styles. Reuses [CoreDatePickerStyle] (single-date and range
  /// share chrome).
  CoreDatePickerStyle? get dateRangePickerStyle;
}
