// The field's inset belongs to the row, not to the `<input>`.
//
// Flutter wraps the whole row (prefix + input + suffix) in the field's
// padding, so a slot sits that far inside the border. Web used to put the
// padding on the `<input>` only, and the slots touched the border. These
// tests read where every composing input puts the inset: on the framed
// wrapper for each side that carries a slot (and vertically), on the
// `<input>` only for a side without one. A slot back on the border fails
// them.
//
// The expected insets come from Core — the size row, a composing parent's
// own stated padding — never from the resolver under test.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const List<CoreSelectItem<String>> _kItems = [
  CoreSelectItem(value: 'apple', label: 'Apple'),
  CoreSelectItem(value: 'banana', label: 'Banana'),
];

/// `top right bottom left` of a `padding` shorthand, as the four tokens.
List<String> _sides(String? shorthand) {
  expect(shorthand, isNotNull, reason: 'padding shorthand present');
  final tokens = shorthand!.split(' ');
  expect(tokens, hasLength(4), reason: 'padding is `top right bottom left`');

  return tokens;
}

/// The nearest DOM element above [element].
DomComponent _domParent(Element element) {
  var cursor = element.parent;
  while (cursor != null && cursor.component is! DomComponent) {
    cursor = cursor.parent;
  }
  expect(cursor, isNotNull, reason: 'the input has a DOM parent');

  return cursor!.component as DomComponent;
}

/// The field's `<input>` (the [index]-th one on the page) and the framed
/// box around it.
({DomComponent input, DomComponent wrapper}) _field([int index = 0]) {
  final inputElement = find.tag('input').evaluate().elementAt(index);
  final input = inputElement.component as DomComponent;
  final wrapper = _domParent(inputElement);
  expect(
    wrapper.styles?.properties.containsKey('gap'),
    isTrue,
    reason: 'the input sits in the framed row (the affix wrapper)',
  );

  return (input: input, wrapper: wrapper);
}

/// Asserts the inset sits where Flutter has it: [inset] on each slotted
/// side of the wrapper, the vertical inset on the wrapper, and the input
/// keeping the inset only of a side without a slot.
void _expectRowInset({
  required CoreEdgeInsets inset,
  required bool leading,
  required bool trailing,
  int index = 0,
}) {
  final field = _field(index);
  final wrapper = _sides(field.wrapper.styles?.properties['padding']);
  final input = _sides(field.input.styles?.properties['padding']);
  final zero = spaceCss(0);

  expect(wrapper[0], spaceCss(inset.top), reason: 'wrapper top');
  expect(wrapper[2], spaceCss(inset.bottom), reason: 'wrapper bottom');
  expect(
    wrapper[3],
    leading ? spaceCss(inset.left) : zero,
    reason: 'a leading slot sits inside the inset, not on the border',
  );
  expect(
    wrapper[1],
    trailing ? spaceCss(inset.right) : zero,
    reason: 'a trailing slot sits inside the inset, not on the border',
  );

  expect(input[0], zero, reason: 'the row holds the vertical inset');
  expect(input[2], zero, reason: 'the row holds the vertical inset');
  expect(
    input[3],
    leading ? zero : spaceCss(inset.left),
    reason: 'the inset is counted once on the leading side',
  );
  expect(
    input[1],
    trailing ? zero : spaceCss(inset.right),
    reason: 'the inset is counted once on the trailing side',
  );
}

/// The size row's inset with a one-line field's vertical inset dropped —
/// the same rule both platforms read.
CoreEdgeInsets _rowInset(CoreComponentSize size) =>
    CoreTextFieldStyle.contentPadding(
      statedPadding: null,
      rowPadding: CoreTextFieldStyle.defaultsBySize[size]!.padding!,
      singleLine: true,
      height: null,
      minHeight: null,
    );

