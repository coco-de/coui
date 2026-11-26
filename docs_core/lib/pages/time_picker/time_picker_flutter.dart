/// TimePicker 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="time-picker/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`time_picker_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대에는 트리거를 둔다. 패널은 트리거를 누르면 열린다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'time_picker_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _timePicker;

/// 장면 이름(`time-picker/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'time-picker/anatomy': () => _sized(_still(const {'value': page.demoValue, 'use24HourFormat': 'true'})),
  'time-picker/states': () => _grid(page.demoStates),
  'time-picker/formats': () => _grid(page.demoFormats),
  'time-picker/do-range-check': () => _sized(
    _still(const {
      'value': page.demoOutOfRangeValue,
      'use24HourFormat': 'true',
      'errorText': page.demoRangeError,
    }),
    width: 176,
  ),
  'time-picker/do-visible-name': () => _sized(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpace.space4,
      children: [
        const FormLabel(label: Text(page.demoFieldName)),
        _still(const {'use24HourFormat': 'true'}),
      ],
    ),
    width: 176,
  ),
  'time-picker/related-date-picker': () => _sized(
    DatePicker(placeholder: '날짜 선택', onChanged: (_) {}),
    width: 192,
  ),
  'time-picker/related-select': () => _sized(
    Select<String>(
      placeholder: '시각 선택',
      onChanged: (_) {},
      items: [for (final slot in page.demoSlots) CoreSelectItem(value: slot, label: slot)],
    ),
    width: 192,
  ),
};

Widget _sized(Widget child, {double width = 240}) => SizedBox(width: width, child: child);

/// 속성으로 고른 TimePicker 하나.
TimePicker _picker(
  Map<String, String> props, {
  required String? value,
  required ValueChanged<String> onChanged,
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
Widget _still(Map<String, String> props) => _picker(props, value: page.demoTimeValue(props), onChanged: (_) {});

/// 이름 아래에 칸을 하나씩 두는 격자 — Web 의 `.docs-demo-field-states` 와 같은 모양.
Widget _grid(List<(String, Map<String, String>)> cells) => Wrap(
  spacing: CoreSpace.space12,
  runSpacing: CoreSpace.space12,
  children: [
    for (final (name, props) in cells)
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpace.space8,
        children: [
          Text(name).labelSmall.onSurfaceVariant,
          SizedBox(width: 152, child: _still(props)),
        ],
      ),
  ],
);

/// 속성이 바뀌면 미리보기를 새로 만든다 — Web 파일과 같은 규칙이다.
Widget _timePicker(Map<String, String> props, String? label) =>
    _sized(_TimePickerPreview(key: ValueKey(page.demoPropsKey(props)), props: props));

/// 저장한 시각을 받아 다시 넘기는 미리보기. TimePicker 는 값을 스스로 바꾸지
/// 않아, 다시 넘기지 않으면 저장해도 트리거가 그대로다.
class _TimePickerPreview extends StatefulWidget {
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
    _value = page.demoTimeValue(widget.props);
  }

  void _handleChanged(String value) => setState(() => _value = value);

  @override
  Widget build(BuildContext context) => _picker(widget.props, value: _value, onChanged: _handleChanged);
}
