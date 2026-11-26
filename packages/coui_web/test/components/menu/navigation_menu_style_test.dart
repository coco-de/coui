// When the open menu moves from one trigger to another, the panel must
// *travel* — it is already on screen. Replaying the entrance keyframe at
// the new spot reads as "closed, then reopened somewhere else" — a
// divergence from the Flutter twin. This file pins the emitters that travel
// is built from (keyframe, start offset, the two crossing halves); the
// choice of the travel emitter over the entrance one is the widget's, and
// is not reachable from a VM test.

import 'package:coui_web/coui_web.dart';
// The motion emitters are internal chrome — not re-exported by the barrel,
// so import them directly for emitter-level assertions.
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveNavigationMenu` directly.
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

const _kTriggers = [
  NavigationMenuTriggerState(highlighted: true, open: true, hasContent: true),
  NavigationMenuTriggerState(highlighted: false, open: false, hasContent: true),
];

void main() {
  group('NavigationMenu panel travel', () {
    test('the travel emitter plays the switch keyframe, no opacity', () {
      // What this pins is the emitter's own output. Whether a trigger
      // switch reaches this emitter rather than the entrance one is decided
      // in the widget's panel build, which only runs positioned in a
      // browser — no assertion here can see that choice.
      final motion = resolveOverlaySwitchMotion(
        fromDx: -160,
        fromDy: 0,
        duration: const Duration(milliseconds: 300),
      );
      final animation = motion.inlineStyles?.properties['animation'];

      expect(animation, isNotNull);
      expect(animation, contains('co-overlay-switch'));
      // No opacity keyframe is involved — the panel never leaves screen.
      expect(motion.className, isEmpty);
    });

    test('the travel starts at the previous origin and relaxes to zero', () {
      final motion = resolveOverlaySwitchMotion(
        // 160 logical px to the left of the new origin, 8 above it.
        fromDx: -160,
        fromDy: -8,
        duration: const Duration(milliseconds: 300),
      );
      final css = motion.inlineStyles!.properties;

      // The keyframe reads these, so the panel starts where it was even
      // though the node is re-created already at its new origin.
      expect(css['--coui-overlay-switch-x'], '-10.0rem');
      expect(css['--coui-overlay-switch-y'], '-0.5rem');
    });

    test('the two content halves cross in opposite directions', () {
      const duration = Duration(milliseconds: 300);
      final incoming = resolveOverlaySwapMotion(
        incoming: true,
        direction: 1,
        duration: duration,
      );
      final outgoing = resolveOverlaySwapMotion(
        incoming: false,
        direction: 1,
        duration: duration,
      );

      expect(
        incoming.inlineStyles?.properties['animation'],
        contains('co-overlay-swap-enter'),
      );
      expect(
        outgoing.inlineStyles?.properties['animation'],
        contains('co-overlay-swap-exit'),
      );
      // Moving toward a later trigger: both halves travel along +x, the
      // incoming one arriving from that side and the outgoing one leaving
      // opposite it (the keyframe negates for the exit).
      expect(
        incoming.inlineStyles?.properties['--coui-overlay-swap-x'],
        '100%',
      );
      expect(
        outgoing.inlineStyles?.properties['--coui-overlay-swap-x'],
        '100%',
      );
      // Only the outgoing half leaves the flow, so the incoming one alone
      // sizes the panel — the box takes its new size up front.
      expect(incoming.className, isEmpty);
      expect(outgoing.className, contains('absolute'));
    });

    test('moving toward an earlier trigger reverses the crossing', () {
      final incoming = resolveOverlaySwapMotion(
        incoming: true,
        direction: -1,
        duration: const Duration(milliseconds: 300),
      );

      expect(
        incoming.inlineStyles?.properties['--coui-overlay-swap-x'],
        '-100%',
      );
    });
  });

  group('NavigationMenu pointer-intent timings', () {
    testComponents('reach the runtime with their design-system defaults', (
      tester,
    ) async {
      final resolved = resolveNavigationMenu(
        _themedContext(tester),
        variant: .standard,
        triggers: _kTriggers,
      );

      expect(
        resolved.runtime.closeDelay,
        CoreNavigationMenuStyle.defaultCloseDelay,
      );
      expect(
        resolved.runtime.panelSwitchDuration,
        CoreNavigationMenuStyle.defaultPanelSwitchDuration,
      );
    });

    testComponents('honour a per-instance override', (tester) async {
      const closeDelay = Duration(milliseconds: 40);
      const switchDuration = Duration(milliseconds: 90);
      final resolved = resolveNavigationMenu(
        _themedContext(tester),
        variant: .standard,
        triggers: _kTriggers,
        navigationMenuStyle: const CoreNavigationMenuStyle(
          closeDelay: closeDelay,
          panelSwitchDuration: switchDuration,
        ),
      );

      expect(resolved.runtime.closeDelay, closeDelay);
      expect(resolved.runtime.panelSwitchDuration, switchDuration);
    });
  });

  group('NavigationMenu trigger redesign (#5967)', () {
    const states = [
      NavigationMenuTriggerState(
        highlighted: true,
        open: true,
        hasContent: true,
      ),
      NavigationMenuTriggerState(
        highlighted: false,
        open: false,
        hasContent: true,
      ),
      NavigationMenuTriggerState(
        highlighted: false,
        open: false,
        hasContent: false,
      ),
    ];

    testComponents('the bar spaces triggers 2 apart', (tester) async {
      final resolved = resolveNavigationMenu(
        _themedContext(tester),
        variant: .standard,
        triggers: states,
      );

      expect(CoreNavigationMenuStyle.defaultTriggerSpacing, 2);
      expect(
        resolved.root.inlineStyles?.properties['gap'],
        'var(--coui-space-2)',
      );
    });

    testComponents('each trigger takes the style its state selects', (
      tester,
    ) async {
      final resolved = resolveNavigationMenu(
        _themedContext(tester),
        variant: .standard,
        triggers: states,
      );
      final open = resolved.triggers[0].buttonStyle;
      final closed = resolved.triggers[1].buttonStyle;
      final plain = resolved.triggers[2].buttonStyle;

      // A trigger that owns a dropdown is inset 12 at the start / 8 at the
      // end; one without is 12 on both sides.
      const content = CoreEdgeInsets.directional(
        start: CoreSpace.space12,
        end: CoreSpace.space8,
        top: CoreSpace.space8,
        bottom: CoreSpace.space8,
      );
      expect(open.padding, content);
      expect(closed.padding, content);
      expect(
        plain.padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space8,
        ),
      );

      // The open one keeps the hover fill; a resting one states none.
      expect(
        open.backgroundColor,
        CoreNavigationMenuStyle.defaultTriggerHoverColor,
      );
      expect(closed.backgroundColor, isNull);
      expect(plain.backgroundColor, isNull);

      // Every trigger states the hover fill and the 4 label → chevron gap.
      for (final style in [open, closed, plain]) {
        expect(
          style.hoverBackgroundColor,
          CoreNavigationMenuStyle.defaultTriggerHoverColor,
        );
        expect(style.iconLabelGapStyle?.size, CoreSpace.space4);
      }
    });

    testComponents('a per-instance override reaches the styles it names', (
      tester,
    ) async {
      final resolved = resolveNavigationMenu(
        _themedContext(tester),
        variant: .standard,
        triggers: states,
        navigationMenuStyle: const CoreNavigationMenuStyle(
          triggerButtonStyle: CoreButtonStyle(
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
          openTriggerButtonStyle: CoreButtonStyle(
            backgroundColor: CoreColor.token(CoreColors.secondaryContainer),
          ),
        ),
      );

      // The plain override reaches every trigger, the content trigger's own
      // inset yields to it, and the open fill is the stated one.
      for (final trigger in resolved.triggers) {
        expect(
          trigger.buttonStyle.padding,
          const CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space24,
            vertical: CoreSpace.space8,
          ),
        );
      }
      expect(
        resolved.triggers[0].buttonStyle.backgroundColor,
        const CoreColor.token(CoreColors.secondaryContainer),
      );
      expect(resolved.triggers[1].buttonStyle.backgroundColor, isNull);
    });

    testComponents('the chevron is on-surface-variant and the panel corner is '
        '12', (tester) async {
      final resolved = resolveNavigationMenu(
        _themedContext(tester),
        variant: .standard,
        triggers: states,
      );

      expect(
        resolved.chevronIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreNavigationMenuStyle.defaultPanelStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
    });

    testComponents('the Button emits a directional inset as logical '
        'longhands and a symmetric one as the shorthand', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveNavigationMenu(
        context,
        variant: .standard,
        triggers: states,
      );
      Styles? rootStyles(CoreButtonStyle style) => resolveButton(
        context,
        variant: .menubar,
        size: .md,
        shape: .rectangle,
        expanded: false,
        buttonStyle: style,
      ).root.inlineStyles;

      final content = rootStyles(resolved.triggers[1].buttonStyle)!.properties;
      expect(content['padding-inline-start'], 'var(--coui-space-12)');
      expect(content['padding-inline-end'], 'var(--coui-space-8)');
      expect(content['padding-block-start'], 'var(--coui-space-8)');
      expect(content['padding-block-end'], 'var(--coui-space-8)');
      expect(content.containsKey('padding'), isFalse);

      final plain = rootStyles(resolved.triggers[2].buttonStyle)!.properties;
      expect(plain['padding'], isNotNull);
      expect(plain.containsKey('padding-inline-start'), isFalse);
    });

    testComponents("a focused trigger takes the stated fill, not the variant's "
        'stronger one', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveNavigationMenu(
        context,
        variant: .standard,
        triggers: states,
      );
      List<String> classes(CoreButtonStyle style) => resolveButton(
        context,
        variant: .menubar,
        size: .md,
        shape: .rectangle,
        expanded: false,
        buttonStyle: style,
      ).root.className.split(' ');

      final open = classes(resolved.triggers[0].buttonStyle);
      expect(open, contains('focus:bg-surface-container'));
      expect(open, isNot(contains('focus:bg-surface-container-highest')));
      expect(open, contains('bg-surface-container'));
      expect(open, contains('hover:bg-surface-container'));

      // A style that states no fill keeps the variant's own focused one.
      final bare = classes(const CoreButtonStyle());
      expect(bare, contains('focus:bg-surface-container-highest'));
    });
  });
}
