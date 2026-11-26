import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/golden_test_app.dart';
import '../helpers/test_app.dart';

void main() {
  // 해결된 스킴을 쓴다. `const ThemeData()` 의 기본 스킴은 토큰 참조 상태라
  // colorConstraint 가 ARGB 를 읽는 순간 던진다 — 실제 앱은 팔레트에서 해결된
  // 스킴을 들고 있으므로 그 입력이 현실이다.
  const semantic = CouiSemanticColors.from(CouiColorPresets.source);
  final base = ThemeData(colorScheme: semantic.light.resolved(.light));

  group('applySurfaceStyle', () {
    test('기본 프리셋은 테마를 건드리지 않는다', () {
      final styled = applySurfaceStyle(
        base,
        surfaceStyle: .defaultStyle,
        highContrast: false,
      );

      expect(styled.geometry, base.geometry);
      expect(styled.colorScheme, base.colorScheme);
      expect(styled.typography, base.typography);
      expect(styled.surfaceOpacity, base.surfaceOpacity);
    });

    test('neoBrutalism 은 기하를 굽힌다', () {
      final styled = applySurfaceStyle(
        base,
        surfaceStyle: .neoBrutalism,
        highContrast: false,
      );

      expect(styled.geometry, isNot(base.geometry));
    });

    test('liquidGlass 는 표면 처리(블러·투명도)를 싣는다', () {
      final styled = applySurfaceStyle(
        base,
        surfaceStyle: .liquidGlass,
        highContrast: false,
      );

      // 이 프리셋은 두 역할 모두 같은 유리 재질이다 — 카드도 팝오버도
      // 반투명 + 블러. 평면 필드(content)와 functional 슬롯이 같은 값을
      // 들어야 한 쪽만 유리가 되는 회귀를 여기서 잡는다.
      expect(styled.functionalSurface, isNotNull);
      expect(styled.functionalSurface!.opacity.isOpaque, isFalse);
      expect(styled.functionalSurface!.blurRadius, greaterThan(0));

      expect(
        styled.surfaceOpacity,
        styled.functionalSurface!.opacityIn(styled),
      );
      expect(styled.surfaceBlur, styled.functionalSurface!.blurRadius);
    });

    group('고대비 — 축마다 다르게 작용한다', () {
      test('평상시에는 프리셋의 색 진술이 적용된다', () {
        final styled = applySurfaceStyle(
          base,
          surfaceStyle: .neoBrutalism,
          highContrast: false,
        );

        expect(styled.colorScheme, isNot(base.colorScheme));
      });

      test('고대비에서는 색 진술을 통째로 건너뛴다', () {
        // 이 seat 은 팔레트가 아니라 이미 완성된 테마를 들고 있어, 프리셋이
        // 굽힌 것 위로 대비를 다시 올릴 수 없다. 장식을 버리는 쪽이 안전한
        // 방향이다 — 고대비를 켠 사용자는 가독성을 요청한 것이다.
        final styled = applySurfaceStyle(
          base,
          surfaceStyle: .neoBrutalism,
          highContrast: true,
        );

        expect(styled.colorScheme, base.colorScheme);
      });

      test('고대비에서도 타이포는 유지된다', () {
        // weight 는 대비 레버가 아니라서, 지우면 접근성 이득 없이 프리셋만
        // 사라진다.
        //
        // 인스턴스 동등성이 아니라 **실제로 굵어졌는지**를 본다 —
        // `CoreTypography` 는 값 동등성이 없어 인스턴스 비교는 내용과 무관하게
        // 항상 다르다고 답한다(= 통과해도 아무것도 증명하지 못한다).
        final styled = applySurfaceStyle(
          base,
          surfaceStyle: .neoBrutalism,
          highContrast: true,
        );

        expect(
          styled.typography.bodyMedium.fontWeight,
          CoreFontWeight.semiBold,
        );
        expect(
          base.typography.bodyMedium.fontWeight,
          isNot(CoreFontWeight.semiBold),
        );
      });

      test('고대비에서도 기하는 유지된다', () {
        final styled = applySurfaceStyle(
          base,
          surfaceStyle: .neoBrutalism,
          highContrast: true,
        );

        expect(styled.geometry, isNot(base.geometry));
      });
    });
  });

  group('테스트 하네스가 같은 fold 를 경유한다', () {
    // 하네스가 fold 를 복제하면 프리셋 해석의 두 번째 출처가 생기고,
    // 검증 도구가 검증 대상과 다른 답을 내게 된다.
    testWidgets('surfaceStyle 이 하네스 테마에 반영된다', (tester) async {
      ThemeData? seen;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            seen = Theme.of(context);

            return const SizedBox.shrink();
          },
        ),
        theme: base,
        surfaceStyle: .neoBrutalism,
      );

      final expected = applySurfaceStyle(
        base,
        surfaceStyle: .neoBrutalism,
        highContrast: false,
      );

      expect(seen, isNotNull);
      expect(seen!.geometry, expected.geometry);
      expect(seen!.colorScheme, expected.colorScheme);
      expect(
        seen!.typography.bodyMedium.fontWeight,
        expected.typography.bodyMedium.fontWeight,
      );
    });

    testWidgets('하네스의 고대비도 같은 분기를 탄다', (tester) async {
      ThemeData? seen;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            seen = Theme.of(context);

            return const SizedBox.shrink();
          },
        ),
        theme: base,
        surfaceStyle: .neoBrutalism,
        highContrast: true,
      );

      // 색은 스킵, 타이포는 유지 — CoUIApp 과 같은 판정.
      expect(seen, isNotNull);
      expect(seen!.colorScheme, base.colorScheme);
      expect(
        seen!.typography.bodyMedium.fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    testWidgets('고대비 플래그가 MediaQuery 와 어긋나지 않는다', (tester) async {
      bool? seen;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            seen = MediaQuery.highContrastOf(context);

            return const SizedBox.shrink();
          },
        ),
        highContrast: true,
      );

      expect(seen, isTrue);
    });

    testWidgets('surfaceStyle 이 SurfaceStyleScope 로도 published 된다', (
      tester,
    ) async {
      CoreSurfaceStyleId? seen;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            seen = SurfaceStyleScope.of(context);

            return const SizedBox.shrink();
          },
        ),
        surfaceStyle: .claymorphism,
      );

      expect(seen, CoreSurfaceStyleId.claymorphism);
    });
  });

  group('하네스 방향은 뒤집을 수 있다', () {
    // 하네스가 방향을 고정하면 미러링에 대한 어떤 주장도 반증할 수 없다.
    testWidgets('기본은 ltr', (tester) async {
      TextDirection? seen;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            seen = Directionality.of(context);

            return const SizedBox.shrink();
          },
        ),
      );

      expect(seen, TextDirection.ltr);
    });

    testWidgets('rtl 로 뒤집힌다', (tester) async {
      TextDirection? seen;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            seen = Directionality.of(context);

            return const SizedBox.shrink();
          },
        ),
        textDirection: .rtl,
      );

      expect(seen, TextDirection.rtl);
    });

    testWidgets('golden 하네스도 방향을 받는다', (tester) async {
      TextDirection? seen;
      await tester.pumpWidget(
        buildGoldenTestApp(
          Builder(
            builder: (context) {
              seen = Directionality.of(context);

              return const SizedBox.shrink();
            },
          ),
          textDirection: .rtl,
        ),
      );

      expect(seen, TextDirection.rtl);
    });

    testWidgets('golden 하네스도 같은 fold 를 경유한다', (tester) async {
      ThemeData? seen;
      await tester.pumpWidget(
        buildGoldenTestApp(
          Builder(
            builder: (context) {
              seen = Theme.of(context);

              return const SizedBox.shrink();
            },
          ),
          theme: base,
          surfaceStyle: .neoBrutalism,
        ),
      );

      final expected = applySurfaceStyle(
        base,
        surfaceStyle: .neoBrutalism,
        highContrast: false,
      );

      expect(seen, isNotNull);
      expect(seen!.geometry, expected.geometry);
    });
  });
}
