import 'package:coui_web/coui_web.dart';
// button_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/control/button/button_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// A raw (token-less) colour — the case that used to throw `token!.name`
/// when routed onto a pseudo-state Tailwind class.
const _kRawGreen = CoreColor(0xFF00FF00);

ResolvedButton _resolve(
  BuildContext context, {
  CoreButtonStyle? style,
  CoreButtonShape shape = CoreButtonShape.rectangle,
  bool disableTransition = false,
  CoreButtonVariant variant = CoreButtonVariant.primary,
}) => resolveButton(
  context,
  variant: variant,
  size: CoreComponentSize.md,
  shape: shape,
  expanded: false,
  disableTransition: disableTransition,
  buttonStyle: style,
);

/// The variants that paint no fill, and so have no box to cast from.
///
/// `ghost` zeroes the opacity multiplier on a real token; `plain` carries
/// the `transparent` sentinel. Both spellings have to reach the same
/// answer — reading only one of them is how this last diverged.
const _kUnfilledVariants = [
  CoreButtonVariant.ghost,
  CoreButtonVariant.plain,
];

/// The chrome properties whose Web emit used to snap while the Flutter
/// twin interpolated them through one `AnimatedContainer` (#4202), plus
/// the colours that already transitioned and must keep doing so.
const _kChromeTransitionProperties = [
  'border-radius',
  'padding',
  'border-width',
  'color',
  'background-color',
  'border-color',
];

/// The `transition` declaration of the shared control rule — the only
/// place a button's transition may be written.
///
/// Extracted from the real emitted stylesheet rather than restated here,
/// so a rule that stops being emitted at all fails instead of matching a
/// copy of itself.
String _sharedTransitionDeclaration() {
  final css = ThemeConfig.defaults().cssVariables;
  const opener = '.coui-control-shadow-press{transition:';
  final start = css.indexOf(opener);
  expect(start, isNonNegative, reason: 'the shared control rule is gone.');
  final end = css.indexOf('}', start);
  return css.substring(start + opener.length, end);
}

/// Counts the surfaces on which [resolved]'s root can set `transition`.
///
/// `transition` is a shorthand: two declarations on one element do not
/// merge, the later one resets `transition-property` wholesale. So the
/// number that matters is not "does the button transition" but "how many
/// declarations claim to say how" — and the answer has to be one, or
/// which half of the button's motion survives is decided by stylesheet
/// source order (class vs class) or by inline beating every rule.
/// Both the shorthand and its longhands count — a `duration-*` utility
/// retimes the shared rule's every item just as thoroughly as a second
/// `transition` shorthand replaces its property list.
int _buttonOwnedTransitionDeclarations(ResolvedButton resolved) {
  const classPrefixes = ['transition', 'duration-', 'ease-', 'delay-'];
  const inlineProperties = [
    'transition',
    'transition-property',
    'transition-duration',
    'transition-timing-function',
    'transition-delay',
  ];
  final classes = resolved.root.className.split(' ');
  final props = resolved.root.inlineStyles?.properties ?? const {};
  final fromClasses = classes
      .where((cls) => classPrefixes.any(cls.startsWith))
      .length;
  final fromInline = inlineProperties.where(props.containsKey).length;
  return fromClasses + fromInline;
}

/// Transition declarations the button writes into its own scoped
/// `<style>` rule.
///
/// The third emit surface, and the one that out-ranks the others: that
/// rule is keyed by `#scopeId`, so an ID selector (1,0,0) beats the shared
/// control rule's class selector (0,1,0) without needing `!important` or
/// source order. Counting only class + inline would let this surface
/// replace half the shared declaration unseen.
int _scopedRuleTransitionDeclarations(ResolvedButtonRules rules) {
  const properties = [
    'transition:',
    'transition-property:',
    'transition-duration:',
    'transition-timing-function:',
    'transition-delay:',
  ];
  final css = rules.css.replaceAll(' ', '');
  return properties.where(css.contains).length;
}

