import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/command_search/command_search_default_example.dart';
import 'package:docs_core/previews/examples/flutter/dock/dock_default_example.dart';
import 'package:docs_core/previews/examples/flutter/navigation_bar/navigation_bar_default_example.dart';
import 'package:docs_core/previews/examples/flutter/navigation_bar/navigation_bar_rail_example.dart';
import 'package:docs_core/previews/examples/flutter/navigation_bar/navigation_bar_sidebar_example.dart';
import 'package:flutter/rendering.dart' show RenderBox, RenderPadding;
import 'package:flutter/widgets.dart'
    show
        AnimatedContainer,
        AnimatedScale,
        Axis,
        Builder,
        Center,
        Column,
        ConstrainedBox,
        Container,
        DecoratedBox,
        DecorationPosition,
        Element,
        Expanded,
        Flexible,
        IconTheme,
        IgnorePointer,
        IndexedSlot,
        InheritedWidget,
        IntrinsicHeight,
        IntrinsicWidth,
        KeyedSubtree,
        LayoutBuilder,
        Padding,
        Positioned,
        Row,
        SafeArea,
        Semantics,
        SingleChildScrollView,
        SizedBox,
        Stack,
        StatelessWidget,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

enum _Kind { command, navigation, dock }

typedef _Route = ({
  Element result,
  Element producer,
  Element field,
  Element padding,
  Element frame,
  BoxProducerScope scope,
  List<Widget?> raw,
  List<Object?> operation,
});

/// Current owned parameters only. Future source constants are Root-owned;
/// this artifact prototype grants no recipe eligibility or runtime approval.
class NavigationTriggerBoxSourceBinding {
  NavigationTriggerBoxSourceBinding._(
    this._capture,
    this._registry,
    this._source,
    this._kind,
    this._route,
  ) : _producerWidget = _route.producer.widget,
      _raw = List.unmodifiable(_route.raw),
      _operation = List.unmodifiable(_route.operation);
  final Element _capture;
  final Widget _registry;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;
  final _Kind _kind;
  final _Route _route;
  final List<Widget?> _raw;
  final List<Object?> _operation;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.field;
  Element get paddingSource => _route.padding;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId => _kind == _Kind.dock
      ? 'current-framework-container-padding-v1'
      : 'current-render-padding-v1';
  String get authority =>
      'Exact current public construction edges; complete '
      'ordered raw slots and data kinds before omission; current parameter '
      'allocation only; no callbacks/private state/Core/Resolved geometry';
  void validateExistingCurrentBinding() {
    if (!_capture.mounted ||
        !_route.result.mounted ||
        !_route.producer.mounted ||
        !identical(_route.result.widget, _registry) ||
        !identical(_route.producer.widget, _producerWidget)) {
      throw _changed('held current producer');
    }
    final now = _locate(_capture, _registry, _source, _kind);
    if (!identical(now.result, registryResultElement) ||
        !identical(now.producer, _route.producer) ||
        !identical(now.field, fieldUnitElement) ||
        !identical(now.padding, paddingSource) ||
        !identical(now.frame, frameSource) ||
        !_same(now.raw, _raw, identity: true) ||
        !_same(now.operation, _operation) ||
        !_same(
          now.scope.foreignBoundaries,
          scope.foreignBoundaries,
          identity: true,
        )) {
      throw _changed('held operation/raw slots/frame');
    }
  }

  BoxPaddingObservation readActualPadding() {
    validateExistingCurrentBinding();
    if (_kind == _Kind.dock) {
      // Container's existing pinned framework decoder excludes its actual
      // decoration reserve and its margin. Inner rowPadding is not added.
      return observeCurrentContainerPadding(
        owner: paddingSource,
        scope: scope,
      ).withFrameOwner(frameSource);
    }
    return observeSourceOwnedRenderPadding(
      owner: paddingSource,
      scope: scope,
    ).withFrameOwner(frameSource);
  }
}

