import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/media_query/media_query_default_example.dart';
import 'package:docs_core/previews/examples/web/swipe_actions/swipe_actions_default_example.dart';
import 'package:docs_core/previews/examples/web/tree/tree_default_example.dart';
import 'package:docs_core/previews/examples/web/tree/tree_selected_example.dart';
import 'package:docs_core/previews/examples/web/tree/tree_trailing_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show RawText, div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const _kRecipes = <(String, String), (Type, Type, BoxObservationSourceSpec)>{
  ('media-query', 'default'): (
    MediaQueryDefaultExample,
    coui.MediaQueryVisibility,
    BoxObservationSourceSpec.mediaQueryVisibilityHost,
  ),
  ('swipe-actions', 'default'): (
    SwipeActionsDefaultExample,
    coui.SwipeActions,
    BoxObservationSourceSpec.swipeActionsOuterHost,
  ),
  ('tree', 'default'): (
    TreeDefaultExample,
    coui.Tree,
    BoxObservationSourceSpec.treeOuterLayoutHost,
  ),
  ('tree', 'selected'): (
    TreeSelectedExample,
    coui.Tree,
    BoxObservationSourceSpec.treeOuterLayoutHost,
  ),
  ('tree', 'trailing'): (
    TreeTrailingExample,
    coui.Tree,
    BoxObservationSourceSpec.treeOuterLayoutHost,
  ),
};
const _kSsrKind = 'canonical-ssr-public-wrapper-v1';

/// Reads one normal original registry mount. Generated opaque rows/platters
/// are explicitly different from caller-supplied Component boundaries.
class PublicWrapperSsrSource implements CurrentSsrBoxSource {
  PublicWrapperSsrSource._(this.entry, this.recipe);
  static PublicWrapperSsrSource? forEntry(MatrixEntry entry) {
    final recipe = _kRecipes[(entry.component, entry.variant)];
    final claims = entry.probes.where(
      (p) => BoxObservationSourceSpec.publicWrapperFrames.contains(
        p.boxObservationSource,
      ),
    );
    if (recipe == null && claims.isEmpty) {
      return null;
    }
    if (recipe != null &&
        entry.probes.every((p) => p.boxObservationSource == null)) {
      return null;
    }
    if (recipe == null ||
        !const ['light', 'dark'].contains(entry.theme.name) ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource != recipe.$3) {
      throw StateError('PUBLIC_WRAPPER_CLOSED_SSR_RECIPE_CHANGED');
    }
    return PublicWrapperSsrSource._(entry, recipe);
  }

  final MatrixEntry entry;
  final (Type, Type, BoxObservationSourceSpec) recipe;
  Component? _registry;
  div? _capture;
  ({List<Object?> held, Map<String, Object?> raw, int count})? _live;
  bool _completed = false;
  @override
  void recordBuild(Component result, div capture) {
    if (_registry != null) {
      throw StateError('PUBLIC_WRAPPER_REPEATED_BUILD');
    }
    _registry = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    if (_live != null || _completed) {
      throw StateError('PUBLIC_WRAPPER_REPEATED_OBSERVATION');
    }
    final before = _read(root);
    final after = _read(root);
    if (!_same(before.held, after.held) ||
        jsonEncode(before.raw) != jsonEncode(after.raw)) {
      throw StateError('PUBLIC_WRAPPER_CURRENT_SSR_CHANGED');
    }
    _live = before;
    // This local marker is not a source receipt. The ordinary backend replaces
    // it only after completing the actual normal response, without remounting.
    return const {'publicWrapperSourceAwaitingExactSerializedBody': true};
  }

