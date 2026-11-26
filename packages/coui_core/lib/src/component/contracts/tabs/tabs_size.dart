/// Size variants for `Tabs` / its tab items.
library;

/// Size options for a `Tabs` bar and its individual tab items.
///
/// Narrowed from the shared 6-step `CoreComponentSize` to the 3 rungs the
/// 2026-09-14 redesign spec states — no navigation surface in the kit uses
/// more than 3 (Command / Select / Chip / MenuItem / CommandItem /
/// ThemeController all narrowed the same way), and `xs`/`xl`/`xl2` had 0
/// live instances anywhere in the file when the canvas was audited. The
/// wider enum stays live for the many components that DO span the full
/// ladder — this is a per-component narrowing, not a kit-wide one.
enum CoreTabsSize {
  /// Small — the 32dp rung: a 32dp `pill` track holding 28dp tabs, or
  /// 32dp `underline` tabs. The `pill` variant draws `labelMedium` (13);
  /// the `underline` variant draws its own `labelXl` on every rung.
  sm,

  /// Medium — the 40dp rung: a 40dp `pill` track holding 36dp tabs, or
  /// 40dp `underline` tabs. The `pill` variant draws `labelLarge` (14);
  /// the `underline` variant draws its own `labelXl` on every rung. The
  /// default.
  md,

  /// Large — the 48dp rung: a 48dp `pill` track holding 44dp tabs, or
  /// 48dp `underline` tabs. The `pill` variant draws `labelXl` (15), the
  /// role the `underline` variant draws on every rung.
  lg;

  /// Widget default size. Flutter / Web `Tabs` constructors reference
  /// this so neither platform diverges silently.
  static const CoreTabsSize defaultSize = md;
}
