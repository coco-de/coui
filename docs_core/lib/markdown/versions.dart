/// Pure parsing/rendering for the docs-site version-snapshot manifest —
/// `docs_core/content/_data/versions.json`.
///
/// CoUI ships from git tags, not pub.dev (`publish_to: none`), so a
/// consumer who pinned an older tag has no pub.dev version dropdown to
/// find matching docs. This manifest is the single source of truth for
/// which historical `docs_site` builds are archived under
/// `/versions/{tag}/` — `VersionSwitcher` (the Jaspr component) renders
/// it, and `tool/build_version_snapshot.sh` appends to it when it builds
/// a new snapshot. Kept `dart:io`-free so both sides can unit test
/// against plain JSON strings.
library;

import 'dart:convert';

/// One archived docs-site snapshot.
class VersionSnapshot {
  const VersionSnapshot({required this.tag, required this.label, required this.date});

  /// The `release-please` git tag this snapshot was built from, e.g.
  /// `coui_flutter-v0.128.1` — also the path segment under `/versions/`.
  final String tag;

  /// Short display label, e.g. `0.128.1`.
  final String label;

  /// ISO date (`YYYY-MM-DD`) the snapshot was built.
  final String date;

  Map<String, Object?> toJson() => {'tag': tag, 'label': label, 'date': date};

  @override
  bool operator ==(Object other) =>
      other is VersionSnapshot && other.tag == tag && other.label == label && other.date == date;

  @override
  int get hashCode => Object.hash(tag, label, date);
}

/// Parses `versions.json`'s `{"versions": [...]}` shape.
///
/// Newest-first is not enforced by the parser — `sortedNewestFirst` below
/// does that explicitly so the switcher's display order does not silently
/// depend on manifest-file edit order.
///
/// Throws [FormatException] on malformed JSON or a missing/wrong-typed
/// `versions` key — a manifest the switcher cannot read is a build error,
/// not a "render nothing" situation, since it would otherwise silently
/// hide every archived version from readers who need them.
List<VersionSnapshot> parseVersionManifest(String jsonSource) {
  final decoded = jsonDecode(jsonSource);
  if (decoded is! Map || decoded['versions'] is! List) {
    throw const FormatException('versions.json must be {"versions": [...]}."');
  }
  return [
    for (final entry in decoded['versions'] as List)
      if (entry is Map)
        VersionSnapshot(
          tag: entry['tag'] as String,
          label: entry['label'] as String,
          date: entry['date'] as String,
        ),
  ];
}

/// Renders the manifest back to the on-disk JSON shape (used by the
/// snapshot script when it appends an entry) — pretty-printed and
/// newline-terminated so the committed diff is one line per version.
String renderVersionManifest(List<VersionSnapshot> versions) {
  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert({
    'versions': [for (final v in versions) v.toJson()],
  })}\n';
}

/// Newest-first by [VersionSnapshot.date], ties broken by [VersionSnapshot.tag]
/// (stable, deterministic — two snapshots built the same day do not
/// reorder between runs).
List<VersionSnapshot> sortedNewestFirst(List<VersionSnapshot> versions) {
  final copy = [...versions];
  copy.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.tag.compareTo(a.tag);
  });
  return copy;
}

/// Adds or replaces the entry for [snapshot].tag (re-archiving the same
/// tag updates its date/label rather than duplicating a row) and returns
/// the result newest-first.
List<VersionSnapshot> withSnapshot(List<VersionSnapshot> versions, VersionSnapshot snapshot) {
  final withoutExisting = versions.where((v) => v.tag != snapshot.tag).toList();
  return sortedNewestFirst([...withoutExisting, snapshot]);
}
