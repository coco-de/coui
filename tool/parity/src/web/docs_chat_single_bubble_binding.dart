import 'dart:convert';

import '../model/box_observation_source_spec.dart';
import 'docs_chat_single_bubble_ssr_source.dart';

/// References/declarations only. The common coordinator must call the held
/// validator before and after both unchanged CSS phases. No CSS is read here.
String get docsChatSingleBubbleRequestBindingScript =>
    '''
(request) => {
 if(request.requested===false)return {applied:false};
 const kind=${jsonEncode(kDocsChatSingleBubbleSsrKind)},expected=${jsonEncode(BoxObservationSourceSpec.docsChatSingleBubble.toJson())};
 const source=request.source;
 const claims=request.requiredCurrentSsrKind===kind||source&&['logicalUnitId','nativeAdapterId','webAdapterId'].some(k=>source[k]===expected[k]);
 if(!claims)return {applied:false};
 const fail=e=>({error:'DOCS_CHAT_'+e});
 const exact=(v,keys)=>v&&typeof v==='object'&&!Array.isArray(v)&&Object.keys(v).length===keys.length&&keys.every(k=>Object.hasOwn(v,k));
 const tuple=v=>exact(v,Object.keys(expected))&&Object.keys(expected).every(k=>v[k]===expected[k]);
 if(request.requested!==true)return fail('STRICT_REQUESTED_FLAG_REQUIRED');
 if(!tuple(source)||request.requiredCurrentSsrKind!==kind)return fail('EXACT_TUPLE_AND_KIND_REQUIRED');
 const receipt=request.currentSsrSource;
 if(!exact(receipt,['kind','entryKey','source','currentRaw','harnessURL'])||receipt.kind!==kind||!tuple(receipt.source)||
 typeof location==='undefined'||receipt.harnessURL!==location.href||
 !/^chat-(neutral|primary|secondary|accent|info|success|warning|error)-(light|dark)-defaultStyle\$/.test(receipt.entryKey))return fail('EXACT16_CURRENT_HEADER_REQUIRED');
 const raw=receipt.currentRaw,variant=receipt.entryKey.split('-')[1];
 if(!exact(raw,['kind','variant','quantityBoundary','opaqueInteriorsRead','rawParameters','bodyDeclaration','opaqueFrontiers','capture'])||
 raw.kind!=='current-documentation-chat-bubble-raw-v1'||raw.variant!==variant||
 raw.quantityBoundary!=='own-bubble-body-only'||raw.opaqueInteriorsRead!==false)return fail('COMPLETE_RAW_REQUIRED');
 const p=raw.rawParameters;
 if(!exact(p,['chatAlignment','bubbleVariant','bubbleAlignment','bubbleTail','instanceStyle','instanceCss',
 'scopeAlignment','scopeChildIsOriginalBubble','themePadding'])||p.chatAlignment!=='start'||p.bubbleVariant!==variant||
 p.bubbleAlignment!==null||p.bubbleTail!==null||p.instanceStyle!==null||p.instanceCss!==null||
 p.scopeAlignment!=='start'||p.scopeChildIsOriginalBubble!==true)return fail('RAW_NULL_AND_SCOPE_FORWARDING_CHANGED');
 const t=p.themePadding,flagKeys=['componentThemePresent','bubbleThemePresent','baseStylePresent','variantMapPresent','selectedEntryPresent','selectedStylePresent'];
 if(!exact(t,['themeElement','themeData',...flagKeys,'basePadding','selectedPadding'])||
 !Number.isSafeInteger(t.themeElement)||!Number.isSafeInteger(t.themeData)||flagKeys.some(k=>typeof t[k]!=='boolean')||
 ![t.basePadding,t.selectedPadding].every(v=>v===null||Number.isSafeInteger(v))||
 !t.componentThemePresent&&t.bubbleThemePresent||
 !t.bubbleThemePresent&&(t.baseStylePresent||t.variantMapPresent||t.selectedEntryPresent||t.selectedStylePresent)||
 !t.baseStylePresent&&t.basePadding!==null||
 t.variantMapPresent!==false||t.selectedEntryPresent!==false||t.selectedStylePresent!==false||t.selectedPadding!==null)
 return fail('ACTUAL_SELECTED_THEME_PADDING_CHAIN_REQUIRED');
 // Reference integers can collide; neither uniqueness nor numerical values
 // determine ownership. The qualified producer holds the actual references.
 const typographyRoles=new Set(${jsonEncode(kDocsChatBodyTypographyRoleClasses.toList())}),colorNames=new Set(${jsonEncode(kDocsChatBodyColorTokenNames.toList())});
 const colorChannel=(value,prefix)=>{
  if(!value.startsWith(prefix))return false;const parts=value.slice(prefix.length).split('/');
  if(!colorNames.has(parts[0]))return false;if(parts.length===1)return true;if(parts.length!==2)return false;
  const a=parts[1];return a.length>=1&&a.length<=2&&(a==='0'||a[0]!=='0')&&Array.from(a).every(c=>c>='0'&&c<='9');
 };
 const bodyClass=value=>{
  if(typeof value!=='string')return false;const t=value.split(' ');if(t.length<2||t[0]!=='inline-block'||t[1]!=='relative')return false;
  let i=2;const role=i<t.length&&typographyRoles.has(t[i]);if(role)i++;
  if(role&&i<t.length&&colorChannel(t[i],'text-'))i++;
  if(i<t.length&&colorChannel(t[i],'bg-'))i++;
  if(i<t.length&&t[i]==='coui-surface'){
   if(i+1>=t.length||t[i+1]!=='coui-surface-content')return false;i+=2;
  }return i===t.length;
 };
 const b=raw.bodyDeclaration,styleKeys=['padding','border-radius','color','max-width','background-color',
 'font-size','font-weight','line-height','--coui-leading','letter-spacing','font-family','--coui-surface-rgb','--coui-surface-alpha'];
 if(!exact(b,['class','styles'])||typeof b.class!=='string'||
 !bodyClass(b.class)||
 !b.styles||typeof b.styles!=='object'||Array.isArray(b.styles)||
 Object.keys(b.styles).some(k=>!styleKeys.includes(k)||typeof b.styles[k]!=='string')||
 ['padding','border-radius','color','max-width'].some(k=>!Object.hasOwn(b.styles,k)))return fail('ORIGINAL_BODY_DECLARATION_CHANNELS_REQUIRED');
 const fs=raw.opaqueFrontiers;
 const shapeValid=s=>exact(s,s?.nodeType===1?['nodeType','namespaceURI','localName']:['nodeType'])&&
 (s.nodeType===3||s.nodeType===1&&typeof s.localName==='string'&&
 s.namespaceURI===(s.localName==='svg'?'http://www.w3.org/2000/svg':'http://www.w3.org/1999/xhtml'));
 if(!Array.isArray(fs)||fs.length!==1||!exact(fs[0],['index','purpose','nodes'])||fs[0].index!==0||
 fs[0].purpose!=='bubble-child'||!Array.isArray(fs[0].nodes)||!fs[0].nodes.every(shapeValid))return fail('EXACT_OPAQUE_CHILD_FRONTIER_REQUIRED');
 const formatter=n=>exact(n,['ownedText'])&&typeof n.ownedText==='string'&&
 Array.from(n.ownedText).every(c=>[9,10,12,13,32].includes(c.charCodeAt(0)));
 const semantic=n=>Array.isArray(n?.children)?n.children.filter(c=>!c||typeof c!=='object'||!Object.hasOwn(c,'ownedText')):[];
 const one=n=>{const c=semantic(n);return c.length===1?c[0]:null;};
 const cap=raw.capture,row=one(cap),column=one(row),body=one(column);
 const direct=(n,children)=>{
  if(!Array.isArray(n?.children))return false;let at=0;
  const formatting=()=>{while(at<n.children.length&&n.children[at]&&Object.hasOwn(n.children[at],'ownedText')){
   if(!formatter(n.children[at++]))return false;}return true;};
  for(const child of children){
   if(child==='opaque'){
    for(let j=0;j<fs[0].nodes.length;j++){
     if(fs[0].nodes[j].nodeType!==3&&!formatting())return false;
     const c=n.children[at++];if(!exact(c,['opaqueNode','frontierNode'])||c.opaqueNode!==0||c.frontierNode!==j)return false;
    }
   }else if(!formatting()||n.children[at++]!==child)return false;
  }return formatting()&&at===n.children.length;
 };
 const fixed=(n,a,children)=>exact(n,['nodeType','namespaceURI','localName','attributes','children'])&&
 n.nodeType===1&&n.namespaceURI==='http://www.w3.org/1999/xhtml'&&n.localName==='div'&&
 n.attributes&&typeof n.attributes==='object'&&!Array.isArray(n.attributes)&&a&&
 Object.keys(n.attributes).length===Object.keys(a).length&&Object.keys(a).every(k=>
 typeof a[k]==='string'&&Object.hasOwn(n.attributes,k)&&n.attributes[k]===a[k])&&direct(n,children);
 if(cap?.attributes?.['data-parity-key']!==receipt.entryKey||
 !fixed(cap,cap.attributes,[row])||!fixed(row,{class:'flex w-full justify-start'},[column])||
 !fixed(column,{class:'flex flex-col w-full items-start min-w-0'},[body])||
 !fixed(body,{class:b.class,style:Object.entries(b.styles).map(([k,v])=>k+': '+v).join('; ')},['opaque']))
 return fail('EXACT_NORMAL_FACTORY_GRAMMAR_CHANGED');
 const selector=request.selector,layoutSelector=request.layoutSelector;
 if(typeof selector!=='string'||!selector||typeof layoutSelector!=='string'||!layoutSelector)return fail('ORIGINAL_SELECTORS_REQUIRED');
 let fields,roots;try{fields=Array.from(document.querySelectorAll(selector));roots=Array.from(document.querySelectorAll(layoutSelector));}
 catch(_){return fail('INVALID_SELECTOR');}
 if(fields.length!==1||roots.length!==1||fields[0]!==roots[0])return fail('UNIQUE_REGISTRY_ROW_REQUIRED');
 const registry=roots[0],capture=registry.parentElement;
 const same=(a,b)=>a.length===b.length&&a.every((v,i)=>v===b[i]);
 const attrs=n=>JSON.stringify(Array.from(n.attributes).map(a=>[a.name,a.value]));
 const attrsMatch=(n,a)=>Array.from(n.attributes).length===Object.keys(a).length&&
 Array.from(n.attributes).every(x=>a[x.name]===x.value);
 const shape=(n,s)=>n?.nodeType===s.nodeType&&(s.nodeType!==1||n.namespaceURI===s.namespaceURI&&n.localName===s.localName);
 const owned=[],foreign=[],texts=[],matched=new Map();let nextForeign=0;
 const match=(n,g)=>{
  if(!n||!n.isConnected||!shape(n,g)||!attrsMatch(n,g.attributes))return false;
  const c=Array.from(n.childNodes);if(c.length!==g.children.length)return false;
  owned.push({n,parent:n.parentNode,children:c,attrs:attrs(n)});matched.set(g,n);
  for(let i=0;i<c.length;i++){
   const x=g.children[i],child=c[i];
   if(Object.hasOwn(x,'ownedText')){
    if(!formatter(x)||child.nodeType!==3||child.data!==x.ownedText)return false;
    texts.push({n:child,parent:n,data:child.data});
   }else if(Object.hasOwn(x,'opaqueNode')){
    if(x.opaqueNode!==0||x.frontierNode!==nextForeign||!shape(child,fs[0].nodes[nextForeign++]))return false;
    foreign.push({n:child,parent:n,shape:fs[0].nodes[x.frontierNode]});
   }else if(!match(child,x))return false;
  }return true;
 };
 if(!match(capture,cap)||matched.get(row)!==registry||nextForeign!==fs[0].nodes.length)return fail('CURRENT_EXACT_OWNED_DOM_REQUIRED');
 const owner=matched.get(body),records=v=>v&&typeof v==='object'?[v,...Object.values(v).flatMap(records)]:[];
 const heldSource=records(source),heldReceipt=records(receipt),sourceJSON=JSON.stringify(source),receiptJSON=JSON.stringify(receipt),url=location.href;
 const validateCurrentBinding=()=>{try{
  const f=Array.from(document.querySelectorAll(selector)),r=Array.from(document.querySelectorAll(layoutSelector));
  return f.length===1&&r.length===1&&f[0]===registry&&r[0]===registry&&request.requested===true&&
  request.source===source&&request.currentSsrSource===receipt&&request.requiredCurrentSsrKind===kind&&
  request.selector===selector&&request.layoutSelector===layoutSelector&&location.href===url&&
  JSON.stringify(source)===sourceJSON&&JSON.stringify(receipt)===receiptJSON&&
  same(records(source),heldSource)&&same(records(receipt),heldReceipt)&&
  owned.every(x=>x.n.isConnected&&x.n.parentNode===x.parent&&same(Array.from(x.n.childNodes),x.children)&&attrs(x.n)===x.attrs)&&
  foreign.every(x=>x.n.isConnected&&x.n.parentNode===x.parent&&shape(x.n,x.shape))&&
  texts.every(x=>x.n.parentNode===x.parent&&x.n.data===x.data);
 }catch(_){return false;}};
 if(!validateCurrentBinding())return fail('INITIAL_HELD_BINDING_CHANGED');
 return {applied:true,registryResultElement:registry,fieldUnitElement:owner,paddingSource:owner,frameSource:owner,
 registryIsLayoutRoot:true,validateCurrentBinding,
 authority:'exact original Example -> public Chat/scope/raw selected padding chain -> normal no-tail body; child opaque'};
}
''';
