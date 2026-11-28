import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Exact ordinary SizeSpec graph; generated preview/table interiors stay
/// opaque. Request, receipt objects and every owned DOM occurrence are held
/// through the unchanged legacy and own-padding CSS readers.
String get docsSizeRequestBindingScript =>
    '''
(request) => {
  if(request.requested===false)return {applied:false};
  const expected=${jsonEncode(BoxObservationSourceSpec.docsSizePreview.toJson())};
  const source=request.source,kind='canonical-ssr-docs-size-preview-v1';
  const claims=request.requiredCurrentSsrKind===kind||source&&
    ['logicalUnitId','nativeAdapterId','webAdapterId'].some(k=>source[k]===expected[k]);
  if(!claims)return {applied:false};
  const fail=error=>({applied:true,error});
  const exact=(v,keys)=>v&&typeof v==='object'&&!Array.isArray(v)&&
    Object.keys(v).length===keys.length&&keys.every(k=>Object.hasOwn(v,k));
  const tuple=v=>exact(v,Object.keys(expected))&&Object.keys(expected).every(k=>v[k]===expected[k]);
  const receipt=request.currentSsrSource;
  if(request.requested!==true||!tuple(source)||request.requiredCurrentSsrKind!==kind||
    !exact(receipt,['kind','entryKey','source','currentRaw','harnessURL'])||receipt.kind!==kind||
    !tuple(receipt.source)||typeof receipt.entryKey!=='string'||!receipt.entryKey||
    typeof location==='undefined'||receipt.harnessURL!==location.href)
    return fail('DOCS_SIZE_ACTUAL_NORMAL_SSR_REQUIRED');
  const raw=receipt.currentRaw;
  if(!exact(raw,['kind','sceneReference','component','dataAliasesArePaddingParameters',
    'buildOrResolverReexecuted','previewInteriorsAreSourceAuthority','tableIsOutsideQuantity','headProjection','rowCount','normalTree'])||
    raw.kind!=='current-docs-size-preview-frame-v1'||typeof raw.component!=='string'||!raw.component||
    !/^docs-v2-[0-9a-f]{32}\$/.test(raw.sceneReference)||
    !receipt.entryKey.startsWith(raw.component+'-'+raw.sceneReference+'-')||
    raw.dataAliasesArePaddingParameters!==false||raw.buildOrResolverReexecuted!==false||
    raw.previewInteriorsAreSourceAuthority!==false||raw.tableIsOutsideQuantity!==true||
    !exact(raw.headProjection,['kind','headOutsideBody','orderedChildren'])||
    raw.headProjection.kind!=='normal-content-head-then-section-v1'||raw.headProjection.headOutsideBody!==true||
    JSON.stringify(raw.headProjection.orderedChildren)!==JSON.stringify(['document-head','content-section'])||
    !Number.isSafeInteger(raw.rowCount)||raw.rowCount<0)
    return fail('DOCS_SIZE_COMPLETE_NORMAL_GRAPH_REQUIRED');
  // The canonical capture caller's complete attrs remain held data. Its
  // configurable display/width never establishes this preview's inset owner.
  const literalAttrs={
    host:{id:'docs-shell',class:'docs manual',style:'width: 100%; min-width: 0',
      'data-docs-scene':raw.sceneReference},
    content:{class:'content'},result:{class:'docs-size-spec'},
    preview:{class:'docs-stage docs-stage--hug docs-stage--row'},
    figure:{class:'docs-size-item'},caption:{},code:{},
  };
  const ownAttrs=(a,role)=>role==='capture'||Object.hasOwn(literalAttrs,role)&&
    exact(a,Object.keys(literalAttrs[role]))&&
    Object.entries(literalAttrs[role]).every(([k,v])=>a[k]===v);
  const owned=(n,role,tag)=>n&&n.kind==='owned'&&n.role===role&&n.nodeType===1&&
    n.namespaceURI==='http://www.w3.org/1999/xhtml'&&n.localName===tag&&
    exact(n,['kind','role','nodeType','namespaceURI','localName','attributes','children'])&&
    n.attributes&&typeof n.attributes==='object'&&!Array.isArray(n.attributes)&&
    Object.values(n.attributes).every(v=>typeof v==='string')&&ownAttrs(n.attributes,role)&&Array.isArray(n.children);
  const formatter=n=>exact(n,['kind','nodeType','text'])&&n.kind==='formatter-text'&&n.nodeType===3&&
    typeof n.text==='string'&&Array.from(n.text).every(c=>[9,10,12,13,32].includes(c.charCodeAt(0)));
  const meaningful=n=>n.children.filter(c=>!formatter(c));
  const oneChild=(n,role,tag)=>{const c=meaningful(n);return c.length===1&&owned(c[0],role,tag)?c[0]:null;};
  const tree=raw.normalTree;
  if(!owned(tree,'capture','div'))return fail('DOCS_SIZE_CAPTURE_GRAPH_REQUIRED');
  const host=oneChild(tree,'host','div'),content=host&&oneChild(host,'content','section');
  const resultGraph=content&&oneChild(content,'result','div');
  const branches=resultGraph&&meaningful(resultGraph);
  const previewGraph=branches&&branches[0],tableGraph=branches&&branches[1];
  const opaque=(n,role)=>exact(n,['kind','role','nodes'])&&n.kind==='generated-opaque'&&n.role===role&&Array.isArray(n.nodes)&&n.nodes.length===1&&
    n.nodes.every(s=>s.nodeType===1&&exact(s,['nodeType','namespaceURI','localName'])&&
      s.namespaceURI==='http://www.w3.org/1999/xhtml'&&typeof s.localName==='string');
  if(!host||!content||!resultGraph||branches.length!==2||!owned(previewGraph,'preview','div')||
    !opaque(tableGraph,'table')||tableGraph.nodes.length!==1||tableGraph.nodes[0].localName!=='div'||
    tree.attributes['data-parity-key']!==receipt.entryKey||host.attributes.id!=='docs-shell'||
    host.attributes['data-docs-scene']!==raw.sceneReference||content.attributes.class!=='content'||
    resultGraph.attributes.class!=='docs-size-spec'||
    previewGraph.attributes.class!=='docs-stage docs-stage--hug docs-stage--row')
    return fail('DOCS_SIZE_ORIGINAL_ROUTE_REQUIRED');
  const figures=meaningful(previewGraph);
  if(figures.length!==raw.rowCount||figures.some(f=>{
    if(!owned(f,'figure','figure')||f.attributes.class!=='docs-size-item')return true;
    const parts=meaningful(f),caption=parts.at(-1);
    if(parts.length!==2||!opaque(parts[0],'preview-interior')||
      !owned(caption,'caption','figcaption'))return true;
    const code=oneChild(caption,'code','code'),texts=code&&meaningful(code);
    return !code||texts.length!==1||!exact(texts[0],['kind','nodeType','text'])||
      texts[0].kind!=='owned-text'||texts[0].nodeType!==3||typeof texts[0].text!=='string';
  }))return fail('DOCS_SIZE_GENERATED_FIGURE_GRAPH_REQUIRED');
  const objects=v=>{const a=[];const visit=x=>{if(x&&typeof x==='object'){a.push(x);for(const c of Object.values(x))visit(c);}};visit(v);return a;};
  const heldObjects=[...objects(source),...objects(receipt)];
  const frozenSource=JSON.stringify(source),frozenReceipt=JSON.stringify(receipt);
  const selector=request.selector,layoutSelector=request.layoutSelector;
  if(typeof selector!=='string'||!selector||typeof layoutSelector!=='string'||!layoutSelector)
    return fail('DOCS_SIZE_ORIGINAL_SELECTORS_REQUIRED');
  const one=s=>{try{const a=Array.from(document.querySelectorAll(s));return a.length===1?a[0]:null;}catch(_){return null;}};
  const result=one(selector),layout=one(layoutSelector),capture=result?.parentElement?.parentElement?.parentElement;
  const preview=result?.children[0],table=result?.children[1];
  const attrs=n=>Object.fromEntries(Array.from(n.attributes).map(a=>[a.name,a.value]));
  const same=(a,b)=>JSON.stringify(Object.entries(a).sort())===JSON.stringify(Object.entries(b).sort());
  const heldNodes=[];let initial=true;
  const node=(n,g,refs)=>{
    if(!n||!n.isConnected||n.nodeType!==g.nodeType)return false;
    refs.push(n);
    if(g.kind==='formatter-text'||g.kind==='owned-text')return n.nodeType===3&&n.textContent===g.text;
    if(g.kind!=='owned'||n.namespaceURI!==g.namespaceURI||n.localName!==g.localName||!same(attrs(n),g.attributes))return false;
    const children=Array.from(n.childNodes);let i=0;
    for(const child of g.children){
      if(child.kind==='generated-opaque'){
        for(const s of child.nodes){const c=children[i++];
          if(!c||!c.isConnected||c.parentNode!==n||c.nodeType!==s.nodeType||
            s.nodeType===1&&(c.namespaceURI!==s.namespaceURI||c.localName!==s.localName))return false;
          refs.push(c);
        }
      }else{const c=children[i++];if(!c||c.parentNode!==n||!node(c,child,refs))return false;}
    }
    return i===children.length;
  };
  const validateCurrentBinding=()=>{
    try{
      const currentObjects=[...objects(request.source),...objects(request.currentSsrSource)];
      if(request.requested!==true||request.requiredCurrentSsrKind!==kind||request.source!==source||request.currentSsrSource!==receipt||
        request.selector!==selector||request.layoutSelector!==layoutSelector||JSON.stringify(source)!==frozenSource||
        JSON.stringify(receipt)!==frozenReceipt||currentObjects.length!==heldObjects.length||
        currentObjects.some((v,i)=>v!==heldObjects[i])||receipt.harnessURL!==location.href||
        !result||result!==layout||one(selector)!==result||one(layoutSelector)!==layout||
        result.parentElement?.parentElement?.parentElement!==capture||
        result.children.length!==2||result.children[0]!==preview||result.children[1]!==table||
        capture?.getAttribute('data-parity-key')!==receipt.entryKey)return false;
      const refs=[];if(!node(capture,tree,refs))return false;
      if(initial){heldNodes.push(...refs);initial=false;return true;}
      return refs.length===heldNodes.length&&refs.every((n,i)=>n===heldNodes[i]);
    }catch(_){return false;}
  };
  if(!validateCurrentBinding())return fail('DOCS_SIZE_CURRENT_BINDING_CHANGED');
  return {applied:true,registryResultElement:result,fieldUnitElement:preview,paddingSource:preview,frameSource:preview,
    registryIsLayoutRoot:true,authority:'Original normal SizeSpec constant preview frame; table excluded, generated preview interiors opaque, exact ordinary serialized graph and held current refs; data aliases are not inset parameters',validateCurrentBinding};
}
''';
