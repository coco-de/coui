/// The authored documentation card, shared by the site and isolated scene host.
///
/// 카드의 모양은 넷이다 — 면 카드(`filled`, 기본), 선 카드(`outlined`),
/// 숫자 카드(`value` 를 적은 카드), 미리보기를 단 카드(`component` ·
/// `demo` 를 적은 카드). 앞의 셋은 Figma 문서 페이지(Getting Started ·
/// Foundations · Blocks · Resources)의 카드이고, 미리보기 카드는 컴포넌트
/// 페이지의 `Doc/Card` · `Doc/Do Dont` 다.
library;

import 'package:coui_web/coui_web.dart';

import 'docs_card_shape.dart';
import 'web_stage.dart';

export 'docs_card_shape.dart';

Component buildWebDocsCardGroup(List<Component> cards, {required int columns}) => div(
  classes: 'docs-cards not-content',
  styles: Styles(raw: {'--docs-cards-columns': '$columns'}),
  attributes: const {'data-docs-reveal': ''},
  cards,
);

Component buildWebStandaloneDocsCard(Map<String, String> attributes, {Component Function()? buildBody}) =>
    buildWebDocsCardGroup([
      buildWebDocsCard(attributes, index: 0, buildBody: buildBody),
    ], columns: kDocsCardsMinColumns);

/// 카드 한 장.
///
/// [variant] 는 묶음(`<Cards variant>`)이 정한 모양이다 — 카드가 자기
/// `variant` 를 적으면 그것이 이긴다.
Component buildWebDocsCard(
  Map<String, String> attributes, {
  required int index,
  Component Function()? buildBody,
  String? variant,
}) {
  final title = attributes['title'];
  final eyebrow = attributes['eyebrow'];
  final value = attributes['value'];
  final badge = attributes['badge'];
  final href = attributes['href'];
  final more = attributes['more'];
  final toneName = switch (attributes['tone']) {
    'do' => 'do',
    'dont' => 'dont',
    _ => null,
  };
  // 미리보기를 단 카드(형태 · Do/Don't · 배치 · 관련 컴포넌트) — 카드 위쪽에
  // 무대를 둔다. 미리보기 속성은 `<Preview>` 와 같다(`docs_preview_blocks.dart`).
  final hasPreview = attributes['component'] != null || attributes['demo'] != null;
  final shape = docsCardShape(attributes, groupVariant: variant);

  // 제목의 역할은 모양이 정한다 — 면 카드는 페이지의 첫 줄을 이끄는 카드라
  // 한 단 크고, 선 카드 · 숫자 카드는 그 안의 이름이라 한 단 작다.
  // 미리보기 카드는 무대 아래의 이름표다.
  Component titleText(String text) => switch ((hasPreview, shape, value != null)) {
    (true, _, _) => Text(text).titleSmall.onSurface,
    (_, _, true) || (_, 'outlined', _) => Text(text).labelXl.onSurface,
    _ => Text(text).titleMedium.onSurface,
  };

  final children = [
    if (hasPreview) buildWebDocsStage(attributes),
    if (eyebrow != null)
      span(classes: 'docs-card-eyebrow', [
        // 권장 · 금지는 글자가 종류를 말한다. 문서 페이지 카드의 그 밖의
        // 이름표는 순번 같은 짧은 표시라 고정폭 글자다.
        if (toneName != null || hasPreview) Text(eyebrow).labelSmall.medium else Text(eyebrow).codeSm,
      ]),
    if (value != null) span(classes: 'docs-card-value', [Text(value).headlineMedium.onSurface]),
    if (title != null || badge != null)
      div(classes: 'docs-card-head', [
        if (title != null) titleText(title),
        if (badge != null) Badge(variant: CoreBadgeVariant.outlined, child: Text(badge)),
      ]),
    if (buildBody != null) div(classes: 'docs-card-body', [buildBody()]),
    if (href != null && more != null)
      span(classes: 'docs-card-more', [
        // 링크는 밑줄이 말한다 — 화살표를 덧붙이지 않는다(Figma 의 다음 단계 카드).
        if (hasPreview) ...[
          Text(more).labelLarge.semiBold,
          siteArrow(Text('→').labelLarge.medium),
        ] else
          Text(more).labelLarge.medium,
      ]),
  ];

  final classes = [
    'docs-card',
    if (!hasPreview) 'docs-card--$shape',
    if (value != null) 'docs-card--stat',
    if (toneName != null) 'docs-card--$toneName',
    if (hasPreview) 'docs-card--preview',
  ].join(' ');
  if (href == null) {
    return div(classes: classes, styles: siteOrder(index), children);
  }
  return a(href: href, classes: '$classes site-box-link', styles: siteOrder(index), children);
}

/// 순차 등장에서의 자리 — 같은 줄의 몇 번째인가.
Styles siteOrder(int index) => Styles(raw: {'--i': '$index'});

/// 링크 끝의 화살표 — 장식이라 보조 기술에는 내지 않는다.
Component siteArrow(Component glyph) => span(
  classes: 'site-arrow',
  attributes: const {'aria-hidden': 'true'},
  [glyph],
);
