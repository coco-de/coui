// The typography tier on Web — the rules that step the display and headline
// roles down with the viewport, and the ones a pin switches, read back from
// the stylesheet the theme emits.
//
// The numbers come from the table `coui_core` owns
// (`typography_tier_vectors.json`), the one the Core seat and the Flutter
// render tests read too, so a tier that drifts here fails against the same
// sizes the other platform draws. What the browser makes of these rules — the
// computed size at a given viewport width — is the Chrome probe's to read
// (`tool/parity/test/web/typography_tier_probe_test.dart`).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// The shared table, read from `coui_core` rather than copied here.
const String _kVectorsPath =
    '../coui_core/test/fixtures/typography_tier_vectors.json';

/// The attribute a pin writes — spelled out rather than read from
/// `kTypographyTierAttribute`, so the test is a second source for it.
const String _kAttribute = 'data-coui-typography-tier';

/// What one role draws at one tier: its size in px and tracking in em.
typedef _Drawn = ({double size, double trackingEm});

/// One rule: the `@media` it sits in (or null), its selector, its
/// declarations in order.
typedef _Rule = ({String? media, String selector, Map<String, String> body});

/// Every rule in [css], one `@media` level deep — all these blocks use.
List<_Rule> _rules(String css, {String? media}) {
  final rules = <_Rule>[];
  var i = 0;
  while (i < css.length) {
    final open = css.indexOf('{', i);
    if (open < 0) break;
    final selector = css.substring(i, open).trim();
    var depth = 1;
    var j = open + 1;
    for (; j < css.length && depth > 0; j++) {
      if (css[j] == '{') depth++;
      if (css[j] == '}') depth--;
    }
    final inner = css.substring(open + 1, j - 1);
    if (selector.startsWith('@')) {
      rules.addAll(_rules(inner, media: selector));
    } else if (selector.isNotEmpty) {
      rules.add((
        media: media,
        selector: selector,
        body: {
          for (final declaration in inner.split(';'))
            if (declaration.contains(':'))
              declaration.substring(0, declaration.indexOf(':')).trim():
                  declaration.substring(declaration.indexOf(':') + 1).trim(),
        },
      ));
    }
    i = j;
  }

  return rules;
}

/// [selector] split at its top-level commas — not the ones inside a
/// `:not(…)` list.
List<String> _selectors(String selector) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < selector.length; i++) {
    final char = selector[i];
    if (char == '(') depth++;
    if (char == ')') depth--;
    if (char == ',' && depth == 0) {
      parts.add(selector.substring(start, i));
      start = i + 1;
    }
  }

  return [...parts, selector.substring(start)];
}

/// Class-column specificity — attributes and pseudo-classes, which is all
/// these selectors use. `:not(…)` counts its most specific argument, as CSS
/// does.
int _specificity(String selector) {
  int count(String part) =>
      RegExp(r'\[[^\]]+\]|:[a-z-]+').allMatches(part).length;
  var negated = 0;
  final rest = selector.replaceAllMapped(RegExp(r':not\(([^()]*)\)'), (m) {
    negated += _selectors(m[1]!).map(count).reduce(math.max);

    return '';
  });

  return negated + count(rest);
}

/// `'2.25rem'` → 36 (px at the 16px root font size).
double _px(String rem) {
  expect(rem, endsWith('rem'));

  return double.parse(rem.substring(0, rem.length - 3)) * 16;
}

/// `'-0.01em'` → -0.01.
double _em(String em) {
  expect(em, endsWith('em'));

  return double.parse(em.substring(0, em.length - 2));
}

