/// ColorPicker 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="color-picker/...">` 가 읽는다. 같은 이름의 Web 파일(`color_picker_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 열린 패널을 보이는 장면은 그림이 아니라 인라인 모드(`promptMode: inline`)의
/// 실제 `ColorPicker` 다. 팝오버 패널은 같은 부품을 쓰고 아래 줄만 다르다 —
/// 실제 팝오버는 플레이그라운드의 트리거가 연다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'color_picker_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _colorPicker;

/// 장면 이름(`color-picker/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'color-picker/anatomy': () => _picker(),
  'color-picker/panel-anatomy': () => _withRecent(_picker(inline: true, showAlpha: true)),
  'color-picker/popover': () => _columns([
    ('기본', _picker()),
    ('showHexInput: true', _picker(showHexInput: true)),
  ]),
  'color-picker/inline': () => _picker(inline: true),
  'color-picker/states': () => _columns([
    ('고른 색', _picker()),
    ('색 없음', _picker(hex: null)),
    ('비활성', _picker(enabled: false)),
    ('비활성 · 색 없음', _picker(hex: null, enabled: false)),
  ]),
  'color-picker/recent': () => _withRecent(_picker(inline: true)),
  'color-picker/do-label': () => SizedBox(
    width: 240,
    child: FormField(label: page.demoFieldLabel, child: _picker()),
  ),
  'color-picker/dont-no-label': () => _picker(),
  'color-picker/related-select': () => SizedBox(
    width: 192,
    child: Select<String>(
      placeholder: '색 고르기',
      onChanged: (_) {},
      items: [for (final (value, label) in page.demoNamedColors) CoreSelectItem(value: value, label: label)],
    ),
  ),
};

Widget _colorPicker(Map<String, String> props, String? label) => ColorPicker(
  key: ValueKey(page.demoPreviewKey(props)),
  color: _color(page.demoHexOf(props)),
  onChanged: (_) {},
  enabled: previewFlag(props, 'enabled', fallback: true),
  showAlpha: previewFlag(props, 'showAlpha'),
  showHexInput: previewFlag(props, 'showHexInput'),
  pickerMode: previewEnum(CoreColorPickerMode.values, props['pickerMode'], CoreColorPickerContract.defaultPickerMode),
  promptMode: previewEnum(
    CoreColorPickerPromptMode.values,
    props['promptMode'],
    CoreColorPickerContract.defaultPromptMode,
  ),
);

/// `#RRGGBB` → 불투명한 색. `null` 은 색 없음(알파 0)이다.
Color _color(String? hex) => hex == null ? const Color(0x00000000) : Color(CoreColor.fromHex(hex).value);

Widget _picker({
  String? hex = page.demoColor,
  bool inline = false,
  bool enabled = true,
  bool showAlpha = false,
  bool showHexInput = false,
}) => ColorPicker(
  color: _color(hex),
  onChanged: (_) {},
  enabled: enabled,
  showAlpha: showAlpha,
  showHexInput: showHexInput,
  promptMode: inline ? CoreColorPickerPromptMode.inline : CoreColorPickerContract.defaultPromptMode,
);

/// 최근 색이 있는 기록 범위 — 패널의 "최근 사용" 줄이 보인다.
Widget _withRecent(Widget child) => RecentColorsScope(
  initialRecentColors: [for (final hex in page.demoRecentColors) CoreColor.fromHex(hex)],
  child: child,
);

/// 이름을 단 미리보기를 나란히 놓는다.
Widget _columns(List<(String, Widget)> columns) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  children: [
    for (final (name, child) in columns)
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space8,
        children: [Text(name).labelSmall.onSurfaceVariant, child],
      ),
  ],
);
