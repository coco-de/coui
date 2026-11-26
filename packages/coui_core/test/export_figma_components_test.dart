// Golden test — mirrors `tool/test/generate_style_tables_test.dart`'s
// established shape (regenerate in memory, byte-compare against the
// committed artifact). Catches both non-determinism (two builds disagree
// with each other) and staleness (a `CoreXxxStyle` changed but nobody
// re-ran the exporter and committed the new `components.json`).
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import '../bin/export_figma_components.dart';
import '../bin/figma_reader/emit.dart';
import '../bin/figma_reader/schema_v2.dart';
import '../bin/figma_reader/style_reader.dart';
import '../bin/figma_reader/typography_modes.dart';

// `dart test`'s working directory for this package is
// `packages/coui_core/` itself, not the workspace root
// `buildExportedDoc`'s default paths assume — so every call in this file
// overrides `contractsRoot`/`srcRoot`/`figmaLibraryPath` to match. Without
// the `figmaLibraryPath` override, `_canonicalLibrary` would look for
// `./docs_core/...` (relative to this package) instead of the workspace
// root, silently fall back to the all-null placeholder, and desync the
// golden comparison from the real `dart run` invocation's output.
/// The schema revision this test seals — bump together with the meta
/// marker in `schema_v2.dart`.
const _kSchemaRevision = 3;

BuildResult _build() => buildExportedDoc(
  repoRoot: '.',
  contractsRoot: 'lib/src/component/contracts',
  srcRoot: 'lib/src',
  figmaLibraryPath: '../../docs_core/content/_data/figma_library.json',
  componentsRoot: '../coui_flutter/lib/src/components',
  docsContentRoot: '../../docs_core/content/components',
  docsCatalogPath: '../../docs_core/lib/shared/component_catalog.dart',
  examplesRoot: '../../docs_core/lib/previews/examples',
);

