import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Finder _marked(String attribute) => find.byComponentPredicate(
  (c) => c is div && (c.attributes?.containsKey(attribute) ?? false),
);

Component _glass(Component child) => SurfaceStyleScope(
  surfaceStyle: .liquidGlass,
  child: child,
);

void main() {
  testComponents('authored action gap survives native capsule composition', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const AppBar(
        title: Text('Title'),
        appBarStyle: CoreAppBarStyle(
          surfaceStyle: .liquidGlass,
          actionSpacing: CoreSpace.space16,
        ),
        trailing: [Text('Search'), Text('More')],
      ),
    );
    await tester.pump();
    final popup = find.byType(Popup).evaluate().single.component as Popup;
    expect(popup.popupStyle?.spacing, CoreSpace.space16);
  });

  testComponents('glass host is clear; controls own two grouped lenses', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _glass(
        AppBar(
          title: const Text('Title'),
          centerTitle: true,
          leading: [
            Button(
              variant: .ghost,
              onPressed: () {},
              child: const Text('Back'),
            ),
          ],
          trailing: [
            Button(
              variant: .ghost,
              onPressed: () {},
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(_marked('data-coui-app-bar-glass'), findsOneComponent);
    expect(_marked('data-coui-app-bar-actions'), findsNComponents(2));
    // The centred title is in the bar grid's middle column — the same
    // placement as every other material, with no measuring script.
    expect(
      find.byComponentPredicate(
        (c) => c is div && c.styles?.properties['grid-column'] == '2',
      ),
      findsOneComponent,
    );
    final host =
        _marked('data-coui-app-bar-glass').evaluate().single.component as div;
    expect(host.classes?.split(' '), isNot(contains('coui-surface')));
    expect(host.classes?.split(' '), isNot(contains('border-b')));
  });

  testComponents(
    'local material applies to explicit groups without another platter',
    (tester) async {
      pumpWithTheme(
        tester,
        const AppBar(
          appBarStyle: CoreAppBarStyle(surfaceStyle: .liquidGlass),
          title: Text('Title'),
          trailing: [
            ToolbarGroup(ariaLabel: 'Tools', children: [Text('Search')]),
          ],
        ),
      );
      await tester.pump();
      expect(_marked('data-coui-app-bar-actions'), findsNothing);
      expect(find.byType(Popup), findsOneComponent);
      final popup = find.byType(Popup).evaluate().single.component as Popup;
      expect(popup.popupStyle?.surfaceStyle, CoreSurfaceStyleId.liquidGlass);
    },
  );

  testComponents('floating scaffold leaves the bar capsules in charge', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _glass(
        const Scaffold(
          floatingHeader: true,
          headers: [
            AppBar(title: Text('Title'), leading: [Text('Back')]),
          ],
          child: Text('Body'),
        ),
      ),
    );
    await tester.pump();
    final surfaces = find.byComponentPredicate(
      (c) =>
          c is div &&
          (c.classes?.split(' ').contains('coui-surface-functional') ?? false),
    );
    expect(surfaces, findsOneComponent);
  });

  testComponents('local default material keeps ordinary bar rendering', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _glass(
        const AppBar(
          appBarStyle: CoreAppBarStyle(surfaceStyle: .defaultStyle),
          title: Text('Title'),
          leading: [Text('Back')],
        ),
      ),
    );
    await tester.pump();
    expect(_marked('data-coui-app-bar-glass'), findsNothing);
    expect(_marked('data-coui-app-bar-actions'), findsNothing);
  });
}
