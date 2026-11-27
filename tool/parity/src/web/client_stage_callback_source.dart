import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/stage_container/stage_container_default_example.dart';
import 'package:jaspr/client.dart';
import 'package:jaspr/dom.dart' show div;

import '../model/box_observation_source_spec.dart';
import 'client_box_source_protocol.dart';
import 'current_client_box_source.dart';

@JS('location.href')
external String get _harnessURL;

extension type _Exchange(JSObject _) implements JSObject {
  external JSAny? get request;
  external JSObject? get response;
  external set response(JSObject? value);
  external String? get error;
  external set error(String? value);
}

extension type _Event(JSObject _) implements JSObject {
  external JSAny? get target;
  external JSObject? get detail;
}

extension type _Reply._(JSObject _) implements JSObject {
  external factory _Reply({
    required JSObject receipt,
    required JSAny capture,
    required JSAny layoutRoot,
    required JSAny paddingOwner,
    required JSAny opaqueRoot,
    required JSFunction validateCurrentBinding,
  });
  external JSObject get receipt;
}

typedef _Current = ({
  DomRenderElement capture,
  DomRenderElement frame,
  DomRenderElement padding,
  DomRenderElement body,
  List<Object?> held,
  Map<String, Object?> parameters,
  Map<String, Object?> raw,
});

/// Reads only the current public Stage prefix and its opaque callback root.
/// The product's builder, State, measurement and resolvers are never invoked.
class ClientStageCallbackSource implements CurrentClientBoxSource {
  ClientStageCallbackSource._(this.descriptor);

  static ClientStageCallbackSource? fromConfig(Map<String, Object?> config) {
    final request = config['currentClientBoxSource'];
    if (request == null) return null;
    if (config['component'] != 'stage-container') return null;
    final expected = {
      'kind': kClientStageCallbackSourceKind,
      'entryKey': config['key'],
      'source': BoxObservationSourceSpec.stageCallbackContentInset.toJson(),
      'renderPhase': kClientBoxSourcePhase,
    };
    if (config['variant'] != 'default' ||
        config['scene'] != null ||
        config['key'] is! String ||
        config['key'] == '' ||
        jsonEncode(request) != jsonEncode(expected)) {
      throw StateError('CLIENT_STAGE_CONFIG_CHANGED');
    }
    return ClientStageCallbackSource._(Map.unmodifiable(expected));
  }

  final Map<String, Object?> descriptor;
  Component? _registry;
  div? _capture;
  int _generation = 0;
  bool _disposed = false;
  void Function()? _remove;

  @override
  void recordBuild(Component registryResult, div capture) {
    if (_disposed) throw StateError('CLIENT_STAGE_DISPOSED');
    _remove?.call();
    _remove = null;
    _generation++;
    _registry = registryResult;
    _capture = capture;
  }

  @override
  void arm(Element root, {required bool Function() isMounted}) {
    if (_disposed || !isMounted()) return;
    final generation = _generation;
    final capture = _capture;
    if (capture == null) throw StateError('CLIENT_STAGE_BUILD_NOT_RECORDED');
    final captureElement = _sole(root);
    if (!identical(captureElement.component, capture)) {
      throw StateError('CLIENT_STAGE_CAPTURE_CHANGED');
    }
    final node = _dom(captureElement, capture).render.node;
    _remove?.call();
    _Reply? cached;
    bool Function()? cachedValidation;
    JSAny? requestIdentity;
    late final JSFunction listener;
    void remove() =>
        node.removeEventListener(kClientStageCallbackSourceEvent, listener);
    listener = ((JSObject object) {
      final event = _Event(object);
      final detail = event.detail;
      if (detail == null) return;
      final exchange = _Exchange(detail);
      try {
        if (_disposed ||
            !isMounted() ||
            generation != _generation ||
            !identical(event.target, node) ||
            jsonEncode(exchange.request.dartify()) != jsonEncode(descriptor)) {
          throw StateError('CLIENT_STAGE_REQUEST_CHANGED');
        }
        if (cached != null) {
          if (!identical(requestIdentity, exchange.request)) {
            throw StateError('CLIENT_STAGE_REQUEST_REPLACED');
          }
          if (cachedValidation?.call() != true) {
            throw StateError('CLIENT_STAGE_HELD_BINDING_CHANGED');
          }
          exchange.response = cached;
          return;
        }
        final before = _readCurrent(root);
        final after = _readCurrent(root);
        if (!_same(before.held, after.held) ||
            jsonEncode(before.raw) != jsonEncode(after.raw) ||
            jsonEncode(before.parameters) != jsonEncode(after.parameters)) {
          throw StateError('CLIENT_STAGE_CHANGED_DURING_REQUEST');
        }
        JSObject? receiptIdentity;
        bool validate(JSObject observedReply) {
          try {
            if (_disposed ||
                !isMounted() ||
                generation != _generation ||
                !identical(observedReply, cached) ||
                !identical(cached?.receipt, receiptIdentity)) {
              return false;
            }
            final current = _readCurrent(root);
            return _same(before.held, current.held) &&
                jsonEncode(before.raw) == jsonEncode(current.raw) &&
                jsonEncode(before.parameters) == jsonEncode(current.parameters);
          } on Object {
            return false;
          }
        }

        final validator = validate.toJS;
        cachedValidation = () => cached != null && validate(cached!);
        final receipt = {
          ...descriptor,
          'currentRaw': before.raw,
          'completeRawSlotCount': 1,
          'rawOrderFromPublicProducerLists': true,
          'harnessURL': _harnessURL,
        };
        requestIdentity = exchange.request;
        receiptIdentity = receipt.jsify()! as JSObject;
        cached = _Reply(
          receipt: receiptIdentity,
          capture: before.capture.node,
          layoutRoot: before.frame.node,
          paddingOwner: before.padding.node,
          opaqueRoot: before.body.node,
          validateCurrentBinding: validator,
        );
        exchange.response = cached;
        // Initial guard and box sampler share one synchronous native task.
        // They must reuse this FIRST baseline, never rebind after legacy CSS.
        scheduleMicrotask(() {
          remove();
          if (identical(_remove, remove)) _remove = null;
        });
      } on Object catch (error) {
        exchange.error = '$error';
      }
    }).toJS;
    _remove = remove;
    node.addEventListener(kClientStageCallbackSourceEvent, listener);
  }

