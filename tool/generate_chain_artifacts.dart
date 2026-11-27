#!/usr/bin/env dart

// This is a CLI script — its whole job is printing progress/results, so a
// logging framework would add ceremony without a reader that benefits.
// ignore_for_file: avoid_print

/// Generates the style-chain measurement artifacts straight from the
/// `*StyleChain` extension surfaces in `packages/coui_flutter` and
/// `packages/coui_web`:
///
/// 1. `docs_core/lib/shared/chain_axis_table.dart` — the per-component
///    measured table (tier, getters per platform per extension target,
///    chain-example presence, exclusion set). Pure Dart data — the single
///    source every downstream consumer (tier compliance tests, permutation
///    vocabulary checks, renderer generation) reads instead of re-grepping.
/// 2. `docs_core/lib/shared/chain_tier1.dart` — `kChainTier1Components`,
///    the **server-safe** T1 membership set. SSG code decides whether to
///    render the shuffle affordance from this name-set alone; deciding from
///    a widget-bearing registry would pull `dart:ui` into the server build.
/// 3. `docs/chain-axis-table.md` — the same table rendered for humans
///    (tier membership review, batch planning for the example-expansion
///    stories).
///
/// Why a generator instead of a hand list: tier membership is a fact about
/// the extension surfaces that already exist as code. A hand-maintained
/// copy is a second place to forget to update — grep-derived output plus a
/// `--check` drift gate keeps the artifacts honest and re-runs idempotent.
///
/// Tier judgment (per component, parity-conservative): an axis counts as
/// "held" only when the component's *primary* extension target exposes it
/// on **both** platforms — the random toggle renders the same permutation
/// in both preview panes, so a single-platform axis cannot participate.
/// T1 = both axes, T2 = exactly one, T3 = `withStyle` only. Component dirs
/// with no `*StyleChain` extension at all form the exclusion set (layout
/// primitives without a Style slot).
///
/// The Text chain (`extension TextExtension on Widget`) shares getter
/// *names* with the color axis (`.primary` …) but is a typography chain,
/// not a Style-slot chain. It is excluded structurally: only extensions
/// whose name ends in `StyleChain` are parsed, and any extension target
/// that is a framework base type (`Widget`, `Component`) is rejected as a
/// defensive second fence.
///
/// The parser is intentionally regex/bracket-depth based (no `analyzer`
/// dependency), matching `tool/generate_style_tables.dart`'s approach — the
/// point is not a general Dart parser, it is a reader for the narrow,
/// consistently formatted shape every `*StyleChain` extension has.
///
/// Usage:
///   dart run tool/generate_chain_artifacts.dart            # dry-run report
///   dart run tool/generate_chain_artifacts.dart --write    # write artifacts
///   dart run tool/generate_chain_artifacts.dart --check    # CI drift gate
library;

import 'dart:convert';
import 'dart:io';

import 'package:docs_core/previews/code_registry.dart';
import 'package:docs_core/previews/flutter_code_registry.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/preview_variants.dart';

// ── Output locations ─────────────────────────────────────────────────────

const kAxisTablePath = 'docs_core/lib/shared/chain_axis_table.dart';
const kTier1SetPath = 'docs_core/lib/shared/chain_tier1.dart';
const kMarkdownTablePath = 'docs/chain-axis-table.md';

const _kGeneratedHeader =
    '// GENERATED — dart run tool/generate_chain_artifacts.dart (write '
    'mode).\n// Do not hand-edit; edit the `*StyleChain` extension sources '
    'and regenerate.';

// ── Data model ───────────────────────────────────────────────────────────

/// One `extension {Name}StyleChain on {target}` surface.
class TargetSurface {
  TargetSurface({required this.target, required this.hasWithStyle});

  final String target;
  final bool hasWithStyle;
  final List<String> radiusGetters = [];
  final List<String> colorGetters = [];

  /// Getters patching neither `borderRadius` nor a colour-axis field
  /// ([_colorAxisField]) — reported, never silently classified into an
  /// axis.
  final List<String> otherGetters = [];

  /// Getters that select a component option via copyWith.
  final List<String> optionGetters = [];
}

class ComponentSurface {
  ComponentSurface(this.slug);

  /// Hyphenated slug — the registry/`<LivePreview component=…>` key form.
  final String slug;
  final List<TargetSurface> flutterTargets = [];
  final List<TargetSurface> webTargets = [];

  bool hasFlutterChainExample = false;
  bool hasWebChainExample = false;

  /// Whether the component has a docs example dir at all — the docs
  /// surface a shuffle toggle could ever render on. Library components
  /// without one (the `mockup_*` family documented under a single
  /// `mockup` page) stay in the table as measured truth but are gated out
  /// of the tier-1 name-set.
  bool hasDocsExampleDir = false;

  bool get isTier1 => tier == 't1' && hasDocsExampleDir;

  String get primaryTargetName {
    final pascal = _pascalCase(slug);
    for (final targets in [flutterTargets, webTargets]) {
      for (final t in targets) {
        if (t.target.toLowerCase() == pascal.toLowerCase()) return t.target;
      }
    }
    // Fallback: first target with any getter, else first target — reported
    // by the dry-run so a silent mis-pick cannot hide.
    for (final targets in [flutterTargets, webTargets]) {
      for (final t in targets) {
        if (t.radiusGetters.isNotEmpty || t.colorGetters.isNotEmpty) {
          return t.target;
        }
      }
    }
    if (flutterTargets.isNotEmpty) return flutterTargets.first.target;
    if (webTargets.isNotEmpty) return webTargets.first.target;
    return pascal;
  }

  bool get primaryIsFallback =>
      primaryTargetName.toLowerCase() != _pascalCase(slug).toLowerCase();

  TargetSurface? _primaryIn(List<TargetSurface> targets) {
    final name = primaryTargetName;
    for (final t in targets) {
      if (t.target == name) return t;
    }
    return null;
  }

  TargetSurface? get flutterPrimary => _primaryIn(flutterTargets);
  TargetSurface? get webPrimary => _primaryIn(webTargets);

  /// Axis is held only when the primary target exposes it on both
  /// platforms — the toggle's parity requirement (see library doc).
  bool get hasRadiusAxis =>
      (flutterPrimary?.radiusGetters.isNotEmpty ?? false) &&
      (webPrimary?.radiusGetters.isNotEmpty ?? false);