  Map<String, Object?> completeWithSerializedBody(String body) {
    final live = _live;
    if (live == null || _completed) {
      throw StateError('PUBLIC_WRAPPER_NORMAL_BODY_COMPLETION_CHANGED');
    }
    final parsed = html.parseFragment(body);
    final captures = parsed
        .querySelectorAll('[data-parity-key]')
        .where((e) => e.attributes['data-parity-key'] == entry.key)
        .toList();
    if (captures.length != 1 ||
        captures.single.localName != 'div' ||
        captures.single.children.length != 1) {
      throw StateError('PUBLIC_WRAPPER_NORMAL_CAPTURE_CHANGED');
    }
    final capture = captures.single;
    final owner = capture.children.single;
    final graph = _completeOwned(
      owner,
      live.raw['generatedTree']! as Map<String, Object?>,
    );
    final captureNodes = <Map<String, Object?>>[];
    for (final node in capture.nodes) {
      if (identical(node, owner)) {
        captureNodes.add({'kind': 'layout-root'});
      } else if (node is dom.Text && _ascii.hasMatch(node.data)) {
        captureNodes.add({
          'kind': 'formatter-text',
          'nodeType': 3,
          'text': node.data,
        });
      } else {
        throw StateError('PUBLIC_WRAPPER_NORMAL_CAPTURE_FRONTIER_CHANGED');
      }
    }
    _completed = true;
    return {
      'kind': _kSsrKind,
      'entryKey': entry.key,
      'source': recipe.$3.toJson(),
      'currentRaw': {
        ...live.raw,
        'generatedTree': graph,
        'normalSerializedCaptureNodes': captureNodes,
      },
      'completeRawSlotCount': live.count,
      'rawOrderFromPublicProducerLists': true,
    };
  }

