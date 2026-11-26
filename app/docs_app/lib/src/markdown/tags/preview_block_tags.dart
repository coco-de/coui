/// `<Preview>` · `<VariantRow>` · `<SizeSpec>` 태그 — 컴포넌트 페이지(v2
/// 템플릿)의 미리보기 블록.
///
/// jaspr 사이트의 `DocsPreviewBlocks`(`docs_site/lib/components/
/// docs_preview_blocks.dart`)와 같은 태그를 같은 뜻으로 그린다. 속성의
/// 이름도 같다 — `component` · `props` · `label` · `example` · `height` ·
/// `name`.
///
/// 미리보기는 속성 문자열을 사이트와 같은 파서(`preview_props.dart`)로 읽어
/// Flutter 빌더(`flutter_prop_previews.dart`)에 넘긴다. 이 앱은 Flutter
/// 라서 무대에 Flutter 렌더를 그대로 놓는다 — 사이트의 블록은 Jaspr Web 을
/// 그린다.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_core/internal/preview/flutter_selection.dart';
import 'package:docs_core/internal/preview/flutter_stage.dart';
import 'package:docs_core/internal/preview/selection.dart';
import 'package:docs_core/previews/props/flutter_prop_previews.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_core/shared/size_spec.dart';

export 'package:docs_core/internal/preview/flutter_stage.dart'
    show
        DocsStage,
        docsPreviewFor,
        kDocsStageCompactMinHeight,
        kDocsStageMinHeight;

/// Variant 행에서 무대가 차지하는 폭 — 사이트와 같은 값.
const double kDocsVariantStageWidth = 220;

/// 이 폭보다 좁으면 Variant 행이 무대를 위에, 글을 아래에 둔다.
const double kDocsVariantRowBreakpoint = 520;

/// 미리보기 블록의 본문에서 이름이 [name] 인 태그를 순서대로 뽑는다.
List<DocsTag> _childTags(String? innerMarkdown, String name) => [
  for (final match in findDocsTags(innerMarkdown ?? ''))
    if (match.tag.name == name) match.tag,
];

/// 미리보기 블록 태그 이름 → 빌더. [nested] 는 행의 본문(마크다운)을 렌더한다.
Map<String, DocsTagBuilder> docsPreviewBlockTagBuilders({
  required Widget Function(String markdown) nested,
}) => {
  'Preview': (context, tag) => DocsStage(attributes: tag.attributes),
  'VariantRow': (context, tag) => _DocsVariantRow(tag: tag, nested: nested),
  'SizeSpec': (context, tag) {
    final component = tag.attribute('component');
    final spec = component == null ? null : docsSizeSpecFor(component);
    if (component == null || spec == null) return null;
    return FlutterDocsSizeSpec(
      component: component,
      spec: spec,
      attributes: tag.attributes,
    );
  },
  'Playground': (context, tag) {
    final component = tag.attribute('component');
    final spec = component == null ? null : kDocsPlaygrounds[component];
    if (component == null || spec == null) return null;
    return _DocsPlayground(component: component, spec: spec);
  },
  'Anatomy': (context, tag) => _DocsAnatomy(tag: tag, nested: nested),
  'Note': (context, tag) => _DocsNote(
    label: tag.attribute('label') ?? '참고',
    child: nested(tag.innerMarkdown?.trim() ?? ''),
  ),
  // 앱은 본문 폭이 좁아 두 열을 세로로 쌓는다.
  'Split': (context, tag) => nested(tag.innerMarkdown ?? ''),
};

/// 무대 하나 — 회색 판 가운데에 미리보기를 놓는다. 카드의 미리보기도 쓴다.

/// 태그 속성의 미리보기 — `example` 이면 미리보기 레지스트리, 아니면 속성 빌더.

class _DocsVariantRow extends StatelessWidget {
  const _DocsVariantRow({required this.tag, required this.nested});

  final DocsTag tag;
  final Widget Function(String markdown) nested;

  @override
  Widget build(BuildContext context) {
    final name = tag.attribute('name');
    final body = tag.innerMarkdown?.trim() ?? '';
    final stage = DocsStage(attributes: tag.attributes, compact: true);
    final text = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: CoreSpace.space6,
      children: [
        if (name != null) Text(name).codeMd.onSurface,
        if (body.isNotEmpty) nested(body),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoreSpace.space16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < kDocsVariantRowBreakpoint) {
            return Column(
              crossAxisAlignment: .stretch,
              spacing: CoreSpace.space12,
              children: [stage, text],
            );
          }
          return Row(
            spacing: CoreSpace.space24,
            children: [
              SizedBox(width: kDocsVariantStageWidth, child: stage),
              Expanded(child: text),
            ],
          );
        },
      ),
    );
  }
}

/// 플레이그라운드 — 앱은 처음 속성의 미리보기와 그 코드를 보여 준다.
///
/// 컨트롤은 사이트가 맡는다: 앱의 본문은 Flutter 이므로 플랫폼 전환이
/// 필요 없고, 같은 속성의 미리보기는 페이지의 Variant · 크기 블록이 보여 준다.
class _DocsPlayground extends StatelessWidget {
  const _DocsPlayground({required this.component, required this.spec});

  final String component;
  final DocsPlaygroundSpec spec;

  @override
  Widget build(BuildContext context) {
    final builder = kFlutterPropPreviews[component];
    return Column(
      crossAxisAlignment: .stretch,
      spacing: CoreSpace.space12,
      children: [
        if (builder != null)
          buildFlutterPlaygroundStage(
            context,
            renderFlutterSelection(
              PreviewSelection.properties(component, spec.initial, spec.label),
            )!,
          ),
        CodeSnippet(
          code: spec.codeFor(
            DocsCodePlatform.flutter,
            spec.initial,
            spec.label,
          ),
          mode: 'dart',
        ),
      ],
    );
  }
}

/// 구조 — 미리보기와 번호 붙은 부분 설명.
class _DocsAnatomy extends StatelessWidget {
  const _DocsAnatomy({required this.tag, required this.nested});

  final DocsTag tag;
  final Widget Function(String markdown) nested;

  @override
  Widget build(BuildContext context) {
    final items = _childTags(tag.innerMarkdown, 'AnatomyItem');
    return Column(
      crossAxisAlignment: .stretch,
      spacing: CoreSpace.space12,
      children: [
        DocsStage(attributes: tag.attributes),
        for (final (index, item) in items.indexed)
          Row(
            crossAxisAlignment: .start,
            spacing: CoreSpace.space8,
            children: [
              Text('${index + 1}').labelMedium.semiBold,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(item.attribute('name') ?? '').codeSm,
                    nested(item.innerMarkdown?.trim() ?? ''),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// 참고 상자.
class _DocsNote extends StatelessWidget {
  const _DocsNote({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme
            .resolve(const CoreColor.token(CoreColors.surfaceContainer))
            .toValue(),
        borderRadius: const BorderRadius.all(
          Radius.circular(CoreRadiusRole.panel),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space12,
        ),
        child: Row(
          crossAxisAlignment: .start,
          spacing: CoreSpace.space12,
          children: [
            Text(label).labelMedium.semiBold,
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