NavigationTriggerBoxSourceBinding? bindNavigationTriggerBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final kind = switch (source.logicalUnitId) {
    'command-search-generated-trigger-content-inset' => _Kind.command,
    'navigation-bar-generated-items-content-inset' => _Kind.navigation,
    'dock-generated-bar-content-inset' => _Kind.dock,
    _ => null,
  };
  if (kind == null) return null;
  return NavigationTriggerBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    kind,
    _locate(captureRoot, registryResult, source, kind),
  );
}

BoxObservationSourceSpec _spec(_Kind kind) => switch (kind) {
  _Kind.command => BoxObservationSourceSpec.commandSearchTriggerContentInset,
  _Kind.navigation => BoxObservationSourceSpec.navigationBarItemsContentInset,
  _Kind.dock => BoxObservationSourceSpec.dockBarContentInset,
};
Type _type(_Kind kind) => switch (kind) {
  _Kind.command => coui.CommandSearch,
  _Kind.navigation => coui.NavigationBar,
  _Kind.dock => coui.Dock,
};
bool _example(Widget widget, _Kind kind) => switch (kind) {
  _Kind.command => widget.runtimeType == CommandSearchDefaultExample,
  _Kind.navigation =>
    widget.runtimeType == NavigationBarDefaultExample ||
        widget.runtimeType == NavigationBarRailExample ||
        widget.runtimeType == NavigationBarSidebarExample,
  _Kind.dock => widget.runtimeType == DockDefaultExample,
};

