import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/calendar/calendar_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform calendar for CoUI Web.
///
/// Supports single, range, and multi-date selection modes,
/// month/year navigation, and customizable date state validation.
///
/// Implements [CoreCalendarContract] for cross-platform API consistency.
///
/// Per Epic #1302 / #1696 every chrome / dimensional / nested-slot
/// override flows through the single [calendarStyle] (a
/// [CoreCalendarStyle]):
///
/// ```text
/// design system default
///   → CoreCalendarTheme.style                         // 프로젝트 공통
///   → parent component slot override
///       (e.g. CoreDatePickerStyle.calendarStyle)
///   → component.calendarStyle                         // 인스턴스별
/// ```
class Calendar extends UiStatefulComponent
    implements CoreCalendarContract<Component> {
  /// Creates a [Calendar].
  const Calendar({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.selectionMode = .single,
    this.value,
    this.onChanged,
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
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.value,
    this.onChanged,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.minDate,
    this.maxDate,
    this.markerBuilder,
    this.calendarStyle,
  }) : selectionMode = .single,
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  /// Creates a range-selection calendar.
  const Calendar.range({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.value,
    this.onChanged,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.minDate,
    this.maxDate,
    this.markerBuilder,
    this.calendarStyle,
  }) : selectionMode = .range,
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  /// Creates a multi-selection calendar.
  const Calendar.multi({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.value,
    this.onChanged,
    this.initialView,
    this.firstDayOfWeek = CoreCalendarContract.defaultFirstDayOfWeek,
    this.stateBuilder,
    this.minDate,
    this.maxDate,
    this.markerBuilder,
    this.calendarStyle,
  }) : selectionMode = .multi,
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday '
         '(DateTime.monday..DateTime.sunday)',
       );

  @override
  final CoreCalendarSelectionMode selectionMode;

  @override
  final CoreCalendarValue? value;

  @override
  final void Function(CoreCalendarValue?)? onChanged;

  @override
  final CoreCalendarView? initialView;

  @override
  final int firstDayOfWeek;

  @override
  final CoreCalendarDateStateBuilder? stateBuilder;

  @override
  final DateTime? minDate;

  @override
  final DateTime? maxDate;

  @override
  final CoreCalendarMarkerBuilder? markerBuilder;

  @override
  final CoreCalendarStyle? calendarStyle;

  /// Returns a copy of this [Calendar] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Calendar copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CoreCalendarSelectionMode? selectionMode,
    CoreCalendarValue? value,
    void Function(CoreCalendarValue?)? onChanged,
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
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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

