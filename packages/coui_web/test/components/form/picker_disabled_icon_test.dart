// A disabled date / time picker leaves its trigger glyph untinted, so the
// composed field's (time) or `Button`'s (date) own disabled foreground applies
// to the glyph the way it does to the value text — one disabled tone for the
// whole control. An explicit glyph colour would win over it and leave only the
// icon looking alive. Mirrors the Flutter twin.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));

  return context;
}

void main() {
  group('TimePicker trailing icon', () {
    testComponents('is tinted while enabled', (tester) async {
      final icon = resolveTimePicker(_themedContext(tester)).trailingIconStyle;

      expect(icon.color, isNotNull);
    });

    testComponents('is the icon tone, not the value colour', (tester) async {
      final context = _themedContext(tester);
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

    testComponents('is untinted while disabled and keeps its size', (
      tester,
    ) async {
      final context = _themedContext(tester);
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
    testComponents('is tinted while enabled', (tester) async {
      final icon = resolveDatePicker(_themedContext(tester)).trailingIconStyle;

      expect(
        icon.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    testComponents('is untinted while disabled and keeps its size', (
      tester,
    ) async {
      final context = _themedContext(tester);
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