_Route _locate(
  Element capture,
  Widget registry,
  BoxObservationSourceSpec source,
  _Kind kind,
) {
  if (source != _spec(kind)) throw _changed('closed source tuple/version');
  if (!capture.mounted ||
      !(identical(capture.widget, registry) ||
          (capture.widget.runtimeType == KeyedSubtree &&
              identical((capture.widget as KeyedSubtree).child, registry)))) {
    throw _changed('canonical capture construction');
  }
  final result = _identity(capture, registry);
  var producer = result;
  if (registry.runtimeType != _type(kind)) {
    if (!_example(registry, kind)) throw _changed('exact audited recipe');
    producer = _only(result);
    if (kind == _Kind.command) {
      _concrete(producer, SizedBox);
      producer = _child(producer, (producer.widget as SizedBox).child);
    }
  }
  _concrete(producer, _type(kind));
  final raw = _raw(producer.widget, kind);
  _unique(raw); // Never omit a slot or branch before this check.
  final omitted = Set<Widget>.identity();
  final operation = <Object?>[];
  late Element frame;
  late Element padding;
  switch (kind) {
    case _Kind.command:
      final w = producer.widget as coui.CommandSearch;
      final clickable = _only(producer);
      _concrete(clickable, coui.Clickable);
      final cw = clickable.widget as coui.Clickable;
      if (!identical(cw.onPressed, w.onPressed) ||
          cw.enabled != (w.enabled ?? (w.onPressed != null))) {
        throw _changed('current trigger forwarding');
      }
      final animation = _identity(clickable, cw.child);
      _concrete(animation, AnimatedContainer);
      frame = evaluatedAnimatedContainer(animation);
      final stackUnit = elementOfDeclaredChild(
        frame,
        (frame.widget as Container).child!,
      );
      _concrete(stackUnit, coui.Stacks);
      final seats = (stackUnit.widget as coui.Stacks).children;
      final stack = _stack(stackUnit);
      if (seats.length != 1 && seats.length != 2) throw _changed('wash seats');
      if (seats.length == 2) _paintedPosition(_child(stack, seats.first));
      padding = _child(stack, seats.last);
      _concrete(padding, Padding);
      final row = _child(padding, (padding.widget as Padding).child);
      _concrete(row, Row);
      final rowSeats = (row.widget as Row).children;
      if (rowSeats.length != (w.shortcut == null ? 3 : 5)) {
        throw _changed('whole trigger seats');
      }
      final renderedSeats = _orderedCurrentRowSeats(row);
      final merge = renderedSeats[0];
      _concrete(merge, Builder);
      // Flutter IconTheme.merge's already executed public Builder result.
      // Never invoke its callback or skip an arbitrary builder/descendant.
      final theme = _only(merge);
      _concrete(theme, IconTheme);
      final leading = (theme.widget as IconTheme).child;
      if (w.leading != null && !identical(leading, w.leading)) {
        throw _changed('whole leading slot');
      }
      if (w.leading == null) _concrete(_child(theme, leading), coui.Icon);
      _concrete(renderedSeats[1], coui.Gap);
      final hint = renderedSeats[2];
      _concrete(hint, Expanded);
      _concrete(_child(hint, (hint.widget as Expanded).child), coui.Text);
      if (w.shortcut != null) {
        if (!identical(rowSeats[1], rowSeats[3])) {
          throw _changed('the source-generated shared Gap declaration');
        }
        _concrete(renderedSeats[3], coui.Gap);
        if (!identical(rowSeats[4], w.shortcut)) {
          throw _changed('whole shortcut');
        }
        if (!identical(renderedSeats[4].widget, w.shortcut)) {
          throw _changed('the whole shortcut seat');
        }
      }
      operation.addAll([w.leading, w.shortcut, w.hint, w.enabled, cw.enabled]);
    case _Kind.dock:
      final w = producer.widget as coui.Dock;
      var root = _only(producer);
      _concrete(root, coui.CoUISemantics);
      final declared = root.widget as coui.CoUISemantics;
      if (declared.role != coui.CoreSemanticRole.navigation) {
        throw _changed('the source-owned navigation semantics');
      }
      root = _only(root);
      _concrete(root, Semantics);
      if (!identical((root.widget as Semantics).child, declared.child)) {
        throw _changed('the whole CoUISemantics child forwarding');
      }
      root = _child(root, declared.child);
      _concrete(root, Padding); // Authored barMargin, excluded from this field.
      root = _child(root, (root.widget as Padding).child);
      _concrete(root, coui.InjectedCast);
      root = _identity(root, (root.widget as coui.InjectedCast).child);
      _concrete(root, coui.SurfaceBlur);
      root = _identity(root, (root.widget as coui.SurfaceBlur).child);
      _concrete(root, coui.InsetShadow);
      frame = _identity(root, (root.widget as coui.InsetShadow).child);
      _concrete(frame, Container);
      final content = (frame.widget as Container).child;
      if ((frame.widget as Container).padding == null || content == null) {
        throw _changed('actual bar Container parameter allocation');
      }
      final stackUnit = elementOfDeclaredChild(frame, content);
      _concrete(stackUnit, coui.Stacks);
      final seats = (stackUnit.widget as coui.Stacks).children;
      final stack = _stack(stackUnit);
      if (seats.length != 1 && seats.length != 2) {
        throw _changed('flight seats');
      }
      if (seats.length == 2) {
        var flight = _child(stack, seats.first);
        _concrete(flight, coui.Position);
        flight = _only(flight);
        _concrete(flight, Positioned);
        flight = _child(flight, (flight.widget as Positioned).child);
        _concrete(flight, IgnorePointer);
        flight = _child(flight, (flight.widget as IgnorePointer).child);
        _concrete(flight, coui.LiquidMorphClip);
        final painted = _identity(
          flight,
          (flight.widget as coui.LiquidMorphClip).child,
        );
        _concrete(painted, DecoratedBox);
      }
      final rowPadding = _child(stack, seats.last);
      _concrete(rowPadding, Padding);
      final row = _child(rowPadding, (rowPadding.widget as Padding).child);
      _concrete(row, Row);
      final itemSeats = (row.widget as Row).children;
      if (itemSeats.length != w.items.length) throw _changed('all Dock items');
      for (var i = 0; i < w.items.length; i++) {
        _dockItem(
          _child(row, itemSeats[i]),
          w.items[i],
          flight: seats.length == 2,
        );
      }
      padding = frame; // Deliberately excludes the independent rowPadding.
      operation.addAll(w.items);
    case _Kind.navigation:
      final w = producer.widget as coui.NavigationBar;
      var root = _only(producer);
      if (root.widget.runtimeType == SafeArea) {
        root = _child(root, (root.widget as SafeArea).child);
      }
      _concrete(root, Semantics);
      root = _child(root, (root.widget as Semantics).child);
      _concrete(root, Padding); // Authored barMargin is outside the field.
      root = _child(root, (root.widget as Padding).child);
      _concrete(root, AnimatedScale);
      root = _identity(root, (root.widget as AnimatedScale).child);
      // An unknown material/glass bridge has no public proof here: HOLD.
      _concrete(root, coui.SurfaceBlur);
      frame = _identity(root, (root.widget as coui.SurfaceBlur).child);
      _concrete(frame, Container);
      var content = elementOfDeclaredChild(
        frame,
        (frame.widget as Container).child!,
      );
      if (content.widget.runtimeType == DecoratedBox) {
        final painted = content.widget as DecoratedBox;
        if (painted.position != DecorationPosition.foreground) {
          throw _changed('authored foreground hairline');
        }
        content = _child(content, painted.child);
      }
      if (w.header != null || w.footer != null) {
        if (content.widget is! StatelessWidget) {
          throw _changed('footer build edge');
        }
        final layout = _only(content);
        _concrete(layout, LayoutBuilder);
        padding = _only(layout);
        _concrete(padding, Padding);
        var sequence = _child(padding, (padding.widget as Padding).child);
        if (w.mode.isVertical) {
          _concrete(sequence, IntrinsicWidth);
          sequence = _child(
            sequence,
            (sequence.widget as IntrinsicWidth).child,
          );
          _concrete(sequence, Column);
        } else {
          _concrete(sequence, Row);
        }
        final seats = _flexSeats(sequence);
        if (seats.length !=
            1 + (w.header == null ? 0 : 1) + (w.footer == null ? 0 : 1)) {
          throw _changed('whole current header/items/footer');
        }
        var i = 0;
        if (w.header != null) {
          if (!identical(seats[i++], w.header)) {
            throw _changed('header identity');
          }
        }
        var items = _child(sequence, seats[i]);
        if (items.widget.runtimeType == Expanded ||
            items.widget.runtimeType == Flexible) {
          items = _child(items, (items.widget as Flexible).child);
        }
        _navContent(items, w); // Inner zero allocation remains a separate unit.
        if (w.footer != null && !identical(seats.last, w.footer)) {
          throw _changed('footer identity');
        }
      } else {
        padding = _navContent(content, w);
      }
      for (final item in w.items) {
        switch (item.kind) {
          case .item:
            break;
          case .label:
          case .divider:
          case .gap:
            if (item.icon != null) omitted.add(item.icon!);
            if (item.badge != null) omitted.add(item.badge!);
        }
      }
      operation.addAll([
        w.mode,
        w.selectedIndex,
        w.header,
        w.footer,
        ...w.items,
      ]);
  }
  final boundaries = <Element>[];
  for (final slot in raw.whereType<Widget>()) {
    final matches = _matches(producer, slot);
    if (omitted.contains(slot)) {
      if (matches.isNotEmpty) {
        throw _changed('a source-omitted raw slot mounted');
      }
    } else {
      if (matches.length != 1) throw _changed('one whole supplied slot');
      boundaries.add(matches.single);
    }
  }
  final scope =
      BoxProducerScope(
          producer: result,
          suppliedSlots: const [],
          derivedSuppliedElements: boundaries,
        )
        ..requireOwned(producer)
        ..requireOwned(frame)
        ..requireOwned(padding);
  if (frame.renderObject is! RenderBox ||
      (kind != _Kind.dock && padding.renderObject is! RenderPadding)) {
    throw _changed('actual owned frame/parameter renderer');
  }
  return (
    result: result,
    producer: producer,
    field: frame,
    padding: padding,
    frame: frame,
    scope: scope,
    raw: raw,
    operation: operation,
  );
}

