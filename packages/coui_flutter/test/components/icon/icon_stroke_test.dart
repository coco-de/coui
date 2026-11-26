// #5377 — a Lucide icon draws max(1.25, tokenSize / 16) token px of stroke.
//
// Every vendored Lucide glyph ships `stroke-width="2"`, which would grow the
// stroke with the icon (size ÷ 12): hairline-thin at 10, heavier than body
// text at 32. The resolver rewrites the glyph body through `CoreIconStroke`
// and the widget paints that string, so these tests read the SVG handed to
// flutter_svg — the one place the stroke is stated without rasterising — and
// the resolver output it was painted from.
//
// What each group pins, because a test that only checks "some number came
// out" passes for the wrong reason:
//  - the table rows come from the vector file coui_core owns, the same one
//    the Core and Web tests read, so a fix that lands on one platform only
//    fails on the other;
//  - the scaling group uses sizes BELOW 20. At 20 and above the attribute is
//    1.5 whichever size the rule is fed (`size/16 × 24/size`), so a resolver
//    that fed it the scaled size would pass there and fail only here;
//  - the preset group first proves the preset is really in force (it raises
//    `geometry.stroke`), otherwise "the icon did not thicken" holds trivially;
//  - the resolver group reads the finished string the widget paints, so a
//    widget that rebuilt the SVG on its own would diverge from it.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/icon_stroke_vectors.dart';
import '../../helpers/svg_picture_string.dart';
import '../../helpers/test_app.dart';

/// The glyph every vector row is drawn with: bundled, one path, authored at
/// `stroke-width="2"`.
const IconName kProbeGlyph = LucideIcons.check;

/// The resolved palette a surface preset bends — the default `ThemeData`
/// carries unresolved colour tokens, which a preset's colour constraint
/// cannot read.
final ThemeData kPresetBase = ThemeData.fromCore(CoreThemePresets.light);

/// A phone: the screen-wide 1.25× magnification the stroke must not follow.
const AdaptiveScaling kPhone = AdaptiveScaling(1.25);

/// Token sizes below 20 — where the attribute depends on the size it is fed.
const List<double> kSmallTokenSizes = [10, 12, 16];

/// A Lucide-prefixed glyph with several strokes, one of them not the
/// authored 2.
const IconName kMultiStroke = IconName('lucide', 'rule-probe-multi');
const IconSvgData kMultiStrokeData = IconSvgData(
  body:
      '<g fill="none" stroke="currentColor" stroke-width="2"> '
      '<path stroke-width="2" d="M5 12h14"/> '
      '<path stroke-width="1" d="M12 5v14"/> '
      '</g>',
);

/// A Lucide-prefixed glyph with no authored 2 at all.
const IconName kNoAuthoredWeight = IconName('lucide', 'rule-probe-widths');
const IconSvgData kNoAuthoredWeightData = IconSvgData(
  body:
      '<path stroke-width="1" d="M5 12h14"/> '
      '<path stroke-width="2.5" d="M12 5v14"/>',
);

/// One glyph per other icon set, each authored at the weight Lucide uses — so
/// a rule that forgot the prefix gate would rewrite them.
const List<IconName> kOtherSets = [
  IconName('heroicons', 'rule-probe'),
  IconName('radix-icons', 'rule-probe'),
  IconName('bootstrap-icons', 'rule-probe'),
];
const IconSvgData kOtherSetData = IconSvgData(
  body:
      '<path fill="none" stroke="currentColor" stroke-width="2" d="M5 12h14"/>',
);

/// Mounts [child] under the test app.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
}) async {
  // Unmount first: `buildTestApp` mounts the child in an `Overlay` whose
  // initial entries are only honoured on the first mount, so a second
  // `pumpWidget` would silently keep showing the first tree.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      Center(child: child),
      theme: theme,
      surfaceStyle: surfaceStyle,
    ),
  );
}

/// Mounts [child] and returns the SVG source of the single `Icon` in it.
Future<String> _svgOf(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  CoreSurfaceStyleId surfaceStyle = .defaultId,
}) async {
  await _pump(tester, child, theme: theme, surfaceStyle: surfaceStyle);

  return svgStringOf(tester, find.byType(Icon));
}

/// The geometry constraint the theme carries under [surfaceStyle].
Future<CoreSurfaceGeometryConstraint> _geometryUnder(
  WidgetTester tester,
  CoreSurfaceStyleId surfaceStyle,
) async {
  late CoreSurfaceGeometryConstraint geometry;
  await _pump(
    tester,
    Builder(
      builder: (context) {
        geometry = Theme.of(context).geometry;

        return const SizedBox.shrink();
      },
    ),
    theme: kPresetBase,
    surfaceStyle: surfaceStyle,
  );

  return geometry;
}

Icon _icon(double tokenSize, {IconName icon = kProbeGlyph}) =>
    Icon(icon, iconStyle: CoreIconStyle(size: tokenSize));

/// The box the icon was laid out in, in logical px.
double _boxOf(WidgetTester tester) =>
    tester.widget<SvgPicture>(find.byType(SvgPicture)).width!;

