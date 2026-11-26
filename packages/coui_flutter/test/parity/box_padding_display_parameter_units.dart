import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/skeleton/skeleton_circle_example.dart';
import 'package:docs_core/previews/examples/flutter/status/status_default_example.dart';
import 'package:docs_core/previews/examples/flutter/status/status_error_example.dart';
import 'package:docs_core/previews/examples/flutter/status/status_success_example.dart';
import 'package:docs_core/previews/examples/flutter/status/status_warning_example.dart';
import 'package:docs_core/previews/examples/flutter/tag/tag_default_example.dart';
import 'package:flutter/widgets.dart'
    show
        AnimatedBuilder,
        Builder,
        Container,
        DefaultTextStyle,
        Element,
        KeyedSubtree,
        Row,
        Semantics,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

const _kStatus = 'status-generated-dot-content-inset';
const _kTag = 'tag-generated-label-content-inset';
const _kSkeleton = 'skeleton-circular-block-content-inset';

/// Source refs only. The coordinator validates immediately before its existing
/// current-container reader; no style, expected or numeric values live here.
class DisplayParameterBoxSourceBinding {
  DisplayParameterBoxSourceBinding._(
    this._capture,
    this._resultWidget,
    this._unit,
    this._route,
  ) : _producerWidget = _route.producer.widget;

  final Element _capture;
  final Widget _resultWidget;
  final Widget _producerWidget;
  final String _unit;
  final _Route _route;

  String get authority => _route.authority;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.frame;
  Element get paddingSource => _route.frame;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId => 'current-container-v1';

  /// Original inputs cannot be re-certified after same-key Widget replacement.
  /// Current generated frame Widgets may change during theme/animation rebuilds.
  void validateCurrentConstruction() {
    for (final pair in [
      (_route.result, _resultWidget),
      (_route.producer, _producerWidget),
    ]) {
      if (!pair.$1.mounted || !identical(pair.$1.widget, pair.$2)) {
        throw _error('STALE_DISPLAY_PARAMETER_CONSTRUCTION');
      }
    }
    final current = _locate(_capture, _resultWidget, _unit);
    if (!identical(current.result, _route.result) ||
        !identical(current.producer, _route.producer) ||
        !identical(current.frame, _route.frame) ||
        current.scope.foreignBoundaries.length !=
            _route.scope.foreignBoundaries.length ||
        current.scope.foreignBoundaries.any(
          (element) => !_route.scope.foreignBoundaries.any(
            (old) => identical(old, element),
          ),
        )) {
      throw _error('DISPLAY_PARAMETER_SOURCE_CHANGED');
    }
  }
}

DisplayParameterBoxSourceBinding? bindDisplayParameterBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!const {_kStatus, _kTag, _kSkeleton}.contains(source.logicalUnitId)) {
    return null;
  }
  if (source.schemaVersion != 1) {
    throw _error('UNSUPPORTED_BOX_SOURCE_VERSION');
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity ||
      source.nativeAdapterId != '${source.logicalUnitId}-v1' ||
      source.webAdapterId != '${source.logicalUnitId}-v1') {
    throw _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  }
  return DisplayParameterBoxSourceBinding._(
    captureRoot,
    registryResult,
    source.logicalUnitId,
    _locate(captureRoot, registryResult, source.logicalUnitId),
  );
}

typedef _Route = ({
  Element result,
  Element producer,
  Element frame,
  BoxProducerScope scope,
  String authority,
});

