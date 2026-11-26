import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreNumberInputMath.clamp', () {
    test('limits to the stated bounds only', () {
      expect(CoreNumberInputMath.clamp(5, min: 1, max: 3), 3);
      expect(CoreNumberInputMath.clamp(-5, min: 1, max: 3), 1);
      expect(CoreNumberInputMath.clamp(2, min: 1, max: 3), 2);
      expect(CoreNumberInputMath.clamp(-99), -99);
      expect(CoreNumberInputMath.clamp(99, min: 0), 99);
      expect(CoreNumberInputMath.clamp(-1, max: 5), -1);
    });
  });

  group('CoreNumberInputMath.stepped', () {
    test('moves by step and stays inside the bounds', () {
      expect(CoreNumberInputMath.stepped(5, step: 2), 7);
      expect(CoreNumberInputMath.stepped(5, step: 2, steps: -1), 3);
      expect(CoreNumberInputMath.stepped(9, step: 2, max: 10), 10);
      expect(CoreNumberInputMath.stepped(1, step: 2, steps: -1, min: 0), 0);
    });

    test('scientific decimal steps preserve their magnitude', () {
      expect(CoreNumberInputMath.stepped(0, step: 1e-7), 1e-7);
      expect(CoreNumberInputMath.stepped(1e-7, step: 2e-7), 3e-7);
      expect(CoreNumberInputMath.stepped(3e-7, step: 1e-7, steps: -1), 2e-7);
      expect(CoreNumberInputMath.stepped(0, step: 1e-320), 1e-320);
      expect(CoreNumberInputMath.stepped(0, step: 1.5e-7), 1.5e-7);
    });

    test('a page of steps is steps times step', () {
      expect(
        CoreNumberInputMath.stepped(
          20,
          step: 1,
          steps: CoreNumberInputMath.pageSteps,
        ),
        30,
      );
    });

    test('floating-point drift is rounded away at the step precision', () {
      expect(CoreNumberInputMath.stepped(0.1, step: 0.2), 0.3);
      expect(CoreNumberInputMath.stepped(0.3, step: 0.1, steps: -1), 0.2);
      expect(CoreNumberInputMath.stepped(1.15, step: 0.05), 1.2);
    });
  });

  group('CoreNumberInputMath bounds', () {
    test('canDecrease / canIncrease are false exactly at the bound', () {
      expect(CoreNumberInputMath.canDecrease(1, min: 1), isFalse);
      expect(CoreNumberInputMath.canDecrease(1.5, min: 1), isTrue);
      expect(CoreNumberInputMath.canDecrease(-100), isTrue);
      expect(CoreNumberInputMath.canIncrease(8, max: 8), isFalse);
      expect(CoreNumberInputMath.canIncrease(7, max: 8), isTrue);
      expect(CoreNumberInputMath.canIncrease(1000000000), isTrue);
    });
  });

  group('CoreNumberInputMath text', () {
    test('format prints a whole number without a decimal point', () {
      expect(CoreNumberInputMath.format(3), '3');
      expect(CoreNumberInputMath.format(-2), '-2');
      expect(CoreNumberInputMath.format(0), '0');
      expect(CoreNumberInputMath.format(2.5), '2.5');
    });

    test('format preserves large finite values', () {
      for (final value in [1e20, 1e21, 1e100, -1e100]) {
        expect(double.parse(CoreNumberInputMath.format(value)), value);
      }
      expect(CoreNumberInputMath.format(-double.minPositive * 0), '0');
    });

    test('parse reads a number and rejects everything else', () {
      expect(CoreNumberInputMath.parse(' 12 '), 12);
      expect(CoreNumberInputMath.parse('-3.5'), -3.5);
      expect(CoreNumberInputMath.parse('+4'), 4);
      expect(CoreNumberInputMath.parse(''), isNull);
      expect(CoreNumberInputMath.parse('-'), isNull);
      expect(CoreNumberInputMath.parse('1e3x'), isNull);
      expect(CoreNumberInputMath.parse('NaN'), isNull);
      expect(CoreNumberInputMath.parse('Infinity'), isNull);
    });
  });

  group('CoreNumberInputStyle', () {
    test('the size rows state the widths the parts add up to', () {
      for (final size in CoreNumberInputSize.values) {
        expect(
          CoreNumberInputStyle.defaultsBySize[size]!.width,
          CoreNumberInputStyle.widthAt(size),
          reason: size.name,
        );
      }
      expect(
        CoreNumberInputStyle.widthAt(CoreNumberInputSize.sm),
        90,
      );
      expect(
        CoreNumberInputStyle.widthAt(CoreNumberInputSize.md),
        114,
      );
      expect(
        CoreNumberInputStyle.widthAt(CoreNumberInputSize.lg),
        138,
      );
    });

    test('the button step follows the field height', () {
      expect(CoreNumberInputSize.sm.toStepButtonSize(), CoreComponentSize.xs);
      expect(CoreNumberInputSize.md.toStepButtonSize(), CoreComponentSize.sm);
      expect(CoreNumberInputSize.lg.toStepButtonSize(), CoreComponentSize.md);
    });

    test('the field takes the TextField rung of the same name', () {
      expect(CoreNumberInputSize.sm.toComponentSize(), CoreComponentSize.sm);
      expect(CoreNumberInputSize.md.toComponentSize(), CoreComponentSize.md);
      expect(CoreNumberInputSize.lg.toComponentSize(), CoreComponentSize.lg);
    });

    test('merge keeps the base and lets the other win field by field', () {
      const base = CoreNumberInputStyle(
        width: 100,
        buttonStyle: CoreButtonStyle(),
      );
      const patch = CoreNumberInputStyle(width: 120);
      final merged = base.merge(patch);
      expect(merged.width, 120);
      expect(merged.buttonStyle, const CoreButtonStyle());
      expect(base.merge(null), same(base));
    });

    test('equality and hashCode cover every field', () {
      const a = CoreNumberInputStyle(width: 100);
      const b = CoreNumberInputStyle(width: 100);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(a.copyWith(width: 101)));
      expect(a, isNot(a.copyWith(buttonStyle: const CoreButtonStyle())));
      expect(
        a,
        isNot(a.copyWith(fieldStyle: const CoreTextFieldStyle(height: 10))),
      );
    });

    test('the theme compares its variant table by content', () {
      const one = CoreNumberInputTheme(
        variantStyles: {
          CoreNumberInputVariant.error: CoreNumberInputStyle(width: 1),
        },
      );
      const two = CoreNumberInputTheme(
        variantStyles: {
          CoreNumberInputVariant.error: CoreNumberInputStyle(width: 1),
        },
      );
      expect(one, two);
      expect(one.hashCode, two.hashCode);
    });
  });
}
