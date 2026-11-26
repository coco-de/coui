import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<List<int>> _pixels(
  WidgetTester tester, {
  required CoreOutlinedContainerBorderStyle style,
  required double width,
  required bool dark,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final key = GlobalKey();
  await tester.pumpWidget(
    buildTestApp(
      Center(
        child: RepaintBoundary(
          key: key,
          child: OutlinedContainer(
            containerStyle: CoreOutlinedContainerStyle(
              width: 64,
              height: 64,
              backgroundColor: const CoreColor(0xFFFFFFFF),
              borderColor: const CoreColor(0xFFFF0000),
              borderWidth: width,
              borderStyle: style,
              borderRadius: CoreBorderRadius.zero,
              boxShadow: const [],
            ),
          ),
        ),
      ),
      theme: ThemeData.fromCore(
        dark ? CoreThemePresets.dark : CoreThemePresets.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    image.dispose();
    return bytes!.buffer.asUint8List().toList();
  }))!;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('none ignores nonzero width and opaque color, dark=$dark', (
      tester,
    ) async {
      final baseline = await _pixels(
        tester,
        style: .none,
        width: 0,
        dark: dark,
      );
      final hidden = await _pixels(tester, style: .none, width: 2, dark: dark);
      expect(hidden, baseline);
      const child = Key('none-child');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        buildTestApp(
          const SizedBox(
            width: 40,
            height: 40,
            child: OutlinedContainer(
              containerStyle: CoreOutlinedContainerStyle(
                borderStyle: .none,
                borderWidth: 2,
                borderColor: CoreColor(0xffff0000),
              ),
              child: SizedBox.expand(key: child),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(child)), const Size(40, 40));
    });
    for (final style in CoreOutlinedContainerBorderStyle.values) {
      testWidgets('zero $style paints no hairline, dark=$dark', (tester) async {
        final none = await _pixels(tester, style: .none, width: 0, dark: dark);
        final zero = await _pixels(tester, style: style, width: 0, dark: dark);
        expect(zero, none);
        if (style != .none) {
          final visible = await _pixels(
            tester,
            style: style,
            width: 2,
            dark: dark,
          );
          expect(visible, isNot(none));
        }
      });
    }
  }
}
