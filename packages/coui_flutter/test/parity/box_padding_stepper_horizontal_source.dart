// The exact public normal factory chain proves this generated operation.
import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/stepper/stepper_default_example.dart';
import 'package:docs_core/previews/examples/flutter/stepper/stepper_disabled_example.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        Column,
        Directionality,
        Element,
        KeyedSubtree,
        MultiChildRenderObjectElement,
        MultiChildRenderObjectWidget,
        RenderObjectElement,
        StatefulElement,
        StatelessElement,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

typedef _Current = ({
  Element row,
  RenderObject renderer,
  List<Element> columns,
  List<coui.CoreStepItem> raw,
  List<Object?> held,
  BoxProducerScope scope,
});

/// Specific normal Stepper factory provenance, not generic container absence.
class StepperHorizontalBinding {
  StepperHorizontalBinding._(
    this.product,
    this.registry,
    this.original,
    this.capture,
  ) : _held = _snapshot(product, registry, original, capture);
  final Element product;
  final Element? registry;
  final Widget? original;
  final Element? capture;
  final _Current _held;

  Element get frameSource => _held.row;
  String get readerId => 'stepper-normal-horizontal-factory-v1';
  String get authority =>
      'exact original Example -> exact public Stepper/StatelessElement -> '
      'normal generated MultiChildRenderObjectElement and exact current '
      'factory-renderer frontier; whole pinned layout distributes columns '
      'without an outer inset for every healthy parameter branch; no '
      'private type string, private parameter, build or intrinsic replay';

  void validateCurrentBinding() {
    final now = _snapshot(product, registry, original, capture);
    if (!_same(now.held, _held.held)) {
      throw _changed('held whole normal factory chain');
    }
  }

  BoxPaddingObservation readDeclaredAbsence() {
    validateCurrentBinding();
    _held.scope.requireOwned(frameSource);
    // Structural absence is emitted only after the specific operation proof.
    // Unsupported or stale source throws; no missing-property fallback exists.
    final value = BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: frameSource,
      producer: registry ?? product,
      contentBoundary: frameSource,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      frameOwner: frameSource,
      generatedSlots: [sourceIdentity],
    );
    validateCurrentBinding();
    return value;
  }

  Map<String, Object?> get sourceIdentity {
    validateCurrentBinding();
    return {
      'kind': 'stepper-normal-horizontal-factory-v1',
      'quantityBoundary': 'complete-horizontal-operation-to-generated-columns',
      'normalPublicFactoryProvenance': true,
      'universalOwnedInsetAbsence': true,
      'privateParametersRead': false,
      'buildOrIntrinsicReexecuted': false,
      'generatedColumnInteriorsAreAuthority': false,
      'rawStepItems': [
        for (var i = 0; i < _held.raw.length; i++)
          {
            'index': i,
            'label': _held.raw[i].label,
            'description': _held.raw[i].description,
            'descriptionMountedClaim': false,
            'aliasesEarlier': [
              for (var j = 0; j < i; j++)
                if (identical(_held.raw[j], _held.raw[i])) j,
            ],
          },
      ],
      'generatedColumns': [
        for (var i = 0; i < _held.columns.length; i++)
          {
            'index': i,
            'present': true,
            'generatedNotSupplied': true,
            'opaque': true,
            'elementDiagnostic': identityHashCode(_held.columns[i]),
          },
      ],
    };
  }
}

StepperHorizontalBinding bindStepperHorizontalEntry({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source != BoxObservationSourceSpec.stepperHorizontalHost ||
      source.validationError != null ||
      !const [
        StepperDefaultExample,
        StepperDisabledExample,
      ].contains(registryResult.runtimeType)) {
    throw _changed('closed original recipes and full tuple');
  }
  final registry = identical(captureRoot.widget, registryResult)
      ? captureRoot
      : captureRoot.widget.runtimeType == KeyedSubtree &&
            identical(
              (captureRoot.widget as KeyedSubtree).child,
              registryResult,
            )
      ? _only(captureRoot)
      : throw _changed('original keyed mount');
  final product = _only(registry);
  if (product.widget is! coui.Stepper ||
      (product.widget as coui.Stepper).steps.length != 3) {
    throw _changed('complete original three public item declarations');
  }
  return StepperHorizontalBinding._(
    product,
    registry,
    registryResult,
    captureRoot,
  );
}

/// Mounted public normal-operation control entry; production requires Example.
StepperHorizontalBinding bindCurrentStepperHorizontal(Element product) =>
    StepperHorizontalBinding._(product, null, null, null);

