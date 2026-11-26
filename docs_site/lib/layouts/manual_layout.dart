/// 문서 페이지의 레이아웃 — 헤더, 탭마다 다른 사이드바, 본문, "이 페이지에서".
///
/// ## 뼈대
///
/// ```text
/// (앱 루트 — `siteAppRoot`)
/// #docs-shell.docs.manual
///   ├─ a.docs-skip-link
///   ├─ header.site-gnb                 // SiteHeader — 랜딩과 같은 것
///   └─ div.docs-frame
///        ├─ aside#site-drawer.docs-sidebar   // SiteDrawer — 지금 탭의 페이지
///        ├─ script                           // 사이드바 스크롤 복원
///        └─ main#main-content
///             ├─ article.docs-article
///             │    ├─ PageHeader.docs-head   // 경로 · 제목 · 설명
///             │    ├─ details.docs-mobile-toc
///             │    ├─ (본문)
///             │    └─ nav.docs-pager         // 이전 · 다음
///             └─ aside.docs-toc              // 이 페이지에서
/// ```
///
/// ## 사이드바 · 경로 · 페이저는 한 구조에서 온다
///
/// 셋 다 `docsNavLocate(page.url)` 하나에서 나온다. 사이드바의 목록, 페이지
/// 머리의 경로, 페이저의 앞뒤가 서로 다른 목록을 읽으면 페이지 하나를 옮긴
/// 날 셋 중 하나만 옛 자리를 가리킨다.
library;

import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/shared/component_source_links.dart';
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_core/shared/docs_template.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr/dom.dart' as dom;

import '../components/component_catalog_design.dart';
import '../components/docs_pager.dart';
import '../components/docs_toc.dart';
import '../components/site_drawer.dart';
import '../components/site_header.dart';
import 'sidebar_scroll_restore.dart';
import 'site_chrome.dart';

/// "이 페이지에서" — 목차 머리와 랜드마크의 이름.
const String kDocsTocLabel = '이 페이지에서';

/// 시안 페이지의 시트를 고르는 frontmatter 키 — `design: true`.
///
/// 시안 페이지(Getting Started · Foundations · Blocks · Resources 류)의 그림은
/// 그 페이지들만 쓰는 시트(`web/docs-designed-pages.css`)에 있다. 본문을
/// 공유 문서(`docs_core/content`)에 두는 페이지는 이 키로 그 시트를 받는다.
const String kDocsDesignKey = 'design';

/// 문서 페이지의 레이아웃.
class ManualLayout extends PageLayoutBase {
  /// 문서 레이아웃을 만든다.
  const ManualLayout();

