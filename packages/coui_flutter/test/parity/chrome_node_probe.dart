// #3652 — chrome-node selection for the manifest-driven capture matrix,
// replacing the single-component `flutter_capture_test.dart`'s hardcoded
// `skip: chromeSkipIndex = 1` (a manually-confirmed index that only means
// anything for `Button`'s own specific three-`DecoratedBox` structure —
// 139+ catalog components each have their own tree shape, so no fixed
// index generalizes).
//
// Rule: [findRootScoped] (`root_scoped_walk.dart`) walks from root's own
// element down toward the first [DecoratedBox]/[ColoredBox]/[PhysicalModel]
// reachable on a path that is unambiguously root's own — "the chrome" is
// the one node painting a background/border/shadow across the component's
// whole visible extent, as opposed to a smaller decorated sub-element (an
// icon badge, a focus ring inset from the edge, a nested child's own
// chrome) that sits behind a real branch this walk refuses to guess across
// (a sibling in a `Row`/`Column` where one side currently renders nothing,
// or a `Positioned` layer within a `Stack`).
//
// #3909 — this used to be a *geometric* rule instead: within the probed
// root's whole subtree (`find.descendant`), the first candidate whose own
// render box (a) was exactly root's own size and (b) sat at root's own
// origin. That degenerated the instant a foreign sibling's box happened to
// coincide with root's own (measured directly for `root_text_probe.dart`'s
// analogous text-style rule, `flutter_capture_matrix_overlay_pinning_test
// .dart`'s second case: a "trigger + closed overlay" root collapses to
// *exactly* the trigger's own footprint once the overlay paints nothing) —
// no size/position tolerance can tell those two apart at that point.
// [findRootScoped]'s structural rule never has that failure mode: a foreign
// sub-component's own chrome is only reachable by picking a sibling next to
// one that currently renders nothing at all, which it refuses to do (while
// still searching root's own genuinely multi-slot chrome, `Alert`'s
// icon-plus-label row included — see `root_scoped_walk.dart`'s own doc
// comment for why that distinction, not "never branch", is the actual
// rule).
//
// Candidate widget types: [DecoratedBox] (what `Container`/`AnimatedContainer`
// compile down to — `widget_tree_probe.dart`'s own reasoning), [ColoredBox]
// (a flat fill with no border/radius/shadow of its own — e.g. `Divider`
// paints its line via `Container(color:)`, confirmed empirically: searching
// for `DecoratedBox` alone under a `Divider` root finds zero candidates),
// and [PhysicalModel] (Material's elevation/shape/color primitive). All
// three are `SingleChildRenderObjectWidget`s, so a match found by
// [findRootScoped] has exactly one associated `RenderObject` and
// `Element.renderObject` resolves to it unambiguously.
//
// #3904 — [findRootScoped] is called here with `allowMultiSlotTemplate:
// false`: a chrome candidate reached only by picking among 2+ non-empty
// siblings is refused outright, never attributed to root. Chrome (a
// background/border/radius) is never CSS-inherited the way text is — a
// value painted on one sibling's own box describes *that* box, never
// "whatever's ambient here" the way a `DefaultTextStyle` value does.
// #4872 — Web's probe now walks the same way when the matched node
// itself does not paint (`computed_style_probe.dart` `_kFindChromeJs`):
// stay if the node has fill/border/shadow, else a single-child path to
// the one chrome box, refuse 2+ independent chrome siblings. This
// file's `false` is that same "exactly one path" rule.
//
// Confirmed as a real defect this closes, not a hypothetical: `Wrap([for
// (option in themes) _ThemeSwatch(...)])` (`ThemeController`), and the
// analogous repeated-item roots in `NavigationMenu`/`Swiper`, have no
// chrome of their own at all — before this flag, `findRootScoped` still
// found *a* `DecoratedBox` by picking item zero's own swatch/trigger/slide
// chrome, which for `ThemeController` carries a `selected`/`unselected`
// border color/width that has nothing to do with root's (nonexistent) own
// identity. That produced a *confidently wrong* comparison (Flutter
// reporting a real border Web's actual root element, which declares none
// of its own, could never match) rather than an honest "couldn't find
// one" — measured directly against a real T1 capture (#3904's own issue).
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'root_scoped_walk.dart';

