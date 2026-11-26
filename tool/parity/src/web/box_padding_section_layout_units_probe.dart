import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Closed registry recipe prevalidation supplies constructor authority. This
/// function checks current source edges and returns refs without reading CSS.
String get sectionLayoutBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  const tuples=${jsonEncode(BoxObservationSourceSpec.sectionLayoutFrames.map((s) => s.toJson()).toList())};
  const expected=source && tuples.find(s=>s.logicalUnitId===source.logicalUnitId);
  if(!expected || Object.keys(expected).some(k=>source[k]!==expected[k]))
    return fail('SECTION_SOURCE_TUPLE_CHANGED');
  const div=n=>n && n.tagName==='DIV';
  const has=(n,...names)=>n && names.every(name=>n.classList.contains(name));
  const children=n=>{
    const all=Array.from(n.children);
    return new Set(all).size===all.length && all.every(c=>c.parentElement===n)?all:null;
  };
  const capture=layoutRoot && layoutRoot.parentElement;
  const top=capture && children(capture);
  if(!capture || !capture.hasAttribute('data-parity-key') || !top ||
      top.length!==1 || top[0]!==layoutRoot) return fail('SECTION_CAPTURE_CHANGED');
  let field=layoutRoot,currentExpanded=null;
  const outer=children(layoutRoot);
  if(!outer)return fail('SECTION_CHILD_IDENTITY_CHANGED');
  switch(source.logicalUnitId){
    case 'disclosure-generated-header-content-inset': {
      // The canonical > * selector is the registry's docs width wrapper.
      // The direct details/summary below it owns the actual header padding.
      if(!div(layoutRoot) || !has(layoutRoot,'w-full') || outer.length!==1 ||
          outer[0].tagName!=='DETAILS' || !has(outer[0],'coui-disclosure','group'))
        return fail('DISCLOSURE_REGISTRY_ROUTE_CHANGED');
      const details=outer[0],seats=children(details);
      if(!seats || seats.length!==3 || seats[0].tagName!=='SUMMARY' ||
          !div(seats[1]) || seats[2].tagName!=='STYLE')
        return fail('DISCLOSURE_CURRENT_SEATS_CHANGED');
      currentExpanded=details.hasAttribute('open');
      field=seats[0];
      const header=children(field);
      if(!has(field,'flex','items-center','w-full') || !header ||
          header.length!==3 || header.some(n=>!div(n)))
        return fail('DISCLOSURE_HEADER_CHANGED');
      // Body exists in the DOM even while closed; details.open is the actual
      // browser operation, never inferred from a seed, CSS or body geometry.
      break;
    }
    case 'disclosure-group-generated-layout-host': {
      if(!div(field) || !has(field,'flex','flex-col','w-full') || outer.length!==3)
        return fail('DISCLOSURE_GROUP_LAYOUT_CHANGED');
      // Entire supplied sections stay opaque, including their own summaries.
      break;
    }
    case 'collapsible-generated-section-layout-host': {
      if(!div(field) || !has(field,'inline-flex','flex-col') || outer.length!==2 ||
          !div(outer[0]) || outer[0].getAttribute('role')!=='button' ||
          !['true','false'].includes(outer[0].getAttribute('aria-expanded')) ||
          !div(outer[1]))return fail('COLLAPSIBLE_LAYOUT_CHANGED');
      const trigger=children(outer[0]),body=children(outer[1]);
      if(!trigger || trigger.length!==1 || !div(trigger[0]) ||
          !has(trigger[0],'flex','items-center','w-full') ||
          !body || body.length!==1 || !div(body[0]))
        return fail('COLLAPSIBLE_SEATS_CHANGED');
      break;
    }
    case 'resizable-generated-pane-layout-host': {
      if(!div(layoutRoot) || !has(layoutRoot,'coui-resizable-preview') ||
          outer.length!==1 || !div(outer[0]))
        return fail('RESIZABLE_REGISTRY_ROUTE_CHANGED');
      field=outer[0];
      const seats=children(field);
      if(!has(field,'flex','flex-row','w-full','h-full') || !seats ||
          seats.length!==3 || seats.some(n=>!div(n)) ||
          seats[2].getAttribute('role')!=='separator')
        return fail('RESIZABLE_PANE_OVERLAY_CHANGED');
      // First two complete pane wrappers precede one generated divider overlay.
      // Their supplied content and the overlay never donate this root's inset.
      break;
    }
    case 'breadcrumb-generated-trail-layout-host': {
      if(!div(field) || field.getAttribute('role')!=='navigation')
        return fail('BREADCRUMB_LAYOUT_CHANGED');
      let seats=outer;
      if(seats[0]?.tagName==='STYLE')seats=seats.slice(1);
      if(seats.length!==9 || seats.some(n=>n.tagName==='STYLE') ||
          seats[8].getAttribute('aria-current')!=='page')
        return fail('BREADCRUMB_TRAIL_SEATS_CHANGED');
      break;
    }
    default:return fail('UNSUPPORTED_SECTION_LAYOUT_SOURCE');
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:field,registryIsLayoutRoot:true,currentExpanded,
    authority:'Exact prevalidated section recipe and current canonical registry/source child edges; own header summary or section layout root only; whole supplied sections/panes/trigger/content, generated item padding, overlays and gaps excluded; no CSS or numeric owner selection'};
}
''';
