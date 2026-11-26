// #5149 — every icon a CoUI component draws ships in the package. On Web a
// bundled icon renders as an inline `<svg>`, so it needs neither the
// `<iconify-icon>` script nor a request to the Iconify API: it is in the
// server-rendered markup, and it shows offline and behind a strict CSP.
//
// The same inline `<svg>` is where the Lucide stroke rule lands
// (`CoreIconStroke`): a glyph is authored `stroke-width="2"` on a 24 grid and
// is rewritten to `max(1.25, size / 16)` token px.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
// icon_style.dart is not re-exported by the barrel — import it directly
// for resolver-level assertions.
import 'package:coui_web/src/components/icon/icon_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The vector table coui_core owns. The Flutter `Icon` test reads the same
/// file, so the string each platform writes for a given size is pinned to the
/// same row: a fix that lands on one platform only fails the other. That is
/// the whole Flutter-vs-Web parity check — there is no second copy of the
/// numbers here.
const String kIconStrokeVectorsPath =
    '../coui_core/test/fixtures/icon_stroke_vectors.json';

DomComponent _single(String tag) =>
    find.tag(tag).evaluate().single.component as DomComponent;

String _bodyOf(DomComponent svg) {
  final body = svg.children!.whereType<RawText>().single;

  return body.text;
}

String _renderedBody() =>
    (find.byType(RawText).evaluate().single.component as RawText).text;

/// Every `stroke-width="…"` value in [body], in document order.
List<String> _strokeWidths(String body) => RegExp(
  'stroke-width="([^"]*)"',
).allMatches(body).map((m) => m[1]!).toList();

