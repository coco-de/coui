import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kTestSize = 32.0;
const _kTestColor = CoreColor(0xFFFF0000);

mat.Widget _buildApp(mat.Widget child) => mat.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('Loading', () {
    testWidgets('renders the default spinner variant', (tester) async {
      await tester.pumpWidget(_buildApp(const Loading()));

      expect(find.byType(Loading), findsOneWidget);
    });

    testWidgets('renders with custom size via loadingStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Loading(loadingStyle: CoreLoadingStyle(size: _kTestSize)),
        ),
      );

      expect(find.byType(Loading), findsOneWidget);
    });

    testWidgets('renders with custom color via loadingStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Loading(loadingStyle: CoreLoadingStyle(color: _kTestColor)),
        ),
      );

      expect(find.byType(Loading), findsOneWidget);
    });

    testWidgets('renders the dots variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Loading(variant: CoreLoadingVariant.dots)),
      );

      expect(find.byType(Loading), findsOneWidget);
    });

    testWidgets('renders the bar variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Loading(variant: CoreLoadingVariant.bar)),
      );

      expect(find.byType(Loading), findsOneWidget);
    });

    testWidgets('renders the pulse variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Loading(variant: CoreLoadingVariant.pulse)),
      );

      expect(find.byType(Loading), findsOneWidget);
    });
  });

  group('CoreLoadingStyle', () {
    test('merge overrides only non-null fields', () {
      const base = CoreLoadingStyle(size: _kTestSize);
      const override = CoreLoadingStyle(color: _kTestColor);
      final merged = base.merge(override);

      expect(merged.size, _kTestSize);
      expect(merged.color, _kTestColor);
    });

    test('equality compares all fields', () {
      const a = CoreLoadingStyle(size: _kTestSize);
      const b = CoreLoadingStyle(size: _kTestSize);
      const c = CoreLoadingStyle(color: _kTestColor);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
