import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/chip/chip_disabled_example.dart';
import 'package:docs_core/previews/examples/flutter/chip/chip_removable_example.dart';
import 'package:docs_core/previews/examples/flutter/number_input/number_input_default_example.dart';
import 'package:docs_core/previews/examples/flutter/number_input/number_input_disabled_example.dart';
import 'package:docs_core/previews/examples/flutter/number_input/number_input_error_example.dart';
import 'package:docs_core/previews/examples/flutter/number_input/number_input_filled_example.dart';
import 'package:flutter/widgets.dart'
    show
        Align,
        Column,
        ConstrainedBox,
        Container,
        Element,
        Focus,
        KeyedSubtree,
        Listener,
        MouseRegion,
        Padding,
        Semantics,
        SizedBox,
        TextSelectionGestureDetector,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

/// Source references consumed by the existing shared padding readers.
typedef ControlShellBoxSourceBinding = ({
  String authority,
  Element registryResultElement,
  Element fieldUnitElement,
  Element paddingSource,
  Element? frameSource,
  BoxProducerScope scope,
  String readerId,
});

/// Follows the two audited builders without invoking a builder or callback.
///
/// The generated TextField box and Chip surface are explicit descendant units,
/// not replacements for the existing legacy component-root finder or metrics.
ControlShellBoxSourceBinding? bindControlShellBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final adapter = switch (source.logicalUnitId) {
    'number-input-generated-field-frame' =>
      'number-input-generated-field-frame-v1',
    'chip-generated-frame' => 'chip-generated-frame-v1',
    _ => null,
  };
  if (adapter == null) return null;
  if (source.schemaVersion != 1) {
    throw const BoxObservationError(
      'UNSUPPORTED_BOX_SOURCE_VERSION',
      'The control shell requires source schema 1.',
    );
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity ||
      source.nativeAdapterId != adapter ||
      source.webAdapterId != adapter) {
    throw const BoxObservationError(
      'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
      'The quantity and both adapters must match the closed logical unit.',
    );
  }
  final root = captureRoot.widget;
  if (!identical(root, registryResult) &&
      !(root.runtimeType == KeyedSubtree &&
          identical((root as KeyedSubtree).child, registryResult))) {
    throw _changed('the actual capture construction result');
  }
  final result = _identity(captureRoot, registryResult);
  final type = registryResult.runtimeType;
  final number = adapter == 'number-input-generated-field-frame-v1';
  final producerType = number ? coui.NumberInput : coui.Chip;
  final examples = number
      ? const <Type>[
          NumberInputDefaultExample,
          NumberInputFilledExample,
          NumberInputErrorExample,
          NumberInputDisabledExample,
        ]
      : const <Type>[ChipRemovableExample, ChipDisabledExample];
  if (type != producerType && !examples.contains(type)) {
    throw const BoxObservationError(
      'UNREGISTERED_COMPONENT_CONSTRUCTION',
      'An exact concrete producer or audited official example is required.',
    );
  }
  final producer = type == producerType ? result : _only(result);
  if (producer.widget.runtimeType != producerType) {
    throw _changed('the example single generated public component');
  }
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  final binding = number
      ? _numberInput(producer, scope)
      : _chip(producer, scope);
  scope
    ..requireOwned(binding.unit)
    ..requireOwned(binding.padding)
    ..requireOwned(binding.frame);
  return (
    authority:
        'Exact official example/public producer and actual child identities; '
        '${declaration.authority}; $adapter. Source-frozen private build '
        'operation is trusted, not independently authenticated by private '
        'RTTI.',
    registryResultElement: result,
    fieldUnitElement: binding.unit,
    paddingSource: binding.padding,
    frameSource: binding.frame,
    scope: scope,
    readerId: number ? 'current-render-padding-v1' : 'outlined-content-v1',
  );
}