  _Current _readCurrent(Element root) {
    final capture = _capture;
    final registry = _registry;
    if (_disposed ||
        root.runtimeType != StatefulElement ||
        capture == null ||
        registry == null ||
        registry.runtimeType != StageContainerDefaultExample ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry) ||
        capture.attributes?['data-parity-key'] != descriptor['entryKey']) {
      throw StateError('CLIENT_STAGE_ORIGINAL_CAPTURE_CHANGED');
    }
    final captureElement = _sole(root);
    if (!identical(captureElement.component, capture)) {
      throw StateError('CLIENT_STAGE_CAPTURE_EDGE_CHANGED');
    }
    final captureDom = _dom(captureElement, capture);
    final example = _sole(captureDom.element);
    if (example.runtimeType != StatelessElement ||
        !identical(example.component, registry)) {
      throw StateError('CLIENT_STAGE_EXAMPLE_CHANGED');
    }
    final stage = _sole(example);
    if (stage.runtimeType != StatefulElement ||
        stage.component.runtimeType != coui.StageContainer) {
      throw StateError('CLIENT_STAGE_PUBLIC_PRODUCER_CHANGED');
    }
    final input = stage.component as coui.StageContainer;
    if (input.css != null ||
        input.classes != null ||
        input.id != null ||
        (input.userAttributes?.isNotEmpty ?? false) ||
        input.eventHandlers.isNotEmpty) {
      throw StateError('CLIENT_STAGE_ORIGINAL_FRAME_CHANGED');
    }
    final returned = _sole(stage);
    if (returned.component.runtimeType != div) {
      throw StateError('CLIENT_STAGE_OUTER_DIV_CHANGED');
    }
    final frameInput = returned.component as div;
    if (frameInput.children.length != 1 ||
        frameInput.children.single.runtimeType != div) {
      throw StateError('CLIENT_STAGE_COMPLETE_OWNED_PREFIX_CHANGED');
    }
    final frame = _dom(returned, frameInput);
    final innerInput = frameInput.children.single as div;
    final innerElement = _sole(frame.element);
    final padding = _dom(innerElement, innerInput);
    if (innerInput.children.length != 1 ||
        innerInput.children.single.runtimeType != div) {
      throw StateError('CLIENT_STAGE_CALLBACK_ROOT_CHANGED');
    }
    final bodyInput = innerInput.children.single as div;
    final bodyElement = _sole(padding.element);
    // Only the callback's public outer DIV frontier. Never read its attributes,
    // styles, text, children, childNodes or any descendant Element.
    final body = _dom(bodyElement, bodyInput, opaque: true);
    _nodes(captureDom.render, frame.render);
    _nodes(frame.render, padding.render);
    _nodes(padding.render, body.render);
    return (
      capture: captureDom.render,
      frame: frame.render,
      padding: padding.render,
      body: body.render,
      held: [
        root,
        captureElement,
        capture,
        capture.children,
        captureDom.element,
        captureDom.element.component,
        captureDom.render,
        captureDom.render.node,
        example,
        registry,
        stage,
        input,
        input.builder,
        returned,
        frameInput,
        frameInput.children,
        frame.element,
        frame.element.component,
        frame.render,
        frame.render.node,
        innerElement,
        innerInput,
        innerInput.children,
        padding.element,
        padding.element.component,
        padding.render,
        padding.render.node,
        bodyElement,
        bodyInput,
        body.element,
        body.element.component,
        body.render,
        body.render.node,
        ...captureDom.parametersHeld,
        ...frame.parametersHeld,
        ...padding.parametersHeld,
      ],
      parameters: {
        'capture': captureDom.parameterValues,
        'frame': frame.parameterValues,
        'paddingOwner': padding.parameterValues,
      },
      raw: {
        'kind': 'current-client-stage-callback-padding-v1',
        'quantityBoundary': 'original-stage-frame-to-opaque-callback-content',
        'callbackReexecuted': false,
        'bodyInteriorIsSourceAuthority': false,
        'capture': _owned(captureDom.render),
        'frame': _owned(frame.render),
        'paddingOwner': _owned(padding.render),
        'opaqueRoot': {
          'namespaceURI': body.render.node.namespaceURI,
          'localName': body.render.node.localName,
        },
        'ownedNodeOrder': ['capture', 'frame', 'paddingOwner', 'opaqueRoot'],
      },
    );
  }

  @override
  void dispose() {
    _remove?.call();
    _remove = null;
    _disposed = true;
    _generation++;
    _registry = null;
    _capture = null;
  }
}

