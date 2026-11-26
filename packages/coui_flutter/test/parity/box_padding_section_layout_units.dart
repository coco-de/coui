import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/breadcrumb/breadcrumb_default_example.dart';
import 'package:docs_core/previews/examples/flutter/collapsible/collapsible_default_example.dart';
import 'package:docs_core/previews/examples/flutter/disclosure/disclosure_chain_example.dart';
import 'package:docs_core/previews/examples/flutter/disclosure/disclosure_default_example.dart';
import 'package:docs_core/previews/examples/flutter/disclosure/disclosure_group_example.dart';
import 'package:docs_core/previews/examples/flutter/resizable/resizable_default_example.dart';
import 'package:flutter/rendering.dart'
    show RenderBox, RenderFlex, RenderPadding;
import 'package:flutter/widgets.dart'
    show
        Column,
        EdgeInsets,
        Element,
        Expanded,
        Flex,
        InheritedWidget,
        IntrinsicWidth,
        KeyedSubtree,
        LayoutBuilder,
        Padding,
        Positioned,
        Row,
        ScrollConfiguration,
        Semantics,
        SingleChildScrollView,
        SizedBox,
        Stack,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

enum _Kind { disclosure, group, collapsible, resizable, breadcrumb }

typedef _Route = ({
  Element result,
  Element producer,
  Element frame,
  BoxProducerScope scope,
  List<Widget> raw,
  bool? expanded,
  String authority,
});

/// Current source references. No builder, callback or private State is read.
class SectionLayoutBoxSourceBinding {
  SectionLayoutBoxSourceBinding._(
    this._capture,
    this._registry,
    this._source,
    this._kind,
    this._route,
  ) : _producerWidget = _route.producer.widget,
      _raw = List.unmodifiable(_route.raw);

  final Element _capture;
  final Widget _registry;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;
  final _Kind _kind;
  final _Route _route;
  final List<Widget> _raw;

  String get authority => _route.authority;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.frame;
  Element get paddingSource => _route.frame;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId => _kind == _Kind.disclosure
      ? 'current-render-padding-v1'
      : 'section-layout-declared-absence-v1';

  void validateExistingCurrentBinding() {
    if (!_capture.mounted ||
        !_route.result.mounted ||
        !_route.producer.mounted ||
        !_route.frame.mounted ||
        !identical(_route.result.widget, _registry) ||
        !identical(_route.producer.widget, _producerWidget)) {
      throw _changed('the original mounted construction identities');
    }
    final current = _locate(_capture, _registry, _source, _kind);
    if (!identical(current.result, _route.result) ||
        !identical(current.producer, _route.producer) ||
        !identical(current.frame, _route.frame) ||
        current.expanded != _route.expanded ||
        !_sameWidgets(current.raw, _raw) ||
        current.scope.foreignBoundaries.length !=
            scope.foreignBoundaries.length) {
      throw _changed('the held current operation and foreign boundaries');
    }
    for (var i = 0; i < scope.foreignBoundaries.length; i++) {
      if (!identical(
        current.scope.foreignBoundaries[i],
        scope.foreignBoundaries[i],
      )) {
        throw _changed('the original complete foreign boundaries');
      }
    }
  }

  BoxPaddingObservation readDeclaredAbsence() {
    validateExistingCurrentBinding();
    if (_kind == _Kind.disclosure) {
      throw _changed('Disclosure has an actual header Padding operation');
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
        {'sourceContract': readerId, 'authority': authority},
      ],
      frameOwner: frameSource,
    );
  }
}

SectionLayoutBoxSourceBinding? bindSectionLayoutBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final kind = switch (source.logicalUnitId) {
    'disclosure-generated-header-content-inset' => _Kind.disclosure,
    'disclosure-group-generated-layout-host' => _Kind.group,
    'collapsible-generated-section-layout-host' => _Kind.collapsible,
    'resizable-generated-pane-layout-host' => _Kind.resizable,
    'breadcrumb-generated-trail-layout-host' => _Kind.breadcrumb,
    _ => null,
  };
  if (kind == null) return null;
  return SectionLayoutBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    kind,
    _locate(captureRoot, registryResult, source, kind),
  );
}

