import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _white = 0xFFFFFFFF;

/// A `BorderSide` of width 0 is not "no border" in Flutter: it paints a
/// hairline, one physical pixel wide. The web's `border-width: 0` paints
/// nothing, so a box that states a border width of 0 — to sit inside a frame
/// that draws the border — must not paint one.
Widget _buildApp(Widget child, GlobalKey boundary) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: RepaintBoundary(
        key: boundary,
        child: ColoredBox(
          color: const Color(_white),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 240, child: child),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The pixel at [local] (the box's own coordinates) of the box [find] finds,
/// read from the repaint boundary [key].
Future<int> _pixelAt(
  WidgetTester tester,
  GlobalKey key,
  Finder find,
  Offset local,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final origin = boundary.localToGlobal(Offset.zero);
  final at = tester.getTopLeft(find) + local - origin;
  final rgba = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    return (image.width, data!);
  });
  final width = rgba!.$1;
  final bytes = rgba.$2;
  final i = (at.dy.round() * width + at.dx.round()) * 4;
  return (bytes.getUint8(i + 3) << 24) |
      (bytes.getUint8(i) << 16) |
      (bytes.getUint8(i + 1) << 8) |
      bytes.getUint8(i + 2);
}

void main() {
  const fill = CoreColor.token(CoreColors.surface);

  final boxes = <String, ({Widget Function(double width) build, Type type})>{
    'TextArea': (
      type: TextArea,
      build: (width) => TextArea(
        textAreaStyle: CoreTextAreaStyle(
          backgroundColor: fill,
          borderWidth: width,
          activeBorderWidth: width,
        ),
      ),
    ),
    'TextField': (
      type: TextField,
      build: (width) => TextField(
        textFieldStyle: CoreTextFieldStyle(
          backgroundColor: fill,
          borderWidth: width,
          activeBorderWidth: width,
        ),
      ),
    ),
  };

  for (final entry in boxes.entries) {
    group('${entry.key} with a border width of 0', () {
      testWidgets('draws no border — not a hairline', (tester) async {
        final key = GlobalKey();
        await tester.pumpWidget(_buildApp(entry.value.build(0), key));
        await tester.pumpAndSettle();
        final box = find.byType(entry.value.type);
        // The top edge row: a hairline would colour it, the fill leaves it
        // white like the page around the box.
        expect(await _pixelAt(tester, key, box, const Offset(120, 0)), _white);
        expect(await _pixelAt(tester, key, box, const Offset(0, 12)), _white);
      });

      testWidgets('a stated width still draws its border', (tester) async {
        final key = GlobalKey();
        await tester.pumpWidget(_buildApp(entry.value.build(1), key));
        await tester.pumpAndSettle();
        final box = find.byType(entry.value.type);
        expect(
          await _pixelAt(tester, key, box, const Offset(120, 0)),
          isNot(_white),
        );
      });
    });
  }
}
