import 'dart:convert';

import 'package:docs_core/internal/preview/scenes.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show Styles, a, div, section, span;
import 'package:jaspr/server.dart';

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const kDocsCardRegistrySsrKind = 'canonical-ssr-documentation-frame-v1';
const _kNamespace = 'http://www.w3.org/1999/xhtml';
const _kSvgNamespace = 'http://www.w3.org/2000/svg';
final _formatter = RegExp(r'^[\t\n\f\r ]*$');

/// The scene is the object already resolved by the ordinary capture build.
/// The exact original scene and closed Anatomy declarations are required too.
String? requiredDocsCardRegistrySsrKind(MatrixEntry entry, DocsScene? scene) =>
    DocsCardRegistrySsrSource.forEntry(entry, scene) == null
    ? null
    : kDocsCardRegistrySsrKind;

/// Classification from the same original normal resolve, separate from the
/// optional quantity receipt; neither the tag nor the route is ownership proof.
Map<String, String>? docsCardRegistrySceneRoute(
  MatrixEntry entry,
  DocsScene? scene,
) {
  final claims = entry.probes.any(
    (p) =>
        p.boxObservationSource == BoxObservationSourceSpec.wholeDocCard ||
        p.boxObservationSource == BoxObservationSourceSpec.docsStage,
  );
  if (!claims) return null;
  DocsCardRegistrySsrSource.forEntry(entry, scene);
  return {
    'entryKey': entry.key,
    'sceneReference': scene!.reference,
    'sceneTag': scene.tag,
  };
}

/// Passive, tool-only observation of the original documentation factories.
/// It neither resolves a scene nor invokes a builder/body/selection callback.
class DocsCardRegistrySsrSource implements CurrentSsrBoxSource {
  DocsCardRegistrySsrSource._(this.entry, this.scene, this.source);

  static DocsCardRegistrySsrSource? forEntry(
    MatrixEntry entry,
    DocsScene? scene,
  ) {
    const sources = [
      BoxObservationSourceSpec.wholeDocCard,
      BoxObservationSourceSpec.docsStage,
    ];
    final claims = entry.probes.any(
      (p) => sources.any(
        (s) =>
            s.logicalUnitId == p.boxObservationSource?.logicalUnitId ||
            s.webAdapterId == p.boxObservationSource?.webAdapterId,
      ),
    );
    if (!claims) return null;
    if (scene == null ||
        scene.reference != entry.variant ||
        !entry.variant.startsWith(docsScenePrefix) ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root') {
      throw _changed('same original scene and one root declaration');
    }
    final source = scene.tag == 'Card'
        ? BoxObservationSourceSpec.wholeDocCard
        : BoxObservationSourceSpec.docsStage;
    if (entry.probes.single.boxObservationSource != source) {
      throw _changed('exact original documentation tuple');
    }
    if (scene.tag == 'Anatomy') {
      if (scene.selections.length != 1 ||
          scene.attributes.length != 1 ||
          scene.attributes['demo'] == null) {
        throw _changed('closed original Anatomy demo declaration');
      }
      return DocsCardRegistrySsrSource._(entry, scene, source);
    }
    if (!const {'Card', 'Preview', 'VariantRow'}.contains(scene.tag) ||
        scene.selections.length != 1 ||
        (scene.attributes['component'] == null &&
            scene.attributes['demo'] == null)) {
      throw _changed('closed original Card/Preview/VariantRow family');
    }
    if (scene.tag == 'Card' &&
        (scene.cardIndex != 0 ||
            scene.nativeCardAttributes == null ||
            scene.nativeCardBody == null ||
            scene.cardBody.isEmpty ||
            scene.attributes['value'] != null ||
            scene.attributes['badge'] != null)) {
      throw _changed('whole single preview Card and current four branches');
    }
    return DocsCardRegistrySsrSource._(entry, scene, source);
  }

