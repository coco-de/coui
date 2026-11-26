/// Where the component/tier filter handed to `ParityManifest.resolve` came
/// from.
///
/// The matrix derivation cannot judge on its own whether coming back empty
/// is a mistake — that depends entirely on who wrote the filter, which only
/// the caller knows. `changed_components.dart` already draws this line for
/// the selection itself (`ChangedComponentNone` is "a confident nothing to
/// check", explicitly *not* "a filter that failed to match anything"); this
/// carries the same distinction through the one step that happens after the
/// selection is known — intersecting it with the requested tier.
///
/// Stated as a fact about provenance rather than as permission to skip the
/// check. A caller granting itself `allowEmpty: true` reads like a legitimate
/// option and disables the guard wherever it is written; a caller claiming
/// [derivedFromDiff] for a hand-typed filter is lying about where its input
/// came from, which is visible at the call site.
enum ComponentFilterSource {
  /// Typed by a person: `--components` / `--tier` on the command line.
  ///
  /// Selecting nothing means the slug or the tier is wrong — nobody asks for
  /// an empty matrix on purpose, and passing the gate on one would hide the
  /// typo behind a green check. This is the default because forgetting to
  /// state the provenance should fail loudly, not silently widen what the
  /// gate accepts.
  handTyped,

  /// Derived from a diff: `--changed-from`.
  ///
  /// Selecting nothing means the changed components all sit outside the
  /// requested tier — a fact about the diff, not a mistake. Tier1 is
  /// `{control, menu, overlay}` plus a named form set, so any PR touching
  /// only `display` / `layout` / `navigation` lands here by construction.
  /// The caller reports what it skipped; the gate is not silent about it.
  derivedFromDiff,
}
