// Exports CoUI component visual defaults (schema v2 — colors / radius /
// padding / border / typography / gap / icon / duration, per-field, not a
// curated subset) to `tools/figma-token-sync/src/data/components.json`,
// consumed at build time by the Figma plugin's data-driven builders
// (code → Figma, one-way).
//
// Run: `dart run packages/coui_core/bin/export_figma_components.dart`
// or via melos: `melos run export:figma-components`.
//
// SSOT: every `CoreXxxStyle.defaultsByVariant` / `defaultsBySize` /
// `static const default*` in `coui_core`, discovered generically by the
// `figma_reader/` AST reader — not the ten hand-written per-component
// functions this file used to have. Adding a field to a `CoreXxxStyle` and
// re-running this exporter is enough; there is no second place (a
// per-component extractor function) to remember to update. Component slugs
// (`text_field`, `radio_group`, …) come from the discovered class name
// (`schema_v2.dart#slugOf`), so they already track a component's current
// name (#3742's rename) without a second hand-maintained mapping.
//
// Schema v2 leaf shapes (`figma_reader/schema_v2.dart` / `emit.dart`):
//   Dim:    { v, ref, via }               — ref/via null at a terminal token
//   Color:  { ref, argb, opacity, fallbacks } — always these four keys
//   Insets: { l, t, r, b } (physical) OR { start, t, end, b } (logical) —
//           start→left / end→right resolves downstream in exactly one
//           place, `bindPad` in `tools/figma-token-sync/src/helpers.ts`.
//   Radius: { topLeft, topRight, bottomLeft, bottomRight } (each a Dim)
//   Text:   { role, fontSize?, fontWeight?, letterSpacing?, lineHeight?,
//             lineHeightPx?, fontFamily?, color? }
//   Gap:    { size: Dim }
//   Icon:   { size?: Dim, color?: Color }
//
// Determinism: component/field/dispatch-entry order all trace back to
// `repo_reader.dart`'s sorted file glob and `style_reader.dart`'s
// source-order class-body walk — two consecutive runs produce
// byte-identical output (verified by `test/export_figma_components_test.dart`'s
// golden test, mirroring `tool/generate_style_tables_test.dart`'s
// established in-memory-regenerate-then-compare shape). `canonicalLibrary`
// (below) reads a literal file's contents, not the current time, so it
// doesn't break this.

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';

import 'figma_reader/axis_reader.dart';
import 'figma_reader/docs_reader.dart';
import 'figma_reader/emit.dart';
import 'figma_reader/example_reader.dart';
import 'figma_reader/repo_reader.dart';
import 'figma_reader/schema_v2.dart';
import 'figma_reader/section_reader.dart';
import 'figma_reader/token_scale.dart';
import 'figma_reader/typography_modes.dart';
import 'figma_reader/typography_roles.dart';

void main() {
  // `melos run export:figma-components` / the documented `dart run` command
  // both run from the workspace root, so paths default to
  // `repoRoot`-prefixed. `buildExportedDoc`'s `contractsRoot`/`srcRoot`
  // params exist for `export_figma_components_test.dart`, whose `dart
  // test` working directory is this *package's* root instead.
  final result = buildExportedDoc(repoRoot: '.');

  final out = File('tools/figma-token-sync/src/data/components.json');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(result.doc)}\n',
  );

  final components = result.doc['components'] as Map;
  // R-2 — the registry↔docs correspondence gap as a printed fact: which
  // components ended up with no description from either source.
  final undescribed = [
    for (final entry in components.entries)
      if (((entry.value as Map)['docs'] as Map)['description'] == null)
        entry.key,
  ];
  stdout
    ..writeln('Wrote ${out.path}')
    ..writeln('  components: ${components.length}')
    ..writeln('  undescribed components: ${undescribed.length}')
    ..writeln(
      '  untokenized fields: ${result.untokenizedTotal}'
      '${result.untokenizedTotal == 0 ? '' : ' (see note below)'}',
    );

  // 정보성 Note 는 stdout — stderr 로 내면 melos 가 성공 실행(exit 0)에도
  // ERROR: 라벨을 붙여 오류처럼 읽힌다(#4095). 실패 신호는 exit code 가 담당.
  if (undescribed.isNotEmpty) {
    stdout.writeln(
      'Note: ${undescribed.length} component(s) have no description in '
      'either docs source (block or component md frontmatter / '
      'component catalog): '
      '${undescribed.join(', ')}',
    );
  }

  if (result.untokenizedTotal > 0) {
    stdout.writeln(
      'Note: ${result.untokenizedTotal} default field(s) could not be '
      'routed to a schema v2 leaf shape (unroutable type, e.g. an enum or '
      'a composite this reader does not model, or a value shape emit.dart '
      "doesn't recognize). These are silently omitted from the JSON — "
      'no placeholder or guessed value is emitted for them — rather than '
      'printed per-field here; see schema_v2.dart#UntokenizedField if a '
      'specific component looks incomplete.',
    );
  }
}

