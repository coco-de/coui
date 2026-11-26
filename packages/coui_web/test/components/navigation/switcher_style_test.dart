import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveSwitcher` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedSwitcher _resolve(
  BuildContext context, {
  bool dragging = false,
  CoreSwitcherStyle? switcherStyle,
}) => resolveSwitcher(
  context,
  direction: .defaultDirection,
  position: 0,
  itemCount: 2,
  dragging: dragging,
  switcherStyle: switcherStyle,
);

String _trackTransition(ResolvedSwitcher resolved) =>
    resolved.track.inlineStyles?.properties['transition'] ?? '';

String _slotTransition(ResolvedSwitcher resolved) =>
    resolved.slots.first.inlineStyles?.properties['transition'] ?? '';

void main() {
  // Why read the emitted string: the track slide and the per-slot fade are
  // two separate declarations. An easing wired into one of them animates the
  // movement and the fade on different curves, which reads as a stutter
  // rather than as a wrong value.
  group('Switcher easing reaches the emitted transitions', () {
    testComponents('default is the design-system easing token', (tester) async {
      final context = _themedContext(tester);
      final resolved = _resolve(context);

      final timing = CoreSwitcherStyle.defaultCurve.toCss();
      expect(_trackTransition(resolved), contains(timing));
      expect(_slotTransition(resolved), contains(timing));
    });

    testComponents('the style slot overrides both declarations', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        switcherStyle: const CoreSwitcherStyle(curve: CoreEasing.easeOutBack),
      );

      final timing = CoreEasing.easeOutBack.toCss();
      expect(_trackTransition(resolved), contains(timing));
      expect(_slotTransition(resolved), contains(timing));
    });

    testComponents('dragging still drops the transition entirely', (
      tester,
    ) async {
      // A drag follows the pointer 1:1; keeping an easing here would lag the
      // track behind the finger.
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        dragging: true,
        switcherStyle: const CoreSwitcherStyle(curve: CoreEasing.easeOutBack),
      );

      expect(_trackTransition(resolved), equals('none'));
      expect(_slotTransition(resolved), equals('none'));
    });
  });

  group('Switcher easing precedence', () {
    testComponents('theme style fills in when the instance is silent', (
      tester,
    ) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              switcher: CoreSwitcherTheme(
                style: CoreSwitcherStyle(curve: CoreEasing.easeInQuad),
              ),
            ),
          ),
          child: _ContextCapture((c) => context = c),
        ),
      );

      expect(
        _trackTransition(_resolve(context)),
        contains(CoreEasing.easeInQuad.toCss()),
      );
    });

    testComponents('the instance style wins over the theme', (tester) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              switcher: CoreSwitcherTheme(
                style: CoreSwitcherStyle(curve: CoreEasing.easeInQuad),
              ),
            ),
          ),
          child: _ContextCapture((c) => context = c),
        ),
      );

      final resolved = _resolve(
        context,
        switcherStyle: const CoreSwitcherStyle(curve: CoreEasing.easeOutCirc),
      );
      expect(
        _trackTransition(resolved),
        contains(CoreEasing.easeOutCirc.toCss()),
      );
    });
  });
}
