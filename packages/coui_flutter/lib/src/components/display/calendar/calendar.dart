import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform calendar with full selection support.
///
/// Supports single, range, and multi-date selection modes,
/// month/year navigation, and customizable date state validation.
///
/// Implements [CoreCalendarContract] for cross-platform API consistency.
///
/// Per Epic #1302 / #1696 every chrome / dimensional / nested-slot
/// override flows through the single [calendarStyle] (a
/// [CoreCalendarStyle]) so the merge chain is:
///
/// ```text
/// design system default
///   → CoreCalendarTheme.style                         // 프로젝트 공통
///   → parent component slot override
///       (e.g. CoreDatePickerStyle.calendarStyle)
///   → widget.calendarStyle                            // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Calendar(
///   selectionMode: CoreCalendarSelectionMode.single,
///   calendarStyle: CoreCalendarStyle(
///     selectedColor: CoreColor.token(CoreColors.success),
///     dateCellStyle: CoreButtonStyle(
///       labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
///     ),
///   ),
///   onChanged: (value) => print('Selected: $value'),
/// )
/// ```
class Calendar extends StatefulWidget implements CoreCalendarContract<Widget> {
  /// Creates a [Calendar].
  const Calendar({
    super.key,
    this.selectionMode = CoreCalendarSelectionMode.single,
    this.onChanged,
    this.value,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.minDate,
    this.maxDate,
    this.markerBuilder,
    this.calendarStyle,
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  /// Creates a single-selection calendar.
  const Calendar.single({
    super.key,
    this.onChanged,
    this.value,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.minDate,
    this.maxDate,
    this.markerBuilder,
    this.calendarStyle,
  }) : selectionMode = CoreCalendarSelectionMode.single,
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  /// Creates a range-selection calendar.
  const Calendar.range({
    super.key,
    this.onChanged,
    this.value,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.minDate,
    this.maxDate,
    this.markerBuilder,
    this.calendarStyle,
  }) : selectionMode = CoreCalendarSelectionMode.range,
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  /// Creates a multi-selection calendar.
  const Calendar.multi({
    super.key,
    this.onChanged,
    this.value,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.minDate,
    this.maxDate,
    this.markerBuilder,
    this.calendarStyle,
  }) : selectionMode = CoreCalendarSelectionMode.multi,
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  @override
  final CoreCalendarSelectionMode selectionMode;

  @override
  final ValueChanged<CoreCalendarValue?>? onChanged;

  @override
  final CoreCalendarDateStateBuilder? stateBuilder;

  @override
  final DateTime? minDate;

  @override
  final DateTime? maxDate;

  @override
  final CoreCalendarMarkerBuilder? markerBuilder;

  @override
  final CoreCalendarValue? value;

  @override
  final CoreCalendarView? initialView;

  @override
  final int firstDayOfWeek;

  @override
  final CoreCalendarStyle? calendarStyle;

  /// Returns a copy of this [Calendar] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Calendar copyWith({
    Key? key,
    ValueChanged<CoreCalendarValue?>? onChanged,
    CoreCalendarSelectionMode? selectionMode,
    CoreCalendarValue? value,
    CoreCalendarView? initialView,
    int? firstDayOfWeek,
    CoreCalendarDateStateBuilder? stateBuilder,
    DateTime? minDate,
    DateTime? maxDate,
    CoreCalendarMarkerBuilder? markerBuilder,
    CoreCalendarStyle? calendarStyle,
  }) {
    return Calendar(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      selectionMode: selectionMode ?? this.selectionMode,
      value: value ?? this.value,
      initialView: initialView ?? this.initialView,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      stateBuilder: stateBuilder ?? this.stateBuilder,
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
      markerBuilder: markerBuilder ?? this.markerBuilder,
      calendarStyle: calendarStyle ?? this.calendarStyle,
    );
  }

  @override
  State<Calendar> createState() => _CalendarState();
}

