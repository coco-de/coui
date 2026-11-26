@TestOn('vm')
library;

import 'package:coui_web/coui_web.dart' show CoUIWeb, ThemeData;
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_site/components/component_catalog_design.dart';
import 'package:docs_site/components/docs_pager.dart';
import 'package:docs_site/components/site_drawer.dart';
import 'package:docs_site/components/site_header.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// 헤더 · 사이드바 · 페이저가 **서버 렌더에서** 실제로 무엇을 내는지 본다.
///
/// 옆의 파생 테스트는 소스 텍스트를 읽어 "구조를 참조한다" 까지만 말한다.
/// 그것은 참조가 화면에 도달했다는 증거가 아니다. 여기서는 렌더된 HTML 을
/// 읽는다.
///
/// 이 파일이 지키는 것은 하나다 — **이동은 스크립트 없이 된다.** 탭,
/// 사이드바의 줄, 페이저의 카드가 전부 서버가 그린 `<a href>` 이고, 좁은
/// 폭의 서랍은 버튼의 `popovertarget` 만으로 열린다. 클라이언트 번들이
/// 늦거나 없는 환경과 크롤러에게도 이 사이트에는 내비게이션이 있다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  Component app(Component child) => CoUIWeb(theme: ThemeData.coui, child: child);

  group('헤더', () {
    testServer('탭 다섯이 구조의 순서대로, 각자의 첫 페이지를 가리킨다', (tester) async {
      tester.pumpComponent(app(const SiteHeader(currentPath: '/principles')));
      final document = (await tester.request('/')).document!;

      final tabs = document.querySelectorAll('nav.site-tabs li.site-tab > a');
      // 보이는 글자만 — 킷의 버튼이 자기 안에 싣는 `<style>` 의 내용은 뺀다.
      expect(
        tabs.map(
          (tab) => tab.children.where((child) => child.localName != 'style').map((child) => child.text).join().trim(),
        ),
        [for (final tab in kDocsNavTabs) tab.label],
      );
      expect(tabs.map((tab) => tab.attributes['href']), [for (final tab in kDocsNavTabs) tab.path]);
      expect(document.querySelector('nav.site-tabs')!.attributes['aria-label'], kSiteNavLabel);
    });

    testServer('지금 탭만 표시되고, 알약은 그 탭에 하나다', (tester) async {
      tester.pumpComponent(app(const SiteHeader(currentPath: '/guides/colors')));
      final document = (await tester.request('/')).document!;

      final current = document.querySelectorAll('li.site-tab[data-current]');
      expect(current, hasLength(1));
      expect(current.single.querySelector('a')!.attributes['href'], kDocsNavTabs[1].path);
      expect(document.querySelectorAll('.site-tab-pill'), hasLength(1));
      expect(current.single.querySelector('.site-tab-pill'), isNotNull);

      // 탭이 가리키는 그 페이지가 아니라 탭 안의 다른 페이지다.
      expect(current.single.querySelector('a')!.attributes['aria-current'], 'true');
      expect(document.querySelectorAll('nav.site-tabs a[aria-current]'), hasLength(1));
    });

    testServer('탭이 가리키는 바로 그 페이지에서는 page 다', (tester) async {
      tester.pumpComponent(app(SiteHeader(currentPath: kDocsNavTabs[1].path)));
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('li.site-tab[data-current] > a')!.attributes['aria-current'], 'page');
    });

    testServer('랜딩에는 지금 탭이 없다', (tester) async {
      tester.pumpComponent(app(const SiteHeader()));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('li.site-tab'), hasLength(kDocsNavTabs.length));
      expect(document.querySelectorAll('[data-current]'), isEmpty);
      expect(document.querySelectorAll('.site-tab-pill'), isEmpty);
      expect(document.querySelectorAll('nav.site-tabs [aria-current]'), isEmpty);
    });

    testServer('메뉴 버튼이 서랍을 스크립트 없이 연다', (tester) async {
      tester.pumpComponent(
        app(const Component.fragment([SiteHeader(currentPath: '/overview'), SiteDrawer(currentPath: '/overview')])),
      );
      final document = (await tester.request('/')).document!;

      final button = document.querySelector('.site-menu-button')!;
      expect(button.localName, 'button');
      expect(button.attributes['popovertarget'], kSiteDrawerId);
      // 핸들러가 없는 버튼은 킷이 끈 채로 그린다 — 꺼진 버튼은 서랍을 못 연다.
      expect(button.attributes.containsKey('disabled'), isFalse);
      expect(button.attributes['aria-label'], isNotEmpty);

      final drawer = document.querySelector('#$kSiteDrawerId')!;
      expect(drawer.attributes.containsKey('popover'), isTrue);
      expect(drawer.querySelector('[popovertargetaction="hide"]')!.attributes['popovertarget'], kSiteDrawerId);
    });
  });

  group('사이드바 · 서랍', () {
    testServer('지금 탭의 묶음과 페이지만 담는다', (tester) async {
      tester.pumpComponent(app(const SiteDrawer(currentPath: '/guides/theming')));
      final document = (await tester.request('/')).document!;
      final tab = docsNavTabFor('/guides/theming');

      expect(document.querySelectorAll('.docs-nav-title').map((title) => title.text.trim()), [
        for (final group in tab.groups) group.title,
      ]);
      expect(document.querySelectorAll('nav.docs-nav a').map((link) => link.attributes['href']), [
        for (final page in tab.pages) page.path,
      ]);
      // 다른 탭의 페이지는 없다.
      expect(document.querySelector('nav.docs-nav a[href="/tokens/overview"]'), isNull);
    });

    testServer('지금 페이지 하나만 표시된다', (tester) async {
      tester.pumpComponent(app(const SiteDrawer(currentPath: '/guides/theming')));
      final document = (await tester.request('/')).document!;

      final current = document.querySelectorAll('.docs-nav-item[data-current]');
      expect(current, hasLength(1));
      expect(current.single.querySelector('a')!.attributes['aria-current'], 'page');
      expect(current.single.querySelector('a')!.attributes['href'], '/guides/theming');
      expect(document.querySelectorAll('.docs-nav-mark'), hasLength(1));
    });

    testServer('묶음의 이름이 그 목록의 이름이다', (tester) async {
      tester.pumpComponent(app(const SiteDrawer(currentPath: '/overview')));
      final document = (await tester.request('/')).document!;

      for (final list in document.querySelectorAll('nav.docs-nav ul')) {
        final title = document.querySelector('[id="${list.attributes['aria-labelledby']}"]');
        expect(title, isNotNull);
        expect(title!.classes, contains('docs-nav-title'));
      }
    });

    testServer('폐기된 컴포넌트는 줄에서 구분된다', (tester) async {
      final deprecated = kDocsComponentEntries.where((entry) => entry.isDeprecated).toList();
      tester.pumpComponent(app(const SiteDrawer(currentPath: '/components-overview')));
      final document = (await tester.request('/')).document!;

      final marked = document.querySelectorAll('nav.docs-nav a').where((link) => link.text.contains('Deprecated'));
      expect(marked.map((link) => link.attributes['href']).toSet(), {
        for (final entry in deprecated) '/components/${entry.slug}',
      });
    });

    testServer('서랍은 모든 탭으로 가는 길을 갖는다', (tester) async {
      // 좁은 폭에서는 헤더의 탭이 감춰진다 — 서랍이 그 길을 대신한다.
      tester.pumpComponent(app(const SiteDrawer(currentPath: '/overview')));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('.site-drawer-tabs a').map((link) => link.attributes['href']), [
        for (final tab in kDocsNavTabs) tab.path,
      ]);
      expect(document.querySelectorAll('.site-drawer-tabs a[aria-current]'), hasLength(1));
    });

    testServer('랜딩의 서랍은 탭 목록만 담는다', (tester) async {
      tester.pumpComponent(app(const SiteDrawer()));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll('.site-drawer-tabs a'), hasLength(kDocsNavTabs.length));
      expect(document.querySelector('nav.docs-nav'), isNull);
      // 사이드바가 아니므로 넓은 폭에서도 본문 옆에 놓이지 않는다.
      expect(document.querySelector('#$kSiteDrawerId')!.classes, isNot(contains('docs-sidebar')));
    });
  });

  group('페이저', () {
    testServer('앞뒤 페이지가 링크로 나가고 방향을 말한다', (tester) async {
      final location = docsNavLocate('/principles')!;
      tester.pumpComponent(app(DocsPager(location: location)));
      final document = (await tester.request('/')).document!;

      final previous = document.querySelector('a[rel="prev"]')!;
      final next = document.querySelector('a[rel="next"]')!;
      expect(previous.attributes['href'], location.previous!.path);
      expect(previous.text, contains(location.previous!.label));
      expect(next.attributes['href'], location.next!.path);
      expect(next.text, contains(location.next!.label));
      expect(document.querySelector('nav.docs-pager')!.attributes['aria-label'], kDocsPagerLabel);
    });

    testServer('컴포넌트 템플릿의 페이저가 전체 보기와 예제 문서로 연결된다', (tester) async {
      for (final (path, previous, next) in const [
        ('/components/button', '/components-overview', '/components/fab'),
        ('/components/text-field', '/components-overview#form', '/components/select'),
      ]) {
        final location = docsNavLocate(path)!;
        final destinations = componentTemplatePager(location)!;
        tester.pumpComponent(
          app(DocsPager(location: location, previousPage: destinations.previous, nextPage: destinations.next)),
        );
        final document = (await tester.request('/')).document!;
        expect(document.querySelector('a[rel="prev"]')!.attributes['href'], previous);
        expect(document.querySelector('a[rel="next"]')!.attributes['href'], next);
      }
    });

    testServer('첫 페이지에는 다음만 있고, 그 카드가 줄을 채운다', (tester) async {
      tester.pumpComponent(app(DocsPager(location: kDocsNavLocations.first)));
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('a[rel="prev"]'), isNull);
      // 있는 카드만 그린다 — 빈 칸을 두지 않고, 하나뿐인 카드가 줄을 채운다
      // (Figma `Doc/Pager`). 글자는 끝 정렬이라 다음 카드는 오른쪽에서 읽힌다.
      final pager = document.querySelector('nav.docs-pager')!;
      expect(pager.children, hasLength(1));
      final next = pager.children.single;
      expect(next.attributes['rel'], 'next');
      expect(next.classes, contains('docs-pager-card--next'));
      expect(next.querySelector('.site-arrow'), isNull);
      expect(next.querySelector('.docs-pager-label')!.text, isNotEmpty);
      expect(next.querySelector('.docs-pager-title')!.text, isNotEmpty);
    });

    testServer('탭의 끝에서 다음 탭으로 이어진다', (tester) async {
      final last = docsNavLocate(kDocsNavTabs.first.pages.last.path)!;
      tester.pumpComponent(app(DocsPager(location: last)));
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('a[rel="next"]')!.attributes['href'], kDocsNavTabs[1].path);
    });
  });
}
