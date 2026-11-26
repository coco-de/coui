import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.fragment([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

void main() {
  group('MockupBrowser resolver — window body and content card', () {
    testComponents('the frame uses the low surface and the designer shadow', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(context);

      expect(
        resolved.frameStyle.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      expect(
        resolved.frameStyle.borderColor,
        CoreColor.transparent,
      );
      expect(
        resolved.frameStyle.boxShadow,
        CoreMockupBrowserStyle.defaultBoxShadow,
      );
      expect(resolved.content.className, contains('bg-surface'));
      expect(
        resolved.content.inlineStyles?.properties['background-color'],
        isNull,
      );
    });

    testComponents('the card radius is derived — body radius minus the '
        'window thickness', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(context);

      expect(
        resolved.content.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(14).toValue(),
      );
      expect(
        resolved.contentInset.inlineStyles?.properties['padding'],
        '2.75rem 0.0rem 0.0rem 0.0rem',
      );
    });

    testComponents('border width does not change toolbar or content geometry', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(
        context,
        mockupBrowserStyle: const CoreMockupBrowserStyle(borderWidth: 2),
      );

      expect(
        resolved.contentInset.inlineStyles?.properties['padding'],
        '2.75rem 0.0rem 0.0rem 0.0rem',
      );
      expect(resolved.toolbar.inlineStyles?.properties['height'], '2.75rem');
      expect(
        resolved.windowBorder.inlineStyles?.properties['border-width'],
        'var(--coui-stroke-width-2)',
      );
      expect(
        resolved.toolbar.inlineStyles?.properties['border-bottom-width'],
        'var(--coui-stroke-width-1)',
      );
      expect(
        resolved.toolbar.inlineStyles?.properties['padding'],
        const CoreEdgeInsets.fromLTRB(12, 0, 12, 0).toValue(),
      );
      expect(
        resolved.toolbar.inlineStyles?.properties['padding'],
        const CoreEdgeInsets.symmetric(horizontal: 12).toValue(),
      );
      expect(
        resolved.content.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(14).toValue(),
      );
    });

    testComponents('a thicker chrome tightens the derived radius', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(
        context,
        mockupBrowserStyle: const CoreMockupBrowserStyle(chromeWidth: 4),
      );

      expect(
        resolved.content.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(10).toValue(),
      );
    });

    testComponents('an explicit contentBorderRadius wins over the '
        'derivation', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(
        context,
        mockupBrowserStyle: const CoreMockupBrowserStyle(
          contentBorderRadius: CoreBorderRadius.all(2),
        ),
      );

      expect(
        resolved.content.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(2).toValue(),
      );
    });

    testComponents('the frame reserves no space for the overlay border', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(context);

      final frame = resolveOutlinedContainer(
        context: context,
        containerStyle: resolved.frameStyle,
      );
      expect(
        frame.root.inlineStyles?.properties['border-width'],
        'var(--coui-stroke-width-0)',
      );
    });
  });

  group('MockupBrowser resolver — toolbar', () {
    testComponents('the control dots are 8px, fully round, and painted with '
        'semantic status colours', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(context);

      for (final dot in [
        resolved.controlClose,
        resolved.controlMinimize,
        resolved.controlMaximize,
      ]) {
        expect(dot.inlineStyles?.properties['width'], '0.5rem');
        expect(dot.inlineStyles?.properties['height'], '0.5rem');
        expect(dot.className, contains('bg-'));
        expect(dot.inlineStyles?.properties['background-color'], isNull);
      }
      expect(
        resolved.controlClose.className,
        contains('bg-error'),
      );
      expect(
        resolved.controls.inlineStyles?.properties['gap'],
        'var(--coui-space-6)',
      );
    });

    testComponents('the address pill fills the bar and only centres '
        'vertically; its label spans the pill and carries the alignment', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(context);
      final pillClasses = resolved.addressBar.className.split(' ');

      expect(pillClasses, containsAll(['flex', 'items-center', 'flex-1']));
      expect(pillClasses, isNot(contains('justify-center')));
      expect(
        resolved.addressBar.inlineStyles?.properties,
        isNot(contains('text-align')),
      );
      expect(
        resolved.addressBar.className,
        contains('bg-surface-container/70'),
      );

      expect(resolved.addressBarLabel.className, 'min-w-0 truncate');
      expect(resolved.addressBarLabel.inlineStyles?.properties, {
        'text-align': 'center',
      });
      expect(
        resolved.toolbar.inlineStyles?.properties['gap'],
        'var(--coui-space-8)',
      );
      expect(resolved.toolbar.inlineStyles?.properties['height'], '2.75rem');
    });

    testComponents('an addressBarTextAlign override reaches the label', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final (align, css) in const [
        (CoreTextAlign.start, 'start'),
        (CoreTextAlign.end, 'end'),
      ]) {
        final resolved = resolveMockupBrowser(
          context,
          mockupBrowserStyle: CoreMockupBrowserStyle(
            addressBarTextAlign: align,
          ),
        );
        expect(
          resolved.addressBarLabel.inlineStyles?.properties['text-align'],
          css,
        );
      }
    });

    testComponents('icon chrome is raw-forwarded with the defaults merged', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveMockupBrowser(
        context,
        mockupBrowserStyle: const CoreMockupBrowserStyle(
          navIconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.error)),
        ),
      );

      expect(resolved.navIconStyle.size, CoreIconSize.size12);
      expect(
        resolved.navIconStyle.color,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        resolved.navDisabledIconStyle,
        CoreMockupBrowserStyle.defaultNavDisabledIconStyle,
      );
      expect(
        resolved.actionIconStyle,
        CoreMockupBrowserStyle.defaultActionIconStyle,
      );
    });
  });

  group('MockupBrowser DOM — what the composition leaves out', () {
    testComponents('the web page composition renders the address bar, the '
        'chevrons and the action', (tester) async {
      pumpWithTheme(
        tester,
        const MockupBrowser(
          addressBar: 'https://coui.dev',
          child: Text('page'),
        ),
      );

      expect(find.text('https://coui.dev'), findsOneComponent);
      expect(find.byType(Icon), findsNComponents(6));
      expect(find.text('page'), findsOneComponent);
    });

    testComponents('addressBar: null is the app window — no address bar, '
        'no chevrons, no action in the DOM', (tester) async {
      pumpWithTheme(
        tester,
        const MockupBrowser(addressBar: null, child: Text('app')),
      );

      expect(find.text('example.com'), findsNothing);
      expect(find.byType(Icon), findsNothing);
      expect(find.text('app'), findsOneComponent);
    });

    testComponents('the default address bar is example.com', (tester) async {
      pumpWithTheme(tester, const MockupBrowser());

      expect(find.text('example.com'), findsOneComponent);
    });
  });

  group('MockupBrowser.copyWith', () {
    test('a getter clears the address bar into the app-window composition', () {
      const page = MockupBrowser(addressBar: 'coui.dev');

      expect(page.copyWith(addressBar: () => null).addressBar, isNull);
      expect(page.copyWith(addressBar: () => 'b.io').addressBar, 'b.io');
      expect(page.copyWith().addressBar, 'coui.dev');
    });
  });
}
