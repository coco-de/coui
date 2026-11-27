// Records the original registry scope and complete public allocation slots.
import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/drag/drag_board_example.dart';
import 'package:docs_core/previews/examples/web/drag/drag_default_example.dart';
import 'package:docs_core/previews/examples/web/drag/drag_overlay_example.dart';
import 'package:docs_core/previews/examples/web/subfocus/subfocus_default_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const _kRecipes = <(String, String), (Type, Type, int)>{
  ('drag', 'default'): (DragDefaultExample, coui.DragScope, 2),
  ('drag', 'board'): (DragBoardExample, coui.DragScope, 2),
  ('drag', 'overlay'): (DragOverlayExample, coui.DragScope, 2),
  ('subfocus', 'default'): (SubfocusScopeDefaultExample, coui.SubfocusScope, 3),
};

/// Reads the actual original mount; never calls a producer's build/resolver.
///
/// observe() retains the live typed prefix and complete caller frontiers.
/// completeWithSerializedBody() MUST then receive the exact body returned by
/// the existing normal SSR response, before publishing any source receipt.
/// A subtree renderToHtml() is used only to read owned attributes/frontier
/// kinds; its formatting never supplies literal owned Text evidence.
class ScopeAllocationSsrSource implements CurrentSsrBoxSource {
  ScopeAllocationSsrSource._(this.entry, this.recipe);

  static ScopeAllocationSsrSource? forEntry(MatrixEntry entry) {
    const source = BoxObservationSourceSpec.scopeAllocationHost;
    final claims = entry.probes.where(
      (p) => p.boxObservationSource?.logicalUnitId == source.logicalUnitId,
    );
    if (claims.isEmpty) return null;
    final recipe = _kRecipes[(entry.component, entry.variant)];
    if (recipe == null ||
        !const ['light', 'dark'].contains(entry.theme.name) ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource != source) {
      throw _changed('closed original source tuple/recipe');
    }
    return ScopeAllocationSsrSource._(entry, recipe);
  }

