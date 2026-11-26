// The digit of a Countdown, read off what is drawn.
//
// The widget is one number: a unit box, a unit word and a width floor around
// it are the caller's, so what these cases pin is the number itself — the
// `headlineLarge` role in the primary ink with tabular figures — and the
// line box it is drawn in while the value changes.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    // `MaterialApp` hands its home a tight screen-sized box, which would make
    // every `Text` as tall as the window; `Align` loosens it so the size read
    // back is the line box the glyphs are drawn in.
    home: Theme(
      data: const ThemeData(),
      child: Align(child: child),
    ),
  );
}

/// The style of the `Text` the countdown drew for [text].
TextStyle _drawn(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  group('Countdown digit typography', () {
    testWidgets('draws the headlineLarge role — size, weight, leading, '
        'tracking', (tester) async {
      await tester.pumpWidget(_buildApp(const Countdown(value: 12)));

      final role = CoreTypography.coui.headlineLarge;
      final style = _drawn(tester, '12');
      expect(style.fontSize, role.fontSize);
      expect(style.fontSize, 32);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.height, role.lineHeight);
      // Tracking is stored as em and drawn as px: −2% of the 32px size.
      expect(style.letterSpacing, role.letterSpacing! * role.fontSize!);
    });

    testWidgets('keeps tabular figures so every digit holds one advance', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const Countdown(value: 12)));

      expect(
        _drawn(tester, '12').fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('is drawn in the on-surface ink', (tester) async {
      await tester.pumpWidget(_buildApp(const Countdown(value: 12)));

      final ink = Theme.of(tester.element(find.byType(Countdown))).colorScheme
          .resolve(const CoreColor.token(CoreColors.onSurface))
          .toValue();
      expect(_drawn(tester, '12').color, ink);
    });
  });

  group('Countdown line box while the value changes', () {
    testWidgets('holds one line height across values and digit counts', (
      tester,
    ) async {
      final role = CoreTypography.coui.headlineLarge;
      final expected = role.fontSize! * role.lineHeight!;
      final heights = <double>[];

      // 12 → 08 → 30 → 15, then a three-digit day count: the line box is the
      // role's own whichever value is on screen.
      for (final value in [12, 8, 30, 15, 100]) {
        await tester.pumpWidget(
          _buildApp(Countdown(value: value, max: 365)),
        );
        // Let the cross-fade finish so only the new number is on screen.
        await tester.pump(const Duration(milliseconds: 300));
        heights.add(tester.getSize(find.byType(Text)).height);
      }

      // One box for every value. The engine rounds a line box to whole
      // pixels (44.8 is drawn as 45), so the role's computed height is
      // matched to within a pixel and the value-independence is exact.
      expect(heights.toSet(), hasLength(1), reason: 'heights: $heights');
      expect(heights.first, closeTo(expected, 1));
    });
  });
}
