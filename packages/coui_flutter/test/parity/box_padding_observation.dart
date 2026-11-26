import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A required observation could not be attributed to its declared source.
class BoxObservationError implements Exception {
  const BoxObservationError(this.code, this.reason);

  final String code;
  final String reason;

  @override
  String toString() => '$code: $reason';
}

/// Only the audited concrete build may establish this source contract.
void requireConcreteBoxSourceType(Widget widget, Type auditedType) {
  if (widget.runtimeType != auditedType) {
    throw const BoxObservationError(
      'UNREGISTERED_CONCRETE_SOURCE_PRODUCER',
      'An unknown subclass may override build or add supplied Widget slots.',
    );
  }
}

/// The current renderer's parameter and its source allocation are distinct.
enum PaddingQuantityKind {
  frameworkOwnParameter,
  declaredOuterEdgeInsetWithinBorder,
  declaredNoOwnPadding,
}

/// A declaring producer's generated subtree, excluding supplied widget slots.
class BoxProducerScope {
  BoxProducerScope({
    required this.producer,
    required Iterable<Widget> suppliedSlots,
    Iterable<Element> derivedSuppliedElements = const [],
  }) : suppliedSlots = List.unmodifiable(suppliedSlots) {
    final derived = Set<Element>.identity()..addAll(derivedSuppliedElements);
    for (final element in derived) {
      if (identical(element, producer) || !contains(producer, element)) {
        throw const BoxObservationError(
          'INVALID_DERIVED_SLOT_BOUNDARY',
          'A derived supplied slot must be inside its actual producer.',
        );
      }
    }
    final remaining = Set<Widget>.identity()..addAll(this.suppliedSlots);
    void visit(Element element) {
      if (!identical(element, producer) &&
          (derived.contains(element) ||
              this.suppliedSlots.any(
                (slot) => identical(slot, element.widget),
              ))) {
        foreignBoundaries.add(element);
        remaining.remove(element.widget);
        return;
      }
      element.visitChildren(visit);
    }

    visit(producer);
    if (remaining.isNotEmpty) {
      throw const BoxObservationError(
        'UNRESOLVED_SUPPLIED_SLOT',
        'A supplied slot has no rendered Element in the declared producer.',
      );
    }
  }

  final Element producer;
  final List<Widget> suppliedSlots;
  final List<Element> foreignBoundaries = [];

  static bool contains(Element ancestor, Element candidate) {
    if (identical(ancestor, candidate)) return true;
    var result = false;
    candidate.visitAncestorElements((element) {
      result = identical(element, ancestor);
      return !result;
    });
    return result;
  }

  void requireOwned(Element element) {
    if (!contains(producer, element)) {
      throw const BoxObservationError(
        'OUTSIDE_DECLARING_PRODUCER',
        'The source is outside the declaring producer.',
      );
    }
    if (foreignBoundaries.any((boundary) => contains(boundary, element))) {
      throw const BoxObservationError(
        'FOREIGN_SUPPLIED_CONTENT',
        'A caller-supplied subtree cannot supply the declaring box padding.',
      );
    }
  }
}

Element requireOneBoxOwner(Iterable<Element> elements, String role) {
  final candidates = elements.toList();
  if (candidates.isEmpty) {
    throw BoxObservationError('MISSING_OWNER', role);
  }
  if (candidates.length != 1) {
    throw BoxObservationError('DUPLICATE_OWNER', role);
  }
  return candidates.single;
}

/// A measured value always carries the actual source and allocation evidence.
class BoxPaddingObservation {
  const BoxPaddingObservation({
    required this.value,
    required this.quantity,
    required this.owner,
    required this.producer,
    required this.contentBoundary,
    required this.paddingElement,
    required this.currentRenderPadding,
    required this.allocatedDecorationInsets,
    required this.excludedMargin,
    required this.generatedSlots,
    this.frameOwner,
  });

  final EdgeInsets value;
  final PaddingQuantityKind quantity;
  final Element owner;
  final Element producer;
  final Element? contentBoundary;
  final Element? paddingElement;
  final EdgeInsets currentRenderPadding;
  final EdgeInsets allocatedDecorationInsets;
  final EdgeInsets excludedMargin;
  final List<Map<String, Object?>> generatedSlots;
  final Element? frameOwner;

  BoxPaddingObservation withFrameOwner(Element frame) => BoxPaddingObservation(
    value: value,
    quantity: quantity,
    owner: owner,
    producer: producer,
    contentBoundary: contentBoundary,
    paddingElement: paddingElement,
    currentRenderPadding: currentRenderPadding,
    allocatedDecorationInsets: allocatedDecorationInsets,
    excludedMargin: excludedMargin,
    generatedSlots: generatedSlots,
    frameOwner: frame,
  );

