import 'dart:convert';

import 'package:coui_core/coui_core.dart' show CoreSurfaceStyleId;

import '../model/box_observation_source_spec.dart';

/// Holds only the original root and complete opaque generated top columns.
String get stepperHorizontalRequestBindingScript =>
    '''
(request) => {
  const expected=${jsonEncode(BoxObservationSourceSpec.stepperHorizontalHost.toJson())};
  const source=request.source;
  const claimed=source&&['logicalUnitId','nativeAdapterId','webAdapterId'].some(k=>source[k]===expected[k]);
  if(!claimed)return {applied:false};
  const fail=error=>({applied:true,error});
  const exact=(v,keys)=>v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===keys.length&&keys.every(k=>Object.hasOwn(v,k));
  const tuple=v=>exact(v,Object.keys(expected))&&Object.keys(expected).every(k=>v[k]===expected[k]);
  const receipt=request.currentSsrSource;
  if(request.requested!==true||!tuple(source)||request.requiredCurrentSsrKind!=='canonical-ssr-stepper-horizontal-v1'||
    !exact(receipt,['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL'])||
    receipt.kind!=='canonical-ssr-stepper-horizontal-v1'||!tuple(receipt.source)||
    !${jsonEncode([
      for (final variant in ['default', 'disabled'])
        for (final theme in ['light', 'dark'])
          for (final style in CoreSurfaceStyleId.values) 'stepper-$variant-$theme-${style.name}',
    ])}.includes(receipt.entryKey)||
    receipt.rawOrderFromPublicProducerLists!==true||typeof location==='undefined'||receipt.harnessURL!==location.href)
    return fail('STEPPER_ACTUAL_NORMAL_SSR_REQUIRED');
  const raw=receipt.currentRaw;
  if(!exact(raw,['kind','quantityBoundary','buildOrResolverReexecuted','columnInteriorsAreSourceAuthority',
    'frame','rawStepItems','generatedColumns','capture','captureNodes','frameNodes'])||
    raw.kind!=='current-stepper-horizontal-generated-root-v1'||
    raw.quantityBoundary!=='complete-horizontal-operation-to-generated-columns'||
    raw.buildOrResolverReexecuted!==false||raw.columnInteriorsAreSourceAuthority!==false||
    !Array.isArray(raw.rawStepItems)||!Array.isArray(raw.generatedColumns)||
    !Array.isArray(raw.captureNodes)||!Array.isArray(raw.frameNodes)||
    raw.rawStepItems.length!==3||raw.rawStepItems.length!==raw.generatedColumns.length||receipt.completeRawSlotCount!==3)
    return fail('STEPPER_COMPLETE_SOURCE_GRAPH_REQUIRED');
  for(let i=0;i<raw.rawStepItems.length;i++){
    const item=raw.rawStepItems[i],column=raw.generatedColumns[i];
    if(!exact(item,['index','label','description','descriptionMountedClaim','aliasesEarlier'])||
      item.index!==i||typeof item.label!=='string'||!(item.description===null||typeof item.description==='string')||
      item.descriptionMountedClaim!==false||!Array.isArray(item.aliasesEarlier)||
      new Set(item.aliasesEarlier).size!==item.aliasesEarlier.length||
      item.aliasesEarlier.some(j=>!Number.isInteger(j)||j<0||j>=i)||
      !exact(column,['index','present','generatedNotSupplied','opaque','nodeType','namespaceURI','localName'])||
      column.index!==i||column.present!==true||column.generatedNotSupplied!==true||column.opaque!==true||
      column.nodeType!==1||column.namespaceURI!=='http://www.w3.org/1999/xhtml'||column.localName!=='div')
      return fail('STEPPER_COMPLETE_DECLARED_GENERATED_ROSTER_REQUIRED');
  }
  const attrs=node=>Object.fromEntries(Array.from(node.attributes).map(a=>[a.name,a.value]));
  const same=(a,b)=>JSON.stringify(Object.entries(a).sort())===JSON.stringify(Object.entries(b).sort());
  const own=(node,record)=>node&&node.isConnected&&node.nodeType===1&&
    exact(record,['namespaceURI','localName','attributes'])&&record.namespaceURI==='http://www.w3.org/1999/xhtml'&&
    record.localName==='div'&&node.namespaceURI===record.namespaceURI&&node.localName===record.localName&&
    record.attributes&&same(attrs(node),record.attributes);
  const one=selector=>{try{const found=Array.from(document.querySelectorAll(selector));return found.length===1?found[0]:null;}catch(_){return null;}};
  const selector=request.selector,layoutSelector=request.layoutSelector;
  if(typeof selector!=='string'||!selector||typeof layoutSelector!=='string'||!layoutSelector)
    return fail('STEPPER_ORIGINAL_SELECTORS_REQUIRED');
  const frame=one(selector),layout=one(layoutSelector),capture=frame?.parentElement;
  if(!frame||frame!==layout||!capture||capture.getAttribute('data-parity-key')!==receipt.entryKey)
    return fail('STEPPER_ORIGINAL_ROOT_CHANGED');
  const graphObjects=value=>{const out=[];const visit=v=>{if(v&&typeof v==='object'){out.push(v);for(const child of Object.values(v))visit(child);}};visit(value);return out;};
  const heldObjects=[...graphObjects(source),...graphObjects(receipt)];
  const frozenSource=JSON.stringify(source),frozenReceipt=JSON.stringify(receipt);
  const heldNodes=[];let initial=true;
  const scan=(parent,records,kind,refs)=>{
    const nodes=Array.from(parent.childNodes);if(nodes.length!==records.length)return false;
    let count=0;
    for(let i=0;i<nodes.length;i++){
      const node=nodes[i],record=records[i];
      if(node.parentNode!==parent||!node.isConnected)return false;
      refs.push(node);
      if(exact(record,['formatterText'])){
        if(node.nodeType!==3||typeof record.formatterText!=='string'||
          Array.from(record.formatterText).some(c=>![9,10,12,13,32].includes(c.charCodeAt(0)))||
          node.textContent!==record.formatterText)return false;
      }else if(kind==='generatedColumn'){
        if(!exact(record,['generatedColumn'])||record.generatedColumn!==count||count>=raw.generatedColumns.length||
          node.nodeType!==1||node.namespaceURI!==raw.generatedColumns[count].namespaceURI||
          node.localName!==raw.generatedColumns[count].localName)return false;
        count++;
      }else if(!exact(record,['frame'])||record.frame!==true||node!==frame||++count!==1)return false;
    }
    return count===(kind==='generatedColumn'?raw.generatedColumns.length:1);
  };
  const validateCurrentBinding=()=>{
    try{
      const objects=[...graphObjects(request.source),...graphObjects(request.currentSsrSource)];
      if(request.requested!==true||request.requiredCurrentSsrKind!=='canonical-ssr-stepper-horizontal-v1'||
        request.source!==source||request.currentSsrSource!==receipt||request.selector!==selector||request.layoutSelector!==layoutSelector||
        JSON.stringify(source)!==frozenSource||JSON.stringify(receipt)!==frozenReceipt||
        objects.length!==heldObjects.length||objects.some((o,i)=>o!==heldObjects[i])||receipt.harnessURL!==location.href||
        one(selector)!==frame||one(layoutSelector)!==frame||frame.parentElement!==capture||
        capture.getAttribute('data-parity-key')!==receipt.entryKey||
        !own(capture,raw.capture)||!own(frame,raw.frame)||frame.children.length!==raw.generatedColumns.length)return false;
      const refs=[capture,frame];
      if(!scan(capture,raw.captureNodes,'frame',refs)||!scan(frame,raw.frameNodes,'generatedColumn',refs))return false;
      if(initial){heldNodes.push(...refs);initial=false;return true;}
      return refs.length===heldNodes.length&&refs.every((node,i)=>node===heldNodes[i]);
    }catch(_){return false;}
  };
  if(!validateCurrentBinding())return fail('STEPPER_CURRENT_BINDING_CHANGED');
  return {applied:true,registryResultElement:frame,fieldUnitElement:frame,
    paddingSource:frame,frameSource:frame,registryIsLayoutRoot:true,
    authority:'exact original public horizontal Stepper -> complete normal generated root DIV and ordered opaque generated columns; exact normal body and held identities, no build or resolver replay',
    validateCurrentBinding};
}
''';
