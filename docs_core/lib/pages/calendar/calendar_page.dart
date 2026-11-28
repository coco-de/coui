/// Calendar 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `calendar_web.dart` · `calendar_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 날짜 · 마커 · 규칙은 이 파일 한 곳에 둔다 — 두 플랫폼의 그림과
/// 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/calendar.md`.
const String slug = 'calendar';

/// 미리보기가 여는 달. 이미 지난 달로 고정한다 — 그래야 서버가 그리는 그림이
/// 오늘 날짜에 따라 바뀌지 않는다.
const CoreCalendarView previewView = CoreCalendarView(2026, 4);

/// [previewView] 안의 날짜.
DateTime previewDay(int day) => DateTime(previewView.year, previewView.month, day);

/// 단일 선택이 고른 날.
const int _singleDay = 15;

/// 다중 선택이 고른 날들.
const List<int> _multiDays = [7, 15, 23];

/// 기간 선택의 시작과 끝.
const int _rangeStartDay = 14;
const int _rangeEndDay = 23;

/// 표시 전용 달력에 넘기는 짧은 기간의 끝 — 한 줄에 시작 · 안 · 끝이 모두 보인다.
const int _shortRangeEndDay = 16;

/// 고를 수 있는 구간의 처음과 마지막 날.
const int _openFirstDay = 6;
const int _openLastDay = 24;

/// 구조 장면에서 점을 찍는 날 — 토요일 칸이라 번호를 오른쪽에 놓을 수 있다.
const int _anatomyMarkerDay = 18;

/// 마커 장면의 일정 수 — 날 → 건수.
const Map<int, int> _scheduleCounts = {3: 1, 9: 2, 15: 5, 21: 3};

/// 마커가 자기 색을 지정하는 날.
const int _coloredMarkerDay = 21;

/// 플레이그라운드의 마커가 찍히는 간격(일).
const int _markerEvery = 5;

/// 단일 선택 값.
CoreCalendarValue get previewSingleValue => CoreCalendarValue.single(previewDay(_singleDay));

/// 다중 선택 값.
CoreCalendarValue get previewMultiValue => CoreCalendarValue.multi([for (final day in _multiDays) previewDay(day)]);

/// 두 주에 걸친 기간 값.
CoreCalendarValue get previewRangeValue =>
    CoreCalendarValue.range(previewDay(_rangeStartDay), previewDay(_rangeEndDay));

/// 한 줄 안에서 끝나는 기간 값.
CoreCalendarValue get previewShortRangeValue =>
    CoreCalendarValue.range(previewDay(_rangeStartDay), previewDay(_shortRangeEndDay));

/// 선택 모드에 맞는 값. 표시 전용(`none`)은 받은 값을 그리기만 하므로 기간을
/// 넘겨 단일 선택과 다른 그림이 되게 한다.
CoreCalendarValue previewValueFor(CoreCalendarSelectionMode mode) => switch (mode) {
  CoreCalendarSelectionMode.none => previewShortRangeValue,
  CoreCalendarSelectionMode.single => previewSingleValue,
  CoreCalendarSelectionMode.range => previewRangeValue,
  CoreCalendarSelectionMode.multi => previewMultiValue,
};

/// 속성 → 선택 모드.
CoreCalendarSelectionMode previewModeOf(Map<String, String> props) =>
    previewEnum(CoreCalendarSelectionMode.values, props['mode'], CoreCalendarSelectionMode.single);

/// 속성 → 한 주의 첫 요일.
int previewWeekStartOf(Map<String, String> props) => props['week'] == 'monday' ? DateTime.monday : DateTime.sunday;

/// 주말을 고를 수 없게 하는 `stateBuilder`.
CoreCalendarDateState weekendsDisabled(DateTime date) =>
    date.weekday >= DateTime.saturday ? CoreCalendarDateState.disabled : CoreCalendarDateState.enabled;

/// 고를 수 있는 구간의 첫 날 — `minDate`.
DateTime get previewMinDate => previewDay(_openFirstDay);

/// 고를 수 있는 구간의 마지막 날 — `maxDate`.
DateTime get previewMaxDate => previewDay(_openLastDay);

/// 구간과 주말을 `stateBuilder` 한 곳에서 함께 막는다.
CoreCalendarDateState openDaysOnly(DateTime date) => date.isBefore(previewMinDate) || date.isAfter(previewMaxDate)
    ? CoreCalendarDateState.disabled
    : weekendsDisabled(date);

