import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/theme_config.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Every class on every element in the rendered tree.
Set<String> _classes(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .expand((c) => (c.classes ?? '').split(' '))
    .where((c) => c.isNotEmpty)
    .toSet();

/// Finds every element whose OWN class list contains [token] as a whole
/// class — not a substring hit inside a longer class name (so `-h-`
/// scope classes and the like don't false-match).
Finder _byOwnClass(String token) => find.byComponentPredicate(
  (c) => c is DomComponent && (c.classes ?? '').split(' ').contains(token),
  description: 'element with own class "$token"',
);

/// Finds every element carrying at least one `hover:`-prefixed Tailwind
/// class — every element whose own appearance depends on the browser
/// computing `:hover` for THAT element specifically, as opposed to some
/// ancestor or descendant of it.
Finder get _hoverStyled => find.byComponentPredicate(
  (c) =>
      c is DomComponent &&
      (c.classes ?? '').split(' ').any((cls) => cls.startsWith('hover:')),
  description: 'element with an hover: class',
);

Finder get _markers => _byOwnClass(kWebTouchTargetMarker);

/// Asserts the relationship proven safe for checkbox / radio group /
/// toggle / slider / range / dot indicator: every element in the render
/// tree that carries `hover:` chrome also carries the pointer-target
/// marker itself — the same element, not an ancestor or a descendant of
/// it.
///
/// `.coui-touch-target::after` accepts the pointer; extending its hit
/// area to the WCAG floor is the whole point of the rule. That makes the
/// MARKED element the one the browser hit-tests, so `:hover` is computed
/// for the marked element — not for whatever happens to be its ancestor
/// or descendant. An element with a `hover:` class that lands on some
/// OTHER element never matches, because the pointer resolves to the
/// marker (or its hit area) first while it is anywhere inside the
/// marker's own bounds. That is the exact shape #3704 shipped: the
/// marker sat on the surrounding `Clickable`, `hover:border-*` /
/// `hover:scale-110` sat one level down on the dot, and the dot's hover
/// chrome never painted.
///
/// This is a different question from "does `coui-touch-target` exist
/// somewhere in this tree", which is all `_classes` above can answer —
/// that assertion is blind to which element carries which class and
/// passes unchanged whichever element the marker lands on. This checks
/// the relationship between the two classes directly, on the same
/// rendered elements a browser would hit-test.
void _expectHoverChromeSitsOnAMarker(
  ComponentTester tester, {
  required String component,
}) {
  final markerElements = _markers.evaluate().toSet();
  expect(
    markerElements,
    isNotEmpty,
    reason: '$component: expected at least one pointer-target marker',
  );
  for (final hovered in _hoverStyled.evaluate()) {
    expect(
      markerElements.contains(hovered),
      isTrue,
      reason:
          '$component: an element carries hover: chrome without '
          'carrying the pointer-target marker itself — a marker on '
          'some OTHER element sits between the pointer and this one, '
          'and its `:hover` will never match (the #3704 shape)',
    );
  }
}

void main() {
  group('the pointer-target rule ships once, globally', () {
    final css = ThemeConfig.defaults().cssVariables;

    test('and is stated as a floor rather than a size', () {
      // `max(100%, …)` is the reason this is one rule instead of one per
      // component: the browser compares the element against the floor,
      // so nothing in Dart has to know how large the element came out.
      // A chip's height comes from its content, and no resolver field
      // holds it.
      expect(css, contains('.coui-touch-target::after'));
      expect(
        css,
        contains(
          'max(100%,var($kWebTouchTargetVar,${CoreTouchTarget.minimum}px))',
        ),
      );
    });

    test('and positions the marked element so the hit area lands on it', () {
      // The one thing that fails silently: without `relative` on the
      // element, the absolutely positioned pseudo-element resolves against
      // some ancestor and the target lands somewhere else entirely.
      expect(css, contains('position:relative'));
    });

    test('and puts the hit area behind the content, not over it', () {
      // It is a hit area, not an overlay — it paints nothing, and behind
      // is where it belongs. In front it was the hit target for everything
      // inside: a chip's remove button fired the chip's own tap instead of
      // its own handler, and a dot indicator's `hover:` chrome never
      // matched. Behind, content wins wherever content is drawn and only
      // the margin ring is left to catch — which is what the Flutter twin
      // does
      // (`_RenderTouchTarget.hitTest` delegates inside positions down to
      // the child rather than consuming them).
      expect(css, contains('z-index:-1'));
    });

    test('and isolates it, which is the other half of that', () {
      // Measured, not assumed: with `z-index:-1` and no stacking context
      // here, the pseudo-element escapes past this element and lands
      // behind an ancestor's background, where it catches nothing — the expansion
      // stops working entirely. Neither declaration means anything without
      // the other, so this is pinned separately rather than folded into
      // the test above.
      expect(css, contains('isolation:isolate'));
    });

    test('and never disarms itself', () {
      // A `pointer-events:none` addition here would leave every
      // assertion above green — the rule would still say
      // `.coui-touch-target::after{...}`, still state the floor, still
      // sit behind the content with a stacking context. What it would
      // stop doing is accepting a pointer at all, which is the
      // mechanism's only job: the marker would still be present on
      // every marked element, the hit area would still be sized and
      // positioned correctly, and it would catch nothing. This is the
      // regression the substring checks above cannot see by
      // construction, so it gets its own assertion.
      expect(css, isNot(contains('pointer-events:none')));
    });
  });

  group('small controls carry the marker', () {
    testComponents('a checkbox box does', (tester) async {
      // The box is 12, 14 or 16 at the smaller sizes, below the minimum.
      pumpWithTheme(tester, Checkbox(size: CoreComponentSize.xs));

      expect(_classes(tester), contains('coui-touch-target'));
    });

    testComponents('a tappable chip does', (tester) async {
      pumpWithTheme(
        tester,
        Chip(size: CoreChipSize.sm, label: 'a', onTap: () {}),
      );

      expect(_classes(tester), contains('coui-touch-target'));
    });

    testComponents('and a display-only chip does not', (tester) async {
      // It has nothing to hit. A marker here would capture pointers over
      // the few pixels around the pill and do nothing with them, which
      // is worse than being small — the chip inside a chip input sits in
      // exactly that situation.
      pumpWithTheme(tester, Chip(size: CoreChipSize.sm, label: 'a'));

      expect(_classes(tester), isNot(contains('coui-touch-target')));
    });

    testComponents('every window-panel control button does', (tester) async {
      // The title-bar controls draw at 20×20. Each carries its own floor,
      // on the button element itself — the element whose `:hover` wash
      // the pointer has to reach (the co-location check below).
      pumpWithTheme(
        tester,
        WindowPanel(
          title: const Text('Editor'),
          minimizable: true,
          maximizable: true,
          onMinimize: () {},
          onMaximize: () {},
          onClose: () {},
        ),
      );

      expect(_markers.evaluate(), hasLength(3));
      _expectHoverChromeSitsOnAMarker(tester, component: 'window panel');
    });
  });

  group(
    'a marker sits with the chrome a pointer needs to reach — '
    'not merely somewhere in the tree',
    () {
      // Six of the eight marker sites carry no `hover:` chrome at
      // all — their interactive feedback is owned by the surrounding
      // `Clickable` (which is unaffected by where inside it the marker
      // sits, since a click anywhere in its bounds still bubbles to
      // it) or is driven by Dart state rather than a CSS pseudo-class.
      // `_expectHoverChromeSitsOnAMarker` is vacuously true for those
      // today — there is nothing to catch a marker landing in the
      // wrong place, because nothing here depends on `:hover`. That is
      // exactly what makes it a real net rather than a tautology: if a
      // future change adds `hover:` chrome to a descendant of one of
      // these markers without moving the marker to sit with it — the
      // precise shape of #3704 — this assertion stops being vacuous
      // and starts failing.
      testComponents('checkbox', (tester) async {
        pumpWithTheme(tester, Checkbox(size: CoreComponentSize.xs));
        _expectHoverChromeSitsOnAMarker(tester, component: 'checkbox');
      });

      testComponents('radio group', (tester) async {
        pumpWithTheme(
          tester,
          RadioGroup(
            value: 'a',
            options: const [(value: 'a', label: 'A')],
            size: CoreComponentSize.xs,
          ),
        );
        _expectHoverChromeSitsOnAMarker(tester, component: 'radio group');
      });

      testComponents('toggle', (tester) async {
        pumpWithTheme(tester, Toggle());
        _expectHoverChromeSitsOnAMarker(tester, component: 'toggle');
      });

      testComponents('slider', (tester) async {
        pumpWithTheme(tester, Slider());
        _expectHoverChromeSitsOnAMarker(tester, component: 'slider');
      });

      testComponents('range — both thumbs', (tester) async {
        // Range carries two markers, one per thumb — the helper checks
        // every hover-styled element against the full marker set, so
        // this exercises the multi-marker case the other five sites
        // don't.
        pumpWithTheme(tester, Range());
        _expectHoverChromeSitsOnAMarker(tester, component: 'range');
      });

      testComponents('dot indicator', (tester) async {
        // The one site in this group that actually carries `hover:`
        // chrome (`hover:border-*` / `hover:scale-110` on the inactive
        // dots, per dot_indicator_style.dart's `buildDotClassName`) —
        // this generalizes the check already pinned per-component in
        // dot_indicator_style_test.dart's "pointer target — the
        // overlay must not shadow the dot" group onto the shared net
        // every marker site now goes through.
        pumpWithTheme(
          tester,
          DotIndicator(onChanged: (_) {}, index: 0, length: 3),
        );
        expect(
          _hoverStyled.evaluate(),
          isNotEmpty,
          reason:
              'dot indicator: no hover: chrome rendered — the '
              'assertion below would pass vacuously and prove nothing',
        );
        _expectHoverChromeSitsOnAMarker(tester, component: 'dot indicator');
      });
    },
  );

  group('chip — the one documented exception', () {
    testComponents(
      "the close button's hover chrome is a descendant of the marker, "
      'not the marker itself — safe only because the shared '
      'hit-area-behind-content rule (tested above) keeps content on '
      'top of it',
      (tester) async {
        // Chip has TWO nested pointer targets under 24px — the pill and
        // the close button — and only one of them can carry the marker
        // (see #3705: a second full-bleed marker on the close button
        // would sit inside the pill's own hit area). The marker rides
        // the outer `Clickable`; the close button's `hover:` chrome
        // (from `Button.plain`) is a genuine descendant of it. That is
        // *not* the co-located shape the six sites above have — it is
        // exactly the shape #3704/#3705 broke — and it stays safe here
        // only because `z-index:-1` + `isolation:isolate` (asserted in
        // "the pointer-target rule ships once, globally" above) paints
        // the hit area behind the pill's own content instead of in
        // front of it.
        pumpWithTheme(
          tester,
          Chip(
            size: CoreChipSize.sm,
            label: 'a',
            onTap: () {},
            onRemove: () {},
          ),
        );

        final markers = _markers.evaluate().toList();
        expect(
          markers,
          hasLength(1),
          reason: 'chip: expected exactly one pointer-target marker',
        );
        final marker = markers.single;

        final hovered = _hoverStyled.evaluate().toList();
        expect(
          hovered,
          isNotEmpty,
          reason:
              'chip: no hover: chrome rendered on the close button — '
              'the exception this test documents no longer applies; if '
              'the close button truly carries no hover chrome any '
              'more, delete this group instead of leaving it vacuous',
        );

        // Documents the shape rather than the co-located one above:
        // the hover-styled element is NOT the marker itself...
        expect(
          hovered,
          isNot(contains(marker)),
          reason:
              'chip: the close button hover chrome sits on the marker '
              'element itself now — this exception is stale, replace '
              'this group with the co-located assertion the other six '
              'sites use',
        );
        // ...but it IS reachable as a descendant of it, which is what
        // the shared hit-area-behind-content rule protects. An element
        // outside the marker's own subtree gets no such protection.
        final hoveredInsideMarker = find
            .descendant(of: _markers, matching: _hoverStyled)
            .evaluate()
            .toList();
        expect(
          hoveredInsideMarker.length,
          hovered.length,
          reason:
              'chip: a hover-styled element sits outside the '
              "marker's own subtree — outside it, the shared "
              'hit-area-behind-content rule cannot protect it at all, '
              'and the marker will intercept it exactly like #3705',
        );
      },
    );
  });
}
