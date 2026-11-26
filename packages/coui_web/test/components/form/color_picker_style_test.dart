// The `coui_web.dart` barrel re-exports `color_picker_style.dart`, so the
// resolver-level symbols (`resolveColorPicker` / `resolveColorPickerRules`
// / `ResolvedColorPicker` / `ResolvedColorPickerRules`) are available here
// without a direct `src/` import.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveColorPicker` / `resolveColorPickerRules` directly.
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
/// `token!.name` when routed onto a Tailwind class via `.tailwindColor`.
const _kRawGreen = CoreColor(0xFF00FF00);

void main() {
  group('ColorPicker border / ring — default (token) path', () {
    testComponents(
      'default borderColor / selectedRingColor tokens keep the Tailwind '
      'utility classes and emit no scoped rule (output-equivalent to '
      'pre-change)',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveColorPicker(
          context,
          scopeId: 'co-color-picker-test',
        );

        // Non-pseudo border — token → `border border-outline-variant` class.
        expect(
          resolved.swatch.className,
          contains('border border-outline-variant'),
        );
        // The saturation/value area draws no border.
        expect(
          resolved.saturationValueArea.className,
          isNot(contains('border')),
        );
        // The hue / alpha bars draw no border.
        expect(resolved.hueTrack.className, isNot(contains('border')));
        expect(resolved.alphaSlider.className, isNot(contains('border')));
        // No inline border-color on the token path.
        expect(
          resolved.swatch.inlineStyles?.properties.containsKey('border-color'),
          isNot(true),
        );

        // Pseudo hover ring — token colours keep the Tailwind ring classes.
        expect(
          resolved.recentSwatchUnselected.className,
          contains('hover:ring-1 hover:ring-outline-variant'),
        );

        // Non-pseudo selection ring — token → `ring-2 ring-primary` class,
        // no inline box-shadow.
        expect(
          resolved.recentSwatchSelected.className,
          contains('ring-2 ring-primary'),
        );
        expect(
          resolved.recentSwatchSelected.inlineStyles?.properties.containsKey(
            'box-shadow',
          ),
          isNot(true),
        );

        // No scoped rules on the default path.
        final rules = resolveColorPickerRules(
          context,
          scopeId: 'co-color-picker-test',
        );
        expect(rules.css, isEmpty);
      },
    );
  });

  // Regression for #3469: the trigger swatch relied on `disabled:opacity-50`
  // alone for its border (dimming the enabled border colour rather than
  // switching to a dedicated disabled tone).
  group(
    'ColorPicker disabled trigger border — dedicated colour token (#3469)',
    () {
      testComponents(
        'the swatch carries a disabled:border-disabled-outline class '
        'alongside the existing disabled:opacity-50',
        (tester) async {
          final context = _themedContext(tester);
          final resolved = resolveColorPicker(
            context,
            scopeId: 'co-color-picker-test',
          );

          expect(
            resolved.swatch.className,
            contains('disabled:border-disabled-outline'),
          );
          // The fill still dims via opacity — an arbitrary user-picked
          // colour has no dedicated "disabled" substitute to give it
          // instead, the one case design-tokens.md still allows a
          // multiplier for.
          expect(resolved.swatch.className, contains('disabled:opacity-50'));
        },
      );
    },
  );

  group('ColorPicker border — raw override (inline + scoped-rule) path', () {
    testComponents(
      'a raw borderColor override no longer throws — the swatch carries an '
      'inline border-color and the recent-swatch hover ring paints via a '
      'scoped .co-color-picker-sw-<id>:hover box-shadow rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreColorPickerStyle(borderColor: _kRawGreen);

        // Before the fix this call threw a null-check on `token!.name`.
        final resolved = resolveColorPicker(
          context,
          scopeId: 'co-color-picker-raw',
          colorPickerStyle: style,
        );

        // The enabled edge is the inline variable fallback; :disabled
        // selects its own value without competing with that inline colour.
        expect(
          resolved.swatch.inlineStyles?.properties['border-color'],
          'var(--co-color-picker-edge, rgb(0, 255, 0))',
        );
        expect(resolved.swatch.className, isNot(contains('border-outline')));
        // The bars draw no border, so the override does not reach them.
        expect(
          resolved.hueTrack.inlineStyles?.properties.containsKey(
            'border-color',
          ),
          isNot(true),
        );
        expect(
          resolved.alphaSlider.inlineStyles?.properties.containsKey(
            'border-width',
          ),
          isNot(true),
        );

        // (B) Pseudo hover ring → the `hover:ring-*` classes are dropped
        // and the swatch carries the scope class + a scoped rule.
        expect(
          resolved.recentSwatchUnselected.className,
          isNot(contains('hover:ring')),
        );
        expect(
          resolved.recentSwatchUnselected.className,
          contains('co-color-picker-sw-co-color-picker-raw'),
        );

        final rules = resolveColorPickerRules(
          context,
          scopeId: 'co-color-picker-raw',
          colorPickerStyle: style,
        );
        expect(
          rules.css,
          contains('.co-color-picker-sw-co-color-picker-raw:hover'),
        );
        expect(rules.css, contains('box-shadow'));
        expect(rules.css, contains('rgb(0, 255, 0)'));
      },
    );
  });

  group('ColorPicker redesigned chrome', () {
    testComponents(
      'area radius 8 with no border, 8px bar under an 18px handle, 20px '
      'recent swatches with radius 6 on one row, dashed empty swatch',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveColorPicker(
          context,
          scopeId: 'co-color-picker-chrome',
        );
        Map<String, String> props(WebElementChrome c) =>
            c.inlineStyles?.properties ?? const {};

        expect(
          props(resolved.saturationValueArea)['border-radius'],
          contains('radius-8'),
        );
        expect(
          props(resolved.saturationValueArea),
          isNot(contains('border-width')),
        );
        // Bar 8 high, hit box (= handle) 18 high.
        expect(props(resolved.hueTrack)['height'], '0.5rem');
        expect(props(resolved.hueSlider)['height'], '1.125rem');
        expect(props(resolved.handle)['width'], '1.125rem');
        expect(props(resolved.handle)['height'], '1.125rem');
        expect(props(resolved.recentSwatchUnselected)['width'], '1.25rem');
        expect(
          props(resolved.recentSwatchUnselected)['border-radius'],
          contains('radius-6'),
        );
        expect(props(resolved.swatch)['border-radius'], contains('radius-6'));
        expect(props(resolved.swatch)['width'], '2.0rem');
        // One row of recentColumns fixed columns; the rest collapse.
        expect(
          props(resolved.recentColorsGrid)['grid-template-columns'],
          'repeat(10, 1.25rem)',
        );
        expect(props(resolved.recentColorsGrid)['grid-auto-rows'], '0');
        // Empty swatch: no fill, dashes ride the text-colour channel.
        expect(
          resolved.swatchEmpty.className,
          contains('text-outline-variant'),
        );
        expect(
          props(resolved.swatchDashRect)['stroke-dasharray'],
          '3.0 2.0',
        );
      },
    );
  });

  group('ColorPicker selection ring — raw override (inline) path', () {
    testComponents(
      'a raw selectedRingColor override drops the ring-2 class and paints an '
      'inline box-shadow on the selected swatch instead',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreColorPickerStyle(selectedRingColor: _kRawGreen);

        final resolved = resolveColorPicker(
          context,
          scopeId: 'co-color-picker-ring',
          colorPickerStyle: style,
        );

        // (C) Non-pseudo persistent ring → inline `box-shadow`, no
        // `ring-2 ring-*` utility class.
        expect(
          resolved.recentSwatchSelected.className,
          isNot(contains('ring-2')),
        );
        final boxShadow = resolved
            .recentSwatchSelected
            .inlineStyles
            ?.properties['box-shadow'];
        expect(boxShadow, isNotNull);
        expect(boxShadow, contains('rgb(0, 255, 0)'));

        // A raw selected-ring override does not add any scoped rule (the
        // persistent ring is inline; only the raw hover ring needs a rule).
        final rules = resolveColorPickerRules(
          context,
          scopeId: 'co-color-picker-ring',
          colorPickerStyle: style,
        );
        expect(rules.css, isEmpty);
      },
    );
  });
  group('ColorPicker handles', () {
    testComponents(
      'the saturation/value handle rings white with the weakest shadow; the '
      'hue handle wears the same white 3 ring',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveColorPicker(
          context,
          scopeId: 'co-color-picker-handles',
        );

        // SV handle: ring is white in every brightness (no surface token).
        final ring = resolved.handle.inlineStyles!.properties;
        expect(ring['border-color'], 'rgb(255, 255, 255)');
        expect(ring['border-width'], isNotNull);
        expect(ring['box-shadow'], 'var(--shadow-xs)');

        // Hue handle: the same white 3 ring and shadow; its fill is the
        // current colour, merged where it is drawn.
        final hue = resolved.hueHandle.inlineStyles!.properties;
        expect(hue['border-color'], 'rgb(255, 255, 255)');
        expect(hue['border-width'], ring['border-width']);
        expect(hue['border-width'], contains('stroke-width-3'));
        expect(hue['background-color'], isNull);
        expect(hue['box-shadow'], 'var(--shadow-xs)');
      },
    );

    testComponents('both handles are filled with the current colour', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ColorPicker(color: '#6750A4', promptMode: .inline),
      );
      await tester.pump();
      final filled = find
          .byComponentPredicate(
            (c) =>
                c is DomComponent &&
                (c.styles?.properties['background-color'] ?? '') == '#6750A4' &&
                (c.styles?.properties['width'] ?? '') == '1.125rem',
            description: 'handles filled with the current colour',
          )
          .evaluate()
          .toList();
      expect(filled, hasLength(2));
    });
  });

  group('ColorPicker mode tabs size', () {
    testComponents('the open panel composes the tabs at sm', (tester) async {
      pumpWithTheme(tester, const ColorPicker(color: '#FF0000'));
      await tester.pump();
      await tester.click(
        find.byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.attributes?.containsKey('aria-haspopup') ?? false),
          description: 'popover trigger',
        ),
      );
      await tester.pump();

      final tabs = find
          .byType(ToggleGroup<CoreColorPickerMode>)
          .evaluate()
          .toList();
      expect(tabs, hasLength(1));
      expect(
        (tabs.single.component as ToggleGroup<CoreColorPickerMode>).size,
        CoreComponentSize.sm,
      );
    });
  });

  group('the popover and hex-input styles reach their components', () {
    // Flutter forwards both; Web used to resolve them and drop them, so a
    // caller's override changed the picker on one platform only.
    testComponents('the popover gets popoverStyle', (tester) async {
      pumpWithTheme(
        tester,
        const ColorPicker(
          color: '#3B82F6',
          colorPickerStyle: CoreColorPickerStyle(
            popoverStyle: CorePopoverStyle(placementOffset: CoreSpace.space12),
          ),
        ),
      );

      final popover =
          find.byType(Popover).evaluate().single.component as Popover;
      expect(popover.popoverStyle?.placementOffset, CoreSpace.space12);
    });

    testComponents('the hex input gets hexInputStyle', (tester) async {
      pumpWithTheme(
        tester,
        const ColorPicker(
          color: '#3B82F6',
          showHexInput: true,
          colorPickerStyle: CoreColorPickerStyle(
            hexInputStyle: CoreTextFieldStyle(
              borderColor: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );

      final hex =
          find.byType(TextField).evaluate().single.component as TextField;
      expect(
        hex.textFieldStyle?.borderColor,
        const CoreColor.token(CoreColors.primary),
      );
    });
  });

  group('ColorPicker field trigger', () {
    testComponents(
      'the trigger is a 184-wide outlined field on the surface face',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveColorPicker(
          context,
          scopeId: 'co-color-picker-field',
        );
        final field = resolved.triggerField.inlineStyles!.properties;
        expect(field['min-width'], '11.5rem');
        // Logical sides: start 4 beside the swatch, end 12 after the chevron.
        expect(field['padding-inline-start'], contains('space-4'));
        expect(field['padding-inline-end'], contains('space-12'));
        expect(field['padding-block-start'], contains('space-4'));
        expect(field['padding-block-end'], contains('space-4'));
        expect(field.containsKey('padding'), isFalse);
        expect(field['gap'], contains('space-10'));
        expect(field['border-radius'], contains('radius-10'));
        expect(field['border-width'], contains('stroke-width-1'));
        expect(resolved.triggerField.className, contains('bg-surface'));
        expect(
          resolved.triggerField.className,
          contains('border-outline-variant'),
        );
        // Text roles: 13 Medium value, 13 Regular placeholder.
        expect(resolved.triggerValue.className, contains('text-label-medium'));
        expect(resolved.triggerValue.className, contains('text-on-surface'));
        expect(
          resolved.triggerPlaceholder.className,
          contains('text-body-small'),
        );
        expect(
          resolved.triggerPlaceholder.className,
          contains('text-on-surface-variant'),
        );
        expect(resolved.triggerChevronIconStyle.size, 16);
      },
    );

    testComponents('no colour shows the dashed swatch and the placeholder', (
      tester,
    ) async {
      pumpWithTheme(tester, const ColorPicker(color: ''));
      await tester.pump();
      expect(find.text('No colour picked'), findsOneComponent);
    });

    testComponents('a picked colour shows its hex', (tester) async {
      pumpWithTheme(tester, const ColorPicker(color: '#6750A4'));
      await tester.pump();
      expect(find.text('#6750A4'), findsOneComponent);
      expect(find.text('No colour picked'), findsNothing);
    });
  });

  group('ColorPicker panel', () {
    testComponents('the panel is a 14-corner box with 16 between sections', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveColorPicker(
        context,
        scopeId: 'co-color-picker-panel',
      );
      expect(
        resolved.popoverStyle.panelStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius14),
      );
      expect(
        resolved.popoverContent.inlineStyles!.properties['gap'],
        contains('space-16'),
      );
      // Handle: 18 with a 3px white ring.
      expect(
        resolved.handle.inlineStyles!.properties['border-width'],
        contains('stroke-width-3'),
      );
      expect(
        resolved.modeHexInputCell.inlineStyles!.properties['flex'],
        '2 1 0%',
      );
      expect(resolved.recentTitle.className, contains('text-label-xs'));
    });

    testComponents('the inputs are HEX + three channels at Size=sm', (
      tester,
    ) async {
      pumpWithTheme(tester, const ColorPicker(color: '#6750A4'));
      await tester.pump();
      await tester.click(
        find.byComponentPredicate(
          (component) =>
              component is DomComponent &&
              (component.attributes?.containsKey('aria-haspopup') ?? false),
          description: 'popover trigger',
        ),
      );
      await tester.pump();
      expect(find.text(kColorPickerHexLabel), findsOneComponent);
      final fields = find
          .byType(TextField)
          .evaluate()
          .map((e) => e.component as TextField)
          .toList();
      expect(fields, hasLength(4));
      expect(fields.every((f) => f.size == CoreComponentSize.sm), isTrue);
      expect(fields.first.initialValue, '#6750A4');
    });
  });

  group('ColorPicker inline presentation', () {
    testComponents('popover stays the default presentation', (tester) async {
      pumpWithTheme(tester, const ColorPicker(color: '#6750A4'));
      await tester.pump();
      expect(find.byType(Popover), findsOneComponent);
    });

    testComponents(
      'draws the panel in place with no shadow and a comparison cell',
      (tester) async {
        final changes = <String>[];
        pumpWithTheme(
          tester,
          ColorPicker(
            color: '#6750A4',
            onChanged: changes.add,
            promptMode: .inline,
          ),
        );
        await tester.pump();
        expect(find.byType(Popover), findsNothing);
        final popup = find.byType(Popup).evaluate().single.component as Popup;
        expect(popup.popupStyle?.boxShadow, isEmpty);
        expect(find.text('Cancel'), findsNothing);
        expect(find.text('Save'), findsNothing);
        final cells = find
            .byComponentPredicate(
              (c) =>
                  c is DomComponent &&
                  (c.styles?.properties['width'] ?? '') == '1.5rem' &&
                  (c.styles?.properties['height'] ?? '') == '1.5rem',
              description: 'comparison halves',
            )
            .evaluate()
            .toList();
        expect(cells, hasLength(2));
      },
    );

    testComponents('a disabled inline panel stays in view, inert', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ColorPicker(
          color: '#6750A4',
          enabled: false,
          promptMode: .inline,
        ),
      );
      await tester.pump();
      expect(find.byType(Popup), findsOneComponent);
      final fields = find
          .byType(TextField)
          .evaluate()
          .map((e) => e.component as TextField)
          .toList();
      expect(fields, hasLength(4));
      expect(fields.every((f) => !(f.enabled ?? true)), isTrue);
    });

    testComponents('the comparison cell is outlined with a 6 corner', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveColorPicker(
        context,
        scopeId: 'co-color-picker-inline',
      );
      final cell = resolved.compareCell.inlineStyles!.properties;
      expect(cell['border-radius'], contains('radius-6'));
      expect(cell['border-width'], contains('stroke-width-1'));
      expect(
        resolved.compareCell.className,
        contains('border-outline-variant'),
      );
      expect(resolved.inlinePanelStyle.boxShadow, isEmpty);
      expect(
        resolved.inlinePanelStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius14),
      );
    });
  });
}