void main() {
  group('TextField — the inset wraps the row', () {
    for (final size in [
      CoreComponentSize.sm,
      CoreComponentSize.md,
      CoreComponentSize.xl,
    ]) {
      testComponents('prefix + suffix at ${size.name}', (tester) async {
        pumpWithTheme(
          tester,
          TextField(
            size: size,
            prefix: const Icon(LucideIcons.search),
            suffix: const Icon(LucideIcons.x),
          ),
        );
        _expectRowInset(inset: _rowInset(size), leading: true, trailing: true);
      });
    }

    testComponents('prefix only — the trailing inset stays on the input', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextField(prefix: Icon(LucideIcons.search)),
      );
      _expectRowInset(
        inset: _rowInset(CoreComponentSize.md),
        leading: true,
        trailing: false,
      );
    });

    testComponents('suffix only — the leading inset stays on the input', (
      tester,
    ) async {
      pumpWithTheme(tester, const TextField(suffix: Icon(LucideIcons.x)));
      _expectRowInset(
        inset: _rowInset(CoreComponentSize.md),
        leading: false,
        trailing: true,
      );
    });

    testComponents('a trailing feature button is a trailing slot', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextField(
          type: .password,
          features: [CoreInputFeature.passwordToggle()],
        ),
      );
      _expectRowInset(
        inset: _rowInset(CoreComponentSize.md),
        leading: false,
        trailing: true,
      );
    });

    testComponents('a stated padding is the one placed on the row', (
      tester,
    ) async {
      const stated = CoreEdgeInsets.fromLTRB(
        CoreSpace.space4,
        CoreSpace.space2,
        CoreSpace.space8,
        CoreSpace.space6,
      );
      pumpWithTheme(
        tester,
        const TextField(
          prefix: Icon(LucideIcons.search),
          suffix: Icon(LucideIcons.x),
          textFieldStyle: CoreTextFieldStyle(padding: stated),
        ),
      );
      _expectRowInset(inset: stated, leading: true, trailing: true);
    });

    testComponents('an unframed field keeps the whole inset on the input', (
      tester,
    ) async {
      pumpWithTheme(tester, const TextField());
      final input = find.tag('input').evaluate().single.component;
      final inset = _rowInset(CoreComponentSize.md);
      expect(
        (input as DomComponent).styles?.properties['padding'],
        inset.toValue(),
      );
    });
  });

  group('composing inputs — slots sit inside the inset', () {
    testComponents('NumberInput: −/+ start the inset from the border', (
      tester,
    ) async {
      pumpWithTheme(tester, const NumberInput(value: 3));
      // The field's own stated padding (#5762): the inset horizontally,
      // the inset less the border vertically.
      _expectRowInset(
        inset: CoreNumberInputStyle.defaultFieldStyle.padding!,
        leading: true,
        trailing: true,
      );
    });

    testComponents('Select: the chevron sits inside the trailing inset', (
      tester,
    ) async {
      pumpWithTheme(tester, const Select<String>(items: _kItems));
      _expectRowInset(
        inset: _rowInset(CoreComponentSize.md),
        leading: false,
        trailing: true,
      );
    });

    testComponents('DatePicker: the calendar glyph inside the inset', (
      tester,
    ) async {
      pumpWithTheme(tester, DatePicker(onChanged: (_) {}));
      _expectRowInset(
        inset: _rowInset(CoreComponentSize.md),
        leading: false,
        trailing: true,
      );
    });

    testComponents('TimePicker: the clock glyph inside the inset', (
      tester,
    ) async {
      pumpWithTheme(tester, const TimePicker(value: '14:30'));
      _expectRowInset(
        inset: _rowInset(CoreComponentSize.md),
        leading: false,
        trailing: true,
      );
    });

    testComponents('ItemPicker search: the glyph inside the stated inset', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ItemPicker(
          items: const ['Apple', 'Banana'],
          onChanged: (_) {},
        ),
      );
      _expectRowInset(
        inset: CoreItemPickerStyle.defaultSearchFieldStyle.padding!,
        leading: true,
        trailing: false,
      );
    });
  });
}
