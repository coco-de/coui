/// Platform-independent contract for time picker components.
library;

import 'package:coui_core/src/component/contracts/date_picker/core_prompt_mode.dart';
import 'package:coui_core/src/component/contracts/popover/core_popover_placement.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';
import 'package:coui_core/src/component/contracts/time_picker/core_minute_interval.dart';
import 'package:coui_core/src/component/contracts/time_picker/time_picker_style.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a time picker component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [timePickerStyle] field — see [CoreTimePickerStyle]
/// for the merge chain. Behaviour fields (placeholder / enabled /
/// showSeconds / use24HourFormat / minuteInterval / min / max / onChanged /
/// mode / dialogTitle / errorText) stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreTimePickerContract<W> {
  /// Default placeholder segment shown for each unselected time field
  /// (hour / minute / second). String content, not visual chrome —
  /// shared by Flutter / Web widget const constructors so the
  /// trigger renders identically across platforms.
  static const String defaultPlaceholderSegment = '--';

  /// Default separator placed between adjacent placeholder segments.
  static const String defaultPlaceholderSeparator = ':';

  /// Size of the panel's am/pm `ToggleGroup` — `sm`: stacked along
  /// [defaultAmPmToggleDirection], its two 26 px segments make a 60 px track
  /// (`3 + 26 + 2 + 26 + 3`), the height of the hour / minute tiles beside
  /// it. Shared by Flutter and Web.
  static const CoreComponentSize defaultAmPmToggleSize = CoreComponentSize.sm;

  /// Direction of the panel's am/pm `ToggleGroup` — `vertical`: AM above
  /// PM, a column beside the hour / minute tiles and aligned to their top,
  /// so the panel stays as narrow as the tiles. Shared by Flutter and Web.
  static const CoreAxis defaultAmPmToggleDirection = CoreAxis.vertical;

  /// Default [minuteInterval] — one minute, so the minute segment steps by a
  /// minute and keeps whatever minute is typed into it.
  static const int defaultMinuteInterval = 1;

  /// Placeholder segment shown for each unselected time field
  /// (hour / minute / second).
  String get placeholderSegment;

  /// Separator placed between adjacent placeholder segments.
  String get placeholderSeparator;

  /// Current time value as an ISO string (`HH:MM` or `HH:MM:SS`).
  String? get value;

  /// Placeholder text shown when no time is selected.
  String? get placeholder;

  /// Whether the picker accepts user interaction.
  bool get enabled;

  /// Whether to include seconds in the picker.
  bool get showSeconds;

  /// Whether to use 24-hour format.
  bool? get use24HourFormat;

  /// The step of the minute segment, in minutes — a divisor of an hour
  /// (`1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60`); anything else is rejected
  /// in debug builds. [defaultMinuteInterval] (one minute) when not stated.
  ///
  /// With an interval of 15 the arrow keys move the minute `:00 → :15 → :30
  /// → :45 → :00`, and a minute typed into the segment snaps to the nearest
  /// multiple (`:07` to `:00`, `:08` to `:15`; a tie goes to the later one)
  /// when the segment loses focus and when the time is saved. The top of the
  /// hour wraps to `:00` **without carrying into the hour**: `:53` at 15
  /// minutes is `:00` of the same hour. [CoreMinuteInterval] holds that
  /// arithmetic for both platforms.
  ///
  /// It governs the minute segment only — the hour and second segments are
  /// unchanged — and it is not a bound: [min] and [max] stay declarations
  /// that the picker does not enforce.
  int get minuteInterval;

  /// Placement of the popover panel relative to the trigger
  /// (popover mode only). Defaults to bottom-start — the picker-family
  /// convention (panel's left edge lines up with the trigger's).
  CorePopoverPlacement get popoverPlacement;

  /// Minimum selectable time as ISO string.
  String? get min;

  /// Maximum selectable time as ISO string.
  String? get max;

  /// Called when the time value changes.
  void Function(String)? get onChanged;

  /// Render shape — anchored popover or centred modal dialog.
  CorePromptMode? get mode;

  /// Title widget rendered in the dialog header.
  W? get dialogTitle;

  /// Optional error message.
  String? get errorText;

  /// Per-instance time-picker style covering popover / dialog /
  /// segment input / am-pm button slot styles plus label /
  /// description / error text styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreTimePickerTheme.style
  ///   → parent component slot override
  ///   → widget.timePickerStyle
  /// ```
  CoreTimePickerStyle? get timePickerStyle;
}