  bool get hasColorAxis =>
      (flutterPrimary?.colorGetters.isNotEmpty ?? false) &&
      (webPrimary?.colorGetters.isNotEmpty ?? false);

  String get tier {
    if (hasRadiusAxis && hasColorAxis) return 't1';
    if (hasRadiusAxis) return 't2Radius';
    if (hasColorAxis) return 't2Color';
    return 't3';
  }

  /// Human-facing asymmetry notes (platform-different surfaces).
  List<String> get asymmetries {
    final notes = <String>[];
    if (flutterTargets.isEmpty) notes.add('Flutter extension 부재');
    if (webTargets.isEmpty) notes.add('Web extension 부재');

    final flutterNames = flutterTargets.map((t) => t.target).toSet();
    final webNames = webTargets.map((t) => t.target).toSet();
    for (final only in flutterNames.difference(webNames)) {
      notes.add('`$only` Flutter 전용 target');
    }
    for (final only in webNames.difference(flutterNames)) {
      notes.add('`$only` Web 전용 target');
    }
    for (final name in flutterNames.intersection(webNames)) {
      final f = flutterTargets.firstWhere((t) => t.target == name);
      final w = webTargets.firstWhere((t) => t.target == name);
      if (f.radiusGetters.length != w.radiusGetters.length ||
          f.colorGetters.length != w.colorGetters.length) {
        final flutterAxes =
            'r${f.radiusGetters.length}·c${f.colorGetters.length}';
        final webAxes = 'r${w.radiusGetters.length}·c${w.colorGetters.length}';
        notes.add('`$name` 축 표면 차 — Flutter $flutterAxes vs Web $webAxes');
      }
      if (f.hasWithStyle != w.hasWithStyle) {
        notes.add('`$name` withStyle 한쪽만');
      }
    }
    if (hasFlutterChainExample != hasWebChainExample) {
      notes.add('chain 예제 한쪽만');
    }
    return notes;
  }
}

// ── Source parsing ───────────────────────────────────────────────────────

String _pascalCase(String slug) => slug
    .split(RegExp('[-_]'))
    .map((s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1))
    .join();

/// Strips `///` and `//` comment text — same in-place shape
/// `tool/generate_style_tables.dart` uses (line count preserved).
String _stripComments(String source) {
  return source
      .replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '')
      .replaceAll(RegExp('//.*'), '');
}

// Extension *names* can be generic (`RadioGroupStyleChain<T>`), so the
// name/`on` gap must admit a type-parameter list.
final _extensionDecl = RegExp(
  r'extension\s+(\w*StyleChain)(?:<[^>]+>)?\s+on\s+([\w<>]+)',
);
final _getterDecl = RegExp(r'\bget\s+(\w+)\s*=>');
final _withStyleDecl = RegExp(r'\bwithStyle\(Core\w+Style\s+patch\)');

/// The fields a colour getter patches — the colour axis. A palette getter
/// patches the component's main paint field: `backgroundColor` for a
/// component whose box is its colour (Button, Card …), `color` for one
/// whose fill sits on a track that takes its colour from the fill
/// (Progress — its `backgroundColor` is that track). `transparent` patches
/// `backgroundColor` everywhere, since it clears the surface. The getter
/// *name* means the same token either way; only the field differs.
final _colorAxisField = RegExp(r'\b(?:backgroundColor|color):');
final _patchedField = RegExp(r'(\w+)\s*:');

/// Framework base types a `*StyleChain` extension never legitimately
/// targets — the Text chain (`TextExtension on Widget`) fence.
const _kFrameworkTargets = {'Widget', 'Component'};

/// Parses every `*StyleChain` extension in [source] into [TargetSurface]s.
List<TargetSurface> parseChainExtensions(String source) {
  final stripped = _stripComments(source);
  final surfaces = <TargetSurface>[];

  for (final decl in _extensionDecl.allMatches(stripped)) {
    final target = decl.group(2)!.replaceAll(RegExp('<.*>'), '');
    if (_kFrameworkTargets.contains(target)) continue;

    final open = stripped.indexOf('{', decl.end);
    if (open < 0) continue;
    var depth = 0;
    var close = -1;
    for (var i = open; i < stripped.length; i++) {
      if (stripped[i] == '{') depth++;
      if (stripped[i] == '}') {
        depth--;
        if (depth == 0) {
          close = i;
          break;
        }
      }
    }
    if (close < 0) continue; // Unbalanced — skip, never guess.
    final body = stripped.substring(open + 1, close);

    final surface = TargetSurface(
      target: target,
      hasWithStyle: _withStyleDecl.hasMatch(body),
    );

    for (final getter in _getterDecl.allMatches(body)) {
      final name = getter.group(1)!;
      final end = body.indexOf(';', getter.end);
      if (end < 0) continue;
      final expr = body.substring(getter.end, end);
      if (expr.contains('borderRadius:')) {
        surface.radiusGetters.add(name);
      } else if (_colorAxisField.hasMatch(expr)) {
        surface.colorGetters.add(name);
      } else if (RegExp(
        r'^\s*copyWith\(\s*(?:variant|tone|chipColor):',
      ).hasMatch(expr)) {
        surface.optionGetters.add(name);
      } else {
        final field = _patchedField.firstMatch(expr)?.group(1) ?? '?';
        surface.otherGetters.add('$name→$field');
      }
    }

    _sortRadius(surface.radiusGetters);
    surface.colorGetters.sort();
    surfaces.add(surface);
  }
  return surfaces;
}

/// `radius0 … radius9999` in numeric scale order — deterministic across
/// platforms regardless of source declaration order.
void _sortRadius(List<String> getters) {
  getters.sort((a, b) {
    final na = int.tryParse(a.replaceFirst('radius', '')) ?? 1 << 30;
    final nb = int.tryParse(b.replaceFirst('radius', '')) ?? 1 << 30;
    return na.compareTo(nb);
  });
}

// ── Repository scan ──────────────────────────────────────────────────────

