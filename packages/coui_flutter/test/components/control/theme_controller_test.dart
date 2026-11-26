/// Flutter `ThemeController` — 리디자인(Figma ❖ ThemeController)이 위젯까지
/// 도달했는지 본다.
///
/// Core 사다리 값 자체는 `coui_core` 테스트가 고정한다. 여기가 보는 것은
/// **Flutter 만 가진 배선**이다 — resolver 가 `theme.scaling` 을 곱해 그 값을
/// 굽는지, 팔레트가 색 수만큼 등분되는지, 고리가 호버 · 눌림 · 선택 · 잠금에서
/// 제 자리에 서는지, 눌림이 팔레트를 줄이는지, 두 잠금(그룹 · 개별)이 탭을
/// 실제로 막는지, 라벨과 시맨틱이 붙는지.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// ─── 픽스처 ───────────────────────────────────────────────────────

/// 2색 — 캔버스가 그리는 반원 둘.
const _kOcean = CoreThemeOption(
  name: 'Ocean',
  primaryColor: CoreColor.fromRGB(14, 165, 233),
  secondaryColor: CoreColor.fromRGB(2, 132, 199),
);

/// 4색 — 같은 원을 4등분.
const _kForest = CoreThemeOption(
  name: 'Forest',
  primaryColor: CoreColor.fromRGB(34, 197, 94),
  secondaryColor: CoreColor.fromRGB(22, 163, 74),
  accentColor: CoreColor.fromRGB(21, 128, 61),
  neutralColor: CoreColor.fromRGB(20, 83, 45),
);

/// 1색 — primary 만.
const _kSunset = CoreThemeOption(
  name: 'Sunset',
  primaryColor: CoreColor.fromRGB(249, 115, 22),
);

/// `md` 의 기준선 — 버튼 40 · 팔레트 32 · 칸 사이는 어느 단에서나 12.
const _kMdButtonSize = 40.0;
const _kMdPreviewSize = 32.0;
const _kButtonSpacing = 12.0;

/// 이름이 세 글자라 테스트 폰트(Ahem — 글자 폭이 크기와 같다)에서도 48 보다
/// 좁다 — "짧은 이름의 칸은 48" 을 재는 픽스처.
const _kSky = CoreThemeOption(
  name: 'Sky',
  primaryColor: CoreColor.fromRGB(56, 189, 248),
);
const _kFir = CoreThemeOption(
  name: 'Fir',
  primaryColor: CoreColor.fromRGB(22, 101, 52),
);

/// 스와치의 `Semantics` 노드 — 라벨이 옵션 이름인 버튼.
Finder _swatchSemantics(String name) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == name,
  description: 'Semantics(label: $name)',
);

/// 한 스와치 안의 팔레트 세그먼트 — 옵션 색 하나당 `ColoredBox` 하나.
Finder _segmentsOf(String name) => find.descendant(
  of: _swatchSemantics(name),
  matching: find.byType(ColoredBox),
);

/// 한 스와치의 버튼 박스 — 고리를 그리는 `OutlinedContainer`.
Finder _buttonOf(String name) => find.descendant(
  of: _swatchSemantics(name),
  matching: find.byType(OutlinedContainer),
);

/// 한 스와치의 팔레트 원 — `ClipRRect` 바로 아래 `SizedBox`.
Finder _paletteOf(String name) => find
    .descendant(
      of: find.descendant(
        of: _swatchSemantics(name),
        matching: find.byType(ClipRRect),
      ),
      matching: find.byType(SizedBox),
    )
    .first;

/// 한 스와치의 라벨 글자.
Finder _labelOf(String name) => find.text(name);

/// 마우스를 먼저 연결한다 — **마운트 전에** 해야 한다.
///
/// `Clickable` 안의 `FocusableActionDetector` 는 첫 post-frame 에서 포커스
/// 하이라이트 모드를 한 번 찍고, 그 뒤 마우스 이벤트만으로는 다시 찍지 않는다.
/// 마운트 뒤에 연결하면 터치 모드로 굳어 호버가 끝까지 보이지 않는다.
Future<TestGesture> _connectMouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: .mouse);
  await gesture.addPointer(location: .zero);
  addTearDown(gesture.removePointer);
  return gesture;
}

