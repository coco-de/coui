/// Web `ThemeController` — 리디자인(Figma ❖ ThemeController)이 Web 쪽에도
/// 도달했는지 본다.
///
/// Core 사다리 값 자체는 플랫폼 무관이라 `coui_core` 테스트가 고정한다.
/// 여기가 보는 것은 **Web 만 가진 배선**이다 — resolver 가 그 값을 rem 으로
/// 굽는지, 위젯이 색 수만큼 세그먼트 `<div>` 를 내는지, 버튼이 바탕 없는
/// 고리인지, 호버 · 눌림 고리와 눌림 팔레트가 scoped 규칙으로 나가 알맞은
/// 버튼에만 붙는지, 두 잠금(그룹 · 개별)이 `aria-disabled` 와 disabled
/// 채움으로 나타나는지, 라벨이 typography 롤 class 와 상태의 잉크를 받는지.
library;

import 'package:coui_web/coui_web.dart';
// theme_controller_style.dart is not re-exported by the barrel (the
// resolver is internal chrome) — import it directly for resolver-level
// assertions.
import 'package:coui_web/src/components/control/theme_controller/theme_controller_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

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

/// `md` 의 기준선 (logical px) — 버튼 40 · 팔레트 32 · 칸 사이는 어느 단에서나 12.
const _kMdButtonSize = 40.0;
const _kMdPreviewSize = 32.0;
const _kButtonSpacing = 12.0;

/// logical px → 이 resolver 가 emit 하는 rem 문자열.
String _rem(double px) => '${px / kRemDivisor}rem';

/// 간격 단계 → 이 resolver 가 emit 하는 `--coui-space-*` 변수 참조.
String _spaceVar(double step) => 'var(--coui-space-${step.toInt()})';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedThemeController _resolve(
  ComponentTester tester, {
  CoreThemeControllerSize size = CoreThemeControllerSize.defaultSize,
  CoreThemeControllerStyle? style,
}) => resolveThemeController(
  _themedContext(tester),
  size: size,
  themeControllerStyle: style,
);

