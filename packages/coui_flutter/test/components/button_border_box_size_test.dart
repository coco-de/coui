import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Border widths the height is probed at — one below the point the growth
/// used to start, and three above it.
const List<double> kProbeBorderWidths = [1, 2, 3, 4];

/// The two widths the horizontal assertion compares.
const double kThinBorder = 1;
const double kThickBorder = 4;

/// Both sides of the box grow, so the width delta is twice the difference.
const double kExpectedWidthGrowth = 2 * (kThickBorder - kThinBorder);

/// Layout arrives in fractional logical pixels; this is tighter than any
/// difference the assertion is looking for.
const double kSizeEpsilon = 0.01;

/// A control's height is a token, and a border is not allowed to spend it.
///
/// Flutter's `Container` adds a `BoxDecoration`'s border dimensions on top
/// of the padding it is handed, and the constraint under the button states
/// the token as a minimum, so nothing caps the growth. The Web twin pins
/// the token as a fixed height and lets `box-sizing: border-box` eat the
/// border inward, so the two platforms drew the same button at different
/// heights: 40 on Web, 46 on Flutter under a style whose stroke floor is
/// four.
///
/// Width is deliberately *not* pinned. Web's width is `auto`, where the
/// border adds to the used size exactly as Flutter's does — the two
/// already agreed there, and a fix that deflated both axes would trade the
/// height divergence for a width one. Both directions are asserted below,
/// because checking only the height would let that trade pass.
///
/// Heights are compared against the unbordered button rather than against
/// the token's number, so the assertion holds at any platform scaling —
/// the mobile default puts the natural height above the token, where a
/// literal would be measuring the wrong thing.
///
/// Nothing here is specific to a surface style. The explicit-width group
/// runs under no style at all and reproduces it from a per-instance border
/// width, which is how a caller meets it today.
void main() {
  Future<Size> pumpButton(
    WidgetTester tester, {
    required CoreButtonVariant variant,
    CoreSurfaceStyleId style = .defaultStyle,
    double? borderWidth,
  }) async {
    // Tear the tree down between measurements. Pumping a second app over
    // the first reuses the element tree, and the reused elements kept
    // answering with the *first* configuration — which made every equality
    // assertion in this file pass without measuring anything. The width
    // case is what exposed it: it expects a difference, and got zero. An
    // empty pump forces the next one to build from scratch.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CoUIApp(
        surfaceStyle: style,
        home: Center(
          child: Button(
            onPressed: () {},
            variant: variant,
            buttonStyle: borderWidth == null
                ? null
                : CoreButtonStyle(borderWidth: borderWidth),
            child: const Text('Button'),
          ),
        ),
        theme: ThemeData.fromCore(CoreThemePresets.light),
      ),
    );

    return tester.getSize(find.byType(Button));
  }

  group('a border does not spend the height token', () {
    for (final width in kProbeBorderWidths) {
      testWidgets('borderWidth $width leaves the height where 0 put it', (
        tester,
      ) async {
        final unbordered = await pumpButton(
          tester,
          variant: .outline,
          borderWidth: 0,
        );
        final bordered = await pumpButton(
          tester,
          variant: .outline,
          borderWidth: width,
        );

        expect(
          bordered.height,
          unbordered.height,
          reason:
              'a $width border pushed the control off its own size token — '
              'the container adds the border dimensions and a minimum '
              'cannot cap them',
        );
      });
    }

    testWidgets('the width still grows with the border, as it does on Web', (
      tester,
    ) async {
      final thin = await pumpButton(
        tester,
        variant: .outline,
        borderWidth: kThinBorder,
      );
      final thick = await pumpButton(
        tester,
        variant: .outline,
        borderWidth: kThickBorder,
      );

      expect(
        thick.width - thin.width,
        moreOrLessEquals(kExpectedWidthGrowth, epsilon: kSizeEpsilon),
        reason:
            'Web sizes width by content and lets the border add to it; '
            'pinning the width here would break an axis that agreed',
      );
    });
  });

  group('variants read as one visual unit under a thick-stroke style', () {
    testWidgets('bordered and unbordered variants share a height', (
      tester,
    ) async {
      const CoreSurfaceStyleId style = .neoBrutalism;
      final unbordered = await pumpButton(
        tester,
        variant: .primary,
        style: style,
      );
      final outline = await pumpButton(tester, variant: .outline, style: style);

      expect(outline.height, unbordered.height);
    });
  });

  group('the deflation only applies where the border is actually drawn', () {
    /// A width with no colour behind it draws nothing, so the container
    /// adds nothing — and taking padding out anyway would shrink the
    /// control rather than hold it. `primary` names no border colour in
    /// any state.
    testWidgets('a width on a variant that draws no border changes nothing', (
      tester,
    ) async {
      final plain = await pumpButton(tester, variant: .primary);
      final withWidth = await pumpButton(
        tester,
        variant: .primary,
        borderWidth: kThickBorder,
      );

      expect(withWidth, plain);
    });
  });
}
