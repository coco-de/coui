// #5377 — the check is an ordinary Lucide icon, drawn at the icon stroke rule,
// and the indeterminate dash's thickness is the rule's floor, so the two read
// at the same weight at every checkbox size and every app scaling.
//
// What the assertions compare, because "some number came out" passes for the
// wrong reason:
//  - the check's drawn stroke is read the way the screen shows it: the
//    `stroke-width` attribute of the SVG handed to flutter_svg, times the box
//    that SVG is laid out in, over the viewBox. A check that went through the
//    icon box twice (a scaled size forwarded to an icon that scales itself)
//    only shows at a scaling other than 1, so 1.25 and 1.5 are mounted too;
//  - the dash is read off the render tree of an indeterminate checkbox (the
//    height its `Container` is laid out at), then compared with
//    `resolveCheckbox(...).markThickness` (token thickness × scaling), so a
//    widget that stopped painting the dash at the resolver's value fails here;
//  - the shared vector table coui_core owns states what the rule gives for
//    the check's token size, so a rule that drifted on one platform fails
//    here as well.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/icon_stroke_vectors.dart';
import '../../helpers/svg_picture_string.dart';

/// App scalings the check and the dash must agree at.
const List<double> kScalings = [1, 1.25, 1.5];

/// The `stroke-width` attribute is written with at most four decimals
/// (`CoreIconStroke.formatNumber`), so a drawn width read back from it can
/// differ from the exact one by half a unit of the fourth decimal, scaled by
/// the box over the viewBox. Token 14 (`xl`) is the only checkbox glyph whose
/// attribute is not exact (2.142857… → 2.1429).
double _attributeRounding(double box) => 0.5e-4 * box / kIconStrokeViewBox;

/// What mounting a checkbox gave back.
class _Mounted {
  const _Mounted({
    required this.resolved,
    required this.svg,
    required this.box,
    required this.dash,
  });

  /// The resolver output for the checkbox that was mounted.
  final ResolvedCheckbox resolved;

  /// The SVG source of the check glyph — the only `Icon` a checkbox draws.
  final String svg;

  /// The box the check glyph was laid out in, in logical px.
  final double box;

  /// The indeterminate dash as the render tree lays it out, in logical px.
  /// Read only when the checkbox was mounted indeterminate (`checked: null`),
  /// the one state the dash is on screen in; `null` otherwise.
  final Size? dash;

  /// The check's stroke as the screen shows it, in logical px.
  double get checkPx =>
      double.parse(strokeWidthsIn(svg).single) * box / kIconStrokeViewBox;
}

