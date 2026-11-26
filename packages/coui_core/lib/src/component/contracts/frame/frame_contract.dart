import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/alignment.dart';
import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/frame/core_cross_axis_alignment.dart';
import 'package:coui_core/src/component/contracts/frame/core_cursor.dart';
import 'package:coui_core/src/component/contracts/frame/core_flex_fit.dart';
import 'package:coui_core/src/component/contracts/frame/core_frame_a11y.dart';
import 'package:coui_core/src/component/contracts/frame/core_frame_border_style.dart';
import 'package:coui_core/src/component/contracts/frame/core_frame_direction.dart';
import 'package:coui_core/src/component/contracts/frame/core_frame_elevation.dart';
import 'package:coui_core/src/component/contracts/frame/core_gradient.dart';
import 'package:coui_core/src/component/contracts/frame/core_image_source.dart';
import 'package:coui_core/src/component/contracts/frame/core_main_axis_alignment.dart';
import 'package:coui_core/src/component/contracts/frame/frame_style.dart';
import 'package:coui_core/src/component/contracts/stacks/core_clip_behavior.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';

/// Platform-independent contract for `Frame` — the unified
/// low-level layout primitive.
///
/// `Frame` is the cross-platform analogue of Flutter `Container` /
/// `Row` / `Column` / `Wrap` / `Padding` / `Center` / `Align` /
/// `SizedBox` / `Expanded` / `DecoratedBox` / `Opacity` / `Transform`
/// / `ClipRRect` / `Visibility` and Web `<div>`. A single component
/// captures the full Figma Frame surface (Auto Layout + Sizing +
/// Fill + Stroke + Effects + Behaviour).
///
/// The contract is intentionally **flat** — every Figma "Inspect"
/// slot is a top-level prop, not a nested decoration object. This
/// makes Figma → code conversion a 1:1 mapping.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [Trans] — transform (Flutter `Matrix4`, Web CSS string).

/// Contract for the unified frame primitive.
///
/// Property layers (group cognitively but live on the same class):
/// 1. Visual / Figma — every slot the designer touches.
/// 2. Behaviour — interaction callbacks and cursor.
/// 3. HTML semantic / SEO — the rendered tag for jaspr SSR. Maps to
///    Flutter `Semantics` for accessibility tree parity.
/// 4. Accessibility / DOM metadata — bundled as `a11y` so the common
///    case carries no extra noise.
abstract interface class CoreFrameContract<W, Trans> {
  // ============================================================
  // Layer 1 — Visual / Figma
  // ============================================================

  // --- Layout (Auto Layout) ---

  /// Flex direction. `null` means *no flex layout* — the frame
  /// behaves like a single-child / non-flex box (CSS `display:block`).
  ///
  /// In a row / column (and their reverses) a child that does not set
  /// [flex] keeps its intrinsic size and does not shrink — in a parent
  /// too narrow for it, it overflows (clipped by [clipBehavior]),
  /// the same on Flutter (`Row` / `Column`) and Web. Give a child
  /// [flex] to let it grow or shrink. [CoreFrameDirection.wrap] is the
  /// exception: each child is bounded by the run width, so text wraps.
  CoreFrameDirection? get direction;

  /// Spacing between flex children (logical px).
  double? get gap;

  /// Main-axis alignment when [direction] is set.
  CoreMainAxisAlignment? get mainAxisAlignment;

  /// Cross-axis alignment when [direction] is set.
  CoreCrossAxisAlignment? get crossAxisAlignment;

  /// 9-grid alignment used when [direction] is `null` (single-child)
  /// or to position non-flex content.
  CoreAlignment? get alignment;

  // --- Sizing ---

  /// Fixed width (logical px). `null` = hug / parent default / flex.
  double? get width;

  /// Fixed height.
  double? get height;

  /// Minimum width.
  double? get minWidth;

  /// Minimum height.
  double? get minHeight;

  /// Maximum width.
  double? get maxWidth;

  /// Maximum height.
  double? get maxHeight;

  // --- Flex (child-side hint, only meaningful inside a flex parent) ---

  /// Flex grow weight. `null` = no grow and no shrink — the child keeps
  /// its intrinsic size and overflows a too-narrow row / column parent
  /// (Flutter and Web alike).
  int? get flex;

  /// How the child should fit the allotted space.
  CoreFlexFit? get fit;

