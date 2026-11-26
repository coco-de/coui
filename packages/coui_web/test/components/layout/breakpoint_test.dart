// Width-boundary literals below are the CoreBreakpoint scale itself, not
// arbitrary magic numbers — see the `CoreBreakpoint` enum in coui_core.

import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/breakpoint/breakpoint.dart';
import 'package:coui_web/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  group('CoreBreakpoint.toTier() cross-platform parity', () {
    // `resolveBreakpoint` (Web) and its Flutter counterpart both delegate
    // the judgement entirely to coui_core — the width to
    // `CoreBreakpoint.forWidth`, the breakpoint to the shared
    // `CoreBreakpointToTier.toTier()` self-conversion — so neither platform
    // re-implements the boundary math. Exercising the exact
    // width→breakpoint→tier pipeline that both resolvers run therefore
    // proves the two platforms can never silently diverge on "same width
    // in, same tier out" (this Story's completion criterion), without
    // needing a real browser viewport.
    CoreBreakpointTier tierFor(double width) =>
        CoreBreakpoint.forWidth(width).toTier();

    test('mobile tier below the tablet boundary (md = 768)', () {
      expect(tierFor(0), CoreBreakpointTier.mobile);
      expect(tierFor(639), CoreBreakpointTier.mobile);
      expect(tierFor(767), CoreBreakpointTier.mobile);
    });

    test('tablet tier from the tablet boundary up to the desktop one', () {
      expect(tierFor(768), CoreBreakpointTier.tablet);
      expect(tierFor(1023), CoreBreakpointTier.tablet);
    });

    test('desktop tier at and above the desktop boundary (lg = 1024)', () {
      expect(tierFor(1024), CoreBreakpointTier.desktop);
      expect(tierFor(1280), CoreBreakpointTier.desktop);
      expect(tierFor(1920), CoreBreakpointTier.desktop);
    });

    test(
      'defaultBoundaries matches the confirmed Q1 value '
      '(mobile=xs, tablet=md, desktop=lg)',
      () {
        expect(CoreBreakpointContract.defaultBoundaries, const {
          CoreBreakpointTier.mobile: CoreBreakpoint.xs,
          CoreBreakpointTier.tablet: CoreBreakpoint.md,
          CoreBreakpointTier.desktop: CoreBreakpoint.lg,
        });
      },
    );
  });

  group('resolveBreakpoint (SSR-safe one-shot observation)', () {
    testComponents(
      'resolves a deterministic mobile tier when no browser viewport is '
      'attached (VM/SSR fallback — width observes as 0)',
      (tester) async {
        late ResolvedBreakpoint resolved;
        tester.pumpComponent(
          Builder(
            builder: (context) {
              resolved = resolveBreakpoint(context);
              return Component.text('ok');
            },
          ),
        );

        expect(resolved.width, 0);
        expect(resolved.breakpoint, CoreBreakpoint.xs);
        expect(resolved.tier, CoreBreakpointTier.mobile);
      },
    );

    testComponents(
      'boundaries override reaches the shared toTier() self-conversion',
      (tester) async {
        late ResolvedBreakpoint resolved;
        tester.pumpComponent(
          Builder(
            builder: (context) {
              // Even though the observed width is stuck at 0 in this
              // non-browser test environment, moving the desktop
              // threshold down to `CoreBreakpoint.xs` (0) forces
              // `toTier()` to classify width 0 as desktop — proving the
              // `boundaries` parameter is actually wired through to the
              // Core self-conversion rather than ignored.
              // This partial map (mirrors the coui_core toTier() partial-map
              // test) intentionally omits mobile/tablet — they fall back to
              // CoreBreakpointContract.defaultBoundaries.
              resolved = resolveBreakpoint(
                context,
                // partial map under test
                boundaries: const {.desktop: .xs},
              );
              return Component.text('ok');
            },
          ),
        );

        expect(resolved.tier, CoreBreakpointTier.desktop);
      },
    );
  });

  group('Breakpoint / BuildContext extension wiring', () {
    testComponents(
      'Breakpoint(context) and the BuildContext extension agree with '
      'resolveBreakpoint(context)',
      (tester) async {
        late Breakpoint breakpointAccessor;
        late BuildContext capturedContext;
        tester.pumpComponent(
          Builder(
            builder: (context) {
              capturedContext = context;
              breakpointAccessor = Breakpoint(context);
              return Component.text('ok');
            },
          ),
        );

        final resolved = resolveBreakpoint(capturedContext);

        expect(breakpointAccessor.width, resolved.width);
        expect(breakpointAccessor.coreBreakpoint, resolved.breakpoint);
        expect(breakpointAccessor.tier, resolved.tier);

        expect(capturedContext.breakpointTier, resolved.tier);
        expect(capturedContext.coreBreakpoint, resolved.breakpoint);
        expect(capturedContext.isMobile, resolved.tier == .mobile);
        expect(capturedContext.isTablet, resolved.tier == .tablet);
        expect(capturedContext.isDesktop, resolved.tier == .desktop);
      },
    );

    testComponents(
      'exactly one of isMobile/isTablet/isDesktop is true',
      (tester) async {
        late BuildContext capturedContext;
        tester.pumpComponent(
          Builder(
            builder: (context) {
              capturedContext = context;
              return Component.text('ok');
            },
          ),
        );

        final flags = [
          capturedContext.isMobile,
          capturedContext.isTablet,
          capturedContext.isDesktop,
        ];
        expect(flags.where((f) => f).length, 1);
      },
    );
  });

  group('BDD Feature 6: NG7 negative assertion', () {
    test(
      'coui_web breakpoint.dart exposes no generic value-branching API '
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
