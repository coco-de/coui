// What the density spacing guard sees in a resolver — the shapes the code
// actually takes, line breaks included, because the guard this replaces
// read text and missed exactly that.
import 'package:test/test.dart';

import '../../tool/density_spacing_reach.dart';

List<String> _unbent(String body) => [
  for (final finding in scanSource('''
double resolve(dynamic merged, dynamic theme, double scaling) {
  $body
  return 0;
}
''', path: 'x_style.dart').unbent)
    finding.source,
];

void main() {
  group('flags spacing that skips the density', () {
    test('a merged value with its default', () {
      expect(
        _unbent('final g = (merged.itemSpacing ?? 8) * scaling;'),
        ['(merged.itemSpacing ?? 8) * scaling'],
      );
    });

    test('across line breaks', () {
      expect(
        _unbent('''
final g =
      (merged.rowContentSpacing ??
          CoreXxxStyle.defaultRowContentSpacing) *
      scaling;'''),
        hasLength(1),
      );
    });

    test('with the factor on the left', () {
      expect(_unbent('final g = scaling * merged.gap;'), hasLength(1));
    });

    test('through `theme.scaling` and `*=`', () {
      expect(
        _unbent('''
final a = merged.labelGap * theme.scaling;
var itemSpacing = merged.spacing;
itemSpacing *= scaling;'''),
        hasLength(2),
      );
    });

    test('when the spacing is only part of the operand', () {
      expect(
        _unbent('final g = (theme.geometry.space(a) + merged.gap) * scaling;'),
        hasLength(1),
      );
    });
  });

  group('passes spacing that took the density', () {
    test('every way a resolver names the geometry', () {
      expect(
        _unbent('''
final a = theme.geometry.space(merged.gap ?? 8) * scaling;
final b = geometry.space(merged.spacing) * scaling;
final c = Theme.of(context).geometry.space(merged.itemSpacing) * scaling;
final d = scaling * theme.geometry.space(merged.spacing);
final e = (theme.geometry.space(merged.gap)) * scaling;'''),
        isEmpty,
      );
    });

    test('the gap of a dash pattern — a stroke, not a layout', () {
      expect(
        _unbent('''
final a = (merged.dashSpacing ?? 4) * scaling;
final b = CoreDashedBorder.dashGap * scaling;'''),
        isEmpty,
      );
    });

    test('values that are not spacing at all', () {
      expect(
        _unbent('''
final a = (merged.width ?? 40) * scaling;
final b = merged.iconSize * scaling;
final c = merged.padding.toValue() * scaling;'''),
        isEmpty,
      );
    });
  });

  test('counts the population it read', () {
    final scan = scanSource('''
double f(double scaling, double a, double gap) =>
    a * scaling + gap * scaling + scaling * 2;
''', path: 'x_style.dart');
    expect(scan.products, 3);
    expect(scan.unbent, hasLength(1));
  });
}
