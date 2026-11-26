/// Per-instance style for `Frame`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/frame/core_frame_border_style.dart';
import 'package:coui_core/src/component/contracts/frame/core_frame_elevation.dart';
import 'package:coui_core/src/component/contracts/stacks/core_clip_behavior.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/dashed_border.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Frame` should render.
///
/// `CoreFrameStyle` is **platform-neutral** (Epic #1415 option D). Every
/// chrome / dimensional field is exposed as a nullable override so a
/// single style object can flow through the nested-merge chain:
///
/// ```text
/// design system default
///   → CoreFrameTheme.style                           // 프로젝트 공통
///   → parent component slot override
///   → widget.frameStyle                              // 인스턴스별
/// ```
@immutable
class CoreFrameStyle implements CoreStyle<CoreFrameStyle> {
  /// Creates a [CoreFrameStyle].
  const CoreFrameStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.dashLength,
    this.dashSpacing,
    this.borderStyle,
    this.borderRadius,
    this.elevation,
    this.padding,
    this.clipBehavior,
    this.duration,
    this.shadowBaseColor,
  });

  // ─── Design-system defaults ────────────────────
  //
  // Single source shared by the Flutter and Web `resolveFrame`
  // helpers so the two platforms cannot silently diverge.

  /// Default border style when neither widget nor theme supplies one.
  /// A border renders only when the caller supplies a `borderColor`
  /// (the cross-platform opt-in gate), so this only shapes an opted-in
  /// stroke.
  static const CoreFrameBorderStyle defaultBorderStyle = .solid;

  /// Default dash segment length — the shared [CoreDashedBorder]
  /// baseline, rendered identically by the Flutter dash painter and the
  /// Web SVG `stroke-dasharray` overlay.
  static const double defaultDashLength = CoreDashedBorder.dashLength;

  /// Default gap between dash segments — see [defaultDashLength].
  static const double defaultDashSpacing = CoreDashedBorder.dashGap;

  /// Default base colour the elevation / `boxShadow` layers tint against.
  /// Single source for both platforms' shadow-base lookup so neither
  /// hardcodes a `cs.shadow` reference.
  static const CoreColor defaultShadowBaseColor = CoreColor.token(
    CoreColors.shadow,
  );

  /// Default shadow elevation preset.
  static const CoreFrameElevation defaultElevation = .none;

  /// Default clip behaviour — `hardEdge` matches `<div>` clipping
  /// (CSS `overflow:hidden`) so visuals match across platforms when a
  /// radius or border is applied.
  static const CoreClipBehavior defaultClipBehavior = .hardEdge;

  /// Default chrome-transition duration — `zero` means an unanimated
  /// frame, so a `Frame` only animates once a caller asks it to. Both
  /// platforms read this: Flutter feeds it to its implicit animation,
  /// Web gates its `transition` emit on a non-zero duration.
  static const Duration defaultDuration = Duration.zero;

  /// Background colour override.
  ///
  /// No paired `default*`: the fill is opt-in. Flutter reads `null` in the
  /// `hasChrome` test (no fill *and* no `AnimatedContainer` wrapper) and
  /// Web emits no `background-color`. A default would give every frame both.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Feeds
  /// Flutter's `hasChrome` test — the branch that decides whether an
  /// AnimatedContainer wraps the content AT ALL — and Web emits
  /// `background-color` only when set. A default gives every Frame a
  /// chrome wrapper plus a painted fill.
  final CoreColor? backgroundColor;

  /// Border colour override — and the opt-in gate for the border itself.
  ///
  /// No paired `default*`: `borderColor != null` is what makes Flutter
  /// build a `Border.all` and Web add the `border` class (or mount the
  /// dashed SVG overlay). A default would stroke every frame, the plain
  /// layout ones included. [borderWidth] / [borderStyle] only shape a
  /// stroke this field has already opted into.
  ///
  /// **Deliberately has no `default*` — absence is the design.** It IS
  /// the border's opt-in gate: `resolvedBorderColor != null` is what
  /// builds Flutter's Border.all and adds Web's `border` class / mounts
  /// the dashed SVG overlay. A default strokes every Frame, including the
  /// plain layout ones.
  final CoreColor? borderColor;

  /// Border width (logical px), used once [borderColor] turns the border
  /// on. `null` means the platform's own thinnest stroke — a hairline on
  /// Flutter, the `border` utility's width on the Web.
  ///
  /// No paired `default*`: inside the [borderColor] gate, `null` means the
  /// platform's own thinnest stroke — Flutter `Border.all(width: 0)` (a
  /// hairline), Web the `border` utility's width with no inline override. A
  /// default would change both. The dashed overlay's
  /// `CoreDashedBorder.strokeWidth` fallback is branch-local: an SVG
  /// `<rect>` needs a concrete stroke.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Inside
  /// the borderColor gate, null means the platform's thinnest stroke:
  /// Flutter paints Border.all(width: 0) (hairline), Web leaves the
  /// `border` utility's width alone and emits no inline border-width. A
  /// default changes the hairline AND adds an inline width to every
  /// bordered frame. (The dashed overlay's `??
  /// CoreDashedBorder.strokeWidth` is branch-local — lifting it would
  /// leak into the solid path.)
  final double? borderWidth;

  /// Dash segment length when `borderStyle` is dashed (logical px).
  /// `null` → [defaultDashLength].
  final double? dashLength;

  /// Gap between dash segments (logical px). `null` → [defaultDashSpacing].
  final double? dashSpacing;

  /// Border style — solid / dashed / dotted / none.
  final CoreFrameBorderStyle? borderStyle;

  /// Border radius.
  ///
  /// No paired `default*`: `null` is square corners *and* one of the
  /// `hasChrome` inputs on Flutter; Web emits no `border-radius`. A default
  /// would round every frame and wrap the plain layout ones in chrome.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Another
  /// `hasChrome` input on Flutter; Web emits `border-radius` only when
  /// set. A default rounds every Frame and wraps the plain layout ones in
  /// chrome.
  final CoreBorderRadius? borderRadius;

  /// Shadow elevation preset.
  final CoreFrameElevation? elevation;

  /// Inner padding. `null` adds no padding at all.
  ///
  /// No paired `default*`: `Frame` doubles as the plain layout primitive,
  /// so `null` means no padding wrapper — Flutter skips `Padding`, Web
  /// emits no rule. Even `CoreEdgeInsets.zero` would not be inert; it puts
  /// an inline `padding` on every frame's root.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Flutter
  /// guards with `resolvedPadding != null && != EdgeInsets.zero` (skips
  /// the Padding widget); Web emits no `padding` rule. Even
  /// CoreEdgeInsets.zero is not inert — it would put an inline padding on
  /// every frame root, changing the DOM.
  final CoreEdgeInsets? padding;

  /// Clip behaviour.
  final CoreClipBehavior? clipBehavior;

  /// Animation duration for changes to the frame's look — its fill,
  /// border, corners and shadow.
  final Duration? duration;

  /// Shadow base tint override. `null` defers to [defaultShadowBaseColor].
  final CoreColor? shadowBaseColor;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreFrameStyle merge(CoreFrameStyle? other) {
    if (other == null) return this;
    return CoreFrameStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      dashLength: other.dashLength ?? dashLength,
      dashSpacing: other.dashSpacing ?? dashSpacing,
      borderStyle: other.borderStyle ?? borderStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      elevation: other.elevation ?? elevation,
      padding: other.padding ?? padding,
      clipBehavior: other.clipBehavior ?? clipBehavior,
      duration: other.duration ?? duration,
      shadowBaseColor: other.shadowBaseColor ?? shadowBaseColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFrameStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    double? dashLength,
    double? dashSpacing,
    CoreFrameBorderStyle? borderStyle,
    CoreBorderRadius? borderRadius,
    CoreFrameElevation? elevation,
    CoreEdgeInsets? padding,
    CoreClipBehavior? clipBehavior,
    Duration? duration,
    CoreColor? shadowBaseColor,
  }) {
    return CoreFrameStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      dashLength: dashLength ?? this.dashLength,
      dashSpacing: dashSpacing ?? this.dashSpacing,
      borderStyle: borderStyle ?? this.borderStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      elevation: elevation ?? this.elevation,
      padding: padding ?? this.padding,
      clipBehavior: clipBehavior ?? this.clipBehavior,
      duration: duration ?? this.duration,
      shadowBaseColor: shadowBaseColor ?? this.shadowBaseColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFrameStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          dashLength == other.dashLength &&
          dashSpacing == other.dashSpacing &&
          borderStyle == other.borderStyle &&
          borderRadius == other.borderRadius &&
          elevation == other.elevation &&
          padding == other.padding &&
          clipBehavior == other.clipBehavior &&
          duration == other.duration &&
          shadowBaseColor == other.shadowBaseColor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    dashLength,
    dashSpacing,
    borderStyle,
    borderRadius,
    elevation,
    padding,
    clipBehavior,
    Object.hash(duration, shadowBaseColor),
  );
}
