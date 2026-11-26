// `main` 랜드마크 중첩 회귀 가드 (#3825).
//
// 셸 스캐폴드(앱 chrome + 라우팅된 콘텐츠) 안에 페이지 스캐폴드를 두는 것은
// 평범한 조합인데, 스캐폴드마다 랜드마크를 내면 `main` 안에 `main` 이 되어
// 프레임워크가 거부한다. 바깥 하나만 내고 안쪽은 침묵해야 한다.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart' show SemanticsNode, SemanticsRole;
import 'package:flutter_test/flutter_test.dart';

material.Widget _app(material.Widget home) => CoUIApp(
  theme: ThemeData.fromCore(CoreThemePresets.light),
  home: home,
);

/// 트리 전체에서 `main` 랜드마크 노드 수를 센다.
int _countMainLandmarks(SemanticsNode node) {
  var count = node.getSemanticsData().role == SemanticsRole.main ? 1 : 0;
  node.visitChildren((child) {
    count += _countMainLandmarks(child);
    return true;
  });

  return count;
}

void main() {
  group('Scaffold — main 랜드마크', () {
    testWidgets('단일 스캐폴드는 본문에 랜드마크를 낸다', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(const Scaffold(child: material.Text('single'))),
      );
      await tester.pump();

      expect(
        _countMainLandmarks(
          tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!,
        ),
        1,
        reason: '스캐폴드 하나면 그 본문이 main 이어야 한다',
      );
      handle.dispose();
    });

    testWidgets('중첩 스캐폴드는 바깥 하나만 낸다 (어서션 없음)', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          const Scaffold(child: Scaffold(child: material.Text('inner'))),
        ),
      );
      await tester.pump();

      expect(
        _countMainLandmarks(
          tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!,
        ),
        1,
        reason: '중첩해도 main 은 정확히 하나여야 한다',
      );
      handle.dispose();
    });

    testWidgets('형제 스캐폴드도 바깥 하나만 낸다', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          const Scaffold(
            child: material.Row(
              children: [
                material.Expanded(
                  child: Scaffold(child: material.Text('left')),
                ),
                material.Expanded(
                  child: Scaffold(child: material.Text('right')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        _countMainLandmarks(
          tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!,
        ),
        1,
        reason: '분할 화면(형제 스캐폴드)에서도 main 은 하나여야 한다',
      );
      handle.dispose();
    });

    testWidgets('mainLandmark: false 면 랜드마크가 안쪽으로 넘어간다', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          const Scaffold(
            mainLandmark: false,
            child: Scaffold(child: material.Text('inner')),
          ),
        ),
      );
      await tester.pump();

      expect(
        _countMainLandmarks(
          tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!,
        ),
        1,
        reason: '바깥이 opt-out 하면 안쪽이 main 을 가져가 총 1개가 유지된다',
      );
      handle.dispose();
    });
  });
}
