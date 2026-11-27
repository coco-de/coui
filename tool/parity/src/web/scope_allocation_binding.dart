// Validates the current SSR source and held scope allocation selectors.
import 'dart:convert';

import '../model/box_observation_source_spec.dart';

String get scopeAllocationBoxSourceResolverScript =>
    '''
(owner, source, receipt) => {
  const fail = error => ({error});
  const keys = (v, ks) => v && typeof v === 'object' && !Array.isArray(v) &&
    Object.keys(v).length === ks.length && ks.every(k => Object.hasOwn(v,k));
  const eq = (a,b) => keys(a,Object.keys(b)) && Object.keys(b).every(k => a[k]===b[k]);
  const expectedSource = ${jsonEncode(BoxObservationSourceSpec.scopeAllocationHost.toJson())};
  if (!eq(source,expectedSource)) return fail('SCOPE_DECLARED_TUPLE_CHANGED');
  if (!keys(receipt,['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL']) ||
      receipt.kind!=='canonical-ssr-scope-allocation-v1' ||
      typeof receipt.entryKey!=='string' || !receipt.entryKey || !eq(receipt.source,source) ||
      receipt.rawOrderFromPublicProducerLists!==true ||
      typeof location==='undefined' || receipt.harnessURL!==location.href)
    return fail('SCOPE_ACTUAL_RECEIPT_REQUIRED');
  const ns='http://www.w3.org/1999/xhtml';
  const div=n=>n && n.nodeType===1 && n.namespaceURI===ns && n.localName==='div';
  const ascii=n=>n.nodeType===3 && /^[\\t\\n\\f\\r ]*\$/.test(n.data);
  const capture=owner && owner.parentElement;
  if(!div(owner)||!owner.isConnected||!div(capture)||
      capture.getAttribute('data-parity-key')!==receipt.entryKey||
      capture.children.length!==1||capture.children[0]!==owner||
      Array.from(capture.childNodes).some(n=>n!==owner&&!ascii(n)))
    return fail('SCOPE_CANONICAL_OUTER_OWNER_CHANGED');
  const raw=receipt.currentRaw;
  if(!keys(raw,['kind','logicalUnitId','scopeKind','rawSlotCount','scopeChild','layoutSlots','owner','generatedTree','liveRegion'])||
      raw.kind!=='current-scope-allocation-raw-v1'||raw.logicalUnitId!==source.logicalUnitId||
      !['DragScope','SubfocusScope'].includes(raw.scopeKind)||
      !keys(raw.scopeChild,['seat','present','ownedLayout'])||raw.scopeChild.seat!==0||
      raw.scopeChild.present!==true||raw.scopeChild.ownedLayout!==true||
      !Number.isInteger(raw.rawSlotCount)||![3,4].includes(raw.rawSlotCount)||
      receipt.completeRawSlotCount!==raw.rawSlotCount||!Array.isArray(raw.layoutSlots)||
      raw.layoutSlots.length!==raw.rawSlotCount-1)
    return fail('SCOPE_COMPLETE_DECLARED_OCCURRENCES_REQUIRED');
  const slots=raw.layoutSlots;
  for(let i=0;i<slots.length;i++) {
    const s=slots[i],a=s?.sourceAliasOf;
    if(!keys(s,['seat','sourceAliasOf','nodes'])||s.seat!==i+1||
        !(a===null||(Number.isInteger(a)&&a>=1&&a<=i&&slots[a-1].sourceAliasOf===null))||
        !Array.isArray(s.nodes)||s.nodes.some(n=>!n||![1,3,8].includes(n.nodeType)||
          !keys(n,n.nodeType===1?['nodeType','namespaceURI','localName']:['nodeType'])))
      return fail('SCOPE_LAYOUT_OCCURRENCE_CHANGED');
  }
  const owned=t=>keys(t,['nodeType','namespaceURI','localName','attributes','children'])&&
    t.nodeType===1&&t.namespaceURI===ns&&typeof t.localName==='string'&&
    t.attributes&&typeof t.attributes==='object'&&!Array.isArray(t.attributes)&&
    Object.values(t.attributes).every(v=>typeof v==='string')&&Array.isArray(t.children);
  const tree=raw.generatedTree;
  if(!owned(tree)||tree.localName!=='div'||
      !keys(raw.owner,['namespaceURI','localName','attributes'])||
      raw.owner.namespaceURI!==ns||raw.owner.localName!=='div'||
      !raw.owner.attributes||typeof raw.owner.attributes!=='object'||Array.isArray(raw.owner.attributes)||
      !eq(tree.attributes,raw.owner.attributes)||
      tree.children.length!==(raw.scopeKind==='DragScope'?2:1))
    return fail('SCOPE_TYPED_GENERATED_OUTER_TREE_REQUIRED');
  const layout=tree.children[0];
  if(!owned(layout)||layout.localName!=='div'||layout.children.length!==slots.length||
      layout.children.some((s,i)=>!keys(s,['opaqueSlot'])||s.opaqueSlot!==i))
    return fail('SCOPE_ORIGINAL_LAYOUT_FRONTIER_REQUIRED');
  if(raw.scopeKind==='DragScope') {
    if(slots.length!==2)return fail('SCOPE_DRAG_LAYOUT_COUNT_CHANGED');
    const region=tree.children[1],span=region?.children?.[0],text=span?.children?.[0];
    if(!owned(region)||region.localName!=='div'||region.children.length!==1||
        !owned(span)||span.localName!=='span'||span.children.length!==1||
        !keys(text,['ownedAnnouncementText','sourceData','normalSerializedTextNodes'])||
        text.ownedAnnouncementText!==true||typeof text.sourceData!=='string'||
        !Array.isArray(text.normalSerializedTextNodes)||
        !text.normalSerializedTextNodes.every(v=>typeof v==='string')||
        (text.sourceData===''?text.normalSerializedTextNodes.length!==0:text.normalSerializedTextNodes.length===0)||
        !keys(raw.liveRegion,['present','sourceData','publicRoute','normalSerializedTextNodes'])||
        raw.liveRegion.present!==true||raw.liveRegion.sourceData!==text.sourceData||
        raw.liveRegion.publicRoute!=='CoUI Text.data -> generated SPAN -> Jaspr Text.text'||
        JSON.stringify(raw.liveRegion.normalSerializedTextNodes)!==JSON.stringify(text.normalSerializedTextNodes))
      return fail('SCOPE_OWNED_ACTUAL_ANNOUNCEMENT_REQUIRED');
  } else if(raw.liveRegion!==null||slots.length!==3) {
    return fail('SCOPE_SUBFOCUS_GENERATED_ROUTE_CHANGED');
  }
  const heldNodes=[],heldAttrs=[],heldData=[];
  const attrs=n=>Array.from(n.attributes).map(a=>[a.name,a.value]);
  const sameNodes=(a,b)=>a.length===b.length&&a.every((v,i)=>v===b[i]);
  const keep=(n,ownedNode=true)=>{
    if(heldNodes.includes(n)) throw new Error('SCOPE_REUSED_CURRENT_NODE');
    heldNodes.push(n);heldAttrs.push(ownedNode&&n.nodeType===1?JSON.stringify(attrs(n)):null);
    heldData.push(ownedNode&&(n.nodeType===3||n.nodeType===8)?n.data:null);
  };
  const bind=(node,t)=>{
    if(!node||node.nodeType!==1||node.namespaceURI!==t.namespaceURI||node.localName!==t.localName||
        !eq(Object.fromEntries(attrs(node)),t.attributes)) throw new Error('SCOPE_OWNED_NODE_CHANGED');
    keep(node);
    const children=Array.from(node.childNodes);let cursor=0;
    for(const part of t.children) {
      if(Object.hasOwn(part,'ownedAnnouncementText')) {
        if(children.length!==part.normalSerializedTextNodes.length||
            children.some((n,i)=>n.nodeType!==3||n.data!==part.normalSerializedTextNodes[i]))
          throw new Error('SCOPE_OWNED_TEXT_CHANGED');
        children.forEach(n=>keep(n));
        cursor=children.length;continue;
      }
      if(Object.hasOwn(part,'opaqueSlot')) {
        for(const shape of slots[part.opaqueSlot].nodes) {
          while(cursor<children.length&&shape.nodeType!==3&&ascii(children[cursor]))keep(children[cursor++]);
          const n=children[cursor++];
          if(!n||n.nodeType!==shape.nodeType||(shape.nodeType===1&&
              (n.namespaceURI!==shape.namespaceURI||n.localName!==shape.localName)))
            throw new Error('SCOPE_OPAQUE_FRONTIER_CHANGED');
          keep(n,false); // Foreign attrs/text/interiors stop here, intentionally.
        }
        continue;
      }
      while(cursor<children.length&&ascii(children[cursor]))keep(children[cursor++]);
      bind(children[cursor++],part);
    }
    for(const n of children.slice(cursor)){if(!ascii(n))throw new Error('SCOPE_EXTRA_OWNED_NODE');keep(n);}
    return {node,children};
  };
  let binding;
  try {binding=bind(owner,tree);}catch(e){return fail(String(e.message||e));}
  const captureNodes=Array.from(capture.childNodes),captureAttrs=JSON.stringify(attrs(capture));
  const nodeParents=heldNodes.map(n=>n.parentNode);
  // Retain child lists only for exact generated owned nodes, never for
  // a foreign frontier or any descendant inside that supplied occurrence.
  const ownedChildBindings=[];
  const holdOwned=(n,t)=>{ownedChildBindings.push([n,Array.from(n.childNodes)]);
    let i=0;for(const p of t.children){
      if(Object.hasOwn(p,'opaqueSlot')){for(const s of slots[p.opaqueSlot].nodes){while(i<n.childNodes.length&&s.nodeType!==3&&ascii(n.childNodes[i]))i++;i++;}}
      else if(Object.hasOwn(p,'ownedAnnouncementText'))i=n.childNodes.length;
      else {while(i<n.childNodes.length&&ascii(n.childNodes[i]))i++;holdOwned(n.childNodes[i++],p);}
    }};
  holdOwned(owner,tree);
  const tuple=receipt.source,receiptSnapshot=JSON.stringify(receipt),sourceSnapshot=JSON.stringify(source),url=location.href;
  const graphEdges=[],graphKeys=[],walked=new Set();
  const holdGraph=value=>{if(!value||typeof value!=='object'||walked.has(value))return;
    walked.add(value);const currentKeys=Object.keys(value);graphKeys.push([value,currentKeys]);
    for(const key of currentKeys){const child=value[key];
      graphEdges.push([value,key,child]);holdGraph(child);}};
  holdGraph(receipt);holdGraph(source);
  const slotRecords=slots.slice(),slotNodes=slots.map(s=>s.nodes),
    shapeRecords=slotNodes.map(a=>a.slice());
  const validateCurrentBinding=()=>{
    if(!owner.isConnected||owner.parentElement!==capture||!capture.isConnected||location.href!==url||
        receipt.harnessURL!==url||receipt.source!==tuple||receipt.currentRaw!==raw||raw.generatedTree!==tree||
        raw.layoutSlots!==slots||!sameNodes(slots,slotRecords)||
        slots.some((s,i)=>s.nodes!==slotNodes[i]||!sameNodes(s.nodes,shapeRecords[i]))||
        JSON.stringify(receipt)!==receiptSnapshot||JSON.stringify(source)!==sourceSnapshot||
        JSON.stringify(attrs(capture))!==captureAttrs||!sameNodes(Array.from(capture.childNodes),captureNodes)||
        graphEdges.some(([parent,key,child])=>parent[key]!==child)||
        graphKeys.some(([value,keys])=>!sameNodes(Object.keys(value),keys)))return false;
    if(ownedChildBindings.some(([n,children])=>!sameNodes(Array.from(n.childNodes),children)))return false;
    return heldNodes.every((n,i)=>n.parentNode===nodeParents[i]&&
      (heldAttrs[i]===null||JSON.stringify(attrs(n))===heldAttrs[i])&&
      (heldData[i]===null||n.data===heldData[i]));
  };
  if(!validateCurrentBinding())return fail('SCOPE_CURRENT_BINDING_CHANGED');
  return {registryResultElement:owner,fieldUnitElement:owner,paddingSource:owner,frameSource:owner,
    registryIsLayoutRoot:true,validateCurrentBinding,
    authority:'original exact public scope mount -> complete current generated outer scope DIV -> original scope.child/layout occurrences and owned live-region Text; foreign interiors opaque'};
}
''';

