import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/form_field/form_field_default_example.dart';
import 'package:docs_core/previews/examples/flutter/form_label/form_label_default_example.dart';
import 'package:docs_core/previews/examples/flutter/listing/listing_default_example.dart';
import 'package:docs_core/previews/examples/flutter/option_list/option_list_default_example.dart';
import 'package:docs_core/previews/examples/flutter/toggle_group/toggle_group_default_example.dart';
import 'package:docs_core/previews/examples/flutter/toggle_group/toggle_group_vertical_example.dart';
import 'package:flutter/rendering.dart' show RenderDecoratedBox, RenderFlex;
import 'package:flutter/widgets.dart'
    show
        AnimatedContainer,
        BoxDecoration,
        Builder,
        Column,
        Container,
        DecoratedBox,
        DefaultTextStyle,
        EdgeInsets,
        Element,
        Flexible,
        IgnorePointer,
        IntrinsicWidth,
        KeyedSubtree,
        Row,
        Semantics,
        SizedBox,
        ValueListenableBuilder,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element padding,
  BoxProducerScope scope,
  List<Widget> raw,
  List<Widget> omitted,
  String authority,
});

/// Current source references only; the existing outlined reader owns values.
class FormCollectionBoxSourceBinding {
  FormCollectionBoxSourceBinding._(
    this._capture,
    this._registry,
    this._source,
    this._route,
  ) : _producerWidget = _route.producer.widget,
      _raw = List<Widget>.unmodifiable(_route.raw),
      _omitted = List<Widget>.unmodifiable(_route.omitted);

  final Element _capture;
  final Widget _registry;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;
  final _Route _route;
  final List<Widget> _raw;
  final List<Widget> _omitted;

  String get authority => _route.authority;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.field;
  Element get paddingSource => _route.padding;
  Element get frameSource => _route.padding;
  BoxProducerScope get scope => _route.scope;
  String get readerId =>
      _source == BoxObservationSourceSpec.toggleGroupTrackContentInset
      ? 'outlined-content-v1'
      : 'form-collection-declared-absence-v1';

  void validateExistingCurrentBinding() {
    for (final pair in [
      (_route.result, _registry),
      (_route.producer, _producerWidget),
    ]) {
      if (!pair.$1.mounted || !identical(pair.$1.widget, pair.$2)) {
        throw _changed('the original mounted input identities');
      }
    }
    final current = _locate(_capture, _registry, _source);
    if (!identical(current.result, _route.result) ||
        !identical(current.producer, _route.producer) ||
        !identical(current.field, fieldUnitElement) ||
        !identical(current.padding, paddingSource) ||
        !_same(current.raw, _raw) ||
        !_same(current.omitted, _omitted) ||
        !_same(current.scope.foreignBoundaries, scope.foreignBoundaries)) {
      throw _changed(
        'the source Elements and complete ordered input boundaries',
      );
    }
  }

  BoxPaddingObservation readDeclaredAbsence() {
    validateExistingCurrentBinding();
    if (readerId == 'outlined-content-v1') {
      throw _changed('ToggleGroup requires the actual shared surface reader');
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

FormCollectionBoxSourceBinding? bindFormCollectionBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!BoxObservationSourceSpec.formCollectionFrames.any(
    (known) => known.logicalUnitId == source.logicalUnitId,
  )) {
    return null;
  }
  if (!BoxObservationSourceSpec.formCollectionFrames.contains(source)) {
    throw _changed('the complete versioned source tuple');
  }
  return FormCollectionBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    _locate(captureRoot, registryResult, source),
  );
}

Type _type(BoxObservationSourceSpec source) => switch (source.logicalUnitId) {
  'toggle-group-generated-track-content-inset' => coui.ToggleGroup<String>,
  'form-field-generated-layout-host' => coui.FormField,
  'form-label-generated-label-row-layout-host' => coui.FormLabel,
  'listing-generated-rows-layout-host' => coui.Listing,
  _ => coui.OptionList,
};

