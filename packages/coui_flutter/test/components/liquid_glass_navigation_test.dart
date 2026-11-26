import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

const _glassAppBar = CoreAppBarStyle(surfaceStyle: .liquidGlass);
const _glassNavBar = CoreNavigationBarStyle(surfaceStyle: .liquidGlass);
const _items = [
  CoreNavigationBarItem<Widget>.destination(label: 'Home'),
  CoreNavigationBarItem<Widget>.destination(label: 'Search'),
  CoreNavigationBarItem<Widget>.destination(label: 'Library'),
];

void main() {
  for (final preset in [CoreThemePresets.light, CoreThemePresets.dark]) {
    testWidgets(
      'glass selection uses the palette accent and respects authored colours in ${preset.brightness}',
      (tester) async {
        late ResolvedNavigationBar selected;
        late ResolvedNavigationBar custom;
        late Color accent;
        await pumpTestApp(
          tester,
          Builder(
            builder: (context) {
              accent = Theme.of(context).colorScheme
                  .resolve(const CoreColor.token(CoreColors.primary))
                  .toValue();
              selected = resolveNavigationBar(
                context,
                mode: .bar,
                variant: .standard,
                navigationBarStyle: _glassNavBar,
              );
              custom = resolveNavigationBar(
                context,
                mode: .bar,
                variant: .standard,
                navigationBarStyle: const CoreNavigationBarStyle(
                  surfaceStyle: .liquidGlass,
                  iconStyle: CoreIconStyle(color: CoreColor(0xFF123456)),
                  selectedBackgroundColor: CoreColor(0xFFABCDEF),
                ),
              );
              return const SizedBox();
            },
          ),
          theme: ThemeData.fromCore(preset),
        );
        expect(selected.selectedForegroundColor, accent);
        expect(selected.selectedIconColor, accent);
        expect(selected.selectedBackgroundColor.a, greaterThan(0));
        expect(
          selected.refraction,
          CoreNavigationBarStyle.glassRestingRefraction,
        );
        expect(
          selected.selectionRefraction,
          CoreNavigationBarStyle.glassSelectionRefraction,
        );
        expect(custom.selectedIconColor, const Color(0xFF123456));
        expect(custom.selectedBackgroundColor, const Color(0xFFABCDEF));
      },
    );
  }

  testWidgets(
    'component material follows theme, variant, instance precedence',
    (
      tester,
    ) async {
      late ResolvedAppBar resolved;
      Widget probe(CoreAppBarStyle? style) => Builder(
        builder: (context) {
          resolved = resolveAppBar(
            context,
            variant: .compact,
            appBarStyle: style,
          );
          return const SizedBox();
        },
      );
      const componentTheme = CoreComponentTheme(
        appBar: CoreAppBarTheme(
          style: _glassAppBar,
          variantStyles: {
            .compact: CoreAppBarStyle(surfaceStyle: .defaultStyle),
          },
        ),
      );
      await pumpTestApp(tester, probe(null), componentTheme: componentTheme);
      expect(resolved.backgroundColor.a, 1);
      expect(resolved.material?.blurRadius, isNull);
      await tester.pumpWidget(const SizedBox());
      await pumpTestApp(
        tester,
        probe(_glassAppBar),
        componentTheme: componentTheme,
      );
      expect(resolved.backgroundColor.a, lessThan(1));
      expect(resolved.material?.blurRadius, greaterThan(0));
      expect(resolved.refraction, isNotNull);
    },
  );

  testWidgets('explicit default removes all inherited glass terms', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const AppBar(
        title: Text('Opaque'),
        appBarStyle: CoreAppBarStyle(surfaceStyle: .defaultStyle),
      ),
      surfaceStyle: .liquidGlass,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    final surface = tester.widget<SurfaceBlur>(find.byType(SurfaceBlur));
    expect(surface.refraction, isNull);
    expect(surface.surfaceSheen, isNull);
  });

  testWidgets('SurfaceTheme replaces material and preserves other theme axes', (
    tester,
  ) async {
    final base = ThemeData.fromCore(CoreThemePresets.dark).copyWith(
      scaling: () => 1.25,
      tapSoundEnabled: () => false,
    );
    late ThemeData local;
    await pumpTestApp(
      tester,
      SurfaceTheme(
        surfaceStyle: .liquidGlass,
        child: Builder(
          builder: (context) {
            local = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
      theme: base,
    );
    expect(local.colorScheme, base.colorScheme);
    expect(local.typography, base.typography);
    // 재질 단계는 기하에 테마 밝기를 싣는다 — 다크면 그림자 세기만 바뀐다.
    // `fromCore` 로 바로 만든 base 는 그 단계를 거치지 않아 밝기가 light 다.
    expect(local.geometry, base.geometry.atBrightness(base.coreBrightness));
    expect(local.scaling, 1.25);
    expect(local.tapSoundEnabled, isFalse);
    expect(local.surfaceFor(.functional)?.blurRadius, greaterThan(0));
    expect(local.surfaceFor(.functional)?.opacityIn(local), .6);
  });

  testWidgets('local glass cannot undo reduced transparency or high contrast', (
    tester,
  ) async {
    late ResolvedNavigationBar resolved;
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) {
          resolved = resolveNavigationBar(
            context,
            mode: .bar,
            variant: .standard,
            navigationBarStyle: _glassNavBar,
          );
          return const SizedBox();
        },
      ),
      theme: const ThemeData(reduceTransparency: true),
      highContrast: true,
    );
    expect(resolved.backgroundColor.a, 1);
    expect(resolved.surfaceBlur, isNull);
    expect(resolved.refraction, isNull);
    expect(resolved.selectionRefraction, isNull);
  });

  testWidgets(
    'reduced motion keeps resting glass but removes the optical lens',
    (tester) async {
      late ResolvedNavigationBar resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveNavigationBar(
              context,
              mode: .bar,
              variant: .standard,
              navigationBarStyle: _glassNavBar,
            );
            return const SizedBox();
          },
        ),
        disableAnimations: true,
      );
      expect(
        resolved.refraction,
        CoreNavigationBarStyle.glassRestingRefraction,
      );
      expect(resolved.selectionRefraction, isNull);
      expect(resolved.duration, Duration.zero);
    },
  );

  testWidgets('glass clips to the floating bar, excluding its margin', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const SizedBox(
        width: 360,
        child: NavigationBar(
          items: _items,
          labelMode: .all,
          selectedIndex: 0,
          navigationBarStyle: _glassNavBar,
        ),
      ),
    );
    final pill = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('coui-navigation-selection')),
    );
    expect((pill.decoration as BoxDecoration).color!.a, greaterThan(0));
    final blur = find.byType(BackdropFilter);
    expect(blur, findsOneWidget);
    expect(tester.getSize(blur).width, 344);
    expect(
      tester.getTopLeft(blur).dx,
      tester.getTopLeft(find.byType(NavigationBar)).dx + 8,
    );
  });

  for (final direction in TextDirection.values) {
    testWidgets('one selection capsule moves and retargets in $direction', (
      tester,
    ) async {
      var selected = 0;
      late StateSetter update;
      await pumpTestApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SizedBox(
              width: 360,
              child: NavigationBar(
                items: _items,
                labelMode: .all,
                selectedIndex: selected,
                onSelected: (index) => setState(() => selected = index),
                navigationBarStyle: _glassNavBar,
              ),
            );
          },
        ),
        textDirection: direction,
      );
      final pill = find.byKey(const ValueKey('coui-navigation-selection'));
      expect(pill, findsOneWidget);
      final start = tester.getTopLeft(pill).dx;
      await tester.tap(find.text('Library'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final mid = tester.getTopLeft(pill).dx;
      expect(direction == .ltr ? mid > start : mid < start, isTrue);
      update(() => selected = 1);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(pill, findsOneWidget);
      expect(
        tester.getCenter(pill).dx,
        closeTo(tester.getCenter(find.byType(NavigationBar)).dx, .1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reduced motion snaps selection without a running ticker', (
    tester,
  ) async {
    var selected = 0;
    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 360,
          child: NavigationBar(
            items: _items,
            labelMode: .all,
            selectedIndex: selected,
            onSelected: (index) => setState(() => selected = index),
            navigationBarStyle: _glassNavBar,
          ),
        ),
      ),
      disableAnimations: true,
    );
    await tester.tap(find.text('Library'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('narrow, empty and mixed bars keep their fallback layouts', (
    tester,
  ) async {
    for (final items in [
      <CoreNavigationBarItem<Widget>>[],
      _items,
      [
        const CoreNavigationBarItem<Widget>.destination(label: 'Home'),
        const CoreNavigationBarItem<Widget>.divider(),
        const CoreNavigationBarItem<Widget>.destination(label: 'Search'),
      ],
    ]) {
      await pumpTestApp(
        tester,
        SizedBox(
          width: 100,
          child: NavigationBar(
            items: items,
            labelMode: .all,
            selectedIndex: 0,
            navigationBarStyle: _glassNavBar,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('coui-navigation-selection')),
        findsNothing,
      );
    }
  });

  testWidgets('floating scaffold lets each bar own its material pass', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const Scaffold(
        floatingHeader: true,
        floatingFooter: true,
        headers: [AppBar(title: Text('Title'), appBarStyle: _glassAppBar)],
        footers: [
          NavigationBar(
            items: _items,
            labelMode: .all,
            navigationBarStyle: _glassNavBar,
          ),
        ],
        child: SizedBox.expand(),
      ),
    );
    expect(
      find.byType(BackdropFilter),
      findsOneWidget,
      reason:
          'only the NavigationBar owns a platter; a title-only AppBar is clear',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll edge fades without recreating the action blur filter', (
    tester,
  ) async {
    final controller = ScrollController();
    var actionBuilds = 0;
    addTearDown(controller.dispose);
    await pumpTestApp(
      tester,
      SizedBox(
        height: 400,
        child: Column(
          children: [
            AppBar(
              title: const Text('Title'),
              appBarStyle: _glassAppBar,
              leading: [
                Builder(
                  builder: (context) {
                    actionBuilds++;
                    return Button(
                      variant: .ghost,
                      onPressed: () {},
                      child: const Text('Back'),
                    );
                  },
                ),
              ],
              scrollController: controller,
            ),
            Expanded(
              child: ListView(
                controller: controller,
                children: const [SizedBox(height: 2000)],
              ),
            ),
          ],
        ),
      ),
    );
    final filter = tester
        .widget<BackdropFilter>(find.byType(BackdropFilter))
        .filter;
    Gradient edge() =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(AppBar),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .gradient!;
    expect(edge().colors.first.a, 0);
    final buildsAtRest = actionBuilds;
    controller.jumpTo(24);
    await tester.pump();
    expect(edge().colors.first.a, closeTo(.92, .005));
    expect(
      actionBuilds,
      buildsAtRest,
      reason: 'scrolling must only rebuild the soft edge',
    );
    expect(
      identical(
        filter,
        tester.widget<BackdropFilter>(find.byType(BackdropFilter)).filter,
      ),
      isTrue,
    );
  });
}
