import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

Widget _client({required double width, required double height}) => Center(
  child: SizedBox(
    width: width,
    height: height,
    child: ScrollableClient(
      diagonalDragBehavior: .free,
      builder: (context, offset, viewportSize, child) => Container(
        key: const Key('content'),
        color: const material.Color(0xFFEEEEEE),
        width: 1200,
        height: 560,
        child: Text('vp ${viewportSize.width.toStringAsFixed(0)}'),
      ),
    ),
  ),
);

void main() {
  testWidgets('lays out larger-than-viewport content at its natural size', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(_client(width: 600, height: 320)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('content')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('content'))),
      const Size(1200, 560),
    );
    // The builder reports the real viewport width on the first settled frame
    // (no zero-size flash).
    expect(find.text('vp 600'), findsOneWidget);
  });

  testWidgets('survives a viewport resize without orphaning children (#2136)', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(_client(width: 600, height: 320)));
    await tester.pumpAndSettle();

    // The docs Flutter-web embed resizes the canvas (0 -> final) right after
    // the first paint. A size-dependent ChildVicinity identity minted a fresh
    // child on the new size and orphaned the previous one, whose paint extent
    // is never computed — so isVisible / applyPaintTransform threw on paint
    // and pointer hit-tests and the viewport rendered blank.
    // 760x420 both fit inside the default 800x600 test surface so the viewport
    // really takes the requested width.
    await tester.pumpWidget(_buildApp(_client(width: 760, height: 420)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'paint after resize');

    // localToGlobal on the (formerly orphaned) child drives applyPaintTransform
    // and a tap drives hitTestChildren — both crashed before the fix.
    await tester.tapAt(tester.getCenter(find.byKey(const Key('content'))));
    await tester.pump();
    expect(
      tester.takeException(),
      isNull,
      reason: 'applyPaintTransform + hitTest after resize',
    );

    // The live viewport size reaches the builder after the resize.
    expect(find.text('vp 760'), findsOneWidget);
  });
}
