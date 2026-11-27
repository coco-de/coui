import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/bottom_action_bar/bottom_action_bar_default_example.dart';
import 'package:docs_core/previews/examples/flutter/bottom_action_bar/bottom_action_bar_horizontal_example.dart';
import 'package:docs_core/previews/examples/flutter/bottom_action_bar/bottom_action_bar_summary_compact_example.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show
        Align,
        BoxDecoration,
        Clip,
        Column,
        Container,
        DecoratedBox,
        DefaultTextStyle,
        Directionality,
        Element,
        Expanded,
        KeyedSubtree,
        MediaQuery,
        Padding,
        RenderObjectElement,
        Row,
        SafeArea,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';

const _kSlotNames = [
  'primaryAction',
  'secondaryAction',
  'description',
  'summaryLabel',
  'summaryValue',
];
const Map<Type, coui.CoreBottomActionBarLayout> _kLayouts = {
  BottomActionBarDefaultExample: coui.CoreBottomActionBarLayout.vertical,
  BottomActionBarHorizontalExample: coui.CoreBottomActionBarLayout.horizontal,
  BottomActionBarSummaryCompactExample:
      coui.CoreBottomActionBarLayout.summaryCompact,
};

/// Entry authority is the original exact public Example, never a reconstructed
/// product. The product-only binding below supports independent public
/// controls;
/// it is not a manifest registration or an alternate production entrypoint.
CurrentBottomActionBarSource bindBottomActionBarEntrySource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source != BoxObservationSourceSpec.bottomActionBarContentInset ||
      !_kLayouts.containsKey(registryResult.runtimeType)) {
    throw _changed('BOTTOM_ACTION_BAR_CLOSED_ENTRY_REQUIRED');
  }
  _capture(captureRoot, registryResult);
  final result = identical(captureRoot.widget, registryResult)
      ? captureRoot
      : _only(captureRoot);
  if (!identical(result.widget, registryResult)) {
    throw _changed('BOTTOM_ACTION_BAR_REGISTRY_RESULT_CHANGED');
  }
  final producer = _only(result);
  _exact(producer, coui.BottomActionBar);
  if ((producer.widget as coui.BottomActionBar).layout !=
      _kLayouts[registryResult.runtimeType]) {
    throw _changed('BOTTOM_ACTION_BAR_CLOSED_LAYOUT_CHANGED');
  }
  return CurrentBottomActionBarSource._(
    producer,
    captureRoot,
    registryResult,
    result,
  );
}

/// Reads an already mounted exact public product in focused source controls.
/// No factory, build method, State, callback or style resolver is invoked.
CurrentBottomActionBarSource bindCurrentBottomActionBarProduct(
  Element producer,
) => CurrentBottomActionBarSource._(producer, null, null, null);