void main() {
  final fixture =
      jsonDecode(File(kIconStrokeVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (fixture['cases']! as List).cast<Map<String, Object?>>();

  group('Icon bundled (Web)', () {
    testComponents('a bundled icon renders its SVG inline, with no script', (
      tester,
    ) async {
      pumpWithTheme(tester, const Icon(LucideIcons.chevronDown));

      expect(find.tag('iconify-icon'), findsNothing);
      final svg = _single('svg');
      final data = CoreBundledIcons.icons[LucideIcons.chevronDown.id]!;
      expect(svg.attributes?['viewBox'], '0 0 ${data.width} ${data.height}');
      expect(svg.attributes?['xmlns'], 'http://www.w3.org/2000/svg');
      // No role or name of its own — the same as the `<iconify-icon>` path.
      expect(svg.attributes?.keys.where((k) => k.startsWith('aria-')), isEmpty);
      expect(svg.attributes?['role'], isNull);
      // At the default size (24) the Lucide stroke rule writes 1.5 where the
      // glyph is authored 2 — and changes nothing else in the body.
      expect(CoreIconStyle.defaultSize, 24);
      expect(_renderedBody(), data.body.replaceAll('"2"', '"1.5"'));
    });

    testComponents('it keeps the box <iconify-icon> gives its host', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Icon(LucideIcons.chevronDown, iconStyle: CoreIconStyle(size: 16)),
      );

      final styles = _single('svg').styles!.properties;
      expect(styles['display'], 'inline-block');
      expect(styles['vertical-align'], '-0.125em');
      expect(styles['width'], '1.0rem');
      expect(styles['height'], '1.0rem');
      expect(styles['font-size'], '1.0rem');
    });

    testComponents('a caller can name a bundled icon for assistive tech', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Icon(
          LucideIcons.chevronDown,
          attributes: {'role': 'img', 'aria-label': 'Open'},
        ),
      );

      final attributes = _single('svg').attributes!;
      expect(attributes['role'], 'img');
      expect(attributes['aria-label'], 'Open');
    });

    testComponents('an icon outside the bundle still uses <iconify-icon>', (
      tester,
    ) async {
      const outside = IconName('mdi', 'home');
      expect(CoreBundledIcons.icons, isNot(contains(outside.id)));

      pumpWithTheme(tester, const Icon(outside));

      expect(find.tag('svg'), findsNothing);
      expect(_single('iconify-icon').attributes?['icon'], outside.id);
    });
  });

  group('Lucide stroke rule on the bundled <svg>', () {
    test('the vector table is for the 24-unit grid the bundle draws on', () {
      expect(fixture['viewBox'], 24);
      expect(
        CoreBundledIcons.icons.values.map((d) => d.width).toSet(),
        {24},
        reason: "the table's svg strings assume a 24-unit viewBox",
      );
    });

    for (final c in cases) {
      final tokenSize = (c['tokenSize']! as num).toDouble();
      final svgString = c['svgString']! as String;
      final rendered = c['renderedWidth']! as num;

      testComponents(
        'size $tokenSize draws $rendered px — stroke-width="$svgString"',
        (tester) async {
          pumpWithTheme(
            tester,
            Icon(
              LucideIcons.chevronDown,
              iconStyle: CoreIconStyle(size: tokenSize),
            ),
          );

          final data = CoreBundledIcons.icons[LucideIcons.chevronDown.id]!;
          final body = _renderedBody();
          expect(_strokeWidths(body), [svgString]);
          // Only the one attribute moves.
          expect(
            body,
            data.body.replaceAll(
              'stroke-width="2"',
              'stroke-width="$svgString"',
            ),
          );
        },
      );
    }

    testComponents('every bundled icon is rewritten, whole body, and only the '
        'stroke', (tester) async {
      final ids = CoreBundledIcons.icons.keys.toList();
      // One icon per bundled id, at 16 → stroke-width 1.875 (1.25 px).
      pumpWithTheme(
        tester,
        div([
          for (final id in ids)
            Icon(
              IconName(id.split(':').first, id.split(':').last),
              iconStyle: const CoreIconStyle(size: 16),
            ),
        ]),
      );

      final svgs = find.tag('svg').evaluate().map((e) => e.component).toList();
      expect(svgs, hasLength(ids.length));
      for (final svg in svgs.cast<DomComponent>()) {
        final id = svg.attributes!['data-icon']!;
        final authored = CoreBundledIcons.icons[id]!.body;
        final body = _bodyOf(svg);
        final authoredCount = RegExp('stroke-width="2"').allMatches(authored);

        expect(authoredCount, isNotEmpty, reason: '$id carries no stroke');
        expect(
          _strokeWidths(body),
          List.filled(authoredCount.length, '1.875'),
          reason: '$id was not fully rewritten',
        );
        expect(
          body,
          authored.replaceAll('stroke-width="2"', 'stroke-width="1.875"'),
          reason: '$id changed more than its stroke',
        );
      }
    });

    testComponents('the token size is the ambient IconTheme size when the '
        'icon states none', (tester) async {
      // 20 → 1.25 px → 1.5 in the 24 grid: the ambient size is the token
      // size the rule reads, the same as an explicit one.
      pumpWithTheme(
        tester,
        const IconTheme(
          data: IconThemeData(size: 20),
          child: Icon(LucideIcons.chevronDown),
        ),
      );

      expect(_strokeWidths(_renderedBody()), ['1.5']);
      expect(_single('svg').styles!.properties['width'], '1.25rem');
    });

    testComponents('the box is untouched by the rule — it rewrites the stroke '
        'only', (tester) async {
      pumpWithTheme(
        tester,
        const Icon(LucideIcons.chevronDown, iconStyle: CoreIconStyle(size: 32)),
      );

      final styles = _single('svg').styles!.properties;
      expect(styles['width'], '2.0rem');
      expect(styles['height'], '2.0rem');
      expect(_single('svg').attributes?['viewBox'], '0 0 24 24');
      expect(_strokeWidths(_renderedBody()), ['1.5']);
    });

    testComponents('a surface preset that raises the border scale does not '
        'thicken the glyph', (tester) async {
      // The premise: neo-brutalism really does raise `--coui-stroke-width-*`
      // (borders go to 3 px). If the preset stopped doing that this test
      // would pass for the wrong reason.
      final blocks = ThemeConfig.defaults().surfaceStyleVariableBlocks;
      final neo = RegExp(
        r'\[data-coui-style="neoBrutalism"\]\{([^}]*)\}',
      ).allMatches(blocks).map((m) => m[1]!).join();
      expect(neo, contains('--coui-stroke-width-'));

      const icon = Icon(
        LucideIcons.chevronDown,
        iconStyle: CoreIconStyle(size: 16),
      );

      pumpWithTheme(tester, icon);
      final plain = _single('svg');
      final plainBody = _bodyOf(plain);
      final plainAttributes = Map.of(plain.attributes!);
      final plainStyles = Map.of(plain.styles!.properties);
      final plainClasses = plain.classes;

      pumpWithTheme(
        tester,
        const SurfaceStyleScope(
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          child: icon,
        ),
      );
      final neoSvg = _single('svg');

      expect(_bodyOf(neoSvg), plainBody);
      expect(neoSvg.attributes, plainAttributes);
      expect(neoSvg.styles!.properties, plainStyles);
      expect(neoSvg.classes, plainClasses);
      // And the number is the rule's literal, not a reference a preset could
      // move: no variable anywhere in the glyph's markup.
      expect(_strokeWidths(plainBody), ['1.875']);
      expect(plainBody, isNot(contains('var(')));
      expect(plainBody, isNot(contains('--coui-stroke-width')));
      expect(plainAttributes.values.join(), isNot(contains('--coui-stroke')));
    });
  });

  group('the rule is applied by the resolver, not the widget', () {
    // `resolveIconStyle` hands the widget the finished glyph: the stroke is
    // already rewritten when `Icon.build` reads it, so the widget lays markup
    // out and transforms nothing.
    for (final c in cases) {
      final tokenSize = (c['tokenSize']! as num).toDouble();
      final svgString = c['svgString']! as String;

      testComponents('size $tokenSize resolves stroke-width="$svgString"', (
        tester,
      ) async {
        late ({
          double size,
          CoreColor? color,
          IconSvgData? bundled,
          Map<String, String> strokeAttributes,
        })
        resolved;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              resolved = resolveIconStyle(
                context,
                icon: LucideIcons.chevronDown,
                widgetStyle: CoreIconStyle(size: tokenSize),
              );

              return const Text('probe');
            },
          ),
        );

        final authored = CoreBundledIcons.icons[LucideIcons.chevronDown.id]!;
        final bundled = resolved.bundled!;
        expect(resolved.size, tokenSize);
        expect(_strokeWidths(bundled.body), [svgString]);
        expect(
          bundled.body,
          authored.body.replaceAll(
            'stroke-width="2"',
            'stroke-width="$svgString"',
          ),
        );
        expect(bundled.width, authored.width);
        expect(bundled.height, authored.height);
      });
    }

    testComponents('an icon outside the bundle resolves no glyph', (
      tester,
    ) async {
      late ({
        double size,
        CoreColor? color,
        IconSvgData? bundled,
        Map<String, String> strokeAttributes,
      })
      resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveIconStyle(
              context,
              icon: const IconName('lucide', 'a-arrow-down'),
              widgetStyle: const CoreIconStyle(size: 16),
            );

            return const Text('probe');
          },
        ),
      );

      expect(resolved.bundled, isNull);
      expect(resolved.size, 16);
    });
  });

  group('outside the bundle the Web path retains Iconify', () {
    testComponents('a zero-size icon keeps its box without a stroke ratio', (
      tester,
    ) async {
      const unbundled = IconName('lucide', 'a-arrow-down');
      expect(CoreBundledIcons.icons, isNot(contains(unbundled.id)));
      pumpWithTheme(
        tester,
        const Icon(unbundled, iconStyle: CoreIconStyle(size: 0)),
      );

      expect(_single('iconify-icon').styles!.properties['width'], '0.0rem');
      expect(_single('coui-iconify-stroke').attributes, {'prefix': 'lucide'});
    });

    testComponents('a Lucide icon outside the bundle carries its Core stroke '
        'ratio into the per-instance adapter', (tester) async {
      const outside = IconName('lucide', 'a-arrow-down');
      expect(CoreBundledIcons.icons, isNot(contains(outside.id)));

      pumpWithTheme(
        tester,
        const Icon(outside, iconStyle: CoreIconStyle(size: 16)),
      );

      expect(find.tag('svg'), findsNothing);
      final element = _single('iconify-icon');
      // Keep Iconify's source name, box and public customizations. The
      // companion receives the Core ratio without restating its policy.
      expect(element.attributes, {
        'icon': 'lucide:a-arrow-down',
        'width': '1em',
        'height': '1em',
      });
      expect(element.styles!.properties, {
        'width': '1.0rem',
        'height': '1.0rem',
        'font-size': '1.0rem',
      });
      final companion = _single('coui-iconify-stroke');
      expect(companion.attributes, {
        'prefix': 'lucide',
        'ratio': CoreIconStroke.svgStrokeWidth(16, viewBox: 1).toString(),
      });
      expect(companion.children, isEmpty);
    });

    testComponents('a non-Lucide icon is the bare <iconify-icon>', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const div([
          Icon(RadixIcons.accessibility, iconStyle: CoreIconStyle(size: 16)),
          Icon(BootstrapIcons.house, iconStyle: CoreIconStyle(size: 16)),
          Icon(IconName('mdi', 'home'), iconStyle: CoreIconStyle(size: 16)),
        ]),
      );

      expect(find.tag('svg'), findsNothing);
      final elements = find
          .tag('iconify-icon')
          .evaluate()
          .map((e) => e.component as DomComponent)
          .toList();
      expect(elements, hasLength(3));
      for (final element in elements) {
        expect(element.attributes!.keys, ['icon', 'width', 'height']);
        expect(element.attributes!['width'], '1em');
        expect(element.attributes!['height'], '1em');
        expect(element.styles!.properties.keys, [
          'width',
          'height',
          'font-size',
        ]);
      }
    });
  });
}
