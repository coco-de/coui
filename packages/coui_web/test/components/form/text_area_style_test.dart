// text_area_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/text_area/text_area_style.dart';
// The same resolver the widget's composed `FocusOutline` runs the
// forwarded slot through — the ring tests read its emitted outline
// rather than the slot, because a slot that merges correctly and never
// reaches the paint looks finished from the authoring side.
import 'package:coui_web/src/components/infra/focus_outline/focus_outline_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveTextArea` / `resolveTextAreaRules` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// A raw (token-less) colour — the exact case that used to throw
/// `token!.name` when routed onto the `::selection` pseudo-element class.
const _kRawGreen = CoreColor(0xFF00FF00);

ResolvedTextArea _resolve(
  BuildContext context, {
  bool obscureText = false,
  String obscuringCharacter = CoreTextAreaContract.defaultObscuringCharacter,
  bool? showCursor,
  CoreTextAreaStyle? textAreaStyle,
}) => resolveTextArea(
  context,
  size: CoreComponentSize.md,
  expandableHeight: false,
  expandableWidth: false,
  hasError: false,
  obscureText: obscureText,
  obscuringCharacter: obscuringCharacter,
  showCursor: showCursor,
  textAreaStyle: textAreaStyle,
);

/// Resolves the *framed* text area — the one that renders the affix
/// wrapper `<div>`, i.e. any text area with a prefix or a suffix.
///
/// The unframed text area has no wrapper element at all, so a class
/// emitted onto that wrapper reaches no DOM node there. Passing
/// `affixed: false` would make these tests pass for the wrong reason.
ResolvedTextArea _resolveAffixed(
  BuildContext context, {
  bool hasError = false,
  CoreTextAreaStyle? textAreaStyle,
}) => resolveTextArea(
  context,
  size: CoreComponentSize.md,
  expandableHeight: false,
  expandableWidth: false,
  hasError: hasError,
  obscureText: false,
  obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
  textAreaStyle: textAreaStyle,
);

