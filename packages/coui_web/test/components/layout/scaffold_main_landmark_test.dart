// `main` 랜드마크 중첩 회귀 가드 (#3825) — Flutter 쪽과 같은 계약.
//
// 셸 스캐폴드(앱 chrome + 라우팅된 콘텐츠) 안에 페이지 스캐폴드를 두는 것은
// 평범한 조합인데, 스캐폴드마다 랜드마크를 내면 `<main>` 안에 `<main>` 이
// 되어 유효하지 않은 HTML 이 되고 스크린리더에 "본문" 이 둘로 읽힌다.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// `role="main"` 을 단 요소를 찾는다.
Finder _mainLandmark() => find.byComponentPredicate(
  (c) => c is div && c.attributes?['role'] == CoreSemanticRole.main.ariaRole,
);

void main() {
  group('Scaffold — main 랜드마크', () {
    testComponents('단일 스캐폴드는 본문에 랜드마크를 낸다', (tester) async {
      pumpWithTheme(
        tester,
        Scaffold(child: div([const Component.text('single')])),
      );
      await tester.pump();

      expect(_mainLandmark(), findsOneComponent);
    });

    testComponents('중첩 스캐폴드는 바깥 하나만 낸다', (tester) async {
      pumpWithTheme(
        tester,
        Scaffold(
          child: Scaffold(child: div([const Component.text('inner')])),
        ),
      );
      await tester.pump();

      expect(
        _mainLandmark(),
        findsOneComponent,
        reason: '중첩해도 main 은 정확히 하나여야 한다',
      );
    });

    testComponents('mainLandmark: false 면 랜드마크가 안쪽으로 넘어간다', (tester) async {
      pumpWithTheme(
        tester,
        Scaffold(
          mainLandmark: false,
          child: Scaffold(child: div([const Component.text('inner')])),
        ),
      );
      await tester.pump();

      expect(
        _mainLandmark(),
        findsOneComponent,
        reason: '바깥이 opt-out 하면 안쪽이 가져가 총 1개가 유지된다',
      );
    });
  });
}
