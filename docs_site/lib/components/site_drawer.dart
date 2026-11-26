/// 사이드바이자 좁은 폭의 메뉴 서랍 — 한 요소가 두 역할을 한다.
///
/// 넓은 폭에서는 본문 옆에 놓인 사이드바이고, 좁은 폭에서는 헤더의 메뉴
/// 버튼이 여는 서랍이다. 같은 링크 목록을 두 벌 그리지 않으려고 한 요소로
/// 둔다 — 컴포넌트 탭의 사이드바는 링크가 백 몇십 개다.
///
/// ## 왜 `popover` 인가
///
/// 서랍은 스크립트 없이 열려야 한다. 좁은 폭에서는 탭이 헤더에서 빠지므로,
/// 서랍이 안 열리면 다른 섹션으로 갈 길이 화면에서 사라진다. `popover` 는
/// 버튼의 `popovertarget` 만으로 열리고 닫히며, 바깥을 누르거나 Esc 를
/// 누르면 닫히고, 열린 동안 맨 위 층에 그려진다 — 전부 브라우저가 한다.
///
/// 넓은 폭에서는 스타일시트가 이 요소를 평범한 상자로 되돌린다
/// (`docs-shell.css`). 그때 `popover` 속성은 아무 일도 하지 않는다.
///
/// ## 무엇이 담기나
///
/// - 서랍 머리와 탭 목록 — 좁은 폭에서만 보인다. 넓은 폭에서는 헤더가 같은
///   것을 이미 갖고 있다.
/// - 지금 탭의 그룹과 페이지 — 문서 페이지에서만. 랜딩에는 탭이 없으므로
///   서랍은 탭 목록만 담는다.
library;

import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/shared/component_source_links.dart';
import 'package:docs_core/shared/docs_navigation.dart';

import 'component_catalog_design.dart';
import 'site_header.dart';

/// 서랍 안 탭 목록 랜드마크의 이름.
///
/// 헤더의 탭과 같은 내비게이션이라 같은 이름을 쓴다 — 두 벌이 동시에
/// 보이는 폭은 없다(스타일시트가 한쪽을 감춘다).
const String kSiteDrawerTabsLabel = kSiteNavLabel;

/// 사이드바이자 메뉴 서랍.
class SiteDrawer extends StatelessComponent {
  /// 서랍을 만든다.
  const SiteDrawer({this.currentPath, super.key});

  /// 지금 보고 있는 문서의 경로. 랜딩이면 `null` — 탭 목록만 담는다.
  final String? currentPath;

  @override
  Component build(BuildContext context) {
    final path = currentPath;
    final tab = path == null ? null : docsNavTabFor(path);

    return aside(
      id: kSiteDrawerId,
      classes: tab == null ? 'site-drawer' : 'site-drawer docs-sidebar',
      attributes: const {'popover': '', 'aria-label': '문서 메뉴'},
      [
        div(classes: 'site-drawer-head', [
          siteBrand(),
          Button(
            variant: CoreButtonVariant.ghost,
            size: CoreComponentSize.sm,
            shape: CoreButtonShape.square,
            enabled: true,
            attributes: const {
              'popovertarget': kSiteDrawerId,
              'popovertargetaction': 'hide',
              'aria-label': '메뉴 닫기',
            },
            child: const Icon(LucideIcons.x),
          ),
        ]),
        nav(
          classes: 'site-drawer-tabs',
          attributes: const {'aria-label': kSiteDrawerTabsLabel},
          [
            ul([
              for (final each in kDocsNavTabs)
                li([
                  a(
                    href: each.path,
                    classes: 'site-drawer-tab site-box-link',
                    attributes: {if (each.id == tab?.id) 'aria-current': each.path == path ? 'page' : 'true'},
                    [
                      Text(each.label).labelXl.semiBold.onSurface,
                      Text(each.summary).bodySmall.onSurfaceVariant,
                    ],
                  ),
                ]),
            ]),
          ],
        ),
        if (tab != null && path != null)
          nav(
            classes: 'docs-nav',
            attributes: {'aria-label': '${tab.label} 문서'},
            tab.id == 'components'
                ? _componentGroups(path)
                : [for (final (index, group) in tab.groups.indexed) _group(tab, index, group, path)],
          ),
      ],
    );
  }

