import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Validates the completed actual response before either sampler reads styles.
/// Owned Text is matched literally; supplied frontier interiors stay opaque.
String get cardAccordionFrameRequestBindingScript =>
    '''
(request) => {
 const tuples=${jsonEncode(BoxObservationSourceSpec.cardAccordionSurfaceFrames.map((s) => s.toJson()).toList())};
 const source=request.source, receipt=request.currentSsrSource;
 const claims=tuples.some(t=>t.logicalUnitId===source?.logicalUnitId||t.webAdapterId===source?.webAdapterId)||request.requiredCurrentSsrKind==='canonical-ssr-surface-frame-v1';
 if(!claims||!request.requested)return {applied:false};
 const fail=error=>({error:'SURFACE_FRAME_'+error});
 const exact=(v,ks)=>v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===ks.length&&ks.every(k=>Object.hasOwn(v,k));
 const tuple=tuples.find(t=>t.logicalUnitId===source?.logicalUnitId);
 const tupleMatches=v=>tuple&&exact(v,Object.keys(tuple))&&Object.keys(tuple).every(k=>v[k]===tuple[k]);
 if(!tupleMatches(source)||request.requested!==true||request.requiredCurrentSsrKind!=='canonical-ssr-surface-frame-v1'||
 typeof request.selector!=='string'||!request.selector||typeof request.layoutSelector!=='string'||!request.layoutSelector)
  return fail('REQUEST_CHANGED');
 if(!exact(receipt,['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL'])||
 receipt.kind!=='canonical-ssr-surface-frame-v1'||!tupleMatches(receipt.source)||receipt.harnessURL!==location.href||
 typeof receipt.entryKey!=='string'||!receipt.entryKey||receipt.rawOrderFromPublicProducerLists!==true)return fail('HEADER_CHANGED');
 const raw=receipt.currentRaw,card=tuple.logicalUnitId==='card-surface-frame-content-inset',count=card?6:3;
 if(!exact(raw,['kind','logicalUnitId','rawSlotCount','rawDeclarations','rawDeclarationMountAuthority','opaqueFrontiers','generatedTree','quantityBoundary','distributedSlotAndItemInsetsIncluded','capture'])||
 raw.kind!=='current-surface-frame-raw-v1'||raw.logicalUnitId!==tuple.logicalUnitId||raw.rawSlotCount!==count||receipt.completeRawSlotCount!==count||
 raw.rawDeclarationMountAuthority!==false||raw.quantityBoundary!=='outer-surface-to-immediate-generated-content'||raw.distributedSlotAndItemInsetsIncluded!==false||
 !Array.isArray(raw.rawDeclarations)||raw.rawDeclarations.length!==count||!Array.isArray(raw.opaqueFrontiers))return fail('COMPLETE_RAW_CHANGED');
 const names=['child','media','header','body','footer','overlay'];
 for(let i=0;i<count;i++){
  const d=raw.rawDeclarations[i];
  if(!exact(d,card?['index','slot','present','sourceAliasOf','authority']:['index','present','sourceAliasOf','titlePresent','triggerPresent','contentPresent','authority'])||
  d.index!==i||typeof d.present!=='boolean'||!(d.sourceAliasOf===null||d.present&&Number.isInteger(d.sourceAliasOf)&&d.sourceAliasOf>=0&&d.sourceAliasOf<i&&raw.rawDeclarations[d.sourceAliasOf].present))return fail('DECLARATION_CHANGED');
  if(card?(d.slot!==names[i]||d.authority!=='public-declaration'):
    (d.present!==true||typeof d.titlePresent!=='boolean'||typeof d.triggerPresent!=='boolean'||d.contentPresent!==true||d.authority!=='public-item-data-not-mounted-item'))return fail('DECLARATION_AUTHORITY_CHANGED');
 }
 const shape=(n,s)=>n?.nodeType===s.nodeType&&(s.nodeType!==1||n.namespaceURI===s.namespaceURI&&n.localName===s.localName);
 const validShape=s=>exact(s,s?.nodeType===1?['nodeType','namespaceURI','localName']:['nodeType'])&&
 ([3,8].includes(s.nodeType)||s.nodeType===1&&typeof s.namespaceURI==='string'&&typeof s.localName==='string');
 let total=0;
 const indices=[];
 for(let i=0;i<raw.opaqueFrontiers.length;i++){
  const f=raw.opaqueFrontiers[i];
  if(!exact(f,['index','declarationIndex','authority','nodes','frontierOrder'])||f.index!==i||!Number.isInteger(f.declarationIndex)||f.declarationIndex<0||f.declarationIndex>=count||
  !raw.rawDeclarations[f.declarationIndex].present||indices.includes(f.declarationIndex)||
  f.authority!==(card?'same-public-Component-occurrence':'original-generated-item-position')||!Array.isArray(f.nodes)||!f.nodes.every(validShape)||
  !Array.isArray(f.frontierOrder)||f.frontierOrder.length!==f.nodes.length||f.frontierOrder.some(n=>n!==total++))return fail('FRONTIER_DECLARATION_CHANGED');
  indices.push(f.declarationIndex);
 }
 const present=i=>raw.rawDeclarations[i].present;
 const required=card?(present(0)?[0]:[...(present(1)?[1,...(present(5)?[5]:[])]:[]),...[2,3,4].filter(present)]):[0,1,2];
 if(JSON.stringify(indices)!==JSON.stringify(required))return fail('WHOLE_ACTIVE_DECLARATIONS_CHANGED');
 let fields,roots;
 try{fields=Array.from(document.querySelectorAll(request.selector));roots=Array.from(document.querySelectorAll(request.layoutSelector));}catch(e){return fail('INVALID_SELECTOR');}
 if(fields.length!==1||roots.length!==1||fields[0]!==roots[0])return fail('UNIQUE_OWNER_REQUIRED');
 const owner=roots[0],capture=owner.parentElement,ns='http://www.w3.org/1999/xhtml';
 if(!capture||!owner.isConnected||capture.getAttribute('data-parity-key')!==receipt.entryKey||capture.children.length!==1||capture.children[0]!==owner)return fail('CAPTURE_CHANGED');
 const same=(a,b)=>a.length===b.length&&a.every((v,i)=>v===b[i]);
 const attrs=n=>JSON.stringify(Array.from(n.attributes).map(a=>[a.name,a.value]));
 const attrsMatch=(n,a)=>a&&typeof a==='object'&&!Array.isArray(a)&&Array.from(n.attributes).length===Object.keys(a).length&&Array.from(n.attributes).every(x=>typeof a[x.name]==='string'&&a[x.name]===x.value);
 const own=[],foreign=[],literal=[],used=new Set(),frontierOrder=[];
 const match=(node,t)=>{
  if(!exact(t,['nodeType','namespaceURI','localName','attributes','children'])||t.nodeType!==1||t.namespaceURI!==ns||t.localName!=='div'||
  node?.nodeType!==1||node.namespaceURI!==t.namespaceURI||node.localName!==t.localName||!attrsMatch(node,t.attributes)||!Array.isArray(t.children))return false;
  const children=Array.from(node.childNodes);if(children.length!==t.children.length)return false;
  own.push({node,children,attrs:attrs(node)});
  for(let i=0;i<t.children.length;i++){
   const child=t.children[i],actual=children[i];
   if(exact(child,['ownedText'])){
    if(typeof child.ownedText!=='string'||actual.nodeType!==3||actual.data!==child.ownedText)return false;
    literal.push({node:actual,data:actual.data,parent:node});
   }else if(exact(child,['opaqueNode','frontierNode'])){
    if(!Number.isInteger(child.opaqueNode)||child.opaqueNode<0||child.opaqueNode>=raw.opaqueFrontiers.length)return false;
    const f=raw.opaqueFrontiers[child.opaqueNode],j=child.frontierNode;
    if(!Number.isInteger(j)||j<0||j>=f.nodes.length||!shape(actual,f.nodes[j])||used.has(actual))return false;
    used.add(actual);foreign.push({node:actual,parent:node,shape:f.nodes[j]});frontierOrder.push(f.frontierOrder[j]);
   }else if(!match(actual,child))return false;
  }
  return true;
 };
 if(!match(capture,raw.capture)||frontierOrder.length!==total||frontierOrder.some((n,i)=>n!==i))return fail('EXACT_NORMAL_FRONTIER_CHANGED');
 const ownerTree=raw.capture.children.filter(c=>c.nodeType===1);
 if(ownerTree.length!==1||JSON.stringify(ownerTree[0])!==JSON.stringify(raw.generatedTree))return fail('SAME_FRAME_TREE_REQUIRED');
 const records=v=>v&&typeof v==='object'?[v,...Object.values(v).flatMap(records)]:[];
 const selector=request.selector,layoutSelector=request.layoutSelector,url=location.href;
 const heldRecords=records(receipt),receiptJSON=JSON.stringify(receipt),sourceJSON=JSON.stringify(source);
 const validateCurrentBinding=()=>{
  try{
   const nowFields=Array.from(document.querySelectorAll(selector)),nowRoots=Array.from(document.querySelectorAll(layoutSelector));
   return nowFields.length===1&&nowRoots.length===1&&nowFields[0]===owner&&nowRoots[0]===owner&&
   request.requested===true&&request.requiredCurrentSsrKind==='canonical-ssr-surface-frame-v1'&&request.selector===selector&&request.layoutSelector===layoutSelector&&
   request.source===source&&request.currentSsrSource===receipt&&location.href===url&&JSON.stringify(source)===sourceJSON&&JSON.stringify(receipt)===receiptJSON&&same(records(receipt),heldRecords)&&
   owner.parentElement===capture&&own.every(x=>x.node.isConnected&&same(Array.from(x.node.childNodes),x.children)&&attrs(x.node)===x.attrs)&&
   foreign.every(x=>x.node.isConnected&&x.node.parentNode===x.parent&&shape(x.node,x.shape))&&literal.every(x=>x.node.parentNode===x.parent&&x.node.data===x.data);
  }catch(e){return false;}
 };
 if(!validateCurrentBinding())return fail('HELD_BINDING_CHANGED');
 return {applied:true,registryResultElement:owner,fieldUnitElement:owner,paddingSource:owner,frameSource:owner,
 registryIsLayoutRoot:true,validateCurrentBinding,
 authority:'original exact public surface frame -> immediate generated opaque content boundary; distributed slot and item insets excluded'};
}
''';
