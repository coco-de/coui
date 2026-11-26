// The default values are the fixture data — naming each one would hide the
// number the assertion is about.

/// Read-back tests for the defaults of `CodeSnippet`: the 8 corner, the 10 /
/// 12 padding, the 12 gutter gap, the 6 copy-button seat, the `codeSm` role
/// with its 21px line box on both the code and the line-number gutter, and
/// the colours — the quiet face, the borderless pair, the code ink, the
/// gutter ink, the copy glyph (which states none, so it follows the copy
/// button) and the copy button's plain focus ring.
///
/// A declared default that no resolver reads looks finished from the
/// authoring side and changes nothing on screen, so these read the resolved
/// values, and some of them read the painted boxes.
///
/// The painted tests come first and are kept to two pumped snippets:
/// `CodeSnippet` caches its syntax highlighter in static fields, so a later
/// pump in the same file can stay in the loading branch (see
/// `code_snippet_test.dart`). The measurements that need the settled branch —
/// the gutter — therefore sit before everything else.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// Three lines, so the gutter has three rows to put against three code rows.
const _kThreeLines = "void main() {\n  print('hi');\n}";

/// The code roles' fixed line box — the 21px grid.
const double _kBox = CoreLineBox.px21;

Future<ResolvedCodeSnippet> _resolve(
  WidgetTester tester, {
  CoreCodeSnippetStyle? style,
  ThemeData theme = const ThemeData(),
}) async {
  late ResolvedCodeSnippet resolved;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: theme,
        child: Builder(
          builder: (context) {
            resolved = resolveCodeSnippet(context, codeSnippetStyle: style);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return resolved;
}

/// The drawn line box of [style] in logical px: `height × fontSize`.
double _lineBox(TextStyle style) => style.height! * style.fontSize!;

void main() {
  group('CodeSnippet defaults — painted', () {
    testWidgets('code and gutter rows share one 21px grid', (tester) async {
      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(),
            child: CodeSnippet(
              code: _kThreeLines,
              mode: 'dart',
              showLineNumbers: true,
              showCopyButton: false,
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // The gutter is a settled-branch widget; finding it proves the
      // highlighter loaded and this is the real two-column layout.
      for (final n in ['1', '2', '3']) {
        expect(
          tester.getSize(find.text(n)).height,
          _kBox,
          reason: 'gutter row $n',
        );
      }
      final code = find.byType(material.SelectableText);
      expect(tester.getSize(code).height, 3 * _kBox);
      // Row N of the gutter and row N of the code start at the same y.
      expect(
        tester.getTopLeft(find.text('1')).dy,
        tester.getTopLeft(code).dy,
      );
      expect(
        tester.getTopLeft(find.text('3')).dy -
            tester.getTopLeft(find.text('1')).dy,
        2 * _kBox,
      );
      // The gap between the numbers and the code is the 12 gutter margin.
      expect(
        tester.getTopLeft(code).dx - tester.getTopRight(find.text('1')).dx,
        CoreSpace.space12,
      );
    });

    testWidgets('a one-line snippet is 10 + 21 + 10 tall inside its border', (
      tester,
    ) async {
      late ResolvedCodeSnippet resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Builder(
              builder: (context) {
                resolved = resolveCodeSnippet(context);
                return const Align(
                  alignment: Alignment.topLeft,
                  child: CodeSnippet(
                    code: "print('hi');",
                    mode: 'dart',
                    showCopyButton: false,
                  ),
                );
              },
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final border = resolved.containerStyle.borderWidth ?? 0;
      expect(
        tester.getSize(find.byType(OutlinedContainer)).height,
        10 + _kBox + 10 + 2 * border,
      );
      // And the block has no border, so the 41 is the whole of it — a
      // hairline in the border colour would add to it.
      expect(
        tester.getSize(find.byType(OutlinedContainer)).height,
        10 + _kBox + 10,
      );
    });
  });

  group('CodeSnippet defaults — resolved geometry', () {
    testWidgets('the corner is radius8', (tester) async {
      final resolved = await _resolve(tester);
      expect(
        resolved.containerStyle.borderRadius,
        const CoreBorderRadius.all(8),
      );
    });

    testWidgets('padding is 12 across and 10 down', (tester) async {
      final resolved = await _resolve(tester);
      expect(
        resolved.contentPadding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
    });

    testWidgets('the gutter gap is 12 and the copy seat is 6', (tester) async {
      final resolved = await _resolve(tester);
      expect(resolved.lineNumberMargin, 12);
      expect(resolved.copyButtonOffset, 6);
    });

    testWidgets('the sizes ride the scaling axis', (tester) async {
      final resolved = await _resolve(
        tester,
        theme: const ThemeData(scaling: 2),
      );
      expect(
        resolved.contentPadding,
        const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      );
      expect(resolved.lineNumberMargin, 24);
      expect(resolved.copyButtonOffset, 12);
    });

    testWidgets('an instance value wins over each default', (tester) async {
      final resolved = await _resolve(
        tester,
        style: const CoreCodeSnippetStyle(
          borderRadius: CoreBorderRadius.all(20),
          padding: CoreEdgeInsets.all(CoreSpace.space24),
          lineNumberMargin: CoreSpace.space20,
          copyButtonOffset: CoreSpace.space20,
        ),
      );
      expect(
        resolved.containerStyle.borderRadius,
        const CoreBorderRadius.all(20),
      );
      expect(resolved.contentPadding, const EdgeInsets.all(24));
      expect(resolved.lineNumberMargin, 20);
      expect(resolved.copyButtonOffset, 20);
    });
  });

  group('CodeSnippet defaults — code role', () {
    testWidgets('code is codeSm: 12 / 400 / a 21px box / no tracking / mono', (
      tester,
    ) async {
      final style = (await _resolve(tester)).codeStyle;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w400);
      expect(_lineBox(style), _kBox);
      expect(style.letterSpacing, 0);
      expect(style.fontFamily, CoreFontFamily.mono);
    });

    testWidgets('the gutter takes the same role and the same box', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      final code = resolved.codeStyle;
      final gutter = resolved.lineNumberStyle;
      expect(gutter.fontSize, code.fontSize);
      expect(gutter.height, code.height);
      expect(gutter.fontFamily, code.fontFamily);
      expect(gutter.letterSpacing, code.letterSpacing);
      expect(_lineBox(gutter), _kBox);
    });

    testWidgets('the role follows the theme text scaling', (tester) async {
      // A token-backed default is read off `theme.typography`, so a scaled
      // scale scales the glyphs and the box together — the box stays 7/4 of
      // the size, which is what keeps both columns on one grid.
      final resolved = await _resolve(
        tester,
        theme: ThemeData(typography: CoreTypography.coui.scale(2)),
      );
      expect(resolved.codeStyle.fontSize, 24);
      expect(_lineBox(resolved.codeStyle), 2 * _kBox);
      expect(_lineBox(resolved.lineNumberStyle), 2 * _kBox);
    });

    testWidgets('a role stated by the caller replaces codeSm', (tester) async {
      final style = (await _resolve(
        tester,
        style: const CoreCodeSnippetStyle(
          codeTypography: CoreTextStyle.token(CoreTextStyles.codeMd),
        ),
      )).codeStyle;
      expect(style.fontSize, 13);
      expect(_lineBox(style), _kBox);
      expect(style.fontFamily, CoreFontFamily.mono);
    });

    testWidgets('a size stated on the role keeps the 21px box', (tester) async {
      final resolved = await _resolve(
        tester,
        style: const CoreCodeSnippetStyle(
          codeTypography: CoreTextStyle(fontSize: CoreFontSize.s14),
        ),
      );
      expect(resolved.codeStyle.fontSize, 14);
      expect(_lineBox(resolved.codeStyle), _kBox);
      expect(_lineBox(resolved.lineNumberStyle), _kBox);
    });

    testWidgets('a raw scale role merges onto codeSm — the Web emit shape', (
      tester,
    ) async {
      // Web emits the `codeSm` class with the stated fields inline; this is
      // the Flutter side of that same composite, so the two platforms draw
      // the same face and box for the same caller.
      final style = (await _resolve(
        tester,
        style: CoreCodeSnippetStyle(
          codeTypography: CoreTypography.coui.bodyMedium,
        ),
      )).codeStyle;
      expect(style.fontSize, 14);
      // The multiplier is the newer statement, so it replaces the role's box.
      expect(style.height, CoreLineHeight.h150);
      // The role's face stays — bodyMedium names none.
      expect(style.fontFamily, CoreFontFamily.mono);
    });

    testWidgets('a code text-style multiplier replaces the role box', (
      tester,
    ) async {
      final style = (await _resolve(
        tester,
        style: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(lineHeight: CoreLineHeight.h140),
        ),
      )).codeStyle;
      expect(style.height, CoreLineHeight.h140);
    });
  });

  group('CodeSnippet defaults — colour', () {
    final scheme = CoreThemePresets.lightColorScheme;
    Color slot(CoreColorToken token) => Color(token.read(scheme)!.argb);

    testWidgets('the face is surfaceContainerLow', (tester) async {
      final resolved = await _resolve(tester);
      expect(
        resolved.containerStyle.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
    });

    testWidgets('the block has no border: transparent colour, width 0', (
      tester,
    ) async {
      final resolved = await _resolve(tester);
      expect(resolved.containerStyle.borderColor, CoreColor.transparent);
      expect(resolved.containerStyle.borderWidth, 0);
    });

    testWidgets('the code ink is onSurface', (tester) async {
      final resolved = await _resolve(tester);
      expect(resolved.codeStyle.color, slot(CoreColors.onSurface));
    });

    testWidgets('the gutter ink is onSurfaceVariant, opaque', (tester) async {
      final resolved = await _resolve(tester);
      expect(resolved.lineNumberStyle.color, slot(CoreColors.onSurfaceVariant));
      expect(resolved.lineNumberStyle.color!.a, 1);
    });

    testWidgets('the gutter does not follow a restated code colour', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        style: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.onPrimary),
          ),
        ),
      );
      expect(resolved.codeStyle.color, slot(CoreColors.onPrimary));
      expect(resolved.lineNumberStyle.color, slot(CoreColors.onSurfaceVariant));
    });

    testWidgets('a stated gutter colour wins', (tester) async {
      final resolved = await _resolve(
        tester,
        style: const CoreCodeSnippetStyle(
          lineNumberTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      );
      expect(resolved.lineNumberStyle.color, slot(CoreColors.primary));
      // The gutter keeps the code's role and box.
      expect(_lineBox(resolved.lineNumberStyle), _kBox);
    });

    testWidgets('the copy glyph states a size and no colour', (tester) async {
      final resolved = await _resolve(tester);
      expect(resolved.copyIconStyle.color, isNull);
      expect(resolved.copyIconStyle.size, CoreIconSize.size16);
    });

    /// The colour `Icon` draws the copy glyph in, with a `Button`-like ambient
    /// [IconTheme] colour of [ambient] around it.
    Future<Color> glyphColor(
      WidgetTester tester, {
      required Color ambient,
      CoreCodeSnippetStyle? style,
    }) async {
      late ResolvedIcon icon;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: IconTheme(
              data: IconThemeData(color: ambient),
              child: Builder(
                builder: (context) {
                  final resolved = resolveCodeSnippet(
                    context,
                    codeSnippetStyle: style,
                  );
                  icon = resolveIcon(
                    context,
                    icon: LucideIcons.copy,
                    data: null,
                    widgetStyle: resolved.copyIconStyle,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      return icon.color;
    }

    testWidgets('the glyph takes the colour the button hands down', (
      tester,
    ) async {
      // No colour on the glyph, so the ambient one a `Button` sets for its
      // child (its rest, hover and disabled foreground reach the glyph that
      // way) is the colour drawn.
      const handed = Color(0xFFFF0000);
      expect(await glyphColor(tester, ambient: handed), handed);
    });

    testWidgets('a glyph colour stated on the instance outranks the button', (
      tester,
    ) async {
      // A stated colour pins the glyph through hover and press: what a solid
      // role face relies on to keep its ink.
      final stated = await glyphColor(
        tester,
        ambient: const Color(0xFFFF0000),
        style: const CoreCodeSnippetStyle(
          copyIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.onPrimary),
          ),
        ),
      );
      expect(stated, slot(CoreColors.onPrimary));
    });

    testWidgets('the copy button states no ring of its own', (tester) async {
      final resolved = await _resolve(tester);
      expect(resolved.copyButtonStyle.focusOutlineStyle, isNull);
    });

    testWidgets('the gutter takes the scheme in dark too', (tester) async {
      final resolved = await _resolve(
        tester,
        theme: ThemeData.fromCore(CoreThemePresets.dark),
      );
      final dark = CoreThemePresets.darkColorScheme;
      expect(
        resolved.lineNumberStyle.color,
        Color(CoreColors.onSurfaceVariant.read(dark)!.argb),
      );
      expect(
        resolved.codeStyle.color,
        Color(CoreColors.onSurface.read(dark)!.argb),
      );
    });

    testWidgets('the painted face is the container tone and has no stroke', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const CodeSnippet(
          code: "print('hi');",
          mode: 'dart',
          showCopyButton: false,
        ),
      );
      final decorations = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(OutlinedContainer),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color != null)
          .toList();
      expect(decorations, isNotEmpty);

      final face = decorations.first;
      expect(face.color, slot(CoreColors.surfaceContainerLow));
      // A hairline is a stroke with a visible colour; Flutter strokes one even
      // at width 0, so the colour is what must be transparent.
      final side = (face.border! as Border).top;
      expect(side.color.a, 0);
    });

    testWidgets('a copy button paints a transparent focus band', (
      tester,
    ) async {
      // The standard ring has no gap band: the one FocusOutline under the
      // snippet paints its band transparent (an opaque one is a second
      // outline glued to the button).
      await pumpTestApp(
        tester,
        const CodeSnippet(code: "print('hi');", mode: 'dart'),
      );
      final bands = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.descendant(
                of: find.byType(CodeSnippet),
                matching: find.byType(FocusOutline),
              ),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<ShapeDecoration>()
          .map((d) => (d.shape as RoundedRectangleBorder).side.color)
          .toList();
      expect(bands, hasLength(1));
      expect(bands.single.a, 0);
    });
  });
}
