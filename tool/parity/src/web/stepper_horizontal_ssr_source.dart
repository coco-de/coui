// Passive normal Stepper root; generated column interiors remain opaque.
import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/stepper/stepper_default_example.dart';
import 'package:docs_core/previews/examples/web/stepper/stepper_disabled_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const _kNamespace = 'http://www.w3.org/1999/xhtml';
final _ascii = RegExp(r'^[\t\n\f\r ]*$');

class StepperHorizontalSsrSource implements CurrentSsrBoxSource {
  StepperHorizontalSsrSource._(this.entry);
  static StepperHorizontalSsrSource? forEntry(MatrixEntry entry) {
    const source = BoxObservationSourceSpec.stepperHorizontalHost;
    if (!entry.probes.any(
      (p) => p.boxObservationSource?.logicalUnitId == source.logicalUnitId,
    )) {
      return null;
    }
    if (entry.component != 'stepper' ||
        !const ['default', 'disabled'].contains(entry.variant) ||
        !const ['light', 'dark'].contains(entry.theme.name) ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource != source) {
      throw _changed('closed original horizontal Stepper recipes/full tuple');
    }
    return StepperHorizontalSsrSource._(entry);
  }

  final MatrixEntry entry;
  Component? _registry;
  div? _capture;
  Element? _root;
  ({List<Object?> held, Map<String, Object?> raw})? _live;
  bool _completed = false;

  @override
  void recordBuild(Component result, div capture) {
    if (_registry != null || _capture != null) {
      throw _changed('repeated original build');
    }
    _registry = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    if (_live != null || _completed) {
      throw _changed('repeated observation');
    }
    final before = _read(root);
    final after = _read(root);
    if (!_same(before.held, after.held) ||
        jsonEncode(before.raw) != jsonEncode(after.raw)) {
      throw _changed(
        'current normal public root and complete generated roster',
      );
    }
    _root = root;
    _live = before;
    return const {'stepperAwaitingExactNormalSerializedBody': true};
  }

  Map<String, Object?> completeWithSerializedBody(String body) {
    final live = _live;
    final root = _root;
    if (live == null || root == null || _completed) {
      throw _changed('one same normal body completion');
    }
    final current = _read(root);
    if (!_same(current.held, live.held) ||
        jsonEncode(current.raw) != jsonEncode(live.raw)) {
      throw _changed('current identities through normal serialization');
    }
    final fragment = html.parseFragment(body);
    final captures = fragment.querySelectorAll('[data-parity-key]').where((e) {
      if (e.attributes['data-parity-key'] != entry.key) {
        return false;
      }
      for (var p = e.parent; p != null; p = p.parent) {
        if (p.attributes['data-parity-key'] == entry.key) {
          return false;
        }
      }
      return true;
    }).toList();
    if (captures.length != 1) {
      throw _changed('one original outer capture');
    }
    final capture = captures.single;
    final raw = Map<String, Object?>.of(live.raw);
    final captureNodes = <Map<String, Object?>>[];
    dom.Element? actualRoot;
    for (final node in capture.nodes) {
      if (node is dom.Text && _ascii.hasMatch(node.data)) {
        captureNodes.add({'formatterText': node.data});
      } else if (node is dom.Element && actualRoot == null) {
        actualRoot = node;
        captureNodes.add(const {'frame': true});
      } else {
        throw _changed('complete normal capture nodes');
      }
    }
    if (capture.namespaceUri != _kNamespace ||
        capture.localName != 'div' ||
        actualRoot == null ||
        !_elementMatches(actualRoot, raw['frame']! as Map<String, Object?>)) {
      throw _changed('exact original normal root attributes');
    }
    final frameNodes = <Map<String, Object?>>[];
    var index = 0;
    final columns = raw['generatedColumns']! as List<Map<String, Object?>>;
    for (final node in actualRoot.nodes) {
      if (node is dom.Text && _ascii.hasMatch(node.data)) {
        frameNodes.add({'formatterText': node.data});
      } else if (node is dom.Element &&
          index < columns.length &&
          node.namespaceUri == _kNamespace &&
          node.localName == 'div') {
        frameNodes.add({'generatedColumn': index++});
      } else {
        throw _changed(
          'complete generated normal columns and exact formatter data',
        );
      }
    }
    if (index != columns.length) {
      throw _changed('every generated column occurrence');
    }
    raw.addAll({
      'capture': _attributes(capture),
      'captureNodes': captureNodes,
      'frameNodes': frameNodes,
    });
    _completed = true;
    return {
      'kind': 'canonical-ssr-stepper-horizontal-v1',
      'entryKey': entry.key,
      'source': BoxObservationSourceSpec.stepperHorizontalHost.toJson(),
      'currentRaw': raw,
      'completeRawSlotCount': columns.length,
      'rawOrderFromPublicProducerLists': true,
    };
  }

