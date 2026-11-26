// The stylesheet's half of adaptive quality — the rules a tier switches on.
//
// A governor's step on the Web writes one document attribute
// (`data-coui-quality`) and rebuilds nothing, so everything a tier does to a
// surface's CSS material has to already be in the sheet the page is served.
// The tier that goes without the backdrop pass owes exactly what the
// reduce-transparency preference owes — an opaque fill and no backdrop filter
// — and these tests hold the two to one statement: a rule per (style × role ×
// depth) the preference has one for, with the declarations it has.
//
// The bend is not CSS. It is something `SurfaceRefractionHost` adds to a
// surface in the browser, so withholding it is that host's, and the Chrome
// probe's (`tool/parity/test/web/adaptive_quality_probe_test.dart`).
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

const _kMedia = '@media (prefers-reduced-transparency:reduce)';

/// One rule: the `@media` it sits in (or null), its selector, its
/// declarations in order.
typedef _Rule = ({String? media, String selector, List<String> body});

/// Every rule in [css], one `@media` level deep — all this stylesheet uses.
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
    if (selector.startsWith('@media')) {
      rules.addAll(_rules(inner, media: selector));
    } else if (selector.isNotEmpty) {
      rules.add((
        media: media,
        selector: selector,
        body: [
          for (final declaration in inner.split(';'))
            if (declaration.contains(':')) declaration.trim(),
        ],
      ));
    }
    i = j;
  }

  return rules;
}

final String _sheet = ThemeConfig.defaults().surfaceStyleVariableBlocks;
final List<_Rule> _all = _rules(_sheet);

String _attr(CoreQualityTier tier) => '[data-coui-quality="${tier.name}"]';

/// Whether [rule] is about a panel that fades by its terms — the rules that
/// take it back to fading by its opacity — and not about the surface itself.
bool _isFade(_Rule rule) =>
    rule.selector.contains('.$kFadeBoxClass') ||
    rule.selector.contains('.$kFadePanelClass');

/// The tiers whose ladder step goes without [effect].
Set<CoreQualityTier> _withholding(CoreQualityEffect effect) => {
  for (final tier in CoreQualityLadder.standard.tiers)
    if (CoreQualityLadder.standard.withholds(tier, effect)) tier,
};

