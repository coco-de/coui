/// 본문의 묶음 블록 — 카드 묶음(`<Cards>`), 단계(`<Steps>`), 노트
/// (`<DesignNote>`).
///
/// Figma 문서 페이지(CoUI website 의 Getting Started · Foundations · Blocks ·
/// Resources)가 되풀이해 쓰는 블록이다. 태그와 속성은 아래가 전부다.
///
/// ```md
/// <Cards columns="3">                      ← 열 수 1–4. 적지 않으면 카드 수
///   <Card eyebrow="01" title="하나의 토큰">
///
/// 색상, 타이포그래피, 간격을 `coui_core` 한곳에서 정의합니다.
///
/// </Card>
/// </Cards>
///
/// <Cards variant="outlined">               ← 면 카드(filled, 기본) · 선 카드(outlined)
///   <Card title="컴파일러가 막는 것">
///
/// - 컴포넌트 이름 충돌
///
/// </Card>
///   <Card tone="do" eyebrow="권장" title="토큰으로">…</Card>   ← 권장 · 금지
///   <Card value="34" title="명세">값을 정의합니다.</Card>      ← 숫자 카드
/// </Cards>
///
/// <Cards>
///   <Card title="빠른 시작" href="/getting-started" more="빠른 시작">…</Card>
/// </Cards>                                 ← 링크 카드: 카드 전체가 링크, `more` 는 밑줄 글자
///
/// <Steps>                                  ← 짧은 절차(제목 + 한 문단)
///   <Step title="기준 문서를 엽니다">
///
/// 본문 — 문단, 코드 펜스, 표가 그대로 들어간다.
///
/// </Step>
/// </Steps>
///
/// <Steps size="large">                     ← 따라 하기(제목 + 설명 + 코드 · 미리보기)
///   …
/// </Steps>
///
/// <DesignNote title="우회하면 조용히 깨집니다">   ← 노트. 제목은 없어도 된다
/// 리터럴 색은 CSS 변수를 거치지 않아 다크 모드에서 틀립니다.
/// </DesignNote>
///
/// <DesignNote title="생성된 코드는 반드시 dart analyze로 확인합니다" variant="warning">
/// …                                        ← 경고 노트(warning) · 점선 노트(outlined)
/// </DesignNote>
/// ```
///
/// 마크다운 본문 뒤의 닫는 태그(`</Card>` · `</Step>`)는 들여 쓰지 않는다 —
/// 목록 뒤에서 들여 쓴 줄은 목록이 이어지는 줄로 읽혀 블록이 닫히지 않는다.
/// `<Code …>` 와 `</Code>` 는 각각 한 줄에 혼자 쓴다 — 그 사이는 빈 줄과
/// 제네릭(`Select<String>`)까지 글자 그대로 코드다(`docs_core` 의
/// `code_tag_block_syntax.dart`). 닫는 줄이 없으면 HTML 로 읽혀 뒤의 본문이
/// 코드 상자로 들어간다.
///
/// 같은 태그를 네이티브 문서 앱(`app/docs_app`)도 그린다 — 태그를 더하면
/// 그쪽 레지스트리에도 더한다(그 앱의 태그 검사가 빠진 것을 잡는다).
///
/// ## 글자는 킷이, 상자는 시트가
///
/// 제목과 이름표는 킷의 `Text` 역할이고 배지는 킷의 `Badge` 다. 상자의
/// 선 · 면 · 간격은 `web/docs-shell.css` 가 킷의 변수로 그린다 — 카드가
/// 링크일 때 카드 전체가 `<a>` 여야 해서, 킷의 `Card` 를 그대로 쓸 수 없다
/// (그 컴포넌트의 누름은 브라우저에서 깨어나야 동작한다).
library;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/internal/preview/web_card_view.dart'
    show
        buildWebDocsCard,
        buildWebDocsCardGroup,
        buildWebStandaloneDocsCard,
        docsCardVariant,
        kDocsCardsMinColumns,
        kDocsCardsMaxColumns;
import 'package:jaspr_content/jaspr_content.dart';

