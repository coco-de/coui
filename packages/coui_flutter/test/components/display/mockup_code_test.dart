// The values under test are the design numbers (10 / 16 inset, 28 gutter,
// 21px line box) — naming each one would hide what the assertion is about.

/// Rendered-value tests for the `MockupCode` product defaults: the 10 / 16
/// inset, the `codeSm` text and gutter roles on a 21px line box, and the 28px
/// gutter.
///
/// Each claim is read off a laid-out widget tree (offsets and sizes the user
/// sees), not off the default constants, so a default that is declared but
/// never reaches the screen fails here.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// Resolves `MockupCode` under the test app and hands the result out.
Future<ResolvedMockupCode> _resolve(
  WidgetTester tester, {
  CoreMockupCodeStyle? style,
}) async {
  late ResolvedMockupCode resolved;
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) {
        resolved = resolveMockupCode(context, mockupCodeStyle: style);
        return const SizedBox.shrink();
      },
    ),
  );
  return resolved;
}

/// The frame the lines sit in — the composed `OutlinedContainer`.
Finder get _frame => find.byType(OutlinedContainer);

/// The painted style of the one `Text` showing [data].
TextStyle _styleOf(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data)).style!;

void main() {
  group('MockupCode resolver — product defaults', () {
    testWidgets('the inset is 10 above and below, 16 left and right', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      final padding = resolved.containerStyle.padding!;
      expect(padding.top, 10);
      expect(padding.bottom, 10);
      expect(padding.left, 16);
      expect(padding.right, 16);
    });

    testWidgets('the gutter is 28 wide', (tester) async {
      final resolved = await _resolve(tester);
      expect(resolved.lineNumberWidth, 28);
    });

    testWidgets('text and gutter paint codeSm on a 21px line box', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      for (final style in [resolved.textStyle, resolved.prefixTextStyle]) {
        expect(style.fontSize, 12);
        // `lineHeightPx` travels as a multiplier on the final size, so the
        // painted box is `fontSize * height` = 21 regardless of the face.
        expect(style.fontSize! * style.height!, closeTo(21, 0.001));
        expect(style.fontWeight, FontWeight.w400);
        expect(style.letterSpacing, 0);
      }
    });

    // Colours are not part of this change: the role moved, the slots did not.
    testWidgets('text and gutter keep their colours', (tester) async {
      late ResolvedMockupCode resolved;
      late Color onSurface;
      late Color onSurfaceVariant;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            resolved = resolveMockupCode(context);
            onSurface = scheme
                .resolve(const CoreColor.token(CoreColors.onSurface))
                .toValue();
            onSurfaceVariant = scheme
                .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
                .toValue();
            return const SizedBox.shrink();
          },
        ),
      );
      expect(resolved.textStyle.color, onSurface);
      expect(resolved.prefixTextStyle.color, onSurfaceVariant);
    });

    testWidgets('a caller inset replaces the default on all four sides', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        style: const CoreMockupCodeStyle(padding: CoreEdgeInsets.all(24)),
      );
      final padding = resolved.containerStyle.padding!;
      expect(
        [padding.top, padding.right, padding.bottom, padding.left],
        everyElement(24),
      );
    });
  });

  group('MockupCode widget — the painted face', () {
    /// The solid fills painted by the `Container`s inside the frame.
    Iterable<Color?> fills(WidgetTester tester) => tester
        .widgetList<Container>(
          find.descendant(of: _frame, matching: find.byType(Container)),
        )
        .map((c) => (c.decoration as BoxDecoration?)?.color);

    /// A scheme colour as the screen paints it under the mounted theme.
    Color scheme(WidgetTester tester, CoreColor token) => Theme.of(
      tester.element(find.byType(MockupCode)),
    ).colorScheme.resolve(token).toValue();

    const low = CoreColor.token(CoreColors.surfaceContainerLow);
    const container = CoreColor.token(CoreColors.surfaceContainer);

    for (final dark in [false, true]) {
      testWidgets('the frame is painted surfaceContainerLow in '
          '${dark ? 'dark' : 'light'}', (tester) async {
        await pumpTestApp(
          tester,
          MockupCode.fromString('a'),
          theme: dark ? const ThemeData.dark() : null,
        );

        final face = scheme(tester, low);
        // The two steps are different colours, or this test could not tell
        // the old face from the new one.
        expect(face, isNot(scheme(tester, container)));
        expect(fills(tester), contains(face));
        expect(fills(tester), isNot(contains(scheme(tester, container))));
      });
    }

    testWidgets('the resolver hands the composed frame the same face', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      expect(resolved.containerStyle.backgroundColor, low);
    });

    // The previous face stays reachable: a caller who states it, through the
    // token-exact chain getter, gets that tone.
    testWidgets('a stated surfaceContainer still wins over the default', (
      tester,
    ) async {
      await pumpTestApp(tester, MockupCode.fromString('a').surfaceContainer);

      expect(fills(tester), contains(scheme(tester, container)));
      expect(fills(tester), isNot(contains(scheme(tester, low))));
    });

    // The shared cross-variant theme fill still outranks the default, and the
    // component's own theme outranks that.
    testWidgets('the shared mockup theme fill replaces the default face', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        MockupCode.fromString('a'),
        componentTheme: const CoreComponentTheme(
          mockup: CoreMockupTheme(
            style: CoreMockupStyle(
              backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
            ),
          ),
        ),
      );

      final high = scheme(
        tester,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(fills(tester), contains(high));
      expect(fills(tester), isNot(contains(scheme(tester, low))));
    });

    // Colours are unchanged for the inks: the gutter stays onSurfaceVariant,
    // and both inks stay readable on the new face.
    testWidgets('the inks are readable on the painted face in dark', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        MockupCode.fromString('a'),
        theme: const ThemeData.dark(),
      );

      final face = scheme(tester, low);
      for (final data in const ['1', 'a']) {
        final ink = _styleOf(tester, data).color!;
        final ratio = CoreContrast.ratio(
          CoreColor(ink.toARGB32()),
          CoreColor(face.toARGB32()),
        );
        expect(ratio, greaterThanOrEqualTo(4.5), reason: data);
      }
    });
  });

  group('MockupCode widget — laid-out geometry', () {
    testWidgets('the first line starts 16 right and 10 below the frame edge', (
      tester,
    ) async {
      await pumpTestApp(tester, MockupCode.fromString('a\nb'));

      final frame = tester.getTopLeft(_frame);
      final gutter = tester.getTopLeft(find.text('1'));
      expect(gutter.dx - frame.dx, 16);
      expect(gutter.dy - frame.dy, 10);
    });

    testWidgets('the code column starts one 28px gutter after the inset', (
      tester,
    ) async {
      await pumpTestApp(tester, MockupCode.fromString('a\nb'));

      final gutter = tester.getTopLeft(find.text('1'));
      final code = tester.getTopLeft(find.text('a'));
      expect(code.dx - gutter.dx, 28);
      // Same row, same top: the gutter and the code share one grid.
      expect(code.dy, gutter.dy);
    });

    testWidgets('each row is a 21px line box plus the 4px line spacing', (
      tester,
    ) async {
      await pumpTestApp(tester, MockupCode.fromString('a\nb'));

      final first = tester.getTopLeft(find.text('a'));
      final second = tester.getTopLeft(find.text('b'));
      expect(second.dy - first.dy, 21 + 4);
      expect(tester.getSize(find.text('a')).height, 21);
      expect(tester.getSize(find.text('1')).height, 21);
    });

    testWidgets('the frame height is the inset plus the rows', (tester) async {
      await pumpTestApp(tester, MockupCode.fromString('a\nb'));

      // 10 + 2 × (21 + 4) + 10. Each row carries its line spacing below it,
      // the last one included, so the visible bottom inset is 10 + 4.
      expect(tester.getSize(_frame).height, 70);
    });

    testWidgets('the gutter box is 28 wide', (tester) async {
      await pumpTestApp(tester, MockupCode.fromString('a'));

      final gutterBox = find.ancestor(
        of: find.text('1'),
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(gutterBox.first).width, 28);
    });

    testWidgets('both texts paint with the codeSm face metrics', (
      tester,
    ) async {
      await pumpTestApp(tester, MockupCode.fromString('a'));

      for (final data in const ['1', 'a']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(data),
        );
        expect(paragraph.text.style!.fontSize, 12);
        expect(_styleOf(tester, data).height! * 12, closeTo(21, 0.001));
      }
    });

    testWidgets('the inset follows density', (tester) async {
      // 10 is off the 4px grid: one rung down is 8; 16 → 12.
      await pumpTestApp(
        tester,
        MockupCode.fromString('a'),
        density: .compact,
      );
      final frame = tester.getTopLeft(_frame);
      final gutter = tester.getTopLeft(find.text('1'));
      expect(gutter.dx - frame.dx, 12);
      expect(gutter.dy - frame.dy, 8);
    });
  });
  group('MockupCode widget — line tone', () {
    /// The colour of the paragraph the user sees for [data].
    Color? paintedColor(WidgetTester tester, String data) =>
        tester.renderObject<RenderParagraph>(find.text(data)).text.style!.color;

    /// A scheme colour as the screen paints it under the mounted theme.
    Color scheme(WidgetTester tester, CoreColor token) => Theme.of(
      tester.element(find.byType(MockupCode)),
    ).colorScheme.resolve(token).toValue();

    const lines = [
      CoreCodeLine(text: 'plain'),
      CoreCodeLine(text: 'muted', tone: CoreCodeLineTone.muted),
      CoreCodeLine(text: 'link', tone: CoreCodeLineTone.link),
      CoreCodeLine(text: 'ok', tone: CoreCodeLineTone.success),
      CoreCodeLine(text: 'warn', tone: CoreCodeLineTone.warning),
      CoreCodeLine(text: 'fail', tone: CoreCodeLineTone.error),
    ];
    final expected = <String, CoreColorToken>{
      'plain': CoreColors.onSurface,
      'muted': CoreColors.onSurfaceVariant,
      'link': CoreColors.link,
      'ok': CoreColors.onSuccessContainer,
      'warn': CoreColors.onWarningContainer,
      'fail': CoreColors.onErrorContainer,
    };

    for (final dark in [false, true]) {
      testWidgets('each line paints its tone slot colour in '
          '${dark ? 'dark' : 'light'}', (tester) async {
        await pumpTestApp(
          tester,
          MockupCode.fromList(lines),
          theme: dark ? const ThemeData.dark() : null,
        );

        expected.forEach((data, token) {
          expect(
            paintedColor(tester, data),
            scheme(tester, CoreColor.token(token)),
            reason: data,
          );
        });
      });
    }

    testWidgets('a neutral line paints exactly the colour it painted before '
        'tones existed (onSurface)', (tester) async {
      await pumpTestApp(tester, MockupCode.fromString('a'));

      expect(
        paintedColor(tester, 'a'),
        scheme(tester, const CoreColor.token(CoreColors.onSurface)),
      );
    });

    testWidgets('the tones are different colours, or the test could not tell '
        'them apart', (tester) async {
      await pumpTestApp(tester, MockupCode.fromList(lines));

      final painted = {
        for (final data in expected.keys) paintedColor(tester, data),
      };
      expect(painted, hasLength(expected.length));
    });

    testWidgets('a tone changes only the colour — the line box is the '
        'text own', (tester) async {
      await pumpTestApp(tester, MockupCode.fromList(lines));

      final plain = tester
          .renderObject<RenderParagraph>(find.text('plain'))
          .text
          .style!;
      for (final data in expected.keys) {
        final style = tester
            .renderObject<RenderParagraph>(find.text(data))
            .text
            .style!;
        expect(style.fontSize, plain.fontSize, reason: data);
        expect(style.height, plain.height, reason: data);
        expect(style.fontFamily, plain.fontFamily, reason: data);
        expect(style.fontWeight, plain.fontWeight, reason: data);
      }
    });

    testWidgets('the prefix keeps its own colour whatever the tone', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        MockupCode.fromList(const [
          CoreCodeLine(
            text: 'fail',
            prefix: '1',
            tone: CoreCodeLineTone.error,
          ),
        ]),
      );

      expect(
        paintedColor(tester, '1'),
        scheme(tester, const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
    });

    testWidgets('a stated tone slot recolours that tone only', (tester) async {
      const stated = CoreColor.token(CoreColors.tertiary);
      await pumpTestApp(
        tester,
        MockupCode.fromList(
          lines,
          mockupCodeStyle: const CoreMockupCodeStyle(errorToneColor: stated),
        ),
      );

      expect(paintedColor(tester, 'fail'), scheme(tester, stated));
      expect(
        paintedColor(tester, 'ok'),
        scheme(tester, const CoreColor.token(CoreColors.onSuccessContainer)),
      );
    });

    testWidgets('a recoloured code text recolours neutral lines, and tone '
        'lines keep their slot', (tester) async {
      const stated = CoreColor.token(CoreColors.tertiary);
      await pumpTestApp(
        tester,
        MockupCode.fromList(
          lines,
          mockupCodeStyle: const CoreMockupCodeStyle(
            textStyle: CoreTextStyle(color: stated),
          ),
        ),
      );

      expect(paintedColor(tester, 'plain'), scheme(tester, stated));
      expect(
        paintedColor(tester, 'link'),
        scheme(tester, const CoreColor.token(CoreColors.link)),
      );
    });

    testWidgets('the resolver hands one paint-ready style per tone', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      expect(resolved.toneTextStyles.keys, CoreCodeLineTone.values);
      expect(
        resolved.toneTextStyles[CoreCodeLineTone.neutral]!.color,
        resolved.textStyle.color,
      );
    });
  });
}
