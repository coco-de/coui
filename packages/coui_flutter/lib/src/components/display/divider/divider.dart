import 'package:coui_flutter/coui_flutter.dart';

/// Unified divider line for CoUI Flutter.
///
/// Renders a thin line to visually separate content, optionally with a
/// centered [child] (e.g. "OR" label). All chrome / dimensional
/// overrides flow through [dividerStyle] (Epic #1415 option D).
class Divider extends StatelessWidget implements CoreDividerContract<Widget> {
  /// Creates a [Divider].
  const Divider({
    super.key,
    this.orientation = CoreDividerOrientation.horizontal,
    this.child,
    this.dividerStyle,
    this.semantic = false,
  });

  @override
  final CoreDividerOrientation orientation;

  @override
  final Widget? child;

  @override
  final CoreDividerStyle? dividerStyle;

  @override
  final bool semantic;

  /// Returns a copy of this [Divider] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Divider copyWith({
    Key? key,
    CoreDividerOrientation? orientation,
    CoreDividerStyle? dividerStyle,
    Widget? child,
    bool? semantic,
  }) {
    return Divider(
      key: key ?? this.key,
      orientation: orientation ?? this.orientation,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      semantic: semantic ?? this.semantic,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!semantic) return content;

    // ARIA's `role="separator"` (`CoreSemanticRole.separator`) covers
    // both a focusable "window splitter" (which Flutter mirrors with
    // `slider:` — see `Resizable`) and this non-focusable group
    // boundary. Mapping the latter through the same `slider:` flag
    // would announce a static, decorative-but-meaningful line as an
    // adjustable control it is not, so this widget does not call that
    // generic mapping at all — a plain accessible name is the only
    // signal left to give it. `container: true` keeps that name from
    // merging into a neighboring row's label.
    return Semantics(
      container: true,
      label: CoUILocalizations.of(context).dividerSeparatorLabel,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final resolved = resolveDivider(context, dividerStyle: dividerStyle);

    final isHorizontal = orientation == .horizontal;
    final currentChild = child;

    // The child padding applies along the divider main axis: horizontal
    // padding for a horizontal divider, vertical for a vertical one.
    // `resolved.childPadding` is encoded as horizontal-symmetric EdgeInsets
    // (matches the design-system default); for vertical orientation the
    // axes are transposed.
    final childPadding = isHorizontal
        ? resolved.childPadding
        : EdgeInsets.fromLTRB(
            resolved.childPadding.top,
            resolved.childPadding.left,
            resolved.childPadding.bottom,
            resolved.childPadding.right,
          );

    final line = _DividerLine(
      orientation: orientation,
      color: resolved.color,
      thickness: resolved.thickness,
    );

    // `indent` is the inset at the end the line starts from and `endIndent`
    // the inset at the end it finishes at. Along the horizontal axis that is
    // a reading-direction statement — the right edge in a right-to-left
    // locale — so it is `start` / `end`, never `left` / `right`. A vertical
    // divider runs top to bottom in every locale and keeps its physical
    // sides.
    if (currentChild == null) {
      return Padding(
        padding: isHorizontal
            ? EdgeInsetsDirectional.only(
                start: resolved.indent,
                end: resolved.endIndent,
              )
            : EdgeInsets.only(top: resolved.indent, bottom: resolved.endIndent),
        child: line,
      );
    }

    if (isHorizontal) {
      return Row(
        // `min` + loose flex (rather than `max` + `Expanded`) is what
        // keeps a labelled divider legal inside a horizontally
        // unbounded parent — see `_DividerLine`'s note. `RenderFlex`
        // rejects flex children under an unbounded main axis whenever
        // `mainAxisSize` is `max` *or* the fit is tight, so `Expanded`
        // (tight) threw before the line ever got a chance to collapse.
        // Under a bounded parent the two are equivalent: each loose
        // line still receives `spacePerFlex` and expands into it, so
        // the row's width comes back out as the full available width.
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        children: [
          // A zero weight makes this segment inflexible, so `RenderFlex`
          // hands it the row's own main-axis constraint — unbounded —
          // and `_DividerLine`'s `LimitedBox` caps that to zero. The
          // segment disappears instead of asserting, which is the whole
          // reason `childAlignment` can be expressed as flex at all.
          //
          // The segment before the label carries the start indent and the
          // one after it the end indent. `Row` mirrors in right-to-left, so
          // the first segment lands on the right there and its start inset
          // lands with it.
          //
          // Each inset lives *inside* its `Flexible`, so the two segments
          // share what the label leaves by their weights whatever the insets
          // are and the label stays where the box puts it. The Web states the
          // same division as grid tracks; where the label and the lines land
          // is the shared vector table `divider_label_vectors.json`, so a
          // change to this layout has to move that table.
          Flexible(
            flex: resolved.leadingFlex,
            fit: .loose,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: resolved.indent),
              child: line,
            ),
          ),
          Padding(padding: childPadding, child: currentChild),
          Flexible(
            flex: resolved.trailingFlex,
            fit: .loose,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: resolved.endIndent),
              child: _DividerLine(
                orientation: orientation,
                color: resolved.color,
                thickness: resolved.thickness,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .center,
      children: [
        Flexible(
          flex: resolved.leadingFlex,
          fit: .loose,
          child: Padding(
            padding: .only(top: resolved.indent),
            child: line,
          ),
        ),
        Padding(padding: childPadding, child: currentChild),
        Flexible(
          flex: resolved.trailingFlex,
          fit: .loose,
          child: Padding(
            padding: .only(bottom: resolved.endIndent),
            child: _DividerLine(
              orientation: orientation,
              color: resolved.color,
              thickness: resolved.thickness,
            ),
          ),
        ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreDividerStyle] patch into
/// [Divider.dividerStyle] without hand-reconstructing every field.
/// Mirrors the Web `Divider.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDividerStyle.merge` right-side-wins semantics).
extension DividerStyleChain on Divider {
  /// Returns a copy of this [Divider] with [patch] merged into
  /// [dividerStyle] (patch fields win on conflict).
  Divider withStyle(CoreDividerStyle patch) => copyWith(
    dividerStyle: (dividerStyle ?? const CoreDividerStyle()).merge(patch),
  );
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({
    required this.orientation,
    required this.color,
    required this.thickness,
  });

  final CoreDividerOrientation orientation;
  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    // A divider fills its main axis, which is only defined when the
    // parent bounds that axis. Asking for `infinity` under an
    // unbounded parent is not "as long as possible" — it is an
    // assertion failure (`BoxConstraints forces an infinite height`),
    // so a vertical divider inside a scrolling column, or a
    // horizontal one inside a horizontally scrolling row, used to
    // take the whole subtree down.
    //
    // `LimitedBox` only applies its cap when the incoming constraint
    // on that axis is already unbounded, so the bounded case (every
    // ordinary layout) is untouched and the unbounded case collapses
    // to zero. Zero is the same thing the Web twin does: `h-full` /
    // `w-full` against a parent with no definite extent resolves to
    // `auto` and the line disappears rather than crashing the page.
    if (orientation == .horizontal) {
      return LimitedBox(
        maxWidth: 0,
        child: Container(color: color, width: .infinity, height: thickness),
      );
    }
    return LimitedBox(
      maxHeight: 0,
      child: Container(color: color, width: thickness, height: .infinity),
    );
  }
}
