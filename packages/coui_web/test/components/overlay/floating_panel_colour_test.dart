// The floating panels stand on one raised face with one quiet line, and
// the modal scrim is the black `scrim` token. Each is a token, so it
// reaches the DOM as a class (or the `--coui-scrim` variable) rather than
// a baked colour — the browser resolves it per mode.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/infra/popup/popup_style.dart';
import 'package:coui_web/src/components/menu/navigation_menu/navigation_menu_style.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:coui_web/src/components/overlay/drawer/drawer_style.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.text('x');
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

void main() {
  group('floating panel colours on the DOM', () {
    testComponents('Popup panel reads surface-bright and outline-variant', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolvePopup(context, direction: .vertical);
      expect(resolved.root.className, contains('bg-surface-bright'));
      expect(resolved.root.className, contains('border-outline-variant'));
    });

    testComponents('Menu panel inherits the Popup colours (states none)', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolvePopup(
        context,
        direction: .vertical,
        popupStyle: CoreMenuStyle.defaultPopupStyle,
      );
      expect(resolved.root.className, contains('bg-surface-bright'));
      expect(resolved.root.className, contains('border-outline-variant'));
    });

    testComponents('NavigationMenu panel reads surface-bright and '
        'outline-variant', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveNavigationMenu(
        context,
        variant: CoreNavigationMenuVariant.standard,
        triggers: const [],
      );
      expect(resolved.panel.className, contains('bg-surface-bright'));
      expect(resolved.panel.className, contains('border-outline-variant'));
    });

    testComponents('Dialog panel reads surface-bright and outline-subtle', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveDialog(context);
      expect(resolved.panel.className, contains('bg-surface-bright'));
      expect(resolved.panel.className, contains('border-outline-subtle'));
    });

    testComponents('Dialog backdrop is the scrim token, not on-surface', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final background = resolveDialog(
        context,
      ).backdrop.inlineStyles?.properties['background-color'];
      expect(background, contains('--coui-scrim'));
      expect(background, isNot(contains('--coui-on-surface')));
    });

    testComponents('Drawer panel reads surface-bright and outline-variant', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveDrawer(
        context,
        side: CoreDrawerSide.right,
        open: true,
        dragDelta: 0,
      );
      expect(resolved.panel.className, contains('bg-surface-bright'));
      expect(resolved.panel.className, contains('border-outline-variant'));
    });
  });
}