  @override
  String get name => 'docs';

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    if (_usesDesignedLayout(page)) {
      yield dom.link(rel: 'stylesheet', href: '/docs-designed-pages.css');
    }
  }

  @override
  Component buildBody(Page page, Component child) {
    final data = page.data.page;
    final toc = page.data['toc'];
    final location = docsNavLocate(page.url);
    final tab = docsNavTabFor(page.url);
    final designed = _usesDesignedLayout(page);
    final catalog = page.url == '/components-overview';
    final componentTemplate = data['template'] == kDocsTemplateV2;
    final pager = componentTemplate && location != null ? componentTemplatePager(location) : null;
    final tocLabel = page.url == '/changelog' ? '버전' : kDocsTocLabel;
    final hasToc = toc is TableOfContents && toc.entries.isNotEmpty;

    // 앱 루트는 문서의 본문 안에 놓인다 — 문서 위에 놓으면 문서가 둘이 된다
    // (`site_chrome.dart`).
    return siteAppRoot(
      child: div(
        id: 'docs-shell',
        classes: 'docs manual',
        attributes: {
          'data-docs-tab': tab.id,
          if (designed) 'data-docs-design': '',
          if (catalog) 'data-component-catalog': '',
          if (componentTemplate) 'data-component-template': '',
        },
        [
          const SiteChromeHead(),
          // `<base href="/">` 아래에서는 `#main-content` 만 쓰면 홈으로 간다.
          a(href: '${page.url}#main-content', classes: 'docs-skip-link', [Component.text('본문으로 건너뛰기')]),
          SiteHeader(currentPath: page.url),
          div(classes: 'docs-frame', [
            SiteDrawer(currentPath: page.url),
            // 사이드바 요소 바로 뒤여야 한다 — 첫 페인트 전에 복원하기 위해서다
            // (`SidebarScrollRestore` 문서). `<head>` 로 옮기면 요소가 아직 없다.
            const SidebarScrollRestore(),
            main_(
              id: 'main-content',
              attributes: const {'tabindex': '-1'},
              [
                article(classes: 'docs-article', [
                  _head(page, data, location),
                  if (hasToc)
                    details(classes: 'docs-mobile-toc', [
                      summary([Component.text(tocLabel)]),
                      nav(
                        attributes: {'aria-label': tocLabel, 'data-toc': ''},
                        [DocsTocList(path: page.url, entries: toc.entries, includeSubsections: !componentTemplate)],
                      ),
                    ]),
                  child,
                  if (location != null && !catalog)
                    DocsPager(
                      location: location,
                      // 탭의 첫 페이지는 다른 탭의 끝으로 돌아가지 않는다 — 탭을
                      // 처음 연 사람의 다음 걸음은 앞이다(Figma 의 문서 페이지).
                      showPrevious: location.page.path != location.tab.path,
                      previousPage: pager?.previous,
                      nextPage: pager?.next,
                    ),
                ]),
                if (hasToc)
                  aside(
                    classes: 'docs-toc',
                    attributes: {'aria-label': tocLabel},
                    [
                      // `data-toc` 가 읽는 자리의 계약이다 — `web/docs-toc.js` 가
                      // 이 안의 링크와 그것이 가리키는 제목을 짝짓는다.
                      div(
                        classes: 'toc-rail',
                        attributes: const {'data-toc': ''},
                        [
                          h2(classes: 'toc-title', [Text(tocLabel).labelSmall.medium]),
                          DocsTocList(path: page.url, entries: toc.entries, includeSubsections: !componentTemplate),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  bool _usesDesignedLayout(Page page) => docsUsesDesignedLayout(page);

  /// 페이지 머리 — 경로 · 제목 · 설명. CoUI `PageHeader` 가 그린다.
  Component _head(Page page, Map<String, Object?> data, DocsNavLocation? location) {
    final title = data['title'];
    final description = data['description'];

    return Component.element(
      tag: 'header',
      classes: 'docs-head not-content',
      children: [
        if (title is String)
          PageHeader(
            headingLevel: 1,
            eyebrow: location == null ? null : Text(location.trail.join(' / ')),
            // 제목의 조각 주소는 마크다운의 `# 제목` 이 갖던 것이다 — 그
            // 제목을 본문에서 걷어 냈으므로 여기서 이어받는다.
            title: span(id: page.data['docsTitleId'] as String?, [Text(title)]),
            description: description is String ? Text(description).keepAll : null,
            pageHeaderStyle: _headStyle,
          ),
        if (data['template'] == kDocsTemplateV2) _headMeta(page, data),
        if (data['image'] case final String image) img(src: image, alt: data['imageAlt'] as String?),
      ],
    );
  }

  /// v2 머리의 둘째 줄 — 지원 플랫폼과 원본 링크(소스 · Figma · Markdown).
  Component _headMeta(Page page, Map<String, Object?> data) {
    final slug = docsComponentSlugFromRoutePath(
      page.url.endsWith('/') ? page.url.substring(0, page.url.length - 1) : page.url,
    );
    final platforms = data['platforms'];
    final links = slug == null ? null : docsComponentSourceLinksForSlug(slug);
    final source = data['source'];
    final figma = page.data['figma_library'];
    String? figmaUrl;
    if (figma is Map && slug != null) {
      final url = figma['url'];
      final node = (figma['pages'] as Map?)?[slug];
      if (url is String) figmaUrl = node is Map && node['nodeId'] is String ? '$url?node-id=${node['nodeId']}' : url;
    }

    Component link(String label, String href) => a(
      href: href,
      attributes: const {'target': '_blank', 'rel': 'noopener noreferrer'},
      [Text(label).labelMedium],
    );

    return div(classes: 'docs-head-meta', [
      ul(classes: 'docs-head-platforms', [
        if (platforms is List && platforms.contains('flutter')) li([Component.text('Flutter')]),
        if (platforms is List && platforms.contains('web')) li([Component.text('Jaspr Web')]),
        if (figmaUrl != null) li([Component.text('Figma')]),
      ]),
      div(classes: 'docs-head-links', [
        if (source is String)
          link(
            '소스 코드',
            'https://github.com/$kDocsGithubRepo/tree/$kDocsGithubBranch/packages/coui_flutter/lib/src/components/$source',
          ),
        if (figmaUrl != null) link('Figma에서 열기', figmaUrl),
        if (links != null) link('Markdown', links.githubUrl),
      ]),
    ]);
  }

  /// 페이지 머리의 글자와 간격 — Figma `Doc/Head`.
  ///
  /// 경로는 작은 본문 글자, 제목은 화면의 머리에 놓인 제목이라 display
  /// 역할이다 — 그 역할은 화면 폭이 좁아지면 함께 작아진다(글자 단계). 설명은
  /// 본문의 큰 글자다.
  static const CorePageHeaderStyle _headStyle = CorePageHeaderStyle(
    eyebrowTextStyle: CoreTextStyle.token(
      CoreTextStyles.bodySmall,
      color: CoreColor.token(CoreColors.onSurfaceSubtle),
    ),
    titleTextStyle: CoreTextStyle.token(
      CoreTextStyles.displaySmall,
      color: CoreColor.token(CoreColors.onSurface),
    ),
    descriptionTextStyle: CoreTextStyle.token(
      CoreTextStyles.bodyLarge,
      color: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
    textSpacing: CoreSpace.space16,
  );
}

/// Use frontmatter as the visible title, retaining the Markdown title's anchor.
/// Shared Markdown stays intact for the native docs app and source downloads.
class ManualTitleExtension implements PageExtension {
  const ManualTitleExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    if (page.data.page['layout'] == 'landing') return nodes;
    final first = nodes.whereType<ElementNode>().firstOrNull;
    if (first == null || first.tag != 'h1' || first.innerText.trim() != page.data.page['title']) return nodes;
    page.apply(data: {'docsTitleId': first.attributes['id']});
    return nodes.where((node) => !identical(node, first)).toList();
  }
}

/// Bring the shortest runnable usage section before the interactive gallery.
/// Heading nodes keep their existing IDs and the TOC is built afterwards.
class ManualReadingOrderExtension implements PageExtension {
  const ManualReadingOrderExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    if (!page.url.startsWith('/components/')) return nodes;
    bool heading(Node node, String prefix) =>
        node is ElementNode && node.tag == 'h2' && node.innerText.startsWith(prefix);
    final usage = nodes.indexWhere((node) => heading(node, '기본 사용법'));
    final preview = nodes.indexWhere((node) => heading(node, 'Live Preview'));
    if (usage < 0 || preview < 0 || usage < preview) return nodes;
    var end = usage + 1;
    while (end < nodes.length && !(nodes[end] is ElementNode && (nodes[end] as ElementNode).tag == 'h2')) {
      end++;
    }
    return [...nodes.take(preview), ...nodes.sublist(usage, end), ...nodes.sublist(preview, usage), ...nodes.skip(end)];
  }
}

/// [page] 가 시안 페이지의 시트(`web/docs-designed-pages.css`)와
/// `#docs-shell[data-docs-design]` 을 받는가.
///
/// frontmatter 의 `design: true`([kDocsDesignKey]), 사이트 전용 시안판을
/// 보여 주는 페이지(`docsDesign`), 컴포넌트 v2 템플릿이 받는다.
bool docsUsesDesignedLayout(Page page) =>
    page.data['docsDesign'] == true ||
    page.data.page[kDocsDesignKey] == true ||
    page.data.page['template'] == kDocsTemplateV2;