void main() {
  final vectors = loadIconStrokeVectors();

  setUp(() {
    IconResolver.instance
      ..register(kMultiStroke.id, kMultiStrokeData)
      ..register(kNoAuthoredWeight.id, kNoAuthoredWeightData);
    for (final other in kOtherSets) {
      IconResolver.instance.register(other.id, kOtherSetData);
    }
  });
  tearDown(IconResolver.instance.clearMemoryCache);

  group('the shared vector table', () {
    test('covers the ladder and the sizes off it', () {
      expect(
        vectors.map((v) => v.tokenSize).toSet(),
        containsAll(<double>[8, 10, 12, 14, 16, 18, 20, 22, 24, 28, 32]),
      );
    });

    for (final v in vectors) {
      testWidgets('token ${v.tokenSize} → stroke-width "${v.svgString}"', (
        tester,
      ) async {
        final svg = await _svgOf(tester, _icon(v.tokenSize));

        expect(strokeWidthsIn(svg), [v.svgString]);

        // The attribute is in glyph units; the box scales it. What the
        // screen sees is the rule's width, in token px (scaling is 1).
        final rendered = double.parse(v.svgString) * _boxOf(tester) / 24;
        expect(rendered, closeTo(v.renderedWidth, 1e-3));
      });
    }
  });

  group('only the stroke changes', () {
    testWidgets('every authored 2 is rewritten, other widths are left alone', (
      tester,
    ) async {
      final svg = await _svgOf(tester, _icon(16, icon: kMultiStroke));

      // 16 → 1.25 token px → 1.25 × 24 / 16 = 1.875 in glyph units.
      expect(strokeWidthsIn(svg), ['1.875', '1.875', '1']);
    });

    testWidgets('a glyph with no authored 2 comes back as it was', (
      tester,
    ) async {
      final svg = await _svgOf(
        tester,
        _icon(16, icon: kNoAuthoredWeight),
      );

      expect(strokeWidthsIn(svg), ['1', '2.5']);
    });

    testWidgets('the glyph geometry and colour source are untouched', (
      tester,
    ) async {
      final svg = await _svgOf(tester, _icon(16));
      final bundled = CoreBundledIcons.icons[kProbeGlyph.id]!;

      expect(svg, contains('d="M20 6L9 17l-5-5"'));
      expect(svg, contains('stroke="currentColor"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      expect(
        svg.replaceAll('stroke-width="1.875"', 'stroke-width="2"'),
        contains(bundled.body),
      );
    });
  });

  group('other icon sets are drawn as authored', () {
    for (final other in kOtherSets) {
      testWidgets('${other.prefix} keeps stroke-width "2"', (tester) async {
        // 16 would be rewritten to 1.875 if the prefix gate were missing.
        final svg = await _svgOf(tester, _icon(16, icon: other));

        expect(strokeWidthsIn(svg), ['2']);
      });
    }
  });

  group('the rule reads the token size, not the scaled one', () {
    final scaledTheme = kPhone.scale(const ThemeData());

    for (final token in [...kSmallTokenSizes, 24.0, 32.0]) {
      final expected = vectors.singleWhere((v) => v.tokenSize == token);

      testWidgets('token $token on a 1.25× screen → "${expected.svgString}"', (
        tester,
      ) async {
        final svg = await _svgOf(tester, _icon(token), theme: scaledTheme);

        expect(strokeWidthsIn(svg), [expected.svgString]);
        // The box is the scaled one …
        expect(_boxOf(tester), token * 1.25);
        // … and it scales the stroke with the glyph: token 20 would draw
        // 1.5625 px here, not the rule's 1.25.
        final rendered = double.parse(expected.svgString) * _boxOf(tester) / 24;
        expect(rendered, closeTo(expected.renderedWidth * 1.25, 1e-3));
      });
    }

    testWidgets('an ambient IconTheme size is a token size too', (
      tester,
    ) async {
      final svg = await _svgOf(
        tester,
        IconTheme.merge(
          data: const IconThemeData(size: 16),
          child: const Icon(kProbeGlyph),
        ),
        theme: scaledTheme,
      );

      expect(strokeWidthsIn(svg), ['1.875']);
      expect(_boxOf(tester), 20);
    });
  });

  group('a surface preset does not thicken the icon', () {
    testWidgets('the preset is in force: it raises the stroke scale', (
      tester,
    ) async {
      // The control. Without it, "the icon did not change under the preset"
      // would hold whether or not the preset was applied at all.
      final plain = await _geometryUnder(tester, .defaultId);
      final brutal = await _geometryUnder(tester, .neoBrutalism);

      expect(plain.stroke(CoreStrokeWidth.stroke1), CoreStrokeWidth.stroke1);
      expect(
        brutal.stroke(CoreStrokeWidth.stroke1),
        greaterThan(CoreStrokeWidth.stroke1),
      );
    });

    for (final v in vectors.where((v) => v.tokenSize <= 32)) {
      testWidgets('token ${v.tokenSize} draws "${v.svgString}" under it', (
        tester,
      ) async {
        final plain = await _svgOf(
          tester,
          _icon(v.tokenSize),
          theme: kPresetBase,
        );
        final brutal = await _svgOf(
          tester,
          _icon(v.tokenSize),
          theme: kPresetBase,
          surfaceStyle: .neoBrutalism,
        );

        expect(strokeWidthsIn(brutal), [v.svgString]);
        expect(brutal, plain);
      });
    }
  });

  group('the resolver hands the widget the finished SVG', () {
    final scaledTheme = kPhone.scale(const ThemeData());
    final probeData = CoreBundledIcons.icons[kProbeGlyph.id]!;

    /// Resolves [icon] the way the widget does and returns the output.
    Future<ResolvedIcon> resolve(
      WidgetTester tester, {
      required IconName icon,
      required IconSvgData? data,
      CoreIconStyle? style,
      ThemeData? theme,
    }) async {
      late ResolvedIcon resolved;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveIcon(
              context,
              icon: icon,
              data: data,
              widgetStyle: style,
            );

            return const SizedBox.shrink();
          },
        ),
        theme: theme,
      );

      return resolved;
    }

    testWidgets('the string carries the rule, and the widget paints it', (
      tester,
    ) async {
      const style = CoreIconStyle(size: 16);
      final resolved = await resolve(
        tester,
        icon: kProbeGlyph,
        data: probeData,
        style: style,
        theme: scaledTheme,
      );

      // Token 16 on a 1.25× screen: the box is the scaled 20, and the rule is
      // fed 16 (fed the scaled 20 it would write 1.25 × 24 / 20 = 1.5).
      expect(resolved.size, 20);
      expect(strokeWidthsIn(resolved.svgString!), ['1.875']);
      expect(resolved.svgString, contains('width="20.0"'));

      final painted = await _svgOf(
        tester,
        const Icon(kProbeGlyph, iconStyle: style),
        theme: scaledTheme,
      );
      expect(painted, resolved.svgString);
    });

    testWidgets('no glyph data yet → no string, the box is still sized', (
      tester,
    ) async {
      final resolved = await resolve(
        tester,
        icon: kProbeGlyph,
        data: null,
        style: const CoreIconStyle(size: 16),
        theme: scaledTheme,
      );

      expect(resolved.svgString, isNull);
      expect(resolved.size, 20);
    });

    testWidgets('another set comes back as authored', (tester) async {
      final resolved = await resolve(
        tester,
        icon: kOtherSets.first,
        data: kOtherSetData,
        style: const CoreIconStyle(size: 16),
      );

      expect(strokeWidthsIn(resolved.svgString!), ['2']);
    });

    testWidgets('an ambient IconTheme size feeds the rule as a token size', (
      tester,
    ) async {
      late ResolvedIcon resolved;
      await _pump(
        tester,
        IconTheme.merge(
          data: const IconThemeData(size: 12),
          child: Builder(
            builder: (context) {
              resolved = resolveIcon(
                context,
                icon: kProbeGlyph,
                data: probeData,
                widgetStyle: null,
              );

              return const SizedBox.shrink();
            },
          ),
        ),
        theme: scaledTheme,
      );

      expect(resolved.size, 15);
      // 12 → 1.25 token px → 1.25 × 24 / 12 (fed the scaled 15 it would be 2).
      expect(strokeWidthsIn(resolved.svgString!), ['2.5']);
    });
  });

  group('the rule divides by the glyph viewBox, not by 24', () {
    // Every vendored Lucide glyph is 24 wide, so only a glyph registered here
    // can tell a widget that passes its own viewBox from one that wrote 24.
    const grid16 = IconName('lucide', 'rule-probe-grid-16');
    const grid48 = IconName('lucide', 'rule-probe-grid-48');
    const body =
        '<path fill="none" stroke="currentColor" stroke-width="2" '
        'd="M2 8h12"/>';

    setUp(() {
      IconResolver.instance
        ..register(
          grid16.id,
          const IconSvgData(body: body, width: 16, height: 16),
        )
        ..register(
          grid48.id,
          const IconSvgData(body: body, width: 48, height: 48),
        );
    });

    testWidgets('a 16-unit glyph at token 12 → 1.25 × 16 / 12', (tester) async {
      final svg = await _svgOf(tester, _icon(12, icon: grid16));

      // 24 hard-coded would write 1.25 × 24 / 12 = 2.5.
      expect(strokeWidthsIn(svg), ['1.6667']);
      expect(svg, contains('viewBox="0 0 16 16"'));
      final rendered =
          double.parse(strokeWidthsIn(svg).single) * _boxOf(tester) / 16;
      expect(rendered, closeTo(1.25, 1e-3));
    });

    testWidgets('a 48-unit glyph at token 24 → 1.5 × 48 / 24', (tester) async {
      final svg = await _svgOf(tester, _icon(24, icon: grid48));

      // 24 hard-coded would write 1.5 × 24 / 24 = 1.5.
      expect(strokeWidthsIn(svg), ['3']);
      expect(svg, contains('viewBox="0 0 48 48"'));
      final rendered =
          double.parse(strokeWidthsIn(svg).single) * _boxOf(tester) / 48;
      expect(rendered, closeTo(1.5, 1e-3));
    });
  });
}