/// Maps an extension-bearing source file to its docs component identity.
///
/// Platform file layouts disagree about directories (Flutter keeps
/// `form_field.dart` inside `form/`; Web gives `form_field` its own dir),
/// so the mapping tries the file basename first, then the parent dir,
/// preferring whichever names an actual docs example dir — the example
/// tree is the component universe the generated artifacts key into
/// (`scrollview_interceptor.dart` has no `scrollview_interceptor` example
/// dir, so it falls through to its `scrollview` parent).
String _componentSlugFor(File file) {
  final base = file.uri.pathSegments.last.replaceAll('.dart', '');
  final dir = file.parent.uri.pathSegments.where((s) => s.isNotEmpty).last;
  for (final candidate in [base, dir]) {
    final hasExampleDir =
        Directory(
          'docs_core/lib/previews/examples/flutter/$candidate',
        ).existsSync() ||
        Directory(
          'docs_core/lib/previews/examples/web/$candidate',
        ).existsSync();
    if (hasExampleDir) return candidate.replaceAll('_', '-');
  }
  return dir.replaceAll('_', '-');
}

/// Leaf component dirs (`…/{name}/{name}.dart`) under a package's
/// `src/components` — the component universe for the exclusion set.
Set<String> _componentDirs(String package) {
  final root = Directory('packages/$package/lib/src/components');
  if (!root.existsSync()) return const {};
  final dirs = <String>{};
  for (final entry in root.listSync(recursive: true).whereType<Directory>()) {
    final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (File('${entry.path}/$name.dart').existsSync()) dirs.add(name);
  }
  return dirs;
}

({Map<String, ComponentSurface> components, Set<String> excluded, int files})
scanRepository() {
  final components = <String, ComponentSurface>{};
  var filesWithExtensions = 0;

  for (final (package, isFlutter) in [
    ('coui_flutter', true),
    ('coui_web', false),
  ]) {
    final root = Directory('packages/$package/lib/src/components');
    final files =
        root
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final source = file.readAsStringSync();
      if (!source.contains('StyleChain')) continue;
      final surfaces = parseChainExtensions(source);
      if (surfaces.isEmpty) continue;
      filesWithExtensions++;

      final slug = _componentSlugFor(file);
      final component = components.putIfAbsent(
        slug,
        () => ComponentSurface(slug),
      );
      (isFlutter ? component.flutterTargets : component.webTargets).addAll(
        surfaces,
      );
    }
  }

  for (final component in components.values) {
    final dir = component.slug.replaceAll('-', '_');
    component
      ..hasFlutterChainExample = File(
        'docs_core/lib/previews/examples/flutter/$dir/'
        '${dir}_chain_example.dart',
      ).existsSync()
      ..hasWebChainExample = File(
        'docs_core/lib/previews/examples/web/$dir/'
        '${dir}_chain_example.dart',
      ).existsSync()
      ..hasDocsExampleDir =
          Directory(
            'docs_core/lib/previews/examples/flutter/$dir',
          ).existsSync() ||
          Directory('docs_core/lib/previews/examples/web/$dir').existsSync();
  }

  final universe = _componentDirs(
    'coui_flutter',
  ).union(_componentDirs('coui_web'));
  final excluded = universe
      .map((d) => d.replaceAll('_', '-'))
      .where((slug) => !components.containsKey(slug))
      .toSet();

  return (
    components: components,
    excluded: excluded,
    files: filesWithExtensions,
  );
}

// ── Artifact rendering ───────────────────────────────────────────────────

// The table literal is `const` at the top level, so nested lists are
// implicitly const — emitting `const [` again trips `unnecessary_const`.
String _dartStringList(List<String> items, String indent) {
  if (items.isEmpty) return '[]';
  final buffer = StringBuffer('[\n');
  for (final item in items) {
    buffer.writeln("$indent  '$item',");
  }
  buffer.write('$indent]');
  return buffer.toString();
}

String _renderTargetSurface(TargetSurface surface, String indent) {
  final buffer = StringBuffer()
    ..writeln('${indent}ChainTargetSurface(')
    ..writeln("$indent  target: '${surface.target}',")
    ..writeln('$indent  hasWithStyle: ${surface.hasWithStyle},')
    ..writeln(
      '$indent  radiusGetters: '
      '${_dartStringList(surface.radiusGetters, '$indent  ')},',
    )
    ..writeln(
      '$indent  colorGetters: '
      '${_dartStringList(surface.colorGetters, '$indent  ')},',
    );
  if (surface.optionGetters.isNotEmpty) {
    buffer.writeln(
      '$indent  optionGetters: '
      '${_dartStringList(surface.optionGetters, '$indent  ')},',
    );
  }
  buffer.write('$indent)');
  return buffer.toString();
}

