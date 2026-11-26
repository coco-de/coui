import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

const _kViewportHeight = 800.0;
const _kMobileBoundaryWidth = 767.0;
const _kTabletBoundaryWidth = 768.0;
const _kTabletMidWidth = 1023.0;
const _kDesktopBoundaryWidth = 1024.0;
const _kXxlWidth = 1536.0;
// Fractional, atypical width — mimics an embedded WebView/iframe reporting
// an unusual native width (NFR-7(a) — no correction/estimation applied).
const _kEmbeddedNarrowWidth = 3.4;

// `resolveBreakpoint`/`Breakpoint` observe the *global* viewport width via
// `MediaQuery.sizeOf`, unlike `MediaQueryVisibility` (which measures its
// containing box via `LayoutBuilder`). So width is injected here by
// overriding `MediaQueryData.size` directly rather than constraining the
// real layout width with a SizedBox.
Future<void> _pumpWithWidth(
  WidgetTester tester,
  double width,
  void Function(BuildContext context) onBuild,
) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, _kViewportHeight)),
      child: Builder(
        builder: (context) {
          onBuild(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  group('resolveBreakpoint — Q1 confirmed boundary matrix', () {
    // mobile = CoreBreakpoint.xs(0) / tablet = CoreBreakpoint.md(768) /
    // desktop = CoreBreakpoint.lg(1024) — CoreBreakpointContract
    // .defaultBoundaries. Each width below is one of the issue's mandated
    // edge cases.
    const cases = [
      (0.0, CoreBreakpointTier.mobile, CoreBreakpoint.xs),
      (639.0, CoreBreakpointTier.mobile, CoreBreakpoint.xs),
      (640.0, CoreBreakpointTier.mobile, CoreBreakpoint.sm),
      (767.0, CoreBreakpointTier.mobile, CoreBreakpoint.sm),
      (768.0, CoreBreakpointTier.tablet, CoreBreakpoint.md),
      (1023.0, CoreBreakpointTier.tablet, CoreBreakpoint.md),
      (1024.0, CoreBreakpointTier.desktop, CoreBreakpoint.lg),
      (1536.0, CoreBreakpointTier.desktop, CoreBreakpoint.xxl),
      (3000.0, CoreBreakpointTier.desktop, CoreBreakpoint.xxl),
    ];

    for (final (width, expectedTier, expectedBreakpoint) in cases) {
      testWidgets(
        'width=$width -> breakpoint=${expectedBreakpoint.name}, '
        'tier=${expectedTier.name}',
        (tester) async {
          late ResolvedBreakpoint resolved;
          await _pumpWithWidth(tester, width, (context) {
            resolved = resolveBreakpoint(context);
          });

          expect(resolved.width, width);
          expect(resolved.breakpoint, expectedBreakpoint);
          expect(resolved.tier, expectedTier);
        },
      );
    }
  });

  group('Breakpoint (CoreBreakpointContract implementation)', () {
    testWidgets('exposes width, coreBreakpoint and tier via getters', (
      tester,
    ) async {
      late Breakpoint breakpoint;
      await _pumpWithWidth(tester, _kTabletBoundaryWidth, (context) {
        breakpoint = Breakpoint(context);
      });

      expect(breakpoint.width, _kTabletBoundaryWidth);
      expect(breakpoint.coreBreakpoint, CoreBreakpoint.md);
      expect(breakpoint.tier, CoreBreakpointTier.tablet);
    });
  });

  group('BuildContext extension (BreakpointContextX)', () {
    testWidgets('breakpointTier reflects the resolved tier', (tester) async {
      late CoreBreakpointTier tier;
      await _pumpWithWidth(tester, _kDesktopBoundaryWidth, (context) {
        tier = context.breakpointTier;
      });

      expect(tier, CoreBreakpointTier.desktop);
    });

    testWidgets('coreBreakpoint exposes the raw 6-tier CoreBreakpoint scale', (
      tester,
    ) async {
      late CoreBreakpoint breakpoint;
      await _pumpWithWidth(tester, _kXxlWidth, (context) {
        breakpoint = context.coreBreakpoint;
      });

      expect(breakpoint, CoreBreakpoint.xxl);
    });

    testWidgets('isMobile is true below the tablet boundary', (tester) async {
      late bool isMobile;
      await _pumpWithWidth(tester, _kMobileBoundaryWidth, (context) {
        isMobile = context.isMobile;
      });

      expect(isMobile, isTrue);
    });

    testWidgets('isTablet is true between the tablet and desktop boundaries', (
      tester,
    ) async {
      late bool isTablet;
      await _pumpWithWidth(tester, _kTabletMidWidth, (context) {
        isTablet = context.isTablet;
      });

      expect(isTablet, isTrue);
    });

    testWidgets('isDesktop is true at and above the desktop boundary', (
      tester,
    ) async {
      late bool isDesktop;
      await _pumpWithWidth(tester, _kDesktopBoundaryWidth, (context) {
        isDesktop = context.isDesktop;
      });

      expect(isDesktop, isTrue);
    });
  });

  group('resolveBreakpoint — partial boundaries override', () {
    testWidgets(
      'overriding only the desktop boundary leaves the tablet boundary at '
      'its default and shifts the tier at the previous desktop threshold',
      (tester) async {
        late ResolvedBreakpoint defaultResolved;
        late ResolvedBreakpoint overriddenResolved;

        await _pumpWithWidth(tester, _kDesktopBoundaryWidth, (context) {
          defaultResolved = resolveBreakpoint(context);
          overriddenResolved = resolveBreakpoint(
            context,
            // A partial boundaries map is the intended usage (Decision Log
            // F-2, `CoreBreakpointToTier.toTier`'s doc comment) — this test
            // asserts that the un-overridden `tablet` key correctly falls
            // back to `CoreBreakpointContract.defaultBoundaries`.
            boundaries: const {.desktop: .xl},
          );
        });

        // Default boundaries: 1024px (lg) is already >= the desktop
        // boundary (lg), so it resolves to desktop.
        expect(defaultResolved.tier, CoreBreakpointTier.desktop);

        // Pushing the desktop boundary out to xl (1280px) demotes 1024px
        // to tablet — the (un-overridden) tablet boundary individually
        // falls back to the default (md), per `CoreBreakpointToTier.toTier`.
        expect(overriddenResolved.tier, CoreBreakpointTier.tablet);
        expect(overriddenResolved.breakpoint, CoreBreakpoint.lg);
      },
    );
  });

  group(
    'BDD Feature 4: edge cases — extreme resize + no correction of the '
    'observed width',
    () {
      testWidgets(
        'resizing from desktop down to an extremely narrow, fractional '
        'width (embedded WebView/iframe-like) reflects the newly observed '
        'value verbatim with no crash or correction',
        (tester) async {
          late CoreBreakpointTier desktopTier;
          await _pumpWithWidth(tester, _kDesktopBoundaryWidth, (context) {
            desktopTier = context.breakpointTier;
          });
          expect(desktopTier, CoreBreakpointTier.desktop);

          late ResolvedBreakpoint narrowResolved;
          await _pumpWithWidth(tester, _kEmbeddedNarrowWidth, (context) {
            narrowResolved = resolveBreakpoint(context);
          });

          // The exact fractional width is preserved verbatim — no
          // rounding, clamping, or minimum-width correction.
          expect(narrowResolved.width, _kEmbeddedNarrowWidth);
          expect(narrowResolved.tier, CoreBreakpointTier.mobile);
        },
      );
    },
  );

  group('BDD Feature 6: NG7 negative assertion', () {
    test(
      'coui_flutter breakpoint.dart exposes no generic value-branching API '
      '(context.responsive<T> does not exist)',
      () {
        final source = File(
          'lib/src/components/layout/breakpoint/breakpoint.dart',
        ).readAsStringSync();

        expect(RegExp(r'\bresponsive\s*<').hasMatch(source), isFalse);
      },
    );
  });
}