BoxObservationSourceSpec _spec(_Kind kind) => switch (kind) {
  _Kind.disclosure => BoxObservationSourceSpec.disclosureHeaderContentInset,
  _Kind.group => BoxObservationSourceSpec.disclosureGroupLayoutHost,
  _Kind.collapsible => BoxObservationSourceSpec.collapsibleSectionLayoutHost,
  _Kind.resizable => BoxObservationSourceSpec.resizablePaneLayoutHost,
  _Kind.breadcrumb => BoxObservationSourceSpec.breadcrumbTrailLayoutHost,
};
Type _type(_Kind kind) => switch (kind) {
  _Kind.disclosure => coui.Disclosure,
  _Kind.group => coui.DisclosureGroup,
  _Kind.collapsible => coui.Collapsible,
  _Kind.resizable => coui.Resizable,
  _Kind.breadcrumb => coui.Breadcrumb,
};
bool _example(Widget widget, _Kind kind) => switch (kind) {
  _Kind.disclosure =>
    widget.runtimeType == DisclosureDefaultExample ||
        widget.runtimeType == DisclosureChainExample,
  _Kind.group => widget.runtimeType == DisclosureGroupExample,
  _Kind.collapsible => widget.runtimeType == CollapsibleDefaultExample,
  _Kind.resizable => widget.runtimeType == ResizableDefaultExample,
  _Kind.breadcrumb => widget.runtimeType == BreadcrumbDefaultExample,
};

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
  _Kind kind,
) {
  if (source != _spec(kind)) throw _changed('the closed source tuple/version');
  if (!capture.mounted ||
      !(identical(capture.widget, registry) ||
          (capture.widget.runtimeType == KeyedSubtree &&
              identical((capture.widget as KeyedSubtree).child, registry)))) {
    throw _changed('the exact capture construction result');
  }
  final result = _identity(capture, registry);
  final direct = registry.runtimeType == _type(kind);
  if (!direct && !_example(registry, kind)) {
    throw _changed('an exact audited Example or concrete producer');
  }
  var producer = direct ? result : _only(result);
  if (!direct && kind == _Kind.resizable) {
    _concrete(producer, SizedBox);
    producer = _child(producer, (producer.widget as SizedBox).child);
  }
  _concrete(producer, _type(kind));

  // The current closed Disclosure omits content. Its public header Semantics
  // authenticates that operation; widget.open is only a seed and is never read.
  if (kind == _Kind.disclosure) {
    final input = producer.widget as coui.Disclosure;
    final raw = <Widget>[?input.trigger, input.content];
    _unique(raw);
    final column = _only(producer);
    _concrete(column, Column);
    final seats = (column.widget as Column).children;
    if (seats.isEmpty || seats.length > 2) throw _changed('the section seats');
    final clickable = _child(column, seats.first);
    _concrete(clickable, coui.Clickable);
    final semantics = _child(
      clickable,
      (clickable.widget as coui.Clickable).child,
      direct: false,
    );
    _concrete(semantics, Semantics);
    final properties = (semantics.widget as Semantics).properties;
    final expanded = properties.expanded;
    if (properties.button != true ||
        expanded == null ||
        seats.length != (expanded ? 2 : 1)) {
      throw _changed('the own header current expanded operation');
    }
    final frame = _child(semantics, (semantics.widget as Semantics).child);
    _concrete(frame, Padding);
    final row = _child(frame, (frame.widget as Padding).child);
    _concrete(row, Row);
    final rendered = <Widget>[];
    for (final slot in raw) {
      final matches = boxElements(
        producer,
      ).where((e) => identical(e.widget, slot)).toList();
      if (identical(slot, input.content) && !expanded) {
        if (matches.isNotEmpty) throw _changed('closed content must be absent');
      } else {
        final boundary = requireOneBoxOwner(
          matches,
          'current raw Disclosure slot',
        );
        final seat = identical(slot, input.content)
            ? _child(column, seats[1])
            : row;
        if (!BoxProducerScope.contains(seat, boundary)) {
          throw _changed('the original trigger/content seat identity');
        }
        rendered.add(slot);
      }
    }
    final scope = BoxProducerScope(producer: result, suppliedSlots: rendered);
    [
      producer,
      column,
      clickable,
      semantics,
      frame,
      row,
    ].forEach(scope.requireOwned);
    _render(frame, RenderPadding);
    return (
      result: result,
      producer: producer,
      frame: frame,
      scope: scope,
      raw: raw,
      expanded: expanded,
      authority:
          'Exact Disclosure source Column -> header Clickable public '
          'child -> own Semantics(current expanded) -> actual Padding/RenderPadding; '
          'complete raw trigger/content identities checked before current omission; '
          'body top inset and foreign subtrees excluded; '
          'no initial open inference',
    );
  }

  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final raw = <Widget>[
    ...declaration.scope.suppliedSlots,
    ...declaration.unrenderedSuppliedSlots,
  ];
  _unique(raw);
  if (declaration.unrenderedSuppliedSlots.isNotEmpty) {
    throw _changed('all declared maintained inputs must be mounted');
  }
  for (final slot in raw) {
    _identity(producer, slot);
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  final Element frame;
  switch (kind) {
    case _Kind.group:
      frame = _only(producer);
      _concrete(frame, Column);
      _forwarded(frame, (frame.widget as Column).children, raw);
    case _Kind.collapsible:
      // Data.inherit first builds a public Data Widget, then an inherited
      // bridge forwarding its exact public child. The private data argument
      // and State are never read; the original child fixes the layout path.
      final dataElement = _only(producer);
      if (dataElement.widget is! coui.Data<Object?>) {
        throw _changed('the source public Data.inherit construction');
      }
      final inputChild = (dataElement.widget as coui.Data<Object?>).child;
      final bridge = _only(dataElement);
      if (bridge.widget is! InheritedWidget ||
          !identical((bridge.widget as InheritedWidget).child, inputChild)) {
        throw _changed('the inherited bridge original child identity');
      }
      final current = _child(bridge, inputChild);
      _concrete(current, IntrinsicWidth);
      frame = _child(current, (current.widget as IntrinsicWidth).child);
      _concrete(frame, Column);
      final seats = (frame.widget as Column).children;
      if (seats.length != 2 || raw.length != 2) {
        throw _changed('the maintained trigger/content seats');
      }
      for (var i = 0; i < raw.length; i++) {
        if (!BoxProducerScope.contains(
          _child(frame, seats[i]),
          _identity(producer, raw[i]),
        )) {
          throw _changed('the whole trigger/content seat identity');
        }
      }
    case _Kind.resizable:
      final layout = _only(producer);
      _concrete(layout, LayoutBuilder);
      var current = _only(layout); // already executed actual child, no replay
      if (current.widget.runtimeType == coui.Stacks) {
        final overlays = (current.widget as coui.Stacks).children;
        final expected = raw.isEmpty
            ? 0
            : 1 +
                  (raw.length - 1) *
                      ((producer.widget as coui.Resizable).showDragHandle
                          ? 2
                          : 1);
        if (overlays.length != expected || overlays.isEmpty) {
          throw _changed('the current generated pane/overlay seats');
        }
        final stack = _only(current);
        _concrete(stack, Stack);
        final position = _child(stack, overlays.first);
        _concrete(position, coui.Position);
        final positioned = _only(position);
        _concrete(positioned, Positioned);
        current = _child(positioned, (positioned.widget as Positioned).child);
      }
      _concrete(current, Flex);
      frame = current;
      final panes = (frame.widget as Flex).children;
      if (panes.length != raw.length) throw _changed('the complete pane count');
      for (var i = 0; i < panes.length; i++) {
        final pane = _child(frame, panes[i]);
        _concrete(pane, Expanded);
        if (!identical((pane.widget as Expanded).child, raw[i])) {
          throw _changed('the entire original pane content');
        }
        _child(pane, raw[i]);
      }
    case _Kind.breadcrumb:
      var current = _only(producer);
      _concrete(current, coui.CoUISemantics);
      final scrollConfiguration = (current.widget as coui.CoUISemantics).child;
      final semantics = _only(current);
      _concrete(semantics, Semantics);
      current = _child(semantics, scrollConfiguration);
      _concrete(current, ScrollConfiguration);
      current = _child(current, (current.widget as ScrollConfiguration).child);
      _concrete(current, SingleChildScrollView);
      frame = _child(
        current,
        (current.widget as SingleChildScrollView).child,
        direct: false,
      );
      _concrete(frame, Row);
      final count = (producer.widget as coui.Breadcrumb).items.length;
      final expected = count == 0 ? 0 : count * 4 - 3;
      if ((frame.widget as Row).children.length != expected) {
        throw _changed('the generated item/separator seats');
      }
    case _Kind.disclosure:
      throw _changed('the already handled header operation');
  }
  scope.requireOwned(frame);
  _render(frame, RenderFlex);
  return (
    result: result,
    producer: producer,
    frame: frame,
    scope: scope,
    raw: raw,
    expanded: null,
    authority:
        'Exact audited Example/public ${kind.name} producer and complete '
        'raw inputs; actual current source Flex/Column/Row has no own padding '
        'operation. Whole section/pane inputs, trigger/body insets, item padding, '
        'gaps, overlays and scroll viewport are excluded from this field unit',
  );
}

void _render(Element frame, Type type) {
  final render = frame.renderObject;
  if (render.runtimeType != type ||
      render is! RenderBox ||
      !render.attached ||
      !render.hasSize) {
    throw _changed('the attached current exact source renderer');
  }
}

void _unique(List<Widget> raw) {
  final seen = Set<Widget>.identity();
  if (raw.any((slot) => !seen.add(slot))) {
    throw _changed('unique raw public Widget identities before omission');
  }
}

bool _sameWidgets(List<Widget> a, List<Widget> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((same) => same);
void _forwarded(Element frame, List<Widget> actual, List<Widget> raw) {
  if (!_sameWidgets(actual, raw)) {
    throw _changed('the ordered whole foreign inputs');
  }
  for (final slot in raw) {
    _child(frame, slot);
  }
}

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((e) => identical(e.widget, widget)),
  'the unique actual supplied/source Widget identity',
);
List<Element> _children(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return children;
}

Element _only(Element parent) => requireOneBoxOwner(
  _children(parent),
  'the exact current generated direct child',
);
Element _child(Element parent, Widget? child, {bool direct = true}) {
  if (child == null) throw _changed('the required current public child');
  return requireOneBoxOwner(
    (direct ? _children(parent) : boxElements(parent)).where(
      (element) => identical(element.widget, child),
    ),
    'the original actual public child identity',
  );
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('the exact source type');
  }
}

BoxObservationError _changed(String part) => BoxObservationError(
  'SECTION_LAYOUT_SOURCE_CHANGED',
  'Unsupported $part; no owner, quantity or absence is inferred.',
);
