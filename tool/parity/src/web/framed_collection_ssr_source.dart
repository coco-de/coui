import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/join/join_default_example.dart';
import 'package:docs_core/previews/examples/web/join/join_input_example.dart';
import 'package:docs_core/previews/examples/web/join/join_vertical_example.dart';
import 'package:docs_core/previews/examples/web/mockup/mockup_app_example.dart';
import 'package:docs_core/previews/examples/web/mockup/mockup_browser_example.dart';
import 'package:docs_core/previews/examples/web/mockup/mockup_device_example.dart';
import 'package:docs_core/previews/examples/web/mockup/mockup_device_flat_example.dart';
import 'package:docs_core/previews/examples/web/mockup/mockup_device_landscape_example.dart';
import 'package:docs_core/previews/examples/web/mockup/mockup_device_tablet_example.dart';
import 'package:docs_core/previews/examples/web/table/table_default_example.dart';
import 'package:docs_core/previews/examples/web/table/table_resizable_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

typedef _Inputs = ({
  List<Component?> slots,
  List<Object?> operation,
  Map<String, Object?> contract,
});

/// Original public raw inputs, before nullable omission or row flattening.
/// Operation references are retained privately; no callback or style is read.
class FramedCollectionWebRawSource {
  FramedCollectionWebRawSource._(this.producer, this.source, this._inputs);
  final Component producer;
  final BoxObservationSourceSpec source;
  final _Inputs _inputs;
  List<Component?> get rawSlots => List.unmodifiable(_inputs.slots);
  Map<String, Object?> get currentDomContract {
    validateExistingCurrentBinding();
    return Map.unmodifiable(_inputs.contract);
  }

  void validateExistingCurrentBinding() {
    final now = _readInputs(producer, source);
    if (now.slots.length != _inputs.slots.length ||
        now.operation.length != _inputs.operation.length ||
        List.generate(
          now.slots.length,
          (i) => identical(now.slots[i], _inputs.slots[i]),
        ).any((v) => !v) ||
        List.generate(
          now.operation.length,
          (i) => identical(now.operation[i], _inputs.operation[i]),
        ).any((v) => !v) ||
        jsonEncode(now.contract) != jsonEncode(_inputs.contract)) {
      throw StateError('FRAMED_COLLECTION_CURRENT_INPUTS_CHANGED');
    }
  }
}

FramedCollectionWebRawSource bindFramedCollectionWebRawSource({
  required Component producer,
  required BoxObservationSourceSpec source,
}) => FramedCollectionWebRawSource._(
  producer,
  source,
  _readInputs(producer, source),
);

