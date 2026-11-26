/// Skeleton 리디자인 (디자이너 결정 2026-10-12) — 결정 표를 Core 기본값이 그대로
/// 진술하는지 본다. Flutter · Web · Figma 캔버스가 모두 이 기본값을 읽으므로,
/// 숫자는 여기서 한 번 고정한다.
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('Skeleton 리디자인 — 결정 표', () {
    test('맥동은 70% ↔ 100%, 왕복 한 번 2000ms, move 곡선', () {
      expect(CoreSkeletonStyle.defaultFromOpacity, CoreOpacity.opacity70);
      expect(CoreSkeletonStyle.defaultFromOpacity, 0.7);
      expect(CoreSkeletonStyle.defaultToOpacity, 1);
      expect(
        CoreSkeletonStyle.defaultDuration,
        const Duration(milliseconds: CoreDuration.ms2000),
      );
      expect(CoreSkeletonStyle.defaultCurve, CoreEasing.move);
    });

    test('반경 — 사각형 8, 원 full, 텍스트 줄 4', () {
      const rows = CoreSkeletonStyle.defaultsByVariant;
      expect(
        rows[CoreSkeletonVariant.rectangular]!.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
      expect(
        rows[CoreSkeletonVariant.circular]!.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      expect(
        rows[CoreSkeletonVariant.text]!.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
    });

    test('채움은 세 변형 모두 surface-container-highest', () {
      for (final variant in CoreSkeletonVariant.values) {
        expect(
          CoreSkeletonStyle.defaultsByVariant[variant]!.backgroundColor,
          const CoreColor.token(CoreColors.surfaceContainerHighest),
          reason: variant.name,
        );
      }
    });

    test('텍스트 — 줄 3 · 높이 12 · 간격 12 · 마지막 줄 0.6', () {
      expect(CoreSkeletonStyle.defaultLines, 3);
      expect(CoreSkeletonStyle.defaultLineHeight, CoreSize.size12);
      expect(CoreSkeletonStyle.defaultLineHeight, 12);
      expect(CoreSkeletonStyle.defaultLineSpacing, CoreSpace.space12);
      expect(CoreSkeletonStyle.defaultLineSpacing, 12);
      expect(CoreSkeletonStyle.defaultLastLineWidth, 0.6);
    });

    test('텍스트 세트 높이는 줄 3 × 12 + 간격 2 × 12 = 60, 마지막 줄 폭은 120', () {
      // 세트 폭 200 은 캔버스의 데모 폭이다 (Skeleton 의 폭은 호출자가 정한다).
      const demoWidth = 200;
      const lines = CoreSkeletonStyle.defaultLines;
      const lineHeight = CoreSkeletonStyle.defaultLineHeight;
      const lineSpacing = CoreSkeletonStyle.defaultLineSpacing;

      expect(lines * lineHeight + (lines - 1) * lineSpacing, 60);
      expect(demoWidth * CoreSkeletonStyle.defaultLastLineWidth, 120);
    });

    test('한 줄 피치는 막대 12 + 간격 12 = 24', () {
      expect(
        CoreSkeletonStyle.defaultLineHeight +
            CoreSkeletonStyle.defaultLineSpacing,
        24,
      );
    });
  });
}