// Public framework slots, not visit order, identify every direct Row seat.
// This authorizes only the product-created Gap alias at its two named seats;
// raw supplied identities still pass _unique before this projection.
List<Element> _orderedCurrentRowSeats(Element row) {
  _concrete(row, Row);
  final declared = (row.widget as Row).children;
  final bySlot = <int, Element>{};
  row.visitChildElements((child) {
    final slot = child.slot;
    if (slot is! IndexedSlot<Element?> ||
        slot.index < 0 ||
        slot.index >= declared.length ||
        bySlot.containsKey(slot.index)) {
      throw _changed('a bijection over the complete direct Row slots');
    }
    bySlot[slot.index] = child;
  });
  if (bySlot.length != declared.length) {
    throw _changed('all declared Row children currently mounted');
  }
  final current = <Element>[];
  Element? previous;
  for (var i = 0; i < declared.length; i++) {
    final child = bySlot[i];
    if (child == null || !identical(child.widget, declared[i])) {
      throw _changed('each Row slot and its declared Widget identity');
    }
    final slot = child.slot;
    if (slot is! IndexedSlot<Element?> ||
        slot.index != i ||
        !identical(slot.value, previous)) {
      throw _changed('the public current sibling predecessor chain');
    }
    current.add(child);
    previous = child;
  }
  return current;
}

