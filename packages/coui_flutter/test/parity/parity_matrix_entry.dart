// #3652 — a minimal, package-local parse of `tool/parity/manifest.dart`'s
// output JSON shape.
//
// This file deliberately does NOT import `tool/parity/src/model/
// matrix_entry.dart` (`MatrixEntry`) or `probe_spec.dart` (`ProbeSpec`) —
// `coui_flutter` is a published Flutter package and cannot depend on the
// workspace-root `tool/` scripts (a `dart:io`-only, non-Flutter package
// tree). The contract between the manifest producer and this consumer is
// the **JSON shape** (`MatrixEntry.toJson()`/`ProbeSpec.toJson()`), not a
// shared Dart type — the same "flutter_property_snapshot.dart mirrors
// PropertySnapshot.toJson() without importing it" pattern this directory
// already uses.
//
// Only the fields this capture backend actually needs are parsed: `key`,
// `component`, `variant`, `theme`, `surfaceStyle`, and each probe's `role` +
// `flutterFinder`, requested `fields`, and optional Native source contract.
// Historical property capture still reads every available field; requested
// fields and source declarations drive separate additive observations only.
// `webSelector` remains Web-only.
import 'dart:convert';
import 'dart:io';

/// One `ProbeSpec` from the manifest, reduced to what this backend reads.
class ParityProbeSpec {
  const ParityProbeSpec({
    required this.role,
    required this.flutterFinder,
    this.fields = const {},
    this.nativeBoxSource,
    this.boxObservationSource,
  });

  factory ParityProbeSpec.fromJson(Map<String, Object?> json) =>
      ParityProbeSpec(
        role: json['role']! as String,
        flutterFinder: json['flutterFinder']! as String,
        fields: (json['fields'] as List? ?? const []).cast<String>().toSet(),
        nativeBoxSource: json['nativeBoxSource'] as String?,
        boxObservationSource: (json['boxObservationSource'] as Map?)
            ?.cast<String, Object?>(),
      );

  final String role;
  final Set<String> fields;
  final String? nativeBoxSource;
  final Map<String, Object?>? boxObservationSource;

  /// A wire-format string, e.g. `byType:Button` — see
  /// `tool/parity/src/model/probe_spec.dart`'s `rootProbeSpec` doc comment.
  /// This backend does not resolve it into a `find.byType(...)` call (the
  /// registry-returned widget subtree already *is* the root — no
  /// string→Type lookup needed to find it); it is instead used only as a
  /// post-hoc sanity check (`tester.allWidgets` contains a widget whose
  /// `runtimeType.toString()` equals the class name this names) — see
  /// `flutter_capture_matrix_test.dart`'s `_checkFlutterFinderPresence`.
  final String flutterFinder;

  /// The `byType:<ClassName>` suffix, or `null` if [flutterFinder] isn't in
  /// that wire format (defensive — every manifest producer today emits
  /// exactly this format via `rootProbeSpec`, but a malformed/future value
  /// should degrade to "sanity check skipped", not crash the capture).
  String? get byTypeClassName {
    const prefix = 'byType:';
    return flutterFinder.startsWith(prefix)
        ? flutterFinder.substring(prefix.length)
        : null;
  }
}

/// One `MatrixEntry` from the manifest, reduced to what this backend needs
/// to render + name a capture.
class ParityMatrixEntry {
  const ParityMatrixEntry({
    required this.key,
    required this.component,
    required this.variant,
    required this.dark,
    required this.surfaceStyleName,
    required this.probes,
  });

  factory ParityMatrixEntry.fromJson(Map<String, Object?> json) {
    final themeName = json['theme']! as String;
    final dark = switch (themeName) {
      'light' => false,
      'dark' => true,
      _ => throw FormatException('알 수 없는 theme: $themeName'),
    };
    return ParityMatrixEntry(
      key: json['key']! as String,
      component: json['component']! as String,
      variant: json['variant']! as String,
      dark: dark,
      surfaceStyleName: json['surfaceStyle']! as String,
      probes: [
        for (final raw in (json['probes']! as List))
          ParityProbeSpec.fromJson((raw as Map).cast()),
      ],
    );
  }

  final String key;
  final String component;
  final String variant;
  final bool dark;

  /// `CoreSurfaceStyleId.name` — kept as a raw string here (this file has
  /// no `coui_core`/`coui_flutter` import) and resolved against
  /// `CoreSurfaceStyleId.values` by the caller, which already imports the
  /// enum for theme construction.
  final String surfaceStyleName;

  final List<ParityProbeSpec> probes;

  /// The single `role == 'root'` probe every manifest entry carries today
  /// (`probe_spec.dart`'s doc comment: "이 매니페스트는 항상 root 를
  /// 포함해야 한다") — `null` only for a malformed manifest, which the
  /// caller treats as a per-entry infra failure rather than a crash.
  ParityProbeSpec? get rootProbe {
    for (final probe in probes) {
      if (probe.role == 'root') return probe;
    }
    return null;
  }
}

/// Parses a `tool/parity/manifest.dart`-shaped `{"entries": [...]}` JSON
/// file into [ParityMatrixEntry]s. Returns an empty list (not an error) for
/// a well-formed-but-empty manifest — `manifest.dart --changed-from` writes
/// exactly that when no Tier1 component changed, and an empty matrix is a
/// legitimate "nothing to capture" run, not a failure.
List<ParityMatrixEntry> parseParityManifest(File manifestFile) {
  final decoded =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
  final rawEntries = decoded['entries']! as List;
  return [
    for (final raw in rawEntries)
      ParityMatrixEntry.fromJson((raw as Map).cast()),
  ];
}
