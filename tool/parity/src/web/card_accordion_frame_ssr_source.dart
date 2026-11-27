import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/accordion/accordion_default_example.dart';
import 'package:docs_core/previews/examples/web/card/card_default_example.dart';
import 'package:docs_core/previews/examples/web/card/card_elevated_example.dart';
import 'package:docs_core/previews/examples/web/card/card_filled_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const _kRecipes = <(String, String), Type>{
  ('card', 'default'): CardDefaultExample,
  ('card', 'filled'): CardFilledExample,
  ('card', 'elevated'): CardElevatedExample,
  ('accordion', 'default'): AccordionDefaultExample,
};
final _formatter = RegExp(r'^[\t\n\f\r ]*$');

/// Actual surface frame only. Raw item data is kept distinct from generated
/// item renderers; no private item field or State is read or replayed.
class CardAccordionFrameSsrSource implements CurrentSsrBoxSource {
  CardAccordionFrameSsrSource._(this.entry, this.exampleType, this.source);
  static CardAccordionFrameSsrSource? forEntry(MatrixEntry entry) {
    if (!entry.probes.any(
      (p) => BoxObservationSourceSpec.cardAccordionSurfaceFrames.any(
        (s) => s.logicalUnitId == p.boxObservationSource?.logicalUnitId,
      ),
    )) {
      return null;
    }
    final source = entry.component == 'card'
        ? BoxObservationSourceSpec.cardSurfaceFrame
        : BoxObservationSourceSpec.accordionSurfaceFrame;
    final type = _kRecipes[(entry.component, entry.variant)];
    if (type == null ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource != source) {
      throw _changed('closed exact original recipe and frame tuple');
    }
    return CardAccordionFrameSsrSource._(entry, type, source);
  }

  final MatrixEntry entry;
  final Type exampleType;
  final BoxObservationSourceSpec source;
  Component? _registry;
  div? _capture;
  ({List<Object?> held, Map<String, Object?> raw})? _live;
  bool _completed = false;
  @override
  void recordBuild(Component result, div capture) {
    if (_registry != null) {
      throw _changed('one original registry build');
    }
    _registry = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    if (_live != null) {
      throw _changed('one current observation');
    }
    final before = _read(root);
    final after = _read(root);
    if (!_same(before.held, after.held) ||
        jsonEncode(before.raw) != jsonEncode(after.raw)) {
      throw _changed('held declaration and whole generated frontier');
    }
    _live = before;
    return const {'surfaceFrameAwaitingExactNormalBody': true};
  }

  /// Receives the exact body returned by the ordinary completed SSR response.
  /// Every formatter Text node becomes an exact owned literal, not a generic
  /// ASCII allowance in the browser. Opaque supplied Text remains opaque.
  Map<String, Object?> completeWithSerializedBody(String body) {
    final live = _live;
    if (live == null || _completed) {
      throw _changed('normal body completion');
    }
    final fragment = html.parseFragment(body);
    final captures = fragment
        .querySelectorAll('[data-parity-key]')
        .where((e) => e.attributes['data-parity-key'] == entry.key)
        .toList();
    if (captures.length != 1 || captures.single.children.length != 1) {
      throw _changed('whole normal capture and unique root');
    }
    final capture = captures.single;
    final raw = Map<String, Object?>.of(live.raw);
    final frontiers = raw['opaqueFrontiers']! as List<Map<String, Object?>>;
    final owner = capture.children.single;
    raw['generatedTree'] = _complete(
      owner,
      raw['generatedTree']! as Map<String, Object?>,
      frontiers,
    );
    raw['capture'] = _complete(capture, {
      ..._attributes(capture),
      'children': [live.raw['generatedTree']],
    }, frontiers);
    _completed = true;
    return {
      'kind': 'canonical-ssr-surface-frame-v1',
      'entryKey': entry.key,
      'source': source.toJson(),
      'currentRaw': raw,
      'completeRawSlotCount': raw['rawSlotCount'],
      'rawOrderFromPublicProducerLists': true,
    };
  }

