/// Autocomplete 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `autocomplete_web.dart` · `autocomplete_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자(추천 목록 · 안내 · 입력 값)는 아래 상수 한 곳에 둔다 — 두
/// 플랫폼의 필드 · 목록 그림과 플레이그라운드의 코드가 같은 글자를 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/autocomplete.md`.
const String slug = 'autocomplete';

/// 미리보기 · 코드가 함께 쓰는 추천 목록.
///
/// [demoQuery] 가 앞(서울역 · 서울숲) · 끝(남서울) · 가운데(구서울역사)에 걸리는
/// 추천을 함께 둔다 — 일치 구간이 어디에 있어도 같게 강조되는 것을 보인다.
const List<String> demoSuggestions = ['서울역', '서울숲', '남서울', '구서울역사', '부산역', '대전역'];

/// 비어 있을 때의 안내.
const String demoPlaceholder = '역 이름 검색';

/// 목록 그림과 `값 있음` 의 입력 값.
const String demoQuery = '서울';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 무대의 필드는 실제 `Autocomplete` 다 — 눌러서 입력하면 목록이 열린다.
/// `mode` 는 고른 추천을 입력에 적용하는 방식이라 화면에서는 목록을 열고
/// 골라 봐야 차이가 보인다. 크기 · variant 축은 없다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'mode': 'replaceWord', 'placeholder': demoPlaceholder},
  controls: [
    DocsPlaygroundChoice(label: 'mode', prop: 'mode', options: ['replaceAll', 'replaceWord', 'append']),
    DocsPlaygroundFlag(label: '값 있음', on: {'value': demoQuery}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _autocompleteCode,
);

/// 크기 표. Autocomplete 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// [query] 로 거른 추천 — `Autocomplete` 의 거르기와 같은 규칙이다(앞뒤 공백을
/// 지운 [query] 를 대소문자 없이 포함하는 추천, [query] 가 비면 전부). 목록
/// 그림이 행을 고를 때 쓴다.
List<String> demoFiltered(String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return demoSuggestions;
  return [
    for (final suggestion in demoSuggestions)
      if (suggestion.toLowerCase().contains(needle)) suggestion,
  ];
}

String _autocompleteCode(Map<String, String> props, String? label) {
  final mode = props['mode'] ?? CoreAutocompleteMode.defaultMode.name;
  final lines = [
    'suggestions: const [',
    for (final suggestion in demoSuggestions) "  '$suggestion',",
    '],',
    if (props['value'] case final v?) "value: '$v',",
    if (props['placeholder'] case final v?) "placeholder: '$v',",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    if (mode != CoreAutocompleteMode.defaultMode.name) 'mode: CoreAutocompleteMode.$mode,',
    'onChanged: setQuery,',
    'onSelected: setStation,',
  ];
  return 'Autocomplete(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
