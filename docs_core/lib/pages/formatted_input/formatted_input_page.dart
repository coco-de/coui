/// FormattedInput 페이지 — 플레이그라운드와 마스크 프리셋. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `formatted_input_web.dart` · `formatted_input_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// FormattedInput 의 축은 마스크(`parts`)다. 플레이그라운드는 실제로 쓰이는
/// 마스크 몇 개를 고르게 하고, 두 플랫폼 빌더와 코드가 같은 프리셋을 읽도록
/// 프리셋 · 예시 값 · 해석을 이 파일 한 곳에 둔다. 크기 단계가 없으므로 크기
/// 표는 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/formatted-input.md`.
const String slug = 'formatted-input';

/// 플레이그라운드 · 장면이 고르는 마스크 하나.
class FormattedInputPreset {
  /// 프리셋을 만든다.
  const FormattedInputPreset({
    required this.name,
    required this.parts,
    required this.example,
    required this.icon,
    required this.callback,
    required this.namedConstructor,
  });

  /// 플레이그라운드의 선택지 이름 — 기본 마스크면 생성자 이름(`koreanPhone`).
  final String name;

  /// 마스크.
  final List<CoreFormattedInputPart> parts;

  /// 예시 값 — 편집 자리만 이어 붙인 값(구분자 없음).
  final String example;

  /// 앞 아이콘 — Lucide kebab-case 이름.
  final String icon;

  /// 코드의 `onChanged` 에 넘기는 함수 이름.
  final String callback;

  /// `FormattedInput.<name>` 생성자가 있는가. 없으면 `parts` 로 만든다.
  final bool namedConstructor;

  /// 장면에 적는 이름 — 생성자, 또는 `parts` 로 만든 입력창.
  String get label => namedConstructor ? 'FormattedInput.$name' : 'FormattedInput(parts: …)';
}

/// 사업자등록번호 `___-__-_____` — 기본 마스크가 없어 `parts` 로 만드는 예.
const List<CoreFormattedInputPart> formattedInputBusinessNumberParts = [
  CoreFormattedInputPart.editable(length: 3, pattern: r'\d'),
  CoreFormattedInputPart.static('-'),
  CoreFormattedInputPart.editable(length: 2, pattern: r'\d'),
  CoreFormattedInputPart.static('-'),
  CoreFormattedInputPart.editable(length: 5, pattern: r'\d'),
];

/// 연-월-일 날짜 `____-__-__` — `.date`(`__/__/____`)와 순서가 다른 날짜.
const List<CoreFormattedInputPart> formattedInputIsoDateParts = [
  CoreFormattedInputPart.editable(length: 4, pattern: r'\d'),
  CoreFormattedInputPart.static('-'),
  CoreFormattedInputPart.editable(length: 2, pattern: r'\d'),
  CoreFormattedInputPart.static('-'),
  CoreFormattedInputPart.editable(length: 2, pattern: r'\d'),
];

/// 플레이그라운드 · 장면의 마스크 — 첫 항목이 처음 고른 것.
const List<FormattedInputPreset> formattedInputPresets = [
  FormattedInputPreset(
    name: 'koreanPhone',
    parts: CoreFormattedInputMasks.koreanPhone,
    example: '01012345678',
    icon: 'smartphone',
    callback: 'setPhone',
    namedConstructor: true,
  ),
  FormattedInputPreset(
    name: 'phone',
    parts: CoreFormattedInputMasks.phone,
    example: '5551234567',
    icon: 'phone',
    callback: 'setPhone',
    namedConstructor: true,
  ),
  FormattedInputPreset(
    name: 'creditCard',
    parts: CoreFormattedInputMasks.creditCard,
    example: '4111111111111111',
    icon: 'credit-card',
    callback: 'setCardNumber',
    namedConstructor: true,
  ),
  FormattedInputPreset(
    name: 'date',
    parts: CoreFormattedInputMasks.date,
    example: '12252026',
    icon: 'calendar',
    callback: 'setDate',
    namedConstructor: true,
  ),
  FormattedInputPreset(
    name: 'custom',
    parts: formattedInputBusinessNumberParts,
    example: '1234567890',
    icon: 'hash',
    callback: 'setBusinessNumber',
    namedConstructor: false,
  ),
];