/// Builds the full `{meta, components}` document for [repoRoot] — pulled
/// out of `main()` so `test/export_figma_components_test.dart`'s golden
/// test can call it without touching `File` I/O beyond reading source.
///
/// [contractsRoot] / [srcRoot] default to `repoRoot`-prefixed paths
/// assuming a workspace-root working directory (how this script is
/// documented to run — `melos run export:figma-components`); the golden
/// test overrides all three since `dart test`'s working directory for this
/// package is this package's own root, not the workspace root.
BuildResult buildExportedDoc({
  required String repoRoot,
  String? contractsRoot,
  String? srcRoot,
  String? figmaLibraryPath,
  String? componentsRoot,
  String? docsContentRoot,
  String? docsCatalogPath,
  String? docsBlocksRoot,
  String? examplesRoot,
}) {
  // `referenceRoot` is derived from `srcRoot`, not defaulted independently.
  // They are the same directory by definition — `lib/src` is both the token
  // tree the namespace resolver walks and the class tree a default may point
  // into — and letting them default separately meant the test harness, which
  // overrides `srcRoot` because its working directory is this package rather
  // than the workspace, silently got no reference classes at all. The export
  // it built then disagreed with the committed file, and the failure read as
  // "components.json is stale" rather than "the two callers walked different
  // trees".
  final resolvedSrcRoot = srcRoot ?? '$repoRoot/packages/coui_core/lib/src';
  final repo = readContracts(
    repoRoot: repoRoot,
    contractsRoot: contractsRoot ?? '$resolvedSrcRoot/component/contracts',
    referenceRoot: resolvedSrcRoot,
  );
  if (repo.filesFailed.isNotEmpty) {
    throw StateError(
      'AST reader failed to parse ${repo.filesFailed.length} file(s): '
      '${repo.filesFailed.join(', ')}',
    );
  }

  final tokens = resolveNamespaces(
    repoRoot: repoRoot,
    srcRoot: resolvedSrcRoot,
  );

  final ctx = EmitContext(
    tokenScale: tokens,
    classRegistry: repo.resolutionRegistry,
    resolveSemanticColor: _semanticColorResolver(),
  );

  final result = buildDoc(ctx, repo.classesByName);
  final doc = Map<String, dynamic>.of(result.doc);
  // The role → metrics table. Emitted at the document root because a role is a
  // property of the type scale, not of whichever component references it —
  // one entry per role against hundreds of references. Without it every
  // role-only text style fell back to a hardcoded 14 in the plugin, so
  // `headlineLarge` and `labelSmall` rendered identically. Resolved through
  // the same context as the component fields, so a role's family and line box
  // (neither a token namespace) resolve the way a component's would.
  final roles = readTypographyRoles(srcRoot: resolvedSrcRoot, ctx: ctx);
  // Beside each role, what it draws in every mode of the typography
  // collection — the table the tokens export writes into the role's
  // `font-size/<role>` and `letter-spacing/<role>` variables. A consumer file
  // draws in the collection's first mode (Mobile) unless a frame chooses
  // another, and there the display and headline roles are smaller than the
  // metrics above; the plugin's consumer-file check compares a literal
  // against the role in the mode the text draws in.
  final modes = typographyModeMetrics(
    fail: (problem) =>
        throw StateError('typography modes disagree with the scale: $problem'),
  );
  doc['typography'] = {
    for (final e in roles.entries)
      e.key: {
        ...e.value.toJson(),
        'modes':
            modes[_kebab(e.key)] ??
            (throw StateError(
              'typography role ${e.key} has no row in the mode table — '
              'figma_reader/typography_modes.dart lists every CoreTextStyles '
              'role',
            )),
      },
  };
  // The dials of the GLASS effect the plugin puts on a refracting surface.
  // Figma binds no variable on that effect, so they cannot ride the
  // `Semantic/ Surface` modes the rest of the material rides — the
  // `material/<role>/glass` row there only switches the layer that wears
  // them — and the plugin reads them here, at Generate time, instead.
  doc['surfaceGlass'] = surfaceGlassJson();

  // #4012 (FR-001) — schema v3 `axes`, additive on top of v2 (fields /
  // variants / sizes stay byte-identical; every component gains an `axes`
  // key, `ComponentAxes.empty` when its directory declares none). Axes are
  // keyed by *directory* slug while components are keyed by
  // `slugOf(class name)` — the two agree for every component today, and a
  // mismatch degrades to the empty axes record rather than a crash.
  final axesBySlug = readAxes(
    // Through the hoisted root, like `readContracts` above — defaulting
    // a second time from `repoRoot` is what let the two callers walk
    // different trees.
    contractsRoot: contractsRoot ?? '$resolvedSrcRoot/component/contracts',
  );
  final sizeMembers = readComponentSizeMembers(srcRoot: resolvedSrcRoot);
  // FR-002 — `section`: the fold of coui_flutter's category directories
  // (`section_reader.dart` owns the fold map). Derived from coui_flutter
  // because the contracts tree is flat — the category taxonomy only exists
  // on the widget side.
  final sectionsBySlug = readSections(
    componentsRoot:
        componentsRoot ?? '$repoRoot/packages/coui_flutter/lib/src/components',
  );
  // FR-003 — `docs`: description(블록 md → 컴포넌트 md → 영어 카탈로그) +
  // docs_site URL + slug 3벌 대조. Sources key by kebab. A block page
  // (sibling `blocks/` of the components content dir) wins the URL too.
  final resolvedDocsContent =
      docsContentRoot ?? '$repoRoot/docs_core/content/components';
  final resolvedBlocksRoot =
      docsBlocksRoot ??
      '${Directory(resolvedDocsContent).parent.path}'
          '${Platform.pathSeparator}blocks';
  final docsByKebab = readDocs(
    contentRoot: resolvedDocsContent,
    catalogPath:
        docsCatalogPath ??
        '$repoRoot/docs_core/lib/shared/component_catalog.dart',
    blocksRoot: Directory(resolvedBlocksRoot).existsSync()
        ? resolvedBlocksRoot
        : null,
  );
  final components = doc['components'] as Map<String, dynamic>;
  // FR-004 — `examples`: 파생 불가능한 두 스니펫만(withStyle 식 · 토큰
  // getter 체인); 기본 생성자는 axes 에서 downstream 파생 (S-001).
  final examplesBySlug = readExamples(
    examplesRoot: examplesRoot ?? '$repoRoot/docs_core/lib/previews/examples',
    componentsRoot:
        componentsRoot ?? '$repoRoot/packages/coui_flutter/lib/src/components',
    contractsRoot: contractsRoot ?? '$resolvedSrcRoot/component/contracts',
    slugs: components.keys,
  );
  doc['components'] = {
    for (final entry in components.entries)
      entry.key: {
        ...entry.value as Map<String, dynamic>,
        'section': sectionJson(
          sectionsBySlug[entry.key] ?? .unmapped,
        ),
        'axes': axesJson(
          axesBySlug[entry.key] ?? .empty,
          componentSizeMembers: sizeMembers,
        ),
        // #4099 (D-25) — `props`: contract `W`/`W?` composition slot
        // getters, mechanically read (names + source nullability only).
        'props': propsJson(axesBySlug[entry.key] ?? .empty),
        'docs': docsJson(
          docsByKebab[entry.key.replaceAll('_', '-')],
          snakeSlug: entry.key,
        ),
        'examples': examplesJson(examplesBySlug[entry.key] ?? .none),
      },
  };

  final meta = Map<String, dynamic>.of(doc['meta'] as Map<String, dynamic>);
  // #3740 (A-1b) — this file (unlike build/tokens.figma.json, which the
  // plugin only ever receives via manual paste/import) is the one JSON
  // esbuild actually inlines into code.js, so it's the one that can carry
  // this build-time. Moving the canonical library is a one-file edit
  // (docs_core/content/_data/figma_library.json), zero code changes here or
  // in the plugin.
  meta['canonicalLibrary'] = _canonicalLibrary(
    path:
        figmaLibraryPath ??
        '$repoRoot/docs_core/content/_data/figma_library.json',
  );
  doc['meta'] = meta;

  return BuildResult(doc: doc, untokenizedTotal: result.untokenizedTotal);
}