Element _navContent(Element content, coui.NavigationBar w) {
  var current = content;
  Element padding;
  Element row;
  if (w.mode == coui.CoreNavigationBarMode.bar) {
    _concrete(current, LayoutBuilder);
    current = _only(current);
    if (current.widget.runtimeType == Padding) {
      padding = current;
      row = _child(current, (current.widget as Padding).child);
      // A glass-track replacement is unsupported until independently proved.
      _concrete(row, coui.TouchTarget);
      row = _identity(row, (row.widget as coui.TouchTarget).child);
      _concrete(row, IntrinsicHeight);
      row = _child(row, (row.widget as IntrinsicHeight).child);
    } else {
      (padding, row) = _navScroll(current, w);
    }
    _concrete(row, Row);
  } else {
    (padding, row) = _navScroll(current, w);
    _concrete(row, Column);
  }
  final seats = _flexSeats(row);
  if (seats.length != w.items.length) {
    throw _changed('all ordered navigation kinds');
  }
  var destination = 0;
  for (var i = 0; i < w.items.length; i++) {
    final item = w.items[i];
    var seat = _child(row, seats[i]);
    switch (item.kind) {
      case .item:
        if (seat.widget.runtimeType == Expanded ||
            seat.widget.runtimeType == SizedBox) {
          seat = seat.widget is Flexible
              ? _child(seat, (seat.widget as Flexible).child)
              : _child(seat, (seat.widget as SizedBox).child);
        }
        _concrete(seat, coui.NavigationBarItem);
        final actual = seat.widget as coui.NavigationBarItem;
        if (!identical(actual.icon, item.icon) ||
            !identical(actual.badge, item.badge) ||
            actual.label != item.label ||
            actual.enabled != item.enabled ||
            actual.mode != w.mode ||
            actual.selected != (w.selectedIndex == destination)) {
          throw _changed('composed public current item forwarding');
        }
        destination++;
      case .gap:
        _concrete(seat, coui.Gap);
      case .label:
        if (seat.widget is! StatelessWidget) throw _changed('label build edge');
        seat = _only(seat);
        _concrete(seat, Padding);
        seat = _child(seat, (seat.widget as Padding).child);
        _concrete(seat, coui.Text);
      case .divider:
        if (seat.widget is! StatelessWidget) {
          throw _changed('divider build edge');
        }
        seat = _only(seat);
        _concrete(seat, Padding);
        _concrete(_child(seat, (seat.widget as Padding).child), coui.Divider);
    }
  }
  return padding;
}

