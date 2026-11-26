// The material's edge band is an absolutely placed pseudo-element, and
// `inset: 0` is the element's padding box — inside its border. A surface with
// no border has none to skip, so the band lands on its outer edge, where the
// Flutter twin's sheen is painted over the whole box. A surface that keeps a
// transparent hairline (a field: its style states the edge itself and hides
// the line's colour but not its width) put the band one border inside, leaving
// the outermost row of pixels bare.
//
// So a surface that keeps a border says how wide it is
// (`--coui-surface-bleed`), and the stylesheet widens the band and the rim
// ring by it. A surface that says nothing keeps `inset: 0`.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/chip_input/chip_input_style.dart';
import 'package:coui_web/src/components/form/text_area/text_area_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

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

/// The band's position as the stylesheet states it: the top and bottom edges
/// read their own width first and fall back to the one a surface states for
/// every side.
const String _kBandInset =
    'inset:calc(var($kWebSurfaceBleedTopVar,var($kWebSurfaceBleedVar,0px)) '
    '* -1) calc(var($kWebSurfaceBleedVar,0px) * -1) '
    'calc(var($kWebSurfaceBleedBottomVar,var($kWebSurfaceBleedVar,0px)) '
    '* -1);';

String _treatment(CoreSurfaceRole role) {
  final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);

  return ThemeConfig.defaults().surfaceStyleTreatmentBlock(
    CoreSurfaceStyleId.liquidGlass,
    recipe.surfaceFor(role),
    role: role,
  );
}

String _rule(String css, String pseudo, CoreSurfaceRole role) {
  final roleClass = switch (role) {
    CoreSurfaceRole.content => kWebSurfaceRoleContent,
    CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
  };
  final at = css.indexOf('.$kWebSurfaceMarker.$roleClass$pseudo{');
  expect(at, isNonNegative, reason: 'no $pseudo rule for ${role.name}');

  return css.substring(at, css.indexOf('}', at) + 1);
}

