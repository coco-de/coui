/// Disclosure 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `disclosure_web.dart` · `disclosure_flutter.dart` 가 그린다.
///
/// `open` 은 처음 상태라, 두 플랫폼 빌더는 속성이 바뀌면
/// [disclosurePreviewKey] 로 Disclosure 를 새로 만든다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/disclosure.md`.
const String slug = 'disclosure';

/// 미리보기 항목 — (제목, 본문). 두 플랫폼의 장면과 코드가 함께 읽는다.
const List<(String, String)> disclosureDemoItems = [
  ('배송은 얼마나 걸리나요?', '보통 2~3일 안에 도착합니다.'),
  ('교환할 수 있나요?', '받은 날부터 7일 안에 신청할 수 있습니다.'),
];

/// 미리보기의 폭(logical px). 두 플랫폼이 같은 폭에 그린다.
const double disclosureDemoWidth = 320;

/// 플레이그라운드.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'open': 'true'},
  controls: [
    DocsPlaygroundFlag(label: '처음부터 펼침 (open)', on: {'open': 'true'}),
    DocsPlaygroundFlag(label: '머리 줄에 아이콘 (trigger)', on: {'icon': 'true'}),
  ],
  code: _disclosureCode,
  webCode: _disclosureWebCode,
);

/// 크기 표. Disclosure 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기를 새로 만들어야 하는 속성 묶음의 이름.
String disclosurePreviewKey(Map<String, String> props) =>
    'disclosure-${previewFlag(props, 'open')}-${previewFlag(props, 'icon')}';

String _disclosureCode(Map<String, String> props, String? label) {
  final (title, _) = disclosureDemoItems.first;
  return _code(
    props,
    previewFlag(props, 'icon')
        ? [
            '  trigger: Row(',
            '    children: [',
            '      Icon(LucideIcons.info),',
            '      const Gap.space8(),',
            "      Text('$title'),",
            '    ],',
            '  ),',
          ]
        : ["  title: '$title',"],
  );
}

String _disclosureWebCode(Map<String, String> props, String? label) {
  final (title, _) = disclosureDemoItems.first;
  return _code(
    props,
    previewFlag(props, 'icon')
        ? [
            '  trigger: div(',
            '    [',
            '      Icon(LucideIcons.info),',
            '      const Gap.space8(),',
            "      Text('$title'),",
            '    ],',
            "    classes: 'flex items-center',",
            '  ),',
          ]
        : ["  title: '$title',"],
    extra: ["  classes: 'w-full',"],
  );
}

String _code(Map<String, String> props, List<String> header, {List<String> extra = const []}) {
  final (_, content) = disclosureDemoItems.first;
  return [
    'Disclosure(',
    ...header,
    "  content: Text('$content'),",
    if (previewFlag(props, 'open')) '  open: true,',
    ...extra,
    ')',
  ].join('\n');
}