  final MatrixEntry entry;
  final DocsScene scene;
  final BoxObservationSourceSpec source;
  Component? _result;
  div? _capture;
  _Read? _live;
  Element? _normalRoot;
  bool _completed = false;

  @override
  void recordBuild(Component result, div capture) {
    if (_result != null) throw _changed('one original registry build');
    _result = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    if (_live != null) throw _changed('one current mount observation');
    final before = _read(root);
    final after = _read(root);
    if (!_identicalList(before.held, after.held) ||
        jsonEncode(before.raw) != jsonEncode(after.raw)) {
      throw _changed('held own declarations and immediate opaque frontier');
    }
    _live = before;
    _normalRoot = root;
    return const {'docsCardRegistryAwaitingActualNormalBody': true};
  }

  /// Receives the actual completed response from ssr_render.dart. No collector
  /// renderToHtml, second SSR response, build or callback replay occurs here.
  Map<String, Object?> completeWithSerializedBody(String actualBody) {
    final live = _live;
    final root = _normalRoot;
    if (live == null || root == null || _completed) {
      throw _changed('one normal completion');
    }
    final completed = _read(root);
    if (!_identicalList(live.held, completed.held) ||
        jsonEncode(live.raw) != jsonEncode(completed.raw)) {
      throw _changed('same held original mount at normal response completion');
    }
    final parsed = html.parseFragment(actualBody);
    final captures = parsed
        .querySelectorAll('[data-parity-key]')
        .where(
          (n) => n.attributes['data-parity-key'] == entry.key,
        );
    if (captures.length != 1) throw _changed('unique normal capture');
    final raw = Map<String, Object?>.of(live.raw);
    final frontiers = raw['opaqueFrontiers']! as List<Map<String, Object?>>;
    raw['capture'] = _complete(
      captures.single,
      raw['capture']! as Map<String, Object?>,
      frontiers,
    );
    _completed = true;
    return {
      'kind': kDocsCardRegistrySsrKind,
      'entryKey': entry.key,
      'source': source.toJson(),
      'currentRaw': raw,
    };
  }

