@TestOn('vm')
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart' show CoUIWeb, ThemeData;
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_site/components/site_footer.dart';
import 'package:docs_site/components/site_hero.dart';
import 'package:docs_site/components/site_landing_data.dart';
import 'package:docs_site/components/site_header.dart';
import 'package:docs_site/components/site_showcase.dart';
import 'package:docs_site/layouts/landing_layout.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// 랜딩(`/`)이 실제로 랜딩인지 본다.
///
/// 세 축이다 — 마크다운이 랜딩 레이아웃을 **고르는가**, 본문이 서버
/// 렌더에 **읽을 수 있는 구조로 나오는가**, 그리고 화면이 말하는 값이
/// **출처와 같은가**.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  const indexPath = '../docs_core/content/index.md';
  const gettingStartedPath = '../docs_core/content/getting-started.md';

  /// 문서 경로가 가리키는 콘텐츠 파일이 있는가.
  ///
  /// `/x/y#z` → `content/x/y.md` 또는 `content/x/y/index.md`.
  bool hasPage(String href) {
    final path = href.split('#').first;
    return File('../docs_core/content$path.md').existsSync() || File('../docs_core/content$path/index.md').existsSync();
  }

  Future<DocumentResponse> renderHero(ServerTester tester) {
    tester.pumpComponent(CoUIWeb(theme: ThemeData.coui, child: const SiteHeroView()));
    return tester.request('/');
  }

  Future<DocumentResponse> renderShowcase(ServerTester tester) {
    tester.pumpComponent(CoUIWeb(theme: ThemeData.coui, child: const SiteShowcaseView()));
    return tester.request('/');
  }

  Future<DocumentResponse> renderFooter(ServerTester tester) {
    tester.pumpComponent(CoUIWeb(theme: ThemeData.coui, child: const SiteFooter()));
    return tester.request('/');
  }

  group('랜딩 마크다운', () {
    test('랜딩 레이아웃을 고른다', () {
      final source = File(indexPath).readAsStringSync();

      // jaspr_content 는 frontmatter 의 `layout:` 으로 레이아웃을
      // 고른다. 이 한 줄이 빠지면 홈이 조용히 사이드바 딸린 문서
      // 페이지로 되돌아간다 — 에러는 나지 않는다.
      expect(source, contains('layout: landing'));
    });

    test('히어로와 랜딩 본문을 부른다', () {
      final source = File(indexPath).readAsStringSync();

      // 태그 이름은 네이티브 문서 앱이 같은 파일에서 읽는다 — 이름을
      // 바꾸면 그쪽 홈이 조용히 비어 버린다.
      expect(source, contains('<SiteHero />'));
      expect(source, contains('<SiteShowcase />'));
    });

    test('랜딩은 전체 목록을 늘어놓지 않는다', () {
      final source = File(indexPath).readAsStringSync();

      // 훑어야 할 목록은 `/components-overview` 의 일이다. 첫 화면이
      // 그걸 대신 지면 "무엇을 주는 킷인가" 대신 스크롤이 나온다.
      expect(source, isNot(contains('<ComponentGrid />')));
    });

    test('설치 안내를 중복하지 않는다', () {
      final source = File(indexPath).readAsStringSync();

      // 설치 방법과 저장소 접근 안내는 `/getting-started` 가 소유한다.
      // 랜딩이 사본을 다시 들면 둘이 갈리고, 어느 쪽이 맞는지 알 수
      // 없어진다.
      expect(source, isNot(contains('pubspec.yaml')));
      expect(source, isNot(contains('dependencies:')));
    });

    test('저장소 접근 안내가 사라지지 않았다', () {
      // 랜딩을 바꾸면서 조용히 없어지면 안 되는 고지다 — 영업 · 법무
      // 성격이고, 이 사이트에서 그것을 말하는 유일한 자리다.
      final gettingStarted = File(gettingStartedPath).readAsStringSync();

      expect(gettingStarted, contains('저장소 접근 안내'));
      expect(gettingStarted, contains('cody@cocode.im'));
      expect(gettingStarted, contains('계약 고객'));
    });
  });

  // ── 화면의 숫자는 전부 카탈로그에서 온다 ──────────────────────
  //
  // 손으로 적힌 숫자는 지금은 맞고 컴포넌트가 늘어나는 날 조용히 거짓이
  // 된다. 아래는 드리프트가 생기는 **그 순간** 실패한다: 렌더된 숫자를
  // 카탈로그에서 계산한 값과 대조한다.
  group('랜딩이 말하는 숫자', () {
    final total = kDocsComponentGroups.fold<int>(0, (sum, group) => sum + group.items.length);

    test('십 단위로 내린 수가 카탈로그를 따라간다', () {
      expect(siteComponentFloor, (total ~/ 10) * 10);
    });

    testServer('히어로가 말하는 수가 카탈로그와 같다', (tester) async {
      final response = await renderHero(tester);
      final document = response.document!;

      // 알약과 설명 두 자리.
      expect(document.querySelector('.site-hero-eyebrow')!.text, contains('$siteComponentFloor+'));
      expect(document.querySelector('.site-hero-description')!.text, contains('$siteComponentFloor개'));
    });

    testServer('컴포넌트 타일이 말하는 수가 카탈로그와 같다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final count = document.querySelector('[data-count-to]')!;

      expect(count.attributes['data-count-to'], '$siteComponentFloor');
      expect(count.text, '$siteComponentFloor${count.attributes['data-count-suffix']}');
    });

    testServer('카테고리 칩이 카탈로그의 갈래와 개수 그대로다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final chips = document.querySelectorAll('[data-count-chip]');

      expect(chips, hasLength(kDocsComponentGroups.length));
      for (final (index, group) in kDocsComponentGroups.indexed) {
        final chip = chips[index];

        expect(chip.attributes['href'], '/components-overview#${group.id}');
        expect(chip.attributes['data-count-chip'], '${group.items.length}');
        expect(chip.text, contains(group.title));
        expect(chip.text, contains('${group.items.length}'));
      }
      // 칩의 개수를 다 더하면 전체다 — 타일의 큰 숫자가 내려 적은 그 수.
      expect(
        chips.fold<int>(0, (sum, chip) => sum + int.parse(chip.attributes['data-count-chip']!)),
        total,
      );
    });
  });

  group('랜딩 접근성 구조', () {
    // ── heading 이 0 개였던 적이 있다 ──────────────────────────
    //
    // 제목이 `Text(...).displaySmall` 이면 크기만 주는 styled span 이라
    // 문서 구조에 아무것도 남기지 않는다. 화면은 제목처럼 보이므로
    // 접근성 조회를 돌리기 전까지 아무도 모른다.
    testServer('구획 제목이 진짜 heading 이다', (tester) async {
      final document = (await renderShowcase(tester)).document!;

      // 벤토(시안에 제목이 없어 보이지 않게 둔 것) · 진입 카드 · 업데이트.
      final sections = document.querySelectorAll('section[aria-labelledby]');
      expect(sections, hasLength(3));
      for (final section in sections) {
        final title = document.querySelector('#${section.attributes['aria-labelledby']}');

        expect(title?.localName, 'h2', reason: '구획이 가리키는 제목이 h2 가 아니다');
        expect(title!.text.trim(), isNotEmpty);
      }
    });

    testServer('타일과 카드의 이름이 구획 제목 아래 단계다', (tester) async {
      final document = (await renderShowcase(tester)).document!;

      expect(document.querySelectorAll('.site-bento h3'), hasLength(document.querySelectorAll('.site-tile').length));
      expect(document.querySelectorAll('.site-entry h3'), hasLength(siteEntryPoints.length));
      // h3 밖의 단계가 섞이지 않는다.
      expect(document.querySelectorAll('h1, h4, h5, h6'), isEmpty);
    });

    testServer('카드와 줄이 클릭 핸들러가 아니라 링크다', (tester) async {
      final document = (await renderShowcase(tester)).document!;

      // 링크여야 크롤되고, 새 탭으로 열리고, 스크린 리더가 링크로
      // 읽는다. 클릭 핸들러는 그 셋 중 아무것도 주지 않는다.
      final cards = document.querySelectorAll('.site-entries .site-entry');
      expect(cards, hasLength(siteEntryPoints.length));
      expect(cards.map((card) => card.localName).toSet(), {'a'});
      expect(
        cards.map((card) => card.attributes['href']).toList(),
        siteEntryPoints.map((entry) => entry.href).toList(),
      );

      for (final row in document.querySelectorAll('.site-update')) {
        expect(row.localName, 'a');
        expect(row.attributes['href'], '/changelog');
      }
    });

    testServer('본문의 내부 링크가 전부 실재하는 문서로 간다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final hrefs = {
        for (final link in document.querySelectorAll('a[href]'))
          if (link.attributes['href'] case final href? when href.startsWith('/')) href,
      };

      expect(hrefs, isNotEmpty);
      for (final href in hrefs) {
        expect(hasPage(href), isTrue, reason: '`$href` 에 문서가 없다');
      }
    });

    testServer('굴러가는 숫자는 보조 기술에 내지 않고, 값은 글자로 적는다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final count = document.querySelector('[data-count-to]')!;

      // 큰 숫자는 들어올 때 0 에서 굴러 오고 카테고리를 가리키면 그
      // 개수로 바뀐다. 그대로 읽히면 도중의 숫자가 총 개수로 읽힌다.
      expect(count.attributes['aria-hidden'], 'true');
      expect(count.parent!.querySelector('.site-sr-only')!.text, contains('$siteComponentFloor'));
    });

    testServer('"보기" 가 여럿이어도 링크 이름으로 서로를 가린다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final names = [
        for (final link in document.querySelectorAll('.site-tile-head a'))
          link.attributes['aria-label'] ?? link.text.trim(),
      ];

      expect(names, isNotEmpty);
      expect(names.toSet(), hasLength(names.length), reason: '같은 이름의 링크가 둘이다: $names');
    });
  });

  group('코드 타일', () {
    testServer('탭과 패널이 서로를 가리킨다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final tabs = document.querySelectorAll('[role="tablist"] [role="tab"]');

      expect(tabs, hasLength(kSiteCodeSamples.length));
      for (final tab in tabs) {
        final panel = document.querySelector('#${tab.attributes['aria-controls']}');

        expect(panel?.attributes['role'], 'tabpanel');
        expect(panel?.attributes['aria-labelledby'], tab.id);
      }
    });

    testServer('스크립트 없이도 첫 플랫폼의 코드가 보인다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final tabs = document.querySelectorAll('[role="tab"]');
      final panels = document.querySelectorAll('[role="tabpanel"]');

      // 선택과 가림은 서버가 적는다 — 스크립트는 그것을 옮길 뿐이다.
      expect(tabs.where((tab) => tab.attributes['aria-selected'] == 'true'), hasLength(1));
      expect(tabs.first.attributes['aria-selected'], 'true');
      expect(panels.where((panel) => !panel.attributes.containsKey('hidden')), hasLength(1));
      expect(panels.first.attributes.containsKey('hidden'), isFalse);
      expect(panels.first.text, contains(kSiteCodeSamples.first.importLine));
    });

    testServer('패널의 글자가 복사할 코드 그대로다', (tester) async {
      final document = (await renderShowcase(tester)).document!;

      // 복사는 패널의 글자를 그대로 가져간다. 줄이 블록이라 화면에서는
      // 개행 없이도 줄이 바뀌지만, 글자로 개행이 없으면 한 줄로 붙는다.
      for (final (index, sample) in kSiteCodeSamples.indexed) {
        final panel = document.querySelectorAll('[role="tabpanel"]')[index];

        expect(panel.text.trimRight(), [sample.importLine, '', ...siteCodeCall].join('\n'));
      }
    });

    testServer('복사 버튼이 자기 문구를 들고 있다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final copy = document.querySelector('[data-code-copy]')!;

      // 스크립트는 문구를 갖지 않는다 — 세 상태의 글자를 여기서 읽는다.
      expect(copy.attributes['data-idle'], copy.text.trim());
      expect(copy.attributes['data-copied'], isNotEmpty);
      expect(copy.attributes['data-failed'], isNotEmpty);
      // 결과는 화면의 글자와 함께 알림 영역으로도 나간다.
      expect(document.querySelector('[data-code-status]')?.attributes['aria-live'], 'polite');
    });
  });

  group('Figma · MCP 타일', () {
    testServer('응답 예시가 첫 레이어의 값이다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final first = siteLayers.first;
      final fields = {
        for (final field in document.querySelectorAll('[data-mcp-field]'))
          field.attributes['data-mcp-field']: field.text,
      };

      expect(fields, {
        'name': first.name,
        'property': first.property,
        'value': first.value,
        'token': first.token,
      });
    });

    testServer('레이어 줄이 응답을 채울 값을 전부 들고 있다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final rows = document.querySelectorAll('[data-layer]');

      // 스크립트는 가리킨 줄의 `data-*` 를 응답의 같은 이름 자리에 옮긴다.
      // 한 줄이 한 값을 빠뜨리면 그 자리가 `undefined` 로 바뀐다.
      expect(rows, hasLength(siteLayers.length));
      for (final (index, layer) in siteLayers.indexed) {
        final row = rows[index];

        expect(row.attributes['data-name'], layer.name);
        expect(row.attributes['data-property'], layer.property);
        expect(row.attributes['data-value'], layer.value);
        expect(row.attributes['data-token'], layer.token);
        expect(row.attributes['href'], layer.href);
      }
      expect(rows.where((row) => row.attributes.containsKey('data-active')), hasLength(1));
      expect(rows.first.attributes.containsKey('data-active'), isTrue);
    });
  });

  group('테마 타일', () {
    testServer('스위치 셋이 이름을 갖고 서버 렌더에 나온다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final switches = document.querySelectorAll('.site-theme-rows [role="switch"]');

      expect(switches, hasLength(3));
      for (final toggle in switches) {
        // 이름은 스위치 안의 글자에서 온다.
        expect(toggle.querySelectorAll('span').any((span) => span.text.trim().isNotEmpty), isTrue);
      }
    });

    testServer('서버는 아는 척하지 않는다', (tester) async {
      final document = (await renderShowcase(tester)).document!;

      // 밝기와 OS 설정은 브라우저만 안다. 준비 표시는 island 가 그 값을
      // 읽은 뒤에 붙고, 시트는 그 전의 스위치를 감춘다.
      expect(document.querySelector('.site-theme-rows')!.attributes.containsKey('data-ready'), isFalse);
    });
  });

  group('최근 업데이트', () {
    testServer('패키지 CHANGELOG 의 최근 릴리스가 나온다', (tester) async {
      final document = (await renderShowcase(tester)).document!;
      final rows = document.querySelectorAll('.site-update');
      final updates = SiteUpdates.read();

      expect(rows, hasLength(SiteUpdates.count));
      for (final (index, update) in updates.indexed) {
        expect(rows[index].querySelector('.site-update-version')!.text, update.version);
        expect(rows[index].querySelector('.site-update-summary')!.text, update.summary);
        expect(rows[index].querySelector('.site-update-date')!.text, update.date);
      }
    });
  });

  group('헤더 내비게이션 랜드마크', () {
    testServer('내비게이션 랜드마크를 정확히 하나 낸다', (tester) async {
      // 랜딩의 헤더 — 어느 탭에도 속하지 않으므로 경로를 넘기지 않는다.
      tester.pumpComponent(
        CoUIWeb(theme: ThemeData.coui, child: const SiteHeader()),
      );
      final response = await tester.request('/');
      final document = response.document!;

      // 헤더의 탭 목록이 주 내비게이션이다. 그것을 한 번 더 감싸면 같은
      // 내비게이션이 두 겹이 되어 스크린 리더의 랜드마크 목록에 두 번
      // 나온다 — 그 회귀가 여기서 빨개진다. 반대로 0 이면 "영역으로
      // 건너뛰기" 목록에 주 내비게이션이 없다.
      final landmarks = document.querySelectorAll('nav, [role="navigation"]');
      expect(landmarks, hasLength(1));

      final nav = landmarks.single;
      expect(nav.attributes['aria-label'], kSiteNavLabel);
      expect(nav.querySelectorAll('a[href]'), isNotEmpty);

      // 탭은 페이지를 옮기는 링크다 — 메뉴나 탭 목록 역할을 주장하면
      // 리더가 안의 링크가 줄 수 없는 화살표 조작을 기대한다.
      expect(
        document.querySelectorAll('[role="menubar"], [role="menuitem"], [role="tablist"], [role="tab"]'),
        isEmpty,
      );
    });
  });

  group('랜딩 푸터 — 좁은 폭의 도달 가능성', () {
    testServer('contentinfo 랜드마크를 낸다', (tester) async {
      final response = await renderFooter(tester);
      expect(response.statusCode, 200);
      expect(response.document!.querySelector('footer'), isNotNull);
    });

    // ── 이 테스트가 이 푸터의 존재 이유다 ──────────────────────
    //
    // 헤더 내비게이션은 1024px 아래에서 감춰진다. 문서 페이지에서는
    // 사이드바(햄버거)가 같은 목적지를 들고 있어 괜찮지만 **랜딩에는
    // 사이드바가 없다** — 그래서 좁은 폭의 랜딩에서 네 목적지가 화면에서
    // 통째로 사라졌다. 브라우저에서 좁혀 보기 전까지 안 보이는 결함이다.
    //
    // 아래는 그 구멍이 다시 열리면 빨개진다: 헤더가 제공하는 목적지는
    // 전부 푸터에도 있어야 한다.
    testServer('헤더 내비게이션의 목적지를 전부 담는다', (tester) async {
      final response = await renderFooter(tester);
      final hrefs = response.document!.querySelectorAll('a[href]').map((e) => e.attributes['href']).toSet();

      // 헤더의 링크 항목 셋.
      for (final href in const [
        '/getting-started',
        '/tokens/overview',
        '/changelog',
      ]) {
        expect(hrefs, contains(href), reason: '푸터에 `$href` 가 없다');
      }

      // 헤더의 드롭다운 둘 — 컴포넌트와 가이드.
      expect(
        hrefs,
        contains('/components-overview'),
        reason: '컴포넌트로 가는 길이 푸터에 없다',
      );
      expect(
        hrefs.any((h) => h != null && h.startsWith('/guides/')),
        isTrue,
        reason: '가이드로 가는 길이 푸터에 없다',
      );
    });

    testServer('링크가 전부 실재하는 문서로 간다', (tester) async {
      final response = await renderFooter(tester);
      final hrefs = response.document!.querySelectorAll('a[href]').map((e) => e.attributes['href']!).toList();

      expect(hrefs, isNotEmpty);
      for (final href in hrefs) {
        expect(hasPage(href), isTrue, reason: '푸터의 `$href` 에 문서가 없다');
      }
    });

    testServer('갈래마다 제목 아래 링크 목록이다', (tester) async {
      final document = (await renderFooter(tester)).document!;
      final lists = document.querySelectorAll('ul.site-footer-links');

      // 줄바꿈으로 늘어놓은 링크가 아니라 목록이어야 보조 기술이 "세 항목
      // 중 첫째" 로 읽는다.
      expect(lists, hasLength(3));
      for (final list in lists) {
        expect(list.querySelectorAll('li > * a[href], li > a[href]'), hasLength(list.children.length));
      }
    });
  });

  group('히어로 서버 렌더', () {
    testServer('헤드라인과 요약이 JS 없이도 읽힌다', (tester) async {
      final response = await renderHero(tester);
      expect(response.statusCode, 200);

      // 등장은 CSS 애니메이션이다 — 마크업은 서버가 다 적는다. 헤드라인이
      // 스크립트를 기다린다면 이 페이지는 JS 가 늦는 환경과 크롤러에게
      // 빈 화면이다.
      expect(response.body, contains('Flutter와 Jaspr Web'));
      expect(response.document!.querySelector('h1')!.text, contains('디자인 시스템'));
    });

    testServer('CTA가 자바스크립트 없이도 이동 가능한 링크다', (tester) async {
      final response = await renderHero(tester);

      final links = response.document!.querySelectorAll(
        '.site-hero-actions a[href]',
      );
      expect(links.map((e) => e.attributes['href']).toSet(), {
        '/getting-started',
        '/components-overview',
      });
      expect(response.document!.querySelectorAll('.site-hero-actions button'), isEmpty);
    });

    testServer('알약이 카탈로그로 가는 링크다', (tester) async {
      final response = await renderHero(tester);
      final eyebrow = response.document!.querySelector('.site-hero-eyebrow');

      expect(eyebrow?.localName, 'a');
      expect(hasPage(eyebrow!.attributes['href']!), isTrue);
    });

    testServer('헤드라인이 진짜 h1 이다', (tester) async {
      final response = await renderHero(tester);
      final headings = response.document!.querySelectorAll('h1');

      // 스타일된 `Text` 만으로는 문서 구조에 아무것도 남지 않는다 —
      // 랜딩 전체에 heading 이 0 개였던 적이 있다.
      expect(headings, hasLength(1));
      // 두 줄은 나뉘어 들어오지만 한 문장으로 읽힌다 — 줄 사이에 낱말
      // 경계가 글자로 있다.
      expect(headings.single.text.replaceAll(RegExp(r'\s+'), ' ').trim(), '앱과 웹을 잇는 하나의 디자인 시스템');
    });
  });

  group('랜딩 레이아웃', () {
    test('등장 게이트는 스크립트보다 먼저, 문서 머리에서 돈다', () {
      // 게이트가 본문 뒤에 돌면 숨길 요소가 한 번 그려졌다가 사라진다.
      // 그래서 게이트는 인라인이고, 랜딩 스크립트는 그 뒤에 온다.
      expect(kSiteMotionGate, contains(kSiteMotionAttribute));
      expect(kSiteMotionGate, isNot(contains('src=')));
    });
  });
}