/// One matched chrome node's paint-relevant properties — a strict subset of
/// what each candidate widget type actually carries. [decoration] is
/// non-null only for a matched [DecoratedBox]; [flatColor] is non-null only
/// for a matched [ColoredBox] or [PhysicalModel] (neither has a `border`,
/// `borderRadius: BorderRadius` in the `BoxDecoration` sense, or
/// `boxShadow` list of its own — a [PhysicalModel]'s `borderRadius` field
/// is a plain `BorderRadius` already handled via [physicalModelRadius], and
/// its elevation-driven shadow is a Material painting concern this probe
/// does not attempt to reproduce as a `BoxShadow` list).
///
/// [paddingPx] is the geometric replacement for `widget_tree_probe.dart`'s
/// `probeEffectivePadding(..., skip: N)` — see [_geometricPadding]'s doc
/// comment for the "insets minus border width" derivation.
class ChromeNodeMatch {
  const ChromeNodeMatch({
    required this.renderBox,
    this.decoration,
    this.flatColor,
    this.physicalModelRadius,
    this.paddingPx,
  });

  /// The matched node's own render box — where the chrome is painted, and
  /// therefore where the walk for anything that wraps the chrome (the
  /// root's opacity, `root_opacity_probe.dart`) starts from.
  final RenderBox renderBox;

  final BoxDecoration? decoration;
  final Color? flatColor;
  final BorderRadius? physicalModelRadius;
  final EdgeInsets? paddingPx;
}

/// Whether [element]'s widget is a candidate this probe can actually
/// extract a normalized shape from — a [DecoratedBox] whose own
/// `decoration` is *not* a [BoxDecoration] (a `ShapeDecoration`, etc.)
/// deliberately does **not** count: [findRootScoped] then treats that
/// [DecoratedBox] as an ordinary single-child wrapper and keeps walking
/// past it (down into whatever it decorates) rather than stopping on a
/// match this probe has no normalized shape for.
bool _isChromeCandidate(Element element) {
  final widget = element.widget;
  if (widget is DecoratedBox) return widget.decoration is BoxDecoration;
  return widget is ColoredBox || widget is PhysicalModel;
}

/// Walks [rootFinder]'s element down (`root_scoped_walk.dart`'s
/// [findRootScoped]) for the first chrome node reached per this file's
/// top-comment rule. Returns `null` if the walk stops before reaching one —
/// the caller (`flutter_capture_matrix_test.dart`) treats that as "no
/// chrome for this root", not an error: many catalog components (pure-text,
/// pure-composition roots) legitimately have none.
ChromeNodeMatch? findChromeNode(
  WidgetTester tester, {
  required Finder rootFinder,
}) {
  final rootElement = rootFinder.evaluate().single;
  return findRootScoped<ChromeNodeMatch>(
    rootElement,
    isCandidate: _isChromeCandidate,
    onMatch: (element) {
      final renderObject = element.renderObject;
      if (renderObject is! RenderBox || !renderObject.hasSize) return null;

      final widget = element.widget;
      if (widget is DecoratedBox) {
        // `_isChromeCandidate` already guarantees a `BoxDecoration` here.
        final decoration = widget.decoration as BoxDecoration;
        return ChromeNodeMatch(
          renderBox: renderObject,
          decoration: decoration,
          paddingPx: _geometricPadding(
            renderObject,
            borderWidthPx: decoration.border?.top.width ?? 0,
          ),
        );
      }
      if (widget is ColoredBox) {
        return ChromeNodeMatch(
          renderBox: renderObject,
          flatColor: widget.color,
          paddingPx: _geometricPadding(renderObject, borderWidthPx: 0),
        );
      }
      // `_isChromeCandidate` leaves only `PhysicalModel` here.
      final physicalModel = widget as PhysicalModel;
      return ChromeNodeMatch(
        renderBox: renderObject,
        flatColor: physicalModel.color,
        physicalModelRadius: physicalModel.borderRadius,
        paddingPx: _geometricPadding(renderObject, borderWidthPx: 0),
      );
    },
    // #3904 — chrome is never CSS-inherited (this file's top comment):
    // refuse to guess a representative among 2+ non-empty siblings, unlike
    // [probeRootTextStyle]'s default `true`.
    allowMultiSlotTemplate: false,
  );
}

