import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// The shared caller must prevalidate the concrete canonical construction.
/// This leaf returns source references only; the coordinator reads actual CSS
/// for every style and override, including a field absent on Native.
String get dataOverlayLayoutBoxSourceResolverScript =>
    '''
(layoutRoot,source,currentRaw) => {
  const fail=error=>({error});
  const tuples=${jsonEncode([
      BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
      BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
      BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
      BoxObservationSourceSpec.swiperTriggerLayoutHost,
      BoxObservationSourceSpec.diffViewerLayoutHost,
    ].map((s) => s.toJson()).toList())};
  const spec=source && tuples.find(s=>s.logicalUnitId===source.logicalUnitId);
  if(!spec || Object.keys(source).length!==Object.keys(spec).length ||
      Object.keys(spec).some(k=>source[k]!==spec[k]))return fail('DATA_OVERLAY_TUPLE_CHANGED');
  const raw=currentRaw;
  const baseKeys=['kind','logicalUnitId','rawSlotCount','slotPresence'];
  const extraKeys={
    'theme-controller-generated-option-grid-layout-host':['optionCount'],
    'tracker-generated-segment-row-layout-host':['segmentCount'],
    'bottom-sheet-generated-outer-layout-host':['showHandle','showCloseButton','showDivider'],
    'swiper-generated-trigger-layout-host':['position','variant'],
    'diff-generated-viewer-layout-host':['interactive']
  }[source.logicalUnitId];
  if(!raw || typeof raw!=='object' || Array.isArray(raw) ||
      raw.kind!=='current-data-overlay-raw-v1' || raw.logicalUnitId!==source.logicalUnitId ||
      !extraKeys || Object.keys(raw).length!==baseKeys.length+extraKeys.length ||
      [...baseKeys,...extraKeys].some(k=>!Object.hasOwn(raw,k)) ||
      !Number.isInteger(raw.rawSlotCount) || !Array.isArray(raw.slotPresence) ||
      raw.slotPresence.length!==raw.rawSlotCount || Array.from(raw.slotPresence).some(v=>typeof v!=='boolean'))
    return fail('DATA_OVERLAY_CURRENT_RAW_REQUIRED');
  const present=raw.slotPresence,rawPresent=present.filter(Boolean).length;
  const children=n=>{
    if(!n || n.isConnected===false || !n.children)return null;
    const all=Array.from(n.children);
    return new Set(all).size===all.length && all.every(c=>c.parentElement===n &&
      c.isConnected!==false)?all:null;
  };
  const has=(n,...names)=>n && names.every(s=>n.classList.contains(s));
  const div=n=>n && n.tagName==='DIV';
  const capture=layoutRoot && layoutRoot.parentElement,top=children(capture);
  if(!capture || !capture.hasAttribute('data-parity-key') || !top ||
      top.length!==1 || top[0]!==layoutRoot)return fail('DATA_OVERLAY_CAPTURE_CHANGED');
  const all=children(layoutRoot);
  if(!all)return fail('DATA_OVERLAY_CHILD_IDENTITY_CHANGED');
  let field=layoutRoot,frame=layoutRoot,currentOperationWitness=null;
  const foreignSeats=[],outsideTriggerSlots=[];
  switch(source.logicalUnitId){
    case 'theme-controller-generated-option-grid-layout-host': {
      if(!div(field) || !has(field,'flex','flex-row','flex-wrap'))
        return fail('THEME_OPTION_GRID_SOURCE_CHANGED');
      let index=0;
      if(all[0]?.tagName==='STYLE'){
        if(children(all[0])?.length!==0)return fail('THEME_OPTION_STYLE_CHANGED');
        index++;
      }
      const swatches=all.slice(index);
      // Four options are the exact immutable DefaultExample constructor,
      // not a value/preset/key gate. Shared recipe prevalidation is required.
      if(raw.rawSlotCount!==0 || raw.optionCount!==4 ||
          swatches.length!==raw.optionCount || swatches.some(n=>!div(n)))
        return fail('THEME_ALL_OPTIONS_CHANGED');
      const states=[];
      for(const swatch of swatches){
        const seats=children(swatch);
        if(!seats || seats.length!==3 || seats.some(n=>!div(n)) ||
            seats[0].getAttribute('role')!=='button' ||
            !['true','false'].includes(seats[0].getAttribute('aria-pressed')))
          return fail('THEME_CURRENT_OPTION_SEATS_CHANGED');
        states.push({label:seats[0].getAttribute('aria-label'),
          pressed:seats[0].getAttribute('aria-pressed'),disabled:seats[0].getAttribute('aria-disabled')});
      }
      currentOperationWitness={kind:'source-option-grid',states};
      break;
    }
    case 'tracker-generated-segment-row-layout-host': {
      if(!div(field) || !has(field,'flex') || !field.hasAttribute('aria-label') ||
          raw.rawSlotCount!==0 || raw.segmentCount!==14 ||
          all.length!==raw.segmentCount || all.some(n=>!div(n)))
        return fail('TRACKER_COMPLETE_SEGMENT_ROW_CHANGED');
      // Fourteen data segments are the exact current DefaultExample literal.
      // No first segment/Tooltip paint is promoted to the row's field.
      currentOperationWitness={kind:'complete-source-segment-row',segments:all.length};
      break;
    }
    case 'bottom-sheet-generated-outer-layout-host': {
      if(!div(field) || !has(field,'flex','flex-col','w-full','box-border'))
        return fail('BOTTOM_SHEET_OUTER_SOURCE_CHANGED');
      let index=0;
      if(all[index] && div(all[index]) && has(all[index],'flex','justify-center')){
        const handle=children(all[index]);
        if(!handle || handle.length!==1 || !div(handle[0]) || children(handle[0])?.length!==0)
          return fail('BOTTOM_SHEET_HANDLE_CHANGED');
        index++;
      }
      const header=all[index++],heading=children(header);
      if(!div(header) || !has(header,'flex','flex-col') || !heading ||
          ![1,3].includes(heading.length))return fail('BOTTOM_SHEET_HEADER_CHANGED');
      const titleRow=children(heading[0]);
      if(!div(heading[0]) || !has(heading[0],'flex','flex-row','items-center') ||
          !titleRow || ![1,2].includes(titleRow.length) || !div(titleRow[0]) ||
          (titleRow.length===2 && titleRow[1].tagName!=='BUTTON'))
        return fail('BOTTOM_SHEET_TITLE_CLOSE_CHANGED');
      if(heading.length===3 && (!div(heading[1]) || !div(heading[2])))
        return fail('BOTTOM_SHEET_DESCRIPTION_CHANGED');
      // Source-generated wrappers retain complete individual title and
      // description subtrees; their internals remain opaque/foreign.
      foreignSeats.push(titleRow[0]);
      if(heading.length===3)foreignSeats.push(heading[2]);
      let divider=false;
      // BottomSheet constructs decorative Divider(child:null, semantic:false).
      // Divider's authored single-line branch is an empty DIV, not HR.
      if(div(all[index]) && children(all[index])?.length===0){divider=true;index++;}
      if(index<all.length){
        const body=all[index++],seats=children(body);
        if(!div(body) || !has(body,'flex','flex-col','min-h-0') || !seats ||
            ![1,2].includes(seats.length) || seats.some(n=>!div(n)))
          return fail('BOTTOM_SHEET_CONTENT_FOOTER_CHANGED');
        // Each complete content/footer source wrapper is a boundary, not
        // an arbitrary descendant label or its own padding primitive.
        foreignSeats.push(...seats);
      }
      if(index!==all.length)return fail('BOTTOM_SHEET_EXTRA_SOURCE_SEAT');
      if(raw.rawSlotCount!==4 || present[0]!==true ||
          ['showHandle','showCloseButton','showDivider'].some(k=>typeof raw[k]!=='boolean') ||
          raw.showHandle!==(header!==all[0]) || raw.showCloseButton!==(titleRow.length===2) ||
          raw.showDivider!==divider || present[1]!==(heading.length===3) ||
          foreignSeats.length!==rawPresent)
        return fail('BOTTOM_SHEET_CURRENT_RAW_BRANCH_CHANGED');
      // A single rendered body seat can be either content or footer. The
      // original raw bitmap supplies that distinction, never DOM omission.
      const bodyPresent=Number(present[2])+Number(present[3]);
      const bodySeatCount=foreignSeats.length-1-Number(present[1]);
      if(bodySeatCount!==bodyPresent)return fail('BOTTOM_SHEET_RAW_BODY_CHANGED');
      currentOperationWitness={kind:'source-sheet-branches',handle:header!==all[0],
        description:heading.length===3,close:titleRow.length===2,divider};
      break;
    }
    case 'swiper-generated-trigger-layout-host': {
      // preview_layout.dart and web_registry.dart add the source-owned
      // w-full registry wrapper for both exact current Swiper recipes.
      if(!div(layoutRoot) || !has(layoutRoot,'w-full') || all.length!==1 || !div(all[0]))
        return fail('SWIPER_REGISTRY_ROUTE_CHANGED');
      field=frame=all[0];
      const seats=children(field);
      if(!has(field,'relative') || !seats || seats.length!==1 ||
          !div(seats[0]) || !has(seats[0],'contents') || children(seats[0])?.length!==1)
        return fail('SWIPER_WHOLE_TRIGGER_CHILD_CHANGED');
      const expanded=field.getAttribute('aria-expanded');
      if(expanded!==null && expanded!=='true')return fail('SWIPER_CURRENT_SEMANTICS_CHANGED');
      if(!['left','right','top','bottom'].includes(field.getAttribute('data-swiper-position')) ||
          !['drawer','sheet'].includes(field.getAttribute('data-swiper-variant')))
        return fail('SWIPER_PUBLIC_OPERATION_CHANGED');
      if(raw.rawSlotCount!==2 || present.some(v=>v!==true) ||
          raw.position!==field.getAttribute('data-swiper-position') ||
          raw.variant!==field.getAttribute('data-swiper-variant'))
        return fail('SWIPER_CURRENT_RAW_CHANGED');
      foreignSeats.push(seats[0]);
      outsideTriggerSlots.push({slot:'overlayContent',reason:'source-separate-overlay-host-in-every-state'});
      // Preserve the actual optional attribute, with no fabricated false or
      // initial-open inference. Padding authority is invariant to open state.
      currentOperationWitness={kind:'source-swiper-trigger',expandedAttribute:expanded,
        position:field.getAttribute('data-swiper-position'),variant:field.getAttribute('data-swiper-variant')};
      break;
    }
    case 'diff-generated-viewer-layout-host': {
      const role=field.getAttribute('role'),interactive=role==='slider';
      if(!div(field) || !has(field,'relative','w-full') || !['slider','group'].includes(role) ||
          all.length!==(interactive?2:1) || all.some(n=>!div(n)))return fail('DIFF_VIEWER_SOURCE_CHANGED');
      if(interactive && ['aria-valuemin','aria-valuemax','aria-valuenow'].some(a=>!field.hasAttribute(a)))
        return fail('DIFF_CURRENT_SLIDER_WITNESS_CHANGED');
      const clip=all[0],seats=children(clip);
      if(!has(clip,'absolute','inset-0','overflow-hidden') || !seats || seats.length<3 ||
          seats.some(n=>!div(n)) || children(seats[0])?.length!==1 ||
          children(seats[1])?.length!==1 || children(seats[2])?.length!==0)
        return fail('DIFF_COMPLETE_LAYER_SOURCE_CHANGED');
      foreignSeats.push(seats[0],seats[1]);
      let end=seats.length;
      if(end>3 && children(seats[end-1])?.length===0){
        if(!has(seats[end-1],'pointer-events-none'))return fail('DIFF_PAINTED_EDGE_CHANGED');
        end--;
      }
      if(end-3>2)return fail('DIFF_LABEL_MULTIPLICITY_CHANGED');
      for(const label of seats.slice(3,end)){
        const badge=children(label);
        if(!badge || badge.length!==1 || badge[0].tagName!=='SPAN')return fail('DIFF_PUBLIC_LABEL_CHANGED');
        foreignSeats.push(label);
      }
      if(raw.rawSlotCount!==4 || present[0]!==true || present[1]!==true ||
          typeof raw.interactive!=='boolean' || raw.interactive!==interactive ||
          end-3!==Number(present[2])+Number(present[3]) || foreignSeats.length!==rawPresent)
        return fail('DIFF_CURRENT_RAW_CHANGED');
      currentOperationWitness={kind:'current-before-after-viewer',role,
        value:field.getAttribute('aria-valuenow'),labels:end-3};
      break;
    }
    default:return fail('UNSUPPORTED_DATA_OVERLAY_SOURCE');
  }
  if(new Set(foreignSeats).size!==foreignSeats.length || foreignSeats.some(n=>
      !n || n===field || n.contains?.(field) || n.isConnected===false))
    return fail('DATA_OVERLAY_FOREIGN_FRAME');
  return {registryResultElement:layoutRoot,fieldUnitElement:field,paddingSource:field,
    frameSource:frame,registryIsLayoutRoot:true,foreignSeats,outsideTriggerSlots,currentOperationWitness,
    authority:'Concrete prevalidated current data/overlay source; whole raw slot forwards and source-owned frame; no key value, CSS/Core/geometry selection, private state or callback replay'};
}
''';