import 'docs_code.dart' show kDocsCodePlainAttribute;
import 'site_landing_parts.dart';

export 'package:docs_core/internal/preview/web_card_view.dart'
    show kDocsCardDefaultVariant, kDocsCardVariants, kDocsCardsMinColumns, kDocsCardsMaxColumns;

/// 단계 묶음이 받는 크기 — `<Steps size="large">`.
const String kDocsStepsLargeSize = 'large';

/// 노트가 받는 모양 — `<DesignNote variant>`.
const Set<String> kDocsNoteVariants = {'warning', 'outlined'};

/// `<Cards>` · `<Card>` · `<Steps>` · `<Step>` · `<DesignNote>`.
class DocsBlocks extends CustomComponent {
  /// 묶음 블록 컴포넌트를 만든다.
  DocsBlocks() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node is! ElementNode) return null;

    return switch (node.tag) {
      'Cards' => _cards(node, builder),
      'Steps' => _steps(node, builder),
      // 묶음 밖에 홀로 놓인 것 — 사라지지 않고 하나짜리 묶음으로 그려진다.
      'Card' => buildWebStandaloneDocsCard(
        node.attributes,
        buildBody: node.children != null && node.children!.isNotEmpty ? () => builder.build(node.children!) : null,
      ),
      'Step' => _stepGroup([_step(node, builder, 0)], large: false),
      'DesignNote' => _note(node, builder),
      _ => null,
    };
  }

  // ── 카드 ────────────────────────────────────────────────────────

  Component _cards(ElementNode node, NodesBuilder builder) {
    final cards = _named(node, 'Card');
    final asked = int.tryParse(node.attributes['columns'] ?? '');
    final columns = (asked ?? cards.length).clamp(kDocsCardsMinColumns, kDocsCardsMaxColumns);

    // 묶음이 정한 모양을 카드마다 넘긴다 — 카드가 자기 모양을 적으면 그것이 이긴다.
    final variant = docsCardVariant(node.attributes['variant']);

    return _cardGroup([
      for (final (index, card) in cards.indexed) _card(card, builder, index, variant: variant),
    ], columns: columns);
  }

  Component _cardGroup(List<Component> cards, {required int columns}) => buildWebDocsCardGroup(cards, columns: columns);

  Component _card(ElementNode node, NodesBuilder builder, int index, {required String variant}) => buildWebDocsCard(
    node.attributes,
    index: index,
    variant: variant,
    buildBody: node.children != null && node.children!.isNotEmpty
        ? () => builder.build(_plainCode(node.children!))
        : null,
  );

  /// 카드 본문의 코드 펜스는 맨 코드다 — 이름표 · 복사 · 면 없이, 설명의
  /// 한 부분으로 놓인다(Figma 의 권장 · 금지 카드).
  static List<Node> _plainCode(List<Node> nodes) => [
    for (final node in nodes)
      if (node case ElementNode(tag: 'pre', children: [ElementNode(tag: 'code') && final code]))
        ElementNode('pre', node.attributes, [
          ElementNode('code', {...code.attributes, kDocsCodePlainAttribute: ''}, code.children),
        ])
      else
        node,
  ];

  // ── 단계 ────────────────────────────────────────────────────────

  Component _steps(ElementNode node, NodesBuilder builder) {
    final large = node.attributes['size']?.trim() == kDocsStepsLargeSize;

    return _stepGroup([
      for (final (index, step) in _named(node, 'Step').indexed) _step(step, builder, index, large: large),
    ], large: large);
  }

  Component _stepGroup(List<Component> steps, {required bool large}) {
    return div(
      classes: large ? 'docs-steps docs-steps--large' : 'docs-steps',
      attributes: const {'role': 'list', 'data-docs-reveal': ''},
      steps,
    );
  }

  Component _step(ElementNode node, NodesBuilder builder, int index, {bool large = false}) {
    final title = node.attributes['title'];
    final body = node.children;

    return div(
      classes: 'docs-step',
      styles: siteOrder(index),
      attributes: const {'role': 'listitem'},
      [
        // 번호는 순서를 말한다 — 장식이 아니라서 보조 기술에도 읽힌다.
        span(classes: 'docs-step-number not-content', [Text('${index + 1}').labelSmall.medium]),
        div(classes: 'docs-step-main', [
          // 따라 하기의 단계는 그 아래 코드를 이끄는 제목이라 한 단 크다.
          if (title != null)
            div(classes: 'docs-step-title not-content', [
              if (large) Text(title).titleMedium.onSurface else Text(title).titleSmall.onSurface,
            ]),
          if (body != null && body.isNotEmpty) div(classes: 'docs-step-body', [builder.build(body)]),
        ]),
      ],
    );
  }

  // ── 노트 ────────────────────────────────────────────────────────

  /// 본문 옆에 놓는 한두 문장 — 제목은 없어도 된다.
  ///
  /// 모양은 셋이다: 회색 면(기본), 경고(`warning` — 지금 그대로 믿으면 안 되는
  /// 것), 점선(`outlined` — 아직 정해지지 않은 것). 종류는 색만이 아니라
  /// 제목의 글이 말한다.
  Component _note(ElementNode node, NodesBuilder builder) {
    final title = node.attributes['title'];
    final variant = node.attributes['variant']?.trim();
    final body = node.children;

    return div(
      classes: [
        'design-note',
        if (kDocsNoteVariants.contains(variant)) 'design-note-$variant',
      ].join(' '),
      attributes: const {'role': 'note'},
      [
        if (title != null) strong(classes: 'design-note-title', [Text(title).labelXl]),
        if (body != null && body.isNotEmpty) div(classes: 'design-note-body', [builder.build(body)]),
      ],
    );
  }

  /// 묶음의 직계 자식 가운데 이름이 [tag] 인 것 — 그 사이의 빈 글자는 버린다.
  List<ElementNode> _named(ElementNode node, String tag) => [
    for (final child in node.children ?? const <Node>[])
      if (child is ElementNode && child.tag == tag) child,
  ];
}