bool _example(Widget widget, BoxObservationSourceSpec source) =>
    switch (source.logicalUnitId) {
      'toggle-group-generated-track-content-inset' =>
        widget.runtimeType == ToggleGroupDefaultExample ||
            widget.runtimeType == ToggleGroupVerticalExample,
      'form-field-generated-layout-host' =>
        widget.runtimeType == FormFieldDefaultExample,
      'form-label-generated-label-row-layout-host' =>
        widget.runtimeType == FormLabelDefaultExample,
      'listing-generated-rows-layout-host' =>
        widget.runtimeType == ListingDefaultExample,
      _ => widget.runtimeType == OptionListDefaultExample,
    };

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
) {
  if (!capture.mounted ||
      !(identical(capture.widget, registry) ||
          (capture.widget.runtimeType == KeyedSubtree &&
              identical((capture.widget as KeyedSubtree).child, registry)))) {
    throw _changed('the capture and original registry result');
  }
  final result = _identity(capture, registry);
  final direct = registry.runtimeType == _type(source);
  if (!direct && !_example(registry, source)) {
    throw _changed('an exact audited Example or concrete public producer');
  }
  var producer = direct ? result : _only(result);
  if (!direct && source == BoxObservationSourceSpec.formFieldLayoutHost) {
    _concrete(producer, SizedBox);
    producer = _child(producer, (producer.widget as SizedBox).child);
  }
  _concrete(producer, _type(source));
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  // Reconstruct original public order before omission. Typed binding already
  // rejected duplicate identities and unknown item records before filtering.
  final input = producer.widget;
  final raw = switch (input) {
    coui.ToggleGroup<String>() => [
      for (final item in input.items) ?item.icon,
      ?input.trailing,
    ],
    coui.FormField() => [?input.labelWidget, ?input.labelAction, ?input.child],
    coui.FormLabel() => [?input.label, ?input.requiredIndicator],
    coui.Listing() => [...input.children],
    coui.OptionList() => [...input.children],
    _ => throw _changed('the public supplied-slot declaration'),
  };
  final seen = Set<Widget>.identity();
  for (final slot in raw) {
    if (!seen.add(slot)) {
      throw _changed('unique raw supplied identities before omission');
    }
    if (!declaration.unrenderedSuppliedSlots.any(
      (old) => identical(old, slot),
    )) {
      _identity(producer, slot);
    }
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  Element field;
  Element padding;
  if (input is coui.ToggleGroup<String>) {
    // ToggleGroup owns this public primitive; segment icons/trailing are foreign.
    // The resolver explicitly supplies borderWidth:0 for the track. A themed
    // border cannot consume the CSS padding while Flutter puts it on an outer
    // Container: check that actual public allocation premise before reading.
    padding = _only(producer);
    _concrete(padding, coui.OutlinedContainer);
    final surface = padding.widget as coui.OutlinedContainer;
    if (surface.containerStyle?.borderWidth != 0 || surface.child == null) {
      throw _changed('the track explicit zero-border allocation premise');
    }
    var content = _identity(padding, surface.child!);
    scope.requireOwned(content);
    if (input.direction == coui.CoreAxis.vertical && !input.fillWidth) {
      _concrete(content, IntrinsicWidth);
      content = _child(content, (content.widget as IntrinsicWidth).child);
    }
    _concrete(
      content,
      input.direction == coui.CoreAxis.vertical ? Column : Row,
    );
    final seats = content.widget is Column
        ? (content.widget as Column).children
        : (content.widget as Row).children;
    if (seats.length != input.items.length + (input.trailing == null ? 0 : 1) ||
        (input.trailing != null && !identical(seats.last, input.trailing))) {
      throw _changed('the generated segment/trailing seats');
    }
    _requireZeroTrackAllocation(padding, scope);
    field = producer;
  } else if (input is coui.FormField) {
    // The outer listenable builder forwards the same current Column through
    // Semantics and optional IgnorePointer; no builder/state is invoked here.
    final builder = _only(producer);
    _concrete(builder, ValueListenableBuilder<coui.ValidationResult?>);
    final columnInput =
        (builder.widget as ValueListenableBuilder<coui.ValidationResult?>)
            .child;
    final semantics = _only(builder);
    _concrete(semantics, Semantics);
    if (!identical((semantics.widget as Semantics).child, columnInput)) {
      throw _changed('the current outer validation builder forwarded child');
    }
    field = _child(semantics, columnInput);
    if (field.widget.runtimeType == IgnorePointer) {
      field = _child(field, (field.widget as IgnorePointer).child);
    }
    _concrete(field, Column);
    final seats = (field.widget as Column).children;
    final hasLabel = input.label != null || input.labelWidget != null;
    if (seats.length !=
            (hasLabel ? 2 : 0) + (input.child == null ? 0 : 1) + 1 ||
        seats.last.runtimeType !=
            (ValueListenableBuilder<coui.ValidationResult?>) ||
        (hasLabel && seats[1].runtimeType != coui.Gap)) {
      throw _changed('the source label/input/footer seats');
    }
    if (input.child != null) {
      final seat = seats[hasLabel ? 2 : 0];
      _concreteWidget(seat, ValueListenableBuilder<coui.ValidationResult?>);
      if (!identical(
        (seat as ValueListenableBuilder<coui.ValidationResult?>).child,
        input.child,
      )) {
        throw _changed('the unchanged whole input slot');
      }
    }
    padding = field;
  } else if (input is coui.FormLabel) {
    final merge = _only(producer);
    _concrete(merge, Builder);
    final style = _only(merge);
    _concrete(style, DefaultTextStyle);
    field = _child(style, (style.widget as DefaultTextStyle).child);
    _concrete(field, Row);
    final seats = (field.widget as Row).children;
    if (seats.length !=
        (input.label == null ? 0 : 1) + (input.isRequired ? 2 : 0)) {
      throw _changed('the label and immutable required-marker seats');
    }
    if (input.label != null) {
      _concreteWidget(seats.first, Flexible);
      if (!identical((seats.first as Flexible).child, input.label)) {
        throw _changed('the whole forwarded label');
      }
    }
    if (input.isRequired &&
        (seats[seats.length - 2].runtimeType != coui.Gap ||
            (input.requiredIndicator != null &&
                !identical(seats.last, input.requiredIndicator)))) {
      throw _changed('the required indicator and generated gap');
    }
    padding = field;
  } else if (input is coui.Listing) {
    field = _only(producer);
    if (input.semanticLabel != null) {
      _concrete(field, Semantics);
      field = _child(field, (field.widget as Semantics).child);
    }
    _concrete(field, Column);
    final seats = (field.widget as Column).children;
    final noLines = _same(seats, input.children);
    final lines =
        seats.length ==
            (input.children.isEmpty ? 0 : input.children.length * 2 - 1) &&
        List.generate(
          seats.length,
          (i) => i.isEven
              ? identical(seats[i], input.children[i ~/ 2])
              : seats[i].runtimeType == coui.Divider,
        ).every((ok) => ok);
    if (!noLines && !lines) {
      throw _changed('whole foreign rows with generated separators only');
    }
    padding = field;
  } else {
    final semantics = _only(producer);
    _concrete(semantics, coui.CoUISemantics);
    final semanticChild = (semantics.widget as coui.CoUISemantics).child;
    final actual = _only(semantics);
    _concrete(actual, Semantics);
    if (!identical((actual.widget as Semantics).child, semanticChild)) {
      throw _changed('the actual group semantic forwarding');
    }
    field = _child(actual, semanticChild);
    _concrete(field, Column);
    if (!_same(
      (field.widget as Column).children,
      (input as coui.OptionList).children,
    )) {
      throw _changed('the complete ordered whole foreign option items');
    }
    padding = field;
  }
  scope
    ..requireOwned(field)
    ..requireOwned(padding);
  final render = padding.renderObject;
  if (_readerIsAbsence(source) &&
      (render.runtimeType != RenderFlex ||
          render is! RenderFlex ||
          !render.attached ||
          !render.hasSize)) {
    throw _changed('the attached laid-out source-owned Row/Column renderer');
  }
  return (
    result: result,
    producer: producer,
    field: field,
    padding: padding,
    scope: scope,
    raw: raw,
    omitted: declaration.unrenderedSuppliedSlots,
    authority:
        '${declaration.authority}; exact current generated track or '
        'Row/Column source path. '
        'Whole supplied subtrees and documentation width wrappers '
        'cannot donate padding. '
        'A Row/Column allocates arrangement only; the Toggle track uses '
        'its existing outlined reader.',
  );
}

// Source identity fixes the two evaluated Containers before allocation is read.
// Animation targets and inner segment decorations are never allocation proof.
void _requireZeroTrackAllocation(Element primitive, BoxProducerScope scope) {
  final surface = primitive.widget as coui.OutlinedContainer;
  final local = BoxProducerScope(
    producer: primitive,
    suppliedSlots: [?surface.child],
  );
  final candidates = <({Element outer, Element innerAnimation})>[];
  void visit(Element element) {
    if (local.foreignBoundaries.any(
      (boundary) => identical(boundary, element),
    )) {
      return;
    }
    if (element.widget.runtimeType == AnimatedContainer) {
      final outer = evaluatedAnimatedContainer(element);
      final child = (outer.widget as Container).child;
      if (child?.runtimeType == AnimatedContainer) {
        final innerAnimation = elementOfDeclaredChild(outer, child!);
        final inner = evaluatedAnimatedContainer(innerAnimation);
        final content = (inner.widget as Container).child;
        if (content is KeyedSubtree &&
            identical(content.child, surface.child)) {
          candidates.add((outer: outer, innerAnimation: innerAnimation));
        }
      }
    }
    element.visitChildren(visit);
  }

  visit(primitive);
  if (candidates.length != 1) {
    throw _changed('the unique evaluated track chrome pair');
  }
  final candidate = candidates.single;
  scope.requireOwned(candidate.outer);
  final decoration = (candidate.outer.widget as Container).decoration;
  final actual = <Element>[];
  void chrome(Element element) {
    if (identical(element, candidate.innerAnimation)) return;
    if (element.widget.runtimeType == DecoratedBox &&
        identical((element.widget as DecoratedBox).decoration, decoration)) {
      actual.add(element);
    }
    element.visitChildren(chrome);
  }

  chrome(candidate.outer);
  final owner = requireOneBoxOwner(
    actual,
    'the outer current track decoration slot',
  );
  scope.requireOwned(owner);
  final render = owner.renderObject;
  if (render.runtimeType != RenderDecoratedBox ||
      render is! RenderDecoratedBox ||
      !render.attached ||
      !render.hasSize ||
      render.decoration is! BoxDecoration ||
      render.decoration.padding.resolve(render.configuration.textDirection) !=
          EdgeInsets.zero) {
    throw _changed(
      'the actual attached outer decoration zero-allocation premise',
    );
  }
}

bool _readerIsAbsence(BoxObservationSourceSpec source) =>
    source != BoxObservationSourceSpec.toggleGroupTrackContentInset;
bool _same<T>(List<T> a, List<T> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((same) => same);
Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((element) => identical(element.widget, widget)),
  'the original unique Widget identity',
);
Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the exact source generated child');
}

Element _child(Element parent, Widget? child) {
  if (child == null) throw _changed('the declared non-null child');
  final element = _identity(parent, child);
  return element;
}

void _concrete(Element element, Type type) =>
    _concreteWidget(element.widget, type);
void _concreteWidget(Widget widget, Type type) =>
    requireConcreteBoxSourceType(widget, type);
BoxObservationError _changed(String detail) => BoxObservationError(
  'FORM_COLLECTION_SOURCE_CHANGED',
  'Unsupported form/collection source: $detail. No owner or zero is inferred.',
);
