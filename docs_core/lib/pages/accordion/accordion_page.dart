/// Accordion 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `accordion_web.dart` · `accordion_flutter.dart` 가 그린다.
///
/// `expanded` 는 항목을 만들 때 한 번만 읽는 값이라, 두 플랫폼 빌더는
/// 속성이 바뀌면 [accordionPreviewKey] 로 Accordion 을 새로 만든다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/accordion.md`.
const String slug = 'accordion';

/// 미리보기 항목 — (제목, 본문). 두 플랫폼의 장면과 코드가 함께 읽는다.
const List<(String, String)> accordionDemoItems = [
  ('환불 정책은 어떻게 되나요?', '구매 후 30일 안에 전액 환불을 요청할 수 있어요.'),
  ('요금제는 어떻게 해지하나요?', '설정의 결제 메뉴에서 언제든 해지할 수 있어요.'),
  ('이메일을 바꿀 수 있나요?', '계정 설정에서 언제든 새 이메일로 바꿀 수 있어요.'),
];

/// 미리보기의 폭(logical px). 두 플랫폼이 같은 폭에 그린다.
const double accordionDemoWidth = 360;

/// 플레이그라운드.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'expanded': '1'},
  controls: [
    DocsPlaygroundFlag(label: 'allowMultiple', on: {'allowMultiple': 'true'}),
    DocsPlaygroundChoice(
      label: '처음 펼친 항목 (expanded)',
      prop: 'expanded',
      options: ['none', '1', '2'],
      segmented: true,
    ),
  ],
  code: _accordionCode,
);

/// 크기 표. Accordion 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `expanded` → 처음 펼친 항목의 위치(0부터). `none` 이거나 모르는 값은 `null`.
int? accordionPreviewExpanded(Map<String, String> props) {
  final number = int.tryParse(props['expanded'] ?? '');
  return number == null || number < 1 || number > accordionDemoItems.length ? null : number - 1;
}

/// 미리보기를 새로 만들어야 하는 속성 묶음의 이름.
String accordionPreviewKey(Map<String, String> props) =>
    'accordion-${previewFlag(props, 'allowMultiple')}-${accordionPreviewExpanded(props)}';

String _accordionCode(Map<String, String> props, String? label) {
  final expanded = accordionPreviewExpanded(props);
  final items = [
    for (final (index, (title, content)) in accordionDemoItems.indexed)
      [
        '    AccordionItem(',
        "      title: '$title',",
        "      content: Text('$content'),",
        if (index == expanded) '      expanded: true,',
        '    ),',
      ].join('\n'),
  ].join('\n');
  return [
    'Accordion(',
    if (previewFlag(props, 'allowMultiple')) '  allowMultiple: true,',
    '  items: [',
    items,
    '  ],',
    ')',
  ].join('\n');
}
