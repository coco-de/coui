/// Link 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `link_web.dart` · `link_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// Flutter 의 `Link` 는 URL 을 직접 열지 않아 코드에 `onPressed` 가 있어야
/// 눌렀을 때 일이 일어난다. Web 은 `onPressed` 가 없을 때 `<a href>` 로
/// 이동한다. 그래서 두 플랫폼의 코드가 다르다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/link.md`.
const String slug = 'link';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기의 링크가 가리키는 주소. Web 미리보기는 실제 `<a href>` 라, 눌러도
/// 문서 밖으로 나가지 않도록 이 페이지를 가리킨다.
const String linkDemoHref = '/components/link';

/// 밖으로 나가는 링크 장면의 주소.
const String linkDemoRepositoryUrl = 'https://github.com/coco-de/coui';

/// 라벨을 주지 않은 미리보기의 라벨.
const String linkDemoLabel = '자세히 보기';

/// 문장 안의 링크 장면 — 앞 글 · 링크 글 · 뒤 글. 두 플랫폼 장면이 함께 읽는다.
const (String, String, String) linkDemoParagraph = ('토큰을 덮어쓰기 전에 ', '테마 가이드', '를 먼저 읽어 주세요.');

/// 사용 가이드의 문장 장면 — 앞 글 · 링크 글 · 뒤 글.
const (String, String, String) linkDemoSentence = ('가입하면 ', '이용약관', '에 동의하게 됩니다.');

/// 문장 장면의 폭(logical px). 좁으면 줄어든다.
const double linkDemoParagraphWidth = 320;

/// 카드 안 문장 장면의 폭(logical px). 좁으면 줄어든다.
const double linkDemoCardWidth = 200;

/// `link/related-breadcrumb` 장면의 경로.
const List<CoreBreadcrumbItem> linkDemoTrail = [
  CoreBreadcrumbItem(label: '홈'),
  CoreBreadcrumbItem(label: '컴포넌트'),
  CoreBreadcrumbItem(label: 'Link'),
];

// 선택지는 enum 에서 읽는다 — 값이 늘면 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {'variant': CoreLinkVariant.defaultVariant.name},
  label: linkDemoLabel,
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreLinkVariant.values) variant.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '늘 밑줄', on: {'underline': 'true'}),
    const DocsPlaygroundFlag(label: 'leading 아이콘', on: {'leading': 'hash'}),
    const DocsPlaygroundFlag(label: 'trailing 아이콘', on: {'trailing': 'external-link'}),
    const DocsPlaygroundFlag(label: '외부 링크 (external)', on: {'external': 'true'}),
  ],
  code: _linkCode,
  webCode: _linkWebCode,
);

/// Flutter 코드 — `Link` 가 URL 을 열지 않으므로 `onPressed` 를 적는다.
String _linkCode(Map<String, String> props, String? label) => _linkSnippet(props, label, withCallback: true);

/// Web 코드 — `onPressed` 를 적지 않아 `<a href>` 로 이동한다.
String _linkWebCode(Map<String, String> props, String? label) => _linkSnippet(props, label, withCallback: false);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다.
String _linkSnippet(Map<String, String> props, String? label, {required bool withCallback}) {
  final variant = previewEnum(CoreLinkVariant.values, props['variant'], CoreLinkVariant.defaultVariant);
  final external = previewFlag(props, 'external');
  final leading = props['leading'];
  final trailing = props['trailing'];
  final lines = [
    "href: '${external ? 'https://example.com' : '/docs'}',",
    if (external) 'external: true,',
    if (withCallback) 'onPressed: openLink,',
    if (variant != CoreLinkVariant.defaultVariant) 'variant: CoreLinkVariant.${variant.name},',
    if (previewFlag(props, 'underline')) 'underline: true,',
    if (leading != null) 'leading: Icon(LucideIcons.${docsIconIdentifier(leading)}),',
    if (trailing != null) 'trailing: Icon(LucideIcons.${docsIconIdentifier(trailing)}),',
    "child: Text('${label ?? linkDemoLabel}'),",
  ];
  return 'Link(\n${lines.map((line) => '  $line').join('\n')}\n)';
}
