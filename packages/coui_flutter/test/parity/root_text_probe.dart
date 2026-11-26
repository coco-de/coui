// #3852 — root-representative text style selection for the manifest-driven
// capture matrix (`flutter_capture_matrix_test.dart`).
//
// Problem (measured against `dialog`/`card`, `.bmad/architecture-*.md`
// Component ②/③ intent): `widget_tree_probe.dart`'s original text probe was
// invoked with `find.descendant(of: rootFinder, matching:
// find.byType(Text)).first` — the *first* `Text` found anywhere under
// root, in tree order, however deep, then its fully-resolved (post-merge)
// `RichText` style. Web's counterpart (`computed_style_probe.dart`'s
// `[data-parity-key] > *` selector) reads the root DOM element's OWN
// `getComputedStyle()` — a value that is either that element's own declared
// style, or, if it declares none, whatever it *inherits* from its
// ancestors. It never reflects a descendant's own explicit override,
// because CSS properties never propagate upward from a child to its
// parent's own computed value.
//
// These are not the same node in general — two confirmed shapes:
//
// 1. **Unrelated sibling** (`dialog`). Its root is `Column([Button('Open
//    Dialog'), Dialog(open: false, ...)])` — the Column itself is bare
//    layout with no chrome of its own, and the closed `Dialog` paints
//    nothing. The naive probe's *first* `Text` under this root is
//    therefore the trigger `Button`'s own label, entirely unrelated to
//    `Dialog`. Measured: `onPrimary` (r:15 g:34 b:72 in the dark theme) vs.
//    Web's root `onSurface` (inherited, r:252 g:252 b:253) — a near-total
//    color inversion that is a measurement-methodology artifact, not a
//    real cross-platform rendering difference.
//
// 2. **Deeper override within the same component** (`card`). Its root
//    (`Card`) wraps its whole subtree in `DefaultTextStyle.merge(style:
//    resolved.bodyTextStyle, child: innerChild)` — root's *own* declared
//    text style — but its `header` slot wraps *that* in a second,
//    more-specific `DefaultTextStyle.merge(style: headerTextStyle, child:
//    header!)` deeper down. The naive probe's *first* `Text` (the header's)
//    resolves through *both* merges, reading the header's own semibold/18px
//    override — not root's own bodyTextStyle (400/16px). Measured: Web's
//    root computed style is `color: rgb(24, 25, 27)` (bodyTextStyle's
//    color, matching) but `font-weight: 400` / `font-size: 16px`
//    (bodyTextStyle, not the header override the naive probe read).
//
// Fix, two parts:
//
// - **Stop at root's own declared value, don't resolve through a deeper
//   override.** `DefaultTextStyle.merge` is a `Builder` that reads the
//   *current* ambient `DefaultTextStyle.of(context)` at its own build point
//   and folds its override into it — so the `DefaultTextStyle` *widget
//   instance* found in the built tree already carries the fully-resolved
//   style at exactly that point, with nothing from any deeper override
//   mixed in. Searching for `DefaultTextStyle` widgets (not `Text` widgets)
//   and reading the *first* one's own `.style` field directly gives
//   "whatever governs root's own position" — case 2's fix. When no such
//   widget exists before a bare `Text` is reached (nothing local ever
//   overrode the ambient), that `Text`'s own resolved style already *is*
//   the ambient value, so it is used as a fallback in the same combined
//   scan.
// - **Skip a foreign sub-component's own subtree.** Root's own declared
//   `DefaultTextStyle`/`Text` is found by [findRootScoped]
//   (`root_scoped_walk.dart`'s own doc comment) — a candidate reachable
//   only by picking one of several real siblings where one of them
//   currently renders *nothing at all* (the trigger `Button` next to
//   `dialog`'s own closed-`Dialog` sibling) is never visited.
//
// #3909 — this file used to disambiguate "root's own" from "a foreign
// sub-component's" by comparing candidate render-box *size* against
// `rootSize` within a tolerance (`_kChromeLayerToleranceInPx`,
// `_matchesRootBounds`/`_hasForeignChromeAncestor`). That was only ever
// correct by accident: it relied on root's own measured size reliably
// differing from a foreign sub-component's, which
// `flutter_capture_matrix_test.dart`'s pre-#3909 `Overlay` bug guaranteed
// (every root force-tight-sized to the ambient 800×600 viewport,
// unconditionally) but which stopped being true the instant that capture
// boundary was narrowed to each root's *real* natural size — proven
// directly by `flutter_capture_matrix_overlay_pinning_test.dart`'s second
// case: `dialog`'s root then collapses to *exactly* the trigger `Button`'s
// own footprint, and no size/position tolerance can tell them apart at
// that point. This file now uses `root_scoped_walk.dart`'s structural rule
// instead — see that file's own doc comment for the exact rule (and why a
// naive "never branch" version of it regressed `Alert` and everything
// shaped like it) — and does not need `rootSize`/`rootRenderObject` at all.
import 'package:flutter/rendering.dart'
    show RenderAnimatedOpacity, RenderOpacity;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../src/parity_probe/widget_tree_probe.dart';