String renderAxisTableDart(
  List<ComponentSurface> components,
  Set<String> excluded,
) {
  final buffer = StringBuffer()
    ..writeln(_kGeneratedHeader)
    ..writeln()
    ..writeln('/// 컴포넌트별 chain getter 축 실측표 — **단일 출처**.')
    ..writeln('///')
    ..writeln(
      '/// `packages/coui_flutter`·`packages/coui_web` 의 '
      '`*StyleChain` extension',
    )
    ..writeln(
      '/// 표면을 grep 파생한 결과다. 티어 멤버십·치환 어휘 검증·순열 '
      '렌더러 생성이',
    )
    ..writeln(
      '/// 전부 이 표를 읽는다 — 손 목록 금지. 순수 Dart (jaspr/Flutter '
      'import 0).',
    )
    ..writeln('library;')
    ..writeln()
    ..writeln('/// 컴포넌트의 chain getter 축 티어.')
    ..writeln('///')
    ..writeln('/// 판정은 primary target 이 **양 플랫폼 모두** 보유한 축 기준 —')
    ..writeln(
      '/// 랜덤 토글이 두 팬에 같은 순열을 그려야 하므로(파리티) '
      '단일 플랫폼',
    )
    ..writeln('/// 축은 세지 않는다.')
    ..writeln('enum ChainTier {')
    ..writeln('  /// radius·색 양축 보유 — 랜덤 토글 대상.')
    ..writeln('  t1,')
    ..writeln()
    ..writeln('  /// radius 축만 보유.')
    ..writeln('  t2Radius,')
    ..writeln()
    ..writeln('  /// 색 축만 보유.')
    ..writeln('  t2Color,')
    ..writeln()
    ..writeln('  /// getter 0 — `withStyle` full-control 만.')
    ..writeln('  t3,')
    ..writeln('}')
    ..writeln()
    ..writeln('/// 한 `extension {Name}StyleChain on {target}` 의 getter 표면.')
    ..writeln('class ChainTargetSurface {')
    ..writeln('  const ChainTargetSurface({')
    ..writeln('    required this.target,')
    ..writeln('    required this.hasWithStyle,')
    ..writeln('    required this.radiusGetters,')
    ..writeln('    required this.colorGetters,')
    ..writeln('    this.optionGetters = const [],')
    ..writeln('  });')
    ..writeln()
    ..writeln('  /// extension target 클래스명.')
    ..writeln('  final String target;')
    ..writeln()
    ..writeln('  /// `withStyle(CoreXxxStyle patch)` 선언 보유 여부.')
    ..writeln('  final bool hasWithStyle;')
    ..writeln()
    ..writeln('  /// `borderRadius` 를 patch 하는 getter 이름 (scale 순).')
    ..writeln('  final List<String> radiusGetters;')
    ..writeln()
    ..writeln(
      '  /// 색 축 필드(`backgroundColor` · 채움이 주 색인 부품은 `color`)를',
    )
    ..writeln('  /// patch 하는 getter 이름 (사전순).')
    ..writeln('  final List<String> colorGetters;')
    ..writeln()
    ..writeln('  /// Getters selecting a constructor option through copyWith.')
    ..writeln('  final List<String> optionGetters;')
    ..writeln('}')
    ..writeln()
    ..writeln('/// 한 컴포넌트의 실측 행.')
    ..writeln('class ChainAxisEntry {')
    ..writeln('  const ChainAxisEntry({')
    ..writeln('    required this.component,')
    ..writeln('    required this.tier,')
    ..writeln('    required this.primaryTarget,')
    ..writeln('    required this.flutterTargets,')
    ..writeln('    required this.webTargets,')
    ..writeln('    required this.hasFlutterChainExample,')
    ..writeln('    required this.hasWebChainExample,')
    ..writeln('    required this.hasDocsExampleDir,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  /// 하이픈 slug — registry·`<LivePreview component=…>` 키 형식.')
    ..writeln('  final String component;')
    ..writeln()
    ..writeln('  /// 티어 (양-플랫폼 primary target 기준).')
    ..writeln('  final ChainTier tier;')
    ..writeln()
    ..writeln('  /// 티어 판정에 쓴 대표 target 클래스명.')
    ..writeln('  final String primaryTarget;')
    ..writeln()
    ..writeln('  /// Flutter 쪽 extension 표면 (primary 우선 정렬).')
    ..writeln('  final List<ChainTargetSurface> flutterTargets;')
    ..writeln()
    ..writeln('  /// Web 쪽 extension 표면 (primary 우선 정렬).')
    ..writeln('  final List<ChainTargetSurface> webTargets;')
    ..writeln()
    ..writeln('  /// `…_chain_example.dart` 존재 여부 (Flutter).')
    ..writeln('  final bool hasFlutterChainExample;')
    ..writeln()
    ..writeln('  /// `…_chain_example.dart` 존재 여부 (Web).')
    ..writeln('  final bool hasWebChainExample;')
    ..writeln()
    ..writeln('  /// docs 예제 dir 실재 여부 — 셔플 토글이 렌더될 docs 표면이')
    ..writeln('  /// 있는가. `kChainTier1Components` 멤버십은 `tier == t1` 에')
    ..writeln('  /// 이 조건을 곱한 값이다.')
    ..writeln('  final bool hasDocsExampleDir;')
    ..writeln('}')
    ..writeln()
    ..writeln('/// 실측표 본체 — slug 사전순.')
    ..writeln('const List<ChainAxisEntry> kChainAxisTable = [');

  for (final component in components) {
    final tierName = component.tier;
    buffer
      ..writeln('  ChainAxisEntry(')
      ..writeln("    component: '${component.slug}',")
      ..writeln('    tier: ChainTier.$tierName,')
      ..writeln("    primaryTarget: '${component.primaryTargetName}',")
      ..writeln('    flutterTargets: [');
    for (final t in _primaryFirst(
      component.flutterTargets,
      component.primaryTargetName,
    )) {
      buffer.writeln('${_renderTargetSurface(t, '      ')},');
    }
    buffer
      ..writeln('    ],')
      ..writeln('    webTargets: [');
    for (final t in _primaryFirst(
      component.webTargets,
      component.primaryTargetName,
    )) {
      buffer.writeln('${_renderTargetSurface(t, '      ')},');
    }
    buffer
      ..writeln('    ],')
      ..writeln(
        '    hasFlutterChainExample: ${component.hasFlutterChainExample},',
      )
      ..writeln('    hasWebChainExample: ${component.hasWebChainExample},')
      ..writeln('    hasDocsExampleDir: ${component.hasDocsExampleDir},')
      ..writeln('  ),');
  }

  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('/// `*StyleChain` extension 이 없는 컴포넌트 — 제외 목록')
    ..writeln('/// (Style 슬롯/`merge` 없는 layout primitive 류).')
    ..writeln('const Set<String> kChainExcludedComponents = {');
  for (final slug in excluded.toList()..sort()) {
    buffer.writeln("  '$slug',");
  }
  buffer.writeln('};');
  return buffer.toString();
}

List<TargetSurface> _primaryFirst(List<TargetSurface> targets, String primary) {
  return [...targets]..sort((a, b) {
    if (a.target == primary && b.target != primary) return -1;
    if (b.target == primary && a.target != primary) return 1;
    return a.target.compareTo(b.target);
  });
}

String renderTier1Dart(List<ComponentSurface> components) {
  final tier1 = components.where((c) => c.isTier1).toList();
  final buffer = StringBuffer()
    ..writeln(_kGeneratedHeader)
    ..writeln()
    ..writeln('/// **Server-safe** T1(양축) 멤버십 단일 출처.')
    ..writeln('///')
    ..writeln(
      '/// SSG(`live_preview.dart`)가 셔플 affordance 렌더 여부를 이 '
      'name-set',
    )
    ..writeln(
      '/// 하나로 판정한다 — widget-bearing chain registry 를 서버 '
      '경로에서',
    )
    ..writeln(
      '/// 읽으면 서버 빌드에 `dart:ui` 가 유입되므로 판정용 이름 '
      '집합을',
    )
    ..writeln(
      '/// 분리해 뒀다. 파생 원본은 '
      '`docs_core/lib/shared/chain_axis_table.dart`.',
    )
    ..writeln('library;')
    ..writeln()
    ..writeln(
      '/// radius·색 양축 getter 를 양 플랫폼 primary target 에서 '
      '보유하고',
    )
    ..writeln(
      '/// docs 예제 dir 이 실재하는 컴포넌트 slug (하이픈 형식) — '
      '랜덤 순열',
    )
    ..writeln(
      '/// 토글 대상. 양축이어도 docs 표면이 없는 라이브러리 '
      '컴포넌트는',
    )
    ..writeln('/// 제외된다 (실측표의 `hasDocsExampleDir` 참조).')
    ..writeln('const Set<String> kChainTier1Components = {');
  for (final component in tier1) {
    buffer.writeln("  '${component.slug}',");
  }
  buffer.writeln('};');
  return buffer.toString();
}

