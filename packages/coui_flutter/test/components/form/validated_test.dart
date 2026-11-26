import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// Reads the border colour of the [TextField]'s chrome box.
Color _fieldBorderColor(WidgetTester tester) {
  final containers = tester.widgetList<material.Container>(
    find.descendant(
      of: find.byType(TextField),
      matching: find.byType(material.Container),
    ),
  );
  for (final container in containers) {
    final decoration = container.decoration;
    if (decoration is material.BoxDecoration && decoration.border != null) {
      return (decoration.border! as material.Border).top.color;
    }
  }
  fail('TextField renders no bordered container');
}

/// Pumps [child] and returns the field's rendered border colour.
Future<Color> _pumpAndReadBorder(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_buildApp(child));
  final _ = await tester.pumpAndSettle();
  return _fieldBorderColor(tester);
}

void main() {
  group('Validated widget', () {
    testWidgets('renders child for valid state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Validated(
            state: .valid,
            child: material.Text('No error'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Validated), findsOneWidget);
      expect(find.text('No error'), findsOneWidget);
    });

    testWidgets('respects key parameter', (tester) async {
      const testKey = Key('validated-key');

      await tester.pumpWidget(
        _buildApp(
          const Validated(
            key: testKey,
            state: .valid,
            child: material.Text('content'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('renders the provided child', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Validated(
            state: .pending,
            child: material.Text('Child content'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Child content'), findsOneWidget);
    });

    testWidgets('renders the message for invalid state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Validated(
            state: .invalid,
            message: material.Text('Error message'),
            child: material.Text('Field'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Validated), findsOneWidget);
      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets(
      'invalid state propagates to the wrapped field as its error variant',
      (tester) async {
        // Reference — the field's own error variant border.
        final errorBorder = await _pumpAndReadBorder(
          tester,
          TextField(onChanged: (_) {}, errorText: 'e'),
        );

        // Baseline — an idle field keeps the idle border.
        final idleBorder = await _pumpAndReadBorder(
          tester,
          TextField(onChanged: (_) {}),
        );
        expect(idleBorder, isNot(errorBorder));

        // The ambient Validated state flips the wrapped field to the
        // same error variant — no second ring, the field's own border.
        final propagatedBorder = await _pumpAndReadBorder(
          tester,
          Validated(
            state: .invalid,
            child: TextField(onChanged: (_) {}),
          ),
        );
        expect(propagatedBorder, errorBorder);
      },
    );

    testWidgets('renders without a message', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Validated(
            state: .valid,
            child: material.Text('Field'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Validated), findsOneWidget);
      expect(find.text('Field'), findsOneWidget);
    });
  });
}
