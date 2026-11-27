import 'package:docs_core/previews/examples/flutter/card_image/card_image_default_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_default_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_plain_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_tail_corner_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_tail_top_example.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_cast_motion_example.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_prefix_example.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_selected_example.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_shape_example.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_variant_example.dart';
import 'package:docs_core/previews/examples/flutter/draggable_panel/draggable_panel_default_example.dart';
import 'package:docs_core/previews/examples/flutter/draggable_panel/draggable_panel_outside_example.dart';
import 'package:docs_core/previews/examples/flutter/hidden/hidden_default_example.dart';
import 'package:docs_core/previews/examples/flutter/progress/progress_tone_example.dart';
import 'package:docs_core/previews/examples/flutter/scrollable_client/scrollable_client_default_example.dart';
import 'package:docs_core/previews/examples/flutter/skeleton/skeleton_default_example.dart';
import 'package:docs_core/previews/examples/flutter/step_item/step_item_default_example.dart';
import 'package:docs_core/previews/examples/flutter/table/table_scrollable_example.dart';
import 'package:docs_core/previews/examples/flutter/window/window_default_example.dart';
import 'package:flutter/rendering.dart'
    show RenderBox, RenderConstrainedBox, RenderFlex, RenderObject;
import 'package:flutter/widgets.dart'
    show
        Column,
        EdgeInsets,
        Element,
        Flex,
        KeyedSubtree,
        RenderObjectElement,
        Row,
        SizedBox,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

const _kExamples = <Type, ({Type host, int seats})>{
  CardImageDefaultExample: (host: SizedBox, seats: 1),
  HiddenDefaultExample: (host: Column, seats: 3),
  WindowDefaultExample: (host: Column, seats: 3),
  DraggablePanelDefaultExample: (host: SizedBox, seats: 1),
  DraggablePanelOutsideExample: (host: SizedBox, seats: 1),
  ScrollableClientDefaultExample: (host: SizedBox, seats: 1),
  TableScrollableExample: (host: SizedBox, seats: 1),
  ProgressToneExample: (host: Column, seats: 7),
  ChatDefaultExample: (host: Column, seats: 3),
  ChatPlainExample: (host: Column, seats: 3),
  ChatTailCornerExample: (host: Column, seats: 3),
  ChatTailTopExample: (host: Column, seats: 3),
  ChipSelectedExample: (host: Column, seats: 3),
  ChipVariantExample: (host: Column, seats: 11),
  ChipShapeExample: (host: Row, seats: 4),
  ChipCastMotionExample: (host: Row, seats: 5),
  ChipPrefixExample: (host: Row, seats: 2),
  SkeletonDefaultExample: (host: Column, seats: 3),
  StepItemDefaultExample: (host: SizedBox, seats: 1),
};

typedef _Route = ({
  Element result,
  Element host,
  Widget declaration,
  RenderObject render,
  List<Widget?> raw,
  List<Element> seats,
  List<RenderObject> frontiers,
  BoxProducerScope scope,
});

/// The showcase allocation host; never a contained product's padding box.
class ShowcaseAllocationBoxSourceBinding {
  ShowcaseAllocationBoxSourceBinding._(
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
  Element get fieldUnitElement => _route.host;
  Element get paddingSource => _route.host;
  Element get frameSource => _route.host;
  BoxProducerScope get scope => _route.scope;
  List<Widget?> get allOriginalSuppliedSlots => _route.raw;
  List<Element> get allOriginalMountedSeats => _route.seats;
  String get readerId => 'showcase-allocation-current-framework-host-v1';
  String get authority =>
      'Exact current classic showcase returns its own public '
      'Row/Column/SizedBox allocation; every original child occurrence is a '
      'complete '
      'opaque boundary with distinct mounted Element and renderer in order; '
      'this actual framework host has no padding operation; contained '
      'products, spacing, paint, glyphs and caller interiors are excluded';

  _Route _current() {
    if (!_same(_route.scope.foreignBoundaries, _route.seats)) {
      throw _changed('retained complete per-occurrence foreign boundaries');
    }
    final now = _locate(_capture, _registry, _source);
    if (!identical(now.result, _route.result) ||
        !identical(now.host, _route.host) ||
        !identical(now.declaration, _route.declaration) ||
        !identical(now.render, _route.render) ||
        !_same(now.raw, _route.raw) ||
        !_same(now.seats, _route.seats) ||
        !_same(now.frontiers, _route.frontiers)) {
      throw _changed('original current host, raw occurrences or frontiers');
    }
    return now;
  }

  void validateExistingCurrentBinding() {
    _current();
  }

  BoxPaddingObservation readDeclaredAbsence() {
    final now = _current();
    now.scope.requireOwned(now.host);
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: now.host,
      producer: now.result,
      contentBoundary: now.host,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      frameOwner: now.host,
      generatedSlots: [
        {
          'sourceContract': _source.logicalUnitId,
          'authority': authority,
          'actualFrameworkHostElement': identityHashCode(now.host),
          'actualFrameworkRenderer': now.render.runtimeType.toString(),
          'rawSlots': [
            for (var i = 0; i < now.raw.length; i++)
              {
                'index': i,
                'present': now.raw[i] != null,
                'originalWidget': identityHashCode(now.raw[i]),
                'sameSourceAsEarlierSeat': _earlier(now.raw, i),
                'mountedElement': identityHashCode(now.seats[i]),
                'actualRenderFrontier': identityHashCode(now.frontiers[i]),
              },
          ],
        },
      ],
    );
  }

