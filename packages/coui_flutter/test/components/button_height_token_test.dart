// A Button is exactly as tall as its size token says — at every density.
//
// `CoreControlSize` promises that Button / TextField / Select share the
// same height at each step, so a row of them lines up. Flutter applies
// that token as a `minHeight` with `maxHeight: infinity`, which means
// the promise holds only while the content fits: `sm` rendered 34
// against its 32 token because a 22.4px `labelLarge` line box plus 12px
// of vertical padding does not fit in 32.
//
// Nothing saw it. The existing height regression test compares token map
// values to each other and never a rendered box, so it stayed green. The
// parity gate compared fifteen painted fields and no size — Flutter's 34
// and Web's 32 matched on every one of them.
//
// The density axis was the larger half: the resolver never applied
// `theme.scaling` to height or padding while typography IS text-scaled,
// so at a scaling of 1.25 four of the six sizes drifted off their tokens.
// The guard that should have caught that was matching the words
// `theme.scaling` in a doc comment.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  group('a button is its size token tall', () {
    // `AdaptiveScaling.mobile` is 1; the second density has to be one
    // that is not, or the loop compares the same box with itself.
    for (final scaling in [
      AdaptiveScaling.desktop,
      const AdaptiveScaling(1.25),
    ]) {
      for (final size in CoreComponentSize.values) {
        testWidgets('${size.name} at ${scaling.sizeScaling}x', (tester) async {
          await tester.pumpWidget(
            buildTestApp(
              Button(
                size: size,
                onPressed: () {},
                child: const Text('Label'),
              ),
              theme: scaling.scale(const ThemeData()),
            ),
          );
          await tester.pumpAndSettle();

          final token = CoreButtonStyle.defaultsBySize[size]!.height!;
          expect(
            tester.getSize(find.byType(Button)).height,
            // `token × sizeScaling`, not the bare token: the density
            // axis is supposed to move the control, and a test that
            // pinned the unscaled number would forbid the fix rather
            // than check it.
            closeTo(token * scaling.sizeScaling, 0.01),
            reason:
                '${size.name} at ${scaling.sizeScaling}x should be '
                '${token * scaling.sizeScaling}. A taller box means the '
                'content outgrew the token and `minHeight` let it — check '
                "this size's vertical padding against its label line box.",
          );
        });
      }
    }
  });
}
