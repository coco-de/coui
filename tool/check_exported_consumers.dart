// Ratchet: exported-but-0-consumer public symbols (Epic #2496 S7.4).
//
// The de-prefix sweep removed public top-level symbols that the barrels
// re-exported yet nothing in the monorepo referenced — dead public leftover
// (a `Co`-prefixed twin, an orphaned helper). This guard keeps that cleanup
// from regrowing: it inventories the public top-level symbols each barrel
// (`coui_core` / `coui_flutter` / `coui_web`) exports from its own `src/`
// files, then fails when a symbol referenced NOWHERE in the monorepo outside
// its own declaration file + the barrels appears that is not already in the
// frozen baseline (`tool/exported_consumers_baseline.txt`). Net-new 0; the
// baseline only shrinks as real dead exports get deleted.
//
// "Consumer" means the de-prefix "0-use" signal: a USE site — any `\bName\b`
// occurrence on a line that is NOT the symbol's own declaration header /
// constructor (in any file) and NOT inside a barrel export line. So a legit
// in-file-only public type (e.g. a `CoreXxxVariantStyle` referenced by its own
// `defaultsByVariant` map) counts as consumed and is NOT flagged — only a
// symbol declared and then referenced nowhere at all is dead leftover.
//
// Scope notes (intentional, conservative — over-counts consumers so the gate
// never false-fails, only misses a coincidentally-named dead symbol):
//   * `package:` / `dart:` re-exports are skipped (third-party surface).
//   * comments / strings count as uses (safe direction).
//   * `show` / `hide` clauses on `src/` exports are honoured.
//
// Usage:
//   dart run tool/check_exported_consumers.dart           # list current set
//   dart run tool/check_exported_consumers.dart --ci      # fail on net-new
//   dart run tool/check_exported_consumers.dart --update  # rewrite baseline
import 'dart:io';

const _kBaselinePath = 'tool/exported_consumers_baseline.txt';

/// Barrels keyed by package name → barrel file path.
const _kBarrels = {
  'coui_core': 'packages/coui_core/lib/coui_core.dart',
  'coui_flutter': 'packages/coui_flutter/lib/coui_flutter.dart',
  'coui_web': 'packages/coui_web/lib/coui_web.dart',
};

/// Directories whose `.dart` files count as potential consumers.
const _kScanRoots = ['packages', 'docs_site', 'app', 'tool'];

final _identifier = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');

void main(List<String> args) {
  final mode = args.contains('--update')
      ? _Mode.update
      : args.contains('--ci')
      ? _Mode.ci
      : _Mode.list;

  final barrelPaths = _kBarrels.values.toSet();

  // 1. Inventory exported public symbols per package: pkg → {symbol → file}.
  final exported = <String, Map<String, String>>{
    for (final entry in _kBarrels.entries)
      entry.key: _exportedSymbols(entry.value),
  };

  // 2. Find which candidate symbols have at least one USE site (an occurrence
  //    that is not a declaration header / constructor, outside the barrels).
  final candidates = <String>{
    for (final m in exported.values) ...m.keys,
  };
  final consumed = _consumedSymbols(candidates, barrelPaths);

  // 3. A symbol is dead leftover when it is exported but never used.
  final current = <String>{
    for (final entry in exported.entries)
      for (final symbol in entry.value.keys)
        if (!consumed.contains(symbol)) '${entry.key}::$symbol',
  };

  final sorted = current.toList()..sort();

  switch (mode) {
    case .list:
      stdout.writeln('Exported-but-0-consumer symbols: ${sorted.length}');
      for (final e in sorted) {
        stdout.writeln('  $e');
      }
    case .update:
      File(_kBaselinePath).writeAsStringSync('${sorted.join('\n')}\n');
      stdout.writeln('Wrote baseline (${sorted.length}) → $_kBaselinePath');
    case .ci:
      final baseline = _readBaseline();
      final netNew = sorted.where((e) => !baseline.contains(e)).toList();
      final removed = baseline.where((e) => !current.contains(e)).length;
      if (netNew.isEmpty) {
        stdout.writeln(
          '✅ exported-0 ratchet: ${sorted.length} '
          '(baseline ${baseline.length}, no net-new).',
        );
        if (removed > 0) {
          stdout.writeln(
            '   ℹ $removed baseline entr${removed == 1 ? 'y is' : 'ies are'} '
            'now consumed/removed — run --update to shrink the baseline.',
          );
        }
        exit(0);
      }
      stderr.writeln(
        '❌ exported-0 ratchet: ${netNew.length} net-new dead public export(s):',
      );
      for (final e in netNew) {
        stderr.writeln('     $e');
      }
      stderr.writeln(
        '   A barrel exports this public symbol but nothing in the monorepo\n'
        '   consumes it. Either wire/use it, stop exporting it, or (if it is\n'
        '   genuinely external-only API) run\n'
        '     dart run tool/check_exported_consumers.dart --update\n'
        '   to accept it into the baseline.',
      );
      exit(1);
  }
}

