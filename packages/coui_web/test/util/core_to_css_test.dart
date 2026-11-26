import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  group('CoreColorToCss.toValue (regression #2122)', () {
    test('token emits rgb(var(--coui-<token>)), not the undefined '
        'var(--color-X) that rendered transparent', () {
      // Before the fix this returned `var(--color-primary)`, a variable
      // that is never defined (only `--coui-*` exists) → transparent.
      expect(
        const CoreColor.token(CoreColors.primary).toValue(),
        'rgb(var(--coui-primary))',
      );
    });

    test('token with opacity emits rgb(var(--coui-X) / NN%)', () {
      expect(
        const CoreColor.token(CoreColors.primary, opacity: 0.5).toValue(),
        'rgb(var(--coui-primary) / 50%)',
      );
    });

    test('raw ARGB colour still emits rgb()/rgba()', () {
      expect(const CoreColor(0xFF4273D7).toValue(), 'rgb(66, 115, 215)');
    });
  });

  group('emitColor (a fixed slot, with and without an alpha)', () {
    test('a fixed slot emits its class, nothing inline', () {
      for (final (slot, name) in [
        (CoreColors.primaryFixedDim, 'primary-fixed-dim'),
        (CoreColors.onPrimaryFixed, 'on-primary-fixed'),
        (CoreColors.onPrimaryFixedVariant, 'on-primary-fixed-variant'),
        (CoreColors.secondaryFixed, 'secondary-fixed'),
        (CoreColors.scrim, 'scrim'),
      ]) {
        final emit = emitColor(
          CoreColor.token(slot),
          CoreColor.transparent,
          .background,
        );
        expect(emit.className, 'bg-$name');
        expect(emit.inline, isNull);
        expect(
          emitColor(
            CoreColor.token(slot),
            CoreColor.transparent,
            .border,
          ).className,
          'border-$name',
        );
      }
    });

    test('an alpha rides the class as the opacity modifier', () {
      // The alpha belongs to the colour: a token states its own opacity and
      // the class carries it as the modifier.
      final faint = emitColor(
        const CoreColor.token(CoreColors.secondaryFixed, opacity: 0.55),
        CoreColor.transparent,
        .background,
      );
      expect(faint.className, 'bg-secondary-fixed/55');
      expect(faint.inline, isNull);

      final strong = emitColor(
        const CoreColor.token(CoreColors.secondaryFixed, opacity: 0.9),
        CoreColor.transparent,
        .background,
      );
      expect(strong.className, 'bg-secondary-fixed/90');
    });

    test('the same colour inline spells the alpha as a slash percent', () {
      expect(
        const CoreColor.token(
          CoreColors.secondaryFixed,
          opacity: 0.55,
        ).toValue(),
        'rgb(var(--coui-secondary-fixed) / 55%)',
      );
      expect(
        const CoreColor.token(
          CoreColors.secondaryFixed,
          opacity: 0.9,
        ).toValue(),
        'rgb(var(--coui-secondary-fixed) / 90%)',
      );
      expect(
        const CoreColor.token(CoreColors.scrim).toValue(),
        'rgb(var(--coui-scrim))',
      );
    });

    test('a raw colour is inline, never a class Tailwind cannot read', () {
      final emit = emitColor(
        const CoreColor(0x80FFFFFF),
        CoreColor.transparent,
        .background,
      );
      expect(emit.className, '');
      expect(emit.inline, {'background-color': 'rgba(255, 255, 255, 0.50)'});
    });
  });

  group('emitStrokeWidth (override-keyed class XOR inline)', () {
    test('no override emits the default stroke class, no inline', () {
      final emit = emitStrokeWidth(null, CoreStrokeWidth.stroke1);
      expect(emit.className, 'border-${CoreStrokeWidth.scale.stroke1}');
      expect(emit.inline, isNull);
    });

    test('an off-scale override goes inline as px, never throws', () {
      final emit = emitStrokeWidth(1.25, CoreStrokeWidth.stroke1);
      expect(emit.className, isEmpty);
      expect(emit.inline, {'border-width': '1.25px'});
    });

    test('a token override stays on the stroke variable', () {
      final emit = emitStrokeWidth(
        CoreStrokeWidth.stroke2,
        CoreStrokeWidth.stroke1,
      );
      expect(emit.className, isEmpty);
      expect(emit.inline, {'border-width': 'var(--coui-stroke-width-2)'});
    });
  });

  group('emitTypography (role + overlay)', () {
    test('pure role → class only, no inline (backward-compatible)', () {
      // A token default with no scalar overlay and no value override emits
      // the role class with `inline == null` — the badge case, unchanged by
      // the role+overlay enhancement.
      final emit = emitTypography(
        null,
        const CoreTextStyle.token(CoreTextStyles.labelMedium),
      );
      expect(emit.className, 'text-label-medium');
      expect(emit.inline, isNull);
    });

    test('pure role + token colour → both stay on classes, no inline', () {
      final emit = emitTypography(
        null,
        const CoreTextStyle.token(
          CoreTextStyles.bodyMedium,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      );
      expect(emit.className, 'text-body-medium text-on-surface');
      expect(emit.inline, isNull);
    });

    test(
      'role + explicit fontSize overlay → role class + font-size inline',
      () {
        // The chip case: one role pinned across sizes (`bodySmall`) with a
        // per-size `fontSize`. The role emits a class (dark-mode reactive)
        // while only the explicit overlay emits inline.
        final emit = emitTypography(
          const CoreTextStyle(fontSize: 14),
          const CoreTextStyle.token(CoreTextStyles.bodySmall),
        );
        expect(emit.className, 'text-body-small');
        expect(emit.inline, {'font-size': '0.875rem'});
      },
    );

    test('role + multiple explicit overlays → role class + all overlays '
        'inline (no role-derived fields leak)', () {
      // A token-bound style stores ONLY the role id; the role's own
      // fontWeight / lineHeight stay null until render. So only the
      // explicit fontSize + fontWeight surface inline — never the role's.
      final emit = emitTypography(
        const CoreTextStyle(fontSize: 14, fontWeight: CoreFontWeight.bold),
        const CoreTextStyle.token(CoreTextStyles.bodySmall),
      );
      expect(emit.className, 'text-body-small');
      expect(emit.inline, {'font-size': '0.875rem', 'font-weight': '700'});
    });

    test('role + token colour + scalar overlay → colour on class, scalar '
        'inline (colour omitted from inline)', () {
      final emit = emitTypography(
        const CoreTextStyle(fontSize: 14),
        const CoreTextStyle.token(
          CoreTextStyles.bodySmall,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      );
      expect(emit.className, 'text-body-small text-on-surface');
      expect(emit.inline, {'font-size': '0.875rem'});
    });

    test('role + raw colour overlay → role class + raw colour inline', () {
      // A raw (non-token) colour has no utility class, so it goes inline
      // alongside the role class.
      final emit = emitTypography(
        const CoreTextStyle(color: CoreColor(0xFF112233)),
        const CoreTextStyle.token(CoreTextStyles.bodySmall),
      );
      expect(emit.className, 'text-body-small');
      expect(emit.inline, {'color': 'rgb(17, 34, 51)'});
    });

    test('arbitrary (no role token) → empty class, everything inline', () {
      final emit = emitTypography(
        const CoreTextStyle(fontSize: 17),
        const CoreTextStyle(fontSize: 12),
      );
      expect(emit.className, '');
      expect(emit.inline, {
        'font-size': '1.0625rem',
        // A size alone draws the multiplier it inherits at its own size, on
        // a whole pixel as Flutter's engine lays the line out.
        'line-height': 'round(nearest, calc(var(--coui-leading) * 1em), 1px)',
      });
    });
  });

  group('CoreTextStyleToInlineCss.toInlineCss (typography units)', () {
    // `CoreTextStyle.letterSpacing` is stored as an em ratio (the same value
    // Flutter multiplies by the font size). The role variable
    // `--coui-text-{role}-tracking` is emitted in `em`, so an explicit
    // overlay must also come out in `em` — pushing the ratio through the
    // px→rem divisor would silently shrink -0.01em to -0.000625rem.
    test('letterSpacing −0.01 → letter-spacing: -0.01em (not rem)', () {
      expect(
        const CoreTextStyle(letterSpacing: -0.01).toInlineCss(),
        {'letter-spacing': '-0.01em'},
      );
    });

    test('letterSpacing token ratio stays in em on a role overlay', () {
      final emit = emitTypography(
        const CoreTextStyle(letterSpacing: CoreLetterSpacing.tight),
        const CoreTextStyle.token(CoreTextStyles.bodyMedium),
      );
      expect(emit.className, 'text-body-medium');
      expect(emit.inline, {'letter-spacing': '${CoreLetterSpacing.tight}em'});
    });

    // Flutter's engine lays every line out at a whole pixel, so the box a
    // multiplier makes is drawn rounded — and the multiplier itself is what
    // the text below it inherits, as Flutter's `DefaultTextStyle` hands it
    // down.
    test('a multiplier draws its box on a whole pixel and hands itself '
        'down', () {
      expect(const CoreTextStyle(lineHeight: 1.3).toInlineCss(), {
        'line-height': 'round(nearest, calc(1.3 * 1em), 1px)',
        '--coui-leading': '1.3',
      });
    });

    // A fixed line box is a length, not a ratio: it goes through rem like
    // `font-size`, so the box follows the browser's text size the way
    // Flutter's `height = lineHeightPx / fontSize` follows the text scaler.
    test('lineHeightPx is a length — emitted in rem, never px', () {
      expect(
        const CoreTextStyle(lineHeightPx: CoreLineBox.px21).toInlineCss(),
        {'line-height': 'round(nearest, 1.3125rem, 1px)'},
      );
    });

    test('lineHeightPx wins over a multiplier stated beside it', () {
      expect(
        const CoreTextStyle(
          lineHeight: CoreLineHeight.h140,
          lineHeightPx: CoreLineBox.px21,
        ).toInlineCss()['line-height'],
        'round(nearest, 1.3125rem, 1px)',
      );
    });

    test('a lineHeightPx overlay on a role goes inline beside the class', () {
      final emit = emitTypography(
        const CoreTextStyle(lineHeightPx: CoreLineBox.px21),
        const CoreTextStyle.token(CoreTextStyles.bodyMedium),
      );
      expect(emit.className, 'text-body-medium');
      expect(emit.inline, {'line-height': 'round(nearest, 1.3125rem, 1px)'});
    });

    test('a multiplier overlay on a code role replaces its box inline', () {
      // The role's box rides its class (`--coui-text-code-sm-line-height`);
      // the stated multiplier is the newer statement, so it is drawn.
      final emit = emitTypography(
        const CoreTextStyle(lineHeight: CoreLineHeight.h140),
        const CoreTextStyle.token(CoreTextStyles.codeSm),
      );
      expect(emit.className, 'text-code-sm');
      expect(emit.inline, {
        'line-height':
            'round(nearest, calc(${CoreLineHeight.h140} * 1em), 1px)',
        '--coui-leading': '${CoreLineHeight.h140}',
      });
    });

    test('a size overlay on a code role leaves the box on the class', () {
      final emit = emitTypography(
        const CoreTextStyle(fontSize: CoreFontSize.s14),
        const CoreTextStyle.token(CoreTextStyles.codeSm),
      );
      expect(emit.className, 'text-code-sm');
      expect(emit.inline, {'font-size': '0.875rem'});
    });
  });

  group('CoreTextStyleToTailwindRole.tailwindTypographyRole', () {
    test('every coui role maps back to its own token name', () {
      // The lookup is by identity, so two field-identical roles would be
      // one const instance and the later one would read as the earlier.
      // Walking every token pins that each role is its own instance.
      for (final token in CoreTextStyles.values) {
        expect(
          token.read(CoreTypography.coui).tailwindTypographyRole,
          token.name,
          reason: 'role ${token.name}',
        );
      }
    });

    test('the new roles have keys', () {
      const scale = CoreTypography.coui;
      expect(scale.bodyXs.tailwindTypographyRole, 'body-xs');
      expect(scale.labelXs.tailwindTypographyRole, 'label-xs');
      expect(scale.codeXs.tailwindTypographyRole, 'code-xs');
      expect(scale.codeSm.tailwindTypographyRole, 'code-sm');
      expect(scale.codeMd.tailwindTypographyRole, 'code-md');
    });

    test('a style that is not a coui role throws', () {
      expect(
        () => const CoreTextStyle(
          fontSize: CoreFontSize.s13,
        ).tailwindTypographyRole,
        throwsArgumentError,
      );
    });
  });

  group('CoreBorderRadiusToCss.outsetValue (radius around a border)', () {
    test('a scale corner stays a variable reference, grown with calc()', () {
      expect(
        const CoreBorderRadius.all(CoreRadius.radius4).outsetValue(2),
        'calc(var(--coui-radius-4) + 0.125rem) '
        'calc(var(--coui-radius-4) + 0.125rem) '
        'calc(var(--coui-radius-4) + 0.125rem) '
        'calc(var(--coui-radius-4) + 0.125rem)',
      );
    });

    test('an off-scale corner grows from its px literal', () {
      expect(
        const CoreBorderRadius.all(7).outsetValue(2),
        'calc(7.0px + 0.125rem) calc(7.0px + 0.125rem) '
        'calc(7.0px + 0.125rem) calc(7.0px + 0.125rem)',
      );
    });

    test('corners keep their own radius and the same order as toValue()', () {
      const radius = CoreBorderRadius.only(
        topLeft: CoreRadius.radius2,
        topRight: CoreRadius.radius4,
        bottomRight: CoreRadius.radius8,
        bottomLeft: CoreRadius.radius12,
      );

      expect(
        radius.outsetValue(1),
        'calc(var(--coui-radius-2) + 0.0625rem) '
        'calc(var(--coui-radius-4) + 0.0625rem) '
        'calc(var(--coui-radius-8) + 0.0625rem) '
        'calc(var(--coui-radius-12) + 0.0625rem)',
      );
    });
  });

  group('strokeWidthCss (px-fixed border-width value)', () {
    test('token width → px-valued CSS variable, never rem', () {
      // A token width flows through the px-valued `--coui-stroke-width-N`
      // variable so a designer override reaches every component; it must
      // never be `${x / 16}rem`.
      expect(
        strokeWidthCss(CoreStrokeWidth.stroke1),
        'var(--coui-stroke-width-1)',
      );
      expect(
        strokeWidthCss(CoreStrokeWidth.stroke2),
        'var(--coui-stroke-width-2)',
      );
      expect(
        strokeWidthCss(CoreStrokeWidth.stroke0),
        'var(--coui-stroke-width-0)',
      );
      expect(
        strokeWidthCss(CoreStrokeWidth.stroke0_5),
        'var(--coui-stroke-width-0_5)',
        reason: 'the hairline is a token step, not an arbitrary 0.5px',
      );
      expect(
        strokeWidthCss(CoreStrokeWidth.stroke8),
        'var(--coui-stroke-width-8)',
      );
    });

    test('arbitrary width → literal px (never rem)', () {
      // The exact regression this migration fixes: an off-token width must
      // emit px, not rem, so browser text-scale never thickens the stroke.
      expect(strokeWidthCss(1.25), '1.25px');
    });

    test('the active-boundary step 1.5 is a token, on its variable', () {
      expect(
        strokeWidthCss(CoreStrokeWidth.stroke1_5),
        'var(--coui-stroke-width-1_5)',
      );
      expect(
        CoreStrokeWidth.stroke1_5.tailwindStroke,
        CoreStrokeWidth.scale.stroke1_5,
      );
    });

    test('integer arbitrary width renders without a trailing .0', () {
      // 7 sits between two steps (no `CoreStrokeWidth.stroke7`) and must
      // read `7px`, not `7.0px` — the shape a hand-written `${w}px` has.
      expect(strokeWidthCss(7), '7px');
    });

    test('the 5px step is a token, on its variable', () {
      // Between `stroke4` and `stroke6`: the selected ring of the `lg` and
      // `xl` radio buttons. Off its variable it would emit a literal `5px`
      // that a surface style's stroke floor could never move.
      expect(
        strokeWidthCss(CoreStrokeWidth.stroke5),
        'var(--coui-stroke-width-5)',
      );
      expect(
        CoreStrokeWidth.stroke5.tailwindStroke,
        CoreStrokeWidth.scale.stroke5,
      );
    });

    test('byte-identical to the old rem at the default 16px root', () {
      // stroke1 == 1px; `--coui-stroke-width-1` holds `1px`; the old code
      // emitted `1 / 16 rem` == 1px at the default root. Same rendered px,
      // now fixed against text-scale.
      expect(CoreStrokeWidth.stroke1, 1.0);
    });
  });

  group('tailwindStroke (stroke token → Tailwind class key)', () {
    test('the hairline maps to its own key', () {
      expect(CoreStrokeWidth.stroke0_5.tailwindStroke, 'stroke0_5');
    });

    test('every token step maps to its scale key', () {
      expect(CoreStrokeWidth.stroke0.tailwindStroke, 'stroke0');
      expect(CoreStrokeWidth.stroke1.tailwindStroke, 'stroke1');
      expect(CoreStrokeWidth.stroke5.tailwindStroke, 'stroke5');
      expect(CoreStrokeWidth.stroke8.tailwindStroke, 'stroke8');
    });

    test('a width off the scale still throws', () {
      expect(() => 0.75.tailwindStroke, throwsArgumentError);
    });
  });

  group('pictureStrokeCss (px-fixed stroke of a drawing)', () {
    test('a width on a stroke step stays a literal px, never a variable', () {
      // The step would be a `--coui-stroke-width-N` reference through
      // `strokeWidthCss`, which a surface style's stroke floor moves.
      expect(pictureStrokeCss(CoreStrokeWidth.stroke1), '1px');
      expect(pictureStrokeCss(CoreStrokeWidth.stroke2), '2px');
      expect(pictureStrokeCss(CoreStrokeWidth.stroke0), '0px');
    });

    test('a fractional width keeps its fraction', () {
      expect(pictureStrokeCss(0.5), '0.5px');
      expect(pictureStrokeCss(0.7562189054726368), '0.7562189054726368px');
    });
  });

  group('emitPseudoColor (class-vs-scoped-rule)', () {
    test('token override → Tailwind pseudo class, no rule', () {
      final emit = emitPseudoColor(
        const CoreColor.token(CoreColors.primary),
        const CoreColor.token(CoreColors.surface),
        ColorTarget.background,
        pseudo: WebPseudo.hover,
        scopeSelector: '#co-x-1',
      );
      expect(emit.className, 'hover:bg-primary');
      expect(emit.rule, '');
    });

    test('null override → falls back to the token default class', () {
      final emit = emitPseudoColor(
        null,
        const CoreColor.token(CoreColors.surface),
        ColorTarget.background,
        pseudo: WebPseudo.hover,
        scopeSelector: '#co-x-1',
      );
      expect(emit.className, 'hover:bg-surface');
      expect(emit.rule, '');
    });

    test('raw override → scoped CSS rule, empty class (no throw)', () {
      final emit = emitPseudoColor(
        const CoreColor(0xFF4273D7),
        const CoreColor.token(CoreColors.surface),
        ColorTarget.background,
        pseudo: WebPseudo.hover,
        scopeSelector: '#co-x-1',
      );
      expect(emit.className, '');
      expect(emit.rule, '#co-x-1:hover{background-color: rgb(66, 115, 215);}');
    });

    // The guarded hover steps: the exclusion lives in the selector itself, so
    // the focused state wins whatever order Tailwind emits the utilities in.
    test('hoverUnlessFocusWithin → arbitrary-variant class / guarded rule', () {
      final token = emitPseudoColor(
        const CoreColor.token(CoreColors.onSurface),
        const CoreColor.token(CoreColors.outline),
        ColorTarget.border,
        pseudo: WebPseudo.hoverUnlessFocusWithin,
        scopeSelector: '.co-x-1',
      );
      expect(token.className, '[&:hover:not(:focus-within)]:border-on-surface');
      expect(token.rule, '');

      final raw = emitPseudoColor(
        const CoreColor(0xFF4273D7),
        const CoreColor.token(CoreColors.outline),
        ColorTarget.border,
        pseudo: WebPseudo.hoverUnlessFocusWithin,
        scopeSelector: '.co-x-1',
      );
      expect(raw.className, '');
      expect(
        raw.rule,
        '.co-x-1:hover:not(:focus-within){border-color: rgb(66, 115, 215);}',
      );
    });

    test('hoverUnlessFocus → arbitrary-variant class / guarded rule', () {
      final token = emitPseudoColor(
        null,
        const CoreColor.token(CoreColors.onSurface),
        ColorTarget.border,
        pseudo: WebPseudo.hoverUnlessFocus,
        scopeSelector: '.co-x-1',
      );
      expect(token.className, '[&:hover:not(:focus)]:border-on-surface');
      expect(token.rule, '');

      final raw = emitPseudoColor(
        const CoreColor(0xFF4273D7),
        const CoreColor.token(CoreColors.onSurface),
        ColorTarget.border,
        pseudo: WebPseudo.hoverUnlessFocus,
        scopeSelector: '.co-x-1',
      );
      expect(
        raw.rule,
        '.co-x-1:hover:not(:focus){border-color: rgb(66, 115, 215);}',
      );
    });

    // An INLINE declaration outranks every selector, so a pseudo state on an
    // element that also carries the property inline compiles, matches, and
    // never paints — unless it is `!important`.
    test('important → Tailwind `!` modifier / `!important` declaration', () {
      final token = emitPseudoColor(
        const CoreColor.token(CoreColors.primary),
        const CoreColor.token(CoreColors.surface),
        ColorTarget.border,
        pseudo: WebPseudo.hover,
        scopeSelector: '#co-x-1',
        important: true,
      );
      expect(token.className, 'hover:!border-primary');
      expect(token.rule, '');

      final raw = emitPseudoColor(
        const CoreColor(0xFF4273D7),
        const CoreColor.token(CoreColors.surface),
        ColorTarget.border,
        pseudo: WebPseudo.hover,
        scopeSelector: '#co-x-1',
        important: true,
      );
      expect(raw.className, '');
      expect(
        raw.rule,
        '#co-x-1:hover{border-color: rgb(66, 115, 215) !important;}',
      );
    });

    test('important defaults to false — existing output is unchanged', () {
      final emit = emitPseudoColor(
        const CoreColor(0xFF4273D7),
        const CoreColor.token(CoreColors.surface),
        ColorTarget.background,
        pseudo: WebPseudo.hover,
        scopeSelector: '#co-x-1',
      );
      expect(emit.rule, isNot(contains('important')));
    });

    test('raw override on text target under focus-visible', () {
      final emit = emitPseudoColor(
        const CoreColor(0xFF112233),
        const CoreColor.token(CoreColors.onSurface),
        ColorTarget.text,
        pseudo: WebPseudo.focusVisible,
        scopeSelector: '#co-x-2',
      );
      expect(emit.className, '');
      expect(
        emit.rule,
        '#co-x-2:focus-visible{color: rgb(17, 34, 51);}',
      );
    });

    test('group-focus-visible raw override uses ancestor combinator', () {
      final emit = emitPseudoColor(
        const CoreColor(0xFF010203),
        const CoreColor.token(CoreColors.primary),
        ColorTarget.border,
        pseudo: WebPseudo.groupFocusVisible,
        scopeSelector: '.co-dot-3',
      );
      expect(
        emit.rule,
        '.group:focus-visible .co-dot-3{border-color: rgb(1, 2, 3);}',
      );
    });

    test('peer-disabled raw override uses sibling combinator', () {
      final emit = emitPseudoColor(
        const CoreColor(0xFF040506),
        const CoreColor.token(CoreColors.onSurface),
        ColorTarget.text,
        pseudo: WebPseudo.peerDisabled,
        scopeSelector: '#co-x-4',
      );
      expect(
        emit.rule,
        '.peer:disabled ~ #co-x-4{color: rgb(4, 5, 6);}',
      );
    });
  });

  group('focusRing class-safe vs scoped rule', () {
    test(
      'token colour + transparent band + opacity 1 + scale steps → class-safe',
      () {
        expect(
          focusRingIsClassSafe(
            ringColor: const CoreColor.token(CoreColors.primary),
            offsetColor: CoreFocusRing.ringOffsetColor,
            ringOpacity: 1,
            ringWidth: 2,
            ringOffset: 2,
          ),
          isTrue,
        );
      },
    );

    test('raw ring colour → not class-safe (needs scoped rule)', () {
      expect(
        focusRingIsClassSafe(
          ringColor: const CoreColor(0xFF4273D7),
          offsetColor: CoreFocusRing.ringOffsetColor,
          ringOpacity: 1,
          ringWidth: 2,
          ringOffset: 2,
        ),
        isFalse,
      );
    });

    test('sub-1 ring opacity → not class-safe', () {
      expect(
        focusRingIsClassSafe(
          ringColor: const CoreColor.token(CoreColors.primary),
          offsetColor: CoreFocusRing.ringOffsetColor,
          ringOpacity: 0.5,
          ringWidth: 2,
          ringOffset: 2,
        ),
        isFalse,
      );
    });

    test('off-scale ring width → not class-safe', () {
      expect(
        focusRingIsClassSafe(
          ringColor: const CoreColor.token(CoreColors.primary),
          offsetColor: CoreFocusRing.ringOffsetColor,
          ringOpacity: 1,
          ringWidth: 3,
          ringOffset: 2,
        ),
        isFalse,
      );
    });

    test('fractional ring width → not class-safe (#3993)', () {
      // `2.5.toInt()` is 2, which IS a scale step — so a truncating gate
      // called this class-safe and emitted `ring-2`, rendering 2px where
      // 2.5px was asked for. Nothing in the output said so.
      expect(
        focusRingIsClassSafe(
          ringColor: const CoreColor.token(CoreColors.primary),
          offsetColor: CoreFocusRing.ringOffsetColor,
          ringOpacity: 1,
          ringWidth: 2.5,
          ringOffset: 2,
        ),
        isFalse,
      );
    });

    test('fractional ring offset → not class-safe (#3993)', () {
      // The offset truncates identically — the guard is per-number, so
      // guarding only the width leaves this half of the pair broken.
      expect(
        focusRingIsClassSafe(
          ringColor: const CoreColor.token(CoreColors.primary),
          offsetColor: CoreFocusRing.ringOffsetColor,
          ringOpacity: 1,
          ringWidth: 2,
          ringOffset: 2.5,
        ),
        isFalse,
      );
    });

    test('a fractional width just under a step does not snap up (#3993)', () {
      // 3.5 truncates to 3 (off-scale) so it was already rejected, but
      // 7.5 truncates to 7 — also off-scale — while 8.5 truncates to 8,
      // an on-scale step. The gate must reject by exactness, not by
      // whichever step truncation happens to land on.
      expect(
        focusRingIsClassSafe(
          ringColor: const CoreColor.token(CoreColors.primary),
          offsetColor: CoreFocusRing.ringOffsetColor,
          ringOpacity: 1,
          ringWidth: 8.5,
          ringOffset: 2,
        ),
        isFalse,
      );
    });

    test('a painted band → not class-safe (no outline utility draws it)', () {
      expect(
        focusRingIsClassSafe(
          ringColor: const CoreColor.token(CoreColors.focusRing),
          offsetColor: CoreFocusRing.opaqueOffsetColor,
          ringOpacity: 1,
          ringWidth: 2,
          ringOffset: 2,
        ),
        isFalse,
      );
      // The outline half alone is still class-expressible — a host that
      // carries its band some other way (Button's band variable) asks
      // this narrower question.
      expect(
        focusRingOutlineIsClassSafe(
          ringColor: const CoreColor.token(CoreColors.focusRing),
          ringOpacity: 1,
          ringWidth: 2,
          ringOffset: 2,
        ),
        isTrue,
      );
    });

    test('focusBandPaints — transparent default off, stated band on', () {
      expect(focusBandPaints(CoreFocusRing.ringOffsetColor), isFalse);
      expect(focusBandPaints(CoreColor.transparent), isFalse);
      expect(
        focusBandPaints(
          const CoreColor.token(CoreColors.surface, opacity: 0),
        ),
        isFalse,
      );
      expect(focusBandPaints(CoreFocusRing.opaqueOffsetColor), isTrue);
      expect(focusBandPaints(const CoreColor(0xFFFFFFFF)), isTrue);
    });

    test('focusRingClassName emits the outline width / offset / colour', () {
      expect(
        focusRingClassName(
          pseudo: WebPseudo.focusVisible,
          ringColor: const CoreColor.token(CoreColors.focusRing),
          ringWidth: 2,
          ringOffset: 2,
        ),
        'focus-visible:outline-2 focus-visible:outline-offset-2 '
        'focus-visible:outline-focus-ring',
      );
      expect(
        focusRingClassName(
          pseudo: WebPseudo.focusWithin,
          ringColor: const CoreColor.token(CoreColors.primary),
          ringWidth: 4,
          ringOffset: 0,
        ),
        'focus-within:outline-4 focus-within:outline-offset-0 '
        'focus-within:outline-primary',
      );
    });

    test('focusRingScopedRule — band-less ring is outline only', () {
      final rule = focusRingScopedRule(
        scopeSelector: '#co-x-5',
        pseudo: WebPseudo.focusVisible,
        ringColor: const CoreColor(0xFF4273D7),
        offsetColor: CoreFocusRing.ringOffsetColor,
        ringWidth: 2,
        ringOffset: 2,
        ringOpacity: 1,
      );
      expect(
        rule,
        [
          '#co-x-5{outline-color:transparent;}',
          ':where(#co-x-5){outline-style:solid;}',
          '#co-x-5:focus-visible{outline-color:rgb(66, 115, 215);',
          'outline-width:var(--coui-stroke-width-2);',
          'outline-offset:calc(4.0px - var(--coui-stroke-width-2));}',
        ].join(),
      );
      // No band — so no `box-shadow` reaches the host's own resting
      // shadow, which is the point of the transparent default.
      expect(rule, isNot(contains('box-shadow')));
    });

    test('focusRingScopedRule — the outline is on at rest, so blurring '
        'fades the colour instead of dropping outline-style', () {
      final rule = focusRingScopedRule(
        scopeSelector: '#co-x-8',
        pseudo: WebPseudo.focusVisible,
        ringColor: const CoreColor.token(CoreColors.focusRing),
        offsetColor: CoreFocusRing.ringOffsetColor,
        ringWidth: 2,
        ringOffset: 2,
        ringOpacity: 1,
      );
      // The style switch is gated on the BASE selector (rest), not the
      // focused one — and at zero specificity, so the forced-colours root
      // rule still turns it off on an unfocused element.
      expect(rule, contains(':where(#co-x-8){outline-style:solid;}'));
      expect(rule, isNot(contains(':where(#co-x-8:focus-visible)')));
    });

    test(
      'focusRingScopedRule — ring geometry is px-fixed stroke, never rem',
      () {
        // A focus ring is a line: the width rides the stroke-width variable
        // (px, preset-bent) and the gap is the outer edge minus that width,
        // so neither grows with the browser's text size.
        final rule = focusRingScopedRule(
          scopeSelector: '#co-x-9',
          pseudo: WebPseudo.focusVisible,
          ringColor: const CoreColor.token(CoreColors.focusRing),
          offsetColor: CoreFocusRing.opaqueOffsetColor,
          ringWidth: 3,
          ringOffset: 1,
          ringOpacity: 1,
        );
        expect(rule, isNot(contains('rem')));
        expect(rule, contains('outline-width:var(--coui-stroke-width-3);'));
        expect(
          rule,
          contains('outline-offset:calc(4.0px - var(--coui-stroke-width-3));'),
        );
      },
    );

    test('focusRingScopedRule — a painted band is one box-shadow layer '
        'composed over the host rest shadow', () {
      final rule = focusRingScopedRule(
        scopeSelector: '.co-sl-1',
        pseudo: WebPseudo.focusVisible,
        ringColor: const CoreColor.token(CoreColors.focusRing),
        offsetColor: CoreFocusRing.opaqueOffsetColor,
        ringWidth: 2,
        ringOffset: 2,
        ringOpacity: 1,
        target: ' .box',
        restShadow: 'var(--coui-surface-rim)',
      );
      expect(
        rule,
        [
          '.co-sl-1 .box{outline-color:transparent;}',
          ':where(.co-sl-1 .box){outline-style:solid;}',
          '.co-sl-1:focus-visible .box{',
          'outline-color:rgb(var(--coui-focus-ring));',
          'outline-width:var(--coui-stroke-width-2);',
          'outline-offset:calc(4.0px - var(--coui-stroke-width-2));',
          'box-shadow:0 0 0 calc(4.0px - var(--coui-stroke-width-2)) ',
          'rgb(var(--coui-surface)), var(--coui-surface-rim);}',
        ].join(),
      );
    });

    test('focusRingScopedRule — group ancestor pseudo keeps the base on the '
        'element', () {
      final rule = focusRingScopedRule(
        scopeSelector: '.co-dot-1',
        pseudo: WebPseudo.groupFocusVisible,
        ringColor: const CoreColor(0xFF4273D7),
        offsetColor: CoreFocusRing.ringOffsetColor,
        ringWidth: 2,
        ringOffset: 2,
        ringOpacity: 1,
      );
      expect(rule, startsWith('.co-dot-1{outline-color:transparent;}'));
      expect(rule, contains(':where(.co-dot-1){outline-style:solid;}'));
      expect(rule, contains('.group:focus-visible .co-dot-1{'));
    });

    test('focusRingScopedRule scales ring colour alpha by ringOpacity', () {
      final rule = focusRingScopedRule(
        scopeSelector: '#co-x-6',
        pseudo: WebPseudo.focusVisible,
        ringColor: const CoreColor.token(CoreColors.primary),
        offsetColor: CoreFocusRing.ringOffsetColor,
        ringWidth: 2,
        ringOffset: 2,
        ringOpacity: 0.5,
      );
      expect(rule, contains('rgb(var(--coui-primary) / 50%)'));
    });

    test('focusBandShadow spreads by the gap it is given', () {
      expect(
        focusBandShadow(
          offsetColor: CoreFocusRing.opaqueOffsetColor,
          gap: focusRingGeometryCss(ringWidth: 2, ringOffset: 2).offset,
        ),
        '0 0 0 calc(4.0px - var(--coui-stroke-width-2)) '
        'rgb(var(--coui-surface))',
      );
    });

    test('the class-path offset value is the variable outline-offset-2 '
        'resolves to, Tailwind px elsewhere', () {
      expect(focusRingClassOffsetCss(2), 'var(--coui-ring-offset)');
      expect(focusRingClassOffsetCss(4), '4px');
    });

    test('focusRingGeometryCss — an off-scale width is a literal, and so is '
        'its offset', () {
      final geometry = focusRingGeometryCss(ringWidth: 2.5, ringOffset: 1.5);
      expect(geometry.width, '2.5px');
      expect(geometry.offset, '1.5px');
    });

    test('focusRingDeclarations — one emitter for ring, gap and band', () {
      expect(
        focusRingDeclarations(
          ringColor: 'rgb(var(--coui-focus-ring) / 0)',
          ringWidth: 2,
          ringOffset: 2,
        ),
        {
          'outline-color': 'rgb(var(--coui-focus-ring) / 0)',
          'outline-width': 'var(--coui-stroke-width-2)',
          'outline-offset': 'calc(4.0px - var(--coui-stroke-width-2))',
        },
      );
      expect(
        focusRingDeclarations(
          ringColor: 'red',
          ringWidth: 2,
          ringOffset: 2,
          bandColor: 'white',
          restShadow: 'var(--x)',
        )['box-shadow'],
        '0 0 0 calc(4.0px - var(--coui-stroke-width-2)) white, var(--x)',
      );
    });
  });

  group('CoreGradientToCss.toValue', () {
    test('a linear gradient points from begin to end, stops in percent', () {
      const down = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor(0xFFC3C4C6), CoreColor(0xFF7D7F82)],
        stops: [0, 0.1],
        begin: CoreAlignment.topCenter,
        end: CoreAlignment.bottomCenter,
      );
      expect(
        down.toValue(),
        'linear-gradient(180deg, rgb(195, 196, 198) 0%, '
        'rgb(125, 127, 130) 10%)',
      );
      const right = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor(0xFF000000), CoreColor(0xFFFFFFFF)],
      );
      // The default direction is start → end, left to right.
      expect(
        right.toValue(),
        'linear-gradient(90deg, rgb(0, 0, 0), rgb(255, 255, 255))',
      );
      const left = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor(0xFF000000), CoreColor(0xFFFFFFFF)],
        begin: CoreAlignment.centerEnd,
        end: CoreAlignment.centerStart,
      );
      expect(left.toValue(), startsWith('linear-gradient(-90deg, '));
      const up = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor(0xFF000000), CoreColor(0xFFFFFFFF)],
        begin: CoreAlignment.bottomCenter,
        end: CoreAlignment.topCenter,
      );
      expect(up.toValue(), startsWith('linear-gradient(0deg, '));
    });

    test('a fractional stop keeps its precision, a whole one stays whole', () {
      const gradient = CoreGradient(
        type: CoreGradientType.linear,
        colors: [
          CoreColor(0xFF000000),
          CoreColor(0xFF000000),
          CoreColor(0xFF000000),
        ],
        stops: [0, 0.51, 0.125],
        begin: CoreAlignment.topCenter,
        end: CoreAlignment.bottomCenter,
      );
      expect(gradient.toValue(), contains(' 0%, '));
      expect(gradient.toValue(), contains(' 51%, '));
      expect(gradient.toValue(), endsWith(' 12.5%)'));
    });

    test('a token colour stop keeps its token and its opacity', () {
      const gradient = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor.token(CoreColors.primary, opacity: 0.5)],
        stops: [1],
        begin: CoreAlignment.topCenter,
        end: CoreAlignment.bottomCenter,
      );
      expect(
        gradient.toValue(),
        'linear-gradient(180deg, rgb(var(--coui-primary) / 50%) 100%)',
      );
    });

    test('a radial gradient is centred and reaches the nearest side', () {
      const centred = CoreGradient(
        type: CoreGradientType.radial,
        colors: [CoreColor(0xFF000000), CoreColor(0xFF0A3348)],
        stops: [0.2, 1],
        begin: CoreAlignment.center,
      );
      // Flutter's `RadialGradient` default radius is half the shortest side;
      // CSS's default `farthest-corner` would run past the box.
      const expected =
          'radial-gradient(circle closest-side at 50% 50%, '
          'rgb(0, 0, 0) 20%, rgb(10, 51, 72) 100%)';
      expect(centred.toValue(), expected);
      // `begin` is a linear anchor: left unstated (an edge-centre default) or
      // off-centre, it must not move the centre — an off-centre
      // `closest-side` has radius 0 and would paint the last stop flat.
      for (final begin in [CoreAlignment.centerStart, CoreAlignment.topStart]) {
        final other = CoreGradient(
          type: CoreGradientType.radial,
          colors: const [CoreColor(0xFF000000), CoreColor(0xFF0A3348)],
          stops: const [0.2, 1],
          begin: begin,
        );
        expect(other.toValue(), expected);
      }
    });
  });

  group('figmaLayerBlurCss', () {
    test('a Figma blur radius is twice the CSS blur, in rem', () {
      expect(kFigmaBlurRadiusToCssBlur, 0.5);
      expect(figmaLayerBlurCss(0.8), 'blur(${0.4 / 16}rem)');
      expect(figmaLayerBlurCss(16), 'blur(0.5rem)');
    });
  });

  group('emitScaledTypography', () {
    const role = CoreTextStyle.token(
      CoreTextStyles.titleSmall,
      color: CoreColor.token(CoreColors.onSurface),
    );

    test('the role keeps its class and colour; its size is shrunk inline', () {
      final emit = emitScaledTypography(null, role, factor: 0.5);
      expect(emit.className, 'text-title-small text-on-surface');
      // Read from the role's variable, so a project's own scale drives it.
      // The factor also rides `--coui-text-scale`, which the role class
      // reads only for a fixed line box (a multiplier role ignores it).
      expect(emit.inline, {
        'font-size': 'calc(var(--coui-text-title-small-size) * 0.5)',
        '--coui-text-scale': '0.5',
      });
    });

    test('a stated size is the one that is shrunk', () {
      final emit = emitScaledTypography(
        const CoreTextStyle(fontSize: 20),
        role,
        factor: 0.5,
      );
      expect(emit.className, 'text-title-small text-on-surface');
      expect(emit.inline, {
        'font-size': '${10 / 16}rem',
        '--coui-text-scale': '0.5',
      });
    });

    // #5496 — a code role's 21px box from its class shrinks with the glyphs.
    test('a line box from the role class rides the scale variable', () {
      final emit = emitScaledTypography(
        null,
        const CoreTextStyle.token(CoreTextStyles.codeMd),
        factor: 0.5,
      );
      expect(emit.className, 'text-code-md');
      expect(emit.inline, {
        'font-size': 'calc(var(--coui-text-code-md-size) * 0.5)',
        '--coui-text-scale': '0.5',
      });
    });

    test('a stated line box shrinks with the size it boxes', () {
      final emit = emitScaledTypography(
        const CoreTextStyle(
          fontSize: CoreFontSize.s12,
          lineHeightPx: CoreLineBox.px21,
        ),
        const CoreTextStyle.token(CoreTextStyles.codeSm),
        factor: 0.5,
      );
      expect(emit.className, 'text-code-sm');
      expect(emit.inline, {
        'font-size': '${12 * 0.5 / 16}rem',
        'line-height': 'round(nearest, ${21 * 0.5 / 16}rem, 1px)',
        // The box over the size is the same multiplier at either scale.
        '--coui-leading': '${21 / 12}',
      });
    });

    test('a style with no size anywhere emits nothing extra', () {
      final plain = emitTypography(
        const CoreTextStyle(fontWeight: 600),
        const CoreTextStyle(),
      );
      final scaled = emitScaledTypography(
        const CoreTextStyle(fontWeight: 600),
        const CoreTextStyle(),
        factor: 0.5,
      );
      expect(scaled.className, plain.className);
      expect(scaled.inline, plain.inline);
    });
  });
}
