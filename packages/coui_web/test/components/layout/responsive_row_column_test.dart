// The expected gaps below are the `--coui-space-*` variables of the
// spacing steps they come from, not arbitrary magic numbers.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:coui_web/src/components/layout/responsive_row_column/responsive_row_column.dart';
import 'package:coui_web/src/components/layout/responsive_row_column/responsive_row_column_style.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kOverriddenSpacing = 32.0;

void main() {
  group('ResponsiveRowColumn', () {
    testComponents('renders a single <div> with a text child', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ResponsiveRowColumn(children: [Component.text('Item')]),
      );

      expect(find.tag('div'), findsOneComponent);
      expect(find.text('Item'), findsOneComponent);
    });
  });

  group(
    'resolveResponsiveRowColumn — direction flips at switchAt '
    '(SSR/no-viewport observes as mobile, matching Story C\'s '
    'one-shot fallback)',
    () {
      // `resolveBreakpoint` observes width `0` with no attached browser
      // viewport (SSR-safe one-shot fallback, Story C) which resolves to
      // `CoreBreakpointTier.mobile` — matching
      // `packages/coui_web/test/components/layout/breakpoint_test.dart`'s
      // "resolves a deterministic mobile tier" case. `switchAt` is
      // exercised against that fixed mobile tier instead of simulating a
      // real browser resize.
      testComponents(
        'default switchAt (tablet) renders flex-col at the mobile tier',
        (tester) async {
          late ResolvedResponsiveRowColumn resolved;
          pumpWithTheme(
            tester,
            Builder(
              builder: (context) {
                resolved = resolveResponsiveRowColumn(
                  context,
                  switchAt: null,
                  responsiveRowColumnStyle: null,
                );
                return Component.text('ok');
              },
            ),
          );

          expect(resolved.root.className, contains('flex-col'));
          expect(resolved.root.className, isNot(contains('flex-row')));
        },
      );

      testComponents(
        'switchAt=mobile renders flex-row even at the mobile tier',
        (tester) async {
          late ResolvedResponsiveRowColumn resolved;
          pumpWithTheme(
            tester,
            Builder(
              builder: (context) {
                resolved = resolveResponsiveRowColumn(
                  context,
                  switchAt: .mobile,
                  responsiveRowColumnStyle: null,
                );
                return Component.text('ok');
              },
            ),
          );

          expect(resolved.root.className, contains('flex-row'));
          expect(resolved.root.className, isNot(contains('flex-col')));
        },
      );
    },
  );

  group('resolveResponsiveRowColumn — spacing / alignment defaults', () {
    testComponents('default spacing emits its spacing variable as the gap', (
      tester,
    ) async {
      late ResolvedResponsiveRowColumn resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveResponsiveRowColumn(
              context,
              switchAt: null,
              responsiveRowColumnStyle: null,
            );
            return Component.text('ok');
          },
        ),
      );

      final expectedGap =
          'var(--coui-space-'
          '${CoreResponsiveRowColumnStyle.defaultSpacing.toInt()})';
      expect(resolved.root.inlineStyles?.properties['gap'], expectedGap);
    });

    testComponents('default alignment classes are start/center', (
      tester,
    ) async {
      late ResolvedResponsiveRowColumn resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveResponsiveRowColumn(
              context,
              switchAt: null,
              responsiveRowColumnStyle: null,
            );
            return Component.text('ok');
          },
        ),
      );

      expect(resolved.root.className, contains('justify-start'));
      expect(resolved.root.className, contains('items-center'));
    });

    testComponents(
      'responsiveRowColumnStyle overrides spacing + alignment',
      (tester) async {
        late ResolvedResponsiveRowColumn resolved;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              resolved = resolveResponsiveRowColumn(
                context,
                switchAt: null,
                responsiveRowColumnStyle: const CoreResponsiveRowColumnStyle(
                  spacing: _kOverriddenSpacing,
                  mainAxisAlignment: .spaceBetween,
                  crossAxisAlignment: .end,
                ),
              );
              return Component.text('ok');
            },
          ),
        );

        expect(
          resolved.root.inlineStyles?.properties['gap'],
          'var(--coui-space-${_kOverriddenSpacing.toInt()})',
        );
        expect(resolved.root.className, contains('justify-between'));
        expect(resolved.root.className, contains('items-end'));
      },
    );
  });

  group(
    'ResponsiveRowColumn / Flutter parity — shared '
    'CoreBreakpointTierOrder',
    () {
      // Both platform resolvers derive "is this tier at/above switchAt"
      // from the single `CoreBreakpointTierOrder.isAtLeast` self-comparison
      // in coui_core (see `packages/coui_core/test/breakpoint_style_test
      // .dart`'s `CoreBreakpointTierOrder.isAtLeast` group) — this test
      // proves the Web resolver actually reaches that shared comparison
      // rather than re-deriving its own ordinal logic.
      testComponents(
        'resolveResponsiveRowColumn direction matches '
        'CoreBreakpointTierOrder.isAtLeast(switchAt) for the observed tier',
        (tester) async {
          late ResolvedResponsiveRowColumn resolved;
          late CoreBreakpointTier currentTier;
          pumpWithTheme(
            tester,
            Builder(
              builder: (context) {
                resolved = resolveResponsiveRowColumn(
                  context,
                  switchAt: null,
                  responsiveRowColumnStyle: null,
                );
                currentTier = resolveBreakpoint(context).tier;
                return Component.text('ok');
              },
            ),
          );

          final expectRow = currentTier.isAtLeast(.tablet);

          expect(resolved.root.className.contains('flex-row'), expectRow);
        },
      );
    },
  );
}
