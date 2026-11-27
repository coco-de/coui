import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/media_query/media_query_default_example.dart';
import 'package:docs_core/previews/examples/flutter/swipe_actions/swipe_actions_default_example.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        AnimatedBuilder,
        EdgeInsets,
        Element,
        Focus,
        FocusTraversalGroup,
        FocusTraversalOrder,
        GestureDetector,
        KeyedSubtree,
        LayoutBuilder,
        Listener,
        RenderObjectElement,
        Semantics,
        SizedBox,
        Stack,
        Transform,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  List<Object?> held,
  List<Widget?> raw,
  List<Widget> active,
  BoxProducerScope scope,
});

/// Binds the normal mounted public operation. No State, callback, animation
/// value, constraints value or resolver is consulted to select this source.
class PublicWrapperBoxSourceBinding {
  PublicWrapperBoxSourceBinding._(this._capture, this._registry, this._source)
    : _route = _locate(_capture, _registry, _source);
  final Element _capture;
  final Widget _registry;
  final BoxObservationSourceSpec _source;
  final _Route _route;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.field;
  BoxProducerScope get scope => _route.scope;
  List<Widget?> get allOriginalSuppliedSlots => _route.raw;
  String get readerId => 'public-wrapper-current-framework-operation-v1';
  String get authority =>
      'Exact public producer/current mounted child edges -> '
      'actual SizedBox/RenderConstrainedBox or Stacks/Stack/RenderStack; '
      'all raw public seats held before active omission; whole foreign seats '
      'and generated platters/tap catcher remain opaque; public foreground '
      'child chain held; no builder/State replay';

  void validateExistingCurrentBinding() {
    final now = _locate(_capture, _registry, _source);
    if (!_same(_route.held, now.held) ||
        !_same(_route.raw, now.raw) ||
        !_same(_route.active, now.active)) {
      throw _changed(
        'held public inputs, complete current operation or branch',
      );
    }
  }

  BoxPaddingObservation readDeclaredAbsence() {
    validateExistingCurrentBinding();
    // The concrete framework operation itself has no padding allocation.
    // This structural kind does not assert anything about a descendant inset.
    final result = BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: fieldUnitElement,
      producer: registryResultElement,
      contentBoundary: fieldUnitElement,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {'sourceContract': readerId, 'authority': authority},
      ],
      frameOwner: fieldUnitElement,
    );
    validateExistingCurrentBinding();
    return result;
  }
}