/// 연-월-일 날짜 장면의 예시 값.
const String formattedInputIsoDateExample = '20261225';

/// 상태 장면의 Focus 칸 — 포커스 테두리 색(Core 기본값)을 쉬는 테두리와
/// Hover 테두리에 함께 고정한다. 장면은 포커스를 켤 수 없고, Hover 테두리를
/// 함께 고정하지 않으면 포인터를 올렸을 때 Focus 모양이 사라진다.
const CoreFormattedInputStyle formattedInputFocusLookStyle = CoreFormattedInputStyle(
  borderColor: CoreFormattedInputStyle.defaultFocusBorderColor,
  hoverBorderColor: CoreFormattedInputStyle.defaultFocusBorderColor,
);

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'mask': 'koreanPhone'},
  controls: [
    DocsPlaygroundChoice(
      label: '마스크',
      prop: 'mask',
      options: [for (final preset in formattedInputPresets) preset.name],
    ),
    const DocsPlaygroundFlag(label: '값', on: {'filled': 'true'}),
    const DocsPlaygroundFlag(label: '앞 아이콘', on: {'leading': 'true'}),
    const DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _formattedInputCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// FormattedInput 에는 크기 단계(`defaultsBySize`)가 없다 — 상자는 늘 컨트롤
/// 높이 사다리의 `lg` 행(`CoreFormattedInputStyle.defaultHeight`)이다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `mask` → 프리셋. 없거나 모르는 이름이면 첫 프리셋.
FormattedInputPreset formattedInputPresetFor(Map<String, String> props) {
  final name = props['mask'];
  for (final preset in formattedInputPresets) {
    if (preset.name == name) return preset;
  }
  return formattedInputPresets.first;
}

/// 미리보기의 `value` — `filled` 를 켜면 프리셋의 예시 값, 아니면 `null`.
String? formattedInputPreviewValue(Map<String, String> props) =>
    previewFlag(props, 'filled') ? formattedInputPresetFor(props).example : null;

/// 미리보기의 키 — 마스크와 값이 바뀌면 새 입력창으로 그린다.
///
/// 입력창은 `parts` 의 개수가 같은 마스크로 바뀌면 보이는 값을 다시 맞추지
/// 않고, Flutter 는 `value` 가 `null` 로 돌아가도 칸을 비우지 않는다. 그래서
/// 플레이그라운드는 마스크와 값이 바뀔 때마다 새로 만든다.
String formattedInputPreviewKey(Map<String, String> props) =>
    '${formattedInputPresetFor(props).name}|${formattedInputPreviewValue(props) ?? ''}';

String _formattedInputCode(Map<String, String> props, String? label) {
  final preset = formattedInputPresetFor(props);
  final value = formattedInputPreviewValue(props);
  final lines = [
    if (!preset.namedConstructor) 'parts: const [\n${_partsSource(preset.parts)}\n],',
    if (value != null) "value: '$value',",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    if (previewFlag(props, 'leading')) 'leading: Icon(LucideIcons.${docsIconIdentifier(preset.icon)}),',
    'onChanged: ${preset.callback},',
  ];
  final body = lines.join('\n').split('\n').map((line) => '  $line').join('\n');
  final constructor = preset.namedConstructor ? 'FormattedInput.${preset.name}' : 'FormattedInput';
  return '$constructor(\n$body\n)';
}

/// `parts` 목록을 코드로 — 한 줄에 한 부분.
String _partsSource(List<CoreFormattedInputPart> parts) => [
  for (final part in parts)
    if (part.editable)
      '  CoreFormattedInputPart.editable(length: ${part.length}'
          '${part.pattern == null ? '' : ", pattern: r'${part.pattern}'"}'
          '${part.placeholder == '_' ? '' : ", placeholder: '${part.placeholder}'"}),'
    else
      "  CoreFormattedInputPart.static('${part.text}'),",
].join('\n');
