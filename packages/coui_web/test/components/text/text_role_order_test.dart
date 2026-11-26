import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The single `<span>` a bare `Text` chain renders.
DomComponent _span(ComponentTester tester) =>
    find.byType(DomComponent).evaluate().single.component as DomComponent;

void main() {
  // #5495 — a role chained AFTER a primitive replaces the size, weight, line
  // height and family that primitive set, as Flutter's role getter does
  // (`WrappedText` merges the role's whole `TextStyle` over the chain).
  // Measured on Flutter: `.s20.codeSm` paints 12px, `.h140.codeMd` keeps the
  // role's 21px line box, `.sans.codeSm` stays Geist Mono, `.bold.bodyMedium`
  // stays w400. Letter spacing and slant survive the role on both platforms
  // — Flutter keeps its letter-spacing chain in a slot the role leaves alone.
  group('a role chained after a primitive replaces it (#5495)', () {
    final dropped = <String, Text>{
      's20.codeSm': const Text('x').s20.codeSm,
      'h140.codeMd': const Text('x').h140.codeMd,
      's16.bodyMedium': const Text('x').s16.bodyMedium,
    };
    for (final entry in dropped.entries) {
      testComponents('${entry.key} — no inline size or line height', (
        tester,
      ) async {
        pumpWithTheme(tester, entry.value);

        final styles = _span(tester).styles?.properties ?? const {};
        expect(styles.containsKey('font-size'), isFalse);
        expect(styles.containsKey('line-height'), isFalse);
      });
    }

    testComponents('sans.codeSm — the family class is dropped', (
      tester,
    ) async {
      pumpWithTheme(tester, const Text('x').sans.codeSm);

      final classes = (_span(tester).classes ?? '').split(' ');
      expect(classes, contains('text-code-sm'));
      expect(classes.where((c) => c.startsWith('font-')), isEmpty);
    });

    testComponents('bold.bodyMedium — the weight class is dropped', (
      tester,
    ) async {
      pumpWithTheme(tester, const Text('x').bold.bodyMedium);

      final classes = (_span(tester).classes ?? '').split(' ');
      expect(classes, contains('text-body-medium'));
      expect(classes.where((c) => c.startsWith('font-')), isEmpty);
    });

    testComponents('tighter.codeMd — letter spacing survives the role', (
      tester,
    ) async {
      pumpWithTheme(tester, const Text('x').tighter.codeMd);

      final styles = _span(tester).styles?.properties ?? const {};
      expect(styles.containsKey('letter-spacing'), isTrue);
    });

    testComponents('italic.bodyMedium — slant survives the role', (
      tester,
    ) async {
      pumpWithTheme(tester, const Text('x').italic.bodyMedium);

      final span = _span(tester);
      final classes = (span.classes ?? '').split(' ');
      final styles = span.styles?.properties ?? const {};
      expect(
        classes.contains('italic') || styles['font-style'] == 'italic',
        isTrue,
      );
    });

    testComponents('codeMd.s16 — a primitive AFTER the role still wins', (
      tester,
    ) async {
      pumpWithTheme(tester, const Text('x').codeMd.s16);

      final styles = _span(tester).styles?.properties ?? const {};
      expect(styles.containsKey('font-size'), isTrue);
    });
  });
}
