import 'dart:convert';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/examples/web/bottom_action_bar/bottom_action_bar_default_example.dart';
import 'package:docs_core/previews/examples/web/bottom_action_bar/bottom_action_bar_horizontal_example.dart';
import 'package:docs_core/previews/examples/web/bottom_action_bar/bottom_action_bar_summary_compact_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

const _kNames = [
  'primaryAction',
  'secondaryAction',
  'description',
  'summaryLabel',
  'summaryValue',
];
const Map<String, (Type, coui.CoreBottomActionBarLayout)> _kRecipes = {
  'default': (
    BottomActionBarDefaultExample,
    coui.CoreBottomActionBarLayout.vertical,
  ),
  'horizontal': (
    BottomActionBarHorizontalExample,
    coui.CoreBottomActionBarLayout.horizontal,
  ),
  'summary-compact': (
    BottomActionBarSummaryCompactExample,
    coui.CoreBottomActionBarLayout.summaryCompact,
  ),
};

/// Passive original-entry source reader. Owned generated DIV grammar has no
/// primitive Text inputs; all supplied Components, including raw Text, remain
/// whole opaque frontiers. Renderer formatting is not a primitive source slot.
class BottomActionBarSsrSource implements CurrentSsrBoxSource {
  BottomActionBarSsrSource._(this.entry, this.exampleType, this.layout);
  static BottomActionBarSsrSource? forEntry(MatrixEntry entry) {
    final claims = entry.probes.where(
      (probe) =>
          probe.boxObservationSource?.logicalUnitId ==
          BoxObservationSourceSpec.bottomActionBarContentInset.logicalUnitId,
    );
    if (claims.isEmpty) return null;
    final recipe = entry.component == 'bottom-action-bar'
        ? _kRecipes[entry.variant]
        : null;
    if (recipe == null ||
        !const ['light', 'dark'].contains(entry.theme.name) ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource !=
            BoxObservationSourceSpec.bottomActionBarContentInset) {
      throw StateError('BOTTOM_ACTION_BAR_CLOSED_SSR_RECIPE_CHANGED');
    }
    return BottomActionBarSsrSource._(entry, recipe.$1, recipe.$2);
  }

  final MatrixEntry entry;
  final Type exampleType;
  final coui.CoreBottomActionBarLayout layout;
  Component? _registry;
  div? _capture;
  List<Object?>? _held;

