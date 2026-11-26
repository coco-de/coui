// The value glyph of a NumberTicker, read off what is drawn.
//
// The default role is `titleLarge` (20 / SemiBold / 140% / −2%). The
// resolver's output is not the evidence here: each case reads the style on
// the `Text` the widget put on screen, and the line box the animation
// draws it in.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kTarget = 2048;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

/// The style of the `Text` the ticker drew for [text].
TextStyle _drawn(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

/// The style the engine paints [text] with: the `RichText` that `Text` built
/// after merging its own style into the ambient `DefaultTextStyle`.
TextStyle _painted(WidgetTester tester, String text) => tester
    .widget<RichText>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    )
    .text
    .style!;

void main() {
  group('NumberTicker value typography', () {
    testWidgets('draws the titleLarge role — size, weight, leading, tracking', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const NumberTicker(value: _kTarget)));

      final role = CoreTypography.coui.titleLarge;
      final style = _drawn(tester, '$_kTarget');
      expect(style.fontSize, role.fontSize);
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.height, role.lineHeight);
      // Tracking is stored as em and drawn as px: −2% of the 20px size.
      expect(style.letterSpacing, role.letterSpacing! * role.fontSize!);
    });

    testWidgets('is no longer the bodyLarge role', (tester) async {
      await tester.pumpWidget(_buildApp(const NumberTicker(value: _kTarget)));

      final old = CoreTypography.coui.bodyLarge;
      final style = _drawn(tester, '$_kTarget');
      expect(style.fontSize, isNot(old.fontSize));
      expect(style.fontWeight, isNot(FontWeight.w400));
      expect(style.height, isNot(old.lineHeight));
    });

    testWidgets('keeps tabular figures so digits hold their advance', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const NumberTicker(value: _kTarget)));

      expect(
        _drawn(tester, '$_kTarget').fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('states no ink — the glyph wears the ambient colour', (
      tester,
    ) async {
      // A colour no theme would pick, set as the ambient text colour: if the
      // role (or anything else in the default) stated an ink of its own, the
      // glyph would stop wearing this one.
      const ambient = Color(0xFF123456);
      await tester.pumpWidget(
        _buildApp(
          const DefaultTextStyle(
            style: TextStyle(color: ambient),
            child: Column(
              children: [
                NumberTicker(value: _kTarget),
                NumberTicker(
                  value: 7,
                  numberTickerStyle: CoreNumberTickerStyle(
                    textStyle: CoreTextStyle.token(CoreTextStyles.bodyLarge),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // The role change moves size and weight, not colour: neither role's
      // `TextStyle` carries a colour, so the ink is the ambient one.
      expect(_drawn(tester, '$_kTarget').color, isNull);
      expect(_drawn(tester, '7').color, isNull);
      // And what is actually painted is that ambient colour — read off the
      // `RichText` the `Text` built after merging `DefaultTextStyle`.
      expect(_painted(tester, '$_kTarget').color, ambient);
      expect(_painted(tester, '7').color, ambient);
    });

    testWidgets('a per-instance size overlay wins and the role stays', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const NumberTicker(
            value: _kTarget,
            numberTickerStyle: CoreNumberTickerStyle(
              textStyle: CoreTextStyle(fontSize: 32),
            ),
          ),
        ),
      );

      final style = _drawn(tester, '$_kTarget');
      expect(style.fontSize, 32);
      // The overlay states a size only; the role's weight is still drawn.
      expect(style.fontWeight, FontWeight.w600);
    });

    testWidgets('a theme-level style overrides the default role', (
      tester,
    ) async {
      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(
              coreComponentTheme: CoreComponentTheme(
                numberTicker: CoreNumberTickerTheme(
                  style: CoreNumberTickerStyle(
                    textStyle: CoreTextStyle.token(
                      CoreTextStyles.headlineSmall,
                    ),
                  ),
                ),
              ),
            ),
            child: NumberTicker(value: _kTarget),
          ),
        ),
      );

      expect(
        _drawn(tester, '$_kTarget').fontSize,
        CoreTypography.coui.headlineSmall.fontSize,
      );
    });
  });

  group('NumberTicker line box while counting', () {
    // `MaterialApp` hands its home a tight screen-sized box, which would make
    // every `Text` as tall as the window; `Align` loosens it so the size read
    // back is the line box the glyphs are drawn in.
    Widget loose(Widget child) => _buildApp(Align(child: child));

    double expectedLine() {
      final role = CoreTypography.coui.titleLarge;
      return role.fontSize! * role.lineHeight!;
    }

    testWidgets('holds the titleLarge line height from the first frame to the '
        'last', (tester) async {
      await tester.pumpWidget(
        loose(const NumberTicker(initialValue: 0, value: _kTarget)),
      );

      final heights = <double>[];
      final shown = <String>[];
      // Step through the whole 500 ms count-up and past its end: elapsed
      // 0, 60, 180, 300, 420, 540, 740 ms.
      for (final ms in [0, 60, 120, 120, 120, 120, 200]) {
        await tester.pump(Duration(milliseconds: ms));
        shown.add(tester.widget<Text>(find.byType(Text)).data!);
        heights.add(tester.getSize(find.byType(Text)).height);
      }

      // The digits really changed (it was counting), the box did not.
      expect(shown.toSet().length, greaterThan(2), reason: 'seen: $shown');
      expect(shown.last, '$_kTarget');
      expect(heights, everyElement(closeTo(expectedLine(), 0.01)));
      expect(expectedLine(), closeTo(28, 0.01));
    });

    testWidgets('a single digit and a four-digit value share one line box', (
      tester,
    ) async {
      Future<double> heightOf(num value) async {
        await tester.pumpWidget(loose(NumberTicker(value: value)));
        return tester.getSize(find.byType(Text)).height;
      }

      final one = await heightOf(7);
      final four = await heightOf(_kTarget);
      expect(one, closeTo(expectedLine(), 0.01));
      expect(four, closeTo(expectedLine(), 0.01));
    });
  });
}
