import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The `static const spaceN = …` members of `CoreSpace`, in source order,
/// read from the declaration rather than listed here.
///
/// A list typed into this test would be a second copy of the scale; the
/// point is to catch a constant added to the class without being added to
/// [CoreSpace.steps] (or the reverse), so the comparison has to start from
/// the declarations themselves.
Map<String, double> _declaredSteps() {
  final source = File('lib/src/spacing/spacing.dart').readAsStringSync();
  final pattern = RegExp(r'static const (space(\d+)) = ([0-9.]+);');

  return {
    for (final m in pattern.allMatches(source))
      m.group(1)!: double.parse(m.group(3)!),
  };
}

void main() {
  group('CoreSpace.steps — the whole scale, nothing else', () {
    test('lists every declared spaceN constant, in ascending order', () {
      final declared = _declaredSteps();
      expect(
        declared.length,
        greaterThanOrEqualTo(40),
        reason: 'source scan found too few constants — check the pattern',
      );

      final ascending = declared.values.toList()..sort();
      expect(CoreSpace.steps, ascending);
    });

    test('each step is the value in its name, so --coui-space-N names it', () {
      // Web turns a step into `var(--coui-space-${step.toInt()})`, and the
      // `:root` block names each variable after the constant. The two only
      // agree while every value is the integer in its own name.
      for (final entry in _declaredSteps().entries) {
        final n = entry.key.replaceFirst('space', '');
        expect(entry.value, double.parse(n), reason: entry.key);
        expect(entry.value, entry.value.truncateToDouble(), reason: entry.key);
      }
    });

    test('starts at zero and strictly ascends', () {
      expect(CoreSpace.steps.first, CoreSpace.space0);
      for (var i = 1; i < CoreSpace.steps.length; i++) {
        expect(
          CoreSpace.steps[i],
          greaterThan(CoreSpace.steps[i - 1]),
          reason: 'step $i',
        );
      }
    });

    test('an off-scale value is not on the list', () {
      // The list is how Web tells a step from an arbitrary value; values
      // between steps and negative values must stay off it.
      expect(CoreSpace.steps, isNot(contains(19)));
      expect(CoreSpace.steps, isNot(contains(-4)));
      expect(CoreSpace.steps, isNot(contains(4.5)));
    });
  });
}
