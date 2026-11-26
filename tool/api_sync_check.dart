#!/usr/bin/env dart

/// CoUI API Sync Verification Tool.
///
/// Verifies that every component contract is implemented on **both**
/// platforms, and that the implementing class carries the same name on
/// each side.
///
/// The parity surface is the contract, not the file. `cross-platform/api.md`
/// requires both platforms to `implements CoreXxxContract`, so asking which
/// contracts each package implements measures the rule directly.
///
/// An earlier version of this tool compared **file names** between the two
/// barrel files. File layout is not API: Web keeps `Position` inside
/// `stacks.dart`, and the Web half of the touch-target floor is a CSS rule
/// with no file at all. To paper over that, the tool carried hand-maintained
/// alias and platform-exclusive tables — and those tables went stale the
/// moment components were renamed, reporting nine already-unified components
/// as platform-exclusive. Contract implementations cannot drift that way:
/// the signal is derived, so there is no list to forget to update.
///
/// Usage:
///   dart run tool/api_sync_check.dart [--json] [--ci]
///
/// Flags:
///   --json  Output results in JSON format.
///   --ci    Exit non-zero when parity is incomplete.
library;

import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// Minimum share of contracts that must be implemented on both platforms.
const double kCiThreshold = 100;

/// Multiplier to convert a 0..1 ratio into a percentage.
const double _kPercentMultiplier = 100;

/// Width (in characters) of the report's top-level divider line.
const int _kDividerWidth = 60;

/// Width (in characters) of the report's section divider line.
const int _kSectionDividerWidth = 40;

/// Matches a class declaration header up to its opening brace.
///
/// Stopping at `{` means an `implements` clause is only ever read from the
/// header it belongs to, never from a doc comment further down the file.
final RegExp _kClassHeader = RegExp(
  r'^[ \t]*(?:abstract\s+|final\s+|sealed\s+|base\s+)*'
  r'class\s+(\w+)([^{;]*)\{',
  multiLine: true,
);

/// Matches contract names inside an `implements` clause.
final RegExp _kContractRef = RegExp(r'\b(Core\w*Contract)\b');

/// Matches a contract interface declaration header in `coui_core`.
final RegExp _kContractDecl = RegExp(
  r'^[ \t]*(?:abstract\s+|interface\s+|final\s+|sealed\s+|base\s+)*'
  r'class\s+(Core\w*Contract)\b',
  multiLine: true,
);

/// Matches a `@Deprecated(...)` / `@deprecated` annotation opener.
final RegExp _kDeprecatedAnnotation = RegExp(r'^@[Dd]eprecated\b');

/// How many lines of leading trivia to walk back looking for an annotation.
///
/// Bounded so a malformed file cannot turn the walk into a scan of the whole
/// source. Doc comment + annotation blocks are far shorter than this.
const int _kTriviaScanLimit = 60;

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

/// One contract and the class that implements it on a given platform.
class Implementation {
  /// Creates an [Implementation].
  const Implementation({
    required this.contract,
    required this.className,
    required this.path,
  });

  /// Contract interface name, e.g. `CoreCardContract`.
  final String contract;

  /// Implementing widget/component class name, e.g. `Card`.
  final String className;

  /// Repo-relative path of the declaring file.
  final String path;

  /// Serializes this implementation for `--json` output.
  Map<String, dynamic> toJson() => {
    'contract': contract,
    'class': className,
    'path': path,
  };
}

/// Aggregate parity result across both platforms.
class SyncReport {
  /// Creates a [SyncReport].
  const SyncReport({
    required this.flutter,
    required this.web,
    required this.shared,
    required this.flutterOnly,
    required this.webOnly,
    required this.retired,
    required this.classNameMismatches,
    required this.matchRate,
  });

  /// Contract to implementation, Flutter side.
  final Map<String, Implementation> flutter;

  /// Contract to implementation, Web side.
  final Map<String, Implementation> web;

  /// Contracts implemented on both platforms.
  final List<String> shared;

  /// Contracts implemented only in `coui_flutter`, obligation still live.
  final List<String> flutterOnly;

  /// Contracts implemented only in `coui_web`, obligation still live.
  final List<String> webOnly;

  /// Single-platform contracts whose declaration is `@Deprecated`.
  ///
  /// Listed rather than dropped: an exclusion nobody can see reads as
  /// "parity is complete" when one side has in fact been removed.
  final List<String> retired;

  /// Shared contracts whose implementing class is named differently.
  final Map<String, String> classNameMismatches;

  /// Share of contracts implemented on both platforms, as a percentage.
  final double matchRate;

  /// Serializes this report for `--json` output.
  Map<String, dynamic> toJson() => {
    'summary': {
      'flutter_contracts': flutter.length,
      'web_contracts': web.length,
      'shared': shared.length,
      'flutter_only': flutterOnly.length,
      'web_only': webOnly.length,
      'retired_deprecated': retired.length,
      'class_name_mismatches': classNameMismatches.length,
      'match_rate': '${matchRate.toStringAsFixed(1)}%',
    },
    'shared_contracts': shared,
    'flutter_only': flutterOnly
        .map((c) => flutter[c]!.toJson())
        .toList(growable: false),
    'web_only': webOnly.map((c) => web[c]!.toJson()).toList(growable: false),
    'retired_deprecated': retired
        .map((c) => (flutter[c] ?? web[c]!).toJson())
        .toList(growable: false),
    'class_name_mismatches': classNameMismatches,
  };
}