String _tierLabel(String tier) => switch (tier) {
  't1' => 'T1',
  't2Radius' => 'T2(radius)',
  't2Color' => 'T2(색)',
  _ => 'T3',
};

String _axisCell(TargetSurface? surface) {
  if (surface == null) return '—';
  return 'r${surface.radiusGetters.length}·c${surface.colorGetters.length}'
      '${surface.hasWithStyle ? '' : '·withStyle✗'}';
}

String renderMarkdownTable(
  List<ComponentSurface> components,
  Set<String> excluded,
) {
  final tierCounts = <String, int>{};
  for (final c in components) {
    tierCounts[c.tier] = (tierCounts[c.tier] ?? 0) + 1;
  }

  final buffer = StringBuffer()
    ..writeln('# Chain 축 실측표')
    ..writeln()
    ..writeln(
      '<!-- GENERATED by dart run tool/generate_chain_artifacts.dart '
      '(write mode). Do not hand-edit. -->',
    )
    ..writeln()
    ..writeln(
      '`*StyleChain` extension 표면(grep 파생)의 컴포넌트별 티어·축 '
      '실측. 기계 소비용 정본은',
    )
    ..writeln(
      '`docs_core/lib/shared/chain_axis_table.dart`, T1 판정 '
      'server-safe name-set 은',
    )
    ..writeln('`docs_core/lib/shared/chain_tier1.dart`.')
    ..writeln()
    ..writeln(
      '- 티어 판정: primary target 이 **양 플랫폼 모두** 보유한 축 기준 '
      '(파리티 보수 판정).',
    )
    ..writeln(
      '- Text 체인(`TextExtension on Widget`)은 `*StyleChain` 명명 '
      '스코프 + framework-target 펜스로 구조 배제.',
    )
    ..writeln('- 셀 표기: `r{radius getter 수}·c{색 getter 수}`.')
    ..writeln()
    ..writeln(
      '집계: 총 ${components.length} · '
      'T1 ${tierCounts['t1'] ?? 0} · '
      'T2(radius) ${tierCounts['t2Radius'] ?? 0} · '
      'T2(색) ${tierCounts['t2Color'] ?? 0} · '
      'T3 ${tierCounts['t3'] ?? 0} · '
      '제외 ${excluded.length}',
    )
    ..writeln()
    ..writeln('| 컴포넌트 | 티어 | primary | Flutter | Web | chain 예제 | 비고 |')
    ..writeln('|---|---|---|---|---|---|---|');

  for (final c in components) {
    final example = switch ((c.hasFlutterChainExample, c.hasWebChainExample)) {
      (true, true) => '양쪽',
      (true, false) => 'Flutter 만',
      (false, true) => 'Web 만',
      _ => '없음',
    };
    final notes = <String>[
      ...c.asymmetries,
      if (c.tier == 't1' && !c.isTier1) 'docs 표면 부재 — tier1 set 제외',
      if (c.primaryIsFallback) 'primary fallback',
      for (final t in [...c.flutterTargets, ...c.webTargets])
        if (t.otherGetters.isNotEmpty)
          '`${t.target}` 미분류 getter: ${t.otherGetters.join(', ')}',
    ];
    buffer.writeln(
      '| `${c.slug}` | ${_tierLabel(c.tier)} | `${c.primaryTargetName}` | '
      '${_axisCell(c.flutterPrimary)} | ${_axisCell(c.webPrimary)} | '
      '$example | ${notes.join(' · ')} |',
    );
  }

  final subTargets = components
      .where(
        (c) => c.flutterTargets.length > 1 || c.webTargets.length > 1,
      )
      .toList();
  if (subTargets.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## 서브컴포넌트 표면 (primary 외 target)')
      ..writeln()
      ..writeln('| 컴포넌트 | target | 플랫폼 | 축 |')
      ..writeln('|---|---|---|---|');
    for (final c in subTargets) {
      for (final (platform, targets) in [
        ('Flutter', c.flutterTargets),
        ('Web', c.webTargets),
      ]) {
        for (final t in targets) {
          if (t.target == c.primaryTargetName) continue;
          buffer.writeln(
            '| `${c.slug}` | `${t.target}` | $platform | ${_axisCell(t)} |',
          );
        }
      }
    }
  }

  buffer
    ..writeln()
    ..writeln('## 제외 목록 (`*StyleChain` 없음 — Style 슬롯 비대상)')
    ..writeln();
  for (final slug in excluded.toList()..sort()) {
    buffer.writeln('- `$slug`');
  }
  return buffer.toString();
}

// ── Renderer generation (T1 순열 렌더러) ─────────────────────────────────

/// The combo anchor every T1 base example carries exactly once —
/// substitution and renderer generation share this contract.
const _kRendererAnchor = '.radius16.primary';

/// Canonical getter vocabularies, duplicated here **only as emit text**
/// (the tool cannot import `docs_core`); the generated code references
/// `kChainRadiusGetters`/`kChainColorGetters` from `chain_permutations.dart`
/// at runtime, and the vocabulary-parity unit tests gate both sides.
const _kRadiusGetterNames = [
  'radius0', 'radius2', 'radius4', 'radius6', 'radius8', 'radius10',
  'radius12', 'radius14', 'radius16', 'radius20', 'radius24', 'radius28',
  'radius32', 'radius36', 'radius40', 'radius48', 'radius56', 'radius64',
  'radius9999', //
];
const _kColorGetterNames = [
  'primary', 'secondary', 'tertiary', 'surface', 'surfaceContainer',
  'error', 'success', 'warning', 'info', 'outline', 'transparent', //
];