  _Read _read(Element root) {
    final capture = _capture;
    final result = _result;
    if (capture == null || result == null) {
      throw _changed('actual original build inputs');
    }
    final held = <Object?>[scene, result, capture];
    final frontiers = <Map<String, Object?>>[];
    final captureElement = _captureElement(root, capture);
    final reader = _Reader(held, frontiers);
    final captureNode = reader.owned(captureElement, 'div');
    if (capture.attributes?['data-parity-key'] != entry.key ||
        capture.children.length != 1) {
      throw _changed('original keyed capture and one scene host');
    }
    final hostElement = captureNode.children.single;
    final host = hostElement.component;
    if (host.runtimeType != div) throw _changed('typed docs scene host');
    final hostInput = host as div;
    if (hostInput.id != 'docs-shell' ||
        hostInput.classes != 'docs manual' ||
        !_mapEquals(hostInput.styles?.properties, {
          'width': '100%',
          'min-width': '0',
        }) ||
        !_mapEquals(hostInput.attributes, {
          'data-docs-scene': scene.reference,
        }) ||
        hostInput.children.length != 1) {
      throw _changed('original docsSceneHost forwarding');
    }
    final hostNode = reader.owned(hostElement, 'div');
    final inherited = hostNode.children.single;
    if (inherited.runtimeType != InheritedElement ||
        inherited.component is! InheritedComponent) {
      throw _changed('normal Content.wrapTheme element');
    }
    final inheritedInput = inherited.component as InheritedComponent;
    final contentElement = _sole(inherited);
    if (contentElement.runtimeType != StatelessElement ||
        !identical(contentElement.component, inheritedInput.child) ||
        contentElement.component is! StatelessComponent) {
      throw _changed('normal public Content with original registry child');
    }
    // The frozen docsSceneHost and public Content.wrapTheme/build bodies
    // supply this normal factory provenance. No transitive-package import,
    // private type name or private child field is used to reconstruct it.
    final fragmentElement = _sole(contentElement);
    final fragment = fragmentElement.component;
    if (fragment.runtimeType != Fragment ||
        fragmentElement is! RenderObjectElement ||
        fragmentElement.renderObject is! MarkupRenderFragment) {
      throw _changed('normal Content returned fragment');
    }
    final fragmentInput = fragment as Fragment;
    final fragmentChildren = _ordered(fragmentElement, fragmentInput.children);
    // The pinned Content body creates optional server Document.head followed
    // by exactly one public section. We never descend into the head adapter.
    if (fragmentChildren.length != 2 ||
        fragmentChildren.first.component is! Document) {
      throw _changed('original themed server Content branch');
    }
    final sectionElement = fragmentChildren.last;
    final sectionInput = sectionElement.component;
    if (sectionInput.runtimeType != section ||
        (sectionInput as section).classes != 'content' ||
        sectionInput.children.length != 1 ||
        !identical(sectionInput.children.single, result)) {
      throw _changed('original section.content child');
    }
    held.addAll([
      inherited,
      inheritedInput,
      inheritedInput.child,
      contentElement,
      contentElement.component,
      fragmentElement,
      fragment,
      fragmentInput.children,
      ...fragmentInput.children,
      ...fragmentChildren,
      fragmentElement.renderObject,
    ]);
    final sectionNode = reader.owned(sectionElement, 'section');
    final registryElement = sectionNode.children.single;
    if (!identical(registryElement.component, result)) {
      throw _changed('same original registry result occurrence');
    }
    late final Map<String, Object?> registryTree;
    if (scene.tag == 'Anatomy') {
      registryTree = _anatomy(reader, registryElement);
    } else if (scene.tag == 'Card') {
      registryTree = _card(reader, registryElement);
    } else {
      registryTree = _stage(
        reader,
        registryElement,
        compact: scene.tag == 'VariantRow',
      );
    }
    final sectionTree = reader.tree(sectionNode, [registryTree]);
    final hostTree = reader.tree(hostNode, [sectionTree]);
    final captureTree = reader.tree(captureNode, [hostTree]);
    return _Read(held, {
      'kind': 'current-documentation-frame-raw-v1',
      'family': scene.tag == 'Card' ? 'whole-card' : 'registry-scene',
      'sceneTag': scene.tag,
      'sceneReference': scene.reference,
      if (scene.tag == 'Anatomy') 'entryComponent': entry.component,
      // Data-only labels/body/selection inputs bind the original cohort. Their
      // container alias identities are not an inset quantity obligation.
      'originalSceneInput': scene.toJson(),
      'quantityBoundary': 'own-frame-only',
      'opaqueInteriorsRead': false,
      'opaqueFrontiers': frontiers,
      'capture': captureTree,
    });
  }

  /// Only normal public owned declarations are read. The demo and legend
  /// remain whole slot-target opaque frontiers. Runtime markers do not exist
  /// in this server mount and are never fabricated into its completed body.
  Map<String, Object?> _anatomy(_Reader reader, Element element) {
    final outer = reader.owned(element, 'div');
    final outerInput = element.component as div;
    if (outerInput.classes != 'docs-anatomy not-content' ||
        outerInput.id != null ||
        outerInput.styles != null ||
        outerInput.attributes != null ||
        outerInput.events != null ||
        outer.children.length != 2) {
      throw _changed('complete original Anatomy outer declaration');
    }
    final stageElement = outer.children.first;
    final stage = reader.owned(stageElement, 'div');
    final stageInput = stageElement.component as div;
    if (stageInput.classes != 'docs-stage docs-stage--240 docs-anatomy-stage' ||
        stageInput.id != null ||
        stageInput.styles != null ||
        !_mapEquals(stageInput.attributes, {
          'data-docs-anatomy': scene.anatomyParts.join(';'),
        }) ||
        stageInput.events != null ||
        stage.children.length != 1) {
      throw _changed('complete original Anatomy stage declaration');
    }
    final targetElement = stage.children.single;
    final target = reader.owned(targetElement, 'div');
    final targetInput = targetElement.component as div;
    if (targetInput.classes != 'docs-anatomy-target' ||
        targetInput.id != null ||
        targetInput.styles != null ||
        targetInput.attributes != null ||
        targetInput.events != null ||
        target.children.length != 1) {
      throw _changed('required original owned Anatomy target');
    }
    final targetTree = reader.tree(target, [
      reader.opaque(target, 0, 'preview'),
    ]);
    return reader.tree(outer, [
      reader.tree(stage, [targetTree]),
      reader.opaque(outer, 1, 'anatomy-legend'),
    ]);
  }

