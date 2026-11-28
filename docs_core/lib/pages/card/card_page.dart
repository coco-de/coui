/// Card 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `card_web.dart` · `card_flutter.dart` 가 그린다. 미리보기의 글자는
/// 아래 상수 한 곳에 둔다.
///
/// 플레이그라운드의 푸터는 글자다 — `onTap` 을 켠 카드 안에 버튼을 두면
/// 누르는 것이 겹치기 때문이다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/card.md`.
const String slug = 'card';

/// 미리보기의 머리 글자 — 태그가 `label` 을 주지 않을 때.
const String cardDemoHeader = '프로젝트 요약';

/// 미리보기의 본문.
const String cardDemoBody = '이번 주 진행 상황을 확인해 보세요.';

/// 미리보기의 푸터.
const String cardDemoFooter = '3일 전에 수정';

/// 장면의 카드 폭(logical px).
const double cardDemoWidth = 280;

/// 플레이그라운드.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'variant': 'outlined', 'elevation': 'none', 'footer': 'true'},
  controls: [
    DocsPlaygroundChoice(label: 'variant', prop: 'variant', options: ['filled', 'outlined'], segmented: true),
    DocsPlaygroundChoice(label: 'elevation', prop: 'elevation', options: ['none', 'soft', 'medium', 'strong']),
    DocsPlaygroundFlag(label: '미디어 (media)', on: {'media': 'true'}),
    DocsPlaygroundFlag(label: '푸터 (footer)', on: {'footer': 'true'}),
    DocsPlaygroundFlag(label: '누를 수 있게 (onTap)', on: {'onTap': 'true'}),
  ],
  code: _cardCode,
);

/// 크기 표. Card 에는 크기 단계가 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _cardCode(Map<String, String> props, String? label) {
  final variant = props['variant'];
  final elevation = props['elevation'];
  return [
    'Card(',
    if (variant == 'outlined') '  variant: CoreCardVariant.outlined,',
    if (elevation != null && elevation != 'none') ...[
      '  cardStyle: CoreCardStyle(',
      '    elevation: CoreCardElevation.$elevation,',
      '  ),',
    ],
    if (previewFlag(props, 'media')) '  media: CoverImage(), // 그림을 그리는 내 위젯 · 컴포넌트',
    "  header: Text('${label ?? cardDemoHeader}'),",
    "  body: Text('$cardDemoBody'),",
    if (previewFlag(props, 'footer')) "  footer: Text('$cardDemoFooter').bodySmall.onSurfaceVariant,",
    if (previewFlag(props, 'onTap')) '  onTap: openProject,',
    ')',
  ].join('\n');
}
