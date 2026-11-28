import 'dart:convert';

import 'package:docs_core/internal/preview/scenes.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div, section;
import 'package:jaspr/server.dart';

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const _kKind = 'canonical-ssr-docs-size-preview-v1';
const _kNamespace = 'http://www.w3.org/1999/xhtml';
final _ascii = RegExp(r'^[\t\n\f\r ]*$');

/// The ordinary SizeSpec result owns its constant preview frame. Data-only
/// attributes/spec aliases and generated component interiors are not padding
/// parameters. No build, resolver, callback or collector serialization runs.
class DocsSizeSsrSource implements CurrentSsrBoxSource {
  DocsSizeSsrSource._(this.entry);

  static DocsSizeSsrSource? forEntry(MatrixEntry entry) {
    const expected = BoxObservationSourceSpec.docsSizePreview;
    final claims = entry.probes.any(
      (p) =>
          p.boxObservationSource?.logicalUnitId == expected.logicalUnitId ||
          p.boxObservationSource?.webAdapterId == expected.webAdapterId ||
          p.boxObservationSource?.nativeAdapterId == expected.nativeAdapterId,
    );
    if (!claims) return null;
    if (!entry.variant.startsWith(docsScenePrefix) ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource != expected) {
      throw _changed('closed declared SizeSpec tuple');
    }
    return DocsSizeSsrSource._(entry);
  }

  final MatrixEntry entry;
  DocsScene? _scene;
  Component? _registry;
  div? _capture;
  Element? _root;
  ({List<Object?> held, Map<String, Object?> graph, int rows})? _live;
  bool _completed = false;

  /// Receives the SAME scene already resolved by the normal capture build.
  /// This validates the route, not identities of unrelated data-only lists.
  void recordScene(DocsScene? scene) {
    if (_scene != null ||
        scene == null ||
        scene.tag != 'SizeSpec' ||
        scene.reference != entry.variant ||
        scene.attributes['component'] != entry.component) {
      throw _changed('one original SizeSpec scene/reference/component');
    }
    _scene = scene;
  }

  @override
  void recordBuild(Component result, div capture) {
    if (_registry != null || _capture != null || _scene == null) {
      throw _changed('one already-resolved original registry build');
    }
    _registry = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    if (_live != null || _completed) throw _changed('one observation');
    final before = _read(root);
    final after = _read(root);
    if (!_same(before.held, after.held) ||
        jsonEncode(before.graph) != jsonEncode(after.graph)) {
      throw _changed('current normal public source');
    }
    _root = root;
    _live = before;
    return const {'docsSizeAwaitingExactNormalBody': true};
  }

  Map<String, Object?> completeWithSerializedBody(String body) {
    final root = _root;
    final live = _live;
    if (root == null || live == null || _completed) {
      throw _changed('one actual normal body completion');
    }
    final current = _read(root);
    if (!_same(live.held, current.held) ||
        jsonEncode(live.graph) != jsonEncode(current.graph)) {
      throw _changed('source retained through ordinary serialization');
    }
    final captures = html
        .parseFragment(body)
        .querySelectorAll('[data-parity-key]')
        .where((e) => e.attributes['data-parity-key'] == entry.key)
        .toList();
    if (captures.length != 1) throw _changed('one original normal capture');
    final graph = _complete(captures.single, live.graph);
    _completed = true;
    return {
      'kind': _kKind,
      'entryKey': entry.key,
      'source': BoxObservationSourceSpec.docsSizePreview.toJson(),
      'currentRaw': {
        'kind': 'current-docs-size-preview-frame-v1',
        'sceneReference': entry.variant,
        'component': entry.component,
        'dataAliasesArePaddingParameters': false,
        'buildOrResolverReexecuted': false,
        'previewInteriorsAreSourceAuthority': false,
        'tableIsOutsideQuantity': true,
        'headProjection': {
          'kind': 'normal-content-head-then-section-v1',
          'headOutsideBody': true,
          'orderedChildren': ['document-head', 'content-section'],
        },
        'rowCount': live.rows,
        'normalTree': graph,
      },
    };
  }

