import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/accordion/accordion_default_example.dart';
import 'package:docs_core/previews/examples/flutter/card/card_default_example.dart';
import 'package:docs_core/previews/examples/flutter/card/card_elevated_example.dart';
import 'package:docs_core/previews/examples/flutter/card/card_filled_example.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show
        Column,
        DecoratedBox,
        Element,
        InheritedWidget,
        IntrinsicWidth,
        KeyedSubtree,
        RenderObjectElement,
        SizedBox,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

const _kExamples = {
  CardDefaultExample,
  CardFilledExample,
  CardElevatedExample,
  AccordionDefaultExample,
};

/// The quantity ends at the primitive's generated content boundary. Card slot
/// padding and Accordion item padding remain opaque and are never summed.
CurrentCardAccordionFrame bindCardAccordionEntryFrame({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!_kExamples.contains(registryResult.runtimeType)) {
    throw _changed('exact original public Example');
  }
  final result = identical(captureRoot.widget, registryResult)
      ? captureRoot
      : _only(captureRoot);
  if (!identical(result.widget, registryResult) ||
      (!identical(result, captureRoot) &&
          (captureRoot.widget is! KeyedSubtree ||
              !identical(
                (captureRoot.widget as KeyedSubtree).child,
                registryResult,
              )))) {
    throw _changed('original capture construction result');
  }
  final card = registryResult.runtimeType != AccordionDefaultExample;
  if (source !=
      (card
          ? BoxObservationSourceSpec.cardSurfaceFrame
          : BoxObservationSourceSpec.accordionSurfaceFrame)) {
    throw _changed('complete closed frame tuple');
  }
  return CurrentCardAccordionFrame._(
    _only(result),
    captureRoot,
    registryResult,
    result,
  );
}

/// Product controls bind an already mounted public product, without replay.
CurrentCardAccordionFrame bindCurrentCardAccordionFrame(Element producer) =>
    CurrentCardAccordionFrame._(producer, null, null, null);

class CurrentCardAccordionFrame {
  CurrentCardAccordionFrame._(
    this.producer,
    this.captureRoot,
    this.registryResult,
    this.registryElement,
  ) {
    _held = _snapshot();
  }
  final Element producer;
  final Element? captureRoot;
  final Widget? registryResult;
  final Element? registryElement;
  late final _FrameSnapshot _held;

  Map<String, Object?> get sourceIdentity {
    validateCurrentBinding();
    return _held.identity;
  }

  void validateCurrentBinding() {
    final now = _snapshot();
    if (!_same(_held.held, now.held)) {
      throw _changed('held original frame, parameters or raw declarations');
    }
  }

  BoxPaddingObservation readActualPadding() {
    validateCurrentBinding();
    // All ownership, declaration and generated-boundary checks precede this
    // existing reader's actual current RenderPadding parameter measurement.
    final result = observeOutlinedContainerContentPadding(
      primitive: _held.primitive,
      declaringScope: _held.scope,
    );
    validateCurrentBinding();
    return result;
  }

