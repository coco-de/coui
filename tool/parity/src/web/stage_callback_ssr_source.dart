// Passive Stage source: original frame -> owned padding DIV -> opaque body.
import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/stage_container/stage_container_default_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const _kNamespace = 'http://www.w3.org/1999/xhtml';
final _ascii = RegExp(r'^[\t\n\f\r ]*$');

/// Retains an already mounted result; neither builder nor resolver is called.
class StageCallbackSsrSource implements CurrentSsrBoxSource {
  StageCallbackSsrSource._(this.entry);

  static StageCallbackSsrSource? forEntry(MatrixEntry entry) {
    const source = BoxObservationSourceSpec.stageCallbackContentInset;
    if (!entry.probes.any(
      (p) => p.boxObservationSource?.logicalUnitId == source.logicalUnitId,
    )) {
      return null;
    }
    if (entry.component != 'stage-container' ||
        entry.variant != 'default' ||
        !const ['light', 'dark'].contains(entry.theme.name) ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource != source) {
      throw _changed('closed original Stage recipe/whole tuple');
    }
    return StageCallbackSsrSource._(entry);
  }

  final MatrixEntry entry;
  Component? _registry;
  div? _capture;
  ({List<Object?> held, Map<String, Object?> raw})? _live;
  bool _completed = false;
  Element? _observedRoot;

  @override
  void recordBuild(Component result, div capture) {
    if (_registry != null || _capture != null) throw _changed('repeated build');
    _registry = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    if (_live != null || _completed) throw _changed('repeated observation');
    final before = _read(root);
    final after = _read(root);
    if (!_same(before.held, after.held) ||
        jsonEncode(before.raw) != jsonEncode(after.raw)) {
      throw _changed('held current Stage, callback and original prefix');
    }
    _live = before;
    _observedRoot = root;
    return const {'stageAwaitingExactNormalSerializedBody': true};
  }

  Map<String, Object?> completeWithSerializedBody(String body) {
    final live = _live;
    final root = _observedRoot;
    if (live == null || root == null || _completed) {
      throw _changed('normal body completion');
    }
    final current = _read(root);
    if (!_same(live.held, current.held) ||
        jsonEncode(live.raw) != jsonEncode(current.raw)) {
      throw _changed('current owned fields held through normal serialization');
    }
    final fragment = html.parseFragment(body);
    // A nested foreign attribute is not another canonical capture. Retain the
    // outermost original capture and never use foreign interiors as authority.
    final captures = fragment.querySelectorAll('[data-parity-key]').where((e) {
      if (e.attributes['data-parity-key'] != entry.key) return false;
      for (var p = e.parent; p != null; p = p.parent) {
        if (p.attributes['data-parity-key'] == entry.key) return false;
      }
      return true;
    }).toList();
    if (captures.length != 1) throw _changed('one original capture');
    final capture = captures.single;
    if (capture.namespaceUri != _kNamespace || capture.localName != 'div') {
      throw _changed('original typed capture DIV');
    }
    final raw = Map<String, Object?>.of(live.raw);
    final frame = raw['frame']! as Map<String, Object?>;
    final padding = raw['paddingOwner']! as Map<String, Object?>;
    final shapes = raw['bodyFrontier']! as List<Map<String, Object?>>;
    final captureNodes = <Map<String, Object?>>[];
    dom.Element? actualFrame;
    for (final node in capture.nodes) {
      if (node is dom.Text && _ascii.hasMatch(node.data)) {
        captureNodes.add({'formatterText': node.data});
      } else if (node is dom.Element && actualFrame == null) {
        actualFrame = node;
        captureNodes.add(const {'frame': true});
      } else {
        throw _changed('complete normal capture node list');
      }
    }
    if (actualFrame == null || !_elementMatches(actualFrame, frame)) {
      throw _changed('exact original frame from normal response');
    }
    final frameNodes = <Map<String, Object?>>[];
    dom.Element? actualPadding;
    for (final node in actualFrame.nodes) {
      if (node is dom.Text && _ascii.hasMatch(node.data)) {
        frameNodes.add({'formatterText': node.data});
      } else if (node is dom.Element && actualPadding == null) {
        actualPadding = node;
        frameNodes.add(const {'paddingOwner': true});
      } else {
        throw _changed('complete sole inner allocation and formatter nodes');
      }
    }
    if (actualPadding == null || !_elementMatches(actualPadding, padding)) {
      throw _changed('exact current generated padding DIV');
    }
    final paddingNodes = <Map<String, Object?>>[];
    var cursor = 0;
    final nodes = actualPadding.nodes;
    for (var i = 0; i < shapes.length; i++) {
      final shape = shapes[i];
      while (cursor < nodes.length &&
          shape['nodeType'] != 3 &&
          nodes[cursor] is dom.Text &&
          _ascii.hasMatch((nodes[cursor] as dom.Text).data)) {
        paddingNodes.add({'formatterText': (nodes[cursor++] as dom.Text).data});
      }
      if (cursor == nodes.length || !_maps(_shape(nodes[cursor]), shape)) {
        throw _changed('complete opaque callback frontier order');
      }
      paddingNodes.add({'foreignNode': i});
      cursor++;
    }
    while (cursor < nodes.length) {
      final node = nodes[cursor++];
      if (node is! dom.Text || !_ascii.hasMatch(node.data)) {
        throw _changed('extra unrecorded callback frontier');
      }
      paddingNodes.add({'formatterText': node.data});
    }
    raw.addAll({
      'capture': _attributes(capture),
      'captureNodes': captureNodes,
      'frameNodes': frameNodes,
      'paddingNodes': paddingNodes,
    });
    _completed = true;
    return {
      'kind': 'canonical-ssr-stage-callback-v1',
      'entryKey': entry.key,
      'source': BoxObservationSourceSpec.stageCallbackContentInset.toJson(),
      'currentRaw': raw,
      'completeRawSlotCount': 1,
      'rawOrderFromPublicProducerLists': true,
    };
  }