enum _Mode { list, ci, update }

/// Resolves a barrel's own-`src/` exports to the set of public top-level
/// symbols it exposes (honouring `show` / `hide`).
Map<String, String> _exportedSymbols(String barrelPath) {
  final result = <String, String>{};
  final barrel = File(barrelPath);
  if (!barrel.existsSync()) return result;
  final libDir = Directory(barrelPath).parent.path; // .../lib
  final exportRe = RegExp(
    r'''^export\s+'(?<uri>[^']+)'(?:\s+(?<combinator>show|hide)\s+'''
    r'''(?<names>[^;]+))?\s*;''',
  );

  for (final line in barrel.readAsLinesSync()) {
    final m = exportRe.firstMatch(line.trimRight());
    if (m == null) continue;
    final uri = m.namedGroup('uri')!;
    if (uri.startsWith('package:') || uri.startsWith('dart:')) continue;
    final filePath = _normalize('$libDir/$uri');
    final file = File(filePath);
    if (!file.existsSync()) continue;

    final declared = _publicTopLevelSymbols(file.readAsStringSync());
    final combinator = m.namedGroup('combinator');
    final names = m.namedGroup('names');
    Iterable<String> exposed = declared;
    if (combinator == 'show' && names != null) {
      final shown = names.split(',').map((s) => s.trim()).toSet();
      exposed = declared.where(shown.contains);
    } else if (combinator == 'hide' && names != null) {
      final hidden = names.split(',').map((s) => s.trim()).toSet();
      exposed = declared.where((s) => !hidden.contains(s));
    }
    for (final s in exposed) {
      result[s] = filePath;
    }
  }
  return result;
}

final _typeRe = RegExp(
  r'^(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
  r'(?:class|enum|mixin|extension\s+type|extension|typedef)\s+([A-Za-z_]\w*)',
);
final _getterRe = RegExp(r'^[\w<>,?\s]+\bget\s+([A-Za-z_]\w*)');
final _varRe = RegExp(
  r'^(?:const|final)\s+(?:[\w<>,?\s]+\s+)?([A-Za-z_]\w*)\s*=',
);
final _fnRe = RegExp(r'^[\w<>,?\s]+\s+([A-Za-z_]\w*)\s*(?:<[^>]*>\s*)?\(');

final _extensionRe = RegExp(r'^extension\s+(?!type\b)([A-Za-z_]\w*)');

/// The declared name if [line] is a top-level declaration header, else null.
/// Top-level declarations are unindented; this is called with a stripped line.
String? _declNameOf(String line) {
  final name =
      _typeRe.firstMatch(line)?.group(1) ??
      _getterRe.firstMatch(line)?.group(1) ??
      _varRe.firstMatch(line)?.group(1) ??
      _fnRe.firstMatch(line)?.group(1);
  if (name == null || _kKeywords.contains(name)) return null;
  return name;
}

/// A plain named `extension X on Y` is consumed through its members, not its
/// name, so name-reference dead-detection cannot see it; such extensions are
/// excluded from the inventory. An `extension type` is a nominal type and kept.
bool _isPlainExtension(String line) => _extensionRe.hasMatch(line.trimLeft());

