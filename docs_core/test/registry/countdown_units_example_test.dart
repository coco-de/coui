import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/examples/flutter/countdown/countdown_units_example.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Use the docs' actual font; Flutter's square test font cannot establish
    // tabular glyph advances or the 100/99 width boundary.
    var root = Directory.current;
    while (!Directory('${root.path}/docs_site/fonts').existsSync()) {
      if (root.parent.path == root.path) throw StateError('docs_site/fonts not found');
      root = root.parent;
    }
    final loader = FontLoader(CoreFontFamily.sans);
    for (final weight in ['Regular', 'Bold']) {
      loader.addFont(
        File('${root.path}/docs_site/fonts/Pretendard-$weight.otf').readAsBytes().then(ByteData.sublistView),
      );
    }
    await loader.load();
  });

  final scenarios = [
    for (final tier in CoreBreakpointTier.values)
      for (final density in CoreDensity.values) (tier: tier, density: density, scale: 1.0),
    (tier: CoreBreakpointTier.desktop, density: CoreDensity.standard, scale: 1.25),
  ];
  for (final (:tier, :density, :scale) in scenarios) {
    for (final dark in [false, true]) {
      testWidgets('shared numeral width, boundary and tick at $tier/$density scale=$scale dark=$dark', (tester) async {
        final theme = ThemeData.fromCore(
          (dark ? CoreThemePresets.previewDark : CoreThemePresets.previewLight).copyWith(
            textScaling: scale,
            sizeScaling: 1,
            radiusScaling: 1,
          ),
        );
        Future<void> pump(int days, {bool settle = true}) async {
          await tester.pumpWidget(
            CoUIApp(
              theme: theme,
              typographyTier: tier,
              density: density,
              home: Center(
                child: RepaintBoundary(
                  key: const ValueKey('countdown-capture'),
                  child: CountdownUnitsExample(days: days),
                ),
              ),
            ),
          );
          if (settle) await tester.pumpAndSettle();
        }

        List<double> verify() {
          final boxes = [for (var i = 0; i < 4; i++) find.byKey(ValueKey('countdown-unit-$i'))];
          final widths = boxes.map((box) => tester.getSize(box).width).toList();
          final digits = find.descendant(of: find.byType(Countdown), matching: find.byType(Text));
          final numberWidths = [
            for (final digit in digits.evaluate()) tester.getSize(find.byWidget(digit.widget)).width,
          ];
          final expected = math.max(
            CoreSize.size56,
            numberWidths.reduce(math.max) + 2 * density.space(CoreSpace.space8),
          );
          for (var i = 0; i < 4; i++) {
            expect(widths[i], closeTo(expected, 0.01));
            final cell = tester.getRect(boxes[i]);
            for (final text in find.descendant(of: boxes[i], matching: find.byType(Text)).evaluate()) {
              final rect = tester.getRect(find.byWidget(text.widget));
              expect(rect.center.dx, closeTo(cell.center.dx, 0.01));
              expect(rect.left, greaterThanOrEqualTo(cell.left + density.space(CoreSpace.space8) - 0.01));
              expect(rect.right, lessThanOrEqualTo(cell.right - density.space(CoreSpace.space8) + 0.01));
            }
          }
          for (final widget in tester.widgetList<Text>(digits)) {
            expect(widget.style!.fontFeatures, contains(const FontFeature.tabularFigures()));
          }
          expect(tester.takeException(), isNull);
          final rowWidth = tester.getSize(find.byKey(const ValueKey('countdown-capture'))).width;
          expect(rowWidth, closeTo(widths.first * 4 + 3 * density.space(CoreSpace.space8), 0.01));
          return widths;
        }

        Future<void> capture(int days) async {
          final evidence = Platform.environment['COUI_COUNTDOWN_EVIDENCE_DIR'];
          if (evidence == null || tier != CoreBreakpointTier.desktop || density != CoreDensity.standard || scale != 1) {
            return;
          }
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('countdown-capture')));
          await tester.runAsync(() async {
            Directory(evidence).createSync(recursive: true);
            final image = await boundary.toImage(pixelRatio: 2);
            try {
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              File(
                '$evidence/flutter-${dark ? 'dark' : 'light'}-$days.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }

        await pump(101);
        final before = verify();
        await pump(100);
        expect(verify(), before);
        expect(find.text('100'), findsOneWidget);
        await capture(100);
        // Outgoing 100 stays in AnimatedSwitcher's intrinsic stack until its
        // fade ends. All siblings still share that width during the fade.
        await pump(99, settle: false);
        verify();
        await tester.pumpAndSettle();
        final after = verify();
        await capture(99);
        expect(after.first, lessThanOrEqualTo(before.first));
        if (before.first > CoreSize.size56) expect(after.first, lessThan(before.first));
        await pump(98);
        expect(verify(), after);
        await pump(365);
        verify();
        expect(find.text('365'), findsOneWidget);
        // The caller's explicit max is actually used, not a CSS-only sample.
        await pump(400);
        verify();
        expect(find.text('365'), findsOneWidget);
        expect(find.text('400'), findsNothing);
        // Kept with the test output as measurement evidence.
        debugPrint('Countdown Flutter $tier/$density scale=$scale dark=$dark 100=$before 99=$after');
      });
    }
  }
}
