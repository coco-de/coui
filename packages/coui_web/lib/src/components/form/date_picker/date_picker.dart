import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/form/date_picker/date_picker_style.dart';
import 'package:jaspr/jaspr.dart';

/// A date picker component for selecting dates.
///
/// The DatePicker component provides a calendar interface for date selection
/// with month and year navigation. It follows DaisyUI's modal patterns for
/// the calendar popup.
///
/// Features:
/// - Calendar grid with day selection
/// - Month and year navigation
/// - Min/max date constraints
/// - Today highlighting
/// - Disabled dates support
/// - Modal or inline display
///
/// Example:
/// ```dart
/// DatePicker(
///   selectedDate: DateTime.now(),
///   onDateChanged: (date) => handleDateSelection(date),
///   minDate: DateTime(2020, 1, 1),
///   maxDate: DateTime(2025, 12, 31),
/// )
/// ```
class DatePicker extends UiComponent {
  /// Creates a DatePicker component.
  ///
  /// - [selectedDate]: Currently selected date.
  /// - [onDateChanged]: Callback when date changes (Flutter-compatible).
  /// - [minDate]: Minimum selectable date.
  /// - [maxDate]: Maximum selectable date.
  /// - [displayedMonth]: Currently displayed month (DateTime with year/month).
  /// - [onMonthChanged]: Callback when displayed month changes.
  /// - [open]: Whether the date picker is open (for modal mode).
  /// - [style]: List of [DatePickerStyling] instances for styling.
  const DatePicker({
    super.attributes,
    super.child,
    super.classes,
    super.css,
    this.displayedMonth,
    super.id,
    super.key,
    this.maxDate,
    this.minDate,
    this.onDateChanged,
    this.onMonthChanged,
    this.open = true,
    this.selectedDate,
    List<DatePickerStyling>? style,
    super.tag = 'div',
  }) : super(null, style: style);

  /// Currently selected date.
  final DateTime? selectedDate;

  /// Callback when date changes.
  ///
  /// Flutter-compatible void Function(DateTime) callback.
  final void Function(DateTime)? onDateChanged;

  /// Minimum selectable date.
  final DateTime? minDate;

  /// Maximum selectable date.
  final DateTime? maxDate;

  /// Currently displayed month (DateTime with year/month).
  final DateTime? displayedMonth;

  /// Callback when displayed month changes.
  ///
  /// Flutter-compatible void Function(DateTime) callback.
  final void Function(DateTime)? onMonthChanged;

  /// Whether the date picker is open (for modal mode).
  final bool open;

  @override
  String get baseClass => 'card bg-base-100 shadow-xl';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set ARIA attributes for accessibility
    if (!userProvidedAttributes.containsKey('role')) {
      attributes.addRole('dialog');
    }

    if (!userProvidedAttributes.containsKey('aria-label')) {
      attributes.addAria('label', 'Date Picker');
    }
  }

  @override
  Component build(BuildContext context) {
    if (!open) {
      return Component.element(tag: 'div', children: []);
    }

    final styles = _buildStyleClasses();
    final currentMonth = displayedMonth ?? selectedDate ?? DateTime.now();
    final calendar = _buildCalendar(currentMonth);

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      id: id,
      tag: tag,
      children: [
        Component.element(
          classes: 'card-body',
          tag: 'div',
          children: [
            _buildHeader(currentMonth),
            calendar,
          ],
        ),
      ],
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add custom styles
    if (style != null) {
      for (final s in style!) {
        if (s is DatePickerStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  Component _buildHeader(DateTime month) {
    final monthYear = '${_getMonthName(month.month)} ${month.year}';

    return Component.element(
      classes: 'flex justify-between items-center mb-4',
      tag: 'div',
      children: [
        // Previous month button
        Component.element(
          classes: 'btn btn-sm btn-circle',
          events: onMonthChanged != null
              ? {
                  'click': (_) {
                    final previousMonth =
                        DateTime(month.year, month.month - 1, 1);
                    onMonthChanged!(previousMonth);
                  },
                }
              : null,
          tag: 'button',
          children: [Component.text('‹')],
        ),
        // Month and year display
        Component.element(
          classes: 'text-lg font-semibold',
          tag: 'div',
          children: [Component.text(monthYear)],
        ),
        // Next month button
        Component.element(
          classes: 'btn btn-sm btn-circle',
          events: onMonthChanged != null
              ? {
                  'click': (_) {
                    final nextMonth = DateTime(month.year, month.month + 1, 1);
                    onMonthChanged!(nextMonth);
                  },
                }
              : null,
          tag: 'button',
          children: [Component.text('›')],
        ),
      ],
    );
  }

  Component _buildCalendar(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final calendarDays = <Component>[];

    // Weekday headers
    final weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    for (final day in weekdays) {
      calendarDays.add(
        Component.element(
          classes: 'text-center font-semibold text-sm py-2',
          tag: 'div',
          children: [Component.text(day)],
        ),
      );
    }

    // Empty cells before first day
    for (var i = 0; i < firstWeekday; i++) {
      calendarDays.add(
        Component.element(
          tag: 'div',
        ),
      );
    }

    // Days of the month
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = selectedDate != null &&
          date.year == selectedDate!.year &&
          date.month == selectedDate!.month &&
          date.day == selectedDate!.day;
      final isToday = _isToday(date);
      final isDisabled = _isDateDisabled(date);

      calendarDays.add(_buildDayCell(date, isSelected, isToday, isDisabled));
    }

    return Component.element(
      classes: 'grid grid-cols-7 gap-1',
      tag: 'div',
      children: calendarDays,
    );
  }

  Component _buildDayCell(
      DateTime date, bool isSelected, bool isToday, bool isDisabled) {
    final classes = [
      'btn',
      'btn-sm',
      'btn-square',
      if (isSelected) 'btn-primary',
      if (isToday && !isSelected) 'btn-outline',
      if (isDisabled) 'btn-disabled',
    ].join(' ');

    return Component.element(
      classes: classes,
      events: !isDisabled && onDateChanged != null
          ? {
              'click': (_) => onDateChanged!(date),
            }
          : null,
      tag: 'button',
      children: [Component.text(date.day.toString())],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isDateDisabled(DateTime date) {
    if (minDate != null && date.isBefore(minDate!)) {
      return true;
    }
    if (maxDate != null && date.isAfter(maxDate!)) {
      return true;
    }
    return false;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  @override
  DatePicker copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    DateTime? displayedMonth,
    String? id,
    Key? key,
    DateTime? maxDate,
    DateTime? minDate,
    void Function(DateTime)? onDateChanged,
    void Function(DateTime)? onMonthChanged,
    bool? open,
    DateTime? selectedDate,
    List<DatePickerStyling>? style,
    String? tag,
  }) {
    return DatePicker(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      displayedMonth: displayedMonth ?? this.displayedMonth,
      id: id ?? this.id,
      key: key ?? this.key,
      maxDate: maxDate ?? this.maxDate,
      minDate: minDate ?? this.minDate,
      onDateChanged: onDateChanged ?? this.onDateChanged,
      onMonthChanged: onMonthChanged ?? this.onMonthChanged,
      open: open ?? this.open,
      selectedDate: selectedDate ?? this.selectedDate,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<DatePickerStyling>?
                ? currentStyle
                : null;
          }(),
      tag: tag ?? this.tag,
    );
  }
}