/// Public top-level declaration names in a Dart source string. Top-level
/// declarations are unindented (column 0); members are indented, so anchoring
/// at start-of-line excludes them.
Set<String> _publicTopLevelSymbols(String source) => source
    .split('\n')
    .where(
      (raw) =>
          raw.isNotEmpty &&
          !raw.startsWith(' ') &&
          !raw.startsWith('\t') &&
          !raw.startsWith('//') &&
          !raw.startsWith('/*') &&
          !raw.startsWith('*'),
    )
    .map((raw) => raw.trimRight())
    .where((line) => !_isPlainExtension(line))
    .map(_declNameOf)
    .whereType<String>()
    .where((name) => !name.startsWith('_'))
    .toSet();

const _kKeywords = {
  'get',
  'set',
  'class',
  'enum',
  'mixin',
  'extension',
  'typedef',
  'on',
  'extends',
  'implements',
  'with',
  'return',
  'final',
  'const',
  'void',
  'if',
  'for',
  'while',
  'switch',
  'late',
  'static',
  'external',
  'type',
};

/// The subset of [candidates] that have at least one USE occurrence across the
/// monorepo — an identifier hit on a line that is not a declaration header /
/// constructor for that symbol, outside the barrels.
Set<String> _consumedSymbols(Set<String> candidates, Set<String> barrelPaths) {
  final consumed = <String>{};
  for (final root in _kScanRoots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = _normalize(entity.path);
      if (path.contains('/.dart_tool/') || path.contains('/build/')) continue;
      if (barrelPaths.contains(path)) continue; // export lines are not uses
      for (final line in entity.readAsLinesSync()) {
        consumed.addAll({
          for (final m in _identifier.allMatches(line))
            if (candidates.contains(m.group(0)) &&
                !_isDeclLineOf(line, m.group(0)!))
              m.group(0)!,
        });
      }
    }
  }
  return consumed;
}

final _ctorTail = RegExp(
  r'^(?:const\s+|factory\s+)?[A-Za-z_]\w*(?:\.\w+)?\s*\(',
);

/// Whether [line] is a declaration header or constructor for symbol [name]
/// (so this occurrence is NOT a use). A use line — a type argument, a field
/// type, a constructor call with anything before the name — does not match.
bool _isDeclLineOf(String line, String name) {
  final stripped = line.trimLeft();
  if (_declNameOf(stripped) == name) return true;
  // Constructor: stripped line begins with `[const|factory] Name[(.named)](`.
  // Only classes (Dart convention: UpperCamelCase) can have a constructor
  // declaration that looks like this — a lowercase top-level function name
  // can never be "declaring its own constructor", so gating on the first
  // letter avoids misreading an ordinary call (`buildFoo(...)`) that starts
  // a line as if it were `Foo`'s own constructor header. Without this gate,
  // any top-level function whose only call sites open a line/list-element
  // (no receiver before the name) was invisible to the consumer scan and
  // false-flagged as a dead export (regression: `buildPhoneFlagBackground`,
  // `resolveCouiLocalizationsFor` — both genuinely consumed one line away).
  final isPlausibleConstructorName =
      name.isNotEmpty && name[0].toUpperCase() == name[0];
  if (isPlausibleConstructorName &&
      (stripped.startsWith(name) ||
          stripped.startsWith('const $name') ||
          stripped.startsWith('factory $name'))) {
    final m = _ctorTail.firstMatch(stripped);
    if (m != null) {
      final ctorName = RegExp(
        r'^(?:const\s+|factory\s+)?([A-Za-z_]\w*)',
      ).firstMatch(stripped)!.group(1);
      if (ctorName == name) return true;
    }
  }
  return false;
}

Set<String> _readBaseline() {
  final f = File(_kBaselinePath);
  if (!f.existsSync()) return {};
  return f
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toSet();
}

/// Collapses `a/b/../c` and `./` segments to a stable comparable path.
String _normalize(String path) {
  final parts = <String>[];
  for (final seg in path.split('/')) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.length -= 1;
    } else {
      parts.add(seg);
    }
  }
  return parts.join('/');
}
