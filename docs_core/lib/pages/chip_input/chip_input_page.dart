/// ChipInput 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `chip_input_web.dart` · `chip_input_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// ChipInput 에는 크기 축이 없다 — 프레임은 늘 컨트롤 사다리의 `md` 행이고,
/// 칩은 늘 Chip 의 `sm` 행이다. 그래서 크기 표가 없다.
///
/// `chips` 는 부모가 들고 넘기는 목록이라, 미리보기 빌더는 그 목록을 스스로
/// 기억한다(Tabs 페이지와 같은 방식). 서버에서 그리는 블록에서는 처음 칩만
/// 보이고, 브라우저에서 깨어나는 플레이그라운드에서는 칩을 더하고 지울 수 있다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/chip-input.md`.
const String slug = 'chip-input';

/// 미리보기의 처음 칩 — 두 플랫폼 빌더 · 장면이 같은 칩을 쓴다.
const List<String> chipInputPreviewChips = ['디자인', '개발'];

/// 미리보기 입력 칸의 안내 문구.
const String chipInputPreviewPlaceholder = '태그를 입력하세요';

/// 플레이그라운드에서 켜는 최대 칩 수 — 처음 칩이 둘이라 하나를 더하면
/// 입력 칸이 사라지는 것을 볼 수 있다.
const int chipInputPreviewMaxChips = 3;

/// 상태 장면의 칸 이름 — 두 플랫폼 장면이 같은 순서로 그린다.
const List<String> chipInputStateColumns = ['기본', '칩 있음', 'Hover', '한도 도달', '비활성'];

/// 줄 바꿈 장면의 칩 — 프레임 한 줄을 넘는 수.
const List<String> chipInputWrapChips = ['디자인', '개발', '마케팅', '데이터', '운영'];

/// 이렇게 하세요 카드의 칩 — 낱말 하나씩.
const List<String> chipInputShortChips = ['서울', '부산', '제주'];

/// 이렇게 하지 마세요 카드의 칩 — 문장 하나.
const List<String> chipInputSentenceChips = ['서울에서 출발하는 오전 항공편만 보기'];

/// 속성의 `chips`(쉼표로 이은 값) → 칩 목록. 빈 값은 버린다.
List<String> chipInputPreviewChipList(Map<String, String> props) => [
  for (final chip in (props['chips'] ?? '').split(','))
    if (chip.trim().isNotEmpty) chip.trim(),
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// 바꿔 볼 축이 적다 — variant · size 가 없고, 칩 목록은 미리보기에서 직접
/// 더하고 지운다. 컨트롤은 안내 문구 · 최대 칩 수 · 붙여넣기 나누기 · 비활성
/// 넷이다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'chips': '디자인,개발', 'placeholder': chipInputPreviewPlaceholder},
  controls: [
    DocsPlaygroundFlag(label: '안내 문구', on: {'placeholder': chipInputPreviewPlaceholder}),
    DocsPlaygroundFlag(label: '최대 3개', on: {'maxChips': '$chipInputPreviewMaxChips'}),
    DocsPlaygroundFlag(label: '붙여넣기 나누기', on: {'pasteSplitter': 'true'}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _chipInputCode,
);

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
///
/// ChipInput 의 Style 에는 `defaultsBySize` 가 없다 — 최소 높이는
/// `CoreChipInputStyle.defaultMinHeight` 하나(컨트롤 사다리의 `md` 행)다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 → 코드. `chips` 는 부모가 들고 있는 목록(`tags`)으로 적고, 두 콜백은
/// 그 목록을 바꾸는 부모의 함수로 적는다.
String _chipInputCode(Map<String, String> props, String? label) {
  final placeholder = props['placeholder'];
  final maxChips = props['maxChips'];
  final lines = [
    'chips: tags,',
    if (placeholder != null) "placeholder: '$placeholder',",
    if (maxChips != null) 'maxChips: $maxChips,',
    if (previewFlag(props, 'pasteSplitter')) 'pasteSplitter: CoreChipInputContract.splitOnCommonSeparators,',
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
    'onChanged: setTags,',
    'onSubmitted: addTag,',
  ];
  return 'ChipInput(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
