import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/divider/divider_with_child_example.dart';
import 'package:docs_core/previews/examples/flutter/indexed_switcher/indexed_switcher_default_example.dart';
import 'package:docs_core/previews/examples/flutter/stack_layout/stack_layout_default_example.dart';
import 'package:docs_core/previews/examples/flutter/swap/swap_default_example.dart';
import 'package:docs_core/previews/examples/flutter/swap/swap_rotate_example.dart';
import 'package:flutter/rendering.dart' show RenderBox, RenderFlex, RenderStack;
import 'package:flutter/widgets.dart'
    show
        AnimatedBuilder,
        Column,
        DefaultTextStyle,
        EdgeInsets,
        Element,
        ExcludeFocus,
        ExcludeSemantics,
        FadeTransition,
        Flexible,
        Focus,
        IgnorePointer,
        KeyedSubtree,
        Opacity,
        Padding,
        Row,
        Semantics,
        SizedBox,
        Stack,
        Transform,
        Visibility,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

enum _Kind { stack, indexed, swap, divider }

typedef _Route = ({
  Element result,
  Element producer,
  Element frame,
  BoxProducerScope scope,
  List<Widget> supplied,
  String authority,
});

/// A current, source-specific layout witness; missing padding is not evidence.
class SequenceLayoutBoxSourceBinding {
  SequenceLayoutBoxSourceBinding._(
    this._capture,
    this._resultWidget,
    this._source,
    this._kind,
    this._route,
  ) : _producerWidget = _route.producer.widget,
      _supplied = List<Widget>.unmodifiable(_route.supplied);

  final Element _capture;
  final Widget _resultWidget;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;
  final _Kind _kind;
  final _Route _route;
  final List<Widget> _supplied;

  String get authority => _route.authority;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.frame;
  Element get paddingSource => _route.frame;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId => 'sequence-layout-declared-absence-v1';

  /// Original inputs stay fixed. Generated framework Widgets may change.
  void validateExistingCurrentBinding() {
    _current();
  }

  _Route _current() {
    for (final pair in [
      (_route.result, _resultWidget),
      (_route.producer, _producerWidget),
    ]) {
      if (!pair.$1.mounted || !identical(pair.$1.widget, pair.$2)) {
        throw _changed('the original mounted input Widget identities');
      }
    }
    final current = _locate(_capture, _resultWidget, _source, _kind);
    if (!identical(current.result, _route.result) ||
        !identical(current.producer, _route.producer) ||
        !identical(current.frame, _route.frame) ||
        current.supplied.length != _supplied.length ||
        current.scope.foreignBoundaries.length !=
            scope.foreignBoundaries.length) {
      throw _changed('the current source and foreign boundaries');
    }
    for (var i = 0; i < _supplied.length; i++) {
      if (!identical(current.supplied[i], _supplied[i]) ||
          !identical(
            current.scope.foreignBoundaries[i],
            scope.foreignBoundaries[i],
          )) {
        throw _changed('the complete ordered public input identities');
      }
    }
    return current;
  }

  BoxPaddingObservation readDeclaredAbsence() {
    final current = _current();
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: current.frame,
      producer: current.result,
      contentBoundary: current.frame,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {'sourceContract': readerId, 'authority': current.authority},
      ],
      frameOwner: current.frame,
    );
  }
}

SequenceLayoutBoxSourceBinding? bindSequenceLayoutBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final kind = switch (source.logicalUnitId) {
    'stack-layout-generated-overlap-layout-host' => _Kind.stack,
    'indexed-switcher-generated-indexed-layout-host' => _Kind.indexed,
    'swap-generated-overlap-layout-host' => _Kind.swap,
    'divider-generated-labelled-sequence-layout-host' => _Kind.divider,
    _ => null,
  };
  if (kind == null) return null;
  return SequenceLayoutBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    kind,
    _locate(captureRoot, registryResult, source, kind),
  );
}

BoxObservationSourceSpec _spec(_Kind kind) => switch (kind) {
  _Kind.stack => BoxObservationSourceSpec.stackLayoutOverlapHost,
  _Kind.indexed => BoxObservationSourceSpec.indexedSwitcherLayoutHost,
  _Kind.swap => BoxObservationSourceSpec.swapOverlapLayoutHost,
  _Kind.divider => BoxObservationSourceSpec.dividerLabelledSequenceHost,
};
Type _type(_Kind kind) => switch (kind) {
  _Kind.stack => coui.Stacks,
  _Kind.indexed => coui.IndexedSwitcher,
  _Kind.swap => coui.Swap,
  _Kind.divider => coui.Divider,
};
bool _example(Widget widget, _Kind kind) => switch (kind) {
  _Kind.stack => widget.runtimeType == StackLayoutDefaultExample,
  _Kind.indexed => widget.runtimeType == IndexedSwitcherDefaultExample,
  _Kind.swap =>
    widget.runtimeType == SwapDefaultExample ||
        widget.runtimeType == SwapRotateExample,
  _Kind.divider => widget.runtimeType == DividerWithChildExample,
};

