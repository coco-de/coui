import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'package:docs_core/shared/preview_variants.dart';
import 'live_preview_panel.dart';
import 'preview_gallery.dart';

/// chain 패널 인스턴스 카운터 — SSG 파일-top-level (Web overlay unique-id
/// 선례). 같은 컴포넌트의 `<LivePreview>` 태그가 한 페이지에 여럿이어도
/// panelId(`chain-{component}-{n}`)가 유일해 embed id·code id·스토어 키가
/// 충돌하지 않는다.
int _chainPanelCounter = 0;

/// Markdown `<LivePreview component="button" variant="primary" />` tag handler.
///
/// Supports single variant and multi-variant gallery modes:
/// - `<LivePreview component="button" variant="primary" />`
/// - `<LivePreview component="button" variants="primary,secondary,outline" />`
class LivePreview extends CustomComponent {
  LivePreview() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(tag: 'LivePreview', :final attributes)) {
      final component = attributes['component'];
      final variant = attributes['variant'];
      final variants = attributes['variants'];
      if (component == null) return null;

      // md-declared variants — `variants` list first, else single `variant`.
      final declared = variants != null
          ? [
              for (final part in variants.split(','))
                if (part.trim().isNotEmpty) part.trim(),
            ]
          : [if (variant != null && variant.trim().isNotEmpty) variant.trim()];

      // Metadata-driven shared variants (e.g. `chain`) are merged in one
      // place instead of being hand-declared per md file. `chain="off"` 는
      // 태그 단위 저자 큐레이션 — 같은 컴포넌트 태그가 복수인 페이지의
      // chain 중복 노출을 끈다 (페이지당 chain ≥1 불변식은 테스트가 강제).
      final effective = resolveDocsPreviewVariants(
        component,
        declared,
        chainOptOut: attributes['chain'] == 'off',
      );

      // Multi-variant gallery mode.
      if (variants != null || effective.length > 1) {
        return PreviewGallery(
          componentName: component,
          variants: effective,
          panelId: 'chain-$component-${++_chainPanelCounter}',
        );
      }

      // Single variant mode.
      return LivePreviewPanel(
        componentName: component,
        variant: effective.isEmpty ? null : effective.single,
      );
    }
    return null;
  }
}
