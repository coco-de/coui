import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_centered_example.dart';
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_compact_example.dart';
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_default_example.dart';
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_dense_example.dart';
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_prominent_example.dart';
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_text_example.dart';
import 'package:docs_core/previews/examples/flutter/empty_state/empty_state_default_example.dart';
import 'package:docs_core/previews/examples/flutter/empty_state/empty_state_failure_example.dart';
import 'package:docs_core/previews/examples/flutter/empty_state/empty_state_large_example.dart';
import 'package:docs_core/previews/examples/flutter/empty_state/empty_state_success_example.dart';
import 'package:flutter/widgets.dart'
    show
        Center,
        Column,
        ConstrainedBox,
        CustomMultiChildLayout,
        DecoratedBox,
        Element,
        KeyedSubtree,
        Padding,
        Row,
        SizedBox,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

/// Source references only; shared readers own all numeric observations.
typedef SolidLayoutBoxSourceBinding = ({
  String authority,
  Element registryResultElement,
  Element fieldUnitElement,
  Element paddingSource,
  Element? frameSource,
  BoxProducerScope scope,
  String readerId,
});

/// Binds the generated solid bar or empty-state content Padding operation.
///
/// This quantity is the current framework parameter, not physical distance
/// inside the bar's painted divider, Core authored padding or descendant sums.
/// Constructors, callbacks and resolvers are never invoked to recover a source.
SolidLayoutBoxSourceBinding? bindSolidLayoutBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final adapter = switch (source.logicalUnitId) {
    'app-bar-solid-content-inset' => 'app-bar-solid-content-inset-v1',
    'empty-state-generated-content-inset' =>
      'empty-state-generated-content-inset-v1',
    _ => null,
  };
  if (adapter == null) return null;
  if (source.schemaVersion != 1) {
    throw _error('UNSUPPORTED_BOX_SOURCE_VERSION');
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity ||
      source.nativeAdapterId != adapter ||
      source.webAdapterId != adapter) {
    throw _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  }
  final capture = captureRoot.widget;
  if (!identical(capture, registryResult) &&
      !(capture.runtimeType == KeyedSubtree &&
          identical((capture as KeyedSubtree).child, registryResult))) {
    throw _error('MISMATCHED_CONSTRUCTION_RESULT');
  }
  final result = _identity(captureRoot, registryResult);
  final appBar = adapter == 'app-bar-solid-content-inset-v1';
  final type = registryResult.runtimeType;
  final producerType = appBar ? coui.AppBar : coui.EmptyState;
  final examples = appBar
      ? const <Type>[
          AppBarDefaultExample,
          AppBarCompactExample,
          AppBarDenseExample,
          AppBarProminentExample,
          AppBarCenteredExample,
          AppBarTextExample,
        ]
      : const <Type>[
          EmptyStateDefaultExample,
          EmptyStateLargeExample,
          EmptyStateFailureExample,
          EmptyStateSuccessExample,
        ];
  if (type != producerType && !examples.contains(type)) {
    throw _error('UNREGISTERED_SOLID_LAYOUT_CONSTRUCTION');
  }
  final producer = type == producerType ? result : _only(result);
  _concrete(producer, producerType);
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  // Omission does not erase duplicate public slot identities. The existing
  // declaration retains the whole bag across its rendered/omitted partitions.
  final supplied = Set<Widget>.identity();
  for (final slot in [
    ...declaration.scope.suppliedSlots,
    ...declaration.unrenderedSuppliedSlots,
  ]) {
    if (!supplied.add(slot)) throw _error('DUPLICATE_OWNER');
  }
  // A single declared slot mounted twice is independently ambiguous.
  for (final slot in declaration.scope.suppliedSlots) {
    _identity(producer, slot);
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  final route = appBar ? _bar(producer) : _empty(producer);
  scope
    ..requireOwned(route.padding)
    ..requireOwned(route.frame);
  return (
    authority:
        'Exact official example/public producer and mounted Widget identity; '
        '${declaration.authority}; ${route.authority}; '
        'frameworkOwnParameter, not painted-edge or nested-total spacing',
    registryResultElement: result,
    fieldUnitElement: producer,
    paddingSource: route.padding,
    frameSource: route.frame,
    scope: scope,
    readerId: 'current-render-padding-v1',
  );
}

({Element padding, Element frame, String authority}) _bar(Element producer) {
  final widget = producer.widget as coui.AppBar;
  if (widget.variant == coui.CoreAppBarVariant.medium) {
    throw _error('UNSUPPORTED_APP_BAR_MULTILINE_SOURCE');
  }
  var frame = _only(producer);
  if (frame.widget.runtimeType == coui.SurfaceBlur) {
    frame = _child(frame, (frame.widget as coui.SurfaceBlur).child);
  }
  // The glass/snapshot branch builds a SizedBox/Stacks instead. It cannot
  // borrow a decorated child, action capsule or title Padding as this unit.
  _concrete(frame, DecoratedBox);
  final sized = _child(frame, (frame.widget as DecoratedBox).child);
  _concrete(sized, SizedBox);
  final padding = _child(sized, (sized.widget as SizedBox).child);
  _concrete(padding, Padding);
  final content = _child(padding, (padding.widget as Padding).child);
  _concrete(
    content,
    widget.centerTitle && !widget.trailingExpanded
        ? CustomMultiChildLayout
        : Row,
  );
  return (
    padding: padding,
    frame: frame,
    authority:
        'AppBar solid optional SurfaceBlur.child -> DecoratedBox.child -> '
        'SizedBox.child -> Padding; direct Row/centered layout content',
  );
}

({Element padding, Element frame, String authority}) _empty(Element producer) {
  var frame = _only(producer);
  if ((producer.widget as coui.EmptyState).tone ==
      coui.CoreEmptyStateTone.failure) {
    _concrete(frame, coui.CoUISemantics);
    frame = _child(frame, (frame.widget as coui.CoUISemantics).child);
  }
  _concrete(frame, ConstrainedBox);
  final padding = _child(frame, (frame.widget as ConstrainedBox).child);
  _concrete(padding, Padding);
  final center = _child(padding, (padding.widget as Padding).child);
  _concrete(center, Center);
  _concrete(_child(center, (center.widget as Center).child), Column);
  return (
    padding: padding,
    frame: frame,
    authority:
        'EmptyState optional failure CoUISemantics.child -> '
        'ConstrainedBox.child -> Padding -> Center.child Column; '
        'title/icon/description/action remain foreign',
  );
}

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((element) => identical(element.widget, widget)),
  'the actual source Widget identity',
);

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the exact generated source child');
}

Element _child(Element parent, Widget? child) {
  if (child == null) throw _error('MISSING_SOLID_LAYOUT_SOURCE_CHILD');
  return _identity(parent, child);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _error('SOLID_LAYOUT_SOURCE_CHANGED');
  }
}

BoxObservationError _error(String code) => BoxObservationError(
  code,
  'The audited solid-layout construction/source boundary is not satisfied.',
);
