import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// The original frame and the sole typed inner padding owner stay distinct.
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
  const receipt=request.currentSsrSource;
  if(request.requested!==true||!tuple(source)||request.requiredCurrentSsrKind!=='canonical-ssr-stage-callback-v1'||
    !exact(receipt,['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL'])||
    receipt.kind!=='canonical-ssr-stage-callback-v1'||!tuple(receipt.source)||
    typeof receipt.entryKey!=='string'||!receipt.entryKey||receipt.completeRawSlotCount!==1||
    receipt.rawOrderFromPublicProducerLists!==true||typeof location==='undefined'||receipt.harnessURL!==location.href)
    return fail('STAGE_ACTUAL_NORMAL_SSR_REQUIRED');
  const raw=receipt.currentRaw;
  if(!exact(raw,['kind','quantityBoundary','callbackReexecuted','bodyInteriorIsSourceAuthority',
    'frame','paddingOwner','bodyFrontier','capture','captureNodes','frameNodes','paddingNodes'])||
    raw.kind!=='current-stage-callback-padding-v1'||raw.quantityBoundary!=='original-stage-frame-to-opaque-callback-content'||
    raw.callbackReexecuted!==false||raw.bodyInteriorIsSourceAuthority!==false||
    !Array.isArray(raw.bodyFrontier)||!Array.isArray(raw.captureNodes)||!Array.isArray(raw.frameNodes)||!Array.isArray(raw.paddingNodes))
    return fail('STAGE_COMPLETE_SOURCE_GRAPH_REQUIRED');
  const attrs=node=>Object.fromEntries(Array.from(node.attributes).map(a=>[a.name,a.value]));
  const same=(a,b)=>JSON.stringify(Object.entries(a).sort())===JSON.stringify(Object.entries(b).sort());
  const own=(node,record)=>node&&node.isConnected&&node.nodeType===1&&
    exact(record,['namespaceURI','localName','attributes'])&&record.namespaceURI==='http://www.w3.org/1999/xhtml'&&
    record.localName==='div'&&node.namespaceURI===record.namespaceURI&&node.localName===record.localName&&
    record.attributes&&same(attrs(node),record.attributes);
  const shape=(node,record)=>node&&node.isConnected&&record&&Number.isInteger(record.nodeType)&&
    node.nodeType===record.nodeType&&(record.nodeType===1
      ?exact(record,['nodeType','namespaceURI','localName'])&&typeof record.namespaceURI==='string'&&
        typeof record.localName==='string'&&node.namespaceURI===record.namespaceURI&&node.localName===record.localName
      :[3,8].includes(record.nodeType)&&exact(record,['nodeType']));
  const one=selector=>{try{const found=Array.from(document.querySelectorAll(selector));return found.length===1?found[0]:null;}catch(_){return null;}};
  const selector=request.selector,layoutSelector=request.layoutSelector;
  if(typeof selector!=='string'||!selector||typeof layoutSelector!=='string'||!layoutSelector)
    return fail('STAGE_ORIGINAL_SELECTORS_REQUIRED');
  const frame=one(selector),layout=one(layoutSelector),capture=frame?.parentElement;
  if(!frame||frame!==layout||!capture||capture.getAttribute('data-parity-key')!==receipt.entryKey||frame.children.length!==1)
    return fail('STAGE_ORIGINAL_FRAME_CHANGED');
  const padding=frame.children[0];
  const graphObjects=value=>{const out=[];const visit=v=>{if(v&&typeof v==='object'){out.push(v);for(const c of Object.values(v))visit(c);}};visit(value);return out;};
  const heldObjects=[...graphObjects(source),...graphObjects(receipt)],frozenSource=JSON.stringify(source),frozenReceipt=JSON.stringify(receipt);
  const heldNodes=[];let initial=true;
  const scan=(parent,records,kind,target,refs)=>{
    const nodes=Array.from(parent.childNodes);if(nodes.length!==records.length)return false;
    let count=0;
    for(let i=0;i<nodes.length;i++){
      const node=nodes[i],record=records[i];
      if(node.parentNode!==parent||!node.isConnected)return false;
      refs.push(node);
      if(exact(record,['formatterText'])){
        if(node.nodeType!==3||typeof record.formatterText!=='string'||Array.from(record.formatterText).some(c=>![9,10,12,13,32].includes(c.charCodeAt(0)))||node.textContent!==record.formatterText)return false;
      }else if(kind==='foreignNode'){
        if(!exact(record,['foreignNode'])||!Number.isInteger(record.foreignNode)||record.foreignNode!==count||
          count>=raw.bodyFrontier.length||!shape(node,raw.bodyFrontier[count]))return false;
        count++;
      }else{
        if(!exact(record,[kind])||record[kind]!==true||node!==target||++count!==1)return false;
      }
    }
    return kind==='foreignNode'?count===raw.bodyFrontier.length:count===1;
  };
  const validateCurrentBinding=()=>{
    try{
      const objects=[...graphObjects(request.source),...graphObjects(request.currentSsrSource)];
      if(request.requested!==true||request.requiredCurrentSsrKind!=='canonical-ssr-stage-callback-v1'||
        request.source!==source||request.currentSsrSource!==receipt||request.selector!==selector||request.layoutSelector!==layoutSelector||
        JSON.stringify(source)!==frozenSource||JSON.stringify(receipt)!==frozenReceipt||
        objects.length!==heldObjects.length||objects.some((o,i)=>o!==heldObjects[i])||receipt.harnessURL!==location.href||
        one(selector)!==frame||one(layoutSelector)!==frame||frame.parentElement!==capture||padding.parentElement!==frame||
        capture.getAttribute('data-parity-key')!==receipt.entryKey||frame.children.length!==1||frame.children[0]!==padding||
        !own(capture,raw.capture)||!own(frame,raw.frame)||!own(padding,raw.paddingOwner))return false;
      const refs=[capture,frame,padding];
      if(!scan(capture,raw.captureNodes,'frame',frame,refs)||!scan(frame,raw.frameNodes,'paddingOwner',padding,refs)||
        !scan(padding,raw.paddingNodes,'foreignNode',null,refs))return false;
      if(initial){heldNodes.push(...refs);initial=false;return true;}
      return refs.length===heldNodes.length&&refs.every((node,i)=>node===heldNodes[i]);
    }catch(_){return false;}
  };
  if(!validateCurrentBinding())return fail('STAGE_CURRENT_BINDING_CHANGED');
  return {applied:true,registryResultElement:frame,fieldUnitElement:frame,
    paddingSource:padding,frameSource:frame,registryIsLayoutRoot:true,
    authority:'original public Stage frame -> sole generated inner padding DIV -> whole opaque callback body; exact normal response and held references, no callback or resolver replay',
    validateCurrentBinding};
}
''';
