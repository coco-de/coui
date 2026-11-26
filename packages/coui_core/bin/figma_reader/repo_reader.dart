/// Repo-wide reader — recursively globs every `.dart` file under
/// `packages/coui_core/lib/src/component/contracts/`, parses each, and
/// builds a single global registry keyed by class name.
///
/// Recursive glob (not a `*_style.dart` filename filter, not a
/// `{slug}/{slug}_style.dart` path assumption) is the point: convention #4
/// (`style_reader.dart`'s doc comment) is that a component's identity is
/// its *class name*, not the file it lives in — `scrollview_style.dart`
/// declaring `CoreScrollViewInterceptorStyle` is exactly the shape a
/// filename-pattern reader would miss.
///
/// The registry is global (not per-file) because cross-class references
/// (`CoreFocusOutlineStyle.defaultRingWidth` read from `badge`, `button`,
/// `clickable`, `text_area`, `text_field`) can only resolve once every
/// class in the package has been discovered — this is convention #3's
/// "2차 해소는 전역" (`core/style-contract.md`).
///
/// ## Two roots, two different questions
///
/// "Which classes are components?" and "which classes can a default point
/// at?" are not the same set, and conflating them cost 23 fields. A Style
/// default is free to name any class in the package — `CoreShadow.md`,
/// `CoreFocusRing.ringWidth`, `CoreDashedBorder.dashLength` — and those
/// three live in `effect/` and `shape/`, outside `contracts/`. Resolution
/// stopped at `classRegistry[owner] == null` and returned no value at all,
/// so the field reached `components.json` empty and the plugin painted its
/// own fallback. Nothing failed: an unresolvable ref and a field the author
/// deliberately left null look identical downstream.
///
/// So [readContracts] parses two roots. [RepoReadResult.classesByName] stays
/// exactly what it was — the component universe, `contracts/` only, which is
/// what `buildDoc` iterates. [RepoReadResult.resolutionRegistry] is the
/// wider one, and only the emitter's class registry uses it. Widening the
/// discovery map instead would have made every primitive namespace try to
/// become a component.
///
/// Contracts win on a name collision. There are none today (575 classes
/// inside, 123 outside, zero shared names), but the precedence has to be
/// stated rather than left to iteration order, because the failure it
/// prevents — a reference class shadowing a Style class — would change what
/// a component's defaults resolve to without changing anything visible.
library;

import 'dart:io';

import 'style_reader.dart';

/// Result of walking the whole `contracts/` tree.
final class RepoReadResult {
  const RepoReadResult({
    required this.classesByName,
    required this.resolutionRegistry,
    required this.filesParsed,
    required this.filesFailed,
  });

  /// Every discovered class, keyed by class name. A name collision (two
  /// classes with the same name in different files) overwrites — this
  /// codebase's class names are unique by construction (Dart itself would
  /// refuse to compile two top-level classes of the same name in the same
  /// library import graph), so this reader doesn't defend against it
  /// beyond last-write-wins, which would surface as a wrong-looking census
  /// count rather than a silent, undetectable loss.
  final Map<String, DiscoveredClass> classesByName;

  /// Every class a *default* may reference — [classesByName] plus the rest
  /// of `coui_core/lib/src`, contracts winning on a name collision.
  ///
  /// This is the resolution universe and nothing else: `buildDoc` must keep
  /// iterating [classesByName], or `CoreShadow` becomes a component.
  final Map<String, DiscoveredClass> resolutionRegistry;

  final int filesParsed;

  /// Paths that failed to parse or threw. Non-empty means the "0 실패"
  /// completion criterion isn't met — callers should treat this reader's
  /// output as unreliable if it is.
  final List<String> filesFailed;
}

/// Walks every `.dart` file under [contractsRoot] (default:
/// `packages/coui_core/lib/src/component/contracts` relative to
/// [repoRoot]) and returns the merged, deterministic result.
///
/// File order is sorted lexicographically by path before parsing —
/// `Directory.listSync()`'s order is filesystem-dependent (readdir order),
/// and schema v2's determinism requirement (`components.json` byte-stable
/// across two consecutive runs) depends on this reader's output not
/// silently reordering when the OS's directory-entry order does.
/// [referenceRoot] (default: `packages/coui_core/lib/src`) is parsed too, and
/// its classes populate [RepoReadResult.resolutionRegistry] only. Pass the
/// same path as [contractsRoot] to keep the two sets identical.
RepoReadResult readContracts({
  required String repoRoot,
  String? contractsRoot,
  String? referenceRoot,
}) {
  final root = Directory(
    contractsRoot ?? '$repoRoot/packages/coui_core/lib/src/component/contracts',
  );
  if (!root.existsSync()) {
    throw StateError('contracts root not found: ${root.path}');
  }

  final classesByName = <String, DiscoveredClass>{};
  final failed = <String>[];
  var parsed = 0;

  List<String> dartFilesUnder(Directory dir) =>
      dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.path)
          .toList()
        ..sort();

  for (final path in dartFilesUnder(root)) {
    final source = File(path).readAsStringSync();
    final classes = readCompilationUnit(path, source);
    if (classes == null) {
      failed.add(path);
      continue;
    }
    parsed++;
    for (final cls in classes) {
      classesByName[cls.name] = cls;
    }
  }

  // Reference classes first, contracts merged over them — a Style class must
  // never be shadowed by a same-named class outside `contracts/`.
  final resolution = <String, DiscoveredClass>{};
  final refDir = Directory(
    referenceRoot ?? '$repoRoot/packages/coui_core/lib/src',
  );
  if (refDir.existsSync()) {
    for (final path in dartFilesUnder(refDir)) {
      // Already read as a contract — re-parsing would double `filesParsed`
      // and make the freshness guard's file count disagree with reality.
      if (path.startsWith('${root.path}${Platform.pathSeparator}')) continue;
      final classes = readCompilationUnit(path, File(path).readAsStringSync());
      // A reference file that will not parse is not a failure of this
      // reader's contract: it holds no component. It costs the refs that
      // pointed into it, which show up as an empty field in the coverage
      // guard — visible, and not worth failing the whole export over.
      if (classes == null) continue;
      for (final cls in classes) {
        resolution[cls.name] = cls;
      }
    }
  }
  resolution.addAll(classesByName);

  return RepoReadResult(
    classesByName: classesByName,
    resolutionRegistry: resolution,
    filesParsed: parsed,
    filesFailed: failed,
  );
}
