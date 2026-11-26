/// Per-instance style for `MediaQueryVisibility`.
library;

import 'package:coui_core/src/component/contracts/media_query_visibility/core_breakpoint.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:meta/meta.dart';

/// Immutable style describing the viewport bounds inside which a
/// `MediaQueryVisibility` shows its primary child.
///
/// `MediaQueryVisibility` has no chrome of its own — it is a layout
/// switch that conditionally renders one of two subtrees based on the
/// current viewport width. The style therefore carries the runtime
/// **bounds** rather than visual defaults. Pixel bounds
/// ([minWidth]/[maxWidth]) take precedence over `breakpoint` bounds
/// ([minBreakpoint]/[maxBreakpoint]) at every layer of the chain so
/// consumers can fine-tune above the breakpoint system.
///
/// ```text
/// design system default                              (no default — null)
///   → CoreMediaQueryVisibilityTheme.style           // 프로젝트 공통
///   → widget per-call bounds                         // 인스턴스별
/// ```
@immutable
class CoreMediaQueryVisibilityStyle
    implements CoreStyle<CoreMediaQueryVisibilityStyle> {
  /// Creates a [CoreMediaQueryVisibilityStyle].
  const CoreMediaQueryVisibilityStyle({
    this.minWidth,
    this.maxWidth,
    this.minBreakpoint,
    this.maxBreakpoint,
  });

  // ── Bounds ─────────────────────────────────────────────
  //
  // None of the four fields below has a `default*`, and none may get
  // one. `layer-mapping.md` calls a default-less field an orphan and
  // asks for the justification to be written down; this is it, and it
  // is one justification because all four collapse into the same pair
  // of effective bounds:
  //
  //     effectiveMin = minWidth ?? minBreakpoint?.minWidth ?? …
  //     effectiveMax = maxWidth ?? maxBreakpoint?.minWidth ?? …
  //
  // Both platforms then branch on that pair being ABSENT, and absence
  // is what "no bound on this side" is spelled as:
  //
  //   · Flutter — `resolved.minWidth != null && width < resolved.minWidth!`
  //     picks between the primary and the alternate subtree. A non-null
  //     default makes the comparison live on every instance, so every
  //     `MediaQueryVisibility` starts hiding its child below (or above)
  //     a width nobody asked for.
  //   · Web — `isUnbounded: effectiveMin == null && effectiveMax == null`
  //     decides whether a scoped `@container` rule is generated at all.
  //     A default makes it permanently false, which injects a `<style>`
  //     child and a `display:none` rule into markup that has neither
  //     today.
  //
  // A default here would not be a value this component was missing; it
  // would be a viewport range asserted over every caller that never
  // named one.

  /// Minimum viewport width (px) below which the alternate child shows.
  /// `null` = unbounded below — see the note above for why that has no
  /// `default*`.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Web's
  /// `isUnbounded: effectiveMin == null && effectiveMax == null` decides
  /// whether a scoped @container rule is generated AT ALL; a non-null
  /// default makes it permanently false, injecting a <style> child and a
  /// `display:none` rule into markup that has neither. Flutter's
  /// `resolved.minWidth != null && width < resolved.minWidth!` then picks
  /// between the primary and alternate subtree on every instance, so
  /// every MediaQueryVisibility starts hiding its child below a width
  /// nobody named.
  final double? minWidth;

  /// Maximum viewport width (px) above which the alternate child shows.
  /// `null` = unbounded above — see the note above.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Same
  /// single branch as minWidth — it is the other half of the
  /// `effectiveMax` chain that `isUnbounded` tests. A default bounds
  /// every instance above a width no caller asked for, and flips the Web
  /// short-circuit that today emits no <style> node.
  final double? maxWidth;

  /// Minimum breakpoint, read only when [minWidth] is unset (one
  /// position later in the same `??` chain, so it flips the same
  /// branch). `null` = unbounded below — see the note above.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Read one
  /// position later in the SAME `??` chain (`minWidth ??
  /// minBreakpoint?.minWidth ?? …`), so it flips the identical
  /// `isUnbounded` / `!= null` branch as minWidth. Absence here is how
  /// 'unbounded below' is spelled.
  final CoreBreakpoint? minBreakpoint;

  /// Maximum breakpoint, read only when [maxWidth] is unset. `null` =
  /// unbounded above — see the note above.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Tail of
  /// the `effectiveMax` chain; same flipped branch as above.
  final CoreBreakpoint? maxBreakpoint;

  @override
  CoreMediaQueryVisibilityStyle merge(CoreMediaQueryVisibilityStyle? other) {
    if (other == null) return this;
    return CoreMediaQueryVisibilityStyle(
      minWidth: other.minWidth ?? minWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      minBreakpoint: other.minBreakpoint ?? minBreakpoint,
      maxBreakpoint: other.maxBreakpoint ?? maxBreakpoint,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMediaQueryVisibilityStyle copyWith({
    double? minWidth,
    double? maxWidth,
    CoreBreakpoint? minBreakpoint,
    CoreBreakpoint? maxBreakpoint,
  }) => .new(
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    minBreakpoint: minBreakpoint ?? this.minBreakpoint,
    maxBreakpoint: maxBreakpoint ?? this.maxBreakpoint,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMediaQueryVisibilityStyle &&
          runtimeType == other.runtimeType &&
          minWidth == other.minWidth &&
          maxWidth == other.maxWidth &&
          minBreakpoint == other.minBreakpoint &&
          maxBreakpoint == other.maxBreakpoint;

  @override
  int get hashCode =>
      Object.hash(minWidth, maxWidth, minBreakpoint, maxBreakpoint);
}
