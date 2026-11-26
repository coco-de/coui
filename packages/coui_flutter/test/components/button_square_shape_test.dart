// `CoreButtonShape.square` means equal width and height — and did not.
//
// The enum's own words are "Square button with equal width and height".
// Web honoured them (`aspect-square`); Flutter forced the height only
// and left the width to whatever the content asked for. So the same
// call rendered 32×32 in a browser and 20×32 in the app: as wide as the
// icon happened to be.
//
// Nothing saw it because nothing looked. The square and circle paths
// carried no test on either platform — a grep for `CoreButtonShape
// .square` across both test trees matched documentation and nothing
// else. The parity gate compares painted fields, and both platforms
// painted the same fill, border and radius; only the box differed.
//
// These tests read the rendered box rather than the resolver, because
// the resolver was not wrong about anything it was asked — it was never
// asked for a width at all.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: Center(child: child)),
  ),
);

Future<Size> _boxOf(WidgetTester tester, Widget button) async {
  await tester.pumpWidget(_app(button));
  // `pumpAndSettle`, because a button's chrome is animated: re-pumping the
  // same widget type at the same position updates the existing element and
  // animates toward the new box, so a single frame can still report the
  // previous case's size. The size-step case below pumps twice in one test
  // and would compare a settled box against a stale one.
  await tester.pumpAndSettle();
  return tester.getSize(find.byType(Button));
}

void main() {
  group('CoreButtonShape.square', () {
    testWidgets('is as wide as it is tall', (tester) async {
      final size = await _boxOf(
        tester,
        const Button(
          shape: CoreButtonShape.square,
          size: CoreComponentSize.sm,
          child: Icon(LucideIcons.check),
        ),
      );

      expect(size.width, size.height);
    });

    testWidgets('circle is too — the same promise, rounder', (tester) async {
      final size = await _boxOf(
        tester,
        const Button(
          shape: CoreButtonShape.circle,
          size: CoreComponentSize.sm,
          child: Icon(LucideIcons.check),
        ),
      );

      expect(size.width, size.height);
    });

    testWidgets('a rectangle button still hugs its content', (tester) async {
      // The control this needs: if the floor were applied unconditionally
      // every button would be square, and the assertions above would pass
      // for a reason that breaks every other button in the kit.
      //
      // Stated as "not square" rather than "narrower than the square one".
      // The narrower form was the first draft and it was simply false — a
      // rectangle button around the same glyph measures 44x32 at `sm` (its
      // horizontal padding is wider than the square's height floor), so the
      // square is the NARROWER of the two. It passed anyway, because the
      // helper pumped a single frame and read a box still animating from the
      // previous case. Two wrongs cancelling is exactly what a control is
      // supposed to catch, so the claim here is the one that is actually
      // load-bearing: the floor did not reach this button.
      final rectangle = await _boxOf(
        tester,
        const Button(
          size: CoreComponentSize.sm,
          child: Icon(LucideIcons.check),
        ),
      );

      expect(rectangle.width, isNot(rectangle.height));
    });

    testWidgets('an explicit width still wins over the shape', (tester) async {
      // A number is a narrower statement than a shape, so the caller's
      // own `minWidth` is what the shape falls back from — not the other
      // way round.
      final size = await _boxOf(
        tester,
        Button(
          shape: CoreButtonShape.square,
          size: CoreComponentSize.sm,
          buttonStyle: const CoreButtonStyle(minWidth: 120),
          child: const Icon(LucideIcons.check),
        ),
      );

      expect(size.width, greaterThanOrEqualTo(120));
    });

    testWidgets('the square grows with the size step', (tester) async {
      Future<double> widthAt(CoreComponentSize step) async => (await _boxOf(
        tester,
        Button(
          shape: CoreButtonShape.square,
          size: step,
          child: const Icon(LucideIcons.check),
        ),
      )).width;

      // The step is what makes the box, which is the whole reason an
      // icon-only button does not need a component of its own.
      expect(await widthAt(.lg), greaterThan(await widthAt(.sm)));
    });
  });
}
