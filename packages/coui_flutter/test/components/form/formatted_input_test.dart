import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kEditableLength = 3;
const _kBorderRadius = 4.0;
const _kBorderWidth = 1.0;
const _kPhoneSegments = 6;
const _kDateSegments = 5;

material.Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(child: child),
  ),
);

/// Focuses the [TextField] under [finder] and pushes [value] through the
/// active `TextInputConnection` — the same route a real platform edit
/// (keystroke, IME commit, paste, OS-level backspace) takes, so it flows
/// through [FormattedInput]'s `inputFormatters` exactly like a genuine
/// edit would. `WidgetTester.enterText` cannot express an edit with the
/// caret anywhere but the end, so arbitrary-position insertion/deletion
/// tests drive the connection directly.
Future<void> _simulateEdit(
  WidgetTester tester,
  Finder finder,
  TextEditingValue value,
) async {
  await tester.showKeyboard(finder);
  tester.testTextInput.updateEditingValue(value);
  await tester.pump();
}

TextEditingController _controllerOf(WidgetTester tester, Finder finder) =>
    tester.widget<TextField>(finder).controller!;

void main() {
  group('CoreFormattedInputPart', () {
    test('editable part records length and pattern', () {
      const part = CoreFormattedInputPart.editable(
        length: _kEditableLength,
        pattern: r'\d',
      );
      expect(part.editable, isTrue);
      expect(part.length, equals(_kEditableLength));
      expect(part.pattern, equals(r'\d'));
    });

    test('static part records text', () {
      const part = CoreFormattedInputPart.static('/');
      expect(part.editable, isFalse);
      expect(part.text, equals('/'));
    });
  });

  group('CoreFormattedInputMasks', () {
    test('phone mask has six segments', () {
      expect(
        CoreFormattedInputMasks.phone.length,
        equals(_kPhoneSegments),
      );
    });

    test('date mask has five segments', () {
      expect(CoreFormattedInputMasks.date.length, equals(_kDateSegments));
    });
  });

  group('FormattedInput — single-field rendering', () {
    testWidgets('phone factory renders exactly one TextField', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.phone()));
      expect(find.byType(FormattedInput), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('custom parts render exactly one TextField', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormattedInput(
            parts: [
              CoreFormattedInputPart.editable(length: 2),
              CoreFormattedInputPart.static('/'),
              CoreFormattedInputPart.editable(length: 2),
            ],
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('empty field shows the full mask pattern as a hint', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.phone()));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.hintText, equals('(___) ___-____'));
    });

    testWidgets('leading and trailing render around the single field', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormattedInput.phone(
            leading: Icon(LucideIcons.phone, key: Key('leading')),
            trailing: Icon(LucideIcons.check, key: Key('trailing')),
          ),
        ),
      );
      expect(find.byKey(const Key('leading')), findsOneWidget);
      expect(find.byKey(const Key('trailing')), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('enabled: false disables the inner TextField', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const FormattedInput.phone(enabled: false)),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });

    testWidgets('implements CoreFormattedInputContract', (tester) async {
      const input = FormattedInput(parts: []);
      expect(
        input,
        isA<CoreFormattedInputContract<ValueChanged<String>?, Widget>>(),
      );
    });
  });

  group('FormattedInput — autofill hints (DDR-04)', () {
    test('phone factory defaults to telephoneNumber', () {
      const input = FormattedInput.phone();
      expect(
        input.autofillHints,
        equals(const [AutofillHints.telephoneNumber]),
      );
    });

    test('koreanPhone factory defaults to telephoneNumber', () {
      const input = FormattedInput.koreanPhone();
      expect(
        input.autofillHints,
        equals(const [AutofillHints.telephoneNumber]),
      );
    });

    test('creditCard factory defaults to creditCardNumber', () {
      const input = FormattedInput.creditCard();
      expect(
        input.autofillHints,
        equals(const [AutofillHints.creditCardNumber]),
      );
    });

    test('date factory has no autofill default', () {
      const input = FormattedInput.date();
      expect(input.autofillHints, isNull);
    });

    test('explicit parts constructor has no autofill default', () {
      const input = FormattedInput(parts: []);
      expect(input.autofillHints, isNull);
    });

    test('caller can override the phone factory default', () {
      const input = FormattedInput.phone(
        autofillHints: [AutofillHints.username],
      );
      expect(input.autofillHints, equals(const [AutofillHints.username]));
    });

    testWidgets('autofillHints reach the composed TextField', (tester) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.phone()));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.autofillHints,
        equals(const [AutofillHints.telephoneNumber]),
      );
    });
  });

  group('FormattedInput — typing and onChanged', () {
    testWidgets('typing the full raw value at once fires onChanged '
        'with the raw digits and displays the formatted mask', (
      tester,
    ) async {
      final values = <String>[];
      await tester.pumpWidget(
        _buildApp(FormattedInput.phone(onChanged: values.add)),
      );
      await tester.enterText(find.byType(TextField), '3334567890');
      await tester.pump();

      expect(values, isNotEmpty);
      expect(values.last, equals('3334567890'));
      expect(
        _controllerOf(tester, find.byType(TextField)).text,
        equals('(333) 456-7890'),
      );
    });

    testWidgets('custom parts field fires onChanged with the raw value', (
      tester,
    ) async {
      String? value;
      await tester.pumpWidget(
        _buildApp(
          FormattedInput(
            onChanged: (v) => value = v,
            parts: const [CoreFormattedInputPart.editable(length: 3)],
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      expect(value, equals('123'));
    });

    testWidgets('a literal is only emitted once the next digit is typed', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.phone()));
      await tester.enterText(find.byType(TextField), '333');
      await tester.pump();
      expect(
        _controllerOf(tester, find.byType(TextField)).text,
        equals('(333'),
      );
    });
  });

  group('FormattedInput — arbitrary-position insertion (widget-level)', () {
    testWidgets('typing past a group boundary auto-inserts the literal '
        'and moves the caret past it', (tester) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.koreanPhone()));
      final finder = find.byType(TextField);

      await _simulateEdit(
        tester,
        finder,
        const TextEditingValue(
          text: '010',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await _simulateEdit(
        tester,
        finder,
        const TextEditingValue(
          text: '0101',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );

      final controller = _controllerOf(tester, finder);
      expect(controller.text, equals('010-1'));
      expect(controller.selection.baseOffset, equals('010-1'.length));
    });

    testWidgets('pasting a full raw value at once formats and positions '
        'the caret at the end', (tester) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.koreanPhone()));
      final finder = find.byType(TextField);

      await _simulateEdit(
        tester,
        finder,
        const TextEditingValue(
          text: '01012345678',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );

      final controller = _controllerOf(tester, finder);
      expect(controller.text, equals('010-1234-5678'));
      expect(controller.selection.baseOffset, equals('010-1234-5678'.length));
    });

    testWidgets('deleting a selected middle chunk reflows the remaining '
        'digits', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        _buildApp(FormattedInput.phone(onChanged: values.add)),
      );
      final finder = find.byType(TextField);

      await _simulateEdit(
        tester,
        finder,
        const TextEditingValue(
          text: '(333) 456-7890',
          selection: TextSelection.collapsed(offset: 14),
        ),
      );
      // Select and delete "456" from "(333) 456-7890" in one action.
      await _simulateEdit(
        tester,
        finder,
        const TextEditingValue(
          text: '(333) -7890',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );

      final controller = _controllerOf(tester, finder);
      expect(controller.text, equals('(333) 789-0'));
      expect(values.last, equals('3337890'));
    });
  });

  group('FormattedInput — backspace at a literal boundary (DDR-05)', () {
    testWidgets('backspace right after a hyphen deletes the preceding '
        'digit, not the hyphen', (tester) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.koreanPhone()));
      final finder = find.byType(TextField);

      await _simulateEdit(
        tester,
        finder,
        const TextEditingValue(
          text: '010-1234',
          selection: TextSelection.collapsed(offset: 8),
        ),
      );

      // Move the caret to right after the first hyphen (e.g. a tap or an
      // arrow-key move) — a local selection change Flutter never routes
      // through `TextInputFormatter` (only platform-reported *edits* are),
      // so this is set directly on the controller rather than through
      // `_simulateEdit`.
      final controller = _controllerOf(tester, finder)
        ..selection = const TextSelection.collapsed(offset: 4);
      await tester.pump();

      // OS-level Backspace with the caret right after the first hyphen
      // removes the hyphen character; the raw digit stream must still
      // shrink by one (the last digit of the first group), not be a
      // dead keystroke.
      await _simulateEdit(
        tester,
        finder,
        const TextEditingValue(
          text: '0101234',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );

      expect(controller.text, equals('011-234'));
    });

    testWidgets('backspace on an empty field is a no-op, not a crash', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.koreanPhone()));
      final finder = find.byType(TextField);

      await _simulateEdit(
        tester,
        finder,
        const TextEditingValue(selection: TextSelection.collapsed(offset: 0)),
      );

      final controller = _controllerOf(tester, finder);
      expect(controller.text, isEmpty);
    });
  });

  group('FormattedInput — controlled value', () {
    testWidgets('external value changes reformat the displayed text', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _buildApp(FormattedInput.phone(key: key, value: '333')),
      );
      expect(
        _controllerOf(tester, find.byType(TextField)).text,
        equals('(333'),
      );

      await tester.pumpWidget(
        _buildApp(FormattedInput.phone(key: key, value: '3334567890')),
      );
      await tester.pump();
      expect(
        _controllerOf(tester, find.byType(TextField)).text,
        equals('(333) 456-7890'),
      );
    });
  });

  group('FormattedInput — koreanPhone preset (DDR-03)', () {
    testWidgets('formats as 3-4-4', (tester) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.koreanPhone()));
      await tester.enterText(find.byType(TextField), '01012345678');
      await tester.pump();
      expect(
        _controllerOf(tester, find.byType(TextField)).text,
        equals('010-1234-5678'),
      );
    });
  });

  // The field fills the width it is given — the same rule the Web twin's
  // root row follows (`flex w-full`) and every other text-entry field
  // keeps. Pinned here so a change on either platform that lets the field
  // shrink to its content shows up as a failure on the other platform's
  // side of the pair too.
  group('FormattedInput — width', () {
    const kNarrow = 300.0;

    double viewportWidth(WidgetTester tester) =>
        tester.view.physicalSize.width / tester.view.devicePixelRatio;

    testWidgets('fills the available width under a loose parent', (
      tester,
    ) async {
      // `_buildApp` centres the field, which hands it loose constraints.
      await tester.pumpWidget(_buildApp(const FormattedInput.phone()));
      expect(
        tester.getSize(find.byType(FormattedInput)).width,
        viewportWidth(tester),
      );
    });

    testWidgets('follows a parent that states a width', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(width: kNarrow, child: FormattedInput.phone()),
        ),
      );
      expect(tester.getSize(find.byType(FormattedInput)).width, kNarrow);
    });

    testWidgets('the field takes whatever width the affixes leave over', (
      tester,
    ) async {
      const leadingKey = Key('leading');
      const trailingKey = Key('trailing');
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(
            width: kNarrow,
            child: FormattedInput.phone(
              leading: SizedBox(key: leadingKey, width: 40, height: 16),
              trailing: SizedBox(key: trailingKey, width: 30, height: 16),
            ),
          ),
        ),
      );

      final leading = tester.getRect(find.byKey(leadingKey));
      final field = tester.getRect(find.byType(TextField));
      final trailing = tester.getRect(find.byKey(trailingKey));

      // One content gap between each affix and the field, no other slack.
      expect(
        field.left,
        leading.right + CoreFormattedInputStyle.defaultContentSpacing,
      );
      expect(
        field.right,
        trailing.left - CoreFormattedInputStyle.defaultContentSpacing,
      );
    });
  });

  // The row is the text field's lg row (48), not the frame around its line:
  // the padding is horizontal only and the line sits centred in the row. The
  // composed `TextField` still gives way to the `codeMd` role `FormattedInput`
  // states (13px on a 21px line) rather than laying its own base over it.
  group('FormattedInput — height', () {
    testWidgets('is the lg control row', (tester) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.phone()));
      expect(
        tester.getSize(find.byType(FormattedInput)).height,
        CoreFormattedInputStyle.defaultHeight,
      );
      expect(CoreFormattedInputStyle.defaultHeight, CoreControlSize.heightLg);
    });

    testWidgets('types on the code role: 13px on a 21px line', (tester) async {
      await tester.pumpWidget(_buildApp(const FormattedInput.phone()));
      final style = tester
          .widget<material.EditableText>(find.byType(material.EditableText))
          .style;
      expect(style.fontSize, 13);
      expect(style.height! * style.fontSize!, closeTo(CoreLineBox.px21, 0.001));
    });
  });

  group('CoreFormattedInputStyle', () {
    test('merge overrides non-null fields', () {
      const base = CoreFormattedInputStyle(
        borderRadius: CoreBorderRadius.all(_kBorderRadius),
      );
      const override = CoreFormattedInputStyle(borderWidth: _kBorderWidth);
      final merged = base.merge(override);
      expect(
        merged.borderRadius,
        equals(const CoreBorderRadius.all(_kBorderRadius)),
      );
      expect(merged.borderWidth, equals(_kBorderWidth));
    });
  });
}
