import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// Minimal [CoreFormFieldHandle] standing in for the field glue (the real
/// `FormField` is exercised in widget tests) — the controller only reads
/// [formKey] from it during `attach`.
class _StubHandle implements CoreFormFieldHandle {
  const _StubHandle(this.formKey);

  @override
  final CoreFormKey<dynamic> formKey;

  @override
  bool get mounted => true;

  @override
  FutureOr<ValidationResult?> reportNewFormValue<T>(T? value) => null;

  @override
  FutureOr<ValidationResult?> revalidate() => null;
}

void main() {
  group('Web FormController (shared algorithm + listener-bag binding)', () {
    test('surfaces a sync validator error for a missing required value', () {
      final controller = FormController();
      const key = FormKey<String>('name');
      final context = CoUIWebValidationContext();

      controller.attach(
        context,
        _StubHandle(key),
        null,
        const RequiredValidator<String>(),
      );

      final error = controller.getSyncError(key);
      expect(error, isA<InvalidResult>());
      expect((error! as InvalidResult).message, 'This field cannot be empty');
    });

    test('clears the error once a value is present', () {
      final controller = FormController();
      const key = FormKey<String>('name');
      final context = CoUIWebValidationContext();
      final handle = _StubHandle(key);

      controller
        ..attach(context, handle, null, const RequiredValidator<String>())
        ..attach(context, handle, 'Ada', const RequiredValidator<String>());

      expect(controller.getSyncError(key), isNull);
    });

    test('collects values and reports presence', () {
      final controller = FormController();
      const key = FormKey<String>('name');
      final context = CoUIWebValidationContext();

      controller.attach(context, _StubHandle(key), 'Ada', null);

      expect(controller.getValue(key), 'Ada');
      expect(controller.hasValue(key), isTrue);
      expect(controller.values[key], 'Ada');
    });

    test('notifies listeners on attach (microtask-deferred)', () async {
      final controller = FormController();
      const key = FormKey<String>('name');
      final context = CoUIWebValidationContext();
      var notified = 0;
      controller.addListener(() => notified += 1);

      controller.attach(context, _StubHandle(key), 'Ada', null);
      expect(notified, 0, reason: 'notification is deferred, not synchronous');

      await Future<void>.delayed(.zero);
      expect(notified, greaterThan(0));
    });

    test('stops notifying after dispose', () async {
      final controller = FormController();
      const key = FormKey<String>('name');
      final context = CoUIWebValidationContext();
      var notified = 0;
      controller
        ..addListener(() => notified += 1)
        ..dispose()
        ..attach(context, _StubHandle(key), 'Ada', null);

      await Future<void>.delayed(.zero);
      expect(notified, 0);
    });
  });
}
