/// MultipleChoice 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `multiple_choice_web.dart` · `multiple_choice_flutter.dart` 가 그린다.
/// 이 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성: `value` 는 처음 고른 옵션의 값(`null` 은 선택 없음), `allowUnselect` ·
/// `enabled` 는 위젯 속성 그대로, `many=true` 는 줄바꿈이 보이도록 옵션을
/// 여섯 개로 늘린다. 두 플랫폼 빌더와 코드가 같은 뜻으로 읽도록 해석은 이
/// 파일 한 곳에 둔다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/multiple-choice.md`.
const String slug = 'multiple-choice';

/// 미리보기 · 코드가 함께 쓰는 기본 옵션 — 값과 라벨.
const List<(String, String)> multipleChoiceSizeOptions = [
  ('sm', '작음'),
  ('md', '보통'),
  ('lg', '큼'),
];

/// 줄바꿈을 보이는 옵션 여섯 개 — 기본 옵션 앞뒤에 셋을 더한다.
const List<(String, String)> multipleChoiceManyOptions = [
  ('xs', '아주 작음'),
  ...multipleChoiceSizeOptions,
  ('xl', '아주 큼'),
  ('free', '프리 사이즈'),
];

/// 후보가 많은 예(Select 가 맞는 경우)의 옵션 — 값과 라벨.
const List<(String, String)> multipleChoiceTimeOptions = [
  ('mon-am', '월요일 오전'),
  ('mon-pm', '월요일 오후'),
  ('tue-am', '화요일 오전'),
  ('tue-pm', '화요일 오후'),
  ('wed-am', '수요일 오전'),
  ('wed-pm', '수요일 오후'),
  ('thu-am', '목요일 오전'),
  ('thu-pm', '목요일 오후'),
];

/// ChipGroup 관련 카드의 칩 라벨 — 처음에 앞의 둘을 켜 둔다.
const List<String> multipleChoiceRelatedChips = ['Flutter', 'Web', 'iOS'];

/// 속성의 `many` → 그릴 옵션.
List<(String, String)> multipleChoicePreviewOptions(Map<String, String> props) =>
    previewFlag(props, 'many') ? multipleChoiceManyOptions : multipleChoiceSizeOptions;

/// 속성의 `value` → 처음 고른 값. 없거나 `null` 이면 선택 없음.
String? multipleChoicePreviewValue(Map<String, String> props) => switch (props['value']) {
  null || 'null' => null,
  final value => value,
};

/// 속성의 `allowUnselect` — 없으면 위젯 기본값.
bool multipleChoicePreviewAllowUnselect(Map<String, String> props) =>
    previewFlag(props, 'allowUnselect', fallback: CoreMultipleChoiceContract.defaultAllowUnselect);

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'value': 'md'},
  controls: [
    DocsPlaygroundChoice(label: 'value', prop: 'value', options: ['sm', 'md', 'lg', 'null'], segmented: true),
    DocsPlaygroundFlag(label: 'allowUnselect', on: {'allowUnselect': 'true'}),
    DocsPlaygroundFlag(label: '옵션 6개', on: {'many': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _multipleChoiceCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// MultipleChoice 에는 크기 속성도 크기 단계(`defaultsBySize`)도 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _multipleChoiceCode(Map<String, String> props, String? label) {
  final value = multipleChoicePreviewValue(props);
  final lines = [
    'options: const [',
    for (final (optionValue, text) in multipleChoicePreviewOptions(props)) "  (value: '$optionValue', label: '$text'),",
    '],',
    value == null ? 'value: null,' : "value: '$value',",
    if (multipleChoicePreviewAllowUnselect(props)) 'allowUnselect: true,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setSize,',
  ];
  return 'MultipleChoice<String>(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
