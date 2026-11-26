import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output — Stacks
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Stacks`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                          // stack container (relative)
///   ├─ layer wrapper (<div>)            // per non-`Position` child — anchored
///   │    └─ child                       // anchored via layer chrome
///   └─ Position (<div>)               // explicit edge / size — bypasses anchor
/// ```
///
/// `root` carries the outer container chrome — `relative` className
/// plus the `overflow` + optional `width:100%; height:100%` inline-CSS
/// bundle derived from the resolved [fit] / [clipBehavior]. `layer`
/// carries the per-child layer wrapper chrome (`absolute` className +
/// alignment-derived `top/left/right/bottom` + optional
/// `transform: translate(...)` self-anchor on the centred axes); the
/// single layer chrome is shared across every non-`Position` child
/// because the alignment vector is identical for every child.
class ResolvedStacks implements WebResolvedChrome {
  /// Creates a [ResolvedStacks].
  const ResolvedStacks({
    required this.root,
    required this.layer,
  });

  /// Paint-ready chrome for the outer stack `<div>` container — the
  /// `relative` className plus the `overflow` + optional
  /// `width:100%; height:100%` inline-CSS bundle derived from the
  /// resolved `fit` / `clipBehavior`.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for a per-child layer `<div>` — `absolute`
  /// className plus the inline-CSS bundle carrying the
  /// `top/left/right/bottom` anchor rules and the optional
  /// `transform: translate(...)` self-anchor on the centred axes.
  /// Shared across every non-`Position` child of the stack (the
  /// alignment vector is the same for every child).
  final WebElementChrome layer;
}

/// Resolver output for a `Position` `<div>` inside a `Stacks`.
///
/// DOM shape:
///
/// ```text
/// position (<div>)                      // resolved.root — absolute, per-edge rem
///   └─ child                            // optional user content
/// ```
///
/// Direct CSS port of Flutter's `Positioned`. Any of `top` / `right`
/// / `bottom` / `left` / `width` / `height` may be supplied;
/// unspecified sides are left unset (the child sizes itself like
/// Flutter's `Positioned` with the missing edges).
class ResolvedPosition implements WebResolvedChrome {
  /// Creates a [ResolvedPosition].
  const ResolvedPosition({required this.root});

