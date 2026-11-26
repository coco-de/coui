// SPIKE-5 (#3603) — Dialog 대상 probe PoC.
//
// 대상으로 고른 이유(이슈 본문): "오버레이 — Navigator route 안에 있어
// 트리 위치가 다름". Command/DatePicker 는 `pumpTestApp` 이 만든 트리
// 안쪽에 직접 존재하지만, Dialog 는 `showDialog` 로 push 된 별도
// route(Overlay 엔트리) 안에 산다 — pump 한 위젯의 직계 서브트리가
// 아니다. 이 테스트는 (a) 그런데도 `find.byType(Dialog)` 하나로 찾아지는지,
// (b) 패널 chrome(BoxDecoration)과 제목 텍스트 스타일을 똑같은 probe 함수로
// 읽을 수 있는지를 검증한다.
import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import 'widget_tree_probe.dart';

Future<void> _pumpAndOpenDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    // coui_flutter 의 Theme.of 는 coui 자체 Theme 위젯을 요구한다(Material
    // ThemeData 와 별개) — MaterialApp 을 이걸로 감싸야 showDialog 가 push 한
    // route(별도 Overlay 엔트리) 안에서도 dialog_style.dart 의 resolveDialog
    // 가 context 를 타고 올라가 이 Theme 을 찾는다. Navigator/Overlay 경계는
    // InheritedWidget 조회를 막지 않으므로, 감싸는 지점은 MaterialApp
    // 바깥이면 된다(그 안 어디서 push 되든 동일 Theme 을 상속).
    Theme(
      data: const ThemeData(),
      child: material.MaterialApp(
        home: material.Scaffold(
          body: material.Center(
            child: material.Builder(
              builder: (context) => material.ElevatedButton(
                onPressed: () => unawaited(
                  showDialog<void>(
                    context: context,
                    builder: (_) => const Dialog(
                      title: Text('Probe Title'),
                      content: Text('Probe content'),
                    ),
                  ),
                ),
                child: const material.Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // Dialog 는 진입 애니메이션을 가진다(모션 파리티 요구사항) — pumpAndSettle
  // 로 전환이 끝난 안정 상태를 probe 한다. 애니메이션 도중 값을 읽으면
  // geometry 가 보간 중이라 매 실행마다 다른 값이 나올 수 있다.
  await tester.pumpAndSettle();
}

void main() {
  group('probe: Dialog 패널 (SPIKE-5 / #3603)', () {
    testWidgets(
      'Navigator route 안에 있어도 find.byType(Dialog) 하나로 찾아진다 — '
      'route-aware finder 를 따로 만들 필요 없음',
      (tester) async {
        await _pumpAndOpenDialog(tester);

        // pump 한 위젯(MaterialApp)의 "직계" 서브트리가 아니라 Navigator 가
        // push 한 별도 route 의 Overlay 엔트리 안에 있는데도, WidgetTester
        // 의 Finder 는 기본적으로 전체 렌더 트리(활성 Overlay 포함)를
        // 대상으로 하므로 root finder 선언에 Navigator/route 인식 로직이
        // 필요 없다 — README.md 의 "root 하나로 충분한가" 판단 근거.
        expect(find.byType(Dialog), findsOneWidget);
      },
    );

    testWidgets('패널 BoxDecoration(보더·반경)을 읽는다', (tester) async {
      await _pumpAndOpenDialog(tester);

      final dialogFinder = find.byType(Dialog);
      final decorations = probeAllBoxDecorations(tester, dialogFinder);
      expect(
        decorations,
        isNotEmpty,
        reason: 'Dialog 패널 아래에서 BoxDecoration 을 하나도 못 찾음.',
      );

      // 패널 자신의 chrome — dialog.dart 의 패널 build(line ~675)가 만드는
      // decoration. 배경색이 있는 박스를 "그" 패널로 판정한다(포커스
      // 링처럼 border 유무로 가르는 대신 color 로 가르는 이유는, 패널은
      // 항상 배경을 채우지만 보더는 variant 에 따라 없을 수도 있어서다).
      final panel = decorations.firstWhere(
        (d) => d.color != null,
        orElse: () => throw StateError('Dialog 패널에서 배경색 있는 박스를 못 찾음.'),
      );
      expect(panel.borderRadius, isNotNull);
    });

    testWidgets('패널이 그림자를 그린다 (#3777, Core 0 · Flutter 0 이었음)', (
      tester,
    ) async {
      await _pumpAndOpenDialog(tester);

      final dialogFinder = find.byType(Dialog);
      final decorations = probeAllBoxDecorations(tester, dialogFinder);
      final panel = decorations.firstWhere(
        (d) => d.color != null,
        orElse: () => throw StateError('Dialog 패널에서 배경색 있는 박스를 못 찾음.'),
      );

      // CoreDialogStyle.defaultPanelBoxShadow(CoreShadow.xl)가 실제로
      // BoxDecoration.boxShadow 까지 도달했는지 — 개수만이 아니라 레이어
      // 형태(2-layer, 각 offset/blur)까지 확인해 "선언은 있는데 소비가
      // 없다"(theme-axis-composition.md 죽은 필드 패턴)를 배제한다.
      expect(
        panel.boxShadow,
        isNotNull,
        reason: 'Dialog 패널에 boxShadow 가 없음 — #3777 회귀.',
      );
      expect(panel.boxShadow, hasLength(CoreShadow.xl.length));
      for (var i = 0; i < CoreShadow.xl.length; i++) {
        final expected = CoreShadow.xl[i];
        final actual = panel.boxShadow![i];
        expect(actual.offset.dx, expected.offsetX);
        expect(actual.offset.dy, expected.offsetY);
        expect(actual.spreadRadius, expected.spreadRadius);
      }
    });

    testWidgets('제목 텍스트의 실효 TextStyle 을 읽는다', (tester) async {
      await _pumpAndOpenDialog(tester);

      final titleStyle = probeEffectiveTextStyle(
        tester,
        find.text('Probe Title'),
      );
      expect(titleStyle.fontWeight, isNotNull);
      expect(titleStyle.fontSize, isNotNull);
    });
  });
}