  ({List<Object?> held, Map<String, Object?> raw}) _read(Element root) {
    final original = _registry;
    final capture = _capture;
    final expected = entry.variant == 'default'
        ? StepperDefaultExample
        : StepperDisabledExample;
    if (original == null ||
        original.runtimeType != expected ||
        capture == null ||
        capture.children.length != 1 ||
        !identical(capture.children.single, original) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw _changed('closed original registry and capture occurrence');
    }
    final captureDom = currentSsrGeneratedDiv(
      currentSsrIdentityElement(root, capture),
      capture,
    );
    final example = currentSsrIdentityElement(root, original);
    if (!identical(example.parent, captureDom)) {
      throw _changed('original registry parent');
    }
    final product = soleCurrentSsrChild(example);
    if (product.component.runtimeType != coui.Stepper) {
      throw _changed('exact public Stepper');
    }
    final input = product.component as coui.Stepper;
    if (input.steps.length != 3 ||
        input.orientation != coui.CoreStepperOrientation.horizontal ||
        input.id != null ||
        input.classes != null ||
        input.css != null ||
        (input.userAttributes?.isNotEmpty ?? false) ||
        input.eventHandlers.isNotEmpty) {
      throw _changed('original horizontal public root inputs');
    }
    final returned = soleCurrentSsrChild(product);
    if (returned.component.runtimeType != div) {
      throw _changed('normal generated root DIV');
    }
    final frameInput = returned.component as div;
    final frame = currentSsrGeneratedDiv(returned, frameInput);
    final children = <Element>[];
    frame.visitChildren(children.add);
    final render = _ownedRender(frame);
    final actual = render.children.toList();
    if (input.steps.length != frameInput.children.length ||
        children.length != frameInput.children.length ||
        actual.length != children.length) {
      throw _changed('complete public data and generated top frontier');
    }
    final held = <Object?>[
      root,
      original,
      capture,
      captureDom,
      example,
      product,
      input,
      input.steps,
      input.onStepChanged,
      input.currentStep,
      input.enabled,
      input.orientation,
      input.stepperStyle,
      returned,
      frameInput,
      frameInput.children,
      frame,
      render,
      render.id,
      render.classes,
      render.styles,
      render.attributes,
    ];
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (frameInput.children[i].runtimeType != div ||
          !identical(child.component, frameInput.children[i]) ||
          !identical(child.parent, frame)) {
        throw _changed('ordered generated typed column edges');
      }
      // The public div's normal sole DOM hop is the opaque boundary. Do not
      // inspect its attributes, styles, text, children or serialize it.
      final boundary = soleCurrentSsrChild(child);
      final foreign = _markup(boundary);
      if (foreign is! MarkupRenderElement ||
          foreign.tag != 'div' ||
          !identical(actual[i], foreign) ||
          !identical(foreign.parent, render)) {
        throw _changed('complete direct opaque render frontier');
      }
      held.addAll([
        input.steps[i],
        input.steps[i].label,
        input.steps[i].description,
        frameInput.children[i],
        child,
        boundary,
        foreign,
      ]);
    }
    return (
      held: held,
      raw: {
        'kind': 'current-stepper-horizontal-generated-root-v1',
        'quantityBoundary':
            'complete-horizontal-operation-to-generated-columns',
        'buildOrResolverReexecuted': false,
        'columnInteriorsAreSourceAuthority': false,
        'frame': _owned(frame),
        'rawStepItems': [
          for (var i = 0; i < input.steps.length; i++)
            {
              'index': i,
              'label': input.steps[i].label,
              'description': input.steps[i].description,
              'descriptionMountedClaim': false,
              'aliasesEarlier': [
                for (var j = 0; j < i; j++)
                  if (identical(input.steps[j], input.steps[i])) j,
              ],
            },
        ],
        'generatedColumns': [
          for (var i = 0; i < children.length; i++)
            {
              'index': i,
              'present': true,
              'generatedNotSupplied': true,
              'opaque': true,
              'nodeType': 1,
              'namespaceURI': _kNamespace,
              'localName': 'div',
            },
        ],
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
    StateError('STEPPER_HORIZONTAL_SOURCE_CHANGED: $detail');
String? requiredStepperHorizontalSsrKind(MatrixEntry entry) =>
    StepperHorizontalSsrSource.forEntry(entry) == null
    ? null
    : 'canonical-ssr-stepper-horizontal-v1';