String get scopeAllocationRequestBindingScript =>
    '''
(request)=>{
  const source=request.source;
  const claims=request.requiredCurrentSsrKind==='canonical-ssr-scope-allocation-v1'||
    source?.logicalUnitId===${jsonEncode(BoxObservationSourceSpec.scopeAllocationHost.logicalUnitId)}||
    source?.webAdapterId===${jsonEncode(BoxObservationSourceSpec.scopeAllocationHost.webAdapterId)};
  if(!claims||!request.requested)return {applied:false};
  if(request.requiredCurrentSsrKind!=='canonical-ssr-scope-allocation-v1')return {error:'SCOPE_REQUIREMENT_MISSING'};
  const selector=request.selector,layoutSelector=request.layoutSelector;
  if(typeof selector!=='string'||!selector||typeof layoutSelector!=='string'||!layoutSelector)
    return {error:'SCOPE_SELECTOR_REQUIRED'};
  let fields,roots;
  try{fields=Array.from(document.querySelectorAll(selector));roots=Array.from(document.querySelectorAll(layoutSelector));}
  catch(e){return {error:'SCOPE_INVALID_SELECTOR'};}
  if(fields.length!==1||roots.length!==1||fields[0]!==roots[0])return {error:'SCOPE_UNIQUE_OUTER_OWNER_REQUIRED'};
  const receipt=request.currentSsrSource;
  const bound=($scopeAllocationBoxSourceResolverScript)(roots[0],source,receipt);
  if(bound.error)return bound;
  const original=bound.fieldUnitElement;
  const validateCurrentBinding=()=>{
    let f,r;
    try{f=Array.from(document.querySelectorAll(selector));r=Array.from(document.querySelectorAll(layoutSelector));}
    catch(e){return false;}
    return f.length===1&&r.length===1&&f[0]===original&&r[0]===original&&
      request.source===source&&request.currentSsrSource===receipt&&request.requested===true&&
      request.requiredCurrentSsrKind==='canonical-ssr-scope-allocation-v1'&&
      request.selector===selector&&request.layoutSelector===layoutSelector&&bound.validateCurrentBinding();
  };
  if(!validateCurrentBinding())return {error:'SCOPE_REQUEST_BINDING_CHANGED'};
  return {...bound,applied:true,validateCurrentBinding};
}
''';
