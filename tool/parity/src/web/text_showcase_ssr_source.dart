import 'dart:convert';

import 'package:docs_core/previews/examples/web/text/text_colors_brand_example.dart';
import 'package:docs_core/previews/examples/web/text/text_colors_status_example.dart';
import 'package:docs_core/previews/examples/web/text/text_colors_surface_example.dart';
import 'package:docs_core/previews/examples/web/text/text_keep_all_example.dart';
import 'package:docs_core/previews/examples/web/text/text_modifiers_example.dart';
import 'package:docs_core/previews/examples/web/text/text_opacity_example.dart';
import 'package:docs_core/previews/examples/web/text/text_rich_example.dart';
import 'package:docs_core/previews/examples/web/text/text_textstyle_example.dart';
import 'package:docs_core/previews/examples/web/text/text_typography_body_example.dart';
import 'package:docs_core/previews/examples/web/text/text_typography_display_example.dart';
import 'package:docs_core/previews/examples/web/text/text_typography_headline_example.dart';
import 'package:docs_core/previews/examples/web/text/text_typography_primitive_example.dart';
import 'package:docs_core/previews/examples/web/text/text_typography_title_example.dart';
import 'package:docs_core/previews/examples/web/text/text_typography_weight_example.dart';
import 'package:docs_core/previews/examples/web/text/text_wrap_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

/// The exact declared Example's outer allocation, never Text ink, spans or
/// line boxes. The original declaration children remain opaque boundaries.
const _kExampleTypes = <String, Type>{
  'typography-display': TextTypographyDisplayExample,
  'typography-headline': TextTypographyHeadlineExample,
  'typography-title': TextTypographyTitleExample,
  'typography-body': TextTypographyBodyExample,
  'typography-weight': TextTypographyWeightExample,
  'typography-primitive': TextTypographyPrimitiveExample,
  'colors-brand': TextColorsBrandExample,
  'colors-status': TextColorsStatusExample,
  'colors-surface': TextColorsSurfaceExample,
  'modifiers': TextModifiersExample,
  'wrap': TextWrapExample,
  'keep-all': TextKeepAllExample,
  'textstyle': TextTextstyleExample,
  'opacity': TextOpacityExample,
  'rich': TextRichExample,
};

/// Observes one original registry mount. Production requires an exact declared
/// source. An undeclared entry never borrows source authority.
class TextShowcaseSsrSource implements CurrentSsrBoxSource {
  TextShowcaseSsrSource._(this.entry, this.exampleType);

  static TextShowcaseSsrSource? forEntry(MatrixEntry entry) {
    const expected = BoxObservationSourceSpec.textShowcaseOuterPadding;
    final closed =
        entry.component == 'text' && _kExampleTypes.containsKey(entry.variant);
    final claims = entry.probes.where(
      (probe) =>
          probe.boxObservationSource?.logicalUnitId == expected.logicalUnitId,
    );
    if (claims.isEmpty && !closed) return null;
    if (claims.isEmpty &&
        entry.probes.every(
          (probe) => probe.boxObservationSource == null,
        )) {
      return null;
    }
    if (!closed ||
        !const ['light', 'dark'].contains(entry.theme.name) ||
        entry.probes.length != 1 ||
        entry.probes.single.role != 'root' ||
        entry.probes.single.boxObservationSource != expected) {
      throw StateError('TEXT_SHOWCASE_DECLARED_SOURCE_CHANGED');
    }
    return TextShowcaseSsrSource._(
      entry,
      _kExampleTypes[entry.variant]!,
    );
  }

  final MatrixEntry entry;
  final Type exampleType;
  Component? _registry;
  div? _capture;
  _Current? _bound;