void main() {
  group('the stylesheet reaches the band over the border a surface keeps', () {
    for (final role in CoreSurfaceRole.values) {
      test('the ${role.name} band is widened by the stated border', () {
        final band = _rule(_treatment(role), '::after', role);

        expect(band, contains(_kBandInset));
        expect(band, isNot(contains('inset:0;')));
      });

      test('and so is the ${role.name} rim ring', () {
        final ring = _rule(_treatment(role), '::before', role);

        expect(ring, contains(_kBandInset));
        expect(ring, isNot(contains('inset:0;')));
      });
    }

    test('a surface that states no border keeps the box it is', () {
      // The fallback is the zero the reset rule gives every marked surface,
      // so the default is `inset: 0` for a card.
      expect(_kBandInset, contains('$kWebSurfaceBleedVar,0px'));
    });

    test('a bar with one hairline widens the band on that edge only', () {
      // The sides read the uniform width alone, which a one-edge bar never
      // states — they keep the box they are. Top and bottom each have a
      // variable of their own, and neither reads the other's.
      final inset = _kBandInset.substring('inset:'.length);
      final edges = inset.split(' calc(');

      expect(edges, hasLength(3));
      final [top, sides, bottom] = edges;
      expect(top, contains(kWebSurfaceBleedTopVar));
      expect(top, isNot(contains(kWebSurfaceBleedBottomVar)));
      expect(sides, isNot(contains(kWebSurfaceBleedTopVar)));
      expect(sides, isNot(contains(kWebSurfaceBleedBottomVar)));
      expect(bottom, contains(kWebSurfaceBleedBottomVar));
      expect(bottom, isNot(contains(kWebSurfaceBleedTopVar)));
    });

    test('and no surface inherits a top width its ancestor stated', () {
      // `initial` is the guaranteed-invalid value, so the band's fallback to
      // the uniform width takes over on every marked element — a button inside
      // a docked bar does not draw its band past its own top edge.
      expect(
        ThemeConfig.defaults().cssVariables,
        allOf(
          contains('$kWebSurfaceBleedTopVar:initial;'),
          contains('$kWebSurfaceBleedBottomVar:initial;'),
        ),
      );
    });
  });

  group('surfaces that keep a border say how wide it is', () {
    testComponents('a field says it on the box that draws the border', (
      tester,
    ) async {
      final field = resolveTextField(
        _themedContext(tester),
        scopeId: 'tf',
        size: CoreComponentSize.md,
        expands: false,
        hasError: false,
        enabled: true,
      );
      final width = strokeWidthCss(CoreTextFieldStyle.defaultBorderWidth);

      expect(
        field.affixWrapper.inlineStyles?.properties['border-width'],
        width,
      );
      expect(
        field.affixWrapper.inlineStyles?.properties[kWebSurfaceBleedVar],
        width,
      );
      // The input is not a box: it keeps no border to reach over.
      expect(
        field.input.inlineStyles?.properties.containsKey(kWebSurfaceBleedVar),
        isFalse,
      );
    });

    testComponents('a text area says it on the wrapper, not the <textarea>', (
      tester,
    ) async {
      final area = resolveTextArea(
        _themedContext(tester),
        size: CoreComponentSize.md,
        expandableHeight: false,
        expandableWidth: false,
        hasError: false,
        obscureText: false,
        obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
      );
      final width = strokeWidthCss(CoreTextAreaStyle.defaultBorderWidth);

      expect(
        area.affixWrapper.inlineStyles?.properties['border-width'],
        width,
      );
      expect(
        area.affixWrapper.inlineStyles?.properties[kWebSurfaceBleedVar],
        width,
      );
      // The `<textarea>` is not a box: it keeps no border to reach over.
      expect(
        area.textarea.inlineStyles?.properties.containsKey(kWebSurfaceBleedVar),
        isFalse,
      );
    });

    testComponents('a footed text area says it on the frame', (tester) async {
      final area = resolveTextArea(
        _themedContext(tester),
        size: CoreComponentSize.md,
        expandableHeight: false,
        expandableWidth: false,
        hasError: false,
        hasFooter: true,
        obscureText: false,
        obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
      );

      expect(
        area.frame.inlineStyles?.properties[kWebSurfaceBleedVar],
        strokeWidthCss(CoreTextAreaStyle.defaultBorderWidth),
      );
    });

    testComponents('a stated border width is the one it says', (tester) async {
      final field = resolveTextField(
        _themedContext(tester),
        scopeId: 'tf',
        size: CoreComponentSize.md,
        expands: false,
        hasError: false,
        enabled: true,
        textFieldStyle: const CoreTextFieldStyle(
          borderWidth: CoreStrokeWidth.stroke2,
        ),
      );

      expect(
        field.affixWrapper.inlineStyles?.properties[kWebSurfaceBleedVar],
        strokeWidthCss(CoreStrokeWidth.stroke2),
      );
    });

    testComponents('the ChipInput frame says it', (tester) async {
      final frame = resolveChipInput(_themedContext(tester), enabled: true);

      expect(
        frame.root.inlineStyles?.properties[kWebSurfaceBleedVar],
        frame.root.inlineStyles?.properties['border-width'],
      );
      expect(
        frame.root.inlineStyles?.properties[kWebSurfaceBleedVar],
        isNotNull,
      );
    });

    testComponents('the FormattedInput box says it', (tester) async {
      final box = resolveFormattedInput(
        _themedContext(tester),
        enabled: true,
        focused: false,
      );

      expect(
        box.root.inlineStyles?.properties[kWebSurfaceBleedVar],
        box.root.inlineStyles?.properties['border-width'],
      );
      expect(
        box.root.inlineStyles?.properties[kWebSurfaceBleedVar],
        isNotNull,
      );
    });

    testComponents('a filled chip says the line its `border` class carries', (
      tester,
    ) async {
      final chip = resolveChip(
        _themedContext(tester),
        variant: .filled,
        chipColor: .defaultColor,
        size: .defaultSize,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
      );

      // No stated width: the `border` class is the stroke-1 hairline.
      expect(
        chip.root.inlineStyles?.properties[kWebSurfaceBleedVar],
        strokeWidthCss(CoreStrokeWidth.stroke1),
      );
    });

    testComponents('a chip with no fill is no surface and says nothing', (
      tester,
    ) async {
      final chip = resolveChip(
        _themedContext(tester),
        variant: .outlined,
        chipColor: .defaultColor,
        size: .defaultSize,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
      );

      expect(
        chip.root.inlineStyles?.properties.containsKey(kWebSurfaceBleedVar),
        isFalse,
      );
    });
  });

  group('a rendered field puts its input inside the box', () {
    testComponents('a bare field is a wrapper holding the input', (
      tester,
    ) async {
      pumpWithTheme(tester, const TextField());

      final boxes = find
          .tag('div')
          .evaluate()
          .map((e) => e.component)
          .whereType<DomComponent>()
          .where(
            (d) => (d.children ?? const []).any(
              (c) => c is DomComponent && c.tag == 'input',
            ),
          );

      expect(boxes, hasLength(1));
      // The box is what the material marks; the replaced `<input>` could not
      // draw a `::after` band at all.
      expect(boxes.single.classes, contains(kWebSurfaceMarker));
      expect(
        boxes.single.styles?.properties[kWebSurfaceBleedVar],
        isNotNull,
      );
    });

    testComponents('a bare text area is a wrapper holding the <textarea>', (
      tester,
    ) async {
      pumpWithTheme(tester, const TextArea());

      final boxes = find
          .tag('div')
          .evaluate()
          .map((e) => e.component)
          .whereType<DomComponent>()
          .where(
            (d) => (d.children ?? const []).any(
              (c) => c is DomComponent && c.tag == 'textarea',
            ),
          );

      expect(boxes, hasLength(1));
      // The replaced `<textarea>` could not draw a `::after` band at all, so
      // the box that is marked is the wrapper.
      expect(boxes.single.classes, contains(kWebSurfaceMarker));
      expect(boxes.single.styles?.properties[kWebSurfaceBleedVar], isNotNull);
      final textarea = (boxes.single.children ?? const [])
          .whereType<DomComponent>()
          .singleWhere((c) => c.tag == 'textarea');
      expect(textarea.classes ?? '', isNot(contains(kWebSurfaceMarker)));
    });
  });
}