  ({List<Object?> held, Map<String, Object?> raw, int count}) _read(
    Element root,
  ) {
    final registry = _registry;
    final capture = _capture;
    if (registry == null ||
        capture == null ||
        registry.runtimeType != recipe.$1 ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw StateError('PUBLIC_WRAPPER_ORIGINAL_CAPTURE_CHANGED');
    }
    final cap = currentSsrGeneratedDiv(
      currentSsrIdentityElement(root, capture),
      capture,
    );
    final example = currentSsrIdentityElement(root, registry);
    if (!identical(example.parent, cap)) {
      throw StateError('PUBLIC_WRAPPER_ORIGINAL_REGISTRY_EDGE_CHANGED');
    }
    final producer = soleCurrentSsrChild(example);
    if (producer.component.runtimeType != recipe.$2) {
      throw StateError('PUBLIC_WRAPPER_EXACT_PUBLIC_PRODUCT_REQUIRED');
    }
    final held = <Object?>[
      capture,
      cap,
      registry,
      example,
      producer,
      producer.component,
    ];
    final raw = <Component?>[];
    final witnesses = <Object?>[];
    final input = producer.component;
    if (input is coui.MediaQueryVisibility) {
      raw.addAll([input.child, input.alternateChild]);
      witnesses.addAll([
        input.minWidth,
        input.maxWidth,
        input.minBreakpoint,
        input.maxBreakpoint,
      ]);
    } else if (input is coui.SwipeActions) {
      raw.addAll([
        input.child,
        for (final a in [...input.leadingActions, ...input.trailingActions])
          a.icon,
      ]);
      witnesses.addAll([
        input.enabled,
        input.showLabels,
        input.allowsFullSwipe,
        input.fullSwipeThreshold,
        input.swipeActionsStyle,
        ...input.leadingActions,
        ...input.trailingActions,
      ]);
    } else if (input is coui.Tree) {
      if (input.leadingBuilder != null ||
          (input.trailingBuilder != null && recipe.$1 != TreeTrailingExample) ||
          (input.trailingBuilder == null && recipe.$1 == TreeTrailingExample) ||
          input.loadingBuilder != null ||
          input.errorBuilder != null ||
          input.nodeContextMenu != null ||
          input.loadChildren != null ||
          input.virtualRowHeight != null ||
          input.onNodeDrop != null ||
          input.onNodePlace != null ||
          input.onFilesPlaced != null) {
        throw StateError('PUBLIC_WRAPPER_TREE_CALLBACK_SCOPE_CHANGED');
      }
      witnesses.addAll([
        input.trailingBuilder,
        input.showRoots,
        ...input.nodes,
      ]);
    }
    held.addAll([...raw, ...witnesses]);
    final unique = Set<Component>.identity();
    if (raw.whereType<Component>().any((c) => !unique.add(c))) {
      throw StateError('PUBLIC_WRAPPER_RAW_ALIAS');
    }
    Element generated(Element original) {
      var e = original;
      if (e.component.runtimeType == div) {
        e = currentSsrGeneratedDiv(e, e.component as div);
      }
      if (e.component is! DomComponent ||
          e is! RenderObjectElement ||
          e.renderObject is! MarkupRenderElement) {
        throw StateError('PUBLIC_WRAPPER_NORMAL_GENERATED_DOM_REQUIRED');
      }
      held.addAll([e, e.component, e.parent, e.renderObject]);
      return e;
    }

    final owner = generated(soleCurrentSsrChild(producer));
    final ownerComponent = owner.component as DomComponent;
    if (ownerComponent.tag != 'div') {
      throw StateError('PUBLIC_WRAPPER_DIRECT_DIV_REQUIRED');
    }
    final children = _declaredChildren(owner, held);
    final seatOf = <Element, int>{};
    final generatedOpaque = <Element>{};
    final owned = <Element>{owner};
    final mounted = <int>{};
    void foreign(Element e, int index) {
      if (raw[index] == null ||
          !identical(e.component, raw[index]) ||
          !mounted.add(index)) {
        throw StateError('PUBLIC_WRAPPER_WHOLE_FOREIGN_SEAT_CHANGED');
      }
      seatOf[e] = index;
    }

    if (input is coui.MediaQueryVisibility) {
      if (children.length != 2 + (input.alternateChild == null ? 0 : 1)) {
        throw StateError('PUBLIC_WRAPPER_MEDIA_COMPLETE_CHILDREN_CHANGED');
      }
      final style = generated(children[0]);
      if ((style.component as DomComponent).tag != 'style') {
        throw StateError('PUBLIC_WRAPPER_MEDIA_OWNED_RULE_REQUIRED');
      }
      owned.add(style);
      final primary = generated(children[1]);
      owned.add(primary);
      final primaryChildren = _declaredChildren(primary, held);
      if (primaryChildren.length != 1) {
        throw StateError('PUBLIC_WRAPPER_MEDIA_PRIMARY_CHANGED');
      }
      foreign(primaryChildren.single, 0);
      if (input.alternateChild != null) {
        final alt = generated(children[2]);
        owned.add(alt);
        final altChildren = _declaredChildren(alt, held);
        if (altChildren.length != 1) {
          throw StateError('PUBLIC_WRAPPER_MEDIA_ALTERNATE_CHANGED');
        }
        foreign(altChildren.single, 1);
      }
    } else if (input is coui.SwipeActions) {
      if (!(ownerComponent.attributes?.containsKey('data-swipe-actions') ??
          false)) {
        throw StateError('PUBLIC_WRAPPER_SWIPE_ROOT_CHANGED');
      }
      final rows = children
          .where(
            (e) =>
                e.component is DomComponent &&
                (e.component as DomComponent).attributes?.containsKey(
                      'data-swipe-row',
                    ) ==
                    true,
          )
          .toList();
      if (rows.length != 1) {
        throw StateError('PUBLIC_WRAPPER_SWIPE_CURRENT_ROW_CHANGED');
      }
      final row = generated(rows.single);
      owned.add(row);
      final rowChildren = _declaredChildren(row, held);
      if (rowChildren.isEmpty || rowChildren.length > 2) {
        throw StateError('PUBLIC_WRAPPER_SWIPE_ROW_FRONTIER_CHANGED');
      }
      foreign(rowChildren.first, 0);
      generatedOpaque.addAll([
        ...children.where((e) => !identical(e, row)),
        ...rowChildren.skip(1),
      ]);
      // Icons are original public inputs. They are contained inside complete
      // generated opaque platters; DOM cannot independently reconstruct them.
      // Dart holds the exact raw action/icon roster before and after binding.
    } else {
      if (ownerComponent.attributes?['role'] != 'tree') {
        throw StateError('PUBLIC_WRAPPER_TREE_ROOT_CHANGED');
      }
      // tree.dart emits its owned STYLE only when normal rules.css is
      // nonempty. Presence is not replayed from a resolver or guessed from
      // a first row: every actual direct child is retained in source order.
      for (final e in children) {
        if (e.component is DomComponent &&
            (e.component as DomComponent).tag == 'style') {
          owned.add(generated(e));
        } else {
          generatedOpaque.add(e);
        }
      }
    }
    var generatedOrdinal = 0;
    Map<String, Object?> tree(Element original) {
      var e = original;
      if (seatOf[e] case final index?) {
        held.addAll([e, e.component, e.parent]);
        return {'kind': 'foreign', 'seat': index, 'nodes': _opaque(e)};
      }
      if (generatedOpaque.contains(e)) {
        held.addAll([e, e.component, e.parent]);
        return {
          'kind': 'generated-opaque',
          'ordinal': generatedOrdinal++,
          'nodes': _opaque(e),
        };
      }
      e = generated(e);
      if (!owned.contains(e)) {
        throw StateError('PUBLIC_WRAPPER_UNDECLARED_GENERATED_NODE');
      }
      final component = e.component as DomComponent;
      final markup =
          (e as RenderObjectElement).renderObject as MarkupRenderElement;
      final parsed = html.parseFragment(markup.renderToHtml()).children.single;
      final kids = _declaredChildren(e, held);
      final List<Map<String, Object?>> graph;
      if (component.tag == 'style') {
        if (kids.length != 1 || kids.single.component is! RawText) {
          throw StateError('PUBLIC_WRAPPER_LITERAL_STYLE_REQUIRED');
        }
        final text = kids.single.component as RawText;
        final render = (kids.single as RenderObjectElement).renderObject;
        if (render is! MarkupRenderText || render.text != text.text) {
          throw StateError('PUBLIC_WRAPPER_NORMAL_SERIALIZED_RULE_CHANGED');
        }
        held.addAll([kids.single, text, render, text.text]);
        graph = [
          {
            'kind': 'owned-text',
            'nodeType': 3,
            'sourceData': text.text,
            'text': text.text,
          },
        ];
      } else {
        graph = [for (final child in kids) tree(child)];
      }
      return {
        'kind': 'owned',
        'nodeType': 1,
        'namespaceURI': parsed.namespaceUri,
        'localName': parsed.localName,
        'attributes': {
          for (final a in parsed.attributes.entries) a.key.toString(): a.value,
        },
        'children': graph,
      };
    }

    final graph = tree(owner);
    _declaredChildren(cap, held);
    return (
      held: held,
      count: raw.length,
      raw: {
        'kind': 'current-public-wrapper-raw-v1',
        'logicalUnitId': recipe.$3.logicalUnitId,
        'rawSeats': [
          for (var i = 0; i < raw.length; i++)
            {
              'index': i,
              'present': raw[i] != null,
              'sourceAliasOf': null,
              'domFrontierValidated': mounted.contains(i),
            },
        ],
        'owner': {
          'namespaceURI': graph['namespaceURI'],
          'localName': graph['localName'],
          'attributes': graph['attributes'],
        },
        'generatedTree': graph,
      },
    );
  }
}

