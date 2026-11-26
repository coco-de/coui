// #3909 — the single traversal primitive `root_text_probe.dart`
// (`probeRootTextStyle`) and `chrome_node_probe.dart` (`findChromeNode`)
// both build on to find "root's own" text style / chrome node.
//
// Both probes used to disambiguate "belongs to root itself" from "belongs
// to a foreign nested sub-component" (a trigger `Button` sitting next to
// the real thing under test) by comparing a candidate's rendered SIZE
// against `rootSize` within a tolerance. That worked only as long as root's
// own measured size reliably differed from a foreign sub-component's — true
// by *accident* under `flutter_capture_matrix_test.dart`'s pre-#3909
// harness bug (`Overlay` force-tight-sizing every root to the ambient
// 800×600 viewport regardless of its real content, `root_text_probe.dart`'s
// own prior header comment), false the moment root measures its real
// natural size: a "trigger + closed overlay" composition (`dialog`,
// `navigation-menu`, `swiper`) collapses to *exactly* the trigger's own
// footprint once the overlay paints nothing, and no size/position tolerance
// can then tell "root itself" from "the trigger" apart — confirmed directly
// (`flutter_capture_matrix_overlay_pinning_test.dart`'s second case,
// #3859): re-key `Overlay` to force it to actually reflect a rebuild, and
// the geometric probe starts returning the trigger's own `onPrimary` label
// style instead of `null` ("nothing belongs to root").
//
// This file replaces size/position matching with a *structural* rule.
// A first attempt ("never branch into more than one child") measurably
// broke a large, unrelated class of real components: `Alert`'s own
// `build()` is `Row([Icon(...), Gap(...), Expanded(child: Column([title?,
// description]))])` — a genuine multi-child branch that is nonetheless
// entirely `Alert`'s *own* implementation, not a foreign nested
// composition. Refusing to descend past it dropped `Alert`'s text style
// entirely (measured against a real T1 manifest run: `color` went from a
// correct cross-platform match to `null` on every `alert-*` entry, and the
// same icon/label-row shape recurs across dozens of other catalog
// components). "Never branch" over-generalized what actually
// distinguishes `dialog`'s composition from `alert`'s.
//
// The real distinguishing fact: `dialog`'s branch has a sibling that
// renders **nothing at all** — a closed `Dialog` is literally `const
// SizedBox.shrink()` (zero size), because closing it is meant to make it
// vanish, not just look empty. `alert`'s branches (`Icon`, `Gap`, the text
// column) are all genuinely visible, all the time — nothing about `Alert`'s
// own layout is conditionally absent. A zero-size sibling is Flutter's own
// vocabulary for "something that isn't here right now but could be" (a
// closed overlay, a collapsed panel) — and that is exactly the shape where
// picking whichever sibling *does* render something risks reading a
// completely unrelated composition's content as if it were root's own.
// When every sibling renders something, by contrast, the branch is almost
// certainly root's own multi-slot template, and the first match found in
// tree order is root's own primary content — the same "first-found" rule
// the pre-#3852 naive implementation used, safe here specifically because
// the one shape that rule got wrong (a zero-size sibling standing in for
// "something could appear here") has already been excluded above it.
//
// #3904 — "every sibling renders something" is necessary but not
// sufficient for "root's own multi-slot template". The actual question
// this file answers below is: *how many of these siblings independently
// lead to a candidate of their own?*
//
// - **Exactly one** (`Alert`'s `[Icon, Gap, Expanded(Column)]` — only the
//   `Column` branch reaches a `Text`; `Checkbox`'s `[checkboxSquare, Gap,
//   suffix]` — only `checkboxSquare` reaches a `DecoratedBox`) means root's
//   own fixed template has exactly one slot that *could* be the candidate,
//   so picking it is unambiguous — even when a sibling merely shares a
//   generic widget *type* with `checkboxSquare` (two `SizedBox`-shaped
//   *leaf* siblings, an icon placeholder and a gap, neither leading
//   anywhere) rather than being a real second source. For `Checkbox` that
//   one slot *is* root's own box chrome sitting right next to an unrelated
//   label — refusing to cross this branch at all (an earlier, cruder fix
//   attempt) measurably regressed `checkbox`/`radio-group`/`text-field`
//   (#3904's own before/after `compare_reports.dart` run:
//   `borderRadiusPx`/`paddingPx` mismatches *increased*, a real
//   regression, not a wash) — and refusing it whenever 2+ siblings merely
//   *share a widget type* regressed the exact same components for the
//   exact same reason (false-positiving on those two `SizedBox` leaves).
// - **Two or more** (`ThemeController`'s
//   `Wrap([for (option in themes) _ThemeSwatch(...)])`, and the analogous
//   shape in `NavigationMenu`/`Swiper`) means N independent,
//   self-contained sub-components each independently offer their own
//   candidate — not named slots of root's own template at all. Picking
//   "first found" among those doesn't read root's own identity, it reads
//   *item zero's* — confirmed as a real defect for `ThemeController`: item
//   zero's own `selected`/`unselected` border color got attributed to
//   root's (nonexistent) chrome, producing a *confidently wrong*
//   comparison (Flutter reporting a real border color/width/radius Web's
//   actual root element — which has none of its own — could never match),
//   not an honest "couldn't find one".
//
// [allowMultiSlotTemplate] `true` (the default, `probeRootTextStyle`'s
// choice) never asks this question — every sibling renders something is
// enough, same as before #3904, and "first found" wins regardless of how
// many siblings could have supplied it. `false` (`findChromeNode`'s
// choice) requires the reachable-candidate count to be *exactly one*;
// zero or 2+ refuses the whole branch (same outcome as a zero-size
// sibling: stop, report nothing found).
//
// This asymmetry is not arbitrary pattern-matching — it mirrors a
// distinction the Web side encodes structurally
// (`computed_style_probe.dart`: six CSS-inherited text fields walk via
// `findTextSource`; box fields walk via `_kFindChromeJs` only when the
// matched node itself does not paint, and refuse 2+ chrome siblings the
// same way [allowMultiSlotTemplate] `false` does here):
//
// - **Text** is CSS-*inherited* — a value declared several levels down
//   still describes "whatever is ambient at root's own position" as long
//   as nothing between root and that point overrides it differently. A
//   repeated collection of sibling items that all happen to share the
//   same typography role (`filter`'s items, `menubar`'s trigger labels)
//   makes "first found" land on a value that *is* root's own ambient
//   default, even though the literal element it was read from belongs to
//   one specific item, and even though 2+ of those siblings could equally
//   have supplied it — measured directly: `filter`/`menubar` text fields
//   already match Web's own root-computed style this way. Requiring
//   exactly-one-candidate for text too would regress that back to null
//   (the original #3904 symptom for these two).
// - **Chrome** is never CSS-inherited — a background/border/radius
//   belongs to the one specific box it's painted on, full stop; nothing
//   "ambient" flows down through a wrapper the way text color does. So
//   when 2+ siblings each independently offer a chrome candidate, none of
//   them is "close enough" the way a repeated sibling's inherited text can
//   be — whichever one gets picked is simply a different node's own
//   paint, misattributed.
/// Shared traversal for native text and box probes.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Finds the first descendant of [root] for which [isCandidate] returns
/// `true`, walking down a path this file's top comment argues is
/// unambiguously "root's own" — `null` when no such descendant exists on
/// any such path. [onMatch] converts a matched [Element] into the caller's
/// result type ([TextStyle] for `probeRootTextStyle`, `ChromeNodeMatch` for
/// `findChromeNode`) — kept as a callback (not a fixed return type) so each
/// caller reads whatever `Element.renderObject`/`Element.widget` data it
/// needs at the exact point of the match, same as before this file existed
/// as a shared primitive. [onMatch] returning `null` is treated the same as
/// [isCandidate] never having matched at that element (e.g.
/// `chrome_node_probe.dart`'s non-`BoxDecoration` `Decoration` case, which
/// keeps walking rather than reporting an empty match) — this function
/// does *not* itself distinguish "no candidate" from "candidate matched but
/// [onMatch] declined it", callers that need to keep walking past a
/// declined match do so from their own [isCandidate]/[onMatch] pair.
///
/// [allowMultiSlotTemplate] (default `true`) governs a genuine multi-child
/// branch (2+ non-empty siblings): `true` picks the first sibling whose own
/// subtree reaches a candidate, same as before #3904. `false` additionally
/// requires that count to be *exactly one* — if 2+ (or 0) searchable
/// siblings independently lead to a candidate of their own, the branch is
/// refused outright, the same as a branch with a zero-size sibling: stop,
/// report nothing found. See this file's top comment (#3904) for why
/// `probeRootTextStyle` and `findChromeNode` need different answers here.
T? findRootScoped<T>(
  Element root, {
  required bool Function(Element element) isCandidate,
  required T? Function(Element element) onMatch,
  bool allowMultiSlotTemplate = true,
}) {
  final children = <Element>[];
  root.visitChildren(children.add);
  if (children.isEmpty) return null;

  if (children.length == 1) {
    final only = children.single;
    return isCandidate(only)
        ? onMatch(only)
        : findRootScoped(
            only,
            isCandidate: isCandidate,
            onMatch: onMatch,
            allowMultiSlotTemplate: allowMultiSlotTemplate,
          );
  }

  // More than one element child — a genuine branch. `Stack` gets one
  // exception before the general multi-child rule below: `Positioned`
  // children are Flutter's own vocabulary for "layered on top of, not
  // part of the main content flow" (a badge, a focus ring, a decorative
  // overlay), read off each child's own render object's `parentData`
  // (`StackParentData.isPositioned`) rather than by widget type — a
  // `Positioned` several `StatelessWidget` layers below a
  // `Stack.children[i]` entry (this package's own `Position`, which builds
  // a `Positioned` from inside its own `build()`) still resolves to the
  // right render object this way, because `Element.renderObject` walks
  // down through non-`RenderObjectElement` layers to the first real one.
  // Exactly one remaining non-positioned child continues the walk the same
  // as the single-child case above.
  var searchable = children;
  if (root.widget is Stack) {
    final nonPositioned = children.where((child) {
      final parentData = child.renderObject?.parentData;
      return parentData is! StackParentData || !parentData.isPositioned;
    }).toList();
    if (nonPositioned.length == 1) {
      final only = nonPositioned.single;
      final main = isCandidate(only)
          ? onMatch(only)
          : findRootScoped(
              only,
              isCandidate: isCandidate,
              onMatch: onMatch,
              allowMultiSlotTemplate: allowMultiSlotTemplate,
            );
      if (main != null || !allowMultiSlotTemplate) return main;
      // A Stack may keep an invisible measurement child in normal flow
      // and paint its actual text in a positioned layer (Carousel).
      // Text can follow that visible layer when the main child supplies
      // no candidate. Chrome keeps the existing main-box-only rule.
      searchable = children.where((child) => !identical(child, only)).toList();
    } else {
      searchable = nonPositioned.isEmpty && allowMultiSlotTemplate
          ? children
          : nonPositioned;
    }
    // Zero or more than one non-positioned child — fall through to the
    // general multi-child rule below with the *filtered* set (a
    // `Positioned` decoration layer still shouldn't be searched as if it
    // were root's own primary content, even in the ambiguous-count case).
  }

  // A sibling that renders literally nothing (`Size.zero` — `const
  // SizedBox.shrink()`, a closed overlay's own build output) marks this
  // composition as "something could appear here", not root's own stable
  // layout (this file's top comment). Refuse the whole branch rather than
  // picking whichever sibling currently happens to render something. Both
  // callers want this — checked before the [allowMultiSlotTemplate] split
  // below, not after.
  final hasEmptySibling = searchable.any((child) {
    final renderObject = child.renderObject;
    if (renderObject is! RenderBox || !renderObject.hasSize) return true;
    return renderObject.size == Size.zero;
  });
  if (hasEmptySibling) return null;

  if (!allowMultiSlotTemplate) {
    // #3904 — chrome only gets to pick among these siblings when exactly
    // one of them independently leads to a candidate of its own; 2+ doing
    // so is the ambiguity this file's top comment describes (a *repeated*
    // collection — `filter`'s items, `ThemeController`'s swatches, each
    // one an independent sub-component with its own chrome), and 0 means
    // there's genuinely nothing here to find.
    //
    // This is deliberately *not* "2+ siblings share a widget runtime
    // type" — that reads as the same signal for `ThemeController`'s
    // repeated `_ThemeSwatch`es, but false-positives on a branch like
    // `[icon-shaped SizedBox, gap-shaped SizedBox, Expanded(chrome
    // panel)]` (`chrome_node_probe_test.dart`'s own committed regression
    // fixture): two *leaf* siblings happen to share the generic `SizedBox`
    // type for unrelated reasons (one's an icon placeholder, one's a
    // spacer), neither leads to a chrome candidate at all, and the type
    // check would refuse a branch that has exactly one real source.
    // Counting *reachable candidates* (not sibling types) answers the
    // actual question directly: how many of these siblings could this
    // chrome plausibly have come from?
    final found = <T>[];
    for (final child in searchable) {
      final result = isCandidate(child)
          ? onMatch(child)
          : findRootScoped(
              child,
              isCandidate: isCandidate,
              onMatch: onMatch,
              allowMultiSlotTemplate: false,
            );
      if (result != null) found.add(result);
    }
    return found.length == 1 ? found.single : null;
  }

  // Every sibling renders something — root's own multi-slot template
  // (icon + text, header + body, ...), not a foreign composition. The
  // first match found in tree order is root's own primary content.
  for (final child in searchable) {
    final result = isCandidate(child)
        ? onMatch(child)
        : findRootScoped(
            child,
            isCandidate: isCandidate,
            onMatch: onMatch,
            allowMultiSlotTemplate: allowMultiSlotTemplate,
          );
    if (result != null) return result;
  }
  return null;
}
