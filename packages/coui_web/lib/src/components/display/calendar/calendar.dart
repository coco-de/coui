import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for date selection.
typedef DateSelectCallback = void Function(DateTime date);

/// A calendar component for date selection following shadcn-ui patterns.
///
/// Example:
/// ```dart
/// Calendar(
///   selectedDate: DateTime.now(),
///   onDateSelected: (date) => print('Selected: $date'),
/// )
/// ```
class Calendar extends UiComponent {
  /// Creates a Calendar component.
  ///
  /// Parameters:
  /// - [selectedDate]: Currently selected date
  /// - [onDateSelected]: Callback when date is selected
  /// - [minDate]: Minimum selectable date
  /// - [maxDate]: Maximum selectable date
  const Calendar({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.minDate,
    this.maxDate,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Currently selected date.
  final DateTime? selectedDate;

  /// Callback when date is selected.
  final DateSelectCallback? onDateSelected;

  /// Minimum selectable date.
  final DateTime? minDate;

  /// Maximum selectable date.
  final DateTime? maxDate;

  static const _divValue = 'div';

  static const _weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  static const _monthNames = [
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
    'December',
  ];

  @override
  Calendar copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    DateTime? selectedDate,
    DateSelectCallback? onDateSelected,
    DateTime? minDate,
    DateTime? maxDate,
    Key? key,
  }) {
    return Calendar(
      key: key ?? this.key,
      selectedDate: selectedDate ?? this.selectedDate,
      onDateSelected: onDateSelected ?? this.onDateSelected,
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final now = DateTime.now();
    final displayMonth = selectedDate ?? now;

    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'role': 'application',
        'aria-label': 'Calendar',
      },
      events: this.events,
      children: [
        // Header with month/year
        div(
          classes: 'flex items-center justify-between mb-4',
          children: [
            button(
              classes:
                  'inline-flex items-center justify-center rounded-md text-sm font-medium h-7 w-7 bg-transparent p-0 opacity-50 hover:opacity-100',
              attributes: {'type': 'button', 'aria-label': 'Previous month'},
              child: text('\u2039'),
            ),
            div(
              classes: 'text-sm font-medium',
              child: text(
                '${_monthNames[displayMonth.month - 1]} ${displayMonth.year}',
              ),
            ),
            button(
              classes:
                  'inline-flex items-center justify-center rounded-md text-sm font-medium h-7 w-7 bg-transparent p-0 opacity-50 hover:opacity-100',
              attributes: {'type': 'button', 'aria-label': 'Next month'},
              child: text('\u203A'),
            ),
          ],
        ),
        // Weekday headers
        div(
          classes: 'grid grid-cols-7 gap-1 mb-1',
          children: _weekDays
              .map(
                (day) => div(
                  classes:
                      'text-xs text-center font-medium text-muted-foreground py-2',
                  child: text(day),
                ),
              )
              .toList(),
        ),
        // Calendar grid
        div(
          classes: 'grid grid-cols-7 gap-1',
          children: _buildCalendarDays(displayMonth),
        ),
      ],
    );
  }

  @override
  String get baseClass => 'p-3 rounded-md border';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  List<Component> _buildCalendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startOffset = firstDay.weekday % 7;

    final days = <Component>[];

    // Empty cells before first day
    for (var i = 0; i < startOffset; i++) {
      days.add(div(classes: 'h-9 w-9'));
    }

    // Days of the month
    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected =
          selectedDate != null &&
          date.year == selectedDate!.year &&
          date.month == selectedDate!.month &&
          date.day == selectedDate!.day;

      days.add(
        button(
          classes: _buildDayClasses(isSelected),
          attributes: {
            'type': 'button',
            'aria-label': date.toIso8601String(),
            if (isSelected) 'aria-selected': 'true',
          },
          events: _buildDayEvents(date),
          child: text(day.toString()),
        ),
      );
    }

    return days;
  }

  String _buildDayClasses(bool isSelected) {
    const base =
        'inline-flex items-center justify-center rounded-md text-sm h-9 w-9 p-0 font-normal hover:bg-accent hover:text-accent-foreground';
    final state = isSelected ? 'bg-primary text-primary-foreground' : '';

    return '$base $state';
  }

  Map<String, List<dynamic>> _buildDayEvents(DateTime date) {
    final callback = onDateSelected;
    if (callback == null) {
      return {};
    }

    return {
      'click': [
        (event) => callback(date),
      ],
    };
  }
}
