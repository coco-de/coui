/// IndexedSwitcher 페이지 — 플레이그라운드와 장면이 함께 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `indexed_switcher_web.dart` · `indexed_switcher_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에
/// 싣는다.
///
/// IndexedSwitcher 는 스스로 그리는 겉모습이 없고, 화면을 바꾸는 순간의
/// 전환만 가진다. 그래서 플레이그라운드는 보여 줄 순번(`index`)과 전환
/// 시간(`indexedSwitcherStyle=slow`)만 바꾼다. 미리보기의 화면마다 누른
/// 횟수를 세는 버튼이 있어, 다른 화면에 다녀와도 상태가 남는 것이 보인다.
/// variant · 크기 축은 없다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/indexed-switcher.md`.
const String slug = 'indexed-switcher';

/// 미리보기 화면의 이름 — 두 플랫폼 빌더 · 장면이 함께 쓴다.
const List<String> kIndexedSwitcherScreenNames = ['홈', '검색', '설정'];

/// 코드에 적는 화면 자리 — [kIndexedSwitcherScreenNames] 와 같은 순서다.
const List<String> kIndexedSwitcherScreenTypes = ['HomeScreen', 'SearchScreen', 'SettingsScreen'];

/// 플레이그라운드의 `indexedSwitcherStyle=slow` — 두 시간을 모두 늘려 전환의
/// 두 단계가 눈에 보이게 한다. 둘 다 500ms 이하라 동작 줄이기에서는 바로
/// 바뀐다.
const CoreIndexedSwitcherStyle kIndexedSwitcherSlowStyle = CoreIndexedSwitcherStyle(
  exitDuration: Duration(milliseconds: CoreDuration.moderate),
  enterDuration: Duration(milliseconds: CoreDuration.slow),
);

/// 속성의 `index` → 보여 줄 순번. 없거나 범위를 벗어난 값은 0.
int indexedSwitcherPreviewIndex(Map<String, String> props) {
  final index = int.tryParse(props['index'] ?? '') ?? 0;
  return index >= 0 && index < kIndexedSwitcherScreenNames.length ? index : 0;
}

/// 속성의 `indexedSwitcherStyle` → 미리보기의 전환 스타일. `slow` 만 읽는다.
CoreIndexedSwitcherStyle? indexedSwitcherPreviewStyle(Map<String, String> props) =>
    props['indexedSwitcherStyle'] == 'slow' ? kIndexedSwitcherSlowStyle : null;

/// `indexed-switcher/fade-through` 장면의 네 순간 — 아래 설명, 칸의 글자, 그
/// 글자의 진하기. 시간은 Core 기본값에서 읽는다.
final List<(String, String, double)> kIndexedSwitcherFadeFrames = () {
  final exit = CoreIndexedSwitcherStyle.defaultExitDuration.inMilliseconds;
  final total = exit + CoreIndexedSwitcherStyle.defaultEnterDuration.inMilliseconds;
  return [
    ('바꾸기 전', kIndexedSwitcherScreenNames[0], 1.0),
    ('0~${exit}ms · 앞 화면이 흐려짐', kIndexedSwitcherScreenNames[0], 0.4),
    ('$exit~${total}ms · 새 화면이 나타남', kIndexedSwitcherScreenNames[1], 0.4),
    ('${total}ms 뒤', kIndexedSwitcherScreenNames[1], 1.0),
  ];
}();

/// `indexed-switcher/sizing` 장면의 작은 화면 이름.
const String kIndexedSwitcherSmallScreen = '작은 화면';

/// `indexed-switcher/sizing` 장면의 큰 화면 이름.
const String kIndexedSwitcherLargeScreen = '큰 화면';

/// `indexed-switcher/sizing` 장면의 두 칸 설명.
const List<String> kIndexedSwitcherSizingCaptions = ['index: 0', 'index: 1'];

/// `indexed-switcher/related-switcher` 장면의 보기 이름.
const List<String> kIndexedSwitcherStepNames = ['1단계', '2단계', '3단계'];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'index': '0'},
  controls: [
    DocsPlaygroundChoice(label: 'index', prop: 'index', options: ['0', '1', '2'], segmented: true),
    DocsPlaygroundFlag(label: '느린 전환', on: {'indexedSwitcherStyle': 'slow'}),
  ],
  code: _indexedSwitcherCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// IndexedSwitcher 에는 크기 행(`defaultsBySize`)이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _indexedSwitcherCode(Map<String, String> props, String? label) {
  final lines = [
    'index: ${indexedSwitcherPreviewIndex(props)},',
    if (indexedSwitcherPreviewStyle(props) != null) ...[
      'indexedSwitcherStyle: const CoreIndexedSwitcherStyle(',
      '  exitDuration: Duration(milliseconds: CoreDuration.moderate),',
      '  enterDuration: Duration(milliseconds: CoreDuration.slow),',
      '),',
    ],
    'children: const [',
    for (final screen in kIndexedSwitcherScreenTypes) '  $screen(),',
    '],',
  ];
  return 'IndexedSwitcher(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