/// Chain sugar for merging a [CoreCalendarStyle] patch into
/// [Calendar.calendarStyle] without hand-reconstructing every field.
/// Mirrors the Web `Calendar.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreCalendarStyle.merge` right-side-wins semantics).
extension CalendarStyleChain on Calendar {
  /// Returns a copy of this [Calendar] with [patch] merged into
  /// [calendarStyle] (patch fields win on conflict).
  Calendar withStyle(CoreCalendarStyle patch) => copyWith(
    calendarStyle: (calendarStyle ?? const CoreCalendarStyle()).merge(patch),
  );
}

class _CalendarState extends State<Calendar> {
  late CoreCalendarView _view;
  late CoreCalendarView _alternateView;
  late CoreCalendarViewType _viewType;
  late int _yearSelectStart;

  CoreCalendarValue? _value;

  // ── Header text ──

  static String _getHeaderText(
    CoUILocalizations localizations,
    CoreCalendarView view,
    CoreCalendarViewType viewType,
  ) {
    if (viewType == .date) {
      return localizations.formatMonthYear(view.month, view.year);
    }
    return viewType == .month
        ? '${view.year}'
        : localizations.datePickerSelectYear;
  }

  @override
  void initState() {
    super.initState();
    final wv = widget.value;
    _view =
        widget.initialView ??
        (wv != null
            ? CoreCalendarView(wv.viewYear, wv.viewMonth)
            : CoreCalendarView.now());
    _alternateView = _view.next;
    _value = widget.value;
    _viewType = .date;
    _yearSelectStart =
        (_view.year ~/ CoreCalendarStyle.defaultYearGridSize) *
        CoreCalendarStyle.defaultYearGridSize;
  }

  CoreCalendarDateState _resolveState(DateTime date) {
    final sb = widget.stateBuilder;
    if (sb != null) return sb(date);
    final min = widget.minDate;
    if (min != null && date.isBefore(DateTime(min.year, min.month, min.day))) {
      return .disabled;
    }
    final max = widget.maxDate;
    if (max != null && date.isAfter(DateTime(max.year, max.month, max.day))) {
      return .disabled;
    }
    return .enabled;
  }

  DateState _toCoreState(CoreCalendarDateState s) =>
      s == .enabled ? .enabled : .disabled;

  // ── View navigation ──

  void _handleViewNavigation({
    required bool forward,
    required int yearGridSize,
  }) {
    setState(() {
      switch (_viewType) {
        case .date:
          if (forward) {
            _view = _view.next;
            if (_isRange) _alternateView = _alternateView.next;
          } else {
            _view = _view.previous;
            if (_isRange) _alternateView = _alternateView.previous;
          }
        case .month:
          _view = forward ? _view.nextYear : _view.previousYear;
        case .year:
          _yearSelectStart += forward ? yearGridSize : -yearGridSize;
      }
    });
  }

  void _handleHeaderTap() {
    switch (_viewType) {
      case .date:
        setState(() => _viewType = .month);
      case .month:
        setState(() => _viewType = .year);
      case .year:
        break;
    }
  }

  void _handleViewChanged(CoreCalendarView value) {
    setState(() {
      _view = value;
      _alternateView = value.next;
      switch (_viewType) {
        case .date:
          break;
        case .month:
          _viewType = .date;
        case .year:
          _viewType = .month;
      }
    });
  }

  // ── Date tap handling ──

