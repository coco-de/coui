import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:coui_flutter/src/components/layout/responsive_grid/render_grid.dart'
    show GridMultiChild, RenderGrid;
import 'package:docs_core/previews/examples/flutter/responsive_container/responsive_container_default_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_grid/responsive_grid_default_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_grid/responsive_grid_span_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_row_column/responsive_row_column_default_example.dart';
import 'package:docs_core/previews/examples/flutter/responsive_row_column/responsive_row_column_desktop_example.dart';
import 'package:flutter/rendering.dart' show RenderFlex, RenderPadding;
import 'package:flutter/widgets.dart'
    show
        Align,
        ConstrainedBox,
        EdgeInsets,
        Element,
        Flex,
        KeyedSubtree,
        LayoutBuilder,
        Padding,
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
  List<Widget> slots,
  String authority,
});

/// Live references to a source-owned responsive host, not measured numbers.
class ResponsiveLayoutBoxSourceBinding {
  ResponsiveLayoutBoxSourceBinding._(
    this._capture,
    this._registry,
    this._source,
    this._route,
  ) : _producerWidget = _route.producer.widget,
      _slots = List.unmodifiable(_route.slots);
  final Element _capture;
  final Widget _registry;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;
  final _Route _route;
  final List<Widget> _slots;

  String get authority => _route.authority;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.frame;
  Element get paddingSource => _route.frame;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId =>
      _source == BoxObservationSourceSpec.responsiveContainerContentInset
      ? 'current-render-padding-v1'
      : 'responsive-layout-declared-absence-v1';

  /// Must run synchronously immediately before Root's unchanged numeric reader.
  /// Current generated Widgets may rebuild, original public inputs may not.
  void validateExistingCurrentBinding() {
    if (!_capture.mounted ||
        !_route.result.mounted ||
        !_route.producer.mounted ||
        !_route.frame.mounted ||
        !identical(_route.result.widget, _registry) ||
        !identical(_route.producer.widget, _producerWidget)) {
      throw _changed('the original mounted input Widget identities');
    }
    final current = _locate(_capture, _registry, _source);
    if (!identical(current.result, _route.result) ||
        !identical(current.producer, _route.producer) ||
        !identical(current.frame, _route.frame) ||
        current.slots.length != _slots.length ||
        current.scope.foreignBoundaries.length !=
            scope.foreignBoundaries.length) {
      throw _changed('the held source Element boundaries');
    }
    for (var i = 0; i < _slots.length; i++) {
      if (!identical(current.slots[i], _slots[i]) ||
          !identical(
            current.scope.foreignBoundaries[i],
            scope.foreignBoundaries[i],
          )) {
        throw _changed('the original ordered public foreign boundaries');
      }
    }
  }

  BoxPaddingObservation readDeclaredAbsence() {
    validateExistingCurrentBinding();
    if (_source == BoxObservationSourceSpec.responsiveContainerContentInset) {
      throw _changed(
        'Container has a real Padding parameter, not declared absence',
      );
    }
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: frameSource,
      producer: registryResultElement,
      contentBoundary: frameSource,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {'sourceContract': _source.logicalUnitId, 'authority': authority},
      ],
      frameOwner: frameSource,
    );
  }
}

ResponsiveLayoutBoxSourceBinding? bindResponsiveLayoutBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!_kSources.any((known) => known.logicalUnitId == source.logicalUnitId)) {
    return null;
  }
  return ResponsiveLayoutBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    _locate(captureRoot, registryResult, source),
  );
}

