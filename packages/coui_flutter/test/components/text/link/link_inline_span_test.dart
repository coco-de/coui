import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _kHref = 'https://example.com/docs';
const _kAmbientFontSize = 30.0;

/// Hosts [builder] inside a CoUI theme and a paragraph whose ambient
/// style is deliberately far from the link's own body-medium role, so an
/// inherited size is unmistakable.
material.Widget _host(
  List<GestureRecognizer> recognizers,
  InlineSpan Function(BuildContext context) builder, {
  double width = 600,
}) {
  return material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: material.Scaffold(
        body: Align(
          alignment: .topLeft,
          child: SizedBox(
            width: width,
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: _kAmbientFontSize),
              child: Builder(
                builder: (context) => Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Read the '),
                      builder(context),
                      const TextSpan(text: ' first.'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

RenderParagraph _paragraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(find.byType(RichText).first);

/// Taps a quarter of the way into the first glyph of [needle] — the
/// same probe the docs renderer test uses, since the centre of a glyph
/// run can land in a sub-pixel gap between tracked glyph advances.
Future<void> _tapText(WidgetTester tester, String needle) async {
  final paragraph = _paragraph(tester);
  final start = paragraph.text.toPlainText().indexOf(needle);
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + 1),
      )
      .first
      .toRect();
  await tester.tapAt(
    paragraph.localToGlobal(Offset(box.left + box.width / 4, box.center.dy)),
  );
  await tester.pump();
}

void main() {
  group('Link.inlineSpan — typography comes from the paragraph', () {
    // The widget `Link` paints its label in its own body-medium role, so in
    // a heading or a table cell the link text jumps size. The inline span
    // must carry no role at all: only the link colour and underline.
    testWidgets('carries no font size — the ambient size wins', (
      tester,
    ) async {
      final recognizers = <GestureRecognizer>[];
      late TextStyle? spanStyle;
      await tester.pumpWidget(
        _host(recognizers, (context) {
          final span = Link.inlineSpan(
            context,
            href: _kHref,
            text: 'theming guide',
            onPressed: () {},
            recognizers: recognizers,
          );
          spanStyle = span.style;
          return span;
        }),
      );

      expect(spanStyle?.fontSize, isNull);
      expect(spanStyle?.fontWeight, isNull);
      expect(spanStyle?.height, isNull);
      // The resolved size the paragraph actually lays out with.
      final paragraph = _paragraph(tester);
      final start = paragraph.text.toPlainText().indexOf('theming');
      final box = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: start + 1),
          )
          .first;
      expect(box.bottom - box.top, greaterThanOrEqualTo(_kAmbientFontSize));

      for (final r in recognizers) {
        r.dispose();
      }
    });

    testWidgets('colour and underline match the Link widget label', (
      tester,
    ) async {
      final recognizers = <GestureRecognizer>[];
      late TextStyle? spanStyle;
      late ResolvedLink resolved;
      await tester.pumpWidget(
        _host(recognizers, (context) {
          resolved = resolveLink(context, variant: CoreLinkVariant.standard);
          final span = Link.inlineSpan(context, href: _kHref);
          spanStyle = span.style;
          return span;
        }),
      );

      expect(spanStyle?.color, resolved.labelStyle.color);
      expect(spanStyle?.decoration, TextDecoration.underline);
      expect(spanStyle?.decorationColor, resolved.labelStyle.decorationColor);
      expect(recognizers, isEmpty, reason: 'no onPressed → no recognizer');
    });

    testWidgets('is underlined whatever the style states', (tester) async {
      // Inside a sentence the colour alone cannot carry the recognition, so
      // the inline form has no flag to turn the underline off — and no style
      // field reaches it either.
      late TextStyle? spanStyle;
      await tester.pumpWidget(
        _host(<GestureRecognizer>[], (context) {
          final span = Link.inlineSpan(
            context,
            href: _kHref,
            linkStyle: const CoreLinkStyle(
              interactionTextDecoration: CoreTextDecoration.none,
            ),
          );
          spanStyle = span.style;
          return span;
        }),
      );

      expect(spanStyle?.decoration, TextDecoration.underline);
    });

    testWidgets('the muted variant reads the muted colour', (tester) async {
      late TextStyle? standardStyle;
      late TextStyle? mutedStyle;
      late Color expectedMuted;
      await tester.pumpWidget(
        _host(<GestureRecognizer>[], (context) {
          expectedMuted = Theme.of(context).colorScheme
              .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
              .toValue();
          standardStyle = Link.inlineSpan(context, href: _kHref).style;
          final span = Link.inlineSpan(
            context,
            href: _kHref,
            variant: CoreLinkVariant.muted,
          );
          mutedStyle = span.style;
          return span;
        }),
      );

      expect(mutedStyle?.color, expectedMuted);
      expect(mutedStyle?.decorationColor, expectedMuted);
      expect(standardStyle?.color, isNot(expectedMuted));
    });

    testWidgets('an explicit labelStyle field still rides along', (
      tester,
    ) async {
      late TextStyle? spanStyle;
      await tester.pumpWidget(
        _host(<GestureRecognizer>[], (context) {
          final span = Link.inlineSpan(
            context,
            href: _kHref,
            linkStyle: const CoreLinkStyle(
              labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
            ),
          );
          spanStyle = span.style;
          return span;
        }),
      );

      expect(spanStyle?.fontWeight, FontWeight.w600);
      expect(spanStyle?.fontSize, isNull);
    });
  });

  group('Link.inlineSpan — flows with the text', () {
    testWidgets('a long link breaks across lines instead of overflowing', (
      tester,
    ) async {
      // The WidgetSpan form is atomic: it either fits on the line or moves
      // whole, and in a narrow cell it spills out. A TextSpan wraps word
      // by word like the text around it.
      const label = 'a link whose label is far longer than the column';
      await tester.pumpWidget(
        _host(
          <GestureRecognizer>[],
          (context) => Link.inlineSpan(context, href: _kHref, text: label),
          width: 240,
        ),
      );

      final paragraph = _paragraph(tester);
      final start = paragraph.text.toPlainText().indexOf(label);
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + label.length),
      );
      final lineTops = boxes.map((b) => b.top.round()).toSet();
      expect(lineTops.length, greaterThan(1));
      expect(tester.takeException(), isNull);
    });
  });

  group('Link.inlineSpan — activation', () {
    testWidgets('a tap runs onPressed and the recognizer is handed over', (
      tester,
    ) async {
      final recognizers = <GestureRecognizer>[];
      var pressed = 0;
      await tester.pumpWidget(
        _host(
          recognizers,
          (context) => Link.inlineSpan(
            context,
            href: _kHref,
            text: 'theming guide',
            onPressed: () => pressed++,
            recognizers: recognizers,
          ),
        ),
      );

      await _tapText(tester, 'theming');
      expect(pressed, 1);
      expect(recognizers, hasLength(1));
      expect(recognizers.single, isA<TapGestureRecognizer>());
      for (final r in recognizers) {
        r.dispose();
      }
    });

    testWidgets('styled children answer the tap too', (tester) async {
      // A recognizer on a TextSpan covers only its own text — the bold
      // leaf inside the link must receive the same recognizer, or tapping
      // that word does nothing.
      final recognizers = <GestureRecognizer>[];
      var pressed = 0;
      await tester.pumpWidget(
        _host(
          recognizers,
          (context) => Link.inlineSpan(
            context,
            href: _kHref,
            children: const [
              TextSpan(text: 'plain '),
              TextSpan(
                text: 'bold',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            onPressed: () => pressed++,
            recognizers: recognizers,
          ),
        ),
      );

      await _tapText(tester, 'bold');
      expect(pressed, 1);
      await _tapText(tester, 'plain');
      expect(pressed, 2);
      for (final r in recognizers) {
        r.dispose();
      }
    });

    testWidgets('onPressed marks the span as a link for accessibility', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final recognizers = <GestureRecognizer>[];
      await tester.pumpWidget(
        _host(
          recognizers,
          (context) => Link.inlineSpan(
            context,
            href: _kHref,
            text: 'theming guide',
            onPressed: () {},
            recognizers: recognizers,
          ),
        ),
      );

      // The span becomes its own semantics node inside the paragraph —
      // not a widget, so it is found in the semantics tree directly.
      final node = find.semantics.byLabel('theming guide').evaluate().single;
      expect(node.getSemanticsData().flagsCollection.isLink, isTrue);
      for (final r in recognizers) {
        r.dispose();
      }
      handle.dispose();
    });

    testWidgets('onPressed without an owner for the recognizer asserts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(<GestureRecognizer>[], (context) {
          expect(
            () => Link.inlineSpan(context, href: _kHref, onPressed: () {}),
            throwsAssertionError,
          );
          return const TextSpan(text: 'x');
        }),
      );
    });
  });
}