void main() {
  test(
    'components.json is byte-identical to what the exporter regenerates '
    '(determinism + staleness combined)',
    () {
      final result = _build();
      final regenerated =
          '${const JsonEncoder.withIndent('  ').convert(result.doc)}\n';

      // Two levels below the workspace root the committed artifact's path
      // is relative to.
      final committedFile = File(
        '../../tools/figma-token-sync/src/data/components.json',
      );
      expect(
        committedFile.existsSync(),
        isTrue,
        reason:
            'components.json is missing — run `dart run '
            'bin/export_figma_components.dart` and commit the result.',
      );
      final committed = committedFile.readAsStringSync();

      expect(
        regenerated,
        committed,
        reason:
            'components.json is stale relative to the CoreXxxStyle '
            'sources it was generated from. Re-run '
            '`dart run bin/export_figma_components.dart` from the repo '
            'root and commit the result.',
      );
    },
  );

  test(
    'dynamic identity defaults are recorded as relationships, not absence',
    () {
      Map<String, dynamic> read(String expression) {
        final classes = readCompilationUnit('test.dart', '''
        class CoreFooStyle implements CoreStyle<CoreFooStyle> {
          final double? dotSize;
          final double? activeLength;
          static double defaultActiveLength(double dotSize) => $expression;
        }
      ''')!;
        final registry = {for (final c in classes) c.name: c};
        final result = buildDoc(
          EmitContext(tokenScale: const {}, classRegistry: registry),
          registry,
        );
        return ((result.doc['components'] as Map)['foo'] as Map)
            .cast<String, dynamic>();
      }

      final identity = read('dotSize');
      expect(identity['derivedDefaults'], {'activeLength': 'dotSize'});
      expect(identity['absent'], isNot(contains('activeLength')));
      expect(identity['untokenized'], isEmpty);

      // Unknown operations and unrelated parameters are not guessed or called
      // absent. They remain a visible unresolved export until supported.
      for (final expression in ['dotSize * 2', 'other']) {
        final unknown = read(expression);
        expect(unknown['derivedDefaults'], isEmpty);
        expect(unknown['absent'], isNot(contains('activeLength')));
        expect(
          unknown['untokenized'],
          equals([
            {
              'field': 'activeLength',
              'type': 'double?',
              'reason': 'dynamic-default-unresolved',
            },
          ]),
        );
      }
    },
  );

  test('DotIndicator exports active length as derived from dot size', () {
    final component =
        (_build().doc['components'] as Map)['dot_indicator'] as Map;
    expect(component['derivedDefaults'], {'activeLength': 'dotSize'});
    expect(component['absent'], isNot(contains('activeLength')));
  });

  test('TextField exports the platform caret height as host-derived', () {
    final component = (_build().doc['components'] as Map)['text_field'] as Map;
    expect(component['hostDerived'], contains('cursorHeight'));
    expect(component['absent'], isNot(contains('cursorHeight')));
  });

  // The exporter drops a class-level `@Deprecated` MAIN Style — a retired
  // component exported would put a retired set on the canvas, every field
  // of it reported sent-but-unread. The reader's half (the flag is read off
  // the declaration) is covered in `figma_reader_test.dart`; this is the
  // other half, through the real entry point, so a `where` clause that
  // stops consulting the flag fails here and not in a `components.json`
  // diff a reviewer has to notice. Fixture, not the repo: the repo has no
  // such class today and the previous test lost its subject when the last
  // one retired. A bare `EmitContext` is enough — the fixtures state no
  // chrome, so nothing is resolved through it.
  test('a class-level @Deprecated MAIN Style is not exported (fixture)', () {
    final classes = readCompilationUnit('test.dart', '''
      @Deprecated('Use CoreBarStyle instead (since 0.1).')
      @immutable
      class CoreFooStyle implements CoreStyle<CoreFooStyle> {
        const CoreFooStyle();
      }
      @immutable
      class CoreBarStyle implements CoreStyle<CoreBarStyle> {
        const CoreBarStyle();
      }
    ''')!;
    const ctx = EmitContext(tokenScale: {}, classRegistry: {});
    final doc = buildDoc(ctx, {for (final c in classes) c.name: c}).doc;
    final exported = (doc['components'] as Map<String, dynamic>).keys.toList();
    expect(exported, ['bar']);
  });

  // A call's bare-identifier arguments are names in the class that WROTE the
  // call, not the one that pointed at it. `CoreReaderStyle` states its padding
  // by naming `CoreWriterStyle`'s const; the `all(step)` inside belongs to the
  // writer, so `step` is 7. Resolving it in the reader's scope finds the
  // reader's same-named 99 — a value Core never states, reached through a
  // decoy that exists only because two classes may legally share a member
  // name. No site in the tree has that decoy, so a `components.json` diff
  // would have shown nothing; this fixture is the only thing that fails when
  // the scope is dropped again.
  test('a leaf call resolves its arguments in the writing class (fixture)', () {
    final classes = readCompilationUnit('test.dart', '''
      @immutable
      class CoreWriterStyle implements CoreStyle<CoreWriterStyle> {
        const CoreWriterStyle({this.padding});
        final CoreEdgeInsets? padding;
        static const double step = 7;
        static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(step);
      }
      @immutable
      class CoreReaderStyle implements CoreStyle<CoreReaderStyle> {
        const CoreReaderStyle({this.padding});
        final CoreEdgeInsets? padding;
        static const double step = 99;
        static const CoreEdgeInsets defaultPadding =
            CoreWriterStyle.defaultPadding;
      }
    ''')!;
    final registry = {for (final c in classes) c.name: c};
    final doc = buildDoc(
      EmitContext(tokenScale: const {}, classRegistry: registry),
      registry,
    ).doc;
    final reader =
        (doc['components'] as Map<String, dynamic>)['reader']
            as Map<String, dynamic>;
    final padding = (reader['fields'] as Map<String, dynamic>)['padding'];

    // Shape-agnostic on purpose: which keys `CoreEdgeInsets.all` lands on is
    // the insets emitter's business, and pinning them here would make this
    // test fail for a reason it is not about.
    expect(padding.toString(), contains('7'));
    expect(
      padding.toString(),
      isNot(contains('99')),
      reason: "resolved in the reader's scope — the decoy, not Core's value",
    );
  });

  // An argument the reader cannot follow is refused, and a nested-Style slot
  // is refused the same way a leaf is. `defaultNope` names nothing; silence
  // here would hand `CoreMidStyle`'s own `defaultInnerStyle` (size 3) to the
  // canvas while the parent stated something else — the `CardImage` fault's
  // exact shape, through the one door a leaf-only refusal left open.
  test('an unresolvable nested-Style argument is refused (fixture)', () {
    final classes = readCompilationUnit('test.dart', '''
      @immutable
      class CoreParentStyle implements CoreStyle<CoreParentStyle> {
        const CoreParentStyle({this.midStyle});
        final CoreMidStyle? midStyle;
        static const CoreMidStyle defaultMidStyle =
            CoreMidStyle(innerStyle: defaultNope);
      }
      @immutable
      class CoreMidStyle implements CoreStyle<CoreMidStyle> {
        const CoreMidStyle({this.innerStyle});
        final CoreInnerStyle? innerStyle;
        static const CoreInnerStyle defaultInnerStyle = CoreInnerStyle(size: 3);
      }
      @immutable
      class CoreInnerStyle implements CoreStyle<CoreInnerStyle> {
        const CoreInnerStyle({this.size});
        final double? size;
        static const double defaultSize = 1;
      }
    ''')!;
    final registry = {for (final c in classes) c.name: c};
    expect(
      () => buildDoc(
        EmitContext(tokenScale: const {}, classRegistry: registry),
        registry,
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('defaultNope'), contains('CoreInnerStyle')),
        ),
      ),
    );
  });

  // …and that refusal must not swallow the cycle guard, which returns the same
  // null for a different reason. `inner` DOES name a constructor — only the
  // recursion is cut, because `CoreNodeStyle` is already on the stack. Telling
  // the two apart by "does this identifier name a constructor at all" is the
  // whole distinction, so a rewrite that refuses on null alone fails here.
  test('a nested-Style cycle is still silent, not refused (fixture)', () {
    final classes = readCompilationUnit('test.dart', '''
      @immutable
      class CoreNodeStyle implements CoreStyle<CoreNodeStyle> {
        const CoreNodeStyle({this.size, this.childStyle});
        final double? size;
        final CoreNodeStyle? childStyle;
        static const double defaultSize = 2;
        static const CoreNodeStyle inner = CoreNodeStyle(size: 5);
        static const CoreNodeStyle defaultChildStyle =
            CoreNodeStyle(childStyle: inner);
      }
    ''')!;
    final registry = {for (final c in classes) c.name: c};
    expect(
      () => buildDoc(
        EmitContext(tokenScale: const {}, classRegistry: registry),
        registry,
      ),
      returnsNormally,
    );
  });

  test('two consecutive in-memory builds are byte-identical', () {
    final first = _build();
    final second = _build();
    expect(
      const JsonEncoder.withIndent('  ').convert(second.doc),
      const JsonEncoder.withIndent('  ').convert(first.doc),
    );
    expect(second.untokenizedTotal, first.untokenizedTotal);
  });

  test('a shadow keeps the scale step its source names', () {
    // Read off the reference (`CoreShadow.md` is a name in the source), so the
    // canvas can bind the layers to the rows a surface style bends per mode.
    // `xl2` / `xl3` are spelled as the canvas spells the step.
    final components = _build().doc['components']! as Map<String, dynamic>;
    final container = components['outlined_container'] as Map<String, dynamic>;
    final constants = container['constants'] as Map<String, dynamic>;
    expect((constants['softShadow'] as Map)['step'], 'sm');
    expect((constants['mediumShadow'] as Map)['step'], 'md');
    expect((constants['strongShadow'] as Map)['step'], 'lg');

    // An empty stack names no step: `CoreShadow.none` is "flat", not a step.
    final card = components['card'] as Map<String, dynamic>;
    final boxShadow = (card['fields'] as Map)['boxShadow'] as Map;
    expect(boxShadow['layers'], isEmpty);
    expect(boxShadow.containsKey('step'), isFalse);
  });

  test('the glass table is the refracting style, in the panel numbers', () {
    // Written out, then read from the seat: the GLASS effect takes no
    // variable, so these dials reach the canvas only through this table.
    final glass = _build().doc['surfaceGlass']! as Map<String, Object>;
    expect(glass, {
      'style': 'liquidGlass',
      'refraction': 0.8,
      'depth': 27.0,
      'dispersion': 0.5,
      'lightAngle': -45.0,
      'lightIntensity': 0.8,
    });
    final recipe = CoreSurfaceRecipe.of(.liquidGlass);
    final bevel = recipe.surfaceFor(.functional)!.sheen!.bevel!;
    expect(glass['refraction'], recipe.refraction!.strength);
    expect(glass['depth'], closeTo(recipe.refraction!.bezel * 100, 1e-9));
    expect(glass['dispersion'], recipe.refraction!.dispersion);
    expect(glass['lightAngle'], bevel.lightAngle);
    expect(glass['lightIntensity'], bevel.lightIntensity);
    // Only the refracting style may state the dials — a second one would
    // need a second effect, and the export refuses rather than choosing.
    expect(
      [
        for (final id in CoreSurfaceStyleId.values)
          if (CoreSurfaceRecipe.of(id).refraction != null) id,
      ],
      [CoreSurfaceStyleId.liquidGlass],
    );
  });

  test('each role carries its size and tracking in every typography mode', () {
    // Read back where the plugin reads it: a consumer file draws in the
    // collection's first mode, where the display and headline roles are
    // smaller than the code scale, and the plugin's consumer-file check
    // compares a literal against these rows.
    final typography = _build().doc['typography']! as Map;
    expect((typography['headlineSmall']! as Map)['modes'], {
      'Mobile': {'fontSize': 16.0, 'letterSpacing': -0.01},
      'Tablet': {'fontSize': 20.0, 'letterSpacing': -0.02},
      'Desktop': {'fontSize': 24.0, 'letterSpacing': -0.02},
    });
    expect(
      ((typography['headlineLarge']! as Map)['modes']! as Map)['Mobile'],
      {'fontSize': 24.0, 'letterSpacing': -0.02},
    );
    for (final MapEntry(key: role, value: metrics as Map)
        in typography.entries) {
      final modes = metrics['modes']! as Map;
      expect(modes.keys, kTypographyModes, reason: role as String);
      // Desktop is the code scale, so its row is the role's own metrics —
      // the tokens export holds the same table to the same rule.
      final desktop = modes['Desktop']! as Map;
      expect(desktop['fontSize'], metrics['fontSize'], reason: role);
      expect(desktop['letterSpacing'], metrics['letterSpacing'], reason: role);
    }
  });

  test('meta carries no timestamp (would break determinism)', () {
    final result = _build();
    final meta = result.doc['meta'] as Map;
    expect(meta.keys, isNot(contains('timestamp')));
    expect(meta.keys, isNot(contains('generatedAt')));
  });

  test(
    'schema v3 seal — meta marker + ordered additive keys over the v2 trio',
    () {
      final result = _build();
      final meta = result.doc['meta'] as Map;
      expect(meta['schema'], _kSchemaRevision);

      final components = result.doc['components'] as Map;
      expect(components, isNotEmpty);
      for (final entry in components.entries) {
        final doc = entry.value as Map;
        expect(
          doc.keys.toList(),
          // Ordered, not a set — key order is part of the deterministic
          // byte-stable output, so ordering drift is a real regression.
          // The v2 trio leads (byte-stable underneath), the v3 additive
          // keys follow in wiring order (each reader's own test owns its
          // value shape).
          [
            // The v2 trio and the four coverage buckets come from
            // `ComponentDoc.toJson`'s own order; the v3 additive keys follow
            // because `buildExportedDoc` spreads them after it. Ordered and
            // not a set, because key order is part of the byte-stable output
            // — ordering drift is a real regression.
            //
            // The four buckets after `sizes` partition every declared field
            // with `fields`: a value reached, an absence decided, a default
            // retired, or the reader failed. Anything in none of them is a gap
            // nobody has looked at, and that partition is what the coverage
            // gate asserts rather than infers — so the shape carries all four,
            // not just the valued one. `constants` / `constantsUnroutable` sit
            // where a `static const` with no matching instance field lands: a
            // value the widget paints that has no override slot.
            'fields',
            'constants',
            'constantsUnroutable',
            // The contract's behaviour defaults — widget-parameter values,
            // not Style slots, so they sit apart from `fields` /
            // `constants`.
            'behaviour',
            'variants',
            'sizes',
            'slots',
            'absent',
            'deprecated',
            'hostDerived',
            'derivedDefaults',
            'untokenized',
            'section',
            'axes',
            'props',
            'docs',
            'examples',
          ],
          reason: '${entry.key} has a divergent shape/order',
        );
        for (final v2Key in const ['fields', 'variants', 'sizes']) {
          expect(
            doc[v2Key],
            isA<Map<String, dynamic>>(),
            reason: '${entry.key}.$v2Key lost its v2 shape',
          );
        }
      }
    },
  );

  // The widgets read their behaviour defaults off the contract
  // (`core/style-contract.md`), and the builder draws the default field from
  // the same export — so the number has to arrive, and only literals do.
  test('a contract behaviour default reaches the export', () {
    final result = _build();
    final components = result.doc['components'] as Map;
    final otp = components['input_otp'] as Map;
    expect(otp['behaviour'], {'length': 6, 'separatorInterval': 3});
    // A component whose contract states none still carries the key, empty —
    // every component keeps one shape.
    final card = components['card'] as Map;
    expect(card['behaviour'], isEmpty);
  });

  // A distance the contract spells with a token is the same number to a canvas
  // as one spelled with a literal. It reaches the export resolved, so the
  // builder reads it from there and keeps no copy of its own; an expression
  // that is not a scalar still stays out.
  test('a behaviour default spelled as a token or a sibling literal arrives '
      'resolved', () {
    final components = _build().doc['components'] as Map;
    final contextMenu = components['context_menu'] as Map;
    final behaviour = contextMenu['behaviour'] as Map;

    expect(behaviour['previewGap'], 8, reason: 'CoreSpace.space8');
    expect(behaviour['glideSlop'], 18, reason: 'defaultLongPressSlop');
    expect(behaviour['longPressSlop'], 18);
    expect(
      behaviour.containsKey('longPressDuration'),
      isFalse,
      reason: 'a Duration(…) is not a scalar the canvas can be built from',
    );
  });

  // A dispatch table that exports as `{}` is the one failure this reader
  // has produced three separate times — BOOL keys, alias values, and a
  // second axis — and every time the symptom was the same: the component's
  // colours silently never reached the canvas.
  //
  // It is worth its own test because an empty table does not read as a
  // fault. It reads as "this component declined to state per-variant
  // chrome", which is a real and common thing for a component to say — so
  // nothing downstream complains, and the gap surfaces only when someone
  // opens the file and finds a whole component grey.
  //
  // A clean assertion rather than a ratchet: all 34 tables carry rows
  // today, and a component that genuinely states none simply has no
  // `defaultsBy*` member to export.
  test('no exported dispatch table is empty', () {
    final doc = _build().doc['components']! as Map<String, dynamic>;
    final empty = <String>[];

    for (final entry in doc.entries) {
      final component = entry.value as Map<String, dynamic>;
      for (final axis in const ['variants', 'sizes']) {
        final tables = component[axis] as Map<String, dynamic>? ?? const {};
        for (final table in tables.entries) {
          final rows = table.value;
          if (rows is Map && rows.isEmpty) {
            empty.add('${entry.key}.$axis.${table.key}');
          }
        }
      }
    }

    expect(
      empty,
      isEmpty,
      reason:
          'these dispatch tables declare rows in Dart but exported none, '
          'so the components they belong to reach Figma with no per-variant '
          'chrome at all — check how their keys and values are shaped '
          'against what `_readDispatchTable` resolves: $empty',
    );
  });

  // A nested-Style default states its partial through the parent's OWN
  // sibling constants — every bare identifier in the constructor call is a
  // name in the class that wrote it. The exporter used to emit those
  // arguments in the CHILD's scope, which is wrong in two ways at once: where
  // the child declares the same name (with a different value) that value
  // won, and where it declares nothing the argument was dropped and the
  // child's base default stayed. `CardImage`'s transparent frame reached the
  // canvas as `surface` + `outline-variant` that way, and no test could say
  // so because nothing compared the two spellings of one value.
  group('nested-Style default identifiers resolve in the writing class', () {
    // The child shadows two of the parent's names with different values and
    // has no third — both failure modes of a child-scoped lookup.
    const child = '''
class CoreChildStyle implements CoreStyle<CoreChildStyle> {
  const CoreChildStyle({this.backgroundColor, this.size, this.radius});
  final CoreColor? backgroundColor;
  final double? size;
  final double? radius;
  static const CoreColor defaultBackgroundColor =
      CoreColor.token(CoreColors.surface);
  static const double defaultSize = 4.0;
  static const double defaultRadius = 1.0;
}
''';

    String parent({required String frameArgs}) =>
        '''
class CoreParentStyle implements CoreStyle<CoreParentStyle> {
  const CoreParentStyle({
    this.backgroundColor,
    this.size,
    this.frameRadius,
    this.frameStyle,
  });
  final CoreColor? backgroundColor;
  final double? size;
  final double? frameRadius;
  final CoreChildStyle? frameStyle;
  static const CoreColor defaultBackgroundColor = .transparent;
  static const double defaultSize = 9.0;
  static const double defaultFrameRadius = 2.0;
  static const CoreChildStyle defaultFrameStyle = CoreChildStyle(
    $frameArgs
  );
}
''';

    Map<String, dynamic> exportOf(String parentSource) {
      final classes = readCompilationUnit(
        'test.dart',
        '$child\n$parentSource',
      )!;
      final registry = {for (final c in classes) c.name: c};
      return buildDoc(
        EmitContext(tokenScale: const {}, classRegistry: registry),
        registry,
      ).doc;
    }

    Map<String, dynamic> frameStyleOf(Map<String, dynamic> doc) {
      final parent = (doc['components'] as Map)['parent'] as Map;
      return ((parent['fields'] as Map)['frameStyle'] as Map)
          .cast<String, dynamic>();
    }

    // `via` is provenance (the alias chain), not value — the identifier form
    // records one more hop than the literal form and that is the only
    // difference allowed.
    Object? stripVia(Object? value) => switch (value) {
      Map() => {
        for (final e in value.entries)
          if (e.key != 'via') e.key: stripVia(e.value),
      },
      List() => [for (final item in value) stripVia(item)],
      _ => value,
    };

    test('the identifier form exports the same leaves as the literal form', () {
      final byIdentifier = frameStyleOf(
        exportOf(
          parent(
            frameArgs:
                'backgroundColor: defaultBackgroundColor, '
                'size: defaultSize, '
                'radius: defaultFrameRadius,',
          ),
        ),
      );
      final byLiteral = frameStyleOf(
        exportOf(
          parent(
            frameArgs: 'backgroundColor: .transparent, size: 9.0, radius: 2.0,',
          ),
        ),
      );

      expect(stripVia(byIdentifier), equals(stripVia(byLiteral)));

      // The parent's values, not the child's same-named ones and not the
      // child's base: transparent (not `surface`), 9 (not 4), 2 (not 1).
      final background = byIdentifier['backgroundColor'] as Map;
      expect(background['ref'], isNull);
      expect(background['argb'], 0);
      expect((byIdentifier['size'] as Map)['v'], 9.0);
      expect((byIdentifier['radius'] as Map)['v'], 2.0);

      // Provenance names the parent's constant the value came through.
      expect((byIdentifier['size'] as Map)['via'], contains('defaultSize'));
    });

    // `PhoneInput.defaultNumberFieldStyle` is `chromelessFieldStyle.merge(
    // const CoreTextFieldStyle(baseTextStyle: …))`. The reader folded a merge
    // only onto a constructor call, so a NAMED receiver read as raw source, the
    // overlay found no call, and the slot exported the child's own chrome —
    // the opposite of what the parent states.
    test(
      'a named const as a merge receiver is folded, the overlay winning',
      () {
        const parentSource = '''
class CoreParentStyle implements CoreStyle<CoreParentStyle> {
  const CoreParentStyle({this.frameStyle});
  final CoreChildStyle? frameStyle;
  static const CoreChildStyle chromeless = CoreChildStyle(
    backgroundColor: .transparent,
    size: 0.0,
  );
  static final CoreChildStyle defaultFrameStyle = chromeless.merge(
    const CoreChildStyle(size: 7.0),
  );
}
''';
        final frame = frameStyleOf(exportOf(parentSource));
        final background = frame['backgroundColor'] as Map;
        expect(
          background['ref'],
          isNull,
          reason: 'the receiver states transparent',
        );
        expect(background['argb'], 0);
        expect(
          (frame['size'] as Map)['v'],
          7.0,
          reason: 'the merge argument wins',
        );
        expect(
          (frame['radius'] as Map)['v'],
          1.0,
          reason: "a field neither side states is the child's own default",
        );
      },
    );

    test("PhoneInput's number field exports chromeless, at bodyLarge", () {
      final doc = _build().doc;
      final phone = (doc['components'] as Map)['phone_input'] as Map;
      final number = ((phone['fields'] as Map)['numberFieldStyle'] as Map)
          .cast<String, dynamic>();
      for (final key in ['backgroundColor', 'borderColor']) {
        expect((number[key] as Map)['argb'], 0, reason: '$key is transparent');
        expect(
          (number[key] as Map)['ref'],
          isNull,
          reason: '$key is transparent',
        );
      }
      expect((number['borderWidth'] as Map)['v'], 0.0);
      expect((number['minHeight'] as Map)['v'], 0.0);
      for (final corner in (number['borderRadius'] as Map).values) {
        expect((corner as Map)['v'], 0.0);
      }
      for (final side in (number['padding'] as Map).values) {
        expect((side as Map)['v'], 0.0);
      }
      expect((number['baseTextStyle'] as Map)['role'], 'bodyLarge');
    });

    test('an identifier the reader cannot follow fails the export', () {
      expect(
        () => exportOf(parent(frameArgs: 'size: defaultNope,')),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('CoreParentStyle'),
              contains('defaultNope'),
              contains('CoreChildStyle'),
            ),
          ),
        ),
        reason:
            "silence here is the fault itself — the child's default would "
            'reach the canvas in place of a value the parent stated',
      );
    });
  });
}