// ---------------------------------------------------------------------------
// Source scanning
// ---------------------------------------------------------------------------

/// Collects `contract → implementation` for every class under [packageSrc].
///
/// When more than one class implements the same contract the shortest name
/// wins: internal helpers (`XxxState`, `XxxRenderer`) are longer than the
/// public widget they support.
Map<String, Implementation> scanImplementations(Directory packageSrc) {
  final found = <String, Implementation>{};
  // `.../packages/<pkg>/lib/src` → repo root is four levels up.
  final root = packageSrc.parent.parent.parent.parent.path;

  final files = packageSrc
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final relative = file.path.startsWith(root)
        ? file.path.substring(root.length + 1)
        : file.path;

    for (final header in _kClassHeader.allMatches(file.readAsStringSync())) {
      final className = header.group(1)!;
      final clause = header.group(2)!;
      final at = clause.indexOf('implements');
      if (at < 0) continue;

      // Read from the `implements` keyword on — an `extends` superclass or a
      // `with` mixin never names a contract.
      for (final ref in _kContractRef.allMatches(clause.substring(at))) {
        final contract = ref.group(1)!;
        final existing = found[contract];
        if (existing == null || className.length < existing.className.length) {
          found[contract] = Implementation(
            contract: contract,
            className: className,
            path: relative,
          );
        }
      }
    }
  }

  return found;
}

/// Whether the declaration starting at [declLine] carries `@Deprecated`.
///
/// Walks the leading trivia backwards. Doc comments and other annotations are
/// stepped over; the walk stops at the first line that can only be a
/// preceding *statement* (one ending in `;` or `}`), so a deprecated member
/// further up the file is never read as deprecating this declaration.
bool isDeprecatedBefore(List<String> lines, int declLine) {
  final floor = declLine - _kTriviaScanLimit;
  for (var i = declLine - 1; i >= 0 && i >= floor; i--) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    if (line.startsWith('//') ||
        line.startsWith('*') ||
        line.startsWith('/*')) {
      continue;
    }
    if (line.startsWith('@')) {
      if (_kDeprecatedAnnotation.hasMatch(line)) return true;
      // A different annotation — keep walking; `@Deprecated` may sit above it.
      continue;
    }
    // A multi-line annotation's argument lines reach here. Anything that ends
    // a statement or a block cannot be one, so the trivia ends there.
    if (line.endsWith(';') || line.endsWith('}')) return false;
  }

  return false;
}

/// Collects contracts declared `@Deprecated` under [contractsDir].
///
/// Derived from the declaration itself rather than a hand-maintained
/// exclusion table: a list of retired contracts would go stale the moment one
/// was un-deprecated or actually deleted, and nothing would notice.
Set<String> scanDeprecatedContracts(Directory contractsDir) {
  final deprecated = <String>{};
  if (!contractsDir.existsSync()) return deprecated;

  final files = contractsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final source = file.readAsStringSync();
    if (!source.contains('Contract')) continue;
    final lines = source.split('\n');

    for (final decl in _kContractDecl.allMatches(source)) {
      final declLine = source.substring(0, decl.start).split('\n').length - 1;
      if (isDeprecatedBefore(lines, declLine)) {
        deprecated.add(decl.group(1)!);
      }
    }
  }

  return deprecated;
}

// ---------------------------------------------------------------------------
// Sync analysis
// ---------------------------------------------------------------------------

/// Compares the two platforms' contract implementations.
///
/// [deprecatedContracts] names contracts whose declaration is `@Deprecated`.
/// The parity obligation is the contract, so retiring the contract retires
/// the obligation: a deprecated contract left on one platform is a removal in
/// progress, not a gap. Such contracts leave the denominator, and are
/// reported separately so the exclusion stays visible.
SyncReport analyzeSync(
  Map<String, Implementation> flutter,
  Map<String, Implementation> web, {
  Set<String> deprecatedContracts = const {},
}) {
  final shared = <String>[];
  final flutterOnly = <String>[];
  final webOnly = <String>[];
  final retired = <String>[];
  final mismatches = <String, String>{};

  for (final contract in flutter.keys) {
    final webImpl = web[contract];
    if (webImpl == null) {
      (deprecatedContracts.contains(contract) ? retired : flutterOnly).add(
        contract,
      );
      continue;
    }
    shared.add(contract);
    final flutterName = flutter[contract]!.className;
    if (flutterName != webImpl.className) {
      mismatches[contract] =
          'flutter: $flutterName → web: ${webImpl.className}';
    }
  }

  for (final contract in web.keys) {
    if (flutter.containsKey(contract)) continue;
    (deprecatedContracts.contains(contract) ? retired : webOnly).add(contract);
  }

  shared.sort();
  flutterOnly.sort();
  webOnly.sort();
  retired.sort();

  final union = shared.length + flutterOnly.length + webOnly.length;
  final matchRate = union > 0
      ? (shared.length / union) * _kPercentMultiplier
      : 0.0;

  return SyncReport(
    flutter: flutter,
    web: web,
    shared: shared,
    flutterOnly: flutterOnly,
    webOnly: webOnly,
    retired: retired,
    classNameMismatches: mismatches,
    matchRate: matchRate,
  );
}

