/// 전체 컴포넌트 갤러리 — 카드마다 **실제 렌더된 프리뷰**.
///
/// 마크다운에서 `<ComponentGrid />` 로 부른다. 랜딩(`/`)과
/// `/components-overview` 가 **같은 것**을 부른다 — 두 라우트, 한 구현.
///
/// 태그 이름을 그대로 둔 것은 의도다. 이 태그는 네이티브 `docs_app` 도
/// 렌더한다(`app/docs_app/lib/src/markdown/tags/reference_tags.dart`,
/// 테스트까지 있다) — 같은 마크다운 파일을 두 표면이 읽으므로 태그는
/// **콘텐츠와 두 렌더러 사이의 계약**이다. Web 쪽 구현을 바꾸려고
/// 계약을 바꾸면 네이티브 앱이 그 자리에서 아무것도 못 그린다.
///
/// ## chrome 을 다시 그리지 않는다
///
/// 카드는 CoUI `Card`, 그리드는 `ResponsiveGrid`, deprecated 표시는
/// `Badge` 다. 이 파일의 이전 구현은 raw `<a>` + 손으로 쓴 CSS 227 줄로
/// 같은 것을 그렸고, 그래서 **다섯 surface 프리셋 중 어느 것으로 바꿔도
/// 따라오지 않았다.**
/// `process/application-limits.md` 가 금지하는 정확한 형태다 —
/// "크롬을 다시 그리지 않는다 … raw 박스로 다시 만들면 그 자리가
/// 테마에서 떨어진다."
///
/// ## 프리뷰는 island 없이 서버에서 그린다
///
/// `kWebPreviewRegistry` 는 `Component Function(BuildContext, String?)`
/// 순수 맵이고 `@client WebPreview` 는 그 맵을 **감싸는 래퍼**일 뿐이다.
/// 그래서 갤러리는 래퍼를 건너뛰고 빌더를 직접 불러 hydration 없는
/// 정적 마크업을 낸다. `/embed/<slug>` 가 같은 맵을 같은 방식으로 이미
/// 쓰고 있다 — 새 경로가 아니라 있는 경로다.
///
/// 이 선택은 측정으로 뒷받침된다 (#4979):
///
/// | | |
/// |---|---|
/// | 144 프리뷰 한 페이지 | 495.9 KiB raw → **35.8 KiB gzip** (7.2%) |
/// | 서버 호출 실패 빌더 | **0 / 144** |
/// | 렌더 순증 | **70ms** |
///
/// 압축비가 7.2% 인 이유는 마크업이 압도적으로 반복되는 Tailwind
/// 클래스 문자열이기 때문이다. 무게를 이유로 전량 SSR 을 포기할 근거가
/// 없어서, lazy hydration 도 대표 세트 큐레이션도 하지 않는다.
///
/// ## 카드 전체가 링크인 방법 — stretched link
///
/// `Card.onTap` 은 클릭 핸들러이지 링크가 아니다. 목적지가 있는 이동은
/// 링크여야 크롤되고, 새 탭으로 열리고, 스크린 리더가 링크로 읽는다.
/// 그렇다고 `Card` 를 통째로 `<a>` 안에 넣을 수도 없다 — 프리뷰 안에
/// 진짜 `<button>` 이 들어 있고, **interactive content 를 `<a>` 안에
/// 두는 것은 유효하지 않은 HTML** 이며 그 버튼이 클릭을 삼킨다.
///
/// 그래서 제목만 `<a>` 로 두고 그 `::after` 가 카드를 덮는다. 프리뷰는
/// `pointer-events: none` 이라 클릭을 가로채지 않는다 — 어차피
/// hydration 이 없어 눌러도 아무 일도 일어나지 않으므로, 눌리지 않는
/// 편이 정직하다.
library;

import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_content/jaspr_content.dart';

import 'component_catalog_design.dart';

/// 카드가 stretched-link 의 기준이 되도록 `position: relative` 를 받는다.
const String kShowcaseCardClass = 'showcase-card';

/// 프리뷰 뷰포트 — 고정 높이 + 클립.
const String kShowcasePreviewClass = 'showcase-preview';

/// 카드를 덮는 stretched link.
const String kShowcaseTitleClass = 'showcase-title';

/// 대표 섹션의 키운 프리뷰 뷰포트.
const String kShowcasePreviewTallClass = 'showcase-preview--tall';

/// 프리뷰 썸네일 높이.
///
/// 컴포넌트마다 실제 높이는 다르다(`preview_constraints.dart` 는 56 부터
/// 600 까지의 tier 를 갖는다). 갤러리는 **격자**이므로 한 값으로 고정하고
/// 넘치는 것은 자른다 — 카드마다 높이가 다르면 그건 격자가 아니라
/// 벽돌쌓기이고, 눈이 그룹을 훑는 일이 어려워진다.
const double _previewViewportHeight = 148;

