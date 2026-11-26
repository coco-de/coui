import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'capture_body_probe.dart';
import 'capture_host.dart';
import 'parity_fonts.dart';

void main() {
  setUpAll(loadParityFonts);
  for (final available in [400.0, 800.0]) {
    for (final device in [true, false]) {
      testWidgets(
        '${device ? 'device' : 'container'} body under $available host',
        (tester) async {
          tester.view.physicalSize = Size(
            available * tester.view.devicePixelRatio,
            1200 * tester.view.devicePixelRatio,
          );
          addTearDown(tester.view.reset);
          final root = GlobalKey();
          final boundary = GlobalKey();
          await pumpTestApp(
            tester,
            captureHost(
              child: RepaintBoundary(
                key: boundary,
                child: KeyedSubtree(
                  key: root,
                  child: device
                      ? const MockupDevice(child: SizedBox.shrink())
                      : const ResponsiveContainer(
                          maxWidth: .sm,
                          child: SizedBox(height: 24),
                        ),
                ),
              ),
            ),
          );
          final geometry = captureBodyGeometry(
            root.currentContext!,
            boundary.currentContext!,
          );
          final expectedWidth = device
              ? CoreMockupDeviceStyle.defaultWidthFor(.realistic)
              : available.clamp(
                  0.0,
                  CoreResponsiveContainerMaxWidth.sm.maxWidth!,
                );
          expect(tester.getSize(find.byKey(root)).width, available);
          expect(geometry.width, expectedWidth);
          expect(geometry.left, (available - expectedWidth) / 2);
        },
      );
    }
  }
  testWidgets('a non-Align root is rejected rather than guessed', (
    tester,
  ) async {
    final root = GlobalKey();
    final boundary = GlobalKey();
    await pumpTestApp(
      tester,
      RepaintBoundary(
        key: boundary,
        child: SizedBox(key: root, width: 40, height: 20),
      ),
    );
    expect(
      () => captureBodyGeometry(root.currentContext!, boundary.currentContext!),
      throwsStateError,
    );
  });
}