/// The matched chrome node's own inset from its single child, per side,
/// minus [borderWidthPx] — "padding 은 insets − decoration.padding(= border
/// dimensions)": `BoxDecoration` has no `padding` field of its own, so
/// "decoration.padding" here means the border's own stroke width, which
/// occupies part of the visual gap between the chrome box's edge and its
/// content without being padding in the CSS-parity sense Web reports
/// separately via `getComputedStyle().padding`.
///
/// Replaces `widget_tree_probe.dart`'s `probeEffectivePadding(..., skip:
/// N)` — that helper locates a `Padding` *widget* by position, which only
/// means anything for a component whose author happened to build chrome+
/// content with an explicit `Padding` at a known index. This instead reads
/// the *rendered* geometry directly off the chrome node's descendants, so
/// it generalizes to any component regardless of whether its padding came
/// from a `Padding` widget, a `Container`'s `padding:` argument (itself
/// compiled to an internal `Padding`), or any other means.
///
/// The chrome box's *immediate* single child is not always "the content" —
/// confirmed empirically against `Button`: its matched chrome
/// `DecoratedBox`'s immediate child is the focus-ring's own border-stroke
/// box, painted at *exactly* the chrome box's own size (zero inset of its
/// own), with the button's real 16/8px padding one layer further down
/// still. This walks down through any number of these zero-inset,
/// same-sized single-child proxy layers and measures against the *first*
/// descendant whose size actually differs from the chrome box's — that is
/// where padding (plus border width, subtracted via [borderWidthPx]) is
/// actually being spent.
///
/// Returns `null` if no such descendant exists — either the chrome node has
/// no child at all, or every descendant it has is a non-single-child render
/// object (nothing left to walk through) — nothing to compute an inset
/// against, rather than a false "confirmed zero" if the walk otherwise
/// bottomed out at a same-sized leaf.
EdgeInsets? _geometricPadding(
  RenderBox chromeBox, {
  required double borderWidthPx,
}) {
  var current = chromeBox;
  while (true) {
    // Must be the `RenderObjectWithChildMixin<RenderBox>` *mixin*
    // interface, not the concrete `RenderProxyBox` — `Padding`'s own render
    // object (`RenderPadding`) extends `RenderShiftedBox`, a *sibling*
    // single-child hierarchy that also mixes in this interface but does
    // NOT extend `RenderProxyBox`. Narrowing to `RenderProxyBox` instead
    // silently broke this walk for exactly the case it exists for —
    // confirmed empirically against `Button`: with `RenderProxyBox`, the
    // walk stopped one layer early (at the focus ring's same-sized
    // border-stroke box, itself a `RenderProxyBox`) and never reached the
    // `RenderPadding` one layer further down carrying the real 16/8px
    // inset, so `paddingPx` silently went from `[8.0, 16.0, 8.0, 16.0]`
    // back to `null` with no error — a correctness regression, not a lint
    // fix.
    //
    // The cast below sees through a subtype relationship a static
    // type-overlap check cannot model: a `RenderBox` subtype ALSO
    // implements an unrelated mixin interface via a *different* branch of
    // the hierarchy (both `RenderProxyBox` and `RenderShiftedBox`
    // separately mix in `RenderObjectWithChildMixin<RenderBox>`), which is
    // exactly the situation this walk needs to see through.
    if (current is! RenderObjectWithChildMixin<RenderBox>) return null;
    final child = (current as RenderObjectWithChildMixin<RenderBox>).child;
    if (child == null || !child.hasSize) return null;

    if (child.size == chromeBox.size) {
      // A zero-inset proxy layer (e.g. a same-extent border-stroke box) —
      // keep walking, comparing against the *outer* chrome box's size, not
      // this layer's (so a chain of several such layers is fully skipped).
      current = child;
      continue;
    }

    final origin = child.localToGlobal(.zero, ancestor: chromeBox);
    final left = origin.dx;
    final top = origin.dy;
    final right = chromeBox.size.width - (left + child.size.width);
    final bottom = chromeBox.size.height - (top + child.size.height);

    double net(double inset) =>
        (inset - borderWidthPx).clamp(0, double.infinity);

    return EdgeInsets.fromLTRB(net(left), net(top), net(right), net(bottom));
  }
}
