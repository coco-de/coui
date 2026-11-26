import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/calendar/calendar_default_example.dart';
import 'package:docs_core/previews/examples/flutter/calendar/calendar_markers_example.dart';
import 'package:docs_core/previews/examples/flutter/calendar/calendar_multi_example.dart';
import 'package:docs_core/previews/examples/flutter/calendar/calendar_none_example.dart';
import 'package:docs_core/previews/examples/flutter/calendar/calendar_range_example.dart';
import 'package:docs_core/previews/examples/flutter/definition_list/definition_list_columns_example.dart';
import 'package:docs_core/previews/examples/flutter/definition_list/definition_list_default_example.dart';
import 'package:docs_core/previews/examples/flutter/definition_list/definition_list_inline_example.dart';
import 'package:flutter/rendering.dart'
    show RenderBox, RenderFlex, RenderIntrinsicWidth, RenderTable, RenderWrap;
import 'package:flutter/widgets.dart'
    show
        Builder,
        Column,
        CrossAxisAlignment,
        DefaultTextStyle,
        EdgeInsets,
        Element,
        ExcludeSemantics,
        Flexible,
        IntrinsicWidth,
        KeyedSubtree,
        MainAxisSize,
        Padding,
        Row,
        Semantics,
        Table,
        Widget,
        Wrap;

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

/// A source-specific no-own-allocation witness, never a missing-Padding search.
class CollectionLayoutHostBoxSourceBinding {
  CollectionLayoutHostBoxSourceBinding._(
    this._capture,
    this._resultWidget,
    this._source,
    this._route,
  ) : _producerWidget = _route.producer.widget;

  final Element _capture;
  final Widget _resultWidget;
  final Widget _producerWidget;
  final BoxObservationSourceSpec _source;
  final _Route _route;

  String get authority => _route.authority;
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.frame;
  Element get paddingSource => _route.frame;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId => 'collection-host-declared-absence-v1';

  /// Original public inputs are fixed; their generated current Widgets are not.
  /// No callback or builder is invoked to reconstruct this live source route.
  BoxPaddingObservation readDeclaredAbsence() {
    for (final pair in [
      (_route.result, _resultWidget),
      (_route.producer, _producerWidget),
    ]) {
      if (!pair.$1.mounted || !identical(pair.$1.widget, pair.$2)) {
        throw _changed('the original mounted input Widget identities');
      }
    }
    final current = _locate(_capture, _resultWidget, _source);
    if (!identical(current.result, _route.result) ||
        !identical(current.producer, _route.producer) ||
        !identical(current.frame, _route.frame) ||
        current.scope.foreignBoundaries.length !=
            scope.foreignBoundaries.length ||
        current.scope.foreignBoundaries.any(
          (boundary) => !scope.foreignBoundaries.any(
            (original) => identical(original, boundary),
          ),
        )) {
      throw _changed('the current source host and public child boundaries');
    }
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: current.frame,
      producer: current.result,
      contentBoundary: current.frame,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {'sourceContract': readerId, 'authority': current.authority},
      ],
      frameOwner: current.frame,
    );
  }
}

CollectionLayoutHostBoxSourceBinding? bindCollectionLayoutHostBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (!const [
    'calendar-generated-layout-host',
    'definition-list-generated-layout-host',
  ].contains(source.logicalUnitId)) {
    return null;
  }
  return CollectionLayoutHostBoxSourceBinding._(
    captureRoot,
    registryResult,
    source,
    _locate(captureRoot, registryResult, source),
  );
}

const _kCalendarExamples = <Type, coui.CoreCalendarSelectionMode>{
  CalendarDefaultExample: coui.CoreCalendarSelectionMode.single,
  CalendarRangeExample: coui.CoreCalendarSelectionMode.range,
  CalendarMultiExample: coui.CoreCalendarSelectionMode.multi,
  CalendarNoneExample: coui.CoreCalendarSelectionMode.none,
  CalendarMarkersExample: coui.CoreCalendarSelectionMode.range,
};
const _kDefinitionExamples = <Type, coui.CoreDefinitionLayout>{
  DefinitionListDefaultExample: coui.CoreDefinitionLayout.stacked,
  DefinitionListColumnsExample: coui.CoreDefinitionLayout.columns,
  DefinitionListInlineExample: coui.CoreDefinitionLayout.inline,
};

