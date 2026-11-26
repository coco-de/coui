import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/loading/loading_bar_example.dart';
import 'package:docs_core/previews/examples/flutter/loading/loading_default_example.dart';
import 'package:docs_core/previews/examples/flutter/loading/loading_dots_example.dart';
import 'package:docs_core/previews/examples/flutter/loading/loading_pulse_example.dart';
import 'package:flutter/rendering.dart' show RenderConstrainedBox;
import 'package:flutter/widgets.dart'
    show
        EdgeInsets,
        Element,
        KeyedSubtree,
        RepaintBoundary,
        Semantics,
        SizedBox,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

typedef _Route = ({
  Element result,
  Element producer,
  Element frame,
  BoxProducerScope scope,
  String authority,
});

/// Witness for Loading's source-created size host, never its animated paint.
class LoadingHostBoxSourceBinding {
  LoadingHostBoxSourceBinding._({
    required _Route route,
    required Element captureRoot,
    required Widget registryResult,
    required BoxObservationSourceSpec source,
  }) : authority = route.authority,
       registryResultElement = route.result,
       fieldUnitElement = route.frame,
       paddingSource = route.frame,
       frameSource = route.frame,
       scope = route.scope,
       _captureRoot = captureRoot,
       _registryWidget = registryResult,
       _producer = route.producer,
       _producerWidget = route.producer.widget,
       _source = source;

  final String authority;
  final Element registryResultElement;
  final Element fieldUnitElement;
  final Element paddingSource;
  final Element frameSource;
  final BoxProducerScope scope;
  final Element _captureRoot;
  final Widget _registryWidget;
  final Element _producer;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;

  String get readerId => 'loading-host-declared-absence-v1';

  /// Revalidates the current source route before returning source absence.
  /// Frame Widgets can rebuild; original construction Widgets cannot change.
  BoxPaddingObservation readDeclaredAbsence() {
    if (!_captureRoot.mounted ||
        !registryResultElement.mounted ||
        !_producer.mounted ||
        !frameSource.mounted ||
        !identical(registryResultElement.widget, _registryWidget) ||
        !identical(_producer.widget, _producerWidget)) {
      throw _changed('the original mounted construction identities');
    }
    final current = _locate(_captureRoot, _registryWidget, _source);
    if (!identical(current.result, registryResultElement) ||
        !identical(current.producer, _producer) ||
        !identical(current.frame, frameSource)) {
      throw _changed('the original source host Element');
    }
    current.scope.requireOwned(current.frame);
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: current.frame,
      producer: current.producer,
      contentBoundary: current.frame,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {
          'sourceContract': _source.logicalUnitId,
          'authority': current.authority,
        },
      ],
      frameOwner: current.frame,
    );
  }
}

LoadingHostBoxSourceBinding? bindLoadingHostBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.logicalUnitId !=
      BoxObservationSourceSpec.loadingSizeHost.logicalUnitId) {
    return null;
  }
  return LoadingHostBoxSourceBinding._(
    route: _locate(captureRoot, registryResult, source),
    captureRoot: captureRoot,
    registryResult: registryResult,
    source: source,
  );
}

const _kExamples = <Type, coui.CoreLoadingVariant>{
  LoadingDefaultExample: coui.CoreLoadingVariant.spinner,
  LoadingDotsExample: coui.CoreLoadingVariant.dots,
  LoadingBarExample: coui.CoreLoadingVariant.bar,
  LoadingPulseExample: coui.CoreLoadingVariant.pulse,
};

_Route _locate(
  Element captureRoot,
  Widget registryResult,
  BoxObservationSourceSpec source,
) {
  if (source != BoxObservationSourceSpec.loadingSizeHost) {
    throw _changed('the closed source tuple/version');
  }
  final capture = captureRoot.widget;
  if (!identical(capture, registryResult) &&
      !(capture.runtimeType == KeyedSubtree &&
          identical((capture as KeyedSubtree).child, registryResult))) {
    throw _changed('the actual capture construction result');
  }
  final result = _identity(captureRoot, registryResult);
  final direct = registryResult.runtimeType == coui.Loading;
  if (!direct && !_kExamples.containsKey(registryResult.runtimeType)) {
    throw _changed('the exact audited example or public producer');
  }
  final producer = direct ? result : _only(result);
  _concrete(producer, coui.Loading);
  final loading = producer.widget as coui.Loading;
  if (!direct && loading.variant != _kExamples[registryResult.runtimeType]) {
    throw _changed('the example source variant');
  }
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final rawSlots = [
    ...declaration.scope.suppliedSlots,
    ...declaration.unrenderedSuppliedSlots,
  ];
  final identities = Set<Widget>.identity();
  for (final slot in rawSlots) {
    if (!identities.add(slot)) throw _changed('unique public source slots');
    _identity(producer, slot);
  }
  if (rawSlots.isNotEmpty || declaration.scope.foreignBoundaries.isNotEmpty) {
    throw _changed('the audited data-only Loading constructor');
  }
  final scope = BoxProducerScope(producer: result, suppliedSlots: const [])
    ..requireOwned(producer);
  final semantics = _only(producer);
  _concrete(semantics, Semantics);
  final repaint = _directChild(
    semantics,
    (semantics.widget as Semantics).child,
  );
  _concrete(repaint, RepaintBoundary);
  final frame = _directChild(
    repaint,
    (repaint.widget as RepaintBoundary).child,
  );
  _concrete(frame, SizedBox);
  final indicator = (frame.widget as SizedBox).child;
  _directChild(frame, indicator);
  final render = frame.renderObject;
  if (render is! RenderConstrainedBox ||
      render.runtimeType != RenderConstrainedBox ||
      !render.attached ||
      !render.hasSize) {
    throw _changed('the attached current sizing RenderConstrainedBox');
  }
  scope.requireOwned(frame);
  return (
    result: result,
    producer: producer,
    frame: frame,
    scope: scope,
    authority:
        'Exact Loading construction/example variant '
        'and actual source child refs; '
        'Semantics.child -> RepaintBoundary.child -> '
        'SizedBox/current RenderConstrainedBox; '
        'no own padding operation; private indicator subtree '
        'and paint excluded; '
        '${declaration.authority}',
  );
}

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((element) => identical(element.widget, widget)),
  'the unique actual source Widget identity',
);
Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the single source-created child');
}

Element _directChild(Element parent, Widget? child) {
  if (child == null) throw _changed('the required current source child');
  final element = _only(parent);
  if (!identical(element.widget, child)) {
    throw _changed('the exact direct child identity');
  }
  return element;
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('the exact concrete source type');
  }
}

BoxObservationError _changed(String part) => BoxObservationError(
  'LOADING_HOST_SOURCE_CHANGED',
  'Unsupported $part; no owner or absence is inferred.',
);
