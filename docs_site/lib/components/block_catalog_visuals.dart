import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/shared/block_catalog.dart';
import 'package:jaspr_content/jaspr_content.dart';

const _assetRoot = '/images/blocks';

class BlockCatalogVisuals extends CustomComponent {
  const BlockCatalogVisuals() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(tag: 'BlockCatalogVisual', :final attributes)) {
      return switch (attributes['kind']) {
        'catalog' => _catalog(),
        'hero-layouts' => _layouts(_block('hero')),
        'footer-layouts' => _layouts(_block('footer')),
        'footer-structure' => _footerStructure(),
        _ => null,
      };
    }
    return null;
  }
}

DocsBlockEntry _block(String slug) => kDocsBlocks.firstWhere((block) => block.slug == slug);

/// 개요 카드의 그림이 보여 주는 레이아웃 — 블록이 가장 블록답게 보이는 배치.
String _catalogLayout(DocsBlockEntry block) => block.slug == 'hero' ? 'split' : block.layouts.first;

Component _catalog() => div(classes: 'block-cards not-content', [
  for (final block in kDocsBlocks)
    a(href: block.path, classes: 'block-card site-box-link', [
      _diagram(block.slug, _catalogLayout(block)),
      Text(block.name).titleMedium.semiBold.onSurface,
      Text(block.description).bodyMedium.onSurfaceVariant,
      div(classes: 'block-layout-tags', [
        for (final layout in block.layouts) code([Component.text('Layout=$layout')]),
      ]),
    ]),
]);

Component _layouts(DocsBlockEntry block) => div(
  classes: 'block-cards block-layouts not-content',
  attributes: {'data-block-layouts': block.slug},
  [
    for (final layout in block.layouts)
      div(classes: 'block-layout', [
        _diagram(block.slug, layout),
        code([Component.text(block.layoutLabel(layout))]),
      ]),
  ],
);

Component _footerStructure() => div(classes: 'block-structure not-content', [
  _diagram('footer', 'horizontal'),
  ol([
    for (final (index, part) in kDocsFooterStructure.indexed)
      li([
        Text('${index + 1} ${part.label}').labelLarge,
        code([Component.text(part.slots)]),
      ]),
  ]),
]);

Component _diagram(String block, String layout) => div(
  classes: 'block-diagram',
  attributes: {'aria-hidden': 'true', 'data-block': block, 'data-layout': layout},
  [
    div(classes: 'block-window', [
      div(classes: 'block-window-bar', [
        for (var i = 0; i < 3; i++) img(src: '$_assetRoot/window-dot.svg', alt: ''),
      ]),
      if (block == 'hero')
        div(classes: 'block-window-hero', [
          div(classes: 'block-wire-copy', [
            span(classes: 'block-wire-kicker', []),
            span(classes: 'block-wire-headline', []),
            span(classes: 'block-wire-headline block-wire-headline-short', []),
            span(classes: 'block-wire-line', []),
            span(classes: 'block-wire-line block-wire-line-short', []),
            div(classes: 'block-wire-actions', [span([]), span([])]),
          ]),
          if (layout == 'split') div(classes: 'block-wire-media', [img(src: '$_assetRoot/media-glyph.svg', alt: '')]),
        ])
      else ...[
        div(classes: 'block-window-content', [
          span(classes: 'block-wire-line', []),
          span(classes: 'block-wire-line block-wire-line-short', []),
        ]),
        div(classes: 'block-window-footer', [
          div(classes: 'block-wire-nav', [
            div(classes: 'block-wire-brand', [
              span(classes: 'block-wire-emblem', []),
              span(classes: 'block-wire-headline', []),
              span(classes: 'block-wire-line', []),
              span(classes: 'block-wire-line block-wire-line-short', []),
            ]),
            div(classes: 'block-wire-sections', [
              for (var i = 0; i < 3; i++)
                div([
                  span(classes: 'block-wire-line', []),
                  span(classes: 'block-wire-line block-wire-line-short', []),
                  span(classes: 'block-wire-line', []),
                ]),
            ]),
          ]),
          div(classes: 'block-wire-legal', [
            img(src: '$_assetRoot/company.svg', alt: ''),
            span(classes: 'block-wire-line block-wire-line-short', []),
          ]),
        ]),
      ],
    ]),
  ],
);
