// Text.keepAll — the Web half of the shared keep-all vectors.
//
// The Web never changes the string: `.keepAll` emits
// `word-break: keep-all` (with `overflow-wrap: anywhere`) on the Text's own
// span and the browser removes the break opportunities. Every join vector's
// input therefore renders as it is. Whether Chrome removes the same
// opportunities CoreKeepAll draws on Flutter is the Chrome probe's question
// (tool/parity/test/web/keep_all_line_break_probe_test.dart), which lays the
// same table out in a real browser.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The table shared with the Core and Flutter keep-all tests.
const String kKeepAllVectorsPath =
    '../coui_core/test/fixtures/keep_all_vectors.json';

const String _kSentence = '리포머 심화 플로우와 회복 스트레칭';

/// The Text's own `<span>` — the first element the tree renders.
DomComponent _span(ComponentTester tester) =>
    find.byType(DomComponent).evaluate().first.component as DomComponent;

Map<String, String> _inline(ComponentTester tester) =>
    _span(tester).styles?.properties ?? const {};

List<String> _classes(ComponentTester tester) =>
    (_span(tester).classes ?? '').split(' ');

void main() {
  final doc =
      jsonDecode(File(kKeepAllVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final joins = (doc['joins']! as List).cast<Map<String, Object?>>();

  group('.keepAll leaves every join vector as it is and asks the browser', () {
    for (final c in joins) {
      final input = c['input']! as String;
      testComponents(c['name']! as String, (tester) async {
        pumpWithTheme(tester, Text(input).keepAll);

        expect(find.text(input), findsOneComponent);
        expect(_inline(tester)['word-break'], 'keep-all');
        expect(_inline(tester)['overflow-wrap'], 'anywhere');
      });
    }
  });

  group('without .keepAll', () {
    testComponents('a plain Text sets no line-breaking CSS', (tester) async {
      pumpWithTheme(tester, const Text(_kSentence));

      expect(_inline(tester).containsKey('word-break'), isFalse);
      expect(_inline(tester).containsKey('overflow-wrap'), isFalse);
    });
  });

  group('.keepAll composes with the rest of the chain', () {
    testComponents('before a role', (tester) async {
      pumpWithTheme(tester, const Text(_kSentence).keepAll.bodyMedium);

      expect(
        _classes(tester),
        contains('text-${CoreTextStyles.bodyMedium.name}'),
      );
      expect(_inline(tester)['word-break'], 'keep-all');
    });

    testComponents('after a role', (tester) async {
      pumpWithTheme(tester, const Text(_kSentence).bodyMedium.keepAll);

      expect(
        _classes(tester),
        contains('text-${CoreTextStyles.bodyMedium.name}'),
      );
      expect(_inline(tester)['word-break'], 'keep-all');
    });

    testComponents('with a line limit on either side', (tester) async {
      for (final chain in [
        const Text(_kSentence).lineLimit(2).keepAll,
        const Text(_kSentence).keepAll.lineLimit(2),
      ]) {
        pumpWithTheme(tester, chain);

        expect(_inline(tester)['-webkit-line-clamp'], '2');
        expect(_inline(tester)['word-break'], 'keep-all');
        expect(_inline(tester)['overflow-wrap'], 'anywhere');
      }
    });
  });

  group('.keepAll on Text.rich', () {
    testComponents('the root span carries the CSS and every span keeps its '
        'text', (tester) async {
      pumpWithTheme(
        tester,
        const Text.rich(
          TextSpan(
            text: '리포',
            children: [
              TextSpan(
                text: '머',
                style: TextStyle(fontWeight: 'bold'),
              ),
              TextSpan(text: ' 심화'),
            ],
          ),
        ).keepAll,
      );

      expect(_inline(tester)['word-break'], 'keep-all');
      expect(find.text('리포'), findsOneComponent);
      expect(find.text('머'), findsOneComponent);
      expect(find.text(' 심화'), findsOneComponent);
    });
  });
}
