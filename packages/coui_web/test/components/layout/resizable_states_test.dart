// Pins the divider's runtime states on the Web twin — resting, hover,
// dragging, focus — against the values the redesign states: a 1px
// `outlineVariant` line, 1px `outline` on hover, a 2px `primary` line while
// dragged, and the shared focus ring (keyboard focus only) over the resting
// line. The grab area is its own 8px and does not follow the line.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/resizable/resizable_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _Probe extends StatelessComponent {
  const _Probe({required this.onResolved, this.style});

  final void Function(ResolvedResizable) onResolved;
  final CoreResizableStyle? style;

  @override
  Component build(BuildContext context) {
    onResolved(
      resolveResizable(
        context,
        direction: .horizontal,
        paneFlexes: const [1, 1],
        showDragHandle: false,
        optionalDivider: false,
        resizableStyle: style,
      ),
    );
    return const Component.text('');
  }
}

void main() {
  group('Resizable divider states', () {
    testComponents('the resting line is 1px, the dragging line 2px', (
      tester,
    ) async {
      late ResolvedResizable resolved;
      pumpWithTheme(tester, _Probe(onResolved: (r) => resolved = r));

      final resting = resolved.dividerLine.inlineStyles!.properties;
      final dragging = resolved.dividerLineDragging.inlineStyles!.properties;
      expect(resting['width'], strokeWidthCss(CoreStrokeWidth.stroke1));
      expect(dragging['width'], strokeWidthCss(CoreStrokeWidth.stroke2));
    });

    testComponents('the grab area does not follow the line', (tester) async {
      late ResolvedResizable resolved;
      pumpWithTheme(tester, _Probe(onResolved: (r) => resolved = r));

      final wrapper = resolved.dividerWrappers.first.inlineStyles!.properties;
      expect(
        wrapper['width'],
        '${CoreResizableStyle.defaultDividerHitExtent / kRemDivisor}rem',
      );
    });

    testComponents('keyboard focus does not recolour the line', (
      tester,
    ) async {
      // Focus is the ring's job: the class list carries the hover pair only,
      // no `group-focus-visible` colour swap (that is `optionalDivider`'s
      // reveal).
      late ResolvedResizable resolved;
      pumpWithTheme(tester, _Probe(onResolved: (r) => resolved = r));

      expect(
        resolved.dividerLine.className.contains('group-focus-visible'),
        isFalse,
      );
    });

    testComponents('the ring style defaults to the shared outline', (
      tester,
    ) async {
      late ResolvedResizable resolved;
      pumpWithTheme(tester, _Probe(onResolved: (r) => resolved = r));

      expect(
        resolved.focusOutlineStyle,
        CoreResizableStyle.defaultFocusOutlineStyle,
      );
    });
  });
}
