// SPIKE-5 (#3603) — Command 대상 probe PoC.
//
// 대상으로 고른 이유(이슈 본문): "리스트 아이템 라벨 — 확인된 font-weight
// 결함 대상, 중첩 텍스트". `.bmad/prd-*.md`가 확인한 버그: Flutter/Web 모두
// `CoreCommandStyle.defaultLabelStyle` → `CoreTextStyles.bodySmall` →
// `CoreFontWeight.regular`(=400) 토큰을 참조하는데도 Flutter 렌더가
// semibold 처럼 보였다 — 토큰 값 대조로는 안 잡히고 실제 렌더값 비교로만
// 드러난다는 것이 그 PRD 항목의 요지. 이 테스트는 `probeEffectiveTextStyle`
// 이 바로 그 "실제 렌더값"을 읽어낼 수 있는지를 검증한다.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' show FontWeight;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import 'widget_tree_probe.dart';

void main() {
  group('probe: Command 아이템 라벨 (SPIKE-5 / #3603)', () {
    testWidgets(
      '활성·비하이라이트 아이템 라벨의 실효 fontWeight 를 읽는다',
      (tester) async {
        await pumpTestApp(
          tester,
          Command(
            onSelect: (_) {},
            groups: const [
              CoreCommandGroup(
                items: [
                  CoreCommandItem(value: 'calendar', label: 'Calendar'),
                ],
              ),
            ],
          ),
        );

        final labelStyle = probeEffectiveTextStyle(
          tester,
          find.text('Calendar'),
        );

        // 잡으려는 회귀는 "라벨의 실효 굵기가 자기 토큰과 다르다" — 어딘가에서
        // 새어 들어온 굵기가 토큰을 덮는 것이다. 그래서 리터럴이 아니라 토큰을
        // 읽는다: 리터럴 400 은 그 누출과 "토큰이 결정으로 바뀌었다" 를 구별하지
        // 못하고, 실제로 label role 이 medium 으로 올라갔을 때 후자로 실패했다.
        //
        // 토큰을 읽어도 이빨은 그대로다 — `.medium()` 류 오버레이가 새어 들어오면
        // 실효 굵기가 토큰과 갈라지고 여기서 잡힌다. 그때는 이 테스트를 고치지
        // 말고 회귀 이슈로 보고한다.
        final tokenWeight = CoreCommandStyle.defaultLabelStyle
            .toValue(theme: Theme.of(tester.element(find.text('Calendar'))))
            .fontWeight;
        expect(
          labelStyle.fontWeight,
          equals(tokenWeight),
          reason:
              'Command 아이템 라벨 실효 fontWeight 가 자기 토큰과 다름 — '
              '어딘가에서 굵기가 새어 들어와 토큰을 덮고 있다.',
        );
        // fontSize 도 같이 읽어 probe 가 fontWeight 하나만 우연히 맞춘 게
        // 아니라 TextStyle 전체를 실제로 읽고 있음을 보인다.
        expect(labelStyle.fontSize, isNotNull);
      },
    );

    testWidgets(
      '역할명 → finder 는 텍스트 라벨만으로 충분 — 중첩 Row/Expanded 를 '
      '뚫고 들어갈 필요 없음',
      (tester) async {
        // Command 의 아이템은 Row(icon, Expanded(label), shortcut) 로
        // 중첩돼 있다(command.dart `_buildItem`). find.text() 는 그 중첩과
        // 무관하게 트리 전체에서 찾으므로, probe 선언에 "Row 의 두 번째
        // 자식" 같은 위치 기반 경로가 필요 없다 — README.md 의 "probe
        // 선언 방식" 판단 근거.
        await pumpTestApp(
          tester,
          Command(
            onSelect: (_) {},
            groups: const [
              CoreCommandGroup(
                items: [
                  CoreCommandItem(
                    value: 'search',
                    label: 'Search',
                    icon: Icon(LucideIcons.search),
                    shortcut: '⌘K',
                  ),
                ],
              ),
            ],
          ),
        );

        expect(find.text('Search'), findsOneWidget);
        final labelStyle = probeEffectiveTextStyle(tester, find.text('Search'));
        expect(labelStyle.fontWeight, isNotNull);
      },
    );
  });
}