  ({List<Object?> held, Map<String, Object?> graph, int rows}) _read(
    Element root,
  ) {
    final scene = _scene;
    final registry = _registry;
    final capture = _capture;
    if (scene == null ||
        scene.tag != 'SizeSpec' ||
        scene.reference != entry.variant ||
        scene.attributes['component'] != entry.component ||
        registry == null ||
        registry.runtimeType != div ||
        capture == null ||
        capture.children.length != 1 ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw _changed('original scene and declared capture');
    }
    final held = <Object?>[root, scene, registry, capture];
    final captureElement = _identityPruned(root, capture);
    final cap = _dom(captureElement, held);
    final resultElement = _identityPruned(cap, registry);
    final result = _dom(resultElement, held);
    final prefix = <Element>[];
    for (Element? e = result; e != null; e = e.parent) {
      if (e is RenderObjectElement && e.renderObject is MarkupRenderElement) {
        prefix.insert(0, e);
      }
      if (identical(e, cap)) break;
    }
    if (prefix.length != 4 ||
        !identical(prefix.first, cap) ||
        !_tag(prefix[0], 'div') ||
        !_tag(prefix[1], 'div') ||
        !_tag(prefix[2], 'section') ||
        !_tag(prefix[3], 'div') ||
        _render(prefix[1]).id != 'docs-shell' ||
        _render(prefix[1]).attributes?['data-docs-scene'] != entry.variant ||
        _render(prefix[2]).classes != 'content' ||
        _render(result).classes != 'docs-size-spec') {
      throw _changed('normal capture/host/content/result route');
    }
    final children = _declared(result, held);
    if (children.length != 2) throw _changed('preview then excluded table');
    final preview = _dom(children[0], held);
    final table = _opaque(children[1], 'table', held);
    if (!_tag(preview, 'div') ||
        _render(preview).classes !=
            'docs-stage docs-stage--hug docs-stage--row' ||
        table['nodes'] is! List ||
        (table['nodes']! as List).length != 1 ||
        ((table['nodes']! as List).single as Map)['localName'] != 'div') {
      throw _changed('literal preview frame and table boundary');
    }
    final figures = _declared(preview, held);
    final figureGraphs = <Map<String, Object?>>[];
    for (final original in figures) {
      final figure = _dom(original, held);
      if (!_tag(figure, 'figure') ||
          _render(figure).classes != 'docs-size-item') {
        throw _changed('generated size figure');
      }
      final parts = _declared(figure, held);
      if (parts.length != 2) throw _changed('generated preview then caption');
      final caption = _dom(parts[1], held);
      if (!_tag(caption, 'figcaption')) throw _changed('normal caption');
      final codes = _declared(caption, held);
      if (codes.length != 1) throw _changed('caption code boundary');
      final code = _dom(codes.single, held);
      if (!_tag(code, 'code')) throw _changed('caption code');
      final texts = _declared(code, held);
      if (texts.length != 1 ||
          texts.single is! RenderObjectElement ||
          (texts.single as RenderObjectElement).renderObject
              is! MarkupRenderText) {
        throw _changed('source-generated size text');
      }
      final text =
          (texts.single as RenderObjectElement).renderObject
              as MarkupRenderText;
      held.addAll([texts.single, texts.single.component, text, text.text]);
      figureGraphs.add(
        _owned(figure, 'figure', [
          _opaque(parts[0], 'preview-interior', held),
          _owned(caption, 'caption', [
            _owned(code, 'code', [
              {'kind': 'owned-text', 'nodeType': 3, 'text': text.text},
            ]),
          ]),
        ]),
      );
    }
    var graph = _owned(result, 'result', [
      _owned(preview, 'preview', figureGraphs),
      table,
    ]);
    const roles = ['capture', 'host', 'content'];
    for (var i = 2; i >= 0; i--) {
      if (i == 1) {
        _contentBody(prefix[i], prefix[i + 1], registry, held);
        graph = _owned(prefix[i], roles[i], [graph]);
        continue;
      }
      final children = _declared(prefix[i], held);
      final frontier = [for (final e in children) ..._frontier(e)];
      if (frontier.length != 1 ||
          !identical(frontier.single, _render(prefix[i + 1]))) {
        throw _changed('complete normal ${roles[i]} body frontier');
      }
      graph = _owned(prefix[i], roles[i], [graph]);
    }
    return (held: held, graph: graph, rows: figures.length);
  }
}

