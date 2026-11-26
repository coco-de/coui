// The barrel re-exports `phone_input_style.dart`, so `resolvePhoneInput` /
// `resolvePhoneInputRules` / `ResolvedPhoneInput` come through `coui_web.dart`
// alongside the core types used for the overrides.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
// The composed field's resolver — the corner tests read the `<input>` it emits.
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolvePhoneInput` / `resolvePhoneInputRules` directly.
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

/// Expected CSS string for [_kRawGreen] emitted through `.toValue()`.
const _kRawGreenCss = 'rgb(0, 255, 0)';

/// Fixed scope id used across the tests so the scope classes / rule selectors
/// are deterministic.
const _kScopeId = 'test';

/// The vector table coui_core owns — the Flutter and Web `Icon` tests read the
/// same file, so the stroke each platform writes for a size is pinned to one
/// row.
const _kIconStrokeVectorsPath =
    '../coui_core/test/fixtures/icon_stroke_vectors.json';

void main() {
  group('PhoneInput pseudo colours — default (token) path', () {
    testComponents(
      'token defaults keep the pseudo utility classes, add no scope classes, '
      'and emit no scoped rule (output-equivalent to pre-change)',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
        );

        // Focus-within border rides its Tailwind pseudo class on the row.
        expect(resolved.root.className, contains('focus-within:border-'));
        expect(resolved.root.className, isNot(contains('co-phone-input-fw-')));

        // Hover background rides its Tailwind pseudo class on the dropdown
        // rows — the opaque `surfaceContainerHigh` tone, a neutral step off
        // the panel. The selector takes no fill and no edge of its own: the
        // hairline after it is a composed `Divider`.
        expect(
          resolved.countrySelector.className,
          isNot(contains('hover:bg-')),
        );
        expect(resolved.countrySelector.className, isNot(contains('border-')));
        expect(
          resolved.dropdownItem.className.split(' '),
          contains('hover:bg-surface-container-high'),
        );

        // The placeholder colour is not on the phone input's own elements
        // (`::placeholder` only matches an `<input>`, and both inputs belong
        // to composed TextFields) — it rides both field styles instead.
        expect(resolved.phoneInput.className, isNot(contains('placeholder:')));
        expect(resolved.searchInput.className, isNot(contains('placeholder:')));
        expect(
          resolved.numberFieldStyle.placeholderStyle?.color,
          CorePhoneInputStyle.defaultPlaceholderColor,
        );
        expect(
          resolved.searchFieldStyle.placeholderStyle?.color,
          CorePhoneInputStyle.defaultPlaceholderColor,
        );

        // No raw pseudo override → no scoped `<style>` rules.
        final rules = resolvePhoneInputRules(context, scopeId: _kScopeId);
        expect(rules.css, isEmpty);
      },
    );
  });

  // The outer box owns the one border. While the pointer is over it the border
  // steps to `on-surface`; `disabled > focus-within > hover > rest`.
  //
  // Tailwind v3 emits `hover:` AFTER `focus-within:` at the same specificity,
  // so a plain `hover:border-*` would beat `focus-within:border-primary` while
  // the pointer sits over a focused field. The hover step therefore excludes
  // `:focus-within` in the selector itself (`:hover:not(:focus-within)`), which
  // is independent of the order the two utilities are emitted in.
  group('PhoneInput hover border', () {
    const guardedHover = '[&:hover:not(:focus-within)]:';

    // The one `hover…` utility that targets the border, whatever its prefix.
    Iterable<String> hoverBorderClasses(String className) => className
        .split(' ')
        .where((c) => c.contains('hover') && c.contains('border-'));

    testComponents(
      'token path: outline-variant at rest, outline on hover, focus-within '
      'kept',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
        );
        final classes = resolved.root.className.split(' ');

        expect(classes, contains('border-outline-variant'));
        expect(classes, contains('focus-within:border-primary'));
        expect(classes, contains('${guardedHover}border-outline'));
        // Exactly one hover-border utility, and it is the guarded one — a
        // plain `hover:border-*` would out-cascade `focus-within:`.
        expect(hoverBorderClasses(resolved.root.className), [
          '${guardedHover}border-outline',
        ]);
        expect(
          classes.any((c) => c.contains('co-phone-input-hb-')),
          isFalse,
          reason: 'a token needs no scope class',
        );
        expect(
          resolvePhoneInputRules(context, scopeId: _kScopeId).css,
          isEmpty,
          reason: 'a token rides its class — no <style>',
        );
      },
    );

    testComponents(
      'the hover border does not touch the row hover background',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
        );

        expect(
          resolved.dropdownItem.className.split(' '),
          contains('hover:bg-surface-container-high'),
        );
        expect(
          resolved.dropdownItem.className,
          isNot(contains('border-outline')),
        );
        // The hairline keeps its own quieter edge, as a composed Divider.
        expect(
          resolved.separatorDividerStyle.color,
          CorePhoneInputStyle.defaultSeparatorColor,
        );
      },
    );

    testComponents(
      'a token hoverBorderColor override rides the guarded class',
      (
        tester,
      ) async {
        final context = _themedContext(tester);
        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
          phoneInputStyle: const CorePhoneInputStyle(
            hoverBorderColor: CoreColor.token(CoreColors.error),
          ),
        );

        expect(hoverBorderClasses(resolved.root.className), [
          '${guardedHover}border-error',
        ]);
      },
    );

    testComponents(
      'a raw hoverBorderColor override scopes by class and writes a rule that '
      'excludes focus-within',
      (tester) async {
        final context = _themedContext(tester);
        const style = CorePhoneInputStyle(hoverBorderColor: _kRawGreen);

        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        );

        expect(hoverBorderClasses(resolved.root.className), isEmpty);
        expect(
          resolved.root.className.split(' '),
          contains('co-phone-input-hb-$_kScopeId'),
        );

        final css = resolvePhoneInputRules(
          context,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        ).css;
        expect(
          css,
          '.co-phone-input-hb-$_kScopeId:hover:not(:focus-within)'
          '{border-color: $_kRawGreenCss;}',
        );
      },
    );

    testComponents(
      'raw focus-within and raw hover rules coexist; no hover rule lacks the '
      'focus-within exclusion',
      (tester) async {
        final context = _themedContext(tester);
        const style = CorePhoneInputStyle(
          focusBorderColor: _kRawGreen,
          hoverBorderColor: CoreColor(0xFF0000FF),
        );

        final css = resolvePhoneInputRules(
          context,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        ).css;

        expect(
          css,
          contains(
            '.co-phone-input-fw-$_kScopeId:focus-within'
            '{border-color: $_kRawGreenCss;}',
          ),
        );
        // Every `:hover` the border rule uses is immediately followed by the
        // exclusion — a bare `:hover` rule would win over the focus rule.
        final bareHover = RegExp(
          r'co-phone-input-hb-[^{]*:hover(?!:not\(:focus-within\))',
        );
        expect(bareHover.hasMatch(css), isFalse);
        expect(css, contains(':hover:not(:focus-within)'));
      },
    );

    // A raw resting border is emitted inline, and inline outranks every
    // selector. Flutter still steps on hover when the resting border is
    // restyled, so Web has to as well: the hover step turns `!important`
    // exactly when the resting border is inline.
    testComponents(
      'a raw resting border goes inline, and the hover step turns !important',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
          phoneInputStyle: const CorePhoneInputStyle(borderColor: _kRawGreen),
        );

        expect(
          resolved.root.inlineStyles?.properties['border-color'],
          _kRawGreenCss,
        );
        expect(hoverBorderClasses(resolved.root.className), [
          '$guardedHover!border-outline',
        ]);
      },
    );

    testComponents(
      'a raw resting border and a raw hover border: the rule is !important',
      (tester) async {
        final context = _themedContext(tester);
        const style = CorePhoneInputStyle(
          borderColor: _kRawGreen,
          hoverBorderColor: CoreColor(0xFF0000FF),
        );

        expect(
          resolvePhoneInputRules(
            context,
            scopeId: _kScopeId,
            phoneInputStyle: style,
          ).css,
          '.co-phone-input-hb-$_kScopeId:hover:not(:focus-within)'
          '{border-color: rgb(0, 0, 255) !important;}',
        );
      },
    );

    testComponents('a disabled field takes no hover step', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolvePhoneInput(
        context,
        enabled: false,
        scopeId: _kScopeId,
      );
      expect(hoverBorderClasses(resolved.root.className), isEmpty);
      // Focus-within stays: only the hover step is gated.
      expect(resolved.root.className, contains('focus-within:border-'));

      // A raw override changes nothing for a disabled field either: no scope
      // class on the box and no rule written.
      const style = CorePhoneInputStyle(hoverBorderColor: _kRawGreen);
      final disabledRaw = resolvePhoneInput(
        context,
        enabled: false,
        scopeId: _kScopeId,
        phoneInputStyle: style,
      );
      expect(disabledRaw.root.className, isNot(contains('co-phone-input-hb-')));
      expect(
        resolvePhoneInputRules(
          context,
          scopeId: _kScopeId,
          enabled: false,
          phoneInputStyle: style,
        ).css,
        isEmpty,
      );
    });

    // A zero-width Flutter border is a hairline, and the same chromeless style
    // composes into the Web `TextField`; both read this one Core style.
    testComponents('the chromeless inner fields state no hover border', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolvePhoneInput(
        context,
        enabled: true,
        scopeId: _kScopeId,
      );
      expect(resolved.numberFieldStyle.hoverBorderColor, CoreColor.transparent);
    });
  });

  group('PhoneInput pseudo colours — raw override (scoped-rule) path', () {
    testComponents(
      'a raw hoverColor override no longer throws — the hover:bg-* class is '
      'dropped, the shared scope class is added, and the css carries a :hover '
      'rule with the raw colour',
      (tester) async {
        final context = _themedContext(tester);
        const style = CorePhoneInputStyle(hoverColor: _kRawGreen);

        // Before the fix this threw a null-check on `token!.name`.
        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        );

        // The raw colour cannot ride `hover:bg-*`, so the class is dropped and
        // the shared scope class carries the state on every dropdown row.
        expect(resolved.dropdownItem.className, isNot(contains('hover:bg-')));
        expect(
          resolved.dropdownItem.className,
          contains('co-phone-input-h-$_kScopeId'),
        );

        final rules = resolvePhoneInputRules(
          context,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        );
        expect(rules.css, contains('.co-phone-input-h-$_kScopeId:hover'));
        expect(rules.css, contains('background-color'));
        expect(rules.css, contains(_kRawGreenCss));
      },
    );

    testComponents(
      'a raw separatorColor override emits inline border-color (non-pseudo — '
      'no scoped rule)',
      (tester) async {
        final context = _themedContext(tester);
        const style = CorePhoneInputStyle(separatorColor: _kRawGreen);

        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        );

        // Non-pseudo colour → forwarded to the composed `Divider`s (the
        // hairline after the selector and the one closing the search row).
        expect(resolved.separatorDividerStyle.color, _kRawGreen);
        expect(resolved.dividerStyle.color, _kRawGreen);

        // A non-pseudo colour never routes to a scoped rule.
        final rules = resolvePhoneInputRules(
          context,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        );
        expect(rules.css, isEmpty);
      },
    );

    testComponents(
      'a raw placeholderColor rides both composed field styles, not a rule '
      'on the phone input',
      (tester) async {
        final context = _themedContext(tester);
        const style = CorePhoneInputStyle(placeholderColor: _kRawGreen);

        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        );
        expect(resolved.numberFieldStyle.placeholderStyle?.color, _kRawGreen);
        expect(resolved.searchFieldStyle.placeholderStyle?.color, _kRawGreen);
        // The rest of the chromeless field style survives the overlay.
        expect(
          resolved.numberFieldStyle.borderWidth,
          CorePhoneInputStyle.chromelessFieldStyle.borderWidth,
        );

        final rules = resolvePhoneInputRules(
          context,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        );
        expect(rules.css, isEmpty);
      },
    );

    testComponents(
      'a caller searchFieldStyle placeholder still wins over placeholderColor '
      'for the search field',
      (tester) async {
        final context = _themedContext(tester);
        const searchOnly = CoreColor.token(CoreColors.onSurface);
        const style = CorePhoneInputStyle(
          placeholderColor: _kRawGreen,
          searchFieldStyle: CoreTextFieldStyle(
            placeholderStyle: CoreTextStyle(color: searchOnly),
          ),
        );

        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
          phoneInputStyle: style,
        );
        expect(resolved.searchFieldStyle.placeholderStyle?.color, searchOnly);
        expect(resolved.numberFieldStyle.placeholderStyle?.color, _kRawGreen);
      },
    );
  });

  group('PhoneInput chevron stroke follows the icon stroke rule', () {
    final fixture =
        jsonDecode(File(_kIconStrokeVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final cases = (fixture['cases']! as List).cast<Map<String, Object?>>();

    testComponents(
      'the chevron draws the rule weight at every size of the shared table',
      (tester) async {
        final context = _themedContext(tester);
        for (final row in cases) {
          final tokenSize = (row['tokenSize']! as num).toDouble();
          final resolved = resolvePhoneInput(
            context,
            enabled: true,
            scopeId: _kScopeId,
            phoneInputStyle: CorePhoneInputStyle(
              chevronIconStyle: CoreIconStyle(size: tokenSize),
            ),
          );

          expect(
            resolved.chevron.inlineStyles?.properties['stroke-width'],
            row['svgString'],
            reason: 'chevron at token size $tokenSize',
          );
        }
      },
    );

    testComponents('the default chevron size is a row of the table', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolvePhoneInput(
        context,
        enabled: true,
        scopeId: _kScopeId,
      );
      final size = CorePhoneInputStyle.defaultChevronIconStyle.size!;
      final row = cases.singleWhere(
        (c) => (c['tokenSize']! as num).toDouble() == size,
      );

      expect(
        resolved.chevron.inlineStyles?.properties['stroke-width'],
        row['svgString'],
      );
    });

    testComponents('a disabled chevron keeps the same weight', (tester) async {
      final context = _themedContext(tester);
      final enabled = resolvePhoneInput(
        context,
        enabled: true,
        scopeId: _kScopeId,
      );
      final disabled = resolvePhoneInput(
        context,
        enabled: false,
        scopeId: _kScopeId,
      );

      expect(
        disabled.chevron.inlineStyles?.properties['stroke-width'],
        enabled.chevron.inlineStyles?.properties['stroke-width'],
      );
    });
  });

  group('PhoneInput placeholder reaches the <input>', () {
    // The whole point: the colour has to land on the element `::placeholder`
    // can match. Before, both the token class and the raw scope class sat on
    // the wrapper `<div>`, where they matched nothing.
    List<DomComponent> inputs() => find
        .tag('input')
        .evaluate()
        .map((e) => e.component as DomComponent)
        .toList();

    testComponents('a token colour rides the number input as a class', (
      tester,
    ) async {
      pumpWithTheme(tester, const PhoneInput());

      final number = inputs().single;
      expect(number.classes, contains('placeholder:text-placeholder'));
    });

    testComponents(
      'a raw colour paints the number input through a scoped rule',
      (tester) async {
        pumpWithTheme(
          tester,
          const PhoneInput(
            phoneInputStyle: CorePhoneInputStyle(placeholderColor: _kRawGreen),
          ),
        );

        final number = inputs().single;
        expect(number.classes, isNot(contains('placeholder:text-')));
        final scopeClass = number.classes!
            .split(' ')
            .singleWhere((c) => c.startsWith('co-text-field-ph-'));

        final css = find
            .byType(RawText)
            .evaluate()
            .map((e) => (e.component as RawText).text)
            .join();
        expect(
          css,
          contains('.$scopeClass::placeholder{color: $_kRawGreenCss;}'),
        );
      },
    );
  });

  group('PhoneInput inner field corners', () {
    /// The `border-radius` a composed chromeless `<input>` emits — the value
    /// a browser clips the field's content (the 1px caret included) to.
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
      'the number field is square, so the caret on its padding-0 left edge is '
      'not shaved by a rounded clip',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolvePhoneInput(
          context,
          enabled: true,
          scopeId: _kScopeId,
        );
        final square = CoreBorderRadius.zero.toValue();

        expect(inputRadius(context, resolved.numberFieldStyle), square);
      },
    );

    // The resolver hands the field its style; this is the hop after it — the
    // widget has to put that style on the `<input>` a browser actually clips.
    testComponents(
      'a mounted PhoneInput puts that square corner on the number `<input>`',
      (tester) async {
        pumpWithTheme(tester, const PhoneInput());

        final number = find
            .tag('input')
            .evaluate()
            .map((e) => e.component as DomComponent)
            .single;
        expect(
          number.styles?.properties['border-radius'],
          CoreBorderRadius.zero.toValue(),
        );
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

  group('PhoneInput redesign (#5831)', () {
    testComponents('the box is the lg row, corner 12, quiet edge, and the '
        'disabled tokens instead of a dimming opacity', (tester) async {
      final context = _themedContext(tester);
      final enabled = resolvePhoneInput(
        context,
        enabled: true,
        scopeId: _kScopeId,
      );
      final disabled = resolvePhoneInput(
        context,
        enabled: false,
        scopeId: _kScopeId,
      );
      final props = enabled.root.inlineStyles!.properties;

      expect(props['height'], controlHeightCss(CoreControlSize.heightLg));
      expect(
        props['border-radius'],
        const CoreBorderRadius.all(CoreRadiusRole.panel).toValue(),
      );
      expect(enabled.root.className.split(' '), contains('bg-surface'));
      expect(
        disabled.root.className.split(' '),
        containsAll(['bg-disabled-container', 'border-disabled-outline']),
      );
      expect(
        disabled.numberFieldStyle.placeholderStyle?.color,
        CorePhoneInputStyle.defaultDisabledPlaceholderColor,
      );
      expect(
        disabled.dialCode.className.split(' '),
        contains('text-disabled-content'),
      );
    });

    testComponents('the number field insets 12 / 12 by reading order, never a '
        'physical shorthand', (tester) async {
      final resolved = resolvePhoneInput(
        _themedContext(tester),
        enabled: true,
        scopeId: _kScopeId,
      );
      final number = resolved.phoneInput.inlineStyles!.properties;

      expect(
        number['padding-inline-start'],
        'var(--coui-space-12)',
      );
      expect(
        number['padding-inline-end'],
        'var(--coui-space-12)',
      );
      expect(number, isNot(contains('padding')));
    });

    testComponents('the selector insets 14 / 10 by reading order, the flag '
        'is 14 with the part corner, the hairline 20 high', (tester) async {
      final resolved = resolvePhoneInput(
        _themedContext(tester),
        enabled: true,
        scopeId: _kScopeId,
      );
      final selector = resolved.countrySelector.inlineStyles!.properties;

      expect(selector['padding-inline-start'], isNotNull);
      expect(selector['padding-inline-end'], isNotNull);
      expect(selector, isNot(contains('padding')));

      final flag = resolved.flag.inlineStyles!.properties;
      expect(flag['height'], '${CoreSize.size14 / kRemDivisor}rem');
      expect(
        flag['border-radius'],
        const CoreBorderRadius.all(CoreRadiusRole.part).toValue(),
      );
      expect(
        resolved.separatorLine.inlineStyles!.properties['height'],
        '${CoreSize.size20 / kRemDivisor}rem',
      );
    });

    testComponents('the country list is the item picker panel: list inset '
        '6, rows 8 with corner 8, bodyMedium, check and search glyph', (
      tester,
    ) async {
      final resolved = resolvePhoneInput(
        _themedContext(tester),
        enabled: true,
        scopeId: _kScopeId,
      );
      final row = resolved.dropdownItem.inlineStyles!.properties;

      expect(
        resolved.dropdown.inlineStyles!.properties['padding'],
        const CoreEdgeInsets.all(CoreSpace.space6).toValue(),
      );
      expect(
        row['padding'],
        const CoreEdgeInsets.all(CoreSpace.space8).toValue(),
      );
      expect(
        row['border-radius'],
        const CoreBorderRadius.all(CoreRadiusRole.control).toValue(),
      );
      expect(resolved.dropdownItem.className, contains('text-body-medium'));
      expect(
        resolved.dropdownCheckIconStyle.color,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        resolved.searchIconStyle,
        CorePhoneInputStyle.defaultSearchIconStyle,
      );
      expect(
        resolved.popoverStyle.panelStyle?.borderColor,
        CoreItemPickerStyle.defaultBorderColor,
      );
      expect(resolved.popoverStyle.panelStyle?.padding, CoreEdgeInsets.zero);
    });
  });
}
