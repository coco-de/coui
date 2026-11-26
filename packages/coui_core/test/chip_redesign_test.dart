/// Chip 리디자인 — 캔버스가 정한 것을 Core 표가 그대로 진술하는지 본다.
/// (2026-09-08 사다리·disabled, 2026-10-13 꺼진 칩 무채·neutral 반전 선택,
/// 2026-10-14 색 축 둘로 정리·모양 축 variant, 2026-10-19 반경 6 · 8 · 10 ·
/// 패딩 8 · 10 · 12 · 라벨 역할 12 / 13 / 14 (500) · 아이콘 12 / 14 / 14)
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('Chip 리디자인 — 캔버스 실측과 같은 표', () {
    test('사다리는 셋 — 28 / 32 / 40, 아이콘 12 / 14 / 16', () {
      // 24 는 Badge 의 자리, 48·56 은 Button 의 자리 (8월 결정의 실행).
      const heights = {
        CoreChipSize.sm: CoreSize.size28,
        CoreChipSize.md: CoreSize.size32,
        CoreChipSize.lg: CoreSize.size40,
      };
      const icons = {
        CoreChipSize.sm: CoreIconSize.size12,
        CoreChipSize.md: CoreIconSize.size14,
        CoreChipSize.lg: CoreIconSize.size16,
      };
      // 닫기 글리프는 12 / 14 / 16, 그 버튼은 16 / 18 / 20 정사각 (#6068 —
      // 닫기 아이콘이 라벨보다 커 보여서 줄였다). 칸이 따로라 앞·뒤 슬롯이
      // 닫기 글리프를 끌고 가지 않는다.
      const closeGlyphs = {
        CoreChipSize.sm: CoreIconSize.size12,
        CoreChipSize.md: CoreIconSize.size14,
        CoreChipSize.lg: CoreIconSize.size16,
      };
      const closeBoxes = {
        CoreChipSize.sm: CoreSize.size16,
        CoreChipSize.md: CoreSize.size18,
        CoreChipSize.lg: CoreSize.size20,
      };
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        expect(row.minHeight, heights[size], reason: '${size.name} 높이');
        expect(
          row.leadingIconStyle!.size,
          icons[size],
          reason: '${size.name} 앞 아이콘',
        );
        expect(
          row.trailingIconStyle!.size,
          icons[size],
          reason: '${size.name} 뒤 아이콘',
        );
        expect(
          row.closeIconStyle!.size,
          closeGlyphs[size],
          reason: '${size.name} 닫기 글리프',
        );
        expect(
          row.closeButtonStyle!.width,
          closeBoxes[size],
          reason: '${size.name} 닫기 버튼 폭',
        );
        expect(
          row.closeButtonStyle!.height,
          closeBoxes[size],
          reason: '${size.name} 닫기 버튼 높이',
        );
      }
      // 고정 폭 칩에서 내용이 한쪽으로 쏠리지 않게 가운데 (#6068).
      expect(
        CoreChipStyle.defaultContentAlignment,
        CoreMainAxisAlignment.center,
      );
      expect(CoreChipSize.defaultSize, CoreChipSize.md);
    });

    test('색 축은 셋 — custom · neutral · primary, 표는 neutral · primary', () {
      // secondary · tertiary 는 기본 테마에서 primary 와 겹치거나(tertiary)
      // neutral 과 구분되지 않아(secondary) 축이 거짓 신호였다. 표는 seed 에서
      // 파생되는 custom 을 뺀 나머지 전부다.
      expect(CoreChipColor.values, [
        CoreChipColor.custom,
        CoreChipColor.neutral,
        CoreChipColor.primary,
      ]);
      expect(CoreChipStyle.defaultsByColor.keys.toSet(), {
        CoreChipColor.neutral,
        CoreChipColor.primary,
      });
      expect(CoreChipColor.defaultColor, CoreChipColor.neutral);
    });

    test('선택 안 됨 · low 는 색을 말하지 않는다 — 라벨은 전 색이 무채', () {
      // 꺼진 칩은 색과 무관하게 무채이고 색은 켜질 때만 나온다. 그래서 꺼진
      // low 변형은 Variant 끼리 같은 그림이다.
      for (final color in CoreChipStyle.defaultsByColor.keys) {
        expect(
          CoreChipStyle.defaultsByColor[color]!.lowUnselectedFg,
          const CoreColor.token(CoreColors.onSurfaceVariant),
          reason: color.name,
        );
      }
      // 테두리는 전 색이 공유하는 옅은 hairline.
      expect(
        CoreChipStyle.defaultLowUnselectedBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('neutral — 꺼진 high 는 옅은 테두리, 켜진 high 는 반전 채움', () {
      final neutral = CoreChipStyle.defaultsByColor[CoreChipColor.neutral]!;
      expect(
        neutral.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      // 꺼진 high 의 라벨은 그대로 on-surface — 바뀐 것은 테두리뿐.
      expect(neutral.unselectedFg, const CoreColor.token(CoreColors.onSurface));
      expect(
        neutral.selectedBg,
        const CoreColor.token(CoreColors.inverseSurface),
      );
      expect(
        neutral.selectedFg,
        const CoreColor.token(CoreColors.inverseOnSurface),
      );
      // 약한 선택은 트랙보다 두 단 위의 면이다.
      expect(
        neutral.lowSelectedBg,
        const CoreColor.token(CoreColors.surfaceContainerHighest),
      );
      expect(
        neutral.lowSelectedFg,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('primary — 켜진 색은 그대로, 꺼진 칩은 neutral 과 같은 무채', () {
      final v = CoreChipStyle.defaultsByColor[CoreChipColor.primary]!;
      expect(
        v.selectedBg,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        v.selectedFg,
        const CoreColor.token(CoreColors.onPrimary),
      );
      expect(
        v.lowSelectedBg,
        const CoreColor.token(CoreColors.primaryContainer),
      );
      expect(
        v.lowSelectedFg,
        const CoreColor.token(CoreColors.onPrimaryContainer),
      );
      // 꺼진 high 도 색을 말하지 않는다 — 예전에는 라벨·테두리가 primary 였다.
      expect(v.unselectedFg, const CoreColor.token(CoreColors.onSurface));
      expect(
        v.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('꺼진 칩의 모든 열은 색 행끼리 같다 — 색은 켜질 때만 나온다', () {
      // 열이 행마다 적혀 있는 것은 한 칩의 팔레트를 한곳에서 읽게 하려는
      // 것이지 행마다 다른 값을 허용하려는 것이 아니다. 한 행만 고치면 같은
      // 꺼진 칩이 색에 따라 달라지므로 여기서 묶는다.
      final rows = CoreChipStyle.defaultsByColor.values.toList();
      final first = rows.first;
      for (final row in rows) {
        expect(row.unselectedBg, first.unselectedBg, reason: '꺼진 채움');
        expect(row.unselectedFg, first.unselectedFg, reason: '꺼진 high 라벨');
        expect(row.lowUnselectedFg, first.lowUnselectedFg, reason: '꺼진 low 라벨');
        expect(
          row.unselectedPrefixFg,
          first.unselectedPrefixFg,
          reason: '꺼진 키 글자',
        );
        expect(row.borderColor, first.borderColor, reason: '꺼진 high 테두리');
        expect(row.disabledBg, first.disabledBg, reason: '비활성 채움');
        expect(row.disabledFg, first.disabledFg, reason: '비활성 라벨');
        expect(row.disabledBorderColor, first.disabledBorderColor);
      }
    });

    test('variant — outlined 가 기본이고 filled 의 채움은 surface-container-high', () {
      expect(CoreChipVariant.values, [
        CoreChipVariant.outlined,
        CoreChipVariant.filled,
      ]);
      expect(CoreChipVariant.defaultVariant, CoreChipVariant.outlined);
      // surface-container 는 흰 바탕 대비 1.09 라 칩이 모양으로 읽히지 않는다.
      expect(
        CoreChipStyle.defaultFilledUnselectedBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      // outlined 의 꺼진 채움은 투명 — filled 가 바꾸는 것은 이것뿐이다.
      for (final row in CoreChipStyle.defaultsByColor.values) {
        expect(row.unselectedBg, CoreColor.transparent);
      }
    });

    test('filled 채움은 override 가 merge · copyWith · == 를 통과한다', () {
      const override = CoreColor.token(CoreColors.surfaceContainerHighest);
      const style = CoreChipStyle(filledUnselectedBackgroundColor: override);
      expect(
        const CoreChipStyle().merge(style).filledUnselectedBackgroundColor,
        override,
      );
      expect(
        const CoreChipStyle().copyWith(
          filledUnselectedBackgroundColor: override,
        ),
        style,
      );
      expect(style, isNot(const CoreChipStyle()));
      expect(style.hashCode, isNot(const CoreChipStyle().hashCode));
    });

    test('Theme — variantStyles 는 모양, colorStyles 는 색이 키이고 ==에 든다', () {
      const style = CoreChipStyle(minHeight: 50);
      const base = CoreChipTheme();
      const byVariant = CoreChipTheme(
        variantStyles: {CoreChipVariant.filled: style},
      );
      const byColor = CoreChipTheme(
        colorStyles: {CoreChipColor.primary: style},
      );
      expect(byVariant, isNot(base));
      expect(byColor, isNot(base));
      expect(byVariant, isNot(byColor));
      // 같은 값의 다른 맵 인스턴스는 같고 해시도 같다 — 맵 자체의 동일성을
      // 해시하면 ==가 참인 두 테마가 서로 다른 해시를 낸다.
      final copyOfVariant = CoreChipTheme(
        variantStyles: Map.of(byVariant.variantStyles!),
      );
      final copyOfColor = CoreChipTheme(
        colorStyles: Map.of(byColor.colorStyles!),
      );
      expect(copyOfVariant, byVariant);
      expect(copyOfVariant.hashCode, byVariant.hashCode);
      expect(copyOfColor, byColor);
      expect(copyOfColor.hashCode, byColor.hashCode);
    });

    test('본문 라벨은 모든 모드에서 기준을 넘는다 — 테두리는 대상이 아니다', () {
      // 꺼진 low · 꺼진 high · neutral 강한 선택 · 약한 선택의 라벨. 4.5:1,
      // 고대비 모드는 7:1. (정확한 수치는 팔레트가 움직이면 함께 움직이므로
      // 기준선만 고정한다.)
      const pairs = [
        (CoreColors.onSurfaceVariant, CoreColors.surface, '꺼진 low'),
        (CoreColors.onSurface, CoreColors.surface, '꺼진 high'),
        (
          CoreColors.inverseOnSurface,
          CoreColors.inverseSurface,
          'neutral 강한 선택',
        ),
        (CoreColors.onSurface, CoreColors.surfaceContainer, '약한 선택'),
        // filled 의 꺼진 라벨은 회색 채움 위에 앉는다. 채움 자체는 라벨이
        // 칩을 알려 주므로 1.4.11 대상이 아니다.
        (
          CoreColors.onSurfaceVariant,
          CoreColors.surfaceContainerHigh,
          'filled 꺼진 low',
        ),
        (
          CoreColors.onSurface,
          CoreColors.surfaceContainerHigh,
          'filled 꺼진 high',
        ),
      ];
      const source = CouiColorPresets.source;
      final modes = {
        'light': (source.light(), 4.5),
        'dark': (source.dark(), 4.5),
        'high-contrast light': (source.highContrastLight(), 7.0),
        'high-contrast dark': (source.highContrastDark(), 7.0),
      };
      for (final MapEntry(key: mode, value: (scheme, floor)) in modes.entries) {
        for (final (fg, bg, name) in pairs) {
          final ratio = CoreContrast.ratio(
            scheme.resolve(CoreColor.token(fg)),
            scheme.resolve(CoreColor.token(bg)),
          );
          expect(
            ratio,
            greaterThanOrEqualTo(floor),
            reason: '$mode / $name: ${ratio.toStringAsFixed(2)}:1',
          );
        }
        // 켜진 neutral 칩은 페이지와 구분된다 — 이전 채움은 1.15:1 이었다.
        final fill = CoreContrast.ratio(
          scheme.resolve(const CoreColor.token(CoreColors.inverseSurface)),
          scheme.resolve(const CoreColor.token(CoreColors.surface)),
        );
        expect(fill, greaterThan(3.0), reason: '$mode / 선택 채움 대 페이지');
      }
    });

    test('선택된 disabled 는 보더가 없다 — 채움색 보더가 아니라', () {
      // 디자이너 사본: State=disabled · Selected=true 는 stroke 없음. 채움과
      // 같은 색의 1px 보더는 픽셀로는 같아 보여도 캔버스에는 stroke 로
      // 기록된다 — 그래서 "보더 = 채움" 이 아니라 투명 sentinel 이다.
      // 색과 무관하게 한 값이라 표의 열이 아니라 Style 의 공유 default.
      expect(
        CoreChipStyle.defaultDisabledSelectedBorderColor,
        CoreColor.transparent,
      );
      for (final color in CoreChipStyle.defaultsByColor.keys) {
        final v = CoreChipStyle.defaultsByColor[color]!;
        expect(
          CoreChipStyle.defaultDisabledSelectedBorderColor,
          isNot(v.disabledSelectedBg),
          reason: '${color.name}: 보더가 채움색이면 캔버스에 stroke 가 남는다',
        );
      }
      // 미선택 disabled 는 여전히 hairline — 두 줄이 갈리는 지점.
      expect(
        CoreChipStyle
            .defaultsByColor[CoreChipColor.neutral]!
            .disabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      // 인스턴스 override 가 merge 를 통과한다 (6자리 중 Core 두 자리).
      const override = CoreColor.token(CoreColors.outline);
      final merged = const CoreChipStyle().merge(
        const CoreChipStyle(disabledSelectedBorderColor: override),
      );
      expect(merged.disabledSelectedBorderColor, override);
      expect(
        const CoreChipStyle().copyWith(disabledSelectedBorderColor: override),
        const CoreChipStyle(disabledSelectedBorderColor: override),
      );
    });

    test('라벨 사다리는 역할이다 — 12 / 13 / 14 가 labelSmall / Medium / Large', () {
      // `fontSize` 스칼라를 역할 위에 덮던 자리. 역할로 진술하면 그
      // 역할의 자간 · 행간이 크기와 함께 따라온다 — 세 라벨 역할은 모두
      // 20px 아래라 자간 −1%, 행간 140% 를 같이 진술한다. 굵기도 역할의
      // 것이다 — 아래 '라벨은 역할의 500' 테스트.
      const roles = {
        CoreChipSize.sm: CoreTextStyles.labelSmall,
        CoreChipSize.md: CoreTextStyles.labelMedium,
        CoreChipSize.lg: CoreTextStyles.labelLarge,
      };
      const sizes = {
        CoreChipSize.sm: CoreFontSize.s12,
        CoreChipSize.md: CoreFontSize.s13,
        CoreChipSize.lg: CoreFontSize.s14,
      };
      final base = CoreTextStyles.labelLarge.read(CoreTypography.coui);
      for (final size in CoreChipSize.values) {
        final slot = CoreChipStyle.defaultsBySize[size]!.labelStyle!;
        expect(slot.token, roles[size], reason: '${size.name} 역할');
        // 역할이 통째로 말한다 — 스칼라 overlay 는 없다.
        expect(slot.fontSize, isNull, reason: '${size.name} fontSize overlay');
        final role = slot.token!.read(CoreTypography.coui);
        expect(role.fontSize, sizes[size], reason: '${size.name} 크기');
        // 역할 자신의 굵기는 셋이 같다(500).
        expect(role.fontWeight, base.fontWeight, reason: '${size.name} 굵기');
        expect(role.lineHeight, base.lineHeight, reason: '${size.name} 행간');
        // 사다리 base 위에 merge 해도 역할이 이긴다 (merge: other.token 우선).
        expect(
          CoreChipStyle.defaultLabelStyle.merge(slot).token,
          roles[size],
          reason: '${size.name} merge',
        );
      }
      // 자간은 세 역할이 같다 — 크기가 20px 아래인 라벨은 모두 −1%.
      for (final token in roles.values) {
        expect(
          token.read(CoreTypography.coui).letterSpacing,
          CoreLetterSpacing.tight10,
          reason: '${token.name} 자간',
        );
      }
    });

    test('라벨은 역할의 500 — 기본값과 세 크기 행 모두 굵기를 덮지 않는다', () {
      // 옆의 Button 라벨과 같은 굵기. 기본값은 기본 크기(md) 행과 같은
      // 역할이다 — 행을 건너뛴 호출자가 떨어지는 자리.
      expect(CoreChipStyle.defaultLabelStyle.fontWeight, isNull);
      expect(
        CoreChipStyle.defaultLabelStyle.token,
        CoreChipStyle
            .defaultsBySize[CoreChipSize.defaultSize]!
            .labelStyle!
            .token,
      );
      for (final size in CoreChipSize.values) {
        final slot = CoreChipStyle.defaultsBySize[size]!.labelStyle!;
        expect(slot.fontWeight, isNull, reason: size.name);
        expect(slot.fontSize, isNull, reason: '${size.name} fontSize');
        expect(slot.letterSpacing, isNull, reason: '${size.name} 자간');
        expect(slot.token, isNotNull, reason: '${size.name} 역할');
        // 합성한 최종 라벨이 그리는 굵기도 역할의 500 이다.
        expect(
          CoreTypography.coui
              .resolve(CoreChipStyle.defaultLabelStyle.merge(slot))
              .fontWeight,
          CoreFontWeight.medium,
          reason: '${size.name} merge',
        );
      }
    });

    test('ChipInput 배지는 Chip sm 행의 라벨을 그대로 그린다 (#5831)', () {
      // 배지는 자기 라벨을 진술하지 않는다: 글자 크기 · 굵기 · 자간은 Chip
      // sm 행의 역할(labelSmall)이 정한다. 예전처럼 14px · 400 을 박아 두면
      // 같은 크기의 Chip 과 라벨이 갈린다.
      expect(CoreChipInputStyle.defaultChipStyle.labelStyle, isNull);
      expect(CoreChipInputStyle.chipSize, CoreChipSize.sm);

      final smRow = CoreChipStyle.defaultsBySize[CoreChipSize.sm]!;
      final composed = const CoreChipStyle()
          .merge(smRow)
          .merge(CoreChipInputStyle.defaultChipStyle);
      final finalLabel = CoreChipStyle.defaultLabelStyle.merge(
        composed.labelStyle,
      );
      expect(finalLabel.token, CoreTextStyles.labelSmall);
      expect(finalLabel.fontSize, isNull, reason: '크기는 역할이 정한다');
    });

    test('ChipInput 배지의 지우기 버튼은 16 정사각, 글리프 12', () {
      final close = CoreChipInputStyle.defaultChipStyle.closeButtonStyle!;
      expect(close.width, CoreSize.size16);
      expect(close.height, CoreSize.size16);
      expect(
        CoreChipInputStyle.defaultChipStyle.closeIconStyle!.size,
        CoreIconSize.size12,
      );
    });

    test('disabled 는 두 줄 — 선택은 채우고, 미선택은 surface 위 hairline', () {
      for (final color in CoreChipStyle.defaultsByColor.keys) {
        final v = CoreChipStyle.defaultsByColor[color]!;
        expect(
          v.disabledBg,
          const CoreColor.token(CoreColors.surface),
          reason: '$color 미선택 bg',
        );
        expect(
          v.disabledSelectedBg,
          const CoreColor.token(CoreColors.disabledContainer),
          reason: '$color 선택 bg',
        );
        expect(
          v.disabledFg,
          const CoreColor.token(CoreColors.disabledContent),
          reason: '$color fg',
        );
        expect(
          v.disabledBorderColor,
          const CoreColor.token(CoreColors.disabledOutline),
          reason: '$color 테두리',
        );
      }
      // custom seed 도 같은 두 줄을 탄다.
      expect(
        CoreChipStyle.defaultCustomDisabledUnselectedBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        CoreChipStyle.defaultCustomDisabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });
  });
}