ResolvedButtonRules _rules(
  BuildContext context, {
  CoreButtonStyle? style,
  String scopeId = 'co-button-test',
  CoreButtonVariant variant = CoreButtonVariant.primary,
}) => resolveButtonRules(
  context,
  scopeId: scopeId,
  variant: variant,
  buttonStyle: style,
);

void main() {
  group('Button pseudo-state — default (class-safe) path', () {
    testComponents(
      'default button rides the focus-visible:outline-* utility classes '
      'and emits no scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        // `primary` — its hover/focus/pressed are an opaque container
        // swap (`primaryHover` / `primaryPressed`, 2026-09-08 §5), so it
        // carries no `stateLayer` and emits no scoped rule; `outline` /
        // `ghost` do (the `color-mix()` wash) and would not exercise the
        // "nothing scoped" path this test asserts.
        const variant = CoreButtonVariant.primary;
        final resolved = _resolve(context, variant: variant);
        final classes = resolved.root.className.split(' ');
        expect(classes, contains('outline-none'));
        expect(classes, contains('focus-visible:outline-2'));
        expect(classes, contains('focus-visible:outline-offset-2'));
        expect(classes, contains('focus-visible:outline-focus-ring'));
        // No ring utility and no band — the default band is transparent.
        expect(
          classes.where(
            (c) => c.contains(':ring-') || c.startsWith('ring-offset-'),
          ),
          isEmpty,
        );
        expect(classes, isNot(contains(kFocusBandMarker)));
        expect(
          resolved.root.inlineStyles!.properties,
          isNot(contains(kFocusBandVar)),
        );
        expect(_rules(context, variant: variant).css, isEmpty);
      },
    );

    testComponents('a token hover override still emits a hover:bg-* class', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreButtonStyle(
        hoverBackgroundColor: CoreColor.token(CoreColors.error),
      );
      final resolved = _resolve(context, style: style);
      expect(resolved.root.className, contains('hover:bg-error'));
      expect(_rules(context, style: style).css, isEmpty);
    });
  });

  group('Button pseudo-state — raw override (scoped-rule) path', () {
    testComponents(
      'a raw hoverBackgroundColor no longer throws — the hover:bg class is '
      'dropped and a #id:hover{background-color} rule is emitted',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreButtonStyle(hoverBackgroundColor: _kRawGreen);
        // Before the fix this threw a null-check on `token!.name`.
        final resolved = _resolve(context, style: style);
        expect(resolved.root.className, isNot(contains('hover:bg-')));

        final css = _rules(context, style: style, scopeId: 'btn-a').css;
        expect(css, contains('#btn-a:hover'));
        expect(css, contains('background-color: rgb(0, 255, 0)'));
      },
    );

    testComponents(
      'a raw focusOutlineStyle.borderColor drops the outline classes and '
      'paints via a scoped #id:focus-visible outline rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreButtonStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kRawGreen),
        );
        final resolved = _resolve(context, style: style);
        expect(
          resolved.root.className,
          isNot(contains('focus-visible:outline-focus-ring')),
        );
        // The resting outline stays on both paths.
        expect(resolved.root.className.split(' '), contains('outline-none'));

        final css = _rules(context, style: style, scopeId: 'btn-b').css;
        expect(
          css,
          contains('#btn-b:focus-visible{outline-color:rgb(0, 255, 0);'),
        );
        // The outline does not fight the inline rest shadow, so the rule
        // needs neither a box-shadow nor `!important`.
        expect(css, isNot(contains('box-shadow')));
        expect(css, isNot(contains('!important')));
      },
    );

    testComponents('disableHoverEffect suppresses the raw hover scoped rule', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreButtonStyle(
        hoverBackgroundColor: _kRawGreen,
        disableHoverEffect: true,
      );
      expect(_rules(context, style: style).css, isEmpty);
    });
  });

  group('Button focus band vs. inline rest-shadow', () {
    test(
      'the shared control rule composes a painted band on top of the '
      'button\'s own inline box-shadow, !important, and only on a button '
      'that states a band — the button root always states box-shadow '
      'inline, which out-ranks any selector without !important',
      () {
        final css = ThemeConfig.defaults().cssVariables;
        expect(
          css,
          contains(
            '.$kControlShadowPressMarker.$kFocusBandMarker:focus-visible{'
            'box-shadow:var($kFocusBandVar,0 0 #0000),'
            'var(--coui-button-rest-shadow-layer,0 0 #0000) !important;}',
          ),
        );
        // No rule touches the box-shadow of a band-less focused button.
        expect(
          css,
          isNot(contains('.$kControlShadowPressMarker:focus-visible{')),
        );
      },
    );

    testComponents(
      'a control that casts nothing publishes its rest shadow as a '
      'list-item-safe twin, never the bare `none` keyword — `none` is '
      'only valid as an entire box-shadow value, and substituting it into '
      'the band rule\'s comma-separated list above invalidates that '
      'whole declaration at computed-value time (falls back to `none`, '
      'silently swallowing the band with it)',
      (tester) async {
        final context = _themedContext(tester);
        for (final variant in _kUnfilledVariants) {
          final props = _resolve(
            context,
            variant: variant,
          ).root.inlineStyles!.properties;
          expect(
            props['box-shadow'],
            'none',
            reason:
                '${variant.name} casts nothing, so the property itself is '
                'still the bare keyword — only the composable twin below '
                'may not be.',
          );
          expect(
            props['--coui-button-rest-shadow-layer'],
            isNot('none'),
            reason: '${variant.name} would invalidate the focus band rule.',
          );
        }
      },
    );

    testComponents(
      'a stated band publishes its layer on the band variable and carries '
      'the band marker, beside the class-path outline — as wide as the gap '
      'that outline leaves, read from the same variable',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreButtonStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            offsetColor: CoreFocusRing.opaqueOffsetColor,
          ),
        );
        final resolved = _resolve(context, style: style);
        final classes = resolved.root.className.split(' ');
        expect(classes, contains(kFocusBandMarker));
        expect(classes, contains(kControlShadowPressMarker));
        // The band does not push the outline off its class path.
        expect(classes, contains('focus-visible:outline-focus-ring'));
        expect(classes, contains('focus-visible:outline-offset-2'));
        // `outline-offset-2` resolves to `--coui-ring-offset`; the band
        // spreads by that same variable, so the two cannot drift apart at
        // a non-16px root (a rem band would).
        expect(
          resolved.root.inlineStyles!.properties[kFocusBandVar],
          '0 0 0 var(--coui-ring-offset) rgb(var(--coui-surface))',
        );
        expect(_rules(context, style: style).css, isEmpty);
      },
    );

    testComponents(
      'a band-on button leads its resting shadow with the same band at zero '
      'alpha, so rest and focus carry the same layers',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreButtonStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            offsetColor: CoreFocusRing.opaqueOffsetColor,
          ),
        );
        // The default `primary` variant has a fill, so it casts.
        final props = _resolve(
          context,
          style: style,
        ).root.inlineStyles!.properties;
        const restBand =
            '0 0 0 var(--coui-ring-offset) rgb(var(--coui-surface) / 0%)';
        // `box-shadow` interpolates layer by index: the focus rule composes
        // [band, cast], so rest must be [band at zero alpha, cast] or the
        // band pairs with the first cast layer and the cast swings into it.
        expect(props['box-shadow'], '$restBand, var(--coui-control-shadow)');
        expect(
          props['--coui-button-rest-shadow'],
          '$restBand, var(--coui-control-shadow)',
        );
        // The list-safe twin the focus rule composes under the painted band
        // stays the cast alone.
        expect(
          props['--coui-button-rest-shadow-layer'],
          'var(--coui-control-shadow)',
        );

        final plain = _resolve(
          context,
          variant: .plain,
          style: style,
        ).root.inlineStyles!.properties;
        // A control that casts nothing rests on the zero-alpha band alone.
        expect(plain['box-shadow'], restBand);
        expect(plain['--coui-button-rest-shadow-layer'], '0 0 #0000');
      },
    );

    testComponents(
      'a band beside a raw ring colour keeps the band on the variable — '
      'the scoped outline rule carries no box-shadow',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreButtonStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            borderColor: _kRawGreen,
            offsetColor: CoreFocusRing.opaqueOffsetColor,
          ),
        );
        final resolved = _resolve(context, style: style);
        expect(resolved.root.className.split(' '), contains(kFocusBandMarker));
        final css = _rules(context, style: style, scopeId: 'btn-c').css;
        expect(css, contains('#btn-c:focus-visible{outline-color:'));
        expect(css, isNot(contains('box-shadow')));
      },
    );
  });

  group('Button transition — one declaration owns it (#4202)', () {
    testComponents(
      'the button root states no transition of its own, so the shared '
      'control rule is the only declaration in play',
      (tester) async {
        final context = _themedContext(tester);
        expect(
          _buttonOwnedTransitionDeclarations(_resolve(context)),
          isZero,
          reason:
              'a second declaration of the transition shorthand (or one of '
              'its longhands) on the same element does not merge with the '
              'shared rule — it replaces the half it names. Equal '
              'specificity leaves the winner to stylesheet source order; '
              'inline wins outright. Either way one half dies silently.',
        );
        expect(
          _scopedRuleTransitionDeclarations(_rules(context)),
          isZero,
          reason:
              'the scoped rule is keyed by `#scopeId`, so an ID selector '
              'out-ranks the shared control rule outright — a transition '
              'written there does not merge with it, it replaces the half '
              'it names, and no source order or `!important` is needed for '
              'that to happen.',
        );
        expect(_sharedTransitionDeclaration(), isNotEmpty);
      },
    );

    test('that one declaration names every property Flutter interpolates', () {
      // Flutter runs background colour, border colour, border width,
      // border radius and padding through a single `AnimatedContainer`
      // (`button.dart`'s chrome container). Web named only the colours,
      // via a `transition-colors` utility, so a runtime `shape` / `size`
      // change snapped on Web and eased on Flutter.
      final declaration = _sharedTransitionDeclaration();
      for (final property in _kChromeTransitionProperties) {
        // Anchored at a segment boundary, not a substring: `contains`
        // matched `color …` inside `background-color …`, so the shorter
        // names were unguarded — dropping `color` from the shared rule
        // left this test green. The clock itself carries commas inside
        // `var(…, fallback)`, so splitting on `,` is not an option either.
        expect(
          declaration,
          matches(
            RegExp(
              '(^|,)${RegExp.escape(property)} '
              r'var\(--coui-control-chrome-duration',
            ),
          ),
          reason: '$property is not on the control\'s chrome clock.',
        );
      }
    });

    test('and still pairs the press hide with its travel on one clock', () {
      // The press affordance hides the rest shadow and moves the control
      // by the distance the style throws shadows. Two clocks would drift
      // the pair apart; the chrome clock is a different speed entirely.
      // The travel rides `translate`, not `transform` — a control
      // positioned by a transform is holding its position there, and
      // writing that property would replace it for the length of the
      // press (see `control_press_composes_test.dart`).
      //
      // The clock itself is `var(--coui-control-engage-duration,
      // var(--coui-duration-50))` — a custom property with the duration
      // token as its fallback, not a bare `50ms` literal (#4407). The
      // fallback puts it inside reach of
      // `@media (prefers-reduced-motion:reduce)` the same way the chrome
      // clock above already is; the custom property itself is what lets
      // a per-instance `CoreButtonStyle.castHideDuration` override reach
      // Web without a second `transition` declaration fighting this one.
      final declaration = _sharedTransitionDeclaration();
      final clock =
          'var($kControlEngageDurationVar,${durationMsCss(CoreDuration.ms50)})';
      expect(declaration, contains('translate $clock'));
      expect(declaration, contains('box-shadow $clock'));
    });

    test('the press effect itself is untouched by the added properties', () {
      // Widening the property list must not disturb what `:active` does —
      // and a test that only checked *this* would happily pass a button
      // that re-declared `transition` inline and lost the clock, which is
      // why it is the companion to the ownership assertion above rather
      // than a substitute for it.
      final css = ThemeConfig.defaults().cssVariables;
      expect(css, contains('.coui-control-shadow-press:active{'));
      expect(
        css,
        contains(
          'box-shadow:var(--coui-control-shadow-press,'
          'var(--coui-button-rest-shadow)) !important;',
        ),
      );
      expect(
        css,
        contains(
          'translate:var(--coui-control-shadow-offset-x) '
          'var(--coui-control-shadow-offset-y);',
        ),
      );
    });

    testComponents(
      'the button publishes its chrome clock as a duration variable, which '
      'is what puts it inside reach of prefers-reduced-motion',
      (tester) async {
        final context = _themedContext(tester);
        final props = _resolve(context).root.inlineStyles!.properties;
        final ms = CoreButtonStyle.defaultAnimationDuration.inMilliseconds;
        expect(
          props['--coui-control-chrome-duration'],
          'var(--coui-duration-$ms)',
          reason:
              'a literal ${ms}ms compiles and looks right, but the reduce '
              'query rewrites the variable — not the literal.',
        );
        expect(
          ThemeConfig.defaults().cssVariables,
          contains('--coui-duration-$ms:0ms;'),
          reason: 'the variable the button published is never zeroed.',
        );
      },
    );

    testComponents(
      'a shape change moves the radius that declaration transitions',
      (tester) async {
        // The user-visible trigger: `shape` is a runtime prop, and the
        // value it changes is one of the properties named above.
        final context = _themedContext(tester);
        final rectangle = _resolve(context).root.inlineStyles!.properties;
        final circle = _resolve(
          context,
          shape: CoreButtonShape.circle,
        ).root.inlineStyles!.properties;
        expect(circle['border-radius'], isNot(rectangle['border-radius']));
        expect(circle['padding'], isNot(rectangle['padding']));
      },
    );

    testComponents(
      'disableTransition publishes a zero clock instead of a second '
      'declaration, so the press pair keeps moving as it does on Flutter',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(context, disableTransition: true);
        expect(
          resolved.root.inlineStyles!.properties['--coui-control-chrome-'
              'duration'],
          '0s',
        );
        expect(_buttonOwnedTransitionDeclarations(resolved), isZero);
      },
    );
  });

  /// The press-squash is a *pair*: the cast hides and the control travels
  /// into the space it vacated. A button with no fill casts nothing, so
  /// there is no vacated space and the travel has nothing to mean — it
  /// reads as the label sliding out of alignment, which is worst for the
  /// variants that sit inline with running text.
  ///
  /// The cast half was withheld for these variants on both platforms, but
  /// the travel halves are wired differently: Flutter derives it from the
  /// resolved shadow (so it followed), Web hangs it off a class marker
  /// (so it did not). Only a test that reads the *values* catches that —
  /// asserting the marker is present passes either way, which is exactly
  /// how this shipped.
  group('an unfilled button has no vacated space to travel into', () {
    for (final variant in _kUnfilledVariants) {
      testComponents('${variant.name} pins the press offsets to zero', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final props = _resolve(
          context,
          variant: variant,
        ).root.inlineStyles!.properties;

        expect(props['box-shadow'], 'none');
        expect(props['--coui-control-shadow-offset-x'], '0px');
        expect(props['--coui-control-shadow-offset-y'], '0px');
      });
    }

    testComponents(
      'a filled button leaves the offsets to the active style, so the '
      'affordance still fires where a cast exists',
      (tester) async {
        final context = _themedContext(tester);
        final props = _resolve(context).root.inlineStyles!.properties;

        expect(props.containsKey('--coui-control-shadow-offset-x'), isFalse);
        expect(props.containsKey('--coui-control-shadow-offset-y'), isFalse);
      },
    );

    testComponents(
      'a caller-stated shadow on a transparent button travels, matching '
      'the cast it was allowed to keep',
      (tester) async {
        final context = _themedContext(tester);
        final props = _resolve(
          context,
          variant: CoreButtonVariant.ghost,
          style: const CoreButtonStyle(boxShadow: CoreShadow.md),
        ).root.inlineStyles!.properties;

        expect(props['box-shadow'], isNot('none'));
        expect(props.containsKey('--coui-control-shadow-offset-x'), isFalse);
      },
    );

    /// Suppressing the travel by withholding the marker would take the
    /// button's chrome transition with it — that rule is the only place a
    /// button's `transition` may be written, so these variants would snap
    /// their radius / padding / colours while every other button eased.
    /// The suppression has to speak through values.
    testComponents('every button keeps the marker that carries its clock', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final variant in [
        ..._kUnfilledVariants,
        CoreButtonVariant.primary,
      ]) {
        expect(
          _resolve(context, variant: variant).root.className.split(' '),
          contains(kControlShadowPressMarker),
          reason: '${variant.name} lost the shared transition declaration',
        );
      }
    });
  });

  group('locale switcher chrome — ghost and plain', () {
    testComponents(
      'ghost and plain paint no border and no opaque fill',
      (tester) async {
        final context = _themedContext(tester);
        for (final variant in [
          CoreButtonVariant.ghost,
          CoreButtonVariant.plain,
        ]) {
          final resolved = _resolve(context, variant: variant);
          final props = resolved.root.inlineStyles?.properties ?? const {};
          final classes = resolved.root.className.split(' ');
          expect(
            props['border-width'],
            'var(--coui-stroke-width-0)',
            reason: '${variant.name} still has a hairline',
          );
          expect(
            classes,
            isNot(contains('border')),
            reason: '${variant.name} emits a border utility',
          );
          expect(
            classes.where((cls) => cls.startsWith('bg-')).toList(),
            isNot(contains('bg-primary')),
            reason: '${variant.name} took the filled primary disc',
          );
        }
      },
    );

    testComponents(
      'an accent fill override replaces primary and drops its hover swap',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(
          context,
          style: const CoreButtonStyle(
            backgroundColor: CoreColor.token(CoreColors.accent),
            foregroundColor: CoreColor.token(CoreColors.onAccent),
          ),
        );
        final classes = resolved.root.className.split(' ');
        expect(classes, contains('bg-accent'));
        expect(classes, contains('text-on-accent'));
        expect(classes, isNot(contains('bg-primary')));
        expect(classes, isNot(contains('hover:bg-primary-hover')));
      },
    );
  });

  group('CoreButtonShape — equal width and height', () {
    // The Flutter twin asserts the rendered box; here the class is the
    // box, so the class is what there is to read. Both platforms are
    // making the same promise — the enum says "equal width and height"
    // — and until this pair existed neither said it out loud.
    testComponents('square emits aspect-square', (tester) async {
      late ResolvedButton resolved;
      pumpWithTheme(
        tester,
        _ContextCapture((context) {
          resolved = _resolve(context, shape: CoreButtonShape.square);
        }),
      );

      expect(resolved.root.className, contains('aspect-square'));
    });

    testComponents('circle does too', (tester) async {
      late ResolvedButton resolved;
      pumpWithTheme(
        tester,
        _ContextCapture((context) {
          resolved = _resolve(context, shape: CoreButtonShape.circle);
        }),
      );

      expect(resolved.root.className, contains('aspect-square'));
    });

    testComponents('a rectangle does not', (tester) async {
      // The control the two above need: an unconditional class would
      // pass them and make every button in the kit square.
      late ResolvedButton resolved;
      pumpWithTheme(
        tester,
        _ContextCapture((context) {
          resolved = _resolve(context);
        }),
      );

      expect(resolved.root.className, isNot(contains('aspect-square')));
    });
  });

  // #4136 — the icon style the resolver computes is handed to the content as
  // an ambient `IconTheme`, the Web twin of Flutter's `leadingIconTheme` /
  // `trailingIconTheme`. Before this the resolver published
  // `--btn-icon-size` / `--btn-icon-color*` CSS variables that nothing read,
  // so a bare `Icon` inside a Button took whatever ambient size sat above
  // the Button and a slot size / colour never reached the glyph.
  group('Button icon theme reaches its content (#4136)', () {
    testComponents(
      'resolver — size-keyed default, colour left to currentColor',
      (
        tester,
      ) async {
        final context = _themedContext(tester);
        final md = _resolve(context);
        final lg = resolveButton(
          context,
          variant: CoreButtonVariant.primary,
          size: CoreComponentSize.lg,
          shape: CoreButtonShape.rectangle,
          expanded: false,
        );

        expect(md.leadingIconStyle.size, CoreIconSize.size16);
        expect(md.trailingIconStyle.size, CoreIconSize.size16);
        expect(lg.leadingIconStyle.size, CoreIconSize.size18);
        // No pinned colour — the glyph inherits the per-state foreground.
        expect(md.leadingIconStyle.color, isNull);
        expect(md.trailingIconStyle.color, isNull);
      },
    );

    testComponents('resolver — a slot size and an explicit colour survive', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreButtonStyle(
          leadingIconStyle: CoreIconStyle(
            size: CoreIconSize.size28,
            color: CoreColor.token(CoreColors.error),
          ),
        ),
      );

      expect(resolved.leadingIconStyle.size, CoreIconSize.size28);
      expect(
        resolved.leadingIconStyle.color,
        const CoreColor.token(CoreColors.error),
      );
      // The other slot takes the stated size (Flutter precedence), not the
      // colour — a colour pins only the slot it was stated on.
      expect(resolved.trailingIconStyle.size, CoreIconSize.size28);
      expect(resolved.trailingIconStyle.color, isNull);
    });

    testComponents('render — the child and leading read the leading theme', (
      tester,
    ) async {
      IconThemeData? childAmbient;
      IconThemeData? leadingAmbient;
      IconThemeData? trailingAmbient;
      pumpWithTheme(
        tester,
        Button(
          size: CoreComponentSize.lg,
          buttonStyle: const CoreButtonStyle(
            trailingIconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.tertiary),
            ),
          ),
          leading: _ContextCapture(
            (c) => leadingAmbient = IconTheme.maybeOf(c),
          ),
          trailing: _ContextCapture(
            (c) => trailingAmbient = IconTheme.maybeOf(c),
          ),
          child: _ContextCapture((c) => childAmbient = IconTheme.maybeOf(c)),
        ),
      );

      // An icon-only button's glyph is its child, so the leading theme
      // wraps the whole content (as Flutter's does).
      expect(childAmbient?.size, CoreIconSize.size18);
      expect(childAmbient?.color, isNull);
      expect(leadingAmbient?.size, CoreIconSize.size18);
      expect(trailingAmbient?.size, CoreIconSize.size18);
      expect(
        trailingAmbient?.color,
        const CoreColor.token(CoreColors.tertiary),
      );
    });

    // Web icons do not read the variant icon tokens — they inherit
    // `currentColor`, the per-state foreground the Button already paints.
    // That is exact only while every variant's icon token equals the
    // foreground token of the same state. If a variant ever pins a distinct
    // icon colour, this fails and Web needs its own emit for it.
    test('every variant icon token equals its foreground token', () {
      for (final entry in CoreButtonStyle.defaultsByVariant.entries) {
        final vs = entry.value;
        final idle = vs.foregroundColor;
        final hover = vs.hoverForegroundColor ?? idle;
        final pressed = vs.pressedForegroundColor ?? hover;
        expect(vs.iconColor ?? idle, idle, reason: '${entry.key} idle');
        expect(
          vs.hoverIconColor ?? hover,
          hover,
          reason: '${entry.key} hover',
        );
        expect(
          vs.pressedIconColor ?? pressed,
          pressed,
          reason: '${entry.key} pressed',
        );
        expect(
          vs.disabledIconColor ?? vs.disabledForegroundColor,
          vs.disabledForegroundColor,
          reason: '${entry.key} disabled',
        );
      }
    });
  });
}