  ({List<Object?> held, Map<String, Object?> raw}) _read(Element root) {
    final registry = _registry;
    final capture = _capture;
    if (registry == null ||
        capture == null ||
        registry.runtimeType != exampleType ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw _changed('original capture and exact public Example');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    final example = currentSsrIdentityElement(root, registry);
    if (!identical(example.parent, captureDom)) {
      throw _changed('registry edge');
    }
    final producer = soleCurrentSsrChild(example);
    final isCard = source == BoxObservationSourceSpec.cardSurfaceFrame;
    if (producer.component.runtimeType !=
        (isCard ? coui.Card : coui.Accordion)) {
      throw _changed('exact public surface producer');
    }
    final returned = soleCurrentSsrChild(producer);
    if (returned.component.runtimeType != div) {
      throw _changed('original noninteractive outer typed DIV');
    }
    final declared = returned.component as div;
    final owner = currentSsrGeneratedDiv(returned, declared);
    final held = <Object?>[
      captureElement,
      capture,
      captureDom,
      example,
      registry,
      producer,
      producer.component,
      returned,
      declared,
      owner,
    ];
    final raw = <Component?>[];
    final declarations = <Map<String, Object?>>[];
    final seats = <Element, int>{};
    final frontiers = <Map<String, Object?>>[];
    final usedRender = Set<MarkupRenderObject>.identity();
    var order = 0;

    List<Element> children(Element element, List<Component> inputs) {
      final actual = _children(element);
      if (actual.length != inputs.length ||
          (Set<Element>.identity()..addAll(actual)).length != actual.length ||
          List.generate(
            actual.length,
            (i) =>
                identical(actual[i].parent, element) &&
                identical(actual[i].component, inputs[i]),
          ).any((v) => !v)) {
        throw _changed('complete ordered current declaration occurrences');
      }
      final render = _markup(element);
      final expected = [for (final c in actual) ..._frontier(c)];
      final current = render.children.toList();
      if (expected.length != current.length ||
          List.generate(
            current.length,
            (i) =>
                identical(current[i], expected[i]) &&
                identical(current[i].parent, render),
          ).any((v) => !v)) {
        throw _changed('complete immediate current render frontier');
      }
      held.addAll([element, element.component, render, ...inputs, ...actual]);
      return actual;
    }

    Element generated(Element element) {
      var current = element;
      if (current.component.runtimeType == coui.Divider) {
        final divider = current.component as coui.Divider;
        held.addAll([current, divider]);
        final dom = soleCurrentSsrChild(current);
        final input = dom.component;
        if (divider.child != null ||
            input is! DomComponent ||
            input.tag != divider.tag ||
            input.tag != 'div' ||
            input.children == null ||
            input.children!.isNotEmpty) {
          throw _changed('exact public empty Divider branch');
        }
        children(dom, input.children!);
        return dom;
      }
      if (current.component.runtimeType == coui.Gap) {
        held.addAll([current, current.component]);
        current = soleCurrentSsrChild(current);
      }
      if (current.component.runtimeType != div) {
        throw _changed('typed generated layout DIV');
      }
      final input = current.component as div;
      final dom = currentSsrGeneratedDiv(current, input);
      children(dom, input.children);
      return dom;
    }

    void opaque(Element element, int declarationIndex, String authority) {
      if (seats.containsKey(element)) {
        throw _changed('disjoint occurrence seats');
      }
      final index = frontiers.length;
      seats[element] = index;
      held.addAll([element, element.component]);
      final nodes = <Map<String, Object?>>[];
      for (final render in _frontier(element)) {
        nodes.addAll(_opaque(render, usedRender, held));
      }
      frontiers.add({
        'index': index,
        'declarationIndex': declarationIndex,
        'authority': authority,
        'nodes': nodes,
        'frontierOrder': [for (final _ in nodes) order++],
      });
    }

    final top = children(owner, declared.children);
    if (isCard) {
      final input = producer.component as coui.Card;
      if (input.onTap != null) {
        throw _changed('noninteractive frame branch');
      }
      raw.addAll([
        input.child,
        input.media,
        input.header,
        input.body,
        input.footer,
        input.overlay,
      ]);
      held.addAll(raw);
      const names = ['child', 'media', 'header', 'body', 'footer', 'overlay'];
      for (var i = 0; i < raw.length; i++) {
        declarations.add({
          'index': i,
          'slot': names[i],
          'present': raw[i] != null,
          'sourceAliasOf': _alias(raw, i),
          'authority': 'public-declaration',
        });
      }
      var at = 0;
      void supplied(Element element, int i) {
        if (!identical(element.component, raw[i]) || raw[i] == null) {
          throw _changed('same exact supplied public Card slot');
        }
        opaque(element, i, 'same-public-Component-occurrence');
      }

      if (input.child != null) {
        if (top.length != 1) {
          throw _changed('custom public child wrapper');
        }
        final wrap = generated(top.single);
        final items = children(
          wrap,
          (wrap.component as DomComponent).children!,
        );
        if (items.length != 1) {
          throw _changed('single public custom child');
        }
        supplied(items.single, 0);
      } else {
        if (input.media != null) {
          if (at == top.length) {
            throw _changed('media wrapper');
          }
          final wrap = generated(top[at++]);
          final items = children(
            wrap,
            (wrap.component as DomComponent).children!,
          );
          if (items.length != (input.overlay == null ? 1 : 2)) {
            throw _changed('complete media and optional overlay');
          }
          supplied(items.first, 1);
          if (input.overlay != null) {
            final overlay = generated(items.last);
            final list = children(
              overlay,
              (overlay.component as DomComponent).children!,
            );
            if (list.length != 1) {
              throw _changed('overlay wrapper child');
            }
            supplied(list.single, 5);
          }
        }
        final content = [
          if (input.header != null) 2,
          if (input.body != null) 3,
          if (input.footer != null) 4,
        ];
        if (content.isNotEmpty) {
          if (at == top.length) {
            throw _changed('generated content wrapper');
          }
          final wrap = generated(top[at++]);
          final list = children(
            wrap,
            (wrap.component as DomComponent).children!,
          );
          var j = 0;
          for (var i = 0; i < content.length; i++) {
            if (i != 0) {
              if (j == list.length ||
                  list[j].component.runtimeType != coui.Gap) {
                throw _changed('exact owned gap position');
              }
              generated(list[j++]);
            }
            if (j == list.length) {
              throw _changed('complete content slots');
            }
            if (content[i] == 2) {
              final header = generated(list[j++]);
              final item = children(
                header,
                (header.component as DomComponent).children!,
              );
              if (item.length != 1) {
                throw _changed('header wrapper');
              }
              supplied(item.single, 2);
            } else {
              supplied(list[j++], content[i]);
            }
          }
          if (j != list.length) {
            throw _changed('extra content occurrence');
          }
        }
        if (at != top.length) {
          throw _changed('whole Card branch closure');
        }
      }
    } else {
      final input = producer.component as coui.Accordion;
      raw.addAll(input.items);
      held.addAll([input.items, ...input.items]);
      if (top.length != raw.length * 2) {
        throw _changed('whole item/separator roster');
      }
      for (var i = 0; i < raw.length; i++) {
        final item = raw[i];
        if (item.runtimeType != coui.AccordionItem) {
          throw _changed('public raw item data');
        }
        final data = item! as coui.AccordionItem;
        held.addAll([data.title, data.trigger, data.content, data.expanded]);
        declarations.add({
          'index': i,
          'present': true,
          'sourceAliasOf': _alias(raw, i),
          'titlePresent': data.title != null,
          'triggerPresent': data.trigger != null,
          'contentPresent': true,
          'authority': 'public-item-data-not-mounted-item',
        });
        if (identical(top[i * 2].component, item)) {
          throw _changed('generated renderer, not public item mount');
        }
        // Exact original public producer owns this complete generated list.
        // No private renderer.item field or callback is used as proof.
        opaque(top[i * 2], i, 'original-generated-item-position');
        generated(top[i * 2 + 1]);
      }
    }

    Map<String, Object?> tree(Element dom) {
      final input = dom.component as DomComponent;
      final list = children(dom, input.children ?? const []);
      final record = _attributesFromMarkup(_markup(dom));
      held.addAll([dom, dom.component, _markup(dom)]);
      return {
        ...record,
        'children': [
          for (final child in list)
            if (seats[child] case final i?)
              {'opaqueFrontier': i}
            else
              tree(generated(child)),
        ],
      };
    }

    return (
      held: held,
      raw: {
        'kind': 'current-surface-frame-raw-v1',
        'logicalUnitId': source.logicalUnitId,
        'rawSlotCount': raw.length,
        'rawDeclarations': declarations,
        'rawDeclarationMountAuthority': false,
        'opaqueFrontiers': frontiers,
        'generatedTree': tree(owner),
        'quantityBoundary': 'outer-surface-to-immediate-generated-content',
        'distributedSlotAndItemInsetsIncluded': false,
      },
    );
  }
}

StateError _changed(String reason) =>
    StateError('SURFACE_FRAME_SOURCE_CHANGED: $reason');
List<Element> _children(Element e) {
  final out = <Element>[];
  e.visitChildren(out.add);
  return out;
}

bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((v) => v);
int? _alias(List<Component?> raw, int i) => raw[i] == null
    ? null
    : [
        for (var j = 0; j < i; j++)
          if (identical(raw[i], raw[j])) j,
      ].firstOrNull;
MarkupRenderObject _markup(Element e) {
  if (e is! RenderObjectElement || e.renderObject is! MarkupRenderObject) {
    throw _changed('actual markup');
  }
  return e.renderObject as MarkupRenderObject;
}

List<MarkupRenderObject> _frontier(Element e) => e is RenderObjectElement
    ? [_markup(e)]
    : [for (final c in _children(e)) ..._frontier(c)];
Map<String, Object?> _attributes(dom.Element e) => {
  'nodeType': 1,
  'namespaceURI': e.namespaceUri,
  'localName': e.localName,
  'attributes': {
    for (final a in e.attributes.entries) a.key.toString(): a.value,
  },
};
Map<String, Object?> _attributesFromMarkup(MarkupRenderObject r) {
  final parsed = html.parseFragment(r.renderToHtml());
  if (r is! MarkupRenderElement || parsed.children.length != 1) {
    throw _changed('owned markup element');
  }
  return _attributes(parsed.children.single);
}

Map<String, Object?> _shape(dom.Node n) => n is dom.Element
    ? {'nodeType': 1, 'namespaceURI': n.namespaceUri, 'localName': n.localName}
    : n is dom.Text || n is dom.Comment
    ? {'nodeType': n.nodeType}
    : throw _changed('opaque node kind');
List<Map<String, Object?>> _opaque(
  MarkupRenderObject r,
  Set<MarkupRenderObject> used,
  List<Object?> held,
) {
  if (!used.add(r)) {
    throw _changed('disjoint actual render occurrences');
  }
  held.add(r);
  if (r is MarkupRenderFragment) {
    return [for (final c in r.children) ..._opaque(c, used, held)];
  }
  if (r is! MarkupRenderElement && r is! MarkupRenderText) {
    throw _changed('opaque render kind');
  }
  return [
    for (final n in html.parseFragment(r.renderToHtml()).nodes) _shape(n),
  ];
}

bool _equal(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) =>
    a.length == b.length &&
    a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);
