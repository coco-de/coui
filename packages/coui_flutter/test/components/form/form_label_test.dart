import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Theme constants
const _kLabelFontSize = 14.0;

// Color constants
const _kLabelColor = CoreColor(0xFF212121);

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('FormLabel — the size ladder', () {
    // 13 / 500 through `md`, 14 / 500 from `lg` — the label family the
    // `TextField` / `TextArea` / `Select` labels all read.
    const expected = {
      CoreComponentSize.xs: 13.0,
      CoreComponentSize.sm: 13.0,
      CoreComponentSize.md: 13.0,
      CoreComponentSize.lg: 14.0,
      CoreComponentSize.xl: 14.0,
      CoreComponentSize.xl2: 14.0,
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key.name} reads ${entry.value} / 500', (
        tester,
      ) async {
        late ResolvedFormLabel resolved;
        await tester.pumpWidget(
          _buildApp(
            Builder(
              builder: (context) {
                resolved = resolveFormLabel(context, size: entry.key);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(resolved.labelTextStyle.fontSize, entry.value);
        expect(resolved.labelTextStyle.fontWeight, FontWeight.w500);
      });
    }
  });

  group('FormLabel widget', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormLabel(
            label: Text('Email Address'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets('respects key parameter', (tester) async {
      const testKey = Key('form-label-key');

      await tester.pumpWidget(
        _buildApp(
          const FormLabel(
            key: testKey,
            label: Text('Name'),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('does not show required indicator when isRequired is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormLabel(
            label: Text('Optional Field'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // Default indicator ' *' should not appear
      expect(find.text('*'), findsNothing);
    });

    testWidgets('shows default required indicator when isRequired is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormLabel(
            label: Text('Required Field'),
            isRequired: true,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('*'), findsOneWidget);
    });

    testWidgets('shows custom required indicator when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormLabel(
            label: Text('Required Field'),
            isRequired: true,
            requiredIndicator: Text('(required)'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('(required)'), findsOneWidget);
      // Default indicator should not appear when custom one is provided
      expect(find.text('*'), findsNothing);
    });

    testWidgets('renders without padding by default', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormLabel(
            label: Text('No Padding Label'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('No Padding Label'), findsOneWidget);
    });

    testWidgets('applies custom labelStyle when provided', (tester) async {
      const customStyle = CoreFormLabelStyle(
        labelStyle: CoreTextStyle(
          color: _kLabelColor,
          fontSize: _kLabelFontSize,
        ),
      );

      await tester.pumpWidget(
        _buildApp(
          const FormLabel(
            label: Text('Styled Label'),
            formLabelStyle: customStyle,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Styled Label'), findsOneWidget);
    });

    testWidgets('both label and required indicator render together', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormLabel(
            label: Text('Password'),
            isRequired: true,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('*'), findsOneWidget);
    });
  });
}
