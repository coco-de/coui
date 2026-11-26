import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

const _glass = CorePopupStyle(surfaceStyle: .liquidGlass);

void main() {
  testWidgets(
    'menu panel overrides material without blurring inline submenus',
    (tester) async {
      await pumpTestApp(
        tester,
        const Menu(
          menuStyle: CoreMenuStyle(popupStyle: _glass),
          items: [
            CoreMenuItem.action(
              'Edit',
              submenu: [
                CoreMenuItem.action('Copy', standardAction: .copy),
              ],
            ),
          ],
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      final surface = tester.widget<SurfaceBlur>(find.byType(SurfaceBlur));
      expect(surface.refraction, isNotNull);
      final row = tester.widget<MenuItem>(
        find.widgetWithText(MenuItem, 'Copy'),
      );
      expect((row.leading! as Icon).icon, LucideIcons.copy);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('explicit leading wins over standard command icon', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const Menu(
        items: [
          CoreMenuItem.action(
            'Translated copy',
            standardAction: .copy,
            leading: Text('custom icon'),
          ),
        ],
      ),
    );
    final row = tester.widget<MenuItem>(
      find.widgetWithText(MenuItem, 'Translated copy'),
    );
    expect(row.leading, isA<Text>());
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('popup theme and instance precedence preserve opaque opt-out', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const Menu(
        menuStyle: CoreMenuStyle(
          popupStyle: CorePopupStyle(surfaceStyle: .defaultStyle),
        ),
        items: [CoreMenuItem.action('Copy', standardAction: .copy)],
      ),
      componentTheme: const CoreComponentTheme(
        popup: CorePopupTheme(style: _glass),
      ),
      surfaceStyle: .liquidGlass,
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('menu material obeys reduced transparency and motion', (
    tester,
  ) async {
    late ResolvedPopup popup;
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) {
          popup = resolvePopup(context, popupStyle: _glass);
          return const Menu(
            menuStyle: CoreMenuStyle(popupStyle: _glass),
            items: [CoreMenuItem.action('Copy', standardAction: .copy)],
          );
        },
      ),
      theme: const ThemeData(reduceTransparency: true),
      disableAnimations: true,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(popup.refraction, isNull);
    expect(popup.backgroundColor.a, 1);
    expect(popup.openAnimationDuration, Duration.zero);
    expect(popup.closeAnimationDuration, Duration.zero);
  });

  testWidgets(
    'toolbar groups share one backdrop, expose labels, and omit empty groups',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var pressed = 0;
      await pumpTestApp(
        tester,
        Row(
          mainAxisSize: .min,
          children: [
            ToolbarGroup(
              ariaLabel: 'History',
              popupStyle: _glass,
              children: [
                Semantics(
                  label: 'Undo',
                  child: Button(
                    variant: .ghost,
                    onPressed: () => pressed++,
                    child: const Icon(LucideIcons.undo2),
                  ),
                ),
                Semantics(
                  label: 'Redo',
                  child: Button(
                    variant: .ghost,
                    onPressed: () {},
                    child: const Icon(LucideIcons.redo2),
                  ),
                ),
              ],
            ),
            const ToolbarGroup(
              ariaLabel: 'Hidden actions',
              popupStyle: _glass,
              children: [],
            ),
          ],
        ),
      );
      expect(find.byType(ToolbarGroup), findsNWidgets(2));
      expect(find.byType(Popup), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.bySemanticsLabel('History'), findsOneWidget);
      expect(find.bySemanticsLabel('Hidden actions'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Undo'));
      expect(pressed, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'menubar material forwards to its open panel and standard icons',
    (tester) async {
      await pumpTestApp(
        tester,
        const Menubar(
          menubarStyle: CoreMenubarStyle(surfaceStyle: .liquidGlass),
          menus: [
            CoreMenubarMenu(
              label: 'Edit',
              entries: [
                CoreMenubarEntry.action(label: 'Copy', standardAction: .copy),
              ],
            ),
          ],
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.byType(Menu), findsOneWidget);
      final menu = tester.widget<Menu>(find.byType(Menu));
      expect(
        menu.menuStyle!.popupStyle!.surfaceStyle,
        CoreSurfaceStyleId.liquidGlass,
      );
      expect(menu.items.single.standardAction, CoreMenuAction.copy);
      expect(tester.takeException(), isNull);
    },
  );
}
