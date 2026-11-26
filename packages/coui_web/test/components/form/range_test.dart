import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

// Keyboard-driven value changes (`_handleThumbKeyDown`) aren't covered
// here — `dart test` runs this suite on the VM, and `universal_web`'s
// `KeyboardEvent.key` getter throws `Unsupported operation` outside a
// real browser/JS environment (no `dart_test.yaml` chrome platform is
// configured in this package). What's testable on the VM — the
// structural ARIA wiring that makes each thumb its own reachable,
// numerically-valid slider in the first place — is covered below.

const _kInitialMin = 20.0;
const _kInitialMax = 80.0;

/// The two `role="slider"` thumb `<div>`s, in DOM order (min, then max).
List<DomComponent> _thumbs(ComponentTester tester) {
  final divs = find
      .tag('div')
      .evaluate()
      .map((e) => e.component)
      .whereType<DomComponent>()
      .where((c) => c.attributes?['role'] == 'slider')
      .toList();
  return divs;
}

void main() {
  group('Range', () {
    testComponents('exposes two independently focusable thumbs', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Range(
          onChanged: (_, _) {},
          minValue: _kInitialMin,
          maxValue: _kInitialMax,
        ),
      );

      final thumbs = _thumbs(tester);
      expect(thumbs, hasLength(2));
    });

    testComponents('each thumb carries a numeric aria-valuenow', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Range(
          onChanged: (_, _) {},
          minValue: _kInitialMin,
          maxValue: _kInitialMax,
        ),
      );

      final thumbs = _thumbs(tester);
      for (final thumb in thumbs) {
        final now = thumb.attributes?['aria-valuenow'];
        expect(now, isNotNull);
        expect(double.tryParse(now!), isNotNull);
      }
      expect(thumbs[0].attributes?['aria-valuenow'], '$_kInitialMin');
      expect(thumbs[1].attributes?['aria-valuenow'], '$_kInitialMax');
    });

    testComponents('min and max thumbs carry distinct aria-labels', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Range(
          onChanged: (_, _) {},
          minValue: _kInitialMin,
          maxValue: _kInitialMax,
        ),
      );

      final thumbs = _thumbs(tester);
      final minLabel = thumbs[0].attributes?['aria-label'];
      final maxLabel = thumbs[1].attributes?['aria-label'];
      expect(minLabel, isNotNull);
      expect(maxLabel, isNotNull);
      expect(minLabel, isNot(maxLabel));
    });

    testComponents('each thumb is mutually bounded by the other', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Range(
          onChanged: (_, _) {},
          minValue: _kInitialMin,
          maxValue: _kInitialMax,
        ),
      );

      final thumbs = _thumbs(tester);
      // Min thumb can't be dragged past the max thumb's current value,
      // and vice versa (ARIA APG multi-thumb mutual clamp).
      expect(thumbs[0].attributes?['aria-valuemax'], '$_kInitialMax');
      expect(thumbs[1].attributes?['aria-valuemin'], '$_kInitialMin');
    });

    testComponents('interactive thumbs carry tabindex="0"', (tester) async {
      pumpWithTheme(
        tester,
        Range(
          onChanged: (_, _) {},
          minValue: _kInitialMin,
          maxValue: _kInitialMax,
        ),
      );

      for (final thumb in _thumbs(tester)) {
        expect(thumb.attributes?['tabindex'], '0');
      }
    });

    testComponents('non-interactive thumbs have no tabindex', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Range(minValue: _kInitialMin, maxValue: _kInitialMax),
      );

      for (final thumb in _thumbs(tester)) {
        expect(thumb.attributes?.containsKey('tabindex'), isFalse);
      }
    });
  });
}