/// Mounts a checkbox under [scaling] and reads the mark that is on screen in
/// its [checked] state off it: the check when checked, the dash when
/// indeterminate (`checked: null`).
Future<_Mounted> _mount(
  WidgetTester tester, {
  CoreComponentSize size = .md,
  CoreCheckboxStyle? checkboxStyle,
  double scaling = 1,
  ThemeData theme = const ThemeData(),
  bool? checked = true,
}) async {
  late ResolvedCheckbox resolved;
  await tester.pumpWidget(const material.SizedBox.shrink());
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: AdaptiveScaling(scaling).scale(theme),
        child: material.Column(
          children: [
            material.Builder(
              builder: (context) {
                resolved = resolveCheckbox(
                  context,
                  size: size,
                  checkboxStyle: checkboxStyle,
                );

                return const material.SizedBox.shrink();
              },
            ),
            Checkbox(
              checked: checked,
              onChanged: (_) {},
              size: size,
              checkboxStyle: checkboxStyle,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // The dash is the one pill-cornered `Container` filled with the mark ink.
  // It is found by how it is decorated and measured by how it is laid out, so
  // the height compared later is not the resolver's own number read back.
  final dash = checked == null
      ? tester.getSize(
          find.byWidgetPredicate((widget) {
            if (widget is! Container) {
              return false;
            }
            final decoration = widget.decoration;

            return decoration is BoxDecoration &&
                decoration.color == resolved.checkmarkColor &&
                decoration.borderRadius == resolved.indeterminateBorderRadius;
          }),
        )
      : null;

  return _Mounted(
    resolved: resolved,
    svg: svgStringOf(tester, find.byType(Checkbox)),
    box: tester.widget<SvgPicture>(find.byType(SvgPicture)).width!,
    dash: dash,
  );
}

void main() {
  final vectors = loadIconStrokeVectors();

  for (final size in CoreCheckboxStyle.defaultsBySize.keys) {
    final token = CoreCheckboxStyle.defaultsBySize[size]!.checkmarkSize!;
    final row = vectors.singleWhere((v) => v.tokenSize == token);

    for (final scaling in kScalings) {
      testWidgets(
        '$size at $scaling× draws the check and the dash at one weight',
        (tester) async {
          final mounted = await _mount(tester, size: size, scaling: scaling);

          // The glyph is laid out once, at the scaled token size.
          expect(mounted.box, closeTo(token * scaling, 1e-9));

          // The check follows the shared rule for its token size …
          expect(strokeWidthsIn(mounted.svg), [row.svgString]);
          expect(
            mounted.checkPx,
            closeTo(
              row.renderedWidth * scaling,
              _attributeRounding(mounted.box),
            ),
            reason: 'the check at $size is the rule weight, scaled',
          );

          // … the dash is the rule's floor, scaled …
          expect(
            mounted.resolved.markThickness,
            closeTo(CoreIconStroke.minRenderedWidth * scaling, 1e-9),
          );

          // … and the dash the widget lays out is that thickness …
          final dashed = await _mount(
            tester,
            size: size,
            scaling: scaling,
            checked: null,
          );
          expect(
            dashed.dash!.height,
            closeTo(dashed.resolved.markThickness, 1e-9),
            reason:
                'the dash at $size, $scaling× is laid out at the thickness '
                'the resolver states',
          );

          // … so the two are one weight on the screen.
          expect(
            mounted.checkPx,
            closeTo(dashed.dash!.height, _attributeRounding(mounted.box)),
            reason: 'check and dash at $size, $scaling×',
          );
        },
      );
    }
  }

  test('every checkbox glyph size is a row of the shared table', () {
    for (final size in CoreCheckboxStyle.defaultsBySize.keys) {
      final token = CoreCheckboxStyle.defaultsBySize[size]!.checkmarkSize!;

      expect(
        vectors.where((v) => v.tokenSize == token),
        hasLength(1),
        reason: 'token $token at $size',
      );
    }
  });

  testWidgets('a markThickness override moves the dash only', (tester) async {
    for (final size in [CoreComponentSize.xs, CoreComponentSize.md]) {
      for (final scaling in kScalings) {
        const override = CoreCheckboxStyle(markThickness: 2);
        final plain = await _mount(tester, size: size, scaling: scaling);
        final thick = await _mount(
          tester,
          size: size,
          scaling: scaling,
          checkboxStyle: override,
        );
        final plainDash = await _mount(
          tester,
          size: size,
          scaling: scaling,
          checked: null,
        );
        final thickDash = await _mount(
          tester,
          size: size,
          scaling: scaling,
          checkboxStyle: override,
          checked: null,
        );

        // The dash takes the override, scaled, and is laid out at it …
        expect(thick.resolved.markThickness, closeTo(2 * scaling, 1e-9));
        expect(
          thick.resolved.markThickness,
          isNot(closeTo(plain.resolved.markThickness, 1e-3)),
        );
        expect(thickDash.dash!.height, closeTo(2 * scaling, 1e-9));
        expect(
          thickDash.dash!.height,
          isNot(closeTo(plainDash.dash!.height, 1e-3)),
        );
        // … the check keeps following the icon rule.
        expect(thick.svg, plain.svg, reason: '$size, $scaling×');
        expect(thick.box, plain.box);
      }
    }
  });

  testWidgets('a theme markThickness moves the dash only', (tester) async {
    const theme = ThemeData(
      coreComponentTheme: CoreComponentTheme(
        checkbox: CoreCheckboxTheme(
          style: CoreCheckboxStyle(markThickness: 3),
        ),
      ),
    );

    final plain = await _mount(tester);
    final themed = await _mount(tester, theme: theme);
    final themedDash = await _mount(tester, theme: theme, checked: null);

    expect(themed.resolved.markThickness, 3);
    expect(themedDash.dash!.height, 3);
    expect(themed.svg, plain.svg);
  });

  testWidgets('a caller icon in the prefix keeps the icon rule', (
    tester,
  ) async {
    // The check is an ordinary icon: the prefix the caller supplies and the
    // check each draw at their own size's weight, whatever sits beside them.
    await tester.pumpWidget(
      material.MaterialApp(
        home: Theme(
          data: const ThemeData(),
          child: Checkbox(
            checked: true,
            onChanged: (_) {},
            prefix: const Icon(
              LucideIcons.chevronDown,
              iconStyle: CoreIconStyle(size: 16),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final prefixIcon = find.byWidgetPredicate(
      (widget) => widget is Icon && widget.icon == LucideIcons.chevronDown,
    );
    final checkIcon = find.byWidgetPredicate(
      (widget) => widget is Icon && widget.icon == LucideIcons.check,
    );
    expect(prefixIcon, findsOneWidget);
    expect(checkIcon, findsOneWidget);

    // 16 → 1.25 token px → 1.25 × 24 / 16 in glyph units.
    expect(strokeWidthsIn(svgStringOf(tester, prefixIcon)), ['1.875']);
    // The `md` check glyph is 10 → 1.25 × 24 / 10.
    expect(strokeWidthsIn(svgStringOf(tester, checkIcon)), ['3']);
  });
}