(Element, Element) _navScroll(Element scroll, coui.NavigationBar w) {
  _concrete(scroll, SingleChildScrollView);
  final s = scroll.widget as SingleChildScrollView;
  if (s.padding == null ||
      s.child == null ||
      s.scrollDirection !=
          (w.mode.isVertical ? Axis.vertical : Axis.horizontal)) {
    throw _changed('current authored scroll allocation');
  }
  final child = _identity(scroll, s.child);
  final padding = _parent(child);
  _concrete(padding, Padding);
  if (!identical((padding.widget as Padding).child, s.child)) {
    throw _changed('pinned framework scroll Padding -> declared child edge');
  }
  var row = child;
  if (w.mode == coui.CoreNavigationBarMode.bar) {
    if (row.widget.runtimeType == ConstrainedBox) {
      row = _child(row, (row.widget as ConstrainedBox).child);
    }
    // The executed source RowExtent is viewed only as its public inherited
    // child contract, never by private RTTI or its private data.
    if (row.widget is! InheritedWidget) throw _changed('row extent child edge');
    row = _child(row, (row.widget as InheritedWidget).child);
  }
  if (row.widget.runtimeType == coui.TouchTarget) {
    row = _identity(row, (row.widget as coui.TouchTarget).child);
  }
  if (w.mode.isVertical) {
    _concrete(row, IntrinsicWidth);
    row = _child(row, (row.widget as IntrinsicWidth).child);
  } else {
    _concrete(row, IntrinsicHeight);
    row = _child(row, (row.widget as IntrinsicHeight).child);
  }
  return (padding, row);
}

void _dockItem(
  Element item,
  coui.CoreDockItemData<Widget> raw, {
  required bool flight,
}) {
  if (item.widget is! StatelessWidget) throw _changed('Dock item build edge');
  var e = _only(item);
  if (raw.onPressed != null) {
    _concrete(e, coui.Clickable);
    final click = e.widget as coui.Clickable;
    if (!identical(click.onPressed, raw.onPressed)) {
      throw _changed('Dock handler forwarding');
    }
    e = _identity(e, click.child);
  }
  _concrete(e, Semantics);
  if ((e.widget as Semantics).properties.selected != raw.isActive ||
      (e.widget as Semantics).properties.button != (raw.onPressed != null)) {
    throw _changed('current Dock item semantics');
  }
  e = _child(e, (e.widget as Semantics).child);
  if (e.widget.runtimeType == SizedBox) {
    e = _child(e, (e.widget as SizedBox).child);
  }
  _concrete(e, Column);
  final seats = (e.widget as Column).children;
  if (seats.length != 1 && seats.length != 3) {
    throw _changed('Dock icon/label seats');
  }
  final unit = _child(e, seats.first);
  _concrete(unit, coui.Stacks);
  final stack = _stack(unit);
  final children = (unit.widget as coui.Stacks).children;
  if (children.length != 1 + (raw.isActive && !flight ? 1 : 0)) {
    throw _changed('Dock plate seats');
  }
  if (children.length == 2) _paintedPosition(_child(stack, children.first));
  var icon = _child(stack, children.last);
  _concrete(icon, KeyedSubtree);
  icon = _child(icon, (icon.widget as KeyedSubtree).child);
  if (icon.widget.runtimeType == SizedBox) {
    icon = _child(icon, (icon.widget as SizedBox).child);
    _concrete(icon, Center);
    icon = _child(icon, (icon.widget as Center).child);
  }
  _concrete(icon, IconTheme);
  if (!identical((icon.widget as IconTheme).child, raw.icon)) {
    throw _changed('whole Dock icon');
  }
  _child(icon, raw.icon);
  if (seats.length == 3) {
    if (raw.label == null) throw _changed('current Dock label presence');
    _concrete(_child(e, seats[1]), coui.Gap);
    _concrete(_child(e, seats[2]), coui.Text);
  }
}