_Route _locate(
  Element capture,
  Widget resultWidget,
  BoxObservationSourceSpec source,
) {
  final calendar = source.logicalUnitId == 'calendar-generated-layout-host';
  final expected = calendar
      ? BoxObservationSourceSpec.calendarLayoutHost
      : BoxObservationSourceSpec.definitionListLayoutHost;
  if (source != expected) throw _changed('the closed source tuple/version');
  final root = capture.widget;
  if (!identical(root, resultWidget) &&
      !(root.runtimeType == KeyedSubtree &&
          identical((root as KeyedSubtree).child, resultWidget))) {
    throw _changed('the capture result identity');
  }
  final result = _identity(capture, resultWidget);
  final type = calendar ? coui.Calendar : coui.DefinitionList;
  final direct = resultWidget.runtimeType == type;
  if (!direct &&
      !(calendar ? _kCalendarExamples : _kDefinitionExamples).containsKey(
        resultWidget.runtimeType,
      )) {
    throw _changed('an exact audited Example or public producer');
  }
  final producer = direct ? result : _only(result);
  _concrete(producer, type);
  if (!direct &&
      calendar &&
      (producer.widget as coui.Calendar).selectionMode !=
          _kCalendarExamples[resultWidget.runtimeType]) {
    throw _changed('the source Example selection mode');
  }
  if (!direct &&
      !calendar &&
      (producer.widget as coui.DefinitionList).layout !=
          _kDefinitionExamples[resultWidget.runtimeType]) {
    throw _changed('the source Example layout');
  }
  final declaration = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final raw = [
    ...declaration.scope.suppliedSlots,
    ...declaration.unrenderedSuppliedSlots,
  ];
  final identities = Set<Widget>.identity();
  for (final slot in raw) {
    if (!identities.add(slot)) throw _changed('unique raw public Widget slots');
    _identity(producer, slot);
  }
  if (calendar && raw.isNotEmpty) {
    throw _changed('Calendar data callbacks without Widget slots');
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  )..requireOwned(producer);
  final frame = calendar
      ? _calendar(producer, scope)
      : _definition(producer, scope);
  scope.requireOwned(frame);
  final render = frame.renderObject;
  if (render is! RenderBox || !render.attached || !render.hasSize) {
    throw _changed('the attached laid-out concrete layout renderer');
  }
  final hostOperation = calendar
      ? 'Semantics.child -> IntrinsicWidth.child -> Column'
      : 'layout enum -> Column/Table/Wrap';
  return (
    result: result,
    producer: producer,
    frame: frame,
    scope: scope,
    authority:
        'Exact Example/public producer and original Widget identities; '
        '${declaration.authority}; current source-created '
        '$hostOperation '
        'has no own padding allocation. Child rows/cells/markers and all supplied '
        'rich descriptions are outside this field quantity.',
  );
}

Element _calendar(Element producer, BoxProducerScope scope) {
  final semantics = _only(producer);
  _concrete(semantics, Semantics);
  final host = _child(semantics, (semantics.widget as Semantics).child);
  _concrete(host, IntrinsicWidth);
  final intrinsic = host.widget as IntrinsicWidth;
  if (intrinsic.stepWidth != null ||
      intrinsic.stepHeight != null ||
      host.renderObject.runtimeType != RenderIntrinsicWidth) {
    throw _changed('the actual source intrinsic-width allocation');
  }
  final content = _child(host, intrinsic.child);
  _concrete(content, Column);
  final column = content.widget as Column;
  if (column.mainAxisSize != MainAxisSize.min ||
      column.crossAxisAlignment != CrossAxisAlignment.stretch ||
      column.children.length != 3) {
    throw _changed('the Calendar content boundary');
  }
  for (final child in column.children) {
    scope.requireOwned(_child(content, child));
  }
  // Stop here: navigation/date-cell/marker padding is a different source unit.
  return host;
}

