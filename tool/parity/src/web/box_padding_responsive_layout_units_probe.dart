import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// References after Root's closed constructor/recipe prevalidation only.
/// CSS shape alone cannot attest a constructor; this getter never reads values.
String get responsiveLayoutBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail=error=>({error});
  const tuples=${jsonEncode([BoxObservationSourceSpec.responsiveFlexLayoutHost, BoxObservationSourceSpec.responsiveContainerContentInset, BoxObservationSourceSpec.responsiveGridLayoutHost].map((s) => s.toJson()).toList())};
  const expected=source && tuples.find(t=>t.logicalUnitId===source.logicalUnitId);
  if(!expected || Object.keys(expected).some(k=>source[k]!==expected[k])) return fail('RESPONSIVE_SOURCE_TUPLE_CHANGED');
  if(!layoutRoot || layoutRoot.tagName!=='DIV')return fail('RESPONSIVE_ROOT_CHANGED');
  const container=source.logicalUnitId==='responsive-container-generated-content-inset';
  const grid=source.logicalUnitId==='responsive-grid-generated-grid-layout-host';
  const children=parent=>{
    const all=Array.from(parent.children);
    if(new Set(all).size!==all.length || all.some(n=>n.parentElement!==parent))return null;
    return all;
  };
  // The docs registry wraps ResponsiveContainer in a width-filling stage.
  // The existing canonical root selects the actual container below that stage.
  const registry=container?layoutRoot.parentElement:layoutRoot;
  if(!registry || registry.tagName!=='DIV')return fail('RESPONSIVE_REGISTRY_CHANGED');
  const capture=registry.parentElement,top=capture && children(capture);
  if(!capture || !capture.hasAttribute('data-parity-key') || !top || top.length!==1 || top[0]!==registry)return fail('RESPONSIVE_CAPTURE_CHANGED');
  const all=children(registry);
  if(!all)return fail('RESPONSIVE_CHILD_IDENTITY_CHANGED');
  let unit=registry;
  if(container){
    if(all.length!==1 || all[0]!==layoutRoot || !registry.classList.contains('w-full') || !registry.classList.contains('flex') || !registry.classList.contains('justify-center') || !layoutRoot.classList.contains('w-full'))return fail('RESPONSIVE_CONTAINER_ROUTE_CHANGED');
    unit=layoutRoot;
    const content=children(unit);
    if(!content || content.length!==1)return fail('RESPONSIVE_CONTAINER_CONTENT_CHANGED');
  }else if(grid){
    const styles=all.filter(n=>n.tagName==='STYLE');
    if(styles.length){
      if(styles.length!==1 || all.length!==2 || all[0]!==styles[0] || all[1].tagName!=='DIV')return fail('RESPONSIVE_GRID_WRAPPER_CHANGED');
      unit=all[1];
    }
    if(!unit.hasAttribute('id'))return fail('RESPONSIVE_GRID_SCOPE_CHANGED');
    const cells=children(unit);
    if(!cells || cells.length===0 || cells.some(n=>n.tagName==='STYLE'))return fail('RESPONSIVE_GRID_SLOTS_CHANGED');
  }else{
    if(!registry.classList.contains('flex') || all.length===0 || all.some(n=>n.tagName==='STYLE'))return fail('RESPONSIVE_FLEX_ROUTE_CHANGED');
  }
  return {registryResultElement:registry,fieldUnitElement:unit,paddingSource:unit,frameSource:unit,
    registryIsLayoutRoot:registry===layoutRoot,
    authority:'Exact prevalidated responsive constructor/recipe and current source child route; canonical container owns CSS padding below documentation stage, grid owns inner grid seat, supplied interiors and distribution excluded'};
}
''';