/// 본문의 표를 옆으로 스크롤하는 상자로 감싼다.
///
/// 표 자신을 스크롤 상자로 만들면(`display: block`) 표가 본문 폭을 채우지
/// 않고 내용만큼 줄어든다 — 머리줄의 선이 본문 중간에서 끊긴다. 상자를
/// 하나 두면 표는 폭을 채우고, 넓은 표만 그 상자 안에서 스크롤한다.
///
/// ## 머리줄이 빈 표는 이름 · 값 표다
///
/// 마크다운의 표는 머리줄이 있어야 표가 된다. 그래서 이름과 값을 나란히 적는
/// 표(라이브러리 정보 · 커밋 고정 같은 것)는 머리줄을 비워 쓴다:
///
/// ```md
/// | | |
/// |---|---|
/// | 식별자 | coui-component-library |
/// ```
///
/// 빈 머리줄은 읽을 것이 없는 줄이라 보조 기술에 내지 않고 걷어 내며, 표는
/// `docs-table--plain` 으로 이름 · 값 표의 모양을 받는다.
class DocsTableExtension implements PageExtension {
  /// 표 감싸기 확장을 만든다.
  const DocsTableExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async => [
    for (final node in nodes)
      if (node is ElementNode && node.tag == 'table')
        if (_withoutEmptyHead(node) case final plain?)
          ElementNode('div', const {'class': 'docs-table docs-table--plain'}, [plain])
        else
          ElementNode('div', const {'class': 'docs-table'}, [node])
      else
        node,
  ];

  /// 머리줄의 칸이 모두 비었으면 머리줄을 뺀 표, 아니면 `null`.
  static ElementNode? _withoutEmptyHead(ElementNode table) {
    final children = table.children ?? const <Node>[];
    final head = children.whereType<ElementNode>().where((child) => child.tag == 'thead').firstOrNull;
    if (head == null || head.innerText.trim().isNotEmpty) return null;
    return ElementNode(table.tag, table.attributes, [
      for (final child in children)
        if (!identical(child, head)) child,
    ]);
  }
}