void main() {
  final vectors =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, dynamic>;
  final roles = {
    for (final row in (vectors['roles'] as List).cast<Map<String, dynamic>>())
      row['role'] as String: {
        for (final tier in CoreBreakpointTier.values)
          tier: (
            size: ((row[tier.name] as Map)['size'] as num).toDouble(),
            trackingEm: ((row[tier.name] as Map)['trackingEm'] as num)
                .toDouble(),
          ),
      },
  };
  final widths = (vectors['widths'] as List).cast<Map<String, dynamic>>();

  /// The first width the table puts in [tier] — the tier's boundary.
  int firstWidthOf(CoreBreakpointTier tier) => widths
      .where((row) => row['tier'] == tier.name)
      .map((row) => row['width'] as int)
      .reduce(math.min);

  /// Whether a role's [of] differs between tiers.
  bool steps(
    Map<CoreBreakpointTier, _Drawn> drawn,
    double Function(_Drawn) of,
  ) => drawn.values.map(of).toSet().length > 1;

  final steppedRoles = {
    for (final MapEntry(:key, :value) in roles.entries)
      if (steps(value, (d) => d.size)) key: value,
  };
  final flatRoles = roles.keys.where((role) => !steppedRoles.containsKey(role));

  /// Every variable the tier moves under CoUI's scale, by the table: the
  /// size of each role whose size steps, the tracking of each whose tracking
  /// does.
  final movedVariables = {
    for (final MapEntry(:key, :value) in roles.entries) ...[
      if (steps(value, (d) => d.size)) '--coui-text-$key-size',
      if (steps(value, (d) => d.trackingEm)) '--coui-text-$key-tracking',
    ],
  };

  /// Checks that [body] states what the table says the roles draw at [tier].
  void expectDrawnAt(Map<String, String> body, CoreBreakpointTier tier) {
    for (final MapEntry(:key, :value) in steppedRoles.entries) {
      final size = body['--coui-text-$key-size'];
      expect(size, isNotNull, reason: '$key size at ${tier.name}');
      expect(_px(size!), value[tier]!.size, reason: '$key at ${tier.name}');
      final tracking = body['--coui-text-$key-tracking'];
      if (tracking != null) {
        expect(
          _em(tracking),
          closeTo(value[tier]!.trackingEm, 1e-12),
          reason: '$key tracking at ${tier.name}',
        );
      }
    }
  }

  String pinSelector(CoreBreakpointTier tier) =>
      ':root[$_kAttribute="${tier.name}"],'
      '[$_kAttribute="${tier.name}"]:not(:root)';

  /// A root whose attribute names no tier — none at all, or the value
  /// `CoUIWeb` writes when it lifts a pin it set.
  const unpinned =
      ':root:not([$_kAttribute="mobile"],[$_kAttribute="tablet"],'
      '[$_kAttribute="desktop"])';

  group('the viewport chooses the tier', () {
    final rules = _rules(ThemeConfig.defaults().typographyTierBlocks);
    final mediaRules = rules.where((rule) => rule.media != null).toList();
    final viewportRules = mediaRules
        .where((rule) => rule.media!.startsWith('@media not all'))
        .toList();

    test('one rule below each boundary, then print, on an unpinned root', () {
      expect(
        mediaRules.map((rule) => rule.media),
        [
          '@media not all and (min-width:${firstWidthOf(.desktop)}px)',
          '@media not all and (min-width:${firstWidthOf(.tablet)}px)',
          '@media print',
        ],
        reason:
            'tablet first, mobile after it, print last — the three tie on '
            'specificity, so where several match the later one wins',
      );
      for (final rule in mediaRules) {
        expect(rule.selector, unpinned);
      }
    });

    test('print draws the scale as authored', () {
      // A printed page is laid out at the paper's width, which the viewport
      // queries match like a phone's.
      expectDrawnAt(mediaRules.last.body, .desktop);
    });

    test('below desktop the headings are the tablet sizes', () {
      expectDrawnAt(viewportRules[0].body, .tablet);
    });

    test('below tablet they are the mobile sizes, tracking included', () {
      expectDrawnAt(viewportRules[1].body, .mobile);
      // The one heading that crosses the tracking step: 16px tracks on −1%.
      expect(
        _em(viewportRules[1].body['--coui-text-headline-small-tracking']!),
        roles['headline-small']![CoreBreakpointTier.mobile]!.trackingEm,
      );
    });

    test('the boundaries are the ones the shared judgement uses', () {
      for (final row in widths) {
        expect(
          CoreBreakpoint.forWidth((row['width'] as int).toDouble()).toTier(),
          CoreBreakpointTier.values.byName(row['tier'] as String),
          reason: '${row['width']}px',
        );
      }
    });
  });

  group('a pin holds a page or a part of one to a tier', () {
    final rules = _rules(ThemeConfig.defaults().typographyTierBlocks);

    for (final tier in CoreBreakpointTier.values) {
      test('${tier.name} — on the root and on any element below it', () {
        final pin = rules.where((rule) => rule.selector == pinSelector(tier));
        expect(pin, hasLength(1));
        expect(pin.single.media, isNull);
        expectDrawnAt(pin.single.body, tier);
      });
    }
  });

  group('every rule states the same variables', () {
    final rules = _rules(ThemeConfig.defaults().typographyTierBlocks);

    test('the ones some tier moves — and nothing else', () {
      // Rules overlap (a phone matches both queries) and pins nest, so a
      // variable one rule left out would show the outer tier's value.
      for (final rule in rules) {
        expect(
          rule.body.keys.toSet(),
          movedVariables,
          reason: '${rule.media ?? ''} ${rule.selector}',
        );
      }
    });

    test('a role that keeps one size is never restated', () {
      for (final role in flatRoles) {
        for (final rule in rules) {
          expect(
            rule.body.keys.where((key) => key.startsWith('--coui-text-$role-')),
            isEmpty,
            reason: '$role in ${rule.selector}',
          );
        }
      }
    });
  });

  group('the rules outrank the role block', () {
    final css = ThemeConfig.defaults().cssVariables;
    final rules = _rules(ThemeConfig.defaults().typographyTierBlocks);

    test('every selector is (0,2,0), above :root', () {
      expect(_specificity(':root'), 1);
      for (final rule in rules) {
        for (final selector in _selectors(rule.selector)) {
          expect(_specificity(selector), 2, reason: selector);
        }
      }
    });

    test('they ship with the role variables, after them', () {
      final blocks = ThemeConfig.defaults().typographyTierBlocks;
      expect(css, contains(blocks));
      expect(
        css.indexOf(blocks),
        greaterThan(css.indexOf('--coui-text-display-large-size:')),
      );
    });

    test('the :root block itself stays the desktop scale', () {
      final root = _rules(css).firstWhere(
        (rule) =>
            rule.media == null &&
            rule.selector == ':root' &&
            rule.body.containsKey('--coui-text-display-large-size'),
      );
      for (final MapEntry(:key, :value) in roles.entries) {
        final desktop = value[CoreBreakpointTier.desktop]!;
        expect(
          _px(root.body['--coui-text-$key-size']!),
          desktop.size,
          reason: key,
        );
        expect(
          _em(root.body['--coui-text-$key-tracking']!),
          closeTo(desktop.trackingEm, 1e-12),
          reason: key,
        );
      }
    });
  });

  group("an app's own scale steps by the same ratio", () {
    test('a scale multiplied by 1.25 keeps the multiplier at every tier', () {
      const factor = 1.25;
      final rules = _rules(
        ThemeConfig.from(
          CouiColorPresets.source,
          typography: CoreTypography.coui.scale(factor),
        ).typographyTierBlocks,
      );
      for (final tier in CoreBreakpointTier.values) {
        final pin = rules.singleWhere((r) => r.selector == pinSelector(tier));
        for (final MapEntry(:key, :value) in steppedRoles.entries) {
          expect(
            _px(pin.body['--coui-text-$key-size']!),
            value[tier]!.size * factor,
            reason: '$key at ${tier.name}',
          );
        }
        // Tracking is read at the table's size, so the multiplier does not
        // move which step it lands on.
        expect(
          _em(pin.body['--coui-text-headline-small-tracking']!),
          roles['headline-small']![tier]!.trackingEm,
          reason: tier.name,
        );
      }
    });

    test('a role that states its own tracking keeps it at every tier', () {
      final own = CoreTypography.coui.copyWith(
        headlineSmall: CoreTypography.coui.headlineSmall.copyWith(
          letterSpacing: 0.05,
        ),
      );
      final rules = _rules(
        ThemeConfig.from(
          CouiColorPresets.source,
          typography: own,
        ).typographyTierBlocks,
      );
      expect(rules, isNotEmpty);
      for (final rule in rules) {
        expect(
          rule.body.containsKey('--coui-text-headline-small-tracking'),
          isFalse,
          reason: rule.selector,
        );
        expect(rule.body, contains('--coui-text-headline-small-size'));
      }
    });
  });
}
