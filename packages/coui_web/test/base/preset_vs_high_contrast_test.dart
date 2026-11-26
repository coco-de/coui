import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// A style that says one thing about colour and nothing about the rest.
const _accentOnly = CoreSurfaceColorConstraint(accentChromaScale: 1.6);

void main() {
  final config = ThemeConfig.defaults();

  group('a style writes only what it changed', () {
    test('an accent statement does not touch foregrounds or boundaries', () {
      // The failure this prevents: a style rule and the high-contrast rule
      // match the same element with the same specificity, so whichever is
      // later in the stylesheet wins every slot it writes. A style that
      // wrote the whole vocabulary would therefore switch high contrast off
      // wholesale — inverting the one ordering this axis is built on.
      final block = config.surfaceStyleBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _accentOnly,
      );

      expect(block, contains('--coui-primary:'));
      for (final untouched in [
        '--coui-on-surface:',
        '--coui-outline:',
        '--coui-disabled-content:',
        '--coui-on-primary:',
      ]) {
        expect(
          block,
          isNot(contains(untouched)),
          reason:
              '$untouched was not changed by the style but was written, '
              'which would override the high-contrast value for that slot',
        );
      }
    });

    test('the slots it does change are present in both modes', () {
      final block = config.surfaceStyleBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _accentOnly,
      );

      expect(block, contains('[data-coui-style="neoBrutalism"]{'));
      expect(
        block,
        contains('[data-theme="dark"][data-coui-style="neoBrutalism"]{'),
      );
    });

    test('a constraint that changes nothing emits no rule at all', () {
      // Distinct from the identity short-circuit upstream: even a
      // non-identity constraint can resolve to the same colours, and an
      // empty rule would still be parsed.
      expect(
        config.surfaceStyleBlock(
          CoreSurfaceStyleId.neoBrutalism,
          const CoreSurfaceColorConstraint(),
        ),
        isEmpty,
      );
    });
  });

  group('high contrast still says what it always said', () {
    test('its block is unchanged by the delta emitter', () {
      // High contrast legitimately overrides its whole vocabulary, so it
      // keeps writing every slot it governs.
      final css = config.cssVariables;
      final block = RegExp(
        r'@media \(prefers-contrast:more\)'
        r'\{:root:root:where\(:not\(\[data-theme="dark"\]\)\)\{(.*?)\}\}',
        dotAll: true,
      ).firstMatch(css)?.group(1);

      expect(block, isNotNull);
      for (final slot in [
        '--coui-outline:',
        '--coui-on-surface:',
        '--coui-primary:',
        '--coui-disabled-content:',
      ]) {
        expect(block, contains(slot));
      }
    });
  });

  group('the preference outranks a style that speaks about the same slot', () {
    test('a shipped style really does write a slot high contrast writes', () {
      // Without this the rest of the group would be guarding a collision
      // that no longer happens, and would keep passing after the reason for
      // it disappeared. The overlap is the premise, so it is asserted.
      final overlap = _slotsIn(
        config.surfaceStyleVariableBlocks,
      ).intersection(_slotsIn(config.cssVariables));

      expect(
        overlap,
        isNotEmpty,
        reason: 'a style states a boundary colour, which is its whole point',
      );
    });

    test('the preference outranks the style in each mode', () {
      // Compared per mode, because a light rule and a dark rule never match
      // the same page — pitting one against the other would be measuring a
      // collision that cannot happen, and would fail on a stylesheet that
      // is entirely correct.
      //
      // And per target, for the same reason: a rule for the root and a rule
      // for a brightness scope (`:not(:root)`) never match the same element.
      // A scope restates its own palette, so on a scoped element the root's
      // rules arrive only as inherited values, which any declaration there
      // replaces — the contest inside a scope is the scope's own rules.
      //
      // Specificity rather than source order, because the two blocks reach
      // the page by different routes — one in the served markup, one
      // appended by script — and which lands last is not something the
      // library gets to decide. Comparing the numbers is the check; a
      // string match would pass on a selector that reads right and loses.
      final contrast = _contrastSelectorsIn(config.cssVariables);
      // Only blocks that *declare* a `--coui-*` slot. This group is about
      // two rules writing the same custom property — its premise test
      // above asserts exactly that overlap — and a rule declaring none
      // cannot take a slot away from the preference no matter how it
      // scores. The glass band is the case that forced the distinction:
      // it sets ordinary paint properties on a pseudo-element and only
      // *reads* the slots, which means it resolves whatever `:root` says
      // and high contrast still governs the values it draws with.
      final styles = _declaringSelectorsIn(
        config.surfaceStyleVariableBlocks,
      ).where((selector) => !_isPanelFade(selector)).toList();

      for (final scoped in [false, true]) {
        for (final dark in [false, true]) {
          // A light rule that negates the dark attribute is still a light
          // rule — read the attributes a selector requires, not every one it
          // mentions.
          bool inMode(String s) =>
              _withoutNegations(s).contains('data-theme="dark"') == dark;
          bool onTarget(String s) => s.contains(':not(:root)') == scoped;
          bool contends(String s) => inMode(s) && onTarget(s);

          final preference = contrast.where(contends).map(_specificity);
          final style = styles.where(contends).map(_specificity);
          final where = 'dark=$dark scoped=$scoped';

          expect(preference, isNotEmpty, reason: where);
          expect(style, isNotEmpty, reason: where);
          expect(
            preference.reduce((low, next) => low < next ? low : next),
            greaterThan(
              style.reduce((high, next) => high > next ? high : next),
            ),
            reason: 'a decorative style would win a shared slot ($where)',
          );
        }
      }
    });
  });
}

