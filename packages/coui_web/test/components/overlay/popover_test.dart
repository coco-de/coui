import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/components/overlay/popover/popover_style.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so the resolver can be called
/// directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

void main() {
  group('Popover', () {
    test('scroll policy defaults false and copyWith preserves an opt in', () {
      const original = Popover(
        trigger: Component.text('Open'),
        content: Component.text('Panel'),
      );
      expect(original.closeOnScroll, isFalse);
      expect(
        original.copyWith(closeOnScroll: true).copyWith().closeOnScroll,
        isTrue,
      );
    });
    testComponents('renders its trigger, content closed by default', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Popover(
          trigger: Component.text('Open'),
          content: Component.text('Panel'),
        ),
      );

      expect(find.text('Open'), findsOneComponent);
    });

    test('accepts custom id', () {
      const popover = Popover(
        trigger: Component.text('Open'),
        content: Component.text('Panel'),
        id: 'popover-1',
      );
      expect(popover.id, equals('popover-1'));
    });

    test('copyWith preserves properties', () {
      const original = Popover(
        trigger: Component.text('Open'),
        content: Component.text('Panel'),
        placement: CorePopoverPlacement.top,
        openTrigger: CorePopoverTrigger.focus,
        modal: true,
        id: 'popover-orig',
      );

      final copy = original.copyWith(id: 'popover-new');

      expect(copy.id, equals('popover-new'));
      expect(copy.placement, equals(CorePopoverPlacement.top));
      expect(copy.openTrigger, equals(CorePopoverTrigger.focus));
      expect(copy.modal, isTrue);
    });

    test('implements CorePopoverContract', () {
      const popover = Popover(
        trigger: Component.text('Open'),
        content: Component.text('Panel'),
        placement: CorePopoverPlacement.right,
      );

      expect(popover.placement, equals(CorePopoverPlacement.right));
    });
  });
  group('resolvePopoverConfig offset (#5967)', () {
    testComponents('the trigger-to-panel gap defaults to 4', (tester) async {
      late ({double gap}) config;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => config = (gap: resolvePopoverConfig(context).gap),
        ),
      );

      expect(config.gap, 4);
      expect(config.gap, CorePopoverStyle.defaultPlacementOffset);
    });

    testComponents('a stated offset still wins over the default', (
      tester,
    ) async {
      late double gap;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => gap = resolvePopoverConfig(
            context,
            popoverStyle: const CorePopoverStyle(placementOffset: 12),
          ).gap,
        ),
      );

      expect(gap, 12);
    });
  });

  // The scope is an inline formatting context whose strut is the surrounding
  // body line height. A trigger with no text of its own (an empty colour
  // swatch) has its baseline on its bottom edge, so on the baseline the
  // strut's descent hung below it and the whole popover came out a few px
  // taller than its trigger. Top-aligned, the line box is the trigger's own
  // height.
  group('Popover trigger wrapper in a block scope', () {
    testComponents('an intrinsic trigger is top-aligned, not on the baseline', (
      tester,
    ) async {
      late ResolvedPopover resolved;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => resolved = resolvePopover(context),
        ),
      );

      final classes = resolved.trigger.className.split(' ');
      expect(classes, containsAll(['inline-flex', 'align-top']));
    });

    testComponents('an expanding trigger is a block flex row', (tester) async {
      late ResolvedPopover resolved;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => resolved = resolvePopover(
            context,
            popoverStyle: const CorePopoverStyle(
              triggerSizing: CorePopoverTriggerSizing.expand,
            ),
          ),
        ),
      );

      final classes = resolved.trigger.className.split(' ');
      expect(classes, containsAll(['flex', 'w-full']));
      expect(classes, isNot(contains('align-top')));
    });
  });
}