/// 대표 섹션 프리뷰 높이 — 카드가 적고 크므로 잘림이 더 아깝다.
const double _tallPreviewViewportHeight = 240;

/// 마크다운 `<ComponentShowcase />` 태그 핸들러.
class ComponentGrid extends CustomComponent {
  /// 갤러리 태그 핸들러를 만든다.
  ComponentGrid() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node case ElementNode(tag: 'ComponentGrid')) {
      return const ComponentGridView();
    }
    return null;
  }
}

/// 컴포넌트 한 개를 카드로 — 전체 갤러리와 랜딩의 대표 섹션이 **같은
/// 구현**을 쓴다.
///
/// [tall] 은 프리뷰 뷰포트를 키운다. 랜딩의 대표 섹션은 카드가 크고
/// 수가 적어 잘림이 더 아깝고, 전체 갤러리는 144 개를 훑는 격자라
/// 썸네일 높이가 맞다.
Component showcaseCard(
  BuildContext context,
  DocsComponentEntry item, {
  bool tall = false,
}) {
  final builder = kWebPreviewRegistry[item.slug];

  return Card(
    variant: CoreCardVariant.outlined,
    classes: kShowcaseCardClass,
    attributes: {
      'data-catalog-search': [item.slug, ...item.searchKeywords].join(' ').toLowerCase(),
    },
    media: div(
      classes: tall ? '$kShowcasePreviewClass $kShowcasePreviewTallClass' : kShowcasePreviewClass,
      // Thumbnails must not autofocus or receive keyboard input.
      attributes: const {'inert': '', 'aria-hidden': 'true'},
      [
        // 레지스트리에 없는 컴포넌트는 조용히 빈 칸이 되지 않고
        // 자기 이름을 말한다 — 측정 시점에는 누락이 0 이었고(#4979),
        // 그게 깨지면 화면에서 보여야 한다.
        if (builder != null) builder(context, null) else Text('프리뷰 없음').bodySmall.onSurfaceVariant,
      ],
    ),
    header: div(classes: 'showcase-card-title', [
      // `<h3>` 안의 링크 — 그룹 제목(`<h2>`) 아래 계층이고, 그래서
      // heading 으로 훑을 때 카드가 그룹에 속해 읽힌다. 스타일된
      // `Text` 만으로는 그 계층이 존재하지 않는다.
      h3([
        Link(
          href: '/components/${item.slug}',
          underline: false,
          classes: kShowcaseTitleClass,
          child: Text(item.name).titleSmall.semiBold.onSurface,
        ),
      ]),
      if (item.isDeprecated) Badge(variant: CoreBadgeVariant.outlined, child: Text('Deprecated')),
    ]),
    body: Text(item.description).bodySmall.onSurfaceVariant,
  );
}

/// 갤러리 본체.
///
/// 마크다운 태그 핸들러와 직접 합성(랜딩) 양쪽이 이것을 쓴다 — 두
/// 진입점, 한 구현.
class ComponentGridView extends StatelessComponent {
  /// 갤러리를 만든다.
  const ComponentGridView({super.key});

  @override
  Component build(BuildContext context) {
    final counts = {
      for (final group in catalogGroups) group.id: group.cards.fold(0, (sum, card) => sum + 1 + card.children.length),
    };
    final utilities = catalogUtilities.fold(0, (sum, group) => sum + group.items.length);
    final utilityCount = counts['infra']! + utilities;
    counts['infra'] = utilityCount;
    final total = counts.values.fold(0, (sum, count) => sum + count);
    final summary = '컴포넌트 ${total - utilityCount} · 유틸리티 $utilityCount';

    return div(classes: 'showcase catalog-grid', [
      div(classes: 'catalog-tools not-content', [
        const TextField(
          id: 'catalog-query',
          placeholder: Text('컴포넌트 이름이나 설명으로 찾기'),
          attributes: {'data-catalog-query': '', 'aria-label': '컴포넌트 검색'},
        ),
        div(
          classes: 'catalog-categories',
          attributes: const {'role': 'group', 'aria-label': '컴포넌트 카테고리'},
          [
            _filter('all', '전체', total),
            for (final group in catalogGroups) ...[
              if (group.id == 'infra')
                span(classes: 'catalog-filter-break', attributes: const {'aria-hidden': 'true'}, []),
              _filter(group.id, group.title, counts[group.id]!),
            ],
          ],
        ),
        div(classes: 'catalog-result-bar', [
          p(
            attributes: {'data-catalog-count': summary, 'role': 'status', 'aria-live': 'polite'},
            [Text(summary).bodySmall.onSurfaceVariant],
          ),
          Button(
            enabled: true,
            size: CoreComponentSize.sm,
            variant: CoreButtonVariant.ghost,
            attributes: const {'data-catalog-reset': '', 'hidden': ''},
            child: Text('필터 초기화'),
          ),
        ]),
        p(
          classes: 'catalog-empty',
          attributes: const {'data-catalog-empty': '', 'hidden': ''},
          [Text('일치하는 컴포넌트가 없습니다. 검색어나 카테고리를 바꿔보세요.').bodyMedium.onSurfaceVariant],
        ),
      ]),
      for (final group in catalogGroups) _group(context, group, counts[group.id]!),
    ]);
  }