_Route _locate(
  Element capture,
  Widget resultWidget,
  BoxObservationSourceSpec source,
  _Kind kind,
) {
  if (source != _spec(kind)) throw _changed('the exact source tuple/version');
  if (!capture.mounted ||
      !(identical(capture.widget, resultWidget) ||
          (capture.widget.runtimeType == KeyedSubtree &&
              identical(
                (capture.widget as KeyedSubtree).child,
                resultWidget,
              )))) {
    throw _changed('the capture result identity');
  }
  final result = _identity(capture, resultWidget);
  final direct = resultWidget.runtimeType == _type(kind);
  if (!direct && !_example(resultWidget, kind)) {
    throw _changed('an exact audited Example or public producer');
  }
  var producer = direct ? result : _only(result);
  if (!direct && kind == _Kind.stack) {
    _concrete(producer, SizedBox);
    producer = _child(producer, (producer.widget as SizedBox).child);
  } else if (!direct && kind == _Kind.indexed) {
    _concrete(producer, Column);
    final column = producer.widget as Column;
    if (column.children.length != 3) {
      throw _changed('the Example view/control seats');
    }
    producer = _child(producer, column.children[0]);
    _concrete(producer, SizedBox);
    producer = _child(producer, (producer.widget as SizedBox).child);
  }
  _concrete(producer, _type(kind));
  if (!direct && kind == _Kind.swap) {
    final expected = resultWidget.runtimeType == SwapRotateExample
        ? coui.CoreSwapAnimation.rotate
        : coui.CoreSwapAnimation.none;
    if ((producer.widget as coui.Swap).animation != expected) {
      throw _changed('the Example animation branch');
    }
  }
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final raw = [
    ...declaration.scope.suppliedSlots,
    ...declaration.unrenderedSuppliedSlots,
  ];
  final seen = Set<Widget>.identity();
  for (final slot in raw) {
    if (!seen.add(slot)) {
      throw _changed('unique raw supplied Widget identities');
    }
    _identity(producer, slot);
  }
  if (declaration.unrenderedSuppliedSlots.isNotEmpty) {
    throw _changed('all declared maintained foreign inputs must be mounted');
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  final frame = switch (kind) {
    _Kind.stack => _stack(
      producer,
      (producer.widget as coui.Stacks).children,
      scope,
    ),
    _Kind.indexed => _indexed(producer, scope),
    _Kind.swap => _swap(producer, scope),
    _Kind.divider => _divider(producer, scope),
  };
  scope.requireOwned(frame);
  final render = frame.renderObject;
  final expectedRender = kind == _Kind.divider ? RenderFlex : RenderStack;
  if (render.runtimeType != expectedRender ||
      render is! RenderBox ||
      !render.attached ||
      !render.hasSize) {
    throw _changed('the attached laid-out exact source renderer');
  }
  return (
    result: result,
    producer: producer,
    frame: frame,
    scope: scope,
    supplied: raw,
    authority:
        'Original exact Example/public producer and ordered Widget inputs; '
        '${declaration.authority}; current source-owned ${kind.name} '
        'layout host '
        'has no own padding allocation. Position layers, hidden views, '
        'both Swap slots and Divider label/line insets remain outside this '
        'field quantity.',
  );
}

Element _stack(
  Element producer,
  List<Widget> children,
  BoxProducerScope scope,
) {
  final frame = _only(producer);
  _concrete(frame, Stack);
  final stack = frame.widget as Stack;
  if (!_sameWidgets(stack.children, children)) {
    throw _changed('the source Stack children');
  }
  final elements = _children(frame);
  if (elements.length != children.length) {
    throw _changed('the actual Stack child count');
  }
  for (var i = 0; i < children.length; i++) {
    if (!identical(elements[i].widget, children[i])) {
      throw _changed('the direct Stack child Widget references');
    }
  }
  scope.requireOwned(frame);
  return frame;
}

Element _indexed(Element producer, BoxProducerScope scope) {
  final input = producer.widget as coui.IndexedSwitcher;
  final stacks = _only(producer);
  _concrete(stacks, coui.Stacks);
  scope.requireOwned(stacks);
  final children = (stacks.widget as coui.Stacks).children;
  if (children.length != input.children.length) {
    throw _changed('maintained slot cardinality');
  }
  for (var i = 0; i < children.length; i++) {
    var slot = _child(stacks, children[i], direct: false);
    _concrete(slot, Visibility);
    scope.requireOwned(slot);
    final visible = slot.widget as Visibility;
    if (!visible.maintainState ||
        !visible.maintainAnimation ||
        !visible.maintainSize) {
      throw _changed('the source-maintained hidden slot contract');
    }
    slot = _child(slot, visible.child, direct: false);
    _concrete(slot, IgnorePointer);
    scope.requireOwned(slot);
    slot = _child(slot, (slot.widget as IgnorePointer).child);
    _concrete(slot, ExcludeSemantics);
    scope.requireOwned(slot);
    slot = _child(slot, (slot.widget as ExcludeSemantics).child);
    _concrete(slot, ExcludeFocus);
    scope.requireOwned(slot);
    final focusChild = (slot.widget as ExcludeFocus).child;
    final focus = _only(slot);
    _concrete(focus, Focus);
    scope.requireOwned(focus);
    if (!identical((focus.widget as Focus).child, focusChild)) {
      throw _changed('the actual ExcludeFocus public child forwarding');
    }
    slot = _child(focus, focusChild, direct: false);
    _concrete(slot, FadeTransition);
    scope.requireOwned(slot);
    final fade = slot.widget as FadeTransition;
    if (!fade.alwaysIncludeSemantics ||
        !identical(fade.child, input.children[i])) {
      throw _changed('the exact maintained public child boundary');
    }
    _child(slot, input.children[i]); // STOP at the entire supplied view.
  }
  return _stack(stacks, children, scope);
}

Element _swap(Element producer, BoxProducerScope scope) {
  final input = producer.widget as coui.Swap;
  var seat = _only(producer);
  _concrete(seat, coui.Clickable);
  scope.requireOwned(seat);
  // Clickable forwards its actual public child; its internal press/focus paint
  // is outside this overlap field. No builder or callback is called.
  seat = _child(seat, (seat.widget as coui.Clickable).child, direct: false);
  _concrete(seat, Semantics);
  scope.requireOwned(seat);
  seat = _child(seat, (seat.widget as Semantics).child);
  _concrete(seat, AnimatedBuilder);
  scope.requireOwned(seat);
  seat = _only(seat); // actual already-executed animation operation
  if (input.animation == coui.CoreSwapAnimation.rotate) {
    _concrete(seat, Transform);
    scope.requireOwned(seat);
    seat = _child(seat, (seat.widget as Transform).child);
  }
  _concrete(seat, DefaultTextStyle);
  scope.requireOwned(seat);
  final stacks = _child(seat, (seat.widget as DefaultTextStyle).child);
  _concrete(stacks, coui.Stacks);
  scope.requireOwned(stacks);
  final children = (stacks.widget as coui.Stacks).children;
  if (children.length != 2) throw _changed('the two mounted Swap slots');
  final raw = [input.offContent, input.onContent];
  for (var i = 0; i < 2; i++) {
    final opacity = _child(stacks, children[i], direct: false);
    _concrete(opacity, Opacity);
    scope.requireOwned(opacity);
    if (!identical((opacity.widget as Opacity).child, raw[i])) {
      throw _changed('the original on/off slot identity');
    }
    _child(opacity, raw[i]); // STOP at each whole supplied input.
  }
  return _stack(stacks, children, scope);
}

Element _divider(Element producer, BoxProducerScope scope) {
  final input = producer.widget as coui.Divider;
  final frame = _only(producer);
  _concrete(frame, Row);
  final children = (frame.widget as Row).children;
  if (children.length != 3) throw _changed('the labelled sequence cardinality');
  for (final index in [0, 2]) {
    final flex = _child(frame, children[index]);
    _concrete(flex, Flexible);
    scope.requireOwned(flex);
    final inset = _child(flex, (flex.widget as Flexible).child);
    _concrete(inset, Padding);
    scope.requireOwned(inset);
    // Line seat is generated and separate; no private line type or inset value.
    _child(inset, (inset.widget as Padding).child);
  }
  final label = _child(frame, children[1]);
  _concrete(label, Padding);
  scope.requireOwned(label);
  if (!identical((label.widget as Padding).child, input.child)) {
    throw _changed('the original supplied label boundary');
  }
  _child(label, input.child); // STOP before label's entire foreign subtree.
  return frame;
}

bool _sameWidgets(List<Widget> a, List<Widget> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((same) => same);
List<Element> _children(Element element) {
  final out = <Element>[];
  element.visitChildren(out.add);
  return out;
}

Element _only(Element parent) =>
    requireOneBoxOwner(_children(parent), 'the exact sequence source child');
Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((e) => identical(e.widget, widget)),
  'the actual sequence Widget identity',
);
Element _child(Element parent, Widget? child, {bool direct = true}) {
  if (child == null) throw _changed('a required actual source child');
  final found = _identity(parent, child);
  if (direct && !_children(parent).any((e) => identical(e, found))) {
    throw _changed('the direct source child relationship');
  }
  return found;
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('the exact public $type source');
  }
}

BoxObservationError _changed(String reason) => BoxObservationError(
  'SEQUENCE_LAYOUT_SOURCE_CHANGED',
  'Unsupported $reason; no owner/absence inferred.',
);
