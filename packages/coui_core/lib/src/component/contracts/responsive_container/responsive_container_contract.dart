import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_tier.dart';
import 'package:coui_core/src/component/contracts/responsive_container/core_responsive_container_max_width.dart';
import 'package:coui_core/src/component/contracts/responsive_container/responsive_container_style.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';

/// Platform-agnostic contract for `ResponsiveContainer`.
///
/// The container provides a horizontally-centred max-width wrapper with
/// consistent horizontal padding — the layout primitive Tailwind's
/// `container` and Flutter's `ConstrainedBox + Center` patterns both
/// address. Padding is expressed as the platform-neutral
/// [CoreEdgeInsets]; the resolver converts to the platform's native
/// padding primitive at render time.
///
/// Type parameters:
///   - [W]    — `Widget` on Flutter, `Component` on Web (child type).
abstract interface class CoreResponsiveContainerContract<W> {
  /// The content rendered inside the container. Required on both
  /// platforms — a responsive container without a child has no visual
  /// role.
  W get child;

  /// Maximum width preset. `null` falls back to the theme default
  /// (typically [CoreResponsiveContainerMaxWidth.xl]).
  CoreResponsiveContainerMaxWidth? get maxWidth;

  /// Per-[CoreBreakpointTier] max-width overrides — non-breaking
  /// extension over the static [maxWidth] (Story H, Decision Log K-3).
  ///
  /// When non-null, the effective max-width switches per breakpoint
  /// tier at render time instead of staying static at [maxWidth].
  /// Each tier individually falls back when missing from the map:
  /// `responsiveMaxWidth[tier] ?? maxWidth ?? <design-system default>`
  /// — mirroring `CoreBreakpointContract.defaultBoundaries`'s per-key
  /// fallback (no crash on a partial map). `null` (the default)
  /// preserves the pre-existing static [maxWidth] behaviour
  /// unchanged — no breakpoint observation is performed at all.
  Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>?
  get responsiveMaxWidth;

  /// Whether the container is horizontally centred inside its parent.
  /// `null` falls back to the theme default (`true`).
  bool? get centered;

  /// Horizontal padding. `null` falls back to the theme default
  /// (`CoreSpace.space16` on both platforms).
  CoreEdgeInsets? get padding;

  /// Per-instance layout / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreResponsiveContainerTheme (legacy flat fields)
  ///   → CoreResponsiveContainerTheme.style
  ///   → parent component slot override
  ///   → widget.responsiveContainerStyle
  /// ```
  CoreResponsiveContainerStyle? get responsiveContainerStyle;
}
