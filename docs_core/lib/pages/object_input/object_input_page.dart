/// ObjectInput 페이지 — 플레이그라운드와 칸 묶음. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `object_input_web.dart` · `object_input_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// ObjectInput 에는 variant 도 크기 단계도 없다. 바꿔 볼 것은 어떤 칸을
/// 묶는가(`fields` 와 구분자)라, 플레이그라운드는 칸 묶음을 고르게 한다. 두
/// 플랫폼 빌더와 코드가 같은 묶음을 읽도록 묶음 · 예시 값 · 해석을 이 파일 한
/// 곳에 둔다. 크기 단계(`defaultsBySize`)가 없으므로 크기 표는 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/object-input.md`.
const String slug = 'object-input';

/// 연 · 월 · 일 — 숫자만 받는 세 칸.
const List<CoreObjectInputField> objectInputDateFields = [
  CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4, pattern: r'\d'),
  CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2, pattern: r'\d'),
  CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2, pattern: r'\d'),
];

/// 시 · 분 — 숫자만 받는 두 칸.
const List<CoreObjectInputField> objectInputTimeFields = [
  CoreObjectInputField(key: 'hour', placeholder: 'HH', maxLength: 2, pattern: r'\d'),
  CoreObjectInputField(key: 'minute', placeholder: 'MM', maxLength: 2, pattern: r'\d'),
];

/// 날짜 칸의 예시 값 — 칸 `key` → 값.
const Map<String, String> objectInputDateExample = {'year': '2026', 'month': '11', 'day': '25'};

/// 시 · 분 칸의 예시 값.
const Map<String, String> objectInputTimeExample = {'hour': '09', 'minute': '30'};

/// 카드와 상태 장면의 시 · 분 칸. 기본 칸 폭에 담기는 두 자리 값과
/// `placeholder` 만 쓴다 — 칸보다 넓은 글자는 잘린다. "라벨 없이" 카드는 이
/// 칸이 무엇을 받는지 알 수 없다는 것을 보인다.
const List<CoreObjectInputField> objectInputClockFields = [
  CoreObjectInputField(key: 'hour', placeholder: '00', maxLength: 2, pattern: r'\d'),
  CoreObjectInputField(key: 'minute', placeholder: '00', maxLength: 2, pattern: r'\d'),
];

/// [objectInputClockFields] 에서 `pattern` 만 뺀 칸 — 어떤 글자든 들어간다.
const List<CoreObjectInputField> objectInputUnfilteredClockFields = [
  CoreObjectInputField(key: 'hour', placeholder: '00', maxLength: 2),
  CoreObjectInputField(key: 'minute', placeholder: '00', maxLength: 2),
];

/// `pattern` 없는 칸에 사용자가 칠 수 있는 값의 예.
const Map<String, String> objectInputUnfilteredExample = {'hour': 'am', 'minute': '??'};

/// 구조 그림의 칸 — 기본 칸 폭에 담기는 두 자리 칸 셋.
const List<CoreObjectInputField> objectInputAnatomyFields = [
  CoreObjectInputField(key: 'year', placeholder: '00', maxLength: 2, pattern: r'\d'),
  CoreObjectInputField(key: 'month', placeholder: '00', maxLength: 2, pattern: r'\d'),
  CoreObjectInputField(key: 'day', placeholder: '00', maxLength: 2, pattern: r'\d'),
];

/// `object-input/widths` 장면의 칸 — 설명과 칸 하나. 두 플랫폼 장면이 함께
/// 읽는다. 폭을 견주는 장면이라 `maxLength` 칸의 `placeholder` 는 칸에 담기는
/// 짧은 글자다(`maxLength` 가 있으면 폭은 `placeholder` 와 무관하다).
const List<(String, CoreObjectInputField)> objectInputWidthSamples = [
  ('maxLength: 2', CoreObjectInputField(key: 'two', placeholder: '00', maxLength: 2)),
  ('maxLength: 4', CoreObjectInputField(key: 'four', placeholder: '00', maxLength: 4)),
  ('maxLength: 6', CoreObjectInputField(key: 'six', placeholder: '00', maxLength: 6)),
  ('maxLength 없음 · placeholder 5글자', CoreObjectInputField(key: 'free', placeholder: '자유 입력')),
];

