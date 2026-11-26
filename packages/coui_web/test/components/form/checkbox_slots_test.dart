import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/checkbox/checkbox.dart';
// checkbox_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/form/checkbox/checkbox_style.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Web twin of `checkbox_slots_test.dart` (Flutter) — the same two slots,
/// checked where this platform actually decides them.
///
/// The Flutter file reads the widget tree; here the equivalent facts live
/// in the resolver's output, because the alignment and the column shape
/// are className decisions rather than widget ones. Both files pin the
/// same claim: `description` and `trailing` render *alongside* the label
/// rather than instead of it, and the row re-aligns only once the content
/// is two lines tall.
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

ResolvedCheckbox _resolve(
  ComponentTester tester, {
  required bool hasDescription,
  CoreComponentSize size = CoreComponentSize.md,
  bool enabled = true,
}) => resolveCheckbox(
  _themedContext(tester),
  size: size,
  checked: false,
  enabled: enabled,
  hasDescription: hasDescription,
);

void main() {
  group('the row re-aligns only when the content is two lines', () {
    testComponents('without a description the row stays centred', (
      tester,
    ) async {
      final resolved = _resolve(tester, hasDescription: false);

      expect(
        resolved.root.className,
        contains('items-center'),
        reason:
            'this is the alignment every checkbox emitted before the '
            'description slot existed — adding a slot must not move rows '
            'that never use it',
      );
      expect(resolved.root.className, isNot(contains('items-start')));
    });

    testComponents('with a description the row top-aligns', (tester) async {
      final resolved = _resolve(tester, hasDescription: true);

      expect(
        resolved.root.className,
        contains('items-start'),
        reason:
            'centred against a two-line block the box sits against '
            'neither line; the canvas states MIN for this pose',
      );
      expect(resolved.root.className, isNot(contains('items-center')));
    });
  });

  group('the content wrapper becomes a column for two lines', () {
    testComponents('without a description it is not a column', (tester) async {
      final resolved = _resolve(tester, hasDescription: false);

      expect(resolved.labelWrapper.className, isNot(contains('flex-col')));
    });

    testComponents('with a description it stacks', (tester) async {
      final resolved = _resolve(tester, hasDescription: true);

      expect(
        resolved.labelWrapper.className,
        contains('flex-col'),
        reason:
            'the label and the description share a row instead of '
            'stacking — the canvas `content` frame is vertical',
      );
    });
  });

  group('the description is drawn quieter than the label', () {
    testComponents('their emitted typography differs', (tester) async {
      final resolved = _resolve(tester, hasDescription: true);

      expect(
        resolved.description.className,
        isNotEmpty,
        reason: 'the description line carries no typography of its own',
      );
      expect(
        resolved.description.className,
        isNot(resolved.root.className),
        reason:
            'the description resolves to the same emit as the label the '
            'root wrapper carries, so the hierarchy is not drawn',
      );
    });

    testComponents('disabling folds the two lines onto one foreground', (
      tester,
    ) async {
      // Enabled the two differ (`onSurface` / `onSurfaceVariant`);
      // disabled BOTH move onto the one `disabledForegroundColor`
      // (`disabledContent`) — the row dims as one block, and neither line
      // keeps its enabled ink.
      final enabled = _resolve(tester, hasDescription: true);
      final disabled = _resolve(tester, hasDescription: true, enabled: false);

      expect(
        disabled.root.className,
        isNot(enabled.root.className),
        reason: 'the label did not dim when the checkbox was disabled',
      );
      expect(
        disabled.description.className,
        isNot(enabled.description.className),
        reason: 'the description did not dim when the checkbox was disabled',
      );
      final disabledInk =
          'text-${CoreCheckboxStyle.defaultDisabledForegroundColor.tailwindColor}';
      expect(disabled.root.className, contains(disabledInk));
      expect(
        disabled.description.className,
        contains(disabledInk),
        reason: 'the two lines fold onto one disabled token',
      );
    });
  });

  group('the size ladder reaches the emitted label', () {
    testComponents('xs and xl2 do not emit the same label typography', (
      tester,
    ) async {
      // The defect this ladder was added for: the box scaled and the
      // label did not, so both ends of the ladder emitted one class.
      final xs = _resolve(
        tester,
        hasDescription: false,
        size: CoreComponentSize.xs,
      );
      final xl2 = _resolve(
        tester,
        hasDescription: false,
        size: CoreComponentSize.xl2,
      );

      expect(
        xs.root.inlineStyles?.properties['font-size'] ?? xs.root.className,
        isNot(
          xl2.root.inlineStyles?.properties['font-size'] ?? xl2.root.className,
        ),
        reason:
            'the smallest and largest checkbox draw their labels at the '
            'same size — the size axis stops at the box',
      );
    });
  });

  group('the size ladder reaches the emitted description', () {
    testComponents('each size draws 11 / 12 / 13 / 14 / 14 / 14', (
      tester,
    ) async {
      // The description steps one under the label from `xs` to `lg` and then
      // holds at 14 (the label holds at 16). The size is the rung's
      // `fontSize` overlay on the body role, so it rides inline.
      const expected = <CoreComponentSize, double>{
        CoreComponentSize.xs: CoreFontSize.s11,
        CoreComponentSize.sm: CoreFontSize.s12,
        CoreComponentSize.md: CoreFontSize.s13,
        CoreComponentSize.lg: CoreFontSize.s14,
        CoreComponentSize.xl: CoreFontSize.s14,
        CoreComponentSize.xl2: CoreFontSize.s14,
      };
      for (final entry in expected.entries) {
        final resolved = _resolve(
          tester,
          hasDescription: true,
          size: entry.key,
        );
        expect(
          resolved.description.inlineStyles?.properties['font-size'],
          '${entry.value / kRemDivisor}rem',
          reason: '${entry.key.name} description drifted off the ladder',
        );
      }
    });
  });

  group('the widget exposes both slots', () {
    test('description and trailing survive copyWith', () {
      const original = Checkbox(
        label: 'Terms of service',
        description: 'Required',
        trailing: span([Component.text('>')]),
      );
      final copy = original.copyWith(checked: true, checkedProvided: true);

      expect(copy.description, 'Required');
      expect(copy.trailing, isNotNull);
      expect(copy.checked, isTrue);
    });

    test('the contract carries them', () {
      const checkbox = Checkbox(
        label: 'Terms of service',
        description: 'Required',
        trailing: span([Component.text('>')]),
      );

      expect(
        checkbox,
        isA<CoreCheckboxContract<Component, void, void, void>>(),
      );
      expect(checkbox.description, 'Required');
      expect(checkbox.trailing, isNotNull);
    });
  });
}
