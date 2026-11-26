import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Constructor/recipe prevalidation remains mandatory in the shared caller.
/// Only current source DOM references are returned; CSS and dimensions are not
/// consulted to choose a field. Supplied child subtrees remain opaque.
String get structuredRootBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  const tuples=${jsonEncode(BoxObservationSourceSpec.structuredRootFrames.map((s) => s.toJson()).toList())};
  const expected=source && tuples.find(s=>s.logicalUnitId===source.logicalUnitId);
  if(!expected || Object.keys(expected).some(k=>source[k]!==expected[k]))
    return fail('STRUCTURED_SOURCE_TUPLE_CHANGED');
  const children=n=>{
    if(!n || !n.isConnected)return null;
    const all=Array.from(n.children);
    return new Set(all).size===all.length && all.every(c=>c.parentElement===n && c.isConnected)?all:null;
  };
  const has=(n,...names)=>n && names.every(k=>n.classList.contains(k));
  const div=n=>n && n.tagName==='DIV';
  const capture=layoutRoot && layoutRoot.parentElement,top=children(capture);
  if(!capture || !capture.hasAttribute('data-parity-key') || !top ||
      top.length!==1 || top[0]!==layoutRoot)return fail('STRUCTURED_CAPTURE_CHANGED');
  let field=layoutRoot,frame=layoutRoot;
  const outer=children(layoutRoot);
  if(!outer)return fail('STRUCTURED_CHILD_IDENTITY_CHANGED');
  // Counts below describe the exact audited Example constructors, not generic
  // producer sizes: Basic five direct seats; MultipleChoice three literal
  // options; PageHeader eyebrow/title-actions/description; Timeline three
  // literal items; Category four literal bar rows or donut+legend; Trend
  // default summary/periods/plot/legend versus bar's sole plot. The shared
  // constructor prevalidation is required. Native direct-producer bindings
  // intentionally also accept their fully typed public input lists.
  switch(source.logicalUnitId){
    case 'basic-generated-content-inset':
      if(!div(field) || !has(field,'inline-flex','items-stretch') ||
          outer.length!==5 || outer.some(n=>!div(n)))return fail('BASIC_LAYOUT_CHANGED');
      // Leading, gap, complete supplied body, gap, trailing wrapper.
      break;
    case 'disclosure-badge-solid-content-inset': {
      const marker=outer.length===2;
      if(field.tagName!=='SPAN' || !has(field,'inline-flex','items-center','border-solid') ||
          has(field,'border-dashed') || outer.length!==(marker?2:1) ||
          outer.some(n=>n.tagName!=='SPAN') ||
          (marker && outer[0].getAttribute('aria-hidden')!=='true'))
        return fail('DISCLOSURE_BADGE_SOLID_LAYOUT_CHANGED');
      break;
    }
    case 'multiple-choice-generated-options-layout-host':
      if(!div(field) || field.getAttribute('role')!=='radiogroup' ||
          !has(field,'inline-flex','flex-wrap') || outer.length!==3 ||
          outer.some(n=>n.getAttribute('role')!=='radio' ||
            !['true','false'].includes(n.getAttribute('aria-checked'))))
        return fail('MULTIPLE_CHOICE_LAYOUT_CHANGED');
      break;
    case 'page-header-generated-layout-host':
      if(!div(field) || !has(field,'flex','flex-col','w-full') ||
          outer.length!==3 || outer.some(n=>!div(n)))
        return fail('PAGE_HEADER_LAYOUT_CHANGED');
      break;
    case 'sidebar-generated-outer-layout-host': {
      if(!div(layoutRoot) || outer.length!==1 || outer[0].tagName!=='NAV')
        return fail('SIDEBAR_REGISTRY_ROUTE_CHANGED');
      field=frame=outer[0];
      const seats=children(field);
      if(!has(field,'flex','h-full','items-stretch') || !seats ||
          ![1,2].includes(seats.length) || seats.some(n=>!div(n)))
        return fail('SIDEBAR_CURRENT_LAYOUT_CHANGED');
      break;
    }
    case 'tab-pane-generated-bar-content-inset': {
      if(!div(layoutRoot))return fail('TAB_PANE_ROOT_CHANGED');
      let seats=outer;
      if(seats[0]?.tagName==='STYLE')seats=seats.slice(1);
      if(![1,2].includes(seats.length) || !div(seats[0]) ||
          seats[0].getAttribute('role')!=='tablist' ||
          (seats.length===2 && (!div(seats[1]) || seats[1].getAttribute('role')!=='tabpanel')))
        return fail('TAB_PANE_BAR_CONTENT_CHANGED');
      field=frame=seats[0];
      const tabs=children(field);
      if(!tabs || tabs.some(n=>n.tagName!=='SPAN'))return fail('TAB_PANE_GENERATED_TABS_CHANGED');
      // The actual bar owns barPadding. Content, tab-label slots and per-chip
      // spacing/borders never replace this source, even if nested roles match.
      break;
    }
    case 'tree-generated-outer-layout-host':
      if(!div(field) || field.getAttribute('role')!=='tree' ||
          !outer.some(n=>n.tagName!=='STYLE'))return fail('TREE_LAYOUT_CHANGED');
      // Dynamic current expansion is deliberately not inferred from initial
      // CoreTreeNode.expanded or from a first row. The outer root is invariant.
      break;
    case 'timeline-generated-sequence-layout-host': {
      // preview_layout.dart explicitly lists timeline/default as fill-width;
      // web_registry.dart adds one w-full wrapper around the actual Timeline.
      if(!div(layoutRoot) || !has(layoutRoot,'w-full') || outer.length!==1)
        return fail('TIMELINE_REGISTRY_ROUTE_CHANGED');
      field=frame=outer[0];
      const seats=children(field);
      if(!div(field) || !has(field,'relative','flex','flex-col') || !seats ||
          seats.length!==3 || seats.some(n=>!div(n)))return fail('TIMELINE_LAYOUT_CHANGED');
      break;
    }
    case 'category-breakdown-generated-layout-host': {
      const role=field.getAttribute('role'),donut=role==='group';
      if(!div(field) || !has(field,'flex','w-full') ||
          !['group','list'].includes(role) ||
          outer.length!==(donut?2:4) || outer.some(n=>!div(n)))
        return fail('CATEGORY_BREAKDOWN_CURRENT_LAYOUT_CHANGED');
      if(!donut && outer.some(n=>n.getAttribute('role')!=='listitem'))
        return fail('CATEGORY_BREAKDOWN_ROWS_CHANGED');
      // Empty fallback has no generated breakdown frame and cannot enter here.
      break;
    }
    case 'trend-chart-generated-outer-layout-host':
      if(!div(field) || !has(field,'flex','flex-col','w-full') ||
          ![1,4].includes(outer.length))
        return fail('TREND_CHART_CURRENT_LAYOUT_CHANGED');
      break;
    case 'window-panel-generated-frame-content-inset': {
      if(!div(layoutRoot) || outer.length!==1 || !div(outer[0]))
        return fail('WINDOW_PANEL_REGISTRY_ROUTE_CHANGED');
      field=frame=outer[0];
      const seats=children(field);
      if(!has(field,'flex','flex-col','overflow-hidden') || !seats ||
          ![1,2].includes(seats.length) || seats.some(n=>!div(n)))
        return fail('WINDOW_PANEL_CURRENT_FRAME_CHANGED');
      // The root surface owns containerPadding; body content padding belongs
      // to a separate direct child, including after current minimize changes.
      break;
    }
    default:return fail('UNSUPPORTED_STRUCTURED_SOURCE');
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:frame,registryIsLayoutRoot:true,
    authority:'Exact prevalidated concrete source/current child edges; whole supplied subtrees, per-item insets, body padding, gaps and painted overlays excluded; no CSS/numeric owner selection'};
}
''';
