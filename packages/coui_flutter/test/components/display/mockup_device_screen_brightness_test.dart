// A screen in its own brightness — a light app previewed on a dark page.
//
// `screenBrightness` scopes the screen and what draws on it: the fill, the
// status bar, the gesture bar and the child. The body, the bezel and the
// buttons stay the page's. Read from the painted tree, in the `flat` finish
// whose bezel is a token — the realistic one paints literal hardware that
// looks the same in either brightness and could not tell the two apart. The
// flat finish hides its bars by default; they are turned on so the bars are
// there to read.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final _light = ThemeData.fromCore(CoreThemePresets.light);
final _dark = ThemeData.fromCore(CoreThemePresets.dark);

const ValueKey<String> _kContent = ValueKey('content');

Future<void> _pump(
  WidgetTester tester, {
  required CoreThemeMode page,
  CoreBrightness? screen,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: _light,
      darkTheme: _dark,
      themeMode: page,
      home: Center(
        child: MockupDevice(
          finish: .flat,
          showStatusBar: true,
          showGestureBar: true,
          screenBrightness: screen,
          child: const SizedBox.expand(key: _kContent),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The screen: the clip the child is drawn inside.
Finder get _screen => find
    .ancestor(of: find.byKey(_kContent), matching: find.byType(ClipRRect))
    .first;

/// The bezel: the stack the screen sits in.
Finder get _bezel =>
    find.ancestor(of: _screen, matching: find.byType(Stacks)).first;

/// Every box fill painted under [within].
List<Color?> _fills(WidgetTester tester, Finder within) => [
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(of: within, matching: find.byType(DecoratedBox)),
  ))
    (box.decoration as BoxDecoration).color,
];

/// The screen fill — the box right behind the child.
Color _screenFill(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .ancestor(
            of: find.byKey(_kContent),
            matching: find.byType(ColoredBox),
          )
          .first,
    )
    .color;

void main() {
  for (final (page, screen, inScreen, onPage) in [
    (CoreThemeMode.dark, CoreBrightness.light, _light, _dark),
    (CoreThemeMode.light, CoreBrightness.dark, _dark, _light),
  ]) {
    group('a $screen screen on a ${page.name} page', () {
      testWidgets('the screen fill and its bars take the screen’s', (
        tester,
      ) async {
        await _pump(tester, page: page, screen: screen);
        final surface = inScreen.colorScheme.surface.toValue();
        final onSurface = inScreen.colorScheme.onSurface.toValue();

        expect(_screenFill(tester), surface);
        // The status bar band is the screen fill, the gesture bar the
        // screen's `onSurface`.
        expect(_fills(tester, _screen), containsAll([surface, onSurface]));
        expect(
          _fills(tester, _screen),
          isNot(contains(onPage.colorScheme.surface.toValue())),
        );
        expect(
          _fills(tester, _screen),
          isNot(contains(onPage.colorScheme.onSurface.toValue())),
        );
        expect(
          tester.widget<Text>(find.text('9:41')).style?.color,
          onSurface,
          reason: 'the clock',
        );
      });

      testWidgets('the bezel around it keeps the page’s', (tester) async {
        await _pump(tester, page: page, screen: screen);
        final pageBezel = onPage.colorScheme.surfaceContainerHighest.toValue();

        expect(_fills(tester, _bezel), contains(pageBezel));
        expect(
          _fills(tester, _bezel),
          isNot(
            contains(inScreen.colorScheme.surfaceContainerHighest.toValue()),
          ),
        );
      });

      testWidgets('the child renders in the screen’s brightness', (
        tester,
      ) async {
        await _pump(tester, page: page, screen: screen);
        final content = tester.element(find.byKey(_kContent));

        expect(Theme.of(content).coreBrightness, screen);
        expect(
          DefaultTextStyle.of(content).style.color,
          inScreen.colorScheme.onSurface.toValue(),
        );
      });

      testWidgets('the geometry is the same in either brightness', (
        tester,
      ) async {
        await _pump(tester, page: page);
        final unscoped = tester.getRect(_screen);
        await _pump(tester, page: page, screen: screen);

        expect(tester.getRect(_screen), unscoped);
      });
    });
  }

  testWidgets('stated nowhere, the screen is the page’s', (tester) async {
    await _pump(tester, page: .dark);

    expect(find.byType(BrightnessScope), findsNothing);
    expect(_screenFill(tester), _dark.colorScheme.surface.toValue());
  });

  testWidgets('copyWith carries the brightness', (tester) async {
    const device = MockupDevice(
      screenBrightness: CoreBrightness.light,
      child: SizedBox(),
    );

    expect(device.copyWith(width: 200).screenBrightness, CoreBrightness.light);
    expect(
      device.copyWith(screenBrightness: CoreBrightness.dark).screenBrightness,
      CoreBrightness.dark,
    );
  });
}