// docsSceneHost -> Content.wrapTheme's exact forwarded public child -> normal
// Content.build Fragment[Document.head, section(content)]. Document's normal
// server adapter moves head output outside the body. Authenticate BOTH original
// branches; do not flatten/drop arbitrary STYLE nodes or search by appearance.
void _contentBody(
  Element host,
  Element body,
  Component registry,
  List<Object?> held,
) {
  final hostChildren = _declared(host, held);
  if (hostChildren.length != 1 ||
      hostChildren.single is! InheritedElement ||
      hostChildren.single.component is! InheritedComponent) {
    throw _changed('normal Content.wrapTheme inherited child');
  }
  final inherited = hostChildren.single;
  final forwarded = (inherited.component as InheritedComponent).child;
  final content = soleCurrentSsrChild(inherited);
  if (content is! StatelessElement ||
      !identical(content.component, forwarded)) {
    throw _changed('normal forwarded Content instance');
  }
  final fragment = soleCurrentSsrChild(content);
  if (fragment.component.runtimeType != Fragment ||
      fragment is! RenderObjectElement ||
      fragment.renderObject is! MarkupRenderFragment) {
    throw _changed('normal Content output fragment');
  }
  final declared = (fragment.component as Fragment).children;
  final children = <Element>[];
  fragment.visitChildren(children.add);
  final renders = (fragment.renderObject as MarkupRenderFragment).children
      .toList();
  if (declared.length != 2 ||
      children.length != 2 ||
      renders.length != 2 ||
      declared[0].runtimeType != const Document.head().runtimeType ||
      declared[1].runtimeType != section ||
      (declared[1] as section).classes != 'content' ||
      (declared[1] as section).children.length != 1 ||
      !identical((declared[1] as section).children.single, registry)) {
    throw _changed('exact normal Document.head then original content section');
  }
  for (var i = 0; i < 2; i++) {
    if (!identical(children[i].component, declared[i]) ||
        !identical(children[i].parent, fragment) ||
        !identical(_slotRender(children[i]), renders[i]) ||
        !identical(renders[i].parent, fragment.renderObject)) {
      throw _changed('current normal Content fragment order/identity');
    }
  }
  if (!identical(_dom(children[1], held), body)) {
    throw _changed('actual normal body section projection');
  }
  held.addAll([
    inherited,
    inherited.component,
    forwarded,
    content,
    content.component,
    fragment,
    fragment.component,
    fragment.renderObject,
    declared,
    for (final e in children) ...[
      e,
      e.component,
      e.parent,
      e.slot.target,
      _slotRender(e),
    ],
  ]);
}

Element _identityPruned(Element root, Component wanted) {
  final matches = <Element>[];
  void visit(Element e) {
    if (identical(e.component, wanted)) {
      matches.add(e);
      return;
    }
    e.visitChildren(visit);
  }

  visit(root);
  if (matches.length != 1) {
    throw _changed('unique original component occurrence');
  }
  return matches.single;
}

Element _dom(Element original, List<Object?> held) {
  var e = original;
  held.addAll([e, e.component, e.parent]);
  if (e.component is! DomComponent) {
    e = soleCurrentSsrChild(e);
  }
  if (e.component is! DomComponent ||
      e is! RenderObjectElement ||
      e.renderObject is! MarkupRenderElement) {
    throw _changed('original public DOM/render hop');
  }
  final render = e.renderObject as MarkupRenderElement;
  held.addAll([
    e,
    e.component,
    e.parent,
    render,
    render.id,
    render.classes,
    render.styles,
    render.attributes,
  ]);
  return e;
}

MarkupRenderElement _render(Element e) =>
    (e as RenderObjectElement).renderObject as MarkupRenderElement;
bool _tag(Element e, String tag) =>
    (e.component as DomComponent).tag == tag && _render(e).tag == tag;

List<Element> _declared(Element e, List<Object?> held) {
  final component = e.component as DomComponent;
  final declared = component.children ?? const <Component>[];
  final children = <Element>[];
  e.visitChildren(children.add);
  if (children.length != declared.length ||
      List.generate(
        children.length,
        (i) =>
            !identical(children[i].component, declared[i]) ||
            !identical(children[i].parent, e),
      ).any((v) => v)) {
    throw _changed('current public declared child order');
  }
  final actual = _render(e).children.toList();
  final frontier = [for (final child in children) _slotRender(child)];
  if (actual.length != frontier.length ||
      List.generate(
        actual.length,
        (i) =>
            !identical(actual[i], frontier[i]) ||
            !identical(actual[i].parent, _render(e)),
      ).any((v) => v)) {
    throw _changed('current declared render frontier');
  }
  held.addAll([
    component.children,
    for (final c in children) ...[c, c.component, c.parent],
  ]);
  return children;
}

List<MarkupRenderObject> _frontier(Element e) {
  return _renderFrontier(_slotRender(e));
}

MarkupRenderObject _slotRender(Element e) {
  // Public ElementSlot.target is the normal first RenderObjectElement of this
  // declared child. Do not walk its opaque Component/Element interior.
  final render = e.slot.target?.renderObject;
  if (render is! MarkupRenderObject) {
    throw _changed('normal public slot frontier');
  }
  return render;
}

