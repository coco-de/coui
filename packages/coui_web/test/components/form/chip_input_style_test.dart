import 'package:coui_web/coui_web.dart';
// chip_input_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/form/chip_input/chip_input_style.dart';
// The composed field's resolver — the corner tests read the `<input>` it emits.
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Rules owned by this frame, independently of its composed children.
Finder _frameStyles(ComponentTester tester) {
  final id = _divs(tester).first.id;
  return find.byComponentPredicate((component) {
    if (id == null || component is! DomComponent || component.tag != 'style') {
      return false;
    }
    final css =
        component.children
            ?.whereType<RawText>()
            .map((text) => text.text)
            .join() ??
        '';
    return css.contains('#$id:');
  });
}

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveChipInput` / `resolveChipInputRules` directly.
///
/// Local rather than shared: `pump_with_theme.dart` has no componentTheme
/// hook, and widening it is out of this component's scope.
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
/// `token!.name` when routed onto a pseudo-state Tailwind class.
const _kRawGreen = CoreColor(0xFF00FF00);

/// Every `<div>` in the pumped tree, for id / child assertions.
Iterable<DomComponent> _divs(ComponentTester tester) =>
    find.tag('div').evaluate().map((e) => e.component as DomComponent);

/// The root `className` as a set of whole classes. Substring assertions pass
/// whether or not the class is really there as its own token (`hover:border-
/// on-surface` is a substring of `focus-within:hover:border-outline`), and
/// this axis is exactly about which pseudo-states a class is scoped to.
Set<String> _classes(String className) =>
    className.split(' ').where((c) => c.isNotEmpty).toSet();

