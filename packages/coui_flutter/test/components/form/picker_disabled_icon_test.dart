// A disabled date / time picker leaves its trigger glyph untinted, so the
// composed field's (time) or `Button`'s (date) own disabled foreground applies
// to the glyph the way it does to the value text — one disabled tone for the
// whole control. An explicit glyph colour would win over it and leave only the
// icon looking alive. Mirrors the Web twin.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _themedContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            captured = context;

            return const SizedBox();
          },
        ),
      ),
      localizationsDelegates: const [CoUILocalizationsDelegate.delegate],
    ),
  );

  return captured;
}

void main() {
  group('TimePicker trailing icon', () {
    testWidgets('is tinted while enabled', (tester) async {
      final icon = resolveTimePicker(
        await _themedContext(tester),
      ).trailingIconStyle;

      expect(icon.color, isNotNull);
    });

    testWidgets('is the icon tone, not the value colour', (tester) async {
      final context = await _themedContext(tester);
      const iconTone = CoreColor.token(CoreColors.onSurfaceVariant);

      expect(resolveTimePicker(context).trailingIconStyle.color, iconTone);
      expect(
        resolveTimePicker(
          context,
          timePickerStyle: const CoreTimePickerStyle(
            contentColor: CoreColor.token(CoreColors.primary),
          ),
        ).trailingIconStyle.color,
        iconTone,
      );
    });

    testWidgets('is untinted while disabled and keeps its size', (
      tester,
    ) async {
      final context = await _themedContext(tester);
      final enabled = resolveTimePicker(context).trailingIconStyle;
      final disabled = resolveTimePicker(
        context,
        enabled: false,
      ).trailingIconStyle;

      expect(disabled.color, isNull);
      expect(disabled.size, enabled.size);
    });
  });

  group('DatePicker trailing icon', () {
    testWidgets('is tinted while enabled', (tester) async {
      final icon = resolveDatePicker(
        await _themedContext(tester),
      ).trailingIconStyle;

      expect(
        icon.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    testWidgets('is untinted while disabled and keeps its size', (
      tester,
    ) async {
      final context = await _themedContext(tester);
      final enabled = resolveDatePicker(context).trailingIconStyle;
      final disabled = resolveDatePicker(
        context,
        enabled: false,
      ).trailingIconStyle;

      expect(disabled.color, isNull);
      expect(disabled.size, enabled.size);
    });
  });
}
