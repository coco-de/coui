/// The chrome-less `/embed` route — a single Web preview and nothing else.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import '../components/web_preview.dart';
import '../site_head.dart';

/// Renders one component's Web preview with no sidebar, header or code panel.
///
/// This is what docs_app (the native Flutter docs twin) loads into the WebView
/// that backs its Web preview pane, via
/// `/embed/<component>?variant=<v>&theme=<light|dark>`.
///
/// The markup deliberately reproduces the docs pages' preview subtree —
/// `.preview-content` wrapping [WebPreview] — because the shared preview CSS
/// (`docsPreviewStyles`) targets that exact shape with direct-child selectors
/// (`.preview-content > div[id^="web-"] > div.w-full > …`). Inserting a wrapper
/// between them, or mounting an extra `CoUIWeb` here, would break the chain and
/// silently change the layout relative to the site. The route mounts `CoUIWeb`
/// around this page (`main.server.dart`) and [WebPreview] mounts it again
/// inside, so theme context is present without one here.
class EmbedPage extends StatelessComponent {
  /// Creates the embed page for [component].
  const EmbedPage({
    required this.component,
    this.variant,
    this.dark = false,
    this.chainStep,
    super.key,
  });

  /// Component slug, e.g. `button` — the `kWebPreviewRegistry` key.
  final String component;

  /// Optional variant name, e.g. `primary`.
  final String? variant;

  /// Whether to render the dark theme.
  final bool dark;

  /// chain 순열 고정 step — 네이티브 docs_app 셔플이 WebView HTML 을 다시
  /// 렌더할 때 넘긴다 ([WebPreview.chainStep] 로 그대로 통과).
  final int? chainStep;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      // The CoUI dark CSS variables are scoped to `[data-theme="dark"]`, so
      // the attribute on the document element is what actually flips the
      // theme. Rendered server-side rather than toggled on the client: the
      // pane is driven by the URL, and a client-side flip would show a
      // light-mode flash before hydration.
      Document.html(attributes: {'data-theme': dark ? 'dark' : 'light'}),
      Document.head(
        title: 'CoUI preview: $component',
        // The docs pages get this viewport meta from the site's `Document`
        // root; this fragment-composed page must declare it itself. Without
        // it a mobile WebView treats the embed as a legacy desktop page and
        // applies font boosting (text autosizing) — inflating text ~1.2x, so
        // e.g. a Button grows wider than the same button in the neighbouring
        // Flutter pane while its `h-*` fixed height stays put. With the meta,
        // CSS px == logical px and both panes render the same design size.
        meta: const {'viewport': 'width=device-width, initial-scale=1.0'},
        children: [
          ...docsSharedHead(),
          Style(
            styles: [
              // The docs pages render previews under the site-wide
              // `ContentTheme` styles (jaspr_content injects them for every
              // content page) — most importantly its CSS reset:
              // `* { box-sizing: border-box }` and the UA form-element reset.
              // The embed must render under the same styles or its previews
              // diverge from the site's: `w-full` + padding overflows the
              // pane (content-box), `<button>`s keep the UA grey fill /
              // outset border / Arial font (wider label than the Flutter
              // twin), and native focus outlines leak through. Same order as
              // the site: theme first, preview styles on top.
              ...docsContentTheme().styles,
              ...docsPreviewStyles(),
              ..._embedStyles,
            ],
          ),
        ],
      ),
      div(classes: 'preview-content not-content', [
        WebPreview(component: component, variant: variant, chainStep: chainStep),
      ]),
    ]);
  }
}

/// Styles specific to the embed page.
List<StyleRule> get _embedStyles => [
  // Tailwind's preflight is disabled site-wide, so the UA's default 8px body
  // margin survives. On a full docs page it is absorbed by the layout; here
  // the preview *is* the page, so it would offset every component against its
  // Flutter twin in the neighbouring pane.
  //
  // The surface fill comes from the CoUI token rather than a literal so the
  // page background tracks the theme — `--coui-surface` is defined by the
  // shared `:root` block and overridden under `[data-theme="dark"]`.
  css('html, body').styles(
    raw: {
      'margin': '0',
      'padding': '0',
      'background': 'rgb(var(--coui-surface))',
    },
  ),
];
