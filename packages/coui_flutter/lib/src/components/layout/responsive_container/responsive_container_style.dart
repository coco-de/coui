import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/breakpoint/breakpoint_style.dart';
import 'package:coui_flutter/src/theme/theme.dart';
import 'package:coui_flutter/src/util.dart';
import 'package:coui_flutter/src/util/core_to_flutter.dart';
import 'package:flutter/widgets.dart';

/// Resolved configuration for `ResponsiveContainer`, computed from
/// the resolve-priority chain
/// `widget parameter > CoreComponentTheme.responsiveContainer > defaults`.
///
/// ```text
/// ResponsiveContainer (Align? > ConstrainedBox > SizedBox > Padding)
///   ├─ maxWidth        → ConstrainedBox.constraints.maxWidth  (paint-ready double)
///   ├─ centered        → wrap with Align(topCenter)?           (bool)
///   └─ horizontalPadding → Padding.padding                     (paint-ready EdgeInsets)
/// ```
class ResolvedResponsiveContainer {
  /// Creates a [ResolvedResponsiveContainer].
  const ResolvedResponsiveContainer({
    required this.maxWidth,
    required this.centered,
    required this.horizontalPadding,
  });

  /// Paint-ready max-width in logical pixels, already multiplied by
  /// `theme.scaling`. `double.infinity` means "stretch to parent"
  /// (matches `max-w-full` on the web).
  final double maxWidth;

  /// Whether the container is horizontally centred inside its parent.
  final bool centered;

  /// Paint-ready horizontal padding, already multiplied by
  /// `theme.scaling`.
  final EdgeInsets horizontalPadding;
}

/// Resolves [ResolvedResponsiveContainer] from widget inputs,
/// the shared [CoreResponsiveContainerTheme], and defaults.
///
/// The widget's [padding] wins when supplied so callers can pass
/// asymmetric padding; otherwise the merged style value, then the
/// design-system default applies.
///
/// [responsiveMaxWidth] (widget param, wins over
/// `CoreResponsiveContainerStyle.responsiveMaxWidth` — same
/// widget-first convention as [maxWidth]/[centered]/[padding] above)
/// is Story H's non-breaking extension: when the merged map is
/// non-null, the current [CoreBreakpointTier] (observed once via the
/// existing `resolveBreakpoint` — Story B/C, no new measurement
/// logic) selects the effective preset, individually falling back to
/// the static [maxWidth] resolution for any tier missing from the
/// map. When the merged map is `null` this whole branch is skipped
/// entirely, so a caller that never sets [responsiveMaxWidth] takes
/// the exact pre-existing code path (no breakpoint observation, no
/// behaviour change).
ResolvedResponsiveContainer resolveResponsiveContainer(
  BuildContext context, {
  required CoreResponsiveContainerMaxWidth? maxWidth,
  Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>? responsiveMaxWidth,
  required bool? centered,
  required CoreEdgeInsets? padding,
  CoreResponsiveContainerStyle? responsiveContainerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final themeStyle = theme.coreComponentTheme?.responsiveContainer?.style;

  final merged = resolveStyleChain(const CoreResponsiveContainerStyle(), [
    themeStyle,
    responsiveContainerStyle,
  ]);

  final resolvedMaxWidth = styleValue(
    widgetValue: maxWidth,
    themeValue: merged.maxWidth,
    defaultValue: CoreResponsiveContainerStyle.defaultMaxWidth,
  );
  final resolvedCentered = styleValue(
    widgetValue: centered,
    themeValue: merged.centered,
    defaultValue: CoreResponsiveContainerStyle.defaultCentered,
  );
  // The widget's explicit `padding` wins; otherwise fall back to the
  // merged style value, then the design-system default.
  final resolvedHorizontalPadding =
      padding ??
      merged.horizontalPadding ??
      CoreResponsiveContainerStyle.defaultHorizontalPadding;

  // Widget param wins over the merged style slot (same convention as
  // maxWidth/centered/padding above).
  final effectiveResponsiveMaxWidth =
      responsiveMaxWidth ?? merged.responsiveMaxWidth;

  // `resolvedMaxWidth` is reused unchanged as the static value AND as
  // the per-tier fallback when a tier is missing from the map. The
  // null-aware index (`?[]`) short-circuits — `resolveBreakpoint` is
  // never called when `effectiveResponsiveMaxWidth` is null, so a
  // caller that never sets `responsiveMaxWidth` takes the exact
  // pre-existing code path (no breakpoint observation performed).
  final effectiveMaxWidthPreset =
      effectiveResponsiveMaxWidth?[resolveBreakpoint(context).tier] ??
      resolvedMaxWidth;

  // `null` max-width on the enum = stretch (matches `max-w-full`).
  final paintReadyMaxWidth = effectiveMaxWidthPreset.maxWidth != null
      ? effectiveMaxWidthPreset.maxWidth! * scaling
      : double.infinity;
  final paintReadyHorizontalPadding =
      resolvedHorizontalPadding.toValue(geometry: theme.geometry) * scaling;

  return ResolvedResponsiveContainer(
    maxWidth: paintReadyMaxWidth,
    centered: resolvedCentered,
    horizontalPadding: paintReadyHorizontalPadding,
  );
}
