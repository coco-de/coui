// CoreStyle<T> is a generic-bound marker interface — used as the bound of
// `resolveStyleChain<T extends CoreStyle<T>>`. A top-level function cannot
// serve as a type bound, so the single-member abstract class is required.

/// Contract for a CoUI component's per-instance style.
library;

/// A platform-neutral per-instance style that participates in the
/// nested-merge resolution chain.
///
/// Every `CoreXxxStyle` (the per-instance style passed to a `*`
/// widget — e.g. `CoreFabStyle`, `CoreCardStyle`) implements
/// `CoreStyle<CoreXxxStyle>` so the merge chain can be expressed once,
/// generically:
///
/// ```text
/// CoreXxxStyle.defaultX  (design-system default)
///   → CoreXxxTheme.style (project theme)
///   → widget.xxxStyle    (instance override)
/// ```
///
/// The generic helper `resolveStyleChain<T extends CoreStyle<T>>`
/// folds that chain with [merge] — a resolver that uses it cannot
/// silently omit a merge step. See
/// `docs/tech-spec-resolver-style-contract.md`.
///
/// **Self-referential bound** — `T` is the implementing type itself
/// (`class CoreFabStyle implements CoreStyle<CoreFabStyle>`), so
/// [merge] is statically typed to return the concrete style.
///
/// **Not for variant chrome** — `CoreXxxVariantStyle` (the value type
/// of `defaultsByVariant` maps) does NOT implement this interface: it
/// is a per-variant chrome bundle, not a merge-chain participant.
abstract interface class CoreStyle<T extends CoreStyle<T>> {
  /// Returns a copy of this style with the non-null fields of [other]
  /// overriding the matching fields here. Nested style slots are
  /// merged recursively. Returns `this` unchanged when [other] is null.
  T merge(T? other);
}

/// Folds the nested-merge resolution chain for a [CoreStyle].
///
/// Starts from [base] (the design-system default — `const CoreXxxStyle()`)
/// and merges each non-null entry of [overrides] in order, lowest to
/// highest priority. Null entries are skipped, so resolvers pass the
/// theme / variant / instance overrides directly without `if` guards:
///
/// ```dart
/// final merged = resolveStyleChain(const CoreFabStyle(), [
///   fabTheme?.style,                    // project theme
///   fabTheme?.variantStyles?[variant],  // per-variant theme override
///   fabStyle,                           // widget instance override
/// ]);
/// ```
///
/// Because the chain is expressed once here, a resolver cannot silently
/// omit a merge step. See `docs/tech-spec-resolver-style-contract.md`.
T resolveStyleChain<T extends CoreStyle<T>>(T base, List<T?> overrides) {
  var merged = base;
  for (final override in overrides) {
    if (override != null) merged = merged.merge(override);
  }
  return merged;
}
