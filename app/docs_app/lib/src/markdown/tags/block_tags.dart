/// `<Cards>` + `<Card>`, `<Steps>` + `<Step>`, `<DesignNote>`, `<Code>` 태그 —
/// 본문의 묶음 블록.
///
/// jaspr 사이트의 `DocsBlocks`(`docs_site/lib/components/docs_blocks.dart`)와
/// 같은 태그를 같은 뜻으로 그린다. 속성의 이름도 같다 — 카드는 `title` ·
/// `eyebrow` · `value` · `badge` · `href` · `more` · `tone` · `variant`, 묶음은
/// `columns` · `variant`, 단계 묶음은 `size`, 노트는 `title` · `variant`, 코드는
/// `language` · `title`.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_core/internal/preview/flutter_card_view.dart';

export 'package:docs_core/internal/preview/flutter_card_view.dart'
    show kDocsCardMinWidth;

/// 단계 묶음이 받는 크기 — `<Steps size="large">`(사이트의 `kDocsStepsLargeSize`).
const String kDocsStepsLargeSize = 'large';

/// 노트가 받는 모양 — `<DesignNote variant>`(사이트의 `kDocsNoteVariants`).
const Set<String> kDocsNoteVariants = {'warning', 'outlined'};

/// 묶음 블록 태그 이름 → 빌더.
///
/// [nested] 는 카드 · 단계의 본문(마크다운)을 렌더한다. [onInternalLink] 는
/// 링크가 달린 카드를 눌렀을 때 그 경로로 호출된다.
///
/// `Card` 와 `Step` 도 등록한다 — 묶음 밖에 홀로 놓인 것이 통째로 사라지지
/// 않고 하나짜리 묶음으로 그려지게 하는 저하 경로다. 묶음 안의 것은 여기
/// 오지 않는다(부모가 본문에서 직접 뽑는다).
Map<String, DocsTagBuilder> docsBlockTagBuilders({
  required Widget Function(String markdown) nested,
  required void Function(String path) onInternalLink,
}) => {
  'Cards': (context, tag) => _DocsCards(
    cards: _children(tag.innerMarkdown ?? '', 'Card'),
    variant: docsCardVariant(tag.attribute('variant')),
    nested: nested,
    onInternalLink: onInternalLink,
  ),
  'Card': (context, tag) => _DocsCards(
    cards: [tag],
    nested: nested,
    onInternalLink: onInternalLink,
  ),
  'Steps': (context, tag) => _DocsSteps(
    steps: _children(tag.innerMarkdown ?? '', 'Step'),
    large: tag.attribute('size')?.trim() == kDocsStepsLargeSize,
    nested: nested,
  ),
  'Step': (context, tag) => _DocsSteps(steps: [tag], nested: nested),
  'DesignNote': (context, tag) => _DocsDesignNote(
    title: tag.attribute('title'),
    variant: switch (tag.attribute('variant')?.trim()) {
      final name? when kDocsNoteVariants.contains(name) => name,
      _ => null,
    },
    child: switch (tag.innerMarkdown?.trim()) {
      final body? when body.isNotEmpty => nested(body),
      _ => null,
    },
  ),
  // 사이트의 `SafeCodeBlock` 과 같은 태그 — 이름표는 `title`, 색은 `language`.
  'Code': (context, tag) => _DocsCodeTag(
    source: (tag.innerMarkdown ?? '')
        .replaceFirst(RegExp(r'^\n+'), '')
        .replaceFirst(RegExp(r'\n+$'), ''),
    language: tag.attribute('language'),
    title: tag.attribute('title'),
  ),
};

/// 묶음의 본문에서 이름이 [name] 인 태그를 순서대로 뽑는다.
///
/// 태그 스캔은 [findDocsTags] 를 그대로 쓴다 — 자체 정규식을 두면 코드 펜스
/// 인식과 속성 따옴표 규칙이 렌더러와 갈라진다.
List<DocsTag> _children(String innerMarkdown, String name) => [
  for (final match in findDocsTags(innerMarkdown))
    if (match.tag.name == name) match.tag,
];

class _DocsCards extends StatelessWidget {
  const _DocsCards({
    required this.cards,
    required this.nested,
    required this.onInternalLink,
    this.variant,
  });

  final List<DocsTag> cards;
  final String? variant;
  final Widget Function(String markdown) nested;
  final void Function(String path) onInternalLink;

