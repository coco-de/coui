/// Per-instance style for `Diff`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/badge/badge_style.dart';
import 'package:coui_core/src/component/contracts/focus_outline/focus_outline_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Diff` should render.
///
/// `CoreDiffStyle` carries chrome / dimensional / layout flat fields.
/// Behavioural fields (`before`, `after`, `interactive`,
/// `onPositionChanged`, `ariaLabel`, `beforeLabel`, `afterLabel`) stay
/// flat on the widget.
///
/// All design-system defaults live here as `static const` so Flutter and
/// Web share one definition.
///
/// ```text
/// design system default (CoreDiffStyle.defaultX)
///   → CoreDiffTheme.style                           // 프로젝트 공통
///   → parent component slot override
///   → widget.diffStyle                              // 인스턴스별
/// ```
///
/// The split line, its handle and the two label chips float over the
/// compared content, which can be any picture. All of them take the opaque
/// `surfaceRaised` fill. The line and the handle also cast `sm`, and only
/// the handle states an edge (`outlineVariant`). A label chip states its
/// fill and ink and takes the rest from `Badge`. The handle's fill, edge
/// and cast are the ones the carousel's previous / next buttons wear, so a
/// control laid over an image reads the same wherever it appears.
@immutable
class CoreDiffStyle implements CoreStyle<CoreDiffStyle> {
  /// Creates a [CoreDiffStyle].
  const CoreDiffStyle({
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.resizerColor,
    this.resizerWidth,
    this.resizerShadow,
    this.handleSize,
    this.handleHitSize,
    this.handleColor,
    this.handleBorderColor,
    this.handleBorderWidth,
    this.handleShadow,
    this.handleHoverShadow,
    this.handlePressedShadow,
    this.handlePressedScale,
    this.handleTransitionDuration,
    this.handleIconStyle,
    this.labelInset,
    this.labelBadgeStyle,
    this.focusOutlineStyle,
    this.aspectRatio,
    this.initialPosition,
    this.keyboardStep,
    this.keyboardPageStep,
  });

  // ─── Design-system defaults ──────────────────────────────────────
  // Variant-independent defaults live as static const here so Flutter
  // and Web resolvers read the same single source of truth.

