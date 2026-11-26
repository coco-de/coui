import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kMaxLength4 = 4;
const _kMaxLength2 = 2;
const _kBorderRadius = 8.0;
const _kBorderWidth = 1.0;
const _kFieldCount = 3;

material.Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(child: child),
  ),
);

const _kDateFields = [
  CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4),
  CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2),
  CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2),
];

/// The container's painted border colour — the outer box the composed
/// `OutlinedContainer` draws around the fields. The fields themselves are
/// chromeless, so this is the one visible boundary.
Color _containerBorderColor(WidgetTester tester) {
  final box = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OutlinedContainer),
          matching: find.byType(DecoratedBox),
        ),
      )
      .first;
  final decoration = box.decoration as BoxDecoration;
  return (decoration.border! as Border).top.color;
}

/// The scheme-resolved colour of a Core token, the way the container does.
Color _resolved(WidgetTester tester, CoreColor color) => Theme.of(
  tester.element(find.byType(ObjectInput)),
).colorScheme.resolve(color).toValue();

/// Parks a mouse pointer over the centre of [finder] and returns the
/// gesture so the test can move it away again.
Future<TestGesture> _hoverOver(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: .mouse);
  await gesture.addPointer(location: .zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pumpAndSettle();
  return gesture;
}

void main() {
  group('CoreObjectInputField', () {
    test('records key, placeholder and maxLength', () {
      const field = CoreObjectInputField(
        key: 'year',
        placeholder: 'YYYY',
        maxLength: _kMaxLength4,
      );
      expect(field.key, equals('year'));
      expect(field.placeholder, equals('YYYY'));
      expect(field.maxLength, equals(_kMaxLength4));
    });

    test('equality compares all fields', () {
      const a = CoreObjectInputField(
        key: 'm',
        placeholder: 'MM',
        maxLength: _kMaxLength2,
      );
      const b = CoreObjectInputField(
        key: 'm',
        placeholder: 'MM',
        maxLength: _kMaxLength2,
      );
      expect(a, equals(b));
    });
  });

  group('ObjectInput', () {
    testWidgets('renders all fields', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ObjectInput(fields: _kDateFields)),
      );
      expect(find.byType(TextField), findsNWidgets(_kFieldCount));
    });

    testWidgets('renders separator between fields', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ObjectInput(fields: _kDateFields, separator: '/'),
        ),
      );
      expect(find.text('/'), findsNWidgets(2));
    });

    testWidgets('typing fires onChanged with values map', (tester) async {
      Map<String, String>? values;
      await tester.pumpWidget(
        _buildApp(
          ObjectInput(
            onChanged: (v) => values = v,
            fields: _kDateFields,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, '2024');
      await tester.pump();
      expect(values?['year'], equals('2024'));
    });

    testWidgets('implements CoreObjectInputContract', (tester) async {
      const input = ObjectInput(fields: _kDateFields);
      expect(
        input,
        isA<
          CoreObjectInputContract<ValueChanged<Map<String, String>>?, Widget>
        >(),
      );
    });
  });

  group('CoreObjectInputStyle', () {
    test('merge overrides non-null fields', () {
      const base = CoreObjectInputStyle(
        borderRadius: CoreBorderRadius.all(_kBorderRadius),
      );
      const override = CoreObjectInputStyle(borderWidth: _kBorderWidth);
      final merged = base.merge(override);
      expect(
        merged.borderRadius,
        equals(const CoreBorderRadius.all(_kBorderRadius)),
      );
      expect(merged.borderWidth, equals(_kBorderWidth));
    });
  });

  // The container is the box and the fields inside it are chromeless, so the
  // pointer has to step the container's own border: `disabled > focus >
  // hover > rest`. A focused container keeps its focus border under the
  // pointer.
  group('container hover border', () {
    testWidgets('the resolver swaps only the border colour', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ObjectInput(fields: _kDateFields)),
      );
      final _ = await tester.pumpAndSettle();

      final resolved = resolveObjectInput(
        tester.element(find.byType(ObjectInput)),
      );
      final rest = resolved.unfocusedContainerStyle;
      final hovered = resolved.hoveredContainerStyle;

      expect(rest.borderColor, CoreObjectInputStyle.defaultBorderColor);
      expect(hovered.borderColor, CoreObjectInputStyle.defaultHoverBorderColor);
      // Everything else is the resting chrome — a hovered container must
      // not be a different box.
      expect(
        hovered.copyWith(borderColor: rest.borderColor),
        equals(rest),
      );
    });

    testWidgets('rests on the resting border', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ObjectInput(fields: _kDateFields)),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        _containerBorderColor(tester),
        _resolved(tester, CoreObjectInputStyle.defaultBorderColor),
      );
    });

    testWidgets('the pointer steps the border to the hover colour and back', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const ObjectInput(fields: _kDateFields)),
      );
      final _ = await tester.pumpAndSettle();
      final rest = _resolved(tester, CoreObjectInputStyle.defaultBorderColor);
      final hover = _resolved(
        tester,
        CoreObjectInputStyle.defaultHoverBorderColor,
      );
      expect(hover, isNot(rest));

      final gesture = await _hoverOver(tester, find.byType(ObjectInput));
      expect(_containerBorderColor(tester), hover);

      // Over a field inside the container is still over the container.
      await gesture.moveTo(tester.getCenter(find.byType(TextField).first));
      await tester.pumpAndSettle();
      expect(_containerBorderColor(tester), hover);

      await gesture.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(_containerBorderColor(tester), rest);
    });

    testWidgets('a per-instance hoverBorderColor wins over the default', (
      tester,
    ) async {
      const custom = CoreColor.token(CoreColors.error);
      await tester.pumpWidget(
        _buildApp(
          const ObjectInput(
            fields: _kDateFields,
            objectInputStyle: CoreObjectInputStyle(hoverBorderColor: custom),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await _hoverOver(tester, find.byType(ObjectInput));

      expect(_containerBorderColor(tester), _resolved(tester, custom));
    });

    testWidgets('focus wins: a focused container keeps its focus border '
        'under the pointer', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ObjectInput(fields: _kDateFields)),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      final focus = _resolved(
        tester,
        CoreObjectInputStyle.defaultFocusBorderColor,
      );
      expect(
        _containerBorderColor(tester),
        focus,
        reason:
            'the tap has to focus the container for this test to mean '
            'anything',
      );

      await _hoverOver(tester, find.byType(ObjectInput));
      expect(_containerBorderColor(tester), focus);
    });

    testWidgets('a disabled container has no hover step', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ObjectInput(fields: _kDateFields, enabled: false)),
      );
      final _ = await tester.pumpAndSettle();

      await _hoverOver(tester, find.byType(ObjectInput));

      expect(
        _containerBorderColor(tester),
        _resolved(tester, CoreObjectInputStyle.defaultDisabledBorderColor),
      );
    });
  });
}