  Component _filter(String group, String title, int count) => Button(
    enabled: true,
    classes: 'catalog-filter',
    size: CoreComponentSize.sm,
    variant: CoreButtonVariant.outline,
    buttonStyle: const CoreButtonStyle(
      height: CoreSize.size36,
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
    ),
    attributes: {'data-catalog-category': group, 'aria-pressed': '${group == 'all'}'},
    child: span([
      Component.text('$title '),
      span(classes: 'catalog-filter-count', [Component.text('$count')]),
    ]),
  );

  Component _group(BuildContext context, CatalogGroup group, int count) => section(
    classes: 'showcase-group',
    attributes: {'data-catalog-group': group.id},
    [
      div(classes: 'showcase-group-header not-content', [
        h2(id: group.id, [
          Text(group.title).headlineMedium.bold.onSurface,
          Text('$count').labelXl.onSurfaceVariant,
        ]),
        Text(group.description).bodyLarge.onSurfaceVariant,
      ]),
      if (group.cards.isNotEmpty)
        div(classes: 'catalog-cards not-content', [
          for (final card in group.cards) _card(context, card),
        ]),
      if (group.id == 'infra')
        for (final subgroup in catalogUtilities)
          section(
            classes: 'catalog-utilities not-content',
            attributes: const {'data-catalog-utility-group': ''},
            [
              h3([Text('${subgroup.title} ${subgroup.items.length}').labelMedium.onSurfaceVariant]),
              div(classes: 'catalog-utility-list', [
                for (final row in subgroup.items)
                  a(
                    href: '/components/${row.item.slug}',
                    classes: 'catalog-utility site-box-link',
                    attributes: {'data-catalog-search': _search(row.item, row.description)},
                    [Text(row.item.name).labelLarge.onSurface, Text(row.description).bodySmall.onSurfaceVariant],
                  ),
              ]),
            ],
          ),
    ],
  );

  Component _card(BuildContext context, CatalogCard card) {
    final item = card.item;
    final builder = kWebPreviewRegistry[item.slug];
    return article(
      classes: 'showcase-card catalog-card',
      attributes: {'data-catalog-search': _search(item, card.description)},
      [
        div(
          classes: 'showcase-preview catalog-stage catalog-stage--${card.stage}',
          attributes: {'inert': '', 'aria-hidden': 'true', 'data-component': item.slug},
          [
            switch (item.slug) {
              'button' => const _CatalogButtons(),
              'text-field' => const TextField(label: '이메일', placeholder: Text('name@cocode.im')),
              _ => builder?.call(context, null) ?? Text(item.name).bodySmall,
            },
          ],
        ),
        div(classes: 'catalog-card-copy', [
          h3(classes: 'catalog-card-title', [
            a(href: '/components/${item.slug}', classes: kShowcaseTitleClass, [Text(item.name).labelLarge.onSurface]),
            if (item.isDeprecated) Badge(variant: CoreBadgeVariant.outlined, child: Text('Deprecated')),
          ]),
          Text(card.description).bodySmall.onSurfaceVariant,
        ]),
        if (card.children.isNotEmpty)
          ul(classes: 'catalog-members', [
            for (final child in card.children)
              li([
                a(
                  href: '/components/${child.slug}',
                  classes: 'catalog-member site-box-link',
                  attributes: {'data-catalog-member': _search(child, child.description)},
                  [Text(child.name).labelSmall.onSurfaceVariant],
                ),
              ]),
          ]),
      ],
    );
  }

  String _search(DocsComponentEntry item, String description) =>
      [item.name, item.slug, description, item.description, ...item.searchKeywords].join(' ');
}

class _CatalogButtons extends StatelessComponent {
  const _CatalogButtons();

  @override
  Component build(BuildContext context) => div(classes: 'catalog-button-preview', [
    Button(enabled: true, variant: CoreButtonVariant.outline, child: Text('취소')),
    Button(enabled: true, child: Text('저장하기')),
  ]);
}