import 'root_scoped_walk.dart';

/// Finds the [TextStyle] that represents root's own visual identity,
/// matching Web's "root DOM element's own computed style" semantics (this
/// file's top comment).
///
/// Returns `null` when [findRootScoped] never reaches a
/// [DefaultTextStyle]/[Text] under root (there is neither one under root at
/// all, or reaching one would require picking among siblings where one
/// currently renders nothing) — the caller treats this identically to "no
/// text found": it contributes to `_isVacuousSnapshot`, not to a fabricated
/// comparison against an unrelated sibling's — or a deeper override's —
/// style.
TextStyle? probeRootTextStyle(
  WidgetTester tester, {
  required Finder rootFinder,
}) {
  final rootElement = rootFinder.evaluate().single;
  return findRootScoped<TextStyle>(
    rootElement,
    isCandidate: (element) {
      if (!_isVisibleUnder(element, rootElement)) return false;
      final widget = element.widget;
      return (widget is DefaultTextStyle && _containsPaintedText(element)) ||
          widget is Text ||
          (widget is EditableText && widget.controller.text.isNotEmpty);
    },
    onMatch: (element) {
      final widget = element.widget;
      if (widget is DefaultTextStyle) return widget.style;
      if (widget is EditableText) return widget.style;
      // widget is Text — no `DefaultTextStyle.merge` stood between root
      // and this bare `Text` on the walk, so its own fully-resolved
      // `RichText` style already *is* the ambient value at root's
      // position.
      return probeEffectiveTextStyle(
        tester,
        find.byElementPredicate(
          (candidate) => identical(candidate, element),
          description: 'root-representative Text (#3909)',
        ),
      );
    },
  );
}

// A size-preserving hidden hint still has Text/DefaultTextStyle in the
// element tree. It must not supply the colour of the value drawn beside it.
bool _isVisibleUnder(Element element, Element root) {
  var visible = true;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    final render = ancestor.renderObject;
    if ((widget is Visibility && !widget.visible) ||
        (widget is Offstage && widget.offstage) ||
        (render is RenderOpacity && render.opacity == 0) ||
        (render is RenderAnimatedOpacity && render.opacity.value == 0)) {
      visible = false;
      return false;
    }
    return !identical(ancestor, root);
  });
  return visible;
}

// An icon-only wrapper can declare a DefaultTextStyle for its own layout.
// That declaration is not representative text when it paints no glyphs.
bool _containsPaintedText(Element root) {
  bool visit(Element element) {
    if (!_isVisibleUnder(element, root)) return false;
    final widget = element.widget;
    if (widget is Text) {
      return (widget.data ?? widget.textSpan?.toPlainText() ?? '')
          .trim()
          .isNotEmpty;
    }
    if (widget is RichText) return widget.text.toPlainText().trim().isNotEmpty;
    if (widget is EditableText) return widget.controller.text.isNotEmpty;
    var found = false;
    element.visitChildren((child) {
      if (!found) found = visit(child);
    });
    return found;
  }

  return visit(root);
}
