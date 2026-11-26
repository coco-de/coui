/// Kbd 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `kbd_web.dart` · `kbd_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 셋이다: `keys`(공백으로 나눈 키 목록), `keySeparatorSpacing`
/// (CoreSpace 단계의 숫자), `keyShadow`(`xs` 면 키마다 그림자). 두 플랫폼
/// 빌더와 코드가 같은 뜻으로 읽도록 해석은 이 파일 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/kbd.md`.
const String slug = 'kbd';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'keys': 'Ctrl C', 'keySeparatorSpacing': '4'},
  controls: [
    DocsPlaygroundChoice(
      label: 'keys',
      prop: 'keys',
      options: ['Esc', 'Ctrl C', 'Ctrl Shift P', '⌃ ⇧ ⌘ 4'],
    ),
    DocsPlaygroundChoice(
      label: 'keySeparatorSpacing',
      prop: 'keySeparatorSpacing',
      options: ['4', '8', '12'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '키마다 그림자', on: {'keyShadow': 'xs'}),
  ],
  code: _kbdCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `keys` → 키 목록. 비었으면 `Ctrl` · `C`.
List<String> kbdPreviewKeys(Map<String, String> props) {
  final keys = [
    for (final key in (props['keys'] ?? '').split(' '))
      if (key.isNotEmpty) key,
  ];
  return keys.isEmpty ? const ['Ctrl', 'C'] : keys;
}

/// 속성의 `keySeparatorSpacing` → 간격(logical px). `CoreSpace` 의 단계가
/// 아니면 `null` — 그때 미리보기는 기본 간격을 그린다.
double? kbdPreviewSpacing(Map<String, String> props) {
  final px = double.tryParse(props['keySeparatorSpacing'] ?? '');
  return px != null && CoreSpace.steps.contains(px) ? px : null;
}

/// 속성의 `keyShadow` 가 `xs` 인가.
bool kbdPreviewShadow(Map<String, String> props) => props['keyShadow'] == 'xs';

/// 아이콘 키의 글리프 모습. `Kbd` 는 아이콘의 크기 · 색을 정하지 않으므로
/// 장면이 `Icon` 에 직접 준다 — 두 플랫폼 장면이 함께 읽는다.
const CoreIconStyle kbdIconKeyStyle = CoreIconStyle(
  size: CoreIconSize.size12,
  color: CoreColor.token(CoreColors.onSurfaceVariant),
);

/// 키 수를 늘어놓는 장면의 설명과 키 목록 — 두 플랫폼 장면이 함께 읽는다.
const List<(String, List<String>)> kbdCountSamples = [
  ('1개', ['Esc']),
  ('2개', ['Ctrl', 'C']),
  ('3개', ['Ctrl', 'Shift', 'P']),
  ('4개', ['⌃', '⇧', '⌘', '4']),
];

/// 단축키 목록 장면의 동작 이름과 키 — 두 플랫폼 장면이 함께 읽는다.
const List<(String, List<String>)> kbdShortcutSamples = [
  ('복사', ['Ctrl', 'C']),
  ('붙여넣기', ['Ctrl', 'V']),
  ('전체 선택', ['Ctrl', 'A']),
  ('저장', ['Ctrl', 'S']),
  ('실행 취소', ['Ctrl', 'Z']),
  ('커맨드 팔레트 (macOS)', ['⌘', 'K']),
  ('화면 일부 복사 (macOS)', ['⌃', '⇧', '⌘', '4']),
];

/// `kbd/activator` 장면의 키. Flutter 장면은 같은 단축키를
/// `kbdKeysFromActivator` 로 만들고, `ShortcutActivator` 가 없는 Web 장면은
/// 이 목록을 그대로 넘긴다.
const List<String> kbdActivatorSampleKeys = ['Ctrl', 'Shift', 'S'];

String _kbdCode(Map<String, String> props, String? label) {
  final keys = kbdPreviewKeys(props).map((key) => "'$key'").join(', ');
  final spacing = kbdPreviewSpacing(props);
  final style = [
    if (spacing != null && spacing != CoreKbdStyle.defaultKeySeparatorSpacing)
      'keySeparatorSpacing: CoreSpace.space${spacing.toInt()},',
    if (kbdPreviewShadow(props)) 'keyShadow: CoreShadow.xs,',
  ];
  if (style.isEmpty) return 'const Kbd(keys: [$keys])';
  return [
    'const Kbd(',
    '  keys: [$keys],',
    '  kbdStyle: CoreKbdStyle(',
    for (final line in style) '    $line',
    '  ),',
    ')',
  ].join('\n');
}
