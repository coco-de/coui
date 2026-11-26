import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:docs_core/previews/code_registry.dart';
import 'package:docs_core/previews/flutter_code_registry.dart';
import 'package:docs_core/shared/preview_layout.dart';
import 'package:docs_core/shared/preview_panel_id.dart';
import 'package:docs_core/components/web_preview.dart';
import 'flutter_preview.dart';

/// Renders Web + Flutter side-by-side preview with code snippet.
class LivePreviewPanel extends StatelessComponent {
  const LivePreviewPanel({
    required this.componentName,
    super.key,
    this.variant,
    this.panelId,
    this.parentOwnsHydration = false,
  });

  final String componentName;
  final String? variant;

  /// chain 항목의 인스턴스-유일 id — 코드 요소·copy 버튼 id 와 양 팬의
  /// 스토어 구독 키로 흐른다. non-chain 은 null (기존 마크업 무변경).
  final String? panelId;

  /// A gallery owns the client boundary for both preview contents.
  final bool parentOwnsHydration;

  @override
  Component build(BuildContext context) {
    final webCode = _getWebCodeSnippet();
    final flutterCode = _getFlutterCodeSnippet();

    final isWide = kDocsWideComponents.contains(componentName);

    return div(classes: 'live-preview', [
      // Preview container: Web | Flutter side-by-side (or stacked for wide).
      div(
        classes: 'preview-container${isWide ? ' preview-container--stacked' : ''}',
        [
          // Web preview (SSG-time rendering).
          div(classes: 'preview-pane preview-web', [
            div(classes: 'preview-label', [
              span(classes: 'preview-label-dot preview-label-dot--web', []),
              Component.text('Web'),
            ]),
            div(classes: 'preview-content not-content', [
              _buildWebPreview(),
            ]),
          ]),
          // Flutter preview (client-time rendering).
          div(classes: 'preview-pane preview-flutter', [
            div(classes: 'preview-label', [
              span(classes: 'preview-label-dot preview-label-dot--flutter', []),
              Component.text('Flutter'),
            ]),
            div(classes: 'preview-content not-content', [
              _buildFlutterPreview(),
            ]),
          ]),
        ],
      ),
      // Code snippet with Web / Flutter tabs.
      details(classes: 'preview-code', [
        summary(classes: 'preview-code-summary', [Component.text('코드 보기')]),
        div(classes: 'preview-code-header', [
          div(
            classes: 'preview-code-tabs',
            attributes: const {'role': 'group', 'aria-label': '코드 플랫폼'},
            [
              button(
                classes: 'preview-code-tab preview-code-tab--active',
                attributes: {'data-tab': 'web', 'aria-pressed': 'true'},
                events: {},
                [
                  span(classes: 'preview-label-dot preview-label-dot--web', []),
                  Component.text('Web'),
                ],
              ),
              button(
                classes: 'preview-code-tab',
                attributes: {'data-tab': 'flutter', 'aria-pressed': 'false'},
                events: {},
                [
                  span(
                    classes: 'preview-label-dot preview-label-dot--flutter',
                    [],
                  ),
                  Component.text('Flutter'),
                ],
              ),
            ],
          ),
          button(
            // chain 패널만 id 를 갖는다 — 셔플 시 data-code 를 현재 순열
            // 코드로 갱신하는 대상.
            id: panelId != null ? chainCopyElementId(panelId!) : null,
            classes: 'preview-copy-btn',
            attributes: {'data-code': webCode},
            events: {},
            [Component.text('Copy')],
          ),
        ]),
        div(
          classes: 'preview-code-panel preview-code-panel--active',
          attributes: {'data-panel': 'web'},
          [
            pre([
              code(
                id: panelId != null ? chainCodeElementId(panelId!, forFlutter: false) : null,
                classes: 'language-dart',
                [Component.text(webCode)],
              ),
            ]),
          ],
        ),
        div(
          classes: 'preview-code-panel',
          attributes: {'data-panel': 'flutter'},
          [
            pre([
              code(
                id: panelId != null ? chainCodeElementId(panelId!, forFlutter: true) : null,
                classes: 'language-dart',
                [Component.text(flutterCode)],
              ),
            ]),
          ],
        ),
      ]),
    ]);
  }

  /// Build web preview using @client WebPreview component.
  Component _buildWebPreview() {
    if (parentOwnsHydration) {
      return WebPreviewContent(component: componentName, variant: variant, panelId: panelId);
    }
    return WebPreview(
      component: componentName,
      variant: variant,
      panelId: panelId,
    );
  }

  /// Build Flutter preview using @client FlutterPreview component.
  Component _buildFlutterPreview() {
    if (parentOwnsHydration) {
      return FlutterPreviewContent(component: componentName, variant: variant, panelId: panelId);
    }
    return FlutterPreview(
      component: componentName,
      variant: variant,
      panelId: panelId,
    );
  }

  /// Get Web code snippet from the code registry.
  String _getWebCodeSnippet() {
    final builder = kCodeSnippetRegistry[componentName];
    if (builder == null) {
      return '// No code example available';
    }
    return builder(variant);
  }

  /// Get Flutter code snippet from the Flutter code registry.
  String _getFlutterCodeSnippet() {
    final builder = kFlutterCodeSnippetRegistry[componentName];
    if (builder == null) {
      // Fall back to web code if no Flutter-specific code exists.
      return _getWebCodeSnippet();
    }
    return builder(variant);
  }
}