PublicWrapperBoxSourceBinding? bindPublicWrapperBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) =>
    BoxObservationSourceSpec.publicWrapperFrames.any(
      (s) => s.logicalUnitId == source.logicalUnitId,
    )
    ? PublicWrapperBoxSourceBinding._(captureRoot, registryResult, source)
    : null;

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
) {
  if (!BoxObservationSourceSpec.publicWrapperFrames.contains(source) ||
      !capture.mounted) {
    throw _changed('closed complete source tuple');
  }
  final result = identical(capture.widget, registry)
      ? capture
      : capture.widget.runtimeType == KeyedSubtree &&
            identical((capture.widget as KeyedSubtree).child, registry)
      ? _only(capture)
      : throw _changed('original keyed construction');
  if (!identical(result.widget, registry)) {
    throw _changed('registry identity');
  }
  final media = source == BoxObservationSourceSpec.mediaQueryVisibilityHost;
  final type = media ? coui.MediaQueryVisibility : coui.SwipeActions;
  final direct = registry.runtimeType == type;
  if (!direct &&
      registry.runtimeType !=
          (media ? MediaQueryDefaultExample : SwipeActionsDefaultExample)) {
    throw _changed('exact public producer or original Example');
  }
  final producer = direct ? result : _only(result);
  if (producer.widget.runtimeType != type) {
    throw _changed('direct public producer');
  }
  final held = <Object?>[
    capture,
    capture.widget,
    result,
    registry,
    producer,
    producer.widget,
  ];
  final raw = <Widget?>[];
  final active = <Widget>[];
  void own(Element e) {
    if (!e.mounted) {
      throw _changed('mounted current prefix');
    }
    held.addAll([e, e.widget, _parent(e)]);
    // Proxy Elements must not expose a foreign descendant's renderer.
    if (e is RenderObjectElement) {
      final render = e.renderObject;
      if (!render.attached) {
        throw _changed('attached own renderer');
      }
      held.addAll([render, render.parent]);
      if (render is RenderConstrainedBox) {
        held.add(render.additionalConstraints);
      }
      if (render is RenderStack) {
        held.addAll([
          render.alignment,
          render.textDirection,
          render.fit,
          render.clipBehavior,
        ]);
      }
    }
  }

  own(result);
  own(producer);
  late Element field;
  if (media) {
    final input = producer.widget as coui.MediaQueryVisibility;
    raw.addAll([input.child, input.alternateChild]);
    held.addAll([
      input.minWidth,
      input.maxWidth,
      input.minBreakpoint,
      input.maxBreakpoint,
    ]);
    final layout = _only(producer);
    own(layout);
    if (layout.widget.runtimeType != LayoutBuilder) {
      throw _changed('normal LayoutBuilder');
    }
    field = _only(layout);
    own(field);
    if (field.widget.runtimeType != SizedBox ||
        field is! RenderObjectElement ||
        field.renderObject is! RenderConstrainedBox) {
      throw _changed('actual SizedBox operation');
    }
    final child = (field.widget as SizedBox).child;
    if (!identical(child, input.child) &&
        !identical(child, input.alternateChild)) {
      throw _changed('current public branch child');
    }
    held.add(child);
    if (child != null) {
      final boundary = _only(field);
      if (!identical(boundary.widget, child)) {
        throw _changed('whole current branch');
      }
      active.add(child);
      held.addAll([boundary, boundary.widget]);
    } else if (_children(field).isNotEmpty) {
      throw _changed('absent branch');
    }
  } else {
    final input = producer.widget as coui.SwipeActions;
    raw.addAll([
      input.child,
      for (final a in [...input.leadingActions, ...input.trailingActions])
        a.icon,
    ]);
    held.addAll([
      input.enabled,
      input.showLabels,
      input.allowsFullSwipe,
      input.fullSwipeThreshold,
      input.swipeActionsStyle,
      ...input.leadingActions,
      ...input.trailingActions,
    ]);
    var current = _only(producer);
    own(current);
    if (current.widget.runtimeType != Listener) {
      throw _changed('original Listener');
    }
    current = _forward(current, (current.widget as Listener).child!, own);
    if (current.widget.runtimeType != GestureDetector) {
      throw _changed('original GestureDetector');
    }
    current = _forward(
      current,
      (current.widget as GestureDetector).child!,
      own,
    );
    if (current.widget.runtimeType != Focus) {
      throw _changed('original Focus');
    }
    current = _forward(current, (current.widget as Focus).child, own);
    if (current.widget.runtimeType != FocusTraversalGroup) {
      throw _changed('original traversal group');
    }
    current = _forward(
      current,
      (current.widget as FocusTraversalGroup).child,
      own,
    );
    if (current.widget.runtimeType != AnimatedBuilder ||
        !identical((current.widget as AnimatedBuilder).child, input.child)) {
      throw _changed('original AnimatedBuilder public child');
    }
    final stacks = _only(current);
    own(stacks);
    if (stacks.widget.runtimeType != coui.Stacks) {
      throw _changed('normal public Stacks result');
    }
    final declaration = stacks.widget as coui.Stacks;
    if (declaration.fit != coui.CoreStackFit.passthrough) {
      throw _changed('source passthrough operation');
    }
    field = _only(stacks);
    own(field);
    if (field.widget.runtimeType != Stack ||
        field is! RenderObjectElement ||
        field.renderObject is! RenderStack) {
      throw _changed('actual Stack operation');
    }
    final children = _children(field);
    final declared = (field.widget as Stack).children;
    if (children.length != declaration.children.length ||
        declared.length != children.length ||
        children.isEmpty ||
        List.generate(
          children.length,
          (i) =>
              !identical(declared[i], declaration.children[i]) ||
              !identical(children[i].widget, declared[i]) ||
              !identical(_parent(children[i]), field),
        ).any((bad) => bad)) {
      throw _changed('complete generated Stack frontier');
    }
    // Platter subtrees are GENERATED opaque boundaries, not caller slots.
    // Only the public foreground chain is owned down to the raw child seat.
    for (final child in children) {
      held.addAll([child, child.widget]);
    }
    var row = children.last;
    own(row);
    if (row.widget.runtimeType != FocusTraversalOrder) {
      throw _changed('public foreground order');
    }
    row = _forward(row, (row.widget as FocusTraversalOrder).child, own);
    if (row.widget.runtimeType != FocusTraversalGroup) {
      throw _changed('public foreground group');
    }
    row = _forward(row, (row.widget as FocusTraversalGroup).child, own);
    if (row.widget.runtimeType != Transform) {
      throw _changed('normal foreground transform');
    }
    row = _forward(row, (row.widget as Transform).child!, own);
    if (row.widget.runtimeType != Semantics) {
      throw _changed('normal foreground semantics');
    }
    row = _forward(row, (row.widget as Semantics).child!, own);
    if (row.widget.runtimeType != coui.Stacks) {
      throw _changed('public foreground Stacks');
    }
    final innerDeclaration = row.widget as coui.Stacks;
    row = _only(row);
    own(row);
    if (row.widget.runtimeType != Stack ||
        row is! RenderObjectElement ||
        row.renderObject is! RenderStack) {
      throw _changed('current foreground Stack');
    }
    final inner = _children(row);
    final innerWidgets = (row.widget as Stack).children;
    if (inner.isEmpty ||
        inner.length > 2 ||
        inner.length != innerDeclaration.children.length ||
        inner.length != innerWidgets.length ||
        List.generate(
          inner.length,
          (i) =>
              !identical(inner[i].widget, innerWidgets[i]) ||
              !identical(innerWidgets[i], innerDeclaration.children[i]) ||
              !identical(_parent(inner[i]), row),
        ).any((bad) => bad) ||
        !identical(inner.first.widget, input.child)) {
      throw _changed(
        'complete foreground child and optional generated tap catcher',
      );
    }
    held.addAll([
      for (final e in inner) ...[e, e.widget],
    ]);
    active.add(input.child);
  }
  final unique = Set<Widget>.identity();
  if (raw.whereType<Widget>().any((w) => !unique.add(w))) {
    throw _changed('raw public slot aliases before omission');
  }
  // Icons remain exact raw public source declarations. We never descend
  // into opaque generated platters to prove an icon's mounted implementation.
  final scope = BoxProducerScope(producer: result, suppliedSlots: active)
    ..requireOwned(producer)
    ..requireOwned(field);
  final render = field.renderObject;
  if (render is! RenderBox || !render.attached || !render.hasSize) {
    throw _changed('sized attached frame');
  }
  return (
    result: result,
    producer: producer,
    field: field,
    held: held,
    raw: List.unmodifiable(raw),
    active: List.unmodifiable(active),
    scope: scope,
  );
}

Element _forward(Element parent, Widget declared, void Function(Element) own) {
  var current = _only(parent);
  while (!identical(current.widget, declared)) {
    own(current);
    if (current is RenderObjectElement &&
        current.renderObject is! RenderPointerListener &&
        current.renderObject is! RenderSemanticsGestureHandler &&
        current.renderObject is! RenderSemanticsAnnotations) {
      throw _changed(
        'unexpected allocating operation in public forwarding prefix',
      );
    }
    current = _only(current);
  }
  own(current);
  return current;
}

List<Element> _children(Element e) {
  final list = <Element>[];
  e.visitChildren(list.add);
  return list;
}

Element _only(Element e) {
  final list = _children(e);
  if (list.length != 1) {
    throw _changed('sole normal child');
  }
  return list.single;
}

bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);
BoxObservationError _changed(String detail) =>
    BoxObservationError('PUBLIC_WRAPPER_SOURCE_CHANGED', detail);

Element? _parent(Element e) {
  Element? parent;
  e.visitAncestorElements((a) {
    parent = a;
    return false;
  });
  return parent;
}
