/// TimePicker 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="time-picker/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`time_picker_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대에는 트리거를 둔다. 패널은 트리거를 누르면 열린다 — 사이트의 장면은
/// 브라우저에서 깨어나지 않으므로 열어 보는 곳은 플레이그라운드다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'time_picker_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _timePicker;

/// 장면 이름(`time-picker/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'time-picker/anatomy': () => _sized(_still(const {'value': page.demoValue, 'use24HourFormat': 'true'})),
  'time-picker/states': () => _grid(page.demoStates),
  'time-picker/formats': () => _grid(page.demoFormats),
  'time-picker/do-range-check': () => _sized(
    _still(const {
      'value': page.demoOutOfRangeValue,
      'use24HourFormat': 'true',
      'errorText': page.demoRangeError,
    }),
    width: '11rem',
  ),
  'time-picker/do-visible-name': () => div(
    styles: Styles(
      raw: {'width': '11rem', 'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space4)},
    ),
    [
      const FormLabel(label: Text(page.demoFieldName)),
      _still(const {'use24HourFormat': 'true'}),
    ],
  ),
  'time-picker/related-date-picker': () => _sized(
    DatePicker(placeholder: '날짜 선택', onChanged: (_) {}),
    width: '12rem',
  ),
  'time-picker/related-select': () => _sized(
    Select<String>(
      placeholder: '시각 선택',
      onChanged: (_) {},
      items: [for (final slot in page.demoSlots) CoreSelectItem(value: slot, label: slot)],
    ),
    width: '12rem',
  ),
};

Component _sized(Component child, {String width = '15rem'}) => div(styles: Styles(raw: {'width': width}), [child]);

/// 속성으로 고른 TimePicker 하나.
TimePicker _picker(
  Map<String, String> props, {
  required String? value,
  required CoreValueChanged<String> onChanged,
}) => TimePicker(
  value: value,
  placeholder: props['placeholder'],
  use24HourFormat: page.demoUse24Hour(props),
  showSeconds: previewFlag(props, 'showSeconds'),
  minuteInterval: page.demoMinuteInterval(props),
  mode: previewEnum(CorePromptMode.values, props['mode'], CorePromptMode.popover),
  dialogTitle: props['mode'] == 'dialog' ? const Text(page.demoDialogTitle) : null,
  errorText: props['errorText'],
  enabled: previewFlag(props, 'enabled', fallback: true),
  onChanged: onChanged,
);

/// 장면의 정지 그림 — 값이 바뀌지 않는다.
Component _still(Map<String, String> props) => _picker(props, value: page.demoTimeValue(props), onChanged: (_) {});

/// 이름 아래에 칸을 하나씩 두는 다섯 칸 격자.
Component _grid(List<(String, Map<String, String>)> cells) => div(classes: 'docs-demo-field-states', [
  for (final (name, _) in cells) span([Text(name).labelSmall.onSurfaceVariant]),
  for (final (_, props) in cells) div(styles: Styles(raw: {'width': '9.5rem'}), [_still(props)]),
]);

/// 속성이 바뀌면 미리보기를 새로 만든다 — Web 의 TimePicker 는 칸의 시각을 `value` 가
/// 바뀔 때만 다시 계산하므로, 시간 형식 같은 속성을 바꾼 뒤에도 칸이 맞게 시작한다.
Component _timePicker(Map<String, String> props, String? label) =>
    _sized(_TimePickerPreview(key: ValueKey(page.demoPropsKey(props)), props: props));

/// 저장한 시각을 받아 다시 넘기는 미리보기. TimePicker 는 값을 스스로 바꾸지
/// 않아, 다시 넘기지 않으면 저장해도 트리거가 그대로다.
class _TimePickerPreview extends StatefulComponent {
  const _TimePickerPreview({required this.props, super.key});

  final Map<String, String> props;

  @override
  State<_TimePickerPreview> createState() => _TimePickerPreviewState();
}

class _TimePickerPreviewState extends State<_TimePickerPreview> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = page.demoTimeValue(component.props);
  }

  void _handleChanged(String value) => setState(() => _value = value);

  @override
  Component build(BuildContext context) => _picker(component.props, value: _value, onChanged: _handleChanged);
}