_Inputs _readInputs(Component producer, BoxObservationSourceSpec source) {
  if (!BoxObservationSourceSpec.framedCollectionFrames.contains(source) &&
      source != BoxObservationSourceSpec.mockupBrowserFrame) {
    throw StateError('FRAMED_COLLECTION_CLOSED_RAW_SOURCE_CHANGED');
  }
  final slots = <Component?>[];
  final operation = <Object?>[];
  final contract = <String, Object?>{};
  if (source == BoxObservationSourceSpec.mockupDeviceBodyFrame) {
    if (producer is! coui.MockupDevice ||
        producer.runtimeType != coui.MockupDevice ||
        producer.tag != 'div') {
      throw StateError('FRAMED_COLLECTION_CONCRETE_DEVICE_REQUIRED');
    }
    final w = producer;
    slots.add(w.child);
    operation.addAll([
      w.device,
      w.orientation,
      w.finish,
      w.showCamera,
      w.showStatusBar,
      w.showGestureBar,
      w.screenBrightness,
    ]);
  } else if (source == BoxObservationSourceSpec.mockupBrowserFrame) {
    if (producer is! coui.MockupBrowser ||
        producer.runtimeType != coui.MockupBrowser ||
        producer.tag != 'div') {
      throw StateError('FRAMED_COLLECTION_CONCRETE_BROWSER_REQUIRED');
    }
    final w = producer;
    slots.add(w.child);
    operation.addAll([w.showControls, w.addressBar]);
    contract.addAll({
      'showControls': w.showControls,
      'addressSupplied': w.addressBar != null,
    });
  } else if (source == BoxObservationSourceSpec.joinStripLayoutHost) {
    if (producer.runtimeType != coui.Join) {
      throw StateError('FRAMED_COLLECTION_CONCRETE_JOIN_REQUIRED');
    }
    final w = producer as coui.Join;
    slots.addAll(w.children);
    operation.add(w.vertical);
    contract['vertical'] = w.vertical;
  } else {
    final List<coui.CoreTableRowData<Component>> rows;
    final bool resizable;
    coui.CoreTableCellResizeMode? columnsMode;
    coui.CoreTableCellResizeMode? rowsMode;
    if (producer.runtimeType == coui.Table) {
      final w = producer as coui.Table;
      rows = w.rows;
      resizable = false;
    } else if (producer.runtimeType == coui.ResizableTable) {
      final w = producer as coui.ResizableTable;
      rows = w.rows;
      resizable = true;
      operation.add(w.controller);
      columnsMode = w.columnResizeMode;
      rowsMode = w.rowResizeMode;
      operation.addAll([columnsMode, rowsMode]);
    } else {
      throw StateError('FRAMED_COLLECTION_CONCRETE_TABLE_REQUIRED');
    }
    var columns = 0;
    for (final row in rows) {
      if (row.runtimeType != (coui.CoreTableRowData<Component>)) {
        throw StateError('FRAMED_COLLECTION_CONCRETE_ROW_REQUIRED');
      }
      var count = 0;
      for (final cell in row.cells) {
        if (cell.runtimeType != (coui.CoreTableCellData<Component>) ||
            cell.columnSpan < 1 ||
            cell.rowSpan < 1) {
          throw StateError('FRAMED_COLLECTION_CONCRETE_CELL_REQUIRED');
        }
        count += cell.columnSpan;
      }
      if (count > columns) columns = count;
    }
    final rowContracts = <Map<String, Object?>>[];
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      operation.add(row);
      final cells = <Map<String, Object?>>[];
      var column = 0;
      for (final cell in row.cells) {
        // Keep every generic cell and child before any DOM flattening.
        operation.add(cell);
        slots.add(cell.child);
        final columnResizer =
            resizable &&
            columnsMode != .none &&
            (columnsMode == .expand || column + cell.columnSpan < columns);
        final rowResizer =
            resizable &&
            rowsMode != .none &&
            (rowsMode == .expand || r + cell.rowSpan < rows.length);
        cells.add({
          'columnSpan': cell.columnSpan,
          'rowSpan': cell.rowSpan,
          'resizers': (columnResizer ? 1 : 0) + (rowResizer ? 1 : 0),
        });
        column += cell.columnSpan;
      }
      rowContracts.add({'kind': row.kind.name, 'cells': cells});
    }
    contract.addAll({'resizable': resizable, 'rows': rowContracts});
  }
  final unique = Set<Component>.identity();
  for (final slot in slots) {
    if (slot != null && !unique.add(slot)) {
      throw StateError('FRAMED_COLLECTION_DUPLICATE_RAW_BEFORE_OMISSION');
    }
  }
  return (
    slots: List.unmodifiable(slots),
    operation: List.unmodifiable(operation),
    contract: Map.unmodifiable({
      'kind': 'current-framed-collection-raw-v1',
      'logicalUnitId': source.logicalUnitId,
      'rawSlotCount': slots.length,
      'slotPresence': slots.map((s) => s != null).toList(growable: false),
      ...contract,
    }),
  );
}

/// A requirement descriptor only; it is not proof that a producer was mounted.
/// Existing direct-slug Browser returns null; recognized wrong recipes throw.
String? requiredFramedCollectionSsrKind(MatrixEntry entry) =>
    FramedCollectionSsrSource.forEntry(entry) == null
    ? null
    : 'canonical-ssr-framed-collection-v1';