  Map<String, Object?> toJson() => {
    'status': 'measured',
    'quantityKind': quantity.name,
    'value': _four(value),
    'ownerElement': identityHashCode(owner),
    'ownerWidgetType': owner.widget.runtimeType.toString(),
    'declaringProducerWidgetType': producer.widget.runtimeType.toString(),
    'declaringProducerElement': identityHashCode(producer),
    'contentBoundaryElement': contentBoundary == null
        ? null
        : identityHashCode(contentBoundary),
    'frameSourceOwnerElement': frameOwner == null
        ? null
        : identityHashCode(frameOwner),
    'frameSourceStatus': frameOwner == null
        ? 'no-generated-frame-before-content'
        : 'bound-configured-frame',
    'paintPresenceInferred': false,
    'actualPaddingElement': paddingElement == null
        ? null
        : identityHashCode(paddingElement),
    'currentRenderPadding': _four(currentRenderPadding),
    'sameOwnerDecorationAllocation': _four(allocatedDecorationInsets),
    'excludedMargin': _four(excludedMargin),
    'generatedSlots': generatedSlots,
  };
}

List<double> _four(EdgeInsets insets) => [
  insets.top,
  insets.right,
  insets.bottom,
  insets.left,
];

/// Decodes Container's pinned framework build slots, independent of paint.
///
/// Margin and own padding may have the same value or even the same immutable
/// argument object. Their positions follow Container.build's generated slots,
/// not a first-Padding search or a comparison with an expected inset.
BoxPaddingObservation observeCurrentContainerPadding({
  required Element owner,
  required BoxProducerScope scope,
  Element? declaredContentBoundary,
}) {
  scope.requireOwned(owner);
  if (owner.widget is! Container) {
    throw const BoxObservationError(
      'NOT_CURRENT_CONTAINER',
      'The declared layout owner is not a current framework Container.',
    );
  }
  requireConcreteBoxSourceType(owner.widget, Container);
  final container = owner.widget as Container;
  final slots = <Map<String, Object?>>[];
  var current = _onlyChild(owner);

  Element take(String slot, bool Function(Widget) accepts) {
    final element = current;
    if (element == null || !accepts(element.widget)) {
      throw BoxObservationError(
        'CONTAINER_GENERATED_SLOT_CHANGED',
        'The framework $slot slot does not match Container.build.',
      );
    }
    slots.add({
      'slot': slot,
      'element': identityHashCode(element),
      'widget': element.widget.runtimeType.toString(),
    });
    current = _onlyChild(element);
    return element;
  }

  if (container.transform != null) {
    take('transform', (widget) => widget is Transform);
  }
  var margin = EdgeInsets.zero;
  if (container.margin != null) {
    final element = take('margin', (widget) => widget is Padding);
    margin = _renderPadding(element);
  }
  if (container.constraints != null) {
    take('constraints', (widget) => widget is ConstrainedBox);
  }
  if (container.foregroundDecoration != null) {
    take('foregroundDecoration', (widget) => widget is DecoratedBox);
  }
  if (container.decoration != null) {
    take('decoration', (widget) => widget is DecoratedBox);
  }
  if (container.clipBehavior != Clip.none) {
    take('clip', (widget) => widget is ClipPath);
  }
  if (container.color != null) {
    take('color', (widget) => widget is ColoredBox);
  }

  Element? ownPaddingElement;
  var actual = EdgeInsets.zero;
  if (container.padding != null || container.decoration != null) {
    ownPaddingElement = take(
      'paddingIncludingDecoration',
      (widget) => widget is Padding,
    );
    actual = _renderPadding(ownPaddingElement);
  }
  final createsEmptyContent =
      container.child == null && !(container.constraints?.isTight ?? false);
  if (!createsEmptyContent && container.alignment != null) {
    take('alignment', (widget) => widget is Align);
  }

  Element? boundary;
  if (container.child case final child?) {
    if (current == null || !identical(current!.widget, child)) {
      throw const BoxObservationError(
        'INVALID_CONTENT_BOUNDARY',
        'The generated slots do not end at the actual Container.child.',
      );
    }
    boundary = current;
    if (declaredContentBoundary != null &&
        !identical(declaredContentBoundary, boundary)) {
      throw const BoxObservationError(
        'INVALID_CONTENT_BOUNDARY',
        'The supplied boundary is a foreign descendant, not Container.child.',
      );
    }
  } else if (createsEmptyContent) {
    take('emptyContentLimit', (widget) => widget is LimitedBox);
    take('emptyContentConstraints', (widget) => widget is ConstrainedBox);
    if (current != null) {
      throw const BoxObservationError(
        'UNEXPECTED_EMPTY_CONTENT',
        'The framework empty-content slots have an unexpected descendant.',
      );
    }
  } else if (current != null) {
    throw const BoxObservationError(
      'UNEXPECTED_EMPTY_CONTENT',
      'A tight childless Container has unexpected generated content.',
    );
  }

  final direction = ownPaddingElement == null
      ? Directionality.maybeOf(owner)
      : (ownPaddingElement.renderObject! as RenderPadding).textDirection;
  final allocation =
      container.decoration?.padding.resolve(direction) ?? EdgeInsets.zero;
  return BoxPaddingObservation(
    value: .fromLTRB(
      actual.left - allocation.left,
      actual.top - allocation.top,
      actual.right - allocation.right,
      actual.bottom - allocation.bottom,
    ),
    quantity: .frameworkOwnParameter,
    owner: owner,
    producer: scope.producer,
    contentBoundary: boundary,
    paddingElement: ownPaddingElement,
    currentRenderPadding: actual,
    allocatedDecorationInsets: allocation,
    excludedMargin: margin,
    generatedSlots: slots,
    frameOwner:
        slots.any(
          (slot) => [
            'decoration',
            'foregroundDecoration',
            'color',
          ].contains(slot['slot']),
        )
        ? owner
        : null,
  );
}