  Map<String, Object?> _stage(
    _Reader reader,
    Element element, {
    required bool compact,
  }) {
    final node = reader.owned(element, 'div');
    final input = element.component as div;
    final height = scene.attributes['height'];
    final heightClass = const {'140', '240', '340', 'hug'}.contains(height)
        ? ' docs-stage--$height'
        : '';
    if (input.classes !=
            'docs-stage${compact ? ' docs-stage--compact' : ''}'
                '$heightClass not-content' ||
        input.id != null ||
        input.styles != null ||
        input.attributes != null ||
        input.events != null ||
        node.children.length != 1) {
      throw _changed('complete original stage declaration');
    }
    return reader.tree(node, [reader.opaque(node, 0, 'preview')]);
  }

  Map<String, Object?> _card(_Reader reader, Element element) {
    final group = reader.owned(element, 'div');
    final groupInput = element.component as div;
    if (groupInput.classes != 'docs-cards not-content' ||
        !_mapEquals(groupInput.styles?.properties, {
          '--docs-cards-columns': '1',
        }) ||
        !_mapEquals(groupInput.attributes, {'data-docs-reveal': ''}) ||
        groupInput.id != null ||
        groupInput.events != null ||
        group.children.length != 1) {
      throw _changed('original standalone single Card group');
    }
    final attributes = scene.attributes;
    final href = attributes['href'];
    final card = reader.owned(
      group.children.single,
      href == null ? 'div' : 'a',
    );
    final tone = const {'do', 'dont'}.contains(attributes['tone'])
        ? ' docs-card--${attributes['tone']}'
        : '';
    final declared = _declaration(card.element.component);
    if (declared.classes !=
            'docs-card$tone docs-card--preview'
                '${href == null ? '' : ' site-box-link'}' ||
        declared.id != null ||
        declared.events?.isNotEmpty == true ||
        !_mapEquals(declared.styles?.properties, {'--i': '0'}) ||
        !_mapEquals(
          declared.attributes,
          href == null ? null : {'href': href},
        )) {
      throw _changed('actual Card own frame parameters and href branch');
    }
    final children = <Map<String, Object?>>[];
    var at = 0;
    Element next() {
      if (at == card.children.length) {
        throw _changed('missing original Card child');
      }
      return card.children[at++];
    }

    children.add(_stage(reader, next(), compact: false));
    if (attributes['eyebrow'] != null) {
      final eyebrow = reader.owned(next(), 'span');
      _plain(eyebrow, 'docs-card-eyebrow', 1);
      children.add(
        reader.tree(eyebrow, [reader.opaque(eyebrow, 0, 'eyebrow-label')]),
      );
    }
    if (attributes['title'] != null) {
      final head = reader.owned(next(), 'div');
      _plain(head, 'docs-card-head', 1);
      children.add(reader.tree(head, [reader.opaque(head, 0, 'title-label')]));
    }
    final body = reader.owned(next(), 'div');
    _plain(body, 'docs-card-body', 1);
    children.add(reader.tree(body, [reader.opaque(body, 0, 'markdown-body')]));
    if (href != null && attributes['more'] != null) {
      final more = reader.owned(next(), 'span');
      _plain(more, 'docs-card-more', 2);
      final arrow = reader.owned(more.children.last, 'span');
      final arrowInput = _declaration(arrow.element.component);
      if (arrowInput.classes != 'site-arrow' ||
          !_mapEquals(arrowInput.attributes, {'aria-hidden': 'true'}) ||
          arrowInput.id != null ||
          arrowInput.styles != null ||
          arrowInput.events != null ||
          arrow.children.length != 1) {
        throw _changed('original decorative arrow declaration');
      }
      children.add(
        reader.tree(more, [
          reader.opaque(more, 0, 'more-label'),
          reader.tree(arrow, [reader.opaque(arrow, 0, 'arrow-label')]),
        ]),
      );
    }
    if (at != card.children.length) throw _changed('extra original Card child');
    return reader.tree(group, [reader.tree(card, children)]);
  }
}