Map<String, Object?> _complete(
  dom.Element actual,
  Map<String, Object?> expected,
  List<Map<String, Object?>> frontiers,
) {
  if (!_equal(
        _attributes(actual)['attributes']! as Map<dynamic, dynamic>,
        expected['attributes']! as Map<dynamic, dynamic>,
      ) ||
      actual.localName != expected['localName'] ||
      actual.namespaceUri != expected['namespaceURI']) {
    throw _changed('exact normal owned element');
  }
  final nodes = actual.nodes;
  var at = 0;
  final completed = <Map<String, Object?>>[];
  void formatting() {
    while (at < nodes.length &&
        nodes[at] is dom.Text &&
        _formatter.hasMatch((nodes[at] as dom.Text).data)) {
      completed.add({'ownedText': (nodes[at++] as dom.Text).data});
    }
  }

  for (final object in expected['children']! as List) {
    final child = object as Map<String, Object?>;
    if (child['opaqueFrontier'] case final int i) {
      for (final (ordinal, object)
          in (frontiers[i]['nodes']! as List).indexed) {
        final shape = object as Map<dynamic, dynamic>;
        if (shape['nodeType'] != 3) {
          formatting();
        }
        if (at == nodes.length || !_equal(_shape(nodes[at]), shape)) {
          throw _changed('normal complete opaque frontier');
        }
        completed.add({'opaqueNode': i, 'frontierNode': ordinal});
        at++;
      }
    } else {
      formatting();
      if (at == nodes.length || nodes[at] is! dom.Element) {
        throw _changed('normal owned child');
      }
      completed.add(_complete(nodes[at++] as dom.Element, child, frontiers));
    }
  }
  formatting();
  if (at != nodes.length) {
    throw _changed('extra normal owned content');
  }
  return {...expected, 'children': completed};
}

String? requiredCardAccordionFrameSsrKind(MatrixEntry entry) =>
    CardAccordionFrameSsrSource.forEntry(entry) == null
    ? null
    : 'canonical-ssr-surface-frame-v1';
