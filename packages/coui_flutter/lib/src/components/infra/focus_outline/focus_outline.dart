import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/util/standoff_border_radius.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;

/// Reports "no baseline" for its subtree so a baseline query never
/// descends into it.
///
/// The focus ring layers are `Position`-ed *decoration* (`IgnorePointer`,
/// not content) inside a [Stacks]. A stack's baseline must come from its
/// real content child, never from a decorative overlay — but
/// `RenderStack.computeDryBaseline` queries **every** child, positioned
/// ones included, via `getDryBaseline`. A childless decorative box
/// (`RenderDecoratedBox` / `RenderLimitedBox`) then asserts in
/// `computeDryBaseline` ("does not implement computeDryBaseline"), which
/// surfaces when a baseline-driven ancestor asks the stack for a dry
/// baseline — e.g. a `Table` cell sizing an inline
/// `WidgetSpan(child: Link(...))` (#3163). The `Table` cannot avoid the
/// query (any cell-height pass — intrinsic or dry — makes the paragraph
/// probe the placeholder's dry baseline), so the fix belongs here: the
/// decorative layers report `null`, and the stack's baseline comes only
/// from the focused content. Every focus component (TextField / Button /
/// Radio / …) composes `FocusOutline`, so all become inline-safe at once.
class _NoBaseline extends SingleChildRenderObjectWidget {
  const _NoBaseline({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNoBaseline();
}

class _RenderNoBaseline extends RenderProxyBox {
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => null;

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => null;
}

/// A focus outline wrapper that draws a ring around [child] when
/// [focused] is `true`.
///
/// `FocusOutline` is a pure visual wrapper — it draws the ring and
/// nothing else. Focus tracking is the **caller's** responsibility,
/// because the right "focus" depends on the call site:
///
/// - a text field tracks `_focusNode.hasFocus`,
/// - a radio cell tracks `_focusing && isSelected`,
/// - an accordion trigger tracks
///   `FocusableActionDetector.onShowFocusHighlight`.
///
/// The Web implementation has the same contract: callers wire focus
/// state and pass the resulting boolean. Both platforms agree on the
/// shape (`focused: bool`, default `false`) so cross-platform code
/// stays identical.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [focusOutlineStyle] slot. Behavioural fields
/// (`child`, `focused`, `shape`) stay flat on the widget.
///
/// ```dart
/// FocusOutline(
///   focused: focusNode.hasFocus,
///   focusOutlineStyle: CoreFocusOutlineStyle(
///     borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
///   ),
///   child: TextField(...),
/// )
/// ```
class FocusOutline extends StatelessWidget
    implements CoreFocusOutlineContract<Widget> {
  /// Creates a [FocusOutline].
  const FocusOutline({
    required this.child,
    this.focused = false,
    this.shape = CoreFocusOutlineShape.rectangle,
    this.focusOutlineStyle,
    super.key,
  });

  /// Outer ring corners must be rounder than child by `align` px so that
  /// the ring's curvature matches the child's perceived corner.
  static BorderRadius _adjustedBorderRadius(
    TextDirection textDirection,
    double align,
    BorderRadiusGeometry? borderRadius,
  ) {
    if (borderRadius == null) return .zero;
    final resolved = borderRadius.resolve(textDirection);
    return BorderRadius.only(
      topLeft: resolved.topLeft + .circular(align),
      topRight: resolved.topRight + .circular(align),
      bottomLeft: resolved.bottomLeft + .circular(align),
      bottomRight: resolved.bottomRight + .circular(align),
    );
  }

  /// The circle branch's standoff — same idea as [_adjustedBorderRadius],
  /// except a corner that is already square stays square. The rule is the
  /// shared [StandoffBorderRadius.standoff], which `Avatar`'s ring reads
  /// too, so the two standoff rings cannot drift apart.
  static BorderRadius _standoffBorderRadius(
    TextDirection textDirection,
    double standoff,
    BorderRadiusGeometry borderRadius,
  ) => borderRadius.resolve(textDirection).standoff(standoff);

  @override
  final Widget child;

  @override
  final bool focused;

  @override
  final CoreFocusOutlineShape shape;

  @override
  final CoreFocusOutlineStyle? focusOutlineStyle;

  /// Returns a copy of this [FocusOutline] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  FocusOutline copyWith({
    Key? key,
    bool? focused,
    CoreFocusOutlineShape? shape,
    CoreFocusOutlineStyle? focusOutlineStyle,
    Widget? child,
  }) {
    return FocusOutline(
      key: key ?? this.key,
      focused: focused ?? this.focused,
      shape: shape ?? this.shape,
      focusOutlineStyle: focusOutlineStyle ?? this.focusOutlineStyle,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveFocusOutline(
      context,
      widgetStyle: focusOutlineStyle,
    );

    final resolvedAlign = resolved.align;
    final offset = -resolvedAlign;
    final textDirection = Directionality.of(context);

    // Pin the ring at its final geometry (offset / width) and animate
    // *only* opacity, mirroring the Web `box-shadow` alpha fade —
    // a pure opacity fade reads as "the ring appears" rather than
    // "the ring grows in", which is the W3C `:focus-visible` UX both
    // platforms aim for. `AnimatedOpacity` is the Flutter idiom for
    // an implicit alpha animation driven by a bool flag.
    // Two-layer ring (Web ring + ring-offset parity):
    //   inner layer (offsetColor) is the band directly outside the child,
    //   outer layer (borderColor) is the ring outside that band.
    // Both are strokes. The band box is sized to `child + 2 * offsetExtent`
    // and strokes `offsetExtent` inward, so it covers exactly the gap; the
    // ring box is sized to `child + 2 * align` and strokes `borderWidth`
    // inward. Neither paints anything over or under the child itself.
    final offsetExtent = resolvedAlign - resolved.borderWidth;
    final innerOffset = -offsetExtent;

    // Which radius the ring follows. The shape picks the source only —
    // the ring box itself stays a rounded rectangle in both cases, so
    // the decorations below leave `BoxDecoration.shape` at its
    // rectangle default and never ask for a circle.
    //
    // A circle decoration takes its diameter from the shortest side of
    // its rect and ignores the radius outright, which cost two things
    // at once: the resolved circle radius reached nothing on Flutter
    // while Web honoured it, and a circle ring around a non-square
    // child drew a small centred disc rather than enclosing it. A pill
    // radius reproduces the circle for a square child and encloses a
    // non-square one, so a single expression covers both.
    //
    // The selection mirrors the Web resolver, which switches on the
    // same shape to pick between the same two fields — both platforms
    // now read the same one for a given shape.
    //
    // Unconditional, rather than falling back to a circle decoration
    // when the caller left the radius alone: a conditional would make
    // an explicitly stated default render differently from an omitted
    // one, and would put the widget back in the business of comparing
    // resolved values to pick its own chrome (`widget/render-only.md`).
    final circle = shape == .circle;
    final ringRadius = circle
        ? _standoffBorderRadius(
            textDirection,
            resolvedAlign,
            resolved.circleBorderRadius,
          )
        : _adjustedBorderRadius(
            textDirection,
            resolvedAlign,
            resolved.borderRadius,
          );
    final offsetRadius = circle
        ? _standoffBorderRadius(
            textDirection,
            offsetExtent,
            resolved.circleBorderRadius,
          )
        : _adjustedBorderRadius(
            textDirection,
            offsetExtent,
            resolved.borderRadius,
          );

    return Stacks(
      fit: .passthrough,
      clipBehavior: .none,
      children: [
        // Offset (ring-offset) band — a stroke ring knocked out of the
        // child's own box, not a filled box behind the child. CSS paints
        // an outer `box-shadow` only outside the border box; a filled box
        // behind the child would show the band *through* the child
        // wherever the child is not opaque (a ghost or plain button, a
        // translucent carousel control), and only on Flutter
        // (`cross-platform/api.md`, shadows paint in different places).
        // The stroke's outer edge is `offsetRadius` and its inner edge
        // lands on the child's own corner, so the band covers the gap
        // and nothing else.
        //
        // Painted behind the child so a child that overflows its box is
        // never covered by the band. Skipped when the gap has collapsed
        // (a preset stroke floor can widen the ring to `align`): a
        // zero-width `BorderSide` is a hairline, not nothing.
        //
        // A shape stroke rather than a bordered `Container`, so the band
        // never reads as a box border: the ring below and the control's
        // own chrome are the boxes that carry a `Border`.
        if (resolved.offsetColor != null && offsetExtent > 0)
          Position(
            top: innerOffset,
            right: innerOffset,
            bottom: innerOffset,
            left: innerOffset,
            // Decorative overlay — kept out of the stack's baseline query.
            child: _NoBaseline(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: focused ? 1.0 : 0.0,
                  duration: resolved.duration,
                  curve: CoreEasing.move.toValue(),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: resolved.offsetColor!,
                          width: offsetExtent,
                        ),
                        borderRadius: offsetRadius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        child,
        Position(
          top: offset,
          right: offset,
          bottom: offset,
          left: offset,
          // Decorative overlay — kept out of the stack's baseline query.
          child: _NoBaseline(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: focused ? 1.0 : 0.0,
                duration: resolved.duration,
                curve: CoreEasing.move.toValue(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: resolved.borderColor,
                      width: resolved.borderWidth,
                      style: resolved.borderStyle,
                    ),
                    borderRadius: ringRadius,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chain sugar for merging a [CoreFocusOutlineStyle] patch into
/// [FocusOutline.focusOutlineStyle] without hand-reconstructing every
/// field. Mirrors the Web `FocusOutline.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFocusOutlineStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreFocusOutlineStyle.borderRadius]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// FocusOutline(child: content).radius4
/// ```
extension FocusOutlineStyleChain on FocusOutline {
  /// Sets the border color.
  FocusOutline borderColor(CoreColor value) =>
      withStyle(CoreFocusOutlineStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  FocusOutline borderWidth(double value) =>
      withStyle(CoreFocusOutlineStyle(borderWidth: value));

  /// Returns a copy of this [FocusOutline] with [patch] merged into
  /// [focusOutlineStyle] (patch fields win on conflict).
  FocusOutline withStyle(CoreFocusOutlineStyle patch) => copyWith(
    focusOutlineStyle: (focusOutlineStyle ?? const CoreFocusOutlineStyle())
        .merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  FocusOutline get radius0 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  FocusOutline get radius2 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  FocusOutline get radius4 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  FocusOutline get radius6 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  FocusOutline get radius8 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  FocusOutline get radius10 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  FocusOutline get radius12 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  FocusOutline get radius14 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  FocusOutline get radius16 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  FocusOutline get radius20 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  FocusOutline get radius24 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  FocusOutline get radius28 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  FocusOutline get radius32 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  FocusOutline get radius36 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  FocusOutline get radius40 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  FocusOutline get radius48 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  FocusOutline get radius56 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  FocusOutline get radius64 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  FocusOutline get radius9999 => withStyle(
    const CoreFocusOutlineStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