  /// Default container border radius — daisyUI parity (lg = radius16).
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius16,
  );

  /// Default colour of the frame's edge — `outlineSubtle`.
  ///
  /// The compared content can be a picture of any tone, including one
  /// that is the page's own colour, and then the frame has no edge at
  /// all. A hairline in the lightest outline step gives it one without
  /// competing with the content.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Default width of the frame's edge, drawn inside the frame (it takes
  /// from the content, it does not grow the frame).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default resizer line width (logical px). 2 px matches daisyUI's
  /// `divide-x` weight.
  static const double defaultResizerWidth = CoreSpace.space2;

  /// Default resizer line colour — `surfaceRaised`.
  ///
  /// A raised face, not an outline step: `outline` is a mid-grey, and over
  /// a picture of a similar tone a line in it disappears. In a light theme
  /// the raised surface is the light end, and its cast
  /// ([defaultResizerShadow]) does the separating on a light picture. In a
  /// dark theme it is a dark face, so the line is faint over a dark picture
  /// and the handle is the main cue.
  static const CoreColor defaultResizerColor = CoreColor.token(
    CoreColors.surfaceRaised,
  );

  /// Default cast of the resizer line — the `sm` step of the shadow scale.
  ///
  /// In a light theme the line is lighter than most of what it divides, so
  /// the cast is what keeps it readable against a light picture. Single
  /// source shared by Flutter (`BoxShadow`) and Web (`box-shadow`).
  static const List<CoreShadowLayer> defaultResizerShadow = CoreShadow.sm;

  /// Default diameter of the handle (logical px) — forty.
  ///
  /// A control-sized disc: large enough to read as the thing to grab and
  /// to hold the glyph with room around it, small enough not to cover the
  /// content it sits over.
  static const double defaultHandleSize = CoreSpace.space40;

  /// Default width of the area that accepts a grab around the handle
  /// (logical px) — forty-four, running the full height of the frame.
  ///
  /// Wider than the 24 px floor WCAG 2.2 sets for a pointer target (2.5.8)
  /// and wider than the disc itself, so the line can be taken without
  /// aiming at it. It is drawn nowhere — the disc and the line are the
  /// only visible parts.
  static const double defaultHandleHitSize = CoreSpace.space44;

  /// Default fill of the handle — `surfaceRaised`, fully opaque.
  ///
  /// Opaque for the reason the carousel's buttons are: an alpha fill let
  /// whatever was underneath show through the glyph, and the cast only
  /// reads as the shadow of a body when the body is solid.
  static const CoreColor defaultHandleColor = CoreColor.token(
    CoreColors.surfaceRaised,
  );

  /// Default colour of the handle's edge — `outlineVariant`.
  ///
  /// The fill is a raised surface and can sit on a picture of its own
  /// tone, where the edge keeps the disc readable if the cast alone would
  /// not. That holds only where this token differs from the fill: in CoUI's
  /// dark theme the two resolve to the same colour, so the edge does not
  /// show there.
  static const CoreColor defaultHandleBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default width of the handle's edge, drawn inside the disc.
  static const double defaultHandleBorderWidth = CoreStrokeWidth.stroke1;

  /// Default cast of the handle at rest — `sm`.
  static const List<CoreShadowLayer> defaultHandleShadow = CoreShadow.sm;

  /// Default cast of the handle while the pointer is over it — `md`, one
  /// step up from rest.
  ///
  /// Hover is how a pointer user learns the disc moves; the lift says it
  /// without a colour change that would have to survive every picture.
  static const List<CoreShadowLayer> defaultHandleHoverShadow = CoreShadow.md;

  /// Default cast of the handle while it is being dragged — `xs`, one step
  /// down from rest.
  ///
  /// Held, the disc is pressed toward the content: it shrinks
  /// ([defaultHandlePressedScale]) and its shadow tightens.
  static const List<CoreShadowLayer> defaultHandlePressedShadow = CoreShadow.xs;

  /// Default scale of the handle while it is being dragged — 94 %.
  ///
  /// A dimensionless ratio of the handle's own size, not part of the
  /// spacing scale.
  static const double defaultHandlePressedScale = 0.94;

  /// Default time the handle takes to change between rest, hover and
  /// pressed — `CoreDuration.fast`.
  ///
  /// Covers the cast and the scale together, so a hover lift and a press
  /// shrink move as one gesture instead of two.
  static const Duration defaultHandleTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default glyph on the handle — sixteen, in the foreground colour
  /// `onSurface`. The glyph itself (`chevrons-left-right`) is the
  /// widget's: it says "this moves sideways", which is what the handle is.
  static const CoreIconStyle defaultHandleIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default distance of a label chip from the frame's top corner —
  /// twelve on every side.
  ///
  /// The frame's own radius is sixteen, so a chip at twelve sits inside
  /// the curve instead of being cut by it.
  static const CoreEdgeInsets defaultLabelInset = CoreEdgeInsets.all(
    CoreSpace.space12,
  );

  /// Default look of a label chip — a raised face (`surfaceRaised` fill,
  /// `onSurface` text), the same face as the handle.
  ///
  /// Only what diverges from the badge's own defaults is stated. The chip
  /// is a `Badge`, which draws the pill, the padding and the label type.
  static const CoreBadgeStyle defaultLabelBadgeStyle = CoreBadgeStyle(
    backgroundColor: CoreColor.token(CoreColors.surfaceRaised),
    foregroundColor: CoreColor.token(CoreColors.onSurface),
  );

  /// Default focus ring of the handle — a full pill around the disc, with
  /// the ring's gap band turned on.
  ///
  /// The handle floats over a picture, so the colour beside the ring is
  /// whatever the picture shows and the ring needs the two-colour band
  /// (`CoreFocusRing.opaqueOffsetColor`) to stay readable on any of them.
  /// Width, gap and colour stay null so `FocusOutline`'s own defaults
  /// (two and two) apply.
  static const CoreFocusOutlineStyle defaultFocusOutlineStyle =
      CoreFocusOutlineStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        offsetColor: CoreFocusRing.opaqueOffsetColor,
      );

  /// Default canvas aspect ratio (width / height) — daisyUI 16/9 frame.
  /// Pure geometric ratio, not part of the spacing scale.
  ///
  /// Written as the evaluated quotient rather than `16 / 9`: the value is
  /// the same double (`16 / 9 == 1.7777777777777777` — the literal is the
  /// shortest round-trip form of that bit pattern), but a constant-folded
  /// expression is invisible to readers that walk the declaration without
  /// evaluating it, so the ratio never left this file. The `16 / 9` intent
  /// stays in this comment, which is where the other ratio defaults in
  /// this codebase (`defaultInitialPosition` / `defaultKeyboardStep`)
  /// already keep theirs.
  static const double defaultAspectRatio = 1.7777777777777777;

  /// Default initial split position (`[0, 1]`). 0.5 places the resizer
  /// at the centre.
  static const double defaultInitialPosition = 0.5;

  /// Default position delta applied per arrow-key press (`[0, 1]`
  /// units). 0.05 = 5 % of the frame width per tap.
  static const double defaultKeyboardStep = 0.05;

  /// Default position delta applied per Page Up / Page Down press
  /// (`[0, 1]` units). 0.1 = 10 % of the frame width — twice an arrow
  /// press, the ratio the ARIA slider pattern asks of a larger step.
  static const double defaultKeyboardPageStep = 0.1;

  // ─── Fields ──────────────────────────────────────────────────────

  /// Container border radius override.
  final CoreBorderRadius? borderRadius;

  /// Frame edge colour override. `null` → [defaultBorderColor].
  final CoreColor? borderColor;

  /// Frame edge width override (logical px). `0` draws no edge. `null` →
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Resizer line colour override. `null` → [defaultResizerColor].
  final CoreColor? resizerColor;

  /// Resizer line width override (logical px, pre-scaling). `null` →
  /// [defaultResizerWidth].
  final double? resizerWidth;

  /// Resizer line cast override. An empty list draws no cast. `null` →
  /// [defaultResizerShadow].
  final List<CoreShadowLayer>? resizerShadow;

  /// Handle diameter override (logical px, pre-scaling). `null` →
  /// [defaultHandleSize].
  final double? handleSize;

  /// Width of the area that accepts a grab around the handle (logical
  /// px, pre-scaling). `null` → [defaultHandleHitSize].
  final double? handleHitSize;

  /// Handle fill override. `null` → [defaultHandleColor].
  final CoreColor? handleColor;

  /// Handle edge colour override. `null` → [defaultHandleBorderColor].
  final CoreColor? handleBorderColor;

  /// Handle edge width override (logical px). `null` →
  /// [defaultHandleBorderWidth].
  final double? handleBorderWidth;

  /// Handle cast at rest. An empty list draws no cast. `null` →
  /// [defaultHandleShadow].
  final List<CoreShadowLayer>? handleShadow;

  /// Handle cast while the pointer is over it. `null` →
  /// [defaultHandleHoverShadow].
  final List<CoreShadowLayer>? handleHoverShadow;

  /// Handle cast while it is being dragged. `null` →
  /// [defaultHandlePressedShadow].
  final List<CoreShadowLayer>? handlePressedShadow;

  /// Scale of the handle while it is being dragged, as a ratio of its own
  /// size. `1` turns the shrink off. `null` → [defaultHandlePressedScale].
  final double? handlePressedScale;

  /// Time the handle takes to change between rest, hover and pressed.
  /// `null` → [defaultHandleTransitionDuration].
  final Duration? handleTransitionDuration;

  /// Look of the glyph on the handle — size and colour. Laid over
  /// [defaultHandleIconStyle].
  final CoreIconStyle? handleIconStyle;

  /// Distance of the label chips from the frame's top corners. Laid over
  /// [defaultLabelInset].
  final CoreEdgeInsets? labelInset;

  /// Look of the label chips, handed to the `Badge` each one is drawn
  /// with. Laid over [defaultLabelBadgeStyle].
  final CoreBadgeStyle? labelBadgeStyle;

  /// Focus ring of the handle. Laid over [defaultFocusOutlineStyle].
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Container aspect ratio (width / height) — it sets the box's
  /// proportions.
  final double? aspectRatio;

  /// Where the split bar starts (0.0 — 1.0), applied at first render.
  /// When `interactive: true`, dragging moves it from there.
  final double? initialPosition;

  /// Position delta applied per arrow-key press (`[0, 1]` units)
  /// override. Falls back to [defaultKeyboardStep] when null.
  final double? keyboardStep;

  /// Position delta applied per Page Up / Page Down press (`[0, 1]`
  /// units) override. Falls back to [defaultKeyboardPageStep] when null.
  final double? keyboardPageStep;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are merged
  /// recursively.
  @override
  CoreDiffStyle merge(CoreDiffStyle? other) {
    if (other == null) return this;
    return CoreDiffStyle(
      borderRadius: other.borderRadius ?? borderRadius,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      resizerColor: other.resizerColor ?? resizerColor,
      resizerWidth: other.resizerWidth ?? resizerWidth,
      resizerShadow: other.resizerShadow ?? resizerShadow,
      handleSize: other.handleSize ?? handleSize,
      handleHitSize: other.handleHitSize ?? handleHitSize,
      handleColor: other.handleColor ?? handleColor,
      handleBorderColor: other.handleBorderColor ?? handleBorderColor,
      handleBorderWidth: other.handleBorderWidth ?? handleBorderWidth,
      handleShadow: other.handleShadow ?? handleShadow,
      handleHoverShadow: other.handleHoverShadow ?? handleHoverShadow,
      handlePressedShadow: other.handlePressedShadow ?? handlePressedShadow,
      handlePressedScale: other.handlePressedScale ?? handlePressedScale,
      handleTransitionDuration:
          other.handleTransitionDuration ?? handleTransitionDuration,
      handleIconStyle:
          handleIconStyle?.merge(other.handleIconStyle) ??
          other.handleIconStyle,
      labelInset: other.labelInset ?? labelInset,
      labelBadgeStyle:
          labelBadgeStyle?.merge(other.labelBadgeStyle) ??
          other.labelBadgeStyle,
      focusOutlineStyle:
          focusOutlineStyle?.merge(other.focusOutlineStyle) ??
          other.focusOutlineStyle,
      aspectRatio: other.aspectRatio ?? aspectRatio,
      initialPosition: other.initialPosition ?? initialPosition,
      keyboardStep: other.keyboardStep ?? keyboardStep,
      keyboardPageStep: other.keyboardPageStep ?? keyboardPageStep,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreDiffStyle copyWith({
    CoreBorderRadius? borderRadius,
    CoreColor? borderColor,
    double? borderWidth,
    CoreColor? resizerColor,
    double? resizerWidth,
    List<CoreShadowLayer>? resizerShadow,
    double? handleSize,
    double? handleHitSize,
    CoreColor? handleColor,
    CoreColor? handleBorderColor,
    double? handleBorderWidth,
    List<CoreShadowLayer>? handleShadow,
    List<CoreShadowLayer>? handleHoverShadow,
    List<CoreShadowLayer>? handlePressedShadow,
    double? handlePressedScale,
    Duration? handleTransitionDuration,
    CoreIconStyle? handleIconStyle,
    CoreEdgeInsets? labelInset,
    CoreBadgeStyle? labelBadgeStyle,
    CoreFocusOutlineStyle? focusOutlineStyle,
    double? aspectRatio,
    double? initialPosition,
    double? keyboardStep,
    double? keyboardPageStep,
  }) {
    return CoreDiffStyle(
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      resizerColor: resizerColor ?? this.resizerColor,
      resizerWidth: resizerWidth ?? this.resizerWidth,
      resizerShadow: resizerShadow ?? this.resizerShadow,
      handleSize: handleSize ?? this.handleSize,
      handleHitSize: handleHitSize ?? this.handleHitSize,
      handleColor: handleColor ?? this.handleColor,
      handleBorderColor: handleBorderColor ?? this.handleBorderColor,
      handleBorderWidth: handleBorderWidth ?? this.handleBorderWidth,
      handleShadow: handleShadow ?? this.handleShadow,
      handleHoverShadow: handleHoverShadow ?? this.handleHoverShadow,
      handlePressedShadow: handlePressedShadow ?? this.handlePressedShadow,
      handlePressedScale: handlePressedScale ?? this.handlePressedScale,
      handleTransitionDuration:
          handleTransitionDuration ?? this.handleTransitionDuration,
      handleIconStyle: handleIconStyle ?? this.handleIconStyle,
      labelInset: labelInset ?? this.labelInset,
      labelBadgeStyle: labelBadgeStyle ?? this.labelBadgeStyle,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      initialPosition: initialPosition ?? this.initialPosition,
      keyboardStep: keyboardStep ?? this.keyboardStep,
      keyboardPageStep: keyboardPageStep ?? this.keyboardPageStep,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDiffStyle &&
          runtimeType == other.runtimeType &&
          borderRadius == other.borderRadius &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          resizerColor == other.resizerColor &&
          resizerWidth == other.resizerWidth &&
          _shadowEq(resizerShadow, other.resizerShadow) &&
          handleSize == other.handleSize &&
          handleHitSize == other.handleHitSize &&
          handleColor == other.handleColor &&
          handleBorderColor == other.handleBorderColor &&
          handleBorderWidth == other.handleBorderWidth &&
          _shadowEq(handleShadow, other.handleShadow) &&
          _shadowEq(handleHoverShadow, other.handleHoverShadow) &&
          _shadowEq(handlePressedShadow, other.handlePressedShadow) &&
          handlePressedScale == other.handlePressedScale &&
          handleTransitionDuration == other.handleTransitionDuration &&
          handleIconStyle == other.handleIconStyle &&
          labelInset == other.labelInset &&
          labelBadgeStyle == other.labelBadgeStyle &&
          focusOutlineStyle == other.focusOutlineStyle &&
          aspectRatio == other.aspectRatio &&
          initialPosition == other.initialPosition &&
          keyboardStep == other.keyboardStep &&
          keyboardPageStep == other.keyboardPageStep;

  @override
  int get hashCode => Object.hashAll([
    borderRadius,
    borderColor,
    borderWidth,
    resizerColor,
    resizerWidth,
    _shadowHash(resizerShadow),
    handleSize,
    handleHitSize,
    handleColor,
    handleBorderColor,
    handleBorderWidth,
    _shadowHash(handleShadow),
    _shadowHash(handleHoverShadow),
    _shadowHash(handlePressedShadow),
    handlePressedScale,
    handleTransitionDuration,
    handleIconStyle,
    labelInset,
    labelBadgeStyle,
    focusOutlineStyle,
    aspectRatio,
    initialPosition,
    keyboardStep,
    keyboardPageStep,
  ]);

  static int? _shadowHash(List<CoreShadowLayer>? layers) =>
      layers == null ? null : Object.hashAll(layers);

  static bool _shadowEq(List<CoreShadowLayer>? a, List<CoreShadowLayer>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