void _plain(_Owned node, String classes, int children) {
  final input = _declaration(node.element.component);
  if (input.classes != classes ||
      input.id != null ||
      input.styles != null ||
      input.attributes != null ||
      input.events != null ||
      node.children.length != children) {
    throw _changed('complete own $classes declaration');
  }
}

class _Read {
  _Read(this.held, this.raw);
  final List<Object?> held;
  final Map<String, Object?> raw;
}

typedef _Declaration = ({
  String tag,
  String? id,
  String? classes,
  Styles? styles,
  Map<String, String>? attributes,
  Map<String, EventCallback>? events,
  List<Component> children,
});

_Declaration _declaration(Component component) => switch (component) {
  final div d => (
    tag: 'div',
    id: d.id,
    classes: d.classes,
    styles: d.styles,
    attributes: d.attributes,
    events: d.events,
    children: d.children,
  ),
  final section d => (
    tag: 'section',
    id: d.id,
    classes: d.classes,
    styles: d.styles,
    attributes: d.attributes,
    events: d.events,
    children: d.children,
  ),
  final span d => (
    tag: 'span',
    id: d.id,
    classes: d.classes,
    styles: d.styles,
    attributes: d.attributes,
    events: d.events,
    children: d.children,
  ),
  final a d
      when d.target == null &&
          d.type == null &&
          d.download == null &&
          d.referrerPolicy == null &&
          d.onClick == null =>
    (
      tag: 'a',
      id: d.id,
      classes: d.classes,
      styles: d.styles,
      attributes: {...?d.attributes, 'href': d.href},
      events: {...?d.events},
      children: d.children,
    ),
  _ => throw _changed('closed typed own element'),
};

class _Owned {
  _Owned(this.element, this.dom, this.render, this.children, this.attributes);
  final Element element;
  final Element dom;
  final MarkupRenderElement render;
  final List<Element> children;
  final Map<String, String> attributes;
}

class _Reader {
  _Reader(this.held, this.frontiers);
  final List<Object?> held;
  final List<Map<String, Object?>> frontiers;
  final Set<MarkupRenderObject> _used = Set.identity();

