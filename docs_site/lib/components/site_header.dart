/// 사이트 헤더 — 로고, 탭 다섯, 도구.
///
/// ## 탭은 구조에서 온다
///
/// 탭의 이름과 목적지는 여기 적지 않는다. `kDocsNavTabs` 를 그대로 편다 —
/// 탭마다 다른 사이드바, 이전 · 다음 페이저, 네이티브 문서 앱의 사이드바가
/// 같은 목록을 읽으므로, 헤더가 사본을 들면 탭 하나를 옮긴 날 헤더만
/// 옛 자리를 가리킨다.
///
/// ## 탭은 링크다
///
/// 탭은 페이지를 바꾸는 링크이지 한 화면 안의 패널을 고르는 `tablist` 가
/// 아니다. 그래서 랜드마크는 `<nav>` 이고 항목은 `<a href>` 다 — 서버가
/// 그린 그대로 동작하고, 스크립트가 늦거나 없어도 섹션 이동이 살아 있다.
/// 지금 탭은 `aria-current` 로 말한다.
///
/// ## 지금 탭의 알약은 탭과 따로 있다
///
/// 알약(`.site-tab-pill`)은 탭 뒤에 놓인 별도의 상자다. 탭 자신의 채움으로
/// 그리면 페이지를 옮길 때 한 탭에서 꺼지고 다른 탭에서 켜질 뿐이지만,
/// 상자가 따로 있으면 브라우저가 두 문서 사이에서 그 상자를 이어 그릴 수
/// 있다 — 알약이 탭에서 탭으로 미끄러진다(`docs-shell.css` 의 페이지 전환).
library;

import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/shared/docs_navigation.dart';

import 'docs_search.dart';
import 'site_theme_toggle.dart';
import 'surface_style_switcher.dart';
import 'version_switcher.dart';

/// 헤더 내비게이션 랜드마크의 이름.
///
/// 한 페이지에 내비게이션 랜드마크가 여럿이면(헤더 · 사이드바 · 푸터) 같은
/// 이름이 반복돼 리더의 랜드마크 목록에서 서로를 가릴 수 없다 — 헤더의
/// 것은 '주요' 다. 테스트가 같은 상수를 읽는다.
const String kSiteNavLabel = '주요';

/// 좁은 폭에서 열리는 메뉴 서랍의 id — 헤더의 메뉴 버튼이 이 id 를 연다.
const String kSiteDrawerId = 'site-drawer';

/// cocode 표지 — 로고 이름 앞의 마크.
///
/// `.site-mark` 는 Figma에서 내보낸 SVG를 마스크로 쓰고 테마 색으로 칠한다.
///
/// 장식이다 — 이름은 옆의 글자가 말하므로 보조 기술에는 내지 않는다.
Component siteMark() => span(
  classes: 'site-mark',
  attributes: const {'aria-hidden': 'true'},
  const [],
);

/// 헤더와 모바일 서랍에서 사용하는 CoUI 홈 링크.
Component siteBrand() => a(
  href: '/',
  classes: 'site-brand site-box-link',
  attributes: const {'aria-label': 'CoUI 홈'},
  [siteMark(), Text('CoUI').titleMedium.semiBold.onSurface],
);

/// 사이트 헤더.
class SiteHeader extends StatelessComponent {
  /// 헤더를 만든다.
  const SiteHeader({this.currentPath, super.key});

  /// 지금 보고 있는 문서의 경로. 랜딩처럼 어느 탭에도 속하지 않으면 `null`.
  final String? currentPath;

  @override
  Component build(BuildContext context) {
    final path = currentPath;
    final currentTab = path == null ? null : docsNavTabFor(path);

    return header(classes: 'site-gnb', [
      div(classes: 'site-gnb-inner', [
        // 좁은 폭에서만 보인다. 서랍은 `popover` 라 이 버튼의
        // `popovertarget` 만으로 열린다 — 스크립트가 없어도 메뉴가 닿는다.
        Button(
          variant: CoreButtonVariant.ghost,
          size: CoreComponentSize.sm,
          shape: CoreButtonShape.square,
          enabled: true,
          classes: 'site-menu-button',
          attributes: const {
            'popovertarget': kSiteDrawerId,
            'aria-controls': kSiteDrawerId,
            'aria-label': '메뉴 열기',
          },
          child: const Icon(LucideIcons.menu),
        ),
        siteBrand(),
        nav(
          classes: 'site-tabs',
          attributes: const {'aria-label': kSiteNavLabel},
          [
            ul([
              for (final tab in kDocsNavTabs) _tab(tab, current: tab.id == currentTab?.id, path: path),
            ]),
          ],
        ),
        div(classes: 'site-tools', [
          const DocsSearch(),
          const VersionSwitcher(),
          const SurfaceStyleSwitcher(),
          const SiteThemeToggle(),
        ]),
      ]),
    ]);
  }

  /// 탭 하나 — 지금 탭이면 뒤에 알약이 놓인다.
  Component _tab(DocsNavTab tab, {required bool current, required String? path}) {
    return li(
      classes: 'site-tab',
      attributes: {if (current) 'data-current': ''},
      [
        if (current) span(classes: 'site-tab-pill', attributes: const {'aria-hidden': 'true'}, []),
        Button(
          href: tab.path,
          variant: CoreButtonVariant.ghost,
          size: CoreComponentSize.sm,
          buttonStyle: current ? _currentTabStyle : _tabStyle,
          attributes: {
            // 탭이 가리키는 그 페이지면 `page`, 탭 안의 다른 페이지면 `true`.
            if (current) 'aria-current': tab.path == path ? 'page' : 'true',
          },
          child: Text(tab.label),
        ),
      ],
    );
  }

  /// 쉬는 탭 — 한 단 물러난 글자색, 다가가면 본문색.
  static const CoreButtonStyle _tabStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
    hoverForegroundColor: CoreColor.token(CoreColors.onSurface),
    height: CoreSize.size36,
    labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
  );

  /// 지금 탭 — 본문색. 면은 뒤의 알약이 그린다.
  static const CoreButtonStyle _currentTabStyle = CoreButtonStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurface),
    height: CoreSize.size36,
    labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
  );
}