List<Element> _declaredChildren(Element e, List<Object?> held) {
  final declaration =
      (e.component as DomComponent).children ?? const <Component>[];
  final children = <Element>[];
  e.visitChildren(children.add);
  if (children.length != declaration.length ||
      List.generate(
        children.length,
        (i) =>
            !identical(children[i].component, declaration[i]) ||
            !identical(children[i].parent, e),
      ).any((bad) => bad)) {
    throw StateError('PUBLIC_WRAPPER_COMPLETE_CURRENT_ORDER_CHANGED');
  }
  final markup = (e as RenderObjectElement).renderObject as MarkupRenderElement;
  final renderChildren = markup.children.toList();
  final frontier = [for (final c in children) ..._frontier(c)];
  if (renderChildren.length != frontier.length ||
      List.generate(
        frontier.length,
        (i) =>
            !identical(frontier[i], renderChildren[i]) ||
            !identical(frontier[i].parent, markup),
      ).any((bad) => bad)) {
    throw StateError('PUBLIC_WRAPPER_RENDER_FRONTIER_CHANGED');
  }
  held.addAll([
    for (final c in children) ...[c, c.component],
  ]);
  return children;
}

List<MarkupRenderObject> _frontier(Element e) => e is RenderObjectElement
    ? [e.renderObject as MarkupRenderObject]
    : [for (final child in _children(e)) ..._frontier(child)];
List<Element> _children(Element e) {
  final list = <Element>[];
  e.visitChildren(list.add);
  return list;
}

List<Map<String, Object?>> _opaque(Element e) => [
  for (final render in _frontier(e)) ..._shapes(render),
];
List<Map<String, Object?>> _shapes(MarkupRenderObject render) =>
    render is MarkupRenderFragment
    ? [for (final child in render.children) ..._shapes(child)]
    : [
        for (final node in html.parseFragment(render.renderToHtml()).nodes)
          if (node is dom.Element)
            {
              'nodeType': 1,
              'namespaceURI': node.namespaceUri,
              'localName': node.localName,
            }
          else if (node is dom.Text || node is dom.Comment)
            {'nodeType': node.nodeType}
          else
            throw StateError('PUBLIC_WRAPPER_OPAQUE_NODE_KIND_CHANGED'),
      ];
bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => identical(a[i], b[i])).every((same) => same);

// Formatter Text is recorded once from the actual normal response. It is
// never skipped, trimmed, reconstructed or supplied by an isolated serializer.
final _ascii = RegExp(r'^[\t\n\f\r ]*$');
Map<String, Object?> _completeOwned(
  dom.Element actual,
  Map<String, Object?> source,
) {
  final attrs = {
    for (final a in actual.attributes.entries) a.key.toString(): a.value,
  };
  final expectedAttrs = source['attributes']! as Map;
  if (actual.namespaceUri != source['namespaceURI'] ||
      actual.localName != source['localName'] ||
      attrs.length != expectedAttrs.length ||
      attrs.keys.any((k) => attrs[k] != expectedAttrs[k])) {
    throw StateError('PUBLIC_WRAPPER_NORMAL_OWNED_ELEMENT_CHANGED');
  }
  final nodes = actual.nodes;
  final completed = <Map<String, Object?>>[];
  var cursor = 0;
  Map<String, Object?> formatting(dom.Text text) => {
    'kind': 'formatter-text',
    'nodeType': 3,
    'text': text.data,
  };
  void before(
    int type,
    List<Map<String, Object?>> target, {
    bool opaque = false,
  }) {
    while (cursor < nodes.length &&
        type != 3 &&
        nodes[cursor] is dom.Text &&
        _ascii.hasMatch((nodes[cursor] as dom.Text).data)) {
      final text = nodes[cursor++] as dom.Text;
      target.add(
        opaque
            ? {'nodeType': 3, 'normalSerializedData': text.data}
            : formatting(text),
      );
    }
  }

  for (final object in source['children']! as List) {
    final child = object as Map<String, Object?>;
    if (child['kind'] == 'foreign' || child['kind'] == 'generated-opaque') {
      final shapes = <Map<String, Object?>>[];
      for (final value in child['nodes']! as List) {
        final shape = value as Map<String, Object?>;
        before(shape['nodeType']! as int, shapes, opaque: true);
        if (cursor == nodes.length || !_shapeMatches(nodes[cursor], shape)) {
          throw StateError('PUBLIC_WRAPPER_NORMAL_OPAQUE_FRONTIER_CHANGED');
        }
        cursor++;
        shapes.add(shape);
      }
      completed.add({...child, 'nodes': shapes});
    } else if (child['kind'] == 'owned-text') {
      // The typed RawText/RenderText literal was held before and after the
      // normal build. Its actual text serialization belongs to THIS ordinary
      // response, not an isolated serializer's indentation. No trim/normalizer
      // or regenerated CSS is used; browser later requires exact text/data.
      if (nodes.any((n) => n is! dom.Text) ||
          ((child['sourceData']! as String).isNotEmpty && nodes.isEmpty)) {
        throw StateError('PUBLIC_WRAPPER_NORMAL_LITERAL_RULE_CHANGED');
      }
      for (final node in nodes) {
        completed.add({...child, 'text': (node as dom.Text).data});
      }
      cursor = nodes.length;
    } else {
      before(1, completed);
      if (cursor == nodes.length || nodes[cursor] is! dom.Element) {
        throw StateError('PUBLIC_WRAPPER_NORMAL_GENERATED_CHILD_CHANGED');
      }
      completed.add(_completeOwned(nodes[cursor++] as dom.Element, child));
    }
  }
  for (final node in nodes.skip(cursor)) {
    if (node is! dom.Text || !_ascii.hasMatch(node.data)) {
      throw StateError('PUBLIC_WRAPPER_NORMAL_EXTRA_OWNED_CONTENT');
    }
    completed.add(formatting(node));
  }
  return {...source, 'children': completed};
}

bool _shapeMatches(dom.Node node, Map<String, Object?> shape) =>
    node.nodeType == shape['nodeType'] &&
    (node is! dom.Element ||
        node.namespaceUri == shape['namespaceURI'] &&
            node.localName == shape['localName']);

String? requiredPublicWrapperSsrKind(MatrixEntry entry) =>
    PublicWrapperSsrSource.forEntry(entry) == null ? null : _kSsrKind;

