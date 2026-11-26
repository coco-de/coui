import 'package:jaspr/jaspr.dart';
import 'package:jaspr_flutter_embed/jaspr_flutter_embed.dart';

import 'package:docs_core/shared/preview_constraints.dart';
import 'package:docs_core/shared/preview_panel_id.dart';
import 'preview_skeleton.dart';

@Import.onWeb('../widgets/preview_app.dart', show: [#PreviewApp])
import 'flutter_preview.imports.dart';

/// 공유 순수-Dart 제약을 jaspr 임베드의 [ViewConstraints] 로 옮긴다.
///
/// 숫자는 `shared/preview_constraints.dart` 한 곳에서만 산다 — docs_app 이
/// 같은 맵을 읽어 자기 렌더러용으로 매핑한다.
ViewConstraints _toViewConstraints(DocsPreviewConstraints c) =>
    ViewConstraints(minHeight: c.minHeight, maxHeight: c.maxHeight);

/// 컴포넌트(+선택적 변형)에 적용할 임베드 제약.
///
/// 조회는 Web 팬과 같은 `docsPreviewConstraintsFor` 단일 출처를 거친다
/// (per-variant 우선 + chain 하한 포함) — 양쪽이 세로로 맞아야 한다.
ViewConstraints viewConstraintsFor(String component, String? variant) =>
    _toViewConstraints(docsPreviewConstraintsFor(component, variant));

/// Client-side component that hydrates FlutterEmbedView for live previews.
///
/// The view is created at the tier height and stays there — the app root
/// fills its view, so it resolves to the tier's `maxHeight`, and the Web
/// pane (`WebPreview`) takes that same height as a fixed stage. Why the
/// height is a tier chosen ahead of time rather than a measurement is
/// written down in `shared/preview_constraints.dart`.
@client
class FlutterPreview extends StatelessComponent {
  const FlutterPreview({required this.component, this.variant, this.panelId, super.key});

  final String component;
  final String? variant;
  final String? panelId;

  @override
  Component build(BuildContext context) =>
      FlutterPreviewContent(component: component, variant: variant, panelId: panelId);
}

/// Embedded view for composition inside an existing client island.
class FlutterPreviewContent extends StatelessComponent {
  const FlutterPreviewContent({
    required this.component,
    this.variant,
    this.panelId,
    super.key,
  });

  final String component;
  final String? variant;

  /// chain 패널의 인스턴스-유일 id — SSG(`live_preview.dart`)가 부여하고
  /// 임베드 id 파생과 [PreviewApp] 의 셔플 스토어 구독 키로 흐른다.
  final String? panelId;

  @override
  Component build(BuildContext context) {
    // Per-variant constraints (`component/variant` key) win, then the
    // component entry, then the default — the same lookup the Web pane uses.
    final constraints = viewConstraintsFor(component, variant);

    return FlutterEmbedView(
      // chain 패널은 같은 컴포넌트 임베드가 한 페이지에 여럿일 수 있어
      // panelId 파생 id 를 쓴다 — 파생식 단일 출처는 preview_panel_id.dart.
      id: flutterEmbedElementId(
        component: component,
        variant: variant,
        panelId: panelId,
      ),
      constraints: constraints,
      loader: const PreviewSkeleton(),
      widget: kIsWeb ? PreviewApp(component: component, variant: variant, panelId: panelId) : null,
    );
  }
}
