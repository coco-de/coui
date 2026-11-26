// What the redesigned Web `Menubar` emits, read back from the markup it
// produces rather than from the style it was given.
//
// A token can be wired into the Core defaults and the resolver and still
// never reach a class, so every claim here is a Tailwind class or an inline
// declaration on a node that is rendered.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.empty();
  }
}

/// Runs [read] against a themed build context and returns what it read.
T _read<T>(ComponentTester tester, T Function(BuildContext context) read) {
  late T value;
  pumpWithTheme(tester, _ContextCapture((context) => value = read(context)));
  return value;
}

ResolvedMenubar _bar(BuildContext context, {CoreMenubarStyle? style}) =>
    resolveMenubar(
      context,
      variant: CoreMenubarVariant.standard,
      border: true,
      menubarStyle: style,
    );

/// The trigger `Button` as `menubar.dart` composes it from [style].
ResolvedButton _trigger(BuildContext context, CoreButtonStyle style) =>
    resolveButton(
      context,
      variant: CoreButtonVariant.menubar,
      size: CoreComponentSize.md,
      shape: CoreButtonShape.rectangle,
      expanded: false,
      buttonStyle: style,
    );

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

String? _inline(WebElementChrome chrome, String property) =>
    chrome.inlineStyles?.properties[property];

void main() {
  group('the bar', () {
    testComponents('is the raised face with a quiet hairline', (tester) async {
      final bar = _read(tester, _bar);
      final classes = _classes(bar.root);

      expect(classes, contains('bg-surface-bright'));
      expect(classes, contains('border-outline-subtle'));
      expect(classes, isNot(contains('bg-surface')));
      expect(classes, isNot(contains('border-outline')));
    });

    testComponents('has an 8 corner on every side', (tester) async {
      final bar = _read(tester, _bar);

      expect(
        _inline(bar.root, 'border-radius'),
        List.filled(4, 'var(--coui-radius-8)').join(' '),
      );
    });

    testComponents('keeps its padding and hairline width', (tester) async {
      final bar = _read(tester, _bar);

      expect(_inline(bar.root, 'border-width'), 'var(--coui-stroke-width-1)');
      expect(
        _inline(bar.root, 'padding'),
        contains('var(--coui-space-4)'),
      );
    });
  });

  group('the trigger labels', () {
    testComponents('read regular at rest and medium while open', (
      tester,
    ) async {
      final bar = _read(tester, _bar);
      final resting = _read(
        tester,
        (context) => _trigger(context, bar.triggerButtonStyle),
      );
      final open = _read(
        tester,
        (context) => _trigger(context, bar.openTriggerButtonStyle),
      );

      expect(_inline(resting.root, 'font-weight'), '400');
      expect(_inline(open.root, 'font-weight'), '500');
    });

    testComponents('a caller-stated label style reaches every trigger', (
      tester,
    ) async {
      final bar = _read(
        tester,
        (context) => _bar(
          context,
          style: const CoreMenubarStyle(
            labelTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
            openTriggerButtonStyle: CoreButtonStyle(
              labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
            ),
          ),
        ),
      );
      final resting = _read(
        tester,
        (context) => _trigger(context, bar.triggerButtonStyle),
      );
      final open = _read(
        tester,
        (context) => _trigger(context, bar.openTriggerButtonStyle),
      );

      expect(_inline(resting.root, 'font-weight'), '700');
      expect(_inline(open.root, 'font-weight'), '600');
    });
  });

  group('the open trigger', () {
    testComponents('fills one step under the hover fill when selected', (
      tester,
    ) async {
      final bar = _read(tester, _bar);
      final open = _read(
        tester,
        (context) => _trigger(context, bar.openTriggerButtonStyle),
      );
      final classes = _classes(open.root);

      expect(classes, contains('aria-selected:bg-surface-container-high'));
      expect(
        classes,
        isNot(contains('aria-selected:bg-surface-container-highest')),
      );
      expect(classes, contains('hover:bg-surface-container-highest'));
    });
  });

  group('what stays', () {
    testComponents('the triggers keep their padding and corner', (
      tester,
    ) async {
      final bar = _read(tester, _bar);

      expect(
        bar.triggerButtonStyle.borderRadius,
        CoreMenubarStyle.defaultItemBorderRadius,
      );
      expect(
        bar.triggerButtonStyle.padding,
        CoreMenubarStyle.defaultItemPadding,
      );
      expect(
        bar.openTriggerButtonStyle.padding,
        CoreMenubarStyle.defaultItemPadding,
      );
    });
  });
}