  BoxPaddingObservation readActualPadding() =>
      throw _changed('parameter reader on a layout-only allocation');
}

ShowcaseAllocationBoxSourceBinding? bindShowcaseAllocationBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.logicalUnitId !=
      BoxObservationSourceSpec.showcaseAllocationHost.logicalUnitId) {
    return null;
  }
  return ShowcaseAllocationBoxSourceBinding._(
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
  if (source != BoxObservationSourceSpec.showcaseAllocationHost ||
      source.validationError != null) {
    throw _changed('complete registered source tuple/version');
  }
  final shape = _kExamples[registry.runtimeType];
  if (shape == null || !capture.mounted) {
    throw _changed('mounted exact audited showcase type');
  }
  final Element result;
  if (identical(capture.widget, registry)) {
    result = capture;
  } else if (capture.widget.runtimeType == KeyedSubtree &&
      identical((capture.widget as KeyedSubtree).child, registry)) {
    result = _only(capture);
  } else {
    throw _changed('original actual capture result identity');
  }
  if (!result.mounted || !identical(result.widget, registry)) {
    throw _changed('original current registry result');
  }
  final host = _only(result);
  requireConcreteBoxSourceType(host.widget, shape.host);
  if (host is! RenderObjectElement || !identical(_parent(host), result)) {
    throw _changed('direct current framework render-object host');
  }
  final input = host.widget;
  // Collect the complete nullable raw vector before checking its branch.
  final raw = input is SizedBox
      ? [input.child]
      : List<Widget?>.of((input as Flex).children);
  if (raw.length != shape.seats || raw.any((child) => child == null)) {
    throw _changed('complete required original raw-slot vector');
  }
  if (raw.any(
    (child) =>
        identical(child, registry) ||
        identical(child, capture.widget) ||
        identical(child, input),
  )) {
    throw _changed('foreign boundary cannot alias its owner or ancestor');
  }
  final seats = _children(host);
  if (seats.length != raw.length ||
      (Set<Element>.identity()..addAll(seats)).length != seats.length) {
    throw _changed('one distinct current Element for every original seat');
  }
  for (var i = 0; i < raw.length; i++) {
    if (!seats[i].mounted ||
        !identical(_parent(seats[i]), host) ||
        !identical(seats[i].widget, raw[i])) {
      throw _changed('raw index to direct mounted Element parent/order');
    }
  }
  final render = host.renderObject;
  if (!render.attached ||
      render is! RenderBox ||
      !render.hasSize ||
      (shape.host == SizedBox
          ? render.runtimeType != RenderConstrainedBox
          : render.runtimeType != RenderFlex)) {
    throw _changed('same current laid-out framework allocation renderer');
  }
  final frontiers = <RenderObject>[];
  for (final seat in seats) {
    final frontier = seat.findRenderObject();
    if (frontier == null ||
        !frontier.attached ||
        !identical(frontier.parent, render)) {
      throw _changed('actual direct opaque child renderer');
    }
    frontiers.add(frontier);
  }
  final actual = <RenderObject>[];
  render.visitChildren(actual.add);
  if (!_same(actual, frontiers) ||
      (Set<RenderObject>.identity()..addAll(frontiers)).length !=
          frontiers.length) {
    throw _changed('complete ordered disjoint actual render frontiers');
  }
  // Scope already retains every matching mounted Element. Its Widget Set is
  // coverage only; the explicit per-occurrence bijection above supplies order
  // and cardinality. Repeated const Widgets do not collapse their seats.
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: raw.whereType<Widget>(),
  )..requireOwned(host);
  if (!_same(scope.foreignBoundaries, seats)) {
    throw _changed('complete opaque foreign occurrence boundaries');
  }
  return (
    result: result,
    host: host,
    declaration: input,
    render: render,
    raw: List.unmodifiable(raw),
    seats: List.unmodifiable(seats),
    frontiers: List.unmodifiable(frontiers),
    scope: scope,
  );
}

Element? _parent(Element element) {
  Element? parent;
  element.visitAncestorElements((ancestor) {
    parent = ancestor;
    return false;
  });
  return parent;
}

List<Element> _children(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return children;
}

Element _only(Element parent) =>
    requireOneBoxOwner(_children(parent), 'exact showcase build edge');

bool _same<T>(List<T> first, List<T> second) =>
    first.length == second.length &&
    List.generate(first.length, (i) => identical(first[i], second[i])).every(
      (same) => same,
    );

int? _earlier(List<Widget?> raw, int index) {
  for (var i = 0; i < index; i++) {
    if (identical(raw[i], raw[index])) return i;
  }
  return null;
}

BoxObservationError _changed(String part) => BoxObservationError(
  'SHOWCASE_ALLOCATION_SOURCE_CHANGED',
  'Unsupported $part; no copied, missing, foreign or stale layout '
      'becomes zero.',
);