  /// Paint-ready chrome for the position `<div>` — `absolute`
  /// className plus the per-edge inline-CSS bundle (`top` / `right`
  /// / `bottom` / `left` / `width` / `height` in rem).
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolvers
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStacks] for [Stacks] — single entry point.
///
/// Priority (per-field): widget value > `CoreComponentTheme.stacks.style`
/// > design-system default ([CoreStacksStyle.defaultAlignment] /
/// [CoreStacksStyle.defaultFit] / [CoreStacksStyle.defaultClipBehavior]).
ResolvedStacks resolveStacks(
  BuildContext context, {
  CoreAlignment? alignment,
  CoreStackFit? fit,
  CoreClipBehavior? clipBehavior,
}) {
  final coreTheme = context.theme.coreComponentTheme?.stacks;
  final merged = resolveStyleChain(const CoreStacksStyle(), [
    coreTheme?.style,
    CoreStacksStyle(
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
    ),
  ]);
  final effectiveAlignment =
      merged.alignment ?? CoreStacksStyle.defaultAlignment;
  final effectiveFit = merged.fit ?? CoreStacksStyle.defaultFit;
  final effectiveClipBehavior =
      merged.clipBehavior ?? CoreStacksStyle.defaultClipBehavior;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer stack `<div>` Tailwind className — `relative`.
  /// `relative` is the Flutter `Stack` analogue — positioning context
  /// for absolute children and container for non-positioned children.
  String buildRootClassName() => WebLayout.relative;

  /// Composes the outer stack `<div>` inline CSS — `overflow` plus
  /// the optional `width:100%; height:100%` fill rules.
  ///
  /// - `fit` decides whether the wrapper sizes to its children, fills
  ///   the parent, or simply passes the parent's box constraints
  ///   through.
  /// - `clipBehavior` maps to a CSS `overflow` rule.
  Styles buildRootInlineStyles() {
    final overflow = switch (effectiveClipBehavior) {
      .none => 'visible',
      // Web has no native antialiased clip — both fall back to hidden.
      .hardEdge || .antiAlias || .antiAliasWithSaveLayer => WebLayout.hidden,
    };

    final raw = {'overflow': overflow};

    switch (effectiveFit) {
      // `loose` / `expand`: Flutter takes the parent's *max*
      //   constraints — wrapper grows to fill the box that the parent
      //   box-model gave it. CSS `width:100%; height:100%` does the
      //   same. Difference between the two only shows up in how the
      //   *non-positioned* children are sized, which is handled in
      //   the layer chrome.
      case .loose || .expand:
        raw['width'] = '100%';
        raw['height'] = '100%';
      // `passthrough`: parent constraints flow through unchanged and
      //   the wrapper takes the child's resolved size. CSS matches by
      //   leaving width/height unset — a block child fills its
      //   parent line, an inline child takes its intrinsic width.
      //   This is the mode used by `FocusOutline`, where the
      //   wrapper has to be exactly the child's box so the ring lands
      //   tight against the child.
      case .passthrough:
        break;
    }

    return Styles(raw: raw);
  }

  /// Composes the per-child layer `<div>` Tailwind className —
  /// `absolute`.
  String buildLayerClassName() => WebLayout.absolute;

  /// Composes the per-child layer `<div>` inline CSS — `top/left/right
  /// /bottom` anchor rules plus the optional `transform: translate
  /// (...)` self-anchor on the centred axes. Pins the child via
  /// `position: absolute`, anchors it at the stack edge that matches
  /// the alignment vector, then translates `-50%` on the centred axes
  /// so the child's own anchor lands on the stack's anchor — exactly
  /// what Flutter `Alignment` does.
  Styles buildLayerInlineStyles() {
    final raw = <String, String>{};

    // Horizontal anchor.
    if (effectiveAlignment.x > 0) {
      raw['right'] = '0';
    } else {
      raw['left'] = effectiveAlignment.x < 0 ? '0' : '50%';
    }

    // Vertical anchor.
    if (effectiveAlignment.y > 0) {
      raw['bottom'] = '0';
    } else {
      raw['top'] = effectiveAlignment.y < 0 ? '0' : '50%';
    }

    final tx = effectiveAlignment.x == 0 ? '-50%' : '0';
    final ty = effectiveAlignment.y == 0 ? '-50%' : '0';
    if (tx != '0' || ty != '0') {
      raw['transform'] = 'translate($tx, $ty)';
    }

    return Styles(raw: raw);
  }

  return ResolvedStacks(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    layer: WebElementChrome(
      className: buildLayerClassName(),
      inlineStyles: buildLayerInlineStyles(),
    ),
  );
}

/// Resolves [ResolvedPosition] for a `Position` child of a
/// `Stacks`. Closes over the per-instance edge / size values so the
/// inline CSS is pre-composed.
///
/// Each supplied edge / size becomes a `rem` value. Unspecified sides
/// are left unset (the child sizes itself like Flutter's `Positioned`
/// with the missing edges).
ResolvedPosition resolvePosition({
  double? top,
  double? right,
  double? bottom,
  double? left,
  double? width,
  double? height,
}) {
  // ─── Local builders ───────────────────────────────────

  /// Composes the position `<div>` Tailwind className — `absolute`.
  String buildPositionClassName() => WebLayout.absolute;

  /// Composes the position `<div>` inline CSS — each supplied edge /
  /// size as a `rem` value.
  Styles buildPositionInlineStyles() {
    final raw = <String, String>{};
    if (top != null) raw['top'] = '${top / kRemDivisor}rem';
    if (right != null) raw['right'] = '${right / kRemDivisor}rem';
    if (bottom != null) raw['bottom'] = '${bottom / kRemDivisor}rem';
    if (left != null) raw['left'] = '${left / kRemDivisor}rem';
    if (width != null) raw['width'] = '${width / kRemDivisor}rem';
    if (height != null) raw['height'] = '${height / kRemDivisor}rem';
    return Styles(raw: raw);
  }

  return ResolvedPosition(
    root: WebElementChrome(
      className: buildPositionClassName(),
      inlineStyles: buildPositionInlineStyles(),
    ),
  );
}
