import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/carousel_banner/carousel_banner_default_example.dart';
import 'package:docs_core/previews/examples/flutter/carousel_banner/carousel_banner_md_example.dart';
import 'package:docs_core/previews/examples/flutter/menu_item/menu_item_critical_example.dart';
import 'package:docs_core/previews/examples/flutter/menu_item/menu_item_default_example.dart';
import 'package:docs_core/previews/examples/flutter/menu_item/menu_item_description_example.dart';
import 'package:docs_core/previews/examples/flutter/panel_header/panel_header_default_example.dart';
import 'package:flutter/rendering.dart' show RenderDecoratedBox, RenderPadding;
import 'package:flutter/widgets.dart'
    show
        AnimatedContainer,
        BoxDecoration,
        Clip,
        ConstrainedBox,
        Container,
        DecoratedBox,
        Decoration,
        Element,
        KeyedSubtree,
        Padding,
        Row,
        SizedBox,
        Stack,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element padding,
  Element frame,
  BoxProducerScope scope,
  String authority,
});

/// References to a declared border-free content inset, never numeric values.
class ExplicitContentInsetBoxSourceBinding {
  ExplicitContentInsetBoxSourceBinding._({
    required _Route route,
    required Element captureRoot,
    required Widget registryResult,
    required BoxObservationSourceSpec source,
  }) : authority = route.authority,
       registryResultElement = route.result,
       fieldUnitElement = route.field,
       paddingSource = route.padding,
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

  String get readerId => 'current-render-padding-v1';

  /// Call synchronously immediately before the unchanged shared reader.
  /// Generated frame Widgets may rebuild; original inputs must remain current.
  void validateCurrentConstruction() {
    if (!_captureRoot.mounted ||
        !registryResultElement.mounted ||
        !_producer.mounted ||
        !paddingSource.mounted ||
        !frameSource.mounted ||
        !identical(registryResultElement.widget, _registryWidget) ||
        !identical(_producer.widget, _producerWidget)) {
      throw _changed('the original mounted construction inputs');
    }
    final current = _locate(_captureRoot, _registryWidget, _source);
    if (!identical(current.result, registryResultElement) ||
        !identical(current.producer, _producer) ||
        !identical(current.field, fieldUnitElement) ||
        !identical(current.padding, paddingSource) ||
        !identical(current.frame, frameSource) ||
        current.scope.foreignBoundaries.length !=
            scope.foreignBoundaries.length) {
      throw _changed('the original source Element boundaries');
    }
    for (var i = 0; i < scope.foreignBoundaries.length; i++) {
      if (!identical(
        current.scope.foreignBoundaries[i],
        scope.foreignBoundaries[i],
      )) {
        throw _changed('the current foreign slot boundaries');
      }
    }
  }
}

ExplicitContentInsetBoxSourceBinding? bindExplicitContentInsetBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!BoxObservationSourceSpec.explicitContentInsetFrames.any(
    (known) => known.logicalUnitId == source.logicalUnitId,
  )) {
    return null;
  }
  return ExplicitContentInsetBoxSourceBinding._(
    route: _locate(captureRoot, registryResult, source),
    captureRoot: captureRoot,
    registryResult: registryResult,
    source: source,
  );
}

const _kMenuExamples = <Type>[
  MenuItemDefaultExample,
  MenuItemCriticalExample,
  MenuItemDescriptionExample,
];
const _kCarouselExamples = <Type>[
  CarouselBannerDefaultExample,
  CarouselBannerMdExample,
];

