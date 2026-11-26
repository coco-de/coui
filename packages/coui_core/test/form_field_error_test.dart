import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreFormFieldSeverity', () {
    test('has 3 values', () {
      expect(CoreFormFieldSeverity.values.length, 3);
      expect(
        CoreFormFieldSeverity.values.map((v) => v.name).toSet(),
        {'error', 'warning', 'info'},
      );
    });
  });

  group('CoreFormValidationTrigger', () {
    test('has 3 values', () {
      expect(CoreFormValidationTrigger.values.length, 3);
      expect(
        CoreFormValidationTrigger.values.map((v) => v.name).toSet(),
        {'onSubmit', 'onBlur', 'onChange'},
      );
    });

    test('kDefaultFormValidationTrigger is onBlur', () {
      expect(kDefaultFormValidationTrigger, CoreFormValidationTrigger.onBlur);
    });
  });

  group('CoreFormFieldError', () {
    test('severity defaults to error', () {
      const e = CoreFormFieldError(message: 'required');
      expect(e.severity, CoreFormFieldSeverity.error);
      expect(e.field, isNull);
    });

    test('stores message, field, severity', () {
      const e = CoreFormFieldError(
        message: 'invalid email',
        field: 'email',
        severity: CoreFormFieldSeverity.warning,
      );
      expect(e.message, 'invalid email');
      expect(e.field, 'email');
      expect(e.severity, CoreFormFieldSeverity.warning);
    });

    group('copyWith', () {
      const original = CoreFormFieldError(
        message: 'required',
        field: 'username',
      );

      test('no args returns equal instance', () {
        expect(original.copyWith(), original);
      });

      test('replaces message only', () {
        final updated = original.copyWith(message: 'too short');
        expect(updated.message, 'too short');
        expect(updated.field, 'username');
        expect(updated.severity, CoreFormFieldSeverity.error);
      });

      test('replaces field only', () {
        final updated = original.copyWith(field: 'email');
        expect(updated.field, 'email');
        expect(updated.message, 'required');
      });

      test('replaces severity only', () {
        final updated = original.copyWith(
          severity: CoreFormFieldSeverity.info,
        );
        expect(updated.severity, CoreFormFieldSeverity.info);
        expect(updated.message, 'required');
      });
    });

    group('equality', () {
      test('equal instances compare equal', () {
        const a = CoreFormFieldError(message: 'x', field: 'y');
        const b = CoreFormFieldError(message: 'x', field: 'y');
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('implicit null field equals explicit null field', () {
        const implicit = CoreFormFieldError(message: 'x');
        // Explicit null is intentional here — we're asserting the
        // equality contract holds regardless of how `null` was produced.
        // ignore: avoid_redundant_argument_values
        const explicit = CoreFormFieldError(message: 'x', field: null);
        expect(implicit, explicit);
        expect(implicit.hashCode, explicit.hashCode);
      });

      test('different message not equal', () {
        const a = CoreFormFieldError(message: 'x');
        const b = CoreFormFieldError(message: 'y');
        expect(a, isNot(b));
      });

      test('different severity not equal', () {
        const a = CoreFormFieldError(message: 'x');
        const b = CoreFormFieldError(
          message: 'x',
          severity: CoreFormFieldSeverity.info,
        );
        expect(a, isNot(b));
      });
    });

    test('toString includes all fields', () {
      const e = CoreFormFieldError(
        message: 'bad',
        field: 'pw',
        severity: CoreFormFieldSeverity.warning,
      );
      final s = e.toString();
      expect(s, contains('bad'));
      expect(s, contains('pw'));
      expect(s, contains('warning'));
    });
  });
}
