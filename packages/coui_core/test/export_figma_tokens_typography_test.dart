// `Semantic/ Typography` and the canvas text styles — the type scale as the
// Figma library carries it.
//
// The rows and styles are written from three lists in the exporter (font
// sizes per mode, groups, roles), so a role can go missing from one of them
// while the other two carry it — a variable with no style, or a style that
// binds a variable nobody made. Neither shows on the canvas until a designer
// looks for the role. The expectations here are read from
// `CoreTypography.coui`, the seat both platforms draw from, and some are also
// written out as numbers — the per-mode sizes and tracking in the tier
// vectors the platforms share — a second source that fails if the scale and
// the export drift together.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` relative to its working directory).
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, dynamic> typography;
  late Map<String, dynamic> primitives;
  late List<Map<String, dynamic>> textStyles;
  late Set<String> names;

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_typography_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final result = Process.runSync(Platform.resolvedExecutable, [
      'run',
      script,
    ], workingDirectory: tmp.path);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final doc =
        jsonDecode(
              File('${tmp.path}/build/tokens.figma.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final collections = (doc['collections'] as List)
        .cast<Map<String, dynamic>>();
    typography = collections.singleWhere(
      (c) => c['name'] == 'Semantic/ Typography',
    );
    primitives = collections.singleWhere((c) => c['name'] == 'Primitives');
    textStyles = (doc['textStyles'] as List).cast<Map<String, dynamic>>();
    names = {
      for (final c in collections)
        for (final v in (c['variables'] as List).cast<Map<String, dynamic>>())
          '${c['name']}/${v['name']}',
    };
  });

  List<Map<String, dynamic>> rowsOf(Map<String, dynamic> collection) =>
      (collection['variables'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> rowOf(Map<String, dynamic> collection, String name) =>
      rowsOf(collection).singleWhere((v) => v['name'] == name);

  Map<String, dynamic> valuesOf(String name) =>
      rowOf(typography, name)['valuesByMode'] as Map<String, dynamic>;

  Map<String, dynamic> styleNamed(String name) =>
      textStyles.singleWhere((s) => s['name'] == name);

  /// Every role's tracking per mode, Mobile · Tablet · Desktop.
  List<double> trackingOf(String role) => [
    for (final mode in const ['Mobile', 'Tablet', 'Desktop'])
      (valuesOf('letter-spacing/$role')[mode] as num).toDouble(),
  ];

  const modes = ['Mobile', 'Tablet', 'Desktop'];
  const box = 'Semantic/ Typography/line-height/code';

  group('Semantic/ Typography', () {
    test('three breakpoint modes, Desktop last', () {
      expect(typography['modes'], modes);
    });

    test('77 rows: 22 roles, 6 groups, a size tier of 21', () {
      final rows = [for (final v in rowsOf(typography)) v['name'] as String];
      int count(bool Function(String) where) => rows.where(where).length;

      expect(rows, hasLength(77));
      expect(count((n) => n.startsWith('font-size/')), 22);
      expect(count((n) => n.startsWith('line-height/')), 6);
      expect(count((n) => n.startsWith('font-weight/')), 6);
      expect(count((n) => n.startsWith('letter-spacing/size-')), 21);
      expect(
        count(
          (n) =>
              n.startsWith('letter-spacing/') &&
              !n.startsWith('letter-spacing/size-'),
        ),
        22,
      );
    });

    test('every role has a size row and a tracking row', () {
      for (final token in CoreTextStyles.values) {
        expect(
          names,
          containsAll([
            'Semantic/ Typography/font-size/${token.name}',
            'Semantic/ Typography/letter-spacing/${token.name}',
          ]),
          reason: token.name,
        );
      }
    });

    test('every alias names a variable the export has', () {
      for (final v in rowsOf(typography)) {
        for (final value in (v['valuesByMode'] as Map).values) {
          // A raw FLOAT (tracking px, the code box) aliases nothing.
          if (value is! Map) continue;
          expect(names, contains(value['alias']), reason: '${v['name']}');
        }
      }
    });

    test('Desktop draws each role at the size the code role states', () {
      for (final token in CoreTextStyles.values) {
        final size = token.read(CoreTypography.coui).fontSize!;
        final desktop = valuesOf('font-size/${token.name}')['Desktop'] as Map;
        expect(
          desktop['alias'],
          'Primitives/font/size/${size.toInt()}',
          reason: token.name,
        );
      }
    });

    test('the new roles are flat across the modes', () {
      for (final (role, size) in const [
        ('body-xs', 12),
        ('label-xs', 11),
        ('code-xs', 11),
        ('code-sm', 12),
        ('code-md', 13),
      ]) {
        for (final mode in modes) {
          expect(
            (valuesOf('font-size/$role')[mode] as Map)['alias'],
            'Primitives/font/size/$size',
            reason: '$role $mode',
          );
        }
      }
      expect(
        [
          for (final mode in modes)
            (valuesOf('font-size/headline-small')[mode] as Map)['alias'],
        ],
        [
          'Primitives/font/size/16',
          'Primitives/font/size/20',
          'Primitives/font/size/24',
        ],
      );
    });

    // The code box is px, not a multiplier — the one line-height a text style
    // binds, so it is written raw rather than aliased to a ladder it is not on.
    test('line-height/code is a raw 21 in every mode', () {
      expect(valuesOf('line-height/code'), {
        for (final mode in modes) mode: CoreLineBox.px21,
      });
      expect(valuesOf('line-height/code')['Desktop'], 21);
    });

    test('the other groups alias their multiplier', () {
      for (final (group, leaf) in const [
        ('display', '140'),
        ('headline', '140'),
        ('title', '140'),
        ('body', '150'),
        ('label', '140'),
      ]) {
        for (final mode in modes) {
          expect(
            (valuesOf('line-height/$group')[mode] as Map)['alias'],
            'Primitives/line-height/$leaf',
            reason: '$group $mode',
          );
        }
      }
    });

    test('one weight per group, code regular', () {
      for (final (group, leaf) in const [
        ('display', 'bold'),
        ('headline', 'bold'),
        ('title', 'semibold'),
        ('body', 'regular'),
        ('label', 'medium'),
        ('code', 'regular'),
      ]) {
        expect(
          (valuesOf('font-weight/$group')['Desktop'] as Map)['alias'],
          'Primitives/font/weight/$leaf',
          reason: group,
        );
      }
    });

    // Desktop IS the code value, so each role's Desktop tracking is the
    // tracking it states times its size — read from the scale, not restated.
    test('Desktop tracking is each role’s own em × its size', () {
      for (final token in CoreTextStyles.values) {
        final role = token.read(CoreTypography.coui);
        expect(
          trackingOf(token.name).last,
          closeTo(role.letterSpacing! * role.fontSize!, 1e-9),
          reason: token.name,
        );
      }
    });

    test('tracking follows the two steps per mode, mono stays 0', () {
      final expected = <String, List<double>>{
        'display-large': [-0.72, -0.88, -1.04],
        // 16px on Mobile is below 20, so it takes the smaller step there.
        'headline-small': [-0.16, -0.4, -0.48],
        'title-large': [-0.4, -0.4, -0.4],
        'title-medium': [-0.18, -0.18, -0.18],
        'body-small': [-0.13, -0.13, -0.13],
        'label-xs': [-0.11, -0.11, -0.11],
        'code-xs': [0, 0, 0],
        'code-sm': [0, 0, 0],
        'code-md': [0, 0, 0],
      };
      for (final MapEntry(key: role, value: px) in expected.entries) {
        final actual = trackingOf(role);
        for (var i = 0; i < modes.length; i++) {
          expect(actual[i], closeTo(px[i], 1e-9), reason: '$role ${modes[i]}');
        }
      }
    });

    // The same hand-written numbers the Core tier and both platforms are held
    // to: the canvas modes are the tiers the code draws at those widths.
    test('each mode is the tier the shared vectors state', () {
      final vectors =
          jsonDecode(
                File(
                  'test/fixtures/typography_tier_vectors.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final rows = (vectors['roles'] as List).cast<Map<String, dynamic>>();
      expect(rows, isNotEmpty);
      for (final row in rows) {
        final role = row['role'] as String;
        for (final (mode, tier) in const [
          ('Mobile', 'mobile'),
          ('Tablet', 'tablet'),
          ('Desktop', 'desktop'),
        ]) {
          final want = row[tier] as Map<String, dynamic>;
          final size = (want['size'] as num).toDouble();
          final em = (want['trackingEm'] as num).toDouble();
          expect(
            (valuesOf('font-size/$role')[mode] as Map)['alias'],
            'Primitives/font/size/${size.toInt()}',
            reason: '$role $mode',
          );
          expect(
            valuesOf('letter-spacing/$role')[mode],
            closeTo(em * size, 1e-9),
            reason: '$role $mode',
          );
        }
      }
    });

    test('the size tier tracks by the same two steps', () {
      for (final (size, px) in const [
        (10, -0.1),
        (11, -0.11),
        (13, -0.13),
        (15, -0.15),
        (18, -0.18),
        (20, -0.4),
        (28, -0.56),
      ]) {
        for (final mode in modes) {
          expect(
            valuesOf('letter-spacing/size-$size')[mode],
            closeTo(px, 1e-9),
            reason: 'size-$size $mode',
          );
        }
      }
    });
  });

  group('text styles', () {
    test('one per role, in scale order, under these 22 names', () {
      expect(
        [for (final s in textStyles) s['name']],
        [
          'Display/Large',
          'Display/Medium',
          'Display/Small',
          'Headline/Large',
          'Headline/Medium',
          'Headline/Small',
          'Title/Large',
          'Title/Medium',
          'Title/Small',
          'Body/Large',
          'Body/Medium',
          'Body/Small',
          'Body/XS',
          'Label/XL2',
          'Label/XL',
          'Label/Large',
          'Label/Medium',
          'Label/Small',
          'Label/XS',
          'Code/XS',
          'Code/SM',
          'Code/MD',
        ],
      );
      expect(
        [for (final s in textStyles) s['role']],
        [
          for (final t in CoreTextStyles.values) t.name,
        ],
      );
    });

    test('every variable a style binds is one the export makes', () {
      for (final style in textStyles) {
        for (final field in const [
          'fontFamily',
          'fontSize',
          'fontWeight',
          'letterSpacing',
          'lineHeightPx',
        ]) {
          final binding = style[field];
          if (binding == null) continue;
          expect(
            names,
            contains((binding as Map)['variable']),
            reason: '${style['name']} $field',
          );
        }
      }
    });

    test('a code style binds the 21px box and states no percent', () {
      for (final name in const ['Code/XS', 'Code/SM', 'Code/MD']) {
        final style = styleNamed(name);
        expect(style['lineHeightPx'], {'variable': box, 'value': 21.0});
        expect(style.containsKey('lineHeightPercent'), isFalse, reason: name);
        expect(style['fontFamily'], {
          'variable': 'Primitives/font/family/Geist Mono',
          'value': CoreFontFamily.mono,
        });
        expect(
          (style['fontWeight'] as Map)['variable'],
          'Semantic/ Typography/font-weight/code',
        );
        expect((style['letterSpacing'] as Map)['value'], 0);
      }
      expect((styleNamed('Code/SM')['fontSize'] as Map)['value'], 12.0);
    });

    test('every other style states its percent and binds no box', () {
      for (final token in CoreTextStyles.values) {
        final role = token.read(CoreTypography.coui);
        if (role.lineHeightPx != null) continue;
        final style = textStyles.singleWhere((s) => s['role'] == token.name);
        expect(style.containsKey('lineHeightPx'), isFalse, reason: token.name);
        expect(
          style['lineHeightPercent'],
          (role.lineHeight! * 100).round(),
          reason: token.name,
        );
        expect(
          (style['fontFamily'] as Map)['value'],
          CoreFontFamily.sans,
          reason: token.name,
        );
      }
    });

    test('values written out', () {
      final body = styleNamed('Body/Medium');
      expect(body['lineHeightPercent'], 150);
      expect((body['fontSize'] as Map)['value'], 14.0);
      expect((body['letterSpacing'] as Map)['value'], closeTo(-0.14, 1e-9));

      final labelXs = styleNamed('Label/XS');
      expect(labelXs['lineHeightPercent'], 140);
      expect(
        (labelXs['letterSpacing'] as Map)['value'],
        closeTo(-0.11, 1e-9),
      );

      final title = styleNamed('Title/Large');
      expect(title['lineHeightPercent'], 140);
      expect((title['letterSpacing'] as Map)['value'], closeTo(-0.4, 1e-9));

      expect((styleNamed('Headline/Large')['fontWeight'] as Map)['value'], 700);
    });
  });

  group('Primitives', () {
    List<String> leavesUnder(String prefix) => [
      for (final v in rowsOf(primitives))
        if ((v['name'] as String).startsWith(prefix))
          (v['name'] as String).substring(prefix.length),
    ];

    test('font/size carries 21 steps, 11 · 13 · 15 among them', () {
      final leaves = leavesUnder('font/size/');
      expect(leaves, hasLength(21));
      expect(leaves, containsAll(['11', '13', '15']));
    });

    test('line-height carries 7 multipliers, 150 among them', () {
      expect(leavesUnder('line-height/'), hasLength(7));
      expect(rowOf(primitives, 'line-height/150')['valuesByMode'], {
        'Value': CoreLineHeight.h150,
      });
    });

    test('the two families the roles name, and no other', () {
      expect(leavesUnder('font/family/'), [
        CoreFontFamily.sans,
        CoreFontFamily.mono,
      ]);
      expect(leavesUnder('font/family/'), ['Pretendard', 'Geist Mono']);
    });

    // The Dart export reads a weight's type from this scope: a primitive
    // no role aliases (thin, black) has nothing else to say it is a weight,
    // and would come back as `double` beside the `int` ones.
    test('every font weight is scoped as one, aliased or not', () {
      final weights = [
        for (final v in rowsOf(primitives))
          if ((v['name'] as String).startsWith('font/weight/')) v,
      ];
      expect(weights, hasLength(9));
      for (final v in weights) {
        expect(v['scopes'], ['FONT_WEIGHT'], reason: '${v['name']}');
      }
      expect(rowOf(typography, 'font-weight/label')['scopes'], [
        'FONT_WEIGHT',
      ]);
    });
  });
}
