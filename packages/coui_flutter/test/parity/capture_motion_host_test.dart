import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'capture_motion_host.dart';

void main() {
  Future<Uint8List> pixels(WidgetTester tester, GlobalKey key) async {
    final result = await tester.runAsync(() async {
      final box =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await box.toImage();
      final data = await image.toByteData();
      image.dispose();
      return data!.buffer.asUint8List();
    });
    return result!;
  }

  for (final variant in CoreLoadingVariant.values) {
    testWidgets('$variant stays at its initial paint during capture settling', (
      tester,
    ) async {
      final key = GlobalKey();
      await pumpTestApp(
        tester,
        captureMotionHost(
          component: 'loading',
          child: RepaintBoundary(
            key: key,
            child: Loading(variant: variant),
          ),
        ),
      );
      final first = await pixels(tester, key);
      await tester.pump(const Duration(milliseconds: 537));
      expect(await pixels(tester, key), orderedEquals(first));
    });
  }

  final placeholders = <String, Widget>{
    'default': const Skeleton(width: 200, height: 20),
    'circle': const Skeleton.circle(size: 48),
    'text': const SizedBox(width: 200, child: Skeleton.text()),
    'region': const LoadingRegion(
      child: Column(
        mainAxisSize: .min,
        children: [Skeleton(width: 200, height: 20)],
      ),
    ),
  };
  for (final entry in placeholders.entries) {
    testWidgets(
      '${entry.key} keeps its initial pulse during capture settling',
      (
        tester,
      ) async {
        final key = GlobalKey();
        await pumpTestApp(
          tester,
          captureMotionHost(
            component: entry.key == 'region' ? 'loading-region' : 'skeleton',
            child: RepaintBoundary(key: key, child: entry.value),
          ),
        );
        final first = await pixels(tester, key);
        await tester.pump(const Duration(milliseconds: 537));
        expect(await pixels(tester, key), orderedEquals(first));
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets('ordinary runtime ${entry.key} still pulses', (tester) async {
      final key = GlobalKey();
      await pumpTestApp(
        tester,
        captureMotionHost(
          component: 'ordinary-runtime',
          child: RepaintBoundary(key: key, child: entry.value),
        ),
      );
      final first = await pixels(tester, key);
      await tester.pump(const Duration(milliseconds: 537));
      expect(await pixels(tester, key), isNot(orderedEquals(first)));
    });
  }

  testWidgets('ordinary runtime loading still animates', (tester) async {
    final key = GlobalKey();
    await pumpTestApp(
      tester,
      captureMotionHost(
        component: 'ordinary-runtime',
        child: RepaintBoundary(key: key, child: const Loading()),
      ),
    );
    final first = await pixels(tester, key);
    await tester.pump(const Duration(milliseconds: 137));
    expect(await pixels(tester, key), isNot(orderedEquals(first)));
  });
}