  void _handleDateTap(DateTime date) {
    var calendarValue = _value;

    if (widget.selectionMode == .none) {
      return;
    }

    if (widget.selectionMode == .single) {
      if (calendarValue is CoreSingleCalendarValue &&
          date.isAtSameMomentAs(calendarValue.date)) {
        _emitValue(null);
        return;
      }
      _emitValue(CoreCalendarValue.single(date));
      return;
    }

    if (widget.selectionMode == .multi) {
      if (calendarValue == null) {
        _emitValue(CoreCalendarValue.single(date));
        return;
      }
      final lookup = calendarValue.lookup(date.year, date.month, date.day);
      if (lookup == .none) {
        final multi = calendarValue.toMulti();
        final updatedDates = [...multi.dates, date];
        final updatedMulti = CoreMultiCalendarValue(updatedDates);
        _emitValue(updatedMulti);
        return;
      }
      final multi = calendarValue.toMulti();
      final updatedDates = multi.dates.where((d) => d != date).toList();
      if (updatedDates.isEmpty) {
        _emitValue(null);
        return;
      }
      final updatedMulti = CoreMultiCalendarValue(updatedDates);
      _emitValue(updatedMulti);
      return;
    }

    if (widget.selectionMode == .range) {
      if (calendarValue == null) {
        _emitValue(CoreCalendarValue.single(date));
        return;
      }
      if (calendarValue is CoreMultiCalendarValue) {
        calendarValue = calendarValue.toRange();
      }
      if (calendarValue is CoreSingleCalendarValue) {
        final selectedDate = calendarValue.date;
        if (date.isAtSameMomentAs(selectedDate)) {
          _emitValue(null);
          return;
        }
        _emitValue(CoreCalendarValue.range(selectedDate, date));
        return;
      }
      if (calendarValue is CoreRangeCalendarValue) {
        _emitValue(CoreCalendarValue.single(date));
      }
    }
  }

  void _emitValue(CoreCalendarValue? value) {
    setState(() {
      _value = value;
      widget.onChanged?.call(value);
    });
  }

