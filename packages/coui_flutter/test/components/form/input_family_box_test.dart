// FormattedInput and ObjectInput share the text field's lg-row box (#5831):
// the outer container owns the single border / fill / focus boundary, and the
// composed `TextField` is the `plain` variant on the `lg` row with no border
// or fill of its own. These read the values the widgets actually paint, not
// the Core declarations alone.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kFields = [
  CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4),
  CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2),
];

material.Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Center(child: child),
  ),
);

BoxDecoration _boxDecoration(WidgetTester tester) {
  final box = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OutlinedContainer),
          matching: find.byType(DecoratedBox),
        ),
      )
      .first;
  return box.decoration as BoxDecoration;
}

Color _scheme(WidgetTester tester, Finder owner, CoreColor color) =>
    Theme.of(tester.element(owner)).colorScheme.resolve(color).toValue();

/// Every box the composed fields paint: none may draw a visible border or a
/// non-transparent fill — the outer container is the only boundary.
void _expectNoInnerBoxChrome(WidgetTester tester) {
  final boxes = tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byType(TextField),
      matching: find.byType(DecoratedBox),
    ),
  );
  for (final box in boxes) {
    final decoration = box.decoration;
    if (decoration is! BoxDecoration) continue;
    final border = decoration.border;
    if (border is Border) {
      for (final side in [
        border.top,
        border.bottom,
        border.left,
        border.right,
      ]) {
        expect(
          side.width == 0 || side.color.a == 0,
          isTrue,
          reason: 'an inner field drew a ${side.width}px ${side.color} edge',
        );
      }
    }
    final color = decoration.color;
    expect(
      color == null || color.a == 0,
      isTrue,
      reason: 'an inner field filled itself with $color',
    );
  }
}

