import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The error line under a DatePicker: the helper-text role (12 px) and, once
/// the picker is disabled, `disabledContent` instead of `error` — disabled
/// outranks the error. The Flutter twin has the same file; both read what the
/// resolver hands the widget.
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

String _colorClass(CoreColor c) => 'text-${c.tailwindColor}';

void main() {
  group('DatePicker error text', () {
    testComponents('enabled: error colour, bodyXs role', (tester) async {
      final resolved = resolveDatePicker(_themedContext(tester));
      final classes = resolved.error.className;

      expect(
        classes,
        contains(_colorClass(CoreDatePickerStyle.defaultErrorColor)),
      );
      expect(classes, contains(CoreTextStyles.bodyXs.name));
      expect(classes, isNot(contains(CoreTextStyles.bodySmall.name)));
    });

    testComponents('description: bodyXs role, same size as the error', (
      tester,
    ) async {
      final classes = resolveDatePicker(
        _themedContext(tester),
      ).description.className;

      expect(classes, contains(CoreTextStyles.bodyXs.name));
      expect(classes, isNot(contains(CoreTextStyles.bodySmall.name)));
    });

    testComponents('disabled: disabledContent instead of error', (
      tester,
    ) async {
      final resolved = resolveDatePicker(
        _themedContext(tester),
        enabled: false,
      );
      final classes = resolved.error.className;

      expect(
        classes,
        contains(_colorClass(CoreDatePickerStyle.defaultDisabledErrorColor)),
      );
      expect(
        classes,
        isNot(contains(_colorClass(CoreDatePickerStyle.defaultErrorColor))),
      );
      expect(classes, contains(CoreTextStyles.bodyXs.name));
    });

    testComponents('a caller disabledErrorColor wins while disabled only', (
      tester,
    ) async {
      const custom = CoreColor.token(CoreColors.tertiary);
      const style = CoreDatePickerStyle(disabledErrorColor: custom);
      final context = _themedContext(tester);

      final disabled = resolveDatePicker(
        context,
        datePickerStyle: style,
        enabled: false,
      ).error;
      final enabled = resolveDatePicker(
        context,
        datePickerStyle: style,
      ).error;

      // A caller override rides inline and replaces the colour class.
      expect(disabled.inlineStyles?.properties['color'], custom.toValue());
      expect(disabled.className, isNot(contains('text-error')));
      expect(enabled.inlineStyles?.properties['color'], isNull);
      expect(enabled.className, contains('text-error'));
    });

    for (final enabled in [true, false]) {
      testComponents('description colour enabled=$enabled', (tester) async {
        final classes = resolveDatePicker(
          _themedContext(tester),
          enabled: enabled,
        ).description.className;
        // Stated as tokens, not the Core defaults, so a default that drifts
        // away from the designer's decision fails here.
        final want = CoreColor.token(
          enabled ? CoreColors.onSurfaceSubtle : CoreColors.disabledContent,
        );
        final other = CoreColor.token(
          enabled ? CoreColors.disabledContent : CoreColors.onSurfaceSubtle,
        );
        expect(classes, contains(_colorClass(want)));
        expect(classes, isNot(contains(_colorClass(other))));
        expect(
          classes,
          isNot(
            contains(
              _colorClass(
                const CoreColor.token(CoreColors.onSurfaceVariant),
              ),
            ),
          ),
        );
      });
    }

    testComponents(
      'a caller disabledDescriptionColor wins while disabled only',
      (tester) async {
        const custom = CoreColor.token(CoreColors.tertiary);
        const style = CoreDatePickerStyle(disabledDescriptionColor: custom);
        final context = _themedContext(tester);

        final disabled = resolveDatePicker(
          context,
          datePickerStyle: style,
          enabled: false,
        ).description;
        final enabled = resolveDatePicker(
          context,
          datePickerStyle: style,
        ).description;

        expect(disabled.inlineStyles?.properties['color'], custom.toValue());
        expect(
          disabled.className,
          isNot(
            contains(
              _colorClass(CoreDatePickerStyle.defaultDisabledDescriptionColor),
            ),
          ),
        );
        expect(enabled.inlineStyles?.properties['color'], isNull);
        expect(
          enabled.className,
          contains(
            _colorClass(CoreDatePickerStyle.defaultDescriptionColor),
          ),
        );
      },
    );
  });
}
