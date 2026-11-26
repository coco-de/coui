// What a FadeScroll looks like before its measurer has read the viewport.
//
// The mask mixes each edge colour with transparent by
// `(1 - var(--co-fade-<edge>-alpha, <fallback>)) * 100%`, and only the
// measurer — a script that runs after the page is drawn — writes those
// variables. Until then the fallbacks are the picture: a server-rendered
// page, and every page in the moment before the script runs.
//
// A viewport always first paints at its start, so the leading edge must
// not fade there; Flutter's settled FadeScroll fades an edge only while
// content lies beyond it. The fallbacks once faded both edges, so a
// horizontal list opened with its first items washed out on Web and solid
// on Flutter.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

Iterable<DomComponent> _dom(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

Map<String, String> _inline(DomComponent c) => c.styles?.properties ?? const {};

/// How much of the opaque edge colour an edge keeps while its variable is
/// unset, in percent: 100 draws the content (no fade), 0 masks it out.
double _opaquePercentBeforeMeasuring(String mask, String edge) {
  final match = RegExp(
    'var\\(--co-fade-$edge-alpha, ([0-9.]+)\\)',
  ).firstMatch(mask);
  expect(match, isNotNull, reason: 'the $edge stop reads its variable');

  return (1 - double.parse(match!.group(1)!)) * 100;
}

String _maskOf(ComponentTester tester) {
  final masked = _dom(
    tester,
  ).where((c) => _inline(c).containsKey('mask-image')).toList();
  expect(masked, hasLength(1));

  return _inline(masked.single)['mask-image']!;
}

void main() {
  group('FadeScroll before its measurer runs', () {
    for (final direction in CoreFadeScrollDirection.values) {
      testComponents(
        '${direction.name}: the leading edge is drawn and the trailing '
        'edge fades',
        (tester) async {
          pumpWithTheme(
            tester,
            FadeScroll(
              direction: direction,
              child: div([
                for (var i = 0; i < 12; i++) Text('item $i'),
              ]),
            ),
          );

          final mask = _maskOf(tester);
          expect(_opaquePercentBeforeMeasuring(mask, 'start'), 100);
          expect(_opaquePercentBeforeMeasuring(mask, 'end'), 0);
        },
      );
    }
  });
}
