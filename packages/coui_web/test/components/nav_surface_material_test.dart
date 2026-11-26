import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

Iterable<DomComponent> _marked(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((c) => (c.classes ?? '').split(' ').contains(kWebSurfaceMarker));

Map<String, String> _inline(DomComponent c) => c.styles?.properties ?? const {};

/// Destination `Clickable` roots — the actual flex children of the
/// `<nav>` row, found by the `role="button"` `Clickable` renders.
Iterable<DomComponent> _destinations(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((c) => c.attributes?['role'] == 'button');

void main() {
  group('a navigation bar is a surface', () {
    // Why this matters beyond tidiness: a material preset reaches a
    // surface through the marker. A nav bar that does not carry it stays
    // opaque while every panel around it turns translucent — the preset
    // looks broken rather than unapplied, and the bar is the one chrome
    // a user looks at on every screen.
    testComponents('the bar carries the marker and publishes its fill', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          items: [CoreNavigationBarItem<Component>.destination(label: 'Home')],
        ),
      );

      final surfaces = _marked(tester);
      expect(surfaces, isNotEmpty);
      expect(
        surfaces.any((c) => _inline(c).containsKey(kWebSurfaceFillVar)),
        isTrue,
      );
    });

    testComponents('and so does a dock', (tester) async {
      pumpWithTheme(
        tester,
        const Dock(
          items: [
            CoreDockItemData<Component>(
              label: 'Home',
              icon: Icon(LucideIcons.house),
            ),
          ],
        ),
      );

      final surfaces = _marked(tester);
      expect(surfaces, isNotEmpty);
      expect(
        surfaces.any((c) => _inline(c).containsKey(kWebSurfaceFillVar)),
        isTrue,
      );
    });
  });

  group('a bar can detach and round its own corners', () {
    testComponents('stated geometry reaches the element', (tester) async {
      pumpWithTheme(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          navigationBarStyle: CoreNavigationBarStyle(
            barRadius: CoreBorderRadius.all(CoreRadius.radius9999),
            barMargin: CoreEdgeInsets.all(CoreSpace.space16),
          ),
          items: [CoreNavigationBarItem<Component>.destination(label: 'Home')],
        ),
      );

      final inline = _marked(tester).map(_inline);

      expect(inline.any((m) => m.containsKey('border-radius')), isTrue);
      expect(inline.any((m) => m.containsKey('margin')), isTrue);
    });

    testComponents('and a docked bar emits neither', (tester) async {
      // The half that keeps this from being a visual change for everyone
      // who has not asked for a floating bar. Emitting `margin: 0` and
      // `border-radius: 0` would be harmless CSS and a lie about what the
      // component states.
      pumpWithTheme(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          items: [CoreNavigationBarItem<Component>.destination(label: 'Home')],
        ),
      );

      final inline = _marked(tester).map(_inline);

      expect(inline.any((m) => m.containsKey('border-radius')), isFalse);
      expect(inline.any((m) => m.containsKey('margin')), isFalse);
    });
  });

  group('a navigation bar keeps a hairline on its docked edge', () {
    testComponents('bar mode draws it on the physical top', (tester) async {
      pumpWithTheme(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          items: [CoreNavigationBarItem<Component>.destination(label: 'Home')],
        ),
      );

      final inline = _marked(tester).map(_inline);

      expect(inline.any((m) => m.containsKey('border-top-width')), isTrue);
      expect(
        inline.any((m) => m.containsKey('border-inline-end-width')),
        isFalse,
      );
    });

    testComponents('the vertical modes draw it on the logical end', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const NavigationBar(
          mode: .rail,
          selectedIndex: 0,
          items: [CoreNavigationBarItem<Component>.destination(label: 'Home')],
        ),
      );

      final inline = _marked(tester).map(_inline);

      expect(
        inline.any((m) => m.containsKey('border-inline-end-width')),
        isTrue,
      );
      expect(inline.any((m) => m.containsKey('border-top-width')), isFalse);
    });

    testComponents('and drops it once the bar detaches', (tester) async {
      // Same reasoning `Dock` already states for its own hairline: a
      // detached bar has no adjacent edge left to separate from.
      pumpWithTheme(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          navigationBarStyle: CoreNavigationBarStyle(
            barMargin: CoreEdgeInsets.all(CoreSpace.space16),
          ),
          items: [CoreNavigationBarItem<Component>.destination(label: 'Home')],
        ),
      );

      final inline = _marked(tester).map(_inline);

      expect(inline.any((m) => m.containsKey('border-top-width')), isFalse);
      expect(
        inline.any((m) => m.containsKey('border-inline-end-width')),
        isFalse,
      );
    });
  });

  group('bar-mode destinations fill the row', () {
    testComponents("each destination is the row's flex child", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const NavigationBar(
          selectedIndex: 0,
          items: [
            CoreNavigationBarItem<Component>.destination(label: 'A'),
            CoreNavigationBarItem<Component>.destination(label: 'B'),
          ],
        ),
      );

      final destinations = _destinations(tester);
      expect(destinations, hasLength(2));
      expect(
        destinations.every((c) => (c.classes ?? '').contains('flex-1')),
        isTrue,
      );
    });

    testComponents('the vertical modes do not force an equal share', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const NavigationBar(
          mode: .rail,
          selectedIndex: 0,
          items: [
            CoreNavigationBarItem<Component>.destination(label: 'A'),
            CoreNavigationBarItem<Component>.destination(label: 'B'),
          ],
        ),
      );

      final destinations = _destinations(tester);
      expect(destinations, isNotEmpty);
      expect(
        destinations.any((c) => (c.classes ?? '').contains('flex-1')),
        isFalse,
      );
    });
  });

  group('a dock draws its line all round, docked or floating', () {
    testComponents('the docked bar draws it', (tester) async {
      pumpWithTheme(
        tester,
        const Dock(
          items: [
            CoreDockItemData<Component>(
              label: 'Home',
              icon: Icon(LucideIcons.house),
            ),
          ],
        ),
      );

      expect(
        _marked(tester).any((c) => _inline(c).containsKey('border-width')),
        isTrue,
      );
    });

    testComponents('and so does a floating one', (tester) async {
      // The bar is rounded at every size, so the line goes round it whether
      // it is docked or floating — a line on one edge of a rounded box has
      // nowhere to end.
      pumpWithTheme(
        tester,
        const Dock(
          dockStyle: CoreDockStyle(
            barMargin: CoreEdgeInsets.all(CoreSpace.space16),
          ),
          items: [
            CoreDockItemData<Component>(
              label: 'Home',
              icon: Icon(LucideIcons.house),
            ),
          ],
        ),
      );

      expect(
        _marked(tester).any((c) => _inline(c).containsKey('border-width')),
        isTrue,
      );
      expect(
        _marked(tester).any((c) => _inline(c).containsKey('border-top-width')),
        isFalse,
      );
    });
  });
}