  Widget _buildSingleLayout(
    BuildContext context,
    ThemeData theme,
    CoUILocalizations localizations,
    ResolvedCalendar resolved,
  ) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          _buildHeader(
            theme: theme,
            localizations: localizations,
            resolved: resolved,
            view: _view,
          ),
          Gap(gapStyle: resolved.headerGridGapStyle),
          _buildViewContent(
            context: context,
            view: _view,
            resolved: resolved,
            onViewChanged: _handleViewChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRangeLayout(
    BuildContext context,
    ThemeData theme,
    CoUILocalizations localizations,
    ResolvedCalendar resolved,
  ) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Row(
            mainAxisSize: .min,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    _buildNavButton(
                      onPressed: () => _handleViewNavigation(
                        forward: false,
                        yearGridSize: resolved.yearGridSize,
                      ),
                      resolved: resolved,
                      theme: theme,
                      forward: false,
                    ),
                    Gap(gapStyle: resolved.headerGridGapStyle),
                    Expanded(
                      child: _buildHeaderButton(
                        onTap: _handleHeaderTap,
                        theme: theme,
                        localizations: localizations,
                        resolved: resolved,
                        view: _view,
                      ),
                    ),
                    if (_viewType == .date)
                      SizedBox(width: resolved.dayCellSize),
                    Gap(gapStyle: resolved.headerGridGapStyle),
                    if (_viewType != .date)
                      _buildNavButton(
                        onPressed: () => _handleViewNavigation(
                          forward: true,
                          yearGridSize: resolved.yearGridSize,
                        ),
                        resolved: resolved,
                        theme: theme,
                        forward: true,
                      ),
                  ],
                ),
              ),
              if (_viewType == .date)
                Gap(gapStyle: resolved.headerGridGapStyle),
              if (_viewType == .date)
                Expanded(
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      SizedBox(
                        width: resolved.dayCellSize + resolved.headerGridGap,
                      ),
                      Expanded(
                        child: _buildHeaderButton(
                          onTap: _handleHeaderTap,
                          theme: theme,
                          localizations: localizations,
                          resolved: resolved,
                          view: _alternateView,
                        ),
                      ),
                      Gap(gapStyle: resolved.headerGridGapStyle),
                      _buildNavButton(
                        onPressed: () => _handleViewNavigation(
                          forward: true,
                          yearGridSize: resolved.yearGridSize,
                        ),
                        resolved: resolved,
                        theme: theme,
                        forward: true,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Gap(gapStyle: resolved.headerGridGapStyle),
          Row(
            mainAxisAlignment: .spaceAround,
            crossAxisAlignment: .start,
            children: [
              _buildViewContent(
                context: context,
                view: _view,
                resolved: resolved,
                onViewChanged: _handleViewChanged,
              ),
              if (_viewType == .date)
                Gap(gapStyle: resolved.headerGridGapStyle),
              if (_viewType == .date)
                _buildViewContent(
                  context: context,
                  view: _alternateView,
                  resolved: resolved,
                  onViewChanged: (v) {},
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required ThemeData theme,
    required CoUILocalizations localizations,
    required ResolvedCalendar resolved,
    required CoreCalendarView view,
  }) {
    return Row(
      children: [
        _buildNavButton(
          onPressed: () => _handleViewNavigation(
            forward: false,
            yearGridSize: resolved.yearGridSize,
          ),
          resolved: resolved,
          theme: theme,
          forward: false,
        ),
        Gap(gapStyle: resolved.headerGridGapStyle),
        Expanded(
          child: _buildHeaderButton(
            onTap: _handleHeaderTap,
            theme: theme,
            localizations: localizations,
            resolved: resolved,
            view: view,
          ),
        ),
        Gap(gapStyle: resolved.headerGridGapStyle),
        _buildNavButton(
          onPressed: () => _handleViewNavigation(
            forward: true,
            yearGridSize: resolved.yearGridSize,
          ),
          resolved: resolved,
          theme: theme,
          forward: true,
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required ResolvedCalendar resolved,
    required ThemeData theme,
    required bool forward,
    required VoidCallback onPressed,
  }) {
    final localizations = CoUILocalizations.of(context);
    return Semantics(
      label: forward
          ? localizations.calendarNextPeriod
          : localizations.calendarPreviousPeriod,
      child: Button(
        onPressed: onPressed,
        variant: .ghost,
        size: .sm,
        buttonStyle: resolved.navButtonStyle,
        child: Icon(
          forward ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
          iconStyle: resolved.arrowIconStyle,
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required ThemeData theme,
    required CoUILocalizations localizations,
    required ResolvedCalendar resolved,
    required CoreCalendarView view,
    required VoidCallback onTap,
  }) {
    return Button(
      onPressed: onTap,
      variant: .ghost,
      size: .sm,
      enabled: _viewType != .year,
      buttonStyle: resolved.headerButtonStyle,
      alignment: .center,
      child: DefaultTextStyle.merge(
        style: resolved.headerLabelTextStyle,
        // A month name plus a year, in whatever the locale spells them,
        // inside a button the header row sizes. The component cannot
        // promise that fits — what it can do is say what happens when it
        // does not, the same as the weekday cell below. Left undeclared
        // this clipped, which throws nothing and looks like a short
        // month: `September` is the longest English month at nine
        // letters, so the gap was invisible for eleven months a year.
        child: Text(
          _getHeaderText(localizations, view, _viewType),
          overflow: .ellipsis,
        ),
      ),
    );
  }

  Widget _buildViewContent({
    required BuildContext context,
    required CoreCalendarView view,
    required ResolvedCalendar resolved,
    required ValueChanged<CoreCalendarView> onViewChanged,
  }) {
    DateState dateStateFor(DateTime date) => _toCoreState(_resolveState(date));
    if (_viewType == .year) {
      return _YearGrid(
        onChanged: (year) {
          setState(() {
            _handleViewChanged(view.copyWith(year: () => year));
          });
        },
        yearSelectStart: _yearSelectStart,
        calendarValue: _value,
        stateBuilder: dateStateFor,
        resolved: resolved,
      );
    }

    if (_viewType == .month) {
      return _MonthGrid(
        onChanged: onViewChanged,
        value: view,
        calendarValue: _value,
        stateBuilder: dateStateFor,
        resolved: resolved,
      );
    }

    final stateBuilder = _resolveState;
    return _DateGrid(
      view: view,
      firstDayOfWeek: widget.firstDayOfWeek,
      calendarValue: _value,
      resolved: resolved,
      stateBuilder: stateBuilder,
      onDateTap: _handleDateTap,
      markerBuilder: widget.markerBuilder,
      calendarStyle: widget.calendarStyle,
    );
  }

  @override
  void didUpdateWidget(covariant Calendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  bool get _isRange => widget.selectionMode == .range;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = CoUILocalizations.of(context);
    final resolved = resolveCalendar(
      context,
      calendarStyle: widget.calendarStyle,
    );

    // Both layouts, not just one. The range layout returned above this
    // wrapper, so a two-month range calendar reached a screen reader as
    // an unnamed pile of buttons — while the comment claimed parity with
    // the Web twin, which labels both.
    return Semantics(
      container: true,
      label: localizations.calendarLabel,
      child: _isRange
          ? _buildRangeLayout(context, theme, localizations, resolved)
          : _buildSingleLayout(context, theme, localizations, resolved),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// _DateGrid — direct date grid rendering using CoreCalendarGridData
// ══════════════════════════════════════════════════════════════════════

class _DateGrid extends StatelessWidget {
  const _DateGrid({
    required this.view,
    required this.firstDayOfWeek,
    required this.calendarValue,
    required this.resolved,
    required this.stateBuilder,
    required this.onDateTap,
    required this.markerBuilder,
    required this.calendarStyle,
  });

  final CoreCalendarView view;
  final int firstDayOfWeek;
  final CoreCalendarValue? calendarValue;
  final ResolvedCalendar resolved;
  final CoreCalendarDateState Function(DateTime) stateBuilder;
  final ValueChanged<DateTime> onDateTap;
  final CoreCalendarMarkerBuilder? markerBuilder;
  final CoreCalendarStyle? calendarStyle;

  Widget _buildDayCell({
    required BuildContext context,
    required CoreCalendarGridItem item,
    required DateTime now,
    required double itemSize,
  }) {
    final date = item.date;
    final state = stateBuilder(date);
    final isEnabled = state == .enabled;

    final lookup =
        calendarValue?.lookup(date.year, date.month, date.day) ?? .none;

    var type = _DayCellType.none;
    switch (lookup) {
      case .none:
        if (now.year == date.year &&
            now.month == date.month &&
            now.day == date.day) {
          type = .today;
        }
      case .selected:
        type = .selected;
      case .start:
        type = .startRangeSelected;
      case .end:
        type = .endRangeSelected;
      case .inRange:
        type = .inRange;
    }

    if (item.indexInRow == 0 && type == .endRangeSelected) {
      type = .selected;
    }
    if (item.indexInRow == CoreCalendarGridData.daysPerWeek - 1 &&
        type == .startRangeSelected) {
      type = .selected;
    }

    // A `Button` cell takes its label typography from its own `labelStyle`
    // (the cell / state slots the resolver bakes into each cell style), so
    // its child is the bare number. Only the hand-drawn range band — not a
    // `Button` — wraps the number in the cell typography itself.
    final dayLabel = Text('${date.day}');
    final dayText = DefaultTextStyle.merge(
      style: resolved.cellLabelTextStyle,
      child: dayLabel,
    );
    void handleTap() => onDateTap(date);

    Widget cell;
    switch (type) {
      case .none:
        cell = Button(
          onPressed: handleTap,
          variant: .ghost,
          size: .sm,
          enabled: isEnabled,
          buttonStyle: resolved.dateCellNormalStyle,
          alignment: .center,
          child: dayLabel,
        );

      case .today:
        final todayTextColor = resolved.todayTextColor;
        final todayChild = todayTextColor != null
            ? DefaultTextStyle.merge(
                style: TextStyle(color: todayTextColor),
                child: dayLabel,
              )
            : dayLabel;
        cell = Button(
          onPressed: handleTap,
          variant: .ghost,
          size: .sm,
          enabled: isEnabled,
          buttonStyle: resolved.dateCellTodayStyle,
          alignment: .center,
          child: todayChild,
        );

      case .selected:
        cell = Button(
          onPressed: handleTap,
          size: .sm,
          enabled: isEnabled,
          buttonStyle: resolved.dateCellSelectedStyle,
          alignment: .center,
          child: dayLabel,
        );

      case .inRange:
        // `Clickable`, not `GestureDetector`. Every other date in this
        // grid composes `Button`; this one draws a flat band so the
        // range reads as continuous, and it was left as a bare gesture —
        // so a keyboard user could pick a range start and then had no
        // way to reach any date inside it. The selection could be begun
        // and not finished.
        cell = Clickable(
          onPressed: isEnabled ? handleTap : null,
          // `enabled` as well as the handler. `Clickable.enabled`
          // defaults to true, so passing only a null handler leaves a
          // disabled date announcing as an ordinary button that does
          // nothing when activated — the worst of the three states to be
          // in, because it is the one that lies.
          enabled: isEnabled,
          child: Container(
            alignment: .center,
            decoration: BoxDecoration(
              color: resolved.rangeSelectionColor,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: resolved.rangeSelectionTextColor),
              child: dayText,
            ),
          ),
        );

      case .startRangeSelected:
        cell = Stacks(
          fit: .passthrough,
          clipBehavior: .none,
          children: [
            Position.fill(
              left: itemSize / 2,
              child: Container(
                decoration: BoxDecoration(
                  color: resolved.rangeSelectionColor,
                ),
              ),
            ),
            Button(
              onPressed: handleTap,
              size: .sm,
              enabled: isEnabled,
              buttonStyle: resolved.dateCellSelectedStyle,
              alignment: .center,
              disableHoverEffect: true,
              child: dayLabel,
            ),
          ],
        );

      case .endRangeSelected:
        cell = Stacks(
          fit: .passthrough,
          clipBehavior: .none,
          children: [
            Position.fill(
              right: itemSize / 2,
              child: Container(
                decoration: BoxDecoration(
                  color: resolved.rangeSelectionColor,
                ),
              ),
            ),
            Button(
              onPressed: handleTap,
              size: .sm,
              enabled: isEnabled,
              buttonStyle: resolved.dateCellSelectedStyle,
              alignment: .center,
              disableHoverEffect: true,
              child: dayLabel,
            ),
          ],
        );
    }

    final marker = markerBuilder?.call(date);
    if (marker != null) {
      cell = _MarkedCell(
        marker: marker,
        lookup: switch (type) {
          .selected ||
          .startRangeSelected ||
          .endRangeSelected => CoreCalendarValueLookup.selected,
          .inRange => CoreCalendarValueLookup.inRange,
          .none || .today => CoreCalendarValueLookup.none,
        },
        calendarStyle: calendarStyle,
        child: cell,
      );
    }

    if (item.fromAnotherMonth) {
      return Opacity(opacity: resolved.fadedOpacity, child: cell);
    }
    return cell;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final gridData = CoreCalendarGridData(
      month: view.month,
      year: view.year,
      firstDayOfWeek: firstDayOfWeek,
    );
    final now = CoreCalendarView.currentTime();
    final itemSize = resolved.dayCellSize;

    final rows = <Widget>[];

    final weekDays = <Widget>[];
    // The header is the Core order for the same week start the grid was laid
    // out with — a header drawn from anything else would head the wrong
    // columns.
    for (final weekday in CoreCalendarGridData.weekdayOrder(firstDayOfWeek)) {
      weekDays.add(
        // `container: true` forces a distinct semantics-tree boundary per
        // header cell, matching the Web twin's `role="columnheader"` — see
        // `table_layout_render.dart`'s cell wrapping for the same pattern.
        CoUISemantics(
          role: .columnHeader,
          container: true,
          child: Container(
            alignment: Alignment.center,
            width: itemSize,
            height: itemSize,
            // The cell is a fixed square and the label comes from the
            // locale, so the component cannot know it will fit. Saying
            // what happens when it does not is the part that was missing:
            // the default is a silent clip, which cuts a glyph in half and
            // reports nothing. The Web twin carries `truncate` for the
            // same reason, so both platforms now fail the same way.
            child: Text(
              localizations.getAbbreviatedWeekday(weekday),
              overflow: .ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      );
    }
    final weekdayRow = DefaultTextStyle.merge(
      style: resolved.weekdayLabelTextStyle,
      child: CoUISemantics(
        role: .row,
        container: true,
        child: Row(
          mainAxisAlignment: .center,
          children: weekDays,
        ),
      ),
    );
    rows.add(weekdayRow);

    for (
      var i = 0;
      i < gridData.items.length;
      i += CoreCalendarGridData.daysPerWeek
    ) {
      final rowItems = gridData.items.sublist(
        i,
        i + CoreCalendarGridData.daysPerWeek,
      );
      rows.add(
        CoUISemantics(
          role: .row,
          container: true,
          child: Row(
            mainAxisAlignment: .center,
            children: rowItems.map((item) {
              // `role: .gridCell` on the wrapper, not the day `Button`
              // itself — an element only carries one semantics role, so
              // the button's own button-role semantics nest one level
              // inside this one (mirrors the Web twin's `role="gridcell"`
              // wrapper).
              return CoUISemantics(
                role: .gridCell,
                container: true,
                child: SizedBox.square(
                  dimension: itemSize,
                  child: _buildDayCell(
                    context: context,
                    item: item,
                    now: now,
                    itemSize: itemSize,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return CoUISemantics(
      role: .grid,
      container: true,
      child: Column(
        mainAxisSize: .min,
        spacing: resolved.cellSpacing,
        children: rows,
      ),
    );
  }
}

/// A day cell with its marker dots drawn under the number.
///
/// The dots overlay the cell instead of joining its layout, so a marked day
/// keeps the exact square every other day has and the grid does not shift
/// when markers come and go. They ignore the pointer, so a tap on a dot still
/// lands on the date beneath it.
///
/// `MergeSemantics` folds the marker's label into the date's own node — the
/// cell reads as "15, 2 items, button" rather than as a button followed by a
/// stray label. The dots themselves are excluded: the label already says
/// what they show.
class _MarkedCell extends StatelessWidget {
  const _MarkedCell({
    required this.marker,
    required this.lookup,
    required this.calendarStyle,
    required this.child,
  });

  final CoreCalendarMarker marker;
  final CoreCalendarValueLookup lookup;
  final CoreCalendarStyle? calendarStyle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCalendarMarker(
      context,
      marker: marker,
      lookup: lookup,
      calendarStyle: calendarStyle,
    );
    final label =
        marker.semanticsLabel ??
        CoUILocalizations.of(context).calendarMarkerCount(marker.count);

    return MergeSemantics(
      child: Stacks(
        fit: .passthrough,
        clipBehavior: .none,
        children: [
          child,
          Position.fill(
            child: IgnorePointer(
              child: Semantics(
                label: label,
                child: ExcludeSemantics(
                  child: Align(
                    alignment: .bottomCenter,
                    child: Padding(
                      padding: resolved.padding,
                      child: Row(
                        mainAxisSize: .min,
                        spacing: resolved.dotSpacing,
                        children: [
                          for (var i = 0; i < resolved.dotCount; i += 1)
                            SizedBox.square(
                              dimension: resolved.dotSize,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: resolved.dotColor,
                                  borderRadius: resolved.dotBorderRadius,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal cell type for direct date grid rendering.
enum _DayCellType {
  none,
  today,
  selected,
  inRange,
  startRangeSelected,
  endRangeSelected,
}

// ══════════════════════════════════════════════════════════════════════
// _MonthGrid / _YearGrid
// ══════════════════════════════════════════════════════════════════════

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.value,
    required this.calendarValue,
    required this.stateBuilder,
    required this.onChanged,
    required this.resolved,
  });

  final CoreCalendarView value;
  final CoreCalendarValue? calendarValue;
  final DateStateBuilder? stateBuilder;
  final ValueChanged<CoreCalendarView> onChanged;
  final ResolvedCalendar resolved;

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);
    final rows = <Widget>[];
    final months = <Widget>[];

    for (
      var i = CoreCalendarGridData.firstMonth;
      i <= CoreCalendarGridData.lastMonth;
      i += 1
    ) {
      final date = DateTime(value.year, i);
      final cv = calendarValue;
      final lookup = cv?.lookup(date.year, date.month) ?? .none;
      final isSelected =
          lookup == .selected || lookup == .start || lookup == .end;
      final isInRange = lookup == .inRange;

      final CoreButtonVariant variant;
      if (isSelected) {
        variant = .primary;
      } else if (isInRange) {
        variant = .secondary;
      } else {
        variant = .ghost;
      }

      months.add(
        // `role: .gridCell` on the wrapper, not the `Button` itself — see
        // the matching comment in `_DateGrid.build`.
        CoUISemantics(
          role: .gridCell,
          container: true,
          child: Button(
            key: ValueKey(date),
            onPressed: () => onChanged(value.copyWith(month: () => i)),
            variant: variant,
            size: .sm,
            buttonStyle: resolved.monthYearCellStyle,
            child: DefaultTextStyle.merge(
              style: resolved.cellLabelTextStyle,
              child: Text(localizations.getAbbreviatedMonth(i)),
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < months.length; i += resolved.monthGridColumns) {
      rows.add(
        CoUISemantics(
          role: .row,
          container: true,
          child: Row(
            children: months.sublist(i, i + resolved.monthGridColumns),
          ),
        ),
      );
    }

    return CoUISemantics(
      role: .grid,
      container: true,
      child: Column(
        mainAxisSize: .min,
        spacing: resolved.cellSpacing,
        children: rows,
      ),
    );
  }
}

class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.yearSelectStart,
    required this.calendarValue,
    required this.stateBuilder,
    required this.onChanged,
    required this.resolved,
  });

  final int yearSelectStart;
  final CoreCalendarValue? calendarValue;
  final DateStateBuilder? stateBuilder;
  final ValueChanged<int> onChanged;
  final ResolvedCalendar resolved;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final years = <Widget>[];

    for (
      var i = yearSelectStart;
      i < yearSelectStart + resolved.yearGridSize;
      i += 1
    ) {
      final date = DateTime(i);
      final cv = calendarValue;
      final lookup = cv?.lookup(date.year) ?? .none;
      final isSelected =
          lookup == .selected || lookup == .start || lookup == .end;
      final isInRange = lookup == .inRange;

      final CoreButtonVariant variant;
      if (isSelected) {
        variant = .primary;
      } else if (isInRange) {
        variant = .secondary;
      } else {
        variant = .ghost;
      }

      years.add(
        // `role: .gridCell` on the wrapper, not the `Button` itself — see
        // the matching comment in `_DateGrid.build`.
        CoUISemantics(
          role: .gridCell,
          container: true,
          child: Button(
            key: ValueKey(date),
            onPressed: () => onChanged(i),
            variant: variant,
            size: .sm,
            buttonStyle: resolved.monthYearCellStyle,
            child: DefaultTextStyle.merge(
              style: resolved.cellLabelTextStyle,
              child: Text('$i'),
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < years.length; i += resolved.yearGridColumns) {
      rows.add(
        CoUISemantics(
          role: .row,
          container: true,
          child: Row(children: years.sublist(i, i + resolved.yearGridColumns)),
        ),
      );
    }

    return CoUISemantics(
      role: .grid,
      container: true,
      child: Column(
        mainAxisSize: .min,
        spacing: resolved.yearRowSpacing,
        children: rows,
      ),
    );
  }
}

/// 캘린더에서 날짜의 상호작용 상태를 나타냅니다.
///
/// 특정 날짜를 선택하거나 상호작용할 수 있는지를 제어합니다:
/// - [disabled]: 날짜를 선택하거나 클릭할 수 없음.
/// - [enabled]: 날짜가 완전히 상호작용 가능하고 선택 가능함.
enum DateState {
  /// 비활성화됨 - 선택 불가.
  disabled,

  /// 활성화됨 - 선택 가능.
  enabled,
}

/// 캘린더 날짜의 상태를 결정하기 위한 콜백 함수 타입.
///
/// [DateTime]을 받아 해당 날짜가 사용자 상호작용을 위해 활성화되어야 하는지
/// 비활성화되어야 하는지를 제어하는 [DateState]를 반환합니다.
typedef DateStateBuilder = DateState Function(DateTime date);