  final MatrixEntry entry;
  final (Type, Type, int) recipe;
  Component? _registry;
  div? _capture;
  ({List<Object?> held, Map<String, Object?> raw})? _live;
  bool _completed = false;

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
      throw _changed('current typed prefix/frontiers');
    }
    _live = before;
    // This local marker is never a source receipt or a successful result.
    // Backend integration replaces it only after exact normal-body closure.
    return const {'scopeSourceAwaitingExactSerializedBody': true};
  }

  Map<String, Object?> completeWithSerializedBody(String body) {
    final live = _live;
    if (live == null || _completed) throw _changed('normal body completion');
    final fragment = html.parseFragment(body);
    final captures = fragment
        .querySelectorAll('[data-parity-key]')
        .where((e) => e.attributes['data-parity-key'] == entry.key)
        .toList();
    if (captures.length != 1) throw _changed('unique original capture');
    final capture = captures.single;
    if (capture.localName != 'div' ||
        capture.namespaceUri != _kHtmlNS ||
        capture.children.length != 1 ||
        capture.nodes.any(
          (n) =>
              !identical(n, capture.children.single) &&
              !(n is dom.Text && _ascii.hasMatch(n.data)),
        )) {
      throw _changed('whole serialized capture frontier');
    }
    final raw = Map<String, Object?>.of(live.raw);
    final slots = raw['layoutSlots']! as List<Map<String, Object?>>;
    final completed = _completeOwned(
      capture.children.single,
      raw['generatedTree']! as Map<String, Object?>,
      slots,
    );
    raw['generatedTree'] = completed;
    final liveRegion = raw['liveRegion'] as Map<String, Object?>?;
    if (liveRegion != null) {
      // Owned literal nodes come from the exact normal response, including
      // whitespace introduced by its real document serialization context.
      final region = (completed['children']! as List).last as Map;
      final span = (region['children']! as List).single as Map;
      final text = (span['children']! as List).single as Map;
      raw['liveRegion'] = {
        ...liveRegion,
        'normalSerializedTextNodes': text['normalSerializedTextNodes'],
      };
    }
    _completed = true;
    return {
      'kind': 'canonical-ssr-scope-allocation-v1',
      'entryKey': entry.key,
      'source': BoxObservationSourceSpec.scopeAllocationHost.toJson(),
      'currentRaw': raw,
      'completeRawSlotCount': recipe.$3 + 1,
      'rawOrderFromPublicProducerLists': true,
    };
  }

  ({List<Object?> held, Map<String, Object?> raw}) _read(Element root) {
    final registry = _registry;
    final capture = _capture;
    if (registry == null ||
        capture == null ||
        registry.runtimeType != recipe.$1 ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw _changed('original registry/capture');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    final example = currentSsrIdentityElement(root, registry);
    if (!identical(example.parent, captureDom)) throw _changed('registry edge');
    final scope = soleCurrentSsrChild(example);
    if (scope.component.runtimeType != recipe.$2) {
      throw _changed('public scope');
    }
    final held = <Object?>[
      captureElement,
      capture,
      captureDom,
      _markup(captureDom),
      example,
      registry,
      scope,
      scope.component,
    ];
    final Component publicChild;
    final Element owner;
    Element? liveRegionElement;
    coui.Text? announcement;
    Map<String, Object?>? live;
    if (scope.component is coui.DragScope) {
      final input = scope.component as coui.DragScope;
      if (input.originElementId != null || !input.announcements) {
        // The adopted-origin fragment is a different field unit. Do not
        // unwrap it, or turn a missing live region into an empty one.
        throw _changed('normal owned-root DragScope branch');
      }
      publicChild = input.child;
      final provider = soleCurrentSsrChild(scope);
      if (provider.component.runtimeType != coui.DragScopeProvider) {
        throw _changed('public DragScopeProvider');
      }
      final provided = provider.component as coui.DragScopeProvider;
      final returned = soleCurrentSsrChild(provider);
      if (!identical(provided.child, returned.component) ||
          returned.component.runtimeType != div) {
        throw _changed('provider exact generated DIV child');
      }
      final declaration = returned.component as div;
      if (declaration.children.length != 2 ||
          !identical(declaration.children.first, publicChild) ||
          declaration.children.last.runtimeType != div) {
        throw _changed('complete original scope child plus owned live region');
      }
      owner = currentSsrGeneratedDiv(returned, declaration);
      final children = _children(owner);
      _directDeclared(owner, declaration.children, children);
      final regionDeclaration = declaration.children.last as div;
      if (regionDeclaration.children.length != 1 ||
          regionDeclaration.children.single.runtimeType != coui.Text) {
        throw _changed('owned public CoUI Text declaration');
      }
      announcement = regionDeclaration.children.single as coui.Text;
      if (announcement.textSpan != null) throw _changed('plain announcement');
      liveRegionElement = currentSsrGeneratedDiv(
        children.last,
        regionDeclaration,
      );
      final textElement = soleCurrentSsrChild(liveRegionElement);
      if (!identical(textElement.component, announcement)) {
        throw _changed('current original announcement occurrence');
      }
      final span = soleCurrentSsrChild(textElement);
      final spanComponent = span.component;
      if (spanComponent.runtimeType != DomComponent ||
          (spanComponent as DomComponent).tag != 'span' ||
          spanComponent.children == null ||
          spanComponent.children!.length != 1 ||
          spanComponent.children!.single is! Text) {
        throw _changed('normal public Text generated SPAN and primitive');
      }
      final primitive = spanComponent.children!.single as Text;
      final primitiveElement = soleCurrentSsrChild(span);
      final primitiveRender = _markup(primitiveElement);
      if (!identical(primitiveElement.component, primitive) ||
          primitive.text != announcement.data ||
          primitiveRender is! MarkupRenderText ||
          primitiveRender.rawHtml ||
          primitiveRender.text != primitive.text) {
        throw _changed('actual owned public primitive Text');
      }
      _renderChildrenMatch(span, [primitiveElement]);
      _renderChildrenMatch(liveRegionElement, [textElement]);
      held.addAll([
        input.child,
        input.originElementId,
        input.announcements,
        provider,
        provided,
        returned,
        declaration,
        owner,
        _markup(owner),
        regionDeclaration,
        children.last,
        liveRegionElement,
        _markup(liveRegionElement),
        textElement,
        announcement,
        announcement.data,
        span,
        spanComponent,
        _markup(span),
        primitive,
        primitive.text,
        primitiveElement,
        primitiveRender,
        primitiveRender.text,
      ]);
      live = {
        'present': true,
        'sourceData': announcement.data,
        'publicRoute': 'CoUI Text.data -> generated SPAN -> Jaspr Text.text',
      };
    } else {
      final input = scope.component as coui.SubfocusScope;
      final child = input.child;
      if (child == null) throw _changed('original nonnull public scope.child');
      publicChild = child;
      owner = soleCurrentSsrChild(scope);
      final declaration = owner.component;
      if (declaration.runtimeType != DomComponent ||
          (declaration as DomComponent).tag != 'div' ||
          declaration.children == null ||
          declaration.children!.length != 1 ||
          !identical(declaration.children!.single, child)) {
        throw _changed('actual scope-generated outer DomComponent DIV');
      }
      _directDeclared(owner, declaration.children!, _children(owner));
      held.addAll([child, owner, declaration, _markup(owner)]);
    }
    if (publicChild.runtimeType != div) throw _changed('original layout DIV');
    final layoutDeclaration = publicChild as div;
    final ownerChildren = _children(owner);
    final layoutElement = ownerChildren.first;
    if (!identical(layoutElement.component, publicChild)) {
      throw _changed('scope.child actual original layout occurrence');
    }
    final layout = currentSsrGeneratedDiv(layoutElement, layoutDeclaration);
    final raw = List<Component>.unmodifiable(layoutDeclaration.children);
    final seats = _children(layout);
    if (raw.length != recipe.$3 ||
        raw.any(
          (c) =>
              identical(c, publicChild) ||
              identical(c, registry) ||
              identical(c, scope.component),
        )) {
      throw _changed('complete original layout list');
    }
    _directDeclared(layout, raw, seats);
    _renderChildrenMatch(layout, seats);
    _renderChildrenMatch(owner, ownerChildren);
    _renderChildrenMatch(captureDom, [example]);
    final frontiers = <Map<String, Object?>>[];
    final used = Set<MarkupRenderObject>.identity();
    for (var i = 0; i < raw.length; i++) {
      final render = _frontier(seats[i]);
      held.addAll([raw[i], seats[i], ...render]);
      frontiers.add({
        'seat': i + 1,
        'sourceAliasOf': _earlier(raw, i),
        'nodes': [for (final r in render) ..._opaque(r, used, held)],
      });
    }
    held.addAll([
      publicChild,
      layoutElement,
      layoutDeclaration,
      layout,
      _markup(layout),
    ]);
    final layoutTree = _owned(layout, [
      for (var i = 0; i < raw.length; i++) {'opaqueSlot': i},
    ]);
    final ownedChildren = <Map<String, Object?>>[layoutTree];
    if (liveRegionElement != null) {
      final span = soleCurrentSsrChild(soleCurrentSsrChild(liveRegionElement));
      ownedChildren.add(
        _owned(liveRegionElement, [
          _owned(span, [
            {'ownedAnnouncementText': true, 'sourceData': announcement!.data},
          ]),
        ]),
      );
    }
    return (
      held: List.unmodifiable(held),
      raw: {
        'kind': 'current-scope-allocation-raw-v1',
        'logicalUnitId':
            BoxObservationSourceSpec.scopeAllocationHost.logicalUnitId,
        'scopeKind': scope.component is coui.DragScope
            ? 'DragScope'
            : 'SubfocusScope',
        'rawSlotCount': recipe.$3 + 1,
        'scopeChild': {'seat': 0, 'present': true, 'ownedLayout': true},
        'layoutSlots': frontiers,
        'owner': _attributes(_markup(owner)),
        'generatedTree': _owned(owner, ownedChildren),
        'liveRegion': live,
      },
    );
  }
}

