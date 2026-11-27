import 'dart:convert';

import '../model/box_observation_source_spec.dart';
import 'client_box_source_protocol.dart';

/// Same physical Stage frame/inner owner, proven by its actual CLIENT tree.
String get stageCallbackRequestBindingScript =>
    '''
(request) => {
  const expected=${jsonEncode(BoxObservationSourceSpec.stageCallbackContentInset.toJson())};
  const source=request.source;
  const claimed=source&&['logicalUnitId','nativeAdapterId','webAdapterId'].some(k=>source[k]===expected[k]);
  if(!claimed)return {applied:false};
  const fail=error=>({applied:true,error});
  const exact=(v,keys)=>v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===keys.length&&keys.every(k=>Object.hasOwn(v,k));
  const tuple=v=>exact(v,Object.keys(expected))&&Object.keys(expected).every(k=>v[k]===expected[k]);
  const descriptor=request.currentClientBoxSource;
  if(request.requested!==true||!tuple(source)||request.requiredCurrentSsrKind!=null||request.currentSsrSource!=null||
    !exact(descriptor,['kind','entryKey','source','renderPhase'])||
    descriptor.kind!==${jsonEncode(kClientStageCallbackSourceKind)}||descriptor.renderPhase!==${jsonEncode(kClientBoxSourcePhase)}||
    !tuple(descriptor.source)||typeof descriptor.entryKey!=='string'||!descriptor.entryKey)
    return fail('STAGE_ACTUAL_CURRENT_CLIENT_REQUIRED');
  const one=selector=>{try{const nodes=Array.from(document.querySelectorAll(selector));return nodes.length===1?nodes[0]:null;}catch(_){return null;}};
  const selector=request.selector,layoutSelector=request.layoutSelector;
  if(typeof selector!=='string'||!selector||typeof layoutSelector!=='string'||!layoutSelector)
    return fail('STAGE_ORIGINAL_SELECTORS_REQUIRED');
  const frame=one(selector),layout=one(layoutSelector),capture=frame?.parentElement;
  if(!frame||frame!==layout||!capture||capture.getAttribute('data-parity-key')!==descriptor.entryKey)
    return fail('STAGE_ORIGINAL_CAPTURE_CHANGED');
  const exchange={request:descriptor};
  capture.dispatchEvent(new CustomEvent(${jsonEncode(kClientStageCallbackSourceEvent)},{detail:exchange,bubbles:false}));
  if(exchange.error)return fail(exchange.error);
  const reply=exchange.response;
  if(!exact(reply,['receipt','capture','layoutRoot','paddingOwner','opaqueRoot','validateCurrentBinding'])||
    reply.capture!==capture||reply.layoutRoot!==frame||typeof reply.validateCurrentBinding!=='function')
    return fail('STAGE_MISSING_ACTUAL_TYPED_CLIENT_SOURCE');
  const receipt=reply.receipt,padding=reply.paddingOwner,body=reply.opaqueRoot,typedValidate=reply.validateCurrentBinding;
  if(!exact(receipt,['kind','entryKey','source','renderPhase','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL'])||
    receipt.kind!==descriptor.kind||receipt.entryKey!==descriptor.entryKey||!tuple(receipt.source)||
    receipt.renderPhase!==descriptor.renderPhase||receipt.completeRawSlotCount!==1||
    receipt.rawOrderFromPublicProducerLists!==true||typeof location==='undefined'||receipt.harnessURL!==location.href)
    return fail('STAGE_CURRENT_CLIENT_HEADER_CHANGED');
  const raw=receipt.currentRaw;
  if(!exact(raw,['kind','quantityBoundary','callbackReexecuted','bodyInteriorIsSourceAuthority','capture','frame','paddingOwner','opaqueRoot','ownedNodeOrder'])||
    raw.kind!=='current-client-stage-callback-padding-v1'||raw.quantityBoundary!=='original-stage-frame-to-opaque-callback-content'||
    raw.callbackReexecuted!==false||raw.bodyInteriorIsSourceAuthority!==false||
    JSON.stringify(raw.ownedNodeOrder)!==JSON.stringify(['capture','frame','paddingOwner','opaqueRoot']))
    return fail('STAGE_CURRENT_CLIENT_GRAPH_CHANGED');
  const attrs=node=>Object.fromEntries(Array.from(node.attributes).map(a=>[a.name,a.value]));
  const same=(a,b)=>JSON.stringify(Object.entries(a).sort())===JSON.stringify(Object.entries(b).sort());
  const own=(node,record)=>node&&node.isConnected&&node.nodeType===1&&
    exact(record,['namespaceURI','localName','attributes'])&&record.namespaceURI==='http://www.w3.org/1999/xhtml'&&record.localName==='div'&&
    node.namespaceURI===record.namespaceURI&&node.localName===record.localName&&record.attributes&&same(attrs(node),record.attributes);
  const edge=(parent,child)=>parent&&child&&child.isConnected&&child.parentElement===parent&&
    parent.childNodes.length===1&&parent.childNodes[0]===child;
  // Opaque root: only top public kind/tag/ref. Never read its attributes,
  // text, styles, childNodes, descendants or outerHTML.
  const opaque=()=>body&&body.isConnected&&body.nodeType===1&&
    exact(raw.opaqueRoot,['namespaceURI','localName'])&&raw.opaqueRoot.namespaceURI==='http://www.w3.org/1999/xhtml'&&raw.opaqueRoot.localName==='div'&&
    body.namespaceURI===raw.opaqueRoot.namespaceURI&&body.localName===raw.opaqueRoot.localName;
  const graph=value=>{const objects=[];const visit=v=>{if(v&&typeof v==='object'){objects.push(v);for(const x of Object.values(v))visit(x);}};visit(value);return objects;};
  const held=[...graph(source),...graph(descriptor),...graph(receipt)],frozenSource=JSON.stringify(source),frozenDescriptor=JSON.stringify(descriptor),frozenReceipt=JSON.stringify(receipt);
  const validateCurrentBinding=()=>{
    try{
      const now=[...graph(request.source),...graph(request.currentClientBoxSource),...graph(reply.receipt)];
      return request.requested===true&&request.requiredCurrentSsrKind==null&&request.currentSsrSource==null&&
        request.source===source&&request.currentClientBoxSource===descriptor&&request.selector===selector&&request.layoutSelector===layoutSelector&&
        JSON.stringify(source)===frozenSource&&JSON.stringify(descriptor)===frozenDescriptor&&JSON.stringify(receipt)===frozenReceipt&&
        now.length===held.length&&now.every((x,i)=>x===held[i])&&reply.receipt===receipt&&reply.validateCurrentBinding===typedValidate&&
        reply.capture===capture&&reply.layoutRoot===frame&&reply.paddingOwner===padding&&reply.opaqueRoot===body&&
        location.href===receipt.harnessURL&&one(selector)===frame&&one(layoutSelector)===frame&&
        capture.getAttribute('data-parity-key')===receipt.entryKey&&
        own(capture,raw.capture)&&own(frame,raw.frame)&&own(padding,raw.paddingOwner)&&opaque()&&
        edge(capture,frame)&&edge(frame,padding)&&edge(padding,body)&&typedValidate(reply)===true;
    }catch(_){return false;}
  };
  if(!validateCurrentBinding())return fail('STAGE_CURRENT_TYPED_BINDING_CHANGED');
  return {applied:true,registryResultElement:frame,fieldUnitElement:frame,paddingSource:padding,frameSource:frame,registryIsLayoutRoot:true,
    authority:'Current original public client Stage -> already-executed normal outer/inner DIV -> opaque callback DIV root; typed references revalidated, no callback/State/resolver replay',
    currentClientSource:receipt,clientEvidence:{ownedNodeRoles:raw.ownedNodeOrder,wholeOwnedPrefixValidated:true,foreignInteriorUsedForAuthority:false},validateCurrentBinding};
}
''';
