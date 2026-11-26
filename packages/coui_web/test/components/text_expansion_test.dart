import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

String _long(String text) => CorePseudoLocale.expand(text);

/// Mirrors the Flutter suite's coverage of the *same* component set
/// (`coui_flutter/test/components/text_expansion_test.dart`) — every
/// layout in this kit has only ever been shown Korean (which runs
/// shorter than its English source), never text that grew.
///
/// Jaspr's test harness (`testComponents`) has no real CSS layout
/// engine — `dart test` runs on the VM, not a browser, so there is no
/// pixel measurement here and no equivalent of Flutter's thrown
/// overflow error. What this *can* catch, and what it checks: that the
/// full pseudo-expanded string (both `CorePseudoLocale` bracket
/// markers) reaches the rendered DOM text node unmodified — i.e. no
/// Dart-level truncation (an ellipsis helper, a `maxLength` clamp)
/// silently drops the tail before the browser even sees it. Whether the
/// box then visually clips that text is a `min-width: 0` / overflow
/// question a real browser has to answer — see `web/web-specifics.md`'s
/// flex-trap section for the failure mode, and `cc-pixel-loop`
/// (screenshot diffing) for the follow-up that would actually measure
/// it.
void main() {
  group('a label that grew in translation still reaches the DOM in full', () {
    final cases = <String, Component Function()>{
      'Button': () => Button(
        onPressed: () {},
        child: Text(_long('Save changes')),
      ),
      'Badge': () => Badge(child: Text(_long('In review'))),
      'Chip': () => Chip(label: _long('Marketing')),
      // The expansion goes on `title`, the slot every other case here
      // uses: the component's own primary label. It used to be
      // `description` because that was the only slot Alert had; `title`
      // is now the required one and `description` the optional second
      // line, so measuring the description would be measuring the slot
      // most Alerts do not fill.
      'Alert': () => Alert(title: _long('Could not load orders')),
    };

    cases.forEach((name, build) {
      testComponents(name, (tester) async {
        final expanded = _long(
          switch (name) {
            'Button' => 'Save changes',
            'Badge' => 'In review',
            'Chip' => 'Marketing',
            _ => 'Could not load orders',
          },
        );
        pumpWithTheme(tester, build());

        expect(
          find.textContaining(expanded),
          findsOneComponent,
          reason:
              '$name dropped part of the expanded string before it '
              'reached the DOM (declared-overflow / maxLength clamp?)',
        );
      });
    });
  });

  group('the expansion itself is honest', () {
    test('it grows the string', () {
      final expanded = CorePseudoLocale.expand('Save');

      expect(expanded.length, greaterThan('Save'.length));
    });

    test('it marks both ends so clipping is visible', () {
      final expanded = CorePseudoLocale.expand('Save');

      expect(expanded.startsWith(CorePseudoLocale.startMarker), isTrue);
      expect(expanded.endsWith(CorePseudoLocale.endMarker), isTrue);
      expect(CorePseudoLocale.isComplete(expanded), isTrue);
      // Simulate a container clipping off the trailing end marker.
      final clippedLength = expanded.length - CorePseudoLocale.endMarker.length;
      expect(
        CorePseudoLocale.isComplete(expanded.substring(0, clippedLength)),
        isFalse,
      );
    });
  });
}