/// 플레이그라운드의 마커 — 5의 배수인 날에 `날 ÷ 5` 건.
CoreCalendarMarker? everyFifthDayMarker(DateTime date) =>
    date.day % _markerEvery == 0 ? CoreCalendarMarker(count: date.day ~/ _markerEvery) : null;

/// 마커 장면의 일정 — [previewView] 의 정해 둔 날에만 점을 찍는다.
CoreCalendarMarker? scheduleMarker(DateTime date) {
  if (date.year != previewView.year || date.month != previewView.month) return null;
  final count = _scheduleCounts[date.day];
  if (count == null) return null;
  return CoreCalendarMarker(
    count: count,
    color: date.day == _coloredMarkerDay ? const CoreColor.token(CoreColors.success) : null,
    semanticsLabel: '일정 $count건',
  );
}

/// 구조 장면의 마커 — 하루에만 찍는다.
CoreCalendarMarker? anatomyMarker(DateTime date) =>
    date == previewDay(_anatomyMarkerDay) ? const CoreCalendarMarker(count: 2) : null;

/// 테마 · 스타일 장면의 덮어쓰기 — 두 플랫폼에 함께 닿는 필드만 쓴다.
const CoreCalendarStyle previewThemedStyle = CoreCalendarStyle(
  dayCellSize: CoreSpace.space36,
  rangeSelectionColor: CoreColor.token(CoreColors.successContainer),
  rangeSelectionTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSuccessContainer)),
  markerMaxCount: 4,
  markerColor: CoreColor.token(CoreColors.success),
  rangeMarkerColor: CoreColor.token(CoreColors.onSuccessContainer),
);

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `value` 는 날짜를 미리 고른 상태, `markers` 는 `markerBuilder`, `weekends` 는
/// 주말을 막는 `stateBuilder` 를 켠다. 보이는 달은 늘 [previewView] 다.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'mode': 'single', 'week': 'sunday', 'value': 'true'},
  controls: [
    DocsPlaygroundChoice(
      label: 'selectionMode',
      prop: 'mode',
      options: [for (final mode in CoreCalendarSelectionMode.values) mode.name],
    ),
    const DocsPlaygroundChoice(label: '첫 요일', prop: 'week', options: ['sunday', 'monday'], segmented: true),
    const DocsPlaygroundFlag(label: '값 넣기', on: {'value': 'true'}),
    const DocsPlaygroundFlag(label: '마커', on: {'markers': 'true'}),
    const DocsPlaygroundFlag(label: '주말 막기', on: {'weekends': 'true'}),
  ],
  code: _calendarCode,
);

/// 크기 표. Calendar 에는 크기 축이 없다 — 칸 크기는 `calendarStyle` 로 바꾼다.
DocsSizeSpec Function()? get sizeSpec => null;

String _calendarCode(Map<String, String> props, String? label) {
  final mode = previewModeOf(props);
  final displayOnly = mode == CoreCalendarSelectionMode.none;
  final lines = [
    if (displayOnly) 'selectionMode: CoreCalendarSelectionMode.none,',
    'initialView: const CoreCalendarView(${previewView.year}, ${previewView.month}),',
    if (previewFlag(props, 'value')) 'value: ${_valueCode(previewValueFor(mode))},',
    if (!displayOnly) 'onChanged: setValue,',
    if (previewWeekStartOf(props) == DateTime.monday) 'firstDayOfWeek: DateTime.monday,',
    if (previewFlag(props, 'weekends')) ...[
      'stateBuilder: (date) => date.weekday >= DateTime.saturday',
      '    ? CoreCalendarDateState.disabled',
      '    : CoreCalendarDateState.enabled,',
    ],
    if (previewFlag(props, 'markers')) ...[
      'markerBuilder: (date) => date.day % $_markerEvery == 0',
      '    ? CoreCalendarMarker(count: date.day ~/ $_markerEvery)',
      '    : null,',
    ],
  ];
  final name = displayOnly ? 'Calendar' : 'Calendar.${mode.name}';
  return '$name(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

/// 값 → 그 값을 만드는 코드.
String _valueCode(CoreCalendarValue value) {
  String day(DateTime date) => 'DateTime(${date.year}, ${date.month}, ${date.day})';
  return switch (value) {
    CoreSingleCalendarValue(:final date) => 'CoreCalendarValue.single(${day(date)})',
    CoreRangeCalendarValue(:final start, :final end) => 'CoreCalendarValue.range(${day(start)}, ${day(end)})',
    CoreMultiCalendarValue(:final dates) => 'CoreCalendarValue.multi([${dates.map(day).join(', ')}])',
    _ => 'null',
  };
}