_Route _locate(
  Element captureRoot,
  Widget registryResult,
  BoxObservationSourceSpec source,
) {
  if (!BoxObservationSourceSpec.explicitContentInsetFrames.contains(source)) {
    throw _changed('the closed source tuple/version');
  }
  final capture = captureRoot.widget;
  if (!identical(capture, registryResult) &&
      !(capture.runtimeType == KeyedSubtree &&
          identical((capture as KeyedSubtree).child, registryResult))) {
    throw _changed('the actual registry construction result');
  }
  final result = _identity(captureRoot, registryResult);
  final menu = source == BoxObservationSourceSpec.menuItemRowContentInset;
  final carousel =
      source == BoxObservationSourceSpec.carouselBannerStripContentInset;
  final type = menu
      ? coui.MenuItem
      : carousel
      ? coui.CarouselBanner
      : coui.PanelHeader;
  final actualType = registryResult.runtimeType;
  final direct = actualType == type;
  final supported = menu
      ? _kMenuExamples.contains(actualType)
      : carousel
      ? _kCarouselExamples.contains(actualType)
      : actualType == PanelHeaderDefaultExample;
  if (!direct && !supported) {
    throw _changed('the exact audited construction type');
  }
  var producer = direct ? result : _only(result);
  if (menu && !direct) {
    _concrete(producer, SizedBox);
    producer = _child(producer, (producer.widget as SizedBox).child);
  }
  _concrete(producer, type);
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final seen = Set<Widget>.identity();
  for (final slot in [
    ...declaration.scope.suppliedSlots,
    ...declaration.unrenderedSuppliedSlots,
  ]) {
    if (!seen.add(slot)) {
      throw _changed('unique raw supplied Widget identities');
    }
  }
  if (declaration.unrenderedSuppliedSlots.isNotEmpty) {
    throw _changed('a source-proven rendered public slot branch');
  }
  for (final slot in declaration.scope.suppliedSlots) {
    _identity(producer, slot);
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  late final Element field;
  late final Element padding;
  late final Element frame;
  if (menu) {
    if ((producer.widget as coui.MenuItem).hasSubmenu) {
      throw _changed('the supported non-submenu source');
    }
    var clickable = _only(producer);
    if (clickable.widget.runtimeType == coui.CoUISemantics) {
      clickable = _child(
        clickable,
        (clickable.widget as coui.CoUISemantics).child,
      );
    }
    _concrete(clickable, coui.Clickable);
    final animated = _identity(
      clickable,
      (clickable.widget as coui.Clickable).child,
    );
    _concrete(animated, AnimatedContainer);
    frame = evaluatedAnimatedContainer(animated);
    _concrete(frame, Container);
    final box = frame.widget as Container;
    if (box.padding != null ||
        box.margin != null ||
        box.foregroundDecoration != null ||
        box.alignment != null ||
        box.transform != null ||
        box.clipBehavior != Clip.none) {
      throw _changed('the border-free unallocated current Container source');
    }
    _decoration(box.decoration);
    final stacks = _containerChild(frame, box.child, box.decoration!);
    _concrete(stacks, coui.Stacks);
    final children = (stacks.widget as coui.Stacks).children;
    if (children.length != 1 && children.length != 2) {
      throw _changed('the content and optional wash source order');
    }
    final stack = _only(stacks);
    _concrete(stack, Stack);
    final generated = (stack.widget as Stack).children;
    if (generated.length != children.length ||
        List.generate(
          children.length,
          (i) => identical(children[i], generated[i]),
        ).contains(false)) {
      throw _changed('the actual source-ordered Stack children');
    }
    if (children.length == 2) {
      final position = _identity(stack, children[0]);
      _concrete(position, coui.Position);
      final wash = position.widget as coui.Position;
      if (wash.top != 0 ||
          wash.right != 0 ||
          wash.bottom != 0 ||
          wash.left != 0 ||
          wash.width != null ||
          wash.height != null) {
        throw _changed('the generated fill wash branch');
      }
      final painted = _identity(position, wash.child!);
      _concrete(painted, DecoratedBox);
      _paintedBox(painted);
      if ((painted.widget as DecoratedBox).child != null) {
        throw _changed('the paint-only wash');
      }
    }
    padding = _identity(stack, children.last);
    _concrete(padding, Padding);
    _concrete(_child(padding, (padding.widget as Padding).child), Row);
    field = frame;
  } else if (carousel) {
    if ((producer.widget as coui.CarouselBanner).onTap != null) {
      throw _changed('the supported noninteractive strip source');
    }
    frame = _only(producer);
    _concrete(frame, DecoratedBox);
    _paintedBox(frame);
    padding = _child(frame, (frame.widget as DecoratedBox).child);
    _concrete(padding, Padding);
    _concrete(_child(padding, (padding.widget as Padding).child), Row);
    field = frame;
  } else {
    padding = _only(producer);
    _concrete(padding, Padding);
    _child(padding, (padding.widget as Padding).child);
    frame = padding;
    field = padding;
  }
  if (padding.renderObject.runtimeType != RenderPadding) {
    throw _changed('the exact current RenderPadding');
  }
  scope
    ..requireOwned(field)
    ..requireOwned(frame)
    ..requireOwned(padding);
  return (
    result: result,
    producer: producer,
    field: field,
    padding: padding,
    frame: frame,
    scope: scope,
    authority:
        'Exact audited Example/public producer and current child identities; '
        '${declaration.authority}; border-free source-owned content Padding; '
        'not nested sums or painted-edge distance',
  );
}

void _decoration(Decoration? decoration) {
  if (decoration is! BoxDecoration ||
      decoration.runtimeType != BoxDecoration ||
      decoration.border != null) {
    throw _changed('an exact current BoxDecoration without border allocation');
  }
}

void _paintedBox(Element box) {
  final decoration = (box.widget as DecoratedBox).decoration;
  _decoration(decoration);
  final render = box.renderObject;
  if (render is! RenderDecoratedBox ||
      render.runtimeType != RenderDecoratedBox) {
    throw _changed('the exact live decoration renderer');
  }
  // RenderDecoratedBox's setter retains its old object when == succeeds.
  // Check both concrete no-border sources and their forwarded value equality;
  // the Container-to-DecoratedBox Widget forwarding identity stays strict.
  _decoration(render.decoration);
  if (render.decoration != decoration) {
    throw _changed('the live RenderDecoratedBox decoration source');
  }
}

Element _containerChild(
  Element container,
  Widget? child,
  Decoration decoration,
) {
  if (child == null) {
    throw _changed('the current Container child');
  }
  // SDK Container.build wraps its child with decoration.padding even when
  // BoxDecoration.border is null. This generated slot is not content inset.
  // Validate the property-source identity, never search for a zero value.
  final widget = container.widget as Container;
  final constrained = _only(container);
  _concrete(constrained, ConstrainedBox);
  if (!identical(
    (constrained.widget as ConstrainedBox).constraints,
    widget.constraints,
  )) {
    throw _changed('the Container constraints source');
  }
  final painted = _child(
    constrained,
    (constrained.widget as ConstrainedBox).child,
  );
  _concrete(painted, DecoratedBox);
  if (!identical((painted.widget as DecoratedBox).decoration, decoration)) {
    throw _changed('the Container-owned decoration identity');
  }
  _paintedBox(painted);
  final allocated = _child(painted, (painted.widget as DecoratedBox).child);
  _concrete(allocated, Padding);
  if (!identical((allocated.widget as Padding).padding, decoration.padding)) {
    throw _changed('the exact generated decoration-padding property source');
  }
  final result = _child(allocated, (allocated.widget as Padding).child);
  if (!identical(result.widget, child)) {
    throw _changed('the actual Container child after its property slots');
  }
  return result;
}

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((element) => identical(element.widget, widget)),
  'the unique actual source Widget identity',
);
Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the single generated source child');
}

Element _child(Element parent, Widget? child) {
  if (child == null) {
    throw _changed('the required source child');
  }
  return elementOfDeclaredChild(parent, child);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('the exact concrete source type');
  }
}

BoxObservationError _changed(String part) => BoxObservationError(
  'EXPLICIT_CONTENT_INSET_SOURCE_CHANGED',
  'Unsupported $part; no frame or padding quantity is inferred.',
);
