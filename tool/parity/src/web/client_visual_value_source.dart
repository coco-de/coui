import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/number_ticker/number_ticker_default_example.dart';
import 'package:jaspr/client.dart';
import 'package:jaspr/dom.dart' show div, span;

import '../model/box_observation_source_spec.dart';
import 'client_box_source_protocol.dart';
import 'visual_value_web_raw_source.dart';

@JS('location.href')
external String get _harnessURL;

extension type _Exchange(JSObject _) implements JSObject {
  external JSAny? get request;
  external JSObject? get response;
  external set response(JSObject? value);
  external String? get error;
  external set error(String? value);
}

extension type _RequestEvent(JSObject _) implements JSObject {
  external JSAny? get target;
  external JSObject? get detail;
}

extension type _Reply._(JSObject _) implements JSObject {
  external factory _Reply({
    required JSObject receipt,
    required JSAny capture,
    required JSAny layoutRoot,
    required JSArray<JSAny> nodes,
  });
}

typedef _Mounted = ({
  DomRenderElement capture,
  DomRenderElement owner,
  List<Element> elements,
  List<Component> components,
  List<RenderObject> renderObjects,
  List<JSAny> nodes,
  VisualValueWebRawSource raw,
  Map<String, Object?> tree,
});

/// A one-shot, read-only observer owned solely by the parity client harness.
/// It retains original build objects, never a product State or a new render.
class ClientVisualValueSource {
  ClientVisualValueSource._(this.descriptor);

  static ClientVisualValueSource? fromConfig(Map<String, Object?> config) {
    final value = config['currentClientBoxSource'];
    if (value == null) return null;
    final expected = {
      'kind': kClientBoxSourceKind,
      'entryKey': config['key'],
      'source': BoxObservationSourceSpec.numberTickerTextLayoutHost.toJson(),
      'renderPhase': kClientBoxSourcePhase,
    };
    if (config['component'] != 'number-ticker' ||
        config['variant'] != 'default' ||
        config['scene'] != null ||
        config['key'] is! String ||
        config['key'] == '' ||
        !_sameJson(value, expected)) {
      throw StateError('CLIENT_BOX_SOURCE_CONFIG_CHANGED');
    }
    return ClientVisualValueSource._(Map.unmodifiable(expected));
  }

  final Map<String, Object?> descriptor;
  Component? _registryResult;
  div? _capture;
  int _generation = 0;
  int? _armedGeneration;
  bool _disposed = false;
  void Function()? _removeListener;

  /// Called once per actual harness build, before framework child inflation.
  void recordBuild(Component registryResult, div capture) {
    if (_disposed) throw StateError('CLIENT_BOX_SOURCE_DISPOSED');
    _removeListener?.call();
    _removeListener = null;
    _generation++;
    _registryResult = registryResult;
    _capture = capture;
  }

