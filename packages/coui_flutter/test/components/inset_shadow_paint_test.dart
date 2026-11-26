import 'dart:ui' as ui;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A hard inset layer pushed in from the top-left.
const _inset = [
  (
    offsetX: 10.0,
    offsetY: 10.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: true,
  ),
];

/// The same layer, outward.
const _outer = [
  (
    offsetX: 10.0,
    offsetY: 10.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

/// Renders the surface and reads its pixels back.
///
/// The question — does an inset layer land inside the surface — is only
/// answerable in painted output. A resolver assertion would pass on a
/// stack that never reaches the canvas, which is the shape of the defect
/// this replaces.
Future<ui.Image> _render(
  WidgetTester tester,
  List<CoreShadowLayer> shadow,
) async {
  final key = GlobalKey();

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: OutlinedContainer(
            containerStyle: CoreOutlinedContainerStyle(
              width: 80,
              height: 80,
              borderRadius: CoreBorderRadius.zero,
              backgroundColor: const CoreColor.token(CoreColors.surface),
              boxShadow: shadow,
            ),
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  return boundary.toImage();
}

Future<int> _luminanceAt(ui.Image image, int x, int y) async {
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final i = (y * image.width + x) * 4;

  return data.getUint8(i);
}

void main() {
  testWidgets('an inset layer darkens the inside, not the outside', (
    tester,
  ) async {
    late int insetNearEdge;
    late int insetMiddle;

    await tester.runAsync(() async {
      final image = await _render(tester, _inset);
      // Just inside the top-left corner, where a shadow pushed in from
      // that corner has to land, and the middle, which it must not reach.
      insetNearEdge = await _luminanceAt(image, 3, 3);
      insetMiddle = await _luminanceAt(image, 60, 60);
    });

    expect(
      insetNearEdge,
      lessThan(insetMiddle),
      reason: 'the inner edge must be darker than the middle',
    );
  });

  testWidgets('an outer layer leaves the inside alone', (tester) async {
    late int outerNearEdge;
    late int outerMiddle;

    await tester.runAsync(() async {
      final image = await _render(tester, _outer);
      outerNearEdge = await _luminanceAt(image, 3, 3);
      outerMiddle = await _luminanceAt(image, 60, 60);
    });

    expect(
      outerNearEdge,
      outerMiddle,
      reason:
          'an outward shadow is behind the surface, so it shows nothing '
          'inside it — this is the half that already worked',
    );
  });

  testWidgets('a surface with no inset layer paints no overlay', (
    tester,
  ) async {
    late int plainEdge;
    late int plainMiddle;

    await tester.runAsync(() async {
      final image = await _render(tester, const []);
      plainEdge = await _luminanceAt(image, 3, 3);
      plainMiddle = await _luminanceAt(image, 60, 60);
    });

    expect(plainEdge, plainMiddle);
  });
}
