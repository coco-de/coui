// A tab given `CoreTabItem.onClose` draws a close × after its label and
// badge — the composition `TabPane` uses for the same item field: a ghost
// `Button` beside the select `Clickable`, not inside it, so pressing the ×
// never selects. The tab's box holds both, so its hover and press wash is
// read off the whole box (the Web twin's `hover:` / `active:` on the box).
// Read from the built tree and from real pointer input.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {Locale? locale}) {
  final body = Theme(
    data: const ThemeData(),
    child: Center(child: child),
  );

  return material.MaterialApp(
    home: material.Scaffold(
      body: locale == null
          ? body
          : Localizations(
              locale: locale,
              delegates: const [
                CoUILocalizationsDelegate.delegate,
                DefaultWidgetsLocalizations.delegate,
                material.DefaultMaterialLocalizations.delegate,
              ],
              child: body,
            ),
    ),
  );
}

/// The close glyph's `Icon`.
Finder get _closeGlyph => find.byWidgetPredicate(
  (widget) => widget is Icon && widget.icon == LucideIcons.x,
  description: 'the close × glyph',
);

/// The close `Button`.
Finder get _closeButton =>
    find.ancestor(of: _closeGlyph, matching: find.byType(Button)).first;

/// The box of the tab labelled [label] — the indicator, the wash, the
/// padding and the height floor.
Finder _box(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(AnimatedContainer))
    .first;

Color? _boxFill(WidgetTester tester, String label) =>
    (tester.widget<AnimatedContainer>(_box(label)).decoration! as BoxDecoration)
        .color;

ResolvedTabs _resolved(
  WidgetTester tester, {
  CoreTabVariant variant = CoreTabVariant.defaultVariant,
  CoreTabsStyle? tabsStyle,
}) => resolveTabs(
  tester.element(find.byType(Tabs)),
  variant: variant,
  size: CoreTabsSize.defaultSize,
  tabsStyle: tabsStyle,
);