  /// Called by the harness's public postframe callback, not during build.
  void arm(Element root, {required bool Function() isMounted}) {
    if (_disposed || !isMounted()) return;
    final generation = _generation;
    if (_armedGeneration == generation) {
      throw StateError('CLIENT_BOX_GENERATION_ALREADY_ARMED');
    }
    final capture = _capture;
    if (capture == null) throw StateError('CLIENT_BOX_BUILD_NOT_RECORDED');
    final captureDom = _single(_identity(root, capture));
    _declared(captureDom, 'div', capture.children);
    final node = _elementRender(captureDom).node;
    _removeListener?.call();
    late final JSFunction listener;
    void remove() {
      node.removeEventListener(kClientBoxSourceEvent, listener);
    }

    listener = ((JSObject object) {
      // Consume first, including invalid requests. dispatchEvent does not
      // provide exception transport, so failures are explicit in the exchange.
      remove();
      _removeListener = null;
      final event = _RequestEvent(object);
      final detail = event.detail;
      if (detail == null) return;
      final exchange = _Exchange(detail);
      try {
        if (_disposed ||
            !isMounted() ||
            generation != _generation ||
            !identical(event.target, node) ||
            !_sameJson(exchange.request.dartify(), descriptor)) {
          throw StateError('CLIENT_BOX_SOURCE_REQUEST_CHANGED');
        }
        final before = _readCurrent(root);
        if (!identical(before.capture.node, node)) {
          throw StateError('CLIENT_BOX_CAPTURE_REPLACED');
        }
        final markup = node.outerHTML;
        before.raw.validateExistingCurrentBinding();
        final receipt = {
          ...descriptor,
          'currentRaw': {
            ...before.raw.currentDomContract,
            'generatedTree': before.tree,
          },
          'completeRawSlotCount': before.raw.rawSlots.length,
          'rawOrderFromPublicProducerLists': true,
          'harnessURL': _harnessURL,
        };
        final after = _readCurrent(root);
        if (!_sameIdentity(before.elements, after.elements) ||
            !_sameIdentity(before.components, after.components) ||
            !_sameIdentity(before.renderObjects, after.renderObjects) ||
            !_sameIdentity(before.nodes, after.nodes) ||
            node.outerHTML != markup) {
          throw StateError('CLIENT_BOX_OBSERVER_MUTATED_DOM');
        }
        exchange.response = _Reply(
          receipt: receipt.jsify()! as JSObject,
          capture: node,
          layoutRoot: before.owner.node,
          nodes: before.nodes.toJS,
        );
      } on Object catch (error) {
        exchange.error = '$error';
      }
    }).toJS;
    _armedGeneration = generation;
    _removeListener = remove;
    node.addEventListener(kClientBoxSourceEvent, listener);
  }

  void dispose() {
    _removeListener?.call();
    _removeListener = null;
    _disposed = true;
    _generation++;
    _registryResult = null;
    _capture = null;
  }

  _Mounted _readCurrent(Element root) {
    final capture = _capture;
    final registry = _registryResult;
    if (_disposed ||
        capture == null ||
        registry == null ||
        registry.runtimeType != NumberTickerDefaultExample ||
        capture.attributes?['data-parity-key'] != descriptor['entryKey'] ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry)) {
      throw StateError('CLIENT_BOX_CANONICAL_BUILD_CHANGED');
    }
    final captureElement = _identity(root, capture);
    final captureDom = _single(captureElement);
    _declared(captureDom, 'div', capture.children);
    final registryElement = _identity(root, registry);
    if (!identical(registryElement.parent, captureDom)) {
      throw StateError('CLIENT_BOX_REGISTRY_EDGE_CHANGED');
    }
    final producer = _single(registryElement);
    final raw = bindVisualValueWebRawSource(
      producer: producer.component,
      source: BoxObservationSourceSpec.numberTickerTextLayoutHost,
    );
    final generated = _single(producer);
    if (generated.component.runtimeType != span) {
      throw StateError('CLIENT_BOX_GENERATED_SPAN_CHANGED');
    }
    final declared = generated.component as span;
    if (declared.children.length != 1 ||
        declared.children.single.runtimeType != coui.Text) {
      throw StateError('CLIENT_BOX_GENERATED_TEXT_CHANGED');
    }
    final owner = _single(generated);
    _declared(owner, 'span', declared.children);
    final text = _single(owner);
    final textDom = _single(text);
    final component = textDom.component;
    if (component is! DomComponent ||
        component.children?.length != 1 ||
        component.children!.single.runtimeType != Text) {
      throw StateError('CLIENT_BOX_PLAIN_TEXT_DOM_CHANGED');
    }
    _declared(textDom, 'span', component.children!);
    final textLeaf = _single(textDom);
    if (textLeaf is! RenderObjectElement ||
        textLeaf.renderObject is! DomRenderText) {
      throw StateError('CLIENT_BOX_TEXT_RENDER_OBJECT_CHANGED');
    }
    final captureRender = _elementRender(captureDom);
    final ownerRender = _elementRender(owner);
    final textRender = _elementRender(textDom);
    final leafRender = textLeaf.renderObject as DomRenderText;
    _exactNodes(captureRender, [ownerRender.node]);
    _exactNodes(ownerRender, [textRender.node]);
    _exactNodes(textRender, [leafRender.node]);
    if (!leafRender.node.isConnected || leafRender.node.nodeType != 3) {
      throw StateError('CLIENT_BOX_TEXT_NODE_CHANGED');
    }
    return (
      capture: captureRender,
      owner: ownerRender,
      elements: [
        captureElement,
        captureDom,
        registryElement,
        producer,
        generated,
        owner,
        text,
        textDom,
        textLeaf,
      ],
      components: [
        capture,
        captureDom.component,
        registry,
        producer.component,
        generated.component,
        owner.component,
        text.component,
        textDom.component,
        textLeaf.component,
      ],
      renderObjects: [captureRender, ownerRender, textRender, leafRender],
      nodes: [
        captureRender.node,
        ownerRender.node,
        textRender.node,
        leafRender.node,
      ],
      raw: raw,
      tree: {
        'namespaceURI': ownerRender.node.namespaceURI,
        'localName': ownerRender.node.localName,
        'nodeKinds': [textRender.node.nodeType],
        'children': [
          {
            'namespaceURI': textRender.node.namespaceURI,
            'localName': textRender.node.localName,
            'nodeKinds': [leafRender.node.nodeType],
            'children': <Map<String, Object?>>[],
          },
        ],
      },
    );
  }
}

