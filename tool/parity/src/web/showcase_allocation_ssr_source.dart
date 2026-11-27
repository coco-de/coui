import 'dart:convert';

import 'package:docs_core/previews/examples/web/bottom_action_bar/bottom_action_bar_scaffold_example.dart';
import 'package:docs_core/previews/examples/web/card_image/card_image_default_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_default_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_plain_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_tail_corner_example.dart';
import 'package:docs_core/previews/examples/web/chat/chat_tail_top_example.dart';
import 'package:docs_core/previews/examples/web/chip/chip_cast_motion_example.dart';
import 'package:docs_core/previews/examples/web/chip/chip_prefix_example.dart';
import 'package:docs_core/previews/examples/web/chip/chip_selected_example.dart';
import 'package:docs_core/previews/examples/web/chip/chip_shape_example.dart';
import 'package:docs_core/previews/examples/web/chip/chip_variant_example.dart';
import 'package:docs_core/previews/examples/web/draggable_panel/draggable_panel_default_example.dart';
import 'package:docs_core/previews/examples/web/draggable_panel/draggable_panel_outside_example.dart';
import 'package:docs_core/previews/examples/web/hidden/hidden_default_example.dart';
import 'package:docs_core/previews/examples/web/mockup_foldable/mockup_foldable_angle_example.dart';
import 'package:docs_core/previews/examples/web/mockup_foldable/mockup_foldable_default_example.dart';
import 'package:docs_core/previews/examples/web/progress/progress_tone_example.dart';
import 'package:docs_core/previews/examples/web/scaffold/scaffold_default_example.dart';
import 'package:docs_core/previews/examples/web/scrollable_client/scrollable_client_default_example.dart';
import 'package:docs_core/previews/examples/web/scrollview/scrollview_default_example.dart';
import 'package:docs_core/previews/examples/web/skeleton/skeleton_default_example.dart';
import 'package:docs_core/previews/examples/web/step_item/step_item_default_example.dart';
import 'package:docs_core/previews/examples/web/table/table_scrollable_example.dart';
import 'package:docs_core/previews/examples/web/window/window_default_example.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';
import 'ssr_source_identity.dart';

/// The exact classic compound allocation, never a contained product frame.
const _kExampleTypes = <(String, String), Type>{
  ('card-image', 'default'): CardImageDefaultExample,
  ('hidden', 'default'): HiddenDefaultExample,
  ('window', 'default'): WindowDefaultExample,
  ('draggable-panel', 'default'): DraggablePanelDefaultExample,
  ('draggable-panel', 'outside'): DraggablePanelOutsideExample,
  ('scrollable-client', 'default'): ScrollableClientDefaultExample,
  ('table', 'scrollable'): TableScrollableExample,
  ('mockup-foldable', 'angle'): MockupFoldableAngleExample,
  ('mockup-foldable', 'default'): MockupFoldableDefaultExample,
  ('scaffold', 'default'): ScaffoldDefaultExample,
  ('bottom-action-bar', 'scaffold'): BottomActionBarScaffoldExample,
  ('scrollview', 'default'): ScrollViewInterceptorDefaultExample,
  ('progress', 'tone'): ProgressToneExample,
  ('chat', 'default'): ChatDefaultExample,
  ('chat', 'plain'): ChatPlainExample,
  ('chat', 'tail-corner'): ChatTailCornerExample,
  ('chat', 'tail-top'): ChatTailTopExample,
  ('chip', 'selected'): ChipSelectedExample,
  ('chip', 'variant'): ChipVariantExample,
  ('chip', 'shape'): ChipShapeExample,
  ('chip', 'cast-motion'): ChipCastMotionExample,
  ('chip', 'prefix'): ChipPrefixExample,
  ('skeleton', 'default'): SkeletonDefaultExample,
  ('step-item', 'default'): StepItemDefaultExample,
};
const _kSlotCounts = <(String, String), int>{
  ('card-image', 'default'): 1,
  ('hidden', 'default'): 3,
  ('window', 'default'): 3,
  ('draggable-panel', 'default'): 1,
  ('draggable-panel', 'outside'): 1,
  ('scrollable-client', 'default'): 1,
  ('table', 'scrollable'): 1,
  ('mockup-foldable', 'angle'): 2,
  ('mockup-foldable', 'default'): 1,
  ('scaffold', 'default'): 1,
  ('bottom-action-bar', 'scaffold'): 1,
  ('scrollview', 'default'): 1,
  ('progress', 'tone'): 7,
  ('chat', 'default'): 3,
  ('chat', 'plain'): 3,
  ('chat', 'tail-corner'): 3,
  ('chat', 'tail-top'): 3,
  ('chip', 'selected'): 3,
  ('chip', 'variant'): 11,
  ('chip', 'shape'): 4,
  ('chip', 'cast-motion'): 5,
  ('chip', 'prefix'): 2,
  ('skeleton', 'default'): 3,
  ('step-item', 'default'): 4,
};