Element _sole(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  if (children.length != 1 || !identical(children.single.parent, parent)) {
    throw StateError('CLIENT_STAGE_COMPLETE_CURRENT_EDGE_CHANGED');
  }
  return children.single;
}

({
  Element element,
  DomRenderElement render,
  List<Object?> parametersHeld,
  Map<String, Object?> parameterValues,
})
_dom(Element declared, div component, {bool opaque = false}) {
  if (declared.runtimeType != StatelessElement ||
      !identical(declared.component, component)) {
    throw StateError('CLIENT_STAGE_DECLARED_DIV_CHANGED');
  }
  final element = _sole(declared);
  final current = element.component;
  if (element.runtimeType != DomElement ||
      current.runtimeType != DomComponent ||
      current is! DomComponent ||
      current.tag != 'div' ||
      element is! RenderObjectElement ||
      element.renderObject.runtimeType != DomRenderElement ||
      element.renderObject is! DomRenderElement) {
    throw StateError('CLIENT_STAGE_NORMAL_DOM_DIV_CHANGED');
  }
  final render = element.renderObject as DomRenderElement;
  if (!render.node.isConnected ||
      render.node.namespaceURI != 'http://www.w3.org/1999/xhtml' ||
      render.node.localName != 'div') {
    throw StateError('CLIENT_STAGE_CURRENT_DOM_CHANGED');
  }
  if (opaque) {
    return (
      element: element,
      render: render,
      parametersHeld: const [],
      parameterValues: const {},
    );
  }
  if (current.id != component.id ||
      current.classes != component.classes ||
      !identical(current.styles, component.styles) ||
      !identical(current.attributes, component.attributes) ||
      !identical(current.events, component.events) ||
      !identical(current.children, component.children)) {
    throw StateError('CLIENT_STAGE_NORMAL_DECLARATION_FORWARDING_CHANGED');
  }
  final children = <Element>[];
  element.visitChildren(children.add);
  if (children.length != component.children.length ||
      List.generate(children.length, (i) => i).any(
        (i) =>
            !identical(children[i].parent, element) ||
            !identical(children[i].component, component.children[i]),
      )) {
    throw StateError('CLIENT_STAGE_COMPLETE_OWNED_DECLARATION_CHANGED');
  }
  return (
    element: element,
    render: render,
    parametersHeld: [
      component.id,
      component.classes,
      component.styles,
      component.attributes,
      component.events,
      component.children,
      ...component.children,
      ...?component.events?.values,
      current.id,
      current.classes,
      current.styles,
      current.attributes,
      current.events,
      current.children,
      ...?current.children,
      ...?current.events?.values,
      ...children,
    ],
    parameterValues: {
      'id': component.id,
      'classes': component.classes,
      'attributes': component.attributes == null
          ? null
          : Map.of(component.attributes!),
      'styles': component.styles == null
          ? null
          : Map.of(component.styles!.properties),
      'eventKeys': component.events?.keys.toList(),
      'domId': current.id,
      'domClasses': current.classes,
      'domAttributes': current.attributes == null
          ? null
          : Map.of(current.attributes!),
      'domStyles': current.styles == null
          ? null
          : Map.of(current.styles!.properties),
      'domEventKeys': current.events?.keys.toList(),
    },
  );
}

void _nodes(DomRenderElement parent, DomRenderElement child) {
  if (!identical(child.parent, parent) ||
      !identical(child.node.parentNode, parent.node) ||
      parent.node.childNodes.length != 1 ||
      !identical(parent.node.childNodes.item(0), child.node)) {
    throw StateError('CLIENT_STAGE_COMPLETE_OWNED_DOM_EDGE_CHANGED');
  }
}

Map<String, Object?> _owned(DomRenderElement render) => {
  'namespaceURI': render.node.namespaceURI,
  'localName': render.node.localName,
  'attributes': {
    for (var i = 0; i < render.node.attributes.length; i++)
      render.node.attributes.item(i)!.name: render.node.attributes
          .item(i)!
          .value,
  },
};

bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => i).every((i) => identical(a[i], b[i]));
