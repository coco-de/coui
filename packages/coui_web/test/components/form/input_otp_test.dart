import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kCustomDotSize = 12.0;
const _kLength = 4;
const _kCustomHeight = 56.0;

// Fixture padding values for the "full 4-side padding" regression test —
// named so `no-magic-number` doesn't flag them and so the constructed
// `CoreEdgeInsets` and the expected CSS shorthand stay in sync.
const _kPaddingTop = 4.0;
const _kPaddingRight = 8.0;
const _kPaddingBottom = 12.0;
const _kPaddingLeft = 16.0;

/// Captures the [BuildContext] a real component tree resolves under
/// (with the ambient `Theme.defaults` [pumpWithTheme] installs) so
/// resolver-level tests can call `resolveInputOtp` directly instead of
/// re-deriving chrome assertions by digging through rendered DOM nodes.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.element(tag: 'div', children: []);
  }
}

/// Pumps a [_ContextCapture] under [pumpWithTheme] and returns the
/// captured context.
BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// Finds every `<input>`/`<div>` `DomComponent` in the tree and returns
/// the first whose composed `classes` contains [needle] — used to locate
/// a specific rendered chrome element (e.g. the obscured-dot `<div>`)
/// without relying on brittle tree-position assumptions.
Finder _byClassContaining(String needle) {
  return find.byComponentPredicate(
    (c) => c is DomComponent && (c.classes ?? '').contains(needle),
  );
}

/// Finds every `DomComponent` whose composed inline `styles` contains
/// [needle] — used to locate the obscured-dot `<div>`, whose fully-round
/// circle shape is emitted as an inline `border-radius: 50%` (RULE F: chrome
/// radius is inline, not a `rounded-full` Tailwind class; `50%` is the
/// canonical circle CSS, mirroring Flutter's `BoxShape.circle`). The `50%`
/// value is unique to the dot (cells use `rem` corner radii).
Finder _byStyleContaining(String needle) {
  return find.byComponentPredicate(
    (c) =>
        c is DomComponent &&
        (c.styles?.properties.values.join(' ') ?? '').contains(needle),
  );
}

/// The whole classes of a composed `className` — `contains` on the string
/// would read `border-outline` inside `border-outline-variant` and
/// `group-hover/input-otp:border-error` inside a longer token.
List<String> _classes(String className) => className.split(' ');

/// The hover step a resting cell wears — the `group-hover/…` classes of the
/// named group on the root (absent when the cell does not step).
List<String> _hoverClasses(String className) =>
    _classes(className).where((c) => c.startsWith('group-hover/')).toList();

/// Every chrome slot of [resolved] as its className + inline properties —
/// two resolutions draw the same markup exactly when these maps are equal.
Map<String, Map<String, Object?>> _slots(ResolvedInputOtp resolved) {
  final slots = {
    'root': resolved.root,
    'hiddenInput': resolved.hiddenInput,
    'visualRow': resolved.visualRow,
    'cell': resolved.cell,
    'cellFocused': resolved.cellFocused,
    'cellFocusSibling': resolved.cellFocusSibling,
    'value': resolved.value,
    'obscuredDot': resolved.obscuredDot,
    'caret': resolved.caret,
    'separator': resolved.separator,
    'separatorBar': resolved.separatorBar,
    'errorText': resolved.errorText,
  };
  return {
    for (final MapEntry(:key, :value) in slots.entries)
      key: {
        'className': value.className,
        'inline': value.inlineStyles?.properties,
      },
  };
}

/// Finds every `DomComponent` whose inline [property] is exactly [value].
Finder _byStyleProperty(String property, String value) {
  return find.byComponentPredicate(
    (c) => c is DomComponent && c.styles?.properties[property] == value,
  );
}

/// [length] in the literal rem the cell box is emitted in.
String _rem(double length) => '${length / kRemDivisor}rem';

/// Resolves the chrome at [size] — a parameter rather than a literal, so a
/// call at the default size states it instead of leaning on the default.
ResolvedInputOtp _resolveAt(
  BuildContext context,
  CoreInputOtpSize size, {
  required bool enabled,
  bool hasError = false,
}) => resolveInputOtp(
  context,
  enabled: enabled,
  hasError: hasError,
  size: size,
);

/// Resolves the hover rules at [size] — see [_resolveAt].
ResolvedInputOtpRules _rulesAt(
  BuildContext context,
  CoreInputOtpSize size, {
  required bool enabled,
  bool hasError = false,
  String scopeId = 'co-input-otp',
  CoreInputOtpStyle? inputOtpStyle,
}) => resolveInputOtpRules(
  context,
  enabled: enabled,
  hasError: hasError,
  scopeId: scopeId,
  size: size,
  inputOtpStyle: inputOtpStyle,
);

