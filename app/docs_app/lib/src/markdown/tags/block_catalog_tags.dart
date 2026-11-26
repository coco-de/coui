/// 블록 페이지의 그림 태그 — `<BlockCatalogVisual kind="…" />`.
///
/// 사이트는 블록마다 브라우저 창 모양의 그림을 그린다(`docs_site`
/// `block_catalog_visuals.dart`). 여기서는 그림 대신 **같은 값**을 목록으로
/// 그린다 — 블록 이름 · 설명 · `Layout` 값은 블록 카탈로그
/// (`kDocsBlocks`)에서, Footer 구조의 범례는 `kDocsFooterStructure` 에서
/// 온다. 두 표면이 같은 목록을 읽으므로 값이 갈라질 자리가 없다.
///
/// `kind` 는 사이트와 같은 넷이다: `catalog` · `hero-layouts` ·
/// `footer-layouts` · `footer-structure`. 모르는 값은 아무것도 그리지 않는다
/// (사이트도 같다).
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_app/src/markdown/inline_renderer.dart';
import 'package:docs_core/shared/block_catalog.dart';

/// 블록 그림 태그 이름 → 빌더.
///
/// [onInternalLink] 는 개요 카드의 탭에서 쓴다 — 블록 페이지 경로를 받는다.
Map<String, DocsTagBuilder> docsBlockCatalogTagBuilders({
  required void Function(String path) onInternalLink,
}) => {
  'BlockCatalogVisual': (context, tag) =>
      switch (tag.attribute('kind')?.trim()) {
        'catalog' => _BlockCatalogView(onInternalLink: onInternalLink),
        'hero-layouts' => _BlockLayoutsView(block: _block('hero')),
        'footer-layouts' => _BlockLayoutsView(block: _block('footer')),
        'footer-structure' => const _FooterStructureView(),
        _ => const SizedBox.shrink(),
      },
};

DocsBlockEntry _block(String slug) =>
    kDocsBlocks.firstWhere((block) => block.slug == slug);

/// 고정폭 이름표 — 사이트의 `code` 와 같은 글자.
class _CodeLabel extends StatelessWidget {
  const _CodeLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(text: text, style: docsInlineCodeStyle(context)),
  ).bodySmall.onSurface;
}

/// 개요의 블록 목록 — 카드마다 이름 · 설명 · `Layout` 값. 탭하면 그 블록 페이지로.
class _BlockCatalogView extends StatelessWidget {
  const _BlockCatalogView({required this.onInternalLink});

  final void Function(String path) onInternalLink;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      columns: 2,
      cellSpacing: CoreSpace.space16,
      children: [
        for (final block in kDocsBlocks)
          Card(
            onTap: () => onInternalLink(block.path),
            body: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text(block.name).titleMedium.semiBold.onSurface,
                const Gap.space6(),
                Text(block.description).bodyMedium.onSurfaceVariant,
                const Gap.space8(),
                Wrap(
                  spacing: CoreSpace.space6,
                  runSpacing: CoreSpace.space6,
                  children: [
                    for (final layout in block.layouts)
                      _CodeLabel('Layout=$layout'),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 블록 페이지의 레이아웃 목록 — 사이트가 그림 아래에 적는 이름표.
class _BlockLayoutsView extends StatelessWidget {
  const _BlockLayoutsView({required this.block});

  final DocsBlockEntry block;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: CoreSpace.space8,
      runSpacing: CoreSpace.space8,
      children: [
        for (final layout in block.layouts)
          _CodeLabel(block.layoutLabel(layout)),
      ],
    );
  }
}

/// Footer 구조의 범례 — 세로로 쌓이는 세 블록과 그 블록을 채우는 속성.
class _FooterStructureView extends StatelessWidget {
  const _FooterStructureView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        for (final (index, part) in kDocsFooterStructure.indexed) ...[
          if (index > 0) const Gap.space12(),
          Text('${index + 1} ${part.label}').labelLarge.onSurface,
          const Gap.space2(),
          _CodeLabel(part.slots),
        ],
      ],
    );
  }
}
