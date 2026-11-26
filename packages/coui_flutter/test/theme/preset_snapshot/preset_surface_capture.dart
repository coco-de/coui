// #4355 — what a surface *renders* under a preset, as reviewable text.
//
// The Project claims the four non-glass presets are untouched by the role
// and material work. That claim is true by design — those presets state no
// material, so there is nothing for the role axis to interpret — and this
// file exists because "true by design" and "renders the same" are two
// different statements. Only the second is falsifiable, and only by
// reading what actually reached the render tree.
//
// ## Why render objects, not widgets
//
// A widget-level walk sees what was *asked for*; the render tree is what
// the framework resolved. `Container` compiles to a `DecoratedBox`,
// `AnimatedContainer` to one carrying its animated value at the pumped
// phase, and a resolver that changed which of those a component builds
// would be invisible to a walk keyed on widget classes.
//
// ## Why not pixels
//
// A golden image answers "did it change" and never "what changed" — the
// question a preset regression actually asks. These snapshots diff as JSON,
// so a review sees `"a": 1.0 → 0.502` rather than two PNGs and a percentage.
// The cost is that a change with no chrome consequence (a re-ordered
// wrapper that paints nothing) still moves the file; that is the trade this
// takes on purpose, because the failure it guards against is a chrome value
// appearing where the design says none can.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decimal places every physical length is rounded to.
///
/// Mirrors `test/parity/flutter_property_snapshot.dart`'s own px precision
/// so the two capture paths cannot disagree about whether a value moved.
const int _kPxDecimals = 2;

/// Decimal places an alpha channel is rounded to.
const int _kAlphaDecimals = 3;

const int _kAlphaShift = 24;
const int _kRedShift = 16;
const int _kGreenShift = 8;
const int _kByteMask = 0xFF;

double _px(double value) => double.parse(value.toStringAsFixed(_kPxDecimals));

/// `Color` → the `{r,g,b,a}` shape the parity capture already writes.
///
/// Alpha is the field this snapshot most needs to be exact about: a
/// translucent fill is precisely what "a material leaked into a non-glass
/// preset" looks like on the way to paint.
Map<String, Object?> _colorJson(Color color) {
  final argb = color.toARGB32();
  return {
    'r': (argb >> _kRedShift) & _kByteMask,
    'g': (argb >> _kGreenShift) & _kByteMask,
    'b': argb & _kByteMask,
    'a': double.parse(
      (((argb >> _kAlphaShift) & _kByteMask) / _kByteMask).toStringAsFixed(
        _kAlphaDecimals,
      ),
    ),
  };
}

/// A gradient by the fields `Gradient` itself defines.
///
/// Not `toString()`: the base class does not override it, so an exotic
/// subclass would serialise as `Instance of 'X'` and two different
/// gradients of that type would compare equal — a blind spot exactly where
/// a fill is being replaced by something else.
Map<String, Object?>? _gradientJson(Gradient? gradient) => gradient == null
    ? null
    : {
        't': gradient.runtimeType.toString(),
        'colors': gradient.colors.map(_colorJson).toList(growable: false),
        'stops': ?gradient.stops?.map(_px).toList(growable: false),
      };

/// [_colorJson] for a value that may be absent, so a fill can be written as
/// a null-aware map entry rather than a conditional one.
Map<String, Object?>? _colorJsonOrNull(Color? color) =>
    color == null ? null : _colorJson(color);

Map<String, Object?> _sideJson(BorderSide side) => {
  'w': _px(side.width),
  'c': _colorJson(side.color),
  's': side.style.name,
};

/// Every side of [border], named the way that border type names them.
///
/// `BoxBorder` itself only promises `top`/`bottom` — the other two are
/// physical on `Border` and logical on `BorderDirectional`, and collapsing
/// them into one shape would print a left/right pair for a border that was
/// authored as start/end. A border type this does not know falls through to
/// its text form rather than being reported as four absent sides.
Map<String, Object?> _borderJson(BoxBorder border) {
  if (border is Border) {
    return {
      'top': _sideJson(border.top),
      'right': _sideJson(border.right),
      'bottom': _sideJson(border.bottom),
      'left': _sideJson(border.left),
    };
  }
  if (border is BorderDirectional) {
    return {
      'top': _sideJson(border.top),
      'end': _sideJson(border.end),
      'bottom': _sideJson(border.bottom),
      'start': _sideJson(border.start),
    };
  }
  return {'t': border.runtimeType.toString(), 'v': border.toString()};
}