({Element unit, Element padding, Element frame}) _numberInput(
  Element producer,
  BoxProducerScope scope,
) {
  final sized = _only(producer);
  _concrete(sized, SizedBox);
  final focus = _child(sized, (sized.widget as SizedBox).child);
  _concrete(focus, Focus);
  final semantics = _child(focus, (focus.widget as Focus).child);
  _concrete(semantics, Semantics);
  final field = _child(semantics, (semantics.widget as Semantics).child);
  _concrete(field, coui.TextField);
  final fieldWidget = field.widget as coui.TextField;
  // Preserve the generated field's actual prefix/suffix boundaries too. The
  // NumberInput generated step Buttons cannot donate their nested padding.
  final fieldDeclaration = DeclaredBoxProducer.bind(
    producer: field,
    sourceContract: 'renderer-frame-padding-v1',
  );
  var mouse = _only(field);
  if (fieldWidget.label != null ||
      fieldWidget.description != null ||
      fieldWidget.errorText != null) {
    _concrete(mouse, Column);
    final children = (mouse.widget as Column).children;
    final expected =
        1 +
        (fieldWidget.label == null ? 0 : 1) +
        (fieldWidget.description != null || fieldWidget.errorText != null
            ? 1
            : 0);
    if (children.length != expected) throw _changed('TextField label cells');
    mouse = _child(mouse, children[fieldWidget.label == null ? 0 : 1]);
  }
  _concrete(mouse, MouseRegion);
  final outline = _child(mouse, (mouse.widget as MouseRegion).child);
  _concrete(outline, coui.FocusOutline);
  var blur = _child(outline, (outline.widget as coui.FocusOutline).child);
  if (blur.widget.runtimeType == Listener) {
    final gestures = _child(blur, (blur.widget as Listener).child);
    _concrete(gestures, TextSelectionGestureDetector);
    blur = _child(
      gestures,
      (gestures.widget as TextSelectionGestureDetector).child,
    );
  }
  _concrete(blur, coui.SurfaceBlur);
  final constraints = _child(blur, (blur.widget as coui.SurfaceBlur).child);
  _concrete(constraints, ConstrainedBox);
  final frame = _child(
    constraints,
    (constraints.widget as ConstrainedBox).child,
  );
  _concrete(frame, Container);
  final align = _child(frame, (frame.widget as Container).child);
  _concrete(align, Align);
  final padding = _child(align, (align.widget as Align).child);
  _concrete(padding, Padding);
  fieldDeclaration.scope
    ..requireOwned(frame)
    ..requireOwned(padding);
  scope
    ..requireOwned(field)
    ..requireOwned(frame)
    ..requireOwned(padding);
  return (unit: frame, padding: padding, frame: frame);
}

({Element unit, Element padding, Element frame}) _chip(
  Element producer,
  BoxProducerScope scope,
) {
  final widget = producer.widget as coui.Chip;
  if (widget.onTap == null) {
    throw _changed('the audited interactive Chip branch');
  }
  // Exact Chip.build constructs one private pressable operation, whose actual
  // build result is TouchTarget. We inspect that existing operation once; no
  // private class string or arbitrary descendant search supplies authority.
  final operation = _only(producer);
  final touch = _only(operation);
  _concrete(touch, coui.TouchTarget);
  final clickable = _child(touch, (touch.widget as coui.TouchTarget).child);
  _concrete(clickable, coui.Clickable);
  final cast = _child(clickable, (clickable.widget as coui.Clickable).child);
  _concrete(cast, coui.InjectedCast);
  final constraints = _child(cast, (cast.widget as coui.InjectedCast).child);
  _concrete(constraints, ConstrainedBox);
  final frame = _child(
    constraints,
    (constraints.widget as ConstrainedBox).child,
  );
  _concrete(frame, coui.OutlinedContainer);
  scope.requireOwned(frame);
  return (unit: frame, padding: frame, frame: frame);
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the exact source operation build child');
}

Element _identity(Element parent, Widget widget) => requireOneBoxOwner(
  boxElements(parent).where((element) => identical(element.widget, widget)),
  'the actual source Widget identity',
);

Element _child(Element parent, Widget? child) {
  if (child == null) throw _changed('a required public source child');
  return _identity(parent, child);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('the exact concrete source Widget $type');
  }
}

BoxObservationError _changed(String slot) => BoxObservationError(
  'CONTROL_SHELL_SOURCE_CHANGED',
  'Unsupported or missing $slot; no fallback owner or value is supplied.',
);