  ({List<Object?> held, Map<String, Object?> raw}) _read(Element root) {
    final original = _registry;
    final capture = _capture;
    if (original == null ||
        original.runtimeType != StageContainerDefaultExample ||
        capture == null ||
        capture.children.length != 1 ||
        !identical(capture.children.single, original) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw _changed('exact original registry and declared capture');
    }
    final captureDom = currentSsrGeneratedDiv(
      currentSsrIdentityElement(root, capture),
      capture,
    );
    final example = currentSsrIdentityElement(root, original);
    if (!identical(example.parent, captureDom)) {
      throw _changed('registry parent');
    }
    final stage = soleCurrentSsrChild(example);
    if (stage.component.runtimeType != coui.StageContainer) {
      throw _changed('original public Stage producer');
    }
    final input = stage.component as coui.StageContainer;
    // The closed original Example has no root style/event overrides. Their
    // presence would require different source authority, not a padding guess.
    if (input.css != null ||
        input.classes != null ||
        input.id != null ||
        (input.userAttributes?.isNotEmpty ?? false) ||
        input.eventHandlers.isNotEmpty) {
      throw _changed('unmodified original outer frame');
    }
    final returned = soleCurrentSsrChild(stage);
    if (returned.component.runtimeType != div) {
      throw _changed('normal outer DIV');
    }
    final frameInput = returned.component as div;
    if (frameInput.children.length != 1 ||
        frameInput.children.single.runtimeType != div) {
      throw _changed('complete owned two-DIV prefix');
    }
    final frame = currentSsrGeneratedDiv(returned, frameInput);
    final innerInput = frameInput.children.single as div;
    final innerElement = soleCurrentSsrChild(frame);
    if (!identical(innerElement.component, innerInput) ||
        innerInput.children.length != 1) {
      throw _changed('sole declared current inner allocation');
    }
    final inner = currentSsrGeneratedDiv(innerElement, innerInput);
    final bodyInput = innerInput.children.single;
    final body = soleCurrentSsrChild(inner);
    if (!identical(body.component, bodyInput)) {
      throw _changed('opaque callback edge');
    }
    final foreign = _frontier(body);
    final actual = _markup(inner).children.toList();
    // This closed original callback returns one typed DIV. Its interior is
    // opaque: inspect only the public current outer render kind/tag.
    if (bodyInput.runtimeType != div ||
        foreign.length != 1 ||
        foreign.single is! MarkupRenderElement ||
        (foreign.single as MarkupRenderElement).tag != 'div') {
      throw _changed('original callback whole outer DIV frontier');
    }
    final frameRender = _ownedRender(frame);
    final innerRender = _ownedRender(inner);
    if (!_same(actual, foreign) ||
        foreign.any((r) => !identical(r.parent, _markup(inner)))) {
      throw _changed('complete current callback render frontier');
    }
    return (
      held: [
        root,
        capture,
        captureDom,
        example,
        original,
        stage,
        input,
        input.builder,
        returned,
        frameInput,
        frame,
        frameRender,
        frameRender.id,
        frameRender.classes,
        frameRender.styles,
        frameRender.attributes,
        innerElement,
        innerInput,
        inner,
        innerRender,
        innerRender.id,
        innerRender.classes,
        innerRender.styles,
        innerRender.attributes,
        bodyInput,
        body,
        ...foreign,
      ],
      raw: {
        'kind': 'current-stage-callback-padding-v1',
        'quantityBoundary': 'original-stage-frame-to-opaque-callback-content',
        'callbackReexecuted': false,
        'bodyInteriorIsSourceAuthority': false,
        'frame': _owned(frame),
        'paddingOwner': _owned(inner),
        'bodyFrontier': [for (final r in foreign) ..._frontierShapes(r)],
      },
    );
  }
}

