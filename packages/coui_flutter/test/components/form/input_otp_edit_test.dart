import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cell editing is opt-in and survives copyWith', () {
    const standard = InputOtp();
    expect(standard.allowCellEditing, isFalse);
    final editing = standard.copyWith(allowCellEditing: true);
    expect(editing.allowCellEditing, isTrue);
    expect(editing.copyWith(length: 4).allowCellEditing, isTrue);
  });
  for (final dark in [false, true]) {
    for (final editing in [false, true]) {
      testWidgets(
        'hidden OTP selection remains invisible, dark=$dark, editing=$editing',
        (tester) async {
          await tester.pumpWidget(
            material.MaterialApp(
              home: Theme(
                data: dark ? const ThemeData.dark() : const ThemeData(),
                child: material.Scaffold(
                  body: InputOtp(
                    allowCellEditing: editing,
                    initialValue: '123'.codeUnits,
                  ),
                ),
              ),
            ),
          );
          await tester.tapAt(tester.getCenter(find.text('2')));
          await tester.pumpAndSettle();
          final input = tester.widget<material.EditableText>(
            find.byType(material.EditableText),
          );
          expect(input.focusNode.hasFocus, isTrue);
          expect(input.selectionColor, material.Colors.transparent);
        },
      );
    }
  }
  testWidgets('cell editing keeps one OTP autofill field and completion edge', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      material.MaterialApp(
        home: Theme(
          data: const ThemeData(),
          child: material.Scaffold(
            body: InputOtp(
              allowCellEditing: true,
              onCompleted: (_) => completions++,
            ),
          ),
        ),
      ),
    );
    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    expect(
      tester.widget<TextField>(field).autofillHints,
      contains(AutofillHints.oneTimeCode),
    );
    await tester.showKeyboard(field);
    await tester.enterText(field, '123456');
    await tester.pump();
    expect(completions, 1);
    final editable = tester.widget<material.EditableText>(
      find.byType(material.EditableText),
    );
    expect(editable.focusNode.hasFocus, isFalse);
    await tester.tapAt(tester.getCenter(find.text('2')));
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '193456',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(completions, 1);
    expect(editable.focusNode.hasFocus, isTrue);
  });
  testWidgets('cell editing stays disabled when the field is disabled', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(
      material.MaterialApp(
        home: Theme(
          data: const ThemeData(),
          child: material.Scaffold(
            body: InputOtp(
              allowCellEditing: true,
              enabled: false,
              initialValue: '123456'.codeUnits,
              onChanged: (_) => changes++,
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(tester.getCenter(find.text('2')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    final editable = tester.widget<material.EditableText>(
      find.byType(material.EditableText),
    );
    expect(field.enabled, isFalse);
    expect(editable.focusNode.hasFocus, isFalse);
    expect(editable.controller.text, '123456');
    expect(changes, 0);
  });

  testWidgets('cell editing does not reveal obscured digits', (tester) async {
    await tester.pumpWidget(
      material.MaterialApp(
        home: Theme(
          data: const ThemeData(),
          child: material.Scaffold(
            body: InputOtp(
              allowCellEditing: true,
              obscured: true,
              initialValue: '123456'.codeUnits,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final digit in '123456'.split('')) {
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == digit),
        findsNothing,
      );
    }
    expect(find.byType(material.EditableText), findsOneWidget);
  });

  testWidgets('completion rearms after deleting a middle cell', (
    tester,
  ) async {
    final completed = <String>[];
    await tester.pumpWidget(
      material.MaterialApp(
        home: Theme(
          data: const ThemeData(),
          child: material.Scaffold(
            body: InputOtp(
              allowCellEditing: true,
              initialValue: '123'.codeUnits,
              onCompleted: (value) => completed.add(
                String.fromCharCodes(value.nonNulls),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    final editable = tester.widget<material.EditableText>(
      find.byType(material.EditableText),
    );
    await tester.tapAt(tester.getCenter(find.text('1')));
    await tester.pumpAndSettle();
    expect(
      editable.controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    await tester.enterText(field, '123456');
    await tester.pump();
    expect(completed, ['123456']);
    await tester.tapAt(tester.getCenter(find.text('3')));
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '12456',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(completed, ['123456']);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '129456',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(completed, ['123456', '129456']);
  });

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    for (final narrow in [false, true]) {
      testWidgets('selects a filled cell in $direction narrow=$narrow', (
        tester,
      ) async {
        OTPCodepointList? value;
        var completions = 0;
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: const ThemeData(),
              child: material.Scaffold(
                body: Directionality(
                  textDirection: direction,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: narrow ? 180 : 400,
                      child: InputOtp(
                        allowCellEditing: true,
                        initialValue: '123456'.codeUnits,
                        onChanged: (next) => value = next,
                        onCompleted: (_) => completions++,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tapAt(tester.getCenter(find.text('2')));
        await tester.pumpAndSettle();
        final editable = tester.widget<material.EditableText>(
          find.byType(material.EditableText),
        );
        expect(
          editable.controller.selection,
          const TextSelection(baseOffset: 1, extentOffset: 2),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(
          editable.controller.selection,
          const TextSelection.collapsed(offset: 1),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(
          editable.controller.selection,
          const TextSelection.collapsed(offset: 2),
        );
        await tester.tapAt(tester.getCenter(find.text('2')));
        await tester.pumpAndSettle();
        final outlines = tester
            .widgetList<FocusOutline>(
              find.descendant(
                of: find.byType(InputOtp),
                matching: find.byType(FocusOutline),
              ),
            )
            .skip(1)
            .toList();
        expect(outlines.length, 6);
        expect(
          [for (final o in outlines) o.focused],
          [false, true, false, false, false, false],
        );
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '193456',
            selection: TextSelection.collapsed(offset: 2),
          ),
        );
        await tester.pump();
        expect(String.fromCharCodes(value!.nonNulls), '193456');
        expect(completions, 0);
        expect(editable.focusNode.hasFocus, isTrue);
        editable.controller.selection = const TextSelection.collapsed(
          offset: 4,
        );
        await tester.pump();
        final moved = tester
            .widgetList<FocusOutline>(
              find.descendant(
                of: find.byType(InputOtp),
                matching: find.byType(FocusOutline),
              ),
            )
            .skip(1)
            .toList();
        expect(
          [for (final o in moved) o.focused],
          [false, false, false, false, true, false],
        );
      });
    }
  }
}