/// The scale Figma's glass panel runs its depth dial on.
///
/// `CoreSurfaceRefraction.figma` converts the panel's 0–100 numbers into the
/// fractions the platforms read; this is the way back for the one dial the
/// plugin API also takes on that scale. Restated rather than shared because
/// the Core constant is that constructor's private detail.
const double _kFigmaPanelScale = 100;

/// Precision the panel numbers are rounded to, to drop the binary noise a
/// fraction picks up on its way back to the panel's scale (`0.27 × 100` is
/// not exactly 27).
const double _kPanelPrecision = 1000000;

/// The static dials of the GLASS effect a refracting surface wears on the
/// canvas, in the units Figma's plugin API takes — or null when no style
/// refracts.
///
/// Read from the style whose recipe states a refraction, found rather than
/// named. Figma's GLASS effect takes no variable, so a mode cannot switch its
/// dials: two styles refracting differently would need two effects, and this
/// throws rather than showing the first one's under both.
///
/// * `refraction` — the strength dial, 0–1 (`CoreSurfaceRefraction.strength`).
/// * `depth` — the band, back on the panel's scale (the bezel fraction ×
///   [_kFigmaPanelScale]; the API takes it at ≥ 1).
/// * `dispersion` — 0–1.
/// * `lightAngle` / `lightIntensity` — the light of the glass material's edge
///   bevel (`CoreSurfaceEdgeBevel`), which states the numbers the panel shows
///   for the same look. A material with no bevel puts no light on the glass.
///
/// What does not carry: the lens (the dome is this kit's own dial and the
/// panel has none), the refractive index (the panel states the bend as one
/// dial), and the fallback blur (it stands in for a refraction a renderer
/// cannot draw, and the canvas draws it).
Map<String, Object>? surfaceGlassJson() {
  final refracting = [
    for (final id in CoreSurfaceStyleId.values)
      if (CoreSurfaceRecipe.of(id).refraction != null) CoreSurfaceRecipe.of(id),
  ];
  if (refracting.isEmpty) return null;
  final first = refracting.first;
  for (final other in refracting.skip(1)) {
    if (other.refraction != first.refraction) {
      throw StateError(
        '${first.id.name} and ${other.id.name} refract differently, and a '
        'GLASS effect takes no variable a mode could switch — the canvas '
        'can show one set of dials',
      );
    }
  }
  final refraction = first.refraction!;
  final bevel = first.surfaceFor(CoreSurfaceRole.functional)?.sheen?.bevel;
  double panel(double fraction) =>
      (fraction * _kFigmaPanelScale * _kPanelPrecision).round() /
      _kPanelPrecision;

  return {
    'style': first.id.name,
    'refraction': refraction.strength,
    'depth': panel(refraction.bezel),
    'dispersion': refraction.dispersion,
    'lightAngle': bevel?.lightAngle ?? 0,
    'lightIntensity': bevel?.lightIntensity ?? 0,
  };
}

