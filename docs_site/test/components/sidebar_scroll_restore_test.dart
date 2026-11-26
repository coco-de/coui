@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_site/layouts/manual_layout.dart';
import 'package:docs_site/layouts/sidebar_scroll_restore.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_test/server_test.dart';

/// 사이드바 스크롤 복원이 **어디서, 어떤 순서로** 도는지 본다.
///
/// 복원이 `<head>` 의 `DOMContentLoaded` 에 있던 때는 `defer` 스크립트가 느린 날
/// 사이드바가 맨 위로 먼저 그려졌고, 그 틈에 링크를 누르면 저장이 아직 복원 안 된
/// `0` 으로 정상 저장값을 덮었다. 이 동작은 마크업의 위치와 스크립트의 순서에서
/// 나오므로 둘을 고정한다 — 어느 쪽이 바뀌어도 페이지는 **에러 없이** 렌더되고, 느린
/// 로드에서만 사이드바가 맨 위로 돌아간다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  final page = Page(
    path: 'components/button.md',
    url: '/components/button',
    content: '',
    initialData: {
      'page': {'title': 'Button'},
    },
    config: const PageConfig(),
    loader: MemoryLoader(pages: []),
  );

  const layout = ManualLayout();

  /// 레이아웃의 본문 — 앱 루트까지 레이아웃이 놓는다.
  Component body() => layout.buildBody(page, Component.text('본문'));

  group('사이드바 스크롤 복원 위치', () {
    testServer('스크립트가 사이드바 요소 바로 뒤, 본문 앞에 있다', (tester) async {
      tester.pumpComponent(body());
      final response = await tester.request('/');

      final container = response.document!.querySelector(kSidebarScrollSelector)!;
      final next = container.nextElementSibling;
      expect(next?.localName, 'script', reason: '사이드바가 파싱된 직후에 복원해야 첫 페인트 전에 끝난다');
      expect(next!.text, contains(kSidebarScrollKey));
      expect(next.nextElementSibling?.localName, 'main');
    });

    testServer('스크립트는 한 번만 나간다', (tester) async {
      tester.pumpComponent(body());
      final response = await tester.request('/');

      final scripts = response.document!.querySelectorAll('script').where((el) => el.text.contains(kSidebarScrollKey));
      expect(scripts, hasLength(1));
    });
  });

  group('사이드바 스크롤 스크립트', () {
    test('레이아웃이 그리는 사이드바를 집는다', () {
      expect(kSidebarScrollScript, contains('querySelector("$kSidebarScrollSelector")'));
    });

    test('위치는 탭마다 따로 기억한다', () {
      // 탭이 다르면 사이드바의 목록이 다르다 — 한 키에 담으면 다른 탭에서
      // 내려 둔 위치가 엉뚱한 줄을 맨 위에 올린다.
      expect(kSidebarScrollScript, contains('"data-docs-tab"'));
      expect(kSidebarScrollScript, contains('K="$kSidebarScrollKey:"+'));
    });

    test('로드 완료를 기다리지 않는다', () {
      // `DOMContentLoaded` 는 defer 스크립트가 끝나야 오고, 그전에 첫 페인트가 맨 위로 나간다.
      expect(kSidebarScrollScript, isNot(contains('DOMContentLoaded')));
      expect(kSidebarScrollScript, isNot(contains('readyState')));
    });

    test('복원이 저장 리스너보다 먼저다', () {
      // 리스너를 먼저 달면 복원 전 `pagehide` 가 `0` 을 저장해 정상 저장값을 덮는다.
      final restore = kSidebarScrollScript.indexOf('e.scrollTop=');
      expect(restore, isNonNegative);
      for (final listener in ['"scroll"', '"pagehide"', '"beforeunload"']) {
        final at = kSidebarScrollScript.indexOf(listener);
        expect(at, greaterThan(restore), reason: '$listener 리스너는 복원 뒤에 달려야 한다');
      }
    });

    test('저장소 접근은 전부 try 안이다', () {
      // 저장소가 막힌 환경에서 접근이 던지면 스크립트 전체가 죽는다.
      for (final access in ['sessionStorage.getItem', 'sessionStorage.setItem']) {
        final at = kSidebarScrollScript.indexOf(access);
        expect(at, isNonNegative);
        expect(kSidebarScrollScript.substring(0, at), contains('try{'));
      }
      expect(RegExp('try\\{').allMatches(kSidebarScrollScript), hasLength(2));
    });
  });

  group('사이트 head', () {
    test('복원 스크립트의 두 번째 사본이 없다', () {
      // 같은 키를 두 스크립트가 쓰면 head 쪽(요소가 없는 시점)이 아무 일도 못 하면서도
      // 리스너 순서를 흐린다. 사본은 `ManualLayout` 안의 하나뿐이다.
      final source = File('lib/main.server.dart').readAsStringSync();
      expect(source, isNot(contains(kSidebarScrollKey)));
      expect(source, isNot(contains('sessionStorage')));
    });
  });
}
