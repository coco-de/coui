// FormattedInput and ObjectInput share the text field's lg-row box (#5831):
// the outer container owns the single border / fill / focus boundary and sits
// on the control ladder's lg row. These read the classes and inline CSS the
// resolvers hand the widgets, not the Core declarations alone.
import 'package:coui_web/coui_web.dart';
// The resolvers are internal chrome and the barrel does not re-export them.
import 'package:coui_web/src/components/form/object_input/object_input_style.dart';
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

Set<String> _classes(String className) =>
    className.split(' ').where((c) => c.isNotEmpty).toSet();

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

void main() {
  group('FormattedInput container', () {
    testComponents('is the lg row with the 12 corner, 14 inset and 8 gap', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final root = resolveFormattedInput(
        context,
        enabled: true,
        focused: false,
      ).root;
      final inline = _inline(root);

      expect(inline['height'], 'var(--coui-control-height-48)');
      expect(inline['gap'], 'var(--coui-space-8)');
      expect(
        inline['border-radius'],
        List.filled(4, 'var(--coui-radius-12)').join(' '),
      );
      expect(inline['padding'], contains('var(--coui-space-14)'));
      expect(CoreFormattedInputStyle.defaultHeight, CoreControlSize.heightLg);
    });

    testComponents('a stated height stays as stated', (tester) async {
      final context = _themedContext(tester);
      final root = resolveFormattedInput(
        context,
        enabled: true,
        focused: false,
        formattedInputStyle: const CoreFormattedInputStyle(height: 40),
      ).root;

      expect(_inline(root)['height'], '2.5rem');
    });

    testComponents('rests on outline-variant and steps to outline on hover', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final classes = _classes(
        resolveFormattedInput(
          context,
          enabled: true,
          focused: false,
        ).root.className,
      );

      expect(classes, contains('border-outline-variant'));
      expect(classes, contains('hover:border-outline'));
    });

    testComponents('focus and disabled carry no hover step', (tester) async {
      final context = _themedContext(tester);

      final focused = _classes(
        resolveFormattedInput(
          context,
          enabled: true,
          focused: true,
        ).root.className,
      );
      final disabled = _classes(
        resolveFormattedInput(
          context,
          enabled: false,
          focused: false,
        ).root.className,
      );

      expect(focused.where((c) => c.startsWith('hover:')), isEmpty);
      expect(disabled.where((c) => c.startsWith('hover:')), isEmpty);
      expect(focused, contains('border-primary'));
    });

    testComponents('the field types in disabledContent while disabled', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final enabled = _classes(
        resolveFormattedInput(
          context,
          enabled: true,
          focused: false,
        ).field.className,
      );
      final disabled = _classes(
        resolveFormattedInput(
          context,
          enabled: false,
          focused: false,
        ).field.className,
      );

      expect(enabled, contains('placeholder:text-placeholder'));
      expect(disabled, contains('text-disabled-content'));
      expect(disabled, contains('placeholder:text-disabled-content'));
    });

    testComponents('the placeholder takes the body face, the value the code '
        'role', (tester) async {
      final context = _themedContext(tester);
      final field = _classes(
        resolveFormattedInput(
          context,
          enabled: true,
          focused: false,
        ).field.className,
      );

      expect(field, contains('placeholder:text-body-small'));
      expect(field, contains('placeholder:font-sans'));
      expect(field, contains('text-code-md'));
    });

    testComponents('the field is borderless and fill-less', (tester) async {
      final context = _themedContext(tester);
      final field = resolveFormattedInput(
        context,
        enabled: true,
        focused: false,
      ).field;
      final inline = _inline(field);

      expect(inline['border-width'], 'var(--coui-stroke-width-0)');
      expect(inline['background-color'], isNot(contains('--coui-surface')));
      expect(
        _classes(field.className).where((c) => c.startsWith('bg-')),
        isEmpty,
      );
    });
  });

  group('ObjectInput container', () {
    testComponents('is the lg row with the 12 corner, 14 inset and 4 gap', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final root = resolveObjectInput(
        context,
        enabled: true,
        focused: false,
      ).root;
      final inline = _inline(root);

      expect(inline['height'], 'var(--coui-control-height-48)');
      expect(inline['gap'], 'var(--coui-space-4)');
      expect(
        inline['border-radius'],
        List.filled(4, 'var(--coui-radius-12)').join(' '),
      );
      expect(inline['padding'], contains('var(--coui-space-14)'));
    });

    testComponents('a disabled container takes the disabled pair, not an '
        'opacity, even when it held focus', (tester) async {
      final context = _themedContext(tester);
      final disabled = _classes(
        resolveObjectInput(
          context,
          enabled: false,
          focused: true,
        ).root.className,
      );

      expect(disabled, contains('bg-disabled-container'));
      expect(disabled, contains('border-disabled-outline'));
      expect(disabled, isNot(contains('opacity-50')));
      expect(disabled, isNot(contains('border-primary')));
      expect(disabled.where((c) => c.startsWith('hover:')), isEmpty);
      expect(disabled, contains('cursor-not-allowed'));
    });

    testComponents('the separator is on-surface-subtle, disabledContent when '
        'disabled', (tester) async {
      final context = _themedContext(tester);
      final enabled = _classes(
        resolveObjectInput(
          context,
          enabled: true,
          focused: false,
        ).separator.className,
      );
      final disabled = _classes(
        resolveObjectInput(
          context,
          enabled: false,
          focused: false,
        ).separator.className,
      );

      expect(enabled, contains('text-on-surface-subtle'));
      expect(disabled, contains('text-disabled-content'));
      expect(
        _inline(
          resolveObjectInput(context, enabled: true, focused: false).separator,
        )['padding'],
        contains('var(--coui-space-2)'),
      );
    });

    testComponents('the composed fields are plain on the lg row', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveObjectInput(
        context,
        enabled: true,
        focused: false,
      );

      expect(resolved.fieldInputVariant, CoreTextFieldVariant.plain);
      expect(resolved.fieldInputSize, CoreComponentSize.lg);
      expect(resolved.fieldInputStyle.backgroundColor, CoreColor.transparent);
      expect(resolved.fieldInputStyle.borderWidth, 0);
    });

    testComponents('the field width buckets are 28 / 28 / 48', (tester) async {
      final context = _themedContext(tester);
      final buckets = resolveObjectInputFieldBuckets(context);

      expect(buckets.shortFieldMaxWidth, CoreSpace.space28);
      expect(buckets.mediumFieldMaxWidth, CoreSpace.space28);
      expect(buckets.longFieldMaxWidth, CoreSpace.space48);
    });
  });
}
