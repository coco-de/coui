/// Calendar 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="calendar/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`calendar_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 달력은 폭이 정해져 있어 좁은 무대에서 넘칠 수 있다. 장면마다 폭이 모자랄
/// 때만 줄여 그리는 상자(`FittedBox`)에 담는다. 높이는 내용만큼이라 따로
/// 제한하지 않는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'calendar_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _calendar;

/// 장면 이름(`calendar/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'calendar/anatomy': () => _fit(
    Calendar.single(
      initialView: page.previewView,
      value: page.previewSingleValue,
      markerBuilder: page.anatomyMarker,
    ),
  ),
  'calendar/single': () => _fit(Calendar.single(initialView: page.previewView, value: page.previewSingleValue)),
  'calendar/multi': () => _fit(Calendar.multi(initialView: page.previewView, value: page.previewMultiValue)),
  'calendar/range': () => _fit(Calendar.range(initialView: page.previewView, value: page.previewRangeValue)),
  'calendar/none': () => _fit(
    Calendar(
      selectionMode: CoreCalendarSelectionMode.none,
      initialView: page.previewView,
      value: page.previewShortRangeValue,
    ),
  ),
  'calendar/week-start': _weekStart,
  'calendar/markers': () => _fit(
    Calendar.single(
      initialView: page.previewView,
      value: page.previewSingleValue,
      markerBuilder: page.scheduleMarker,
    ),
  ),
  'calendar/states': () => _fit(
    Calendar(
      selectionMode: CoreCalendarSelectionMode.none,
      initialView: page.previewView,
      value: page.previewShortRangeValue,
      minDate: page.previewMinDate,
      maxDate: page.previewMaxDate,
    ),
  ),
  'calendar/disabled': () => _fit(
    const Calendar.single(initialView: page.previewView, stateBuilder: page.weekendsDisabled),
  ),
  'calendar/do-combined-rules': () => _fit(
    const Calendar.single(initialView: page.previewView, stateBuilder: page.openDaysOnly),
  ),
  'calendar/dont-split-rules': () => _fit(
    Calendar.single(
      initialView: page.previewView,
      minDate: page.previewMinDate,
      maxDate: page.previewMaxDate,
      stateBuilder: page.weekendsDisabled,
    ),
  ),
  'calendar/themed': () => _fit(
    Calendar(
      selectionMode: CoreCalendarSelectionMode.none,
      initialView: page.previewView,
      value: page.previewRangeValue,
      markerBuilder: page.scheduleMarker,
      calendarStyle: page.previewThemedStyle,
    ),
  ),
  'calendar/related-date-picker': () => _sized(DatePicker(value: DateTime(2026, 4, 15), onChanged: (_) {})),
  'calendar/related-time-picker': () => _sized(TimePicker(value: '14:30', use24HourFormat: true, onChanged: (_) {})),
};

Widget _calendar(Map<String, String> props, String? label) {
  final mode = page.previewModeOf(props);
  final hasValue = previewFlag(props, 'value');
  return _fit(
    Calendar(
      // 선택 값은 달력이 스스로도 들고 있어, 모드나 값 손잡이를 바꾸면 새로
      // 만든다.
      key: ValueKey('${mode.name}-$hasValue'),
      selectionMode: mode,
      value: hasValue ? page.previewValueFor(mode) : null,
      initialView: page.previewView,
      firstDayOfWeek: page.previewWeekStartOf(props),
      stateBuilder: previewFlag(props, 'weekends') ? page.weekendsDisabled : null,
      markerBuilder: previewFlag(props, 'markers') ? page.everyFifthDayMarker : null,
      onChanged: (_) {},
    ),
  );
}

/// 폭이 모자랄 때만 줄여 그린다.
Widget _fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, child: child);

/// 첫 요일이 다른 같은 달 두 개.
Widget _weekStart() => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space32,
  runSpacing: CoreSpace.space16,
  children: [
    _captioned('일요일 시작 (기본)', const Calendar.single(initialView: page.previewView)),
    _captioned(
      '월요일 시작',
      const Calendar.single(initialView: page.previewView, firstDayOfWeek: DateTime.monday),
    ),
  ],
);

Widget _captioned(String caption, Widget calendar) => _fit(
  Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space8,
    children: [Text(caption).labelSmall.onSurfaceVariant, calendar],
  ),
);

Widget _sized(Widget child) => SizedBox(width: 192, child: child);
