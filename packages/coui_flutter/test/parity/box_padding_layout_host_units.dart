import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/aspect_ratio_box/aspect_ratio_box_default_example.dart';
import 'package:docs_core/previews/examples/flutter/clickable/clickable_default_example.dart';
import 'package:docs_core/previews/examples/flutter/focus_outline/focus_outline_default_example.dart';
import 'package:docs_core/previews/examples/flutter/stepper/stepper_vertical_example.dart';
import 'package:docs_core/previews/examples/flutter/steps/steps_default_example.dart';
import 'package:docs_core/previews/examples/flutter/steps/steps_horizontal_example.dart';
import 'package:docs_core/previews/examples/flutter/steps/steps_list_example.dart';
import 'package:docs_core/previews/examples/flutter/switch_field/switch_field_default_example.dart';
import 'package:flutter/rendering.dart'
    show RenderAspectRatio, RenderBox, RenderFlex, RenderStack;
import 'package:flutter/widgets.dart'
    show
        AspectRatio,
        BoxDecoration,
        Clip,
        Column,
        ConstrainedBox,
        Container,
        EdgeInsets,
        Element,
        FocusableActionDetector,
        GestureDetector,
        IntrinsicWidth,
        KeyedSubtree,
        Listener,
        Opacity,
        Positioned,
        Row,
        SelectionContainer,
        Semantics,
        SizedBox,
        Stack,
        StackFit,
        Transform,
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

/// A source-specific witness; no generic proxy/Stack absence permission.
class LayoutHostBoxSourceBinding {
  LayoutHostBoxSourceBinding._({
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
       absenceKind = source.logicalUnitId,
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
  final String absenceKind;
  final Element _captureRoot;
  final Widget _registryWidget;
  final Element _producer;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;

  String get readerId => 'layout-host-declared-absence-v1';

  /// Rechecks original Widget identities and this live source/layout route.
  /// Clip contour, scale paint, foreign content and overlay are not insets.
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
      throw _changed('the original generated host Element');
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
        {'sourceContract': absenceKind, 'authority': current.authority},
      ],
      frameOwner: current.frame,
    );
  }
}

LayoutHostBoxSourceBinding? bindLayoutHostBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!_kUnits.contains(source.logicalUnitId)) {
    return null;
  }
  return LayoutHostBoxSourceBinding._(
    route: _locate(captureRoot, registryResult, source),
    captureRoot: captureRoot,
    registryResult: registryResult,
    source: source,
  );
}

final Set<String> _kUnits = {
  for (final spec in BoxObservationSourceSpec.layoutHostFrames)
    spec.logicalUnitId,
};

