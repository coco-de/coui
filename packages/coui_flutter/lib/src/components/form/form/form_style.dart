library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Form`.
///
/// Widget tree (`co_form.dart`):
///
/// ```text
/// optional Data.inherit (when controller != null)
///   └─ Column (mainAxisSize.min, crossAxisAlignment.stretch,
///              spacing: rowSpacing)              // native paint-API
///        ├─ children[0]
///        ├─ children[1]
///        ├─ …
///        └─ Row (mainAxisAlignment.end, spacing: actionSpacing)  // showActions == true only
///             ├─ secondaryAction                 // showSecondaryAction == true only
///             └─ primaryAction
/// ```
///
/// `Form` is a pure layout container — its only chrome is the inter-item
/// spacing. The vertical spacer between adjacent children (and the
/// actions row itself, appended as one more child) is rendered via
/// `Column.spacing` (Flutter 3.41+) which consumes a raw double; the
/// spacer between the two action buttons is `Row.spacing`. The resolver
/// applies `theme.scaling` to both here so the widget reads a
/// paint-ready value (no widget-side `* scaling` Anti-C).
class ResolvedForm {
  /// Creates a [ResolvedForm].
  const ResolvedForm({required this.rowSpacing, required this.actionSpacing});

  /// Inter-item spacing (logical px, scaling pre-applied) between adjacent
  /// form rows. Flows directly into `Column.spacing` — the widget reads
  /// this value directly without re-multiplying by scaling.
  final double rowSpacing;

  /// Spacing (logical px, scaling pre-applied) between the two action
  /// buttons in the actions row. Flows directly into `Row.spacing` —
  /// same paint-ready shape as [rowSpacing].
  final double actionSpacing;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedForm] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreFormStyle.defaultRowSpacing)
///   → theme.coreComponentTheme.form.style
///   → widget.formStyle
/// ```
ResolvedForm resolveForm(
  BuildContext context, {
  double? rowSpacing,
  double? actionSpacing,
  CoreFormStyle? formStyle,
}) {
  final theme = Theme.of(context);
  final formTheme = theme.coreComponentTheme?.form;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreFormStyle(), [
    formTheme?.style,
    formStyle,
    if (rowSpacing != null || actionSpacing != null)
      CoreFormStyle(rowSpacing: rowSpacing, actionSpacing: actionSpacing),
  ]);

  // ─── Native-API spacing (paint-ready, scaling pre-applied) ─────
  // `rowSpacing` / `actionSpacing` flow directly into `Column.spacing` /
  // `Row.spacing` — raw double native paint-API arguments. Per-instance
  // override wins, else the design-system default. Scaling is Stage2
  // EMIT, so the `* scaling` product is materialised in a local var
  // (like a colour `.resolve().toValue()`); the return is a bare
  // mapping (no `* scaling` in the literal).
  final scaling = theme.scaling;
  final rowSpacingValue =
      theme.geometry.space(
        merged.rowSpacing ?? CoreFormStyle.defaultRowSpacing,
      ) *
      scaling;
  final actionSpacingValue =
      theme.geometry.space(
        merged.actionSpacing ?? CoreFormStyle.defaultActionSpacing,
      ) *
      scaling;

  return ResolvedForm(
    rowSpacing: rowSpacingValue,
    actionSpacing: actionSpacingValue,
  );
}
