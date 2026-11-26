import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Every element in the tree marked as a surface — restricts to the
/// button's own root, since leading/trailing icons and the internal
/// `Gap` render other `DomComponent`s that never carry the marker.
Iterable<DomComponent> _marked(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((c) => (c.classes ?? '').split(' ').contains(kWebSurfaceMarker));

List<String> _classes(DomComponent c) => (c.classes ?? '').split(' ');

/// Whether any class in [classes] publishes [kWebSurfaceFillVar] for the
/// given [pseudo] prefix (`''` = the rest state) — the companion class
/// `_surfaceFillClass` emits alongside a token-bound background class,
/// since a pseudo-scoped custom property has no inline form to carry it.
bool _publishesFillFor(Iterable<String> classes, {String pseudo = ''}) =>
    classes.any((c) => c.startsWith('$pseudo[$kWebSurfaceFillVar:'));

void main() {
  group('a button is a surface at its role', () {
    // Restates the same hook `OutlinedContainer`-composing surfaces carry
    // — Button can't compose that primitive (its root already resolves
    // hover × focus × disabled × selected, and its Web twin is the
    // native `<button>` element itself), so the marker is restated here
    // directly. The style rule it selects restates the fill at the
    // material's share and frosts, bends and edges the box — this pins
    // that the hook exists so a content-role material reaches Button the
    // same way it reaches every other content surface.
    testComponents('the default (content) role carries the content marker', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(child: const Component.text('Submit')),
      );

      final surfaces = _marked(tester);
      expect(surfaces, isNotEmpty);
      expect(
        surfaces.any((c) => _classes(c).contains(kWebSurfaceRoleContent)),
        isTrue,
      );
    });

    testComponents('role: .functional carries the functional marker', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(role: .functional, child: const Component.text('Submit')),
      );

      final surfaces = _marked(tester);
      expect(surfaces, isNotEmpty);
      expect(
        surfaces.any((c) => _classes(c).contains(kWebSurfaceRoleFunctional)),
        isTrue,
      );
    });

    testComponents('a variant that rests unfilled is no surface', (
      tester,
    ) async {
      // `menu` rests at opacity 0 and fills only on hover and selection.
      // The material rule restates the published triplet without that
      // alpha, so marked it came out half-filled at rest — and at rest it
      // has no box to frost or edge. Its Flutter twin withholds the
      // material on the same answer.
      pumpWithTheme(
        tester,
        Button(variant: .menu, child: const Component.text('Item')),
      );

      expect(_marked(tester), isEmpty);
    });
  });

  group('a token-bound background publishes the fill triplet', () {
    testComponents('the idle fill', (tester) async {
      pumpWithTheme(
        tester,
        Button(child: const Component.text('Submit')),
      );

      final classes = _marked(tester).expand(_classes);
      expect(_publishesFillFor(classes), isTrue);
    });

    testComponents('the disabled fill', (tester) async {
      // `primary`'s disabled background is a distinct token
      // (`surfaceContainerHigh`, not the idle `primary`) — this pins
      // that the companion rides every state's *own* token, not just
      // the rest one.
      pumpWithTheme(
        tester,
        Button(
          enabled: false,
          child: const Component.text('Submit'),
        ),
      );

      final classes = _marked(tester).expand(_classes);
      expect(_publishesFillFor(classes, pseudo: 'disabled:'), isTrue);
    });

    testComponents('the hover fill', (tester) async {
      // `primary` states its own hover token (`primaryHover`, not the idle
      // `primary`) — the companion rides the hovered state's own token.
      // No variant that rests filled states a selected or focused fill of
      // its own; the two that do (`menu` / `menubar`) rest unfilled and are
      // no surface (see the group above).
      pumpWithTheme(
        tester,
        Button(child: const Component.text('Submit')),
      );

      final classes = _marked(tester).expand(_classes);
      expect(_publishesFillFor(classes, pseudo: 'hover:'), isTrue);
    });
  });

  group('a raw (token-less) background publishes nothing', () {
    testComponents('a per-instance raw override has no companion class', (
      tester,
    ) async {
      // A caller who stated a raw colour stated it — a material rule
      // restating it would overrule an explicit choice, so no
      // companion class should exist for that state's slot at all.
      pumpWithTheme(
        tester,
        Button(
          buttonStyle: const CoreButtonStyle(
            backgroundColor: CoreColor.fromRGB(10, 20, 30),
          ),
          child: const Component.text('Submit'),
        ),
      );

      final classes = _marked(tester).expand(_classes).toList();
      expect(
        classes.any((c) => c.startsWith('[$kWebSurfaceFillVar:')),
        isFalse,
      );
    });
  });
}
