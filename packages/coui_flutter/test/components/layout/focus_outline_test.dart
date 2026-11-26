import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestAlign = 4.0;
const _kTestBorderWidth = 2.0;
const _kTestBorderRadius = CoreBorderRadius.circular(8.0);

void main() {
  group('CoreFocusRing token parity', () {
    test('ringOpacity matches Web ring-ring (full opacity)', () {
      // Web uses `ring-ring` CSS class which applies the primary color
      // at 100% opacity. Flutter must match this to ensure visual parity.
      expect(CoreFocusRing.ringOpacity, equals(1));
    });

    test('ringWidth matches Web ring-2 (2px)', () {
      expect(CoreFocusRing.ringWidth, equals(2));
    });

    test('ringOffset matches Web ring-offset-2 (2px)', () {
      expect(CoreFocusRing.ringOffset, equals(2));
    });
  });

  group('FocusOutline default ring', () {
    testWidgets('uses primary color at full opacity when focused', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const FocusOutline(
            focused: true,
            child: material.SizedBox(width: 100, height: 40),
          ),
        ),
      );

      // Pump animation to completion.
      final _ = await tester.pumpAndSettle();

      // Find the inner Container that renders the focus ring decoration.
      final containers = find.byType(material.Container).evaluate();
      final ringContainer = containers
          .map((e) => e.widget)
          .whereType<material.Container>()
          .where((c) => c.decoration is BoxDecoration)
          .where((c) {
            final deco = c.decoration! as BoxDecoration;
            return deco.border != null;
          });

      expect(ringContainer, isNotEmpty, reason: 'Focus ring container found');

      final deco = ringContainer.first.decoration! as BoxDecoration;
      final border = deco.border! as Border;
      final ringColor = border.top.color;

      // Ring color should be primary at full opacity (scaleAlpha(1.0) = no-op).
      final theme = const ThemeData();
      final expectedColor = theme.colorScheme.primary.toValue();
      expect(
        ringColor.a,
        equals(expectedColor.a),
        reason: 'Focus ring opacity should match Web (full opacity)',
      );
    });
  });

  group('FocusOutline ringOpacity', () {
    Future<material.Border> pumpAndFindRingBorder(
      WidgetTester tester,
      CoreFocusOutlineStyle? focusOutlineStyle,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          FocusOutline(
            focusOutlineStyle: focusOutlineStyle,
            focused: true,
            child: const material.SizedBox(width: 100, height: 40),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final containers = find.byType(material.Container).evaluate();
      final ringContainer = containers
          .map((e) => e.widget)
          .whereType<material.Container>()
          .where((c) => c.decoration is BoxDecoration)
          .where((c) {
            final deco = c.decoration! as BoxDecoration;
            return deco.border != null;
          })
          .first;
      final deco = ringContainer.decoration! as BoxDecoration;
      return deco.border! as Border;
    }

    testWidgets(
      'setting ringOpacity alone (no borderColor override) dims the ring',
      (tester) async {
        final fullBorder = await pumpAndFindRingBorder(tester, null);
        final dimmedBorder = await pumpAndFindRingBorder(
          tester,
          const CoreFocusOutlineStyle(ringOpacity: 0.5),
        );

        expect(
          dimmedBorder.top.color.a,
          lessThan(fullBorder.top.color.a),
          reason:
              'ringOpacity must scale the default border colour — a '
              'no-op here means the field is declared but unwired',
        );
      },
    );

    testWidgets('ringOpacity of 1.0 (default) is a no-op', (tester) async {
      final implicitBorder = await pumpAndFindRingBorder(tester, null);
      final explicitBorder = await pumpAndFindRingBorder(
        tester,
        const CoreFocusOutlineStyle(ringOpacity: 1),
      );

      expect(explicitBorder.top.color.a, equals(implicitBorder.top.color.a));
    });
  });

  group('FocusOutline', () {
    testWidgets('renders with child when focused is false', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const FocusOutline(
            focused: false,
            child: material.Text('Inner Widget'),
          ),
        ),
      );

      expect(find.byType(FocusOutline), findsOneWidget);
      expect(find.text('Inner Widget'), findsOneWidget);
    });

    testWidgets('renders with child when focused is true', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const FocusOutline(
            focused: true,
            child: material.Text('Focused Child'),
          ),
        ),
      );

      expect(find.byType(FocusOutline), findsOneWidget);
      expect(find.text('Focused Child'), findsOneWidget);
    });

    testWidgets('renders with borderRadius param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const FocusOutline(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderRadius: _kTestBorderRadius,
            ),
            focused: false,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(FocusOutline), findsOneWidget);
    });

    testWidgets('renders with align param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const FocusOutline(
            focusOutlineStyle: CoreFocusOutlineStyle(align: _kTestAlign),
            focused: false,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(FocusOutline), findsOneWidget);
    });

    testWidgets('renders with border param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const FocusOutline(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderWidth: _kTestBorderWidth,
            ),
            focused: true,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(FocusOutline), findsOneWidget);
    });

    testWidgets('renders with circle shape', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const FocusOutline(
            focused: true,
            shape: .circle,
            child: material.SizedBox(
              width: 40,
              height: 40,
            ),
          ),
        ),
      );

      expect(find.byType(FocusOutline), findsOneWidget);
    });

    testWidgets('uses Stack with AnimatedValueBuilder internally', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const FocusOutline(
            focused: false,
            child: material.Text('Check'),
          ),
        ),
      );

      expect(find.byType(Stack), findsWidgets);
    });
  });
}
