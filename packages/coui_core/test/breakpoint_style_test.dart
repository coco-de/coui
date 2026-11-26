// Tests for CoreBreakpointStyle / CoreBreakpointTheme / CoreBreakpointTier.
//
// The groups tagged `BDD Feature N` below implement scenarios from
// `docs/bdd-responsive-breakpoints.md` that are pure width/tier logic (no
// BuildContext needed) and therefore belong at the coui_core level — see
// that doc + `docs/flow-permutation-responsive-breakpoints.md` for the
// full Gherkin scenarios these mirror.

import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreBreakpointStyle', () {
    test('merge always returns this (no fields)', () {
      const style = CoreBreakpointStyle();
      expect(style.merge(const CoreBreakpointStyle()), same(style));
      expect(style.merge(null), same(style));
    });

    test('equality + hashCode', () {
      const a = CoreBreakpointStyle();
      const b = CoreBreakpointStyle();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreBreakpointTheme', () {
    test('copyWith replaces style', () {
      const theme = CoreBreakpointTheme();
      final withStyle = theme.copyWith(style: const CoreBreakpointStyle());
      expect(withStyle.style, const CoreBreakpointStyle());
    });

    test('equality + hashCode', () {
      const a = CoreBreakpointTheme(style: CoreBreakpointStyle());
      const b = CoreBreakpointTheme(style: CoreBreakpointStyle());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreBreakpoint.forWidth', () {
    // Every breakpoint starts at its own minWidth and the one below it holds
    // up to just under that — the `>=` both platforms' resolvers and the
    // typography tier read. A width past the widest breakpoint stays on it.
    test('each breakpoint starts at its minWidth', () {
      const breakpoints = CoreBreakpoint.values;
      for (var i = 0; i < breakpoints.length; i++) {
        final breakpoint = breakpoints[i];
        expect(CoreBreakpoint.forWidth(breakpoint.minWidth), breakpoint);
        if (i > 0) {
          expect(
            CoreBreakpoint.forWidth(breakpoint.minWidth - 0.5),
            breakpoints[i - 1],
          );
        }
      }
      expect(CoreBreakpoint.forWidth(10000), CoreBreakpoint.xxl);
    });
  });

  group('CoreBreakpointContract.defaultBoundaries', () {
    test('matches Q1 confirmed values', () {
      expect(
        CoreBreakpointContract.defaultBoundaries[CoreBreakpointTier.mobile],
        CoreBreakpoint.xs,
      );
      expect(
        CoreBreakpointContract.defaultBoundaries[CoreBreakpointTier.tablet],
        CoreBreakpoint.md,
      );
      expect(
        CoreBreakpointContract.defaultBoundaries[CoreBreakpointTier.desktop],
        CoreBreakpoint.lg,
      );
    });
  });

  group('CoreBreakpointToTier.toTier', () {
    test('below tablet boundary resolves to mobile', () {
      expect(CoreBreakpoint.xs.toTier(), CoreBreakpointTier.mobile);
      expect(CoreBreakpoint.sm.toTier(), CoreBreakpointTier.mobile);
    });

    test(
      'at or above tablet boundary but below desktop resolves to tablet',
      () {
        expect(CoreBreakpoint.md.toTier(), CoreBreakpointTier.tablet);
      },
    );

    test('at or above desktop boundary resolves to desktop', () {
      expect(CoreBreakpoint.lg.toTier(), CoreBreakpointTier.desktop);
      expect(CoreBreakpoint.xl.toTier(), CoreBreakpointTier.desktop);
      expect(CoreBreakpoint.xxl.toTier(), CoreBreakpointTier.desktop);
    });

    test(
      'partial boundaries override only the given tier, others fall back',
      () {
        // Only override desktop's threshold to xl — mobile/tablet keep
        // defaults.
        // partial map under test
        final boundaries = {CoreBreakpointTier.desktop: CoreBreakpoint.xl};

        // md (768) is still >= default tablet boundary (768) => tablet.
        expect(
          CoreBreakpoint.md.toTier(boundaries: boundaries),
          CoreBreakpointTier.tablet,
        );
        // lg (1024) no longer clears the overridden desktop boundary
        // (1280), and falls back to tablet since it still clears that
        // boundary.
        expect(
          CoreBreakpoint.lg.toTier(boundaries: boundaries),
          CoreBreakpointTier.tablet,
        );
        // xl (1280) clears the overridden desktop boundary.
        expect(
          CoreBreakpoint.xl.toTier(boundaries: boundaries),
          CoreBreakpointTier.desktop,
        );
      },
    );
  });

  group('CoreBreakpointTierOrder.isAtLeast', () {
    // `ResponsiveRowColumn` (Story G) shares this single ordinal
    // comparison between its Flutter and Web resolvers instead of each
    // re-deriving `.index >=` locally — this group is the coui_core-level
    // guarantee that both platforms can never diverge on "has the
    // viewport reached this tier or wider". Table-driven over every
    // (tier, other) pair so the `mobile < tablet < desktop` ordering is
    // exhaustively covered, including the reflexive `tier.isAtLeast(tier)`
    // case.
    // The explicit type argument below is required, not inferrable: the
    // dot-shorthand elements (`.mobile` etc.) need the record type as
    // context, which a bare `const cases = [...]` cannot provide.
    const cases = <(CoreBreakpointTier, CoreBreakpointTier, bool)>[
      (.mobile, .mobile, true),
      (.mobile, .tablet, false),
      (.mobile, .desktop, false),
      (.tablet, .mobile, true),
      (.tablet, .tablet, true),
      (.tablet, .desktop, false),
      (.desktop, .mobile, true),
      (.desktop, .tablet, true),
      (.desktop, .desktop, true),
    ];

    for (final (tier, other, expected) in cases) {
      test('${tier.name}.isAtLeast(${other.name}) == $expected', () {
        expect(tier.isAtLeast(other), expected);
      });
    }
  });

  group('BDD Feature 1: tier stores no independent pixel value', () {
    test(
      'CoreBreakpointTier definition file has no breakpoint px literal '
      'outside comments, and toTier() is a pure mapping to CoreBreakpoint '
      'members',
      () {
        final source = File(
          'lib/src/component/contracts/breakpoint/breakpoint_tier.dart',
        ).readAsStringSync();

        // Strip both `///` doc comments and plain `//` comments before
        // checking for numeric literals — the scenario's intent is "no px
        // value in the *executable code*", and an explanatory `//` note
        // mentioning a number (e.g. "compile-time 3-entry literal") is not
        // a breakpoint value either.
        final codeOnly = source
            .split('\n')
            .where((line) => !line.trim().startsWith('//'))
            .join('\n');

        expect(RegExp(r'\d').hasMatch(codeOnly), isFalse);

        // toTier() delegates to CoreBreakpoint members' `.minWidth` and
        // CoreBreakpointContract's single boundary source — it is a pure
        // mapping function, not an independent threshold table.
        expect(codeOnly, contains('CoreBreakpointContract.defaultBoundaries'));
        expect(codeOnly, contains('.minWidth'));
      },
    );
  });

  group(
    'BDD Feature 2: cross-platform parity is structural, not '
    'per-platform value duplication',
    () {
      // Flutter's `resolveBreakpoint` (coui_flutter) and Web's
      // `resolveBreakpoint` (coui_web) each observe the global viewport
      // width through their own platform-native mechanism
      // (`MediaQuery.sizeOf` vs `viewportSize()`), then both hand that
      // width to the single `CoreBreakpoint.forWidth` lookup and its
      // breakpoint to the single `CoreBreakpointToTier.toTier()`
      // self-conversion, both defined here in coui_core. Parity therefore
      // does not need to be re-verified value-by-value on each platform; it
      // is a structural consequence of both resolvers delegating to these
      // two functions —
      // `packages/coui_flutter/test/.../breakpoint_test.dart` and
      // `packages/coui_web/test/.../breakpoint_test.dart` each separately
      // exercise their own platform's *observation* mechanism, not this
      // shared judgement.
      test(
        'the shared width -> CoreBreakpoint -> CoreBreakpointTier pipeline '
        'both platforms delegate to produces the Q1 confirmed matrix',
        () {
          const cases = [
            (0.0, CoreBreakpointTier.mobile),
            (639.0, CoreBreakpointTier.mobile),
            (640.0, CoreBreakpointTier.mobile),
            (767.0, CoreBreakpointTier.mobile),
            (768.0, CoreBreakpointTier.tablet),
            (1023.0, CoreBreakpointTier.tablet),
            (1024.0, CoreBreakpointTier.desktop),
            (1536.0, CoreBreakpointTier.desktop),
            (3000.0, CoreBreakpointTier.desktop),
          ];

          for (final (width, expectedTier) in cases) {
            expect(CoreBreakpoint.forWidth(width).toTier(), expectedTier);
          }
        },
      );
    },
  );

  group('BDD Feature 3: boundaries override — empty map and dual override', () {
    test(
      'empty boundaries override map falls back entirely to '
      'defaultBoundaries (OV-3′ — identical to no override at all)',
      () {
        const empty = <CoreBreakpointTier, CoreBreakpoint>{};

        expect(
          CoreBreakpoint.xs.toTier(boundaries: empty),
          CoreBreakpoint.xs.toTier(),
        );
        expect(
          CoreBreakpoint.md.toTier(boundaries: empty),
          CoreBreakpoint.md.toTier(),
        );
        expect(
          CoreBreakpoint.lg.toTier(boundaries: empty),
          CoreBreakpoint.lg.toTier(),
        );

        // width=1024 (lg) with an empty map still resolves to desktop
        // with no crash, per the BDD scenario.
        expect(
          CoreBreakpoint.lg.toTier(boundaries: empty),
          CoreBreakpointTier.desktop,
        );
      },
    );

    test(
      'overriding two tiers simultaneously (tablet+desktop) leaves the '
      'remaining tier (mobile) at its default',
      () {
        // partial map under test
        const boundaries = {
          CoreBreakpointTier.tablet: CoreBreakpoint.sm,
          CoreBreakpointTier.desktop: CoreBreakpoint.xxl,
        };

        // width=700 maps to sm (640) — the resolver's width lookup, not
        // toTier() itself.
        final breakpoint = CoreBreakpoint.forWidth(700);
        expect(breakpoint, CoreBreakpoint.sm);

        // sm (640) clears the overridden tablet boundary (640, inclusive)
        // but is nowhere near the overridden desktop boundary (xxl=1536)
        // => tablet, matching the BDD scenario's expectation.
        expect(
          breakpoint.toTier(boundaries: boundaries),
          CoreBreakpointTier.tablet,
        );
      },
    );
  });

  group(
    'BDD Feature 5 (GAP-5): largerThan(TABLET) vs isDesktop regression '
    'window (801~1023px)',
    () {
      // Old responsive_framework semantics under the trigger app-shell's
      // registered breakpoints (MOBILE 0-450/TABLET 451-800/DESKTOP
      // 801-1920): `.largerThan(TABLET)` is exactly "width >= 801".
      // Expressed as a literal boolean since `responsive_framework` is
      // not (and must not become) a coui dependency.
      const cases = [
        (800.0, false, false),
        (801.0, true, false),
        (1023.0, true, false),
        (1024.0, true, true),
      ];

      for (final (width, oldVerdict, newVerdict) in cases) {
        test(
          'width=$width -> old(largerThan(TABLET))=$oldVerdict, '
          'new(isDesktop)=$newVerdict',
          () {
            final computedOldVerdict = width >= 801;
            final computedNewVerdict =
                CoreBreakpoint.forWidth(width).toTier() == .desktop;

            expect(computedOldVerdict, oldVerdict);
            expect(computedNewVerdict, newVerdict);
          },
        );
      }
    },
  );

  group(
    'BDD Feature 5 (GAP-5): raw MediaQuery Constant(480/800) vs '
    'defaultBoundaries(768/1024) regression windows (480~767px, '
    '800~1023px)',
    () {
      CoreBreakpointTier oldConstantTier(double width) {
        if (width >= 800) return .desktop;
        if (width >= 480) return .tablet;
        return .mobile;
      }

      const cases = [
        (0.0, CoreBreakpointTier.mobile, CoreBreakpointTier.mobile),
        (479.0, CoreBreakpointTier.mobile, CoreBreakpointTier.mobile),
        (480.0, CoreBreakpointTier.tablet, CoreBreakpointTier.mobile),
        (767.0, CoreBreakpointTier.tablet, CoreBreakpointTier.mobile),
        (768.0, CoreBreakpointTier.tablet, CoreBreakpointTier.tablet),
        (799.0, CoreBreakpointTier.tablet, CoreBreakpointTier.tablet),
        (800.0, CoreBreakpointTier.desktop, CoreBreakpointTier.tablet),
        (1023.0, CoreBreakpointTier.desktop, CoreBreakpointTier.tablet),
        (1024.0, CoreBreakpointTier.desktop, CoreBreakpointTier.desktop),
      ];

      for (final (width, oldTier, newTier) in cases) {
        test(
          'width=$width -> old(Constant 480/800)=${oldTier.name}, '
          'new(defaultBoundaries)=${newTier.name}',
          () {
            expect(oldConstantTier(width), oldTier);
            expect(CoreBreakpoint.forWidth(width).toTier(), newTier);
          },
        );
      }
    },
  );

  group('BDD Feature 6: NG7 negative assertion', () {
    test(
      'CoreBreakpointContract source exposes no generic value-branching '
      'API (context.responsive<T> does not exist)',
      () {
        final source = File(
          'lib/src/component/contracts/breakpoint/breakpoint_contract.dart',
        ).readAsStringSync();

        expect(RegExp(r'\bresponsive\s*<').hasMatch(source), isFalse);
      },
    );
  });
}
