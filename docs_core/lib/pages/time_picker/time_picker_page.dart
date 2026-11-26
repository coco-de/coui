/// TimePicker 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `time_picker_web.dart` · `time_picker_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 시각 · 글자는 아래 상수 한 곳에 둔다 — 두 플랫폼의 장면과
/// 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/time-picker.md`.
const String slug = 'time-picker';

/// 미리보기의 고른 시각 — 24시간 `HH:MM`.
const String demoValue = '14:30';

/// 플레이그라운드의 안내 글자.
const String demoPlaceholder = '시간을 선택해 주세요';

/// 플레이그라운드의 오류 문구.
const String demoError = '시간을 선택해야 해요';

/// dialog 모드의 제목.
const String demoDialogTitle = '시간 선택';

/// "화면에 이름 보이기" 카드의 필드 이름.
const String demoFieldName = '알림 시각';

/// "범위를 앱에서 확인하기" 카드의 시각 — 범위 밖의 값.
const String demoOutOfRangeValue = '07:30';

/// "범위를 앱에서 확인하기" 카드의 오류 문구.
const String demoRangeError = '9시부터 가능해요';

/// 관련 컴포넌트(Select) 장면의 시각 목록.
const List<String> demoSlots = ['10:00', '10:30', '11:00'];

/// 상태 장면의 칸 — 이름과 속성.
const List<(String, Map<String, String>)> demoStates = [
  ('빈 값', {'use24HourFormat': 'true'}),
  ('값 있음', {'value': demoValue, 'use24HourFormat': 'true'}),
  ('안내 글자', {'placeholder': demoFieldName, 'use24HourFormat': 'true'}),
  ('오류', {'use24HourFormat': 'true', 'errorText': '필수 항목'}),
  ('비활성', {'value': demoValue, 'use24HourFormat': 'true', 'enabled': 'false'}),
];

/// 시간 형식 장면의 칸 — 이름과 속성.
const List<(String, Map<String, String>)> demoFormats = [
  ('24시간', {'value': demoValue, 'use24HourFormat': 'true'}),
  ('12시간', {'value': demoValue, 'use24HourFormat': 'false'}),
  ('초 · 24시간', {'value': demoValue, 'use24HourFormat': 'true', 'showSeconds': 'true'}),
  ('초 · 12시간', {'value': demoValue, 'use24HourFormat': 'false', 'showSeconds': 'true'}),
  ('초 · 빈 값', {'use24HourFormat': 'true', 'showSeconds': 'true'}),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// variant · 크기 축이 없어 컨트롤은 값 · 여는 방식 · 시간 형식과 상태다.
/// `use24HourFormat` 은 늘 정해 둔다 — 비우면 플랫폼 설정을 따라 두 미리보기가
/// 서로 다른 시간 형식으로 보일 수 있다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'value': demoValue, 'mode': 'popover', 'use24HourFormat': 'true', 'minuteInterval': '1'},
  controls: [
    DocsPlaygroundFlag(label: '선택됨', on: {'value': demoValue}),
    DocsPlaygroundChoice(label: 'mode', prop: 'mode', options: ['popover', 'dialog'], segmented: true),
    DocsPlaygroundChoice(
      label: 'use24HourFormat',
      prop: 'use24HourFormat',
      options: ['true', 'false'],
      segmented: true,
    ),
    DocsPlaygroundChoice(label: 'minuteInterval', prop: 'minuteInterval', options: ['1', '15', '30'], segmented: true),
    DocsPlaygroundFlag(label: '초 (showSeconds)', on: {'showSeconds': 'true'}),
    // 값이 있으면 트리거는 안내 글자를 그리지 않는다 — '선택됨' 을 끄면 보인다.
    DocsPlaygroundFlag(label: '안내 글자 (값 없을 때)', on: {'placeholder': demoPlaceholder}),
    DocsPlaygroundFlag(label: '오류', on: {'errorText': demoError}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _timePickerCode,
);

/// 크기 표. TimePicker 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성이 고른 값 — 초를 보이면 `HH:MM` 값에 초를 붙여 `HH:MM:SS` 로 읽는다.
///
/// 트리거는 24시간 형식에서 `value` 를 적힌 그대로 보여 주므로, 초를 켜면
/// 앱이 저장하는 값의 모양(`HH:MM:SS`)을 함께 보인다.
String? demoTimeValue(Map<String, String> props) {
  final value = props['value'];
  if (value == null || !previewFlag(props, 'showSeconds')) return value;
  return value.split(':').length == 2 ? '$value:45' : value;
}

/// `use24HourFormat` 속성 — 없으면 `null`(플랫폼 설정).
bool? demoUse24Hour(Map<String, String> props) =>
    props.containsKey('use24HourFormat') ? previewFlag(props, 'use24HourFormat', fallback: true) : null;

/// `minuteInterval` 속성 — 숫자가 아니거나 60 의 약수가 아니면 기본값.
int demoMinuteInterval(Map<String, String> props) {
  final interval = int.tryParse(props['minuteInterval'] ?? '') ?? CoreTimePickerContract.defaultMinuteInterval;
  return CoreMinuteInterval.isValid(interval) ? interval : CoreTimePickerContract.defaultMinuteInterval;
}

/// 속성 묶음의 이름 — 속성이 바뀌면 미리보기를 새로 만드는 데 쓴다.
String demoPropsKey(Map<String, String> props) =>
    [for (final MapEntry(:key, :value) in props.entries) '$key=$value'].join(';');

String _timePickerCode(Map<String, String> props, String? label) {
  final value = demoTimeValue(props);
  final use24Hour = demoUse24Hour(props);
  final interval = demoMinuteInterval(props);
  final lines = [
    if (value != null) "value: '$value',",
    if (props['placeholder'] case final text?) "placeholder: '$text',",
    if (use24Hour != null) 'use24HourFormat: $use24Hour,',
    if (previewFlag(props, 'showSeconds')) 'showSeconds: true,',
    if (interval != CoreTimePickerContract.defaultMinuteInterval) 'minuteInterval: $interval,',
    if (props['mode'] == 'dialog') ...[
      'mode: CorePromptMode.dialog,',
      "dialogTitle: Text('$demoDialogTitle'),",
    ],
    if (props['errorText'] case final text?) "errorText: '$text',",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setTime,',
  ];
  return 'TimePicker(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