Element? _onlyChild(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  if (children.length > 1) {
    throw const BoxObservationError(
      'AMBIGUOUS_FRAMEWORK_SLOT',
      'A framework generated slot has more than one Element child.',
    );
  }
  return children.singleOrNull;
}

EdgeInsets _renderPadding(Element element) {
  final render = element.renderObject;
  if (render is! RenderPadding) {
    throw const BoxObservationError(
      'PADDING_RENDER_OBJECT_CHANGED',
      'The declared Padding Element does not own a RenderPadding.',
    );
  }
  return render.padding.resolve(render.textDirection);
}

/// Resolves a source-declared supplied child through generated wrappers.
Element elementOfDeclaredChild(Element owner, Widget child) {
  var current = _onlyChild(owner);
  for (var depth = 0; depth < 80; depth++) {
    if (current == null) break;
    if (identical(current.widget, child)) return current;
    current = _onlyChild(current);
  }
  throw const BoxObservationError(
    'UNRESOLVED_DECLARED_CHILD',
    'The actual child object is not on the declared generated path.',
  );
}

/// Reads the evaluated framework Container, never an animation target value.
Element evaluatedAnimatedContainer(Element animationOwner) {
  if (animationOwner.widget is! AnimatedContainer) {
    throw const BoxObservationError(
      'NOT_ANIMATED_CONTAINER',
      'The declared source is not an AnimatedContainer.',
    );
  }
  requireConcreteBoxSourceType(animationOwner.widget, AnimatedContainer);
  final current = _onlyChild(animationOwner);
  if (current == null || current.widget is! Container) {
    throw const BoxObservationError(
      'ANIMATED_CONTAINER_BUILD_CHANGED',
      'The current framework build is not a single Container.',
    );
  }
  return current;
}

/// Reads an exact source-bound framework Padding, independent of chrome.
BoxPaddingObservation observeSourceOwnedRenderPadding({
  required Element owner,
  required BoxProducerScope scope,
}) {
  scope.requireOwned(owner);
  if (owner.widget is! Padding || owner.renderObject is! RenderPadding) {
    throw const BoxObservationError(
      'NOT_DECLARED_CONTENT_PADDING',
      'The actual source slot is not a Padding renderer.',
    );
  }
  requireConcreteBoxSourceType(owner.widget, Padding);
  final render = owner.renderObject! as RenderPadding;
  final actual = render.padding.resolve(render.textDirection);
  return BoxPaddingObservation(
    value: actual,
    quantity: .frameworkOwnParameter,
    owner: owner,
    producer: scope.producer,
    contentBoundary: (owner.widget as Padding).child == null
        ? null
        : elementOfDeclaredChild(owner, (owner.widget as Padding).child!),
    paddingElement: owner,
    currentRenderPadding: actual,
    allocatedDecorationInsets: EdgeInsets.zero,
    excludedMargin: EdgeInsets.zero,
    generatedSlots: const [],
  );
}

/// Enumerates a rendered subtree for an already declared source identity.
List<Element> boxElements(Element root) {
  final elements = <Element>[];
  void visit(Element element) {
    elements.add(element);
    element.visitChildren(visit);
  }

  visit(root);
  return elements;
}

/// Resolves the framework Container that generated an exact frame primitive.
/// Supplied children are outside that Container's generated region.
Element containerOwningFrame({
  required Element captureRoot,
  required RenderObject frame,
  required BoxProducerScope scope,
}) {
  final frameElement = requireOneBoxOwner(
    boxElements(captureRoot).where(
      (element) =>
          element is RenderObjectElement &&
          identical(element.renderObject, frame),
    ),
    'the actual frame RenderObjectElement',
  );
  scope.requireOwned(frameElement);
  final candidates = <Element>[];
  frameElement.visitAncestorElements((element) {
    if (element.widget is Container) {
      final container = element.widget as Container;
      var current = _onlyChild(element);
      while (current != null && !identical(current.widget, container.child)) {
        if (identical(current, frameElement)) {
          candidates.add(element);
          break;
        }
        current = _onlyChild(current);
      }
    }
    return !identical(element, captureRoot);
  });
  final owner = requireOneBoxOwner(
    candidates,
    'the Container that generated the exact frame',
  );
  scope.requireOwned(owner);
  return owner;
}
