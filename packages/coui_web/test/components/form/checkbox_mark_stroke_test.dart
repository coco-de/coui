import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The check mark is an ordinary `Icon(LucideIcons.check)`: it follows the
/// icon stroke rule at its glyph size, and the indeterminate dash is
/// `markThickness` tall. Every glyph size on the checkbox ladder sits on the
/// rule's floor, which is also the dash's default thickness, so the check and
/// the dash are drawn at the same weight at every size.
///
/// The number each glyph size must write into its `stroke-width` attribute is
/// the row `coui_core` owns in `icon_stroke_vectors.json` — the table the
/// Flutter `Icon` reads too — so there is no second copy of it here.
const String kIconStrokeVectorsPath =
    '../coui_core/test/fixtures/icon_stroke_vectors.json';

/// Tolerance on a drawn stroke in px. The attribute is written to four
/// decimals (`2.1429` for glyph 14), which is off the exact 1.25 by under
/// 0.0001 once multiplied back by `box / viewBox`.
const double _kDrawnStrokeTolerance = 1e-4;

DomComponent _checkSvg() => find
    .tag('svg')
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>()
    .singleWhere((c) => c.attributes?['data-icon'] == 'lucide:check');

/// The indeterminate dash — the one `<div>` whose inline width and height
/// differ: the box writes one size to both (it is square), the dash writes
/// its length to the width and its thickness to the height.
DomComponent _dash() => find
    .tag('div')
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>()
    .singleWhere((c) {
      final width = c.styles?.properties['width'];
      final height = c.styles?.properties['height'];

      return width != null && height != null && width != height;
    });

String _bodyOf(DomComponent svg) =>
    svg.children!.whereType<RawText>().single.text;

List<String> _strokeWidths(String body) => RegExp(
  'stroke-width="([^"]*)"',
).allMatches(body).map((m) => m[1]!).toList();

/// `'1.25rem'` → 20 (px at the 16 px root font size).
double _remToPx(String? rem) {
  expect(rem, isNotNull);
  expect(rem, endsWith('rem'));

  return double.parse(rem!.substring(0, rem.length - 3)) * kRemDivisor;
}

/// What the check mark is drawn at, in px on the page: the `stroke-width`
/// attribute is in viewBox units, so it is scaled by `box px / viewBox`.
double _drawnCheckStroke(DomComponent svg) {
  final attribute = double.parse(_strokeWidths(_bodyOf(svg)).single);
  final boxPx = _remToPx(svg.styles!.properties['width']);
  final viewBox = double.parse(svg.attributes!['viewBox']!.split(' ')[2]);

  return attribute * boxPx / viewBox;
}

/// The dash's thickness in px on the page: its height.
double _drawnDashThickness(DomComponent dash) =>
    _remToPx(dash.styles!.properties['height']);