const _kSources = <BoxObservationSourceSpec>[
  BoxObservationSourceSpec.responsiveFlexLayoutHost,
  BoxObservationSourceSpec.responsiveContainerContentInset,
  BoxObservationSourceSpec.responsiveGridLayoutHost,
];
const _kFlexExamples = <Type>[
  ResponsiveRowColumnDefaultExample,
  ResponsiveRowColumnDesktopExample,
];
const _kGridExamples = <Type>[
  ResponsiveGridDefaultExample,
  ResponsiveGridSpanExample,
];

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
) {
  if (!_kSources.contains(source)) {
    throw _changed('the closed tuple/version');
  }
  final captureWidget = capture.widget;
  if (!identical(captureWidget, registry) &&
      !(captureWidget.runtimeType == KeyedSubtree &&
          identical((captureWidget as KeyedSubtree).child, registry))) {
    throw _changed('the exact registry construction result');
  }
  final result = _identity(capture, registry);
  final container =
      source == BoxObservationSourceSpec.responsiveContainerContentInset;
  final flex = source == BoxObservationSourceSpec.responsiveFlexLayoutHost;
  final type = container
      ? coui.ResponsiveContainer
      : flex
      ? coui.ResponsiveRowColumn
      : coui.ResponsiveGrid;
  final direct = registry.runtimeType == type;
  final example = container
      ? registry.runtimeType == ResponsiveContainerDefaultExample
      : (flex ? _kFlexExamples : _kGridExamples).contains(registry.runtimeType);
  if (!direct && !example) {
    throw _changed('the audited exact Example or producer type');
  }
  final producer = direct ? result : _only(result);
  _concrete(producer, type);
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
      throw _changed('unique raw public slots');
    }
    _identity(producer, slot);
  }
  if (declaration.unrenderedSuppliedSlots.isNotEmpty) {
    throw _changed('the rendered public slot source');
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  late final Element frame;
  if (container) {
    var current = _only(producer);
    if (current.widget.runtimeType == Align) {
      current = _direct(current, (current.widget as Align).child);
    }
    _concrete(current, ConstrainedBox);
    current = _direct(current, (current.widget as ConstrainedBox).child);
    _concrete(current, SizedBox);
    current = _direct(current, (current.widget as SizedBox).child);
    _concrete(current, Padding);
    _direct(current, (producer.widget as coui.ResponsiveContainer).child);
    final render = current.renderObject;
    if (render is! RenderPadding ||
        render.runtimeType != RenderPadding ||
        !render.attached ||
        !render.hasSize ||
        render.padding != (current.widget as Padding).padding) {
      throw _changed('the live forwarded Padding renderer');
    }
    frame = current;
  } else if (flex) {
    frame = _only(producer);
    _concrete(frame, Flex);
    _forwardedChildren((frame.widget as Flex).children, raw);
    final render = frame.renderObject;
    if (render is! RenderFlex ||
        render.runtimeType != RenderFlex ||
        !render.attached ||
        !render.hasSize) {
      throw _changed('the exact current RenderFlex');
    }
  } else {
    final layout = _only(producer);
    _concrete(layout, LayoutBuilder);
    frame = _only(layout);
    _concrete(frame, GridMultiChild);
    _forwardedChildren((frame.widget as GridMultiChild).children, raw);
    final render = frame.renderObject;
    if (render is! RenderGrid ||
        render.runtimeType != RenderGrid ||
        !render.attached ||
        !render.hasSize) {
      throw _changed('the public actual current RenderGrid');
    }
  }
  scope.requireOwned(frame);
  final sourceRoute = container
      ? '; optional Align -> ConstrainedBox -> SizedBox -> own Padding; '
            'no decoration allocation or geometric gaps'
      : flex
      ? '; direct Flex/RenderFlex has no own padding operation; '
            'inter-child spacing and supplied subtrees excluded'
      : '; actual LayoutBuilder child GridMultiChild/RenderGrid has no own '
            'padding operation; no builder re-entry, grid cells and spacing '
            'excluded';
  return (
    result: result,
    producer: producer,
    frame: frame,
    scope: scope,
    slots: List.unmodifiable(raw),
    authority:
        'Exact audited Example/public producer -> actual current source spine; '
        '${declaration.authority}$sourceRoute',
  );
}

void _forwardedChildren(List<Widget> generated, List<Widget> original) {
  if (generated.length != original.length) {
    throw _changed('the source forwarded child count');
  }
  for (var i = 0; i < original.length; i++) {
    if (!identical(generated[i], original[i])) {
      throw _changed('the source ordered child identities');
    }
  }
}

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((e) => identical(e.widget, widget)),
  'the unique actual supplied/source Widget identity',
);
Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the exact generated direct child');
}

Element _direct(Element parent, Widget? child) {
  if (child == null) {
    throw _changed('the required current child');
  }
  final actual = _only(parent);
  if (!identical(actual.widget, child)) {
    throw _changed('the forwarded direct child identity');
  }
  return actual;
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('the exact concrete source type');
  }
}

BoxObservationError _changed(String part) => BoxObservationError(
  'RESPONSIVE_LAYOUT_SOURCE_CHANGED',
  'Unsupported $part; no owner, numeric quantity or absence is inferred.',
);
