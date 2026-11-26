import 'package:coui_web/coui_web.dart';
// text_field_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
// The same resolver the widget's composed `FocusOutline` runs the
// forwarded slot through — the ring tests read its emitted outline
// rather than the slot, because a slot that merges correctly and never
// reaches the paint looks finished from the authoring side.
import 'package:coui_web/src/components/infra/focus_outline/focus_outline_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

/// Every rendered DOM node — the composition tests read the tree the
/// widget actually built, not the bundles the resolver handed it.
Iterable<DomComponent> _dom(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedTextField _resolve(
  BuildContext context, {
  required bool enabled,
  CoreTextFieldStyle? style,
}) => resolveTextField(
  context,
  scopeId: 'tf',
  size: CoreComponentSize.md,
  expands: false,
  hasError: false,
  enabled: enabled,
  textFieldStyle: style,
);

/// Resolves the label chrome `TextField` raw-forwards to its composed
/// `FormLabel` — the disabled-tone / colour-override precedence tested
/// below lives in `resolveFormLabel` now, not `resolveTextField` (child-
/// component-composition: `TextField` states only its own overrides,
/// `FormLabel` owns the per-size default + the disabled VALUE select).
ResolvedFormLabel _resolveLabel(
  BuildContext context, {
  required bool enabled,
  CoreTextFieldStyle? style,
}) => resolveFormLabel(
  context,
  size: CoreComponentSize.md,
  enabled: enabled,
  formLabelStyle: _resolve(
    context,
    enabled: enabled,
    style: style,
  ).formLabelStyle,
);

/// Resolves a field the way a caller with a prefix, a suffix or a built-in
/// feature (clear / password toggle) gets it. The box is the wrapper `<div>`
/// for every field, so this is [_resolve]'s twin kept for the tests that
/// state an error and read the wrapper.
ResolvedTextField _resolveAffixed(
  BuildContext context, {
  bool hasError = false,
  CoreTextFieldStyle? style,
}) => resolveTextField(
  context,
  scopeId: 'tf',
  size: CoreComponentSize.md,
  expands: false,
  hasError: hasError,
  enabled: true,
  textFieldStyle: style,
);

/// The inline ring properties the composed `FocusOutline` emits for
/// [style] while focused — `outline-color` / `outline-width` /
/// `outline-offset`, plus `box-shadow` only when a gap band paints.
///
/// This is where the field's one ring is actually painted, so it is the
/// only place an override can be shown to have survived.
Map<String, String> _ringProps(
  BuildContext context,
  CoreFocusOutlineStyle style,
) =>
    resolveFocusOutline(
      context,
      focused: true,
      shape: .rectangle,
      focusOutlineStyle: style,
    ).root.inlineStyles?.properties ??
    const {};

/// Every value of [_ringProps] in one string — for assertions that a
/// colour or length reaches the ring, whichever property carries it.
String _ringPaint(BuildContext context, CoreFocusOutlineStyle style) =>
    _ringProps(context, style).values.join('; ');

/// A ring width off the Tailwind `ring-*` scale — the value the deleted
/// class path truncated to `ring-2`.
const _kFractionalRingWidth = 2.5;

void main() {
  testComponents(
    'optional caret height intent is exposed without changing the default',
    (tester) async {
      final context = _themedContext(tester);
      final baseline = _resolve(
        context,
        enabled: true,
      ).input.inlineStyles?.properties;
      final custom = _resolve(
        context,
        enabled: true,
        style: const CoreTextFieldStyle(cursorHeight: 28),
      ).input.inlineStyles?.properties;
      expect(baseline?.containsKey('--coui-caret-height'), isFalse);
      expect(custom?['--coui-caret-height'], '1.75rem');
    },
  );
  group('TextField disabled label recolor (#3269)', () {
    testComponents(
      'enabled label carries no disabled tone / cursor and drops the '
      'vestigial peer-disabled:* classes',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(context, enabled: true);
        final label = _resolveLabel(context, enabled: true);
        expect(label.root.className, isNot(contains('peer-disabled')));
        expect(resolved.labelHost.className, isNot(contains('peer-disabled')));
        expect(
          resolved.labelHost.className,
          isNot(contains('cursor-not-allowed')),
        );
        // The disabled tone is absent while the field is enabled; the
        // enabled label is `FormLabel`'s own colour, one tier above it.
        expect(label.root.className, contains('text-on-surface-variant'));
        expect(
          label.root.className,
          isNot(contains('text-on-surface-subtle')),
        );
      },
    );

    testComponents(
      'a disabled field tones the label with labelDisabledColor '
      '(on-surface-subtle — the enabled label is on-surface-variant, so it '
      'drops one text tier rather than taking the graphics-only ink) and '
      'shows the not-allowed cursor — the '
      'recolor that the vestigial peer-disabled:* class never delivered',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(context, enabled: false);
        final label = _resolveLabel(context, enabled: false);
        // The two now ride different elements: the cursor is an affordance
        // of the whole label row, which `FormLabel` draws, while the tone
        // belongs to the label TEXT — `FormLabel`'s own concern now that
        // `TextField` raw-forwards `formLabelStyle` rather than emitting
        // the label typography itself. Asserting them on one className
        // would pass only for as long as the field hand-rolled its own
        // `<label>`.
        expect(resolved.labelHost.className, contains('cursor-not-allowed'));
        expect(label.root.className, contains('text-on-surface-subtle'));
        expect(
          label.root.className,
          isNot(contains('text-on-surface-variant')),
        );
        expect(label.root.className, isNot(contains('peer-disabled')));
        expect(resolved.labelHost.className, isNot(contains('peer-disabled')));
      },
    );

    testComponents(
      'a disabled field forces the disabled tone even over an explicit '
      'labelStyle.color override — FormLabel selects the disabled VALUE '
      'rather than letting a per-instance colour silently win over the '
      'disabled state (mirrors the Flutter FormLabel resolver)',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreTextFieldStyle(
          labelStyle: CoreTextStyle(color: CoreColor.token(CoreColors.primary)),
        );
        final label = _resolveLabel(
          context,
          enabled: false,
          style: style,
        ).root.className;
        expect(label, contains('text-on-surface-subtle'));
        expect(label, isNot(contains('text-primary')));
      },
    );

    testComponents(
      'an explicit labelStyle.color override wins when the field is '
      'enabled (the disabled-forcing branch only fires while disabled)',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreTextFieldStyle(
          labelStyle: CoreTextStyle(color: CoreColor.token(CoreColors.primary)),
        );
        final label = _resolveLabel(
          context,
          enabled: true,
          style: style,
        ).root.className;
        expect(label, contains('text-primary'));
        expect(label, isNot(contains('text-on-surface-variant')));
      },
    );

    testComponents(
      'a RAW (token-less) labelDisabledColor override on a disabled field '
      'does not throw and emits no dead peer-disabled: class (the colour '
      'rides the emitTypography inline overlay, not a class)',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreTextFieldStyle(
          labelDisabledColor: CoreColor(0xFF00FF00),
        );
        // Before the fix a raw override was dropped by the token guard; now
        // it flows through emitTypography — this resolve must not throw.
        final label = _resolveLabel(
          context,
          enabled: false,
          style: style,
        );
        expect(label.root.className, isNot(contains('peer-disabled')));
        // Raw colour has no Tailwind class, so it is absent from the class
        // surface (it rides the inline overlay instead).
        expect(label.root.className, isNot(contains('text-on-surface')));
      },
    );
  });

  // Regression for #3469: the `<input>` itself relied on `disabled:opacity-50`
  // (a multiplier — its contrast depends on whatever surface the field
  // sits on, and forced-colours mode doesn't touch opacity at all) instead
  // of dedicated disabled colour tokens for text/border.
  group(
    'TextField disabled input — dedicated colour tokens, not opacity (#3469)',
    () {
      // `disabled:*` are Tailwind pseudo-class variants — present in the class
      // string regardless of the build-time `enabled` flag, and activated at
      // runtime by the browser's native `:disabled` match on `<input disabled>`
      // (which the widget sets from `enabled`, unverified here — this is a
      // resolver-level test). So the assertion is about which `disabled:*`
      // classes exist at all, not a before/after diff across `enabled`.
      testComponents(
        'the input carries disabled:text and the box the disabled border — '
        'dedicated tokens, no disabled:opacity multiplier',
        (tester) async {
          final context = _themedContext(tester);
          final field = _resolve(context, enabled: false);
          final input = field.input.className;

          expect(input, contains('disabled:text-disabled-content'));
          // A `<div>` has no `:disabled`, so the box states it at build time.
          expect(
            field.affixWrapper.className,
            contains('border-disabled-outline'),
          );
          expect(input, isNot(contains('disabled:opacity-50')));
          // Behavioural (not colour) disabled affordances remain.
          expect(input, contains('disabled:cursor-not-allowed'));
          expect(input, contains('disabled:pointer-events-none'));
        },
      );
    },
  );

  // Regression for #4044. The affix wrapper used to paint a *second*
  // focus ring out of `focus-within:ring-*` utility classes, stacked on
  // the `FocusOutline` ring its own parent already draws. That second
  // ring read three values and dropped all three: the width and the
  // offset were truncated to an integer scale step, and the gap band had
  // no colour class at all, so Tailwind's `#fff` default filled it in
  // both themes.
  //
  // Each test below names one of the three and asserts the class is
  // gone *and* that the value reaches the surviving ring's paint, so
  // re-introducing any single class fails exactly its own test.
  group('TextField affix-wrapper second focus ring is gone (#4044)', () {
    testComponents(
      'a fractional ring width reaches the paint instead of truncating to '
      'the ring-2 scale step',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolveAffixed(
          context,
          style: const CoreTextFieldStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderWidth: _kFractionalRingWidth,
            ),
          ),
        );

        // No integer ring step on the wrapper — `ring-2` was what 2.5
        // used to become. The negative lookahead keeps `ring-offset-*`
        // out of this assertion; it has its own test below.
        expect(
          resolved.affixWrapper.className,
          isNot(matches(RegExp(r'focus-within:ring-(?!offset)\d'))),
        );
        // The requested 2.5 lands in the ring the field actually draws.
        // The gap band is `align - borderWidth`, resolved in the browser
        // so a stroke-width variable can reach it.
        expect(
          _ringPaint(context, resolved.focusOutlineStyle),
          // Off the stroke scale the width is a literal, so the gap is
          // the literal `align - width` — still exact, never truncated.
          contains(
            '${CoreFocusOutlineStyle.defaultAlign - _kFractionalRingWidth}px',
          ),
        );
      },
    );

    testComponents(
      'the ring colour follows the focusBorderColor override rather than '
      'the variant token the class hard-coded',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolveAffixed(
          context,
          style: const CoreTextFieldStyle(
            focusBorderColor: CoreColor.token(CoreColors.error),
          ),
        );

        // The class read `vs.focusRingColor` — the variant table — so it
        // painted `primary` here while `FocusOutline` painted `error`:
        // one field, one box, two ring colours.
        expect(
          resolved.affixWrapper.className,
          isNot(matches(RegExp('focus-within:ring-(?!offset)[a-z]'))),
        );
        expect(
          _ringPaint(context, resolved.focusOutlineStyle),
          contains('var(--coui-${CoreColors.error.name})'),
        );
      },
    );

    testComponents(
      'the gap band is a real gap — no ring-offset class on the wrapper '
      'and no band layer on the ring by default',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolveAffixed(context);

        // `ring-offset-<n>` sets the band's width; the band's *colour*
        // comes from `--tw-ring-offset-color`, which nothing in this
        // repo overrides — so the class path filled it with Tailwind's
        // `#fff` regardless of theme.
        expect(
          resolved.affixWrapper.className,
          isNot(contains('focus-within:ring-offset-')),
        );
        // The default band is transparent: the ring is an outline whose
        // offset is left unpainted, and no `box-shadow` layer is
        // emitted to fill it.
        final props = _ringProps(context, resolved.focusOutlineStyle);
        expect(props['outline-offset'], startsWith('calc('));
        expect(props.containsKey('box-shadow'), isFalse);
      },
    );

    testComponents(
      'the wrapper carries no ring utility at all — the focus border tint '
      'is a separate class and stays',
      (tester) async {
        final context = _themedContext(tester);
        final className = _resolveAffixed(context).affixWrapper.className;

        expect(className, isNot(contains('ring-')));
        // The tint is a border, not a ring, and it is the one CSS-native
        // focus affordance on this element — it must survive.
        expect(className, contains('focus-within:border-'));
      },
    );
  });

  // The field's own border width — not the ring's. It reached nothing on
  // Web: the border rode Tailwind's bare `border` class, which is 1px and
  // says nothing about the slot, and the resolver never read the field.
  // Nothing caught it because a `focusOutlineStyle.borderWidth` read for
  // the ring above satisfied the coverage check by name alone; deleting
  // that ring is what made the gap visible. The Flutter twin has honoured
  // the field all along.
  group('TextField borderWidth override reaches the border it names', () {
    testComponents('the wrapper that draws the border takes it, and the input '
        'stays borderless', (tester) async {
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        enabled: true,
        style: const CoreTextFieldStyle(borderWidth: CoreStrokeWidth.stroke4),
      );

      expect(
        resolved.affixWrapper.inlineStyles?.properties['border-width'],
        strokeWidthCss(CoreStrokeWidth.stroke4),
      );
      // The wrapper owns the boundary and the input drops its own border via
      // `border-0`; an inline width here would beat that class and draw a
      // second box.
      expect(resolved.input.className, contains('border-0'));
      expect(
        resolved.input.inlineStyles?.properties.containsKey('border-width'),
        isFalse,
      );
    });

    testComponents('the same width is what the edge band reaches over', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        enabled: true,
        style: const CoreTextFieldStyle(borderWidth: CoreStrokeWidth.stroke4),
      );

      expect(
        resolved.affixWrapper.inlineStyles?.properties[kWebSurfaceBleedVar],
        strokeWidthCss(CoreStrokeWidth.stroke4),
      );
    });
  });

  // The size table lays no line height over its role (10-29 결정 — line
  // height is the Core role's own), so the bare field's value line comes
  // from the role class alone: `text-body-medium` carries `bodyMedium`'s
  // 150%, and nothing inline overrides it. A leftover inline value would
  // beat the role class and silently redraw the line at another height.
  // #5762 (2026-11-04 결정) — a one-line field is held on its size row: the
  // box's floor is the row and the row's vertical padding does not size it,
  // so the line is centred by the wrapper's `align-items: center`. The
  // horizontal inset stays. A field that `expands` keeps the row padding.
  group('a one-line field is held on its row', () {
    for (final size in CoreComponentSize.values) {
      testComponents('${size.name}: no vertical padding, the row floor', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final row = CoreTextFieldStyle.defaultsBySize[size]!;
        final held = row.padding!.copyWith(top: 0, bottom: 0).toValue();
        final r = resolveTextField(
          context,
          scopeId: 'tf',
          size: size,
          expands: false,
          hasError: false,
          enabled: true,
        );
        expect(
          r.input.inlineStyles!.properties['padding'],
          held,
          reason: '$size',
        );
        expect(
          r.affixWrapper.inlineStyles!.properties['min-height'],
          controlHeightCss(row.minHeight!),
          reason: '$size',
        );
        expect(
          r.affixWrapper.inlineStyles!.properties['align-items'],
          'center',
        );
        final grows = resolveTextField(
          context,
          scopeId: 'tf',
          size: size,
          expands: true,
          hasError: false,
          enabled: true,
        );
        // The row's vertical padding goes on the box; the input keeps the
        // horizontal inset of a side without a slot.
        expect(
          grows.affixWrapper.inlineStyles!.properties['padding'],
          row.padding!.copyWith(left: 0, right: 0).toValue(),
          reason: '$size expands',
        );
      });
    }
  });

  group("TextField value/affix line-height is the role's own", () {
    testComponents('the bare field emits the role class and no inline '
        'line-height', (tester) async {
      final context = _themedContext(tester);
      final resolved = _resolve(context, enabled: true);

      expect(resolved.input.className, contains('text-body-medium'));
      expect(
        resolved.input.inlineStyles?.properties.containsKey('line-height'),
        isFalse,
      );
    });

    testComponents('an explicit valueStyle override wins over the overlay', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        enabled: true,
        // Distinct from the role's own 150% so the override is told apart
        // from the default it replaces.
        style: const CoreTextFieldStyle(
          valueStyle: CoreTextStyle(lineHeight: CoreLineHeight.h160),
        ),
      );

      expect(
        resolved.input.inlineStyles?.properties['line-height'],
        CssVariableGenerator.lineHeightCss(CoreLineHeight.h160),
      );
    });

    // A different role stated in `valueStyle` is the newer statement, so it
    // brings its own line box (`code-md`'s fixed 21px comes from its class)
    // and nothing from the base is laid over it — inline `line-height`
    // beats the role class, so a leftover would silently redraw it.
    testComponents('a stated role replaces the overlay with its own line box', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        enabled: true,
        style: const CoreTextFieldStyle(
          valueStyle: CoreTextStyle.token(CoreTextStyles.codeMd),
        ),
      );

      expect(resolved.input.className, contains('text-code-md'));
      expect(
        resolved.input.className.split(' '),
        isNot(contains('text-body-medium')),
      );
      expect(
        resolved.input.inlineStyles?.properties.containsKey('line-height'),
        isFalse,
      );
    });
  });

  // `resolveTextField` builds the ring slot by merging the caller's
  // `focusOutlineStyle` onto the design default and then restating
  // `borderRadius` and `borderColor` with `copyWith`. Both arguments are
  // locals that can never be null (`focusRingColor` is a non-nullable
  // variant field, `borderRadiusCore` is `merged.borderRadius ??
  // default`), and `CoreFocusOutlineStyle.copyWith` writes any non-null
  // argument through — so the two values the merge had just carried in
  // were overwritten on every resolve. The slot declared both fields and
  // reached the paint with neither.
  //
  // These read what `FocusOutline` emits rather than the slot itself: a
  // slot that merges correctly and never reaches the paint looks finished
  // from the authoring side, which is the failure mode the whole family
  // of these bugs shares. Both the bare and the framed field are covered
  // — they are separate branches of this resolver and both were broken.
  group('TextField focus ring — the caller slot reaches it (#4120)', () {
    // A token neither variant table entry uses (`primary` / `error`) and
    // that is not `CoreFocusOutlineStyle.defaultBorderColor` either — a
    // ring that fell back to any of those is visibly not this one. A
    // token rather than a raw colour so the emitted `var(--coui-…)`
    // pins the tone by name.
    const slotToken = CoreColor.token(CoreColors.tertiary);

    // Far off the 4px field default, so a dropped radius is a number
    // nobody can mistake for rounding.
    const bigRadius = CoreBorderRadius.all(CoreRadius.radius64);

    ResolvedTextField resolveField(
      BuildContext context, {
      bool hasError = false,
      CoreTextFieldStyle? style,
    }) => resolveTextField(
      context,
      scopeId: 'tf',
      size: CoreComponentSize.md,
      expands: false,
      hasError: hasError,
      enabled: true,
      textFieldStyle: style,
    );

    /// The `border-radius` the composed `FocusOutline` emits for [style].
    String? ringRadius(BuildContext context, CoreFocusOutlineStyle style) =>
        resolveFocusOutline(
          context,
          focused: true,
          shape: .rectangle,
          focusOutlineStyle: style,
        ).root.inlineStyles?.properties['border-radius'];

    testComponents(
      "an explicit slot borderColor reaches the field's ring instead "
      'of the variant tone',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveField(
          context,
          style: const CoreTextFieldStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(borderColor: slotToken),
          ),
        );

        expect(
          _ringPaint(context, resolved.focusOutlineStyle),
          contains('var(--coui-${CoreColors.tertiary.name})'),
          reason:
              'the slot exposes borderColor, so a colour written there has '
              'to reach the paint — the variant tone is the fallback under '
              'it, not the winner over it',
        );
      },
    );

    testComponents(
      'an explicit slot borderColor wins over the error tone too',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveField(
          context,
          hasError: true,
          style: const CoreTextFieldStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(borderColor: slotToken),
          ),
        );

        final shadow = _ringPaint(context, resolved.focusOutlineStyle);
        expect(shadow, contains('var(--coui-${CoreColors.tertiary.name})'));
        // A fallback that beats an explicit value is not a fallback.
        expect(shadow, isNot(contains('var(--coui-${CoreColors.error.name})')));
      },
    );

    testComponents('an explicit slot borderRadius reaches the ring corner', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveField(
        context,
        style: const CoreTextFieldStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderRadius: bigRadius),
        ),
      );

      expect(
        ringRadius(context, resolved.focusOutlineStyle),
        bigRadius.toValue(),
        reason:
            'the caller radius has to reach the ring — the field corner is '
            'what it defers to, not what overrides it',
      );
    });

    // This one passes before the fix as well, and that is the point: it
    // fails for the *wrong* fix. Reading the merged slot back
    // (`slot.borderColor ?? focusBorderColor ?? vs.focusRingColor`) looks
    // equivalent, but `CoreTextFieldStyle.defaultFocusOutlineStyle`
    // already states a non-null `borderColor`, so the merged value is
    // never null and the variant tone becomes unreachable — the invalid
    // field silently rings the default colour. The guard has to read the
    // *pre-merge* `merged.focusOutlineStyle?.borderColor`.
    testComponents('with no slot colour, an invalid field still rings error', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveField(context, hasError: true);

      expect(
        _ringPaint(context, resolved.focusOutlineStyle),
        contains('var(--coui-${CoreColors.error.name})'),
        reason:
            'the error variant tone is the fallback the ring lands on when '
            'the caller states no colour — a guard that reads the '
            'post-merge slot never reaches it',
      );
    });

    testComponents('focusBorderColor still reaches the ring under an empty '
        'slot', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveField(
        context,
        // A slot that states geometry but no colour: the middle rung of
        // the chain has to stay reachable through it.
        style: const CoreTextFieldStyle(
          focusBorderColor: slotToken,
          focusOutlineStyle: CoreFocusOutlineStyle(
            borderWidth: _kFractionalRingWidth,
          ),
        ),
      );

      expect(
        _ringPaint(context, resolved.focusOutlineStyle),
        contains('var(--coui-${CoreColors.tertiary.name})'),
      );
      expect(resolved.focusOutlineStyle.borderWidth, _kFractionalRingWidth);
    });
  });

  group('a labelled field composes FormLabel rather than drawing one', () {
    // The resolver tests above can only show that the two chrome bundles
    // are built. They cannot show which element each lands on, and the
    // divergence this group pins was exactly that: Flutter composed
    // `FormLabel` while Web hand-rolled a `<label>` plus its own `*`
    // span, so the marker's type size and its semantics were decided
    // twice, in two places, and disagreed.
    testComponents('the `<label>` is FormLabel, not a hand-rolled element', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const TextField(label: 'Email', required: true),
      );

      expect(find.byType(FormLabel), findsOneComponent);
    });

    testComponents('the required marker is aria-hidden', (tester) async {
      pumpWithTheme(
        tester,
        const TextField(label: 'Email', required: true),
      );

      // Flutter wraps its marker in `ExcludeSemantics`; before this the
      // Web twin announced "asterisk" after every required label.
      final markers = _dom(
        tester,
      ).where((c) => c.attributes?['aria-hidden'] == 'true');
      expect(markers, isNotEmpty);
    });

    testComponents('the field states no `*` colour of its own', (tester) async {
      pumpWithTheme(
        tester,
        const TextField(label: 'Email', required: true),
      );

      // `text-error` was the field's own literal for the marker — the
      // same value `CoreFormLabelStyle.defaultRequiredColor` already
      // owns. Two sources for one colour is the duplication; the marker
      // keeps its colour, but only FormLabel says what it is. `TextField`
      // no longer resolves any label chrome of its own at all (it
      // raw-forwards [CoreTextFieldStyle.labelStyle] whole into
      // `formLabelStyle`), so there is no `resolved.label` slot left to
      // carry a stray literal.
      final resolved = _resolve(_themedContext(tester), enabled: true);
      expect(resolved.formLabelStyle.labelStyle, isNull);
      expect(resolved.labelHost.className, isNot(contains('text-error')));
    });
  });

  // The state-layer wash was measured against WCAG 2.4.13's 3:1 non-text
  // contrast floor and dropped from the boxed variants (Δcontrast
  // 1.06–1.17 in every mode — well short of the floor) — hover/focus now
  // ride the border alone. `plain` has no border to step, so it keeps its
  // ramp. Mirrors the Flutter twin's `text_field_test.dart` group of the
  // same name.
  group('TextField state-layer wash — dropped on boxed variants, kept on '
      'plain', () {
    ResolvedTextField resolve(
      BuildContext context, {
      required bool hasError,
      bool enabled = true,
      CoreTextFieldVariant? variant,
      CoreTextFieldStyle? style,
    }) => resolveTextField(
      context,
      scopeId: 'tf',
      size: CoreComponentSize.md,
      expands: false,
      hasError: hasError,
      enabled: enabled,
      variant: variant,
      textFieldStyle: style,
    );

    testComponents('the default variant emits no hover/focus wash rule', (
      tester,
    ) async {
      final css = resolveTextFieldRules(
        _themedContext(tester),
        scopeId: 'tf',
        stateLayerId: 'tf-default',
        hasError: false,
        enabled: true,
      ).css;

      expect(
        css,
        isEmpty,
        reason:
            'hover rides the border step alone — a wash rule on top '
            'of it would double the signal',
      );
    });

    testComponents('the error variant emits no hover/focus wash rule', (
      tester,
    ) async {
      final css = resolveTextFieldRules(
        _themedContext(tester),
        scopeId: 'tf',
        stateLayerId: 'tf-error',
        hasError: true,
        enabled: true,
      ).css;

      expect(css, isEmpty);
    });

    testComponents(
      'plain still emits a wash rule once a caller states an opaque fill',
      (tester) async {
        // Plain's own default fill is transparent, and the resolver gates
        // the wash on having a fill token to mix against — so this test
        // states an override, the same way a real composition would.
        final css = resolveTextFieldRules(
          _themedContext(tester),
          scopeId: 'tf',
          stateLayerId: 'tf-plain',
          hasError: false,
          enabled: true,
          variant: CoreTextFieldVariant.plain,
          textFieldStyle: const CoreTextFieldStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
          ),
        ).css;

        expect(
          css,
          contains(':hover{background-color:'),
          reason:
              'plain has no border to step, so the wash is its only '
              'channel — it must still fire once the fill is opaque',
        );
      },
    );

    testComponents(
      'disabled outranks error — the input carries the same disabled:* '
      'classes either way',
      (tester) async {
        final context = _themedContext(tester);
        final normal = resolve(context, hasError: false, enabled: false);
        final error = resolve(context, hasError: true, enabled: false);

        // Every disabled:* class the normal variant states also appears
        // on the error variant — a disabled field is disabled first, so
        // the error tone must not survive into the disabled trio.
        final normalDisabledClasses = normal.input.className
            .split(' ')
            .where((c) => c.startsWith('disabled:'));
        expect(normalDisabledClasses, isNotEmpty);
        for (final cls in normalDisabledClasses) {
          expect(error.input.className, contains(cls));
        }
      },
    );

    testComponents(
      'disabled outranks error — an errorBorderColor override emits no '
      'inline border on a disabled field',
      (tester) async {
        // An inline `border-color` beats every class, so the row agreement
        // pinned above cannot hold this — the resolver's own
        // `disabled > error` gate has to.
        final context = _themedContext(tester);
        const override = CoreTextFieldStyle(
          errorBorderColor: CoreColor(0xFFFF0000),
        );
        final disabled = resolve(
          context,
          hasError: true,
          enabled: false,
          style: override,
        );
        final enabled = resolve(context, hasError: true, style: override);

        expect(
          disabled.affixWrapper.inlineStyles?.properties['border-color'],
          isNull,
          reason:
              'a disabled field is disabled first — the error border '
              'override must not paint over the disabled edge',
        );
        expect(
          enabled.affixWrapper.inlineStyles?.properties['border-color'],
          isNotNull,
          reason: 'the override still paints while the field is enabled',
        );
      },
    );

    testComponents(
      'disabled outranks error — the affix wrapper does not keep the error '
      'border (`disabled:*` never reaches it)',
      (tester) async {
        final context = _themedContext(tester);
        List<String> wrapperClasses({required bool enabled}) =>
            resolveTextField(
              context,
              scopeId: 'tf',
              size: CoreComponentSize.md,
              expands: false,
              hasError: true,
              enabled: enabled,
            ).affixWrapper.className.split(' ');

        const errorBorder = 'border-error';
        expect(
          wrapperClasses(enabled: true),
          contains(errorBorder),
          reason: 'sanity — an enabled erroring wrapper does carry it',
        );
        expect(
          wrapperClasses(
            enabled: false,
          ).where((c) => c == errorBorder || c.endsWith(':$errorBorder')),
          isEmpty,
        );
      },
    );

    testComponents("plain's horizontal padding is flush (0)", (
      tester,
    ) async {
      final resolved = resolve(
        _themedContext(tester),
        hasError: false,
        variant: CoreTextFieldVariant.plain,
      );

      // Only the horizontal gutter a boxed field would otherwise carry is
      // zeroed by the variant; the vertical inset is not there to keep — a
      // one-line field is held on its row with the line centred.
      final expected = CoreEdgeInsets.zero.toValue();

      expect(resolved.input.inlineStyles?.properties['padding'], expected);
    });

    testComponents(
      'an explicit padding override wins over the plain zero-gutter',
      (tester) async {
        final resolved = resolve(
          _themedContext(tester),
          hasError: false,
          variant: CoreTextFieldVariant.plain,
          style: const CoreTextFieldStyle(
            padding: CoreEdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        );

        // The box takes the vertical inset, the input the horizontal one of a
        // side without a slot — together the stated padding.
        expect(
          resolved.input.inlineStyles?.properties['padding'],
          const CoreEdgeInsets.symmetric(horizontal: 20).toValue(),
        );
        expect(
          resolved.affixWrapper.inlineStyles?.properties['padding'],
          const CoreEdgeInsets.symmetric(vertical: 8).toValue(),
        );
      },
    );
  });

  // `disabled > error` gates the box chrome only. The widget keeps showing
  // `errorText` while disabled, so the message's style must keep reading
  // the Theme `variantStyles[error]` row. Mirrors the Flutter twin's
  // `text_field_test.dart` group of the same name.
  group('TextField disabled > error — box chrome only, the error message '
      'keeps the Theme error row', () {
    const rawGreen = CoreColor(0xFF00FF00);
    const rawRed = CoreColor(0xFFFF0000);

    BuildContext themedWithErrorRow(ComponentTester tester) {
      final data = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          textField: CoreTextFieldTheme(
            variantStyles: {
              CoreTextFieldVariant.error: CoreTextFieldStyle(
                errorColor: rawGreen,
                borderColor: rawRed,
              ),
            },
          ),
        ),
      );
      late BuildContext context;
      tester.pumpComponent(
        Theme(data: data, child: _ContextCapture((c) => context = c)),
      );
      return context;
    }

    ResolvedTextField resolve(
      BuildContext context, {
      required bool enabled,
      bool hasError = true,
    }) => resolveTextField(
      context,
      scopeId: 'tf',
      size: CoreComponentSize.md,
      expands: false,
      hasError: hasError,
      enabled: enabled,
    );

    for (final enabled in const [true, false]) {
      testComponents('enabled: $enabled — the error message reads the Theme '
          'error row', (tester) async {
        final resolved = resolve(themedWithErrorRow(tester), enabled: enabled);

        expect(
          resolved.error.inlineStyles?.properties['color'],
          rawGreen.toValue(),
          reason:
              'the message is content, not box chrome — disabling the '
              'field must not drop the Theme error row off it',
        );
        expect(
          resolved.error.className.split(' '),
          isNot(contains('text-error')),
          reason: 'the default error class must not ride under the override',
        );
      });
    }

    testComponents('disabled — the Theme error row does not reach the box '
        'border', (tester) async {
      final context = themedWithErrorRow(tester);

      expect(
        resolve(
          context,
          enabled: false,
        ).affixWrapper.inlineStyles?.properties['border-color'],
        isNull,
        reason:
            'a disabled field is disabled first — the Theme error row '
            'border must not paint over the disabled edge',
      );
      expect(
        resolve(
          context,
          enabled: true,
        ).affixWrapper.inlineStyles?.properties['border-color'],
        rawRed.toValue(),
        reason: 'sanity — the Theme error row paints while enabled',
      );
    });
  });
  group('TextField selection color', () {
    for (final dark in [false, true]) {
      BuildContext themedContext(ComponentTester tester) {
        late BuildContext context;
        tester.pumpComponent(
          Theme(
            data: ThemeData.fromCore(
              dark ? CoreThemePresets.dark : CoreThemePresets.light,
            ),
            child: _ContextCapture((c) => context = c),
          ),
        );
        return context;
      }

      testComponents('default retains selection token, dark=$dark', (
        tester,
      ) async {
        final context = themedContext(tester);
        expect(
          _resolve(context, enabled: true).input.className,
          contains('selection:bg-primary/20'),
        );
        expect(
          resolveTextFieldRules(
            context,
            scopeId: 'tf',
            stateLayerId: 'tf-input',
            hasError: false,
            enabled: true,
          ).css,
          isNot(contains('::selection')),
        );
      });
      for (final color in [
        CoreColor.transparent,
        const CoreColor(0x80FF0000),
      ]) {
        testComponents('raw selection $color, dark=$dark uses scoped rule', (
          tester,
        ) async {
          final context = themedContext(tester);
          final style = CoreTextFieldStyle(selectionColor: color);
          final input = _resolve(context, enabled: true, style: style).input;
          expect(input.className, isNot(contains('selection:bg-')));
          expect(input.className, contains('co-text-field-selection-tf'));
          final css = resolveTextFieldRules(
            context,
            scopeId: 'tf',
            stateLayerId: 'tf-input',
            hasError: false,
            enabled: true,
            textFieldStyle: style,
          ).css;
          expect(css, contains('.co-text-field-selection-tf::selection'));
          expect(
            css,
            contains(color.scaleAlpha(CoreOpacity.opacity20).toValue()),
          );
        });
      }
    }
  });

  group('TextField placeholder colour — class XOR scoped rule', () {
    // `::placeholder` has no inline form. A raw colour — a composing parent
    // such as PhoneInput forwards whatever its caller wrote — used to go
    // through `.tailwindColor` and throw on the missing token.
    const rawGreen = CoreColor(0xFF00FF00);
    const rawStyle = CoreTextFieldStyle(
      placeholderStyle: CoreTextStyle(color: rawGreen),
    );

    testComponents('a token keeps the class and writes no rule', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final input = _resolve(context, enabled: true).input.className;
      expect(input, contains('placeholder:text-placeholder'));
      expect(input, isNot(contains('co-text-field-ph-')));
      expect(
        resolveTextFieldRules(
          context,
          scopeId: 'tf',
          stateLayerId: 'tf-input',
          hasError: false,
          enabled: true,
        ).css,
        isNot(contains('::placeholder')),
      );
    });

    testComponents('a raw colour drops the class for a scoped rule', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final input = _resolve(
        context,
        enabled: true,
        style: rawStyle,
      ).input.className;
      expect(input, isNot(contains('placeholder:text-')));
      expect(input.split(' '), contains('co-text-field-ph-tf'));
      expect(
        resolveTextFieldRules(
          context,
          scopeId: 'tf',
          stateLayerId: 'tf-input',
          hasError: false,
          enabled: true,
          textFieldStyle: rawStyle,
        ).css,
        contains('.co-text-field-ph-tf::placeholder{color: rgb(0, 255, 0);}'),
      );
    });

    testComponents('a disabled field still writes the raw rule', (
      tester,
    ) async {
      // The state layer stops at disabled; the placeholder colour does not
      // — the class path honours it on a disabled field too.
      final context = _themedContext(tester);
      expect(
        resolveTextFieldRules(
          context,
          scopeId: 'tf',
          stateLayerId: 'tf-input',
          hasError: false,
          enabled: false,
          textFieldStyle: rawStyle,
        ).css,
        contains('.co-text-field-ph-tf::placeholder'),
      );
    });
  });

  // `CoreTextFieldStyle.boxMinHeight` — the same floor Flutter reads. It
  // lands on the wrapper, which draws the boundary (the input inside is
  // borderless, so a floor on it would make the box two border widths taller
  // than Flutter's). A stated height and a cap are the box's too.
  group('the box is floored at the control height', () {
    String? inputMin(ResolvedTextField r) =>
        r.input.inlineStyles?.properties['min-height'];
    String? boxMin(ResolvedTextField r) =>
        r.affixWrapper.inlineStyles?.properties['min-height'];
    String? boxProp(ResolvedTextField r, String name) =>
        r.affixWrapper.inlineStyles?.properties[name];
    // The md control row's variable — the row a density re-points.
    const md = 'var(--coui-control-height-40)';

    testComponents('the wrapper carries the md control height, the input '
        'none', (tester) async {
      final r = _resolve(_themedContext(tester), enabled: true);
      expect(boxMin(r), md);
      expect(inputMin(r), isNull);
    });

    testComponents('a fixed height drops the floor and sizes the box', (
      tester,
    ) async {
      final r = _resolve(
        _themedContext(tester),
        enabled: true,
        style: const CoreTextFieldStyle(height: 36),
      );
      expect(boxMin(r), isNull);
      expect(boxProp(r, 'height'), '${36 / kRemDivisor}rem');
      // The input inside is not given the height a second time — the box is
      // border-box, so a height on both would make it two borders taller.
      expect(r.input.inlineStyles?.properties['height'], isNull);
    });

    testComponents('minHeight 0 (chromeless compositions) removes it', (
      tester,
    ) async {
      final r = _resolve(
        _themedContext(tester),
        enabled: true,
        style: const CoreTextFieldStyle(minHeight: 0),
      );
      expect(boxMin(r), isNull);
    });

    testComponents('the chromeless Core styles all state minHeight 0', (
      tester,
    ) async {
      for (final style in [
        CoreChipInputStyle.chromelessFieldStyle,
        CorePhoneInputStyle.chromelessFieldStyle,
        CoreObjectInputStyle.defaultFieldInputStyle,
        CoreFormattedInputStyle.defaultSegmentInputStyle,
      ]) {
        final r = _resolve(_themedContext(tester), enabled: true, style: style);
        expect(boxMin(r), isNull);
      }
    });

    testComponents("max-height is the box's cap, not the input's", (
      tester,
    ) async {
      const style = CoreTextFieldStyle(maxHeight: 120);
      final r = _resolve(_themedContext(tester), enabled: true, style: style);
      const cap = '${120 / kRemDivisor}rem';
      expect(boxProp(r, 'max-height'), cap);
      expect(r.input.inlineStyles?.properties['max-height'], isNull);
      // The floor is the size row's, capped by the stated maximum in CSS —
      // a cap above it leaves the row where it was, under any density the
      // row variable moves it to.
      expect(boxMin(r), 'min($md, $cap)');
    });

    testComponents('a fixed height keeps a caller minHeight', (tester) async {
      final r = _resolve(
        _themedContext(tester),
        enabled: true,
        style: const CoreTextFieldStyle(height: 36, minHeight: 44),
      );
      expect(boxProp(r, 'height'), '${36 / kRemDivisor}rem');
      expect(boxMin(r), '${44 / kRemDivisor}rem');
    });

    testComponents('a rendered ChipInput entry carries no floor', (
      tester,
    ) async {
      pumpWithTheme(tester, const ChipInput());
      final inputs = _dom(tester).where((c) => c.tag == 'input');
      expect(inputs, isNotEmpty);
      for (final input in inputs) {
        expect(input.styles?.properties['min-height'], isNull);
      }
    });

    testComponents('a caller maxHeight below the floor caps it', (
      tester,
    ) async {
      final r = _resolve(
        _themedContext(tester),
        enabled: true,
        style: const CoreTextFieldStyle(maxHeight: 38),
      );
      // `min()` of the row and the cap: 38 at the md row's 40, and the row
      // itself once a density moves it under the cap — the moved floor
      // capped, which is what Flutter computes.
      expect(boxMin(r), 'min($md, ${38 / kRemDivisor}rem)');
    });
  });

  // A `plain` field states a transparent border, so it emits no `border`
  // colour class — yet the inline `border-width` is still written. With
  // preflight off the box then falls back to the browser's own grey border
  // style and colour and draws that 1px (seen on the `Command` search row,
  // and on a `ChipInput` entry once its field is framed). The wrapper states
  // the style and a transparent colour, which keeps the pixel and keeps it
  // invisible.
  group('TextField plain — the resting border is transparent, not the '
      "browser's", () {
    ResolvedTextField resolve(
      BuildContext context, {
      CoreTextFieldVariant? variant,
      CoreTextFieldStyle? style,
      bool enabled = true,
    }) => resolveTextField(
      context,
      scopeId: 'tf',
      size: CoreComponentSize.md,
      expands: false,
      hasError: false,
      enabled: enabled,
      variant: variant,
      textFieldStyle: style,
    );

    List<String> boxClasses(
      BuildContext context, {
      CoreTextFieldVariant? variant,
      CoreTextFieldStyle? style,
    }) => resolve(
      context,
      variant: variant,
      style: style,
    ).affixWrapper.className.split(' ');

    testComponents(
      'plain states the border style and a transparent colour — nothing '
      'is left for the browser default to draw',
      (tester) async {
        final classes = boxClasses(
          _themedContext(tester),
          variant: CoreTextFieldVariant.plain,
        );

        expect(classes, containsAll(['border-solid', 'border-transparent']));
        expect(
          classes.where((c) => c.startsWith('border-outline')),
          isEmpty,
          reason: 'plain draws no outline-coloured edge',
        );
      },
    );

    testComponents(
      'plain keeps the 1px it always took — the inline width is unchanged',
      (tester) async {
        final resolved = resolve(
          _themedContext(tester),
          variant: CoreTextFieldVariant.plain,
        );

        expect(
          resolved.affixWrapper.inlineStyles?.properties['border-width'],
          strokeWidthCss(CoreTextFieldStyle.defaultBorderWidth),
        );
      },
    );

    testComponents(
      'plain stays chromeless when disabled — no disabled border class, the '
      'transparent base holds (the host draws the disabled box)',
      (tester) async {
        final context = _themedContext(tester);
        final disabled = resolve(
          context,
          variant: CoreTextFieldVariant.plain,
          enabled: false,
        );
        final classes = disabled.affixWrapper.className.split(' ');

        expect(classes, contains('border-transparent'));
        expect(
          classes.where((c) => c.startsWith('border-disabled')),
          isEmpty,
        );
        expect(
          disabled.input.className.split(' '),
          contains('disabled:text-disabled-content'),
        );
      },
    );

    testComponents(
      'the input paints no fill — rest, hover and disabled all ride the box, '
      'so the box wash and the disabled tone are one rectangle',
      (tester) async {
        final context = _themedContext(tester);
        final input = resolve(context).input.className.split(' ');

        expect(input, contains('bg-transparent'));
        expect(
          input.where((c) => c.startsWith('bg-') && c != 'bg-transparent'),
          isEmpty,
        );
        expect(
          input.where(
            (c) => c.startsWith('hover:bg-') || c.startsWith('disabled:bg-'),
          ),
          isEmpty,
        );
      },
    );

    testComponents(
      'the box carries the disabled fill, and no hover step over it',
      (tester) async {
        final context = _themedContext(tester);
        List<String> box({required bool enabled}) => resolve(
          context,
          enabled: enabled,
        ).affixWrapper.className.split(' ');

        expect(box(enabled: true), contains('bg-surface'));

        final disabled = box(enabled: false);
        expect(disabled, contains('bg-disabled-container'));
        expect(disabled, isNot(contains('bg-surface')));
        expect(disabled.where((c) => c.startsWith('hover:bg-')), isEmpty);
      },
    );

    testComponents('the boxed default variant is untouched', (tester) async {
      final classes = boxClasses(_themedContext(tester));

      expect(classes, containsAll(['border', 'border-outline-variant']));
      expect(classes, isNot(contains('border-transparent')));
      expect(classes, isNot(contains('border-solid')));
    });

    testComponents(
      'the Command search field — plain with its focus tint switched off — '
      'is transparent at rest and grows no border on focus',
      (tester) async {
        final context = _themedContext(tester);
        final classes = boxClasses(
          context,
          variant: CoreTextFieldVariant.plain,
          style: resolveCommand(context).searchFieldStyle,
        );

        expect(classes, containsAll(['border-solid', 'border-transparent']));
        expect(
          classes.where(
            (c) =>
                c.startsWith('focus-visible:border-') ||
                c.startsWith('focus-within:border-'),
          ),
          isEmpty,
        );
      },
    );

    testComponents(
      'a stated focus colour tints the box on focus, a transparent one does '
      'not',
      (tester) async {
        final context = _themedContext(tester);
        final green = boxClasses(
          context,
          style: const CoreTextFieldStyle(
            focusBorderColor: CoreColor.token(CoreColors.tertiary),
          ),
        );
        final none = boxClasses(
          context,
          style: const CoreTextFieldStyle(
            focusBorderColor: CoreColor.transparent,
          ),
        );

        expect(green, contains('focus-within:border-tertiary'));
        expect(green, isNot(contains('focus-within:border-primary')));
        expect(
          none.where((c) => c.startsWith('focus-within:border-')),
          isEmpty,
        );
      },
    );
  });
}