/// A passive observer of the original registry mount, never a second build.
/// Browser supplies only current-source metadata for Root's existing reader.
class FramedCollectionSsrSource implements CurrentSsrBoxSource {
  FramedCollectionSsrSource._(
    this.entry,
    this.source,
    this.exampleType,
    this.route,
  );
  static FramedCollectionSsrSource? forEntry(MatrixEntry entry) {
    final sources = entry.probes
        .map((p) => p.boxObservationSource)
        .whereType<BoxObservationSourceSpec>()
        .where(
          (s) => [
            ...BoxObservationSourceSpec.framedCollectionFrames,
            BoxObservationSourceSpec.mockupBrowserFrame,
          ].any((v) => v.logicalUnitId == s.logicalUnitId),
        )
        .toSet();
    if (sources.isEmpty) return null;
    if (sources.length != 1) {
      throw StateError('FRAMED_COLLECTION_MULTIPLE_SOURCES');
    }
    // Existing direct-slug Browser keeps its original component protocol.
    // A different recognized source may not fall through to that reader.
    if (entry.component == 'mockup-browser' && entry.variant == 'default') {
      if (sources.single != BoxObservationSourceSpec.mockupBrowserFrame) {
        throw StateError('FRAMED_COLLECTION_SSR_RECIPE_SOURCE_CHANGED');
      }
      return null;
    }
    final (expected, type, route) = switch ((entry.component, entry.variant)) {
      ('mockup', 'phone') || ('mockup-device', 'default') => (
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        MockupDeviceExample,
        'device',
      ),
      ('mockup', 'tablet') => (
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        MockupDeviceTabletExample,
        'device',
      ),
      ('mockup', 'landscape') => (
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        MockupDeviceLandscapeExample,
        'device',
      ),
      ('mockup-device', 'flat') => (
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        MockupDeviceFlatExample,
        'device',
      ),
      ('mockup', 'browser') => (
        BoxObservationSourceSpec.mockupBrowserFrame,
        MockupBrowserExample,
        'browser-sized',
      ),
      ('mockup', 'app') => (
        BoxObservationSourceSpec.mockupBrowserFrame,
        MockupAppExample,
        'browser-direct',
      ),
      ('join', 'default') => (
        BoxObservationSourceSpec.joinStripLayoutHost,
        JoinDefaultExample,
        'join',
      ),
      ('join', 'input') => (
        BoxObservationSourceSpec.joinStripLayoutHost,
        JoinInputExample,
        'join',
      ),
      ('join', 'vertical') => (
        BoxObservationSourceSpec.joinStripLayoutHost,
        JoinVerticalExample,
        'join',
      ),
      ('table', 'default') => (
        BoxObservationSourceSpec.tableGridContentInset,
        TableDefaultExample,
        'table',
      ),
      ('table', 'resizable') => (
        BoxObservationSourceSpec.tableGridContentInset,
        TableResizableExample,
        'table',
      ),
      _ => throw StateError('FRAMED_COLLECTION_SSR_RECIPE_CHANGED'),
    };
    if (sources.single != expected) {
      throw StateError('FRAMED_COLLECTION_SSR_SOURCE_CHANGED');
    }
    return FramedCollectionSsrSource._(entry, expected, type, route);
  }

