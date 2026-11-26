/// ColorPicker 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `color_picker_web.dart` · `color_picker_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// ColorPicker 의 색 타입은 플랫폼마다 다르다(Flutter `Color`, Web hex 문자열).
/// 속성 `color` 는 Web 의 hex 문자열 모양 하나로 두고, Flutter 빌더와 코드가
/// 거기서 `Color` 를 만든다. 그래서 플레이그라운드의 코드도 두 벌이다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/color-picker.md`.
const String slug = 'color-picker';

/// 미리보기가 처음 고른 색.
const String demoColor = '#6750A4';

/// 속성 `color` 의 값 — 색을 고르지 않은 상태.
const String demoNoColor = 'none';

/// 최근 색 장면의 기록 — 최근 것부터.
const List<String> demoRecentColors = ['#6750A4', '#3B82F6', '#10B981', '#F59E0B', '#E11D48', '#0F172A'];

/// 라벨 장면의 필드 라벨.
const String demoFieldLabel = '브랜드 색';

/// 관련 컴포넌트 카드의 Select 선택지 — 값과 라벨.
const List<(String, String)> demoNamedColors = [('blue', '파랑'), ('green', '초록'), ('red', '빨강')];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `dialog` 모드는 고르지 않는다 — 지금은 `popover` 와 같게 그려진다. 크기 축은
/// 없다. `showHexInput` 은 팝오버 모드의 트리거에만 닿는다(인라인 패널은 늘
/// HEX 칸을 갖는다).
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'promptMode': 'popover', 'pickerMode': 'rgb'},
  controls: [
    DocsPlaygroundChoice(label: 'promptMode', prop: 'promptMode', options: ['popover', 'inline'], segmented: true),
    DocsPlaygroundChoice(label: 'pickerMode', prop: 'pickerMode', options: ['rgb', 'hsl', 'hsv'], segmented: true),
    DocsPlaygroundFlag(label: '색 없음', on: {'color': demoNoColor}),
    DocsPlaygroundFlag(label: 'showHexInput', on: {'showHexInput': 'true'}),
    DocsPlaygroundFlag(label: 'showAlpha', on: {'showAlpha': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _flutterCode,
  webCode: _webCode,
);

/// 크기 표. ColorPicker 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 → 고른 색의 `#RRGGBB`. 색 없음이면(또는 hex 가 아니면) `null`.
String? demoHexOf(Map<String, String> props) {
  final raw = props['color'] ?? demoColor;
  return isValidHexColor(raw) ? normalizeHexColor(raw) : null;
}

/// 속성이 바뀌면 미리보기를 새로 만드는 키.
///
/// 호출자가 넘기는 `color` · `promptMode` · `pickerMode` 가 바뀐 것을 열려 있는
/// picker 가 모두 따라가지는 않는다(페이지의 알려진 제약) — 플레이그라운드는
/// 새로 만들어 고른 속성 그대로를 보인다.
String demoPreviewKey(Map<String, String> props) => '${props['promptMode']}|${props['pickerMode']}|${props['color']}';

String _flutterCode(Map<String, String> props, String? label) {
  final hex = demoHexOf(props);
  return _code(props, hex == null ? 'Color(0x00000000)' : 'Color(0xFF${hex.substring(1)})');
}

String _webCode(Map<String, String> props, String? label) => _code(props, "'${demoHexOf(props) ?? ''}'");

String _code(Map<String, String> props, String color) {
  final promptMode = props['promptMode'] ?? 'popover';
  final pickerMode = props['pickerMode'] ?? 'rgb';
  final lines = [
    'color: $color,',
    'onChanged: setColor,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    if (previewFlag(props, 'showAlpha')) 'showAlpha: true,',
    if (previewFlag(props, 'showHexInput')) 'showHexInput: true,',
    if (pickerMode != 'rgb') 'pickerMode: CoreColorPickerMode.$pickerMode,',
    if (promptMode != 'popover') 'promptMode: CoreColorPickerPromptMode.$promptMode,',
  ];
  return 'ColorPicker(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