// ---------------------------------------------------------------------------
// Output formatters
// ---------------------------------------------------------------------------

/// Prints the human-readable report to stdout.
void printConsoleReport(SyncReport report) {
  final divider = '=' * _kDividerWidth;
  final sectionDivider = '-' * _kSectionDividerWidth;

  void line([String text = '']) => stdout.writeln(text);

  line(divider);
  line('  CoUI API Sync Report — contract implementation parity');
  line(divider);
  line();

  line('SUMMARY');
  line(sectionDivider);
  line('  Flutter contracts:   ${report.flutter.length}');
  line('  Web contracts:       ${report.web.length}');
  line('  Implemented on both: ${report.shared.length}');
  line('  Flutter-only:        ${report.flutterOnly.length}');
  line('  Web-only:            ${report.webOnly.length}');
  line('  Retired (deprecated):${report.retired.length}');
  line('  Class-name mismatch: ${report.classNameMismatches.length}');
  line('  Match rate:          ${report.matchRate.toStringAsFixed(1)}%');
  line();

  line('IMPLEMENTED ON BOTH (${report.shared.length})');
  line(sectionDivider);
  for (final contract in report.shared) {
    line('  + $contract → ${report.flutter[contract]!.className}');
  }

  if (report.flutterOnly.isNotEmpty) {
    line();
    line('FLUTTER-ONLY — unimplemented on Web (${report.flutterOnly.length})');
    line(sectionDivider);
    for (final contract in report.flutterOnly) {
      final impl = report.flutter[contract]!;
      line('  - $contract → ${impl.className}  (${impl.path})');
    }
  }

  if (report.webOnly.isNotEmpty) {
    line();
    line('WEB-ONLY — unimplemented on Flutter (${report.webOnly.length})');
    line(sectionDivider);
    for (final contract in report.webOnly) {
      final impl = report.web[contract]!;
      line('  - $contract → ${impl.className}  (${impl.path})');
    }
  }

  if (report.retired.isNotEmpty) {
    line();
    line(
      'RETIRED — @Deprecated contract, parity obligation '
      'lifted (${report.retired.length})',
    );
    line(sectionDivider);
    for (final contract in report.retired) {
      final impl = report.flutter[contract] ?? report.web[contract]!;
      final side = report.flutter.containsKey(contract) ? 'flutter' : 'web';
      line('  ~ $contract → ${impl.className}  [$side only]  (${impl.path})');
    }
  }

  if (report.classNameMismatches.isNotEmpty) {
    line();
    line('CLASS-NAME MISMATCH (${report.classNameMismatches.length})');
    line(sectionDivider);
    for (final entry in report.classNameMismatches.entries) {
      line('  ${entry.key}: ${entry.value}');
    }
  }

  line();
  line(divider);
}

/// Prints the machine-readable report to stdout.
void printJsonReport(SyncReport report) {
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

/// Entry point.
void main(List<String> args) {
  final jsonOutput = args.contains('--json');
  final ciMode = args.contains('--ci');

  final scriptDir = File(Platform.script.toFilePath()).parent;
  final projectRoot = scriptDir.parent;

  final flutterSrc = Directory(
    '${projectRoot.path}/packages/coui_flutter/lib/src',
  );
  final webSrc = Directory('${projectRoot.path}/packages/coui_web/lib/src');
  final contractsSrc = Directory(
    '${projectRoot.path}/packages/coui_core/lib/src/component/contracts',
  );

  for (final dir in [flutterSrc, webSrc, contractsSrc]) {
    if (!dir.existsSync()) {
      stderr.writeln('Error: source directory not found at ${dir.path}');
      exit(2);
    }
  }

  final report = analyzeSync(
    scanImplementations(flutterSrc),
    scanImplementations(webSrc),
    deprecatedContracts: scanDeprecatedContracts(contractsSrc),
  );

  if (jsonOutput) {
    printJsonReport(report);
  } else {
    printConsoleReport(report);
  }

  if (!ciMode) return;

  if (report.matchRate < kCiThreshold) {
    stderr.writeln(
      'CI FAIL: ${report.flutterOnly.length} contract(s) unimplemented on Web, '
      '${report.webOnly.length} unimplemented on Flutter — '
      'match rate ${report.matchRate.toStringAsFixed(1)}% '
      'is below threshold $kCiThreshold%.',
    );
    exit(1);
  }

  if (report.classNameMismatches.isNotEmpty) {
    stderr.writeln(
      'CI FAIL: ${report.classNameMismatches.length} contract(s) are '
      'implemented under different class names on the two platforms.',
    );
    exit(1);
  }
}