/// 갤러리 카드의 레이아웃 규칙.
///
/// top-level 인 이유는 **두 페이지가 카드를 쓰기 때문**이다. 뷰의
/// `Document.head` 안에 두면 그 뷰를 그리는 페이지에만 규칙이 나가고,
/// 카드만 빌려 쓰는 랜딩에서는 `Card` 의 `w-fit` 이 그대로 남아 카드마다
/// 폭이 달라진다 — 실제로 그렇게 됐고, 측정으로 찾았다.
///
/// 그래서 사이트의 다른 전역 규칙들과 같은 자리(`main.server.dart` 의
/// head)에서 한 번 나간다.
List<StyleRule> showcaseStyles() => [
  css('.showcase').styles(raw: {'padding-bottom': 'var(--coui-space-48)'}),
  css('.showcase-group').styles(
    raw: {'margin-bottom': 'var(--coui-space-48)'},
  ),
  css('.showcase-group-header').styles(
    raw: {'margin-bottom': 'var(--coui-space-16)'},
  ),
  css('.showcase-group-header h2').styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': 'var(--coui-space-8)',
      'margin': '0 0 var(--coui-space-4)',
      // 문서 본문의 `h2` 는 위쪽 구분선을 갖는다. 갤러리의 그룹
      // 제목은 구분선이 아니라 격자가 구획하므로 그 선을 끈다.
      'border': 'none',
      'padding': '0',
    },
  ),
  // ── stretched link ─────────────────────────────────────────
  //
  // 제목의 `::after` 가 카드를 덮어 카드 전체가 한 링크의 히트
  // 영역이 된다. 카드를 `<a>` 로 감싸지 않는 이유는 위 라이브러리
  // 주석 참조 — 프리뷰 안의 `<button>` 이 유효하지 않은 중첩을
  // 만들고 클릭을 삼킨다.
  //
  // `body` 접두는 특이도용이다 — 아래 `width` 가 `Card` 의 `w-fit` 과
  // 같은 클래스 특이도(0,1,0)라 순서로 결정되고, Tailwind 시트가 이
  // `<style>` 뒤에 주입되면 진다. 이 사이트가 `.header-container` 에
  // 이미 쓰는 방식이다.
  css('body .$kShowcaseCardClass').styles(
    raw: {
      'position': 'relative',
      // `Card` 는 `w-fit` 으로 내용에 맞춰 줄어든다 — 홀로 선 카드에는
      // 맞는 기본값이지만 격자 안에서는 셀을 안 채워 카드마다 폭이
      // 달라진다(측정: 같은 행에서 133 · 266 · 168px). 폭은 chrome 이
      // 아니라 **레이아웃**이므로 소비처가 말하는 것이 맞다
      // (`cross-platform/api.md` 의 passthrough 3 표면 중 layout).
      'width': '100%',
      // 격자의 한 행이 가장 높은 카드에 맞춰 늘어날 때, 짧은 카드도
      // 같이 늘어나 행의 아래선이 맞는다.
      'height': '100%',
    },
  ),
  css('.$kShowcaseTitleClass').styles(raw: {'text-decoration': 'none'}),
  css('.$kShowcaseTitleClass::after').styles(
    raw: {'content': "''", 'position': 'absolute', 'inset': '0'},
  ),
  css('.showcase-card-title').styles(
    raw: {
      'display': 'flex',
      'align-items': 'center',
      'gap': 'var(--coui-space-8)',
      // 배지가 긴 이름 옆에서 줄바꿈되지 않도록.
      'flex-wrap': 'wrap',
    },
  ),
  // ── 프리뷰 뷰포트 ───────────────────────────────────────────
  //
  // 고정 높이 + 클립. `pointer-events: none` 이 stretched link 를
  // 가리지 않게 한다 — 프리뷰는 hydration 이 없어 어차피 반응하지
  // 않으므로, 눌리지 않는 편이 정직하다.
  css('body .$kShowcasePreviewClass').styles(
    raw: {
      'height': '${_previewViewportHeight / kRemDivisor}rem',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'overflow': 'hidden',
      'pointer-events': 'none',
      'padding': 'var(--coui-space-12)',
      // 카드 채움 위에 프리뷰가 뜨도록 — 카드와 같은 톤이면
      // 프리뷰의 경계가 어디인지 알 수 없다.
      'background-color': const CoreColor.token(
        CoreColors.surfaceContainerLow,
      ).toValue(),
      'border-radius': radiusCss(CoreRadius.radius8),
    },
  ),
  css('body .$kShowcasePreviewTallClass').styles(
    raw: {'height': '${_tallPreviewViewportHeight / kRemDivisor}rem'},
  ),
  // 프리뷰 안의 요소가 뷰포트를 가로로 넘치지 않게 — Web flex 의
  // intrinsic min-width 함정 (`web/web-specifics.md`).
  css('body .$kShowcasePreviewClass > *').styles(
    raw: {'min-width': '0', 'max-width': '100%'},
  ),
];