String get publicWrapperRequestBindingScript =>
    '''
(request) => {
  const tuples=${jsonEncode([...BoxObservationSourceSpec.publicWrapperFrames, BoxObservationSourceSpec.treeOuterLayoutHost].map((s) => s.toJson()).toList())};
  const claims=tuples.some(t=>t.logicalUnitId===request.source?.logicalUnitId||t.webAdapterId===request.source?.webAdapterId) || request.requiredCurrentSsrKind==='$_kSsrKind';
  if(!claims || !request.requested)return {applied:false};
  const fail=error=>({error});
  const exact=(v,keys)=>v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===keys.length&&keys.every(k=>Object.hasOwn(v,k));
  const source=request.source,tuple=tuples.find(t=>t.logicalUnitId===source?.logicalUnitId);
  const sameTuple=v=>tuple&&exact(v,Object.keys(tuple))&&Object.keys(tuple).every(k=>v[k]===tuple[k]);
  const receipt=request.currentSsrSource;
  if(request.requested!==true || request.requiredCurrentSsrKind!=='$_kSsrKind' || !sameTuple(source) ||
    !exact(receipt,['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL']) ||
    receipt.kind!=='$_kSsrKind'||typeof receipt.entryKey!=='string'||!receipt.entryKey || !sameTuple(receipt.source)||
    receipt.rawOrderFromPublicProducerLists!==true || typeof location==='undefined'||receipt.harnessURL!==location.href)
    return fail('PUBLIC_WRAPPER_ACTUAL_SSR_REQUIRED');
  const raw=receipt.currentRaw;
  const count=tuple.logicalUnitId==='tree-generated-outer-layout-host'?0:tuple.logicalUnitId==='media-query-generated-visibility-layout-host'?2:3;
  if(!exact(raw,['kind','logicalUnitId','rawSeats','owner','generatedTree','normalSerializedCaptureNodes']) || raw.kind!=='current-public-wrapper-raw-v1'||
    raw.logicalUnitId!==source.logicalUnitId || receipt.completeRawSlotCount!==count ||
    !Array.isArray(raw.normalSerializedCaptureNodes)||!Array.isArray(raw.rawSeats)||raw.rawSeats.length!==count || raw.rawSeats.some((s,i)=>
      !exact(s,['index','present','sourceAliasOf','domFrontierValidated'])||s.index!==i||s.present!==true||s.sourceAliasOf!==null||s.domFrontierValidated!==(count===2||i===0)))
    return fail('PUBLIC_WRAPPER_RAW_SEATS_CHANGED');
  const frozen=JSON.stringify(receipt),frozenSource=JSON.stringify(source);
  const heldObjects=[];
  const graphObjects=value=>{const result=[];const visit=v=>{if(v&&typeof v==='object'){result.push(v);for(const child of Object.values(v))visit(child);}};visit(value);return result;};
  heldObjects.push(...graphObjects(receipt),...graphObjects(source));
  const one=selector=>{try{const found=Array.from(document.querySelectorAll(selector));return found.length===1?found[0]:null;}catch(_){return null;}};
  if(typeof request.selector!=='string'||!request.selector||typeof request.layoutSelector!=='string'||!request.layoutSelector)
    return fail('PUBLIC_WRAPPER_SELECTOR_REQUIRED');
  const selector=request.selector,layoutSelector=request.layoutSelector;
  const owner=one(selector),layout=one(layoutSelector),capture=owner?.parentElement;
  if(!owner||owner!==layout||!capture||capture.getAttribute('data-parity-key')!==receipt.entryKey)
    return fail('PUBLIC_WRAPPER_CAPTURE_CHANGED');
  const attrs=n=>Object.fromEntries(Array.from(n.attributes).map(a=>[a.name,a.value]));
  const same=(a,b)=>JSON.stringify(Object.entries(a).sort())===JSON.stringify(Object.entries(b).sort());
  const validShape=s=>s&&(
    s.nodeType===1&&exact(s,['nodeType','namespaceURI','localName'])&&typeof s.namespaceURI==='string'&&typeof s.localName==='string'||
    [3,8].includes(s.nodeType)&&exact(s,['nodeType'])||
    s.nodeType===3&&exact(s,['nodeType','normalSerializedData'])&&typeof s.normalSerializedData==='string');
  const shape=(n,s)=>n&&n.nodeType===s.nodeType&&(s.nodeType!==1||n.namespaceURI===s.namespaceURI&&n.localName===s.localName);
  const snapshots=[];let initial=true;
  const node=(n,s,refs)=>{
    if(!n||!n.isConnected||n.nodeType!==s.nodeType)return false;
    refs.push(n);
    if(s.kind==='owned-text'||s.kind==='formatter-text')return exact(s,s.kind==='owned-text'?['kind','nodeType','sourceData','text']:['kind','nodeType','text'])&&s.nodeType===3&&(s.kind!=='owned-text'||typeof s.sourceData==='string')&&typeof s.text==='string'&&n.textContent===s.text;
    if(s.kind!=='owned'||!exact(s,['kind','nodeType','namespaceURI','localName','attributes','children'])||!shape(n,s)||
      !s.attributes||!same(attrs(n),s.attributes)||!Array.isArray(s.children))return false;
    const children=Array.from(n.childNodes);let i=0;
    for(const child of s.children){
      const opaque=child.kind==='foreign'||child.kind==='generated-opaque';
      const shapes=opaque?child.nodes:[child];
      if(opaque&&(!exact(child,child.kind==='foreign'?['kind','seat','nodes']:['kind','ordinal','nodes'])||
        !Number.isInteger(child.kind==='foreign'?child.seat:child.ordinal)||!Array.isArray(shapes)))return false;
      for(const expected of shapes){

        const actual=children[i++];
        if(!actual||actual.parentNode!==n||!actual.isConnected)return false;
        if(opaque){if(!validShape(expected)||!shape(actual,expected)||(Object.hasOwn(expected,'normalSerializedData')&&actual.textContent!==expected.normalSerializedData))return false;refs.push(actual);}
        else if(!node(actual,expected,refs))return false;
      }
    }
    return i===children.length;
  };
  const validateCurrentBinding=()=>{
    try {
      if(request.requested!==true||request.requiredCurrentSsrKind!=='$_kSsrKind'||request.source!==source||request.selector!==selector||request.layoutSelector!==layoutSelector||JSON.stringify(receipt)!==frozen||JSON.stringify(request.source)!==frozenSource||request.currentSsrSource!==receipt||
        ([...graphObjects(receipt),...graphObjects(source)].length!==heldObjects.length)||[...graphObjects(receipt),...graphObjects(source)].some((v,i)=>v!==heldObjects[i])||
        receipt.harnessURL!==location.href||one(request.selector)!==owner||one(request.layoutSelector)!==owner||
        owner.parentElement!==capture||!capture.isConnected||capture.getAttribute('data-parity-key')!==receipt.entryKey)return false;
      const wrapper=Array.from(capture.childNodes),declaredWrapper=raw.normalSerializedCaptureNodes;
      if(wrapper.length!==declaredWrapper.length||!same(raw.owner,{namespaceURI:raw.generatedTree.namespaceURI,localName:raw.generatedTree.localName,attributes:raw.generatedTree.attributes}))return false;
      const refs=[];let rootCount=0;
      for(let i=0;i<wrapper.length;i++){
        const actual=wrapper[i],expected=declaredWrapper[i];
        if(actual.parentNode!==capture||!actual.isConnected)return false;
        if(expected.kind==='layout-root'){
          if(!exact(expected,['kind'])||actual!==owner||++rootCount!==1||!node(owner,raw.generatedTree,refs))return false;
        }else{
          if(!exact(expected,['kind','nodeType','text'])||expected.kind!=='formatter-text'||expected.nodeType!==3||actual.nodeType!==3||typeof expected.text!=='string'||actual.textContent!==expected.text)return false;
          refs.push(actual);
        }
      }
      if(rootCount!==1)return false;
      if(initial){snapshots.push(...refs);initial=false;return true;}
      return refs.length===snapshots.length&&refs.every((n,i)=>n===snapshots[i]);
    }catch(_){return false;}
  };
  if(!validateCurrentBinding())return fail('PUBLIC_WRAPPER_CURRENT_GRAPH_CHANGED');
  return {applied:true,registryResultElement:owner,fieldUnitElement:owner,paddingSource:owner,frameSource:owner,
    registryIsLayoutRoot:true,authority:'Original typed public wrapper/current generated root; complete generated opaque and supplied foreign frontiers distinguished; no CSS owner selection',validateCurrentBinding};
}
''';