void main() {
  testComponents('lg cells reserve the transparent border at rest', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const InputOtp(size: CoreInputOtpSize.lg, allowCellEditing: true),
    );
    final cells = find
        .byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.attributes?.containsKey('data-otp-cell') ?? false),
        )
        .evaluate()
        .map((e) => e.component as DomComponent)
        .toList();
    expect(cells, hasLength(6));
    for (final cell in cells) {
      expect(
        cell.styles?.properties['border-width'],
        'var(--coui-stroke-width-1)',
      );
    }
  });

  testComponents('composed cells retain DOM geometry and accessibility', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const InputOtp(allowCellEditing: true, initialValue: '123456'),
    );
    expect(find.byType(OutlinedContainer).evaluate(), hasLength(6));
    final cells = find
        .byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.attributes?.containsKey('data-otp-cell') ?? false),
        )
        .evaluate()
        .map((e) => e.component as DomComponent)
        .toList();
    expect(cells, hasLength(6));
    for (final cell in cells) {
      expect(cell.attributes?['aria-hidden'], 'true');
      // #6464: a 44 × 52 cell; every cell holds a character, so each
      // takes the filled look — surface on outline.
      expect(cell.styles?.properties['width'], '2.75rem');
      expect(cell.styles?.properties['height'], '3.25rem');
      expect(_classes(cell.classes ?? ''), contains('bg-surface'));
      expect(_classes(cell.classes ?? ''), contains('border-outline'));
      expect(
        _classes(cell.classes ?? ''),
        contains('group-hover/input-otp:border-outline'),
      );
      expect(_classes(cell.classes ?? ''), contains('transition-all'));
      expect(
        cell.styles?.properties['transition-duration'],
        'var(--coui-duration-150)',
      );
    }
    expect(find.tag('input').evaluate(), hasLength(1));
  });

  testComponents('composed error cells retain the error border', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const InputOtp(allowCellEditing: true, errorText: 'Invalid code'),
    );
    final cells = find
        .byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.attributes?.containsKey('data-otp-cell') ?? false),
        )
        .evaluate()
        .map((e) => e.component as DomComponent)
        .toList();
    expect(cells, hasLength(6));
    for (final cell in cells) {
      expect(_classes(cell.classes ?? ''), contains('border-error'));
      expect(
        _classes(cell.classes ?? ''),
        contains('group-hover/input-otp:border-error'),
      );
    }
  });

  testComponents('cell editing keeps a disabled OTP non-interactive', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const InputOtp(
        allowCellEditing: true,
        enabled: false,
        initialValue: '123456',
      ),
    );
    final input = find.tag('input').evaluate().single.component as DomComponent;
    expect(input.attributes?.containsKey('disabled'), isTrue);
    expect(input.events, anyOf(isNull, isEmpty));
    expect(input.attributes?['value'], '123456');
  });

  testComponents('cell editing keeps obscured digits out of visual nodes', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const InputOtp(
        allowCellEditing: true,
        obscured: true,
        initialValue: '7',
        length: 1,
        separatorInterval: 0,
      ),
    );
    expect(find.text('7'), findsNothing);
    expect(_byStyleContaining('50%'), findsOneComponent);
  });

  group('InputOtp construction', () {
    test('cell editing is opt-in and survives copyWith', () {
      const standard = InputOtp();
      expect(standard.allowCellEditing, isFalse);
      final editing = standard.copyWith(allowCellEditing: true);
      expect(editing.allowCellEditing, isTrue);
      expect(editing.copyWith(length: _kLength).allowCellEditing, isTrue);
    });

    testComponents('only opt-in cells expose geometry markers', (tester) async {
      pumpWithTheme(tester, const InputOtp(allowCellEditing: true));
      final cells = find.byComponentPredicate(
        (c) =>
            c is DomComponent &&
            (c.attributes?.containsKey('data-otp-cell') ?? false),
      );
      expect(cells.evaluate(), hasLength(CoreInputOtpContract.defaultLength));
    });

    test('obscured flag defaults to false', () {
      const otp = InputOtp();
      expect(otp.obscured, isFalse);
    });

    test('accepts the obscured flag', () {
      const otp = InputOtp(obscured: true);
      expect(otp.obscured, isTrue);
    });

    test('accepts a custom obscuredDotSize via inputOtpStyle', () {
      const otp = InputOtp(
        obscured: true,
        inputOtpStyle: CoreInputOtpStyle(obscuredDotSize: _kCustomDotSize),
      );
      expect(otp.inputOtpStyle?.obscuredDotSize, equals(_kCustomDotSize));
    });

    test('autofocus flag defaults to false', () {
      const otp = InputOtp();
      expect(otp.autofocus, isFalse);
    });

    test('accepts the autofocus flag', () {
      const otp = InputOtp(autofocus: true);
      expect(otp.autofocus, isTrue);
    });

    test('errorText defaults to null', () {
      const otp = InputOtp();
      expect(otp.errorText, isNull);
    });

    test('accepts an errorText message', () {
      const otp = InputOtp(errorText: 'Invalid code');
      expect(otp.errorText, equals('Invalid code'));
    });

    test('size defaults to the Core default size', () {
      const otp = InputOtp();
      expect(otp.size, CoreInputOtpSize.defaultSize);
      expect(otp.size, CoreInputOtpSize.md);
    });

    test('copyWith and the style chain keep the size', () {
      const otp = InputOtp(size: CoreInputOtpSize.lg);

      expect(otp.copyWith(length: _kLength).size, CoreInputOtpSize.lg);
      expect(
        otp
            .withStyle(const CoreInputOtpStyle(cellSpacing: CoreSpace.space4))
            .size,
        CoreInputOtpSize.lg,
      );
      expect(otp.radius4.primary.size, CoreInputOtpSize.lg);
      expect(
        otp.copyWith(size: CoreInputOtpSize.md).size,
        CoreInputOtpSize.md,
      );
    });
  });

  group('InputOtp single hidden-input architecture (#SMS autofill parity)', () {
    testComponents(
      'renders exactly one real <input> regardless of length',
      (tester) async {
        pumpWithTheme(tester, const InputOtp(length: _kLength));
        // A single hidden `<input>` backs the whole row — Flutter parity
        // (one `TextField` owns the keyboard/autofill connection). The
        // visual cells are decorative `<div>`s, not separate inputs.
        expect(find.tag('input'), findsOneComponent);
      },
    );

    testComponents(
      'renders exactly one real <input> when obscured',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(length: _kLength, obscured: true),
        );
        expect(find.tag('input'), findsOneComponent);
      },
    );

    testComponents(
      'renders a decorative cell per digit',
      (tester) async {
        pumpWithTheme(tester, const InputOtp(length: _kLength));
        // root <div role=group> + visual row <div> + `length` cell <div>s.
        expect(find.tag('div'), findsComponents);
      },
    );

    testComponents(
      'renders with separator interval without error',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(),
        );
        expect(find.tag('input'), findsOneComponent);
        expect(find.tag('span'), findsComponents);
      },
    );

    testComponents(
      'seeds the hidden input value attribute from initialValue',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(initialValue: '12', length: 3, separatorInterval: 0),
        );
        final input =
            find.tag('input').evaluate().single.component as DomComponent;
        expect(input.attributes?['value'], equals('12'));
      },
    );

    testComponents(
      'truncates an initialValue longer than length to length before '
      'seeding the DOM (both the buffer and the value attribute)',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(
            initialValue: '123456789',
            length: 4,
            separatorInterval: 0,
          ),
        );
        final input =
            find.tag('input').evaluate().single.component as DomComponent;
        // Un-truncated, this would otherwise leave the DOM seeded past
        // `length`, forcing the caret (always pinned to the end) past
        // the visible cells and silently swallowing further typed
        // edits until enough backspaces drop the total back under 4.
        expect(input.attributes?['value'], equals('1234'));
        // Exactly 4 visible digit cells rendered (one span with digit
        // text per filled cell) — the extra "56789" never reaches the
        // visual row.
        for (final digit in ['1', '2', '3', '4']) {
          expect(find.text(digit), findsOneComponent);
        }
        for (final digit in ['5', '6', '7', '8', '9']) {
          expect(find.text(digit), findsNothing);
        }
      },
    );

    testComponents(
      'the hidden input carries a native maxlength backstop matching '
      'length',
      (tester) async {
        pumpWithTheme(tester, const InputOtp(length: 5));
        final input =
            find.tag('input').evaluate().single.component as DomComponent;
        expect(input.attributes?['maxlength'], equals('5'));
      },
    );
  });

  group('InputOtp obscured vs. plaintext rendering (#security)', () {
    testComponents(
      'renders the digit as visible text when not obscured',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(initialValue: '7', length: 1, separatorInterval: 0),
        );
        expect(find.text('7'), findsOneComponent);
      },
    );

    testComponents(
      'renders a dot in place of the digit when obscured — the '
      'plaintext digit never reaches the DOM as text',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(
            initialValue: '7',
            length: 1,
            obscured: true,
            separatorInterval: 0,
          ),
        );
        // The digit must not appear as a text node anywhere — this is
        // the actual security property `obscured` promises.
        expect(find.text('7'), findsNothing);
        // The dot chrome (a filled circle, inline `border-radius: 50%`) is
        // rendered in its place.
        expect(_byStyleContaining('50%'), findsOneComponent);
      },
    );

    testComponents(
      'renders no dot for an empty (unfilled) cell even when obscured',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(length: 1, obscured: true, separatorInterval: 0),
        );
        expect(_byStyleContaining('50%'), findsNothing);
      },
    );
  });

  group('InputOtp variant colour threading (#Theme.variantStyles)', () {
    testComponents(
      'default variant cell border uses the outlineVariant token',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveInputOtp(context, enabled: true);
        final classes = _classes(resolved.cell.className);
        expect(classes, contains('border-outline-variant'));
        expect(classes, isNot(contains('border-outline')));
        expect(classes, isNot(contains('border-error')));
      },
    );

    testComponents(
      'error variant switches the cell border to the error token — not '
      'just the idle border, but the focused-cell border and the focus '
      'ring too',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveInputOtp(
          context,
          enabled: true,
          hasError: true,
        );
        expect(_classes(resolved.cell.className), contains('border-error'));
        expect(
          _classes(resolved.cell.className),
          isNot(contains('border-outline-variant')),
        );
        expect(
          _classes(resolved.cellFocused.className),
          contains('border-error'),
        );
        // The focus-ring colour must thread through the same
        // merged-override → variant-chrome chain as the border, rather
        // than a separate hardcoded `hasError` ternary — otherwise a
        // `CoreInputOtpTheme.variantStyles` override recolouring the
        // error variant's border would leave the ring on the wrong
        // colour.
        expect(
          resolved.cellFocusOutlineStyle.borderColor,
          equals(const CoreColor.token(CoreColors.error)),
        );
      },
    );

    testComponents(
      'default variant leaves the focus ring on its own design-system '
      'default (no explicit ring-colour override threaded through)',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveInputOtp(context, enabled: true);
        expect(resolved.cellFocusOutlineStyle.borderColor, isNull);
      },
    );

    testComponents(
      'a project-level CoreInputOtpTheme.variantStyles override for the '
      'error variant recolours the cell border consistently with the '
      'ring — the ring must not stay pinned to the global error token',
      (tester) async {
        const projectErrorStyle = CoreInputOtpStyle(
          borderColor: CoreColor.token(CoreColors.tertiary),
          focusBorderColor: CoreColor.token(CoreColors.tertiary),
        );
        final themedData = ThemeData.coui.copyWith(
          coreComponentTheme: const CoreComponentTheme(
            inputOtp: CoreInputOtpTheme(
              variantStyles: {
                .defaultVariant: CoreInputOtpStyle(),
                .error: projectErrorStyle,
              },
            ),
          ),
        );
        late BuildContext context;
        tester.pumpComponent(
          Theme(
            data: themedData,
            child: _ContextCapture((c) => context = c),
          ),
        );
        final overridden = resolveInputOtp(
          context,
          enabled: true,
          hasError: true,
        );
        expect(overridden.cellFocused.className, contains('border-tertiary'));
        expect(
          overridden.cellFocusOutlineStyle.borderColor,
          equals(const CoreColor.token(CoreColors.tertiary)),
        );
      },
    );
  });

  group('InputOtp hover border', () {
    // The cells are `pointer-events-none` — the hidden `<input>` is the
    // pointer target — so a cell never matches `:hover` itself. The root
    // carries a NAMED group and the resting cells read its hover. Which
    // slot wears the hover class is what decides the ladder
    // `disabled > error > focus > hover > rest`; the cascade is never asked
    // to arbitrate (Tailwind v3 emits `hover:` after `focus-within:`, so a
    // hover class sitting next to a focus class would win).
    const hoverOutline = 'group-hover/input-otp:border-outline';
    const hoverError = 'group-hover/input-otp:border-error';

    testComponents('the root names the hover group the cells read', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveInputOtp(context, enabled: true);

      expect(_classes(resolved.root.className), contains('group/input-otp'));
    });

    testComponents('a resting cell steps to outline under the pointer', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveInputOtp(context, enabled: true);

      expect(_hoverClasses(resolved.cell.className), [hoverOutline]);
      // The resting edge underneath it is still `outlineVariant`.
      expect(
        _classes(resolved.cell.className),
        contains('border-outline-variant'),
      );
    });

    testComponents('focus outranks hover: the active cell wears no hover '
        'class', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveInputOtp(context, enabled: true);

      expect(_hoverClasses(resolved.cellFocused.className), isEmpty);
    });

    testComponents('a focused control does not step: the cells beside the '
        'active one are the resting chrome without its hover class', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveInputOtp(context, enabled: true);

      expect(_hoverClasses(resolved.cellFocusSibling.className), isEmpty);
      // ...and otherwise identical to the resting cell: same fill, same
      // `outlineVariant` edge, same geometry — only the hover step is gone.
      expect(
        _classes(resolved.cellFocusSibling.className),
        _classes(
          resolved.cell.className,
        ).where((c) => !c.startsWith('group-hover/')).toList(),
      );
      expect(
        resolved.cellFocusSibling.inlineStyles?.properties,
        resolved.cell.inlineStyles?.properties,
      );
    });

    testComponents('error outranks hover: an error control restates error '
        'for the hover step', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveInputOtp(
        context,
        enabled: true,
        hasError: true,
      );

      expect(_hoverClasses(resolved.cell.className), [hoverError]);
      expect(_classes(resolved.cell.className), contains('border-error'));
      expect(
        _classes(resolved.cell.className),
        isNot(contains(hoverOutline)),
      );
    });

    testComponents('disabled outranks hover: a disabled control has no hover '
        'step at all', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveInputOtp(context, enabled: false);

      expect(_hoverClasses(resolved.cell.className), isEmpty);
      expect(_hoverClasses(resolved.cellFocusSibling.className), isEmpty);
      expect(
        resolveInputOtpRules(context, enabled: false).css,
        isEmpty,
      );
    });

    testComponents('a token hoverBorderColor override rides the class — no '
        'rule, no scope class', (tester) async {
      final context = _themedContext(tester);
      const style = CoreInputOtpStyle(
        hoverBorderColor: CoreColor.token(CoreColors.tertiary),
      );
      final resolved = resolveInputOtp(
        context,
        enabled: true,
        inputOtpStyle: style,
      );

      expect(_hoverClasses(resolved.cell.className), [
        'group-hover/input-otp:border-tertiary',
      ]);
      expect(
        resolveInputOtpRules(context, enabled: true, inputOtpStyle: style).css,
        isEmpty,
      );
    });

    testComponents('a RAW hoverBorderColor has no class to ride: the cell '
        'carries a per-instance scope class and the rule paints it', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const raw = CoreColor(0xFFAA3366);
      const style = CoreInputOtpStyle(hoverBorderColor: raw);
      final resolved = resolveInputOtp(
        context,
        enabled: true,
        scopeId: 'otp-7',
        inputOtpStyle: style,
      );
      final rules = resolveInputOtpRules(
        context,
        enabled: true,
        scopeId: 'otp-7',
        inputOtpStyle: style,
      );

      // No `.tailwindColor` on a raw colour: that would throw at render.
      expect(_hoverClasses(resolved.cell.className), isEmpty);
      expect(_classes(resolved.cell.className), contains('otp-7-cell'));
      const selector = r'.group\/input-otp:hover .otp-7-cell';
      expect(rules.css, '$selector{border-color: ${raw.toValue()};}');
      // The rule can only find a cell that wears the scope class — the
      // active cell and the focused control's other cells do not.
      expect(
        _classes(resolved.cellFocused.className),
        isNot(contains('otp-7-cell')),
      );
      expect(
        _classes(resolved.cellFocusSibling.className),
        isNot(contains('otp-7-cell')),
      );
    });

    testComponents('the default path ships no rule and no scope class', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveInputOtp(context, enabled: true);

      expect(resolveInputOtpRules(context, enabled: true).css, isEmpty);
      expect(
        _classes(resolved.cell.className).where((c) => c.endsWith('-cell')),
        isEmpty,
      );
    });

    testComponents('the widget renders the hover group on the root and the '
        'hover class on every resting cell', (tester) async {
      pumpWithTheme(tester, const InputOtp(length: _kLength));

      expect(_byClassContaining('group/input-otp'), findsOneComponent);
      expect(
        _byClassContaining('group-hover/input-otp:border-outline'),
        findsNComponents(_kLength),
      );
      expect(find.tag('style'), findsNothing);
    });

    testComponents('a raw override renders the rule in a <style> child', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const InputOtp(
          length: _kLength,
          inputOtpStyle: CoreInputOtpStyle(
            hoverBorderColor: CoreColor(0xFFAA3366),
          ),
        ),
      );

      expect(find.tag('style'), findsOneComponent);
      expect(
        _byClassContaining('group-hover/input-otp:'),
        findsNothing,
        reason: 'a raw colour has no class — the rule carries it',
      );
    });

    testComponents('a disabled widget renders no hover class on any cell', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const InputOtp(length: _kLength, enabled: false),
      );

      expect(_byClassContaining('group-hover/input-otp:'), findsNothing);
    });
  });

  group('InputOtp root height', () {
    // Every sibling value in the resolver chains its Core default; this
    // one did not, so `CoreInputOtpStyle.defaultHeight` reached Flutter
    // and never reached Web. The row happened to measure the same by
    // content, which is exactly what kept a shared default silently
    // unshared — until a project overrode it and only one platform moved.
    testComponents('emits the Core default height', (tester) async {
      final context = _themedContext(tester);

      final resolved = resolveInputOtp(context, enabled: true);

      expect(
        resolved.root.inlineStyles?.properties['height'],
        equals('${CoreInputOtpStyle.defaultHeight / kRemDivisor}rem'),
      );
    });

    testComponents('the row is never shorter than its cells', (tester) async {
      final context = _themedContext(tester);

      final resolved = resolveInputOtp(
        context,
        enabled: true,
        inputOtpStyle: const CoreInputOtpStyle(
          cellSize: CoreSize.size48,
          cellHeight: CoreSize.size56,
        ),
      );

      expect(
        resolved.root.inlineStyles?.properties['height'],
        equals('${CoreSize.size56 / kRemDivisor}rem'),
      );
      // The cell itself is 48 wide and 56 tall — not square.
      expect(
        resolved.cell.inlineStyles?.properties['width'],
        equals('${CoreSize.size48 / kRemDivisor}rem'),
      );
      expect(
        resolved.cell.inlineStyles?.properties['height'],
        equals('${CoreSize.size56 / kRemDivisor}rem'),
      );
    });

    testComponents('a restated cellSize alone keeps the cell square', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final resolved = resolveInputOtp(
        context,
        enabled: true,
        inputOtpStyle: const CoreInputOtpStyle(cellSize: CoreSize.size48),
      );

      expect(
        resolved.cell.inlineStyles?.properties['height'],
        equals('${CoreSize.size48 / kRemDivisor}rem'),
      );
    });

    test('length and separatorInterval default to the contract', () {
      const otp = InputOtp();
      expect(otp.length, CoreInputOtpContract.defaultLength);
      expect(
        otp.separatorInterval,
        CoreInputOtpContract.defaultSeparatorInterval,
      );
    });

    testComponents('an explicit height still wins', (tester) async {
      final context = _themedContext(tester);

      final resolved = resolveInputOtp(
        context,
        enabled: true,
        inputOtpStyle: const CoreInputOtpStyle(height: _kCustomHeight),
      );

      expect(
        resolved.root.inlineStyles?.properties['height'],
        equals('${_kCustomHeight / kRemDivisor}rem'),
      );
    });
  });

  group('InputOtp size', () {
    // The size row is the head of the merge chain. `md` is the empty style,
    // so the default size has to draw exactly what a call without a size
    // draws; `lg` restates the cell box, its corner, the digit / separator
    // role and the dot, and nothing else.

    testComponents('md draws exactly what no size draws — every slot', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final (enabled, hasError) in [
        (true, false),
        (true, true),
        (false, false),
      ]) {
        final reason = 'enabled: $enabled, hasError: $hasError';
        final md = _resolveAt(
          context,
          CoreInputOtpSize.md,
          enabled: enabled,
          hasError: hasError,
        );
        final noSize = resolveInputOtp(
          context,
          enabled: enabled,
          hasError: hasError,
        );
        expect(_slots(md), equals(_slots(noSize)), reason: reason);
        expect(
          md.cellFocusOutlineStyle,
          equals(noSize.cellFocusOutlineStyle),
          reason: reason,
        );
        expect(
          _rulesAt(
            context,
            CoreInputOtpSize.md,
            enabled: enabled,
            hasError: hasError,
          ).css,
          resolveInputOtpRules(
            context,
            enabled: enabled,
            hasError: hasError,
          ).css,
          reason: reason,
        );
      }
    });

    testComponents('md and a raw hover override: the rule is the same too', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreInputOtpStyle(hoverBorderColor: CoreColor(0xFFAA3366));

      final md = _rulesAt(
        context,
        CoreInputOtpSize.md,
        enabled: true,
        scopeId: 'otp-1',
        inputOtpStyle: style,
      );
      final noSize = resolveInputOtpRules(
        context,
        enabled: true,
        scopeId: 'otp-1',
        inputOtpStyle: style,
      );

      expect(md.css, isNotEmpty);
      expect(md.css, noSize.css);
      // A caller's hover colour wins over the lg row's own transparent
      // hover border, so lg finds the same rule.
      expect(
        resolveInputOtpRules(
          context,
          enabled: true,
          scopeId: 'otp-1',
          size: CoreInputOtpSize.lg,
          inputOtpStyle: style,
        ).css,
        noSize.css,
      );
    });

    testComponents('lg draws a 56 × 64 cell in a 64 row', (tester) async {
      final context = _themedContext(tester);

      final lg = resolveInputOtp(
        context,
        enabled: true,
        size: CoreInputOtpSize.lg,
      );

      for (final cell in [lg.cell, lg.cellFocused, lg.cellFocusSibling]) {
        expect(cell.inlineStyles?.properties['width'], _rem(CoreSize.size56));
        expect(cell.inlineStyles?.properties['height'], _rem(CoreSize.size64));
      }
      for (final style in [
        lg.cellContainerStyle,
        lg.cellFilledContainerStyle,
        lg.cellFocusedContainerStyle,
        lg.cellFocusedFilledContainerStyle,
      ]) {
        expect(style.width, CoreSize.size56);
        expect(style.height, CoreSize.size64);
      }
      expect(lg.cell.inlineStyles?.properties['width'], '3.5rem');
      expect(lg.root.inlineStyles?.properties['height'], '4.0rem');
      // The caret grows to 24.
      expect(lg.caret.inlineStyles?.properties['height'], '1.5rem');
    });

    testComponents('lg rounds the cell to 14 and the focus ring follows', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const radius = CoreBorderRadius.all(CoreRadius.radius14);

      final lg = resolveInputOtp(
        context,
        enabled: true,
        size: CoreInputOtpSize.lg,
      );

      expect(
        lg.cell.inlineStyles?.properties['border-radius'],
        radius.toValue(),
      );
      expect(
        lg.cellFocused.inlineStyles?.properties['border-radius'],
        radius.toValue(),
      );
      expect(lg.cellFocusOutlineStyle.borderRadius, radius);
    });

    testComponents('lg digits are headlineSmall semi-bold on onSurface', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final lg = resolveInputOtp(
        context,
        enabled: true,
        size: CoreInputOtpSize.lg,
      );

      final classes = _classes(lg.value.className);
      expect(
        classes,
        containsAll(['text-headline-small', 'text-on-surface']),
      );
      expect(classes, isNot(contains('text-title-medium')));
      // A weight overlay only — never a size over the role.
      expect(lg.value.inlineStyles?.properties['font-size'], isNull);
      // The lg row restates semi-bold over its role, so the inline overlay
      // is 600.
      expect(lg.value.inlineStyles?.properties['font-weight'], '600');
    });

    testComponents('the separator is an 8 × 2 outline bar at every size', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final size in CoreInputOtpSize.values) {
        final resolved = _resolveAt(context, size, enabled: true);
        expect(_classes(resolved.separatorBar.className), ['bg-outline']);
        final bar = resolved.separatorBar.inlineStyles?.properties;
        expect(bar?['width'], '0.5rem');
        expect(bar?['height'], '0.125rem');
        expect(
          bar?['border-radius'],
          CoreInputOtpStyle.defaultSeparatorBorderRadius.toValue(),
        );
        // The wrapper only centres the bar and pads it 4 either side.
        expect(_classes(resolved.separator.className), [
          'flex',
          'items-center',
        ]);
        expect(
          resolved.separator.inlineStyles?.properties['padding'],
          CoreInputOtpStyle.defaultSeparatorPadding.toValue(),
        );
      }
    });

    testComponents('a rendered separator is the bar, not a hyphen', (
      tester,
    ) async {
      pumpWithTheme(tester, const InputOtp(initialValue: '123456'));
      expect(find.text('-'), findsNothing);
      expect(_byClassContaining('bg-outline'), findsOneComponent);
    });

    testComponents('the hidden dot is 10 at every size', (tester) async {
      final context = _themedContext(tester);

      for (final size in CoreInputOtpSize.values) {
        final resolved = _resolveAt(context, size, enabled: true);
        final dot = resolved.obscuredDot.inlineStyles?.properties;
        expect(dot?['width'], '0.625rem');
        expect(dot?['height'], '0.625rem');
        expect(dot?['border-radius'], '50%');
      }
    });

    testComponents('the caret is a 2 × 20 primary bar, error on the error '
        'variant', (tester) async {
      final context = _themedContext(tester);

      final md = resolveInputOtp(context, enabled: true);
      expect(_classes(md.caret.className), ['bg-primary']);
      final caret = md.caret.inlineStyles?.properties;
      expect(caret?['width'], '0.125rem');
      expect(caret?['height'], '1.25rem');
      expect(
        caret?['border-radius'],
        CoreInputOtpStyle.defaultCaretBorderRadius.toValue(),
      );

      final error = resolveInputOtp(context, enabled: true, hasError: true);
      expect(_classes(error.caret.className), ['bg-error']);
    });

    testComponents('an empty cell is surfaceContainerLow on outlineVariant, a '
        'filled one surface on outline, and the active cell takes outline', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const low = CoreColor.token(CoreColors.surfaceContainerLow);
      const variant = CoreColor.token(CoreColors.outlineVariant);
      const surface = CoreColor.token(CoreColors.surface);
      const outline = CoreColor.token(CoreColors.outline);

      final md = resolveInputOtp(context, enabled: true);
      expect(md.cellContainerStyle.backgroundColor, low);
      expect(md.cellContainerStyle.borderColor, variant);
      expect(md.cellFilledContainerStyle.backgroundColor, surface);
      expect(md.cellFilledContainerStyle.borderColor, outline);
      // The fill of its state and a neutral `outline` edge — never primary.
      expect(md.cellFocusedContainerStyle.backgroundColor, low);
      expect(md.cellFocusedContainerStyle.borderColor, outline);
      expect(md.cellFocusedFilledContainerStyle.backgroundColor, surface);
      expect(md.cellFocusedFilledContainerStyle.borderColor, outline);
      expect(md.cellFocusOutlineStyle.borderColor, isNull);
    });

    testComponents('a rendered field draws empty and filled cells apart', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const InputOtp(
          length: _kLength,
          separatorInterval: 0,
          allowCellEditing: true,
          initialValue: '1',
        ),
      );
      final cells = find
          .byComponentPredicate(
            (c) =>
                c is DomComponent &&
                (c.attributes?.containsKey('data-otp-cell') ?? false),
          )
          .evaluate()
          .map((e) => _classes((e.component as DomComponent).classes ?? ''))
          .toList();
      expect(cells.first, containsAll(['bg-surface', 'border-outline']));
      for (final empty in cells.skip(1)) {
        expect(
          empty,
          containsAll(['bg-surface-container-low', 'border-outline-variant']),
        );
      }
    });

    testComponents('each digit sits in a desktop typography-tier scope', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const InputOtp(
          length: _kLength,
          separatorInterval: 0,
          size: CoreInputOtpSize.lg,
          initialValue: '12',
        ),
      );
      final scopes = find.byType(TypographyTierScope);
      // One per filled cell, wrapping the digit alone.
      expect(scopes, findsNComponents(2));
      for (final e in scopes.evaluate()) {
        expect(
          (e.component as TypographyTierScope).tier,
          CoreBreakpointTier.desktop,
        );
      }
      expect(
        find.descendant(of: scopes.first, matching: find.text('1')),
        findsOneComponent,
      );
      // The wrapper is box-less, so the cell row's own layout is unchanged.
      expect(
        _byStyleProperty('display', 'contents'),
        findsNComponents(2),
      );
    });

    testComponents('the md digit is titleMedium with no weight overlay', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final md = resolveInputOtp(context, enabled: true);
      expect(
        _classes(md.value.className),
        containsAll(['text-title-medium', 'text-on-surface']),
      );
      expect(md.value.inlineStyles?.properties['font-weight'], isNull);
    });

    testComponents('lg keeps the gap and the error message of md', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final lg = resolveInputOtp(
        context,
        enabled: true,
        hasError: true,
        size: CoreInputOtpSize.lg,
      );
      final md = resolveInputOtp(context, enabled: true, hasError: true);

      expect(_classes(lg.root.className), contains('gap-space8'));
      expect(lg.root.className, md.root.className);
      expect(lg.visualRow.className, md.visualRow.className);
      expect(_slots(lg)['errorText'], equals(_slots(md)['errorText']));
      // The error variant still recolours the lg cell.
      expect(_classes(lg.cell.className), contains('border-error'));
    });

    testComponents('the error variant wins over the lg colours', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final lg = resolveInputOtp(
        context,
        enabled: true,
        hasError: true,
        size: CoreInputOtpSize.lg,
      );

      expect(_classes(lg.cell.className), contains('border-error'));
      expect(lg.cell.inlineStyles?.properties['border-color'], isNull);
      expect(_classes(lg.cellFocused.className), contains('border-error'));
      for (final style in [
        lg.cellContainerStyle,
        lg.cellFilledContainerStyle,
        lg.cellFocusedContainerStyle,
        lg.cellFocusedFilledContainerStyle,
      ]) {
        expect(style.borderColor, const CoreColor.token(CoreColors.error));
      }
      expect(
        lg.cellFocusOutlineStyle.borderColor,
        const CoreColor.token(CoreColors.error),
      );
    });

    testComponents('a per-instance cellSize wins over the lg row', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final lg = resolveInputOtp(
        context,
        enabled: true,
        size: CoreInputOtpSize.lg,
        inputOtpStyle: const CoreInputOtpStyle(cellSize: CoreSize.size48),
      );

      expect(lg.cell.inlineStyles?.properties['width'], _rem(CoreSize.size48));
      // The lg row states its own cell height, so restating only the width
      // keeps the lg 64 — `cellHeight ?? cellSize` reads the row's first.
      expect(lg.cell.inlineStyles?.properties['height'], _rem(CoreSize.size64));
      expect(lg.root.inlineStyles?.properties['height'], '4.0rem');
    });

    testComponents('a colour-only textStyle keeps the lg role and weight', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const raw = CoreColor(0xFF112233);

      final lg = resolveInputOtp(
        context,
        enabled: true,
        size: CoreInputOtpSize.lg,
        inputOtpStyle: const CoreInputOtpStyle(
          textStyle: CoreTextStyle(color: raw),
        ),
      );

      final classes = _classes(lg.value.className);
      expect(classes, contains('text-headline-small'));
      // A raw colour has no class — it rides inline over the role.
      expect(classes, isNot(contains('text-on-surface')));
      expect(lg.value.inlineStyles?.properties['color'], isNotNull);
      expect(lg.value.inlineStyles?.properties['font-weight'], '600');
    });

    testComponents('a theme style beats the lg row', (tester) async {
      final themedData = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          inputOtp: CoreInputOtpTheme(
            style: CoreInputOtpStyle(
              cellSize: CoreSize.size48,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
            ),
          ),
        ),
      );
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: themedData,
          child: _ContextCapture((c) => context = c),
        ),
      );

      final lg = resolveInputOtp(
        context,
        enabled: true,
        size: CoreInputOtpSize.lg,
      );

      expect(lg.cell.inlineStyles?.properties['width'], _rem(CoreSize.size48));
      expect(
        lg.cell.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius4).toValue(),
      );
      // What the theme does not state still comes from the lg row.
      expect(_classes(lg.value.className), contains('text-headline-small'));
    });

    testComponents('a rendered lg InputOtp draws its cells at 56', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const InputOtp(length: _kLength, size: CoreInputOtpSize.lg),
      );

      expect(
        _byStyleProperty('width', _rem(CoreSize.size56)),
        findsNComponents(_kLength),
      );
      expect(
        _byStyleProperty('width', _rem(CoreInputOtpStyle.defaultCellSize)),
        findsNothing,
      );
    });

    testComponents('a rendered default InputOtp draws its cells at 44', (
      tester,
    ) async {
      pumpWithTheme(tester, const InputOtp(length: _kLength));

      expect(
        _byStyleProperty('width', _rem(CoreInputOtpStyle.defaultCellSize)),
        findsNComponents(_kLength),
      );
    });
  });

  group('InputOtp error helper text padding (#4-side adapter)', () {
    testComponents(
      'emits the full 4-side padding shorthand, not just padding-top',
      (tester) async {
        final context = _themedContext(tester);
        const customPadding = CoreEdgeInsets.only(
          left: _kPaddingLeft,
          top: _kPaddingTop,
          right: _kPaddingRight,
          bottom: _kPaddingBottom,
        );
        final resolved = resolveInputOtp(
          context,
          enabled: true,
          hasError: true,
          inputOtpStyle: const CoreInputOtpStyle(
            errorTextPadding: customPadding,
          ),
        );
        // Every side is a spacing step, so each names its variable — in
        // shorthand order, top right bottom left.
        final expectedPadding =
            'var(--coui-space-${_kPaddingTop.toInt()}) '
            'var(--coui-space-${_kPaddingRight.toInt()}) '
            'var(--coui-space-${_kPaddingBottom.toInt()}) '
            'var(--coui-space-${_kPaddingLeft.toInt()})';
        expect(
          resolved.errorText.inlineStyles?.properties['padding'],
          equals(expectedPadding),
        );
        // The old bug emitted only `padding-top` and silently dropped
        // the other three sides.
        expect(
          resolved.errorText.inlineStyles?.properties.containsKey(
            'padding-top',
          ),
          isFalse,
        );
      },
    );
  });

  group('InputOtp error state', () {
    testComponents(
      'renders no error message by default',
      (tester) async {
        pumpWithTheme(tester, const InputOtp(length: _kLength));
        expect(find.text('Invalid code'), findsNothing);
        expect(
          find.byComponentPredicate(
            (c) => c is DomComponent && c.attributes?['aria-live'] != null,
          ),
          findsNothing,
        );
      },
    );

    testComponents(
      'renders the error message below the cell row when errorText is set',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(length: _kLength, errorText: 'Invalid code'),
        );
        expect(find.text('Invalid code'), findsOneComponent);
        // A composed `ValidatorHint.error` — a 14 `circle-alert` before the
        // message, announced by the hint's own role.
        final hint = find.byType(ValidatorHint);
        expect(hint, findsOneComponent);
        final hintComponent = hint.evaluate().single.component as ValidatorHint;
        expect(hintComponent.type, CoreValidatorHintType.error);
        expect(
          hintComponent.validatorHintStyle?.iconStyle?.size,
          CoreIconSize.size14,
        );
        final icon = find.descendant(of: hint, matching: find.byType(Icon));
        expect(icon, findsOneComponent);
        expect(
          (icon.evaluate().single.component as Icon).icon,
          LucideIcons.circleAlert,
        );
        expect(
          find.byComponentPredicate(
            (c) => c is DomComponent && c.attributes?['role'] == 'alert',
          ),
          findsOneComponent,
        );
        // Still exactly one real input — the error variant only changes
        // chrome (border colour), never the single-input architecture.
        expect(find.tag('input'), findsOneComponent);
      },
    );
  });

  for (final direction in ['ltr', 'rtl']) {
    testComponents('error region excludes the input in $direction', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const InputOtp(initialValue: '123456').copyWith(
          errorText: 'Try again',
          attributes: {'dir': direction},
        ),
      );
      final group =
          find
                  .byComponentPredicate(
                    (c) =>
                        c is DomComponent && c.attributes?['role'] == 'group',
                  )
                  .evaluate()
                  .single
                  .component
              as DomComponent;
      expect(group.attributes?['dir'], direction);
      expect(group.attributes?['aria-label'], isNotEmpty);
      expect(group.attributes?['aria-live'], isNull);
      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.attributes?['value'], '123456');
      expect(input.attributes?['aria-live'], isNull);
      final live = find.byComponentPredicate(
        (c) => c is DomComponent && c.attributes?['role'] == 'alert',
      );
      expect(live, findsOneComponent);
      expect(
        find.descendant(of: live, matching: find.text('Try again')),
        findsOneComponent,
      );
    });
  }

  group('InputOtp disabled state', () {
    testComponents(
      'sets the disabled attribute and attaches no interaction events '
      'when enabled is false',
      (tester) async {
        pumpWithTheme(
          tester,
          const InputOtp(enabled: false, length: _kLength),
        );
        final input =
            find.tag('input').evaluate().single.component as DomComponent;
        expect(input.attributes?.containsKey('disabled'), isTrue);
        // No `input`/`focus`/`blur` handlers attached at all when
        // disabled — a leftover handler would let the field keep
        // reacting to focus/typing despite `enabled: false`.
        expect(input.events, anyOf(isNull, isEmpty));
      },
    );

    testComponents(
      'does not set the disabled attribute when enabled is true',
      (tester) async {
        pumpWithTheme(tester, const InputOtp(length: _kLength));
        final input =
            find.tag('input').evaluate().single.component as DomComponent;
        expect(input.attributes?.containsKey('disabled'), isFalse);
        expect(input.events, isNotNull);
        expect(input.events, isNotEmpty);
      },
    );
  });
}
