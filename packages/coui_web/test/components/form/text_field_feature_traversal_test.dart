// Pins `skipInputFeatureFocusTraversal` to the DOM it produces.
//
// The flag was declared on the contract and on both widgets and read by
// nobody: Web emitted `tabindex="-1"` unconditionally, Flutter emitted
// nothing, so the same field got opposite answers from the two platforms
// and neither answer moved when a caller set it.
//
// These cases fail against that build — the `false` case found the
// attribute pinned to `-1`, because the emit site was a literal.
//
// Asserting on `containsKey` rather than on the value matters: an
// affordance that is *in* the Tab order carries no `tabindex` at all, so
// a value-only assertion (`equals('-1')` / `isNot('-1')`) passes on an
// attribute that was never removed.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The affordance button rendered for a `CoreInputFeature`.
DomComponent get _featureButton =>
    find.tag('button').evaluate().single.component as DomComponent;

void main() {
  group('TextField skipInputFeatureFocusTraversal', () {
    testComponents('omits tabindex when the caller opts into traversal', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TextField(
          initialValue: 'abc',
          features: const [CoreInputFeature.clear()],
          skipInputFeatureFocusTraversal: false,
        ),
      );

      expect(
        _featureButton.attributes?.containsKey('tabindex') ?? false,
        isFalse,
        reason: 'an affordance in the Tab order carries no tabindex',
      );
    });

    testComponents('emits tabindex="-1" when traversal is skipped', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TextField(
          initialValue: 'abc',
          features: const [CoreInputFeature.clear()],
          skipInputFeatureFocusTraversal: true,
        ),
      );

      expect(_featureButton.attributes?['tabindex'], equals('-1'));
    });

    testComponents('defaults to skipping traversal', (tester) async {
      pumpWithTheme(
        tester,
        TextField(
          initialValue: 'abc',
          features: const [CoreInputFeature.clear()],
        ),
      );

      expect(_featureButton.attributes?['tabindex'], equals('-1'));
    });
  });
}
