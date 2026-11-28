import 'dart:convert';

import '../model/box_observation_source_spec.dart';
import 'docs_card_registry_ssr_source.dart';

/// A passive extension of the ordinary documentation frame binding. Marker
/// interiors and coordinates never establish or select the padding owner.
String get docsAnatomyRequestBindingScript =>
    '''
(request) => {
 if(request.requested===false)return {applied:false};
 if(request.documentationSceneTag!=='Anatomy')return {applied:false};
 const fail=error=>({error:'DOCS_ANATOMY_'+error});
 if(request.requested!==true)return fail('STRICT_REQUESTED_FLAG_REQUIRED');
 const kind=${jsonEncode(kDocsCardRegistrySsrKind)},tuple=${jsonEncode(BoxObservationSourceSpec.docsStage.toJson())};
 const exact=(v,keys)=>v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===keys.length&&keys.every(k=>Object.hasOwn(v,k));
 const tupleMatches=v=>exact(v,Object.keys(tuple))&&Object.keys(tuple).every(k=>v[k]===tuple[k]);
 const source=request.source,receipt=request.currentSsrSource,route=request.documentationSceneRoute;
 if(!tupleMatches(source))return fail('TUPLE_CHANGED');
 if(!exact(route,['entryKey','sceneReference','sceneTag'])||route.sceneTag!=='Anatomy'||
 typeof route.entryKey!=='string'||typeof route.sceneReference!=='string'||
 !/^docs-v2-[0-9a-f]{32}\$/.test(route.sceneReference))return fail('SAME_NORMAL_ROUTE_REQUIRED');
 if(request.requiredCurrentSsrKind!==kind||typeof request.selector!=='string'||!request.selector||
 typeof request.layoutSelector!=='string'||!request.layoutSelector)return fail('REQUEST_CHANGED');
 if(!exact(receipt,['kind','entryKey','source','currentRaw','harnessURL'])||receipt.kind!==kind||
 !tupleMatches(receipt.source)||receipt.entryKey!==route.entryKey||receipt.harnessURL!==location.href)return fail('HEADER_CHANGED');
 const raw=receipt.currentRaw;
 if(!exact(raw,['kind','family','sceneTag','sceneReference','entryComponent','originalSceneInput','quantityBoundary','opaqueInteriorsRead','opaqueFrontiers','capture'])||
 raw.kind!=='current-documentation-frame-raw-v1'||raw.family!=='registry-scene'||raw.sceneTag!=='Anatomy'||
 raw.sceneReference!==route.sceneReference||raw.quantityBoundary!=='own-frame-only'||raw.opaqueInteriorsRead!==false)return fail('COMPLETE_SOURCE_CHANGED');
 const component=raw.entryComponent;
 if(typeof component!=='string'||!component||!['light','dark'].some(theme=>route.entryKey===component+'-'+raw.sceneReference+'-'+theme+'-defaultStyle'))return fail('CANONICAL_ENTRY_KEY_REQUIRED');
 const input=raw.originalSceneInput,a=input?.attributes,parts=input?.anatomyParts;
 if(input?.tag!=='Anatomy'||!exact(a,['demo'])||typeof a.demo!=='string'||
 !Array.isArray(input.selections)||input.selections.length!==1||!Array.isArray(parts)||parts.some(p=>typeof p!=='string')||
 !Array.isArray(input.anatomyBody))return fail('ORIGINAL_DECLARATION_CHANGED');
 const specs=parts.map(spec=>{
  const at=spec.lastIndexOf('@'),what=at<0?spec:spec.slice(0,at);
  const side=(at<0?'':spec.slice(at+1))||(what==='container'?'left':'top');return {what,side};
 });
 const same=(a,b)=>a.length===b.length&&a.every((v,i)=>v===b[i]);
 const element=(t,name,classes)=>t?.nodeType===1&&t.namespaceURI==='http://www.w3.org/1999/xhtml'&&t.localName===name&&
 (classes===null||t.attributes?.class===classes);
 const shape=(n,s)=>n?.nodeType===s.nodeType&&(s.nodeType!==1||n.namespaceURI===s.namespaceURI&&n.localName===s.localName);
 const shapeValid=s=>exact(s,s?.nodeType===1?['nodeType','namespaceURI','localName']:['nodeType'])&&
 (s.nodeType===3||s.nodeType===1&&typeof s.localName==='string'&&
 s.namespaceURI===(s.localName==='svg'?'http://www.w3.org/2000/svg':'http://www.w3.org/1999/xhtml'));
 if(!Array.isArray(raw.opaqueFrontiers)||raw.opaqueFrontiers.length!==2)return fail('OPAQUE_ROSTER_CHANGED');
 const purposes=['preview','anatomy-legend'];
 for(let i=0;i<2;i++){
  const f=raw.opaqueFrontiers[i];
  if(!exact(f,['index','purpose','nodes'])||f.index!==i||f.purpose!==purposes[i]||!Array.isArray(f.nodes)||!f.nodes.every(shapeValid))return fail('OPAQUE_ROSTER_CHANGED');
 }
 const legend=raw.opaqueFrontiers[1].nodes;
 if(legend.length!==1||!element({...legend[0],attributes:{}},'div',null))return fail('NORMAL_LEGEND_FRONTIER_CHANGED');
 const semantic=t=>Array.isArray(t?.children)?t.children.filter(c=>!c||typeof c!=='object'||!Object.hasOwn(c,'ownedText')):[];
 const one=(t,name,classes)=>{const c=semantic(t);return c.length===1&&element(c[0],name,classes)?c[0]:null;};
 const formatter=t=>exact(t,['ownedText'])&&typeof t.ownedText==='string'&&Array.from(t.ownedText).every(c=>[9,10,12,13,32].includes(c.charCodeAt(0)));
 const direct=(t,expected)=>{
  if(!Array.isArray(t?.children))return false;
  let at=0;
  const formatting=()=>{while(at<t.children.length&&t.children[at]&&Object.hasOwn(t.children[at],'ownedText'))if(!formatter(t.children[at++]))return false;return true;};
  for(const child of expected){
   if(Object.hasOwn(child,'frontierIndex')){
    const f=raw.opaqueFrontiers[child.frontierIndex];
    for(let j=0;j<f.nodes.length;j++){
     if(f.nodes[j].nodeType!==3&&!formatting())return false;
     const actual=t.children[at++];
     if(!exact(actual,['opaqueNode','frontierNode'])||actual.opaqueNode!==f.index||actual.frontierNode!==j)return false;
    }
   }else if(!formatting()||t.children[at++]!==child)return false;
  }
  return formatting()&&at===t.children.length;
 };
 const fixed=(t,name,attributes,children)=>exact(t,['nodeType','namespaceURI','localName','attributes','children'])&&element(t,name,null)&&
 t.attributes&&typeof t.attributes==='object'&&!Array.isArray(t.attributes)&&Object.keys(t.attributes).length===Object.keys(attributes).length&&
 Object.keys(attributes).every(k=>Object.hasOwn(t.attributes,k)&&typeof attributes[k]==='string'&&t.attributes[k]===attributes[k])&&direct(t,children);
 const cap=raw.capture,host=one(cap,'div','docs manual'),section=one(host,'section','content'),outer=one(section,'div','docs-anatomy not-content');
 const outerChildren=semantic(outer),stageTree=outerChildren[0],targetTree=one(stageTree,'div','docs-anatomy-target');
 if(!element(cap,'div',null)||cap.attributes?.['data-parity-key']!==receipt.entryKey||!host||!section||!outer||!targetTree||
 !fixed(targetTree,'div',{class:'docs-anatomy-target'},[{frontierIndex:0}])||
 !fixed(stageTree,'div',{class:'docs-stage docs-stage--240 docs-anatomy-stage','data-docs-anatomy':parts.join(';')},[targetTree])||
 !fixed(outer,'div',{class:'docs-anatomy not-content'},[stageTree,{frontierIndex:1}])||
 !fixed(section,'section',{class:'content'},[outer])||
 !fixed(host,'div',{id:'docs-shell',class:'docs manual',style:'width: 100%; min-width: 0','data-docs-scene':raw.sceneReference},[section])||
 !fixed(cap,'div',cap.attributes,[host]))return fail('EXACT_FACTORY_OWNED_GRAMMAR_CHANGED');
 let fields,roots;
 try{fields=Array.from(document.querySelectorAll(request.selector));roots=Array.from(document.querySelectorAll(request.layoutSelector));}
 catch(e){return fail('INVALID_SELECTOR');}
 if(fields.length!==1||roots.length!==1||fields[0]!==roots[0])return fail('UNIQUE_OWNER_REQUIRED');
 const owner=roots[0];let capture=owner;
 while(capture&&capture.getAttribute('data-parity-key')!==receipt.entryKey)capture=capture.parentElement;
 if(!capture||!owner.isConnected)return fail('CURRENT_CAPTURE_MISSING');
 const attrs=n=>JSON.stringify(Array.from(n.attributes).map(a=>[a.name,a.value]));
 const attrsMatch=(n,a)=>a&&typeof a==='object'&&!Array.isArray(a)&&Array.from(n.attributes).length===Object.keys(a).length&&
 Array.from(n.attributes).every(x=>typeof a[x.name]==='string'&&a[x.name]===x.value);
 // This preserves every existing resolver index/range/uniqueness/side rule.
 // Only outer decoration parameters are read, never an annotation interior.
 const annotation=(n,used)=>{
  if(n?.nodeType!==1||n.namespaceURI!=='http://www.w3.org/1999/xhtml'||n.localName!=='span')return false;
  const names=Array.from(n.attributes).map(a=>a.name);
  if(!['class','data-index','aria-hidden'].every(k=>names.includes(k))||names.some(k=>!['class','data-index','aria-hidden','hidden','style'].includes(k))||
  n.getAttribute('aria-hidden')!=='true')return false;
  const rawIndex=n.getAttribute('data-index'),index=Number(rawIndex);
  if(rawIndex===null||!Number.isSafeInteger(index)||String(index)!==rawIndex||index<0||index>=specs.length||!specs[index].what||used.has(index))return false;
  used.add(index);
  const classes=n.getAttribute('class').split(/[\\t\\n\\f\\r ]+/).filter(Boolean);
  if(!classes.includes('docs-anatomy-marker')||classes.some(k=>k!=='docs-anatomy-marker'&&k!=='is-'+specs[index].side))return false;
  if(n.getAttribute('hidden')!==null&&n.getAttribute('hidden')!=='')return false;
  const style=n.getAttribute('style');
  if(style!==null){
   const properties=new Set();
   for(const declaration of style.split(';').map(s=>s.trim()).filter(Boolean)){
    const at=declaration.indexOf(':'),name=declaration.slice(0,at).trim();
    if(at<0||!['left','top'].includes(name)||properties.has(name)||!declaration.slice(at+1).trim())return false;
    properties.add(name);
   }
  }
  return true;
 };
 const own=[],foreign=[],literal=[],annotations=[],seen=new Set(),frontierOrder=[],matched=new Map();
 const match=(node,t)=>{
  if(!exact(t,['nodeType','namespaceURI','localName','attributes','children'])||!['div','section'].includes(t.localName)||
  !element(t,t.localName,null)||!shape(node,t)||!attrsMatch(node,t.attributes)||!Array.isArray(t.children))return false;
  const children=Array.from(node.childNodes),count=t.children.length;
  if(t!==stageTree?children.length!==count:children.length<count)return false;
  own.push({node,parent:node.parentNode,children,attrs:attrs(node)});matched.set(t,node);
  for(let i=0;i<count;i++){
   const s=t.children[i],n=children[i];
   if(exact(s,['ownedText'])){
    if(!formatter(s)||n.nodeType!==3||n.data!==s.ownedText)return false;
    literal.push({node:n,parent:node,data:n.data});
   }else if(exact(s,['opaqueNode','frontierNode'])){
    if(!Number.isInteger(s.opaqueNode)||!Number.isInteger(s.frontierNode)||s.opaqueNode<0||s.frontierNode<0)return false;
    const expected=raw.opaqueFrontiers[s.opaqueNode]?.nodes[s.frontierNode],key=s.opaqueNode+':'+s.frontierNode;
    if(!expected||!shape(n,expected)||seen.has(key)||seen.has(n))return false;
    seen.add(key);seen.add(n);foreign.push({node:n,parent:node,shape:expected});frontierOrder.push(key);
   }else if(!match(n,s))return false;
  }
  if(t===stageTree){
   const used=new Set();
   for(const n of children.slice(count)){
    if(!annotation(n,used))return false;
    annotations.push({node:n,parent:node,attrs:attrs(n)});
   }
  }
  return true;
 };
 if(!match(capture,cap)||matched.get(stageTree)!==owner)return fail('EXACT_NORMAL_OWNED_TREE_CHANGED');
 const expectedOrder=raw.opaqueFrontiers.flatMap(f=>f.nodes.map((_,i)=>f.index+':'+i));
 if(!same(frontierOrder,expectedOrder))return fail('COMPLETE_OPAQUE_FRONTIER_CHANGED');
 const selector=request.selector,layoutSelector=request.layoutSelector,url=location.href;
 const records=v=>v&&typeof v==='object'?[v,...Object.values(v).flatMap(records)]:[];
 // These are recorded outer relationships, not an offline Element identity
 // claim. The SAME live references above are checked by this binding.
 const currentAnatomyEvidence={
  kind:'current-docs-anatomy-stage-roster-v1',quantityBoundary:'own-frame-only',
  normalBodyChildCount:stageTree.children.length,
  currentImmediateRoster:[...stageTree.children.map((_,i)=>({normalBodyNode:i})),
   ...annotations.map((_,i)=>({annotationRoot:i}))],
  annotationRoots:annotations.map(x=>({nodeType:1,namespaceURI:x.node.namespaceURI,localName:x.node.localName,
   attributes:Object.fromEntries(Array.from(x.node.attributes).map(a=>[a.name,a.value]))}))
 };
 const heldRecords=records(receipt),receiptJSON=JSON.stringify(receipt),sourceJSON=JSON.stringify(source);
 const routeJSON=JSON.stringify(route),routeRecords=records(route);
 const routeKey=route.entryKey,routeReference=route.sceneReference,routeTag=route.sceneTag;
 const evidenceRecords=records(currentAnatomyEvidence),evidenceJSON=JSON.stringify(currentAnatomyEvidence);
 const validateCurrentBinding=()=>{
  try{
   const f=Array.from(document.querySelectorAll(selector)),r=Array.from(document.querySelectorAll(layoutSelector)),used=new Set();
   return f.length===1&&r.length===1&&f[0]===owner&&r[0]===owner&&request.requested===true&&request.documentationSceneTag==='Anatomy'&&
   request.requiredCurrentSsrKind===kind&&request.documentationSceneRoute===route&&
   exact(route,['entryKey','sceneReference','sceneTag'])&&route.sceneTag===routeTag&&route.entryKey===routeKey&&route.sceneReference===routeReference&&
   JSON.stringify(route)===routeJSON&&same(records(route),routeRecords)&&route.sceneTag==='Anatomy'&&
   route.entryKey===receipt.entryKey&&route.sceneReference===raw.sceneReference&&request.selector===selector&&request.layoutSelector===layoutSelector&&
   request.source===source&&request.currentSsrSource===receipt&&location.href===url&&JSON.stringify(source)===sourceJSON&&
   JSON.stringify(receipt)===receiptJSON&&same(records(receipt),heldRecords)&&
   JSON.stringify(currentAnatomyEvidence)===evidenceJSON&&same(records(currentAnatomyEvidence),evidenceRecords)&&
   own.every(x=>x.node.isConnected&&x.node.parentNode===x.parent&&same(Array.from(x.node.childNodes),x.children)&&attrs(x.node)===x.attrs)&&
   foreign.every(x=>x.node.isConnected&&x.node.parentNode===x.parent&&shape(x.node,x.shape))&&
   literal.every(x=>x.node.parentNode===x.parent&&x.node.data===x.data)&&
   annotations.every(x=>x.node.isConnected&&x.node.parentNode===x.parent&&attrs(x.node)===x.attrs&&annotation(x.node,used));
  }catch(e){return false;}
 };
 if(!validateCurrentBinding())return fail('HELD_SOURCE_CHANGED');
 return {applied:true,registryResultElement:owner,fieldUnitElement:owner,paddingSource:owner,frameSource:owner,
 registryIsLayoutRoot:true,validateCurrentBinding,currentAnatomyEvidence,
 authority:'same normal Anatomy factory -> exact owned stage and target; complete held direct annotation roster, opaque preview/legend/annotation interiors'};
}
''';