  @override
  void recordBuild(Component result, div capture) {
    if (_registry != null || _capture != null) {
      throw StateError('TEXT_SHOWCASE_BUILD_REPEATED');
    }
    _registry = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    final current = _locate(root);
    final held = _bound;
    if (held != null && !held.sameIdentities(current)) {
      throw StateError('TEXT_SHOWCASE_HELD_BINDING_STALE');
    }
    final markup = _markup(current.owner);
    final before = markup.renderToHtml();
    final parsed = _singleRoot(before);
    final slots = <Map<String, Object?>>[
      for (final child in current.children)
        {
          'nodes': [
            for (final frontier in _renderFrontier(child))
              ..._opaqueNodes(frontier),
          ],
        },
    ];
    _matchNodes(
      parsed.nodes,
      [for (final slot in slots) ...(slot['nodes']! as List)],
    );
    if (!current.sameIdentities(_locate(root)) ||
        markup.renderToHtml() != before) {
      throw StateError('TEXT_SHOWCASE_CURRENT_SOURCE_CHANGED');
    }
    _bound ??= current;
    return {
      'kind': 'canonical-ssr-text-showcase-v1',
      'entryKey': entry.key,
      'source': BoxObservationSourceSpec.textShowcaseOuterPadding.toJson(),
      'currentRaw': {
        'kind': 'current-text-showcase-raw-v1',
        'logicalUnitId':
            BoxObservationSourceSpec.textShowcaseOuterPadding.logicalUnitId,
        'rawSlotCount': current.raw.length,
        // A Component.empty() is still a supplied declaration and has a slot.
        // Its zero DOM frontier is recorded in slots, not omitted from raw.
        'slotPresence': [for (final _ in current.raw) true],
        'opaqueSlots': slots,
        'owner': {
          'namespaceURI': parsed.namespaceUri,
          'localName': parsed.localName,
          'attributes': {
            for (final attribute in parsed.attributes.entries)
              attribute.key.toString(): attribute.value,
          },
        },
        // Already read actual markup is retained for a future independent
        // decoder. It is evidence, not a source of expected padding values.
        'actualOwnerMarkup': before,
      },
      'completeRawSlotCount': current.raw.length,
      'rawOrderFromPublicProducerLists': true,
    };
  }

  _Current _locate(Element root) {
    final registry = _registry;
    final capture = _capture;
    if (registry == null ||
        capture == null ||
        registry.runtimeType != exampleType ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw StateError('TEXT_SHOWCASE_ORIGINAL_CAPTURE_CHANGED');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    final example = currentSsrIdentityElement(root, registry);
    if (!identical(example.parent, captureDom)) {
      throw StateError('TEXT_SHOWCASE_REGISTRY_EDGE_CHANGED');
    }
    // The only owner route is this exact Example's direct typed DIV. Foreign
    // frontier walks below can never supply or replace this owner.
    final returned = soleCurrentSsrChild(example);
    if (returned.component.runtimeType != div) {
      throw StateError('TEXT_SHOWCASE_DIRECT_DIV_REQUIRED');
    }
    final declaration = returned.component as div;
    final raw = List<Component>.unmodifiable(declaration.children);
    final identities = Set<Component>.identity();
    for (final child in raw) {
      if (identical(child, registry) ||
          identical(child, capture) ||
          identical(child, declaration) ||
          (!identities.add(child) && !_emptyFragment(child))) {
        throw StateError('TEXT_SHOWCASE_RAW_ALIAS');
      }
    }
    final owner = currentSsrGeneratedDiv(returned, declaration);
    final children = _children(owner);
    if (children.length != raw.length ||
        List.generate(
          raw.length,
          (i) =>
              identical(children[i].component, raw[i]) &&
              identical(children[i].parent, owner),
        ).any((same) => !same)) {
      throw StateError('TEXT_SHOWCASE_DECLARED_ORDER_CHANGED');
    }
    final mounted = Set<Element>.identity();
    for (var i = 0; i < raw.length; i++) {
      if (!mounted.add(children[i])) {
        throw StateError('TEXT_SHOWCASE_MOUNTED_SLOT_ALIAS');
      }
      if (_emptyFragment(raw[i])) {
        final frontier = _renderFrontier(children[i]);
        if (frontier.length != 1 ||
            frontier.single is! MarkupRenderFragment ||
            frontier.single.children.isNotEmpty) {
          throw StateError('TEXT_SHOWCASE_DECLARED_EMPTY_FRONTIER_CHANGED');
        }
      }
    }
    _renderChildrenMatch(owner, children);
    _renderChildrenMatch(captureDom, [example]);
    return _Current(
      captureElement,
      example,
      returned,
      declaration,
      owner,
      raw,
      children,
    );
  }
}

class _Current {
  _Current(
    this.capture,
    this.example,
    this.returned,
    this.declaration,
    this.owner,
    this.raw,
    this.children,
  );