List<MarkupRenderObject> _renderFrontier(MarkupRenderObject render) =>
    render is MarkupRenderFragment
    ? [for (final c in render.children) ..._renderFrontier(c)]
    : [render];

Map<String, Object?> _opaque(Element e, String role, List<Object?> held) {
  final frontier = _frontier(e);
  // The closed current SizeSpec recipes render one outer element for each
  // generated preview, and one for the excluded table. This is a supported
  // constructor frontier, never a padding value or a fixed number of rows.
  if (frontier.length != 1 || frontier.single is! MarkupRenderElement) {
    throw _changed('one supported generated outer element');
  }
  held.addAll([
    e,
    e.component,
    e.parent,
    e.slot.target,
    _slotRender(e),
    ...frontier,
  ]);
  return {
    'kind': 'generated-opaque',
    'role': role,
    'nodes': [
      for (final r in frontier)
        if (r is MarkupRenderElement)
          {'nodeType': 1, 'namespaceURI': _kNamespace, 'localName': r.tag}
        else
          throw _changed('opaque normal node kind'),
    ],
  };
}

Map<String, Object?> _owned(
  Element e,
  String role,
  List<Map<String, Object?>> children,
) {
  final r = _render(e);
  return {
    'kind': 'owned',
    'role': role,
    'nodeType': 1,
    'namespaceURI': _kNamespace,
    'localName': r.tag,
    'attributes': {
      if (r.id != null) 'id': r.id,
      if (r.classes?.isNotEmpty ?? false) 'class': r.classes,
      if (r.styles?.isNotEmpty ?? false)
        'style': r.styles!.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('; '),
      ...?r.attributes,
    },
    'children': children,
  };
}

Map<String, Object?> _complete(dom.Element actual, Map<String, Object?> graph) {
  final attrs = {
    for (final a in actual.attributes.entries) a.key.toString(): a.value,
  };
  final expected = graph['attributes']! as Map;
  if (actual.namespaceUri != graph['namespaceURI'] ||
      actual.localName != graph['localName'] ||
      attrs.length != expected.length ||
      attrs.keys.any((k) => attrs[k] != expected[k])) {
    throw _changed('exact normal owned attributes');
  }
  final nodes = actual.nodes;
  final out = <Map<String, Object?>>[];
  var cursor = 0;
  void formatter() {
    while (cursor < nodes.length &&
        nodes[cursor] is dom.Text &&
        _ascii.hasMatch((nodes[cursor] as dom.Text).data)) {
      out.add({
        'kind': 'formatter-text',
        'nodeType': 3,
        'text': (nodes[cursor++] as dom.Text).data,
      });
    }
  }

  for (final child in graph['children']! as List<Map<String, Object?>>) {
    if (child['kind'] == 'owned-text') {
      if (cursor >= nodes.length ||
          nodes[cursor] is! dom.Text ||
          (nodes[cursor] as dom.Text).data != child['text']) {
        throw _changed('literal normal caption text');
      }
      out.add(child);
      cursor++;
    } else if (child['kind'] == 'generated-opaque') {
      final shapes = child['nodes']! as List<Map<String, Object?>>;
      for (final shape in shapes) {
        if (shape['nodeType'] != 3) formatter();
        if (cursor >= nodes.length || !_shape(nodes[cursor], shape)) {
          throw _changed('normal opaque frontier');
        }
        out.add({
          ...child,
          'nodes': [shape],
        });
        cursor++;
      }
    } else {
      formatter();
      if (cursor >= nodes.length || nodes[cursor] is! dom.Element) {
        throw _changed('normal owned child');
      }
      out.add(_complete(nodes[cursor++] as dom.Element, child));
    }
  }
  formatter();
  if (cursor != nodes.length) throw _changed('no undeclared normal nodes');
  return {...graph, 'children': out};
}

bool _shape(dom.Node n, Map<String, Object?> shape) =>
    n.nodeType == shape['nodeType'] &&
    (n is! dom.Element ||
        n.namespaceUri == shape['namespaceURI'] &&
            n.localName == shape['localName']);
bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);
StateError _changed(String reason) =>
    StateError('DOCS_SIZE_CURRENT_SOURCE_CHANGED: $reason');

String? requiredDocsSizeSsrKind(MatrixEntry entry) =>
    DocsSizeSsrSource.forEntry(entry) == null ? null : _kKind;