MarkupRenderObject _markup(Element e) {
  if (e is! RenderObjectElement || e.renderObject is! MarkupRenderObject) {
    throw _changed('direct public markup owner');
  }
  return e.renderObject as MarkupRenderObject;
}

List<MarkupRenderObject> _frontier(Element e) {
  if (e is RenderObjectElement) return [_markup(e)];
  final children = <Element>[];
  e.visitChildren(children.add);
  return [for (final child in children) ..._frontier(child)];
}

Map<String, Object?> _attributes(dom.Element e) => {
  'namespaceURI': e.namespaceUri,
  'localName': e.localName,
  'attributes': {
    for (final a in e.attributes.entries) a.key.toString(): a.value,
  },
};

MarkupRenderElement _ownedRender(Element e) {
  final render = _markup(e);
  if (render is! MarkupRenderElement || render.tag != 'div') {
    throw _changed('direct public current owned DIV');
  }
  return render;
}

Map<String, Object?> _owned(Element e) {
  final render = _ownedRender(e);
  final extra = render.attributes ?? const <String, String>{};
  if (extra.keys.any((name) => const {'id', 'class', 'style'}.contains(name))) {
    throw _changed('overlapping current attribute channels');
  }
  // Direct current public fields, with the exact qualified Jaspr attribute
  // spelling/order. No renderToHtml, build, resolver or serializer invocation.
  final attrs = <String, String>{
    if (render.id != null) 'id': render.id!,
    if (render.classes?.isNotEmpty ?? false) 'class': render.classes!,
    if (render.styles?.isNotEmpty ?? false)
      'style': render.styles!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('; '),
    ...extra,
  };
  return {'namespaceURI': _kNamespace, 'localName': 'div', 'attributes': attrs};
}

List<Map<String, Object?>> _frontierShapes(MarkupRenderObject render) {
  if (render is! MarkupRenderElement || render.tag != 'div') {
    throw _changed('closed opaque outer render kind/tag');
  }
  // The original callback's sole complete outer DIV; do not access foreign
  // attributes, styles, text or children and never serialize its subtree.
  return [
    const {'nodeType': 1, 'namespaceURI': _kNamespace, 'localName': 'div'},
  ];
}

Map<String, Object?> _shape(dom.Node node) => node is dom.Element
    ? {
        'nodeType': 1,
        'namespaceURI': node.namespaceUri,
        'localName': node.localName,
      }
    : node is dom.Text || node is dom.Comment
    ? {'nodeType': node.nodeType}
    : throw _changed('unsupported callback node kind');

bool _maps(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) =>
    a.length == b.length &&
    a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);
bool _elementMatches(dom.Element e, Map<String, Object?> expected) =>
    e.namespaceUri == expected['namespaceURI'] &&
    e.localName == expected['localName'] &&
    _maps(_attributes(e)['attributes']! as Map, expected['attributes']! as Map);
bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);

StateError _changed(String detail) =>
    StateError('STAGE_CALLBACK_SOURCE_CHANGED: $detail');
String? requiredStageCallbackSsrKind(MatrixEntry entry) =>
    StageCallbackSsrSource.forEntry(entry) == null
    ? null
    : 'canonical-ssr-stage-callback-v1';
