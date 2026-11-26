import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/overlay/hover_card/hover_card_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so a resolver can be called
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

/// Every `<div>` whose class list holds all of [classes] (whole-class match).
Finder _divWithClasses(List<String> classes) => find.byComponentPredicate((c) {
  if (c is! div) return false;
  final present = c.classes?.split(' ').toSet() ?? const <String>{};
  return classes.every(present.contains);
});

void main() {
  group('HoverCard panel surface', () {
    testComponents('the open panel is a composed Popup box, not a Card', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const HoverCard(
          openDelay: Duration.zero,
          trigger: Component.text('Target'),
          content: Component.text('Panel'),
        ),
      );

      tester.dispatchEvent(
        find.ancestor(of: find.text('Target'), matching: find.tag('div')).first,
        'mouseenter',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();

      expect(find.text('Panel'), findsOneComponent);
      expect(find.byType(Card), findsNothing);
      // The bubble carries the `Popup` root chrome: a flex column that clips
      // to the radius, on the raised floating fill.
      expect(
        _divWithClasses(['flex', 'flex-col', 'overflow-hidden']),
        findsOneComponent,
      );
    });
  });

  group('HoverCard panel chrome (#5967)', () {
    testComponents('the open card is corner 12 on a surface-bright fill', (
      tester,
    ) async {
      late ResolvedHoverCard resolved;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => resolved = resolveHoverCard(context: context),
        ),
      );

      // Corner 12 — the panel role, `Popup`'s own default reached because the
      // hover card does not state one.
      expect(
        resolved.bubble.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(12).toValue(),
      );
      expect(
        resolved.bubble.className.split(' '),
        contains('bg-surface-bright'),
      );
      // The border comes out of the inset: the panel is as large as its
      // padding says, the line over it.
      expect(
        resolved.bubble.inlineStyles?.properties['padding'],
        const CoreEdgeInsets.all(16).toDeclarationsWithinBorder(
          'padding',
          surfaceClipKeptBorder(strokeWidthCss(CoreStrokeWidth.stroke1)),
        )['padding'],
      );
    });

    testComponents('the panel sizes to content under a 256 ceiling', (
      tester,
    ) async {
      late ResolvedHoverCard resolved;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => resolved = resolveHoverCard(context: context),
        ),
      );

      final styles = resolved.bubble.inlineStyles!.properties;
      // 256 / 16 rem — `Popup`'s resolver emits the ceiling the hover card
      // states, and no floor of `Popup`'s own 128.
      expect(styles['max-width'], '16.0rem');
      expect(styles['min-width'], '0.0rem');
    });

    testComponents('a stated radius and fill win over the defaults', (
      tester,
    ) async {
      late ResolvedHoverCard resolved;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => resolved = resolveHoverCard(
            context: context,
            hoverCardStyle: const CoreHoverCardStyle(
              panelStyle: CorePopupStyle(
                borderRadius: CoreBorderRadius.all(20),
                backgroundColor: CoreColor.token(CoreColors.surface),
              ),
            ),
          ),
        ),
      );

      expect(
        resolved.bubble.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(20).toValue(),
      );
      expect(resolved.bubble.className.split(' '), contains('bg-surface'));
      expect(
        resolved.bubble.className.split(' '),
        isNot(contains('bg-surface-bright')),
      );
      // A stated corner and fill do not take the ceiling with them.
      expect(resolved.bubble.inlineStyles?.properties['max-width'], '16.0rem');
    });

    testComponents('the chain getters patch the panel slot', (tester) async {
      const card = HoverCard(
        trigger: Component.text('Target'),
        content: Component.text('Panel'),
      );
      final chained = card.radius4.surface;

      expect(
        chained.hoverCardStyle?.panelStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(
        chained.hoverCardStyle?.panelStyle?.backgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
    });

    testComponents('the card sits 4 off the trigger', (tester) async {
      late double gap;
      pumpWithTheme(
        tester,
        _ContextCapture(
          (context) => gap = resolveHoverCardConfig(context).gap,
        ),
      );

      expect(gap, 4);
    });
  });
}
