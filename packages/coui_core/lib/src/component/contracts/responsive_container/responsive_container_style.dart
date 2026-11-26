/// Per-instance style for `ResponsiveContainer`.
library;

import 'package:coui_core/src/component/contracts/breakpoint/breakpoint_tier.dart';
import 'package:coui_core/src/component/contracts/responsive_container/core_responsive_container_max_width.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ResponsiveContainer` should
/// render.
///
/// `CoreResponsiveContainerStyle` carries layout / dimensional flat
/// fields. Behavioural / content fields (`child`) stay flat on the
/// widget / contract.
///
/// ```text
/// design system default
///   → CoreResponsiveContainerTheme (legacy flat fields)
///   → CoreResponsiveContainerTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.responsiveContainerStyle                          // 인스턴스별
/// ```
@immutable
class CoreResponsiveContainerStyle
    implements CoreStyle<CoreResponsiveContainerStyle> {
  /// Creates a [CoreResponsiveContainerStyle].
  const CoreResponsiveContainerStyle({
    this.maxWidth,
    this.responsiveMaxWidth,
    this.centered,
    this.horizontalPadding,
  });

  /// Default max-width preset when neither the widget nor the theme
  /// provides one.
  static const CoreResponsiveContainerMaxWidth defaultMaxWidth = .xl;

  /// Default horizontal centring behaviour.
  static const bool defaultCentered = true;

  /// Default horizontal padding — `CoreSpace.space16` keeps the
  /// container snug against the layout grid by default.
  static const CoreEdgeInsets defaultHorizontalPadding =
      CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16);

  /// Max-width preset.
  final CoreResponsiveContainerMaxWidth? maxWidth;

  /// Per-[CoreBreakpointTier] max-width overrides — non-breaking
  /// extension over the static [maxWidth]. `null` preserves the static
  /// [maxWidth] behaviour unchanged; a non-null (possibly partial) map
  /// switches the effective max-width per tier, with each missing tier
  /// individually falling back to [maxWidth].
  ///
  /// No `default*`, deliberately, and the reason is stronger than a
  /// changed width. Both resolvers reach the tier through a null-aware
  /// index that short-circuits: the map is subscripted with
  /// `resolveBreakpoint(context).tier` under a `?[]`, falling back to
  /// the static resolution, so with the map absent `resolveBreakpoint`
  /// is **never called**.
  /// A default map would make every `ResponsiveContainer` observe the
  /// breakpoint, i.e. take a dependency it does not have today, and
  /// would silently outrank the static [maxWidth] on every tier the map
  /// names. `null` here is what "this caller never asked to be
  /// responsive" is spelled as; [maxWidth] carries the default
  /// ([defaultMaxWidth]) because it is the value that always applies.
  final Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>?
  responsiveMaxWidth;

  /// Whether the container is horizontally centred inside its parent.
  final bool? centered;

  /// Horizontal padding.
  final CoreEdgeInsets? horizontalPadding;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreResponsiveContainerStyle merge(CoreResponsiveContainerStyle? other) {
    if (other == null) return this;
    return CoreResponsiveContainerStyle(
      maxWidth: other.maxWidth ?? maxWidth,
      responsiveMaxWidth: other.responsiveMaxWidth ?? responsiveMaxWidth,
      centered: other.centered ?? centered,
      horizontalPadding: other.horizontalPadding ?? horizontalPadding,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreResponsiveContainerStyle copyWith({
    CoreResponsiveContainerMaxWidth? maxWidth,
    Map<CoreBreakpointTier, CoreResponsiveContainerMaxWidth>?
    responsiveMaxWidth,
    bool? centered,
    CoreEdgeInsets? horizontalPadding,
  }) {
    return CoreResponsiveContainerStyle(
      maxWidth: maxWidth ?? this.maxWidth,
      responsiveMaxWidth: responsiveMaxWidth ?? this.responsiveMaxWidth,
      centered: centered ?? this.centered,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreResponsiveContainerStyle &&
          runtimeType == other.runtimeType &&
          maxWidth == other.maxWidth &&
          _mapEquals(responsiveMaxWidth, other.responsiveMaxWidth) &&
          centered == other.centered &&
          horizontalPadding == other.horizontalPadding;

  @override
  int get hashCode => Object.hash(
    maxWidth,
    responsiveMaxWidth == null
        ? null
        : Object.hashAllUnordered(
            responsiveMaxWidth!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
    centered,
    horizontalPadding,
  );

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
