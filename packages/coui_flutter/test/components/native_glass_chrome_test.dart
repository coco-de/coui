import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Widget _action(String label) => Button(
  variant: .ghost,
  size: .sm,
  shape: .square,
  onPressed: () {},
  child: Text(label),
);

void main() {
  testWidgets('authored action gap survives native capsule composition', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      AppBar(
        title: const Text('Title'),
        appBarStyle: const CoreAppBarStyle(
          surfaceStyle: .liquidGlass,
          actionSpacing: CoreSpace.space16,
        ),
        trailing: [_action('S'), _action('M')],
      ),
    );
    final first = tester.getRect(find.byType(Button).first);
    final second = tester.getRect(find.byType(Button).last);
    expect(second.left - first.right, 16);
  });

  for (final preset in [CoreThemePresets.light, CoreThemePresets.dark]) {
    testWidgets('glass actions persist at rest in ${preset.brightness}', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        AppBar(
          title: const Text('Title'),
          centerTitle: true,
          leading: [_action('B')],
          trailing: [_action('S'), _action('M')],
        ),
        theme: ThemeData.fromCore(preset),
        surfaceStyle: .liquidGlass,
      );
      expect(find.byType(Popup), findsNWidgets(2));
      expect(find.byType(BackdropFilter), findsNWidgets(2));
      expect(
        tester.getCenter(find.text('Title')).dx,
        closeTo(tester.getCenter(find.byType(AppBar)).dx, .01),
      );
      expect(tester.getSize(find.byType(Button).first).height, 44);
      final context = tester.element(find.byType(Button).first);
      final button = resolveButton(
        context,
        variant: .ghost,
        size: .sm,
        shape: .square,
      );
      expect(
        button.pressedScale,
        1,
        reason: 'a grouped icon must not shrink independently',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('explicit groups keep one surface and no empty capsule', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      AppBar(
        title: const Text('Title'),
        appBarStyle: const CoreAppBarStyle(surfaceStyle: .liquidGlass),
        trailing: [
          const ToolbarGroup(ariaLabel: 'Empty', children: []),
          ToolbarGroup(
            ariaLabel: 'Tools',
            children: [_action('S'), _action('M')],
          ),
        ],
      ),
    );
    expect(find.byType(Popup), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.getSize(find.byType(Button).first).height, 44);
  });

  for (final wrapped in [false, true]) {
    testWidgets('floating header delegates material with Builder=$wrapped', (
      tester,
    ) async {
      final bar = AppBar(title: const Text('Title'), leading: [_action('B')]);
      await pumpTestApp(
        tester,
        Scaffold(
          floatingHeader: true,
          headers: [wrapped ? Builder(builder: (_) => bar) : bar],
          child: const SizedBox.expand(),
        ),
        surfaceStyle: .liquidGlass,
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('authored bar colour is a fill, not a rectangular lens', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      AppBar(
        title: const Text('Title'),
        leading: [_action('B')],
        appBarStyle: const CoreAppBarStyle(
          surfaceStyle: .liquidGlass,
          backgroundColor: CoreColor(0xFF123456),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    final backgrounds = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((b) => b.decoration)
        .whereType<BoxDecoration>();
    expect(backgrounds.any((b) => b.color == const Color(0xFF123456)), isTrue);
  });

  testWidgets('local default material removes inherited native glass chrome', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      AppBar(
        title: const Text('Title'),
        leading: [_action('B')],
        appBarStyle: const CoreAppBarStyle(surfaceStyle: .defaultStyle),
      ),
      surfaceStyle: .liquidGlass,
    );
    expect(find.byType(Popup), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets(
    'reduced transparency retains controls without backdrop filters',
    (tester) async {
      await pumpTestApp(
        tester,
        AppBar(
          title: const Text('Title'),
          leading: [_action('B')],
        ),
        surfaceStyle: .liquidGlass,
        theme: const ThemeData(reduceTransparency: true),
      );
      expect(find.byType(Popup), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('Title'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