class CurrentBottomActionBarSource {
  CurrentBottomActionBarSource._(
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
  late final _Snapshot _held;

  Map<String, Object?> get sourceIdentity {
    validateCurrentBinding();
    return _held.identity;
  }

  void validateCurrentBinding() {
    final now = _snapshot();
    if (!_same(now.held, _held.held)) {
      throw _changed('BOTTOM_ACTION_BAR_HELD_SOURCE_CHANGED');
    }
  }

  BoxPaddingCompositionObservation readActualPadding() {
    validateCurrentBinding();
    final a = _held.safe.renderObject! as RenderPadding;
    final b = _held.explicit.renderObject! as RenderPadding;
    // These are two actual public current parameters, read once each. The
    // parameter objects and directions were retained by the source snapshot.
    final safe = a.padding.resolve(a.textDirection);
    final explicit = b.padding.resolve(b.textDirection);
    validateCurrentBinding();
    return BoxPaddingCompositionObservation(
      contributions: [safe, explicit],
      sourceIdentity: _held.identity,
      declaringProducer: producer,
      frame: _held.frame,
    );
  }

  _Snapshot _snapshot() {
    _exact(producer, coui.BottomActionBar);
    if (captureRoot != null) {
      _capture(captureRoot!, registryResult!);
      if (!identical(registryElement!.widget, registryResult) ||
          !identical(_only(registryElement!), producer) ||
          (producer.widget as coui.BottomActionBar).layout !=
              _kLayouts[registryResult.runtimeType]) {
        throw _changed('BOTTOM_ACTION_BAR_ENTRY_CHANGED');
      }
    }
    final product = producer.widget as coui.BottomActionBar;
    if (!const [
      coui.CoreBottomActionBarLayout.vertical,
      coui.CoreBottomActionBarLayout.horizontal,
      coui.CoreBottomActionBarLayout.summaryCompact,
    ].contains(product.layout)) {
      throw _changed('BOTTOM_ACTION_BAR_LAYOUT_NOT_REGISTERED');
    }
    // Retain all five raw seats before conditional omission. Only active seats
    // enter the foreign scope; inactive supplied Widgets are not fabricated as
    // mounted and do not make the generic scope fail for a missing Element.
    final raw = <Widget?>[
      product.primaryAction,
      product.secondaryAction,
      product.description,
      product.summaryLabel,
      product.summaryValue,
    ];
    final active = <bool>[
      true,
      product.layout != .summaryCompact,
      true,
      product.layout == .summaryCompact,
      product.layout == .summaryCompact,
    ];
    final scope = BoxProducerScope(
      producer: producer,
      suppliedSlots: [
        for (var i = 0; i < raw.length; i++)
          if (active[i] && raw[i] != null) raw[i]!,
      ],
    );
    final held = <Object?>[
      captureRoot,
      registryResult,
      registryElement,
      producer,
      product,
      product.layout,
      ...raw,
    ];
    void own(Element element) {
      scope.requireOwned(element);
      if (!element.mounted) throw _changed('BOTTOM_ACTION_BAR_UNMOUNTED');
      held.addAll([element, element.widget]);
      if (element is RenderObjectElement) held.add(element.renderObject);
    }

    final semantics = _only(producer);
    _exact(semantics, coui.CoUISemantics);
    own(semantics);
    final publicChild = (semantics.widget as coui.CoUISemantics).child;
    var frame = _ownedReference(semantics, publicChild, scope);
    if (publicChild.runtimeType == coui.SurfaceBlur) {
      own(frame);
      frame = _ownedReference(
        frame,
        (publicChild as coui.SurfaceBlur).child,
        scope,
      );
    }
    _exact(frame, Container);
    own(frame);
    final box = frame.widget as Container;
    if (box.padding != null ||
        box.margin != null ||
        box.constraints != null ||
        box.transform != null ||
        box.foregroundDecoration != null ||
        box.color != null ||
        box.alignment != null ||
        box.clipBehavior != Clip.none ||
        box.decoration.runtimeType != BoxDecoration ||
        box.child.runtimeType != SafeArea) {
      throw _changed('BOTTOM_ACTION_BAR_FRAME_ROUTE_CHANGED');
    }
    held.add(box.decoration);
    // The Container decoration's framework Padding is a separate border
    // allocation. It is bound structurally and is never a measured term.
    final decorated = _only(frame);
    _exact(decorated, DecoratedBox);
    if (!identical(
      (decorated.widget as DecoratedBox).decoration,
      box.decoration,
    )) {
      throw _changed('BOTTOM_ACTION_BAR_FRAME_DECORATION_CHANGED');
    }
    own(decorated);
    final borderPadding = _only(decorated);
    _exact(borderPadding, Padding);
    own(borderPadding);
    final safeArea = _only(borderPadding);
    if (!identical(safeArea.widget, box.child)) {
      throw _changed('BOTTOM_ACTION_BAR_SAFE_AREA_CHANGED');
    }
    own(safeArea);
    final safeWidget = safeArea.widget as SafeArea;
    if (safeWidget.top ||
        safeWidget.left ||
        safeWidget.right ||
        !safeWidget.bottom ||
        safeWidget.maintainBottomViewPadding ||
        safeWidget.child.runtimeType != Padding) {
      throw _changed('BOTTOM_ACTION_BAR_SAFE_AREA_ROUTE_CHANGED');
    }
    final safe = _only(safeArea);
    _exact(safe, Padding);
    own(safe);
    final media = _only(safe);
    _exact(media, MediaQuery);
    own(media);
    if (!identical((safe.widget as Padding).child, media.widget) ||
        !identical((media.widget as MediaQuery).child, safeWidget.child)) {
      throw _changed('BOTTOM_ACTION_BAR_MEDIA_ROUTE_CHANGED');
    }
    final explicit = _only(media);
    if (!identical(explicit.widget, safeWidget.child)) {
      throw _changed('BOTTOM_ACTION_BAR_EXPLICIT_PADDING_CHANGED');
    }
    own(explicit);
    final content = _only(explicit);
    final columnWidget = (explicit.widget as Padding).child;
    if (!identical(content.widget, columnWidget)) {
      throw _changed('BOTTOM_ACTION_BAR_COLUMN_CHANGED');
    }
    _exact(content, Column);
    own(content);
    final safeRender = _paddingSource(safe, held);
    final explicitRender = _paddingSource(explicit, held);
    final borderRender = _paddingSource(borderPadding, held);
    if (identical(safe, explicit) ||
        identical(safeRender, explicitRender) ||
        identical(safeRender, borderRender) ||
        identical(explicitRender, borderRender) ||
        !identical(safeRender.child, explicitRender) ||
        !identical(explicitRender.parent, safeRender) ||
        !identical(borderRender.child, safeRender) ||
        !identical(safeRender.parent, borderRender) ||
        !identical(explicitRender.child, content.renderObject) ||
        !identical(content.renderObject!.parent, explicitRender)) {
      throw _changed('BOTTOM_ACTION_BAR_EXACT_RENDER_SEQUENCE_CHANGED');
    }

    final seats = <int, Element>{};
    final paths = <int, List<int>>{};
    void foreign(Element element, int seat, List<int> path) {
      if (!active[seat] ||
          raw[seat] == null ||
          !identical(element.widget, raw[seat]) ||
          seats.containsKey(seat) ||
          !scope.foreignBoundaries.any(
            (boundary) => identical(boundary, element),
          ) ||
          !element.mounted) {
        throw _changed('BOTTOM_ACTION_BAR_FOREIGN_SEAT_CHANGED');
      }
      seats[seat] = element;
      paths[seat] = path;
      held.addAll([element, element.widget]);
      // Stop here, even for raw Text, a Fragment-like Widget or another bar.
    }

    final column = content.widget as Column;
    final top = _children(content, column.children, held, scope);
    var cursor = 0;
    if (product.description != null) {
      final note = top[cursor];
      _exact(note, DefaultTextStyle);
      final child = (note.widget as DefaultTextStyle).child;
      if (!identical(child, product.description)) {
        throw _changed('BOTTOM_ACTION_BAR_DESCRIPTION_CHANGED');
      }
      foreign(_only(note), 2, [cursor, 0]);
      cursor++;
    }
    if (product.layout == .vertical) {
      if (top.length !=
          cursor + 1 + (product.secondaryAction == null ? 0 : 1)) {
        throw _changed('BOTTOM_ACTION_BAR_VERTICAL_FRONTIER_CHANGED');
      }
      foreign(top[cursor], 0, [cursor]);
      if (product.secondaryAction != null) {
        foreign(top[cursor + 1], 1, [cursor + 1]);
      }
    } else {
      if (top.length != cursor + 1) {
        throw _changed('BOTTOM_ACTION_BAR_ROW_FRONTIER_CHANGED');
      }
      final rowElement = top[cursor];
      _exact(rowElement, Row);
      final row = rowElement.widget as Row;
      final cells = _children(rowElement, row.children, held, scope);
      if (product.layout == .horizontal) {
        if (cells.length != 1 + (product.secondaryAction == null ? 0 : 1)) {
          throw _changed('BOTTOM_ACTION_BAR_HORIZONTAL_FRONTIER_CHANGED');
        }
        for (var i = 0; i < cells.length; i++) {
          _exact(cells[i], Expanded);
          final seat = product.secondaryAction != null && i == 0 ? 1 : 0;
          if (!identical((cells[i].widget as Expanded).child, raw[seat])) {
            throw _changed('BOTTOM_ACTION_BAR_HORIZONTAL_CELL_CHANGED');
          }
          foreign(_only(cells[i]), seat, [cursor, i, 0]);
        }
      } else {
        if (cells.length != 2) {
          throw _changed('BOTTOM_ACTION_BAR_SUMMARY_FRONTIER_CHANGED');
        }
        _exact(cells[0], Expanded);
        final alignment = _only(cells[0]);
        _exact(alignment, Align);
        own(alignment);
        if (!identical((cells[0].widget as Expanded).child, alignment.widget)) {
          throw _changed('BOTTOM_ACTION_BAR_SUMMARY_CELL_CHANGED');
        }
        final summary = (alignment.widget as Align).child;
        if (product.summaryLabel == null && product.summaryValue == null) {
          if (summary != null) {
            throw _changed('BOTTOM_ACTION_BAR_EMPTY_SUMMARY_CHANGED');
          }
        } else {
          final summaryElement = _only(alignment);
          if (!identical(summaryElement.widget, summary)) {
            throw _changed('BOTTOM_ACTION_BAR_SUMMARY_CHANGED');
          }
          _exact(summaryElement, Column);
          own(summaryElement);
          final labels = _children(
            summaryElement,
            (summary! as Column).children,
            held,
            scope,
          );
          final present = [
            if (product.summaryLabel != null) 3,
            if (product.summaryValue != null) 4,
          ];
          if (labels.length != present.length) {
            throw _changed('BOTTOM_ACTION_BAR_SUMMARY_SEATS_CHANGED');
          }
          for (var i = 0; i < present.length; i++) {
            _exact(labels[i], DefaultTextStyle);
            final seat = present[i];
            if (!identical(
              (labels[i].widget as DefaultTextStyle).child,
              raw[seat],
            )) {
              throw _changed('BOTTOM_ACTION_BAR_SUMMARY_LABEL_CHANGED');
            }
            foreign(_only(labels[i]), seat, [cursor, 0, 0, i, 0]);
          }
        }
        foreign(cells[1], 0, [cursor, 1]);
      }
    }
    if (seats.length !=
            [
              for (var i = 0; i < 5; i++)
                if (active[i] && raw[i] != null) i,
            ].length ||
        scope.foreignBoundaries.length != seats.length) {
      throw _changed('BOTTOM_ACTION_BAR_WHOLE_SEAT_FRONTIER_CHANGED');
    }
    return _Snapshot(frame, safe, explicit, held, {
      'kind': 'current-bottom-action-bar-owned-padding-composition-v1',
      'quantityId': BoxObservationSourceSpec.quantity,
      'nativeQuantityKind': 'frameworkOwnedPaddingComposition',
      'producer': {
        'publicType': 'BottomActionBar',
        'exactType': true,
        'sameMountedSource': true,
      },
      'ownedFrame': {
        'publicType': 'Container',
        'actualElementDiagnostic': identityHashCode(frame),
        'exactContainerChildIsSafeArea': true,
        'borderAllocationExcluded': true,
      },
      'contributors': [
        for (final (i, e) in [safe, explicit].indexed)
          {
            'ordinal': i,
            'slot': i == 0
                ? 'SafeArea.generatedPadding'
                : 'BottomActionBar.explicitContentPadding',
            'exactPublicWidgetType': 'Padding',
            'actualElementDiagnostic': identityHashCode(e),
            'actualRenderDiagnostic': identityHashCode(e.renderObject),
          },
      ],
      'heldBeforeAfter': {
        for (final key in [
          'sameProducer',
          'sameFrame',
          'sameOrderedContributorElements',
          'sameOrderedRenderPaddings',
          'distinctContributorElementsInProcess',
          'distinctRenderPaddingsInProcess',
          'allMountedAttachedOwned',
          'exactSafeAreaToExplicitPaddingRoute',
          'completeDeclaredSeatsAndFrontiers',
          'sameOrderedPublicRenderPaddingParameterObjects',
          'sameOrderedPublicWidgetPaddingParameterObjects',
          'sameOrderedRenderTextDirections',
          'sameCurrentPublicDirectionalityBindings',
        ])
          key: true,
      },
      'layout': product.layout.name,
      'declaredSeats': [
        for (var i = 0; i < 5; i++)
          {
            'index': i,
            'slot': _kSlotNames[i],
            'present': raw[i] != null,
            'layoutActive': active[i],
            'mountedFrontierPresent': seats.containsKey(i),
            'sourceAliasOf': raw[i] == null
                ? null
                : [
                    for (var j = 0; j < i; j++)
                      if (identical(raw[j], raw[i])) j,
                  ].firstOrNull,
            'frontierOrder': paths[i] ?? <int>[],
          },
      ],
    });
  }
}

class _Snapshot {
  _Snapshot(this.frame, this.safe, this.explicit, this.held, this.identity);
  final Element frame;
  final Element safe;
  final Element explicit;
  final List<Object?> held;
  final Map<String, Object?> identity;
}

RenderPadding _paddingSource(Element element, List<Object?> held) {
  final widget = element.widget as Padding;
  final render = element.renderObject;
  final direction = Directionality.maybeOf(element);
  if (render is! RenderPadding ||
      render.runtimeType != RenderPadding ||
      !render.attached ||
      render.textDirection != direction) {
    throw _changed('BOTTOM_ACTION_BAR_CURRENT_PARAMETER_CHANGED');
  }
  // Hold each real reference independently. RenderPadding's equality-guarded
  // setter may retain an older equal object after a normal Widget rebuild.
  held.addAll([
    render,
    widget.padding,
    render.padding,
    render.textDirection,
    direction,
  ]);
  return render;
}

List<Element> _children(
  Element parent,
  List<Widget> widgets,
  List<Object?> held,
  BoxProducerScope scope,
) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  if (children.length != widgets.length ||
      [
        for (var i = 0; i < widgets.length; i++)
          identical(children[i].widget, widgets[i]),
      ].any((same) => !same)) {
    throw _changed('BOTTOM_ACTION_BAR_COMPLETE_GENERATED_FRONTIER_CHANGED');
  }
  for (final e in children) {
    if (!scope.foreignBoundaries.any((boundary) => identical(boundary, e))) {
      scope.requireOwned(e);
      held.addAll([e, e.widget]);
      if (e is RenderObjectElement) held.add(e.renderObject);
    }
  }
  return children;
}

Element _ownedReference(Element parent, Widget target, BoxProducerScope scope) {
  final matches = <Element>[];
  void visit(Element e) {
    if (scope.foreignBoundaries.any((boundary) => identical(boundary, e))) {
      return;
    }
    if (identical(e.widget, target)) {
      matches.add(e);
      return;
    }
    e.visitChildren(visit);
  }

  visit(parent);
  final result = requireOneBoxOwner(
    matches,
    'exact public owned child Widget reference',
  );
  scope.requireOwned(result);
  return result;
}

void _capture(Element root, Widget result) {
  if (!identical(root.widget, result) &&
      !(root.widget.runtimeType == KeyedSubtree &&
          identical((root.widget as KeyedSubtree).child, result))) {
    throw _changed('BOTTOM_ACTION_BAR_CAPTURE_CHANGED');
  }
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'one actual declared generated child');
}

void _exact(Element element, Type type) =>
    requireConcreteBoxSourceType(element.widget, type);
bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    [
      for (var i = 0; i < a.length; i++) identical(a[i], b[i]),
    ].every((same) => same);
BoxObservationError _changed(String code) => BoxObservationError(
  code,
  'The complete current BottomActionBar source is not established.',
);