Map<String, String> _props(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

// ─── DOM 헬퍼 ─────────────────────────────────────────────────────

/// 렌더된 `Clickable` 루트 — 스와치 하나에 하나, `aria-label` 이 옵션 이름.
Finder _swatchButton(String name) => find.byComponentPredicate(
  (c) => c is DomComponent && c.attributes?['aria-label'] == name,
  description: '<div role="button" aria-label="$name">',
);

/// 한 스와치 안의 팔레트 세그먼트 `<div>` — `flex-1` 이고 색을 실은 것.
Finder _segmentsOf(String name, ResolvedThemeController resolved) =>
    find.descendant(
      of: _swatchButton(name),
      matching: find.byComponentPredicate(
        (c) =>
            c is DomComponent &&
            c.tag == 'div' &&
            c.classes == resolved.segment.className &&
            (c.styles?.properties.containsKey('background-color') ?? false),
        description: 'segment <div class="${resolved.segment.className}">',
      ),
    );

/// 한 스와치의 버튼 박스 `<div>` — `Clickable` 루트 바로 아래, 고리를 싣는 것.
Finder _boxOf(String name) => find.descendant(
  of: _swatchButton(name),
  matching: find.byComponentPredicate(
    (c) =>
        c is DomComponent &&
        c.tag == 'div' &&
        (c.styles?.properties.containsKey('border-style') ?? false),
    description: 'button box <div style="border-style: solid">',
  ),
);

/// 박스가 입은 class 목록.
Set<String> _boxClasses(String name) =>
    ((_boxOf(name).evaluate().single.component as DomComponent).classes ?? '')
        .split(' ')
        .where((c) => c.isNotEmpty)
        .toSet();

ResolvedThemeControllerRules _rules(
  ComponentTester tester, {
  CoreThemeControllerSize size = CoreThemeControllerSize.defaultSize,
  CoreThemeControllerStyle? style,
}) => resolveThemeControllerRules(
  _themedContext(tester),
  size: size,
  themeControllerStyle: style,
);

String _attr(Finder finder, String key) =>
    (finder.evaluate().single.component as DomComponent).attributes?[key] ?? '';

Set<String> _segmentFills(String name, ResolvedThemeController resolved) => {
  for (final e in _segmentsOf(name, resolved).evaluate())
    (e.component as DomComponent).styles!.properties['background-color']!,
};

void main() {
  group('Web ThemeController resolver — 사이즈 사다리가 rem 으로 굽힌다', () {
    testComponents('preview 원의 inline 폭/높이가 24 / 32 / 40 px 의 rem 이다', (
      tester,
    ) async {
      const ladder = {
        CoreThemeControllerSize.sm: CoreSize.size24,
        CoreThemeControllerSize.md: CoreSize.size32,
        CoreThemeControllerSize.lg: CoreSize.size40,
      };
      for (final entry in ladder.entries) {
        final resolved = _resolve(tester, size: entry.key);
        final preview = _props(resolved.preview);
        expect(preview['width'], _rem(entry.value), reason: '${entry.key} 폭');
        expect(
          preview['height'],
          _rem(entry.value),
          reason: '${entry.key} 높이',
        );
        // 원으로 잘라야 N 열이 하나의 원으로 읽힌다.
        expect(preview['border-radius'], isNotNull);
        expect(
          resolved.preview.className,
          contains(WebLayout.overflowHidden),
          reason: '${entry.key} clip',
        );
        // 눌림 규칙이 찾아올 표지.
        expect(
          resolved.preview.className.split(' '),
          contains(kThemeSwatchPaletteMarker),
          reason: '${entry.key} palette marker',
        );
      }
    });

    testComponents('root gap · button 도 사다리를 탄다', (tester) async {
      // (buttonSpacing, buttonSize)
      const ladder = {
        CoreThemeControllerSize.sm: (CoreSpace.space12, CoreSize.size32),
        CoreThemeControllerSize.md: (CoreSpace.space12, CoreSize.size40),
        CoreThemeControllerSize.lg: (CoreSpace.space12, CoreSize.size48),
      };
      for (final entry in ladder.entries) {
        final resolved = _resolve(tester, size: entry.key);
        final (spacing, button) = entry.value;
        expect(
          _props(resolved.root)['gap'],
          _spaceVar(spacing),
          reason: '${entry.key} gap',
        );
        expect(
          _props(resolved.selectedButton)['width'],
          _rem(button),
          reason: '${entry.key} button',
        );
        // 버튼은 원이다 — 모서리가 한 변의 절반.
        expect(
          _props(resolved.selectedButton)['border-radius'],
          CoreBorderRadius.all(button / 2).toValue(),
          reason: '${entry.key} radius',
        );
      }
    });

    testComponents('md 는 40 / 32 / 12 — 칸 사이가 12 로 열린다', (tester) async {
      // 기본 사이즈가 곧 md — 인자 없이 부른 값이 md 의 값이어야 한다.
      final resolved = _resolve(tester);

      expect(_props(resolved.unselectedButton)['width'], _rem(_kMdButtonSize));
      expect(_props(resolved.preview)['width'], _rem(_kMdPreviewSize));
      expect(_props(resolved.root)['gap'], _spaceVar(_kButtonSpacing));
    });

    testComponents('스와치 칸은 min-width 48 이다 — 폭이 아니라 바닥', (tester) async {
      final resolved = _resolve(tester);
      final swatch = _props(resolved.swatch);

      expect(swatch['min-width'], _rem(CoreSize.size48));
      // 폭을 정하지 않아야 긴 이름이 자기 칸만 연다.
      expect(swatch.containsKey('width'), isFalse);
      expect(swatch.containsKey('max-width'), isFalse);
      // 버튼과 라벨은 칸 가운데에 선다.
      expect(resolved.swatch.className, contains(WebLayout.itemsCenter));
      // 바닥은 단과 무관하다.
      for (final size in CoreThemeControllerSize.values) {
        expect(
          _props(_resolve(tester, size: size).swatch)['min-width'],
          _rem(CoreSize.size48),
          reason: '$size',
        );
      }
    });

    testComponents('swatchMinWidth override 가 바닥을 옮긴다', (tester) async {
      final resolved = _resolve(
        tester,
        style: const CoreThemeControllerStyle(swatchMinWidth: CoreSize.size64),
      );

      expect(_props(resolved.swatch)['min-width'], _rem(CoreSize.size64));
    });

    testComponents('세그먼트는 flex-1 이고 enabled 면 색을 위젯에 맡긴다', (
      tester,
    ) async {
      final resolved = _resolve(tester);

      // N 개가 원을 N 등분하는 유일한 규칙 — 폭을 정하지 않는다.
      expect(resolved.segment.className, WebLayout.flex1);
      expect(_props(resolved.segment).containsKey('width'), isFalse);
      // 색은 per-iteration 규칙이라 resolver 의 enabled 세그먼트엔 없다.
      expect(resolved.segment.inlineStyles, isNull);
      // 잠기면 팔레트를 버리고 disabled 채움을 굽는다 — 위젯은 색을 얹지
      // 않는다.
      expect(resolved.disabledSegment.className, WebLayout.flex1);
      expect(
        _props(resolved.disabledSegment)['background-color'],
        CoreThemeControllerStyle.defaultDisabledPreviewColor.toValue(),
      );
    });

    testComponents('버튼은 바탕 없는 고리다 — 쉬면 테두리가 0, 재질도 없다', (tester) async {
      final resolved = _resolve(tester);
      final rest = _props(resolved.unselectedButton);

      expect(rest['border-width'], strokeWidthCss(0));
      // 바탕이 없으니 표면 표지도, 채움을 알리는 변수도 달지 않는다.
      for (final marker in webSurfaceMarkerFor(.content)) {
        expect(
          resolved.unselectedButton.className.split(' '),
          isNot(contains(marker)),
        );
      }
      expect(
        rest.keys.where((k) => k.startsWith('--coui-surface')),
        isEmpty,
        reason: '바탕이 없는 버튼은 채움 변수를 알리지 않는다',
      );
    });

    testComponents('바탕을 준 호출자의 버튼은 표면 표지를 단다', (tester) async {
      final resolved = _resolve(
        tester,
        style: const CoreThemeControllerStyle(
          buttonBackgroundColor: CoreColor.token(CoreColors.surface),
        ),
      );

      final classes = resolved.unselectedButton.className.split(' ');
      for (final marker in webSurfaceMarkerFor(.content)) {
        expect(classes, contains(marker));
      }
      expect(
        _props(resolved.unselectedButton).keys.where(
          (k) => k.startsWith('--coui-surface'),
        ),
        isNotEmpty,
      );
    });

    testComponents('선택 고리는 onSurface · 선택 굵기(2)다', (tester) async {
      final resolved = _resolve(tester);
      final selected = _props(resolved.selectedButton);

      expect(selected['border-width'], 'var(--coui-stroke-width-2)');
      expect(
        selected['border-color'],
        CoreThemeControllerStyle.defaultSelectedBorderColor.toValue(),
      );
      expect(
        CoreThemeControllerStyle.defaultSelectedBorderColor,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    testComponents('disabled 버튼은 선택 폭(2)을 지키고 색만 disabledOutline 으로', (
      tester,
    ) async {
      final resolved = _resolve(tester);
      final selected = _props(resolved.selectedButton);
      final disabledSelected = _props(resolved.disabledSelectedButton);
      final disabled = _props(resolved.disabledButton);

      expect(
        disabledSelected['border-width'],
        selected['border-width'],
        reason: '잠긴 선택 스와치는 여전히 선택된 것',
      );
      expect(
        disabledSelected['border-width'],
        isNot(equals(disabled['border-width'])),
      );
      final disabledOutline = CoreThemeControllerStyle
          .defaultDisabledBorderColor
          .toValue();
      expect(disabledSelected['border-color'], disabledOutline);
      expect(disabled['border-color'], disabledOutline);
      expect(selected['border-color'], isNot(equals(disabledOutline)));
    });

    testComponents('라벨 chrome 이 단의 롤 class 와 상태의 잉크를 싣는다', (tester) async {
      const roles = {
        CoreThemeControllerSize.sm: CoreTextStyles.labelSmall,
        CoreThemeControllerSize.md: CoreTextStyles.labelMedium,
        CoreThemeControllerSize.lg: CoreTextStyles.labelLarge,
      };
      String ink(CoreColor color) => 'text-${color.tailwindColor}';
      for (final entry in roles.entries) {
        final resolved = _resolve(tester, size: entry.key);
        final roleClass = 'text-${entry.value.name}';
        final rest = resolved.label.className.split(' ');
        final selected = resolved.selectedLabel.className.split(' ');
        final disabled = resolved.disabledLabel.className.split(' ');
        for (final classes in [rest, selected, disabled]) {
          expect(classes, contains(roleClass), reason: '${entry.key} 롤');
        }
        // 한 상태에 잉크 class 는 하나뿐이다.
        expect(rest, contains(ink(CoreThemeControllerStyle.defaultLabelColor)));
        expect(
          selected,
          contains(ink(CoreThemeControllerStyle.defaultSelectedLabelColor)),
        );
        expect(
          selected,
          isNot(contains(ink(CoreThemeControllerStyle.defaultLabelColor))),
        );
        expect(
          disabled,
          contains(ink(CoreThemeControllerStyle.defaultDisabledLabelColor)),
        );
      }
    });

    testComponents('labelGapStyle 은 어느 단에서나 6 이다', (tester) async {
      for (final size in CoreThemeControllerSize.values) {
        expect(
          _resolve(tester, size: size).labelGapStyle.size,
          CoreSpace.space6,
          reason: '$size',
        );
      }
    });

    testComponents('caller override 가 사이즈 기본값 위에 얹힌다', (tester) async {
      final resolved = _resolve(
        tester,
        size: CoreThemeControllerSize.sm,
        style: const CoreThemeControllerStyle(
          selectedBorderWidth: CoreStrokeWidth.stroke3,
        ),
      );

      expect(
        _props(resolved.selectedButton)['border-width'],
        'var(--coui-stroke-width-3)',
      );
      // override 가 준 필드만 덮고 나머지 sm 기본값은 살아남는다.
      expect(_props(resolved.preview)['width'], _rem(CoreSize.size24));
      expect(_props(resolved.root)['gap'], _spaceVar(CoreSpace.space12));
    });
  });

  group('Web ThemeController 위젯 — 칸 폭', () {
    testComponents('렌더된 스와치 칸이 min-width 를 싣는다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = _resolveFromTree(tester);

      final cells = find.byComponentPredicate(
        (c) =>
            c is DomComponent &&
            c.classes == resolved.swatch.className &&
            c.styles?.properties['min-width'] == _rem(CoreSize.size48),
        description: 'swatch cell <div style="min-width: 3rem">',
      );
      expect(cells, findsNComponents(2));
    });
  });

  group('Web ThemeController — 호버 · 눌림 scoped 규칙', () {
    testComponents('호버 · 눌림 고리는 !important 로 테두리를 덮는다', (tester) async {
      final rules = _rules(tester);

      expect(rules.ringClass, startsWith('co-theme-swatch-ring-'));
      // 쉬는 테두리가 인라인이라 이 규칙만 !important 가 필요하다.
      expect(
        rules.css,
        contains(
          '.${rules.ringClass}:hover,.${rules.ringClass}:active'
          '{border-width:var(--coui-stroke-width-2)!important;'
          'border-color:'
          '${CoreThemeControllerStyle.defaultHoverBorderColor.toValue()}'
          '!important;}',
        ),
      );
    });

    testComponents('눌림은 팔레트를 (지름 − 2) / 지름 으로 줄인다', (tester) async {
      // 24 → 22, 32 → 30, 40 → 38 — 지름에서 2 를 뺀 값의 비율.
      const scale = {
        CoreThemeControllerSize.sm: '0.9167',
        CoreThemeControllerSize.md: '0.9375',
        CoreThemeControllerSize.lg: '0.95',
      };
      for (final entry in scale.entries) {
        final rules = _rules(tester, size: entry.key);
        expect(
          rules.css,
          contains(
            '.${rules.pressClass}:active .$kThemeSwatchPaletteMarker'
            '{transform:scale(${entry.value});}',
          ),
          reason: '${entry.key}',
        );
      }
    });

    testComponents('같은 모양은 한 class 를 나눈다 — 이름은 값에서 온다', (tester) async {
      final sm = _rules(tester, size: CoreThemeControllerSize.sm);
      final md = _rules(tester);
      final again = _rules(tester);

      // 고리는 세 단이 같고, 눌림 비율은 단마다 다르다.
      expect(sm.ringClass, md.ringClass);
      expect(sm.pressClass, isNot(md.pressClass));
      // 서버와 클라이언트가 같은 이름을 내야 하므로 호출마다 같다.
      expect(again.ringClass, md.ringClass);
      expect(again.pressClass, md.pressClass);
      expect(again.css, md.css);
    });

    testComponents('굵기 0 이면 고리 규칙이, 줄임 0 이면 눌림 규칙이 빠진다', (tester) async {
      final noRing = _rules(
        tester,
        style: const CoreThemeControllerStyle(hoverBorderWidth: 0),
      );
      expect(noRing.ringClass, isEmpty);
      expect(noRing.css, isNot(contains('!important')));
      expect(noRing.pressClass, isNotEmpty);

      final noPress = _rules(
        tester,
        style: const CoreThemeControllerStyle(pressedPreviewShrink: 0),
      );
      expect(noPress.pressClass, isEmpty);
      expect(noPress.css, isNot(contains('transform')));
      expect(noPress.ringClass, isNotEmpty);

      final neither = _rules(
        tester,
        style: const CoreThemeControllerStyle(
          hoverBorderWidth: 0,
          pressedPreviewShrink: 0,
        ),
      );
      expect(neither.css, isEmpty);
    });

    testComponents('줄이는 양을 바꾸면 눌림 비율과 class 가 같이 바뀐다', (tester) async {
      final two = _rules(tester);
      final four = _rules(
        tester,
        style: const CoreThemeControllerStyle(
          pressedPreviewShrink: CoreSpace.space4,
        ),
      );

      // (32 − 4) / 32
      expect(
        four.css,
        contains('{transform:scale(0.875);}'),
      );
      expect(four.pressClass, isNot(two.pressClass));
      expect(four.ringClass, two.ringClass);
    });
  });

  group('Web ThemeController 위젯 — 팔레트 등분', () {
    testComponents('2색은 세그먼트 둘, 4색은 넷, 1색은 하나', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest, _kSunset],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = _resolveFromTree(tester);

      expect(_segmentsOf('Ocean', resolved), findsNComponents(2));
      expect(_segmentsOf('Forest', resolved), findsNComponents(4));
      expect(_segmentsOf('Sunset', resolved), findsOneComponent);
    });

    testComponents('세그먼트는 옵션이 준 색을 inline 으로 싣는다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(themes: const [_kOcean], onThemeChanged: (_) {}),
      );
      final resolved = _resolveFromTree(tester);

      expect(_segmentFills('Ocean', resolved), {
        _kOcean.primaryColor.toValue(),
        _kOcean.secondaryColor!.toValue(),
      });
    });
  });

  group('Web ThemeController 위젯 — 고리와 선택', () {
    testComponents('선택 배지가 없다 — 선택돼도 Icon 이 없다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testComponents('선택은 aria-pressed 로 알려진다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );

      // 칠해진 것과 무관하게 보조기술이 읽는 선택 표시.
      expect(_attr(_swatchButton('Ocean'), 'aria-pressed'), 'true');
      expect(_attr(_swatchButton('Forest'), 'aria-pressed'), 'false');
    });

    testComponents('선택 고리는 진짜 border 다 — 강제 색 모드가 recolor 하는 것', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );
      final resolved = _resolveFromTree(tester);

      // 그림자가 아니라 border 라서 forced-colors 에서 시스템 색으로 남는다.
      final ocean =
          (_boxOf('Ocean').evaluate().single.component as DomComponent)
              .styles!
              .properties;
      expect(ocean['border-style'], 'solid');
      expect(
        ocean['border-width'],
        _props(resolved.selectedButton)['border-width'],
      );
      expect(ocean.containsKey('box-shadow'), isFalse);
      // 선택 안 된 스와치는 쉬면 테두리가 0 이다.
      final forest =
          (_boxOf('Forest').evaluate().single.component as DomComponent)
              .styles!
              .properties;
      expect(forest['border-width'], strokeWidthCss(0));
    });

    testComponents('규칙 class 는 알맞은 버튼에만 붙는다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: [_kOcean, _kForest, _kSunset.locked],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );
      final rules = _rulesFromTree(tester);

      // 비선택 · 활성 — 고리도 눌림도.
      expect(
        _boxClasses('Forest'),
        containsAll([rules.ringClass, rules.pressClass]),
      );
      // 선택 — 이미 강한 고리가 있어 고리 규칙은 받지 않고, 눌림은 받는다.
      expect(_boxClasses('Ocean'), contains(rules.pressClass));
      expect(_boxClasses('Ocean'), isNot(contains(rules.ringClass)));
      // 잠김 — 아무 규칙도 받지 않는다.
      expect(_boxClasses('Sunset'), isNot(contains(rules.ringClass)));
      expect(_boxClasses('Sunset'), isNot(contains(rules.pressClass)));
    });

    testComponents('규칙 <style> 이 root 안에 한 번 나간다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          onThemeChanged: (_) {},
        ),
      );
      final rules = _rulesFromTree(tester);

      final styleTag = find.byComponentPredicate(
        (c) => c is DomComponent && c.tag == 'style',
        description: '<style>',
      );
      expect(styleTag, findsOneComponent);
      expect(rules.css, isNotEmpty);
    });

    testComponents('모든 스와치가 잠기면 규칙 class 가 한 버튼에도 붙지 않는다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          enabled: false,
          onThemeChanged: (_) {},
        ),
      );
      final rules = _rulesFromTree(tester);

      for (final name in ['Ocean', 'Forest']) {
        expect(_boxClasses(name), isNot(contains(rules.ringClass)));
        expect(_boxClasses(name), isNot(contains(rules.pressClass)));
      }
    });

    testComponents('라벨은 선택 여부에 따라 잉크가 다르다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          selectedTheme: 'Ocean',
          onThemeChanged: (_) {},
        ),
      );
      final resolved = _resolveFromTree(tester);

      Finder labelOf(String name, WebElementChrome chrome) => find.ancestor(
        of: find.text(name),
        matching: find.byComponentPredicate(
          (c) => c is DomComponent && c.classes == chrome.className,
        ),
      );
      expect(labelOf('Ocean', resolved.selectedLabel), findsOneComponent);
      expect(labelOf('Forest', resolved.label), findsOneComponent);
    });
  });

  group('Web ThemeController 위젯 — 잠금', () {
    testComponents('enabled: false 면 모든 스와치가 aria-disabled 다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest],
          enabled: false,
          onThemeChanged: (_) {},
        ),
      );

      expect(_attr(_swatchButton('Ocean'), 'aria-disabled'), 'true');
      expect(_attr(_swatchButton('Forest'), 'aria-disabled'), 'true');
    });

    testComponents('CoreThemeOption(enabled: false) 는 그 하나만 잠근다', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: [_kOcean, _kForest.locked],
          onThemeChanged: (_) {},
        ),
      );

      expect(_attr(_swatchButton('Forest'), 'aria-disabled'), 'true');
      expect(_attr(_swatchButton('Ocean'), 'aria-disabled'), '');
    });

    testComponents('잠긴 스와치의 세그먼트는 disabledSegment 채움이다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: [_kOcean, _kForest.locked],
          onThemeChanged: (_) {},
        ),
      );
      final resolved = _resolveFromTree(tester);
      final disabledFill = _props(
        resolved.disabledSegment,
      )['background-color']!;

      // 잠긴 쪽 — 네 세그먼트 전부 같은 disabled 채움, 옵션 색은 없다.
      expect(_segmentsOf('Forest', resolved), findsNComponents(4));
      expect(_segmentFills('Forest', resolved), {disabledFill});
      // 열린 쪽 — 자기 색이 남아 있다.
      expect(_segmentFills('Ocean', resolved), isNot(contains(disabledFill)));
    });

    testComponents('잠긴 선택 스와치는 선택 고리의 굵기를 지키고 라벨은 disabled 잉크다', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean],
          selectedTheme: 'Ocean',
          enabled: false,
          onThemeChanged: (_) {},
        ),
      );
      final resolved = _resolveFromTree(tester);

      final box = (_boxOf('Ocean').evaluate().single.component as DomComponent)
          .styles!
          .properties;
      expect(
        box['border-width'],
        _props(resolved.disabledSelectedButton)['border-width'],
      );
      expect(
        box['border-color'],
        _props(resolved.disabledSelectedButton)['border-color'],
      );
      final label = find.ancestor(
        of: find.text('Ocean'),
        matching: find.byComponentPredicate(
          (c) =>
              c is DomComponent &&
              c.classes == resolved.disabledLabel.className,
        ),
      );
      expect(label, findsOneComponent);
    });
  });

  group('Web ThemeController 위젯 — 라벨', () {
    testComponents('각 스와치 아래에 옵션 이름이 렌더된다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean, _kForest, _kSunset],
          onThemeChanged: (_) {},
        ),
      );

      expect(find.text('Ocean'), findsOneComponent);
      expect(find.text('Forest'), findsOneComponent);
      expect(find.text('Sunset'), findsOneComponent);
    });

    testComponents('라벨 div 가 단의 typography 롤 class 를 받는다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean],
          size: CoreThemeControllerSize.lg,
          onThemeChanged: (_) {},
        ),
      );

      final labelDiv = find.ancestor(
        of: find.text('Ocean'),
        matching: find.byComponentPredicate(
          (c) =>
              c is DomComponent &&
              c.tag == 'div' &&
              (c.classes
                      ?.split(' ')
                      .contains(
                        'text-${CoreTextStyles.labelLarge.name}',
                      ) ??
                  false),
          description: '<div class="… text-label-large …">',
        ),
      );
      expect(labelDiv, findsOneComponent);
    });

    testComponents('라벨과 버튼 사이에 labelGapStyle 의 Gap 이 선다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean],
          size: CoreThemeControllerSize.lg,
          onThemeChanged: (_) {},
        ),
      );

      // 어느 단에서든 6 — 간격은 더 이상 크기를 따라 자라지 않는다.
      final gap = find.byType(Gap).evaluate().single.component as Gap;
      expect(gap.gapStyle?.size, CoreSpace.space6);
    });
  });

  group('Web ThemeController 위젯 — withStyle / copyWith', () {
    test('copyWith 가 size 와 enabled 를 떨어뜨리지 않는다', () {
      final original = ThemeController(
        themes: const [_kOcean],
        size: CoreThemeControllerSize.lg,
        enabled: false,
        onThemeChanged: (_) {},
      );

      final copy = original.copyWith(selectedTheme: 'Ocean');
      expect(copy.size, CoreThemeControllerSize.lg);
      expect(copy.enabled, isFalse);
      expect(copy.selectedTheme, 'Ocean');
    });

    testComponents('withStyle 패치가 렌더에 닿는다', (tester) async {
      pumpWithTheme(
        tester,
        ThemeController(
          themes: const [_kOcean],
          onThemeChanged: (_) {},
        ).withStyle(
          const CoreThemeControllerStyle(previewSize: CoreSize.size24),
        ),
      );

      final preview = find.byComponentPredicate(
        (c) =>
            c is DomComponent &&
            c.tag == 'div' &&
            c.styles?.properties['width'] == _rem(CoreSize.size24) &&
            (c.classes?.contains(WebLayout.overflowHidden) ?? false),
        description: 'preview <div style="width: 1.5rem">',
      );
      expect(preview, findsOneComponent);
    });
  });
}

/// 규칙 resolver 를 이미 렌더된 트리의 컨텍스트에서 부른다 — `_rules` 는
/// 트리를 다시 pump 하므로 렌더된 DOM 을 본 뒤에는 이쪽을 쓴다.
ResolvedThemeControllerRules _rulesFromTree(
  ComponentTester tester, {
  CoreThemeControllerSize size = CoreThemeControllerSize.defaultSize,
}) {
  final element = find.byType(ThemeController).evaluate().single;
  return resolveThemeControllerRules(element, size: size);
}

/// resolver 를 이미 렌더된 트리의 컨텍스트에서 다시 부른다 — 위젯이 읽은
/// 것과 같은 chrome 문자열로 DOM 을 대조하기 위해.
ResolvedThemeController _resolveFromTree(
  ComponentTester tester, {
  CoreThemeControllerSize size = CoreThemeControllerSize.defaultSize,
}) {
  final element = find.byType(ThemeController).evaluate().single;
  return resolveThemeController(element, size: size);
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
