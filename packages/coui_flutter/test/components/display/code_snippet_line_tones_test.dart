import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

import '../../helpers/test_app.dart';

const _code = 'final a = 1;\nfinal b = 2;\nfinal c = 3;\nfinal d = 4;';

/// The painter that draws a snippet's line bands, if it has one.
final Finder _bands = find.byWidgetPredicate(
  (w) =>
      w is CustomPaint &&
      w.painter.runtimeType.toString() == '_CodeLineBandPainter',
);

Future<ResolvedCodeSnippet> _pump(
  WidgetTester tester, {
  Map<int, CoreCodeLineTone> lineTones = const {},
  bool showLineNumbers = true,
  String code = _code,
  CoreCodeSnippetStyle? style,
  double width = 360,
  double textScale = 1,
}) async {
  // The bands belong to the settled snippet, so wait for the highlighter —
  // its language future is cached across tests and resolves outside the fake
  // clock.
  await tester.runAsync(() async {
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: SizedBox(
            width: width,
            child: CodeSnippet(
              code: code,
              mode: 'dart',
              showLineNumbers: showLineNumbers,
              showCopyButton: false,
              lineTones: lineTones,
              codeSnippetStyle: style,
            ),
          ),
        ),
      ),
    );
    await tester
        .widget<FutureBuilder<hl.Highlighter?>>(
          find.byType(FutureBuilder<hl.Highlighter?>),
        )
        .future;
  });
  await tester.pumpAndSettle();
  return resolveCodeSnippet(
    tester.element(find.byType(CodeSnippet)),
    codeSnippetStyle: style,
  );
}

Color _resolve(WidgetTester tester, CoreColor color) => Theme.of(
  tester.element(find.byType(CodeSnippet)),
).colorScheme.resolve(color).toValue();

double _lineBox(ResolvedCodeSnippet resolved) =>
    resolved.codeStyle.height! * resolved.codeStyle.fontSize!;