_Route _locate(
  Element captureRoot,
  Widget registryResult,
  BoxObservationSourceSpec source,
) {
  if (!_kUnits.contains(source.logicalUnitId) ||
      source.schemaVersion != 1 ||
      source.quantityId != BoxObservationSourceSpec.quantity ||
      source.nativeAdapterId != '${source.logicalUnitId}-v1' ||
      source.webAdapterId != '${source.logicalUnitId}-v1') {
    throw _changed('the closed source tuple/version');
  }
  final capture = captureRoot.widget;
  if (!identical(capture, registryResult) &&
      !(capture.runtimeType == KeyedSubtree &&
          identical((capture as KeyedSubtree).child, registryResult))) {
    throw _changed('the actual capture construction result');
  }
  final result = _identity(captureRoot, registryResult);
  final (type, examples) = switch (source.logicalUnitId) {
    'steps-generated-sequence-host' => (
      coui.Steps,
      const <Type>[
        StepsDefaultExample,
        StepsHorizontalExample,
        StepsListExample,
      ],
    ),
    'stepper-vertical-sequence-host' => (
      coui.Stepper,
      const <Type>[StepperVerticalExample],
    ),
    'aspect-ratio-generated-layout-host' => (
      coui.AspectRatioBox,
      const <Type>[AspectRatioBoxDefaultExample],
    ),
    'clickable-generated-interaction-host' => (
      coui.Clickable,
      const <Type>[ClickableDefaultExample],
    ),
    'focus-outline-generated-pass-through-host' => (
      coui.FocusOutline,
      const <Type>[FocusOutlineDefaultExample],
    ),
    'switch-field-generated-control-row' => (
      coui.SwitchField,
      const <Type>[SwitchFieldDefaultExample],
    ),
    _ => throw _changed('an audited construction'),
  };
  Element producer;
  if (registryResult.runtimeType == type) {
    producer = result;
  } else {
    if (!examples.contains(registryResult.runtimeType)) {
      throw _changed('the exact official example/public producer type');
    }
    producer = _only(result);
    if (registryResult.runtimeType == StepsListExample ||
        type == coui.AspectRatioBox) {
      _concrete(producer, SizedBox);
      producer = _child(producer, (producer.widget as SizedBox).child);
    }
  }
  _concrete(producer, type);
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final identities = Set<Widget>.identity();
  for (final slot in [
    ...declaration.scope.suppliedSlots,
    ...declaration.unrenderedSuppliedSlots,
  ]) {
    if (!identities.add(slot)) {
      throw _changed('unique public slot identities');
    }
    _identity(producer, slot);
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  final frame = switch (source.logicalUnitId) {
    'steps-generated-sequence-host' => _steps(producer),
    'stepper-vertical-sequence-host' => _stepper(producer),
    'aspect-ratio-generated-layout-host' => _aspect(producer),
    'clickable-generated-interaction-host' => _clickable(producer),
    'focus-outline-generated-pass-through-host' => _focus(producer),
    'switch-field-generated-control-row' => _switchField(producer),
    _ => throw _changed('the audited host'),
  };
  final render = frame.renderObject;
  if (render is! RenderBox || !render.attached || !render.hasSize) {
    throw _changed('current laid out host');
  }
  scope.requireOwned(frame);
  return (
    result: result,
    producer: producer,
    frame: frame,
    scope: scope,
    authority:
        'Actual exact registry/producer Widget refs and frozen build source; '
        '${declaration.authority}; ${source.logicalUnitId}; '
        'own host has no padding operation, foreign content/paint excluded',
  );
}

Element _steps(Element producer) {
  final widget = producer.widget as coui.Steps;
  Element flex;
  if (widget.variant == coui.CoreStepsVariant.list) {
    final semantics = _only(producer);
    _concrete(semantics, coui.CoUISemantics);
    flex = _child(semantics, (semantics.widget as coui.CoUISemantics).child);
    _concrete(flex, Column);
  } else if (widget.vertical) {
    final intrinsic = _only(producer);
    _concrete(intrinsic, IntrinsicWidth);
    flex = _child(intrinsic, (intrinsic.widget as IntrinsicWidth).child);
    _concrete(flex, Column);
  } else {
    flex = _only(producer);
    _concrete(flex, Row);
  }
  if (flex.renderObject.runtimeType != RenderFlex) {
    throw _changed('sequence RenderFlex');
  }
  return flex;
}

Element _stepper(Element producer) {
  final widget = producer.widget as coui.Stepper;
  if (widget.orientation != coui.CoreStepperOrientation.vertical) {
    throw _changed('vertical source branch');
  }
  final intrinsic = _only(producer);
  _concrete(intrinsic, IntrinsicWidth);
  final column = _child(intrinsic, (intrinsic.widget as IntrinsicWidth).child);
  _concrete(column, Column);
  if (column.renderObject.runtimeType != RenderFlex) {
    throw _changed('vertical RenderFlex');
  }
  return column;
}

Element _aspect(Element producer) {
  final widget = producer.widget as coui.AspectRatioBox;
  final aspect = _only(producer);
  _concrete(aspect, AspectRatio);
  if (!identical((aspect.widget as AspectRatio).child, widget.child) ||
      aspect.renderObject.runtimeType != RenderAspectRatio) {
    throw _changed('ratio child/source host');
  }
  _child(aspect, widget.child);
  return aspect;
}

Element _focus(Element producer) {
  final widget = producer.widget as coui.FocusOutline;
  final stacks = _only(producer);
  _concrete(stacks, coui.Stacks);
  final source = stacks.widget as coui.Stacks;
  final children = source.children;
  if (source.fit != coui.CoreStackFit.passthrough ||
      source.clipBehavior != coui.CoreClipBehavior.none ||
      (children.length != 2 && children.length != 3) ||
      !identical(children[children.length - 2], widget.child)) {
    throw _changed('focus flow and positioned source slots');
  }
  for (var i = 0; i < children.length; i++) {
    final element = _child(stacks, children[i]);
    if (i != children.length - 2) {
      _concrete(element, coui.Position);
      final positioned = _only(element);
      _concrete(positioned, Positioned);
      if (!identical(
        (positioned.widget as Positioned).child,
        (element.widget as coui.Position).child,
      )) {
        throw _changed('positioned paint child');
      }
    }
  }
  final stack = _only(stacks);
  _concrete(stack, Stack);
  final actual = stack.widget as Stack;
  if (actual.children.length != children.length ||
      actual.fit != StackFit.passthrough ||
      actual.clipBehavior != Clip.none ||
      stack.renderObject.runtimeType != RenderStack) {
    throw _changed('focus RenderStack');
  }
  for (var i = 0; i < children.length; i++) {
    if (!identical(actual.children[i], children[i])) {
      throw _changed('current Stack source identity');
    }
  }
  return stack;
}

Element _clickable(Element producer) {
  final widget = producer.widget as coui.Clickable;
  if (!widget.focusOutline || widget.marginAlignment != null) {
    throw _changed('default focus-enabled interaction branch');
  }
  final focus = _only(producer);
  _concrete(focus, coui.FocusOutline);
  final semantic = _child(focus, (focus.widget as coui.FocusOutline).child);
  _concrete(semantic, Semantics);
  final listener = _child(semantic, (semantic.widget as Semantics).child);
  _concrete(listener, Listener);
  final gesture = _child(listener, (listener.widget as Listener).child);
  _concrete(gesture, GestureDetector);
  final actions = _child(gesture, (gesture.widget as GestureDetector).child);
  _concrete(actions, FocusableActionDetector);
  var feedback = _child(
    actions,
    (actions.widget as FocusableActionDetector).child,
  );
  if (!widget.enabled) {
    _concrete(feedback, Opacity);
    feedback = _child(feedback, (feedback.widget as Opacity).child);
  }
  // This actual child reference comes from the audited Clickable build. Its
  // private animation host is never identified by a private RTTI name.
  var transform = _only(feedback);
  if (transform.widget.runtimeType == Container) {
    final container = transform.widget as Container;
    final decoration = container.decoration;
    if (container.padding != null ||
        container.margin != null ||
        container.alignment != null ||
        container.foregroundDecoration != null ||
        container.constraints != null ||
        (decoration != null &&
            (decoration.runtimeType != BoxDecoration ||
                (decoration as BoxDecoration).border != null))) {
      throw _changed('source allocation-null feedback Container');
    }
    transform = _child(transform, container.child);
  }
  _concrete(transform, Transform);
  final selection = _child(transform, (transform.widget as Transform).child);
  _concrete(selection, SelectionContainer);
  if (!identical(
    (selection.widget as SelectionContainer).child,
    widget.child,
  )) {
    throw _changed('supplied interaction child');
  }
  _child(selection, widget.child);
  return _focus(focus);
}

Element _switchField(Element producer) {
  final clickable = _only(producer);
  _concrete(clickable, coui.Clickable);
  _clickable(clickable);
  final constrained = _child(
    clickable,
    (clickable.widget as coui.Clickable).child,
  );
  _concrete(constrained, ConstrainedBox);
  final row = _child(constrained, (constrained.widget as ConstrainedBox).child);
  _concrete(row, Row);
  if (row.renderObject.runtimeType != RenderFlex) {
    throw _changed('control-row RenderFlex');
  }
  return row;
}

Element _identity(Element parent, Widget widget) => requireOneBoxOwner(
  boxElements(parent).where((element) => identical(element.widget, widget)),
  'the exact live source Widget identity',
);
Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the exact generated source child');
}

Element _child(Element parent, Widget? widget) {
  if (widget == null) {
    throw _changed('required source child');
  }
  return _identity(parent, widget);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('exact concrete generated source type');
  }
}

BoxObservationError _changed(String part) => BoxObservationError(
  'LAYOUT_HOST_SOURCE_CHANGED',
  'Unsupported $part; no owner or absence is inferred.',
);