/// The inline ring properties the composed `FocusOutline` emits for
/// [style] while focused — `outline-color` / `outline-width` /
/// `outline-offset`, plus `box-shadow` only when a gap band paints.
///
/// This is where the text area's one ring is actually painted, so it is
/// the only place an override can be shown to have survived.
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
  // Regression for #3469 — mirrors text_field_style_test.dart's identical
  // group: the `<textarea>` relied on `disabled:opacity-50` (contrast
  // depends on the surface behind it; forced-colours mode doesn't touch
  // opacity at all) instead of dedicated disabled colour tokens.
  group(
    'TextArea disabled textarea — dedicated colour tokens, not opacity (#3469)',
    () {
      testComponents(
        'the textarea carries disabled:border + disabled:bg + disabled:text '
        'dedicated tokens, no disabled:opacity multiplier',
        (tester) async {
          final context = _themedContext(tester);
          final textarea = _resolve(context).textarea.className;

          expect(textarea, contains('disabled:text-disabled-content'));
          expect(textarea, contains('disabled:border-disabled-outline'));
          expect(textarea, isNot(contains('disabled:opacity-50')));
          expect(textarea, contains('disabled:cursor-not-allowed'));
          expect(textarea, contains('disabled:pointer-events-none'));
        },
      );
    },
  );

  group('TextArea ::selection — default (token) path', () {
    testComponents(
      'default text area keeps the selection:bg-* utility class and emits '
      'no scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(context);
        expect(
          resolved.textarea.className,
          contains('selection:bg-primary/20'),
        );

        final rules = resolveTextAreaRules(
          context,
          scopeId: 'co-text-area-test',
          hasError: false,
        );
        expect(rules.css, isEmpty);
      },
    );

    testComponents(
      'a token selectionColor override still rides the selection:bg-* class '
      '(no scoped rule)',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreTextAreaStyle(
          selectionColor: CoreColor.token(CoreColors.tertiary),
        );
        final resolved = _resolve(context, textAreaStyle: style);
        expect(
          resolved.textarea.className,
          contains('selection:bg-tertiary/20'),
        );

        final rules = resolveTextAreaRules(
          context,
          scopeId: 'co-text-area-token',
          hasError: false,
          textAreaStyle: style,
        );
        expect(rules.css, isEmpty);
      },
    );
  });

  group('TextArea ::selection — raw override (scoped-rule) path', () {
    testComponents(
      'a raw selectionColor override no longer throws — the selection:bg-* '
      'class is dropped and the tint paints via a scoped '
      '#id::selection background-color rule instead',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreTextAreaStyle(selectionColor: _kRawGreen);

        // Before the fix this call threw a null-check on `token!.name`.
        final resolved = _resolve(context, textAreaStyle: style);
        // A raw colour has no `::selection` class surface, so the
        // `selection:bg-*` class is dropped in favour of the scoped rule.
        expect(
          resolved.textarea.className,
          isNot(contains('selection:bg-')),
        );

        final rules = resolveTextAreaRules(
          context,
          scopeId: 'co-text-area-raw',
          hasError: false,
          textAreaStyle: style,
        );
        expect(rules.css, contains('#co-text-area-raw::selection'));
        expect(rules.css, contains('background-color'));
        // 20%-alpha treatment (scaleAlpha(opacity20)) preserves the green
        // channels — emitted theme-free as an rgba() value.
        expect(rules.css, contains('0, 255, 0'));
      },
    );
  });

  group('TextArea masked rendering', () {
    /// The inline-CSS map the `<textarea>` slot carries.
    Map<String, String> inline(ResolvedTextArea resolved) =>
        resolved.textarea.inlineStyles?.properties ?? const {};

    testComponents('a plain area emits no text-security rule', (tester) async {
      // The property is absent rather than `none`: a text area that was
      // never asked to mask must render byte-identically to before.
      final resolved = _resolve(_themedContext(tester));

      expect(inline(resolved).containsKey('-webkit-text-security'), isFalse);
    });

    testComponents('an obscured area masks with the default dot', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester), obscureText: true);

      expect(inline(resolved)['-webkit-text-security'], equals('disc'));
    });

    testComponents('the mask character picks the shape that draws it', (
      tester,
    ) async {
      final context = _themedContext(tester);

      expect(
        inline(
          _resolve(context, obscureText: true, obscuringCharacter: '○'),
        )['-webkit-text-security'],
        equals('circle'),
      );
      expect(
        inline(
          _resolve(context, obscureText: true, obscuringCharacter: '■'),
        )['-webkit-text-security'],
        equals('square'),
      );
      // CSS has three shapes and no glyph slot, so a character outside
      // them still masks — as the nearest shape rather than not at all.
      expect(
        inline(
          _resolve(context, obscureText: true, obscuringCharacter: '*'),
        )['-webkit-text-security'],
        equals('disc'),
      );
    });
  });

  group('TextArea caret visibility', () {
    testComponents('showCursor: false paints a transparent caret', (
      tester,
    ) async {
      // Parity with Flutter `EditableText.showCursor: false` — the element
      // still takes input and still shows a selection.
      final resolved = _resolve(_themedContext(tester), showCursor: false);

      expect(resolved.textarea.className, contains('caret-transparent'));
    });

    testComponents('and drops the caret-colour override with it', (
      tester,
    ) async {
      // An inline `caret-color` would be a rule nothing can see.
      final resolved = _resolve(
        _themedContext(tester),
        showCursor: false,
        textAreaStyle: const CoreTextAreaStyle(
          cursorColor: CoreColor.token(CoreColors.tertiary),
        ),
      );

      expect(
        resolved.textarea.inlineStyles?.properties.containsKey('caret-color'),
        isFalse,
      );
    });

    testComponents('the default keeps the token caret', (tester) async {
      final resolved = _resolve(_themedContext(tester));

      expect(resolved.textarea.className, isNot(contains('caret-transparent')));
    });
  });

  // Regression for #4044. The affix wrapper used to paint a *second*
  // focus ring out of `focus-within:ring-*` utility classes, stacked on
  // the `FocusOutline` ring an ancestor already draws. That second ring
  // read three values and dropped all three: the width and the offset
  // were truncated to an integer scale step, and the gap band had no
  // colour class at all, so Tailwind's `#fff` default filled it in both
  // themes.
  //
  // Each test below names one of the three and asserts the class is gone
  // *and* that the value reaches the surviving ring's paint, so
  // re-introducing any single class fails exactly its own test.
  group('TextArea affix-wrapper second focus ring is gone (#4044)', () {
    testComponents(
      'a fractional ring width reaches the paint instead of truncating to '
      'the ring-2 scale step',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolveAffixed(
          context,
          textAreaStyle: const CoreTextAreaStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderWidth: _kFractionalRingWidth,
            ),
          ),
        );

        expect(
          resolved.affixWrapper.className,
          isNot(matches(RegExp(r'focus-within:ring-(?!offset)\d'))),
        );
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
          textAreaStyle: const CoreTextAreaStyle(
            focusBorderColor: CoreColor.token(CoreColors.tertiary),
          ),
        );

        expect(
          resolved.affixWrapper.className,
          isNot(matches(RegExp('focus-within:ring-(?!offset)[a-z]'))),
        );
        expect(
          _ringPaint(context, resolved.focusOutlineStyle),
          contains('var(--coui-${CoreColors.tertiary.name})'),
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
        expect(className, contains('focus-within:border-'));
      },
    );

    // The class ring was also the only thing that made the error
    // variant's ring error-toned on Web: the slot forwarded to
    // `FocusOutline` stated no colour, so it fell through to
    // `CoreFocusOutlineStyle.defaultBorderColor` (primary). Deleting the
    // class without moving the tone onto the slot would have turned
    // every invalid text area's ring `primary` — the Flutter twin has
    // baked the variant tone all along.
    testComponents(
      'the error variant tones the surviving ring, matching the Flutter '
      'resolver',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolveAffixed(context, hasError: true);

        expect(
          _ringPaint(context, resolved.focusOutlineStyle),
          contains('var(--coui-${CoreColors.error.name})'),
        );
      },
    );

    // The variant tone is a *fallback*, not an overwrite: this slot
    // field already reached the ring on Web and must keep doing so.
    testComponents(
      'an explicit focusOutlineStyle.borderColor still wins over the '
      'variant tone',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolveAffixed(
          context,
          hasError: true,
          textAreaStyle: const CoreTextAreaStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderColor: CoreColor.token(CoreColors.tertiary),
            ),
          ),
        );

        expect(
          _ringPaint(context, resolved.focusOutlineStyle),
          contains('var(--coui-${CoreColors.tertiary.name})'),
        );
      },
    );
  });

  // Regression for #4138. The ring slot was built on an empty base and
  // its radius fell back to the Core default constant instead of the
  // box's own resolved corner — the one quadrant of text field / text
  // area × Flutter / Web that did either. So a `borderRadius` override
  // rounded the box and left the ring at the default, and an app-wide
  // `CoreFocusOutlineTheme` outranked the component's ring geometry here
  // and nowhere else.
  group('TextArea focus ring — component base, box-corner radius (#4138)', () {
    const bigRadius = CoreBorderRadius.all(CoreRadius.radius64);

    // The radius is read off `FocusOutline`'s own emitted `border-radius`
    // as well as the slot: the outline colour carries no radius, so the
    // colour helper above is blind to this axis.
    String ringRadius(BuildContext context, CoreFocusOutlineStyle style) =>
        resolveFocusOutline(
          context,
          focused: true,
          shape: .rectangle,
          focusOutlineStyle: style,
        ).root.inlineStyles?.properties['border-radius'] ??
        '';

    testComponents('with no slot radius, the ring follows the area corner', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        textAreaStyle: const CoreTextAreaStyle(borderRadius: bigRadius),
      );

      expect(
        resolved.focusOutlineStyle.borderRadius,
        bigRadius,
        reason:
            'the ring traces the corner it sits on — a box rounded to 64 '
            'with a ring still at the default is two radii on one widget',
      );
      expect(
        ringRadius(context, resolved.focusOutlineStyle),
        bigRadius.toValue(),
      );
    });

    testComponents('an explicit slot radius still wins over the area corner', (
      tester,
    ) async {
      const slotRadius = CoreBorderRadius.all(CoreRadius.radius4);
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        textAreaStyle: const CoreTextAreaStyle(
          borderRadius: bigRadius,
          focusOutlineStyle: CoreFocusOutlineStyle(borderRadius: slotRadius),
        ),
      );

      expect(resolved.focusOutlineStyle.borderRadius, slotRadius);
    });

    // The component default states the ring's width, so an app-wide
    // focus-outline theme sits under it here exactly as it does under
    // the Flutter twin and both text fields.
    testComponents(
      'the component ring width wins over an app-wide focus-outline theme',
      (tester) async {
        final data = ThemeData.coui.copyWith(
          coreComponentTheme: const CoreComponentTheme(
            focusOutline: CoreFocusOutlineTheme(
              style: CoreFocusOutlineStyle(
                borderWidth: CoreStrokeWidth.stroke6,
              ),
            ),
          ),
        );
        late BuildContext context;
        tester.pumpComponent(
          Theme(data: data, child: _ContextCapture((c) => context = c)),
        );
        final resolved = _resolve(context);
        final componentWidth =
            CoreTextAreaStyle.defaultFocusOutlineStyle.borderWidth;

        expect(resolved.focusOutlineStyle.borderWidth, componentWidth);
        expect(
          _ringPaint(context, resolved.focusOutlineStyle),
          contains(
            'calc(${CoreFocusOutlineStyle.defaultAlign}px'
            ' - ${strokeWidthCss(componentWidth!)})',
          ),
        );
      },
    );
  });

  // TextArea carries hover on the border and states no wash — and a
  // disabled area is disabled first. `disabled:*` classes reach the
  // `<textarea>` but never the affix wrapper, so the row agreement alone
  // cannot keep a stale error border off the framed box.
  group(
    'TextArea state model — border-only hover, disabled outranks error',
    () {
      List<String> wrapperClasses(
        BuildContext context, {
        required bool enabled,
      }) => resolveTextArea(
        context,
        size: CoreComponentSize.md,
        expandableHeight: false,
        expandableWidth: false,
        hasError: true,
        obscureText: false,
        obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
        enabled: enabled,
      ).affixWrapper.className.split(' ');

      testComponents('no hover/focus background class on the textarea or the '
          'affix wrapper', (tester) async {
        final context = _themedContext(tester);
        final bare = _resolve(context);
        final framed = _resolveAffixed(context);

        for (final className in [
          bare.textarea.className,
          framed.affixWrapper.className,
        ]) {
          expect(
            className
                .split(' ')
                .where(
                  (c) =>
                      c.startsWith('hover:bg-') ||
                      c.startsWith('focus:bg-') ||
                      c.startsWith('focus-within:bg-') ||
                      c.startsWith('active:bg-'),
                ),
            isEmpty,
            reason: 'hover rides the border step — no wash',
          );
        }
      });

      testComponents(
        'disabled outranks error — the affix wrapper drops the error border',
        (tester) async {
          final context = _themedContext(tester);
          const errorBorder = 'border-error';

          expect(
            wrapperClasses(context, enabled: true),
            contains(errorBorder),
            reason: 'sanity — an enabled erroring wrapper does carry it',
          );
          expect(
            wrapperClasses(
              context,
              enabled: false,
            ).where((c) => c == errorBorder || c.endsWith(':$errorBorder')),
            isEmpty,
            reason:
                'a disabled area is disabled first — the error border must '
                'not survive on the framed box',
          );
        },
      );

      // `disabled > error` gates the box chrome only — the widget keeps
      // showing `errorText` while disabled, so the message's style keeps
      // reading the Theme `variantStyles[true]` row. A token colour: the
      // error `<p>` carries its colour as a class.
      for (final enabled in const [true, false]) {
        testComponents('enabled: $enabled — the error message reads the Theme '
            'error row', (tester) async {
          final data = ThemeData.coui.copyWith(
            coreComponentTheme: const CoreComponentTheme(
              textArea: CoreTextAreaTheme(
                variantStyles: {
                  true: CoreTextAreaStyle(
                    errorTextColor: CoreColor.token(CoreColors.success),
                  ),
                },
              ),
            ),
          );
          late BuildContext context;
          tester.pumpComponent(
            Theme(data: data, child: _ContextCapture((c) => context = c)),
          );
          final resolved = resolveTextArea(
            context,
            size: CoreComponentSize.md,
            expandableHeight: false,
            expandableWidth: false,
            hasError: true,
            obscureText: false,
            obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
            enabled: enabled,
          );

          expect(
            resolved.error.className.split(' '),
            contains('text-success'),
            reason:
                'the message is content, not box chrome — disabling the '
                'area must not drop the Theme error row off it',
          );
        });
      }
    },
  );
}