/// Generates `{dir}_chain_permutations.dart` for one T1 component ×
/// platform by **transforming the base chain example source**:
///
/// - the example class is copied and renamed to a private
///   `_XxxChainPermutationView` that takes the current `ChainPermutation`,
///   so the renderer keeps the base's exact 2-instance structure (no
///   content jump on the first click) — including stateful examples,
///   whose `State` survives permutation rebuilds;
/// - the combo anchor `.radius16.primary` is replaced by
///   `.chainPermuted(...)`, a generated private extension that dispatches
///   the coordinate as **radius 19-way + color 11-way independent
///   switches** chained together (never a 209-way table);
/// - getter names come from the shared vocabulary constants, so a
///   coordinate can never reach a getter that does not exist.
String renderChainPermutationsDart({
  required String slug,
  required String platform,
  required String targetType,
  required String exampleSource,
}) {
  final pascal = _pascalCase(slug);
  final isFlutter = platform == 'flutter';
  final returnType = isFlutter ? 'Widget' : 'Component';

  final imports = [
    for (final line in exampleSource.split('\n'))
      if (line.startsWith('import ')) line,
  ].join('\n');

  final classStart = exampleSource.indexOf(
    RegExp('^class ', multiLine: true),
  );
  if (classStart < 0) {
    throw StateError('$slug/$platform: example has no class declaration');
  }
  var body = exampleSource.substring(classStart).trimRight();

  // Renames — longest identifier first so the State-class name (which
  // contains the widget-class name as a substring) never half-renames.
  body = body
      .replaceAll(
        '_${pascal}ChainExampleState',
        '_${pascal}ChainPermutationState',
      )
      .replaceAll('${pascal}ChainExample', '_${pascal}ChainPermutationView');

  final constructorBefore =
      'const _${pascal}ChainPermutationView({super.key});';
  if (!body.contains(constructorBefore)) {
    throw StateError(
      '$slug/$platform: expected `$constructorBefore` — example does not '
      'follow the T1 authoring shape; fix the example, never the output',
    );
  }
  body = body.replaceFirst(
    constructorBefore,
    'const _${pascal}ChainPermutationView({required this.permutation});\n\n'
    '  /// 현재 순열 좌표 — combo 인스턴스에만 적용된다.\n'
    '  final ChainPermutation permutation;',
  );

  final isStateful = body.contains(
    isFlutter ? 'extends StatefulWidget' : 'extends StatefulComponent',
  );
  final accessor = isStateful
      ? (isFlutter ? 'widget.permutation' : 'component.permutation')
      : 'permutation';
  final paintAnchor = explicitPaletteAnchor.firstMatch(body)?[0];
  final anchor = paintAnchor ?? _kRendererAnchor;
  if (!body.contains(anchor)) {
    throw StateError(
      '$slug/$platform: combo anchor `$_kRendererAnchor` not found — the '
      'authoring gate should have caught this',
    );
  }
  body = body.replaceFirst(anchor, '.chainPermuted($accessor)');

  final radiusCases = [
    for (final name in _kRadiusGetterNames) "      '$name' => $name,",
  ].join('\n');
  String paint(String color) {
    if (paintAnchor == null) return 'radiused.$color';
    final patch = explicitPaletteChain(paintAnchor, 'radius16', color);
    return 'radiused${patch.substring('.radius16'.length).trimLeft()}';
  }

  final colorCases = [
    for (final name in _kColorGetterNames) "      '$name' => ${paint(name)},",
  ].join('\n');

  return '''
$_kGeneratedHeader

/// T1 순열 렌더러 — 랜덤 토글 전용 (코드 패널 비노출, 문서용 chain 예제와
/// 역할 분리).
///
/// base 예제(`${pascal}ChainExample`)를 변환-복제한 것이라 **같은
/// 2-인스턴스 구조**에서 combo 인스턴스만 순열 좌표를 적용한다 — 코드
/// 치환 결과와 시각이 1:1 이고, 첫 클릭에 콘텐츠 구조 점프가 없다.
library;

$imports
import '../../../../shared/chain_permutations.dart';

/// [permutation] 좌표를 적용한 $pascal chain 프리뷰를 만든다.
$returnType build${pascal}ChainPermutation(ChainPermutation permutation) =>
    _${pascal}ChainPermutationView(permutation: permutation);

$body

/// 좌표를 radius 19-way + 색 11-way **독립 switch** 로 축 분해 적용 —
/// 209-way 단일 테이블 금지. getter 이름은 어휘 상수에서만 오므로
/// 존재하지 않는 getter 참조가 구조적으로 불가능하다.
extension _${pascal}ChainPermutations on $targetType {
  $targetType chainPermuted(ChainPermutation permutation) {
    final radiused = switch (kChainRadiusGetters[permutation.radiusIndex]) {
$radiusCases
      _ => radius16,
    };
    return switch (kChainColorGetters[permutation.colorIndex]) {
$colorCases
      _ => ${paint('primary')},
    };
  }
}
''';
}

/// Generates the platform chain registry — the map every T1 renderer is
/// wired into. Keys must stay identical to `kChainTier1Components`
/// (guarded by a unit test): both are emitted from the same scan, so the
/// only way they drift is hand-editing a generated file.
String renderChainRegistryDart({
  required String platform,
  required List<ComponentSurface> tier1,
}) {
  final isFlutter = platform == 'flutter';
  final widgetType = isFlutter ? 'Widget' : 'Component';
  final typedefName = isFlutter ? 'FlutterChainRenderer' : 'WebChainRenderer';
  final mapName = isFlutter ? 'kFlutterChainRegistry' : 'kWebChainRegistry';
  final packageImport = isFlutter
      ? "import 'package:coui_flutter/coui_flutter.dart' show Widget;"
      : "import 'package:coui_web/coui_web.dart' show Component;";

  String rendererImport(ComponentSurface c) {
    final dir = c.slug.replaceAll('-', '_');
    return "import 'examples/$platform/$dir/${dir}_chain_permutations.dart';";
  }

  final imports = [for (final c in tier1) rendererImport(c)].join('\n');
  final entries = [
    for (final c in tier1)
      "  '${c.slug}': build${_pascalCase(c.slug)}ChainPermutation,",
  ].join('\n');

  final clientPathDoc = isFlutter
      ? '/// **클라이언트 경로 전용 import**: 이 파일은 Flutter Widget 을\n'
            '/// 나르므로 SSG(서버) 경로가 import 하면 서버 빌드에 `dart:ui` 가\n'
            '/// 유입된다. 서버가 읽는 T1 판정은 `shared/chain_tier1.dart`\n'
            '/// name-set 하나이고, 이 registry 는 임베드 위젯\n'
            '/// (`preview_app.dart`) 쪽에서만 도달한다.'
      : '/// jaspr Component 는 서버에서도 컴파일되므로(SSG 초기 렌더) 서버\n'
            '/// 경로 유입 자체는 무해하다 — 단 SSG 의 T1 **판정**은 여전히\n'
            '/// `shared/chain_tier1.dart` name-set 을 쓴다 (판정 단일 출처).';

  return '''
$_kGeneratedHeader

/// ${isFlutter ? 'Flutter' : 'Web'} 순열 렌더러 registry — T1 컴포넌트 전수.
///
$clientPathDoc
library;

$packageImport

import '../shared/chain_permutations.dart';
$imports

/// 순열 좌표를 받아 chain 프리뷰를 만드는 렌더러.
typedef $typedefName = $widgetType Function(ChainPermutation permutation);

/// T1 컴포넌트 slug → 순열 렌더러. 키 집합 ≡ `kChainTier1Components`
/// (drift 는 unit 테스트가 가드).
final Map<String, $typedefName> $mapName = {
$entries
};
''';
}