/// Observes one original registry mount. Production requires an exact declared
/// source. An undeclared entry never borrows source authority.
class ShowcaseAllocationSsrSource implements CurrentSsrBoxSource {
  ShowcaseAllocationSsrSource._(
    this.entry,
    this.exampleType,
    this.expectedRawCount,
  );

  static ShowcaseAllocationSsrSource? forEntry(MatrixEntry entry) {
    const expected = BoxObservationSourceSpec.showcaseAllocationHost;
    final closed = _kExampleTypes.containsKey((entry.component, entry.variant));
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
      throw StateError('SHOWCASE_ALLOCATION_DECLARED_SOURCE_CHANGED');
    }
    return ShowcaseAllocationSsrSource._(
      entry,
      _kExampleTypes[(entry.component, entry.variant)]!,
      _kSlotCounts[(entry.component, entry.variant)]!,
    );
  }

  final MatrixEntry entry;
  final Type exampleType;
  final int expectedRawCount;
  Component? _registry;
  div? _capture;
  _Current? _bound;
  Component? _registryWidthOriginalChild;

  bool get _isRegistryWidthAllocation =>
      entry.component == 'mockup-foldable' && entry.variant == 'default';

  @override
  void recordBuild(Component result, div capture) {
    if (_registry != null || _capture != null) {
      throw StateError('SHOWCASE_ALLOCATION_BUILD_REPEATED');
    }
    if (_isRegistryWidthAllocation) {
      if (result.runtimeType != div) {
        throw StateError('SHOWCASE_ALLOCATION_TYPED_REGISTRY_DIV_REQUIRED');
      }
      final width = result as div;
      if (width.children.length != 1 ||
          width.children.single.runtimeType != exampleType) {
        throw StateError('SHOWCASE_ALLOCATION_REGISTRY_EXAMPLE_CHANGED');
      }
      _registryWidthOriginalChild = width.children.single;
    }
    _registry = result;
    _capture = capture;
  }

  @override
  Map<String, Object?> observe(Element root) {
    final current = _locate(root);
    final held = _bound;
    if (held != null && !held.sameIdentities(current)) {
      throw StateError('SHOWCASE_ALLOCATION_HELD_BINDING_STALE');
    }
    final markup = _markup(current.owner);
    final before = markup.renderToHtml();
    final parsed = _singleRoot(before);
    final usedFrontiers = Set<MarkupRenderObject>.identity();
    final slots = <Map<String, Object?>>[
      for (var i = 0; i < current.children.length; i++)
        {
          'seat': i,
          'sourceAliasOf': _earlier(current.raw, i),
          'nodes': [
            for (final frontier in current.frontiers[i])
              ..._opaqueNodes(frontier, usedFrontiers),
          ],
        },
    ];
    _matchNodes(
      parsed.nodes,
      [for (final slot in slots) ...(slot['nodes']! as List)],
    );
    if (!current.sameIdentities(_locate(root)) ||
        markup.renderToHtml() != before) {
      throw StateError('SHOWCASE_ALLOCATION_CURRENT_SOURCE_CHANGED');
    }
    _bound ??= current;
    return {
      'kind': 'canonical-ssr-showcase-allocation-v1',
      'entryKey': entry.key,
      'source': BoxObservationSourceSpec.showcaseAllocationHost.toJson(),
      'currentRaw': {
        'kind': 'current-showcase-allocation-raw-v1',
        'logicalUnitId':
            BoxObservationSourceSpec.showcaseAllocationHost.logicalUnitId,
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
    final registryWidthAllocation = _isRegistryWidthAllocation;
    if (registry == null ||
        capture == null ||
        registry.runtimeType != (registryWidthAllocation ? div : exampleType) ||
        capture.children.length != 1 ||
        !identical(capture.children.single, registry) ||
        capture.attributes?['data-parity-key'] != entry.key) {
      throw StateError('SHOWCASE_ALLOCATION_ORIGINAL_CAPTURE_CHANGED');
    }
    final captureElement = currentSsrIdentityElement(root, capture);
    final captureDom = currentSsrGeneratedDiv(captureElement, capture);
    final example = currentSsrIdentityElement(root, registry);
    if (!identical(example.parent, captureDom)) {
      throw StateError('SHOWCASE_ALLOCATION_REGISTRY_EDGE_CHANGED');
    }
    // The exact closed default recipe has a public registry width DIV.
    // Its ONE original Example child is opaque; never unwrap to its DIV.
    // All other recipes retain the original Example -> direct typed DIV route.
    final Element returned;
    final div declaration;
    if (registryWidthAllocation) {
      returned = example;
      declaration = registry as div;
      if (declaration.children.length != 1 ||
          !identical(
            declaration.children.single,
            _registryWidthOriginalChild,
          ) ||
          declaration.children.single.runtimeType != exampleType) {
        throw StateError('SHOWCASE_ALLOCATION_REGISTRY_EXAMPLE_CHANGED');
      }
    } else {
      returned = soleCurrentSsrChild(example);
      if (returned.component.runtimeType != div) {
        throw StateError('SHOWCASE_ALLOCATION_DIRECT_DIV_REQUIRED');
      }
      declaration = returned.component as div;
    }
    final raw = List<Component>.unmodifiable(declaration.children);
    if (raw.length != expectedRawCount ||
        raw.any(
          (child) =>
              identical(child, registry) ||
              identical(child, capture) ||
              identical(child, declaration),
        )) {
      throw StateError('SHOWCASE_ALLOCATION_RAW_VECTOR_CHANGED');
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
      throw StateError('SHOWCASE_ALLOCATION_DECLARED_ORDER_CHANGED');
    }
    final mounted = Set<Element>.identity();
    for (var i = 0; i < raw.length; i++) {
      if (!mounted.add(children[i])) {
        throw StateError('SHOWCASE_ALLOCATION_MOUNTED_SLOT_ALIAS');
      }
    }
    _renderChildrenMatch(owner, children);
    _renderChildrenMatch(captureDom, [example]);
    final frontiers = [
      for (final child in children)
        List<MarkupRenderObject>.unmodifiable(_renderFrontier(child)),
    ];
    final held = <MarkupRenderObject>[];
    final seen = Set<MarkupRenderObject>.identity();
    void hold(MarkupRenderObject render) {
      if (!seen.add(render)) {
        throw StateError('SHOWCASE_ALLOCATION_FRONTIER_ALIAS');
      }
      held.add(render);
      if (render is MarkupRenderFragment) {
        for (final child in render.children) {
          if (!identical(child.parent, render)) {
            throw StateError(
              'SHOWCASE_ALLOCATION_FRAGMENT_PARENT_CHANGED',
            );
          }
          hold(child);
        }
      }
    }

    for (final slot in frontiers) {
      slot.forEach(hold);
    }
    return _Current(
      captureElement,
      example,
      returned,
      declaration,
      owner,
      raw,
      children,
      frontiers,
      List.unmodifiable(held),
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
    this.frontiers,
    this.heldFrontierIdentities,
  );

  final Element capture;
  final Element example;
  final Element returned;
  final div declaration;
  final Element owner;
  final List<Component> raw;
  final List<Element> children;
  final List<List<MarkupRenderObject>> frontiers;
  final List<MarkupRenderObject> heldFrontierIdentities;

  bool sameIdentities(_Current other) =>
      identical(capture, other.capture) &&
      identical(example, other.example) &&
      identical(returned, other.returned) &&
      identical(declaration, other.declaration) &&
      identical(owner, other.owner) &&
      raw.length == other.raw.length &&
      children.length == other.children.length &&
      heldFrontierIdentities.length == other.heldFrontierIdentities.length &&
      List.generate(
        heldFrontierIdentities.length,
        (i) => identical(
          heldFrontierIdentities[i],
          other.heldFrontierIdentities[i],
        ),
      ).every((same) => same) &&
      List.generate(
        raw.length,
        (i) =>
            identical(raw[i], other.raw[i]) &&
            identical(children[i], other.children[i]) &&
            frontiers[i].length == other.frontiers[i].length &&
            List.generate(
              frontiers[i].length,
              (j) => identical(frontiers[i][j], other.frontiers[i][j]),
            ).every((same) => same),
      ).every((same) => same);
}

List<Element> _children(Element element) {
  final result = <Element>[];
  element.visitChildren(result.add);
  return result;
}

int? _earlier(List<Component> raw, int index) {
  for (var i = 0; i < index; i++) {
    if (identical(raw[i], raw[index])) return i;
  }
  return null;
}

List<MarkupRenderObject> _renderFrontier(Element element) {
  if (element is RenderObjectElement) {
    return [_markup(element)];
  }
  return [for (final child in _children(element)) ..._renderFrontier(child)];
}

MarkupRenderObject _markup(Element element) {
  if (element is! RenderObjectElement ||
      element.renderObject is! MarkupRenderObject) {
    throw StateError('SHOWCASE_ALLOCATION_PUBLIC_MARKUP_REQUIRED');
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
    throw StateError('SHOWCASE_ALLOCATION_UNDECLARED_RENDER_NODE');
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
    throw StateError('SHOWCASE_ALLOCATION_WHOLE_OWNER_MARKUP_CHANGED');
  }
  return fragment.children.single;
}

// Stop at each foreign element. Only a public Fragment's top-level frontier
// is flattened; no contained product or foreign element interior is probed.
List<Map<String, Object?>> _opaqueNodes(
  MarkupRenderObject render,
  Set<MarkupRenderObject> used,
) {
  if (!used.add(render)) {
    throw StateError(
      'SHOWCASE_ALLOCATION_OPAQUE_FRONTIER_ALIAS',
    );
  }
  if (render is MarkupRenderFragment) {
    return [
      for (final child in render.children)
        ...(() {
          if (!identical(child.parent, render)) {
            throw StateError(
              'SHOWCASE_ALLOCATION_FRAGMENT_PARENT_CHANGED',
            );
          }
          return _opaqueNodes(child, used);
        })(),
    ];
  }
  if (render is! MarkupRenderElement && render is! MarkupRenderText) {
    throw StateError('SHOWCASE_ALLOCATION_OPAQUE_FRONTIER_UNSUPPORTED');
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
  throw StateError('SHOWCASE_ALLOCATION_OPAQUE_NODE_KIND_UNSUPPORTED');
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
      throw StateError('SHOWCASE_ALLOCATION_OPAQUE_NODE_ORDER_CHANGED');
    }
    index++;
  }
  if (actual
      .skip(index)
      .any(
        (node) => !(node is dom.Text && _asciiWhitespace.hasMatch(node.data)),
      )) {
    throw StateError('SHOWCASE_ALLOCATION_UNDECLARED_OWNER_CONTENT');
  }
}

/// This requirement is a descriptor, not evidence of a mounted producer.
String? requiredShowcaseAllocationSsrKind(MatrixEntry entry) =>
    ShowcaseAllocationSsrSource.forEntry(entry) == null
    ? null
    : 'canonical-ssr-showcase-allocation-v1';

String get showcaseAllocationBoxSourceResolverScript =>
    '''
(layoutRoot, source, receipt) => {
  const fail = error => ({error});
  const keys = (value, expected) => value && typeof value === 'object' &&
    !Array.isArray(value) && Object.keys(value).length === expected.length &&
    expected.every(key => Object.hasOwn(value,key));
  const same = (a,b) => keys(a,Object.keys(b)) &&
    Object.keys(b).every(key => a[key] === b[key]);
  if (!same(source,${jsonEncode(BoxObservationSourceSpec.showcaseAllocationHost.toJson())}))
    return fail('SHOWCASE_ALLOCATION_DECLARED_SOURCE_CHANGED');
  if (!keys(receipt,['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL']) ||
      receipt.kind !== 'canonical-ssr-showcase-allocation-v1' ||
      typeof receipt.entryKey !== 'string' || receipt.entryKey.length === 0 ||
      !same(receipt.source,source) || receipt.rawOrderFromPublicProducerLists !== true ||
      typeof location === 'undefined' || receipt.harnessURL !== location.href)
    return fail('SHOWCASE_ALLOCATION_ACTUAL_SSR_RECEIPT_REQUIRED');
  const htmlNS = 'http://www.w3.org/1999/xhtml';
  const div = node => node && node.nodeType === 1 &&
    node.namespaceURI === htmlNS && node.localName === 'div';
  const ascii = node => node.nodeType === 3 && /^[\\t\\n\\f\\r ]*\$/.test(node.data);
  const capture = layoutRoot && layoutRoot.parentElement;
  if (!div(layoutRoot) || !layoutRoot.isConnected || !div(capture) ||
      capture.getAttribute('data-parity-key') !== receipt.entryKey ||
      capture.children.length !== 1 || capture.children[0] !== layoutRoot ||
      Array.from(capture.childNodes).some(node => node !== layoutRoot && !ascii(node)))
    return fail('SHOWCASE_ALLOCATION_CANONICAL_ROOT_CHANGED');
  const raw = receipt.currentRaw;
  if (!keys(raw,['kind','logicalUnitId','rawSlotCount','slotPresence','opaqueSlots','owner','actualOwnerMarkup']) ||
      raw.kind !== 'current-showcase-allocation-raw-v1' ||
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
    return fail('SHOWCASE_ALLOCATION_COMPLETE_RAW_REQUIRED');
  const attributes = Array.from(layoutRoot.attributes);
  if (attributes.length !== Object.keys(raw.owner.attributes).length ||
      attributes.some(attribute => raw.owner.attributes[attribute.name] !== attribute.value))
    return fail('SHOWCASE_ALLOCATION_OWNER_IDENTITY_CHANGED');
  const nodes = Array.from(layoutRoot.childNodes);
  let index = 0;
  if (new Set(nodes).size !== nodes.length) return fail('SHOWCASE_ALLOCATION_NODE_ALIAS');
  for (let seat=0;seat<raw.opaqueSlots.length;seat++) {
    const slot=raw.opaqueSlots[seat],alias=slot.sourceAliasOf;
    if (!keys(slot,['seat','sourceAliasOf','nodes']) || slot.seat!==seat ||
        !(alias===null || (Number.isInteger(alias) && alias>=0 && alias<seat && raw.opaqueSlots[alias].sourceAliasOf===null)) ||
        !Array.isArray(slot.nodes)) return fail('SHOWCASE_ALLOCATION_RAW_SLOT_CHANGED');
    for (const shape of slot.nodes) {
      if (!shape || ![1,3,8].includes(shape.nodeType) ||
          !keys(shape,shape.nodeType === 1 ? ['nodeType','namespaceURI','localName'] : ['nodeType']))
        return fail('SHOWCASE_ALLOCATION_RAW_FRONTIER_CHANGED');
      while (index < nodes.length && shape.nodeType !== 3 && ascii(nodes[index])) index++;
      const node = nodes[index++];
      if (!node || node === layoutRoot || node === capture || node.nodeType !== shape.nodeType ||
          (shape.nodeType === 1 && (node.namespaceURI !== shape.namespaceURI || node.localName !== shape.localName)))
        return fail('SHOWCASE_ALLOCATION_OPAQUE_ORDER_CHANGED');
    }
  }
  if (nodes.slice(index).some(node => !ascii(node))) return fail('SHOWCASE_ALLOCATION_EXTRA_OWNER_CONTENT');
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
  if(!validateCurrentBinding()) return fail('SHOWCASE_ALLOCATION_CURRENT_BINDING_CHANGED');
  return {registryResultElement:layoutRoot,fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot,frameSource:layoutRoot,registryIsLayoutRoot:true,
    validateCurrentBinding,
    authority:'original exact public registry mount -> audited typed DIV allocation -> complete declared opaque slot frontiers'};
}
''';

/// The wrapper binds only the exact declared selectors, never foreign content.
String get showcaseAllocationRequestBindingScript =>
    '''
(request) => {
  const source=request.source;
  const claims=request.requiredCurrentSsrKind==='canonical-ssr-showcase-allocation-v1' ||
    source?.logicalUnitId===${jsonEncode(BoxObservationSourceSpec.showcaseAllocationHost.logicalUnitId)} ||
    source?.webAdapterId===${jsonEncode(BoxObservationSourceSpec.showcaseAllocationHost.webAdapterId)};
  if(!claims || !request.requested) return {applied:false};
  if(request.requiredCurrentSsrKind!=='canonical-ssr-showcase-allocation-v1') return {error:'MISSING_SHOWCASE_ALLOCATION_REQUIREMENT'};
  if(typeof request.selector!=='string' || !request.selector || typeof request.layoutSelector!=='string' || !request.layoutSelector)
    return {error:'SHOWCASE_ALLOCATION_SOURCE_SELECTOR_REQUIRED'};
  let fields,roots;
  try {fields=Array.from(document.querySelectorAll(request.selector));roots=Array.from(document.querySelectorAll(request.layoutSelector));}
  catch(error){return {error:'SHOWCASE_ALLOCATION_INVALID_SELECTOR'};}
  if(fields.length!==1 || roots.length!==1 || fields[0]!==roots[0]) return {error:'SHOWCASE_ALLOCATION_UNIQUE_DECLARED_OWNER_REQUIRED'};
  const bound=($showcaseAllocationBoxSourceResolverScript)(roots[0],source,request.currentSsrSource);
  if(bound.error) return bound;
  const receipt=request.currentSsrSource,selector=request.selector,layoutSelector=request.layoutSelector;
  const originalOwner=bound.fieldUnitElement;
  const validateCurrentBinding=()=>{
    let currentFields,currentRoots;
    try {
      currentFields=Array.from(document.querySelectorAll(selector));
      currentRoots=Array.from(document.querySelectorAll(layoutSelector));
    } catch(error) {return false;}
    return currentFields.length===1 && currentRoots.length===1 &&
      currentFields[0]===originalOwner && currentRoots[0]===originalOwner &&
      request.source===source && request.currentSsrSource===receipt &&
      request.requested===true && request.requiredCurrentSsrKind==='canonical-ssr-showcase-allocation-v1' &&
      request.selector===selector && request.layoutSelector===layoutSelector && bound.validateCurrentBinding();
  };
  if(!validateCurrentBinding()) return {error:'SHOWCASE_ALLOCATION_REQUEST_BINDING_CHANGED'};
  return {...bound,applied:true,validateCurrentBinding};
}
''';
