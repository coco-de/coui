library;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `SwitchField`.
///
/// Widget tree (`co_switch_field.dart` decides which optional branches
/// render):
///
/// ```text
/// Clickable (onPressed, enabled)
///   └─ Row
///        ├─ Expanded
///        │    └─ Column (mainAxisSize.min, crossAxisAlignment.start)
///        │         ├─ Text (label, labelTextStyle)
///        │         ├─ Gap (labelDescriptionGapStyle)  // rendered only when description != null
///        │         └─ Text (description, descriptionTextStyle)
///        │                                              // rendered only when description != null
///        ├─ Gap (labelToggleGapStyle)
///        └─ IgnorePointer
///             └─ Toggle (size, trackActiveColor, trackInactiveColor)
/// ```
///
/// Field grouping:
///
/// 1. **Nested gap slots** — [labelToggleGapStyle] /
///    [labelDescriptionGapStyle] forwarded straight to the `Gap`
///    widget (raw — `Gap` self-scales).
/// 2. **Paint-ready typography** — [labelTextStyle] /
///    [descriptionTextStyle] composed from the enabled / disabled
///    typography slot, ready to drop into `Text(style: ...)`.
/// 3. **Toggle pass-through chrome** — [size] / [activeColor] /
///    [inactiveColor] forwarded to `Toggle` (active/inactive as
///    [CoreColor] so the child runs its own conversion).
class ResolvedSwitchField {
  /// Creates a [ResolvedSwitchField].
  const ResolvedSwitchField({
    required this.size,
    required this.labelToggleGapStyle,
    required this.clickableStyle,
    required this.labelDescriptionGapStyle,
    required this.labelTextStyle,
    required this.descriptionTextStyle,
    required this.activeColor,
    required this.inactiveColor,
    required this.minHeight,
  });

  /// Resolved toggle size.
  final CoreComponentSize size;

  /// Nested [CoreGapStyle] slot forwarded to the `Gap` widget
  /// rendered between the label section and the toggle. Merged with
  /// [CoreSwitchFieldStyle.defaultLabelToggleGapStyle]. `Gap`
  /// self-scales, so this slot carries raw (pre-scaling) values.
  final CoreGapStyle labelToggleGapStyle;

  /// Nested [CoreClickableStyle] slot for the composed `Clickable` —
  /// design default (`CoreSwitchFieldStyle.defaultClickableStyle`,
  /// which keeps the Clickable's generic disabled fade off because the
  /// field paints its own disabled tokens) merged with the
  /// per-instance override, raw-forwarded to `Clickable(clickableStyle:)`.
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreGapStyle] slot forwarded to the `Gap` widget
  /// rendered between the label and the description inside the label
  /// section. Merged with
  /// [CoreSwitchFieldStyle.defaultLabelDescriptionGapStyle]. `Gap`
  /// self-scales, so this slot carries raw (pre-scaling) values.
  final CoreGapStyle labelDescriptionGapStyle;

  /// Paint-ready label [TextStyle] — enabled or disabled typography
  /// slot resolved with the colour overlay applied.
  final TextStyle labelTextStyle;

  /// Paint-ready description [TextStyle] — enabled or disabled
  /// typography slot resolved with the colour overlay applied.
  final TextStyle descriptionTextStyle;

  /// Active (on) track colour passed to `Toggle` (kept as
  /// [CoreColor] so the child's contract input runs its own
  /// `scheme.resolve(...).toValue()` step).
  final CoreColor activeColor;

  /// Inactive (off) track colour passed to `Toggle`.
  final CoreColor inactiveColor;

  /// Minimum height of the pressable row, already scaled.
  final double minHeight;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSwitchField] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.switchField.style
///   → widget.switchFieldStyle
/// ```
///
/// [enabled] picks between the enabled and disabled typography slot
/// pairs (`defaultLabelTextStyle` / `defaultDisabledLabelTextStyle` and
/// their description counterparts).
ResolvedSwitchField resolveSwitchField(
  BuildContext context, {
  required bool enabled,
  CoreSwitchFieldStyle? switchFieldStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final sfTheme = theme.coreComponentTheme?.switchField;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreSwitchFieldStyle(), [
    sfTheme?.style,
    switchFieldStyle,
  ]);

  // ─── Resolved chrome ──────────────────────────────────
  final size = merged.size ?? CoreSwitchFieldStyle.defaultSize;
  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override and forward the resulting slot straight
  // to the `Gap` widget. `Gap` self-scales, so we forward raw
  // (pre-scaling) values.
  final labelToggleGapStyle = CoreSwitchFieldStyle.defaultLabelToggleGapStyle
      .merge(merged.labelToggleGapStyle);
  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest).
  final clickableStyle = CoreSwitchFieldStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );
  final labelDescriptionGapStyle = CoreSwitchFieldStyle
      .defaultLabelDescriptionGapStyle
      .merge(
        merged.labelDescriptionGapStyle,
      );
  final activeColor =
      merged.activeColor ?? CoreSwitchFieldStyle.defaultActiveColor;
  final inactiveColor =
      merged.inactiveColor ?? CoreSwitchFieldStyle.defaultInactiveColor;
  final minHeight =
      (merged.minHeight ?? CoreSwitchFieldStyle.defaultMinHeight) * scaling;

  // ─── Paint-ready typography ───────────────────────────
  // Slot selection — enabled / disabled default + caller override.
  final labelDefault = enabled
      ? CoreSwitchFieldStyle.defaultLabelTextStyle
      : CoreSwitchFieldStyle.defaultDisabledLabelTextStyle;
  final labelOverride = enabled
      ? merged.labelTextStyle
      : merged.disabledLabelTextStyle;
  final descriptionDefault = enabled
      ? CoreSwitchFieldStyle.defaultDescriptionTextStyle
      : CoreSwitchFieldStyle.defaultDisabledDescriptionTextStyle;
  final descriptionOverride = enabled
      ? merged.descriptionTextStyle
      : merged.disabledDescriptionTextStyle;

  // Single-primitive conversion: compose the token-backed role default
  // with the per-instance override, then materialise in one
  // `.toValue(theme:)` step — the conversion resolves the typography
  // role token AND the slot's own `color` field through the active
  // scheme (`scheme.resolve(...).toValue()`), so dark mode tracks. No
  // hand-rolled `theme.typography.resolve` / colour overlay.
  final labelTextStyle = labelDefault
      .merge(labelOverride)
      .toValue(theme: theme);
  final descriptionTextStyle = descriptionDefault
      .merge(descriptionOverride)
      .toValue(theme: theme);

  // ─── Compose paint-ready resolved object ──────────────
  return ResolvedSwitchField(
    size: size,
    labelToggleGapStyle: labelToggleGapStyle,
    clickableStyle: clickableStyle,
    labelDescriptionGapStyle: labelDescriptionGapStyle,
    labelTextStyle: labelTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    minHeight: minHeight,
  );
}
