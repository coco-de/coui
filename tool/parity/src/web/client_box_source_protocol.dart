import 'dart:convert';

import '../model/box_observation_source_spec.dart';
import '../model/matrix_entry.dart';

const kClientBoxSourceKind = 'canonical-client-visual-value-v1';
const kClientBoxSourcePhase = 'client-settled';
const kClientBoxSourceEvent = 'coui-parity-current-client-box-source';

/// Only the reviewed original client recipe receives this optional request.
/// This is a descriptor, not evidence that a producer was actually mounted.
Map<String, Object?>? clientBoxSourceDescriptor(
  MatrixEntry entry, {
  required bool additiveBoxObservations,
}) {
  if (!additiveBoxObservations ||
      entry.component != 'number-ticker' ||
      entry.variant != 'default') {
    return null;
  }
  final roots = entry.probes.where((probe) => probe.role == 'root').toList();
  if (roots.length != 1 ||
      roots.single.boxObservationSource !=
          BoxObservationSourceSpec.numberTickerTextLayoutHost) {
    throw StateError('CLIENT_BOX_SOURCE_DESCRIPTOR_CHANGED');
  }
  return {
    'kind': kClientBoxSourceKind,
    'entryKey': entry.key,
    'source': roots.single.boxObservationSource!.toJson(),
    'renderPhase': kClientBoxSourcePhase,
  };
}

/// A synchronous request on the exact capture node. Element/State references
/// never leave Dart; DOM references live only in this one request's exchange.
String get clientBoxSourceRequestScript =>
    '''
(layoutRoot,source,descriptor) => {
  const fail=error=>({error});
  const exact=(value,keys)=>value && typeof value==='object' &&
    !Array.isArray(value) && Object.keys(value).length===keys.length &&
    keys.every(key=>Object.hasOwn(value,key));
  const tuple=${jsonEncode(BoxObservationSourceSpec.numberTickerTextLayoutHost.toJson())};
  const sameTuple=value=>exact(value,Object.keys(tuple)) &&
    Object.keys(tuple).every(key=>value[key]===tuple[key]);
  if(!sameTuple(source) || !exact(descriptor,['kind','entryKey','source','renderPhase']) ||
      descriptor.kind!==${jsonEncode(kClientBoxSourceKind)} ||
      descriptor.renderPhase!==${jsonEncode(kClientBoxSourcePhase)} ||
      !sameTuple(descriptor.source))return fail('CLIENT_BOX_DESCRIPTOR_CHANGED');
  const capture=layoutRoot?.parentElement;
  if(!capture || !layoutRoot.isConnected || !capture.isConnected ||
      descriptor.entryKey!==capture.getAttribute('data-parity-key'))
    return fail('CLIENT_BOX_CAPTURE_CHANGED');
  const beforeMarkup=capture.outerHTML;
  const beforeNodes=[];
  const collect=node=>{beforeNodes.push(node);for(const child of node.childNodes)collect(child);};
  collect(capture);
  const exchange={request:descriptor};
  capture.dispatchEvent(new CustomEvent(${jsonEncode(kClientBoxSourceEvent)},
    {detail:exchange,bubbles:false}));
  if(exchange.error)return fail(exchange.error);
  const response=exchange.response;
  if(!exact(response,['receipt','capture','layoutRoot','nodes']))
    return fail('MISSING_ACTUAL_CLIENT_BOX_SOURCE');
  const receipt=response.receipt;
  const header=['kind','entryKey','source','currentRaw','completeRawSlotCount',
    'rawOrderFromPublicProducerLists','harnessURL','renderPhase'];
  if(!exact(receipt,header) || receipt.kind!==descriptor.kind ||
      receipt.entryKey!==descriptor.entryKey || !sameTuple(receipt.source) ||
      receipt.renderPhase!==${jsonEncode(kClientBoxSourcePhase)} ||
      receipt.harnessURL!==location.href ||
      receipt.rawOrderFromPublicProducerLists!==true ||
      !Number.isInteger(receipt.completeRawSlotCount) || receipt.completeRawSlotCount<0)
    return fail('CLIENT_BOX_HEADER_CHANGED');
  if(response.capture!==capture || response.layoutRoot!==layoutRoot ||
      !Array.isArray(response.nodes) || response.nodes.length!==beforeNodes.length ||
      response.nodes.some((node,i)=>node!==beforeNodes[i]))
    return fail('CLIENT_BOX_CURRENT_NODE_CHANGED');
  const raw=receipt.currentRaw;
  if(!exact(raw,['kind','logicalUnitId','rawSlotCount','slotPresence','plainMode','generatedTree']) ||
      raw.kind!=='current-visual-value-raw-v1' || raw.logicalUnitId!==tuple.logicalUnitId ||
      raw.rawSlotCount!==1 || receipt.completeRawSlotCount!==raw.rawSlotCount ||
      !Array.isArray(raw.slotPresence) || raw.slotPresence.length!==1 ||
      raw.slotPresence[0]!==false || raw.plainMode!==true)
    return fail('CLIENT_BOX_RAW_CHANGED');
  const seen=new Set();
  const match=(node,tree)=>{
    if(!node || seen.has(node) || !node.isConnected || node.nodeType!==1 ||
        !exact(tree,['namespaceURI','localName','children','nodeKinds']) ||
        node.namespaceURI!=='http://www.w3.org/1999/xhtml' ||
        node.namespaceURI!==tree.namespaceURI || node.localName!==tree.localName ||
        node.tagName!==tree.localName.toUpperCase() || !Array.isArray(tree.children) ||
        !Array.isArray(tree.nodeKinds))return false;
    seen.add(node);
    const nodes=Array.from(node.childNodes),children=Array.from(node.children);
    if(nodes.length!==tree.nodeKinds.length ||
        nodes.some((child,i)=>child.parentNode!==node || !child.isConnected ||
          child.nodeType!==tree.nodeKinds[i]) || children.length!==tree.children.length)
      return false;
    return children.every((child,i)=>child.parentElement===node && match(child,tree.children[i]));
  };
  const top=Array.from(capture.childNodes);
  if(top.length!==1 || top[0]!==layoutRoot || !match(layoutRoot,raw.generatedTree) ||
      raw.generatedTree.localName!=='span' ||
      raw.generatedTree.nodeKinds.length!==1 || raw.generatedTree.nodeKinds[0]!==1 ||
      raw.generatedTree.children.length!==1 ||
      raw.generatedTree.children[0].localName!=='span' ||
      raw.generatedTree.children[0].nodeKinds.length!==1 ||
      raw.generatedTree.children[0].nodeKinds[0]!==3 ||
      raw.generatedTree.children[0].children.length!==0)
    return fail('CLIENT_BOX_WHOLE_DOM_CHANGED');
  const afterNodes=[];
  const collectAfter=node=>{afterNodes.push(node);for(const child of node.childNodes)collectAfter(child);};
  collectAfter(capture);
  if(capture.outerHTML!==beforeMarkup || afterNodes.length!==beforeNodes.length ||
      afterNodes.some((node,i)=>node!==beforeNodes[i]))
    return fail('CLIENT_BOX_OBSERVER_MUTATED_DOM');
  return {receipt,clientEvidence:{actualCaptureMarkup:beforeMarkup,
    actualNodeCount:beforeNodes.length},
    binding:{registryResultElement:layoutRoot,fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot,frameSource:layoutRoot,registryIsLayoutRoot:true,
    authority:'Exact current public client producer and complete same-mounted DOM nodes'}};
}
''';
