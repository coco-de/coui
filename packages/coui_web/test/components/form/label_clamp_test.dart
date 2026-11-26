import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kLabel = 'A label long enough to be worth clamping';
const _kTwoLines = 2;

Iterable<DomComponent> _elements() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

/// The `-webkit-line-clamp` the label's `Text` emitted, or `null` when
/// no element in the tree carries a line clamp.
String? _lineClamp() {
  for (final el in _elements()) {
    final clamp = el.styles?.properties['-webkit-line-clamp'];
    if (clamp != null) return clamp;
  }
  return null;
}

/// Whether any element's class list carries `truncate` — the utility
/// that draws the single-line default on the controls that clamp.
bool _hasTruncate() => _elements().any(
  (el) => (el.classes ?? '').split(' ').contains('truncate'),
);

void main() {
  // Same assertions as the Flutter twin's label clamp test, read off the
  // DOM the label renders into: the parameter reaching the widget is not
  // enough, it has to reach the element.
  group('wrap-by-default controls keep wrapping until asked', () {
    testComponents('Checkbox emits no clamp by default', (tester) async {
      pumpWithTheme(tester, Checkbox(label: _kLabel));

      expect(_lineClamp(), isNull);
    });

    testComponents('Checkbox forwards a stated clamp to its label', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Checkbox(
          label: _kLabel,
          labelMaxLines: _kTwoLines,
          labelOverflow: CoreTextOverflow.ellipsis,
        ),
      );

      expect(_lineClamp(), '$_kTwoLines');
    });

    testComponents('SwitchField forwards a stated clamp to its label', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SwitchField(label: _kLabel, labelMaxLines: 1),
      );

      expect(_lineClamp(), '1');
    });
  });

  group('single-line controls keep their clamp as the default', () {
    testComponents('ValidationBadge keeps truncate while nothing is stated', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ValidationBadge(label: _kLabel, state: .valid),
      );

      expect(_hasTruncate(), isTrue);
      expect(_lineClamp(), isNull);
    });

    testComponents('ValidationBadge swaps truncate for the stated clamp', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ValidationBadge(
          label: _kLabel,
          state: .valid,
          labelMaxLines: _kTwoLines,
        ),
      );

      // `truncate` pins `white-space: nowrap`, which would hold a
      // two-line clamp to one line — it has to step aside.
      expect(_hasTruncate(), isFalse);
      expect(_lineClamp(), '$_kTwoLines');
    });

    testComponents('Chip falls back to one line when only overflow is set', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Chip(label: _kLabel, labelOverflow: CoreTextOverflow.clip),
      );

      expect(_hasTruncate(), isFalse);
      expect(_lineClamp(), '${CoreChipContract.defaultLabelMaxLines}');
    });
  });
}