const _kHtmlNS = 'http://www.w3.org/1999/xhtml';
final _ascii = RegExp(r'^[\t\n\f\r ]*$');
StateError _changed(String part) =>
    StateError('SCOPE_ALLOCATION_SOURCE_CHANGED: $part');
List<Element> _children(Element e) {
  final out = <Element>[];
  e.visitChildren(out.add);
  return out;
}

bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((same) => same);
int? _earlier(List<Component> raw, int i) {
  for (var j = 0; j < i; j++) {
    if (identical(raw[j], raw[i])) return j + 1;
  }
  return null;
}

MarkupRenderObject _markup(Element e) {
  if (e is! RenderObjectElement || e.renderObject is! MarkupRenderObject) {
    throw _changed('direct actual public markup');
  }
  return e.renderObject as MarkupRenderObject;
}

List<MarkupRenderObject> _frontier(Element e) => e is RenderObjectElement
    ? [_markup(e)]
    : [for (final c in _children(e)) ..._frontier(c)];
void _directDeclared(
  Element owner,
  List<Component> declared,
  List<Element> actual,
) {
  if (declared.length != actual.length ||
      (Set<Element>.identity()..addAll(actual)).length != actual.length ||
      List.generate(
        actual.length,
        (i) =>
            identical(actual[i].parent, owner) &&
            identical(actual[i].component, declared[i]),
      ).any((same) => !same)) {
    throw _changed('all ordered actual child occurrences');
  }
}

void _renderChildrenMatch(Element owner, List<Element> declared) {
  final markup = _markup(owner);
  final expected = [for (final child in declared) ..._frontier(child)];
  final actual = markup.children.toList(growable: false);
  if (actual.length != expected.length ||
      (Set<MarkupRenderObject>.identity()..addAll(expected)).length !=
          expected.length ||
      List.generate(
        actual.length,
        (i) =>
            identical(actual[i], expected[i]) &&
            identical(actual[i].parent, markup),
      ).any((same) => !same)) {
    throw _changed('whole generated render frontier');
  }
}