// ── md chain snippet injection ─────────────────────────────────────────────

/// md 주입 블록의 여닫이 마커 — `STYLE_TABLE:BEGIN/END` 와 같은 계약.
const kChainSnippetBegin =
    '<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run '
    'tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit '
    'between these markers; edit the chain example sources '
    '(`*_chain_example.dart` / `*_code.dart`) and regenerate. -->';

/// 닫는 마커.
const kChainSnippetEnd = '<!-- CHAIN_SNIPPET:END -->';

/// 손저작 withStyle 절을 찾는 산문 앵커 — 마커가 아직 없는 md 의 1회성
/// 마이그레이션 진입점. 이 문장 직후의 `<Tabs>` 블록이 교체 대상이다
/// (전 컴포넌트 문서가 같은 보일러플레이트 문장을 공유한다).
const kChainProseAnchor = '체인을 쓸 수 있습니다';

/// Flutter/Web chain 스니펫을 담은 마커-포함 Tabs 블록.
///
/// 내용물은 코드 registry 의 `'chain'` 스니펫 **그대로**다 — LivePreview
/// 코드 패널이 보여주는 것과 같은 단일 출처에서 파생하므로, md 예제와
/// 실제 예제가 갈라질 수 없다 (손사본이 아니라 파생물).
String renderChainSnippetBlock({
  required String flutterCode,
  required String webCode,
}) =>
    '''
$kChainSnippetBegin
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
$flutterCode
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
$webCode
```

  </TabItem>
</Tabs>
$kChainSnippetEnd''';

/// [content] 에 [block] 을 주입한 결과 — 주입 지점을 못 찾으면 `null`
/// (호출부가 skip 으로 보고).
///
/// 마커가 이미 있으면 그 사이를 재생성하고(정상 운영 경로), 없으면
/// [kChainProseAnchor] 문장 직후의 `<Tabs>` 블록을 마커 블록으로 교체한다
/// (1회성 마이그레이션 경로). 앵커와 Tabs 사이에 헤딩이 끼면 다른 절의
/// Tabs 이므로 건드리지 않는다.
String? injectChainSnippetBlock(String content, String block) {
  final begin = content.indexOf(kChainSnippetBegin);
  if (begin >= 0) {
    final end = content.indexOf(kChainSnippetEnd, begin);
    // 닫는 마커가 사라진 손상 상태 — 잘못 먹느니 건드리지 않는다.
    if (end < 0) return null;
    return content.replaceRange(begin, end + kChainSnippetEnd.length, block);
  }

  final anchor = content.indexOf(kChainProseAnchor);
  if (anchor < 0) return null;
  const tabsOpen = '<Tabs groupId="platform">';
  const tabsClose = '</Tabs>';
  final tabsStart = content.indexOf(tabsOpen, anchor);
  if (tabsStart < 0) return null;
  if (content.substring(anchor, tabsStart).contains('\n#')) return null;
  final tabsEnd = content.indexOf(tabsClose, tabsStart);
  if (tabsEnd < 0) return null;
  return content.replaceRange(tabsStart, tabsEnd + tabsClose.length, block);
}

/// 블록 페이지가 있으면 그쪽을, 없으면 컴포넌트 페이지를 고른다.
///
/// Footer 처럼 문서가 `/blocks` 로 옮겨도 chain 스니펫 주입이 같은
/// 마커를 계속 본다.
File? _docsPageForSlug(String slug) {
  for (final root in const [
    'docs_core/content/blocks',
    'docs_core/content/components',
  ]) {
    final file = File('$root/$slug.md');
    if (file.existsSync()) return file;
  }
  return null;
}

/// chain 스니펫을 가진 전 컴포넌트의 md 를 주입 결과로 계산한다.
///
/// 반환은 (path → 주입된 전체 md) — 기존 write/check 플럼빙이 그대로
/// 소비한다 (`--check` = 파일 바이트 비교이므로 마커 안 손편집·재생성
/// 드리프트가 자동으로 걸린다). 주입 지점이 없는 md 는 `skipped` 로
/// 보고만 한다 — 손저작 절이 없는 페이지에 절을 새로 만드는 것은 이
/// 생성기의 일이 아니다.
({Map<String, String> artifacts, List<String> skipped}) renderMdChainInjections(
  List<ComponentSurface> components,
) {
  final artifacts = <String, String>{};
  final skipped = <String>[];
  for (final component in components) {
    final slug = component.slug;
    if (!docsComponentHasChainPreview(slug)) continue;

    final file = _docsPageForSlug(slug);
    if (file == null) {
      skipped.add('$slug — md 페이지 없음');
      continue;
    }
    final webBuilder = kCodeSnippetRegistry[slug];
    if (webBuilder == null) {
      skipped.add('$slug — web 코드 registry 미등록');
      continue;
    }

    final block = renderChainSnippetBlock(
      flutterCode: kFlutterCodeSnippetRegistry[slug]!('chain').trimRight(),
      webCode: webBuilder('chain').trimRight(),
    );
    final injected = injectChainSnippetBlock(file.readAsStringSync(), block);
    if (injected == null) {
      skipped.add('$slug — 주입 지점 없음 (마커/앵커 불발)');
      continue;
    }
    artifacts[file.path] = injected;
  }
  return (artifacts: artifacts, skipped: skipped);
}

// ── CLI ───────────────────────────────────────────────────────────────────

