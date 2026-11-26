/// 컴포넌트 문서 페이지 상단에 raw `.md` 직링크 + "Open in Claude" 딥링크를
/// 붙이는 [PageExtension]. #3579.
///
/// 페이지별로 마크다운에 손으로 태그를 심지 않는다 — [Page.path] 로
/// `content/components/<slug>.md` 페이지를 판별해 **자동으로** 붙인다.
/// 새 컴포넌트를 카탈로그에 추가하면 문서 페이지가 이 링크를 자동으로
/// 받는다(까먹고 안 붙이는 페이지가 생길 수 없다).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'package:docs_core/shared/component_source_links.dart';
import 'package:docs_core/shared/docs_template.dart';

/// `ComponentSourceLinksExtension` 이 붙이는 링크 행의 스타일.
final List<StyleRule> _styles = [
  css('.component-source-links').styles(
    raw: {
      'display': 'flex',
      'gap': '0.5rem',
      'margin': '0 0 1.5rem',
      'flex-wrap': 'wrap',
    },
  ),
  css('.component-source-links .source-link').styles(
    raw: {
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '0.375rem',
      'padding': '0.25rem 0.625rem',
      'border-radius': '9999px',
      'border': '1px solid var(--color-border, #e2e8f0)',
      'font-size': '0.75rem',
      'font-weight': '500',
      'color': 'var(--color-text-secondary, #64748b)',
      'text-decoration': 'none',
      'transition': 'border-color 0.15s, color 0.15s',
    },
  ),
  css('.component-source-links .source-link:hover').styles(
    raw: {
      'border-color': 'var(--color-primary, #6366f1)',
      'color': 'var(--color-primary, #6366f1)',
    },
  ),
  css('[data-theme="dark"] .component-source-links .source-link').styles(
    raw: {'border-color': 'var(--color-border, #27272a)'},
  ),
];

/// 컴포넌트 문서 페이지(`content/components/<slug>.md`) 상단에 소스
/// 링크 행을 붙인다. 카탈로그 밖 페이지(가이드·개요)는
/// [docsComponentSourceLinksForSlug] 가 null 을 돌려주므로 건드리지 않는다.
class ComponentSourceLinksExtension implements PageExtension {
  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    final slug = _slugFromFilePath(page.path);
    if (slug == null) return nodes;
    // v2 페이지는 머리가 원본 링크를 갖는다(`manual_layout.dart`).
    if (page.data.page['template'] == kDocsTemplateV2) return nodes;
    final links = docsComponentSourceLinksForSlug(slug);
    if (links == null) return nodes;

    return [
      ComponentNode(Document.head(children: [Style(styles: _styles)])),
      ComponentNode(_SourceLinksRow(links: links)),
      ...nodes,
    ];
  }

  /// `components/button.md` → `button`. 파일 경로 표기라 docs_app 의
  /// 라우트 표기(`/components/button`,
  /// `docsComponentSlugFromRoutePath`)와 다르다 — 두 표기는 각자 표기에서
  /// 슬러그만 뽑아 같은 [docsComponentSourceLinksForSlug] 를 부른다.
  String? _slugFromFilePath(String path) {
    const prefix = 'components/';
    const suffix = '.md';
    if (!path.startsWith(prefix) || !path.endsWith(suffix)) return null;
    final slug = path.substring(prefix.length, path.length - suffix.length);
    if (slug.isEmpty || slug.contains('/')) return null;
    return slug;
  }
}

class _SourceLinksRow extends StatelessComponent {
  const _SourceLinksRow({required this.links});

  final DocsComponentSourceLinks links;

  @override
  Component build(BuildContext context) {
    return div(classes: 'component-source-links', [
      a(
        href: links.githubUrl,
        classes: 'source-link',
        attributes: const {'target': '_blank', 'rel': 'noopener noreferrer'},
        [Component.text('원문 .md 보기')],
      ),
      a(
        href: links.openInClaudeUrl,
        classes: 'source-link',
        attributes: const {'target': '_blank', 'rel': 'noopener noreferrer'},
        [Component.text('Open in Claude')],
      ),
    ]);
  }
}