Map<String, Object?> _attributes(MarkupRenderObject r) {
  final f = html.parseFragment(r.renderToHtml());
  if (r is! MarkupRenderElement || f.children.length != 1) {
    throw _changed('typed owned markup element');
  }
  final e = f.children.single;
  return {
    'namespaceURI': e.namespaceUri,
    'localName': e.localName,
    'attributes': {
      for (final a in e.attributes.entries) a.key.toString(): a.value,
    },
  };
}

Map<String, Object?> _owned(Element e, List<Map<String, Object?>> children) => {
  'nodeType': 1,
  ..._attributes(_markup(e)),
  'children': children,
};
Map<String, Object?> _shape(dom.Node n) => n is dom.Element
    ? {'nodeType': 1, 'namespaceURI': n.namespaceUri, 'localName': n.localName}
    : n is dom.Text || n is dom.Comment
    ? {'nodeType': n.nodeType}
    : throw _changed('unsupported opaque frontier node');
List<Map<String, Object?>> _opaque(
  MarkupRenderObject r,
  Set<MarkupRenderObject> used,
  List<Object?> held,
) {
  if (!used.add(r)) throw _changed('same mounted frontier reused');
  held.add(r);
  if (r is MarkupRenderFragment) {
    return [
      for (final c in r.children)
        ...(() {
          if (!identical(c.parent, r)) throw _changed('fragment parent');
          return _opaque(c, used, held);
        })(),
    ];
  }
  if (r is! MarkupRenderElement && r is! MarkupRenderText) {
    throw _changed('unsupported opaque frontier');
  }
  // Foreign attrs/text/interiors are deliberately not source authority.
  return [
    for (final n in html.parseFragment(r.renderToHtml()).nodes) _shape(n),
  ];
}

Map<String, Object?> _completeOwned(
  dom.Element actual,
  Map<String, Object?> expected,
  List<Map<String, Object?>> slots,
) {
  final attrs = <String, Object?>{
    for (final a in actual.attributes.entries) a.key.toString(): a.value,
  };
  if (actual.namespaceUri != expected['namespaceURI'] ||
      actual.localName != expected['localName'] ||
      !_equalMap(attrs, expected['attributes']! as Map)) {
    throw _changed('normal response owned element/attributes');
  }
  final children = actual.nodes;
  var cursor = 0;
  final completed = <Map<String, Object?>>[];
  for (final object in expected['children']! as List) {
    final item = object as Map<String, Object?>;
    if (item['ownedAnnouncementText'] == true) {
      if ((item['sourceData']! as String).isEmpty) {
        if (children.isNotEmpty) throw _changed('empty public text output');
      } else if (children.isEmpty || children.any((n) => n is! dom.Text)) {
        throw _changed('whole literal owned text frontier');
      }
      completed.add({
        ...item,
        'normalSerializedTextNodes': [
          for (final n in children) (n as dom.Text).data,
        ],
      });
      cursor = children.length;
      continue;
    }
    if (item.containsKey('opaqueSlot')) {
      final seat = item['opaqueSlot']! as int;
      for (final shape in slots[seat]['nodes']! as List) {
        final record = shape as Map;
        while (cursor < children.length &&
            record['nodeType'] != 3 &&
            children[cursor] is dom.Text &&
            _ascii.hasMatch((children[cursor] as dom.Text).data)) {
          cursor++;
        }
        if (cursor == children.length ||
            !_equalMap(_shape(children[cursor++]), record)) {
          throw _changed('normal response complete opaque order');
        }
      }
      completed.add(item);
      continue;
    }
    while (cursor < children.length &&
        children[cursor] is dom.Text &&
        _ascii.hasMatch((children[cursor] as dom.Text).data)) {
      cursor++;
    }
    if (cursor == children.length || children[cursor] is! dom.Element) {
      throw _changed('normal response generated child');
    }
    completed.add(
      _completeOwned(children[cursor++] as dom.Element, item, slots),
    );
  }
  if (children
      .skip(cursor)
      .any((n) => !(n is dom.Text && _ascii.hasMatch(n.data)))) {
    throw _changed('unexpected normal response owned content');
  }
  return {...expected, 'children': completed};
}

bool _equalMap(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) =>
    a.length == b.length &&
    a.keys.every((k) => b.containsKey(k) && a[k] == b[k]);

String? requiredScopeAllocationSsrKind(MatrixEntry entry) =>
    ScopeAllocationSsrSource.forEntry(entry) == null
    ? null
    : 'canonical-ssr-scope-allocation-v1';

// The browser resolver/request wrapper independently validates held nodes,
// source receipts and repeated selectors.