/// [content] as `dart format` leaves it at [targetPath], so checked-in
/// artifacts and `--check` comparisons are both post-format bytes —
/// hand-rolled layout guarantees would drift from the formatter.
///
/// The content goes in on stdin and comes back on stdout; `--stdin-name`
/// makes the formatter resolve [targetPath]'s `analysis_options.yaml` (e.g.
/// docs_core's `page_width: 120`) and language version exactly as it would
/// for the file itself. Nothing is written to disk: a scratch file beside
/// the target would sit in the tree the target belongs to, where every test
/// that walks that tree lists it — and a walker that listed it before it was
/// deleted fails reading it. Formatting runs via [Platform.resolvedExecutable]
/// (the exact SDK that invoked this script) instead of a bare `dart` resolved
/// from PATH, so the generator's output always matches `dart format .` run
/// with that same SDK — independent of whatever `dart` a differently-pinned
/// PATH would resolve.
Future<String> formatDart(String content, String targetPath) async {
  final process = await Process.start(Platform.resolvedExecutable, [
    // Stdout is the result here, so no first-run notice may land on it.
    '--suppress-analytics',
    'format',
    '--stdin-name=${Directory.current.path}/$targetPath',
  ]);
  final formatted = process.stdout.transform(utf8.decoder).join();
  final diagnostics = process.stderr.transform(utf8.decoder).join();
  process.stdin.add(utf8.encode(content));
  await process.stdin.close();
  final status = await process.exitCode;
  final output = await formatted;
  // The formatter says nothing on stderr when it formats. A parse error
  // exits non-zero; an `include:` it cannot resolve only warns, exits 0 and
  // formats with the default options — either way the bytes are not what
  // `dart format` makes of the real file.
  final warnings = await diagnostics;
  if (status != 0 || warnings.isNotEmpty) {
    throw StateError('dart format failed for $targetPath:\n$warnings');
  }

  return output;
}

/// Every artifact this tool writes, keyed by repo-relative path, as its final
/// bytes — what `--write` puts on disk and `--check` compares against — plus
/// the md injections it had to skip.
///
/// Reads the repository and writes nothing: each artifact is formatted in
/// memory by [formatDart].
Future<({Map<String, String> artifacts, List<String> skipped})> buildArtifacts(
  List<ComponentSurface> components,
  Set<String> excluded,
) async {
  final artifacts = <String, String>{
    kAxisTablePath: await formatDart(
      renderAxisTableDart(components, excluded),
      kAxisTablePath,
    ),
    kTier1SetPath: await formatDart(renderTier1Dart(components), kTier1SetPath),
    kMarkdownTablePath: renderMarkdownTable(components, excluded),
  };

  // T1 순열 렌더러 + registry 2종 — base 예제 변환-복제 (§renderer 참조).
  final tier1Components = components.where((c) => c.isTier1).toList();
  for (final component in tier1Components) {
    final dir = component.slug.replaceAll('-', '_');
    for (final platform in ['flutter', 'web']) {
      final examplePath =
          'docs_core/lib/previews/examples/$platform/$dir/'
          '${dir}_chain_example.dart';
      final example = File(examplePath);
      if (!example.existsSync()) {
        throw StateError('missing T1 base example: $examplePath');
      }
      final permutationsPath =
          'docs_core/lib/previews/examples/$platform/$dir/'
          '${dir}_chain_permutations.dart';
      artifacts[permutationsPath] = await formatDart(
        renderChainPermutationsDart(
          slug: component.slug,
          platform: platform,
          targetType: component.primaryTargetName,
          exampleSource: example.readAsStringSync(),
        ),
        permutationsPath,
      );
    }
  }
  const flutterRegistryPath =
      'docs_core/lib/previews/flutter_chain_registry.dart';
  artifacts[flutterRegistryPath] = await formatDart(
    renderChainRegistryDart(platform: 'flutter', tier1: tier1Components),
    flutterRegistryPath,
  );
  const webRegistryPath = 'docs_core/lib/previews/web_chain_registry.dart';
  artifacts[webRegistryPath] = await formatDart(
    renderChainRegistryDart(platform: 'web', tier1: tier1Components),
    webRegistryPath,
  );

  // md withStyle 절의 코드 블록 — 손사본 대신 chain 스니펫에서 파생·주입.
  final injections = renderMdChainInjections(components);
  artifacts.addAll(injections.artifacts);

  return (artifacts: artifacts, skipped: injections.skipped);
}

Future<void> main(List<String> args) async {
  final write = args.contains('--write');
  final check = args.contains('--check');

  final scan = scanRepository();
  final components = scan.components.values.toList()
    ..sort((a, b) => a.slug.compareTo(b.slug));

  final (:artifacts, :skipped) = await buildArtifacts(
    components,
    scan.excluded,
  );
  for (final skip in skipped) {
    print('⚠ md injection skip: $skip');
  }

  // Dry-run / shared report.
  final tier1 = components.where((c) => c.tier == 't1').length;
  final tier1Set = components.where((c) => c.isTier1).length;
  final t2r = components.where((c) => c.tier == 't2Radius').length;
  final t2c = components.where((c) => c.tier == 't2Color').length;
  final t3 = components.where((c) => c.tier == 't3').length;
  print(
    '${components.length} components · T1 $tier1 (tier1 set $tier1Set) · '
    'T2(radius) $t2r · T2(color) $t2c · T3 $t3 · '
    'excluded ${scan.excluded.length} · ${scan.files} files parsed',
  );
  for (final c in components) {
    if (c.primaryIsFallback) {
      print('⚠ primary fallback: ${c.slug} → ${c.primaryTargetName}');
    }
    for (final t in [...c.flutterTargets, ...c.webTargets]) {
      if (t.otherGetters.isNotEmpty) {
        print(
          '⚠ unclassified getters: ${c.slug} ${t.target} '
          '${t.otherGetters.join(', ')}',
        );
      }
    }
    for (final note in c.asymmetries) {
      print('ℹ asymmetry: ${c.slug} — $note');
    }
  }

  if (write) {
    artifacts.forEach((path, content) {
      File(path)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
      print('✓ wrote $path');
    });
    return;
  }

  if (check) {
    var drift = 0;
    artifacts.forEach((path, content) {
      final file = File(path);
      if (!file.existsSync()) {
        print('✗ missing: $path (run with --write)');
        drift++;
      } else if (file.readAsStringSync() != content) {
        print('✗ drift: $path is stale relative to *StyleChain sources');
        drift++;
      } else {
        print('✓ up to date: $path');
      }
    });
    if (drift > 0) exit(1);
  }
}
