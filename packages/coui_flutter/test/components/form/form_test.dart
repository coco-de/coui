import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Form key identifiers
const _kFieldKeyName = 'name';
const _kFormValidationModeCount = 3;
const _kFieldKeyEmail = 'email';

// Validation message constants

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
  localizationsDelegates: const [
    CoUILocalizationsDelegate(),
    material.DefaultMaterialLocalizations.delegate,
    material.DefaultWidgetsLocalizations.delegate,
  ],
);

void main() {
  group('FormKey', () {
    test('creates with string key', () {
      const key = FormKey<String>(_kFieldKeyName);

      expect(key.key, equals(_kFieldKeyName));
    });

    test('equality based on key value', () {
      const keyA = FormKey<String>(_kFieldKeyName);
      const keyB = FormKey<String>(_kFieldKeyName);

      expect(keyA, equals(keyB));
    });

    test('different key values are not equal', () {
      const keyA = FormKey<String>(_kFieldKeyName);
      const keyB = FormKey<String>(_kFieldKeyEmail);

      expect(keyA, isNot(equals(keyB)));
    });

    test('hashCode is consistent for equal keys', () {
      const keyA = FormKey<String>(_kFieldKeyName);
      const keyB = FormKey<String>(_kFieldKeyName);

      expect(keyA.hashCode, equals(keyB.hashCode));
    });

    test('toString includes key value', () {
      const key = FormKey<String>(_kFieldKeyName);

      expect(key.toString(), contains(_kFieldKeyName));
    });

    test('type getter returns generic type', () {
      const key = FormKey<String>(_kFieldKeyName);

      expect(key.type, equals(String));
    });

    test('isInstanceOf returns true for matching type', () {
      const key = FormKey<String>(_kFieldKeyName);

      expect(key.isInstanceOf('hello'), isTrue);
    });

    test('isInstanceOf returns false for non-matching type', () {
      const key = FormKey<int>(_kFieldKeyName);

      expect(key.isInstanceOf('hello'), isFalse);
    });
  });

  group('FormValidationMode', () {
    test('has three modes: initial, changed, submitted', () {
      expect(
        FormValidationMode.values.length,
        equals(_kFormValidationModeCount),
      );
      expect(FormValidationMode.values, contains(FormValidationMode.initial));
      expect(FormValidationMode.values, contains(FormValidationMode.changed));
      expect(FormValidationMode.values, contains(FormValidationMode.submitted));
    });
  });

  group('FormController', () {
    test('values is empty when no fields registered', () {
      final controller = FormController();
      expect(controller.values, isEmpty);
      controller.dispose();
    });

    test('errors is empty when no fields registered', () {
      final controller = FormController();
      expect(controller.errors, isEmpty);
      controller.dispose();
    });

    test('validities is empty when no fields registered', () {
      final controller = FormController();
      expect(controller.validities, isEmpty);
      controller.dispose();
    });

    test('getError returns null for unknown key', () {
      final controller = FormController();
      const key = FormKey<String>(_kFieldKeyName);

      expect(controller.getError(key), isNull);
      controller.dispose();
    });

    test('getSyncError returns null for unknown key', () {
      final controller = FormController();
      const key = FormKey<String>(_kFieldKeyName);

      expect(controller.getSyncError(key), isNull);
      controller.dispose();
    });

    test('getValue returns null for unknown key', () {
      final controller = FormController();
      const key = FormKey<String>(_kFieldKeyName);

      expect(controller.getValue(key), isNull);
      controller.dispose();
    });

    test('hasValue returns false for unknown key', () {
      final controller = FormController();
      const key = FormKey<String>(_kFieldKeyName);

      expect(controller.hasValue(key), isFalse);
      controller.dispose();
    });
  });

  group('Form widget', () {
    testWidgets('renders without error with minimal setup', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Form(children: [SizedBox.shrink()]),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('respects key parameter', (tester) async {
      const testKey = Key('form-key');

      await tester.pumpWidget(
        _buildApp(
          const Form(
            key: testKey,
            children: [SizedBox.shrink()],
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('renders its children', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Form(
            children: [Text('Form content')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Form content'), findsOneWidget);
    });

    testWidgets('accepts an external FormController', (tester) async {
      final controller = FormController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          Form(
            controller: controller,
            children: const [Text('Form content')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Form content'), findsOneWidget);
    });
  });

  // showActions / primaryAction / secondaryAction (2026-09-11) — the
  // widget slots never wire to onSubmit (완전 수동 결정), and the
  // default rendering only appears when showActions is true.
  group('Form actions row', () {
    testWidgets('showActions defaults to false — no actions render', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Form(children: [Text('Form content')]),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Submit'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets(
      'showActions renders the default Submit / Cancel buttons',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Form(showActions: true, children: [Text('Form content')]),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.widgetWithText(Button, 'Submit'), findsOneWidget);
        expect(find.widgetWithText(Button, 'Cancel'), findsOneWidget);
      },
    );

    testWidgets(
      'a custom primaryAction replaces the default Submit button outright',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Form(
              showActions: true,
              primaryAction: Text('Save changes'),
              children: [Text('Form content')],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.text('Save changes'), findsOneWidget);
        expect(find.text('Submit'), findsNothing);
        // secondaryAction still renders its own default.
        expect(find.widgetWithText(Button, 'Cancel'), findsOneWidget);
      },
    );

    testWidgets(
      'showSecondaryAction: false hides the Cancel button, Submit stays',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Form(
              showActions: true,
              showSecondaryAction: false,
              children: [Text('Form content')],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.widgetWithText(Button, 'Submit'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
      },
    );

    testWidgets(
      'pressing the default primaryAction does NOT call onSubmit — the '
      'two are fully independent by design',
      (tester) async {
        var submitCount = 0;
        await tester.pumpWidget(
          _buildApp(
            Form(
              showActions: true,
              onSubmit: () => submitCount++,
              children: const [Text('Form content')],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(Button, 'Submit'));
        final _ = await tester.pumpAndSettle();

        expect(submitCount, 0);
      },
    );
  });
}