void main() {
  group('CodeSnippet lineTones', () {
    testWidgets('no tone draws the snippet it always drew', (tester) async {
      expect(const CodeSnippet(code: _code, mode: 'dart').lineTones, isEmpty);
      final resolved = await _pump(tester);

      expect(_bands, findsNothing);
      final scroll = tester.widget<SingleChildScrollView>(
        find.byWidgetPredicate(
          (w) => w is SingleChildScrollView && w.scrollDirection == .horizontal,
        ),
      );
      expect(scroll.padding, resolved.contentPadding);
    });

    testWidgets('a band sits on its line, edge to edge', (tester) async {
      final resolved = await _pump(
        tester,
        lineTones: const {2: CoreCodeLineTone.success},
      );
      final box = tester.renderObject<RenderBox>(_bands);
      final top = resolved.contentPadding.top + _lineBox(resolved);

      // The full width of the code area — under the padding on both sides.
      expect(box.size.width, 360);
      expect(
        box,
        paints..rect(
          rect: Rect.fromLTWH(0, top, 360, _lineBox(resolved)),
          color: _resolve(
            tester,
            CoreCodeSnippetStyle.defaultSuccessLineColor,
          ),
        ),
      );
      // Under the gutter's number 2 and the code's second line.
      final origin = box.localToGlobal(Offset.zero).dy;
      expect(tester.getTopLeft(find.text('2')).dy - origin, top);
    });

    testWidgets('each status tone takes its container colour', (tester) async {
      final resolved = await _pump(
        tester,
        lineTones: const {
          1: CoreCodeLineTone.success,
          3: CoreCodeLineTone.warning,
          4: CoreCodeLineTone.error,
        },
      );
      final line = _lineBox(resolved);
      final top = resolved.contentPadding.top;
      expect(
        tester.renderObject<RenderBox>(_bands),
        paints
          ..rect(
            rect: Rect.fromLTWH(0, top, 360, line),
            color: _resolve(
              tester,
              CoreCodeSnippetStyle.defaultSuccessLineColor,
            ),
          )
          ..rect(
            rect: Rect.fromLTWH(0, top + 2 * line, 360, line),
            color: _resolve(
              tester,
              CoreCodeSnippetStyle.defaultWarningLineColor,
            ),
          )
          ..rect(
            rect: Rect.fromLTWH(0, top + 3 * line, 360, line),
            color: _resolve(tester, CoreCodeSnippetStyle.defaultErrorLineColor),
          ),
      );
    });

    testWidgets('a band follows the text scale', (tester) async {
      final resolved = await _pump(
        tester,
        textScale: 1.5,
        lineTones: const {3: CoreCodeLineTone.warning},
      );
      // The row the gutter draws line 3 in — scaled with the text, and the
      // grid the code's own lines sit on.
      final number = tester.getRect(find.text('3'));
      expect(number.height, greaterThan(_lineBox(resolved)));
      final box = tester.renderObject<RenderBox>(_bands);
      final origin = box.localToGlobal(Offset.zero);
      expect(
        box,
        paints..rect(
          rect: Rect.fromLTWH(0, number.top - origin.dy, 360, number.height),
        ),
      );
    });

    testWidgets('the other tones and lines outside the code draw nothing', (
      tester,
    ) async {
      await _pump(
        tester,
        lineTones: const {
          1: CoreCodeLineTone.neutral,
          2: CoreCodeLineTone.muted,
          3: CoreCodeLineTone.link,
          9: CoreCodeLineTone.error,
          0: CoreCodeLineTone.error,
        },
      );

      expect(_bands, findsNothing);
    });

    testWidgets('each stated colour reaches its own tone', (tester) async {
      const stated = {
        CoreCodeLineTone.success: CoreColor.token(CoreColors.tertiaryContainer),
        CoreCodeLineTone.warning: CoreColor.token(CoreColors.primaryContainer),
        CoreCodeLineTone.error: CoreColor.token(CoreColors.secondaryContainer),
      };
      final resolved = await _pump(
        tester,
        lineTones: const {
          1: CoreCodeLineTone.success,
          2: CoreCodeLineTone.warning,
          3: CoreCodeLineTone.error,
        },
        style: CoreCodeSnippetStyle(
          successLineColor: stated[CoreCodeLineTone.success],
          warningLineColor: stated[CoreCodeLineTone.warning],
          errorLineColor: stated[CoreCodeLineTone.error],
        ),
      );
      final line = _lineBox(resolved);
      final top = resolved.contentPadding.top;
      expect(
        tester.renderObject<RenderBox>(_bands),
        paints
          ..rect(
            rect: Rect.fromLTWH(0, top, 360, line),
            color: _resolve(tester, stated[CoreCodeLineTone.success]!),
          )
          ..rect(
            rect: Rect.fromLTWH(0, top + line, 360, line),
            color: _resolve(tester, stated[CoreCodeLineTone.warning]!),
          )
          ..rect(
            rect: Rect.fromLTWH(0, top + 2 * line, 360, line),
            color: _resolve(tester, stated[CoreCodeLineTone.error]!),
          ),
      );
    });

    testWidgets('a long line carries its band to its own end', (tester) async {
      await _pump(
        tester,
        code: 'short\n${'x' * 200}',
        lineTones: const {1: CoreCodeLineTone.success},
      );

      // The scroll content outgrows the box, and the band layer with it.
      expect(
        tester.renderObject<RenderBox>(_bands).size.width,
        greaterThan(360),
      );
    });

    testWidgets('without the gutter the band still runs edge to edge', (
      tester,
    ) async {
      final resolved = await _pump(
        tester,
        showLineNumbers: false,
        lineTones: const {1: CoreCodeLineTone.success},
      );

      expect(
        tester.renderObject<RenderBox>(_bands),
        paints..rect(
          rect: Rect.fromLTWH(
            0,
            resolved.contentPadding.top,
            360,
            _lineBox(resolved),
          ),
        ),
      );
    });

    testWidgets('each band says its tone in words', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        lineTones: const {
          2: CoreCodeLineTone.success,
          4: CoreCodeLineTone.error,
        },
      );

      // The painter's nodes, not a widget's — found in the semantics tree.
      expect(find.semantics.byLabel('Line 2: success'), findsOne);
      expect(find.semantics.byLabel('Line 4: error'), findsOne);

      // Read in line order, then the code — whose nodes stay as they are
      // with no band: the gutter numbers are not folded into its label.
      final order = tester
          .getSemantics(_bands)
          .debugListChildrenInOrder(.traversalOrder);
      expect(order.map((n) => n.label), [
        'Line 2: success',
        'Line 4: error',
        '',
      ]);
      final code = order.last.debugListChildrenInOrder(.traversalOrder);
      expect(code.map((n) => n.label), ['1', '2', '3', '4', '']);
      expect(code.last.getSemanticsData().flagsCollection.isTextField, isTrue);
      semantics.dispose();
    });

    testWidgets('the words follow the active locale', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          CoUIApp(
            locale: const Locale('ko'),
            supportedLocales: const [Locale('en', 'US'), Locale('ko')],
            theme: ThemeData.fromCore(CoreThemePresets.light),
            home: const SizedBox(
              width: 360,
              child: CodeSnippet(
                code: _code,
                mode: 'dart',
                showCopyButton: false,
                lineTones: {2: CoreCodeLineTone.error},
              ),
            ),
          ),
        );
        await tester
            .widget<FutureBuilder<hl.Highlighter?>>(
              find.byType(FutureBuilder<hl.Highlighter?>),
            )
            .future;
      });
      await tester.pumpAndSettle();

      final label = KoCoUILocalizations.instance.codeSnippetErrorLineLabel(2);
      expect(label, isNot('Line 2: error'));
      expect(find.semantics.byLabel(label), findsOne);
      semantics.dispose();
    });
  });
}
