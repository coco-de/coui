import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Center(child: material.SizedBox(width: 300, child: child)),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    _app(const Autocomplete(suggestions: ['Apple', 'Apricot'])),
  );
  await _settle(tester);
  await tester.tap(find.byType(TextField));
  await _settle(tester);
}

void main() {
  group('Autocomplete option rows read the ItemPicker row', () {
    testWidgets('the label is bodyMedium (14), not bodySmall', (tester) async {
      await _open(tester);
      final text = tester.widget<material.Text>(find.text('Apple'));
      final style = material.DefaultTextStyle.of(
        tester.element(find.text('Apple')),
      ).style.merge(text.style);
      expect(style.fontSize, 14);
    });

    testWidgets('a row is its label line plus 8 above and 8 below', (
      tester,
    ) async {
      await _open(tester);
      final first = tester.getRect(find.text('Apple'));
      final second = tester.getRect(find.text('Apricot'));
      // Rows stack with no gap: the distance between two labels is one
      // row — the label's own line plus the padding above and below.
      expect(second.top - first.top, first.height + 8 + 8);
    });

    testWidgets('the panel sits 4 below the field and holds a 6 inset', (
      tester,
    ) async {
      await _open(tester);
      final field = tester.getRect(find.byType(TextField));
      final firstLabel = tester.getRect(find.text('Apple'));
      // Field bottom → panel top (4) → panel inset (6) → row padding (8).
      expect(firstLabel.top - field.bottom, 4 + 6 + 8);
    });
  });

  group('Autocomplete emphasises the matched part of each label', () {
    Future<void> openWith(WidgetTester tester, String query) async {
      await tester.pumpWidget(
        _app(
          const Autocomplete(
            suggestions: ['Apple', 'Grape', 'Wrap'],
            mode: CoreAutocompleteMode.replaceAll,
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.byType(TextField));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), query);
      await _settle(tester);
    }

    // The option label's spans: (text, weight, colour) per piece.
    List<(String, FontWeight?, Color?)> pieces(
      WidgetTester tester,
      String label,
    ) {
      final rich = tester.widget<material.RichText>(
        find.byWidgetPredicate(
          (w) => w is material.RichText && w.text.toPlainText() == label,
        ),
      );
      // `Text.rich` wraps the label span in the ambient-style span.
      final root =
          (rich.text as material.TextSpan).children!.single
              as material.TextSpan;
      final base = root.style;
      return [
        for (final span in root.children!.cast<material.TextSpan>())
          (
            span.text!,
            span.style?.fontWeight ?? base?.fontWeight,
            span.style?.color ?? base?.color,
          ),
      ];
    }

    testWidgets('at the start, in the middle and at the end', (tester) async {
      await openWith(tester, 'ap');

      expect(pieces(tester, 'Apple').map((p) => p.$1), ['Ap', 'ple']);
      expect(pieces(tester, 'Grape').map((p) => p.$1), ['Gr', 'ap', 'e']);
      expect(pieces(tester, 'Wrap').map((p) => p.$1), ['Wr', 'ap']);
    });

    testWidgets('the match is SemiBold on-surface, the rest Regular '
        'on-surface-variant', (tester) async {
      await openWith(tester, 'ap');

      final grape = pieces(tester, 'Grape');
      final scheme = const ThemeData().colorScheme;
      Color token(CoreColor c) => scheme.resolve(c).toValue();
      expect(grape[1].$2, FontWeight.w600);
      expect(grape[1].$3, token(const CoreColor.token(CoreColors.onSurface)));
      expect(grape[0].$2 ?? FontWeight.w400, FontWeight.w400);
      expect(
        grape[0].$3,
        token(const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
    });
  });
}
