// Where a toast paints its cast. Flutter's `BoxDecoration.boxShadow` fills a
// shape behind the box and lets the fill paint over it; CSS paints an outer
// `box-shadow` outside the border box only. Under an opaque fill the two look
// the same. Under a translucent one — the glass styles — a cast in the
// decoration showed through the panel, on Flutter only, so the panel paints
// it outside the box instead (`ResolvedToast.castOutsideBox`).
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

/// Mounts a toast in an app under [style].
Future<void> _mount(WidgetTester tester, CoreSurfaceStyleId style) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: const w.Center(child: Toast(message: 'Saved')),
    ),
  );
  await tester.pump();
}

/// What the toast resolved, read in the toast's own context.
ResolvedToast _resolved(WidgetTester tester) => resolveToast(
  tester.element(find.byType(Toast)),
  variant: CoreToastVariant.defaultVariant,
  dismissible: false,
);

/// The casts painted outside a box under the toast.
List<InjectedCast> _casts(WidgetTester tester) => tester
    .widgetList<InjectedCast>(
      find.descendant(
        of: find.byType(Toast),
        matching: find.byType(InjectedCast),
      ),
    )
    .toList();

/// The decorations under the toast.
List<BoxDecoration> _decorations(WidgetTester tester) => tester
    .widgetList<w.DecoratedBox>(
      find.descendant(
        of: find.byType(Toast),
        matching: find.byType(w.DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .toList();

/// The decoration that paints the panel's fill.
BoxDecoration _panel(WidgetTester tester, ResolvedToast resolved) =>
    _decorations(tester).singleWhere(
      (decoration) => decoration.color == resolved.backgroundColor,
    );

void main() {
  // The premises of the table below: without a translucent panel the
  // outside-the-box branch would never run, and without an opaque one the
  // decoration branch would never run.
  testWidgets('a glass panel is translucent', (tester) async {
    await _mount(tester, CoreSurfaceStyleId.liquidGlass);
    expect(_resolved(tester).backgroundColor.a, lessThan(1));
  });

  testWidgets('a default panel is opaque', (tester) async {
    await _mount(tester, CoreSurfaceStyleId.defaultStyle);
    expect(_resolved(tester).backgroundColor.a, 1);
  });

  for (final style in CoreSurfaceStyleId.values) {
    testWidgets(
      'under ${style.name} the cast is painted once, outside the box exactly '
      'where the fill is translucent',
      (tester) async {
        await _mount(tester, style);
        final resolved = _resolved(tester);
        final outside = resolved.backgroundColor.a < 1;

        expect(resolved.castOutsideBox, outside);
        expect(
          [for (final cast in _casts(tester)) cast.shadows],
          outside ? [resolved.shadow] : isEmpty,
        );
        expect(
          _panel(tester, resolved).boxShadow,
          outside ? isNull : resolved.shadow,
        );
        if (outside) {
          expect(
            [
              for (final decoration in _decorations(tester))
                ...?decoration.boxShadow,
            ],
            isEmpty,
            reason:
                'a cast in any decoration under a translucent fill is the '
                'kind that shows through it',
          );
        }
      },
    );
  }
}