  _Owned owned(Element element, String tag) {
    final input = _declaration(element.component);
    if (element.runtimeType != StatelessElement || input.tag != tag) {
      throw _changed('normal public typed $tag element');
    }
    final dom = _sole(element);
    if (dom.runtimeType != DomElement ||
        dom.component.runtimeType != DomComponent ||
        dom is! RenderObjectElement ||
        dom.renderObject is! MarkupRenderElement) {
      throw _changed('normal public DomComponent/DomElement factory');
    }
    final declaration = dom.component as DomComponent;
    final render = dom.renderObject as MarkupRenderElement;
    if (declaration.tag != tag ||
        declaration.id != input.id ||
        declaration.classes != input.classes ||
        !identical(declaration.styles, input.styles) ||
        !_mapEquals(declaration.attributes, input.attributes) ||
        !_mapEquals(declaration.events, input.events) ||
        !identical(declaration.children, input.children) ||
        render.tag != tag ||
        render.id != input.id ||
        render.classes != input.classes ||
        !_mapEquals(render.attributes, input.attributes) ||
        !_mapEquals(render.styles, input.styles?.properties)) {
      throw _changed('complete public $tag forwarding');
    }
    final children = _ordered(dom, input.children);
    final renderChildren = render.children.toList();
    final targets = [for (final child in children) child.slot.target];
    if (renderChildren.length != targets.length ||
        targets.indexed.any(
          (e) =>
              e.$2 == null ||
              !identical(e.$2!.renderObject, renderChildren[e.$1]) ||
              !identical(renderChildren[e.$1].parent, render),
        )) {
      throw _changed(
        'public slot targets cover the whole immediate render roster',
      );
    }
    // Keep stable parameter objects and copied property values.
    // Styles.properties
    // may allocate a new map, so its getter result is not an alias requirement.
    held.addAll([
      element,
      element.component,
      dom,
      declaration,
      render,
      input.styles,
      input.children,
      ...input.children,
      ...children,
      declaration.attributes,
      declaration.events,
      render.attributes,
      ...targets,
      ...renderChildren,
      for (final child in children) child.slot,
      for (final e
          in declaration.events?.entries ??
              <MapEntry<String, EventCallback>>[]) ...[e.key, e.value],
    ]);
    if (element.component case final a anchor) {
      held.add(anchor.attributes);
    } else {
      held.add(input.attributes);
      if (!identical(input.attributes, declaration.attributes) ||
          !identical(input.events, declaration.events)) {
        throw _changed('raw own map forwarding');
      }
    }
    final attributes = <String, String>{
      if (render.id != null) 'id': render.id!,
      if (render.classes?.isNotEmpty == true) 'class': render.classes!,
      if (render.styles?.isNotEmpty == true)
        'style': render.styles!.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('; '),
      ...?render.attributes,
    };
    return _Owned(element, dom, render, children, attributes);
  }

  Map<String, Object?> opaque(_Owned parent, int ordinal, String purpose) {
    final child = parent.children[ordinal];
    final target = child.slot.target;
    if (target == null || target.renderObject is! MarkupRenderObject) {
      throw _changed('actual public opaque slot target');
    }
    held.addAll([
      child,
      child.component,
      child.slot,
      target,
      target.renderObject,
    ]);
    // The public normal slot target supplies the first render object without
    // visiting any opaque Element children. Only transparent render fragments
    // are flattened; element attributes/text/interiors are never read.
    final roots = <MarkupRenderObject>[];
    void flatten(MarkupRenderObject render) {
      if (render is MarkupRenderFragment) {
        held.add(render);
        render.children.forEach(flatten);
      } else {
        roots.add(render);
      }
    }

    flatten(target.renderObject as MarkupRenderObject);
    final nodes = <Map<String, Object?>>[];
    for (final render in roots) {
      if (!_used.add(render)) throw _changed('disjoint supplied render roots');
      held.add(render);
      nodes.add(switch (render) {
        MarkupRenderElement(:final tag) => {
          'nodeType': 1,
          // Every opaque root here is inserted under a verified owned HTML
          // element. The pinned normal HTML parser enters SVG only for this
          // public root tag; no opaque attribute or descendant is inspected.
          'namespaceURI': tag == 'svg' ? _kSvgNamespace : _kNamespace,
          'localName': tag,
        },
        MarkupRenderText(rawHtml: false) => {'nodeType': 3},
        _ => throw _changed('unambiguous opaque top-level node kind'),
      });
    }
    final index = frontiers.length;
    frontiers.add({'index': index, 'purpose': purpose, 'nodes': nodes});
    return {'opaqueFrontier': index};
  }

