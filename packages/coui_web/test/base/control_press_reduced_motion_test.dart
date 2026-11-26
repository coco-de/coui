import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// The press pair's transition (#4407) has to reach
/// `@media (prefers-reduced-motion:reduce)` the same way the chrome half
/// of the same `transition` declaration already does — and, like the
/// chrome half, has to be overridable per instance
/// (`CoreButtonStyle.castHideDuration` / `CoreChipStyle.castHideDuration`)
/// without a second `transition` declaration fighting the shared one.
///
/// Before this fix `_controlShadowPressRule` wrote
/// `translate ${CoreDuration.ms50}ms,box-shadow ${CoreDuration.ms50}ms` as
/// a bare literal — `--coui-duration-*` never entered the picture, so the
/// reduced-motion media query (which only ever touches `:root`
/// `--coui-duration-*` variables) had nothing there to override, and no
/// per-instance override could reach it either. The fix routes both
/// properties through `var(--coui-control-engage-duration,
/// var(--coui-duration-50))` — [kControlEngageDurationVar] with the
/// token default as fallback — the same custom-property-with-fallback
/// shape [kControlChromeDurationVar] already uses for the chrome half.
///
/// The correct outcome is narrower than "the whole rule reacts to the
/// preference" — the engage declarations
/// (`box-shadow:var(--coui-control-shadow-press,…)`,
/// `translate:var(--coui-control-shadow-offset-x) …`) must stay exactly
/// as unconditional as they were: state is preserved (the shadow still
/// hides, the control still travels), only the *time it takes to get
/// there* collapses to zero. So this suite checks two things kept apart —
/// the clock is variable-routed, and the state-changing declarations are
/// not additionally gated behind the media query.
void main() {
  final css = ThemeConfig.defaults().cssVariables;

  /// The `var(<engage-var>,<token-default>)` expression both the
  /// `translate` and `box-shadow` properties read.
  final engageClock =
      'var($kControlEngageDurationVar,${durationMsCss(CoreDuration.ms50)})';

  /// The shared `transition:` declaration block on the marker's base
  /// (unconditional) rule — carries both the engage clock and
  /// `_chromeTransitionGroup`.
  String transitionBlock() {
    final marker = RegExp(
      '\\.${RegExp.escape(kControlShadowPressMarker)}\\{transition:([^}]*)\\}',
    ).firstMatch(css);
    expect(
      marker,
      isNotNull,
      reason: 'the shared transition rule is gone',
    );
    return marker!.group(1)!;
  }

  group('the press pair transition is variable-routed (#4407)', () {
    test(
      'translate and box-shadow both read the engage-duration custom '
      'property, falling back to var(--coui-duration-50)',
      () {
        expect(
          durationMsCss(CoreDuration.ms50),
          equals('var(--coui-duration-50)'),
          reason: 'sanity check on the adapter this rule now depends on',
        );

        final block = transitionBlock();
        expect(
          block,
          contains('translate $engageClock,'),
          reason:
              'the translate half must read the engage-duration custom '
              'property (falling back to the duration token), not a '
              'bare 50ms literal, or reduced motion — and a per-instance '
              'override — cannot reach it',
        );
        expect(
          block,
          contains('box-shadow $engageClock,'),
          reason:
              'the box-shadow half must read the same custom property as '
              'the translate half — one shared clock, not two',
        );
      },
    );

    test('no literal "50ms" survives in the transition declaration', () {
      expect(
        transitionBlock(),
        isNot(contains('50ms')),
        reason:
            'a literal duration sits outside the --coui-duration-* '
            'indirection the reduced-motion media query overrides',
      );
    });

    test(
      'both trigger branches share the one clock, not one apiece',
      () {
        // The engage clock is declared exactly once, on the base
        // (un-gated) rule — the :hover / :active blocks only ever set
        // the *value* the transition eases towards
        // (`_kEngageShadowDeclarations`), never a second `transition:`.
        // Counting occurrences of the engage-clock expression in the
        // whole stylesheet segment pins this: exactly three (translate +
        // box-shadow + the press shrink's `scale`, #4427), not six (a
        // duplicate set per media branch).
        final occurrences = RegExp(
          RegExp.escape(engageClock),
        ).allMatches(css).length;
        expect(
          occurrences,
          3,
          reason:
              'expected exactly one clock reference per property '
              '(translate, box-shadow, scale), declared once and shared by '
              'both '
              '@media (hover:…) branches — a second declaration site is '
              'exactly the drift a shared constant is meant to rule out',
        );
      },
    );

    test(
      'the custom property name matches Flutter\'s per-instance override '
      'field (CoreButtonStyle / CoreChipStyle .castHideDuration)',
      () {
        expect(
          kControlEngageDurationVar,
          equals('--coui-control-engage-duration'),
        );
      },
    );
  });

  group('reduced motion collapses the clock, not the state (#4407 AC)', () {
    test('--coui-duration-50 is zeroed under the preference', () {
      final block = RegExp(
        r'@media \(prefers-reduced-motion:reduce\)\{:root\{(.*?)\}\}',
        dotAll: true,
      ).firstMatch(css);
      expect(block, isNotNull);
      expect(
        block!.group(1),
        contains('--coui-duration-50:0ms;'),
        reason:
            'the press pair\'s default clock (50ms) is transition-tier '
            'and must collapse under prefers-reduced-motion, same as '
            'every other transition-tier step — reached through the '
            'token-default fallback even when no per-instance override '
            'is published',
      );
    });

    test(
      'the engage declarations (hide + travel) stay unconditional — '
      'not nested inside the reduced-motion media query',
      () {
        const engageDeclarations =
            'box-shadow:var(--coui-control-shadow-press,'
            'var(--coui-button-rest-shadow)) !important;'
            'translate:var(--coui-control-shadow-offset-x) '
            'var(--coui-control-shadow-offset-y);';

        // Both engage trigger rules must exist exactly as S2 (#4403) left
        // them — gated on device capability (`@media (hover:…)`), never
        // on the reduced-motion preference. Folding "does this control
        // hide its shadow and travel" into the motion preference would
        // be the wrong fix: state must survive with reduced motion on,
        // only the transition duration may change.
        expect(
          css,
          contains(
            '@media (hover:hover){.$kControlShadowPressMarker:hover{'
            '$engageDeclarations}}',
          ),
          reason:
              'the hover engage trigger must still unconditionally hide '
              'the shadow and travel the control — state, not time',
        );
        expect(
          css,
          contains(
            '@media (hover:none){.$kControlShadowPressMarker:active{'
            '$engageDeclarations}}',
          ),
          reason:
              'the touch (press) engage trigger must still '
              'unconditionally hide the shadow and travel the control',
        );
      },
    );

    test(
      'the reduced-motion block never mentions the shadow-press marker',
      () {
        // A wrong fix that scopes the engage rule itself under
        // `@media (prefers-reduced-motion:reduce)` (rather than routing
        // only the duration through a variable) would show up here —
        // the reduced-motion block only ever redefines
        // `--coui-duration-*` custom properties on `:root`.
        final block = RegExp(
          r'@media \(prefers-reduced-motion:reduce\)\{:root\{(.*?)\}\}',
          dotAll: true,
        ).firstMatch(css);
        expect(block, isNotNull);
        expect(
          block!.group(1),
          isNot(contains(kControlShadowPressMarker)),
        );
      },
    );
  });
}
