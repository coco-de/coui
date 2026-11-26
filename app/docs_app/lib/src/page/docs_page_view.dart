/// 문서 페이지 하나를 읽어서 렌더한다.
library;

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/content/content_repository.dart';
import 'package:docs_app/src/content/docs_page.dart';
import 'package:docs_app/src/markdown/docs_heading.dart';
import 'package:docs_app/src/markdown/docs_markdown.dart';
import 'package:docs_app/src/markdown/tags/docs_tags.dart';
import 'package:docs_app/src/preview/live_preview_tag.dart';
import 'package:docs_app/src/shell/docs_shell.dart';
import 'package:docs_core/shared/component_source_links.dart';
import 'package:url_launcher/url_launcher.dart';

/// 마크다운 링크 [href] 를 [from] 페이지에서 눌렀을 때 갈 라우트.
///
/// `#id` 만 있는 링크는 지금 페이지 안을 가리키므로 지금 경로를 붙인다 —
/// 그대로 두면 `/#id`, 곧 홈이 된다.
String resolveDocsLinkTarget(String href, {required String from}) {
  if (href.startsWith('#')) return '$from$href';
  var target = href;
  if (target.startsWith('./') || target.startsWith('../')) {
    final base = from.contains('/')
        ? from.substring(0, from.lastIndexOf('/'))
        : '';
    target = '$base/${target.replaceFirst(RegExp(r'^\./'), '')}';
  }
  if (target.endsWith('.md')) {
    target = target.substring(0, target.length - '.md'.length);
  }
  if (!target.startsWith('/')) target = '/$target';
  return target;
}

/// 경로 하나의 마크다운을 읽어 페이지 한 장으로 렌더한다 — 본문과 목차.
class DocsPageView extends StatefulWidget {
  /// 페이지 뷰를 만든다.
  const DocsPageView({
    required this.repository,
    required this.path,
    required this.onNavigate,
    super.key,
  });

  /// 콘텐츠 저장소.
  final DocsContentRepository repository;

  /// 이 뷰가 보여줄 라우트 경로.
  final String path;

  /// 내부 링크를 눌렀을 때 호출된다.
  final void Function(String path) onNavigate;

  @override
  State<DocsPageView> createState() => _DocsPageViewState();
}

class _DocsPageViewState extends State<DocsPageView> {
  late final Future<DocsPage?> _page = widget.repository.page(widget.path);

  /// 마크다운의 링크를 라우트로 해석한다.
  ///
  /// 렌더러는 href 를 원문 그대로 넘긴다 — 상대 링크(`./card.md`)를 풀려면
  /// 지금 페이지 경로가 필요한데 그건 여기만 안다.
  void handleInternalLink(String href) {
    widget.onNavigate(resolveDocsLinkTarget(href, from: widget.path));
  }

  Widget _body(
    BuildContext context,
    AsyncSnapshot<DocsPage?> snapshot,
    DocsPage? page,
  ) {
    if (snapshot.connectionState != .done) {
      return const Center(child: Loading());
    }
    if (page == null) return _notFound(context);

    final registry = buildDocsTagRegistry(
      onInternalLink: handleInternalLink,
      livePreviewBuilder: buildLivePreviewTag,
    );

    final slug = docsComponentSlugFromRoutePath(widget.path);
    final sourceLinks = slug == null
        ? null
        : docsComponentSourceLinksForSlug(slug);

    return Column(
      crossAxisAlignment: .start,
      children: [
        // frontmatter 헤더 — jaspr 사이트도 frontmatter title/description 을
        // 본문 위에 따로 그린다(본문의 `# Heading` 과 별개다).
        if (page.title != null) Text(page.title!).displaySmall.onSurface,
        if (page.description != null) ...[
          const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
          Text(page.description!).bodyLarge.onSurfaceVariant,
        ],
        if (sourceLinks != null) ...[
          const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space12)),
          _SourceLinksRow(links: sourceLinks),
        ],
        const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space24)),
        DocsMarkdown(
          markdown: page.body,
          registry: registry,
          onInternalLink: handleInternalLink,
        ),
      ],
    );
  }

  Widget _notFound(BuildContext context) {
    return Center(
      child: EmptyState(
        title: const Text('페이지를 찾을 수 없습니다'),
        description: Text(widget.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocsPage?>(
      future: _page,
      builder: (context, snapshot) {
        final page = snapshot.data;
        final headings = page == null
            ? const <DocsHeading>[]
            : extractDocsHeadings(page.body);

        return DocsPageFrame(
          headings: headings,
          child: _body(context, snapshot, page),
        );
      },
    );
  }
}

/// raw `.md` 직링크 + "Open in Claude" 딥링크 — docs_site 의
/// `ComponentSourceLinksExtension`(`docs_site/lib/components/component_source_links.dart`)
/// 과 같은 [DocsComponentSourceLinks] 를 읽어 양쪽에 동등하게 노출한다. #3579.
class _SourceLinksRow extends StatelessWidget {
  const _SourceLinksRow({required this.links});

  final DocsComponentSourceLinks links;

  void _open(String url) {
    unawaited(launchUrl(Uri.parse(url), mode: .externalApplication));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      children: [
        Button(
          variant: .outline,
          size: .sm,
          onPressed: () => _open(links.githubUrl),
          child: const Text('원문 .md 보기'),
        ),
        const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space8)),
        Button(
          variant: .outline,
          size: .sm,
          onPressed: () => _open(links.openInClaudeUrl),
          child: const Text('Open in Claude'),
        ),
      ],
    );
  }
}
