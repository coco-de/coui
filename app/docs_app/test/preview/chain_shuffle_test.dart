import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/preview/chain_shuffle_control.dart';
import 'package:docs_app/src/preview/flutter_pane.dart';
import 'package:docs_app/src/preview/web_render.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/chain_shuffle_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// 네이티브 셔플 배선의 게이트 — jaspr 쪽과 같은 공유 스토어·순열 모듈이
/// Flutter 런타임에서 실제로 동작하는지 (선언이 아니라 발화로) 고정한다.
void main() {
  Widget harness(Widget child) => CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    home: child,
  );

  group('셔플 스토어 — Flutter 런타임 활성', () {
    test('default 생성자 스토어가 advance 를 반영한다 (js_interop 부재 오판 방지)', () {
      // 가드가 `dart.library.js_interop` 하나만 보면 네이티브(VM+dart:ui)가
      // 서버로 오판되어 advance 가 조용히 no-op — 셔플 버튼이 죽는다.
      // flutter_test 는 정확히 그 런타임(ui 있음·js_interop 없음)이다.
      final store = ChainShuffleStore();
      var notified = 0;
      store.addListener('panel-a', () => notified++);

      store.advance('panel-a');

      expect(store.stepOf('panel-a'), 1);
      expect(notified, 1);
    });
  });

  group('DocsChainShuffleControl', () {
    testWidgets('칩은 base 좌표로 시작하고 탭마다 다음 순열 라벨로 간다', (tester) async {
      const panelId = 'chain-test-control-1';
      await tester.pumpWidget(
        harness(const DocsChainShuffleControl(panelId: panelId)),
      );

      expect(
        find.text(chainPermutationLabel(kChainBasePermutation)),
        findsOneWidget,
      );

      await tester.tap(find.text('Shuffle'));
      await tester.pump();

      expect(
        find.text(chainPermutationLabel(chainPermutationAt(1))),
        findsOneWidget,
      );
      // SR 통보 debounce 타이머 소진 (pending timer 로 테스트가 안 죽게).
      await tester.pump(const Duration(milliseconds: 350));
    });
  });

  group('DocsFlutterPane — chain 순열 렌더러', () {
    testWidgets('좌표를 받으면 순열 렌더러 경로로 그린다 (T1 badge)', (tester) async {
      await tester.pumpWidget(
        harness(
          DocsFlutterPane(
            component: 'badge',
            variant: 'chain',
            chainPermutation: chainPermutationAt(1),
          ),
        ),
      );

      // 렌더러 경로가 살아 있으면 안내 문구가 아니라 실제 위젯이 그려진다.
      expect(find.text('Preview not available'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('renderWebPreviewHtml — chainStep 고정 렌더', () {
    test('step 이 다르면 다른 chrome 의 HTML 이 나온다', () async {
      final base = await renderWebPreviewHtml(
        component: 'badge',
        dark: false,
        variant: 'chain',
        chainStep: 0,
      );
      final permuted = await renderWebPreviewHtml(
        component: 'badge',
        dark: false,
        variant: 'chain',
        chainStep: 1,
      );

      expect(base, isNotNull);
      expect(permuted, isNotNull);
      // 같은 페이지 뼈대에 순열 chrome 만 달라야 한다 — 동일하면 chainStep
      // 이 EmbedPage→WebPreview 로 통과되지 않은 것이다.
      expect(base, isNot(equals(permuted)));
    });
  });
}