/// [gesture] 를 [name] 스와치의 가운데로 옮긴다.
Future<void> _hover(
  WidgetTester tester,
  TestGesture gesture,
  String name,
) async {
  await gesture.moveTo(tester.getCenter(_swatchSemantics(name)));
  await tester.pump();
}

/// resolver 를 실제 테마 컨텍스트 안에서 호출한다.
///
/// 하네스의 `Overlay(initialEntries:)` 는 첫 자식을 붙들고 있어 같은 테스트
/// 안에서 두 번째 `pumpTestApp` 이 새 `Builder` 를 마운트하지 않는다 —
/// 매번 빈 트리로 내렸다가 다시 올린다.
Future<ResolvedThemeController> _resolve(
  WidgetTester tester, {
  required CoreThemeControllerSize size,
  ThemeData? theme,
}) async {
  late ResolvedThemeController resolved;
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    theme: theme,
    Builder(
      builder: (context) {
        resolved = resolveThemeController(context, size: size);
        return const SizedBox.shrink();
      },
    ),
  );
  return resolved;
}

void main() {
  group('ThemeController resolver — 사이즈 사다리가 scaling 을 타고 굽힌다', () {
    testWidgets('preview / spacing 이 사다리 × theme.scaling 이다', (tester) async {
      // 사다리 (previewSize, buttonSpacing) — 칸 사이는 단과 무관하다.
      const ladder = {
        CoreThemeControllerSize.sm: (24.0, 12.0),
        CoreThemeControllerSize.md: (32.0, 12.0),
        CoreThemeControllerSize.lg: (40.0, 12.0),
      };
      // 기본 하네스는 `ThemeData()` → scaling 1. 곱셈이 실제로 일어나는지는
      // 아래 별도 케이스가 scaling 2 로 본다.
      for (final entry in ladder.entries) {
        final resolved = await _resolve(tester, size: entry.key);
        final (preview, spacing) = entry.value;
        expect(resolved.previewSize, preview, reason: '${entry.key} preview');
        expect(
          resolved.buttonSpacing,
          spacing,
          reason: '${entry.key} spacing',
        );
      }
    });

    testWidgets('버튼 박스도 사다리를 탄다 — 32 / 40 / 48, 팔레트는 안쪽 4', (tester) async {
      const ladder = {
        CoreThemeControllerSize.sm: CoreSize.size32,
        CoreThemeControllerSize.md: CoreSize.size40,
        CoreThemeControllerSize.lg: CoreSize.size48,
      };
      for (final entry in ladder.entries) {
        final resolved = await _resolve(tester, size: entry.key);
        expect(
          resolved.selectedContainerStyle.width,
          entry.value,
          reason: '${entry.key} selected width',
        );
        expect(
          resolved.unselectedContainerStyle.height,
          entry.value,
          reason: '${entry.key} unselected height',
        );
        // 팔레트 원은 어느 단에서든 고리 안쪽 4 — 버튼의 절반이 아니라
        // 고리가 둘러싸는 원으로 읽히게 하는 간격.
        expect(
          entry.value - resolved.previewSize,
          8,
          reason: '${entry.key} 팔레트는 양쪽에서 4씩 들어와 있다',
        );
        // 버튼은 원이다 — 모서리가 한 변의 절반.
        expect(
          resolved.selectedContainerStyle.borderRadius,
          CoreBorderRadius.all(entry.value / 2),
          reason: '${entry.key} 버튼 모서리',
        );
      }
    });

    testWidgets('scaling 2 면 dimensional 값이 두 배다', (tester) async {
      final resolved = await _resolve(
        tester,
        size: CoreThemeControllerSize.md,
        theme: const ThemeData(scaling: 2),
      );

      expect(resolved.previewSize, _kMdPreviewSize * 2);
      expect(resolved.buttonSpacing, _kButtonSpacing * 2);
      // 최소 폭도 곱해진다 — 칸의 바닥이 배율을 따라 자란다.
      expect(resolved.swatchMinWidth, CoreSize.size48 * 2);
      // 눌림 크기는 줄인 값의 두 배 — 줄이는 양과 크기를 각각 한 번만 곱한다.
      expect(resolved.pressedPreviewSize, (_kMdPreviewSize - 2) * 2);
      // 버튼 박스는 `OutlinedContainer` 가 스스로 scale 하지 않으므로
      // resolver 가 미리 곱해서 넘긴다.
      expect(resolved.selectedContainerStyle.width, _kMdButtonSize * 2);
    });

    testWidgets('md 는 40 / 32 / 12 이고 사다리와 default* 가 같은 숫자다', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        size: CoreThemeControllerSize.md,
      );

      expect(resolved.selectedContainerStyle.width, _kMdButtonSize);
      expect(resolved.previewSize, _kMdPreviewSize);
      expect(resolved.buttonSpacing, _kButtonSpacing);
      expect(resolved.swatchMinWidth, CoreSize.size48);
      // 사다리의 md 칸과 사이즈-무관 `default*` 가 같은 숫자를 말한다 —
      // 둘이 갈리면 어느 쪽이 기본인지 모호해진다.
      final md =
          CoreThemeControllerStyle.defaultsBySize[CoreThemeControllerSize.md]!;
      expect(md.buttonSize, CoreThemeControllerStyle.defaultButtonSize);
      expect(md.previewSize, CoreThemeControllerStyle.defaultPreviewSize);
      expect(md.buttonSpacing, CoreThemeControllerStyle.defaultButtonSpacing);
      expect(md.buttonRadius, CoreThemeControllerStyle.defaultButtonRadius);
      expect(CoreThemeControllerSize.defaultSize, CoreThemeControllerSize.md);
    });

    testWidgets('라벨은 단마다 labelSmall · labelMedium · labelLarge 롤을 굽는다', (
      tester,
    ) async {
      final sm = await _resolve(tester, size: CoreThemeControllerSize.sm);
      final md = await _resolve(tester, size: CoreThemeControllerSize.md);
      final lg = await _resolve(tester, size: CoreThemeControllerSize.lg);
      // 마지막 pump 의 트리에서 활성 테마를 읽는다 — 롤의 실제 fontSize 는
      // 테마 typography 가 정한다.
      final theme = Theme.of(tester.element(find.byType(SizedBox)));

      void expectRole(
        ResolvedThemeController r,
        CoreTextStyle role,
        String at,
      ) {
        expect(r.labelTextStyle.fontSize, role.fontSize, reason: '$at 크기');
        expect(
          r.labelTextStyle.fontWeight,
          fontWeightFromInt(role.fontWeight),
          reason: '$at 굵기',
        );
      }

      expectRole(sm, theme.typography.labelSmall, 'sm');
      expectRole(md, theme.typography.labelMedium, 'md');
      expectRole(lg, theme.typography.labelLarge, 'lg');
      // 세 롤이 같은 크기면 이 테스트는 어느 롤이 도착했는지 구분하지 못한다.
      expect(
        {
          theme.typography.labelSmall.fontSize,
          theme.typography.labelMedium.fontSize,
          theme.typography.labelLarge.fontSize,
        }.length,
        3,
        reason: '세 롤이 서로 다른 크기여야 단을 가릴 수 있다',
      );
      // 선택 · 잠금 라벨은 같은 롤에 색만 다르다.
      for (final r in [sm, md, lg]) {
        expect(r.selectedLabelTextStyle.fontSize, r.labelTextStyle.fontSize);
        expect(r.disabledLabelTextStyle.fontSize, r.labelTextStyle.fontSize);
        expect(
          {
            r.labelTextStyle.color,
            r.selectedLabelTextStyle.color,
            r.disabledLabelTextStyle.color,
          }.length,
          3,
          reason: '쉬는 · 선택 · 잠금 라벨은 서로 다른 잉크다',
        );
      }
    });

    testWidgets('caller override 가 사이즈 기본값 위에 얹힌다', (tester) async {
      late ResolvedThemeController resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveThemeController(
              context,
              size: CoreThemeControllerSize.sm,
              themeControllerStyle: const CoreThemeControllerStyle(
                pressedPreviewShrink: CoreSpace.space4,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      );

      // override 가 준 필드만 덮고 나머지 sm 기본값은 살아남는다.
      expect(resolved.previewSize, CoreSize.size24);
      expect(resolved.pressedPreviewSize, CoreSize.size24 - 4);
      expect(resolved.buttonSpacing, CoreSpace.space12);
    });
  });

  group('ThemeController 위젯 — 칸 폭과 간격', () {
    /// [name] 스와치 한 칸 — 버튼 · 간격 · 라벨을 쌓은 `Column`.
    Finder cellOf(String name) =>
        find.ancestor(of: find.text(name), matching: find.byType(Column)).first;

    testWidgets('짧은 이름의 칸은 라벨 길이와 무관하게 48 폭이다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kSky, _kFir],
          onThemeChanged: (_) {},
        ),
      );

      for (final name in ['Sky', 'Fir']) {
        expect(
          tester.getSize(cellOf(name)).width,
          CoreSize.size48,
          reason: name,
        );
      }
    });

    testWidgets('이름이 길면 그 칸만 넓어지고 이름은 말줄임 없이 다 보인다', (tester) async {
      const longName = 'Midnight Aurora Borealis';
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [
            _kSky,
            CoreThemeOption(
              name: longName,
              primaryColor: CoreColor.fromRGB(88, 28, 135),
            ),
          ],
          onThemeChanged: (_) {},
        ),
      );

      final cell = tester.getSize(cellOf(longName)).width;
      expect(cell, greaterThan(CoreSize.size48), reason: '긴 이름은 칸을 연다');
      expect(
        tester.getSize(cellOf('Sky')).width,
        CoreSize.size48,
        reason: '옆 칸은 그대로',
      );
      // 말줄임이 아니다 — 글자 상자가 칸 안에 온전히 들어간다.
      final label = tester.widget<Text>(find.text(longName));
      expect(label.overflow, isNot(TextOverflow.ellipsis));
      expect(
        tester.getSize(find.text(longName)).width,
        lessThanOrEqualTo(cell),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('버튼은 칸 가운데에 서고 칸 사이는 12 다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kSky, _kFir],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      final sky = cellOf('Sky');
      final fir = cellOf('Fir');
      expect(
        tester.getTopLeft(fir).dx - tester.getTopRight(sky).dx,
        resolved.buttonSpacing,
      );
      expect(resolved.buttonSpacing, _kButtonSpacing);
      // 버튼(40)은 48 칸의 가운데 — 양쪽에서 4 씩 들어와 있다.
      final button = find.descendant(
        of: _swatchSemantics('Sky'),
        matching: find.byType(OutlinedContainer),
      );
      expect(
        tester.getCenter(button).dx,
        tester.getCenter(sky).dx,
      );
    });
  });

  group('ThemeController resolver — 고리와 바탕', () {
    testWidgets('쉬는 스와치에는 고리도 바탕도 없다', (tester) async {
      final resolved = await _resolve(
        tester,
        size: CoreThemeControllerSize.md,
      );

      final rest = resolved.unselectedContainerStyle;
      expect(rest.borderWidth, 0);
      expect(rest.backgroundColor, CoreColor.transparent);
      // 바탕이 없으니 재질이 흐릴 것도 없다.
      expect(rest.surfaceBlur, 0);
      // 바탕이 없으니 캐스트가 비칠 것도 없다 — 명시적으로 빈 스택이다
      // (null 이면 컨테이너가 표면 스타일의 캐스트를 기여해, 투명한 몸체 뒤로
      // 단단한 도형이 비친다).
      expect(rest.boxShadow, isEmpty);
      expect(rest.boxShadow, isNotNull);
      for (final style in [
        resolved.selectedContainerStyle,
        resolved.hoverContainerStyle,
        resolved.disabledContainerStyle,
        resolved.disabledSelectedContainerStyle,
      ]) {
        expect(style.boxShadow, isNotNull);
        expect(style.boxShadow, isEmpty);
      }
    });

    testWidgets('바탕을 준 호출자는 재질을 막지 않는다', (tester) async {
      late ResolvedThemeController resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveThemeController(
              context,
              size: CoreThemeControllerSize.md,
              themeControllerStyle: const CoreThemeControllerStyle(
                buttonBackgroundColor: CoreColor.token(CoreColors.surface),
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      );

      expect(resolved.unselectedContainerStyle.surfaceBlur, isNull);
      expect(resolved.selectedContainerStyle.surfaceBlur, isNull);
      // 스타일의 캐스트도 막지 않는다 — 명시하지 않은 채로 둔다.
      expect(resolved.unselectedContainerStyle.boxShadow, isNull);
      expect(resolved.selectedContainerStyle.boxShadow, isNull);
    });

    testWidgets('선택 고리는 onSurface 2, 호버 고리는 outlineVariant 2 다', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        size: CoreThemeControllerSize.md,
      );

      expect(
        resolved.selectedContainerStyle.borderColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        resolved.selectedContainerStyle.borderWidth,
        CoreStrokeWidth.stroke2,
      );
      expect(
        resolved.hoverContainerStyle.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(resolved.hoverContainerStyle.borderWidth, CoreStrokeWidth.stroke2);
      // 두 고리는 눈으로 가려져야 한다.
      expect(
        resolved.hoverContainerStyle.borderColor,
        isNot(resolved.selectedContainerStyle.borderColor),
      );
    });

    testWidgets('잠긴 선택은 선택 굵기를 지키고 색만 disabled 로 내린다', (tester) async {
      final resolved = await _resolve(
        tester,
        size: CoreThemeControllerSize.md,
      );

      expect(
        resolved.disabledSelectedContainerStyle.borderWidth,
        resolved.selectedContainerStyle.borderWidth,
      );
      expect(
        resolved.disabledSelectedContainerStyle.borderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      // 잠긴 비선택은 쉬는 모양 그대로 — 고리 없음.
      expect(resolved.disabledContainerStyle.borderWidth, 0);
    });
  });

  group('ThemeController 위젯 — 팔레트 등분', () {
    testWidgets('2색은 세그먼트 둘, 4색은 넷, 1색은 하나', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest, _kSunset],
          onThemeChanged: (_) {},
        ),
      );

      expect(_segmentsOf('Ocean'), findsNWidgets(2));
      expect(_segmentsOf('Forest'), findsNWidgets(4));
      expect(_segmentsOf('Sunset'), findsOneWidget);
    });

    testWidgets('세그먼트는 옵션이 준 색을 그린다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(themes: const [_kOcean], onThemeChanged: (_) {}),
      );

      final boxes = tester
          .widgetList<ColoredBox>(_segmentsOf('Ocean'))
          .map((b) => b.color)
          .toList();
      final scheme = Theme.of(
        tester.element(find.byType(ThemeController)),
      ).colorScheme;
      expect(boxes, [
        scheme.resolve(_kOcean.primaryColor).toValue(),
        scheme.resolve(_kOcean.secondaryColor!).toValue(),
      ]);
    });

    testWidgets('세그먼트는 원 하나를 등분한다 — 폭이 previewSize / N', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        ThemeController(themes: const [_kForest], onThemeChanged: (_) {}),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      final segments = _segmentsOf('Forest');
      expect(segments, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        expect(
          tester.getSize(segments.at(i)).width,
          resolved.previewSize / 4,
          reason: '세그먼트 $i',
        );
      }
    });

    // `ColoredBox` 개수만 세는 단언은 세그먼트가 높이 0 으로 접혀 아무것도
    // 안 칠해져도 통과한다 — `Row` 가 자식에게 느슨한 세로 제약을 주면 자식 없는
    // `ColoredBox` 는 0 으로 줄어든다. 그려지는 것은 면적이므로 세로까지 본다.
    testWidgets('세그먼트는 팔레트 원의 전체 높이를 채운다 — 1 · 2 · 4색 모두', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest, _kSunset],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      for (final name in ['Ocean', 'Forest', 'Sunset']) {
        final segments = _segmentsOf(name);
        for (var i = 0; i < segments.evaluate().length; i++) {
          expect(
            tester.getSize(segments.at(i)).height,
            resolved.previewSize,
            reason: '$name 세그먼트 $i 의 높이',
          );
        }
      }
    });

    testWidgets('잠긴 스와치도 같은 면적을 disabled 색으로 채운다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: [_kForest.locked],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      final segments = _segmentsOf('Forest');
      expect(segments, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        final size = tester.getSize(segments.at(i));
        expect(size.height, resolved.previewSize, reason: '세그먼트 $i 높이');
        expect(size.width, resolved.previewSize / 4, reason: '세그먼트 $i 폭');
      }
    });
  });

  group('ThemeController 위젯 — 고리와 선택', () {
    testWidgets('선택 배지가 없다 — 선택돼도 check 글리프는 없다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is Icon && w.icon == LucideIcons.check),
        findsNothing,
      );
    });

    testWidgets('선택은 고리와 라벨 잉크로 보인다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Ocean')).containerStyle,
        resolved.selectedContainerStyle,
      );
      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Forest')).containerStyle,
        resolved.unselectedContainerStyle,
      );
      expect(
        tester.widget<Text>(_labelOf('Ocean')).style,
        resolved.selectedLabelTextStyle,
      );
      expect(
        tester.widget<Text>(_labelOf('Forest')).style,
        resolved.labelTextStyle,
      );
    });

    testWidgets('호버한 비선택 스와치에 옅은 고리가 생기고 떠나면 사라진다', (tester) async {
      final gesture = await _connectMouse(tester);
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      await _hover(tester, gesture, 'Forest');
      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Forest')).containerStyle,
        resolved.hoverContainerStyle,
      );
      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Ocean')).containerStyle,
        resolved.unselectedContainerStyle,
        reason: '옆 스와치는 쉬는 그대로',
      );
      // 호버만으로는 팔레트가 줄지 않는다 — 줄어드는 것은 눌림이다.
      expect(tester.getSize(_paletteOf('Forest')).width, resolved.previewSize);

      await gesture.moveTo(.zero);
      await tester.pump();
      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Forest')).containerStyle,
        resolved.unselectedContainerStyle,
      );
    });

    testWidgets('호버해도 선택된 스와치는 선택 고리를 지킨다', (tester) async {
      final gesture = await _connectMouse(tester);
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      await _hover(tester, gesture, 'Ocean');

      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Ocean')).containerStyle,
        resolved.selectedContainerStyle,
      );
    });

    testWidgets('누르는 동안 팔레트 원이 2 작아지고 놓으면 돌아온다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(themes: const [_kOcean], onThemeChanged: (_) {}),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );
      expect(resolved.pressedPreviewSize, resolved.previewSize - 2);

      final gesture = await tester.startGesture(
        tester.getCenter(_swatchSemantics('Ocean')),
        kind: .mouse,
      );
      await tester.pump();
      expect(
        tester.getSize(_paletteOf('Ocean')),
        Size.square(resolved.pressedPreviewSize),
      );
      // 눌리는 동안에도 옅은 고리가 선다.
      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Ocean')).containerStyle,
        resolved.hoverContainerStyle,
      );

      await gesture.up();
      await tester.pump();
      expect(
        tester.getSize(_paletteOf('Ocean')),
        Size.square(resolved.previewSize),
      );
    });

    testWidgets('잠긴 스와치는 호버에도 눌림에도 반응하지 않는다', (tester) async {
      final gesture = await _connectMouse(tester);
      await pumpTestApp(
        tester,
        ThemeController(
          themes: [_kOcean, _kForest.locked],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      await _hover(tester, gesture, 'Forest');
      await gesture.down(tester.getCenter(_swatchSemantics('Forest')));
      await tester.pump();

      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Forest')).containerStyle,
        resolved.disabledContainerStyle,
      );
      expect(tester.getSize(_paletteOf('Forest')).width, resolved.previewSize);
      await gesture.up();
    });
  });

  group('ThemeController 위젯 — 탭과 잠금', () {
    testWidgets('스와치를 탭하면 그 옵션 이름으로 onThemeChanged 가 불린다', (
      tester,
    ) async {
      final picked = <String>[];
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          onThemeChanged: picked.add,
        ),
      );

      await tester.tap(_swatchSemantics('Forest'));
      await tester.pump();

      expect(picked, ['Forest']);
    });

    testWidgets('enabled: false 면 어떤 스와치도 탭이 닿지 않는다', (tester) async {
      final picked = <String>[];
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          enabled: false,
          onThemeChanged: picked.add,
        ),
      );

      await tester.tap(_swatchSemantics('Ocean'));
      await tester.tap(_swatchSemantics('Forest'));
      await tester.pump();

      expect(picked, isEmpty);
    });

    testWidgets('CoreThemeOption(enabled: false) 는 그 하나만 막는다', (
      tester,
    ) async {
      final picked = <String>[];
      await pumpTestApp(
        tester,
        ThemeController(
          themes: [_kOcean, _kForest.locked],
          onThemeChanged: picked.add,
        ),
      );

      await tester.tap(_swatchSemantics('Forest'));
      await tester.pump();
      expect(picked, isEmpty, reason: '잠긴 스와치');

      await tester.tap(_swatchSemantics('Ocean'));
      await tester.pump();
      expect(picked, ['Ocean'], reason: '옆 스와치는 열려 있다');
    });

    testWidgets('잠긴 스와치는 팔레트 색을 버리고 disabledPreviewColor 로 칠한다', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: [_kOcean, _kForest.locked],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      // 잠긴 쪽 — 네 세그먼트 전부 같은 disabled 채움.
      final locked = tester
          .widgetList<ColoredBox>(_segmentsOf('Forest'))
          .map((b) => b.color)
          .toSet();
      expect(locked, {resolved.disabledPreviewColor});
      // 열린 쪽 — 자기 색이 남아 있다.
      final open = tester
          .widgetList<ColoredBox>(_segmentsOf('Ocean'))
          .map((b) => b.color)
          .toSet();
      expect(open, isNot(contains(resolved.disabledPreviewColor)));
    });

    testWidgets('잠긴 선택 스와치는 선택 고리의 굵기를 지키고 색만 내린다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          selectedTheme: 'Ocean',
          enabled: false,
          onThemeChanged: (_) {},
        ),
      );
      final resolved = resolveThemeController(
        tester.element(find.byType(ThemeController)),
        size: CoreThemeControllerSize.defaultSize,
      );

      // 선택은 잠겨도 살아남는다 — 고리가 그대로 있고 disabled 색이다.
      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Ocean')).containerStyle,
        resolved.disabledSelectedContainerStyle,
      );
      expect(
        tester.widget<OutlinedContainer>(_buttonOf('Forest')).containerStyle,
        resolved.disabledContainerStyle,
      );
      // 라벨은 선택 잉크가 아니라 disabled 잉크다.
      expect(
        tester.widget<Text>(_labelOf('Ocean')).style,
        resolved.disabledLabelTextStyle,
      );
    });
  });

  group('ThemeController 위젯 — 라벨과 시맨틱', () {
    testWidgets('각 스와치 아래에 옵션 이름이 렌더된다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest, _kSunset],
          onThemeChanged: (_) {},
        ),
      );

      expect(find.text('Ocean'), findsOneWidget);
      expect(find.text('Forest'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
    });

    testWidgets('라벨과 버튼 사이에 labelGapStyle 의 Gap 이 선다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean],
          size: CoreThemeControllerSize.lg,
          onThemeChanged: (_) {},
        ),
      );

      // 어느 단에서든 6 — 간격은 더 이상 크기를 따라 자라지 않는다.
      final gap = tester.widget<Gap>(find.byType(Gap));
      expect(gap.gapStyle?.size, CoreSpace.space6);
    });

    testWidgets('Semantics 라벨이 옵션 이름이고 selected / enabled 를 실어 나른다', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: [_kOcean, _kForest.locked],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );

      final ocean = tester.widget<Semantics>(_swatchSemantics('Ocean'));
      expect(ocean.properties.button, isTrue);
      expect(ocean.properties.selected, isTrue);
      expect(ocean.properties.enabled, isTrue);

      final forest = tester.widget<Semantics>(_swatchSemantics('Forest'));
      expect(forest.properties.selected, isFalse);
      expect(forest.properties.enabled, isFalse);
    });

    testWidgets('접근성 트리에도 옵션 이름이 버튼 라벨로 올라간다', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );

      // 라벨 텍스트 노드도 같은 문자열을 갖지만, 버튼 노드만 button + selected.
      expect(
        tester.getSemantics(_swatchSemantics('Ocean')),
        isSemantics(label: 'Ocean', isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(_swatchSemantics('Forest')),
        isSemantics(label: 'Forest', isButton: true, isSelected: false),
      );
      handle.dispose();
    });
  });

  group('ThemeController 위젯 — withStyle 체인', () {
    testWidgets('withStyle 패치가 렌더에 닿는다', (tester) async {
      await pumpTestApp(
        tester,
        ThemeController(
          themes: const [_kOcean],
          onThemeChanged: (_) {},
        ).withStyle(
          const CoreThemeControllerStyle(previewSize: CoreSize.size24),
        ),
      );

      // 팔레트 원 = ClipRRect 바로 아래 SizedBox.
      final preview = find.descendant(
        of: find.byType(ClipRRect),
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(preview.first), const Size.square(24));
    });
  });
}

extension on CoreThemeOption {
  /// `CoreThemeOption` 은 `copyWith` 가 없다 — 테스트용 최소 사본.
  CoreThemeOption get locked => CoreThemeOption(
    name: name,
    primaryColor: primaryColor,
    secondaryColor: secondaryColor,
    accentColor: accentColor,
    neutralColor: neutralColor,
    enabled: false,
  );
}
