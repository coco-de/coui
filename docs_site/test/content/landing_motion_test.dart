@TestOn('vm')
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart' show CoUIWeb, CoreDuration, CoreReducedMotion, ThemeConfig, ThemeData;
import 'package:docs_site/components/site_hero.dart';
import 'package:docs_site/components/site_landing_styles.dart';
import 'package:docs_site/components/site_motion.dart';
import 'package:docs_site/components/site_theme_controls.dart';
import 'package:docs_site/layouts/landing_layout.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// 랜딩의 움직임이 모션 토큰만 읽는지 본다.
///
/// 이 테스트들이 지키는 것은 하나다 — 랜딩의 어떤 전환도 자기 시계를
/// 갖지 않는다. 시간이 리터럴로 적힌 전환은 동작 줄이기 설정이 닿지
/// 않고, 그 누락은 그 설정을 켠 사람이 부딪히기 전까지 보이지 않는다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  final css = siteLandingCss;
  final script = File('web/docs-landing.js').readAsStringSync();

  /// 주석을 뺀 스크립트 — 설명 문장 속의 숫자를 코드로 세지 않게.
  final code = script.split('\n').where((line) => !line.trimLeft().startsWith('//')).join('\n');

  group('모션 어휘', () {
    test('모든 시간과 곡선이 킷의 변수 참조다', () {
      for (final entry in SiteMotion.declarations.entries) {
        expect(
          entry.value,
          matches(RegExp(r'^var\(--(coui-duration|easing)-[a-z0-9-]+\)$')),
          reason: '${entry.key} 가 변수 참조가 아니라 값을 직접 든다 — 동작 줄이기가 닿지 않는다',
        );
      }
    });

    test('전환에 쓰는 시간은 전부 전환 tier 다', () {
      // 표시 시간(`hold`) 하나만 그 위에 있다 — 줄어들면 안 되는 값이다.
      for (final entry in SiteMotion.declarations.entries) {
        final step = RegExp(r'--coui-duration-(\d+)').firstMatch(entry.value)?.group(1);
        if (step == null) continue;
        final isTransition = CoreReducedMotion.isTransitionMotion(Duration(milliseconds: int.parse(step)));

        expect(
          isTransition,
          entry.key != SiteMotion.hold,
          reason: '${entry.key} = ${step}ms 의 tier 가 그 쓰임과 다르다',
        );
      }
    });

    test('선언한 변수는 킷의 시트에 실재한다', () {
      final kit = ThemeConfig.defaults().cssVariables;

      for (final value in SiteMotion.declarations.values) {
        final name = RegExp(r'var\((--[a-z0-9-]+)\)').firstMatch(value)!.group(1)!;
        expect(kit, contains('$name:'), reason: '킷이 `$name` 을 정의하지 않는다');
      }
    });
  });

  group('순차 등장', () {
    test('한 시퀀스의 총합이 slow 를 넘지 않는다', () {
      // 마지막 항목의 지연 + 한 항목의 길이.
      const total = kSiteStaggerLastIndex * kSiteStaggerStepMs + kSiteRevealMs;

      expect(total, lessThanOrEqualTo(CoreDuration.slow));
      // 한 칸 더 늘리면 넘는다 — 상한이 느슨하게 잡히지 않았다.
      expect(total + kSiteStaggerStepMs, greaterThan(CoreDuration.slow));
    });

    test('시트가 순번을 그 상한에서 자른다', () {
      expect(css, contains('--site-stagger-last:$kSiteStaggerLastIndex;'));
      expect(
        RegExp(r'min\(var\(--i, 0\), var\(--site-stagger-last\)\)').allMatches(css).length,
        greaterThanOrEqualTo(3),
        reason: '순번을 쓰는 지연은 전부 상한을 거쳐야 한다',
      );
      // 순번을 상한 없이 곱하는 지연이 없다.
      expect(css, isNot(matches(RegExp(r'\* var\(--i'))));
    });

    testServer('히어로의 조각들이 상한 안의 순번을 갖는다', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: ThemeData.coui, child: const SiteHeroView()));
      final document = (await tester.request('/')).document!;
      final orders = [
        for (final piece in document.querySelectorAll('.site-rise'))
          int.parse(RegExp(r'--i:\s*(\d+)').firstMatch(piece.attributes['style'] ?? '')!.group(1)!),
      ];

      expect(orders, [0, 1, 2, 3, 4]);
      expect(orders.last, lessThanOrEqualTo(kSiteStaggerLastIndex));
    });
  });

  group('랜딩 시트', () {
    test('면 역할을 다크에서도 같은 토큰으로 진술해 셸의 바꿔 끼우기를 이긴다', () {
      // 셸 시트는 `[data-theme='dark'] .docs` 에서 역할을 다른 토큰으로 바꾼다.
      // 랜딩의 역할 블록이 다크 선택자를 함께 갖지 않으면 그 규칙이 이겨,
      // 다크에서만 시안보다 한 단계 어두운 면이 그려진다.
      final block = RegExp(r"\.docs\.landing,\s*\[data-theme='dark'\] \.docs\.landing \{([^}]*)\}").firstMatch(css);
      expect(block, isNotNull, reason: '랜딩 역할 블록에 다크 선택자가 없다');

      for (final role in ['page', 'tile', 'inset', 'select', 'card']) {
        expect(block!.group(1), contains('--site-$role:'), reason: '`--site-$role` 이 다크에서 셸의 값으로 남는다');
      }
    });

    test('토글의 표지색이 셸 시트의 표지색과 같다', () {
      // 토글은 표지색을 토큰 이름이 아니라 값으로 든다 — 시트의 줄이
      // 바뀌면 여기서 갈린다.
      final shell = File('web/docs-shell.css').readAsStringSync();
      final values = [
        for (final m in RegExp(r'--site-accent:\s*(\d+) (\d+) (\d+);').allMatches(shell))
          0xFF000000 | int.parse(m[1]!) << 16 | int.parse(m[2]!) << 8 | int.parse(m[3]!),
      ];

      expect(values, [kSiteAccentLight, kSiteAccentDark]);
    });

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

    test('참조한 --site-* 변수는 전부 선언돼 있다', () {
      final declared = RegExp(r'(--site-[a-z0-9-]+)\s*:').allMatches(css).map((m) => m.group(1)).toSet();
      final used = RegExp(r'var\((--site-[a-z0-9-]+)').allMatches(css).map((m) => m.group(1)).toSet();

      expect(used.difference(declared), isEmpty, reason: '선언 없이 읽는 변수는 그 선언을 통째로 무효로 만든다');
    });

    test('참조한 킷 변수는 전부 킷의 시트에 실재한다', () {
      final config = ThemeConfig.defaults();
      final kit = '${config.cssVariables}${config.surfaceStyleVariableBlocks}';
      final used = RegExp(r'var\((--(?:coui|easing)-[a-z0-9_-]+)').allMatches(css).map((m) => m.group(1)!).toSet();

      expect(used, isNotEmpty);
      for (final name in used) {
        expect(kit, contains('$name:'), reason: '킷이 `$name` 을 정의하지 않는다 — 그 선언은 버려진다');
      }
    });

    test('내용은 스크립트가 맡았을 때만 숨긴다', () {
      // 숨김(`opacity: 0` · `visibility: hidden`)은 키프레임의 시작과 게이트
      // 아래에만 있다. 게이트 밖에 있으면 스크립트 없는 문서가 그 요소를
      // 영영 못 본다.
      //
      // 장식은 예외다: 다가갔을 때만 들어오는 화살표는 `aria-hidden` 이라
      // 감춰도 잃는 내용이 없다.
      const decorative = {'.site-entry .site-arrow'};
      final rules = RegExp(r'([^{}]+)\{([^{}]*)\}').allMatches(css.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ''));
      final hiding = [
        for (final rule in rules)
          if (rule.group(2)!.contains(RegExp(r'opacity:\s*0\b|visibility:\s*hidden')))
            rule.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' '),
      ];

      expect(hiding, isNotEmpty);
      expect(hiding, containsAll(decorative), reason: '예외 목록이 시트에 없는 선택자를 들고 있다');
      for (final selector in hiding) {
        expect(
          selector == 'from' || selector.startsWith('html[$kSiteMotionAttribute]') || decorative.contains(selector),
          isTrue,
          reason: '`$selector` 가 게이트 없이 요소를 숨긴다',
        );
      }
    });
  });

  group('인쇄', () {
    // 스크롤 등장 대상은 화면에 들어오기 전까지 숨겨져 있다. 스크롤하지
    // 않고 인쇄하면 그 구획이 빈 채로 찍힌다 — 그리고 숨김만 풀고 전환을
    // 남기면, 인쇄는 전환이 시작되는 순간을 찍으므로 여전히 투명하다.
    // 브라우저에서 미디어를 바꾼 직후의 값으로 확인한 동작이다.
    test('종이에서는 등장 대상이 전환 없이 전부 보인다', () {
      final print = RegExp(r'@media print\s*\{([\s\S]*?\})\s*\}').firstMatch(css)?.group(1) ?? '';

      expect(print, contains('[data-reveal]'));
      expect(print, contains('opacity: 1'));
      expect(print, contains('transition: none'));
    });

    test('인쇄 직전에 기다리던 대상을 풀고 숫자를 제자리에 둔다', () {
      final handler = RegExp(r"addEventListener\('beforeprint'[\s\S]*?\n    \}\);").firstMatch(script)?.group(0) ?? '';

      expect(handler, contains("removeAttribute('data-site-motion')"));
      expect(handler, contains("removeAttribute('data-reveal')"));
      expect(handler, contains('count.textContent = total + tail'));
    });
  });

  group('랜딩 스크립트', () {
    test('시간을 적지 않는다', () {
      expect(code, isNot(matches(RegExp(r'\b\d+\s*m?s\b'))), reason: '스크립트에 시간 리터럴이 있다');
      // 타이머는 모션 변수에서 읽은 시간만 받는다.
      for (final timer in RegExp(r'setTimeout\(([\s\S]*?)\);').allMatches(code)) {
        expect(timer.group(1), matches(RegExp(r"(duration\('--site-duration-[a-z]+'\)|\bwait)\s*$")));
      }
    });

    test('읽는 모션 변수는 전부 선언돼 있다', () {
      final read = RegExp("'(--site-(?:duration|easing)-[a-z]+)'").allMatches(code).map((m) => m.group(1)!).toSet();

      expect(read, isNotEmpty);
      expect(read.difference(SiteMotion.declarations.keys.toSet()), isEmpty);
    });

    test('문구를 갖지 않는다', () {
      // 화면에 나가는 글자는 서버가 `data-*` 로 건넨다 — 스크립트에 한글이
      // 있으면 같은 문구가 두 곳에 산다.
      expect(code, isNot(matches(RegExp('[가-힣]'))));
    });
  });

  group('등장 게이트', () {
    test('맡을 수 있을 때만 붙이고, 못 맡으면 뗀다', () {
      expect(kSiteMotionGate, contains('IntersectionObserver'));
      expect(kSiteMotionGate, contains('setAttribute("$kSiteMotionAttribute"'));
      expect(kSiteMotionGate, contains('removeAttribute("$kSiteMotionAttribute")'));
      // 뗄지 말지는 스크립트가 남기는 표시로 정한다.
      expect(kSiteMotionGate, contains('__siteLanding'));
      expect(script, contains('window.__siteLanding = true'));
    });
  });
}
