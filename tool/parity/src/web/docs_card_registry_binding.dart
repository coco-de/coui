import 'dart:convert';

import '../model/box_observation_source_spec.dart';
import 'docs_card_registry_ssr_source.dart';

/// Source references only. The coordinator invokes validateCurrentBinding
/// around every legacy and own-CSS phase; this script samples no styles.
String get docsCardRegistryRequestBindingScript =>
    '''
(request) => {
 if(request.requested===false)return {applied:false};
 const kind=${jsonEncode(kDocsCardRegistrySsrKind)};
 const tuples=${jsonEncode([BoxObservationSourceSpec.wholeDocCard.toJson(), BoxObservationSourceSpec.docsStage.toJson()])};
 const source=request.source,receipt=request.currentSsrSource,tag=request.documentationSceneTag;
 const claims=tuples.some(t=>t.logicalUnitId===source?.logicalUnitId||t.webAdapterId===source?.webAdapterId)||request.requiredCurrentSsrKind===kind;
 if(!claims)return {applied:false};
 const fail=error=>({error:'DOCS_FRAME_'+error});
 if(request.requested!==true)return fail('STRICT_REQUESTED_FLAG_REQUIRED');
 const exact=(v,keys)=>v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===keys.length&&keys.every(k=>Object.hasOwn(v,k));
 const tuple=tuples.find(t=>t.logicalUnitId===source?.logicalUnitId);
 const tupleMatches=v=>tuple&&exact(v,Object.keys(tuple))&&Object.keys(tuple).every(k=>v[k]===tuple[k]);
 if(!tupleMatches(source))return fail('TUPLE_CHANGED');
 const card=tuple.logicalUnitId==='whole-documentation-card';
 const route=request.documentationSceneRoute;
 if(!exact(route,['entryKey','sceneReference','sceneTag'])||route.sceneTag!==tag||
 typeof route.entryKey!=='string'||typeof route.sceneReference!=='string'||
 !/^docs-v2-[0-9a-f]{32}\$/.test(route.sceneReference)||!route.entryKey.includes('-'+route.sceneReference+'-'))return fail('SAME_NORMAL_SCENE_ROUTE_REQUIRED');
 // This route fact comes from the same already-resolved scene as the normal
 // build. Intentionally held Anatomy is explicit, never missing-receipt fallback.
 if(tag==='Anatomy'&&!card&&request.requiredCurrentSsrKind==null&&receipt==null){
  let f,r;
  try{f=Array.from(document.querySelectorAll(request.selector));r=Array.from(document.querySelectorAll(request.layoutSelector));}
  catch(e){return fail('ANATOMY_HOLD_SELECTOR_CHANGED');}
  if(f.length!==1||r.length!==1||f[0]!==r[0])return fail('ANATOMY_HOLD_UNIQUE_ROUTE_REQUIRED');
  const stage=r[0],anatomy=stage.parentElement,section=anatomy?.parentElement,host=section?.parentElement,capture=host?.parentElement;
  const own=(n,name,classes)=>n?.nodeType===1&&n.namespaceURI==='http://www.w3.org/1999/xhtml'&&n.localName===name&&n.getAttribute('class')===classes;
  if(!stage.isConnected||!own(stage,'div','docs-stage docs-stage--240 docs-anatomy-stage')||
  !own(anatomy,'div','docs-anatomy not-content')||anatomy.children.length!==2||anatomy.children[0]!==stage||
  !own(anatomy.children[1],'div','docs-anatomy-legend')||!own(section,'section','content')||section.children.length!==1||section.children[0]!==anatomy||
  !own(host,'div','docs manual')||host.getAttribute('id')!=='docs-shell'||host.getAttribute('data-docs-scene')!==route.sceneReference||
  host.children.length!==1||host.children[0]!==section||capture?.getAttribute('data-parity-key')!==route.entryKey||
  capture.children.length!==1||capture.children[0]!==host)return fail('ANATOMY_HOLD_NORMAL_ROUTE_CHANGED');
  // No target, preview, legend interior or runtime marker is read or credited.
  return {applied:false};
 }
 if(card?tag!=='Card':!['Preview','VariantRow'].includes(tag))return fail('CLOSED_SCENE_ROUTE_REQUIRED');
 if(request.requiredCurrentSsrKind!==kind||typeof request.selector!=='string'||!request.selector||
 typeof request.layoutSelector!=='string'||!request.layoutSelector)return fail('REQUEST_CHANGED');
 if(!exact(receipt,['kind','entryKey','source','currentRaw','harnessURL'])||receipt.kind!==kind||
 !tupleMatches(receipt.source)||receipt.harnessURL!==location.href||receipt.entryKey!==route.entryKey)return fail('HEADER_CHANGED');
 const raw=receipt.currentRaw;
 if(!exact(raw,['kind','family','sceneTag','sceneReference','originalSceneInput','quantityBoundary','opaqueInteriorsRead','opaqueFrontiers','capture'])||
 raw.kind!=='current-documentation-frame-raw-v1'||raw.family!==(card?'whole-card':'registry-scene')||raw.sceneTag!==tag||
 raw.sceneReference!==route.sceneReference||
 !receipt.entryKey.includes('-'+raw.sceneReference+'-')||raw.quantityBoundary!=='own-frame-only'||raw.opaqueInteriorsRead!==false||
 raw.originalSceneInput?.tag!==tag||!Array.isArray(raw.opaqueFrontiers))return fail('COMPLETE_SOURCE_CHANGED');
 const input=raw.originalSceneInput,a=input.attributes;
 if(!a||typeof a!=='object'||Array.isArray(a)||Object.values(a).some(v=>typeof v!=='string')||
 !Array.isArray(input.selections)||input.selections.length!==1||(!Object.hasOwn(a,'component')&&!Object.hasOwn(a,'demo'))||
 (card&&(input.captureUnit!=='whole-card'||input.cardIndex!==0||!Array.isArray(input.cardBody)||input.cardBody.length===0||
 a.value!=null||a.badge!=null)))return fail('ORIGINAL_BRANCH_CHANGED');
 const semantic=t=>Array.isArray(t?.children)?t.children.filter(c=>!Object.hasOwn(c,'ownedText')):[];
 const element=(t,name,classes)=>t?.nodeType===1&&t.namespaceURI==='http://www.w3.org/1999/xhtml'&&t.localName===name&&
 (classes===null||t.attributes?.class===classes);
 const one=(t,name,classes)=>{const c=semantic(t);return c.length===1&&element(c[0],name,classes)?c[0]:null;};
 const cap=raw.capture,host=one(cap,'div','docs manual'),section=one(host,'section','content');
 if(!element(cap,'div',null)||cap.attributes?.['data-parity-key']!==receipt.entryKey||!host||host.attributes?.id!=='docs-shell'||
 host.attributes?.['data-docs-scene']!==raw.sceneReference||!section)return fail('OWNED_CAPTURE_ROUTE_CHANGED');
 const height=['140','240','340','hug'].includes(a.height)?' docs-stage--'+a.height:'';
 const stageClass=compact=>'docs-stage'+(compact?' docs-stage--compact':'')+height+' not-content';
 let ownerTree,registryTree;
 if(card){
  registryTree=one(section,'div','docs-cards not-content');
  const roots=semantic(registryTree);ownerTree=roots.length===1?roots[0]:null;
  const tone=['do','dont'].includes(a.tone)?' docs-card--'+a.tone:'';
  if(!registryTree||registryTree.attributes?.['data-docs-reveal']!==''||
  !element(ownerTree,a.href==null?'div':'a','docs-card'+tone+' docs-card--preview'+(a.href==null?'':' site-box-link'))||
  (a.href==null?Object.hasOwn(ownerTree.attributes,'href'):ownerTree.attributes?.href!==a.href))return fail('WHOLE_CARD_BRANCH_CHANGED');
  const parts=semantic(ownerTree);let i=0;
  if(!element(parts[i++],'div',stageClass(false)))return fail('CARD_STAGE_CHANGED');
  if(a.eyebrow!=null&&!element(parts[i++],'span','docs-card-eyebrow'))return fail('CARD_EYEBROW_CHANGED');
  if(a.title!=null&&!element(parts[i++],'div','docs-card-head'))return fail('CARD_HEAD_CHANGED');
  if(!element(parts[i++],'div','docs-card-body'))return fail('CARD_BODY_CHANGED');
  if(a.href!=null&&a.more!=null){
   const more=parts[i++],m=semantic(more);
   if(!element(more,'span','docs-card-more')||m.length!==2||!element(m[1],'span','site-arrow')||
   m[1].attributes?.['aria-hidden']!=='true')return fail('CARD_MORE_CHANGED');
  }
  if(i!==parts.length)return fail('EXTRA_CARD_PART');
 }else{
  ownerTree=one(section,'div',stageClass(tag==='VariantRow'));registryTree=ownerTree;
  if(!ownerTree)return fail('REGISTRY_STAGE_CHANGED');
 }
 const same=(a,b)=>a.length===b.length&&a.every((v,i)=>v===b[i]);
 const attrs=n=>JSON.stringify(Array.from(n.attributes).map(a=>[a.name,a.value]));
 const attrsMatch=(n,a)=>a&&typeof a==='object'&&!Array.isArray(a)&&Array.from(n.attributes).length===Object.keys(a).length&&
 Array.from(n.attributes).every(x=>typeof a[x.name]==='string'&&a[x.name]===x.value);
 const shape=(n,s)=>n?.nodeType===s.nodeType&&(s.nodeType!==1||n.namespaceURI===s.namespaceURI&&n.localName===s.localName);
 const shapeValid=s=>exact(s,s?.nodeType===1?['nodeType','namespaceURI','localName']:['nodeType'])&&
 (s.nodeType===3||s.nodeType===1&&s.namespaceURI==='http://www.w3.org/1999/xhtml'&&typeof s.localName==='string');
 for(let i=0;i<raw.opaqueFrontiers.length;i++){
  const f=raw.opaqueFrontiers[i];
  if(!exact(f,['index','purpose','nodes'])||f.index!==i||!['preview','eyebrow-label','title-label','markdown-body','more-label','arrow-label'].includes(f.purpose)||
  !Array.isArray(f.nodes)||!f.nodes.every(shapeValid))return fail('OPAQUE_ROSTER_CHANGED');
 }
 const purposes=card?['preview',...(a.eyebrow!=null?['eyebrow-label']:[]),...(a.title!=null?['title-label']:[]),'markdown-body',
 ...(a.href!=null&&a.more!=null?['more-label','arrow-label']:[])]:['preview'];
 if(!same(raw.opaqueFrontiers.map(f=>f.purpose),purposes))return fail('COMPLETE_OPAQUE_PURPOSES_CHANGED');
 let fields,roots;
 try{fields=Array.from(document.querySelectorAll(request.selector));roots=Array.from(document.querySelectorAll(request.layoutSelector));}
 catch(e){return fail('INVALID_SELECTOR');}
 if(fields.length!==1||roots.length!==1||fields[0]!==roots[0])return fail('UNIQUE_OWNER_REQUIRED');
 const owner=roots[0];let capture=owner;
 while(capture&&capture.getAttribute('data-parity-key')!==receipt.entryKey)capture=capture.parentElement;
 if(!capture||!owner.isConnected)return fail('CURRENT_CAPTURE_MISSING');
 const own=[],foreign=[],literal=[],seen=new Set(),frontierOrder=[],matched=new Map();
 const match=(node,t)=>{
  if(!exact(t,['nodeType','namespaceURI','localName','attributes','children'])||!['div','section','span','a'].includes(t.localName)||
  !element(t,t.localName,null)||!shape(node,t)||!attrsMatch(node,t.attributes)||!Array.isArray(t.children))return false;
  const children=Array.from(node.childNodes);if(children.length!==t.children.length)return false;
  own.push({node,parent:node.parentNode,children,attrs:attrs(node)});matched.set(t,node);
  for(let i=0;i<t.children.length;i++){
   const s=t.children[i],n=children[i];
   if(exact(s,['ownedText'])){
    if(typeof s.ownedText!=='string'||n.nodeType!==3||n.data!==s.ownedText)return false;
    literal.push({node:n,parent:node,data:n.data});
   }else if(exact(s,['opaqueNode','frontierNode'])){
    if(!Number.isInteger(s.opaqueNode)||!Number.isInteger(s.frontierNode)||s.opaqueNode<0||s.frontierNode<0)return false;
    const f=raw.opaqueFrontiers[s.opaqueNode],expected=f?.nodes[s.frontierNode];
    const key=s.opaqueNode+':'+s.frontierNode;
    if(!expected||!shape(n,expected)||seen.has(key)||seen.has(n))return false;
    seen.add(key);seen.add(n);foreign.push({node:n,parent:node,shape:expected});frontierOrder.push(key);
   }else if(!match(n,s))return false;
  }
  return true;
 };
 if(!match(capture,cap)||matched.get(ownerTree)!==owner)return fail('EXACT_NORMAL_OWNED_TREE_CHANGED');
 const expectedOrder=raw.opaqueFrontiers.flatMap(f=>f.nodes.map((_,i)=>f.index+':'+i));
 if(!same(frontierOrder,expectedOrder))return fail('COMPLETE_OPAQUE_FRONTIER_CHANGED');
 const registry=matched.get(registryTree),selector=request.selector,layoutSelector=request.layoutSelector,url=location.href;
 const records=v=>v&&typeof v==='object'?[v,...Object.values(v).flatMap(records)]:[];
 const heldRecords=records(receipt),receiptJSON=JSON.stringify(receipt),sourceJSON=JSON.stringify(source);
 const validateCurrentBinding=()=>{
  try{
   const f=Array.from(document.querySelectorAll(selector)),r=Array.from(document.querySelectorAll(layoutSelector));
   return f.length===1&&r.length===1&&f[0]===owner&&r[0]===owner&&request.requested===true&&
   request.requiredCurrentSsrKind===kind&&request.documentationSceneTag===tag&&request.documentationSceneRoute===route&&
   route.sceneTag===tag&&route.entryKey===receipt.entryKey&&route.sceneReference===raw.sceneReference&&request.selector===selector&&request.layoutSelector===layoutSelector&&
   request.source===source&&request.currentSsrSource===receipt&&location.href===url&&JSON.stringify(source)===sourceJSON&&
   JSON.stringify(receipt)===receiptJSON&&same(records(receipt),heldRecords)&&
   own.every(x=>x.node.isConnected&&x.node.parentNode===x.parent&&same(Array.from(x.node.childNodes),x.children)&&attrs(x.node)===x.attrs)&&
   foreign.every(x=>x.node.isConnected&&x.node.parentNode===x.parent&&shape(x.node,x.shape))&&
   literal.every(x=>x.node.parentNode===x.parent&&x.node.data===x.data);
  }catch(e){return false;}
 };
 if(!validateCurrentBinding())return fail('HELD_SOURCE_CHANGED');
 return {applied:true,registryResultElement:registry,fieldUnitElement:owner,paddingSource:owner,frameSource:owner,
 registryIsLayoutRoot:registry===owner,validateCurrentBinding,
 authority:'original documentation factory -> exact own frame and public slot-target opaque frontier; preview/body interiors excluded'};
}
''';
