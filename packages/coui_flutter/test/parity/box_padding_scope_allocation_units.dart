// Binds current public scope forwarding and its owned allocation prefix.
import 'package:coui_flutter/coui_flutter.dart'
    show DragScope, SubfocusScope, SubfocusScopeApi;
import 'package:data_widget/data_widget.dart' show Data;
import 'package:docs_core/previews/examples/flutter/drag/drag_board_example.dart';
import 'package:docs_core/previews/examples/flutter/drag/drag_default_example.dart';
import 'package:docs_core/previews/examples/flutter/drag/drag_overlay_example.dart';
import 'package:docs_core/previews/examples/flutter/subfocus/subfocus_default_example.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        Actions,
        Column,
        EdgeInsets,
        Element,
        Flex,
        Focus,
        FocusableActionDetector,
        InheritedWidget,
        KeyedSubtree,
        MouseRegion,
        RenderObjectElement,
        Row,
        Semantics,
        Shortcuts,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

const _kShapes = <Type, ({Type scope, Type layout, int seats})>{
  DragDefaultExample: (scope: DragScope, layout: Column, seats: 2),
  DragBoardExample: (scope: DragScope, layout: Row, seats: 2),
  DragOverlayExample: (scope: DragScope, layout: Column, seats: 2),
  SubfocusScopeDefaultExample: (scope: SubfocusScope, layout: Column, seats: 3),
};

typedef _Current = ({
  Element registry,
  Element scope,
  Element layout,
  RenderFlex renderer,
  Widget publicChild,
  List<Widget?> raw,
  List<Element> seats,
  List<Object?> held,
  List<Map<String, Object?>> prefix,
  BoxProducerScope ownership,
});

/// Current exact public scope forwarding is the proof of structural absence.
/// Supplied product interiors and their descendant renderers are never bound.
class ScopeAllocationBoxSourceBinding {
  ScopeAllocationBoxSourceBinding._(this.capture, this.original, this.source)
    : _current = _locate(capture, original, source);
  final Element capture;
  final Widget original;
  final BoxObservationSourceSpec source;
  final _Current _current;

  Element get registryResultElement => _current.registry;
  Element get fieldUnitElement => _current.scope;
  Element get paddingSource => _current.layout;
  Element get frameSource => _current.layout;
  BoxProducerScope get scope => _current.ownership;
  String get readerId => 'scope-allocation-current-public-forwarding-v1';
  String get authority =>
      'Exact current original Example -> public scope.child through its '
      'complete current public forwarding prefix -> original Row/Column; '
      'no padding operation exists in this owned prefix; complete original '
      'layout child occurrences remain opaque; paint, gaps and foreign '
      'interiors are excluded';

  _Current _read() {
    final now = _locate(capture, original, source);
    if (!_same(_current.held, now.held) ||
        !_same(_current.ownership.foreignBoundaries, _current.seats)) {
      throw _changed('held current owned prefix and every declared occurrence');
    }
    return now;
  }

  void validateExistingCurrentBinding() {
    _read();
  }

  BoxPaddingObservation readDeclaredAbsence() {
    final now = _read();
    now.ownership.requireOwned(now.layout);
    // This branch is reached only after the entire typed prefix is proved.
    // Missing/unsupported/stale source throws; it never falls back to zero.
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: now.layout,
      producer: now.registry,
      contentBoundary: now.layout,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      frameOwner: now.layout,
      generatedSlots: [
        {
          'kind': 'current-public-scope-allocation-v1',
          'sourceContract': source.logicalUnitId,
          'authority': authority,
          'publicScope': original.runtimeType == SubfocusScopeDefaultExample
              ? 'SubfocusScope'
              : 'DragScope',
          'scopeChild': {
            'index': 0,
            'present': true,
            'originalWidgetDiagnostic': identityHashCode(now.publicChild),
            'mountedElementDiagnostic': identityHashCode(now.layout),
            'ownedOriginalLayout': true,
          },
          'ownedPublicForwardingPrefix': now.prefix,
          'frameworkAllocationType': now.layout.widget is Row
              ? 'Row'
              : 'Column',
          'rawLayoutSlots': [
            for (var i = 0; i < now.raw.length; i++)
              {
                'index': i,
                'present': now.raw[i] != null,
                'sourceAliasOf': _earlier(now.raw, i),
                'originalWidgetDiagnostic': identityHashCode(now.raw[i]),
                'mountedElementDiagnostic': identityHashCode(now.seats[i]),
                'foreignWholeBoundary': true,
              },
          ],
          'heldBeforeAfter': {
            'sameOriginalRegistryScopeChildAndLayout': true,
            'sameCompletePublicForwardingPrefix': true,
            'completeOrderedOriginalLayoutOccurrences': true,
            'noOwnedPaddingOrUnexpectedLayout': true,
            'foreignInteriorsNotIdentityAuthority': true,
          },
        },
      ],
    );
  }
}