bool _sameIdentity(List<Object> a, List<Object> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);

bool _sameJson(Object? a, Object? b) {
  Object? ordered(Object? value) {
    if (value is Map<Object?, Object?>) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: ordered(value[key])};
    }
    if (value is List) return value.map(ordered).toList();
    return value;
  }

  return jsonEncode(ordered(a)) == jsonEncode(ordered(b));
}

Element _single(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  if (children.length != 1) {
    throw StateError('CLIENT_BOX_CURRENT_CHILD_COUNT_CHANGED');
  }
  return children.single;
}

Element _identity(Element root, Component component) {
  final matches = <Element>[];
  void visit(Element element) {
    if (identical(element.component, component)) matches.add(element);
    element.visitChildren(visit);
  }

  visit(root);
  if (matches.length != 1) {
    throw StateError('CLIENT_BOX_CURRENT_IDENTITY_NOT_UNIQUE');
  }
  return matches.single;
}

void _declared(Element element, String tag, List<Component> declared) {
  final component = element.component;
  final actual = <Element>[];
  element.visitChildren(actual.add);
  if (component is! DomComponent ||
      component.tag != tag ||
      component.children?.length != declared.length ||
      actual.length != declared.length ||
      (Set<Component>.identity()..addAll(declared)).length != declared.length) {
    throw StateError('CLIENT_BOX_DECLARATION_CHANGED');
  }
  for (var i = 0; i < declared.length; i++) {
    if (!identical(component.children![i], declared[i]) ||
        !identical(actual[i].component, declared[i]) ||
        !identical(actual[i].parent, element)) {
      throw StateError('CLIENT_BOX_GENERATED_IDENTITY_CHANGED');
    }
  }
}

DomRenderElement _elementRender(Element element) {
  if (element is! RenderObjectElement ||
      element.renderObject is! DomRenderElement) {
    throw StateError('CLIENT_BOX_CURRENT_RENDER_OBJECT_REQUIRED');
  }
  final render = element.renderObject as DomRenderElement;
  final component = element.component as DomComponent;
  if (!render.node.isConnected ||
      render.node.namespaceURI != 'http://www.w3.org/1999/xhtml' ||
      render.node.localName != component.tag) {
    throw StateError('CLIENT_BOX_CURRENT_DOM_REQUIRED');
  }
  return render;
}

void _exactNodes(DomRenderElement render, List<JSAny> expected) {
  final nodes = render.node.childNodes;
  if (nodes.length != expected.length) {
    throw StateError('CLIENT_BOX_EXTRA_GENERATED_NODE');
  }
  for (var i = 0; i < expected.length; i++) {
    final node = nodes.item(i)!;
    if (!identical(node, expected[i]) ||
        !identical(node.parentNode, render.node)) {
      throw StateError('CLIENT_BOX_GENERATED_NODE_IDENTITY_CHANGED');
    }
  }
}