  @override
  void recordBuild(Component result, div capture) {
    if (_registry != null || _capture != null) {
      throw StateError('BOTTOM_ACTION_BAR_REPEATED_BUILD');
    }
    _registry = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    final before = _read(root);
    if (_held != null && !_same(_held!, before.held)) {
      throw StateError('BOTTOM_ACTION_BAR_HELD_SSR_CHANGED');
    }
    final after = _read(root);
    if (!_same(before.held, after.held) ||
        jsonEncode(before.raw) != jsonEncode(after.raw)) {
      throw StateError('BOTTOM_ACTION_BAR_CURRENT_SSR_CHANGED');
    }
    _held ??= before.held;
    return {
      'kind': 'canonical-ssr-bottom-action-bar-v1',
      'entryKey': entry.key,
      'source': BoxObservationSourceSpec.bottomActionBarContentInset.toJson(),
      'currentRaw': before.raw,
      'completeRawSlotCount': 5,
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
      throw StateError('BOTTOM_ACTION_BAR_ORIGINAL_CAPTURE_CHANGED');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    final example = currentSsrIdentityElement(root, registry);
    if (!identical(example.parent, captureDom)) {
      throw StateError('BOTTOM_ACTION_BAR_REGISTRY_EDGE_CHANGED');
    }
    final producer = soleCurrentSsrChild(example);
    if (producer.component.runtimeType != coui.BottomActionBar) {
      throw StateError('BOTTOM_ACTION_BAR_EXACT_PUBLIC_PRODUCT_REQUIRED');
    }
    final input = producer.component as coui.BottomActionBar;
    if (input.tag != 'div' || input.layout != layout) {
      throw StateError('BOTTOM_ACTION_BAR_LAYOUT_CHANGED');
    }
    final returned = soleCurrentSsrChild(producer);
    if (returned.component.runtimeType != div) {
      throw StateError('BOTTOM_ACTION_BAR_PUBLIC_DIV_REQUIRED');
    }
    final declaration = returned.component as div;
    final owner = currentSsrGeneratedDiv(returned, declaration);
    final held = <Object?>[
      captureElement,
      capture,
      captureDom,
      example,
      registry,
      producer,
      input,
      returned,
      declaration,
      owner,
      _markup(owner),
      input.layout,
    ];
    final raw = <Component?>[
      input.primaryAction,
      input.secondaryAction,
      input.description,
      input.summaryLabel,
      input.summaryValue,
    ];
    held.addAll(raw);
    final active = [
      true,
      layout != .summaryCompact,
      true,
      layout == .summaryCompact,
      layout == .summaryCompact,
    ];
    final seats = <int, Element>{};
    final seatOf = Map<Element, int>.identity();
    void foreign(Element element, int index) {
      if (!active[index] ||
          raw[index] == null ||
          !identical(element.component, raw[index]) ||
          seats.containsKey(index) ||
          seatOf.containsKey(element)) {
        throw StateError('BOTTOM_ACTION_BAR_FOREIGN_SEAT_CHANGED');
      }
      seats[index] = element;
      seatOf[element] = index;
      held.addAll([element, element.component]);
    }

    Element generatedDiv(Element element) {
      if (element.component.runtimeType != div) {
        throw StateError('BOTTOM_ACTION_BAR_GENERATED_DIV_CHANGED');
      }
      held.addAll([element, element.component]);
      final dom = currentSsrGeneratedDiv(element, element.component as div);
      held.addAll([dom, dom.component, _markup(dom)]);
      return dom;
    }

    List<Element> children(Element element, List<Component> declared) {
      final current = _children(element);
      if (current.length != declared.length ||
          [
            for (var i = 0; i < declared.length; i++)
              identical(current[i].component, declared[i]) &&
                  identical(current[i].parent, element),
          ].any((same) => !same)) {
        throw StateError('BOTTOM_ACTION_BAR_COMPLETE_CHILD_LIST_CHANGED');
      }
      return current;
    }

    List<Element> declaredChildren(Element dom) {
      final component = dom.component;
      if (component is! DomComponent ||
          component.tag != 'div' ||
          component.children == null) {
        throw StateError('BOTTOM_ACTION_BAR_GENERATED_DOM_CHANGED');
      }
      return children(dom, component.children!);
    }

    final top = children(owner, declaration.children);
    var index = 0;
    if (input.description != null) {
      final description = declaredChildren(generatedDiv(top[index++]));
      if (description.length != 1) {
        throw StateError('BOTTOM_ACTION_BAR_DESCRIPTION_CHANGED');
      }
      foreign(description.single, 2);
    }
    if (top.length != index + 1) {
      throw StateError('BOTTOM_ACTION_BAR_ROOT_FRONTIER_CHANGED');
    }
    final actions = declaredChildren(generatedDiv(top[index]));
    if (layout == .vertical) {
      if (actions.length != 1 + (input.secondaryAction == null ? 0 : 1)) {
        throw StateError('BOTTOM_ACTION_BAR_VERTICAL_FRONTIER_CHANGED');
      }
      foreign(actions[0], 0);
      if (input.secondaryAction != null) foreign(actions[1], 1);
    } else if (layout == .horizontal) {
      if (actions.length != 1 + (input.secondaryAction == null ? 0 : 1)) {
        throw StateError('BOTTOM_ACTION_BAR_HORIZONTAL_FRONTIER_CHANGED');
      }
      for (var i = 0; i < actions.length; i++) {
        final cell = declaredChildren(generatedDiv(actions[i]));
        if (cell.length != 1) {
          throw StateError('BOTTOM_ACTION_BAR_ACTION_CELL_CHANGED');
        }
        foreign(cell.single, input.secondaryAction != null && i == 0 ? 1 : 0);
      }
    } else {
      if (actions.length != 2) {
        throw StateError('BOTTOM_ACTION_BAR_SUMMARY_FRONTIER_CHANGED');
      }
      final grow = declaredChildren(generatedDiv(actions[0]));
      final fixed = declaredChildren(generatedDiv(actions[1]));
      if (fixed.length != 1) {
        throw StateError('BOTTOM_ACTION_BAR_PRIMARY_CELL_CHANGED');
      }
      foreign(fixed.single, 0);
      final present = [
        if (input.summaryLabel != null) 3,
        if (input.summaryValue != null) 4,
      ];
      if (grow.length != (present.isEmpty ? 0 : 1)) {
        throw StateError('BOTTOM_ACTION_BAR_SUMMARY_PRESENCE_CHANGED');
      }
      if (present.isNotEmpty) {
        final summary = declaredChildren(generatedDiv(grow.single));
        if (summary.length != present.length) {
          throw StateError('BOTTOM_ACTION_BAR_SUMMARY_SEATS_CHANGED');
        }
        for (var i = 0; i < summary.length; i++) {
          final label = declaredChildren(generatedDiv(summary[i]));
          if (label.length != 1) {
            throw StateError('BOTTOM_ACTION_BAR_SUMMARY_LABEL_CHANGED');
          }
          foreign(label.single, present[i]);
        }
      }
    }
    if (seats.length !=
        [
          for (var i = 0; i < 5; i++)
            if (active[i] && raw[i] != null) i,
        ].length) {
      throw StateError('BOTTOM_ACTION_BAR_WHOLE_FIVE_SEAT_CLOSURE_CHANGED');
    }
    final frontiers = <int, List<Map<String, Object?>>>{};
    final orders = <int, List<int>>{};
    var frontierOrdinal = 0;
    Map<String, Object?> tree(Element dom) {
      final component = dom.component as DomComponent;
      final kids = children(dom, component.children ?? const []);
      final markup = _markup(dom);
      final attrs = _literalAttributes(markup);
      held.addAll([dom, component, markup]);
      return {
        'namespaceURI': 'http://www.w3.org/1999/xhtml',
        'localName': 'div',
        'attributes': attrs,
        'children': [
          for (final child in kids)
            if (seatOf[child] case final seat?)
              (() {
                final nodes = [
                  for (final render in _frontier(child))
                    ..._opaque(render, held),
                ];
                frontiers[seat] = nodes;
                orders[seat] = [for (final _ in nodes) frontierOrdinal++];
                return <String, Object?>{'foreignSeat': seat, 'nodes': nodes};
              })()
            else
              tree(generatedDiv(child)),
        ],
      };
    }

    final generated = tree(owner);
    return (
      held: held,
      raw: {
        'kind': 'current-bottom-action-bar-raw-v1',
        'logicalUnitId':
            BoxObservationSourceSpec.bottomActionBarContentInset.logicalUnitId,
        'layout': layout.name,
        'rawSlotCount': 5,
        'declaredSeats': [
          for (var i = 0; i < 5; i++)
            {
              'index': i,
              'slot': _kNames[i],
              'present': raw[i] != null,
              'layoutActive': active[i],
              'mounted': seats.containsKey(i),
              'sourceAliasOf': raw[i] == null
                  ? null
                  : [
                      for (var j = 0; j < i; j++)
                        if (identical(raw[j], raw[i])) j,
                    ].firstOrNull,
              'frontierOrder': orders[i] ?? <int>[],
              'nodes': frontiers[i] ?? <Object?>[],
            },
        ],
        'owner': {
          'namespaceURI': generated['namespaceURI'],
          'localName': generated['localName'],
          'attributes': generated['attributes'],
        },
        'generatedTree': generated,
      },
    );
  }
}

List<Element> _children(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  return children;
}

MarkupRenderObject _markup(Element element) {
  if (element is! RenderObjectElement ||
      element.renderObject is! MarkupRenderObject) {
    throw StateError('BOTTOM_ACTION_BAR_CURRENT_MARKUP_REQUIRED');
  }
  return element.renderObject as MarkupRenderObject;
}

Map<String, String> _literalAttributes(MarkupRenderObject markup) {
  final parsed = html.parseFragment(markup.renderToHtml());
  if (parsed.children.length != 1 ||
      parsed.children.single.localName != 'div') {
    throw StateError('BOTTOM_ACTION_BAR_OWNED_LITERAL_DIV_CHANGED');
  }
  return {
    for (final a in parsed.children.single.attributes.entries)
      a.key.toString(): a.value,
  };
}

List<MarkupRenderObject> _frontier(Element element) =>
    element is RenderObjectElement
    ? [_markup(element)]
    : [for (final child in _children(element)) ..._frontier(child)];
List<Map<String, Object?>> _opaque(
  MarkupRenderObject render,
  List<Object?> held,
) {
  held.add(render);
  if (render is MarkupRenderFragment) {
    return [for (final child in render.children) ..._opaque(child, held)];
  }
  if (render is MarkupRenderElement || render is MarkupRenderText) {
    // Parse only the top-level frontier. Never inspect descendants or text
    // data.
    return [
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
          throw StateError('BOTTOM_ACTION_BAR_FOREIGN_FRONTIER_CHANGED'),
    ];
  }
  throw StateError('BOTTOM_ACTION_BAR_UNKNOWN_OPAQUE_FRONTIER');
}

bool _same(List<Object?> a, List<Object?> b) =>
    a.length == b.length &&
    [
      for (var i = 0; i < a.length; i++) identical(a[i], b[i]),
    ].every((same) => same);

String? requiredBottomActionBarSsrKind(MatrixEntry entry) =>
    BottomActionBarSsrSource.forEntry(entry) == null
    ? null
    : 'canonical-ssr-bottom-action-bar-v1';

/// Closed request binding only. Measurement reads CSS afterwards in the
/// existing shared sampler. No foreign interior or style resolver is read here.
String get bottomActionBarRequestBindingScript =>
    '''
(request) => {
  const unit='bottom-action-bar-owned-content-inset';
  const source=request.source;
  const claims=source?.logicalUnitId===unit || source?.webAdapterId==='bottom-action-bar-owned-content-inset-v1' ||
    request.requiredCurrentSsrKind==='canonical-ssr-bottom-action-bar-v1';
  if(!claims || !request.requested) return {applied:false};
  const fail=error=>({error});
  const exact=(v,keys)=>v && typeof v==='object' && !Array.isArray(v) &&
    Object.keys(v).length===keys.length && keys.every(k=>Object.hasOwn(v,k));
  const tuple=${jsonEncode(BoxObservationSourceSpec.bottomActionBarContentInset.toJson())};
  const tupleMatches=v=>exact(v,Object.keys(tuple))&&Object.keys(tuple).every(k=>v[k]===tuple[k]);
  const receipt=request.currentSsrSource;
  if(request.requested!==true || request.requiredCurrentSsrKind!=='canonical-ssr-bottom-action-bar-v1' ||
     !tupleMatches(source) || typeof request.selector!=='string' || !request.selector ||
     typeof request.layoutSelector!=='string' || !request.layoutSelector)
    return fail('BOTTOM_ACTION_BAR_REQUIREMENT_CHANGED');
  if(!exact(receipt,['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL']) ||
     receipt.kind!=='canonical-ssr-bottom-action-bar-v1' || !tupleMatches(receipt.source) ||
     typeof receipt.entryKey!=='string' || receipt.entryKey.length===0 ||
     receipt.harnessURL!==location.href || receipt.completeRawSlotCount!==5 ||
     receipt.rawOrderFromPublicProducerLists!==true)
    return fail('BOTTOM_ACTION_BAR_CURRENT_HEADER_CHANGED');
  const raw=receipt.currentRaw;
  if(!exact(raw,['kind','logicalUnitId','layout','rawSlotCount','declaredSeats','owner','generatedTree']) ||
     raw.kind!=='current-bottom-action-bar-raw-v1' || raw.logicalUnitId!==unit || raw.rawSlotCount!==5 ||
     !['vertical','horizontal','summaryCompact'].includes(raw.layout) ||
     !Array.isArray(raw.declaredSeats) || raw.declaredSeats.length!==5)
    return fail('BOTTOM_ACTION_BAR_COMPLETE_RAW_REQUIRED');
  const names=['primaryAction','secondaryAction','description','summaryLabel','summaryValue'];
  const active=[true,raw.layout!=='summaryCompact',true,raw.layout==='summaryCompact',raw.layout==='summaryCompact'];
  const validShape=n=>exact(n,n?.nodeType===1?['nodeType','namespaceURI','localName']:['nodeType']) &&
    ([3,8].includes(n.nodeType) || n.nodeType===1 && typeof n.namespaceURI==='string' && typeof n.localName==='string');
  for(let i=0;i<5;i++) {
    const seat=raw.declaredSeats[i];
    if(!exact(seat,['index','slot','present','layoutActive','mounted','sourceAliasOf','frontierOrder','nodes']) ||
       seat.index!==i || seat.slot!==names[i] || typeof seat.present!=='boolean' || seat.layoutActive!==active[i] ||
       seat.mounted!==(seat.present&&active[i]) || !Array.isArray(seat.nodes) || !seat.nodes.every(validShape) ||
       !Array.isArray(seat.frontierOrder) || seat.frontierOrder.length!==seat.nodes.length ||
       seat.frontierOrder.some(n=>!Number.isInteger(n)||n<0) ||
       (!seat.mounted && (seat.nodes.length!==0||seat.frontierOrder.length!==0)) ||
       !(seat.sourceAliasOf===null || seat.present && Number.isInteger(seat.sourceAliasOf) &&
         seat.sourceAliasOf>=0 && seat.sourceAliasOf<i && raw.declaredSeats[seat.sourceAliasOf].present))
      return fail('BOTTOM_ACTION_BAR_DECLARED_SEAT_CHANGED');
  }
  if(!raw.declaredSeats[0].present) return fail('BOTTOM_ACTION_BAR_PRIMARY_REQUIRED');
  let fields,roots;
  try {fields=Array.from(document.querySelectorAll(request.selector));roots=Array.from(document.querySelectorAll(request.layoutSelector));}
  catch(error){return fail('BOTTOM_ACTION_BAR_INVALID_SELECTOR');}
  if(fields.length!==1||roots.length!==1||fields[0]!==roots[0])
    return fail('BOTTOM_ACTION_BAR_UNIQUE_CURRENT_ROOT_REQUIRED');
  const owner=roots[0],capture=owner.parentElement,htmlNS='http://www.w3.org/1999/xhtml';
  const ascii=n=>n?.nodeType===3&&/^[\\t\\n\\f\\r ]*\$/.test(n.data);
  if(!capture || capture.namespaceURI!==htmlNS || capture.localName!=='div' ||
     capture.getAttribute('data-parity-key')!==receipt.entryKey ||
     capture.children.length!==1||capture.children[0]!==owner ||
     Array.from(capture.childNodes).some(node=>node!==owner&&!ascii(node)) || !owner.isConnected ||
     owner.namespaceURI!==htmlNS||owner.localName!=='div')
    return fail('BOTTOM_ACTION_BAR_CAPTURE_CHANGED');
  const attrsMatch=(node,attrs)=>attrs&&typeof attrs==='object'&&!Array.isArray(attrs) &&
    Array.from(node.attributes).length===Object.keys(attrs).length &&
    Array.from(node.attributes).every(a=>typeof attrs[a.name]==='string'&&attrs[a.name]===a.value);
  if(!exact(raw.owner,['namespaceURI','localName','attributes'])||raw.owner.namespaceURI!==htmlNS||
     raw.owner.localName!=='div'||!attrsMatch(owner,raw.owner.attributes))
    return fail('BOTTOM_ACTION_BAR_OWNER_LITERAL_CHANGED');
  const own=[],foreign=[],format=[],used=new Set(),orders=[];
  const shapeMatches=(n,s)=>n?.nodeType===s.nodeType &&
    (s.nodeType!==1 || n.namespaceURI===s.namespaceURI&&n.localName===s.localName);
  const matchOwned=(node,tree)=>{
    if(!exact(tree,['namespaceURI','localName','attributes','children'])||tree.namespaceURI!==htmlNS||tree.localName!=='div'||
       node?.nodeType!==1||node.namespaceURI!==htmlNS||node.localName!=='div'||
       !attrsMatch(node,tree.attributes)||!Array.isArray(tree.children))return false;
    own.push({node,children:Array.from(node.childNodes),attrs:JSON.stringify(Array.from(node.attributes).map(a=>[a.name,a.value]))});
    const nodes=Array.from(node.childNodes);let at=0;
    const skipFormat=()=>{while(ascii(nodes[at])) {format.push({node:nodes[at],data:nodes[at].data});at++;}};
    for(const child of tree.children) {
      if(Object.hasOwn(child,'foreignSeat')) {
        if(!exact(child,['foreignSeat','nodes'])||!Number.isInteger(child.foreignSeat)||child.foreignSeat<0||child.foreignSeat>4||used.has(child.foreignSeat))return false;
        const seat=raw.declaredSeats[child.foreignSeat];
        if(!seat.mounted||JSON.stringify(child.nodes)!==JSON.stringify(seat.nodes))return false;
        used.add(child.foreignSeat);
        for(let i=0;i<child.nodes.length;i++) {
          const shape=child.nodes[i];
          if(shape.nodeType!==3)skipFormat();
          if(!shapeMatches(nodes[at],shape))return false;
          foreign.push({node:nodes[at],parent:node,shape});orders.push(seat.frontierOrder[i]);at++;
        }
      } else {
        skipFormat();if(!matchOwned(nodes[at],child))return false;at++;
      }
    }
    skipFormat();return at===nodes.length;
  };
  if(!matchOwned(owner,raw.generatedTree)||raw.declaredSeats.some((s,i)=>s.mounted!==used.has(i))||
     orders.some((n,i)=>n!==i)) return fail('BOTTOM_ACTION_BAR_COMPLETE_FRONTIER_CHANGED');
  // Only generated DIVs have formatter separator Text. Primitive supplied Text
  // was consumed as an opaque seat above and its data is never read as source.
  const same=(a,b)=>a.length===b.length&&a.every((v,i)=>v===b[i]);
  const records=v=>v&&typeof v==='object'?[v,...Object.values(v).flatMap(records)]:[];
  const heldRecords=records(receipt),receiptJSON=JSON.stringify(receipt),sourceJSON=JSON.stringify(source);
  const selector=request.selector,layoutSelector=request.layoutSelector,url=location.href;
  const captureChildren=Array.from(capture.childNodes),captureAttrs=JSON.stringify(Array.from(capture.attributes).map(a=>[a.name,a.value]));
  const validateCurrentBinding=()=>{
    try {
      const nowFields=Array.from(document.querySelectorAll(selector)),nowRoots=Array.from(document.querySelectorAll(layoutSelector));
      return nowFields.length===1&&nowRoots.length===1&&nowFields[0]===owner&&nowRoots[0]===owner&&
        request.requested===true&&request.requiredCurrentSsrKind==='canonical-ssr-bottom-action-bar-v1'&&
        request.selector===selector&&request.layoutSelector===layoutSelector&&request.source===source&&request.currentSsrSource===receipt&&location.href===url&&
        JSON.stringify(source)===sourceJSON&&JSON.stringify(receipt)===receiptJSON&&same(records(receipt),heldRecords)&&
        capture.isConnected&&owner.parentElement===capture&&same(Array.from(capture.childNodes),captureChildren)&&
        JSON.stringify(Array.from(capture.attributes).map(a=>[a.name,a.value]))===captureAttrs&&
        own.every(x=>x.node.isConnected&&same(Array.from(x.node.childNodes),x.children)&&JSON.stringify(Array.from(x.node.attributes).map(a=>[a.name,a.value]))===x.attrs)&&
        foreign.every(x=>x.node.isConnected&&x.node.parentNode===x.parent&&shapeMatches(x.node,x.shape))&&
        format.every(x=>x.node.data===x.data);
    }catch(error){return false;}
  };
  if(!validateCurrentBinding())return fail('BOTTOM_ACTION_BAR_CURRENT_BINDING_CHANGED');
  return {applied:true,registryResultElement:owner,fieldUnitElement:owner,paddingSource:owner,frameSource:owner,
    registryIsLayoutRoot:true,validateCurrentBinding,
    authority:'original public BottomActionBar root DIV; complete own content CSS including actual env; five raw seats and opaque active frontiers'};
}
''';
