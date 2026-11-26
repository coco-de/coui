// The viewport tier of the type scale — display and headline step down below
// desktop, every other role keeps one size.
//
// Three readers draw the tiers — Flutter's theme, Web's stylesheet and the
// Figma token export — so the numbers they must all produce live in one
// hand-written fixture each of them reads. This file pins the Core seat to
// that fixture and to the rules `CoreTypography.atTier` states: desktop is the
// scale itself, a step is a ratio, and tracking is read again at the stepped
// size.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter, Web and export tests.
const String kTypographyTierVectorsPath =
    'test/fixtures/typography_tier_vectors.json';

CoreTextStyleToken _tokenNamed(String name) =>
    CoreTextStyles.values.singleWhere((token) => token.name == name);

void main() {
  final doc =
      jsonDecode(File(kTypographyTierVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final roles = (doc['roles']! as List).cast<Map<String, Object?>>();
  final widths = (doc['widths']! as List).cast<Map<String, Object?>>();

  const coui = CoreTypography.coui;
  const belowDesktop = [CoreBreakpointTier.mobile, CoreBreakpointTier.tablet];

  group('vectors', () {
    test('name every heading role and a role that stays flat', () {
      final named = {
        for (final row in roles) _tokenNamed(row['role']! as String),
      };
      expect(named, containsAll(CoreTypography.headingRoles));
      expect(named.difference(CoreTypography.headingRoles.toSet()), isNotEmpty);
    });

    for (final row in roles) {
      final token = _tokenNamed(row['role']! as String);
      for (final tier in CoreBreakpointTier.values) {
        final want = row[tier.name]! as Map<String, Object?>;
        final size = (want['size']! as num).toDouble();
        final tracking = (want['trackingEm']! as num).toDouble();
        test('${token.name} at ${tier.name} is $size / $tracking', () {
          final style = token.read(coui.atTier(tier));
          expect(style.fontSize, size);
          expect(style.letterSpacing, tracking);
        });
      }
    }

    // The table the tier reads is the fixture's numbers — checked apart from
    // `atTier` so a table and a ratio that drift together still fail here.
    test('CoreHeadingSizes.couiByTier states the heading rows', () {
      for (final row in roles) {
        final token = _tokenNamed(row['role']! as String);
        if (!CoreTypography.headingRoles.contains(token)) continue;
        for (final tier in belowDesktop) {
          final want = row[tier.name]! as Map<String, Object?>;
          expect(
            CoreHeadingSizes.couiByTier[tier]!.sizeOf(token),
            (want['size']! as num).toDouble(),
            reason: '${token.name} ${tier.name}',
          );
        }
      }
    });

    for (final row in widths) {
      final width = (row['width']! as num).toDouble();
      final tier = CoreBreakpointTier.values.byName(row['tier']! as String);
      test('a ${width}px viewport is ${tier.name}', () {
        expect(CoreBreakpoint.forWidth(width).toTier(), tier);
      });
    }
  });

  group('desktop is the scale as authored', () {
    test('and comes back as the same instance', () {
      expect(identical(coui.atTier(.desktop), coui), isTrue);
      final product = coui.withFamily('Display');
      expect(identical(product.atTier(.desktop), product), isTrue);
    });

    test('so it has no row in the table', () {
      expect(CoreHeadingSizes.couiByTier.keys, belowDesktop);
    });
  });

  group('below desktop', () {
    test('only the heading roles move', () {
      for (final tier in belowDesktop) {
        final stepped = coui.atTier(tier);
        for (final token in CoreTextStyles.values) {
          final heading = CoreTypography.headingRoles.contains(token);
          expect(
            identical(token.read(stepped), token.read(coui)),
            !heading,
            reason: '${token.name} ${tier.name}',
          );
          if (heading) {
            expect(
              token.read(stepped).fontSize,
              lessThan(token.read(coui).fontSize!),
              reason: '${token.name} ${tier.name}',
            );
          }
        }
      }
    });

    test('weight, leading and family stay the role’s', () {
      final stepped = coui.withFamily('Display').atTier(.mobile);
      for (final token in CoreTypography.headingRoles) {
        final style = token.read(stepped);
        final authored = token.read(coui);
        expect(style.fontFamily, 'Display', reason: token.name);
        expect(style.fontWeight, authored.fontWeight, reason: token.name);
        expect(style.lineHeight, authored.lineHeight, reason: token.name);
      }
    });
  });

  // A size stated outright would erase whatever multiplied the scale before
  // the tier — Flutter folds the theme's text scaling into its typography
  // first — and a product's own heading sizes. A ratio keeps both.
  group('a step is a ratio', () {
    for (final factor in const [1.25, 1.1]) {
      test('it commutes with a ${factor}x scale', () {
        for (final tier in belowDesktop) {
          expect(
            coui.scale(factor).atTier(tier),
            coui.atTier(tier).scale(factor),
            reason: tier.name,
          );
        }
      });
    }

    test('a scaled headline stays scaled', () {
      expect(coui.scale(1.25).atTier(.mobile).headlineSmall.fontSize, 20);
    });

    test("a product's own heading size moves by CoUI's ratio", () {
      final product = coui.copyWith(
        displayLarge: coui.displayLarge.copyWith(fontSize: 60),
      );
      expect(product.atTier(.mobile).displayLarge.fontSize, 60 / 52 * 36);
    });

    test('a fixed line box moves with its glyphs', () {
      final boxed = coui.copyWith(
        headlineSmall: coui.headlineSmall.copyWith(lineHeightPx: 32),
      );
      final stepped = boxed.atTier(.mobile).headlineSmall;
      expect(stepped.fontSize, 16);
      expect(stepped.lineHeightPx, 32 / 24 * 16);
    });

    test('a role that states no size is left alone', () {
      const unsized = CoreTextStyle(fontWeight: CoreFontWeight.bold);
      final stepped = coui.copyWith(displayLarge: unsized).atTier(.mobile);
      expect(stepped.displayLarge, unsized);
    });
  });

  // A part of a page held to another tier steps from the tier it is drawn
  // at, not from the authored scale — a scale already at mobile has to step
  // up to reach desktop.
  group('a scale drawn at a tier steps from there', () {
    test('to every tier, landing on that tier of the authored scale', () {
      for (final from in CoreBreakpointTier.values) {
        for (final tier in CoreBreakpointTier.values) {
          expect(
            coui.atTier(from).atTier(tier, from: from),
            coui.atTier(tier),
            reason: '${from.name} → ${tier.name}',
          );
        }
      }
    });

    test('keeps a multiplier and a face it did not set', () {
      final drawn = coui.scale(1.25).withFamily('Brand Display');
      final stepped = drawn.atTier(.mobile).atTier(.desktop, from: .mobile);
      expect(stepped, drawn);
      expect(stepped.headlineLarge.fontFamily, 'Brand Display');
    });

    test('reads tracking again at the tier it reaches', () {
      // Mobile's 16px headline is on −1%; back at desktop's 24px it is on
      // −2% again.
      final rule = CoreTrackingRule.coui;
      final back = coui
          .atTier(.mobile)
          .atTier(.desktop, from: .mobile)
          .headlineSmall;
      expect(back.letterSpacing, rule.atSize(24));
    });

    test('to the tier it is at, it is the same instance', () {
      final mobile = coui.atTier(.mobile);
      expect(identical(mobile.atTier(.mobile, from: .mobile), mobile), isTrue);
    });
  });

  group('tracking', () {
    test(
      'is read again at the stepped size where the role follows the rule',
      () {
        final rule = CoreTrackingRule.coui;
        expect(rule.atSize(24), isNot(rule.atSize(16)));
        expect(
          coui.atTier(.mobile).headlineSmall.letterSpacing,
          rule.atSize(16),
        );
        // Chosen by the table's size, not the scaled one: 1.25x puts the
        // mobile headline at 20px, but it is the 16px rung of the table.
        expect(
          coui.scale(1.25).atTier(.mobile).headlineSmall.letterSpacing,
          rule.atSize(16),
        );
      },
    );

    test('a role that states its own keeps it', () {
      final product = coui.copyWith(
        headlineSmall: coui.headlineSmall.copyWith(letterSpacing: -0.03),
      );
      expect(product.atTier(.mobile).headlineSmall.letterSpacing, -0.03);
    });

    test('a monospace heading keeps its own', () {
      final mono = coui.withFamily(CoreFontFamily.mono).atTier(.mobile);
      expect(
        mono.headlineSmall.letterSpacing,
        coui.headlineSmall.letterSpacing,
      );
    });

    // couiV1's curve tracks display and the larger headlines tighter than the
    // two-step rule, so they keep it; its 24px headline happens to state the
    // rule's own step at 24, so it follows the rule to 16.
    test('couiV1 keeps the curve it states', () {
      const v1 = CoreTypography.couiV1;
      final stepped = v1.atTier(.mobile);
      expect(stepped.displayLarge.fontSize, 36);
      expect(stepped.displayLarge.letterSpacing, CoreLetterSpacing.tight);
      expect(stepped.headlineLarge.letterSpacing, CoreLetterSpacing.tight);
      expect(stepped.headlineLarge.fontWeight, CoreFontWeight.semiBold);
      expect(
        stepped.headlineSmall.letterSpacing,
        CoreTrackingRule.coui.atSize(16),
      );
    });
  });

  group('CoreHeadingSizes', () {
    test('sizes the heading roles only', () {
      final mobile = CoreHeadingSizes.couiByTier[CoreBreakpointTier.mobile]!;
      for (final token in CoreTextStyles.values) {
        if (CoreTypography.headingRoles.contains(token)) {
          expect(mobile.sizeOf(token), isPositive, reason: token.name);
        } else {
          expect(
            () => mobile.sizeOf(token),
            throwsArgumentError,
            reason: token.name,
          );
        }
      }
    });

    test('equality + hashCode', () {
      const a = CoreHeadingSizes(
        displayLarge: 36,
        displayMedium: 32,
        displaySmall: 28,
        headlineLarge: 24,
        headlineMedium: 20,
        headlineSmall: 16,
      );
      final mobile = CoreHeadingSizes.couiByTier[CoreBreakpointTier.mobile]!;
      expect(a, mobile);
      expect(a.hashCode, mobile.hashCode);
      expect(a, isNot(CoreHeadingSizes.couiByTier[CoreBreakpointTier.tablet]));
    });
  });

  // A tier hands the frameworks a new scale on every build that derives one;
  // they rebuild — and animate — only when it is unequal to the last. Identity
  // would restart the theme animation every time; a role missing from `==`
  // would never reach the screen.
  group('CoreTypography equality', () {
    test('two steps of one scale are equal', () {
      final a = coui.atTier(.mobile);
      final b = coui.atTier(.mobile);
      expect(identical(a, b), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(coui.copyWith(), coui);
      expect(coui.copyWith().hashCode, coui.hashCode);
    });

    test('a stepped scale is not the authored one', () {
      expect(coui.atTier(.mobile), isNot(coui));
      expect(coui.atTier(.mobile), isNot(coui.atTier(.tablet)));
    });

    test('every role takes part', () {
      for (final token in CoreTextStyles.values) {
        expect(
          coui.withFamily('X', roles: [token]),
          isNot(coui),
          reason: token.name,
        );
      }
    });
  });

  group('CoreTrackingRule', () {
    test('coui is −2% from 20px and −1% below', () {
      final rule = CoreTrackingRule.coui;
      expect(rule.from, 20);
      expect(rule.above, CoreLetterSpacing.tight20);
      expect(rule.below, CoreLetterSpacing.tight10);
      expect(rule.atSize(19.5), CoreLetterSpacing.tight10);
      expect(rule.atSize(20), CoreLetterSpacing.tight20);
    });

    test('a monospace role keeps its own at every size', () {
      final rule = CoreTrackingRule.coui;
      expect(rule.forRole(coui.codeSm, 40), CoreLetterSpacing.normal);
      expect(rule.forRole(coui.bodyMedium, 40), CoreLetterSpacing.tight20);
    });

    test('refuses a table that is not two steps', () {
      expect(
        () => CoreTrackingRule.read(const [
          CoreTextStyle(fontSize: 24, letterSpacing: -0.02),
          CoreTextStyle(fontSize: 16, letterSpacing: -0.01),
          CoreTextStyle(fontSize: 12, letterSpacing: 0),
        ]),
        throwsFormatException,
      );
    });

    test('refuses two steps that are not split by size', () {
      expect(
        () => CoreTrackingRule.read(const [
          CoreTextStyle(fontSize: 24, letterSpacing: -0.02),
          CoreTextStyle(fontSize: 28, letterSpacing: -0.01),
        ]),
        throwsFormatException,
      );
    });

    test('refuses a sans role with no size or no tracking', () {
      expect(
        () => CoreTrackingRule.read(const [CoreTextStyle(fontSize: 24)]),
        throwsFormatException,
      );
    });
  });
}