Element _definition(Element producer, BoxProducerScope scope) {
  final widget = producer.widget as coui.DefinitionList;
  final host = _only(producer);
  final expected = switch (widget.layout) {
    coui.CoreDefinitionLayout.stacked => (Column, RenderFlex),
    coui.CoreDefinitionLayout.columns => (Table, RenderTable),
    coui.CoreDefinitionLayout.inline => (Wrap, RenderWrap),
  };
  _concrete(host, expected.$1);
  if (host.renderObject.runtimeType != expected.$2) {
    throw _changed('the actual layout-specific renderer');
  }
  final children = switch (host.widget) {
    final Column column => column.children,
    final Wrap wrap => wrap.children,
    final Table table => [
      for (final row in table.children) ...row.children,
    ],
    _ => throw _changed('the concrete generated list host'),
  };
  final perEntry = widget.layout == coui.CoreDefinitionLayout.columns ? 2 : 1;
  if (children.length != widget.items.length * perEntry) {
    throw _changed('the source entry cardinality');
  }
  if (host.widget case final Table table) {
    if (table.border != null ||
        table.children.any((row) => row.children.length != 2)) {
      throw _changed('the border-free source Table and two cells per entry');
    }
  }
  for (var i = 0; i < widget.items.length; i++) {
    final entry = widget.items[i];
    // The shared typed declaration has already rejected unknown records/dups.
    if (widget.layout == coui.CoreDefinitionLayout.columns) {
      for (var cell = 0; cell < 2; cell++) {
        final padding = _child(host, children[i * 2 + cell]);
        _concrete(padding, Padding);
        scope.requireOwned(padding);
        final content = _child(padding, (padding.widget as Padding).child);
        if (cell == 0) {
          _term(content, scope);
        } else {
          _description(content, entry, scope);
        }
      }
    } else {
      final pair = _child(host, children[i]);
      _concrete(
        pair,
        widget.layout == coui.CoreDefinitionLayout.stacked ? Column : Row,
      );
      final cells = pair.widget is Column
          ? (pair.widget as Column).children
          : (pair.widget as Row).children;
      if (cells.length != 2) throw _changed('the two source term/value cells');
      _term(_child(pair, cells[0]), scope);
      var description = _child(pair, cells[1]);
      if (widget.layout == coui.CoreDefinitionLayout.inline) {
        _concrete(description, Flexible);
        description = _child(
          description,
          (description.widget as Flexible).child,
        );
      }
      _description(description, entry, scope);
    }
  }
  return host;
}

void _term(Element term, BoxProducerScope scope) {
  _concrete(term, ExcludeSemantics);
  scope.requireOwned(term);
  final text = _child(term, (term.widget as ExcludeSemantics).child);
  _concrete(text, coui.Text);
}

void _description(
  Element element,
  coui.CoreDefinitionEntry<Widget> entry,
  BoxProducerScope scope,
) {
  _concrete(element, Semantics);
  scope.requireOwned(element);
  var child = _child(element, (element.widget as Semantics).child);
  if (entry.description case final rich?) {
    _concrete(child, Builder);
    scope.requireOwned(child);
    child = _only(child); // Already mounted DefaultTextStyle.merge operation.
    _concrete(child, DefaultTextStyle);
    scope.requireOwned(child);
    if (!identical((child.widget as DefaultTextStyle).child, rich)) {
      throw _changed('the actual supplied description identity');
    }
    _child(child, rich); // Stop at the entire foreign subtree.
  } else {
    _concrete(child, coui.Text);
    scope.requireOwned(child);
  }
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the exact collection source child');
}

Element _identity(Element root, Widget widget) => requireOneBoxOwner(
  boxElements(root).where((element) => identical(element.widget, widget)),
  'the actual collection Widget identity',
);

Element _child(Element parent, Widget? child) {
  if (child == null) throw _changed('a required source child');
  final element = _identity(parent, child);
  final direct = <Element>[];
  parent.visitChildren(direct.add);
  if (!direct.any((candidate) => identical(candidate, element))) {
    throw _changed('the direct source child relationship');
  }
  return element;
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) throw _changed('concrete $type');
}

BoxObservationError _changed(String reason) => BoxObservationError(
  'COLLECTION_LAYOUT_HOST_SOURCE_CHANGED',
  'Unsupported $reason; no owner or absence is inferred.',
);
