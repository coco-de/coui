// Where a drawer paints its cast. Flutter's `BoxDecoration.boxShadow` fills a
// shape behind the box and lets the fill paint over it; CSS paints an outer
// `box-shadow` outside the border box only. Under an opaque fill the two look
// the same. Under a translucent one — the glass styles — a cast in the
// decoration showed through the panel, on Flutter only, so the panel paints
// it outside the box instead (`ResolvedDrawer.castOutsideBox`).
import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

/// Mounts an app under [style], opens a left drawer over it and lets the
/// drawer arrive.
Future<void> _open(WidgetTester tester, CoreSurfaceStyleId style) async {
  late w.BuildContext app;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: w.Builder(
        builder: (context) {
          app = context;

          return const w.SizedBox.shrink();
        },
      ),
    ),
  );
  unawaited(
    openDrawer<void>(
      context: app,
      side: .left,
      builder: (_) => const Drawer(content: w.SizedBox(width: 120, height: 60)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// What the drawer resolved, read in the drawer's own context.
ResolvedDrawer _resolved(WidgetTester tester) =>
    resolveDrawer(tester.element(find.byType(Drawer)), side: .left);

/// The casts painted outside a box under the drawer.
List<InjectedCast> _casts(WidgetTester tester) => tester
    .widgetList<InjectedCast>(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(InjectedCast),
      ),
    )
    .toList();

/// The decorations under the drawer.
List<BoxDecoration> _decorations(WidgetTester tester) => tester
    .widgetList<w.DecoratedBox>(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(w.DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .toList();

/// The decoration that paints the panel's fill.
BoxDecoration _panel(WidgetTester tester, ResolvedDrawer resolved) =>
    _decorations(tester).singleWhere(
      (decoration) => decoration.color == resolved.panelBackgroundColor,
    );

void main() {
  // The premises of the table below: without a translucent panel the
  // outside-the-box branch would never run, and without an opaque one the
  // decoration branch would never run.
  testWidgets('a glass panel is translucent', (tester) async {
    await _open(tester, CoreSurfaceStyleId.liquidGlass);
    expect(_resolved(tester).panelBackgroundColor.a, lessThan(1));
  });

  testWidgets('a default panel is opaque', (tester) async {
    await _open(tester, CoreSurfaceStyleId.defaultStyle);
    expect(_resolved(tester).panelBackgroundColor.a, 1);
  });

  for (final style in CoreSurfaceStyleId.values) {
    testWidgets(
      'under ${style.name} the cast is painted once, outside the box exactly '
      'where the fill is translucent',
      (tester) async {
        await _open(tester, style);
        final resolved = _resolved(tester);
        final outside = resolved.panelBackgroundColor.a < 1;

        expect(resolved.castOutsideBox, outside);
        expect(
          [for (final cast in _casts(tester)) cast.shadows],
          outside ? [resolved.panelBoxShadow] : isEmpty,
        );
        expect(
          _panel(tester, resolved).boxShadow,
          outside ? isNull : resolved.panelBoxShadow,
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
