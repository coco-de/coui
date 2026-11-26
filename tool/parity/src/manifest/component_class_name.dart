/// `date-picker` → `DatePicker`. Used to name the generic root finder
/// (`rootProbeSpec` in `../model/probe_spec.dart`) — a real Flutter class
/// name lookup would need the widget's actual export, which a pure-Dart
/// manifest derivation cannot import (it would need `coui_flutter`, and
/// the class name is not always this mechanical — see
/// `code-style/naming.md`'s Flutter-first rename table). Close enough for
/// a probe hint; the capture backend that actually resolves it is free to
/// special-case the handful that differ.
///
/// Shared by `parity_manifest.dart` (#3604) and `pruned_pairs.dart`
/// (#3620) so both matrix derivations name a component's class the same
/// way — a second copy of this mapping drifting from the first would mean
/// the nightly sweep's pruned-combination captures resolve a different
/// Flutter widget than the PR-gate manifest's captures of the same slug.
String pascalCaseComponentSlug(String slug) => slug
    .split('-')
    .map((s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1))
    .join();