/// Reads the canonical-Figma-library record (#3740, A-1b) — a single small
/// JSON file, not coui_core state. Mirrors the copy in
/// `export_figma_tokens.dart`; kept duplicated rather than shared because
/// these are two independent, self-contained `bin/` scripts with no shared
/// helper module today.
Map<String, dynamic> _canonicalLibrary({required String path}) {
  final file = File(path);
  if (!file.existsSync()) {
    return {'identifier': null, 'displayName': null, 'url': null};
  }
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    'identifier': data['identifier'],
    'displayName': data['displayName'],
    'url': data['url'],
  };
}

/// Resolves a semantic colour name (`'onSurface'`) to a concrete ARGB int
/// by reusing `export_figma_tokens.dart`'s own machinery
/// (`PrimitiveCssGenerator.semanticVarsFor`) rather than a
/// hand-maintained `CoreColors.X` lookup switch — the same light-mode
/// source both exporters already treat as the single source for a
/// semantic token's *preview* colour (the CSS variable both tools' output
/// alias back to).
int? Function(String) _semanticColorResolver() {
  // CoUI's OWN source, not a generated palette read through the standard
  // mapping — these argb previews are "what the CoUI look renders", and any
  // other reading would preview a colour no CoUI surface ever paints.
  final light = PrimitiveCssGenerator.semanticVarsFor(
    CouiColorPresets.source,
    CoreBrightness.light,
  );
  return (semanticName) {
    final cssVar = '--coui-${_kebab(semanticName)}';
    final triplet = light[cssVar];
    if (triplet == null) return null;
    final channels = triplet
        .trim()
        .split(RegExp(r'\s+'))
        .map(int.parse)
        .toList();
    if (channels.length != 3) return null;
    return (0xFF << 24) |
        ((channels[0] & 0xFF) << 16) |
        ((channels[1] & 0xFF) << 8) |
        (channels[2] & 0xFF);
  };
}

String _kebab(String camel) => camel.replaceAllMapped(
  RegExp('[A-Z]'),
  (m) => '-${m[0]!.toLowerCase()}',
);