_Route _locate(Element capture, Widget resultWidget, String unit) {
  final wrapper = capture.widget;
  if (!capture.mounted ||
      (!identical(wrapper, resultWidget) &&
          !(wrapper.runtimeType == KeyedSubtree &&
              identical((wrapper as KeyedSubtree).child, resultWidget)))) {
    throw _error('MISMATCHED_DISPLAY_PARAMETER_RESULT');
  }
  final result = _identity(capture, resultWidget);
  final exampleTypes = switch (unit) {
    _kStatus => const {
      StatusDefaultExample,
      StatusSuccessExample,
      StatusWarningExample,
      StatusErrorExample,
    },
    _kTag => const {TagDefaultExample},
    _ => const {SkeletonCircleExample},
  };
  final producerType = switch (unit) {
    _kStatus => coui.Status,
    _kTag => coui.Tag,
    _ => coui.Skeleton,
  };
  final isExample = exampleTypes.contains(resultWidget.runtimeType);
  if (!isExample && resultWidget.runtimeType != producerType) {
    throw _error('UNREGISTERED_DISPLAY_PARAMETER_CONSTRUCTION');
  }
  final producer = isExample ? _only(result) : result;
  _concrete(producer, producerType);
  final input = producer.widget;
  if (input is coui.Status &&
      (input.label != null || input.variant != null || input.animated)) {
    throw _error('STATUS_DOT_INPUT_CHANGED');
  }
  if (input is coui.Skeleton &&
      input.variant != coui.CoreSkeletonVariant.circular) {
    throw _error('SKELETON_CIRCLE_INPUT_CHANGED');
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
    if (!seen.add(slot)) throw _error('DUPLICATE_OWNER');
  }
  for (final slot in declaration.scope.suppliedSlots) {
    _identity(producer, slot);
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  var frame = _only(producer);
  if (input is coui.Tag) {
    _concrete(frame, coui.InjectedCast);
    frame = _child(frame, (frame.widget as coui.InjectedCast).child);
    if (frame.widget.runtimeType == coui.SurfaceBlur) {
      frame = _child(frame, (frame.widget as coui.SurfaceBlur).child);
    }
    _concrete(frame, Container);
    final row = _child(frame, (frame.widget as Container).child);
    _concrete(row, Row);
    final children = (row.widget as Row).children;
    if (children.length != 1) throw _error('TAG_LABEL_SOURCE_CHANGED');
    final builder = _child(row, children.single);
    _concrete(builder, Builder);
    final textStyle = _only(builder);
    _concrete(textStyle, DefaultTextStyle);
    if (!identical((textStyle.widget as DefaultTextStyle).child, input.child)) {
      throw _error('TAG_LABEL_SOURCE_CHANGED');
    }
    final foreign = _child(textStyle, input.child);
    if (!scope.foreignBoundaries.any((e) => identical(e, foreign))) {
      throw _error('TAG_FOREIGN_BOUNDARY_CHANGED');
    }
  } else {
    if (input is coui.Status && input.semanticLabel != null ||
        input is coui.Skeleton) {
      _concrete(frame, Semantics);
      frame = _child(frame, (frame.widget as Semantics).child);
    }
    if (input is coui.Skeleton) {
      // Only the observed mounted operation, never AnimatedBuilder.builder().
      _concrete(frame, AnimatedBuilder);
      frame = _only(frame);
    }
    _concrete(frame, Container);
    if ((frame.widget as Container).child != null) {
      throw _error('DISPLAY_PARAMETER_FRAME_CONTENT_CHANGED');
    }
  }
  scope.requireOwned(frame);
  return (
    result: result,
    producer: producer,
    frame: frame,
    scope: scope,
    authority:
        'Exact public producer/parameterless Example and mounted Widget refs; '
        '${declaration.authority}; actual current Container own content inset, '
        'excluding its decoration allocation, alignment '
        'and foreign child inset',
  );
}

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((element) => identical(element.widget, widget)),
  'the declared display-parameter Widget identity',
);

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(
    children,
    'the direct display-parameter build slot',
  );
}

Element _child(Element parent, Widget? child) {
  if (child == null) throw _error('MISSING_DISPLAY_PARAMETER_CHILD');
  return _identity(parent, child);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _error('DISPLAY_PARAMETER_SOURCE_CHANGED');
  }
}

BoxObservationError _error(String code) => BoxObservationError(
  code,
  'The closed display-parameter source is incomplete; no value inferred.',
);
