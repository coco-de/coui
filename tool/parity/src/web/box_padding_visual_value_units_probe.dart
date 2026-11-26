import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Source refs only. The common coordinator samples the actual bound root's
/// CSS after this succeeds, including when Native declares no own padding.
String get visualValueBoxSourceResolverScript =>
    '''
(layoutRoot,source,currentRaw) => {
  const fail=error=>({error});
  const tuples=${jsonEncode([
      BoxObservationSourceSpec.iconVisualFrame,
      BoxObservationSourceSpec.numberTickerTextLayoutHost,
      BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
      BoxObservationSourceSpec.countdownValueLayoutHost,
    ].map((s) => s.toJson()).toList())};
  const spec=source && tuples.find(s=>s.logicalUnitId===source.logicalUnitId);
  if(!spec || Object.keys(source).length!==Object.keys(spec).length ||
      Object.keys(spec).some(k=>source[k]!==spec[k]))return fail('VISUAL_VALUE_TUPLE_CHANGED');
  const ticker=source.logicalUnitId==='number-ticker-generated-text-layout-host';
  const keys=['kind','logicalUnitId','rawSlotCount','slotPresence','generatedTree',
    ...(ticker?['plainMode']:[])];
  const raw=currentRaw;
  if(!raw || typeof raw!=='object' || Array.isArray(raw) ||
      Object.keys(raw).length!==keys.length || keys.some(k=>!Object.hasOwn(raw,k)) ||
      raw.kind!=='current-visual-value-raw-v1' || raw.logicalUnitId!==source.logicalUnitId ||
      raw.rawSlotCount!==(ticker?1:0) || !Array.isArray(raw.slotPresence) ||
      raw.slotPresence.length!==raw.rawSlotCount || raw.slotPresence.some(v=>v!==false) ||
      (ticker && raw.plainMode!==true))return fail('VISUAL_VALUE_CURRENT_RAW_REQUIRED');
  const children=n=>{
    if(!n || n.isConnected===false || !n.children)return null;
    const all=Array.from(n.children);
    return new Set(all).size===all.length && all.every(c=>c.parentElement===n &&
      c.isConnected!==false)?all:null;
  };
  const html='http://www.w3.org/1999/xhtml',svg='http://www.w3.org/2000/svg';
  const exactTag=(n,ns,tag)=>n && n.namespaceURI===ns && n.localName===tag &&
    n.tagName===(ns===html?tag.toUpperCase():tag);
  const capture=layoutRoot && layoutRoot.parentElement,top=children(capture);
  if(!capture || !capture.hasAttribute('data-parity-key') || !top ||
      top.length!==1 || top[0]!==layoutRoot)return fail('VISUAL_VALUE_CAPTURE_CHANGED');
  const captureNodes=capture.childNodes && Array.from(capture.childNodes);
  if(!captureNodes || captureNodes.filter(n=>n===layoutRoot).length!==1 ||
      captureNodes.some(n=>n!==layoutRoot && !(n.nodeType===3 &&
        n.parentNode===capture && typeof n.data==='string' && /^[\\t\\n\\f\\r ]*\$/.test(n.data))))
    return fail('VISUAL_VALUE_CAPTURE_OUTPUT_CHANGED');
  const seen=new Set();
  const match=(node,tree)=>{
    if(!tree || typeof tree!=='object' || Array.isArray(tree) ||
        Object.keys(tree).length!==3 ||
        ['namespaceURI','localName','children'].some(k=>!Object.hasOwn(tree,k)) ||
        ![html,svg].includes(tree.namespaceURI) || typeof tree.localName!=='string' ||
        !Array.isArray(tree.children) || seen.has(node) ||
        !exactTag(node,tree.namespaceURI,tree.localName))return false;
    seen.add(node);
    const all=children(node);
    return all && all.length===tree.children.length &&
      all.every((child,i)=>match(child,tree.children[i]));
  };
  if(!match(layoutRoot,raw.generatedTree))return fail('VISUAL_VALUE_ACTUAL_GENERATED_TREE_CHANGED');
  const all=children(layoutRoot);
  switch(source.logicalUnitId){
    case 'icon-generated-visual-frame-content-inset':
      // Icon's bundled root is native lowercase SVG. Its alternative is the
      // exact HTML Iconify host with its source-owned empty companion.
      if(exactTag(layoutRoot,svg,'svg'))break;
      if(!exactTag(layoutRoot,html,'iconify-icon') || all.length!==1 ||
          !exactTag(all[0],html,'coui-iconify-stroke') || children(all[0]).length!==0)
        return fail('VISUAL_VALUE_ICON_FRAME_CHANGED');
      break;
    case 'number-ticker-generated-text-layout-host':
    case 'countdown-generated-value-layout-host':
      if(!exactTag(layoutRoot,html,'span') || all.length!==1 ||
          !exactTag(all[0],html,'span'))return fail('VISUAL_VALUE_TEXT_FRAME_CHANGED');
      break;
    case 'skeleton-text-generated-lines-layout-host': {
      if(!exactTag(layoutRoot,html,'div'))return fail('VISUAL_VALUE_SKELETON_FRAME_CHANGED');
      // Count/order is the original mounted generated-tree witness, never a
      // Core line-count default or a first line used as the field.
      let announced=false;
      for(let i=0;i<all.length;i++){
        const line=all[i],seats=children(line);
        if(exactTag(line,html,'div') && !announced && seats.length===0)continue;
        if(!exactTag(line,html,'span') || i!==all.length-1 || announced ||
            seats.length!==1 || !exactTag(seats[0],html,'span'))
          return fail('VISUAL_VALUE_SKELETON_LINE_ORDER_CHANGED');
        announced=true;
      }
      break;
    }
    default:return fail('VISUAL_VALUE_UNSUPPORTED_SOURCE');
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot,frameSource:layoutRoot,registryIsLayoutRoot:true,
    foreignSeats:[],outsideTriggerSlots:[],currentOperationWitness:{
      kind:'actual-generated-visual-value-host',generatedChildren:all.length},
    authority:'Exact current public SSR producer and complete actual generated DOM; no key/style/CSS/Core/geometry owner selection'};
}
''';
