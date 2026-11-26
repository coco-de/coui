import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kValidationStateCount = 3;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

Finder _iconFinder(IconName name) =>
    find.byWidgetPredicate((widget) => widget is Icon && widget.icon == name);

void main() {
  group('CoreValidationBadgeStyle', () {
    test('default constructor creates style with null values', () {
      const style = CoreValidationBadgeStyle();

      expect(style.pendingBackgroundColor, isNull);
      expect(style.pendingBorderColor, isNull);
      expect(style.validBackgroundColor, isNull);
      expect(style.validBorderColor, isNull);
      expect(style.invalidBackgroundColor, isNull);
      expect(style.invalidBorderColor, isNull);
    });

    test('constructor accepts background and border colors', () {
      const style = CoreValidationBadgeStyle(
        pendingBackgroundColor: CoreColor(0xFF888888),
        pendingBorderColor: CoreColor(0xFF888888),
        validBackgroundColor: CoreColor(0xFF00FF00),
        validBorderColor: CoreColor(0xFF00FF00),
        invalidBackgroundColor: CoreColor(0xFFFF0000),
        invalidBorderColor: CoreColor(0xFFFF0000),
      );

      expect(style.pendingBackgroundColor, equals(const CoreColor(0xFF888888)));
      expect(style.validBackgroundColor, equals(const CoreColor(0xFF00FF00)));
      expect(
        style.invalidBackgroundColor,
        equals(const CoreColor(0xFFFF0000)),
      );
    });

    test('equality returns true for identical styles', () {
      const style1 = CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor(0xFF00FF00),
      );
      const style2 = CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor(0xFF00FF00),
      );

      expect(style1, equals(style2));
      expect(style1.hashCode, equals(style2.hashCode));
    });

    test('equality returns false for different styles', () {
      const style1 = CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor(0xFF00FF00),
      );
      const style2 = CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor(0xFFFF0000),
      );

      expect(style1, isNot(equals(style2)));
    });

    test('merge combines two styles with other taking precedence', () {
      const base = CoreValidationBadgeStyle(
        pendingBackgroundColor: CoreColor(0xFF888888),
        validBackgroundColor: CoreColor(0xFF00FF00),
      );
      const override = CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor(0xFF0000FF),
        invalidBackgroundColor: CoreColor(0xFFFF0000),
      );

      final merged = base.merge(override);

      expect(
        merged.pendingBackgroundColor,
        equals(const CoreColor(0xFF888888)),
      );
      expect(merged.validBackgroundColor, equals(const CoreColor(0xFF0000FF)));
      expect(
        merged.invalidBackgroundColor,
        equals(const CoreColor(0xFFFF0000)),
      );
    });

    test('merge with null returns same style', () {
      const style = CoreValidationBadgeStyle(
        validBackgroundColor: CoreColor(0xFF00FF00),
      );

      final merged = style.merge(null);

      expect(merged.validBackgroundColor, equals(const CoreColor(0xFF00FF00)));
    });
  });

  group('ValidationBadge', () {
    testWidgets('renders with pending state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(label: 'Pending check', state: .pending),
        ),
      );
      await tester.pump();

      expect(find.text('Pending check'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders with valid state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(label: 'Valid input', state: .valid),
        ),
      );
      await tester.pump();

      expect(find.text('Valid input'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders with invalid state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(label: 'Invalid input', state: .invalid),
        ),
      );
      await tester.pump();

      expect(find.text('Invalid input'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders with custom valid icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(
            label: 'Custom icon',
            state: .valid,
            validIcon: LucideIcons.lock,
          ),
        ),
      );
      await tester.pump();

      expect(_iconFinder(LucideIcons.lock), findsOneWidget);
    });

    testWidgets('renders with custom invalid icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(
            label: 'Custom icon',
            state: .invalid,
            invalidIcon: LucideIcons.lockOpen,
          ),
        ),
      );
      await tester.pump();

      expect(_iconFinder(LucideIcons.lockOpen), findsOneWidget);
    });

    testWidgets('renders with custom pending icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(
            label: 'Custom pending',
            state: .pending,
            pendingIcon: LucideIcons.hourglass,
          ),
        ),
      );
      await tester.pump();

      expect(_iconFinder(LucideIcons.hourglass), findsOneWidget);
    });

    testWidgets('renders with small size by default', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(label: 'Default size', state: .valid),
        ),
      );
      await tester.pump();

      expect(find.byType(ValidationBadge), findsOneWidget);
    });

    testWidgets('renders with extra small size', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(
            label: 'Extra small',
            state: .valid,
            size: .extraSmall,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ValidationBadge), findsOneWidget);
    });

    testWidgets('renders with medium size', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(
            label: 'Medium',
            state: .valid,
            size: .medium,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ValidationBadge), findsOneWidget);
    });

    testWidgets('renders with custom style', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(
            label: 'Styled',
            state: .valid,
            style: CoreValidationBadgeStyle(
              validBackgroundColor: CoreColor(0xFF0000FF),
              validBorderColor: CoreColor(0xFFFFFFFF),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ValidationBadge), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = Key('validation-badge-test');

      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(key: testKey, label: 'Test', state: .valid),
        ),
      );
      await tester.pump();

      expect(find.byKey(testKey), findsOneWidget);
    });
  });

  group('ValidationBadge.fromBool', () {
    testWidgets('creates valid state when isValid is true', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.fromBool(label: 'Password length', isValid: true),
        ),
      );
      await tester.pump();

      expect(find.text('Password length'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('creates invalid state when isValid is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.fromBool(label: 'Password length', isValid: false),
        ),
      );
      await tester.pump();

      expect(find.text('Password length'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('accepts custom icons', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.fromBool(
            label: 'Secure',
            isValid: false,
            validIcon: LucideIcons.lock,
            invalidIcon: LucideIcons.lockOpen,
          ),
        ),
      );
      await tester.pump();

      expect(_iconFinder(LucideIcons.lockOpen), findsOneWidget);
    });

    testWidgets('accepts size parameter', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.fromBool(
            label: 'Sized',
            isValid: true,
            size: .medium,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ValidationBadge), findsOneWidget);
    });
  });

  group('ValidationBadge.withPending', () {
    testWidgets('shows pending when hasInput is false', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.withPending(
            label: 'Min 8 chars',
            hasInput: false,
            isValid: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Min 8 chars'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('shows valid when hasInput is true and isValid is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.withPending(
            label: 'Min 8 chars',
            hasInput: true,
            isValid: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Min 8 chars'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('shows invalid when hasInput is true and isValid is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.withPending(
            label: 'Min 8 chars',
            hasInput: true,
            isValid: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Min 8 chars'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('accepts custom pending icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.withPending(
            label: 'Waiting',
            hasInput: false,
            isValid: false,
            pendingIcon: LucideIcons.hourglass,
          ),
        ),
      );
      await tester.pump();

      expect(_iconFinder(LucideIcons.hourglass), findsOneWidget);
    });

    testWidgets('accepts size and style parameters', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ValidationBadge.withPending(
            label: 'Styled',
            hasInput: true,
            isValid: true,
            size: .extraSmall,
            style: const CoreValidationBadgeStyle(
              validBackgroundColor: CoreColor(0xFF0000FF),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ValidationBadge), findsOneWidget);
    });
  });

  group('CoreValidationState', () {
    test('has three values', () {
      expect(
        CoreValidationState.values.length,
        equals(_kValidationStateCount),
      );
    });

    test('contains expected states', () {
      expect(
        CoreValidationState.values,
        contains(CoreValidationState.pending),
      );
      expect(CoreValidationState.values, contains(CoreValidationState.valid));
      expect(
        CoreValidationState.values,
        contains(CoreValidationState.invalid),
      );
    });
  });

  group('ValidationBadge geometry', () {
    Widget loose(Widget child) =>
        _buildApp(Align(alignment: Alignment.topLeft, child: child));

    BoxDecoration decoration(WidgetTester tester) {
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ValidationBadge),
              matching: find.byType(Container),
            )
            .first,
      );
      return box.decoration! as BoxDecoration;
    }

    testWidgets('heights are 20 · 24 · 28 and the radius 4 · 6 · 6', (
      tester,
    ) async {
      for (final entry in {
        CoreValidationBadgeSize.extraSmall: (20.0, 4.0),
        CoreValidationBadgeSize.small: (24.0, 6.0),
        CoreValidationBadgeSize.medium: (28.0, 6.0),
      }.entries) {
        await tester.pumpWidget(
          loose(
            ValidationBadge(
              label: 'Valid',
              state: CoreValidationState.valid,
              size: entry.key,
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(ValidationBadge)).height,
          entry.value.$1,
        );
        expect(
          decoration(tester).borderRadius,
          BorderRadius.circular(entry.value.$2),
        );
      }
    });

    testWidgets('draws no border by default', (tester) async {
      await tester.pumpWidget(
        loose(
          const ValidationBadge(
            label: 'Valid',
            state: CoreValidationState.valid,
          ),
        ),
      );
      expect(decoration(tester).border, isNull);
    });

    testWidgets('a border width above 0 brings the border back', (
      tester,
    ) async {
      await tester.pumpWidget(
        loose(
          const ValidationBadge(
            label: 'Valid',
            state: CoreValidationState.valid,
            style: CoreValidationBadgeStyle(borderWidth: 1),
          ),
        ),
      );
      expect(decoration(tester).border, isNotNull);
    });

    testWidgets('pending shows a clock', (tester) async {
      await tester.pumpWidget(
        loose(
          const ValidationBadge(
            label: 'Pending',
            state: CoreValidationState.pending,
          ),
        ),
      );
      expect(_iconFinder(LucideIcons.clock), findsOneWidget);
    });

    testWidgets('sides are 8 · 8 · 10 with the gap 4 · 4 · 6', (tester) async {
      for (final entry in {
        CoreValidationBadgeSize.extraSmall: (8.0, 4.0),
        CoreValidationBadgeSize.small: (8.0, 4.0),
        CoreValidationBadgeSize.medium: (10.0, 6.0),
      }.entries) {
        await tester.pumpWidget(
          loose(
            ValidationBadge(
              label: 'Valid',
              state: CoreValidationState.valid,
              size: entry.key,
            ),
          ),
        );
        final badge = tester.getRect(find.byType(ValidationBadge));
        final icon = tester.getRect(find.byType(Icon));
        expect(icon.left - badge.left, entry.value.$1);
        final label = tester.getRect(find.text('Valid'));
        expect(label.left - icon.right, entry.value.$2);
      }
    });
  });
}
