import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoUIApp text baseline', () {
    testWidgets(
      'bare Text inside home inherits the CoUI bodyMedium baseline — '
      'the home-wrapping Material must not reset DefaultTextStyle to '
      'the Material textTheme (14px Roboto)',
      (tester) async {
        TextStyle? effective;
        final theme = ThemeData.fromCore(
          CoreThemePresets.previewLight.copyWith(
            textScaling: 1.0,
            sizeScaling: 1.0,
            radiusScaling: 1.0,
          ),
        );

        await tester.pumpWidget(
          CoUIApp(
            home: Scaffold(
              headers: const [],
              child: material.Builder(
                builder: (context) {
                  effective = material.DefaultTextStyle.of(context).style;
                  return const Text('probe');
                },
              ),
            ),
            theme: theme,
          ),
        );
        await tester.pump();

        final expected = theme.typography.bodyMedium.toValue(theme: theme);
        expect(effective?.fontSize, equals(expected.fontSize));
        expect(effective?.fontFamily, equals(expected.fontFamily));
        expect(
          effective?.color,
          equals(theme.colorScheme.onSurface.toValue()),
        );
      },
    );
  });
}
