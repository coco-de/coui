import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _kViewportHeight = 800.0;
const _kMobileWidth = 500.0;
const _kTabletBoundaryWidth = 768.0;
const _kTabletMidWidth = 900.0;
const _kDesktopBoundaryWidth = 1024.0;
const _kOverriddenSpacing = 24.0;

// `resolveResponsiveRowColumn` derives direction from the same
// `resolveBreakpoint(context)` global-viewport observation the Flutter
// `Breakpoint` accessor uses (`MediaQuery.sizeOf`), so width is injected
// by overriding `MediaQueryData.size` — mirroring
// `packages/coui_flutter/test/components/layout/breakpoint_test.dart`.
// Unlike that non-widget accessor, the resolver also reads `Theme.of`
// (for `scaling` + `coreComponentTheme`), so a `Theme` ancestor is
// required here too.
Future<void> _pumpWithWidth(
  WidgetTester tester,
  double width,
  Widget child,
) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, _kViewportHeight)),
      child: Theme(
        data: const ThemeData(),
        child: Directionality(textDirection: .ltr, child: child),
      ),
    ),
  );
}

void main() {
  group(
    'ResponsiveRowColumn — direction flips at switchAt (default=tablet)',
    () {
      // mobile = CoreBreakpoint.xs(0) / tablet = CoreBreakpoint.md(768) /
      // desktop = CoreBreakpoint.lg(1024) — CoreBreakpointContract
      // .defaultBoundaries, and CoreResponsiveRowColumnContract
      // .defaultSwitchAt == CoreBreakpointTier.tablet.
      const cases = [
        (_kMobileWidth, Axis.vertical),
        (_kTabletBoundaryWidth, Axis.horizontal),
        (_kTabletMidWidth, Axis.horizontal),
        (_kDesktopBoundaryWidth, Axis.horizontal),
      ];

      for (final (width, expectedDirection) in cases) {
        testWidgets(
          'width=$width -> direction=${expectedDirection.name}',
          (tester) async {
            await _pumpWithWidth(
              tester,
              width,
              const ResponsiveRowColumn(
                children: [SizedBox(width: 10, height: 10)],
              ),
            );

            final flex = tester.widget<Flex>(find.byType(Flex));
            expect(flex.direction, expectedDirection);
          },
        );
      }
    },
  );

  group('ResponsiveRowColumn — custom switchAt', () {
    testWidgets(
      'switchAt=desktop keeps tablet-width viewports in Column',
      (tester) async {
        await _pumpWithWidth(
          tester,
          _kTabletMidWidth,
          const ResponsiveRowColumn(
            switchAt: .desktop,
            children: [SizedBox(width: 10, height: 10)],
          ),
        );

        final flex = tester.widget<Flex>(find.byType(Flex));
        expect(flex.direction, Axis.vertical);
      },
    );

    testWidgets(
      'switchAt=mobile renders Row even at the narrowest viewport',
      (tester) async {
        await _pumpWithWidth(
          tester,
          _kMobileWidth,
          const ResponsiveRowColumn(
            switchAt: .mobile,
            children: [SizedBox(width: 10, height: 10)],
          ),
        );

        final flex = tester.widget<Flex>(find.byType(Flex));
        expect(flex.direction, Axis.horizontal);
      },
    );
  });

  group('ResponsiveRowColumn — spacing / alignment defaults', () {
    testWidgets('defaults match CoreResponsiveRowColumnStyle', (
      tester,
    ) async {
      await _pumpWithWidth(
        tester,
        _kDesktopBoundaryWidth,
        const ResponsiveRowColumn(
          children: [SizedBox(width: 10, height: 10)],
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      expect(flex.spacing, CoreResponsiveRowColumnStyle.defaultSpacing);
      expect(flex.mainAxisAlignment, MainAxisAlignment.start);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.center);
    });

    testWidgets('responsiveRowColumnStyle overrides spacing + alignment', (
      tester,
    ) async {
      await _pumpWithWidth(
        tester,
        _kDesktopBoundaryWidth,
        const ResponsiveRowColumn(
          responsiveRowColumnStyle: CoreResponsiveRowColumnStyle(
            spacing: _kOverriddenSpacing,
            mainAxisAlignment: .spaceBetween,
            crossAxisAlignment: .end,
          ),
          children: [SizedBox(width: 10, height: 10)],
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      expect(flex.spacing, _kOverriddenSpacing);
      expect(flex.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.end);
    });
  });

  group(
    'ResponsiveRowColumn / Web parity — shared CoreBreakpointTierOrder',
    () {
      // Both platform resolvers derive "is this tier at/above switchAt"
      // from the single `CoreBreakpointTierOrder.isAtLeast` self-comparison
      // in coui_core (see `packages/coui_core/test/breakpoint_style_test
      // .dart`'s `CoreBreakpointTierOrder.isAtLeast` group) — this test
      // proves the Flutter resolver actually reaches that shared
      // comparison rather than re-deriving its own ordinal logic.
      testWidgets(
        'resolveResponsiveRowColumn direction matches '
        'CoreBreakpointTierOrder.isAtLeast(switchAt) for the observed tier',
        (tester) async {
          late ResolvedResponsiveRowColumn resolved;
          late CoreBreakpointTier currentTier;
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(_kTabletMidWidth, _kViewportHeight),
              ),
              child: Theme(
                data: const ThemeData(),
                child: Builder(
                  builder: (context) {
                    resolved = resolveResponsiveRowColumn(
                      context,
                      switchAt: null,
                      responsiveRowColumnStyle: null,
                    );
                    currentTier = resolveBreakpoint(context).tier;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );

          final expectRow = currentTier.isAtLeast(.tablet);

          expect(resolved.direction == .horizontal, expectRow);
        },
      );
    },
  );
}
