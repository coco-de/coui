import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveNavigationBar` directly.
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

/// The section caption's typography role, read back where it lands.
///
/// Web emits the role as a class rather than a resolved size, so the twin of
/// the Flutter assertion is the class the header carries. The two platforms
/// read the same `CoreNavigationBarStyle.sectionLabelRole` (`labelSmall`,
/// 10px); asserting only one of them would leave the other free to drift.
void main() {
  group('NavigationBar section label role', () {
    for (final mode in CoreNavigationBarMode.values) {
      testComponents('${mode.name} emits the labelSmall role class', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final resolved = resolveNavigationBar(
          context,
          mode: mode,
          variant: CoreNavigationBarVariant.defaultVariant,
          overflow: CoreNavigationOverflow.none,
          labelPosition: CoreNavigationLabelPosition.bottom,
        );

        expect(resolved.sectionLabel.className, contains('label-small'));
        // The two roles differ by one step in the same family, so a substring
        // check for the family alone would pass either way.
        expect(
          resolved.sectionLabel.className,
          isNot(contains('label-large')),
        );
      });
    }
  });

  // The destination surface is the child of the `Clickable`, which is the
  // `<nav>`'s actual flex item. Unless the surface fills that cell it hugs its
  // content and lands on the cell's start edge: in the bar the icon and label
  // sat left of centre, and the hover / selected fill covered the content
  // rather than the whole cell the Flutter twin paints.
  group('NavigationBar destination surface fills its cell', () {
    for (final mode in CoreNavigationBarMode.values) {
      testComponents('${mode.name} gives every state w-full', (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveNavigationBar(
          context,
          mode: mode,
          variant: CoreNavigationBarVariant.defaultVariant,
          overflow: CoreNavigationOverflow.none,
          labelPosition: CoreNavigationLabelPosition.bottom,
        );

        final states = {
          'selected': resolved.destinationSelected,
          'idle': resolved.destinationEnabledIdle,
          'hovered': resolved.destinationEnabledHovered,
          'disabled': resolved.destinationDisabled,
        };
        for (final MapEntry(:key, :value) in states.entries) {
          // Whole-token match: `w-full` is a substring of `min-w-full`.
          expect(
            value.className.split(' '),
            contains(WebLayout.wFull),
            reason: '${mode.name} / $key',
          );
        }
      });
    }
  });
}
