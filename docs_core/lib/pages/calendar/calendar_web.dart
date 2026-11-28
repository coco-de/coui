/// Calendar 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="calendar/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`calendar_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 달력은 제 폭을 그대로 갖고 줄어들지 않는 것을 전제로 그린다. 두 달을
/// 나란히 놓는 기간 선택은 좁은 무대보다 넓으므로 옆으로 스크롤하는 상자에
/// 담는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'calendar_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _calendar;

/// 장면 이름(`calendar/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'calendar/anatomy': _anatomy,
  'calendar/single': () => Calendar.single(initialView: page.previewView, value: page.previewSingleValue),
  'calendar/multi': () => Calendar.multi(initialView: page.previewView, value: page.previewMultiValue),
  'calendar/range': () => _scrollable(Calendar.range(initialView: page.previewView, value: page.previewRangeValue)),
  'calendar/none': () => Calendar(
    selectionMode: CoreCalendarSelectionMode.none,
    initialView: page.previewView,
    value: page.previewShortRangeValue,
  ),
  'calendar/week-start': _weekStart,
  'calendar/markers': () => Calendar.single(
    initialView: page.previewView,
    value: page.previewSingleValue,
    markerBuilder: page.scheduleMarker,
  ),
  'calendar/states': () => Calendar(
    selectionMode: CoreCalendarSelectionMode.none,
    initialView: page.previewView,
    value: page.previewShortRangeValue,
    minDate: page.previewMinDate,
    maxDate: page.previewMaxDate,
  ),
  'calendar/disabled': () => const Calendar.single(
    initialView: page.previewView,
    stateBuilder: page.weekendsDisabled,
  ),
  'calendar/do-combined-rules': () => const Calendar.single(
    initialView: page.previewView,
    stateBuilder: page.openDaysOnly,
  ),
  'calendar/dont-split-rules': () => Calendar.single(
    initialView: page.previewView,
    minDate: page.previewMinDate,
    maxDate: page.previewMaxDate,
    stateBuilder: page.weekendsDisabled,
  ),
  'calendar/themed': () => Calendar(
    selectionMode: CoreCalendarSelectionMode.none,
    initialView: page.previewView,
    value: page.previewRangeValue,
    markerBuilder: page.scheduleMarker,
    calendarStyle: page.previewThemedStyle,
  ),
  'calendar/related-date-picker': () => _sized(DatePicker(value: '2026-04-15', onChanged: (_) {})),
  'calendar/related-time-picker': () => _sized(TimePicker(value: '14:30', use24HourFormat: true, onChanged: (_) {})),
};

Component _calendar(Map<String, String> props, String? label) {
  final mode = page.previewModeOf(props);
  final hasValue = previewFlag(props, 'value');
  return _scrollable(
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

/// 무대보다 넓은 달력은 상자 안에서 옆으로 스크롤한다. 안쪽 여백은 스크롤
/// 상자가 포커스 링을 자르지 않게 둔다.
Component _scrollable(Component calendar) => div(
  styles: Styles(raw: {'max-width': '100%', 'overflow-x': 'auto', 'padding': spaceCss(CoreSpace.space4)}),
  [
    div(styles: Styles(raw: {'width': 'max-content', 'margin': '0 auto'}), [calendar]),
  ],
);

/// 구조 장면 — 제목 위에 번호가 놓일 자리를 위쪽에 둔다.
Component _anatomy() => div(
  styles: Styles(raw: {'width': 'max-content', 'padding-top': spaceCss(CoreSpace.space16)}),
  [
    Calendar.single(
      initialView: page.previewView,
      value: page.previewSingleValue,
      markerBuilder: page.anatomyMarker,
    ),
  ],
);

/// 첫 요일이 다른 같은 달 두 개.
Component _weekStart() => div(
  classes: 'docs-demo-row',
  styles: Styles(raw: {'align-items': 'flex-start', 'gap': spaceCss(CoreSpace.space32)}),
  [
    _captioned('일요일 시작 (기본)', const Calendar.single(initialView: page.previewView)),
    _captioned(
      '월요일 시작',
      const Calendar.single(initialView: page.previewView, firstDayOfWeek: DateTime.monday),
    ),
  ],
);

Component _captioned(String caption, Component calendar) => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space8)},
  ),
  [Text(caption).labelSmall.onSurfaceVariant, calendar],
);

Component _sized(Component child) => div(styles: Styles(raw: {'width': '12rem'}), [child]);
