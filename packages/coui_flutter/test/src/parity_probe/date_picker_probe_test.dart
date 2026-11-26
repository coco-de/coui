// SPIKE-5 (#3603) — DatePicker 대상 probe PoC.
//
// 대상으로 고른 이유(이슈 본문): "트리거 + 포커스 링 — 확인된 테두리 결함
// 대상, 상태 의존 chrome". `.bmad/prd-*.md`가 확인한 버그: DatePicker
// 트리거의 포커스 테두리 지오메트리가 Web(각지고 타이트)과 Flutter(둥글고
// 여유 있음)에서 다르게 렌더링됨(스크린샷 근거). 이 테스트는 그 지오메트리
// (border width / radius)를 실제로 읽어낼 수 있는지, 그리고 focus 상태를
// 흉내내지 않고도 읽을 수 있는지를 검증한다.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import 'widget_tree_probe.dart';

void main() {
  group('probe: DatePicker 트리거 + 포커스 링 (SPIKE-5 / #3603)', () {
    testWidgets(
      'dialog 모드(팝오버·캘린더 마운트 없음)에서 트리거의 실효 '
      'BoxDecoration 을 읽는다',
      (tester) async {
        // dialog 모드를 고른 이유 — popover 모드는 트리거가 Popover 로
        // 감싸이고 그 캘린더 콘텐츠가 (열리기 전엔 미마운트라 해도) 트리
        // 형태를 복잡하게 만든다. dialog 모드는 handleTap 이 실제 다이얼로그
        // 를 열기 전까지 트리거 Button 이 트리에 bare 로 존재해 probe 대상
        // 이 명확하다 — README.md "probe 선언 방식" 판단 근거 중 하나.
        await pumpTestApp(
          tester,
          DatePicker(
            mode: CorePromptMode.dialog,
            value: DateTime(2024),
          ),
        );

        final datePickerFinder = find.byType(DatePicker);
        expect(datePickerFinder, findsOneWidget);

        // 트리거는 읽기 전용 TextField 하나뿐 — dialog 모드는 Popover 로
        // 안 감싼다 (date_picker.dart 의 `(widget.mode != .dialog && _enabled)`
        // 분기).
        final triggerFinder = find.descendant(
          of: datePickerFinder,
          matching: find.byType(TextField),
        );
        expect(triggerFinder, findsOneWidget);

        final decorations = probeAllBoxDecorations(tester, triggerFinder);
        // TextField 자신의 chrome(배경/보더) 박스가 최소 하나는 있어야 한다
        // — 없으면 probe 가 잘못된 finder 를 가리킨 것.
        expect(
          decorations,
          isNotEmpty,
          reason: 'TextField 트리거 아래에서 BoxDecoration 을 하나도 못 찾음.',
        );

        final borderBox = decorations.firstWhere(
          (d) => d.border != null,
          orElse: () => throw StateError(
            '트리거 아래 어떤 BoxDecoration 도 border 를 갖지 않음.',
          ),
        );
        final border = borderBox.border! as Border;
        expect(border.top.width, greaterThan(0));
        expect(borderBox.borderRadius, isNotNull);
      },
    );

    testWidgets(
      '포커스 링의 geometry 는 focus 상태를 실제로 트리거하지 않아도 읽힌다 '
      '— FocusOutline 이 항상 그리고 opacity 로만 토글하기 때문',
      (tester) async {
        // FocusOutline.build (focus_outline.dart) 은 링의 BoxDecoration 을
        // `focused` 값과 무관하게 항상 만들고 AnimatedOpacity 로만 보이고
        // 안 보이고를 바꾼다 — 즉 이 PoC 는 실제 키보드 포커스를 주지
        // *않고도* 지오메트리를 읽을 수 있음을 보인다. 이건 probe 온보딩
        // 비용을 낮추는 실질적 발견이다: "포커스를 흉내내야 하나?" 라는
        // 질문에 이 컴포넌트만 봐선 "아니오" — 다만 이 사실이 다른
        // 컴포넌트에도 일반화된다고 단정하진 않는다(README.md 참조).
        await pumpTestApp(
          tester,
          DatePicker(
            mode: CorePromptMode.dialog,
            value: DateTime(2024),
          ),
        );

        final focusOutlineFinder = find.descendant(
          of: find.byType(DatePicker),
          matching: find.byType(FocusOutline),
        );
        expect(focusOutlineFinder, findsOneWidget);

        final decorations = probeAllBoxDecorations(tester, focusOutlineFinder);
        final ring = decorations.firstWhere(
          (d) => d.border != null,
          orElse: () => throw StateError('FocusOutline 아래 border 있는 박스를 못 찾음.'),
        );
        final ringBorder = ring.border! as Border;

        expect(ringBorder.top.width, greaterThan(0));
        expect(ring.borderRadius, isNotNull);
      },
    );
  });
}