void main() {
  final fixture =
      jsonDecode(File(kIconStrokeVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (fixture['cases']! as List).cast<Map<String, Object?>>();

  Map<String, Object?> rowFor(double tokenSize) => cases.singleWhere(
    (c) => (c['tokenSize']! as num).toDouble() == tokenSize,
    orElse: () => fail('no vector row for token size $tokenSize'),
  );

  // size → check glyph token size.
  const glyphOf = <CoreComponentSize, double>{
    CoreComponentSize.xs: 8,
    CoreComponentSize.sm: 10,
    CoreComponentSize.md: 10,
    CoreComponentSize.lg: 12,
    CoreComponentSize.xl: 14,
    CoreComponentSize.xl2: 16,
  };

  group('Checkbox check mark and dash share one weight', () {
    test('the ladder these tests assume is the ladder in coui_core', () {
      expect(
        glyphOf.keys.toSet(),
        CoreCheckboxStyle.defaultsBySize.keys.toSet(),
        reason: 'a size was added or removed — extend the table',
      );
      for (final entry in glyphOf.entries) {
        expect(
          CoreCheckboxStyle.defaultsBySize[entry.key]!.checkmarkSize,
          entry.value,
          reason: '${entry.key.name} check glyph size moved off the table',
        );
      }
      expect(fixture['viewBox'], 24);
    });

    test('the dash default is the icon rule floor', () {
      expect(
        CoreCheckboxStyle.defaultMarkThickness,
        CoreIconStroke.minRenderedWidth,
      );
      for (final glyph in glyphOf.values) {
        expect(
          CoreIconStroke.renderedWidth(glyph),
          CoreCheckboxStyle.defaultMarkThickness,
          reason:
              'glyph $glyph is above the floor, so the check would be '
              'heavier than the dash',
        );
      }
    });

    for (final entry in glyphOf.entries) {
      final size = entry.key;
      final glyph = entry.value;

      for (final checked in <bool?>[true, false, null]) {
        // Both glyphs are mounted in every state, so the weights do not
        // depend on which one is showing.
        testComponents(
          '${size.name} (glyph ${glyph.toInt()}) writes the fixture row, '
          'checked=$checked',
          (tester) async {
            pumpWithTheme(tester, Checkbox(checked: checked, size: size));

            final svg = _checkSvg();
            final row = rowFor(glyph);
            expect(_strokeWidths(_bodyOf(svg)), [row['svgString']]);
            expect(
              _drawnCheckStroke(svg),
              closeTo(row['renderedWidth']! as num, _kDrawnStrokeTolerance),
            );
          },
        );

        testComponents(
          '${size.name} (glyph ${glyph.toInt()}) draws the check as thick as '
          'the dash, checked=$checked',
          (tester) async {
            pumpWithTheme(tester, Checkbox(checked: checked, size: size));

            expect(
              _drawnCheckStroke(_checkSvg()),
              closeTo(
                _drawnDashThickness(_dash()),
                _kDrawnStrokeTolerance,
              ),
            );
          },
        );
      }
    }

    testComponents('a disabled checkbox draws the same weights', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Checkbox(
          checked: true,
          enabled: false,
          size: CoreComponentSize.lg,
        ),
      );

      final svg = _checkSvg();
      expect(_strokeWidths(_bodyOf(svg)), [rowFor(12)['svgString']]);
      expect(
        _drawnCheckStroke(svg),
        closeTo(_drawnDashThickness(_dash()), _kDrawnStrokeTolerance),
      );
    });

    for (final entry in glyphOf.entries) {
      final size = entry.key;
      final glyph = entry.value;

      testComponents(
        'it is an ordinary icon: the same bytes as a bare Icon at '
        '${size.name}',
        (tester) async {
          pumpWithTheme(
            tester,
            div([
              Checkbox(checked: true, size: size),
              Icon(LucideIcons.check, iconStyle: CoreIconStyle(size: glyph)),
            ]),
          );

          final checks = find
              .tag('svg')
              .evaluate()
              .map((e) => e.component)
              .whereType<DomComponent>()
              .where((c) => c.attributes?['data-icon'] == 'lucide:check')
              .toList();
          expect(checks, hasLength(2));
          // First the checkbox's mark, then the bare icon at the same size.
          expect(_bodyOf(checks[0]), _bodyOf(checks[1]));
        },
      );
    }

    for (final entry in glyphOf.entries) {
      final size = entry.key;
      final glyph = entry.value;

      testComponents(
        'a markThickness override moves only the dash at ${size.name}',
        (tester) async {
          pumpWithTheme(
            tester,
            Checkbox(
              checked: true,
              size: size,
              checkboxStyle: const CoreCheckboxStyle(markThickness: 2),
            ),
          );

          final svg = _checkSvg();
          expect(_drawnDashThickness(_dash()), 2);
          // The check keeps the icon rule's weight.
          expect(_strokeWidths(_bodyOf(svg)), [rowFor(glyph)['svgString']]);
          expect(
            _drawnCheckStroke(svg),
            closeTo(
              CoreCheckboxStyle.defaultMarkThickness,
              _kDrawnStrokeTolerance,
            ),
          );
        },
      );
    }
  });
}
