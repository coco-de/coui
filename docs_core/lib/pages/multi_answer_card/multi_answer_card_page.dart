/// MultiAnswerCard 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `multi_answer_card_web.dart` · `multi_answer_card_flutter.dart` 가
/// 그린다. 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// MultiAnswerCard 에는 variant 와 크기 속성이 없다. 플레이그라운드는 선택 ·
/// 활성 상태와 답의 길이를 바꾼다. 답의 길이를 고르는 `answer` 는 위젯 속성이
/// 아니라 `child` 에 넣을 글자라서, 두 플랫폼 빌더와 코드가 이 파일의 글자를
/// 함께 읽는다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/multi-answer-card.md`.
const String slug = 'multi-answer-card';

/// 미리보기의 답 — 속성 빌더와 장면이 함께 읽는다.
const String multiAnswerPreviewAnswer = '운동을 꾸준히 해요';

/// 줄이 바뀔 만큼 긴 답.
const String multiAnswerLongAnswer = '일주일에 세 번 넘게, 한 번에 30분 이상 땀이 날 만큼 몸을 움직여요';

/// `multi-answer-card/content` 장면의 두 줄 답 — 윗줄.
const String multiAnswerTwoLineTitle = '아침을 챙겨 먹어요';

/// `multi-answer-card/content` 장면의 두 줄 답 — 아랫줄.
const String multiAnswerTwoLineNote = '일주일에 5일 이상';

/// `multi-answer-card/list` 장면의 답 — (`value`, 글, `selected`).
const List<(String, String, bool)> multiAnswerListRows = [
  ('exercise', multiAnswerPreviewAnswer, true),
  ('breakfast', multiAnswerTwoLineTitle, false),
  ('sleep', '7시간 넘게 자요', true),
];

/// `multi-answer-card/states` 장면의 상태 — (이름, `selected`, `enabled`).
const List<(String, bool, bool)> multiAnswerStateRows = [
  ('기본', false, true),
  ('고름', true, true),
  ('비활성', false, false),
  ('고름 · 비활성', true, false),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'selected': 'true'},
  label: multiAnswerPreviewAnswer,
  controls: [
    DocsPlaygroundFlag(label: '선택', on: {'selected': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
    DocsPlaygroundFlag(label: '긴 답', on: {'answer': multiAnswerLongAnswer}),
  ],
  code: _multiAnswerCardCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// 카드에는 크기 속성이 없고 `CoreMultiAnswerCardStyle` 에 `defaultsBySize` 도
/// 없다 — 안의 체크박스는 늘 `lg` 다.
DocsSizeSpec Function()? get sizeSpec => null;

String _multiAnswerCardCode(Map<String, String> props, String? label) {
  final lines = [
    "value: 'exercise',",
    'selected: ${previewFlag(props, 'selected')},',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: toggleAnswer,',
    "child: Text('${props['answer'] ?? label ?? multiAnswerPreviewAnswer}'),",
  ];
  return 'MultiAnswerCard<String>(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
