import 'dart:ui' show SemanticsAction;
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

material.Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(child: child),
  ),
);

Finder get _decrease => find.byWidgetPredicate(
  (w) => w is Button && w.child is Icon && _isIcon(w.child, LucideIcons.minus),
);
Finder get _increase => find.byWidgetPredicate(
  (w) => w is Button && w.child is Icon && _isIcon(w.child, LucideIcons.plus),
);

bool _isIcon(Widget? widget, IconName name) =>
    widget is Icon && widget.icon == name;

bool _enabled(WidgetTester tester, Finder finder) =>
    tester.widget<Button>(finder).enabled ?? true;

void main() {
  testWidgets('error replaces helper text and uses field error ink', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const NumberInput(
          description: 'Choose a count',
          errorText: 'Too many guests',
        ),
      ),
    );
    expect(find.text('Choose a count'), findsNothing);
    final message = find.text('Too many guests');
    expect(message, findsOneWidget);
    expect(
      tester.widget<material.Text>(message).style?.color,
      const ThemeData().colorScheme.error.toValue(),
    );
    await tester.pumpWidget(
      _app(const NumberInput(description: 'Choose a count')),
    );
    expect(find.text('Too many guests'), findsNothing);
    expect(find.text('Choose a count'), findsOneWidget);
  });

  group('NumberInput size', () {
    // Field width = border + inset + button + value + button + inset +
    // border, per size step — the 90 · 114 · 138 the design states.
    const widths = {
      CoreNumberInputSize.sm: 90.0,
      CoreNumberInputSize.md: 114.0,
      CoreNumberInputSize.lg: 138.0,
    };
    const heights = {
      CoreNumberInputSize.sm: 32.0,
      CoreNumberInputSize.md: 40.0,
      CoreNumberInputSize.lg: 48.0,
    };
    const buttonExtents = {
      CoreNumberInputSize.sm: 24.0,
      CoreNumberInputSize.md: 32.0,
      CoreNumberInputSize.lg: 40.0,
    };

    for (final size in widths.keys) {
      testWidgets('${size.name} draws ${widths[size]}x${heights[size]} with '
          '${buttonExtents[size]} buttons', (tester) async {
        await tester.pumpWidget(_app(NumberInput(size: size, initialValue: 1)));
        await tester.pump();
        final box = tester.getSize(find.byType(NumberInput));
        expect(box.width, widths[size]);
        expect(tester.getSize(find.byType(TextField)).height, heights[size]);
        expect(tester.getSize(_decrease).width, buttonExtents[size]);
        expect(tester.getSize(_decrease).height, buttonExtents[size]);
        expect(tester.getSize(_increase).width, buttonExtents[size]);

        // The ends start border + inset (1 + 4) inside the box edge, and the
        // value sits centred between them.
        final field = tester.getRect(find.byType(NumberInput));
        final minus = tester.getRect(_decrease);
        final plus = tester.getRect(_increase);
        const edge =
            CoreNumberInputStyle.defaultBorderWidth +
            CoreNumberInputStyle.defaultInset;
        expect(edge, 5);
        expect(minus.left - field.left, edge);
        expect(field.right - plus.right, edge);
        expect(minus.center.dy, field.center.dy);
        // The value glyphs are centred in the box. `RenderEditable` keeps a
        // caret margin on the trailing edge; the field balances it on the
        // leading edge, so the painted text — not the editable's box — is
        // what sits on the middle (to within the role's trailing tracking).
        final state = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
        final editable = state.renderEditable;
        final glyphs = editable
            .getBoxesForSelection(
              TextSelection(
                baseOffset: 0,
                extentOffset: state.textEditingValue.text.length,
              ),
            )
            .first
            .toRect()
            .shift(editable.localToGlobal(Offset.zero));
        expect(glyphs.center.dx, closeTo(field.center.dx, 0.1));
        final value = tester.getRect(find.byType(EditableText));
        expect(value.left, greaterThanOrEqualTo(minus.right));
        expect(value.right, lessThanOrEqualTo(plus.left));
      });
    }

    test('style rows state the same widths the parts add up to', () {
      for (final size in widths.keys) {
        expect(
          CoreNumberInputStyle.defaultsBySize[size]!.width,
          widths[size],
        );
        expect(CoreNumberInputStyle.widthAt(size), widths[size]);
      }
    });
  });

  group('NumberInput caret', () {
    // #5762 — the designer's caret: 2 wide, corner 2, no gap after the value,
    // as tall as the value's line box, in `primary`. NumberInput states none
    // of it; the composed TextField's defaults are the one source, so this
    // reads what the editable actually paints.
    testWidgets('paints 2 wide, corner 2, primary, on the value line box', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const NumberInput(initialValue: 12)));
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      final state = tester.state<EditableTextState>(find.byType(EditableText));
      final editable = state.renderEditable;
      final context = tester.element(find.byType(EditableText));
      final theme = Theme.of(context);

      expect(editable.cursorWidth, CoreTextFieldStyle.defaultCursorWidth);
      expect(editable.cursorWidth, 2);
      expect(editable.cursorRadius, const Radius.circular(2));
      expect(
        editable.cursorColor,
        theme.colorScheme
            .resolve(CoreTextFieldStyle.defaultCursorColor)
            .toValue(),
      );
      // No gap between the value and the caret.
      expect(editable.cursorOffset, Offset.zero);

      // Height follows the value's line box: bodyMedium 14 at its own 150%
      // (21) — the role's own line box, not a fixed kit number.
      final valueRole = theme.typography.bodyMedium;
      final lineBox = valueRole.fontSize! * valueRole.lineHeight!;
      expect(lineBox, 21);
      final caret = editable.getLocalRectForCaret(
        TextPosition(offset: state.textEditingValue.text.length),
      );
      // The caret is exactly the editable's own line box …
      expect(caret.height, editable.preferredLineHeight);
      // … and that box is the value line's (21).
      expect(editable.preferredLineHeight, closeTo(lineBox, 0.5));

      // The value paints in Body/Medium: Regular 14 at 150%.
      final painted = state.widget.style;
      expect(painted.fontSize, valueRole.fontSize);
      expect(painted.fontSize, 14);
      expect(painted.height, 1.5);
      expect(painted.fontWeight, FontWeight.w400);
    });
  });

  group('NumberInput value', () {
    testWidgets('the buttons move the value by step and report it', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _app(NumberInput(initialValue: 2, step: 2, onChanged: seen.add)),
      );
      await tester.tap(_increase);
      await tester.pump();
      await tester.tap(_decrease);
      await tester.tap(_decrease);
      await tester.pump();
      expect(seen, [4, 2, 0]);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('a button is disabled exactly at its bound', (tester) async {
      await tester.pumpWidget(
        _app(const NumberInput(initialValue: 1, min: 1, max: 3)),
      );
      expect(_enabled(tester, _decrease), isFalse);
      expect(_enabled(tester, _increase), isTrue);

      await tester.tap(_increase);
      await tester.pump();
      expect(_enabled(tester, _decrease), isTrue);

      await tester.tap(_increase);
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(_enabled(tester, _increase), isFalse);
      expect(_enabled(tester, _decrease), isTrue);
    });

    testWidgets('the value never leaves min..max', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _app(
          NumberInput(initialValue: 9, min: 0, max: 10, onChanged: seen.add),
        ),
      );
      await tester.tap(_increase);
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
      // At the bound the button is disabled, so a further tap changes
      // nothing.
      await tester.tap(_increase, warnIfMissed: false);
      await tester.pump();
      expect(seen, [10]);
    });

    testWidgets('a typed number is bounded when it is committed', (
      tester,
    ) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _app(NumberInput(initialValue: 3, min: 1, max: 8, onChanged: seen.add)),
      );
      final field = find.byType(TextField);
      await tester.enterText(field, '5');
      await tester.pump();
      expect(seen, [5]);

      // Outside the bounds: waits for the commit, then lands on the bound.
      await tester.enterText(field, '40');
      await tester.pump();
      expect(seen, [5]);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(seen, [5, 8]);
      expect(tester.widget<TextField>(field).controller!.text, '8');
    });

    testWidgets(
      'scientific values remain editable without changing magnitude',
      (tester) async {
        final seen = <double>[];
        await tester.pumpWidget(
          _app(NumberInput(initialValue: 1e21, onChanged: seen.add)),
        );
        final field = find.byType(TextField);
        expect(tester.widget<TextField>(field).controller!.text, '1e+21');
        await tester.enterText(field, '1.5e+21');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(seen.last, 1.5e21);
        expect(tester.widget<TextField>(field).controller!.text, '1.5e+21');
      },
    );

    testWidgets('an unparsable entry reverts on commit', (tester) async {
      await tester.pumpWidget(_app(const NumberInput(initialValue: 3)));
      final field = find.byType(TextField);
      await tester.enterText(field, '-');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tester.widget<TextField>(field).controller!.text, '3');
    });

    testWidgets('a controlled value follows the parent', (tester) async {
      await tester.pumpWidget(_app(const NumberInput(value: 2)));
      expect(find.text('2'), findsOneWidget);
      await tester.pumpWidget(_app(const NumberInput(value: 7)));
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
    });
  });

  group('NumberInput keyboard', () {
    testWidgets('arrow and page keys move the value by step', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _app(NumberInput(initialValue: 20, onChanged: seen.add)),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(seen, [21, 20, 19, 29, 19]);
    });

    testWidgets('keys do nothing while disabled', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(
        _app(NumberInput(initialValue: 2, enabled: false, onChanged: seen.add)),
      );
      expect(_enabled(tester, _increase), isFalse);
      expect(_enabled(tester, _decrease), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(seen, isEmpty);
    });
  });

  group('NumberInput semantics', () {
    testWidgets('step buttons expose enabled accessibility tap actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <double>[];
      await tester.pumpWidget(
        _app(NumberInput(initialValue: 1, min: 1, max: 2, onChanged: seen.add)),
      );
      var increase = tester.getSemantics(find.bySemanticsLabel('Increase'));
      var decrease = tester.getSemantics(find.bySemanticsLabel('Decrease'));
      expect(
        increase.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        decrease.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      increase.owner!.performAction(
        increase.id,
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(seen, [2]);
      increase = tester.getSemantics(find.bySemanticsLabel('Increase'));
      decrease = tester.getSemantics(find.bySemanticsLabel('Decrease'));
      expect(
        increase.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(
        decrease.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('exposes the value and increase / decrease actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(const NumberInput(initialValue: 4, min: 0, max: 9)),
      );
      final node = tester.getSemantics(
        find.descendant(
          of: find.byType(NumberInput),
          matching: find.byType(TextField),
        ),
      );
      expect(node, isNotNull);
      expect(
        find.bySemanticsLabel('Increase'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Decrease'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