  _FrameSnapshot _snapshot() {
    if (!producer.mounted) {
      throw _changed('mounted public producer');
    }
    if (captureRoot != null &&
        (!captureRoot!.mounted ||
            !identical(registryElement!.widget, registryResult) ||
            !identical(_only(registryElement!), producer))) {
      throw _changed('held Example and direct public producer');
    }
    final held = <Object?>[
      captureRoot,
      registryResult,
      registryElement,
      producer,
      producer.widget,
    ];
    final declarations = <Map<String, Object?>>[];
    var current = _only(producer);
    final product = producer.widget;
    if (product.runtimeType == coui.Card) {
      final card = product as coui.Card;
      if (card.onTap != null) {
        throw _changed('noninteractive Card frame');
      }
      final raw = <Widget?>[
        card.child,
        card.media,
        card.header,
        card.body,
        card.footer,
        card.overlay,
      ];
      const names = ['child', 'media', 'header', 'body', 'footer', 'overlay'];
      // All nullable inputs, including inactive declarations, are retained
      // before omission. This is declaration authority, not individual mounts.
      held.addAll(raw);
      for (var i = 0; i < raw.length; i++) {
        declarations.add({
          'index': i,
          'slot': names[i],
          'present': raw[i] != null,
          'sourceAliasOf': _alias(raw, i),
          'authority': 'public-declaration-only',
        });
      }
      if (current.widget.runtimeType == IntrinsicWidth) {
        final child = (current.widget as IntrinsicWidth).child;
        held.addAll([current, current.widget]);
        current = _forward(current, child);
      } else if (current.widget.runtimeType == SizedBox) {
        final child = (current.widget as SizedBox).child;
        held.addAll([current, current.widget]);
        current = _forward(current, child);
      }
      if (current.widget.runtimeType == DecoratedBox) {
        final child = (current.widget as DecoratedBox).child;
        held.addAll([current, current.widget, current.renderObject]);
        current = _forward(current, child);
      }
    } else if (product.runtimeType == coui.Accordion) {
      final accordion = product as coui.Accordion;
      held.add(accordion.items);
      for (var i = 0; i < accordion.items.length; i++) {
        final item = accordion.items[i];
        if (item.runtimeType != coui.AccordionItem) {
          throw _changed('complete public AccordionItem data roster');
        }
        final input = item as coui.AccordionItem;
        held.addAll([
          item,
          input.trigger,
          input.content,
          input.title,
          input.expanded,
        ]);
        declarations.add({
          'index': i,
          'sourceAliasOf': _alias(accordion.items, i),
          'titlePresent': input.title != null,
          'triggerPresent': input.trigger != null,
          'contentPresent': true,
          'authority': 'public-item-declaration',
        });
      }
      // The private style object and State are never inspected. Both retained
      // inherited hops are proved solely through public InheritedWidget.child.
      current = _inherited(current, held);
      if (current.widget is! coui.Data<Object?>) {
        throw _changed('public Data forwarding');
      }
      final data = current.widget as coui.Data<Object?>;
      held.addAll([current, data]);
      final inherited = _only(current);
      current = _inherited(inherited, held);
      if (!identical(current.widget, data.child) ||
          current.widget.runtimeType != IntrinsicWidth) {
        throw _changed('same Data.child IntrinsicWidth');
      }
      held.addAll([current, current.widget]);
      current = _forward(current, (current.widget as IntrinsicWidth).child);
    } else {
      throw _changed('exact public Card or Accordion');
    }
    if (current.widget.runtimeType != coui.OutlinedContainer) {
      throw _changed('unique direct generated surface primitive');
    }
    final primitive = current;
    final content = (primitive.widget as coui.OutlinedContainer).child;
    if (content == null) {
      throw _changed('generated content boundary');
    }
    final scope = BoxProducerScope(
      producer: producer,
      suppliedSlots: [content],
    );
    final boundaries = scope.foreignBoundaries;
    if (boundaries.length != 1 ||
        !identical(boundaries.single.widget, content)) {
      throw _changed('unique pruned generated content boundary');
    }
    final boundary = boundaries.single;
    held.addAll([primitive, primitive.widget, content, boundary]);
    if (product is coui.Accordion) {
      if (content.runtimeType != Column) {
        throw _changed('public item Column');
      }
      final list = (content as Column).children;
      final n = product.items.length;
      final separated = list.length == n * 2;
      if (list.length != n && !separated) {
        throw _changed('whole item topology');
      }
      final seats = <Element>[];
      boundary.visitChildren(seats.add);
      if (seats.length != list.length || seats.toSet().length != list.length) {
        throw _changed('distinct current Column occurrence seats');
      }
      for (var i = 0; i < list.length; i++) {
        if (!identical(seats[i].widget, list[i]) ||
            !(separated && i.isOdd
                ? list[i].runtimeType == coui.Divider
                : identical(list[i], product.items[separated ? i ~/ 2 : i]))) {
          throw _changed('complete ordered item and separator occurrences');
        }
        held.addAll([list[i], seats[i]]);
      }
    }
    scope.requireOwned(primitive);
    // Retain only the owned primitive prefix, ending before generated opaque
    // content. These are parameter identities/directions, not scalar values.
    void own(Element element) {
      if (identical(element, boundary)) return;
      scope.requireOwned(element);
      held.addAll([element, element.widget]);
      if (element is RenderObjectElement) {
        final render = element.renderObject;
        held.add(render);
        if (render is RenderPadding) {
          held.addAll([render.padding, render.textDirection]);
        }
      }
      element.visitChildren(own);
    }

    own(primitive);
    return _FrameSnapshot(primitive, scope, held, {
      'kind': 'current-public-surface-frame-v1',
      'quantityBoundary': 'outer-surface-to-immediate-generated-content',
      'distributedSlotAndItemInsetsIncluded': false,
      'producerElement': identityHashCode(producer),
      'primitiveElement': identityHashCode(primitive),
      'generatedOpaqueContentElement': identityHashCode(boundary),
      'rawDeclarations': declarations,
      'rawDeclarationMountAuthority': false,
      'heldBeforeAfterRequired': true,
    });
  }
}

class _FrameSnapshot {
  _FrameSnapshot(this.primitive, this.scope, this.held, this.identity);
  final Element primitive;
  final BoxProducerScope scope;
  final List<Object?> held;
  final Map<String, Object?> identity;
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  if (children.length != 1) {
    throw _changed('single current public forwarding');
  }
  return children.single;
}

Element _forward(Element parent, Widget? child) {
  final next = _only(parent);
  if (child == null || !identical(next.widget, child)) {
    throw _changed('same actual public child');
  }
  return next;
}

Element _inherited(Element element, List<Object?> held) {
  if (element.widget is! InheritedWidget) {
    throw _changed('inherited forwarding');
  }
  held.addAll([element, element.widget]);
  return _forward(element, (element.widget as InheritedWidget).child);
}

int? _alias(List<Widget?> raw, int i) => raw[i] == null
    ? null
    : [
        for (var j = 0; j < i; j++)
          if (identical(raw[i], raw[j])) j,
      ].firstOrNull;
bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);
BoxObservationError _changed(String reason) => BoxObservationError(
  'SURFACE_FRAME_SOURCE_CHANGED',
  reason,
);
