import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'flutter_property_snapshot.dart';
import 'parity_capture_binding.dart';

void main() {
  ParityCaptureBinding();

  testWidgets('public Card paint uses the Gaussian recorded by the capture', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      kFlutterPreviewRegistry['card']!('elevated'),
      theme: ThemeData.fromCore(CoreThemePresets.light),
    );
    await tester.pump(const Duration(seconds: 1));
    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.boxShadow?.isNotEmpty ?? false);
    expect(decorations, isNotEmpty);
    expect(debugDisableShadows, isFalse);

    for (final decoration in decorations) {
      final json = buildFlutterPropertySnapshotJson(
        key: 'card',
        probeRole: 'root',
        decoration: decoration,
      );
      final observed = (json['boxShadow']! as List)
          .cast<Map<String, Object?>>();
      final shadows = decoration.boxShadow!;
      expect(observed, hasLength(shadows.length));
      expect(json['shadowBlurUnit'], 'css-radius');
      for (var i = 0; i < shadows.length; i++) {
        final shadow = shadows[i];
        expect(shadow.blurSigma, greaterThan(0));
        expect(
          shadow.toPaint().maskFilter.toString(),
          ui.MaskFilter.blur(shadow.blurStyle, shadow.blurSigma).toString(),
        );
        expect(observed[i]['blur'], shadow.blurSigma * 2);
      }
    }
  });

  testWidgets('the next capture retains masks and the SDK painting invariant', (
    tester,
  ) async {
    const shadow = BoxShadow(blurRadius: 12, blurStyle: ui.BlurStyle.outer);
    await pumpTestApp(
      tester,
      const DecoratedBox(
        decoration: BoxDecoration(boxShadow: [shadow]),
        child: SizedBox(width: 40, height: 40),
      ),
      theme: ThemeData.fromCore(CoreThemePresets.light),
    );
    expect(debugDisableShadows, isFalse);
    expect(shadow.toPaint().maskFilter, isNotNull);
    final json = buildFlutterPropertySnapshotJson(
      key: 'outer',
      probeRole: 'root',
      decoration: const BoxDecoration(boxShadow: [shadow]),
    );
    final layer = (json['boxShadow']! as List).single as Map;
    expect(layer['blurStyle'], 'outer');
    expect(layer['blur'], 14.86);
    expect(tester.takeException(), isNull);
  });
}
