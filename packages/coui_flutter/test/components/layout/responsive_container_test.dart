// Tests for `resolveResponsiveContainer` / `ResponsiveContainer` — Story H
// (#2967): `responsiveMaxWidth` tier-switching extension over the
// pre-existing static `maxWidth`.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _kViewportHeight = 800.0;
const _kMobileWidth = 375.0;
const _kTabletWidth = 800.0;
const _kDesktopWidth = 1200.0;

// `resolveResponsiveContainer` reads the global viewport width through
// `resolveBreakpoint` (`MediaQuery.sizeOf`), mirroring the injection
// pattern used by `breakpoint_test.dart`.
Future<void> _pumpWithWidth(
  WidgetTester tester,
  double width,
  void Function(BuildContext context) onBuild,
) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, _kViewportHeight)),
      child: Theme(
        data: const ThemeData(),
        child: Builder(
          builder: (context) {
            onBuild(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
}

void main() {
  group(
    'resolveResponsiveContainer — static maxWidth regression '
    '(responsiveMaxWidth: null)',
    () {
      testWidgets(
        'resolved.maxWidth stays fixed to the static preset regardless of '
        'viewport width when responsiveMaxWidth is null (pre-existing '
        'behaviour unchanged)',
        (tester) async {
          late ResolvedResponsiveContainer mobileResolved;
          late ResolvedResponsiveContainer desktopResolved;

          await _pumpWithWidth(tester, _kMobileWidth, (context) {
            mobileResolved = resolveResponsiveContainer(
              context,
              maxWidth: .lg,
              responsiveMaxWidth: null,
              centered: null,
              padding: null,
            );
          });
          await _pumpWithWidth(tester, _kDesktopWidth, (context) {
            desktopResolved = resolveResponsiveContainer(
              context,
              maxWidth: .lg,
              responsiveMaxWidth: null,
              centered: null,
              padding: null,
            );
          });

          expect(
            mobileResolved.maxWidth,
            CoreResponsiveContainerMaxWidth.lg.maxWidth,
          );
          expect(
            desktopResolved.maxWidth,
            CoreResponsiveContainerMaxWidth.lg.maxWidth,
          );
          expect(mobileResolved.maxWidth, desktopResolved.maxWidth);
        },
      );

      testWidgets(
        'omitting maxWidth entirely still resolves to the design-system '
        'default (xl) regardless of viewport width',
        (tester) async {
          late ResolvedResponsiveContainer resolved;
          await _pumpWithWidth(tester, _kMobileWidth, (context) {
            resolved = resolveResponsiveContainer(
              context,
              maxWidth: null,
              responsiveMaxWidth: null,
              centered: null,
              padding: null,
            );
          });

          expect(
            resolved.maxWidth,
            CoreResponsiveContainerStyle.defaultMaxWidth.maxWidth,
          );
        },
      );

      testWidgets('centered/padding resolution is unaffected', (
        tester,
      ) async {
        late ResolvedResponsiveContainer resolved;
        await _pumpWithWidth(tester, _kMobileWidth, (context) {
          resolved = resolveResponsiveContainer(
            context,
            maxWidth: .full,
            responsiveMaxWidth: null,
            centered: false,
            padding: const CoreEdgeInsets.all(8),
          );
        });

        expect(resolved.maxWidth, double.infinity);
        expect(resolved.centered, isFalse);
        expect(resolved.horizontalPadding, const EdgeInsets.all(8));
      });
    },
  );

  group('resolveResponsiveContainer — responsiveMaxWidth partial override', () {
    testWidgets(
      'a tier missing from the map falls back individually to the static '
      'maxWidth, while the overridden tier switches',
      (tester) async {
        const staticMaxWidth = CoreResponsiveContainerMaxWidth.sm;
        // Only desktop is overridden — mobile/tablet intentionally
        // missing to exercise the per-key fallback.
        // partial map under test
        const responsiveMaxWidth = {
          CoreBreakpointTier.desktop: CoreResponsiveContainerMaxWidth.xxl,
        };

        late ResolvedResponsiveContainer mobileResolved;
        late ResolvedResponsiveContainer tabletResolved;
        late ResolvedResponsiveContainer desktopResolved;

        await _pumpWithWidth(tester, _kMobileWidth, (context) {
          mobileResolved = resolveResponsiveContainer(
            context,
            maxWidth: staticMaxWidth,
            responsiveMaxWidth: responsiveMaxWidth,
            centered: null,
            padding: null,
          );
        });
        await _pumpWithWidth(tester, _kTabletWidth, (context) {
          tabletResolved = resolveResponsiveContainer(
            context,
            maxWidth: staticMaxWidth,
            responsiveMaxWidth: responsiveMaxWidth,
            centered: null,
            padding: null,
          );
        });
        await _pumpWithWidth(tester, _kDesktopWidth, (context) {
          desktopResolved = resolveResponsiveContainer(
            context,
            maxWidth: staticMaxWidth,
            responsiveMaxWidth: responsiveMaxWidth,
            centered: null,
            padding: null,
          );
        });

        // mobile/tablet tiers are absent from the map — each
        // individually falls back to the static maxWidth (sm), never
        // crashing on the missing key.
        expect(mobileResolved.maxWidth, staticMaxWidth.maxWidth);
        expect(tabletResolved.maxWidth, staticMaxWidth.maxWidth);
        // desktop tier is present in the map — switches to xxl.
        expect(
          desktopResolved.maxWidth,
          CoreResponsiveContainerMaxWidth.xxl.maxWidth,
        );
      },
    );

    testWidgets('a fully-specified map switches every tier', (tester) async {
      const responsiveMaxWidth = {
        CoreBreakpointTier.mobile: CoreResponsiveContainerMaxWidth.sm,
        CoreBreakpointTier.tablet: CoreResponsiveContainerMaxWidth.md,
        CoreBreakpointTier.desktop: CoreResponsiveContainerMaxWidth.xl,
      };

      late ResolvedResponsiveContainer mobileResolved;
      late ResolvedResponsiveContainer tabletResolved;
      late ResolvedResponsiveContainer desktopResolved;

      await _pumpWithWidth(tester, _kMobileWidth, (context) {
        mobileResolved = resolveResponsiveContainer(
          context,
          maxWidth: .full,
          responsiveMaxWidth: responsiveMaxWidth,
          centered: null,
          padding: null,
        );
      });
      await _pumpWithWidth(tester, _kTabletWidth, (context) {
        tabletResolved = resolveResponsiveContainer(
          context,
          maxWidth: .full,
          responsiveMaxWidth: responsiveMaxWidth,
          centered: null,
          padding: null,
        );
      });
      await _pumpWithWidth(tester, _kDesktopWidth, (context) {
        desktopResolved = resolveResponsiveContainer(
          context,
          maxWidth: .full,
          responsiveMaxWidth: responsiveMaxWidth,
          centered: null,
          padding: null,
        );
      });

      expect(
        mobileResolved.maxWidth,
        CoreResponsiveContainerMaxWidth.sm.maxWidth,
      );
      expect(
        tabletResolved.maxWidth,
        CoreResponsiveContainerMaxWidth.md.maxWidth,
      );
      expect(
        desktopResolved.maxWidth,
        CoreResponsiveContainerMaxWidth.xl.maxWidth,
      );
    });

    testWidgets(
      'the widget-level responsiveContainerStyle slot participates in the '
      'same merge chain as the flat widget parameter',
      (tester) async {
        const responsiveMaxWidth = {
          CoreBreakpointTier.mobile: CoreResponsiveContainerMaxWidth.md,
          CoreBreakpointTier.tablet: CoreResponsiveContainerMaxWidth.md,
          CoreBreakpointTier.desktop: CoreResponsiveContainerMaxWidth.md,
        };

        late ResolvedResponsiveContainer resolved;
        await _pumpWithWidth(tester, _kMobileWidth, (context) {
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
        });

        expect(resolved.maxWidth, CoreResponsiveContainerMaxWidth.md.maxWidth);
      },
    );
  });

  group('ResponsiveContainer widget — end-to-end tier switching', () {
    testWidgets(
      'renders a ConstrainedBox whose maxWidth switches per breakpoint tier',
      (tester) async {
        const responsiveMaxWidth = {
          CoreBreakpointTier.mobile: CoreResponsiveContainerMaxWidth.sm,
          CoreBreakpointTier.tablet: CoreResponsiveContainerMaxWidth.md,
          CoreBreakpointTier.desktop: CoreResponsiveContainerMaxWidth.xxl,
        };

        Widget buildWidget(double width) => MediaQuery(
          data: MediaQueryData(size: Size(width, _kViewportHeight)),
          child: Theme(
            data: const ThemeData(),
            child: Directionality(
              textDirection: .ltr,
              child: ResponsiveContainer(
                maxWidth: .md,
                responsiveMaxWidth: responsiveMaxWidth,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        );

        await tester.pumpWidget(buildWidget(_kMobileWidth));
        var constrainedBox = tester.widget<ConstrainedBox>(
          find.byType(ConstrainedBox),
        );
        expect(
          constrainedBox.constraints.maxWidth,
          CoreResponsiveContainerMaxWidth.sm.maxWidth,
        );

        await tester.pumpWidget(buildWidget(_kDesktopWidth));
        constrainedBox = tester.widget<ConstrainedBox>(
          find.byType(ConstrainedBox),
        );
        expect(
          constrainedBox.constraints.maxWidth,
          CoreResponsiveContainerMaxWidth.xxl.maxWidth,
        );
      },
    );

    testWidgets(
      'a widget with no responsiveMaxWidth renders the static maxWidth '
      'unchanged across viewport widths',
      (tester) async {
        Widget buildWidget(double width) => MediaQuery(
          data: MediaQueryData(size: Size(width, _kViewportHeight)),
          child: Theme(
            data: const ThemeData(),
            child: Directionality(
              textDirection: .ltr,
              child: ResponsiveContainer(
                maxWidth: .lg,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        );

        await tester.pumpWidget(buildWidget(_kMobileWidth));
        final mobileMaxWidth = tester
            .widget<ConstrainedBox>(find.byType(ConstrainedBox))
            .constraints
            .maxWidth;
        expect(mobileMaxWidth, CoreResponsiveContainerMaxWidth.lg.maxWidth);

        await tester.pumpWidget(buildWidget(_kDesktopWidth));
        // Compared inline (not captured into a second named variable)
        // against the mobile-width capture above — proves the value
        // is identical across viewport widths without a duplicate
        // initializer / duplicate literal assertion.
        expect(
          tester
              .widget<ConstrainedBox>(find.byType(ConstrainedBox))
              .constraints
              .maxWidth,
          mobileMaxWidth,
        );
      },
    );
  });
}