Set<String> _slotsIn(String css) =>
    RegExp('--coui-([a-z-]+):').allMatches(css).map((m) => m[1]!).toSet();

/// The selectors of every rule inside a `prefers-contrast: more` block —
/// all of them, not only the first: one block carries both scopes' rules.
List<String> _contrastSelectorsIn(String css) {
  const opening = '@media (prefers-contrast:more){';
  final selectors = <String>[];
  var from = css.indexOf(opening);
  while (from >= 0) {
    // Brace-matched, so the block ends where its own `}` closes it.
    var depth = 1;
    var i = from + opening.length;
    final start = i;
    for (; i < css.length && depth > 0; i++) {
      if (css[i] == '{') depth++;
      if (css[i] == '}') depth--;
    }
    final body = css.substring(start, i - 1);
    selectors.addAll(
      RegExp(r'([^{}]+)\{[^}]*\}').allMatches(body).map((m) => m[1]!.trim()),
    );
    from = css.indexOf(opening, i);
  }

  return selectors;
}

/// Selectors of the blocks that declare at least one `--coui-*` slot.
///
/// Kept apart from [_contrastSelectorsIn] because the question here is not
/// which rules exist but which ones can contend for a slot the preference
/// also writes. A rule that consumes slots via `var()` resolves them from
/// wherever they are defined, so it inherits the preference rather than
/// competing with it.
/// No `\}` anchor before the selector: the closing brace of one block
/// would be consumed by that block's own match, leaving the next block
/// with nothing to anchor against and silently dropping every second
/// rule. `}` is excluded from the selector class instead, which starts a
/// match in the same place without eating the delimiter.
List<String> _declaringSelectorsIn(String css) =>
    RegExp(r'([^{@}]+)\{([^}]*)\}')
        .allMatches(css)
        // Declares, not merely mentions. `var(--coui-x)` is a read and
        // puts the rule downstream of whoever defines the slot; only a
        // `--coui-x:` declaration competes for it. Reusing [_slotsIn]
        // keeps that distinction in one place.
        .where((m) => _slotsIn(m[2]!).isNotEmpty)
        .map((m) => m[1]!.trim())
        .where((sel) => sel.isNotEmpty)
        .toList();

/// Whether [selector] is one of the rules that let a panel fade by its terms.
///
/// They are about the panel's surface, an element the preference's rules never
/// match, and what they declare is `--coui-surface-pass` and the names of the
/// fade — no slot the preference writes. `surface_fade_target_test.dart` holds
/// that, so leaving them out here is not a way of not looking at them.
bool _isPanelFade(String selector) =>
    selector.contains('.$kFadeBoxClass') ||
    selector.contains('.$kFadePanelClass');

/// [selector] with every `:not(…)` removed — the attributes it requires.
String _withoutNegations(String selector) =>
    selector.replaceAll(RegExp(r':not\([^()]*\)'), '');

/// Class-column specificity — attributes and pseudo-classes only, which is
/// all either side uses. `:where(…)` adds nothing, and `:not(…)` adds its
/// argument rather than itself, as CSS counts them.
int _specificity(String selector) {
  final counted = selector
      .replaceAll(RegExp(r':where\((?:[^()]|\([^()]*\))*\)'), '')
      .replaceAllMapped(RegExp(r':not\(([^()]*)\)'), (m) => m[1]!);

  return RegExp(r'\[[^\]]+\]|:[a-z-]+').allMatches(counted).length;
}
