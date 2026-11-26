// Pins the Web half of `min` / `max`.
//
// Two separate things have to stay true here, and they are true for
// different reasons:
//
//   1. The `<input min max>` attributes keep rendering. That is what
//      gives the browser its own constraint validation — blocking form
//      submission, raising `rangeOverflow`, matching `:invalid`. None of
//      that is reimplemented in Dart, so losing the attributes would
//      silently drop it. Hence the regression guard.
//
//   2. The error chrome follows the verdict. `:invalid` matches on the
//      element but no rule in this package paints it, so the tone is
//      resolved in Dart from the same shared predicate Flutter reads.
//      Without this, Web renders a constraint the user cannot see until
//      they try to submit.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

DomComponent get _input =>
    find.tag('input').evaluate().single.component as DomComponent;

/// The classes carrying the field's border chrome.
///
/// They sit on the box `<div>` that holds the `<input>`. Compared between
/// builds rather than asserted against a literal, so a case says "the
/// tone changed" without pinning which token it changed to — and the
/// helper asserts the string is non-empty so an empty-vs-empty
/// comparison cannot pass by accident.
String _chromeClasses() {
  final input = _input;
  final box = find
      .tag('div')
      .evaluate()
      .map((element) => element.component)
      .whereType<DomComponent>()
      .firstWhere((box) => (box.children ?? const []).contains(input));
  final classes = box.classes ?? '';
  expect(classes, isNotEmpty, reason: 'chrome classes must be present');

  return classes;
}

void main() {
  group('TextField min/max', () {
    testComponents('renders min and max as input attributes', (tester) async {
      pumpWithTheme(
        tester,
        TextField(type: CoreInputType.number, min: 0, max: 10),
      );

      expect(_input.attributes?['min'], equals('0'));
      expect(_input.attributes?['max'], equals('10'));
    });

    testComponents('keeps the attributes when the value violates them', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TextField(
          initialValue: '99',
          type: CoreInputType.number,
          min: 0,
          max: 10,
        ),
      );

      expect(
        _input.attributes?['max'],
        equals('10'),
        reason: 'the browser still owns constraint validation',
      );
    });

    testComponents('out-of-range text changes the chrome', (tester) async {
      pumpWithTheme(
        tester,
        TextField(
          initialValue: '5',
          type: CoreInputType.number,
          min: 0,
          max: 10,
        ),
      );
      final neutral = _chromeClasses();

      pumpWithTheme(
        tester,
        TextField(
          initialValue: '99',
          type: CoreInputType.number,
          min: 0,
          max: 10,
        ),
      );

      expect(_chromeClasses(), isNot(equals(neutral)));
    });

    testComponents('the violation tone is the errorText tone', (tester) async {
      pumpWithTheme(tester, TextField(initialValue: '5', errorText: 'nope'));
      final errorTone = _chromeClasses();

      pumpWithTheme(
        tester,
        TextField(
          initialValue: '99',
          type: CoreInputType.number,
          min: 0,
          max: 10,
        ),
      );

      expect(
        _chromeClasses(),
        equals(errorTone),
        reason: 'a range violation is an error, not a third state',
      );
    });

    testComponents('unparseable text is not a range violation', (tester) async {
      pumpWithTheme(
        tester,
        TextField(
          initialValue: '5',
          type: CoreInputType.number,
          min: 0,
          max: 10,
        ),
      );
      final neutral = _chromeClasses();

      pumpWithTheme(
        tester,
        TextField(
          initialValue: 'abc',
          type: CoreInputType.number,
          min: 0,
          max: 10,
        ),
      );

      expect(
        _chromeClasses(),
        equals(neutral),
        reason: 'the browser calls that badInput, a different rule',
      );
    });
  });
}
