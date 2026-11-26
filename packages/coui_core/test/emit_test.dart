import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:analyzer/dart/ast/ast.dart' show TopLevelVariableDeclaration;
import 'package:test/test.dart';

import '../bin/figma_reader/ast_value.dart';
import '../bin/figma_reader/emit.dart';
import '../bin/figma_reader/repo_reader.dart';
import '../bin/figma_reader/schema_v2.dart';
import '../bin/figma_reader/style_reader.dart';
import '../bin/figma_reader/token_scale.dart';

void main() {
  group('jsonKeyFor / normalizeVariantName — divergence #1 / #2', () {
    test('strips default prefix, lowercases next letter', () {
      expect(jsonKeyFor('defaultBackgroundColor'), 'backgroundColor');
      expect(jsonKeyFor('defaultBorderRadius'), 'borderRadius');
    });

    test('a name with no default prefix passes through verbatim', () {
      expect(jsonKeyFor('background'), 'background');
      expect(jsonKeyFor('borderColor'), 'borderColor');
    });

    test('defaultVariant / default_ normalize to "default"', () {
      expect(normalizeVariantName('defaultVariant'), 'default');
      expect(normalizeVariantName('default_'), 'default');
      expect(normalizeVariantName('outlined'), 'outlined');
    });
  });

  group('emit* — against real coui_core Style/namespace sources', () {
    late EmitContext ctx;
    late Map<String, DiscoveredClass> classes;

    setUpAll(() {
      final repo = readContracts(
        repoRoot: '.',
        contractsRoot: 'lib/src/component/contracts',
      );
      final tokens = resolveNamespaces(repoRoot: '.', srcRoot: 'lib/src');
      classes = repo.classesByName;
      ctx = EmitContext(tokenScale: tokens, classRegistry: classes);
    });

    AstValue staticValueOf(String className, String memberName) {
      final cls = classes[className]!;
      return cls.staticMembers.firstWhere((m) => m.name == memberName).value;
    }

    // Anchors are `CoreAlignment` consts and radius roles are `CoreRadiusRole`
    // consts — both live outside `contracts/`. The exporter hands the emitters
    // the widened registry, so the tests that read them do too.
    EmitContext exporterContext({
      int? Function(String semanticName)? resolveSemanticColor,
    }) {
      final repo = readContracts(
        repoRoot: '.',
        contractsRoot: 'lib/src/component/contracts',
        referenceRoot: 'lib/src',
      );
      return EmitContext(
        tokenScale: ctx.tokenScale,
        classRegistry: repo.resolutionRegistry,
        resolveSemanticColor: resolveSemanticColor,
      );
    }

    test(
      'emitDim resolves a token reference with ref/via (Dim leaf shape)',
      () {
        final value = staticValueOf(
          'CoreDialogStyle',
          'defaultPanelBorderWidth',
        );
        final leaf = emitDim(ctx, value, currentClass: 'CoreDialogStyle')!;
        expect(leaf['v'], 1.0);
        expect(leaf['ref'], 'Primitives/stroke/1');
      },
    );

    test(
      'emitRadius always emits all four corners (divergence #3), uniform',
      () {
        final value = staticValueOf('CoreFieldsetStyle', 'defaultBorderRadius');
        // `defaultBorderRadius` is a `CoreRadiusRole` — outside `contracts/`.
        final leaf = emitRadius(
          exporterContext(),
          value,
          currentClass: 'CoreFieldsetStyle',
        )!;
        expect(leaf.keys.toSet(), {
          'topLeft',
          'topRight',
          'bottomLeft',
          'bottomRight',
        });
        // A uniform radius resolves to the same value on every corner.
        final tl = leaf['topLeft'] as Map;
        for (final key in leaf.keys) {
          expect((leaf[key] as Map)['v'], tl['v']);
        }
      },
    );

    test(
      'emitInsets picks the physical shape ({l,t,r,b}) for CoreEdgeInsets.only',
      () {
        final value = staticValueOf('CoreDialogStyle', 'defaultPanelPadding');
        final leaf = emitInsets(ctx, value, currentClass: 'CoreDialogStyle')!;
        expect(leaf.keys.toSet(), {'l', 't', 'r', 'b'});
        expect((leaf['l'] as Map)['v'], (leaf['t'] as Map)['v']);
        expect((leaf['l'] as Map)['v'], (leaf['r'] as Map)['v']);
        expect((leaf['b'] as Map)['v'], 20.0);
      },
    );

    test(
      'emitText keeps role and every overlay field present, not just '
      'fontSize/fontWeight (divergence #5)',
      () {
        final value = staticValueOf('CoreDialogStyle', 'defaultTitleStyle');
        final leaf = emitText(ctx, value, currentClass: 'CoreDialogStyle')!;
        expect(leaf['role'], 'titleLarge');
        expect(leaf['color'], isA<Map<String, dynamic>>());
        // fontSize/fontWeight are absent from this particular source value
        // (a bare role+color token) — the point is the *keys that are
        // present* are read from the actual named args, not a fixed
        // fontSize/fontWeight allowlist.
        expect(leaf.containsKey('fontSize'), isFalse);
      },
    );

    test(
      'emitColor is a fixed four-key shape, never a union (divergence #10)',
      () {
        final value = staticValueOf('CoreDialogStyle', 'defaultTitleStyle');
        final textLeaf = emitText(
          ctx,
          value,
          currentClass: 'CoreDialogStyle',
        )!;
        final color = textLeaf['color'] as Map;
        expect(color.keys.toSet(), {'ref', 'argb', 'opacity', 'fallbacks'});
      },
    );

    test('emitColor resolves fallbacks from a CoreColor.token(...) call', () {
      // CoreCardStyle.defaultsByVariant['outlined'].backgroundColor has a
      // fallbacks: [...] arg in the real source.
      final dispatch =
          staticValueOf('CoreCardStyle', 'defaultsByVariant') as MapValue;
      final outlined =
          dispatch.entries
                  .firstWhere((e) => (e.key as RefValue).member == 'outlined')
                  .value
              as CallValue;
      final leaf = emitColor(
        ctx,
        outlined.namedArgs['backgroundColor']!,
        currentClass: 'CoreCardStyle',
      )!;
      expect(leaf['fallbacks'], isNotEmpty);
    });

    test(
      'emitColor resolves the CoreColor.transparent dot-shorthand sentinel',
      () {
        final dispatch =
            staticValueOf('CoreCardStyle', 'defaultsByVariant') as MapValue;
        final filled =
            dispatch.entries
                    .firstWhere((e) => (e.key as RefValue).member == 'filled')
                    .value
                as CallValue;
        final leaf = emitColor(
          ctx,
          filled.namedArgs['borderColor']!,
          currentClass: 'CoreCardStyle',
        )!;
        expect(leaf['argb'], 0);
        expect(leaf['ref'], isNull);
      },
    );

    test('emitGap resolves CoreGapStyle(size: ...) to a Dim-wrapped leaf', () {
      final value = staticValueOf('CoreDialogStyle', 'defaultSectionGapStyle');
      final leaf = emitGap(ctx, value, currentClass: 'CoreDialogStyle')!;
      expect((leaf['size'] as Map)['v'], isA<double>());
    });

    EmitContext gradientContext({
      int? Function(String semanticName)? resolveSemanticColor,
    }) => exporterContext(resolveSemanticColor: resolveSemanticColor);

    test('emitGradient reads a linear gradient: colours, stops, anchors', () {
      final value = staticValueOf(
        'CoreMockupDeviceStyle',
        'defaultRailGradient',
      );
      final leaf = emitGradient(
        gradientContext(),
        value,
        currentClass: 'CoreMockupDeviceStyle',
      )!;
      expect(leaf['type'], 'linear');
      expect(leaf['stops'], [0.0, 0.1, 0.9, 1.0]);
      final colors = leaf['colors'] as List;
      expect(colors, hasLength(4));
      // Each stop is the fixed four-key colour leaf; a literal stop carries
      // its raw ARGB and no reference.
      expect(colors.first, {
        'ref': null,
        'argb': 0xFFC3C4C6,
        'opacity': 1.0,
        'fallbacks': <String>[],
      });
      expect((colors[1] as Map)['ref'], isNull);
      expect((colors[1] as Map)['argb'], 0xFF7D7F82);
      expect((colors[2] as Map)['argb'], 0xFF7D7F82);
      expect((colors.last as Map)['argb'], 0xFFAEAFB2);
      // Anchors are numbers read off `CoreAlignment`'s own consts.
      expect(leaf['begin'], {'x': 0.0, 'y': -1.0});
      expect(leaf['end'], {'x': 0.0, 'y': 1.0});
    });

    // A gradient whose stops stand on semantic slots. No contract default
    // states one, so it is written here as source the way a contract would
    // and read through the same reader.
    AstValue tokenStopGradient() {
      final unit = parseString(
        content:
            'const g = CoreGradient( '
            'type: CoreGradientType.linear, '
            'colors: [CoreColor.token(CoreColors.primaryFixedDim), '
            'CoreColor.token(CoreColors.onPrimaryFixedVariant), '
            'CoreColor.token(CoreColors.primaryFixedDim)], '
            'stops: [0, 0.5, 1], '
            'begin: CoreAlignment.topCenter, '
            'end: CoreAlignment.bottomCenter);',
      ).unit;
      final declaration =
          unit.declarations.single as TopLevelVariableDeclaration;
      return readValue(declaration.variables.variables.single.initializer!);
    }

    test('emitGradient binds a slot stop and resolves its ARGB', () {
      final leaf = emitGradient(
        gradientContext(
          resolveSemanticColor: (name) => switch (name) {
            'primaryFixedDim' => 0xFFC3C4C6,
            'onPrimaryFixedVariant' => 0xFF4D4E51,
            _ => null,
          },
        ),
        tokenStopGradient(),
        currentClass: 'CoreMockupDeviceStyle',
      )!;
      final colors = leaf['colors'] as List;
      expect(colors, hasLength(3));
      // Each stop is the fixed four-key colour leaf, a slot reference with
      // its resolved ARGB.
      expect(colors.first, {
        'ref': 'Semantic/color/primary-fixed-dim',
        'argb': 0xFFC3C4C6,
        'opacity': 1.0,
        'fallbacks': <String>[],
      });
      expect(
        (colors[1] as Map)['ref'],
        'Semantic/color/on-primary-fixed-variant',
      );
      expect((colors[1] as Map)['argb'], 0xFF4D4E51);
      expect(colors.last, colors.first);
    });

    test('emitGradient leaves a slot stop unresolved without a resolver', () {
      final leaf = emitGradient(
        gradientContext(),
        tokenStopGradient(),
        currentClass: 'CoreMockupDeviceStyle',
      )!;
      final first = (leaf['colors'] as List).first as Map;
      expect(first['ref'], 'Semantic/color/primary-fixed-dim');
      expect(first['argb'], 0);
    });

    test('emitGradient reads a literal stop as raw ARGB with no ref', () {
      final value = staticValueOf(
        'CoreMockupDeviceStyle',
        'defaultRimGlowGradient',
      );
      final leaf = emitGradient(
        gradientContext(),
        value,
        currentClass: 'CoreMockupDeviceStyle',
      )!;
      final colors = (leaf['colors'] as List).cast<Map<String, dynamic>>();
      expect(colors.map((c) => c['ref']), [null, null]);
      expect(colors.map((c) => c['argb']), [0xFFFFFFFF, 0x00FFFFFF]);
    });

    test('emitGradient states no anchors for a radial gradient', () {
      final value = staticValueOf(
        'CoreMockupDeviceStyle',
        'defaultCoreGradient',
      );
      final leaf = emitGradient(
        gradientContext(),
        value,
        currentClass: 'CoreMockupDeviceStyle',
      )!;
      expect(leaf['type'], 'radial');
      expect(leaf.containsKey('begin'), isFalse);
      expect(leaf.containsKey('end'), isFalse);
      expect(leaf['stops'], [0.2, 0.35, 0.5, 0.62, 0.8, 1.0]);
      final colors = (leaf['colors'] as List).cast<Map<String, dynamic>>();
      expect(colors.map((c) => c['ref']), List.filled(6, null));
      expect(colors.map((c) => c['argb']), [
        0xFF000000,
        0xFF0A3348,
        0xFF0C3B52,
        0xFF105171,
        0xFF0C3B52,
        0xFF000000,
      ]);
    });

    test(
      'emitGlyph reads a glyph forwarded from another class, path whole',
      () {
        // The Style's const names the drawing in `CoreMockupStatusBarGlyphs`,
        // whose outline is written as adjacent string literals: the leaf has to
        // be the one concatenated path, box and fill rule included.
        final value = staticValueOf('CoreMockupDeviceStyle', 'phoneWifiGlyph');
        final leaf = emitGlyph(
          gradientContext(),
          value,
          currentClass: 'CoreMockupDeviceStyle',
        )!;
        expect(leaf.keys.toSet(), {'path', 'width', 'height', 'fillRule'});
        expect(leaf['width'], 17.1417);
        expect(leaf['height'], 12.3283);
        expect(leaf['fillRule'], 'evenOdd');
        final path = leaf['path'] as String;
        expect(path, startsWith('M 8.5713 2.4663 C '));
        expect(path, endsWith('Z'));
        // One string, not the pieces it was written in: no quote survives.
        expect(path.contains("'"), isFalse);
        expect(path.contains('  '), isFalse);
      },
    );

    test('emitGlyph keeps the fill rule the drawing states', () {
      final value = staticValueOf(
        'CoreMockupDeviceStyle',
        'phoneBatteryCapGlyph',
      );
      final leaf = emitGlyph(
        gradientContext(),
        value,
        currentClass: 'CoreMockupDeviceStyle',
      )!;
      expect(leaf['fillRule'], 'nonZero');
      expect(leaf['width'], 1.328);
      expect(leaf['height'], 4.0755);
    });

    test('a vector glyph routes to its own kind, not to a choice', () {
      expect(fieldKindOf('CoreVectorGlyph'), FieldKind.glyph);
      expect(fieldKindOf('CoreVectorGlyph?'), FieldKind.glyph);
    });
  });
}
