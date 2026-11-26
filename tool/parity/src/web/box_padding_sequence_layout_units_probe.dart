import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Source refs only. Root's closed registry-construction prevalidation is the
/// authority; local DOM attributes/classes are consistency checks, not proof.
String get sequenceLayoutBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  const adapters={
    'stack-layout-generated-overlap-layout-host':'stack-layout-generated-overlap-layout-host-v1',
    'indexed-switcher-generated-indexed-layout-host':'indexed-switcher-generated-indexed-layout-host-v1',
    'swap-generated-overlap-layout-host':'swap-generated-overlap-layout-host-v1',
    'divider-generated-labelled-sequence-layout-host':'divider-generated-labelled-sequence-layout-host-v1'
  };
  if (!source || source.schemaVersion!==1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  const adapter=adapters[source.logicalUnitId];
  if (!adapter || source.quantityId!==${jsonEncode(BoxObservationSourceSpec.quantity)} ||
      source.nativeAdapterId!==adapter || source.webAdapterId!==adapter)
    return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot) return fail('MISSING_SEQUENCE_LAYOUT_SOURCE');
  const capture=layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length!==1 || capture.children[0]!==layoutRoot)
    return fail('MISMATCHED_SEQUENCE_LAYOUT_CAPTURE');
  const children=node=>Array.from(node.children).filter(child=>child.tagName!=='STYLE');
  const has=(node,...names)=>names.every(name=>node.classList.contains(name));
  const div=node=>node && node.tagName==='DIV';
  let field;
  switch(source.logicalUnitId) {
    case 'stack-layout-generated-overlap-layout-host': {
      const outer=children(layoutRoot);
      if (!div(layoutRoot) || outer.length!==1 || !div(outer[0]) ||
          !has(outer[0],'relative')) return fail('STACK_LAYOUT_SOURCE_CHANGED');
      field=outer[0];
      const layers=children(field);
      if (layers.length!==3 || layers.some(node=>!div(node) || !has(node,'absolute')))
        return fail('STACK_LAYOUT_LAYERS_CHANGED');
      break;
    }
    case 'indexed-switcher-generated-indexed-layout-host': {
      const outer=children(layoutRoot);
      if (!div(layoutRoot) || !has(layoutRoot,'inline-flex','flex-col') || outer.length!==3 ||
          !div(outer[0])) return fail('INDEXED_EXAMPLE_VIEW_SOURCE_CHANGED');
      const sizing=children(outer[0]);
      if (sizing.length!==1 || !div(sizing[0]) || !has(sizing[0],'grid'))
        return fail('INDEXED_LAYOUT_SOURCE_CHANGED');
      field=sizing[0];
      const slots=children(field);
      if (slots.length!==3 || slots.some(node=>!div(node) || children(node).length!==1))
        return fail('INDEXED_MAINTAINED_SLOTS_CHANGED');
      break;
    }
    case 'swap-generated-overlap-layout-host': {
      const outer=children(layoutRoot);
      if (!div(layoutRoot) || layoutRoot.getAttribute('role')!=='button' ||
          !['true','false'].includes(layoutRoot.getAttribute('aria-pressed')) ||
          outer.length!==1 || !div(outer[0])) return fail('SWAP_INTERACTIVE_SOURCE_CHANGED');
      const transformed=children(outer[0]);
      if (transformed.length!==1 || !div(transformed[0])) return fail('SWAP_OVERLAP_SOURCE_CHANGED');
      field=transformed[0];
      const declarations=(field.getAttribute('style')??'').split(';');
      if (!declarations.some(part=>{
        const colon=part.indexOf(':');
        return colon>=0 && part.slice(0,colon).trim()==='display' &&
          part.slice(colon+1).trim()==='grid';
      })) return fail('SWAP_UNSUPPORTED_LAYOUT_BRANCH');
      const slots=children(field);
      if (slots.length!==2 || slots.some(node=>!div(node))) return fail('SWAP_SLOTS_CHANGED');
      break;
    }
    case 'divider-generated-labelled-sequence-layout-host': {
      field=layoutRoot;
      const seats=children(field);
      if (!div(field) || !has(field,'grid','w-full','items-center') ||
          field.getAttribute('role')==='separator' || seats.length!==3 ||
          seats.some(node=>!div(node)) || children(seats[0]).length!==0 ||
          children(seats[2]).length!==0) return fail('DIVIDER_LABELLED_SEQUENCE_CHANGED');
      // Label content and the line margins never donate padding to this grid.
      break;
    }
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:field,
    authority:'Closed prevalidated sequence recipe; actual source layout host only. Supplied layers/views/on-off/label subtrees are opaque and no CSS value is read.'};
}
''';