/// Chain sugar mirroring the Flutter `Calendar.withStyle` extension —
/// merges a [CoreCalendarStyle] patch into [Calendar.calendarStyle] via
/// the existing [Calendar.copyWith].
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
  late CoreCalendarView _displayView;
  late CoreCalendarView _alternateView;
  late CoreCalendarViewType _viewType;
  late int _yearSelectStart;

  CoreCalendarValue? _value;

  /// Resolved style for the current build cycle.
  late ResolvedCalendar _resolved;

  /// Resolved behavioural grid counts for the current build cycle —
  /// logic-only layout-loop identifiers (year-grid size + month / year
  /// subgrid columns) read from the merge chain via
  /// [resolveCalendarGrid], kept off [ResolvedCalendar] so the
  /// resolved bundle stays pure paint-ready chrome.
  late ({
    int yearGridSize,
    int monthGridColumns,
    int yearGridColumns,
    int markerMaxCount,
  })
  _grid;

  /// Days per week — calendrical constant, not a design token.
  static const _kDaysPerWeek = 7;

  /// Number of months in the Gregorian calendar. Calendrical constant,
  /// not a design token.
  static const _kMonthsPerYear = 12;

  /// Previous icon (Lucide — matches Flutter LucideIcons.arrowLeft).
  static const IconName _kPrevIcon = LucideIcons.arrowLeft;

  /// Next icon (Lucide — matches Flutter LucideIcons.arrowRight).
  static const IconName _kNextIcon = LucideIcons.arrowRight;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Logic-only grid count — read from the grid resolver record (which
  /// folds `merged.yearGridSize` through the calendar Style chain so Web
  /// and Flutter share one resolution path).
  int get _yearGridSize => _grid.yearGridSize;

  /// Logic-only column count for the month subgrid.
  int get _monthGridColumns => _grid.monthGridColumns;

  /// Logic-only column count for the year subgrid.
  int get _yearGridColumns => _grid.yearGridColumns;

  @override
  void initState() {
    super.initState();
    final iv = component.initialView;
    final v = component.value;
    if (iv != null) {
      _displayView = iv;
    } else if (v != null) {
      _displayView = CoreCalendarView(v.viewYear, v.viewMonth);
    } else {
      _displayView = .now();
    }
    _alternateView = _displayView.next;
    _value = component.value;
    _viewType = .date;
    _yearSelectStart =
        (_displayView.year ~/ CoreCalendarStyle.defaultYearGridSize) *
        CoreCalendarStyle.defaultYearGridSize;
  }

  @override
  void didUpdateComponent(covariant Calendar oldComponent) {
    super.didUpdateComponent(oldComponent);
    // `value` is a controlled field on the shared contract, so an
    // externally-driven change — a form reset, a "Today" shortcut, a
    // programmatic clear, the host picker's value moving while the
    // panel is open — has to land. Seeding it once at mount left this
    // calendar rendering whatever the user last clicked, indefinitely,
    // while the Flutter twin followed the caller.
    if (oldComponent.value != component.value) {
      setState(() {
        _value = component.value;
      });
    }
    // `_displayView` is deliberately not reset here: the month the user
    // navigated to is theirs, and snapping it back to the selection is
    // the exact behaviour that made picking a date in another month jump
    // the calendar away. Neither platform does it.
  }

  bool get _isRange => component.selectionMode == .range;

  CoreCalendarDateState _resolveState(DateTime date) {
    final sb = component.stateBuilder;
    if (sb != null) return sb(date);
    final min = component.minDate;
    if (min != null && date.isBefore(DateTime(min.year, min.month, min.day))) {
      return .disabled;
    }
    final max = component.maxDate;
    if (max != null && date.isAfter(DateTime(max.year, max.month, max.day))) {
      return .disabled;
    }
    return .enabled;
  }

  String _getHeaderText(BuildContext context, CoreCalendarView view) {
    final l10n = CouiLocalizations.of(context);
    if (_viewType == .date) {
      return l10n.formatMonthYear(view.month, view.year);
    }
    if (_viewType == .month) {
      return '${view.year}';
    }
    return l10n.datePickerSelectYear;
  }

  void _handleGoToPrev() {
    setState(() {
      switch (_viewType) {
        case .date:
          _displayView = _displayView.previous;
          if (_isRange) _alternateView = _alternateView.previous;
        case .month:
          _displayView = _displayView.previousYear;
        case .year:
          _yearSelectStart -= _yearGridSize;
      }
    });
  }

  void _handleGoToNext() {
    setState(() {
      switch (_viewType) {
        case .date:
          _displayView = _displayView.next;
          if (_isRange) _alternateView = _alternateView.next;
        case .month:
          _displayView = _displayView.nextYear;
        case .year:
          _yearSelectStart += _yearGridSize;
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
      _displayView = value;
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

  /// Button semantics for a hand-drawn date cell.
  ///
  /// The cells that compose `Button` get these from the native element.
  /// These two draw their own chrome, so they state it themselves — the
  /// alternative is a date a pointer can select and a keyboard cannot.
  Map<String, String> _cellButtonAttributes({required bool isEnabled}) => {
    'role': 'button',
    // Disabled leaves the tab order and stays in the tree. Dropping the
    // role instead would make an unavailable date indistinguishable from
    // the empty padding cells around the month — "unavailable" and "not
    // a date at all" are different answers to the same question.
    if (isEnabled) 'tabindex': '0' else 'aria-disabled': 'true',
  };

  /// Pointer and keyboard activation for a hand-drawn date cell.
  Map<String, EventCallback> _cellActivationEvents(DateTime date) => {
    'click': (_) => _handleDateTap(date),
    'keydown': EventHandlers.createKeyboardEventHandler((event) {
      final key = event.key;
      if (key != ' ' && key != 'Enter') return;
      event.preventDefault();
      _handleDateTap(date);
    }),
  };

  void _handleDateTap(DateTime date) {
    var calendarValue = _value;

    switch (component.selectionMode) {
      case .none:
        return;

      case .single:
        if (calendarValue is CoreSingleCalendarValue &&
            _isSameDay(date, calendarValue.date)) {
          _emitValue(null);
          return;
        }
        _emitValue(CoreCalendarValue.single(date));

      case .multi:
        if (calendarValue == null) {
          _emitValue(CoreCalendarValue.single(date));
          return;
        }
        final lookup = calendarValue.lookup(date.year, date.month, date.day);
        if (lookup == .none) {
          final multi = calendarValue.toMulti();
          final updatedDates = [...multi.dates, date];
          _emitValue(CoreMultiCalendarValue(updatedDates));
          return;
        }
        final multi = calendarValue.toMulti();
        final updatedDates = multi.dates
            .where((d) => !_isSameDay(d, date))
            .toList();
        if (updatedDates.isEmpty) {
          _emitValue(null);
          return;
        }
        _emitValue(CoreMultiCalendarValue(updatedDates));

      case .range:
        if (calendarValue == null) {
          _emitValue(CoreCalendarValue.single(date));
          return;
        }
        if (calendarValue is CoreMultiCalendarValue) {
          calendarValue = calendarValue.toRange();
        }
        if (calendarValue is CoreSingleCalendarValue) {
          final selectedDate = calendarValue.date;
          if (_isSameDay(date, selectedDate)) {
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
      component.onChanged?.call(value);
    });
  }

  Component _buildSingleLayout(BuildContext context) {
    return div(
      [
        _buildHeader(context, view: _displayView),
        Gap(gapStyle: _resolved.headerGridGapStyle),
        _buildViewContent(context, view: _displayView),
      ],
      classes: _resolved.container.className,
    );
  }

  Component _buildRangeLayout(BuildContext context) {
    final gap = Gap(gapStyle: _resolved.headerGridGapStyle);
    final headerRowClass = _resolved.headerRow.className;
    final titleWrapClass = _resolved.headerTitle.className;
    final sideWrapClass = _resolved.rangeHeaderSide.className;
    final navPlaceholderClass = _resolved.navPlaceholder.className;

    if (_viewType == .date) {
      return div(
        [
          div(
            [
              div(
                [
                  _buildNavButton(
                    context,
                    onTap: _handleGoToPrev,
                    icon: _kPrevIcon,
                  ),
                  gap,
                  div(
                    [
                      _buildHeaderButton(
                        context,
                        headerText: _getHeaderText(context, _displayView),
                      ),
                    ],
                    classes: titleWrapClass,
                  ),
                  div(const [], classes: navPlaceholderClass),
                  gap,
                ],
                classes: sideWrapClass,
              ),
              gap,
              div(
                [
                  div(const [], classes: navPlaceholderClass),
                  gap,
                  div(
                    [
                      _buildHeaderButton(
                        context,
                        headerText: _getHeaderText(context, _alternateView),
                      ),
                    ],
                    classes: titleWrapClass,
                  ),
                  gap,
                  _buildNavButton(
                    context,
                    onTap: _handleGoToNext,
                    icon: _kNextIcon,
                  ),
                ],
                classes: sideWrapClass,
              ),
            ],
            classes: headerRowClass,
          ),
          gap,
          div(
            [
              _buildViewContent(context, view: _displayView),
              gap,
              _buildViewContent(context, view: _alternateView),
            ],
            classes: _resolved.rangeGridRow.className,
          ),
        ],
        classes: _resolved.container.className,
      );
    }

    return div(
      [
        div(
          [
            _buildNavButton(context, onTap: _handleGoToPrev, icon: _kPrevIcon),
            gap,
            div(
              [
                _buildHeaderButton(
                  context,
                  headerText: _getHeaderText(context, _displayView),
                ),
              ],
              classes: titleWrapClass,
            ),
            gap,
            _buildNavButton(context, onTap: _handleGoToNext, icon: _kNextIcon),
          ],
          classes: headerRowClass,
        ),
        gap,
        _buildViewContent(context, view: _displayView),
      ],
      classes: _resolved.container.className,
    );
  }

  Component _buildHeader(
    BuildContext context, {
    required CoreCalendarView view,
  }) {
    return div(
      [
        _buildNavButton(context, onTap: _handleGoToPrev, icon: _kPrevIcon),
        Gap(gapStyle: _resolved.headerGridGapStyle),
        div(
          [
            _buildHeaderButton(
              context,
              headerText: _getHeaderText(context, view),
            ),
          ],
          classes: _resolved.headerTitle.className,
        ),
        Gap(gapStyle: _resolved.headerGridGapStyle),
        _buildNavButton(context, onTap: _handleGoToNext, icon: _kNextIcon),
      ],
      classes: _resolved.headerRow.className,
    );
  }

  Component _buildNavButton(
    BuildContext context, {
    required void Function() onTap,
    required IconName icon,
  }) {
    return Button(
      attributes: {
        'aria-label': icon == _kPrevIcon
            ? CouiLocalizations.of(context).calendarPreviousPeriod
            : CouiLocalizations.of(context).calendarNextPeriod,
      },
      onPressed: onTap,
      variant: .ghost,
      size: .sm,
      buttonStyle: _resolved.navButtonStyle,
      child: Icon(icon, iconStyle: _resolved.arrowIconStyle),
    );
  }

  Component _buildHeaderButton(
    BuildContext context, {
    required String headerText,
  }) {
    return Button(
      onPressed: _handleHeaderTap,
      variant: .ghost,
      size: .sm,
      enabled: _viewType != .year,
      buttonStyle: _resolved.headerButtonStyle,
      expanded: true,
      child: Text(headerText),
    );
  }

  Component _buildViewContent(
    BuildContext context, {
    required CoreCalendarView view,
  }) {
    switch (_viewType) {
      case .date:
        return _buildDateGrid(context, view: view);
      case .month:
        return _buildMonthGrid(context, view: view);
      case .year:
        return _buildYearGrid(context);
    }
  }

  Component _buildDateGrid(
    BuildContext context, {
    required CoreCalendarView view,
  }) {
    final now = CoreCalendarView.currentTime();
    final gridData = CoreCalendarGridData(
      month: view.month,
      year: view.year,
      firstDayOfWeek: component.firstDayOfWeek,
    );

    final rows = <Component>[];

    final weekdayClass = _resolved.weekdayCell.className;
    final weekdayInline = _resolved.weekdayCell.inlineStyles;
    final rowClass = _resolved.gridRow.className;
    final l10n = CouiLocalizations.of(context);
    final weekdayHeaders = <Component>[];
    // The header is the Core order for the same week start the grid was laid
    // out with — a header drawn from anything else would head the wrong
    // columns.
    for (final weekday in CoreCalendarGridData.weekdayOrder(
      component.firstDayOfWeek,
    )) {
      weekdayHeaders.add(
        div(
          [Text(l10n.getAbbreviatedWeekday(weekday))],
          classes: weekdayClass,
          styles: weekdayInline,
          attributes: {'role': CoreSemanticRole.columnHeader.ariaRole},
        ),
      );
    }
    rows.add(
      div(
        weekdayHeaders,
        classes: rowClass,
        attributes: {'role': CoreSemanticRole.row.ariaRole},
      ),
    );

    for (var i = 0; i < gridData.items.length; i += _kDaysPerWeek) {
      final rowItems = gridData.items.sublist(i, i + _kDaysPerWeek);
      final cells = <Component>[];
      for (final item in rowItems) {
        cells.add(
          _buildDayCell(context, item: item, now: now),
        );
      }
      rows.add(
        div(
          cells,
          classes: rowClass,
          attributes: {'role': CoreSemanticRole.row.ariaRole},
        ),
      );
    }

    return div(
      rows,
      classes: _resolved.grid.className,
      attributes: {'role': CoreSemanticRole.grid.ariaRole},
    );
  }

  Component _buildDayCell(
    BuildContext context, {
    required CoreCalendarGridItem item,
    required DateTime now,
  }) {
    final date = item.date;
    final state = _resolveState(date);
    final isEnabled = state == .enabled;

    final lookup = _value?.lookup(date.year, date.month, date.day) ?? .none;

    var type = _DayCellType.none;
    switch (lookup) {
      case .none:
        if (_isSameDay(date, now)) {
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
    if (item.indexInRow == _kDaysPerWeek - 1 && type == .startRangeSelected) {
      type = .selected;
    }

    final marker = component.markerBuilder?.call(date);
    final resolvedMarker = marker == null
        ? null
        : resolveCalendarMarker(
            context,
            marker: marker,
            lookup: switch (type) {
              .selected ||
              .startRangeSelected ||
              .endRangeSelected => CoreCalendarValueLookup.selected,
              .inRange => CoreCalendarValueLookup.inRange,
              .none || .today => CoreCalendarValueLookup.none,
            },
            calendarStyle: component.calendarStyle,
          );
    // The marker's meaning joins the date's accessible name — a visually
    // hidden span inside the cell, so the button reads "15, 2 items" rather
    // than "15" followed by a stray label. The dots below are aria-hidden;
    // the label already says what they show.
    final dayLabel = marker == null || resolvedMarker == null
        ? Text('${date.day}')
        : Component.fragment([
            Text('${date.day}'),
            span(
              [
                Text(
                  marker.semanticsLabel ??
                      CouiLocalizations.of(
                        context,
                      ).calendarMarkerCount(marker.count),
                ),
              ],
              classes: resolvedMarker.label.className,
              styles: resolvedMarker.label.inlineStyles,
            ),
          ]);

    Component cell;

    if (type == .startRangeSelected || type == .endRangeSelected) {
      final isStart = type == .startRangeSelected;
      final strip = isStart
          ? _resolved.rangeStripStart
          : _resolved.rangeStripEnd;
      final pill = _resolved.rangeEndpointPill;
      cell = div(
        [
          div(const [], classes: strip.className, styles: strip.inlineStyles),
          div(
            [dayLabel],
            classes: pill.className,
            styles: pill.inlineStyles,
          ),
        ],
        classes: _resolved.rangeEndpointCell.className,
        // Operable, not just clickable. Every other date in this grid is
        // a `Button`; these two are hand-drawn so the strip can run
        // behind the pill, and they were left as bare divs with a click
        // handler — so a keyboard user could pick a range start and then
        // had no way to reach its end. The selection could be begun and
        // not finished.
        attributes: _cellButtonAttributes(isEnabled: isEnabled),
        events: isEnabled ? _cellActivationEvents(date) : null,
      );
    } else if (type == .inRange) {
      cell = div(
        [dayLabel],
        classes: _resolved.inRangeCell.className,
        styles: _resolved.inRangeCell.inlineStyles,
        attributes: _cellButtonAttributes(isEnabled: isEnabled),
        events: isEnabled ? _cellActivationEvents(date) : null,
      );
    } else {
      final variant = switch (type) {
        .today => CoreButtonVariant.ghost,
        .selected => CoreButtonVariant.primary,
        .none ||
        .inRange ||
        .startRangeSelected ||
        .endRangeSelected => CoreButtonVariant.ghost,
      };

      final button = Button(
        onPressed: () => _handleDateTap(date),
        variant: variant,
        size: .sm,
        enabled: isEnabled,
        buttonStyle: switch (type) {
          .today => _resolved.dateCellTodayStyle,
          .selected => _resolved.dateCellSelectedStyle,
          _ => _resolved.dateCellStyle,
        },
        child: dayLabel,
      );

      final override = type == .selected
          ? _resolved.selectedOverride
          : type == .today
          ? _resolved.todayOverride
          : null;
      cell = (override == null || override.inlineStyles == null)
          ? button
          : div([button], styles: override.inlineStyles);
    }

    if (marker != null && resolvedMarker != null) {
      // Dots overlay the cell instead of joining its layout, so a marked day
      // keeps the square every other day has and the grid does not shift as
      // markers come and go.
      final dotCount = marker.count < _grid.markerMaxCount
          ? marker.count
          : _grid.markerMaxCount;
      final row = resolvedMarker.row;
      final dot = resolvedMarker.dot;
      cell = div(
        [
          cell,
          div(
            [
              for (var i = 0; i < dotCount; i += 1)
                div(const [], classes: dot.className, styles: dot.inlineStyles),
            ],
            classes: row.className,
            styles: row.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
          ),
        ],
        classes: resolvedMarker.root.className,
        styles: resolvedMarker.root.inlineStyles,
      );
    }

    // `role="gridcell"` on a wrapper, not on `cell` itself — `cell` is
    // already a `Button` (or a hand-drawn div carrying its own
    // `role="button"` via `_cellButtonAttributes`), and an element can only
    // carry one ARIA role. `display: contents` keeps the wrapper out of the
    // row's flex layout so the wrapped widget still lays out as the row's
    // direct visual child (ARIA APG's "widget within a gridcell" pattern).
    final gridCellAttributes = {'role': CoreSemanticRole.gridCell.ariaRole};
    if (item.fromAnotherMonth) {
      final wrap = _resolved.fadedCellWrap;
      return div(
        [cell],
        classes: wrap.className,
        styles: Styles.combine([kCalendarGridCellStyles, ?wrap.inlineStyles]),
        attributes: gridCellAttributes,
      );
    }
    return div(
      [cell],
      styles: kCalendarGridCellStyles,
      attributes: gridCellAttributes,
    );
  }

  Component _buildMonthGrid(
    BuildContext context, {
    required CoreCalendarView view,
  }) {
    final l10n = CouiLocalizations.of(context);
    final rows = <Component>[];
    final months = <Component>[];

    for (var i = 1; i <= _kMonthsPerYear; i++) {
      final date = DateTime(view.year, i);

      final lookup = _value?.lookup(date.year, date.month) ?? .none;
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
        // `role="gridcell"` on the wrapper, not the `Button` — see the
        // matching comment on `_buildDayCell`'s wrapper.
        div(
          [
            Button(
              onPressed: () =>
                  _handleViewChanged(view.copyWith(month: () => i)),
              variant: variant,
              size: .sm,
              buttonStyle: _resolved.monthYearCellStyle,
              child: Text(l10n.getAbbreviatedMonth(i)),
            ),
          ],
          styles: kCalendarGridCellStyles,
          attributes: {'role': CoreSemanticRole.gridCell.ariaRole},
        ),
      );
    }

    final gappedRow = _resolved.gridRowGapped.className;
    final cols = _monthGridColumns;
    for (var i = 0; i < months.length; i += cols) {
      rows.add(
        div(
          months.sublist(i, i + cols),
          classes: gappedRow,
          attributes: {'role': CoreSemanticRole.row.ariaRole},
        ),
      );
    }

    return div(
      rows,
      classes: _resolved.grid.className,
      attributes: {'role': CoreSemanticRole.grid.ariaRole},
    );
  }

  Component _buildYearGrid(BuildContext context) {
    final rows = <Component>[];
    final years = <Component>[];
    final size = _yearGridSize;

    for (var i = _yearSelectStart; i < _yearSelectStart + size; i++) {
      final date = DateTime(i);

      final lookup = _value?.lookup(date.year) ?? .none;
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
        // `role="gridcell"` on the wrapper, not the `Button` — see the
        // matching comment on `_buildDayCell`'s wrapper.
        div(
          [
            Button(
              onPressed: () {
                _handleViewChanged(_displayView.copyWith(year: () => i));
              },
              variant: variant,
              size: .sm,
              buttonStyle: _resolved.monthYearCellStyle,
              child: Text('$i'),
            ),
          ],
          styles: kCalendarGridCellStyles,
          attributes: {'role': CoreSemanticRole.gridCell.ariaRole},
        ),
      );
    }

    final gappedRow = _resolved.gridRowGapped.className;
    final cols = _yearGridColumns;
    for (var i = 0; i < years.length; i += cols) {
      rows.add(
        div(
          years.sublist(i, i + cols),
          classes: gappedRow,
          attributes: {'role': CoreSemanticRole.row.ariaRole},
        ),
      );
    }

    // Year grid uses the dedicated `yearGrid` wrapper so the vertical
    // row gap is driven by `yearRowSpacing` (Flutter parity).
    return div(
      rows,
      classes: _resolved.yearGrid.className,
      attributes: {'role': CoreSemanticRole.grid.ariaRole},
    );
  }

  @override
  Component build(BuildContext context) {
    _resolved = resolveCalendar(
      context,
      calendarStyle: component.calendarStyle,
    );
    _grid = resolveCalendarGrid(
      context,
      calendarStyle: component.calendarStyle,
    );

    final Component content;
    if (_isRange) {
      content = _buildRangeLayout(context);
    } else {
      content = _buildSingleLayout(context);
    }

    return div(
      [content],
      id: component.id,
      classes: component.rootClasses(_resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?_resolved.root.inlineStyles, component.css!])
          : _resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        // No role here. `role="application"` used to sit on this root and
        // told assistive tech to hand every keystroke to the widget,
        // suppressing browse-mode navigation for the whole calendar.
        // Nothing under this root ever intercepted arbitrary keys — day
        // cells are individually focusable `Button`s reachable by Tab —
        // so the role only turned off navigation without buying anything.
        // The actual structure (`role="grid"` / `"row"` / `"gridcell"`)
        // lives on the grid wrapper below, where it belongs.
        'aria-label': CouiLocalizations.of(context).calendarLabel,
      },
      events: component.events,
    );
  }
}

/// Internal cell type for date grid rendering.
enum _DayCellType {
  none,
  today,
  selected,
  inRange,
  startRangeSelected,
  endRangeSelected,
}