  Map<String, Object?> tree(_Owned node, List<Map<String, Object?>> children) =>
      {
        'nodeType': 1,
        'namespaceURI': _kNamespace,
        'localName': node.render.tag,
        'attributes': node.attributes,
        'children': children,
      };
}

Element _captureElement(Element root, Component capture) {
  final matches = <Element>[];
  void visit(Element element) {
    if (identical(element.component, capture)) {
      matches.add(element);
      return; // All opaque documentation content is below this boundary.
    }
    element.visitChildren(visit);
  }

  visit(root);
  if (matches.length != 1) throw _changed('unique actual capture occurrence');
  return matches.single;
}

List<Element> _children(Element element) {
  final out = <Element>[];
  element.visitChildren(out.add);
  return out;
}

Element _sole(Element element) {
  final children = _children(element);
  if (children.length != 1) throw _changed('one normal generated edge');
  return children.single;
}

List<Element> _ordered(Element element, List<Component> inputs) {
  final children = _children(element);
  if (children.length != inputs.length ||
      (Set<Element>.identity()..addAll(children)).length != children.length ||
      children.indexed.any(
        (e) =>
            !identical(e.$2.parent, element) ||
            !identical(e.$2.component, inputs[e.$1]),
      )) {
    throw _changed('complete ordered original child roster');
  }
  return children;
}

bool _identicalList(List<Object?> a, List<Object?> b) =>
    a.length == b.length && a.indexed.every((e) => identical(e.$2, b[e.$1]));
bool _mapEquals(Map<Object?, Object?>? a, Map<Object?, Object?>? b) =>
    a == null || b == null
    ? a == null && b == null
    : a.length == b.length &&
          a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);
StateError _changed(String reason) =>
    StateError('DOCS_FRAME_SOURCE_CHANGED: $reason');

Map<String, Object?> _shape(html_dom.Node node) => node is html_dom.Element
    ? {
        'nodeType': 1,
        'namespaceURI': node.namespaceUri,
        'localName': node.localName,
      }
    : {'nodeType': node.nodeType};
Map<String, Object?> _complete(
  html_dom.Element actual,
  Map<String, Object?> expected,
  List<Map<String, Object?>> frontiers,
) {
  final attributes = <String, String>{
    for (final a in actual.attributes.entries) a.key.toString(): a.value,
  };
  if (actual.localName != expected['localName'] ||
      actual.namespaceUri != expected['namespaceURI'] ||
      !_mapEquals(attributes, expected['attributes']! as Map)) {
    throw _changed('exact actual normal own element');
  }
  var at = 0;
  final children = <Map<String, Object?>>[];
  void formatting() {
    while (at < actual.nodes.length &&
        actual.nodes[at] is html_dom.Text &&
        _formatter.hasMatch((actual.nodes[at] as html_dom.Text).data)) {
      children.add({'ownedText': (actual.nodes[at++] as html_dom.Text).data});
    }
  }

  for (final raw in expected['children']! as List) {
    final child = raw as Map<String, Object?>;
    if (child['opaqueFrontier'] case final int i) {
      final nodes = frontiers[i]['nodes']! as List<Map<String, Object?>>;
      for (final (j, shape) in nodes.indexed) {
        if (shape['nodeType'] != 3) formatting();
        if (at == actual.nodes.length ||
            !_mapEquals(_shape(actual.nodes[at]), shape)) {
          throw _changed('complete actual normal opaque frontier');
        }
        children.add({'opaqueNode': i, 'frontierNode': j});
        at++;
      }
    } else {
      formatting();
      if (at == actual.nodes.length || actual.nodes[at] is! html_dom.Element) {
        throw _changed('missing actual normal own child');
      }
      children.add(
        _complete(actual.nodes[at++] as html_dom.Element, child, frontiers),
      );
    }
  }
  formatting();
  if (at != actual.nodes.length) {
    throw _changed('extra actual normal own child');
  }
  return {...expected, 'children': children};
}