_Current _snapshot(
  Element product,
  Element? registry,
  Widget? original,
  Element? capture,
) {
  if (registry != null &&
      (!registry.mounted ||
          !identical(registry.widget, original) ||
          registry.runtimeType !=
              (original.runtimeType == StepperDefaultExample
                  ? StatefulElement
                  : StatelessElement) ||
          !identical(_only(registry), product))) {
    throw _changed('exact original public normal Example element');
  }
  if (capture != null &&
      (!capture.mounted ||
          !(identical(capture, registry) &&
                  identical(capture.widget, original) ||
              capture.widget.runtimeType == KeyedSubtree &&
                  identical((capture.widget as KeyedSubtree).child, original) &&
                  identical(_only(capture), registry)))) {
    throw _changed('held original capture mount');
  }
  if (!product.mounted ||
      product.runtimeType != StatelessElement ||
      product.widget.runtimeType != coui.Stepper) {
    throw _changed('exact normal public Stepper element, no subclass');
  }
  final input = product.widget as coui.Stepper;
  if (input.orientation != coui.CoreStepperOrientation.horizontal) {
    throw _changed('horizontal factory branch only');
  }
  final row = _only(product);
  if (row.runtimeType != MultiChildRenderObjectElement ||
      row.widget is! MultiChildRenderObjectWidget ||
      row is! RenderObjectElement) {
    throw _changed('sole normal generated factory operation');
  }
  final renderer = row.renderObject;
  if (!renderer.attached) {
    throw _changed('original actual operation renderer');
  }
  final generated = row.widget as MultiChildRenderObjectWidget;
  final columns = _children(row);
  final renderColumns = <RenderObject>[];
  renderer.visitChildren(renderColumns.add);
  if (input.steps.length != generated.children.length ||
      generated.children.length != columns.length ||
      columns.length != renderColumns.length ||
      (Set<Element>.identity()..addAll(columns)).length != columns.length ||
      (Set<RenderObject>.identity()..addAll(renderColumns)).length !=
          renderColumns.length) {
    throw _changed('complete raw items / generated columns / renderer roster');
  }
  final held = <Object?>[
    if (registry != null) ...[registry, original],
    if (capture != null) ...[capture, capture.widget],
    product,
    input,
    input.steps,
    input.onStepChanged,
    input.stepperStyle,
    input.orientation,
    input.enabled,
    input.currentStep,
    Directionality.maybeOf(product),
    row,
    generated,
    generated.children,
    renderer,
  ];
  for (var i = 0; i < columns.length; i++) {
    final column = columns[i];
    if (generated.children[i].runtimeType != Column ||
        !identical(column.widget, generated.children[i]) ||
        column.runtimeType != MultiChildRenderObjectElement ||
        column is! RenderObjectElement ||
        column.renderObject.runtimeType != RenderFlex ||
        !column.renderObject.attached ||
        !identical(column.renderObject, renderColumns[i]) ||
        !identical(renderColumns[i].parent, renderer)) {
      throw _changed('complete ordered current generated Column frontier');
    }
    // Do not traverse Column children: labels/tracks/gaps are opaque content.
    held.addAll([
      input.steps[i],
      input.steps[i].label,
      input.steps[i].description,
      generated.children[i],
      column,
      column.renderObject,
    ]);
  }
  final scope = BoxProducerScope(
    producer: product,
    suppliedSlots: const [],
    derivedSuppliedElements: columns,
  );
  if (!_same(scope.foreignBoundaries, columns)) {
    throw _changed('only complete generated opaque frontiers');
  }
  scope.requireOwned(row);
  return (
    row: row,
    renderer: renderer,
    columns: columns,
    raw: List.of(input.steps),
    held: held,
    scope: scope,
  );
}

List<Element> _children(Element parent) {
  if (!parent.mounted) throw _changed('detached parent');
  final out = <Element>[];
  parent.visitChildren(out.add);
  for (final child in out) {
    Element? actual;
    child.visitAncestorElements((e) {
      actual = e;
      return false;
    });
    if (!child.mounted || !identical(actual, parent)) {
      throw _changed('exact current parent');
    }
  }
  return out;
}

Element _only(Element parent) {
  final out = _children(parent);
  if (out.length != 1) throw _changed('complete sole current child');
  return out.single;
}

bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((same) => same);
BoxObservationError _changed(String detail) =>
    BoxObservationError('STEPPER_HORIZONTAL_SOURCE_CHANGED', detail);