  final Element capture;
  final Element example;
  final Element returned;
  final div declaration;
  final Element owner;
  final List<Component> raw;
  final List<Element> children;

  bool sameIdentities(_Current other) =>
      identical(capture, other.capture) &&
      identical(example, other.example) &&
      identical(returned, other.returned) &&
      identical(declaration, other.declaration) &&
      identical(owner, other.owner) &&
      raw.length == other.raw.length &&
      children.length == other.children.length &&
      List.generate(
        raw.length,
        (i) =>
            identical(raw[i], other.raw[i]) &&
            identical(children[i], other.children[i]),
      ).every((same) => same);
}

List<Element> _children(Element element) {
  final result = <Element>[];
  element.visitChildren(result.add);
  return result;
}

bool _emptyFragment(Component component) =>
    component.runtimeType == Fragment &&
    (component as Fragment).children.isEmpty;

List<MarkupRenderObject> _renderFrontier(Element element) {
  if (element is RenderObjectElement) {
    return [_markup(element)];
  }
  return [for (final child in _children(element)) ..._renderFrontier(child)];
}

MarkupRenderObject _markup(Element element) {
  if (element is! RenderObjectElement ||
      element.renderObject is! MarkupRenderObject) {
    throw StateError('TEXT_SHOWCASE_PUBLIC_MARKUP_REQUIRED');
  }
  return element.renderObject as MarkupRenderObject;
}

void _renderChildrenMatch(Element owner, List<Element> declared) {
  final expected = [
    for (final child in declared) ..._renderFrontier(child),
  ];
  final markup = _markup(owner);
  final actual = markup.children.toList(growable: false);
  if (actual.length != expected.length ||
      (Set<MarkupRenderObject>.identity()..addAll(expected)).length !=
          expected.length ||
      List.generate(
        expected.length,
        (i) =>
            identical(actual[i], expected[i]) &&
            identical(actual[i].parent, markup),
      ).any((same) => !same)) {
    throw StateError('TEXT_SHOWCASE_UNDECLARED_RENDER_NODE');
  }
}

final _asciiWhitespace = RegExp(r'^[\t\n\f\r ]*$');

dom.Element _singleRoot(String markup) {
  final fragment = html.parseFragment(markup);
  if (fragment.children.length != 1 ||
      fragment.children.single.localName != 'div' ||
      fragment.children.single.namespaceUri != 'http://www.w3.org/1999/xhtml' ||
      fragment.nodes.any(
        (node) =>
            !identical(node, fragment.children.single) &&
            !(node is dom.Text && _asciiWhitespace.hasMatch(node.data)),
      )) {
    throw StateError('TEXT_SHOWCASE_WHOLE_OWNER_MARKUP_CHANGED');
  }
  return fragment.children.single;
}

// Stop at each foreign element. Only a public Fragment's top-level frontier
// is flattened; no Text/chain/WidgetSpan/foreign element interior is probed.
List<Map<String, Object?>> _opaqueNodes(MarkupRenderObject render) {
  if (render is MarkupRenderFragment) {
    return [for (final child in render.children) ..._opaqueNodes(child)];
  }
  if (render is! MarkupRenderElement && render is! MarkupRenderText) {
    throw StateError('TEXT_SHOWCASE_OPAQUE_FRONTIER_UNSUPPORTED');
  }
  return [
    for (final node in html.parseFragment(render.renderToHtml()).nodes)
      _shape(node),
  ];
}

Map<String, Object?> _shape(dom.Node node) {
  if (node is dom.Element) {
    return {
      'nodeType': node.nodeType,
      'namespaceURI': node.namespaceUri,
      'localName': node.localName,
    };
  }
  if (node is dom.Text || node is dom.Comment) {
    return {'nodeType': node.nodeType};
  }
  throw StateError('TEXT_SHOWCASE_OPAQUE_NODE_KIND_UNSUPPORTED');
}

void _matchNodes(List<dom.Node> actual, List<Object?> expected) {
  var index = 0;
  for (final value in expected) {
    final shape = value! as Map;
    // Explicitly declared text, including whitespace, consumes a real text
    // node. Only formatter whitespace outside such a boundary may be skipped.
    while (index < actual.length &&
        shape['nodeType'] != 3 &&
        actual[index] is dom.Text &&
        _asciiWhitespace.hasMatch((actual[index] as dom.Text).data)) {
      index++;
    }
    if (index == actual.length ||
        jsonEncode(_shape(actual[index])) != jsonEncode(shape)) {
      throw StateError('TEXT_SHOWCASE_OPAQUE_NODE_ORDER_CHANGED');
    }
    index++;
  }
  if (actual
      .skip(index)
      .any(
        (node) => !(node is dom.Text && _asciiWhitespace.hasMatch(node.data)),
      )) {
    throw StateError('TEXT_SHOWCASE_UNDECLARED_OWNER_CONTENT');
  }
}

/// This requirement is a descriptor, not evidence of a mounted producer.
String? requiredTextShowcaseSsrKind(MatrixEntry entry) =>
    TextShowcaseSsrSource.forEntry(entry) == null
    ? null
    : 'canonical-ssr-text-showcase-v1';

String get textShowcaseBoxSourceResolverScript =>
    '''
(layoutRoot, source, receipt) => {
  const fail = error => ({error});
  const keys = (value, expected) => value && typeof value === 'object' &&
    !Array.isArray(value) && Object.keys(value).length === expected.length &&
    expected.every(key => Object.hasOwn(value,key));
  const same = (a,b) => keys(a,Object.keys(b)) &&
    Object.keys(b).every(key => a[key] === b[key]);
  if (!same(source,${jsonEncode(BoxObservationSourceSpec.textShowcaseOuterPadding.toJson())}))
    return fail('TEXT_SHOWCASE_DECLARED_SOURCE_CHANGED');
  if (!keys(receipt,['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL']) ||
      receipt.kind !== 'canonical-ssr-text-showcase-v1' ||
      typeof receipt.entryKey !== 'string' || receipt.entryKey.length === 0 ||
      !same(receipt.source,source) || receipt.rawOrderFromPublicProducerLists !== true ||
      typeof location === 'undefined' || receipt.harnessURL !== location.href)
    return fail('TEXT_SHOWCASE_ACTUAL_SSR_RECEIPT_REQUIRED');
  const htmlNS = 'http://www.w3.org/1999/xhtml';
  const div = node => node && node.nodeType === 1 &&
    node.namespaceURI === htmlNS && node.localName === 'div';
  const ascii = node => node.nodeType === 3 && /^[\\t\\n\\f\\r ]*\$/.test(node.data);
  const capture = layoutRoot && layoutRoot.parentElement;
  if (!div(layoutRoot) || !layoutRoot.isConnected || !div(capture) ||
      capture.getAttribute('data-parity-key') !== receipt.entryKey ||
      capture.children.length !== 1 || capture.children[0] !== layoutRoot ||
      Array.from(capture.childNodes).some(node => node !== layoutRoot && !ascii(node)))
    return fail('TEXT_SHOWCASE_CANONICAL_ROOT_CHANGED');
  const raw = receipt.currentRaw;
  if (!keys(raw,['kind','logicalUnitId','rawSlotCount','slotPresence','opaqueSlots','owner','actualOwnerMarkup']) ||
      raw.kind !== 'current-text-showcase-raw-v1' ||
      raw.logicalUnitId !== source.logicalUnitId ||
      !Number.isInteger(raw.rawSlotCount) || raw.rawSlotCount < 0 ||
      receipt.completeRawSlotCount !== raw.rawSlotCount ||
      !Array.isArray(raw.slotPresence) || raw.slotPresence.length !== raw.rawSlotCount ||
      !raw.slotPresence.every(value => value === true) ||
      !Array.isArray(raw.opaqueSlots) || raw.opaqueSlots.length !== raw.rawSlotCount ||
      typeof raw.actualOwnerMarkup !== 'string' || !raw.actualOwnerMarkup ||
      !keys(raw.owner,['namespaceURI','localName','attributes']) ||
      raw.owner.namespaceURI !== htmlNS || raw.owner.localName !== 'div' ||
      !raw.owner.attributes || typeof raw.owner.attributes !== 'object' || Array.isArray(raw.owner.attributes))
    return fail('TEXT_SHOWCASE_COMPLETE_RAW_REQUIRED');
  const attributes = Array.from(layoutRoot.attributes);
  if (attributes.length !== Object.keys(raw.owner.attributes).length ||
      attributes.some(attribute => raw.owner.attributes[attribute.name] !== attribute.value))
    return fail('TEXT_SHOWCASE_OWNER_IDENTITY_CHANGED');
  const nodes = Array.from(layoutRoot.childNodes);
  let index = 0;
  for (const slot of raw.opaqueSlots) {
    if (!keys(slot,['nodes']) || !Array.isArray(slot.nodes)) return fail('TEXT_SHOWCASE_RAW_SLOT_CHANGED');
    for (const shape of slot.nodes) {
      if (!shape || ![1,3,8].includes(shape.nodeType) ||
          !keys(shape,shape.nodeType === 1 ? ['nodeType','namespaceURI','localName'] : ['nodeType']))
        return fail('TEXT_SHOWCASE_RAW_FRONTIER_CHANGED');
      while (index < nodes.length && shape.nodeType !== 3 && ascii(nodes[index])) index++;
      const node = nodes[index++];
      if (!node || node === layoutRoot || node === capture || node.nodeType !== shape.nodeType ||
          (shape.nodeType === 1 && (node.namespaceURI !== shape.namespaceURI || node.localName !== shape.localName)))
        return fail('TEXT_SHOWCASE_OPAQUE_ORDER_CHANGED');
    }
  }
  if (nodes.slice(index).some(node => !ascii(node))) return fail('TEXT_SHOWCASE_EXTRA_OWNER_CONTENT');
  // actualOwnerMarkup is archived evidence for an independent decoder. This
  // script checks the typed owner/frontier protocol, not full HTML equivalence.
  const ownerRecord=raw.owner,ownerAttributes=raw.owner.attributes;
  const presence=raw.slotPresence,slots=raw.opaqueSlots;
  const slotRecords=slots.slice();
  const slotNodes=slots.map(slot=>slot.nodes);
  const shapes=slotNodes.map(list=>list.slice());
  const tuple=receipt.source,url=location.href;
  const sourceSnapshot=JSON.stringify(source),receiptSnapshot=JSON.stringify(receipt);
  const attributesOf=node=>Array.from(node.attributes).map(attribute=>[attribute.name,attribute.value]);
  const rootAttributes=JSON.stringify(attributesOf(layoutRoot));
  const captureAttributes=JSON.stringify(attributesOf(capture));
  const captureNodes=Array.from(capture.childNodes);
  const topKinds=nodes.map(node=>[node.nodeType,node.namespaceURI,node.localName]);
  const textData=nodes.map(node=>node.nodeType===3||node.nodeType===8?node.data:null);
  const sameNodes=(current,held)=>current.length===held.length&&held.every((node,i)=>current[i]===node);
  const validateCurrentBinding=()=>{
    if(!layoutRoot.isConnected || !capture.isConnected || layoutRoot.parentElement!==capture ||
       receipt.source!==tuple || receipt.currentRaw!==raw || raw.owner!==ownerRecord ||
       raw.owner.attributes!==ownerAttributes || raw.slotPresence!==presence || raw.opaqueSlots!==slots || !sameNodes(slots,slotRecords) ||
       slots.some((slot,i)=>slot.nodes!==slotNodes[i] || !sameNodes(slot.nodes,shapes[i])) ||
       location.href!==url || receipt.harnessURL!==url ||
       JSON.stringify(source)!==sourceSnapshot || JSON.stringify(receipt)!==receiptSnapshot ||
       JSON.stringify(attributesOf(layoutRoot))!==rootAttributes ||
       JSON.stringify(attributesOf(capture))!==captureAttributes ||
       !sameNodes(Array.from(capture.childNodes),captureNodes) ||
       !sameNodes(Array.from(layoutRoot.childNodes),nodes)) return false;
    return nodes.every((node,i)=>node.parentNode===layoutRoot &&
      node.nodeType===topKinds[i][0] && node.namespaceURI===topKinds[i][1] && node.localName===topKinds[i][2] &&
      (textData[i]===null || node.data===textData[i]));
  };
  if(!validateCurrentBinding()) return fail('TEXT_SHOWCASE_CURRENT_BINDING_CHANGED');
  return {registryResultElement:layoutRoot,fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot,frameSource:layoutRoot,registryIsLayoutRoot:true,
    validateCurrentBinding,
    authority:'original exact Text Example -> direct typed DIV -> complete declared opaque slot frontiers'};
}
''';

/// The wrapper binds only the exact declared selectors, never foreign content.
String get textShowcaseRequestBindingScript =>
    '''
(request) => {
  const source=request.source;
  const claims=request.requiredCurrentSsrKind==='canonical-ssr-text-showcase-v1' ||
    source?.logicalUnitId===${jsonEncode(BoxObservationSourceSpec.textShowcaseOuterPadding.logicalUnitId)} ||
    source?.webAdapterId===${jsonEncode(BoxObservationSourceSpec.textShowcaseOuterPadding.webAdapterId)};
  if(!claims || !request.requested) return {applied:false};
  if(request.requiredCurrentSsrKind!=='canonical-ssr-text-showcase-v1') return {error:'MISSING_TEXT_SHOWCASE_REQUIREMENT'};
  if(typeof request.selector!=='string' || !request.selector || typeof request.layoutSelector!=='string' || !request.layoutSelector)
    return {error:'TEXT_SHOWCASE_SOURCE_SELECTOR_REQUIRED'};
  let fields,roots;
  try {fields=Array.from(document.querySelectorAll(request.selector));roots=Array.from(document.querySelectorAll(request.layoutSelector));}
  catch(error){return {error:'TEXT_SHOWCASE_INVALID_SELECTOR'};}
  if(fields.length!==1 || roots.length!==1 || fields[0]!==roots[0]) return {error:'TEXT_SHOWCASE_UNIQUE_DECLARED_OWNER_REQUIRED'};
  const bound=($textShowcaseBoxSourceResolverScript)(roots[0],source,request.currentSsrSource);
  if(bound.error) return bound;
  const receipt=request.currentSsrSource,selector=request.selector,layoutSelector=request.layoutSelector;
  const originalField=fields[0],originalRoot=roots[0];
  const validateCurrentBinding=()=>{
    try {
      const currentFields=Array.from(document.querySelectorAll(selector));
      const currentRoots=Array.from(document.querySelectorAll(layoutSelector));
      return currentFields.length===1 && currentRoots.length===1 &&
        currentFields[0]===originalField && currentRoots[0]===originalRoot &&
        request.source===source && request.currentSsrSource===receipt &&
        request.requested===true && request.requiredCurrentSsrKind==='canonical-ssr-text-showcase-v1' &&
        request.selector===selector && request.layoutSelector===layoutSelector && bound.validateCurrentBinding();
    } catch(error) {return false;}
  };
  if(!validateCurrentBinding()) return {error:'TEXT_SHOWCASE_REQUEST_BINDING_CHANGED'};
  return {...bound,applied:true,validateCurrentBinding};
}
''';