List<Widget?> _raw(Widget widget, _Kind kind) {
  switch (kind) {
    case _Kind.command:
      final w = widget as coui.CommandSearch;
      return [w.leading, w.shortcut];
    case _Kind.dock:
      final w = widget as coui.Dock;
      for (final item in w.items) {
        if (item.runtimeType != (coui.CoreDockItemData<Widget>)) {
          throw _changed('concrete Dock generic data');
        }
      }
      return [for (final item in w.items) item.icon];
    case _Kind.navigation:
      final w = widget as coui.NavigationBar;
      for (final item in w.items) {
        if (item.runtimeType != (coui.CoreNavigationBarItem<Widget>)) {
          throw _changed('concrete Navigation generic data');
        }
      }
      return [
        for (final item in w.items) ...[item.icon, item.badge],
        w.header,
        w.footer,
      ];
  }
}

void _unique(List<Widget?> raw) {
  final seen = Set<Widget>.identity();
  for (final widget in raw.whereType<Widget>()) {
    if (!seen.add(widget)) {
      throw _changed('duplicate raw references before omission');
    }
  }
}

Element _stack(Element unit) {
  final stack = _only(unit);
  _concrete(stack, Stack);
  if (!_same(
    (stack.widget as Stack).children,
    (unit.widget as coui.Stacks).children,
    identity: true,
  )) {
    throw _changed('Stacks complete ordered children');
  }
  return stack;
}

void _paintedPosition(Element unit) {
  _concrete(unit, coui.Position);
  var e = _only(unit);
  _concrete(e, Positioned);
  e = _child(e, (e.widget as Positioned).child);
  _concrete(e, DecoratedBox);
  if ((e.widget as DecoratedBox).child != null) {
    throw _changed('paint-only generated box');
  }
}

List<Widget> _flexSeats(Element e) => switch (e.widget) {
  final Row w => w.children,
  final Column w => w.children,
  _ => throw _changed('owned sequence'),
};
List<Element> _matches(Element root, Widget widget) =>
    boxElements(root).where((e) => identical(e.widget, widget)).toList();
Element _identity(Element root, Widget? widget) {
  if (widget == null) {
    throw _changed('a required current declared child');
  }
  return requireOneBoxOwner(
    _matches(root, widget),
    'one exact current identity',
  );
}

List<Element> _children(Element e) {
  final out = <Element>[];
  e.visitChildren(out.add);
  return out;
}

Element _only(Element e) =>
    requireOneBoxOwner(_children(e), 'one direct build child');
Element _child(Element e, Widget? widget) {
  if (widget == null) throw _changed('required child');
  return requireOneBoxOwner(
    _children(e).where((c) => identical(c.widget, widget)),
    'declared direct child',
  );
}

Element _parent(Element e) {
  Element? parent;
  e.visitAncestorElements((p) {
    parent = p;
    return false;
  });
  if (parent == null) throw _changed('mounted immediate parent');
  return parent!;
}

void _concrete(Element e, Type type) {
  if (e.widget.runtimeType != type) throw _changed('exact public type $type');
}

bool _same(List<Object?> a, List<Object?> b, {bool identity = false}) =>
    a.length == b.length &&
    List.generate(
      a.length,
      (i) => identity ? identical(a[i], b[i]) : a[i] == b[i],
    ).every((v) => v);
BoxObservationError _changed(String part) => BoxObservationError(
  'NAVIGATION_TRIGGER_SOURCE_CHANGED',
  'Unsupported $part; no owner or default inferred.',
);
