/// 컴포넌트 페이지(v2 템플릿)의 미리보기 블록 — `<Preview>` · `<VariantRow>` ·
/// `<SizeSpec>`.
///
/// ```md
/// <Preview component="button" props="variant=outline;trailing=external-link" label="홈페이지 열기" />
///
/// <VariantRow name="primary" component="button" props="variant=primary" label="저장하기">
///
/// 화면에서 가장 중요한 행동 하나에 씁니다.
///
/// </VariantRow>
///
/// <SizeSpec component="button" label="버튼" />
///
/// <Playground component="button" />
///
/// <Anatomy demo="button/anatomy">
/// <AnatomyItem part="container" name="Container">배경, 테두리, 모서리.</AnatomyItem>
/// <AnatomyItem select="input" side="right" name="value">입력 값.</AnatomyItem>
/// </Anatomy>
///
/// <Note>menu, menubar, fixed는 내부용 variant입니다.</Note>
///
/// <Split>
/// (두 열로 나란히 놓을 블록들)
/// </Split>
/// ```
///
/// 미리보기는 예제 파일이 아니라 **속성**으로 고른다
/// (`docs_core/shared/preview_props.dart`). 합성 장면처럼 속성으로 표현되지
/// 않는 미리보기는 `example` 속성으로 미리보기 레지스트리의 변형을 고른다
/// (`<LivePreview>` 와 같은 레지스트리).
///
/// 블록 미리보기는 Jaspr Web 으로만 그린다 — 두 플랫폼 비교는 페이지의
/// 플레이그라운드가 맡는다. 같은 태그를 네이티브 문서 앱(`app/docs_app`)도
/// 그린다 — 태그를 더하면 그쪽 레지스트리에도 더한다.
library;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/internal/preview/web_stage.dart';
import 'package:docs_core/internal/preview/web_anatomy_view.dart';
import 'package:jaspr_content/jaspr_content.dart';

export 'package:docs_core/internal/preview/web_stage.dart' show kDocsStageHeights;

import 'docs_playground.dart';

/// 무대 높이의 이름 — Figma `Doc/Stage` 의 `Height` 변형과 같은 이름.

/// 플레이그라운드 인스턴스 카운터 — 한 페이지의 플레이그라운드 id 가
/// 겹치지 않게 한다(`live_preview.dart` 의 chain 카운터와 같은 이유).
int _playgroundCounter = 0;

/// `<Preview>` · `<VariantRow>` · `<SizeSpec>`.
class DocsPreviewBlocks extends CustomComponent {
  /// 미리보기 블록 컴포넌트를 만든다.
  DocsPreviewBlocks() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node is! ElementNode) return null;
    return switch (node.tag) {
      'Preview' => docsStage(node.attributes),
      'VariantRow' => _variantRow(node, builder),
      'SizeSpec' => _sizeSpec(node.attributes),
      'Playground' => _playground(node.attributes),
      'Anatomy' => _anatomy(node, builder),
      'Note' => div(classes: 'docs-note not-content', [
        strong([Component.text(node.attributes['label'] ?? '참고')]),
        div(classes: 'docs-note-body content', [builder.build(node.children ?? const [])]),
      ]),
      'Split' => div(classes: 'docs-split', [builder.build(node.children ?? const [])]),
      _ => null,
    };
  }

  Component _variantRow(ElementNode node, NodesBuilder builder) {
    final name = node.attributes['name'];
    final body = node.children;
    return div(classes: 'docs-variant-row not-content', [
      docsStage(node.attributes, compact: true),
      div(classes: 'docs-variant-text', [
        if (name != null) code(classes: 'docs-variant-name', [Component.text(name)]),
        if (body != null && body.isNotEmpty) div(classes: 'docs-variant-body content', [builder.build(body)]),
      ]),
    ]);
  }

  Component _playground(Map<String, String> attributes) {
    final component = attributes['component'];
    if (component == null) return const Component.empty();
    return DocsPlayground(component: component, panelId: 'playground-$component-${++_playgroundCounter}');
  }

  Component _anatomy(ElementNode node, NodesBuilder builder) => buildWebDocsAnatomy(node, builder);

  Component _sizeSpec(Map<String, String> attributes) => buildWebSizeSpec(attributes);
}

/// 무대 하나 — 판 가운데에 미리보기를 놓는다.
///
/// `<Card>` 의 미리보기도 이 무대를 쓴다(`docs_blocks.dart`).
Component docsStage(Map<String, String> attributes, {bool compact = false}) =>
    buildWebDocsStage(attributes, compact: compact);

/// 무대에 놓을 것 — 장면 이름(`demo`), 미리보기 레지스트리의 변형
/// (`example`), 아니면 속성(`props`).
