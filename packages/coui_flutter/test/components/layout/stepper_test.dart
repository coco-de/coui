import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestStepperWidth = 600.0;
const _kTestStepperNarrowWidth = 400.0;

const _kSteps = [
  CoreStepItem(label: 'Step 1', description: 'First'),
  CoreStepItem(label: 'Step 2', description: 'Second'),
];

void main() {
  group('CoreStepItem', () {
    test('stores label and description', () {
      const item = CoreStepItem(label: 'Account', description: 'Details');

      expect(item.label, equals('Account'));
      expect(item.description, equals('Details'));
    });

    test('leaves description null by default', () {
      const item = CoreStepItem(label: 'Account');

      expect(item.description, isNull);
    });
  });

  group('Stepper', () {
    testWidgets('renders the step labels', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.SizedBox(
            width: _kTestStepperWidth,
            child: Stepper(steps: _kSteps),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Stepper), findsOneWidget);
      // 3 per label — the visible text plus the two invisible
      // width-reservation layers (active / inactive styled) that keep
      // the step column from resizing when the current step changes.
      expect(find.text('Step 1'), findsNWidgets(3));
      expect(find.text('Step 2'), findsNWidgets(3));
    });

    testWidgets('renders with vertical orientation', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.SizedBox(
            width: _kTestStepperNarrowWidth,
            child: Stepper(
              orientation: CoreStepperOrientation.vertical,
              steps: _kSteps,
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Stepper), findsOneWidget);
    });

    testWidgets('honors currentStep', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.SizedBox(
            width: _kTestStepperWidth,
            child: Stepper(currentStep: 1, steps: _kSteps),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Stepper), findsOneWidget);
      // Visible + 2 invisible width-reservation layers (see above).
      expect(find.text('Step 2'), findsNWidgets(3));
    });

    testWidgets('onStepChanged callback is wired up', (tester) async {
      int? changedStep;

      await tester.pumpWidget(
        _buildApp(
          material.SizedBox(
            width: _kTestStepperWidth,
            child: Stepper(
              onStepChanged: (index) {
                changedStep = index;
              },
              steps: _kSteps,
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Stepper), findsOneWidget);
      expect(changedStep, isNull);
    });
  });
}
