import 'package:docs_core/previews/examples/flutter/breakpoint/breakpoint_default_example.dart';
import 'package:flutter/painting.dart' show BoxDecoration;
import 'package:flutter/rendering.dart' show RenderBox, RenderPadding;
import 'package:flutter/widgets.dart'
    show Container, Element, KeyedSubtree, Padding, Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

const BoxObservationSourceSpec kBreakpointShowcaseContentInsetSource =
    BoxObservationSourceSpec.breakpointShowcaseContentInset;

typedef _Route = ({
  Element result,
  Element container,
  Container declaration,
  BoxDecoration decoration,
  Element content,
  Element padding,
  Padding paddingDeclaration,
  RenderPadding render,
  RenderBox frameRender,
  List<Widget?> raw,
  List<Element> generated,
  List<Widget> generatedWidgets,
  BoxProducerScope scope,
  BoxPaddingObservation observation,
});

/// Only the current exact public Example may declare this Container allocation.
/// The readout Text subtree is a whole supplied boundary, never a candidate.
class BreakpointShowcaseBoxSourceBinding {
  BreakpointShowcaseBoxSourceBinding._(
    this._capture,
    this._registry,
    this._source,
    this._route,
  );
  final Element _capture;
  final Widget _registry;
  final BoxObservationSourceSpec _source;
  final _Route _route;

  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.container;
  Element get paddingSource => _route.container;
  Element get frameSource => _route.container;
  Element get actualPaddingElement => _route.padding;
  BoxProducerScope get scope => _route.scope;
  List<Widget?> get allOriginalSuppliedSlots => _route.raw;
  String get readerId => 'breakpoint-showcase-actual-container-padding-v1';
  String get authority =>
      'Original exact BreakpointDefaultExample -> direct public Container '
      'with actual borderless BoxDecoration -> current pinned framework '
      'Padding/RenderPadding; original child opaque; no build/listener replay '
      'or viewport/text/Core-value selection';

  _Route _current() {
    if (_route.scope.foreignBoundaries.length != 1 ||
        !identical(_route.scope.foreignBoundaries.single, _route.content)) {
      throw _changed('retained whole foreign child boundary');
    }
    final now = _locate(_capture, _registry, _source);
    if (!identical(now.result, _route.result) ||
        !identical(now.container, _route.container) ||
        !identical(now.declaration, _route.declaration) ||
        !identical(now.decoration, _route.decoration) ||
        !identical(now.content, _route.content) ||
        !identical(now.padding, _route.padding) ||
        !identical(now.paddingDeclaration, _route.paddingDeclaration) ||
        !identical(now.render, _route.render) ||
        !identical(now.frameRender, _route.frameRender) ||
        !identical(now.raw.single, _route.raw.single) ||
        now.generated.length != _route.generated.length ||
        List.generate(
          now.generated.length,
          (i) =>
              identical(now.generated[i], _route.generated[i]) &&
              identical(now.generatedWidgets[i], _route.generatedWidgets[i]),
        ).any((same) => !same)) {
      throw _changed(
        'held actual declaration, framework route or child identity',
      );
    }
    return now;
  }

  void validateExistingCurrentBinding() {
    _current();
  }

  BoxPaddingObservation readActualPadding() {
    final now = _current();
    final observation = now.observation;
    final v = observation.value;
    if (observation.quantity != PaddingQuantityKind.frameworkOwnParameter ||
        [
          v.top,
          v.right,
          v.bottom,
          v.left,
        ].any((side) => !side.isFinite || side < 0)) {
      throw _changed('finite actual own framework parameter');
    }
    return observation.withFrameOwner(now.container);
  }

  BoxPaddingObservation readDeclaredAbsence() =>
      throw _changed('absence reader for an existing own Container padding');
}

BreakpointShowcaseBoxSourceBinding? bindBreakpointShowcaseBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.logicalUnitId !=
      kBreakpointShowcaseContentInsetSource.logicalUnitId) {
    return null;
  }
  return BreakpointShowcaseBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    _locate(captureRoot, registryResult, source),
  );
}

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
) {
  if (source != kBreakpointShowcaseContentInsetSource ||
      !capture.mounted ||
      registry.runtimeType != BreakpointDefaultExample) {
    throw _changed('closed tuple and exact mounted public Example');
  }
  final Element result;
  if (identical(capture.widget, registry)) {
    result = capture;
  } else if (capture.widget.runtimeType == KeyedSubtree &&
      identical((capture.widget as KeyedSubtree).child, registry)) {
    result = _only(capture);
  } else {
    throw _changed('original capture construction result');
  }
  if (!result.mounted || !identical(result.widget, registry)) {
    throw _changed('current registry Example identity');
  }
  final container = _only(result);
  requireConcreteBoxSourceType(container.widget, Container);
  final declaration = container.widget as Container;
  final raw = <Widget?>[declaration.child];
  // Capture nullable declarations before enforcing this reviewed construction.
  if (raw.single == null ||
      declaration.padding == null ||
      declaration.decoration.runtimeType != BoxDecoration ||
      declaration.foregroundDecoration != null) {
    throw _changed(
      'complete original child/padding/borderless decoration construction',
    );
  }
  final decoration = declaration.decoration! as BoxDecoration;
  // Source-level allocation premise, not a comparison with padding values.
  if (decoration.border != null) {
    throw _changed('explicit BoxDecoration border absence');
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: raw.whereType<Widget>(),
  )..requireOwned(container);
  if (scope.foreignBoundaries.length != 1) {
    throw _changed('one whole original child');
  }
  final content = scope.foreignBoundaries.single;
  if (!content.mounted || !identical(content.widget, raw.single)) {
    throw _changed('original opaque child identity');
  }
  final observed = observeCurrentContainerPadding(
    owner: container,
    scope: scope,
    declaredContentBoundary: content,
  );
  final padding = observed.paddingElement;
  if (padding == null) {
    throw _changed('existing generated own Padding allocation');
  }
  requireConcreteBoxSourceType(padding.widget, Padding);
  scope.requireOwned(padding);
  final frameRender = container.findRenderObject();
  if (frameRender is! RenderBox ||
      !frameRender.attached ||
      !frameRender.hasSize) {
    throw _changed('actual independently laid-out Container frame renderer');
  }
  final render = padding.renderObject;
  if (render is! RenderPadding ||
      !render.attached ||
      !render.hasSize ||
      !identical(render.child, content.findRenderObject())) {
    throw _changed(
      'current same independently laid-out RenderPadding/content frame',
    );
  }
  // Retain every generated edge before the opaque supplied child. Existing
  // observeCurrentContainerPadding validates their framework slot order.
  final generated = <Element>[];
  var current = container;
  while (!identical(current, content)) {
    scope.requireOwned(current);
    generated.add(current);
    current = _only(current);
  }
  return (
    result: result,
    container: container,
    declaration: declaration,
    decoration: decoration,
    content: content,
    padding: padding,
    paddingDeclaration: padding.widget as Padding,
    render: render,
    frameRender: frameRender,
    raw: List.unmodifiable(raw),
    generated: List.unmodifiable(generated),
    generatedWidgets: List.unmodifiable(generated.map((e) => e.widget)),
    scope: scope,
    observation: observed,
  );
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'exact current Breakpoint showcase edge');
}

BoxObservationError _changed(String part) => BoxObservationError(
  'BREAKPOINT_SHOWCASE_SOURCE_CHANGED',
  'Unsupported $part; no missing, stale or foreign allocation becomes zero.',
);