void main() {
  final preference = _all.where((rule) => rule.media == _kMedia).toList();
  final tiered = _all
      .where((rule) => rule.selector.contains('data-coui-quality'))
      .toList();

  group('a tier that goes without the backdrop pass owes what the '
      'preference owes', () {
    test('the sheet has preference rules to be a twin of', () {
      // A sheet that lost them would make everything below pass by being
      // empty.
      expect(preference, isNotEmpty);
    });

    test('and a rule per tier for every one of them, with the same '
        'declarations', () {
      for (final tier in _withholding(CoreQualityEffect.backdropPass)) {
        for (final rule in preference) {
          final twin = rule.selector.startsWith('[data-coui-style="')
              // The style attribute and the quality attribute are on the same
              // element, the document: one compound selector.
              ? rule.selector.replaceFirstMapped(
                  RegExp(r'^(\[data-coui-style="[^"]+"\])'),
                  (match) => '${match[1]}${_attr(tier)}',
                )
              // A local surface carries no style attribute: below the
              // document.
              : '${_attr(tier)} ${rule.selector}';
          final matches = tiered
              .where((candidate) => candidate.selector == twin)
              .toList();

          expect(matches, hasLength(1), reason: twin);
          expect(matches.single.media, isNull, reason: twin);
          expect(matches.single.body, rule.body, reason: twin);
        }
      }
    });

    test('and nothing else is keyed on a tier', () {
      final tiers = _withholding(CoreQualityEffect.backdropPass);
      expect(
        tiered.length,
        preference.length * tiers.length,
        reason: 'a tier rule with no preference rule behind it',
      );
    });

    test('the declarations are the opaque fill and no backdrop filter, '
        'and every one is `!important`', () {
      // The surface primitive writes its fill inline, and an inline
      // declaration outranks every selector.
      final surface = tiered.where((rule) => !_isFade(rule)).toList();

      expect(surface, isNotEmpty);
      for (final rule in surface) {
        expect(rule.body, hasLength(2), reason: rule.selector);
        expect(
          rule.body,
          [
            'background-color:rgb(var(--coui-surface-rgb) / var(--coui-surface-alpha, 1)) !important',
            'backdrop-filter:none !important',
          ],
          reason: rule.selector,
        );
      }
    });

    test('and a panel that fades by its terms goes back to fading by its '
        'opacity, every declaration `!important`', () {
      // With no pass there is nothing for the terms to keep, so the panel
      // fades as a whole, as a panel that draws no pass always does. The
      // panel's own rules name what it plays; this takes the naming back,
      // with `!important` like the rules that drop the pass, because the
      // names it replaces are ordinary declarations.
      const back = [
        '$kFadeOpacityAnimationVar:var($kFadeOpacityNameVar) !important',
        '$kFadePaintAnimationVar:$kFadeNoAnimation !important',
        '$kFadeLayerAnimationVar:$kFadeNoAnimation !important',
      ];
      final fade = tiered.where(_isFade).toList();

      expect(fade, isNotEmpty);
      for (final rule in fade) {
        expect(rule.body, back, reason: rule.selector);
      }
      // One for every surface rule the tier has, so no style that goes
      // opaque is left fading by terms it no longer draws.
      for (final tier in _withholding(CoreQualityEffect.backdropPass)) {
        final styles = {
          for (final rule in tiered)
            if (rule.selector.contains(_attr(tier)))
              RegExp(
                r'^\[data-coui-style="([^"]+)"\]',
              ).firstMatch(rule.selector)?.group(1),
        }..remove(null);
        for (final style in styles) {
          expect(
            fade.any(
              (rule) => rule.selector.startsWith(
                '[data-coui-style="$style"]${_attr(tier)}',
              ),
            ),
            isTrue,
            reason:
                '$style has surface rules in ${tier.name} and none for the '
                'panels that fade',
          );
        }
      }
    });

    test('and the attribute is joined to the style one, never below it', () {
      // `[a] [b]` needs `[b]` on a descendant of the element carrying `[a]`;
      // both attributes are on the document, so that selector matches
      // nothing and the rule would be dead on arrival.
      for (final rule in tiered) {
        expect(
          rule.selector,
          isNot(contains('"] [data-coui-style=')),
          reason: rule.selector,
        );
        expect(rule.selector.split('data-coui-quality'), hasLength(2));
      }
    });
  });

  group('the ladder decides which tiers have a rule', () {
    test('only the one that goes without the backdrop pass', () {
      final keyed = {
        for (final rule in tiered)
          for (final tier in CoreQualityTier.values)
            if (rule.selector.contains(_attr(tier))) tier,
      };

      expect(keyed, _withholding(CoreQualityEffect.backdropPass));
      expect(keyed, {CoreQualityTier.solid});
    });

    test('and never the ones that keep it: the style is drawn as stated', () {
      for (final tier in [
        CoreQualityTier.full,
        CoreQualityTier.noRefraction,
      ]) {
        expect(
          _sheet,
          isNot(contains(_attr(tier))),
          reason: '${tier.name} takes the stylesheet as it comes',
        );
      }
    });
  });

  group('an opaque style has no transparency to take away', () {
    test('and exactly the styles that use some have a tier rule', () {
      for (final id in CoreSurfaceStyleId.values) {
        final scope = '[data-coui-style="${id.name}"]${_attr(.solid)}';
        final has = tiered.any((rule) => rule.selector.startsWith(scope));

        expect(
          has,
          CoreSurfaceRecipe.of(id).a11y.usesTransparency,
          reason: '$id disagrees with its own `usesTransparency`',
        );
      }
    });

    test('and a local surface of such a style is reached below the '
        'document', () {
      final local = tiered.where(
        (rule) => rule.selector.startsWith('${_attr(.solid)} .'),
      );

      expect(local, isNotEmpty);
      for (final rule in local) {
        expect(rule.selector, contains('coui-material-'));
      }
    });
  });
}