  @override
  Widget build(BuildContext context) => FlutterDocsCardsLayout(
    cards: [
      for (final card in cards)
        _DocsCard(
          tag: card,
          variant: variant,
          nested: nested,
          onInternalLink: onInternalLink,
        ),
    ],
  );
}

class _DocsCard extends StatelessWidget {
  const _DocsCard({
    required this.tag,
    required this.nested,
    required this.onInternalLink,
    this.variant,
  });

  final DocsTag tag;
  final String? variant;
  final Widget Function(String markdown) nested;
  final void Function(String path) onInternalLink;

  @override
  Widget build(BuildContext context) => buildNativeDocsCardView(
    context: context,
    attributes: tag.attributes,
    rawBody: tag.innerMarkdown,
    nested: nested,
    onInternalLink: onInternalLink,
    variant: variant,
  );
}

class _DocsSteps extends StatelessWidget {
  const _DocsSteps({
    required this.steps,
    required this.nested,
    this.large = false,
  });

  final List<DocsTag> steps;

  /// 따라 하기 — 단계마다 코드 · 미리보기를 품어 넉넉하고 제목이 한 단 크다.
  final bool large;
  final Widget Function(String markdown) nested;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: large ? CoreSpace.space40 : CoreSpace.space20,
      children: [
        for (final (index, step) in steps.indexed)
          Row(
            crossAxisAlignment: .start,
            spacing: CoreSpace.space14,
            children: [
              // 번호는 순서를 말한다 — 장식이 아니라서 그대로 읽힌다.
              Badge(
                variant: .filled,
                child: Text('${index + 1}').labelSmall.medium,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  spacing: large ? CoreSpace.space8 : CoreSpace.space4,
                  children: [
                    if (step.attribute('title') case final title?)
                      if (large)
                        Text(title).titleMedium.onSurface
                      else
                        Text(title).titleSmall.onSurface,
                    if (step.innerMarkdown?.trim() case final body?
                        when body.isNotEmpty)
                      nested(body),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// `<DesignNote>` — 본문 옆에 놓는 한두 문장. 제목은 없어도 된다.
///
/// 모양은 사이트와 같은 셋이다: 회색 면(기본), 경고(`warning`), 선(`outlined`).
/// 사이트의 선 노트는 점선이다 — Flutter 의 테두리에는 점선이 없어 실선으로
/// 그린다.
class _DocsDesignNote extends StatelessWidget {
  const _DocsDesignNote({this.title, this.variant, this.child});

  final String? title;
  final String? variant;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color color(CoreColorToken token) =>
        scheme.resolve(CoreColor.token(token)).toValue();
    final warning = variant == 'warning';
    final outlined = variant == 'outlined';

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: outlined
              ? null
              : color(
                  warning
                      ? CoreColors.warningContainer
                      : CoreColors.surfaceContainer,
                ),
          border: outlined
              ? Border.all(color: color(CoreColors.outlineVariant))
              : null,
          borderRadius: const BorderRadius.all(
            Radius.circular(CoreRadiusRole.panel),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpace.space20,
            vertical: CoreSpace.space18,
          ),
          // 본문은 어느 모양에서나 같은 글자색이다 — 경고는 면과 제목이 거든다.
          child: DefaultTextStyle.merge(
            style: TextStyle(color: color(CoreColors.onSurfaceVariant)),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              spacing: CoreSpace.space6,
              children: [
                if (title case final title?)
                  if (warning)
                    Text(title).labelXl.onWarningContainer
                  else
                    Text(title).labelXl.onSurface,
                ?child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `<Code>` — 이름표가 달린 코드. 본문의 코드 펜스와 같은 `CodeSnippet` 이다.
class _DocsCodeTag extends StatelessWidget {
  const _DocsCodeTag({required this.source, this.language, this.title});

  final String source;
  final String? language;
  final String? title;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    spacing: CoreSpace.space8,
    children: [
      // Text 체인에 한 단 물러난 글자색의 이름이 없어, 역할과 색을 함께 적는다.
      if (title case final title?)
        Text(
          title,
          style: const CoreTextStyle.token(
            CoreTextStyles.codeSm,
            color: CoreColor.onSurfaceSubtle,
          ).toValue(theme: Theme.of(context)),
        ),
      CodeSnippet(code: source, mode: language ?? 'text'),
    ],
  );
}