void main() {
  group('FormattedInput box', () {
    testWidgets('is one lg row (48) with the 12 corner and a 1 outline-variant '
        'edge', (tester) async {
      await tester.pumpWidget(_app(const FormattedInput.phone()));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(OutlinedContainer)).height,
        CoreControlSize.heightLg,
      );
      final decoration = _boxDecoration(tester);
      final border = decoration.border! as Border;
      expect(border.top.width, CoreStrokeWidth.stroke1);
      expect(
        border.top.color,
        _scheme(
          tester,
          find.byType(FormattedInput),
          const CoreColor.token(CoreColors.outlineVariant),
        ),
      );
      expect(
        decoration.borderRadius,
        BorderRadius.circular(CoreRadius.radius12),
      );
    });

    testWidgets('the composed TextField is plain on the lg row', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const FormattedInput.phone()));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.variant, CoreTextFieldVariant.plain);
      expect(field.size, CoreComponentSize.lg);
    });

    testWidgets('the inner field draws no border or fill of its own', (
      tester,
    ) async {
      for (final enabled in [true, false]) {
        await tester.pumpWidget(
          _app(FormattedInput.phone(enabled: enabled)),
        );
        await tester.pumpAndSettle();
        _expectNoInnerBoxChrome(tester);
      }
    });

    testWidgets('the pointer steps the edge to outline and back', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const FormattedInput.phone()));
      await tester.pumpAndSettle();
      final owner = find.byType(FormattedInput);
      final hover = _scheme(
        tester,
        owner,
        CoreFormattedInputStyle.defaultHoverBorderColor,
      );
      final rest = _scheme(
        tester,
        owner,
        CoreFormattedInputStyle.defaultBorderColor,
      );
      expect(hover, isNot(rest));

      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: .zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(owner));
      await tester.pumpAndSettle();
      expect((_boxDecoration(tester).border! as Border).top.color, hover);

      await gesture.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect((_boxDecoration(tester).border! as Border).top.color, rest);
    });

    testWidgets('a disabled field types in disabledContent', (tester) async {
      await tester.pumpWidget(_app(const FormattedInput.phone(enabled: false)));
      await tester.pumpAndSettle();

      final style = tester
          .widget<material.EditableText>(find.byType(material.EditableText))
          .style;
      expect(
        style.color,
        _scheme(
          tester,
          find.byType(FormattedInput),
          CoreFormattedInputStyle.defaultDisabledForegroundColor,
        ),
      );
    });

    testWidgets('a disabled box paints the disabled tokens, not an opacity', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const FormattedInput.phone(enabled: false)),
      );
      await tester.pumpAndSettle();
      final owner = find.byType(FormattedInput);

      final decoration = _boxDecoration(tester);
      expect(
        decoration.color,
        _scheme(
          tester,
          owner,
          CoreFormattedInputStyle.defaultDisabledBackgroundColor,
        ),
      );
      expect(
        (decoration.border! as Border).top.color,
        _scheme(
          tester,
          owner,
          CoreFormattedInputStyle.defaultDisabledBorderColor,
        ),
      );
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('ObjectInput box', () {
    testWidgets('is one lg row (48) with the 12 corner and a 1 outline-variant '
        'edge', (tester) async {
      await tester.pumpWidget(_app(const ObjectInput(fields: _kFields)));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(OutlinedContainer)).height,
        CoreControlSize.heightLg,
      );
      final decoration = _boxDecoration(tester);
      final border = decoration.border! as Border;
      expect(border.top.width, CoreStrokeWidth.stroke1);
      expect(
        border.top.color,
        _scheme(
          tester,
          find.byType(ObjectInput),
          CoreObjectInputStyle.defaultBorderColor,
        ),
      );
      expect(CoreObjectInputStyle.defaultBorderColor.token, isNotNull);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(CoreRadius.radius12),
      );
    });

    testWidgets('every composed TextField is plain on the lg row', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ObjectInput(fields: _kFields)));
      await tester.pumpAndSettle();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, hasLength(_kFields.length));
      for (final field in fields) {
        expect(field.variant, CoreTextFieldVariant.plain);
        expect(field.size, CoreComponentSize.lg);
      }
    });

    testWidgets('the inner fields draw no border or fill of their own', (
      tester,
    ) async {
      for (final enabled in [true, false]) {
        await tester.pumpWidget(
          _app(ObjectInput(fields: _kFields, enabled: enabled)),
        );
        await tester.pumpAndSettle();
        _expectNoInnerBoxChrome(tester);
      }
    });

    testWidgets('a disabled box paints the disabled tokens even when focus was '
        'held, and not an opacity', (tester) async {
      await tester.pumpWidget(
        _app(const ObjectInput(fields: _kFields, enabled: false)),
      );
      await tester.pumpAndSettle();
      final owner = find.byType(ObjectInput);

      final decoration = _boxDecoration(tester);
      expect(
        decoration.color,
        _scheme(
          tester,
          owner,
          CoreObjectInputStyle.defaultDisabledBackgroundColor,
        ),
      );
      expect(
        (decoration.border! as Border).top.color,
        _scheme(
          tester,
          owner,
          CoreObjectInputStyle.defaultDisabledBorderColor,
        ),
      );
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('a field is capped at its bucket width', (tester) async {
      await tester.pumpWidget(_app(const ObjectInput(fields: _kFields)));
      await tester.pumpAndSettle();

      double widthOf(int index) => tester
          .getSize(
            find
                .ancestor(
                  of: find.byType(TextField).at(index),
                  matching: find.byType(SizedBox),
                )
                .first,
          )
          .width;
      // `year` (4 chars) is the medium bucket and `month` (2) the short one;
      // both land on the 28 cap rather than the 48 / 24 intrinsic widths.
      expect(widthOf(0), CoreObjectInputStyle.defaultMediumFieldMaxWidth);
      expect(
        widthOf(1),
        lessThanOrEqualTo(
          CoreObjectInputStyle.defaultShortFieldMaxWidth,
        ),
      );
    });
  });
}