  List<Component> _componentGroups(String path) {
    final pages = {
      for (final page in docsNavTabFor(path).pages) docsComponentSlugFromRoutePath(page.path): page,
    };
    DocsNavPage lookup(String slug) => pages[slug]!;

    return [
      ul(classes: 'docs-nav-overview', [
        _item(kDocsComponentsOverviewPage, current: path == kDocsComponentsOverviewPage.path),
      ]),
      for (final group in catalogGroups)
        if (group.id != 'icon')
          div(classes: 'docs-nav-group', [
            h2(id: 'docs-nav-components-${group.id}', classes: 'docs-nav-title', [
              Text(group.title).labelSmall.medium,
            ]),
            ul(
              attributes: {'aria-labelledby': 'docs-nav-components-${group.id}'},
              [
                for (final card in group.cards)
                  if (card.children.isEmpty)
                    _item(lookup(card.item.slug), current: path == lookup(card.item.slug).path)
                  else
                    _family(lookup(card.item.slug), [for (final item in card.children) lookup(item.slug)], path),
                if (group.id == 'infra')
                  for (final subgroup in catalogUtilities)
                    _family(
                      null,
                      [for (final row in subgroup.items) lookup(row.item.slug)],
                      path,
                      title: subgroup.title,
                    ),
              ],
            ),
          ]),
    ];
  }

  Component _family(DocsNavPage? parent, List<DocsNavPage> children, String path, {String? title}) {
    final active = parent?.path == path;
    return li(classes: 'docs-nav-family', [
      details(
        attributes: {if (active || children.any((child) => child.path == path)) 'open': ''},
        [
          summary([
            if (parent case final page?)
              div(classes: 'docs-nav-family-root', [_itemContent(page, active)])
            else
              span(classes: 'docs-nav-family-title', [Text(title!).bodyMedium.onSurfaceVariant]),
            const Icon(LucideIcons.chevronRight, iconStyle: CoreIconStyle(size: CoreIconSize.size14)),
          ]),
          ul([for (final child in children) _item(child, current: child.path == path)]),
        ],
      ),
    ]);
  }

  /// 그룹 하나 — 제목과 그 아래의 링크 목록.
  Component _group(DocsNavTab tab, int index, DocsNavGroup group, String path) {
    final titleId = 'docs-nav-${tab.id}-$index';

    return div(classes: 'docs-nav-group', [
      h2(id: titleId, classes: 'docs-nav-title', [Text(group.title).labelSmall.medium]),
      ul(
        attributes: {'aria-labelledby': titleId},
        [for (final page in group.pages) _item(page, current: page.path == path)],
      ),
    ]);
  }

  /// 링크 한 줄. 지금 페이지면 `aria-current` 를 달고, 표지(`.docs-nav-mark`)가
  /// 그 옆에 놓인다 — 표지는 줄과 따로 있는 상자라 페이지를 옮길 때
  /// 브라우저가 이어 그릴 수 있다.
  Component _item(DocsNavPage page, {required bool current}) {
    return li(
      classes: 'docs-nav-item',
      attributes: {if (current) 'data-current': ''},
      [_itemContent(page, current)],
    );
  }

  Component _itemContent(DocsNavPage page, bool current) => Component.fragment([
    if (current) span(classes: 'docs-nav-mark', attributes: const {'aria-hidden': 'true'}, []),
    Link(
      href: page.path,
      classes: 'docs-nav-link',
      linkStyle: current ? _currentLinkStyle : _linkStyle,
      attributes: {if (current) 'aria-current': 'page'},
      child: Component.fragment([
        Text(page.label),
        if (page.deprecated)
          Badge(
            variant: CoreBadgeVariant.outlined,
            child: Text('Deprecated'),
          ),
      ]),
    ),
  ]);

  /// 쉬는 줄 — 한 단 물러난 글자색.
  static const CoreLinkStyle _linkStyle = CoreLinkStyle(
    color: CoreColor.token(CoreColors.onSurfaceVariant),
    labelStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
    interactionTextDecoration: CoreTextDecoration.none,
  );

  /// 지금 페이지 — 본문색, 라벨 굵기(Figma `Doc/Nav Item` 의 Active).
  static const CoreLinkStyle _currentLinkStyle = CoreLinkStyle(
    color: CoreColor.token(CoreColors.onSurface),
    labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
    interactionTextDecoration: CoreTextDecoration.none,
  );
}
