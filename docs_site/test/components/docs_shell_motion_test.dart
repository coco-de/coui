@TestOn('vm')
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart' show CoreZIndex, ThemeConfig;
import 'package:docs_site/components/site_motion.dart';
import 'package:test/test.dart';

/// 문서 셸의 움직임이 모션 토큰만 읽는지 본다.
///
/// 랜딩의 같은 검사(`landing_motion_test.dart`)가 지키는 것을 문서 페이지
/// 150 여 장이 함께 싣는 시트와 스크립트에 대해 지킨다 — 셸의 어떤 전환도
/// 자기 시계를 갖지 않는다. 시간이 리터럴로 적힌 전환은 동작 줄이기 설정이
/// 닿지 않고, 그 누락은 그 설정을 켠 사람이 부딪히기 전까지 보이지 않는다.
void main() {
  final sheet = File('web/docs-shell.css').readAsStringSync();

  /// 주석을 뺀 시트 — 설명 문장 속의 낱말을 규칙으로 세지 않게.
  final css = sheet.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

  /// 주석을 뺀 스크립트.
  String code(String path) =>
      File(path).readAsLinesSync().where((line) => !line.trimLeft().startsWith('//')).join('\n');

  final shell = code('web/docs-shell.js');

  /// 스크립트의 앞부분 — 서랍 · 복사 · 등장. 뒤의 문서 도구(카탈로그 필터
  /// 등)는 움직임을 다루지 않는다.
  final shellMotion = shell.substring(0, shell.indexOf("const catalog = document.querySelector('.showcase')"));

  group('모션 어휘', () {
    test('문서 요소에 선언된다 — 페이지 전환이 읽을 수 있게', () {
      // `::view-transition-*` 은 문서 요소의 가상 요소다. 안쪽 상자에 선언한
      // 변수는 거기서 읽히지 않아, 그 전환만 자기 시계를 갖게 된다.
      expect(siteMotionRootCss, startsWith(':root{'));
      for (final name in SiteMotion.declarations.keys) {
        expect(siteMotionRootCss, contains('$name:'));
      }
      expect(siteMotionRootCss, contains('--site-stagger-last:$kSiteStaggerLastIndex;'));
    });

    test('두 레이아웃의 머리가 시트보다 먼저 싣는다', () {
      final chrome = File('lib/layouts/site_chrome.dart').readAsStringSync();

      final vocabulary = chrome.indexOf('RawText(siteMotionRootCss)');
      final stylesheet = chrome.indexOf('href: kDocsShellStylesheet');
      expect(vocabulary, isNonNegative);
      expect(stylesheet, greaterThan(vocabulary));
    });
  });

  group('셸 시트', () {
    test('전환과 애니메이션의 시간이 전부 모션 변수다', () {
      final timed = RegExp(r'(?:transition|animation)(?:-duration|-delay)?:([^;}]+)').allMatches(css);
      expect(timed, isNotEmpty);

      for (final match in timed) {
        expect(
          match.group(1),
          isNot(matches(RegExp(r'(?<![\w-])\d*\.?\d+m?s\b'))),
          reason: '시간이 리터럴로 적힌 선언: ${match.group(0)}',
        );
      }
    });

    test('곡선을 키워드나 리터럴로 적지 않는다', () {
      expect(css, isNot(contains('cubic-bezier(')));
      expect(css, isNot(matches(RegExp(r'\b(ease|ease-in|ease-out|ease-in-out|linear)\s*[,;]'))));
    });

    test('전환은 킷의 변수가 아니라 사이트의 모션 어휘를 읽는다', () {
      // 어휘를 한 곳(`site_motion.dart`)에서 바꾸면 셸 전체가 따라와야 한다.
      final timed = RegExp(r'(?:transition|animation)(?:-duration|-delay|-timing-function)?:([^;}]+)').allMatches(css);

      for (final match in timed) {
        expect(match.group(1), isNot(contains('--coui-duration-')), reason: match.group(0));
        expect(match.group(1), isNot(contains('var(--easing-')), reason: match.group(0));
      }
    });

    test('참조한 --site-* 변수는 전부 선언돼 있다', () {
      final declared = {
        ...RegExp(r'(--site-[a-z0-9-]+)\s*:').allMatches(css).map((m) => m.group(1)!),
        ...SiteMotion.declarations.keys,
        '--site-stagger-last',
      };
      final used = RegExp(r'var\((--site-[a-z0-9-]+)').allMatches(css).map((m) => m.group(1)!).toSet();

      expect(used, isNotEmpty);
      expect(used.difference(declared), isEmpty, reason: '선언 없이 읽는 변수는 그 선언을 통째로 무효로 만든다');
    });

    test('참조한 킷 변수는 전부 킷의 시트에 실재한다', () {
      final config = ThemeConfig.defaults();
      final kit = '${config.cssVariables}${config.surfaceStyleVariableBlocks}';
      final used = RegExp(r'var\((--(?:coui|easing|z)-[a-z0-9_-]+)').allMatches(css).map((m) => m.group(1)!).toSet();

      expect(used, isNotEmpty);
      for (final name in used) {
        expect(kit, contains('$name:'), reason: '킷이 `$name` 을 정의하지 않는다 — 그 선언은 버려진다');
      }
    });

    test('쌓임 순서는 킷의 단계를 읽는다', () {
      // 킷의 컴포넌트는 본문 층(`--z-0`)에서 시작한다. 셸이 자기 숫자를 쓰면
      // 스크롤된 본문 — 히어로의 내용, 표의 고정 칸 — 이 고정 헤더 위로
      // 올라와 헤더의 도구를 가린다.
      final declared = RegExp(r'z-index:\s*([^;}]+)').allMatches(css).map((m) => m.group(1)!.trim()).toList();
      expect(declared, isNotEmpty);

      for (final value in declared) {
        // `-1` 은 자기 상자 안에서 내용 뒤로 가는 층(헤더의 흐림)이다.
        expect(
          value == '-1' || RegExp(r'^var\(--z-\d+\)$').hasMatch(value),
          isTrue,
          reason: 'z-index: $value 는 킷의 단계가 아니다',
        );
      }
    });

    test('헤더는 킷이 고정 헤더에 둔 단계에, 건너뛰기 링크는 그 위에 놓인다', () {
      String stepOf(String selector) {
        final rule = RegExp('${RegExp.escape(selector)}\\s*\\{([^}]*)\\}').firstMatch(css)!.group(1)!;

        return RegExp(r'z-index:\s*var\(--z-(\d+)\)').firstMatch(rule)!.group(1)!;
      }

      expect(stepOf('.site-gnb'), CoreZIndex.scale.z20);
      expect(int.parse(stepOf('.docs-skip-link')), greaterThan(int.parse(stepOf('.site-gnb'))));
    });

    test('색은 킷의 변수에서 온다 — 사이트가 가진 색은 표지 하나다', () {
      // 리터럴 색은 다크 모드와 서페이스 스타일을 따라오지 않는다.
      final literals = RegExp(r'rgb\(\s*\d').allMatches(css).map((m) => css.substring(m.start, m.start + 24)).toList();
      // 프리뷰의 코드 패널(어두운 면 위의 글자) 하나만 남는다.
      expect(literals, hasLength(1), reason: '$literals');
      expect(css, isNot(matches(RegExp(r'#[0-9a-fA-F]{3,8}\b'))));

      final accent = RegExp(r'--site-accent:\s*([^;]+);').allMatches(css).map((m) => m.group(1)!.trim()).toList();
      // 밝은 쪽 · 어두운 쪽 · 대비 높이기.
      expect(accent, hasLength(3));
      expect(accent.last, 'var(--coui-on-surface)');
    });

    test('표 안의 코드는 글자 사이에서 끊지 않는다', () {
      // 본문 코드의 `overflow-wrap: anywhere` 는 표 칸이 줄어들 수 있는 폭을
      // 한 글자로 만들어, 필드 이름이 `backgrou|ndColor` 처럼 쪼개졌다. 두
      // 규칙은 특이도가 같아 뒤에 오는 쪽이 이긴다.
      final inline = RegExp(r':where\(:not\(pre\) > code\)[^{]*\{[^}]*overflow-wrap:\s*anywhere').firstMatch(css);
      final table = RegExp(r':where\(table code\)[^{]*\{[^}]*overflow-wrap:\s*normal').firstMatch(css);
      expect(inline, isNotNull, reason: '본문 코드 규칙을 찾지 못했다');
      expect(table, isNotNull, reason: '표 안의 코드가 끊기지 않게 하는 규칙이 없다');
      expect(table!.start, greaterThan(inline!.start), reason: '표 규칙이 본문 규칙보다 앞에 있으면 진다');
    });
  });

  group('순차 등장', () {
    test('순번을 상한에서 자른다', () {
      expect(css, contains('min(var(--i, 0), var(--site-stagger-last))'));
      // 순번을 상한 없이 곱하는 지연이 없다.
      expect(css, isNot(matches(RegExp(r'\* var\(--i'))));
    });

    test('내용은 스크립트가 맡았을 때만 숨긴다', () {
      // 숨김(`opacity: 0`)은 스크립트가 맡은 묶음, 열리는 서랍의 시작
      // 모양, 그리고 다가가면 보이는 제목 옆의 `#` 에만 있다. 그 밖에
      // 있으면 스크립트 없는 문서가 그 요소를 영영 못 본다.
      final rules = RegExp(r'([^{}]+)\{([^{}]*)\}').allMatches(css);
      final hiding = [
        for (final rule in rules)
          if (rule.group(2)!.contains(RegExp(r'opacity:\s*0\b|visibility:\s*hidden')))
            rule.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' '),
      ];

      expect(hiding, isNotEmpty);
      for (final selector in hiding) {
        expect(
          selector == '[data-docs-reveal].is-armed > *' ||
              selector == '.site-drawer:popover-open' ||
              selector.endsWith("> a[href*='#']"),
          isTrue,
          reason: '`$selector` 가 조건 없이 요소를 숨긴다',
        );
      }
    });

    test('스크립트는 아직 화면 아래에 있는 묶음만 맡는다', () {
      // 처음부터 보이던 묶음을 숨겼다가 다시 보이면 그것은 등장이 아니라
      // 깜빡임이다.
      expect(shellMotion, contains("classList.add('is-armed')"));
      expect(shellMotion, contains('getBoundingClientRect().top < innerHeight'));
      expect(shellMotion, contains("'IntersectionObserver' in window"));
    });

    test('종이에서는 기다리던 묶음이 전환 없이 전부 보인다', () {
      final print = RegExp(r'@media print\s*\{([\s\S]*?\})\s*\}').firstMatch(css)?.group(1) ?? '';

      expect(print, contains('[data-docs-reveal].is-armed > *'));
      expect(print, contains('opacity: 1'));
      expect(print, contains('transition: none'));
      expect(shellMotion, contains("addEventListener('beforeprint'"));
    });
  });

  group('페이지 전환', () {
    test('화면 전환은 앱 루트가 싣는다 — 시트는 다시 적지 않는다', () {
      // 같은 가상 요소를 시트가 다시 적으면 어느 쪽이 이길지 시트의 순서가
      // 정하고, 진 쪽의 시간이나 곡선만 섞여 남는다.
      expect(css, isNot(contains('@view-transition')));
      expect(css, isNot(contains('(root)')));
    });

    test('이름 붙은 상자는 움직임을 줄여 달라는 요청에서는 이름이 없다', () {
      final gated = RegExp(
        r'@media \(prefers-reduced-motion: no-preference\)\s*\{([\s\S]*?)\n\}',
      ).firstMatch(css)?.group(1);

      expect(gated, isNotNull);
      expect(gated, contains('.site-tab-pill { view-transition-name: site-tab-pill; }'));
      expect(gated, contains('.docs-nav-mark { view-transition-name: docs-nav-mark; }'));
      // 게이트 밖에는 없다.
      expect(css.replaceFirst(gated!, ''), isNot(contains('view-transition')));
    });

    test('머리글과 사이드바는 전환이 도는 동안에만 이름을 갖는다', () {
      // 이름을 가진 상자는 그 안의 흐림이 상자 바깥을 읽지 못한다. 늘 주면
      // 머리글이 뒤의 본문을 흐리지 않는다.
      expect(css, contains('html:active-view-transition .site-gnb { view-transition-name: site-gnb; }'));
      expect(css, contains('html:active-view-transition .docs-sidebar { view-transition-name: docs-sidebar; }'));
      expect(RegExp(r'(?<!active-view-transition )\.site-gnb \{ view-transition-name').hasMatch(css), isFalse);
    });

    test('이어 그리는 상자는 레이아웃이 실제로 낸다', () {
      final header = File('lib/components/site_header.dart').readAsStringSync();
      final drawer = File('lib/components/site_drawer.dart').readAsStringSync();
      expect(header, contains("'site-tab-pill'"));
      expect(header, contains("'site-gnb'"));
      expect(drawer, contains("'docs-nav-mark'"));
      expect(drawer, contains('docs-sidebar'));
    });
  });

  group('셸 스크립트', () {
    test('시간을 적지 않는다', () {
      expect(shellMotion, isNot(matches(RegExp(r'\b\d+\s*m?s\b'))), reason: '스크립트에 시간 리터럴이 있다');
      // 타이머는 모션 변수에서 읽은 시간만 받는다.
      final timers = RegExp(r'setTimeout\(([\s\S]*?)\)\);').allMatches(shellMotion).toList();
      expect(timers, isNotEmpty);
      for (final timer in timers) {
        expect(timer.group(1), matches(RegExp(r'\bwait\s*$')));
      }
    });

    test('읽는 모션 변수는 전부 선언돼 있다', () {
      final read = {
        for (final path in const ['web/docs-shell.js', 'web/docs-toc.js'])
          ...RegExp("'(--site-(?:duration|easing)-[a-z]+)'").allMatches(code(path)).map((m) => m.group(1)!),
      };

      expect(read, isNotEmpty);
      expect(read.difference(SiteMotion.declarations.keys.toSet()), isEmpty);
    });

    test('복사의 문구를 갖지 않는다', () {
      // 화면에 나가는 글자는 서버가 `data-*` 로 건넨다 — 스크립트에 있으면
      // 같은 문구가 두 곳에 산다.
      expect(shellMotion, isNot(matches(RegExp('[가-힣]'))));
      expect(shellMotion, contains('dataset.copyLabel'));
    });

    test('넓은 폭으로 넘어가면 열린 서랍을 닫는다', () {
      // 열린 `popover` 는 맨 위 층에 있어 본문 옆의 사이드바가 될 수 없다.
      // 경계는 시트의 것과 같아야 한다.
      expect(shellMotion, contains("matchMedia('(min-width: 1024px)')"));
      expect(css, contains('@media (min-width: 1024px)'));
      expect(css, contains('@media (max-width: 1023px)'));
      expect(shellMotion, contains('hidePopover()'));
    });
  });
}
