import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kTestText = 'Hello, World!';
const _kOverrideBorderWidth = 5.0;
const _kOverrideRadius = 12.0;
const _kOverridePaddingH = 9.0;
const _kOverridePaddingV = 7.0;

material.Widget _buildApp(material.Widget child, {ThemeData? theme}) =>
    material.MaterialApp(
      home: Theme(data: theme ?? const ThemeData(), child: child),
    );

/// Resolves a [ResolvedTextBlock] inside a real element tree so
/// `Theme.of(context)` / `scheme.resolve` run against the active theme.
Future<ResolvedTextBlock> _resolve(
  WidgetTester tester, {
  required CoreTextBlockElement element,
  List<TextBlockStyle>? presets,
  CoreTextBlockStyle? textBlockStyle,
}) async {
  late ResolvedTextBlock resolved;
  await tester.pumpWidget(
    _buildApp(
      material.Builder(
        builder: (context) {
          resolved = resolveTextBlock(
            context,
            element: element,
            presets: presets,
            textBlockStyle: textBlockStyle,
          );
          return const material.SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

void main() {
  // ═══════════════════════════════════════════════
  // TextBlockStyle (preset value class)
  // ═══════════════════════════════════════════════

  group('TextBlockStyle', () {
    test('value equality on style fragment', () {
      const a = TextBlockStyle(material.TextStyle(fontStyle: .italic));
      const b = TextBlockStyle(material.TextStyle(fontStyle: .italic));
      const c = TextBlockStyle(material.TextStyle(fontWeight: .w700));

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  // ═══════════════════════════════════════════════
  // resolveTextBlock
  // ═══════════════════════════════════════════════

  group('resolveTextBlock', () {
    testWidgets('paragraph element resolves base body typography', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        element: .p,
      );

      expect(resolved.textStyle.fontSize, isNotNull);
    });

    testWidgets('presets merge onto the element base (later wins)', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        element: .p,
        presets: const [
          TextBlockStyle(material.TextStyle(fontWeight: .w700)),
        ],
      );

      expect(resolved.textStyle.fontWeight, equals(material.FontWeight.w700));
    });

    testWidgets('blockquote chrome falls back to design-system defaults', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        element: .blockquote,
      );

      expect(
        resolved.blockQuoteBorderWidth,
        equals(CoreTextBlockStyle.defaultBlockQuoteBorderWidth),
      );
      expect(
        resolved.blockQuotePadding,
        equals(CoreTextBlockStyle.defaultBlockQuotePadding.toGeometry()),
      );
      // Directional, not physical: a blockquote is indented away from the
      // margin the text starts at, which is the right in an Arabic
      // locale. Asserted on the resolved value because that is the one
      // the widget renders — a directional default that flattened here
      // would look correct in English and be wrong in half the world.
      expect(resolved.blockQuotePadding, isA<EdgeInsetsDirectional>());
      // Border colour resolved through the scheme — never the degenerate
      // fallback sentinel under a real theme.
      expect(resolved.blockQuoteBorderColor, isA<material.Color>());
    });

    testWidgets('inline-code chrome falls back to design-system defaults', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        element: .pre,
      );

      expect(
        resolved.inlineCodeRadius,
        equals(
          material.BorderRadius.circular(
            CoreTextBlockStyle.defaultInlineCodeRadius,
          ),
        ),
      );
      expect(
        resolved.inlineCodePadding,
        equals(
          material.EdgeInsets.symmetric(
            vertical: CoreTextBlockStyle.defaultInlineCodePadding.top,
            horizontal: CoreTextBlockStyle.defaultInlineCodePadding.left,
          ),
        ),
      );
      expect(resolved.inlineCodeBackgroundColor, isA<material.Color>());
    });

    testWidgets('textBlockStyle override flows through the merge chain', (
      tester,
    ) async {
      final resolved = await _resolve(
        tester,
        element: .pre,
        textBlockStyle: const CoreTextBlockStyle(
          blockQuoteBorderWidth: _kOverrideBorderWidth,
          inlineCodeRadius: _kOverrideRadius,
          inlineCodePadding: CoreEdgeInsets.symmetric(
            horizontal: _kOverridePaddingH,
            vertical: _kOverridePaddingV,
          ),
        ),
      );

      expect(resolved.blockQuoteBorderWidth, equals(_kOverrideBorderWidth));
      expect(
        resolved.inlineCodeRadius,
        equals(material.BorderRadius.circular(_kOverrideRadius)),
      );
      expect(
        resolved.inlineCodePadding,
        equals(
          const material.EdgeInsets.symmetric(
            vertical: _kOverridePaddingV,
            horizontal: _kOverridePaddingH,
          ),
        ),
      );
    });
  });

  // ═══════════════════════════════════════════════
  // TextBlock widget (render-only)
  // ═══════════════════════════════════════════════

  group('TextBlock', () {
    testWidgets('renders plain text content', (tester) async {
      await tester.pumpWidget(
        _buildApp(const TextBlock(text: _kTestText)),
      );

      expect(find.text(_kTestText), findsOneWidget);
    });

    testWidgets('blockquote wraps content in a bordered DecoratedBox', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const TextBlock(
            text: _kTestText,
            element: .blockquote,
          ),
        ),
      );

      expect(find.byType(material.DecoratedBox), findsWidgets);
      expect(find.text(_kTestText), findsOneWidget);
    });

    testWidgets('pre wraps content in a surface DecoratedBox', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TextBlock(
            text: _kTestText,
            element: .pre,
          ),
        ),
      );

      expect(find.byType(material.DecoratedBox), findsWidgets);
      expect(find.text(_kTestText), findsOneWidget);
    });

    testWidgets('children take precedence over text', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const TextBlock(
            text: 'ignored',
            children: [material.Text(_kTestText)],
          ),
        ),
      );

      expect(find.text(_kTestText), findsOneWidget);
      expect(find.text('ignored'), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════
  // The drawn result — read back from the widget tree
  // ═══════════════════════════════════════════════
  //
  // The resolver tests above compare a resolved value with the default it
  // was resolved from, which cannot fail when the default itself is wrong.
  // These read what is painted: the `Text` the framework draws, the border
  // and padding of the boxes around it. The numbers are the design values,
  // written out — not read back from the constants they are checked against.

  group('what is drawn for the two box roles', () {
    late ThemeData theme;

    Future<void> pumpBlock(WidgetTester tester, TextBlock block) {
      return tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              theme = Theme.of(context);
              return block;
            },
          ),
        ),
      );
    }

    material.Color token(CoreColorToken t) =>
        theme.colorScheme.resolve(CoreColor.token(t)).toValue();

    material.TextStyle drawnText(WidgetTester tester) =>
        tester.widget<Text>(find.text(_kTestText)).style!;

    material.Border drawnBorder(WidgetTester tester) {
      final box = tester.widget<material.DecoratedBox>(
        find
            .ancestor(
              of: find.text(_kTestText),
              matching: find.byType(material.DecoratedBox),
            )
            .first,
      );
      return (box.decoration as material.BoxDecoration).border!
          as material.Border;
    }

    material.BoxDecoration drawnBox(WidgetTester tester) {
      final box = tester.widget<material.DecoratedBox>(
        find
            .ancestor(
              of: find.text(_kTestText),
              matching: find.byType(material.DecoratedBox),
            )
            .first,
      );
      return box.decoration as material.BoxDecoration;
    }

    material.EdgeInsetsGeometry drawnPadding(WidgetTester tester) {
      return tester
          .widget<material.Padding>(
            find
                .ancestor(
                  of: find.text(_kTestText),
                  matching: find.byType(material.Padding),
                )
                .first,
          )
          .padding;
    }

    testWidgets('the quote rule is 3px of outline-variant on the start side', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const TextBlock(text: _kTestText, element: .blockquote),
      );
      final border = drawnBorder(tester);

      expect(border.left.width, 3);
      expect(border.left.color, token(CoreColors.outlineVariant));
      // Not the muted foreground it used to be.
      expect(
        border.left.color,
        isNot(token(CoreColors.onSurfaceVariant)),
      );
      // A rule on one edge only.
      expect(border.top, material.BorderSide.none);
      expect(border.right, material.BorderSide.none);
      expect(border.bottom, material.BorderSide.none);
    });

    testWidgets('the quote is set in 16px from the rule, on the start side', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const TextBlock(text: _kTestText, element: .blockquote),
      );
      final padding = drawnPadding(tester);

      expect(padding, const material.EdgeInsetsDirectional.only(start: 16));
      // Directional: it lands on the right when the text starts there.
      expect(padding.resolve(material.TextDirection.rtl).right, 16);
      expect(padding.resolve(material.TextDirection.rtl).left, 0);
    });

    testWidgets('quote text is the body role in on-surface-variant', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const TextBlock(text: _kTestText, element: .blockquote),
      );
      final text = drawnText(tester);
      final body = theme.typography.bodyMedium.toValue(theme: theme);

      expect(text.fontSize, body.fontSize);
      expect(text.fontFamily, body.fontFamily);
      expect(text.height, body.height);
      expect(text.color, token(CoreColors.onSurfaceVariant));
      expect(text.color, isNot(token(CoreColors.onSurface)));
    });

    testWidgets('inline code text is the fixed-width code role in on-surface', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const TextBlock(text: _kTestText, element: .pre),
      );
      final text = drawnText(tester);
      final code = theme.typography.codeMd.toValue(theme: theme);
      final body = theme.typography.bodyMedium.toValue(theme: theme);

      expect(text.fontSize, 13);
      expect(text.fontSize, code.fontSize);
      expect(text.fontFamily, code.fontFamily);
      expect(text.fontFamilyFallback, code.fontFamilyFallback);
      // The role's own fixed line box (21px over a 13px size), not the body
      // role's multiplier.
      expect(text.height, code.height);
      expect(text.height, isNot(body.height));
      expect(text.color, token(CoreColors.onSurface));
    });

    testWidgets('the inline code box is 6px by 1px with a 4px radius', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const TextBlock(text: _kTestText, element: .pre),
      );
      final box = drawnBox(tester);

      expect(
        drawnPadding(tester),
        const material.EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      );
      expect(box.borderRadius, material.BorderRadius.circular(4));
      // Unchanged: the surface it sits on.
      expect(box.color, token(CoreColors.surfaceContainer));
    });

    for (final coreTheme in [CoreThemePresets.light, CoreThemePresets.dark]) {
      testWidgets(
        'inline code lays out a 23px box in ${coreTheme.brightness}',
        (
          tester,
        ) async {
          await tester.pumpWidget(
            _buildApp(
              const Center(
                child: TextBlock(text: _kTestText, element: .pre),
              ),
              theme: ThemeData.fromCore(coreTheme),
            ),
          );

          final glyphs = find.text(_kTestText);
          final box = find
              .ancestor(
                of: glyphs,
                matching: find.byType(material.DecoratedBox),
              )
              .first;
          final glyphSize = tester.getSize(glyphs);
          final boxSize = tester.getSize(box);
          expect(glyphSize.height, closeTo(21, 0.001));
          expect(boxSize.height, closeTo(23, 0.001));
          expect(boxSize.width - glyphSize.width, closeTo(12, 0.001));

          await tester.pumpWidget(
            _buildApp(
              const Center(
                child: TextBlock(
                  text: _kTestText,
                  element: .pre,
                  textBlockStyle: CoreTextBlockStyle(
                    inlineCodePadding: CoreEdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                  ),
                ),
              ),
              theme: ThemeData.fromCore(coreTheme),
            ),
          );
          expect(tester.getSize(box).height, closeTo(35, 0.001));
          expect(
            tester.getSize(box).width - tester.getSize(glyphs).width,
            closeTo(18, 0.001),
          );
        },
      );
    }

    testWidgets('a text override states only what it changes', (tester) async {
      await pumpBlock(
        tester,
        const TextBlock(
          text: _kTestText,
          element: .blockquote,
          textBlockStyle: CoreTextBlockStyle(
            blockQuoteTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );
      final text = drawnText(tester);
      final body = theme.typography.bodyMedium.toValue(theme: theme);

      expect(text.color, token(CoreColors.primary));
      // The role the default states is kept under the caller's colour.
      expect(text.fontSize, body.fontSize);
      expect(text.height, body.height);
    });

    testWidgets('an inline code text override keeps the code role', (
      tester,
    ) async {
      await pumpBlock(
        tester,
        const TextBlock(
          text: _kTestText,
          element: .pre,
          textBlockStyle: CoreTextBlockStyle(
            inlineCodeTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );
      final text = drawnText(tester);
      final code = theme.typography.codeMd.toValue(theme: theme);

      expect(text.color, token(CoreColors.primary));
      expect(text.fontSize, code.fontSize);
      expect(text.fontFamily, code.fontFamily);
    });

    testWidgets('a paragraph is untouched by either role', (tester) async {
      await pumpBlock(tester, const TextBlock(text: _kTestText));
      final text = drawnText(tester);
      final body = theme.typography.bodyMedium.toValue(theme: theme);

      expect(text.fontSize, body.fontSize);
      // The paragraph states no colour of its own; it takes the ambient one.
      expect(text.color, isNull);
    });
  });

  group('the text slots are part of the style value', () {
    test('merge lays a partial text style over the default role', () {
      const base = CoreTextBlockStyle(
        blockQuoteTextStyle: CoreTextStyle(fontSize: 20),
      );
      const patch = CoreTextBlockStyle(
        blockQuoteTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
      );
      final merged = base.merge(patch);

      expect(merged.blockQuoteTextStyle?.fontSize, 20);
      expect(
        merged.blockQuoteTextStyle?.color,
        const CoreColor.token(CoreColors.primary),
      );
    });

    test('equality and copyWith see both text slots', () {
      const a = CoreTextBlockStyle(
        blockQuoteTextStyle: CoreTextStyle(fontSize: 20),
        inlineCodeTextStyle: CoreTextStyle(fontSize: 12),
      );

      expect(a, isNot(equals(const CoreTextBlockStyle())));
      expect(
        a,
        equals(
          const CoreTextBlockStyle().copyWith(
            blockQuoteTextStyle: const CoreTextStyle(fontSize: 20),
            inlineCodeTextStyle: const CoreTextStyle(fontSize: 12),
          ),
        ),
      );
      expect(
        a,
        isNot(
          equals(
            const CoreTextBlockStyle(
              blockQuoteTextStyle: CoreTextStyle(fontSize: 20),
              inlineCodeTextStyle: CoreTextStyle(fontSize: 13),
            ),
          ),
        ),
      );
    });
  });

  group('blockquote border width reaches a strokeFloor preset (#3771)', () {
    testWidgets('resolveTextBlock.blockQuoteBorderWidth is floored', (
      tester,
    ) async {
      // `_BlockQuote` paints `Border(left: BorderSide(width: resolved
      // .blockQuoteBorderWidth))` directly — a single-side border, so the
      // shared `neo_brutalism_e2e_test.dart` helper (which only reads
      // `.top.width`) cannot observe it. Checked at the resolver level
      // instead: before the fix `blockQuoteBorderWidth` was a plain
      // `(merged ?? default) * scaling` with no `theme.geometry
      // .stroke(...)` call, so it never reached a `strokeFloor` preset.
      const geometry = CoreSurfaceGeometryConstraint(
        strokeFloor: CoreStrokeWidth.stroke4,
      );
      late ResolvedTextBlock resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(geometry: geometry),
            child: Builder(
              builder: (context) {
                resolved = resolveTextBlock(context, element: .blockquote);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved.blockQuoteBorderWidth, greaterThanOrEqualTo(4.0));
    });
  });
}