/// 상태 장면의 Focus 칸 — 포커스 테두리 색(Core 기본값)을 쉬는 테두리와 Hover
/// 테두리에 함께 고정한다. 장면은 포커스를 켤 수 없고, Hover 테두리를 함께
/// 고정하지 않으면 포인터를 올렸을 때 Focus 모양이 사라진다.
const CoreObjectInputStyle objectInputFocusLookStyle = CoreObjectInputStyle(
  borderColor: CoreObjectInputStyle.defaultFocusBorderColor,
  hoverBorderColor: CoreObjectInputStyle.defaultFocusBorderColor,
);

/// 플레이그라운드가 고르는 칸 묶음 하나.
class ObjectInputPreset {
  /// 칸 묶음을 만든다.
  const ObjectInputPreset({
    required this.name,
    required this.fields,
    required this.separator,
    required this.example,
    required this.icon,
    required this.callback,
  });

  /// 플레이그라운드의 선택지 이름.
  final String name;

  /// 칸 목록.
  final List<CoreObjectInputField> fields;

  /// 칸 사이 글자.
  final String separator;

  /// 예시 값 — 칸 `key` → 값.
  final Map<String, String> example;

  /// 앞 아이콘 — Lucide kebab-case 이름.
  final String icon;

  /// 코드의 `onChanged` 에 넘기는 함수 이름.
  final String callback;
}

/// 플레이그라운드의 칸 묶음 — 첫 항목이 처음 고른 것.
const List<ObjectInputPreset> objectInputPresets = [
  ObjectInputPreset(
    name: 'date',
    fields: objectInputDateFields,
    separator: '/',
    example: objectInputDateExample,
    icon: 'calendar',
    callback: 'setBirthDate',
  ),
  ObjectInputPreset(
    name: 'time',
    fields: objectInputTimeFields,
    separator: ':',
    example: objectInputTimeExample,
    icon: 'clock',
    callback: 'setStartTime',
  ),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'fields': 'date'},
  controls: [
    DocsPlaygroundChoice(
      label: 'fields',
      prop: 'fields',
      options: [for (final preset in objectInputPresets) preset.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '처음 값', on: {'filled': 'true'}),
    const DocsPlaygroundFlag(label: '앞 아이콘', on: {'leading': 'true'}),
    const DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _objectInputCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// ObjectInput 의 상자는 늘 컨트롤 높이 사다리의 `lg` 행
/// (`CoreObjectInputStyle.defaultHeight`)이다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `fields` → 칸 묶음. 없거나 모르는 이름이면 첫 묶음.
ObjectInputPreset objectInputPresetFor(Map<String, String> props) {
  final name = props['fields'];
  for (final preset in objectInputPresets) {
    if (preset.name == name) return preset;
  }
  return objectInputPresets.first;
}

/// 미리보기의 `values` — `filled` 를 켜면 묶음의 예시 값, 아니면 `null`.
Map<String, String>? objectInputPreviewValues(Map<String, String> props) =>
    previewFlag(props, 'filled') ? objectInputPresetFor(props).example : null;

/// 미리보기의 키 — 칸 묶음이나 처음 값이 바뀌면 새 입력창으로 그린다.
///
/// ObjectInput 은 `values` 를 처음에만 읽고, 칸 수가 같은 `fields` 로 바뀌면
/// 칸의 값을 다시 읽지 않는다.
String objectInputPreviewKey(Map<String, String> props) =>
    '${objectInputPresetFor(props).name}|${previewFlag(props, 'filled')}';

String _objectInputCode(Map<String, String> props, String? label) {
  final preset = objectInputPresetFor(props);
  final values = objectInputPreviewValues(props);
  final lines = [
    'fields: const [',
    for (final field in preset.fields) '  ${_fieldSource(field)},',
    '],',
    "separator: '${preset.separator}',",
    if (values != null) 'values: const ${_valuesSource(values)},',
    if (previewFlag(props, 'leading')) 'leading: Icon(LucideIcons.${docsIconIdentifier(preset.icon)}),',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: ${preset.callback},',
  ];
  return 'ObjectInput(\n${lines.map((line) => '  $line').join('\n')}\n)';
}

/// 칸 하나를 코드로.
String _fieldSource(CoreObjectInputField field) {
  final arguments = [
    "key: '${field.key}'",
    "placeholder: '${field.placeholder}'",
    if (field.maxLength case final maxLength?) 'maxLength: $maxLength',
    if (field.pattern case final pattern?) "pattern: r'$pattern'",
  ];
  return 'CoreObjectInputField(${arguments.join(', ')})';
}

/// 값 맵을 코드로.
String _valuesSource(Map<String, String> values) {
  final entries = [for (final MapEntry(:key, :value) in values.entries) "'$key': '$value'"];
  return '{${entries.join(', ')}}';
}
