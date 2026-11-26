import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

ResolvedNavigationBar? _seen;

class _Capture extends StatelessComponent {
  const _Capture();

  @override
  Component build(BuildContext context) {
    _seen = resolveNavigationBar(
      context,
      mode: CoreNavigationBarMode.bar,
      variant: CoreNavigationBarVariant.defaultVariant,
      overflow: CoreNavigationOverflow.ellipsis,
      labelPosition: CoreNavigationLabelPosition.bottom,
    );

    return const Component.text('x');
  }
}

void main() {
  group('selection is legible without colour', () {
    testComponents('the selected label carries a different weight', (
      tester,
    ) async {
      // Selection was signalled twice and both signals were colour — the
      // pill behind the item and the label's own colour. A mode that forces
      // the palette lands both on the same value at once, and the selected
      // item stops looking selected. Weight is not forced.
      pumpWithTheme(tester, const _Capture());
      await tester.pump();

      final selected = _seen!.labelSelected;
      final unselected = _seen!.label;

      expect(
        selected.inlineStyles?.properties['font-weight'] ??
            (selected.className == unselected.className ? null : 'class'),
        isNotNull,
        reason: 'the selected label must differ by something other than hue',
      );
      expect(
        selected.inlineStyles?.properties['font-weight'],
        isNot(unselected.inlineStyles?.properties['font-weight']),
      );
    });

    testComponents('the difference is on the label, not inherited', (
      tester,
    ) async {
      // The role class sets a weight on this very element, so a weight
      // inherited from the item would lose to it. Asserting the property
      // lands here is what keeps a future refactor from moving it up and
      // quietly having no effect.
      pumpWithTheme(tester, const _Capture());
      await tester.pump();

      expect(
        _seen!.labelSelected.inlineStyles?.properties,
        contains('font-weight'),
      );
    });
  });
}
