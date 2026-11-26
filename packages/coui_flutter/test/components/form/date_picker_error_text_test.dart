import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The error line under a DatePicker. It is 12 px (the helper-text role), and
/// a disabled picker paints it `disabledContent` — disabled outranks the error,
/// so a field nobody can edit does not keep a live red message. These read the
/// `TextStyle` the line is actually drawn with. The description line is the
/// same 12 px role as the error line.
material.Widget _app(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
  localizationsDelegates: const [CoUILocalizationsDelegate.delegate],
);

TextStyle _errorStyle(WidgetTester tester) =>
    _lineStyle(tester, 'Enter a valid date');

TextStyle _lineStyle(WidgetTester tester, String line) {
  final text = find.descendant(
    of: find.byType(DatePicker),
    matching: find.text(line),
  );
  final defaultStyle = tester
      .widget<material.DefaultTextStyle>(
        find
            .ancestor(
              of: text,
              matching: find.byType(material.DefaultTextStyle),
            )
            .first,
      )
      .style;

  return defaultStyle;
}

Future<ThemeData> _theme(WidgetTester tester) async {
  late ThemeData data;
  await tester.pumpWidget(
    _app(
      material.Builder(
        builder: (context) {
          data = Theme.of(context);

          return const material.SizedBox();
        },
      ),
    ),
  );

  return data;
}

void main() {
  for (final enabled in [true, false]) {
    testWidgets('error text enabled=$enabled', (tester) async {
      final theme = await _theme(tester);
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: enabled ? (_) {} : null,
            errorText: 'Enter a valid date',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final style = _errorStyle(tester);
      expect(style.fontSize, 12);
      final expected = theme.colorScheme
          .resolve(
            enabled
                ? CoreDatePickerStyle.defaultErrorColor
                : CoreDatePickerStyle.defaultDisabledErrorColor,
          )
          .toValue();
      expect(style.color, expected);
    });
  }

  testWidgets('description text is the same 12 px role as the error text', (
    tester,
  ) async {
    final theme = await _theme(tester);
    await tester.pumpWidget(
      _app(
        DatePicker(
          value: DateTime(2024, 1, 15),
          onChanged: (_) {},
          description: 'Pick a delivery date',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final style = _lineStyle(tester, 'Pick a delivery date');
    expect(style.fontSize, 12);
    expect(
      style.color,
      theme.colorScheme
          .resolve(CoreDatePickerStyle.defaultDescriptionColor)
          .toValue(),
    );
  });

  for (final enabled in [true, false]) {
    testWidgets('description colour enabled=$enabled', (tester) async {
      final theme = await _theme(tester);
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: enabled ? (_) {} : null,
            description: 'Any date after today.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final style = _lineStyle(tester, 'Any date after today.');
      // Stated as tokens, not the Core defaults, so a default that drifts
      // away from the designer's decision fails here.
      final expected = theme.colorScheme
          .resolve(
            CoreColor.token(
              enabled ? CoreColors.onSurfaceSubtle : CoreColors.disabledContent,
            ),
          )
          .toValue();
      expect(style.color, expected);
    });
  }

  testWidgets('a caller disabledDescriptionColor wins while disabled only', (
    tester,
  ) async {
    final theme = await _theme(tester);
    const custom = CoreColor.token(CoreColors.tertiary);
    const style = CoreDatePickerStyle(disabledDescriptionColor: custom);
    for (final enabled in [true, false]) {
      await tester.pumpWidget(
        _app(
          DatePicker(
            value: DateTime(2024, 1, 15),
            onChanged: enabled ? (_) {} : null,
            description: 'Any date after today.',
            datePickerStyle: style,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final color = _lineStyle(tester, 'Any date after today.').color;
      final want = theme.colorScheme
          .resolve(
            enabled ? CoreDatePickerStyle.defaultDescriptionColor : custom,
          )
          .toValue();
      expect(color, want, reason: 'enabled=$enabled');
    }
  });
}
