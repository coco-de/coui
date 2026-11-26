// A box something can be seen through throws its cast from outside itself.
//
// Flutter paints `BoxDecoration.boxShadow` as a whole shape behind the box,
// where CSS draws `box-shadow` outside the border box only. The two cannot be
// told apart while the fill is opaque; through a translucent or transparent
// fill the Flutter cast shows through the box's own body and the Web one does
// not (`cross-platform/api.md`, "그림자는 두 플랫폼이 다른 곳에 칠한다"). So a
// see-through box hands its cast to the knocked-out painter, and an opaque one
// keeps the decoration.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, CoreColor fill) => tester.pumpWidget(
  CoUIApp(
    theme: const ThemeData(),
    home: w.Align(
      alignment: w.Alignment.topLeft,
      child: OutlinedContainer(
        containerStyle: CoreOutlinedContainerStyle(
          backgroundColor: fill,
          boxShadow: CoreShadow.xs,
        ),
        child: const w.SizedBox(width: 40, height: 40),
      ),
    ),
  ),
);

/// The decoration the container paints its box with.
BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<w.AnimatedContainer>(
              find
                  .descendant(
                    of: find.byType(OutlinedContainer),
                    matching: find.byType(w.AnimatedContainer),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

Finder _cast() => find.descendant(
  of: find.byType(OutlinedContainer),
  matching: find.byType(InjectedCast),
);

void main() {
  testWidgets('an opaque box keeps the decoration cast', (tester) async {
    await _pump(tester, const CoreColor.token(CoreColors.surface));

    expect(_decoration(tester).boxShadow, hasLength(CoreShadow.xs.length));
    expect(_cast(), findsNothing);
  });

  testWidgets('a transparent box throws its cast from outside the box', (
    tester,
  ) async {
    await _pump(tester, CoreColor.transparent);

    expect(_decoration(tester).boxShadow, isNull);
    expect(
      tester.widget<InjectedCast>(_cast()).shadows,
      hasLength(CoreShadow.xs.length),
    );
  });

  testWidgets('a translucent box throws its cast from outside the box', (
    tester,
  ) async {
    await _pump(
      tester,
      const CoreColor.token(CoreColors.surface, opacity: 0.5),
    );

    expect(_decoration(tester).boxShadow, isNull);
    expect(_cast(), findsOneWidget);
  });
}