  final MatrixEntry entry;
  final BoxObservationSourceSpec source;
  final Type exampleType;
  final String route;
  Component? _registryResult;
  div? _capture;
  @override
  void recordBuild(Component result, div capture) {
    if (_registryResult != null || _capture != null) {
      throw StateError('FRAMED_COLLECTION_BUILD_REPEATED');
    }
    _registryResult = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    final registry = _registryResult;
    final capture = _capture;
    if (registry == null ||
        capture == null ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw StateError('FRAMED_COLLECTION_CAPTURE_CHANGED');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    var example = currentSsrIdentityElement(root, registry);
    if (!identical(example.parent, captureDom)) {
      throw StateError('FRAMED_COLLECTION_REGISTRY_EDGE_CHANGED');
    }
    Element registryDom;
    if (route == 'device') {
      if (registry.runtimeType != div) {
        throw StateError('FRAMED_COLLECTION_DEVICE_WIDTH_WRAPPER_CHANGED');
      }
      final wrapper = registry as div;
      if (wrapper.children.length != 1 ||
          wrapper.children.single.runtimeType != exampleType) {
        throw StateError('FRAMED_COLLECTION_DEVICE_EXAMPLE_CHANGED');
      }
      registryDom = currentSsrGeneratedDiv(example, wrapper);
      example = soleCurrentSsrChild(registryDom);
    } else {
      if (registry.runtimeType != exampleType) {
        throw StateError('FRAMED_COLLECTION_EXAMPLE_CHANGED');
      }
      registryDom = _firstDom(example);
    }
    if (example.component.runtimeType != exampleType) {
      throw StateError('FRAMED_COLLECTION_CURRENT_EXAMPLE_CHANGED');
    }
    var producerElement = soleCurrentSsrChild(example);
    if (route == 'browser-sized') {
      final authored = producerElement.component;
      if (authored.runtimeType != div ||
          (authored as div).children.length != 1) {
        throw StateError('FRAMED_COLLECTION_AUTHORED_BROWSER_HOST_CHANGED');
      }
      producerElement = soleCurrentSsrChild(
        currentSsrGeneratedDiv(producerElement, authored),
      );
    }
    final producer = producerElement.component;
    final raw = bindFramedCollectionWebRawSource(
      producer: producer,
      source: source,
    );
    final built = soleCurrentSsrChild(producerElement);
    final owner = switch (route) {
      'join' || 'table' => _typedDiv(built),
      _ => built,
    };
    _dom(owner, 'div');
    final mounts = <Element>[];
    final foreign = <Element, int>{};
    for (var i = 0; i < raw.rawSlots.length; i++) {
      final slot = raw.rawSlots[i];
      if (slot == null) continue;
      final mounted = currentSsrIdentityElement(owner, slot);
      if (mounts.any(
        (other) => _inside(other, mounted) || _inside(mounted, other),
      )) {
        throw StateError('FRAMED_COLLECTION_OVERLAPPING_RAW_CLOSURES');
      }
      mounts.add(mounted);
      for (final frontier in _domFrontier(mounted)) {
        if (foreign.containsKey(frontier)) {
          throw StateError('FRAMED_COLLECTION_FOREIGN_ALIAS');
        }
        foreign[frontier] = i;
      }
    }
    if (route == 'device') _devicePath(owner, raw);
    if (route == 'join') _joinPath(owner, raw);
    if (route == 'table') _tablePath(owner, raw);
    if (route.startsWith('browser-')) _browserPath(owner, raw);
    final markup = _markup(registryDom);
    final before = markup.renderToHtml();
    final parsed = _singleMarkup(before);
    final tree = _tree(registryDom, parsed, foreign);
    raw.validateExistingCurrentBinding();
    if (!identical(captureElement.component, _capture) ||
        !identical(
          currentSsrIdentityElement(root, registry).component,
          _registryResult,
        ) ||
        !identical(producerElement.component, raw.producer) ||
        markup.renderToHtml() != before) {
      throw StateError('FRAMED_COLLECTION_CURRENT_SOURCE_CHANGED');
    }
    return {
      'kind': 'canonical-ssr-framed-collection-v1',
      'entryKey': entry.key,
      'source': source.toJson(),
      'currentRaw': {
        ...raw.currentDomContract,
        'route': route,
        'generatedTree': tree,
      },
      'completeRawSlotCount': raw.rawSlots.length,
      'rawOrderFromPublicProducerLists': true,
    };
  }
}

bool _inside(Element ancestor, Element child) {
  for (Element? e = child; e != null; e = e.parent) {
    if (identical(e, ancestor)) return true;
  }
  return false;
}

List<Element> _children(Element e) {
  final result = <Element>[];
  e.visitChildren(result.add);
  return result;
}

List<Element> _domFrontier(Element element) {
  if (element.component is DomComponent) return [element];
  return [for (final child in _children(element)) ..._domFrontier(child)];
}

List<MarkupRenderObject> _renderFrontier(Element element) {
  if (element is RenderObjectElement) {
    final render = element.renderObject;
    if (render is! MarkupRenderObject) {
      throw StateError('FRAMED_COLLECTION_PUBLIC_MARKUP_FRONTIER_REQUIRED');
    }
    return [render];
  }
  return [for (final child in _children(element)) ..._renderFrontier(child)];
}

Element _firstDom(Element element) {
  final roots = _domFrontier(element);
  if (roots.length != 1) {
    throw StateError('FRAMED_COLLECTION_SINGLE_DOM_ROOT_REQUIRED');
  }
  return roots.single;
}

Element _typedDiv(Element element) {
  final declared = element.component;
  if (declared.runtimeType != div) {
    throw StateError('FRAMED_COLLECTION_DECLARED_DIV_REQUIRED');
  }
  return currentSsrGeneratedDiv(element, declared as div);
}

DomComponent _dom(Element element, String tag) {
  final component = element.component;
  if (component is! DomComponent || component.tag != tag) {
    throw StateError('FRAMED_COLLECTION_DOM_CHANGED');
  }
  final declared = component.children ?? const <Component>[];
  final actual = _children(element);
  if (actual.length != declared.length ||
      List.generate(
        declared.length,
        (i) =>
            identical(actual[i].component, declared[i]) &&
            identical(actual[i].parent, element),
      ).any((v) => !v)) {
    throw StateError('FRAMED_COLLECTION_FULL_DECLARED_ORDER_CHANGED');
  }
  // Element children alone miss anonymous render text injected beside a raw
  // child. Retain every actual public render frontier, including legitimate
  // Text, RawText and Fragment objects, before serializing that same owner.
  final expectedRender = [
    for (final child in actual) ..._renderFrontier(child),
  ];
  final actualRender = _markup(element).children.toList(growable: false);
  if (actualRender.length != expectedRender.length ||
      List.generate(
        expectedRender.length,
        (i) => identical(actualRender[i], expectedRender[i]),
      ).any((same) => !same)) {
    throw StateError('FRAMED_COLLECTION_UNDECLARED_MARKUP_CHILD_CHANGED');
  }
  return component;
}

void _devicePath(Element owner, FramedCollectionWebRawSource raw) {
  final root = _dom(owner, 'div');
  final children = root.children ?? const <Component>[];
  if (children.length < 2 ||
      children.last.runtimeType != div ||
      children.where((c) => c.runtimeType == coui.OutlinedContainer).length !=
          1 ||
      children.whereType<coui.OutlinedContainer>().single.child != null) {
    throw StateError('FRAMED_COLLECTION_DEVICE_GENERATED_BODY_CHANGED');
  }
  final bezel = _typedDiv(_children(owner).last);
  final bezelChildren = _children(bezel);
  if (bezelChildren.isEmpty) {
    throw StateError('FRAMED_COLLECTION_DEVICE_SCREEN_MISSING');
  }
  var screen = bezelChildren.first;
  final candidate = screen.component;
  if (candidate.runtimeType == coui.BrightnessScope) {
    final declared = (candidate as coui.BrightnessScope).child;
    screen = currentSsrIdentityElement(screen, declared);
  }
  final screenDom = _typedDiv(screen);
  final content = _typedDiv(_children(screenDom).first);
  final input = _dom(content, 'div').children ?? const <Component>[];
  if (input.length != 1 || !identical(input.single, raw.rawSlots.single)) {
    throw StateError('FRAMED_COLLECTION_DEVICE_WHOLE_CHILD_CHANGED');
  }
}

void _joinPath(Element owner, FramedCollectionWebRawSource raw) {
  final seats = _children(owner);
  if (seats.length != raw.rawSlots.length + 1 ||
      seats.first.component is! DomComponent ||
      (seats.first.component as DomComponent).tag != 'style') {
    throw StateError('FRAMED_COLLECTION_JOIN_GENERATED_ORDER_CHANGED');
  }
  for (var i = 0; i < raw.rawSlots.length; i++) {
    final wrapper = _dom(_typedDiv(seats[i + 1]), 'div');
    if (wrapper.children?.length != 1 ||
        !identical(wrapper.children!.single, raw.rawSlots[i])) {
      throw StateError('FRAMED_COLLECTION_JOIN_WHOLE_CHILD_CHANGED');
    }
  }
}

void _tablePath(Element owner, FramedCollectionWebRawSource raw) {
  final root = _dom(owner, 'div');
  if (root.attributes?['role'] != 'table') {
    throw StateError('FRAMED_COLLECTION_TABLE_ROLE_CHANGED');
  }
  final rows = raw.currentDomContract['rows']! as List<Map<String, Object?>>;
  final seats = _children(owner);
  if (seats.length != rows.length) {
    throw StateError('FRAMED_COLLECTION_TABLE_ROWS_CHANGED');
  }
  var index = 0;
  for (var r = 0; r < rows.length; r++) {
    final rowElement = _typedDiv(seats[r]);
    final row = _dom(rowElement, 'div');
    final cells = rows[r]['cells']! as List<Map<String, Object?>>;
    if (row.attributes?['role'] != 'row' ||
        _children(rowElement).length != cells.length) {
      throw StateError('FRAMED_COLLECTION_TABLE_ROW_ORDER_CHANGED');
    }
    for (var c = 0; c < cells.length; c++) {
      final cellElement = _typedDiv(_children(rowElement)[c]);
      final cell = _dom(cellElement, 'div');
      final children = cell.children ?? const <Component>[];
      final resizers = cells[c]['resizers']! as int;
      if (cell.attributes?['role'] !=
              (rows[r]['kind'] == 'header' ? 'columnheader' : 'cell') ||
          children.length != resizers + 1 ||
          !identical(children.first, raw.rawSlots[index])) {
        throw StateError('FRAMED_COLLECTION_TABLE_CELL_ORDER_CHANGED');
      }
      for (final extra in _children(cellElement).skip(1)) {
        if ((_dom(_typedDiv(extra), 'div').children ?? const <Component>[])
            .isNotEmpty) {
          throw StateError('FRAMED_COLLECTION_TABLE_RESIZER_CHANGED');
        }
      }
      index++;
    }
  }
  if (index != raw.rawSlots.length) {
    throw StateError('FRAMED_COLLECTION_TABLE_RAW_COUNT_CHANGED');
  }
}

void _browserPath(Element owner, FramedCollectionWebRawSource raw) {
  final root = _dom(owner, 'div');
  final generated = root.children ?? const <Component>[];
  if (generated.length != 1 ||
      generated.single.runtimeType != coui.OutlinedContainer) {
    throw StateError('FRAMED_COLLECTION_BROWSER_OUTLINED_CHANGED');
  }
  final surface = generated.single as coui.OutlinedContainer;
  final body = surface.child;
  if (body is! div || body.runtimeType != div || body.children.length != 3) {
    throw StateError('FRAMED_COLLECTION_BROWSER_BODY_CHANGED');
  }
  final bodyElement = currentSsrIdentityElement(owner, body);
  final content = _typedDiv(_children(_typedDiv(bodyElement)).first);
  final inset = _typedDiv(_children(content).single);
  final declared = _dom(inset, 'div').children ?? const <Component>[];
  final expected = raw.rawSlots.whereType<Component>().toList();
  if (declared.length != expected.length ||
      List.generate(
        expected.length,
        (i) => identical(declared[i], expected[i]),
      ).any((v) => !v)) {
    throw StateError('FRAMED_COLLECTION_BROWSER_WHOLE_CHILD_CHANGED');
  }
  final bodyDom = _typedDiv(bodyElement);
  final toolbar = _typedDiv(_children(bodyDom)[1]);
  final input = raw.currentDomContract;
  final controls = input['showControls'] == true;
  final address = input['addressSupplied'] == true;
  final generatedToolbar = _children(toolbar);
  if (generatedToolbar.length != (controls ? 1 : 0) + (address ? 3 : 0) ||
      (_dom(_typedDiv(_children(bodyDom)[2]), 'div').children ??
              const <Component>[])
          .isNotEmpty) {
    throw StateError('FRAMED_COLLECTION_BROWSER_TOOLBAR_BRANCH_CHANGED');
  }
  if (controls && _children(_typedDiv(generatedToolbar.first)).length != 3) {
    throw StateError('FRAMED_COLLECTION_BROWSER_CONTROLS_CHANGED');
  }
}

MarkupRenderObject _markup(Element owner) {
  if (owner is! RenderObjectElement ||
      owner.renderObject is! MarkupRenderObject) {
    throw StateError('FRAMED_COLLECTION_MARKUP_OWNER_REQUIRED');
  }
  return owner.renderObject as MarkupRenderObject;
}

dom.Element _singleMarkup(String text) {
  final parsed = html.parseFragment(text);
  final whitespace = RegExp(r'^[\t\n\f\r ]*$');
  if (parsed.children.length != 1 ||
      parsed.nodes.any(
        (n) =>
            !identical(n, parsed.children.single) &&
            !(n is dom.Text && whitespace.hasMatch(n.data)),
      )) {
    throw StateError('FRAMED_COLLECTION_WHOLE_MARKUP_CHANGED');
  }
  return parsed.children.single;
}

Map<String, Object?> _tree(
  Element owner,
  dom.Element parsed,
  Map<Element, int> foreign,
) {
  if (foreign.containsKey(owner)) return {'foreignSlot': foreign[owner]};
  final declared = owner.component;
  if (declared is! DomComponent ||
      declared.tag.toLowerCase() != parsed.localName?.toLowerCase()) {
    throw StateError('FRAMED_COLLECTION_DOM_SERIALIZATION_CHANGED');
  }
  _dom(owner, declared.tag);
  final actual = [for (final child in _children(owner)) ..._domFrontier(child)];
  // Only source-generated Icon glyph RawText inflates an SVG subtree. The
  // original mounted owner is serialized passively, never built again.
  if (declared.tag == 'svg' &&
      declared.children?.length == 1 &&
      declared.children!.single is coui.RawText) {
    return _parsedTree(parsed);
  }
  if (actual.length != parsed.children.length) {
    throw StateError('FRAMED_COLLECTION_GENERATED_DOM_COUNT_CHANGED');
  }
  return {
    'namespaceURI': parsed.namespaceUri,
    'localName': parsed.localName,
    'role': parsed.attributes['role'],
    'nodeKinds': _nodeKinds(parsed),
    'children': [
      for (var i = 0; i < actual.length; i++)
        _tree(actual[i], parsed.children[i], foreign),
    ],
  };
}

Map<String, Object?> _parsedTree(dom.Element node) => {
  'namespaceURI': node.namespaceUri,
  'localName': node.localName,
  'role': node.attributes['role'],
  'nodeKinds': _nodeKinds(node),
  'children': node.children.map(_parsedTree).toList(growable: false),
};

List<int> _nodeKinds(dom.Element node) => [
  for (final child in node.nodes)
    if (!(child is dom.Text && RegExp(r'^[\t\n\f\r ]*$').hasMatch(child.data)))
      child.nodeType,
];