void main() {
  group('Tabs onClose', () {
    for (final variant in CoreTabVariant.values) {
      testWidgets('$variant: the × comes after the label and the badge', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            Tabs(
              variant: variant,
              selectedIndex: 0,
              onChanged: (_) {},
              tabs: [
                CoreTabItem<Widget>(
                  label: 'main.dart',
                  badge: const Badge(child: Text('3')),
                  onClose: () {},
                ),
                const CoreTabItem<Widget>(label: 'pubspec.yaml'),
              ],
            ),
          ),
        );
        await tester.pump();

        // One × for the one closable tab.
        expect(_closeGlyph, findsOneWidget);
        final badgeRight = tester.getTopRight(find.byType(Badge)).dx;
        final closeLeft = tester.getTopLeft(_closeButton).dx;
        // Label → badge → ×, the label↔badge step between each.
        expect(
          tester.getTopRight(find.text('main.dart')).dx,
          lessThan(tester.getTopLeft(find.byType(Badge)).dx),
        );
        expect(
          closeLeft - badgeRight,
          closeTo(CoreTabsStyle.defaultLabelBadgeGapStyle.size!, 0.01),
        );
        // Inside the tab's box.
        final box = tester.getRect(_box('main.dart'));
        expect(box.contains(tester.getCenter(_closeButton)), isTrue);
      });
    }

    testWidgets('pressing the × closes and does not select', (tester) async {
      final selected = <int>[];
      var closed = 0;
      await tester.pumpWidget(
        _app(
          Tabs(
            selectedIndex: 1,
            onChanged: selected.add,
            tabs: [
              CoreTabItem<Widget>(label: 'main.dart', onClose: () => closed++),
              const CoreTabItem<Widget>(label: 'pubspec.yaml'),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(_closeButton);
      await tester.pumpAndSettle();
      expect(closed, 1);
      expect(selected, isEmpty);

      // The label still selects.
      await tester.tap(find.text('main.dart'));
      await tester.pumpAndSettle();
      expect(selected, [0]);
      expect(closed, 1);
    });

    testWidgets('a disabled tab still closes, and still does not select', (
      tester,
    ) async {
      final selected = <int>[];
      var closed = 0;
      await tester.pumpWidget(
        _app(
          Tabs(
            selectedIndex: 1,
            onChanged: selected.add,
            tabs: [
              CoreTabItem<Widget>(
                label: 'main.dart',
                enabled: false,
                onClose: () => closed++,
              ),
              const CoreTabItem<Widget>(label: 'pubspec.yaml'),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(_closeButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('main.dart'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(closed, 1);
      expect(selected, isEmpty);
    });

    for (final (locale, expected) in [
      (null, DefaultCoUILocalizations.instance.buttonClose),
      (const Locale('ko'), KoCoUILocalizations.instance.buttonClose),
    ]) {
      testWidgets('the × is named by the ${locale ?? 'default'} locale', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(
            Tabs(
              selectedIndex: 0,
              onChanged: (_) {},
              tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
            ),
            locale: locale,
          ),
        );
        await tester.pump();

        expect(find.bySemanticsLabel(expected), findsOneWidget);
        semantics.dispose();
      });
    }

    testWidgets('the close box is 24 square around a 12 glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Tabs(
            selectedIndex: 0,
            onChanged: (_) {},
            tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(_closeButton), const Size.square(CoreSize.size24));
      expect(
        tester.getSize(_closeGlyph),
        const Size.square(CoreIconSize.size12),
      );
    });

    testWidgets('a tabsStyle override reaches the close box and its glyph', (
      tester,
    ) async {
      const style = CoreTabsStyle(
        closeButtonStyle: CoreButtonStyle(
          width: CoreSize.size28,
          height: CoreSize.size28,
        ),
        closeIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      );
      await tester.pumpWidget(
        _app(
          Tabs(
            selectedIndex: 0,
            onChanged: (_) {},
            tabsStyle: style,
            tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
          ),
        ),
      );
      await tester.pump();

      // The override merges over the default: the stated size wins, the
      // unstated corner and inset stay the default's.
      final resolved = _resolved(tester, tabsStyle: style);
      expect(
        resolved.closeButtonStyle,
        CoreTabsStyle.defaultCloseButtonStyle.merge(style.closeButtonStyle),
      );
      expect(
        resolved.closeButtonStyle.borderRadius,
        CoreTabsStyle.defaultCloseButtonStyle.borderRadius,
      );
      expect(tester.getSize(_closeButton), const Size.square(CoreSize.size28));
      expect(
        tester.getSize(_closeGlyph),
        const Size.square(CoreIconSize.size16),
      );
    });

    for (final variant in CoreTabVariant.values) {
      testWidgets('$variant: hovering the × washes the whole tab', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            Tabs(
              variant: variant,
              selectedIndex: 1,
              onChanged: (_) {},
              tabs: [
                CoreTabItem<Widget>(label: 'main.dart', onClose: () {}),
                const CoreTabItem<Widget>(label: 'pubspec.yaml'),
              ],
            ),
          ),
        );
        await tester.pump();
        final resting = _boxFill(tester, 'main.dart');
        final hover = _resolved(tester, variant: variant).hoverStateLayerColor;

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(_closeButton));
        await tester.pumpAndSettle();
        expect(_boxFill(tester, 'main.dart'), hover);

        await mouse.moveTo(tester.getCenter(find.text('main.dart')));
        await tester.pumpAndSettle();
        expect(_boxFill(tester, 'main.dart'), hover);

        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        expect(_boxFill(tester, 'main.dart'), resting);
      });
    }

    testWidgets('a press on the × presses the whole tab', (tester) async {
      await tester.pumpWidget(
        _app(
          Tabs(
            selectedIndex: 1,
            onChanged: (_) {},
            tabs: [
              CoreTabItem<Widget>(label: 'main.dart', onClose: () {}),
              const CoreTabItem<Widget>(label: 'pubspec.yaml'),
            ],
          ),
        ),
      );
      await tester.pump();
      final pressed = _resolved(tester).pressedStateLayerColor;

      final press = await tester.startGesture(tester.getCenter(_closeButton));
      await tester.pumpAndSettle();
      expect(_boxFill(tester, 'main.dart'), pressed);

      await press.up();
      await tester.pumpAndSettle();
      expect(_boxFill(tester, 'main.dart'), isNot(pressed));
    });

    testWidgets('a tab without onClose keeps its tree', (tester) async {
      await tester.pumpWidget(
        _app(
          Tabs(
            selectedIndex: 0,
            onChanged: (_) {},
            tabs: [
              CoreTabItem<Widget>(label: 'main.dart', onClose: () {}),
              const CoreTabItem<Widget>(label: 'pubspec.yaml'),
            ],
          ),
        ),
      );
      await tester.pump();

      // The plain tab is still one `Clickable` straight around its box, so
      // nothing about it moved; only the closable tab takes the new shape.
      final plain = tester.widget<Clickable>(
        find
            .ancestor(
              of: find.text('pubspec.yaml'),
              matching: find.byType(Clickable),
            )
            .first,
      );
      expect(plain.child, isA<AnimatedContainer>());
      final closable = tester.widget<Clickable>(
        find
            .ancestor(
              of: find.text('main.dart'),
              matching: find.byType(Clickable),
            )
            .first,
      );
      expect(closable.child, isNot(isA<AnimatedContainer>()));
    });

    testWidgets('an expanded bar of closable tabs lays out', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 400,
            child: Tabs(
              expand: true,
              selectedIndex: 0,
              onChanged: (_) {},
              tabs: [
                CoreTabItem<Widget>(label: 'a.dart', onClose: () {}),
                CoreTabItem<Widget>(label: 'b.dart', onClose: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // Each box takes its share of the bar.
      expect(
        tester.getSize(_box('a.dart')).width,
        tester.getSize(_box('b.dart')).width,
      );
    });
  });

  group('TabPane onClose', () {
    testWidgets('the × is named by the locale', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          TabPane(
            selectedIndex: 0,
            onChanged: (_) {},
            tabs: [CoreTabItem<Widget>(label: 'main.dart', onClose: () {})],
          ),
          locale: const Locale('ko'),
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel(KoCoUILocalizations.instance.buttonClose),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
