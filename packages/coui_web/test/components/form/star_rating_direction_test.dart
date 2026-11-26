// `direction` is the kind of parameter that looks wired the moment it is
// declared: the field exists, copyWith carries it, nothing throws. What
// these tests read back is that it reaches the two places it has to —
// the axis the stars sit on, and the axis a single star fills along.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/star_rating/star_rating_style.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

ResolvedStarRating? _seen;

class _Capture extends StatelessComponent {
  const _Capture({required this.direction});

  final CoreAxis direction;

  @override
  Component build(BuildContext context) {
    _seen = resolveStarRating(
      context,
      isInteractive: true,
      enabled: true,
      direction: direction,
    );

    return const Component.text('x');
  }
}

Future<ResolvedStarRating> _resolve(
  ComponentTester tester,
  CoreAxis direction,
) async {
  pumpWithTheme(tester, _Capture(direction: direction));
  await tester.pump();

  return _seen!;
}

void main() {
  group('direction picks the axis the stars sit on', () {
    testComponents('horizontal lays them out in a row', (tester) async {
      final resolved = await _resolve(tester, .horizontal);

      expect(resolved.stars.className, isNot(contains('flex-col')));
    });

    testComponents('vertical stacks them', (tester) async {
      final resolved = await _resolve(tester, .vertical);

      expect(resolved.stars.className, contains('flex-col'));
    });
  });

  group('direction also picks how one star fills', () {
    testComponents('horizontal sweeps the clip width', (tester) async {
      final resolved = await _resolve(tester, .horizontal);
      final props = resolved.starFill.inlineStyles!.properties;

      expect(props['transition'], contains('width'));
    });

    testComponents('vertical sweeps a transform instead', (tester) async {
      // A vertical star fills bottom-up, which the widget draws by scaling
      // the clip rect rather than narrowing it — so the transitioned
      // property has to follow, or the fill would jump instead of sweep.
      final resolved = await _resolve(tester, .vertical);
      final props = resolved.starFill.inlineStyles!.properties;

      expect(props['transition'], contains('transform'));
    });

    testComponents('vertical anchors the scale at the bottom edge', (
      tester,
    ) async {
      // Without these two an SVG transform pivots around the viewBox
      // origin, so the fill would grow out of the wrong corner — and the
      // transition test above would still pass.
      final resolved = await _resolve(tester, .vertical);
      final props = resolved.starFill.inlineStyles!.properties;

      expect(props['transform-box'], equals('fill-box'));
      expect(props['transform-origin'], equals('bottom'));
    });
  });
}