void main() {
  group('ChipInput frame focus-ring — default (class-safe) path', () {
    testComponents(
      'the frame keeps the focus-within:outline utility classes and emits '
      'no scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveChipInput(context, enabled: true);

        final classes = resolved.root.className.split(' ');
        expect(
          classes,
          containsAll(<String>[
            'outline-none',
            'focus-within:outline-2',
            'focus-within:outline-offset-2',
            'focus-within:outline-focus-ring',
          ]),
        );
        // The ring is an outline, so its offset is a real gap and the
        // transparent default band needs no class — no `ring-*` utility
        // (whose offset band is a painted box-shadow) is emitted.
        expect(resolved.root.className, isNot(contains('ring-offset')));

        final rules = resolveChipInputRules(
          context,
          scopeId: 'co-chip-input-test',
          enabled: true,
        );
        expect(rules.css, isEmpty);
      },
    );

    testComponents('an on-scale width / offset override rides the classes', (
      tester,
    ) async {
      final context = _themedContext(tester);
      // align is the child-edge → ring-outer-edge distance, so the
      // Tailwind offset step is `align - width` = 8.
      const style = CoreChipInputStyle(
        focusOutlineStyle: CoreFocusOutlineStyle(align: 12, borderWidth: 4),
      );
      final resolved = resolveChipInput(
        context,
        enabled: true,
        chipInputStyle: style,
      );

      // A literal `outline-2` here would silently render the
      // design-system width for every on-scale override.
      final classes = resolved.root.className.split(' ');
      expect(classes, contains('focus-within:outline-4'));
      expect(classes, contains('focus-within:outline-offset-8'));
      expect(classes, isNot(contains('focus-within:outline-2')));

      final rules = resolveChipInputRules(
        context,
        scopeId: 'co-chip-input-test',
        enabled: true,
        chipInputStyle: style,
      );
      expect(rules.css, isEmpty);
    });
  });

  group('ChipInput frame focus-ring — raw override (scoped-rule) path', () {
    testComponents(
      'a raw ring borderColor override no longer throws — the ring classes '
      'are dropped and the ring paints via a scoped '
      '#<id>:focus-within outline rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreChipInputStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kRawGreen),
        );

        // Before the fix this call threw a null check on `token!.name`.
        final resolved = resolveChipInput(
          context,
          enabled: true,
          chipInputStyle: style,
        );
        expect(resolved.root.className, contains('outline-none'));
        // A raw colour has no class, so the whole
        // `focus-within:outline-*` block is dropped in favour of the
        // scoped rule (class XOR rule).
        expect(
          resolved.root.className,
          isNot(contains('focus-within:outline')),
        );

        final rules = resolveChipInputRules(
          context,
          scopeId: 'co-chip-input-raw',
          enabled: true,
          chipInputStyle: style,
        );
        expect(rules.css, contains('#co-chip-input-raw:focus-within{'));
        expect(rules.css, contains('outline-color:rgb(0, 255, 0);'));
        // The default band is transparent — no box-shadow, so the
        // frame's resting cast stays.
        expect(rules.css, isNot(contains('box-shadow')));
      },
    );

    testComponents(
      'the transparent sentinel takes the same path instead of throwing',
      (tester) async {
        // `CoreColor.transparent` carries no token either, and this file's
        // own `chromelessFieldStyle` already spells a transparent focus
        // outline — the gate has to cover it, not just user raw colours.
        final context = _themedContext(tester);
        const style = CoreChipInputStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: .transparent),
        );

        final resolved = resolveChipInput(
          context,
          enabled: true,
          chipInputStyle: style,
        );
        expect(
          resolved.root.className,
          isNot(contains('focus-within:outline')),
        );

        final rules = resolveChipInputRules(
          context,
          scopeId: 'co-chip-input-tr',
          enabled: true,
          chipInputStyle: style,
        );
        expect(rules.css, contains('#co-chip-input-tr:focus-within{'));
        expect(rules.css, contains('outline-color:rgba(0, 0, 0, 0.00);'));
      },
    );

    testComponents('an off-scale ring width leaves the Tailwind scale', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreChipInputStyle(
        focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 2.5),
      );

      final resolved = resolveChipInput(
        context,
        enabled: true,
        chipInputStyle: style,
      );
      expect(
        resolved.root.className,
        isNot(contains('focus-within:outline')),
      );

      final rules = resolveChipInputRules(
        context,
        scopeId: 'co-chip-input-off',
        enabled: true,
        chipInputStyle: style,
      );
      // 2.5px ring on a (4 - 2.5) = 1.5px offset. The class path could
      // only have rounded both to the `2` step.
      expect(rules.css, contains('outline-width:2.5px;'));
      expect(rules.css, contains('outline-offset:1.5px;'));
    });

    testComponents('a sub-1 ringOpacity is honoured only by the scoped rule', (
      tester,
    ) async {
      // The class path has no alpha channel, so an opacity override would
      // be silently dropped there; the scoped rule is the only place it
      // can land.
      final context = _themedContext(tester);
      const style = CoreChipInputStyle(
        focusOutlineStyle: CoreFocusOutlineStyle(ringOpacity: 0.5),
      );

      final resolved = resolveChipInput(
        context,
        enabled: true,
        chipInputStyle: style,
      );
      expect(
        resolved.root.className,
        isNot(contains('focus-within:outline')),
      );

      final rules = resolveChipInputRules(
        context,
        scopeId: 'co-chip-input-op',
        enabled: true,
        chipInputStyle: style,
      );
      expect(rules.css, contains('50%'));
    });

    testComponents(
      'a stated gap band paints as a box-shadow over the resting cast',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreChipInputStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            offsetColor: CoreFocusRing.opaqueOffsetColor,
          ),
        );

        final resolved = resolveChipInput(
          context,
          enabled: true,
          chipInputStyle: style,
        );
        expect(
          resolved.root.className,
          isNot(contains('focus-within:outline')),
        );

        final rules = resolveChipInputRules(
          context,
          scopeId: 'co-chip-input-band',
          enabled: true,
          chipInputStyle: style,
        );
        expect(
          rules.css,
          contains(
            'box-shadow:0 0 0 calc(4.0px - var(--coui-stroke-width-2)) '
            'rgb(var(--coui-surface)), '
            'var(--coui-control-shadow);',
          ),
        );
      },
    );
  });

  group('ChipInput frame focus-ring — merge chain', () {
    testComponents('the widget slot wins over the component theme slot', (
      tester,
    ) async {
      final themedData = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          chipInput: CoreChipInputTheme(
            style: CoreChipInputStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(
                align: 8,
                borderWidth: 4,
              ),
            ),
          ),
        ),
      );
      late BuildContext context;
      tester.pumpComponent(
        Theme(data: themedData, child: _ContextCapture((c) => context = c)),
      );

      // Theme alone: width 4, offset = align - width = 4.
      final themed = resolveChipInput(context, enabled: true).root.className;
      expect(themed, contains('focus-within:outline-4'));
      expect(themed, contains('focus-within:outline-offset-4'));

      // Widget slot on top. It moves `align` only, so the merge has to be
      // recursive: a slot-level `??` would drop the theme's width back to
      // the design-system 2 and nothing on screen would say why.
      final overridden = resolveChipInput(
        context,
        enabled: true,
        chipInputStyle: const CoreChipInputStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(align: 12),
        ),
      ).root.className;
      expect(overridden, contains('focus-within:outline-4'));
      expect(overridden, contains('focus-within:outline-offset-8'));
    });
  });

  group('ChipInput scoped-rule wiring', () {
    testComponents('the default path renders no <style> and stamps no id', (
      tester,
    ) async {
      pumpWithTheme(tester, const ChipInput(chips: ['a']));

      expect(_frameStyles(tester), findsNothing);
      expect(_divs(tester).first.id, isNull);
    });

    testComponents(
      'a raw ring override renders the <style> child and stamps the scope id '
      'the rule targets',
      (tester) async {
        pumpWithTheme(
          tester,
          const ChipInput(
            chips: ['a'],
            chipInputStyle: CoreChipInputStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(
                borderColor: _kRawGreen,
              ),
            ),
          ),
        );

        expect(_frameStyles(tester), findsOneComponent);

        final ids = [?_divs(tester).first.id];
        expect(ids, hasLength(1));
        // The selector and the element have to agree — a rule that names
        // an id nothing carries paints nothing, and it looks fine in the
        // resolver test.
        final styleText =
            _frameStyles(tester).evaluate().single.component as DomComponent;
        expect(
          (styleText.children?.first as RawText?)?.text,
          contains('#${ids.single}:focus-within'),
        );
      },
    );

    testComponents("a caller's own id is reused as the scope id", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ChipInput(
          chips: ['a'],
          chipInputStyle: CoreChipInputStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kRawGreen),
          ),
          id: 'my-chips',
        ),
      );

      final ids = [?_divs(tester).first.id];
      expect(ids, contains('my-chips'));

      final styleText =
          _frameStyles(tester).evaluate().single.component as DomComponent;
      expect(
        (styleText.children?.first as RawText?)?.text,
        contains('#my-chips:focus-within'),
      );
    });
  });

  // The frame is the box and the inline entry field inside it is chromeless,
  // so hover has to ride the frame's border: `disabled > focus > hover >
  // rest`. The focus indicator here is the ring, which only reads as a state
  // change if the border under it stays at rest — and Tailwind orders
  // `hover:` AFTER `focus-within:`, so a plain `hover:border-X` would beat a
  // focused frame at equal specificity.
  group('ChipInput frame hover border — default (class) path', () {
    testComponents(
      'the hover step rides hover:border-outline and emits no scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        final classes = _classes(
          resolveChipInput(context, enabled: true).root.className,
        );

        expect(classes, contains('border-outline-variant'));
        expect(classes, contains('hover:border-outline'));
        expect(
          resolveChipInputRules(
            context,
            scopeId: 'co-chip-input-hover',
            enabled: true,
          ).css,
          isEmpty,
        );
      },
    );

    testComponents(
      'focus wins: the resting border is restated under focus-within:hover: — '
      'three pseudo-classes outrank the single hover: whatever the stylesheet '
      'order',
      (tester) async {
        final context = _themedContext(tester);
        final classes = _classes(
          resolveChipInput(context, enabled: true).root.className,
        );

        // Whole-class: the stacked class and the plain one are distinct
        // tokens, and only the stacked one carries the focus guard.
        expect(
          classes,
          contains('focus-within:hover:border-outline-variant'),
        );
        expect(classes, contains('hover:border-outline'));
        // The restated border is the REST colour, never the hover one — a
        // `focus-within:hover:border-outline` would defeat its purpose.
        expect(classes, isNot(contains('focus-within:hover:border-outline')));
      },
    );

    testComponents('a token hoverBorderColor override rides its own class', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreChipInputStyle(
        hoverBorderColor: CoreColor.token(CoreColors.error),
      );
      final classes = _classes(
        resolveChipInput(
          context,
          enabled: true,
          chipInputStyle: style,
        ).root.className,
      );

      expect(classes, contains('hover:border-error'));
      expect(classes, isNot(contains('hover:border-outline')));
      expect(
        resolveChipInputRules(
          context,
          scopeId: 'co-chip-input-hover',
          enabled: true,
          chipInputStyle: style,
        ).css,
        isEmpty,
      );
    });

    testComponents('a token borderColor override is what focus restates', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final classes = _classes(
        resolveChipInput(
          context,
          enabled: true,
          chipInputStyle: const CoreChipInputStyle(
            borderColor: CoreColor.token(CoreColors.primary),
          ),
        ).root.className,
      );

      expect(classes, contains('border-primary'));
      expect(classes, contains('focus-within:hover:border-primary'));
      expect(classes, isNot(contains('focus-within:hover:border-outline')));
    });

    testComponents('a disabled frame has no hover step at all', (tester) async {
      final context = _themedContext(tester);
      final className = resolveChipInput(
        context,
        enabled: false,
      ).root.className;

      expect(className, isNot(contains('hover:')));
      expect(
        resolveChipInputRules(
          context,
          scopeId: 'co-chip-input-hover',
          enabled: false,
          chipInputStyle: const CoreChipInputStyle(
            hoverBorderColor: _kRawGreen,
          ),
        ).css,
        isEmpty,
        reason: 'a disabled frame paints no hover rule either',
      );
    });

    testComponents('a theme-level hoverBorderColor reaches the frame', (
      tester,
    ) async {
      final themedData = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          chipInput: CoreChipInputTheme(
            style: CoreChipInputStyle(
              hoverBorderColor: CoreColor.token(CoreColors.success),
            ),
          ),
        ),
      );
      late BuildContext context;
      tester.pumpComponent(
        Theme(data: themedData, child: _ContextCapture((c) => context = c)),
      );

      expect(
        _classes(resolveChipInput(context, enabled: true).root.className),
        contains('hover:border-success'),
      );
    });
  });

  group('ChipInput frame hover border — raw override (scoped-rule) path', () {
    testComponents(
      'a raw hoverBorderColor no longer throws — the hover class is dropped '
      'and the border steps via a scoped rule that yields to focus',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreChipInputStyle(hoverBorderColor: _kRawGreen);

        // A raw colour has no Tailwind class; routing it onto `hover:` used
        // to be a render-time null check on `token!.name`.
        final resolved = resolveChipInput(
          context,
          enabled: true,
          chipInputStyle: style,
        );
        expect(resolved.root.className, isNot(contains('hover:')));

        final rules = resolveChipInputRules(
          context,
          scopeId: 'co-chip-input-rawhover',
          enabled: true,
          chipInputStyle: style,
        );
        // `:not(:focus-within)` is what makes focus win — and the id makes
        // the rule outrank the single-class resting `border-outline-variant`.
        expect(
          rules.css,
          contains(
            '#co-chip-input-rawhover:not(:focus-within):hover'
            '{border-color: rgb(0, 255, 0);}',
          ),
        );
        // The resting border is a class here, so the rule needs no help.
        expect(rules.css, isNot(contains('!important')));
      },
    );

    testComponents(
      'a raw resting borderColor is inline, so the hover step has to be '
      '!important or it never shows',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreChipInputStyle(borderColor: _kRawGreen);

        final resolved = resolveChipInput(
          context,
          enabled: true,
          chipInputStyle: style,
        );
        // Nothing for a class to step: the inline border beats every class.
        expect(resolved.root.className, isNot(contains('hover:')));

        final rules = resolveChipInputRules(
          context,
          scopeId: 'co-chip-input-rawrest',
          enabled: true,
          chipInputStyle: style,
        );
        expect(
          rules.css,
          contains(
            '#co-chip-input-rawrest:not(:focus-within):hover'
            '{border-color: rgb(var(--coui-outline)) !important;}',
          ),
        );
      },
    );

    testComponents('the hover rule and the focus-ring rule share one <style>', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final rules = resolveChipInputRules(
        context,
        scopeId: 'co-chip-input-both',
        enabled: true,
        chipInputStyle: const CoreChipInputStyle(
          hoverBorderColor: _kRawGreen,
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kRawGreen),
        ),
      );

      expect(rules.css, contains('#co-chip-input-both:focus-within'));
      expect(
        rules.css,
        contains('#co-chip-input-both:not(:focus-within):hover'),
      );
    });
  });

  group('ChipInput frame hover border — scoped-rule wiring', () {
    testComponents(
      'a raw hover override renders the <style> child and stamps the scope id '
      'the rule targets',
      (tester) async {
        pumpWithTheme(
          tester,
          const ChipInput(
            chips: ['a'],
            chipInputStyle: CoreChipInputStyle(hoverBorderColor: _kRawGreen),
          ),
        );

        expect(_frameStyles(tester), findsOneComponent);

        final ids = [?_divs(tester).first.id];
        expect(ids, hasLength(1));
        final styleText =
            _frameStyles(tester).evaluate().single.component as DomComponent;
        expect(
          (styleText.children?.first as RawText?)?.text,
          contains('#${ids.single}:not(:focus-within):hover'),
        );
      },
    );

    testComponents('a disabled frame renders no hover <style> at all', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ChipInput(
          chips: ['a'],
          enabled: false,
          chipInputStyle: CoreChipInputStyle(hoverBorderColor: _kRawGreen),
        ),
      );

      expect(_frameStyles(tester), findsNothing);
    });
  });

  group('ChipInput inner field corners', () {
    /// The `border-radius` the composed chromeless `<input>` emits — the
    /// value a browser clips the field's content (the 1px caret included) to.
    String? inputRadius(BuildContext context, CoreTextFieldStyle style) =>
        resolveTextField(
          context,
          scopeId: 'tf',
          size: CoreComponentSize.md,
          expands: false,
          hasError: false,
          enabled: true,
          textFieldStyle: style,
        ).input.inlineStyles?.properties['border-radius'];

    testComponents(
      'the chromeless field is square, so the caret on its padding-0 left '
      'edge is not shaved by a rounded clip',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveChipInput(context, enabled: true);

        expect(
          inputRadius(context, resolved.fieldStyle),
          CoreBorderRadius.zero.toValue(),
        );
      },
    );

    // The resolver hands the field its style; this is the hop after it — the
    // widget has to put that style on the `<input>` a browser actually clips.
    testComponents(
      'a mounted ChipInput puts that square corner on its entry `<input>`',
      (tester) async {
        pumpWithTheme(tester, const ChipInput());

        final inputs = find
            .tag('input')
            .evaluate()
            .map((e) => e.component as DomComponent);
        expect(inputs, isNotEmpty);
        for (final input in inputs) {
          expect(
            input.styles?.properties['border-radius'],
            CoreBorderRadius.zero.toValue(),
          );
        }
      },
    );

    testComponents(
      'a field that leaves the corner unstated takes the md row radius — '
      'the probe sees a rounded corner when there is one',
      (tester) async {
        final context = _themedContext(tester);
        // Same chrome as the chromeless field minus the corner: the shape
        // that clipped the caret.
        const unsquared = CoreTextFieldStyle(padding: .zero, borderWidth: 0);

        final mdRow = CoreTextFieldStyle
            .defaultsBySize[CoreComponentSize.md]!
            .borderRadius!
            .toValue();
        expect(mdRow, isNot(CoreBorderRadius.zero.toValue()));
        expect(inputRadius(context, unsquared), mdRow);
      },
    );
  });

  // The frame's redesigned chrome (#5831): the text field's quiet resting
  // edge, 12 corner, directional padding and tokens (not an opacity wash)
  // for disabled.
  group('ChipInput frame chrome — redesigned defaults', () {
    testComponents('rests on outline-variant, hovers to outline, 12 corner', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final root = resolveChipInput(context, enabled: true).root;
      final classes = _classes(root.className);

      expect(classes, contains('border-outline-variant'));
      expect(classes, contains('hover:border-outline'));
      expect(
        root.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius12).toValue(),
      );
    });

    testComponents('padding is stated with logical sides', (tester) async {
      final context = _themedContext(tester);
      final raw = resolveChipInput(
        context,
        enabled: true,
      ).root.inlineStyles?.properties;

      expect(raw, isNot(contains('padding')));
      expect(raw?['padding-block-start'], spaceCss(CoreSpace.space6));
      expect(raw?['padding-block-end'], spaceCss(CoreSpace.space6));
      expect(raw?['padding-inline-start'], spaceCss(CoreSpace.space10));
      expect(raw?['padding-inline-end'], spaceCss(CoreSpace.space14));
    });

    testComponents('a disabled frame takes the disabled tokens, no opacity', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final classes = _classes(
        resolveChipInput(context, enabled: false).root.className,
      );

      expect(classes, contains('bg-disabled-container'));
      expect(classes, contains('border-disabled-outline'));
      expect(classes, contains('cursor-not-allowed'));
      expect(classes, isNot(contains('opacity-50')));
      expect(classes, isNot(contains('bg-surface')));
      expect(
        classes.where((c) => c.startsWith('hover:')),
        isEmpty,
        reason: 'a disabled frame has no hover step',
      );
    });

    testComponents('the badge is the sm Chip filled · low with a 16 close', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveChipInput(context, enabled: true);

      expect(CoreChipInputStyle.chipVariant, CoreChipVariant.filled);
      expect(CoreChipInputStyle.chipEmphasis, CoreChipEmphasis.low);
      expect(CoreChipInputStyle.chipSize, CoreChipSize.sm);
      expect(resolved.chipStyle.closeButtonStyle?.width, CoreSize.size16);
      expect(resolved.chipStyle.closeButtonStyle?.height, CoreSize.size16);
      expect(resolved.chipStyle.closeIconStyle?.size, CoreIconSize.size12);
    });

    testComponents('the entry field is the plain TextField variant', (
      tester,
    ) async {
      expect(CoreChipInputStyle.fieldVariant, CoreTextFieldVariant.plain);
    });

    testComponents('the entry field wrapper carries the start inset', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final raw = resolveChipInput(
        context,
        enabled: true,
      ).field.inlineStyles?.properties;

      expect(raw?['padding-inline-start'], spaceCss(CoreSpace.space4));
    });

    // The floor before the entry field may share a row with the chips: the
    // Flutter twin reads the same Contract constant, so the two break rows
    // alike.
    testComponents(
      'the entry field floor is the Contract constant, 80 → 5rem',
      (
        tester,
      ) async {
        final raw = resolveChipInput(
          _themedContext(tester),
          enabled: true,
        ).field.inlineStyles?.properties;

        expect(CoreChipInputContract.defaultInputMinWidth, 80);
        expect(raw?['min-width'], '${80 / kRemDivisor}rem');
      },
    );

    // The frame's ring is the focus indicator. The composed field is the
    // `plain` variant, whose resting 1px edge tints `primary` on focus — a
    // second box around the line being typed on unless the style turns it off.
    testComponents('the entry input draws no focus border of its own', (
      tester,
    ) async {
      final context = _themedContext(tester);
      List<String> boxClasses(CoreTextFieldStyle? style) => resolveTextField(
        context,
        scopeId: 'tf',
        size: CoreComponentSize.md,
        expands: false,
        hasError: false,
        enabled: true,
        variant: CoreChipInputStyle.fieldVariant,
        textFieldStyle: style,
      ).affixWrapper.className.split(' ');

      // The plain field alone does tint its edge on focus…
      expect(
        boxClasses(null).where((c) => c.startsWith('focus-within:border-')),
        isNotEmpty,
      );
      // …the style ChipInput hands it does not.
      final resolved = resolveChipInput(context, enabled: true);
      expect(
        boxClasses(
          resolved.fieldStyle,
        ).where((c) => c.startsWith('focus-within:border-')),
        isEmpty,
      );
    });
  });
}