  // --- Spacing ---

  /// Inner padding.
  CoreEdgeInsets? get padding;

  /// Outer margin.
  CoreEdgeInsets? get margin;

  // --- Decoration / Fill ---

  /// Solid background colour. Composes with [gradient] /
  /// [backgroundImage] in implementation order.
  CoreColor? get backgroundColor;

  /// Background gradient.
  CoreGradient? get gradient;

  /// Background image source.
  CoreImageSource? get backgroundImage;

  // --- Decoration / Stroke ---

  /// Border colour.
  CoreColor? get borderColor;

  /// Border width (logical px).
  double? get borderWidth;

  /// Border style — solid / dashed / dotted / none.
  CoreFrameBorderStyle? get borderStyle;

  /// Border radius — uniform value or per-corner platform shape.
  CoreBorderRadius? get borderRadius;

  // --- Effects (Figma Effects panel 1:1) ---

  /// Drop shadow. Takes precedence over [elevation] when non-null.
  List<CoreShadowLayer>? get boxShadow;

  /// Inner shadow. Implemented via `CustomPaint` on Flutter and
  /// `box-shadow inset` on Web.
  List<CoreShadowLayer>? get innerShadow;

  /// Layer blur sigma — blurs the frame itself
  /// (`ImageFiltered` / CSS `filter: blur()`).
  double? get layerBlur;

  /// Background blur sigma — blurs the surface behind the frame
  /// (`BackdropFilter` / CSS `backdrop-filter: blur()`).
  double? get backdropBlur;

  /// Shadow elevation preset. Used when [boxShadow] is null.
  CoreFrameElevation? get elevation;

  // --- Behaviour ---

  /// Clip policy for child overflow.
  CoreClipBehavior get clipBehavior;

  /// Frame opacity (0..1).
  double? get opacity;

  /// 2D / 3D transform matrix.
  Trans? get transform;

  /// Anchor for [transform] origin.
  CoreAlignment? get transformAlignment;

  /// `false` removes the frame from layout (Flutter
  /// `SizedBox.shrink` / Web `display:none`). Default `true`.
  bool get visible;

  // ============================================================
  // Layer 2 — Behaviour / Interaction
  // ============================================================

  /// Tap / click callback.
  void Function()? get onTap;

  /// Hover state changed (`true` on enter, `false` on leave).
  CoreValueChanged<bool>? get onHover;

  /// Focus state changed.
  CoreValueChanged<bool>? get onFocus;

  /// Mouse cursor while pointing inside the frame.
  CoreCursor? get cursor;

  // ============================================================
  // Layer 3 — HTML semantic / SEO
  // ============================================================

  /// HTML tag emitted on Web. Default `'div'`. Use `'main'`,
  /// `'nav'`, `'section'`, `'article'`, `'header'`, `'footer'`,
  /// `'aside'` for semantic page structure — this is the SEO
  /// surface that drives search-engine page comprehension.
  ///
  /// On Flutter, mapped to the closest `Semantics` role for the
  /// accessibility tree (no visual effect). Defaults to `'div'`
  /// which is a no-op on Flutter.
  String get tag;

  // ============================================================
  // Layer 4 — Accessibility / DOM metadata
  // ============================================================

  /// Optional accessibility / DOM metadata. `null` for the common
  /// case; non-null only when the frame needs an explicit ARIA
  /// role / label / DOM id / `aria-*` attribute.
  CoreFrameA11y? get a11y;

  // ============================================================
  // Children
  // ============================================================

  /// Single-child convenience. When set, [children] must be `null`.
  W? get child;

  /// Multiple children. When set, [child] must be `null`.
  List<W>? get children;

  // ============================================================
  // Style slot (nested merge chain)
  // ============================================================

  /// Per-instance chrome / dimensional style bundle.
  ///
  /// Mirrors the most common Visual / Figma slots
  /// (`backgroundColor`, `borderColor`, `borderWidth`, `borderStyle`,
  /// `borderRadius`, `elevation`, `padding`, `clipBehavior`,
  /// `duration`). The flat contract slots above still win when set,
  /// preserving Figma's 1:1 mapping; this slot is the project-level
  /// style override hook.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreFrameTheme.style
  ///   → parent component slot override
  ///   → widget.frameStyle
  /// ```
  CoreFrameStyle? get frameStyle;
}
