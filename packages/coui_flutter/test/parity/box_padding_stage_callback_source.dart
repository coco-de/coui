// Observes the normal, already executed Stage callback Padding operation.
import 'package:coui_flutter/coui_flutter.dart' show StageContainer;
import 'package:docs_core/previews/examples/flutter/stage_container/stage_container_default_example.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        Directionality,
        Element,
        KeyedSubtree,
        LayoutBuilder,
        Padding,
        RenderObjectElement,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

typedef _CurrentStage = ({
  Element padding,
  Element body,
  List<Object?> held,
  BoxProducerScope scope,
});

/// One current public Padding parameter, separate from the original frame.
/// Neither this binding nor the existing parameter reader invokes a builder.
class StageCallbackContentBinding {
  StageCallbackContentBinding._(
    this.stage,
    this.registry,
    this.original,
    this.capture,
  ) : _held = _snapshot(stage, registry, original, capture);

  final Element stage;
  final Element? registry;
  final Widget? original;
  final Element? capture;
  final _CurrentStage _held;

  Element get paddingSource => _held.padding;
  Element get bodyBoundary => _held.body;
  String get readerId => 'stage-already-executed-callback-padding-v1';
  String get authority =>
      'original public Stage/LayoutBuilder -> already executed Padding '
      'parameter -> one opaque Padding.child; callback identity held, '
      'no callback, constraint or resolver replay';

  void validateCurrentBinding() {
    final now = _snapshot(stage, registry, original, capture);
    if (now.held.length != _held.held.length ||
        List.generate(
          now.held.length,
          (i) => identical(now.held[i], _held.held[i]),
        ).any((same) => !same)) {
      throw _changed('held callback, current prefix or parameter reference');
    }
  }

  BoxPaddingObservation readActualPadding() {
    validateCurrentBinding();
    final result = observeSourceOwnedRenderPadding(
      owner: paddingSource,
      scope: _held.scope,
    );
    validateCurrentBinding();
    // The Stage frame is the original field unit; the inner Padding is the
    // parameter owner. Do not promote a descendant's paint into that frame.
    return result.withFrameOwner(stage);
  }

  Map<String, Object?> get sourceIdentity {
    validateCurrentBinding();
    return {
      'kind': 'stage-current-callback-padding-v1',
      'quantityBoundary': 'original-stage-frame-to-opaque-callback-content',
      'frameElement': identityHashCode(stage),
      'paddingElement': identityHashCode(paddingSource),
      'bodyBoundaryElement': identityHashCode(bodyBoundary),
      'callbackReexecuted': false,
      'bodyInteriorIsSourceAuthority': false,
      'heldBeforeAfterRequired': true,
    };
  }
}

StageCallbackContentBinding bindStageCallbackEntry({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source != BoxObservationSourceSpec.stageCallbackContentInset ||
      source.validationError != null ||
      registryResult.runtimeType != StageContainerDefaultExample) {
    throw _changed('closed original Stage Example and complete source tuple');
  }
  final registry = identical(captureRoot.widget, registryResult)
      ? captureRoot
      : captureRoot.widget.runtimeType == KeyedSubtree &&
            identical(
              (captureRoot.widget as KeyedSubtree).child,
              registryResult,
            )
      ? _only(captureRoot)
      : throw _changed('original keyed registry mount');
  if (!identical(registry.widget, registryResult)) {
    throw _changed('same original Example occurrence');
  }
  final stage = _only(registry);
  return StageCallbackContentBinding._(
    stage,
    registry,
    registryResult,
    captureRoot,
  );
}

/// Test/tool binding of a real public Stage mount; production uses the closed
/// Example entry above. This does not call Stage.build or either builder.
StageCallbackContentBinding bindCurrentStageCallbackContent(Element stage) =>
    StageCallbackContentBinding._(stage, null, null, null);

_CurrentStage _snapshot(
  Element stage,
  Element? registry,
  Widget? original,
  Element? capture,
) {
  if (!stage.mounted || stage.widget.runtimeType != StageContainer) {
    throw _changed('mounted exact public Stage');
  }
  if (registry != null &&
      (!registry.mounted ||
          !identical(registry.widget, original) ||
          !identical(_only(registry), stage))) {
    throw _changed('held original Example -> Stage edge');
  }
  if (capture != null &&
      (!capture.mounted ||
          !(identical(capture, registry) &&
                  identical(capture.widget, original) ||
              capture.widget.runtimeType == KeyedSubtree &&
                  identical((capture.widget as KeyedSubtree).child, original) &&
                  identical(_only(capture), registry)))) {
    throw _changed('held original capture -> registry edge');
  }
  final input = stage.widget as StageContainer;
  final layout = _only(stage);
  if (layout.widget.runtimeType != LayoutBuilder ||
      layout is! RenderObjectElement ||
      !layout.renderObject.attached) {
    throw _changed('the complete current public LayoutBuilder operation');
  }
  final padding = _only(layout);
  if (padding.widget.runtimeType != Padding ||
      padding is! RenderObjectElement ||
      padding.renderObject is! RenderPadding) {
    throw _changed('one already executed Padding callback result');
  }
  final widget = padding.widget as Padding;
  final render = padding.renderObject as RenderPadding;
  final child = widget.child;
  if (!render.attached || child == null) {
    throw _changed('attached real parameter and complete opaque child');
  }
  final body = _only(padding);
  if (!identical(body.widget, child)) {
    throw _changed('same declared whole callback content boundary');
  }
  final scope = BoxProducerScope(producer: stage, suppliedSlots: [child]);
  if (scope.foreignBoundaries.length != 1 ||
      !identical(scope.foreignBoundaries.single, body)) {
    throw _changed('one pruned whole callback body occurrence');
  }
  scope.requireOwned(padding);
  return (
    padding: padding,
    body: body,
    scope: scope,
    held: [
      if (registry != null) ...[registry, original],
      if (capture != null) ...[capture, capture.widget],
      stage,
      input,
      input.builder,
      layout,
      layout.widget,
      (layout.widget as LayoutBuilder).builder,
      layout.renderObject,
      padding,
      widget,
      widget.padding,
      render,
      render.padding,
      render.textDirection,
      Directionality.maybeOf(padding),
      child,
      body,
    ],
  );
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  if (!parent.mounted || children.length != 1 || !children.single.mounted) {
    throw _changed('complete sole current child');
  }
  final child = children.single;
  Element? actualParent;
  child.visitAncestorElements((ancestor) {
    actualParent = ancestor;
    return false;
  });
  if (!identical(actualParent, parent)) throw _changed('current parent edge');
  return child;
}

BoxObservationError _changed(String detail) => BoxObservationError(
  'STAGE_CALLBACK_CONTENT_SOURCE_CHANGED',
  detail,
);
