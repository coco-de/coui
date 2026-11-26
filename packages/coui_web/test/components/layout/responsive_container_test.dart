// Tests for `resolveResponsiveContainer` (Web) — Story H (#2967):
// `responsiveMaxWidth` tier-switching extension over the pre-existing
// static `maxWidth`.
//
// The Jaspr/VM test environment has no attached browser viewport, so
// `resolveBreakpoint`'s width observation deterministically falls back
// to 0 -> `CoreBreakpoint.xs` -> `CoreBreakpointTier.mobile` (mirrors
// `breakpoint_test.dart`'s SSR-fallback coverage). That still fully
// exercises the tier-lookup/per-key-fallback mechanism under test:
// whether the `mobile` key is present in `responsiveMaxWidth` or not
// deterministically switches the branch taken.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Reads the resolved `max-width` inline-CSS value straight off the
/// paint-ready chrome — matches how `co_responsive_container.dart`
/// consumes `resolved.root.inlineStyles` (render-only).
String? _maxWidthCss(ResolvedResponsiveContainer resolved) =>
    resolved.root.inlineStyles?.properties['max-width'];

void main() {
  group(
    'resolveResponsiveContainer — static maxWidth regression '
    '(responsiveMaxWidth: null)',
    () {
      testComponents(
        'resolved max-width stays fixed to the static preset when '
        'responsiveMaxWidth is null (pre-existing behaviour unchanged)',
        (tester) async {
          late ResolvedResponsiveContainer resolved;
          pumpWithTheme(
            tester,
            Builder(
              builder: (context) {
                resolved = resolveResponsiveContainer(
                  context,
                  maxWidth: .lg,
                  responsiveMaxWidth: null,
                  centered: null,
                  padding: null,
                );
                return Component.text('ok');
              },
            ),
          );

          // lg = 1024px / 16 = 64rem.
          expect(_maxWidthCss(resolved), '64.0rem');
        },
      );

      testComponents(
        'omitting maxWidth entirely still resolves to the design-system '
        'default (xl)',
        (tester) async {
          late ResolvedResponsiveContainer resolved;
          pumpWithTheme(
            tester,
            Builder(
              builder: (context) {
                resolved = resolveResponsiveContainer(
                  context,
                  maxWidth: null,
                  responsiveMaxWidth: null,
                  centered: null,
                  padding: null,
                );
                return Component.text('ok');
              },
            ),
          );

          // xl = 1280px / 16 = 80rem (CoreResponsiveContainerStyle
          // .defaultMaxWidth).
          expect(_maxWidthCss(resolved), '80.0rem');
        },
      );
    },
  );

  group('resolveResponsiveContainer — responsiveMaxWidth partial override', () {
    testComponents(
      'a present tier key switches the effective max-width',
      (tester) async {
        const staticMaxWidth = CoreResponsiveContainerMaxWidth.sm;
        // The VM/SSR observation resolves to the `mobile` tier — keying
        // the override on `mobile` exercises the "present" branch.
        // (Exhaustive map — tablet/desktop values are irrelevant to
        // this assertion, added only to stay clear of
        // avoid-missing-enum-constant-in-map.)
        const responsiveMaxWidth = {
          CoreBreakpointTier.mobile: CoreResponsiveContainerMaxWidth.xxl,
          CoreBreakpointTier.tablet: CoreResponsiveContainerMaxWidth.xxl,
          CoreBreakpointTier.desktop: CoreResponsiveContainerMaxWidth.xxl,
        };

        late ResolvedResponsiveContainer resolved;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              resolved = resolveResponsiveContainer(
                context,
                maxWidth: staticMaxWidth,
                responsiveMaxWidth: responsiveMaxWidth,
                centered: null,
                padding: null,
              );
              return Component.text('ok');
            },
          ),
        );

        // xxl = 1536px / 16 = 96rem (not the static sm=40rem).
        expect(_maxWidthCss(resolved), '96.0rem');
      },
    );

    testComponents(
      'a tier missing from the map falls back individually to the static '
      'maxWidth (no crash on the missing key)',
      (tester) async {
        const staticMaxWidth = CoreResponsiveContainerMaxWidth.sm;
        // `mobile` (the tier the VM/SSR observation resolves to) is
        // intentionally absent — only `desktop` is overridden.
        // partial map under test
        const responsiveMaxWidth = {
          CoreBreakpointTier.desktop: CoreResponsiveContainerMaxWidth.xxl,
        };

        late ResolvedResponsiveContainer resolved;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              resolved = resolveResponsiveContainer(
                context,
                maxWidth: staticMaxWidth,
                responsiveMaxWidth: responsiveMaxWidth,
                centered: null,
                padding: null,
              );
              return Component.text('ok');
            },
          ),
        );

        // sm = 640px / 16 = 40rem — falls back to the static preset.
        expect(_maxWidthCss(resolved), '40.0rem');
      },
    );

    testComponents(
      'the widget-level responsiveContainerStyle slot participates in the '
      'same merge chain as the flat parameter',
      (tester) async {
        const responsiveMaxWidth = {
          CoreBreakpointTier.mobile: CoreResponsiveContainerMaxWidth.md,
          CoreBreakpointTier.tablet: CoreResponsiveContainerMaxWidth.md,
          CoreBreakpointTier.desktop: CoreResponsiveContainerMaxWidth.md,
        };

        late ResolvedResponsiveContainer resolved;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              resolved = resolveResponsiveContainer(
                context,
                maxWidth: .sm,
                responsiveMaxWidth: null,
                centered: null,
                padding: null,
                responsiveContainerStyle: const CoreResponsiveContainerStyle(
                  responsiveMaxWidth: responsiveMaxWidth,
                ),
              );
              return Component.text('ok');
            },
          ),
        );

        // md = 768px / 16 = 48rem (from the style-slot map, not sm).
        expect(_maxWidthCss(resolved), '48.0rem');
      },
    );
  });
}
