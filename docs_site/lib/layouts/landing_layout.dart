/// 랜딩 전용 레이아웃 — 사이드바도 "On this page" 도 없는 전체 폭.
///
/// `DocsLayout` 을 고치지 않고 **두 번째 레이아웃**으로 등록하는 이유는
/// jaspr_content 가 페이지마다 레이아웃을 고르기 때문이다:
///
/// ```dart
/// // jaspr_content/lib/src/page.dart
/// final pageLayout = switch (data.page['layout']) {
///   final String layoutName =>
///       config.layouts.where((l) => l.name.matchAsPrefix(layoutName) != null).firstOrNull,
///   _ => config.layouts.firstOrNull,
/// };
/// ```
///
/// `layout:` 키가 없는 페이지는 **첫 번째** 레이아웃을 받는다. 그래서
/// `layouts: [DocsLayout(...), LandingLayout(...)]` 순서를 지키는 한
/// 나머지 150 여 페이지는 지금과 같은 것을 계속 받고, 랜딩만
/// frontmatter 한 줄(`layout: landing`)로 갈라진다.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';

import '../components/site_drawer.dart';
import '../components/site_header.dart';
import '../components/site_landing_styles.dart';
import 'site_chrome.dart';

/// 스크롤 등장을 스크립트가 맡았다는 표시 — 문서 요소의 속성.
///
/// 랜딩 스타일시트는 이 속성 아래에서만 등장 대상을 숨긴다.
const String kSiteMotionAttribute = 'data-site-motion';

/// 첫 페인트 전에 [kSiteMotionAttribute] 를 붙이는 스크립트.
///
/// `<head>` 에 인라인으로 있어야 한다. 본문이 그려진 뒤에 붙이면 타일이
/// 보였다가 사라졌다가 다시 들어온다.
///
/// 속성은 등장을 실제로 맡을 수 있을 때만 붙고(`IntersectionObserver`),
/// 랜딩 스크립트가 끝내 자리를 잡지 못하면 `load` 에서 다시 뗀다 — 그
/// 스크립트가 막히거나 실패한 문서가 숨겨진 타일을 그대로 두지 않게.
const String kSiteMotionGate =
    '(function(){var d=document.documentElement;'
    'if(!("IntersectionObserver" in window))return;'
    'd.setAttribute("$kSiteMotionAttribute","");'
    'addEventListener("load",function(){'
    'if(!window.__siteLanding)d.removeAttribute("$kSiteMotionAttribute")'
    '})})()';

/// 히어로와 랜딩 본문을 담는 전체 폭 레이아웃.
class LandingLayout extends PageLayoutBase {
  /// 랜딩 레이아웃을 만든다.
  const LandingLayout({this.footer});

  /// 콘텐츠 아래에 놓이는 푸터.
  final Component? footer;

  @override
  String get name => 'landing';

  @override
  Iterable<Component> buildHead(Page page) sync* {
    yield* super.buildHead(page);
    yield Style(styles: _styles);
    // 랜딩의 규칙은 랜딩에서만 나간다 — 문서 150 여 페이지가 쓰지 않는
    // 시트를 함께 받지 않는다.
    yield Component.element(tag: 'style', children: [RawText(siteLandingCss)]);
    yield Component.element(tag: 'script', children: [RawText(kSiteMotionGate)]);
    yield script(src: '/docs-landing.js', attributes: const {'defer': ''});
  }

  @override
  Component buildBody(Page page, Component child) {
    // 헤더와 서랍은 문서 레이아웃이 그리는 것과 **같은 컴포넌트**다 —
    // 복사하지 않는 것이 요점이다. 두 벌 저작하면 둘이 갈리고, 그 차이는
    // "랜딩에서만 메뉴가 하나 없다" 로 나타난다. 랜딩은 어느 탭에도 속하지
    // 않으므로 경로를 넘기지 않는다: 지금 탭이 없고, 서랍은 탭 목록만 담는다.
    //
    // 앱 루트는 문서의 본문 안에 놓인다 — 문서 위에 놓으면 문서가 둘이 된다
    // (`site_chrome.dart`).
    return siteAppRoot(
      child: div(classes: 'docs landing', [
        // 문서 레이아웃과 같은 준비물 — 헤더가 같은 것이므로 그 시트와
        // 스크립트도 같아야 한다.
        const SiteChromeHead(),
        a(href: '#main-content', classes: 'docs-skip-link', [Component.text('본문으로 건너뛰기')]),
        const SiteHeader(),
        const SiteDrawer(),
        main_(id: 'main-content', classes: 'landing-main', attributes: const {'tabindex': '-1'}, [child]),
        if (footer case final footer?) div(classes: 'landing-footer', [footer]),
      ]),
    );
  }

  /// 랜딩 뼈대.
  ///
  /// 폭은 여기서 좁히지 않는다. 랜딩의 구획은 면이 화면 끝까지 가는
  /// 것(푸터)과 읽히는 폭 안에 있는 것(벤토 · 카드)이 섞여 있어서, 각
  /// 구획이 자기 여백을 정한다(`site_landing_styles.dart` 의
  /// `--site-gutter`). 레이아웃이 한 폭으로 묶으면 끝까지 가야 하는
  /// 구획이 음수 마진으로 빠져나가야 한다.
  static List<StyleRule> get _styles => [
    css('.landing .landing-main').styles(width: 100.percent),
    // 푸터의 면과 윗선 — 면의 색이 밝기마다 다른 토큰을 읽어서 킷
    // `Footer` 의 배경 슬롯이 아니라 이 상자가 칠한다.
    css('.landing .landing-footer').styles(
      width: 100.percent,
      raw: {
        'border-top': 'var(--coui-stroke-width-1) solid rgb(var(--site-line))',
        'background-color': 'rgb(var(--site-tile))',
      },
    ),
  ];
}
