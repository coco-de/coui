/// A loaded glyph must reserve the same declared box as its placeholder.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => Theme(
  data: const ThemeData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

Icon _icon(int width, int height, double size) {
  final name = IconName('test-size', 'glyph-$width-$height');
  IconResolver.instance.register(
    name.id,
    IconSvgData(
      body: '<path fill="currentColor" d="M2 1h7v4H5v9H2z"/>',
      width: width,
      height: height,
    ),
  );
  return Icon(name, iconStyle: CoreIconStyle(size: size));
}

void main() {
  for (final (width, height) in [(24, 24), (30, 20), (20, 30)]) {
    for (final size in [16.0, 24.0, 60.0]) {
      testWidgets('$width/$height glyph retains a $size square layout box', (
        tester,
      ) async {
        await tester.pumpWidget(_app(_icon(width, height, size)));
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byType(Icon)), Size.square(size));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the caller can still impose a tight non-square box', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(SizedBox(width: 40, height: 20, child: _icon(30, 20, 60))),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(Icon)), const Size(40, 20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('finite parent maxima still constrain the declared size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 20, maxHeight: 10),
          child: _icon(20, 30, 60),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(Icon)), const Size(20, 10));
    expect(tester.takeException(), isNull);
  });
}
