import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kTestIconSize = 32.0;
const _kTestColor = CoreColor(0xFFFF0000);

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('Icon', () {
    testWidgets('renders the widget in the tree', (tester) async {
      await tester.pumpWidget(_buildApp(const Icon(LucideIcons.star)));
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders with custom size via iconStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Icon(
            LucideIcons.star,
            iconStyle: CoreIconStyle(size: _kTestIconSize),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders with custom color via iconStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Icon(
            LucideIcons.house,
            iconStyle: CoreIconStyle(color: _kTestColor),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Icon), findsOneWidget);
    });
  });

  group('CoreIconStyle', () {
    test('merge overrides only non-null fields', () {
      const base = CoreIconStyle(size: _kTestIconSize);
      const override = CoreIconStyle(color: _kTestColor);
      final merged = base.merge(override);

      expect(merged.size, _kTestIconSize);
      expect(merged.color, _kTestColor);
    });

    test('equality compares all fields', () {
      const a = CoreIconStyle(size: _kTestIconSize);
      const b = CoreIconStyle(size: _kTestIconSize);
      const c = CoreIconStyle(color: _kTestColor);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
