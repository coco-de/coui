import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// #5740: the docked bar's top hairline lies over its top padding, so the
/// bar is `padding + item` (80) tall with or without the line. The Web
/// keeps a real `border-top` (forced colours recolour it, the glass rule
/// clears it) and gives its width back from the top padding.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

ResolvedNavigationBar _resolve(
  ComponentTester tester,
  CoreNavigationBarMode mode, {
  CoreNavigationBarStyle? style,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveNavigationBar(
    context,
    mode: mode,
    labelPosition: CoreNavigationLabelPosition.bottom,
    variant: CoreNavigationBarVariant.defaultVariant,
    overflow: CoreNavigationOverflow.ellipsis,
    navigationBarStyle: style,
  );
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

void main() {
  group('the bar hairline lies over the top padding', () {
    testComponents('a docked bar gives the border width back', (tester) {
      final root = _inline(_resolve(tester, .bar).root);
      expect(root['border-top-width'], 'var(--coui-stroke-width-1)');
      expect(
        root['padding-top'],
        'calc(var(--coui-space-8) - var(--coui-stroke-width-1))',
      );
    });

    testComponents('a detached bar keeps its whole top padding', (tester) {
      final root = _inline(
        _resolve(
          tester,
          .bar,
          style: const CoreNavigationBarStyle(
            barMargin: CoreEdgeInsets.all(CoreSpace.space8),
          ),
        ).root,
      );
      expect(root['border-top-width'], isNull);
      expect(root['padding-top'], isNull);
    });

    testComponents('a rail lays its trailing line out as a border', (tester) {
      final root = _inline(_resolve(tester, .rail).root);
      expect(root['border-inline-end-width'], 'var(--coui-stroke-width-1)');
      expect(root['padding-top'], isNull);
    });
  });
}
