/// The entrypoint for the **server** environment.
library;

import 'package:docs_core/markdown/code_tag_block_syntax.dart';
import 'package:docs_core/markdown/changelog_preview_component.dart';
import 'package:docs_core/markdown/current_version_component.dart';
import 'package:docs_core/markdown/heading_slug.dart';
import 'package:jaspr/server.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:jaspr_content/components/image.dart';

import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_router/jaspr_router.dart' show Route, RouteBase, Router;

import 'components/block_catalog_visuals.dart';
import 'components/component_grid.dart';
import 'components/component_source_links.dart';
import 'components/docs_blocks.dart';
import 'components/docs_fragment_links.dart';
import 'components/docs_preview_blocks.dart';
import 'components/docs_tabs.dart';
import 'components/docs_path_redirect.dart';
import 'components/typed_callout.dart';
import 'components/designed_docs_content.dart';
import 'components/foundations_visuals.dart';
import 'components/live_preview.dart';
import 'components/release_timeline.dart';
import 'components/safe_code_block.dart';
import 'components/site_footer.dart';
import 'components/site_hero.dart';
import 'components/site_showcase.dart';
import 'layouts/landing_layout.dart';
import 'layouts/manual_layout.dart';
import 'layouts/site_chrome.dart';
import 'package:docs_core/embed/embed_page.dart';
import 'main.server.options.dart';
import 'package:docs_core/shared/block_catalog.dart';
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/site_head.dart';

const base = '';

void main() {
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  // The page's `Document` is the root of the rendered tree. jaspr looks for
  // `<html>` at the top and, finding none, builds a document of its own around
  // whatever is there — so a component that draws a box (`CoUIWeb` does) must
  // not sit above the layouts: their `<html><head>` — title, description,
  // `<base>` — would end up inside the body. The app root is mounted inside
  // the document instead: by each layout around its body, and by
  // `_buildRouter` around the routes that build no document (`siteAppRoot`).
  runApp(
    // `ContentApp.custom` rather than the plain constructor purely to reach
    // `routerBuilder` — the only hook for adding a non-content route (see
    // `_buildRouter`). The loader / config below reproduce what the plain
    // constructor builds, so page loading is unchanged.
    ContentApp.custom(
      loaders: [FilesystemLoader('../docs_core/content')],
      routerBuilder: _buildRouter,
      configResolver: PageConfig.all(
        dataLoaders: [FilesystemDataLoader('../docs_core/content/_data')],
        templateEngine: MustacheTemplateEngine(),
        parsers: [
          // Custom `documentBuilder` swaps in a Unicode-aware heading-anchor
          // slug (see `heading_slug.dart`) — the package default strips
          // non-ASCII text, which collapses every Korean heading's `id` to
          // empty and breaks both the `#` anchor link and every
          // "On this page" entry that targets it.
          MarkdownParser(
            documentBuilder: (_) => md.Document(
              blockSyntaxes: kDocsBlockSyntaxes,
              extensionSet: docsHeadingAwareExtensionSet,
            ),
          ),
        ],
        extensions: [
          const DesignedDocsContent(),
          // 본문을 갈아끼우는 확장 뒤에 둔다 — 갈아끼운 본문의 링크도 고친다.
          const DocsFragmentLinksExtension(),
          const ManualTitleExtension(),
          const ManualReadingOrderExtension(),
          HeadingAnchorsExtension(),
          TableOfContentsExtension(),
          const ReleaseTimeline(),
          ComponentSourceLinksExtension(),
          const DocsTableExtension(),
        ],
        components: [
          TypedCallout(),
          DocsBlocks(),
          DocsPreviewBlocks(),
          const BlockCatalogVisuals(),
          const FoundationVisual(),
          ComponentGrid(),
          SiteHero(),
          SiteShowcase(),
          LivePreview(),
          SafeCodeBlock(),
          Image(zoom: true),
          DocsTabs(),
          ChangelogPreview(),
          CurrentVersion(),
        ],
        layouts: [
          // 순서가 뜻을 갖는다. jaspr_content 는 `layout:` 키가 없는
          // 페이지에 **첫 번째** 레이아웃을 주므로, 문서 레이아웃이
          // 먼저다 — 뒤집히면 문서 페이지 전부가 사이드바를 잃는다.
          //
          // 헤더 · 사이드바 · 페이저는 레이아웃이 사이트 구조
          // (`docs_core/shared/docs_navigation.dart`)에서 직접 그린다 —
          // 여기서 링크 목록을 넘기지 않는다.
          const ManualLayout(),
          // 좁은 폭에서 헤더의 탭이 서랍으로 들어가는데 랜딩에는
          // 사이드바가 없다 — 푸터가 그 길을 한 번 더 놓는다.
          const LandingLayout(footer: SiteFooter()),
        ],
        // Shared with the `/embed` route (site_head.dart) so the embed's
        // previews render under the same CSS reset / theme as the docs
        // pages' previews.
        theme: docsContentTheme(),
      ),
    ),
  );
}

/// Builds the site's router: every content route, plus one `/embed/<slug>`
/// per catalogued component.
///
/// Each `/embed/<slug>` renders a single Web preview with no site chrome — it
/// backs the Web pane of docs_app, the native Flutter docs twin. The embed set
/// is a finite, build-time-known list (the shared `component_catalog.dart` —
/// the same single source the sidebar and `/components/<slug>` pages
/// enumerate), so we emit one **static** route per component rather than a
/// `:component` path parameter: path-parameter routes are not enumerable and
/// `jaspr build` (static mode) rejects them outright. `variant` / `theme` stay
/// query params — genuine runtime toggles the client applies after hydration.
Component _buildRouter(List<List<RouteBase>> routes) {
  return Router(
    routes: [
      for (final route in routes) ...route,
      for (final moved in kDocsMovedPaths.entries)
        Route(
          path: moved.key,
          builder: (_, _) => siteAppRoot(child: DocsPathRedirect(to: moved.value)),
        ),
      for (final block in kDocsBlocks)
        Route(
          path: '/embed/${block.slug}',
          builder: (context, state) => siteAppRoot(
            child: EmbedPage(
              component: block.slug,
              variant: state.queryParams['variant'],
              dark: state.queryParams['theme'] == 'dark',
            ),
          ),
        ),
      for (final group in kDocsComponentGroups)
        for (final item in group.items)
          Route(
            path: '/embed/${item.slug}',
            builder: (context, state) => siteAppRoot(
              child: EmbedPage(
                component: item.slug,
                variant: state.queryParams['variant'],
                dark: state.queryParams['theme'] == 'dark',
              ),
            ),
          ),
    ],
  );
}
