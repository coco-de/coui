/// Appends (or replaces) one entry in `content/_data/versions.json` —
/// the manifest `VersionSwitcher` renders and `tool/build_version_snapshot.sh`
/// calls into after it finishes building a snapshot.
///
/// Usage (run from `docs_core/`, matching this package's other CLI
/// conventions):
///   dart run bin/record_version_snapshot.dart {tag} {label} {date}
///   dart run bin/record_version_snapshot.dart coui_flutter-v0.128.1 0.128.1 2026-07-25
library;

import 'dart:io';

import 'package:docs_core/markdown/versions.dart';

void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln('Usage: dart run bin/record_version_snapshot.dart {tag} {label} {date}');
    exit(64); // EX_USAGE
  }
  final [tag, label, date] = args;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
    stderr.writeln('date must be YYYY-MM-DD, got "$date"');
    exit(64);
  }

  final file = File('content/_data/versions.json');
  final existing = file.existsSync() ? parseVersionManifest(file.readAsStringSync()) : const <VersionSnapshot>[];
  final updated = withSnapshot(existing, VersionSnapshot(tag: tag, label: label, date: date));
  file.writeAsStringSync(renderVersionManifest(updated));

  // ignore: avoid_print
  print('✓ recorded $tag ($label, $date) — ${updated.length} version(s) in manifest');
}
