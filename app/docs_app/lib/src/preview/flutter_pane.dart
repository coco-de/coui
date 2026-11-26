/// 라이브 프리뷰의 Flutter 페인 — jaspr 쪽 `FlutterEmbedView` + `PreviewApp`
/// 의 네이티브 쌍둥이.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/preview/preview_theme.dart';
import 'package:docs_core/previews/flutter_chain_registry.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/preview_constraints.dart';

/// 컴포넌트(+선택적 변형)에 적용할 프리뷰 높이 제약.
///
/// 조회 순서는 jaspr 쪽 `viewConstraintsFor` 와 **같아야** 두 페인이 세로로
/// 맞는다: `component/variant` → `component` → 기본값. 숫자는 공유 맵
/// 한 곳에서만 산다.
DocsPreviewConstraints docsPreviewConstraintsFor(
  String component,
  String? variant,
) {
  final byVariant = variant != null
      ? kDocsPreviewConstraints['$component/$variant']
      : null;
  return byVariant ??
      kDocsPreviewConstraints[component] ??
      kDocsDefaultConstraints;
}

/// 컴포넌트 하나를 그리는 Flutter 프리뷰 페인.
///
/// 레지스트리에서 빌더를 찾아 프리뷰 테마 스코프 안에서 그린다. 등록되지
/// 않은 컴포넌트면 크래시 대신 안내 문구를 보여준다.
///
/// 높이는 이 페인이 아니라 호스트(`DocsLivePreview`)가 tier 의 `maxHeight`
/// 로 정한다 — docs_site 의 두 페인과 같은 무대 높이다.
class DocsFlutterPane extends StatelessWidget {
  /// [component] (+선택적 [variant]) 의 Flutter 프리뷰를 만든다.
  const DocsFlutterPane({
    required this.component,
    this.variant,
    this.chainPermutation,
    super.key,
  });

  /// 프리뷰할 컴포넌트 슬러그 (예: `button`).
  final String component;

  /// 프리뷰할 변형 (예: `primary`). 없으면 기본 프리뷰.
  ///
  /// 138 개 빌더 중 85 개는 변형을 아예 읽지 않는다 — 그런 컴포넌트의
  /// 변형 페인들이 똑같아 보이는 건 docs_site 와 일치하는 정상 동작이다.
  final String? variant;

  /// chain 순열 좌표 — 셔플 호스트(`DocsLivePreview`)가 스토어 step 을
  /// 해석해 넘긴다. 렌더러가 없는 chain(T2/T3)이나 non-chain 은 null 로
  /// registry 빌더 경로를 그대로 탄다 (jaspr `PreviewApp` 과 같은 분기).
  final ChainPermutation? chainPermutation;

  @override
  Widget build(BuildContext context) {
    final builder = kFlutterPreviewRegistry[component];
    final chainRenderer = chainPermutation != null
        ? kFlutterChainRegistry[component]
        : null;

    // 높이는 부모(`_PreviewPane` 의 SizedBox)가 정한다 — Web 페인과 같은
    // 높이를 써야 두 페인이 정렬된다. 여기서는 그 높이 안에서 콘텐츠를
    // 위로 붙인다 (Web 페인의 `.preview-content` 가 flex-start 로 top-align
    // 하는 것과 짝). 짧은 컴포넌트는 아래에 여백이 남고, 두 컴포넌트의 top
    // 이 같은 y 에서 시작한다.
    return Align(
      alignment: Alignment.topCenter,
      child: chainRenderer != null
          ? _PreviewScope(child: chainRenderer(chainPermutation!))
          : builder == null
          ? const _PreviewUnavailable()
          : _PreviewScope(child: builder(variant)),
    );
  }
}

/// 프리뷰 하나를 문서 본문과 분리된 테마 스코프에 넣는다.
///
/// [Theme] 만으로는 부족하다 — 앰비언트 `DefaultTextStyle` / `IconTheme` 은
/// 문서 본문 테마의 것이라, 다시 깔지 않으면 프리뷰 안 텍스트와 아이콘이
/// 프리뷰 테마가 아니라 문서 테마의 타이포/색을 물려받는다. `CoUIApp` 이
/// 앱 루트에서 하는 일을 프리뷰 서브트리에 국소적으로 반복한다.
class _PreviewScope extends StatelessWidget {
  const _PreviewScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == .dark;
    final theme = docsPreviewTheme(dark: dark);
    final foreground = theme.colorScheme.onSurface.toValue();
    final bodyMedium = theme.typography.bodyMedium;

    return Theme(
      data: theme,
      child: DefaultTextStyle.merge(
        style: bodyMedium.toValue(theme: theme).copyWith(color: foreground),
        child: IconTheme.merge(
          data: theme.iconTheme.medium.copyWith(color: foreground),
          // jaspr 프리뷰 호스트와 동일한 배치 — 위쪽 정렬 + 가로 중앙.
          //
          // 상단 여백은 16px 이어야 웹 페인과 세로로 맞는다. jaspr 은 프리뷰를
          // `.preview-content`(padding-top 8px) 안에 넣고, 그 안의 임베드가 다시
          // `Padding(vertical: 8)` 을 얹어 버튼 위가 8+8=16px 이 된다(web 은
          // `#web-` 패딩, flutter-web 은 preview_app.dart 의 Padding). 네이티브
          // 플러터 페인엔 `.preview-content` 래퍼가 없으므로 그 8px 을 여기서
          // 더해(8+8=16) 버튼이 웹 트윈과 같은 y 에서 시작하게 한다. 가로 16 ·
          // 하단 8 은 임베드와 동일하다.
          child: Align(
            alignment: .topCenter,
            child: Padding(
              padding: const .fromLTRB(
                CoreSpace.space16,
                CoreSpace.space16,
                CoreSpace.space16,
                CoreSpace.space8,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 레지스트리에 없는 컴포넌트 자리에 놓는 안내.
class _PreviewUnavailable extends StatelessWidget {
  const _PreviewUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const .all(CoreSpace.space16),
        child: const Text('Preview not available').bodySmall.onSurfaceVariant,
      ),
    );
  }
}