ScopeAllocationBoxSourceBinding? bindScopeAllocationBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.logicalUnitId !=
      BoxObservationSourceSpec.scopeAllocationHost.logicalUnitId) {
    return null;
  }
  return ScopeAllocationBoxSourceBinding._(captureRoot, registryResult, source);
}

_Current _locate(
  Element capture,
  Widget original,
  BoxObservationSourceSpec source,
) {
  if (source != BoxObservationSourceSpec.scopeAllocationHost ||
      source.validationError != null ||
      !capture.mounted) {
    throw _changed('exact declared tuple and current mounted capture');
  }
  final shape = _kShapes[original.runtimeType];
  if (shape == null) throw _changed('closed original public Example');
  final registry = identical(capture.widget, original)
      ? capture
      : capture.widget.runtimeType == KeyedSubtree &&
            identical((capture.widget as KeyedSubtree).child, original)
      ? _only(capture)
      : throw _changed('original keyed capture');
  if (!registry.mounted || !identical(registry.widget, original)) {
    throw _changed('original actual registry mount');
  }
  final held = <Object?>[capture, capture.widget, registry, original];
  final prefix = <Map<String, Object?>>[];
  void own(Element e, String publicKind) {
    if (!e.mounted) throw _changed('mounted generated public prefix');
    held.addAll([e, e.widget]);
    // Never use a proxy Element.renderObject: that can resolve into a caller.
    if (e is RenderObjectElement) {
      if (!e.renderObject.attached) throw _changed('attached owned renderer');
      held.add(e.renderObject);
    }
    prefix.add({
      'publicKind': publicKind,
      'elementDiagnostic': identityHashCode(e),
    });
  }

  Element exactChild(Element parent, Widget declared) {
    final child = _only(parent);
    if (!identical(child.widget, declared) ||
        !identical(_parent(child), parent)) {
      throw _changed('public declaration -> exact current child edge');
    }
    return child;
  }

  Element inherited(Element parent, Widget child) {
    final marker = _only(parent);
    if (marker.widget is! InheritedWidget ||
        marker is RenderObjectElement ||
        !identical((marker.widget as InheritedWidget).child, child)) {
      throw _changed('current non-rendering public inherited forwarding edge');
    }
    own(marker, 'InheritedWidget');
    return exactChild(marker, child);
  }

  Element focusChild(Element element) {
    _exact(element, Focus);
    own(element, 'Focus');
    final focus = element.widget as Focus;
    // Focus.build forwards through an inherited scope and, when declared,
    // one public Semantics. Debug/unknown wrappers are unsupported.
    final marker = _only(element);
    if (marker.widget is! InheritedWidget || marker is RenderObjectElement) {
      throw _changed('current Focus inherited forwarding edge');
    }
    own(marker, 'InheritedWidget');
    final returned = _only(marker);
    if (!identical((marker.widget as InheritedWidget).child, returned.widget)) {
      throw _changed('Focus inherited child identity');
    }
    if (!focus.includeSemantics) {
      if (!identical(returned.widget, focus.child)) {
        throw _changed('public Focus.child');
      }
      return returned;
    }
    _exact(returned, Semantics);
    own(returned, 'Semantics');
    if (!identical((returned.widget as Semantics).child, focus.child)) {
      throw _changed('Focus Semantics forwarding child');
    }
    return exactChild(returned, focus.child);
  }

  final scopeElement = _only(registry);
  _exact(scopeElement, shape.scope);
  if (!identical(_parent(scopeElement), registry)) {
    throw _changed('direct original public scope');
  }
  own(scopeElement, shape.scope == DragScope ? 'DragScope' : 'SubfocusScope');
  final Widget publicChild;
  final Element layout;
  if (shape.scope == DragScope) {
    publicChild = (scopeElement.widget as DragScope).child;
    layout = inherited(scopeElement, publicChild);
  } else {
    publicChild = (scopeElement.widget as SubfocusScope).child;
    final outer = _only(scopeElement);
    _exact(outer, Semantics);
    own(outer, 'Semantics');
    final detector = _only(outer);
    _exact(detector, FocusableActionDetector);
    if (!identical((outer.widget as Semantics).child, detector.widget)) {
      throw _changed('Subfocus Semantics -> public detector');
    }
    own(detector, 'FocusableActionDetector');
    final d = detector.widget as FocusableActionDetector;
    if (!d.enabled ||
        d.shortcuts == null ||
        d.shortcuts!.isEmpty ||
        d.actions == null ||
        d.actions!.isEmpty ||
        d.child.runtimeType != (Data<SubfocusScopeApi>) ||
        !identical((d.child as Data<SubfocusScopeApi>).child, publicChild)) {
      throw _changed('pinned public Subfocus detector and Data.child');
    }
    final shortcuts = _only(detector);
    _exact(shortcuts, Shortcuts);
    own(shortcuts, 'Shortcuts');
    final s = shortcuts.widget as Shortcuts;
    if (!identical(s.shortcuts, d.shortcuts)) {
      throw _changed('public shortcut map ref');
    }
    final actions = focusChild(_only(shortcuts));
    _exact(actions, Actions);
    own(actions, 'Actions');
    if (!identical(actions.widget, s.child) ||
        !identical((actions.widget as Actions).actions, d.actions)) {
      throw _changed('Shortcuts -> Focus -> actual Actions');
    }
    final mouse = inherited(actions, (actions.widget as Actions).child);
    _exact(mouse, MouseRegion);
    own(mouse, 'MouseRegion');
    final focus = exactChild(mouse, (mouse.widget as MouseRegion).child!);
    final data = focusChild(focus);
    _exact(data, Data<SubfocusScopeApi>);
    own(data, 'Data<SubfocusScopeApi>');
    if (!identical(data.widget, d.child)) {
      throw _changed('original actual public Data');
    }
    layout = inherited(data, publicChild);
  }
  _exact(layout, shape.layout);
  own(layout, shape.layout == Row ? 'Row' : 'Column');
  if (!identical(layout.widget, publicChild) ||
      layout is! RenderObjectElement ||
      layout.renderObject.runtimeType != RenderFlex ||
      !layout.renderObject.attached) {
    throw _changed('actual public scope.child allocation renderer');
  }
  final raw = List<Widget?>.of((layout.widget as Flex).children);
  final seats = _children(layout);
  if (raw.length != shape.seats ||
      raw.any((w) => w == null) ||
      seats.length != raw.length ||
      (Set<Element>.identity()..addAll(seats)).length != seats.length) {
    throw _changed(
      'complete original raw layout vector and occurrence cardinality',
    );
  }
  for (var i = 0; i < raw.length; i++) {
    if (!seats[i].mounted ||
        !identical(seats[i].widget, raw[i]) ||
        !identical(_parent(seats[i]), layout) ||
        identical(raw[i], publicChild)) {
      throw _changed('complete ordered direct opaque occurrence edges');
    }
    // Hold only the public foreign boundary, never its descendant renderer.
    held.addAll([raw[i], seats[i]]);
  }
  held.add(publicChild);
  final ownership =
      BoxProducerScope(
          producer: registry,
          suppliedSlots: raw.whereType<Widget>(),
        )
        ..requireOwned(scopeElement)
        ..requireOwned(layout);
  if (!_same(ownership.foreignBoundaries, seats)) {
    throw _changed('whole original opaque boundary frontier');
  }
  return (
    registry: registry,
    scope: scopeElement,
    layout: layout,
    renderer: layout.renderObject as RenderFlex,
    publicChild: publicChild,
    raw: List.unmodifiable(raw),
    seats: List.unmodifiable(seats),
    held: List.unmodifiable(held),
    prefix: List.unmodifiable(prefix),
    ownership: ownership,
  );
}

void _exact(Element e, Type type) {
  if (!e.mounted || e.widget.runtimeType != type) {
    throw _changed('exact public generated type');
  }
}

List<Element> _children(Element e) {
  final out = <Element>[];
  e.visitChildren(out.add);
  return out;
}

Element _only(Element e) =>
    requireOneBoxOwner(_children(e), 'scope current forwarding edge');
Element? _parent(Element e) {
  Element? p;
  e.visitAncestorElements((a) {
    p = a;
    return false;
  });
  return p;
}

bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);
int? _earlier(List<Widget?> raw, int i) {
  for (var j = 0; j < i; j++) {
    if (identical(raw[j], raw[i])) return j;
  }
  return null;
}

BoxObservationError _changed(String part) => BoxObservationError(
  'SCOPE_ALLOCATION_SOURCE_CHANGED',
  'Unsupported or stale $part; no missing/foreign source becomes zero.',
);