/// One `BoxDecoration` as the chrome facts a preset can move.
///
/// Every field a surface style is defined by is here — fill (and its
/// alpha), stroke, corner, cast, gradient — because the axis states its
/// character in exactly these terms (`docs/surface-preset-axis.md`). A
/// decoration subtype this does not know is emitted by `toString()` rather
/// than dropped: an unrecognised shape must still move the file, or a new
/// decoration class would be a blind spot that reads as "no change".
Map<String, Object?> _decorationJson(Decoration decoration) {
  if (decoration is! BoxDecoration) {
    return {'t': decoration.runtimeType.toString(), 'v': decoration.toString()};
  }

  final border = decoration.border;
  // Resolved `ltr` rather than left as a geometry: this capture is a
  // single-direction render and a directional radius would otherwise
  // serialise as an unresolved object whose text form carries no numbers.
  final radius = decoration.borderRadius?.resolve(.ltr);

  return {
    't': 'box',
    'fill': ?_colorJsonOrNull(decoration.color),
    // All four sides, not a representative one: a preset's stroke floor can
    // raise one edge of an asymmetric border and leave the rest, and a
    // capture that sampled `top` alone would report that as unchanged.
    'border': ?(border == null ? null : _borderJson(border)),
    'radius': ?(radius == null
        ? null
        : [
            radius.topLeft.x,
            radius.topRight.x,
            radius.bottomRight.x,
            radius.bottomLeft.x,
          ].map(_px).toList(growable: false)),
    'shadows': ?decoration.boxShadow
        ?.map(
          (shadow) => {
            'o': [_px(shadow.offset.dx), _px(shadow.offset.dy)],
            'blur': _px(shadow.blurRadius),
            'spread': _px(shadow.spreadRadius),
            'c': _colorJson(shadow.color),
            'style': shadow.blurStyle.name,
          },
        )
        .toList(growable: false),
    'gradient': ?_gradientJson(decoration.gradient),
    'shape': decoration.shape.name,
  };
}

/// The render-tree node kinds this snapshot records, or `null` for a node
/// that paints no chrome of its own.
///
/// The set is chosen by what a surface style can reach: fills/strokes/
/// corners/casts (`RenderDecoratedBox`), elevation-driven shadow
/// (`RenderPhysicalModel`), whole-subtree alpha (`RenderOpacity`), backdrop
/// blur (`RenderBackdropFilter` — the single clearest signature of a glass
/// material arriving somewhere it was not stated), and painters
/// (`RenderCustomPaint`, which is how this kit draws knocked-out casts and
/// highlight rims). A painter is recorded by *type*, not by its fields:
/// the question this answers is "did a paint appear/disappear here", and a
/// painter's internals are already visible through the decoration values
/// it was built from.
Map<String, Object?>? _nodeJson(RenderObject node) {
  if (node is RenderDecoratedBox) return _decorationJson(node.decoration);
  if (node is RenderPhysicalModel) {
    return {
      't': 'physical',
      'e': _px(node.elevation),
      'c': _colorJson(node.color),
      'sc': _colorJson(node.shadowColor),
    };
  }
  if (node is RenderOpacity) return {'t': 'opacity', 'v': _px(node.opacity)};
  if (node is RenderBackdropFilter) {
    // The clearest single signature of a glass material arriving where none
    // was stated — a non-glass preset has no reason to blur anything behind
    // a surface.
    return {'t': 'backdrop', 'f': node.filterConfig.toString()};
  }
  if (node is RenderCustomPaint) {
    final painter = node.painter;
    final foreground = node.foregroundPainter;
    if (painter == null && foreground == null) return null;
    return {
      't': 'paint',
      'p': ?painter?.runtimeType.toString(),
      'fp': ?foreground?.runtimeType.toString(),
    };
  }
  return null;
}

/// Every chrome-bearing node in the pumped tree, in paint order.
///
/// Order is the tree's own child order, which is the order these paint in;
/// it is stable across runs (verified by capturing the full matrix twice
/// and diffing) and carries meaning a sorted list would throw away — a cast
/// that moved from behind a fill to in front of it is a visual change with
/// identical values.
List<Map<String, Object?>> captureSurfaceChrome(WidgetTester tester) {
  final nodes = <Map<String, Object?>>[];

  void walk(RenderObject node) {
    final json = _nodeJson(node);
    if (json != null) nodes.add(json);
    node.visitChildren(walk);
  }

  final root = tester.binding.rootElement?.renderObject;
  if (root == null) {
    throw StateError('렌더 트리가 비어 있다 — pumpWidget 이 선행되지 않았다.');
  }
  walk(root);

  return nodes;
}
