import 'dart:io';

import 'package:test/test.dart';

/// 헤더 · 사이드바 · 페이저가 사이트 구조 하나에서 파생되는지, 그리고 랜딩
/// 레이아웃이 기존 페이지를 가져가지 않는지 고정한다.
///
/// 소스 텍스트를 읽는다 — 옆의 사이드바 파생 테스트와 같은 이유다:
/// 두 패키지를 로드하지 않으므로 `dart test` 가 도는 곳이면 어디서든
/// 돈다. 렌더된 결과는 `site_header_render_test.dart` 가 본다.
void main() {
  const serverSource = 'lib/main.server.dart';

  /// 구조를 읽어 내비게이션을 그리는 파일들.
  const navigationSources = [
    'lib/components/site_header.dart',
    'lib/components/site_drawer.dart',
    'lib/components/docs_pager.dart',
  ];

  group('내비게이션은 구조 하나에서 파생된다', () {
    for (final path in navigationSources) {
      test('$path 가 구조를 읽는다', () {
        final source = File(path).readAsStringSync();

        expect(source, contains('docs_navigation.dart'));
      });

      test('$path 가 문서 경로를 손으로 적지 않는다', () {
        final source = File(path).readAsStringSync();

        // 경로 리터럴은 손으로 관리하는 사본이 취하는 모양이다. 구조에서
        // 파생하면 `page.path` · `tab.path` 가 나오지 리터럴은 나오지 않는다.
        for (final head in const ["'/guides/", "'/components/", "'/tokens/", "'/blocks"]) {
          expect(source, isNot(contains(head)), reason: '$head… 리터럴은 처음부터 다시 시작하는 두 번째 목록이다');
        }
      });
    }

    test('헤더와 서랍이 탭을 구조에서 편다', () {
      for (final path in const ['lib/components/site_header.dart', 'lib/components/site_drawer.dart']) {
        expect(File(path).readAsStringSync(), contains('kDocsNavTabs'), reason: path);
      }
    });

    test('서버 엔트리포인트는 링크 목록을 넘기지 않는다', () {
      final source = File(serverSource).readAsStringSync();

      // 레이아웃이 구조에서 직접 그린다 — 엔트리포인트가 사이드바의 묶음을
      // 조립하던 자리에 두 번째 목록이 생기지 않는다.
      expect(source, isNot(contains('SidebarGroup(')));
      expect(source, isNot(contains('SidebarLink(')));
      expect(source, isNot(contains("'/guides/")));
    });
  });

  group('랜딩 레이아웃은 기존 페이지를 가져가지 않는다', () {
    test('두 레이아웃이 등록돼 있다', () {
      final source = File(serverSource).readAsStringSync();

      expect(source, contains('ManualLayout('));
      expect(source, contains('LandingLayout('));
    });

    test('ManualLayout 이 먼저다', () {
      final source = File(serverSource).readAsStringSync();

      final docsAt = source.indexOf('ManualLayout(');
      final landingAt = source.indexOf('LandingLayout(');

      expect(docsAt, greaterThan(-1));
      expect(landingAt, greaterThan(-1));

      // jaspr_content 는 `layout:` 키가 없는 페이지에 **첫 번째**
      // 레이아웃을 준다(`page.dart` 의 `config.layouts.firstOrNull`).
      // 순서가 뒤집히면 150 여 문서 페이지가 한꺼번에 사이드바를
      // 잃는다 — 그 회귀는 홈만 보고 있으면 안 보인다.
      expect(
        docsAt,
        lessThan(landingAt),
        reason:
            'layout: 키가 없는 페이지는 첫 번째 레이아웃을 받는다 — '
            'ManualLayout 이 뒤로 가면 전 페이지가 사이드바를 잃는다',
      );
    });

    test('두 레이아웃이 같은 헤더 · 서랍 · 머리 준비물을 그린다', () {
      // 헤더를 두 벌 저작하면 둘이 갈리고, 그 차이는 "랜딩에서만 메뉴가
      // 하나 없다" 로 나타난다. 두 레이아웃이 같은 컴포넌트를 부른다.
      for (final path in const ['lib/layouts/manual_layout.dart', 'lib/layouts/landing_layout.dart']) {
        final source = File(path).readAsStringSync();

        expect(source, contains('SiteChromeHead()'), reason: path);
        expect(source, contains('SiteHeader('), reason: path);
        expect(source, contains('SiteDrawer('), reason: path);
      }
    });

    test('머리 준비물은 한 컴포넌트가 문서의 head 에 붙인다', () {
      // 두 레이아웃이 같은 컴포넌트 하나를 놓는다 — 레이아웃마다 따로 적으면
      // 한쪽에서만 스크립트가 빠진다. `Document.head` 는 트리의 어디에
      // 놓이든 문서의 `<head>` 에 붙는다.
      final chrome = File('lib/layouts/site_chrome.dart').readAsStringSync();

      expect(chrome, contains('Document.head(children:'));
      expect(chrome, contains('docsSharedHead()'));
      for (final path in const ['lib/layouts/manual_layout.dart', 'lib/layouts/landing_layout.dart']) {
        expect(File(path).readAsStringSync(), isNot(contains('docsSharedHead')), reason: path);
      }
    });
  });
}
