import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// References from closed registry recipes, never CSS/numeric owner searches.
String get formCollectionBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  const adapters={
    'toggle-group-generated-track-content-inset':'toggle-group-generated-track-content-inset-v1',
    'form-field-generated-layout-host':'form-field-generated-layout-host-v1',
    'form-label-generated-label-row-layout-host':'form-label-generated-label-row-layout-host-v1',
    'listing-generated-rows-layout-host':'listing-generated-rows-layout-host-v1',
    'option-list-generated-layout-host':'option-list-generated-layout-host-v1'
  };
  if (!source || source.schemaVersion!==1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  const adapter=adapters[source.logicalUnitId];
  if (!adapter || source.quantityId!==${jsonEncode(BoxObservationSourceSpec.quantity)} ||
      source.nativeAdapterId!==adapter || source.webAdapterId!==adapter)
    return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot) return fail('MISSING_FORM_COLLECTION_SOURCE');
  const capture=layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length!==1 || capture.children[0]!==layoutRoot)
    return fail('MISMATCHED_FORM_COLLECTION_CAPTURE');
  const children=node=>Array.from(node.children).filter(child=>child.tagName!=='STYLE');
  const div=node=>node && node.tagName==='DIV';
  const role=(node,value)=>node.getAttribute('role')===value;
  let field=layoutRoot;
  switch(source.logicalUnitId) {
    case 'toggle-group-generated-track-content-inset': {
      // The public ToggleGroup builds one track and one arrangement child.
      // Its generated Clickable segment subtrees never donate track padding.
      const outer=children(field);
      if (!div(field) || !role(field,'radiogroup') || outer.length!==1 || !div(outer[0]))
        return fail('TOGGLE_GROUP_TRACK_SOURCE_CHANGED');
      const seats=children(outer[0]);
      if (seats.length!==2 || seats.some(node=>!role(node,'radio')))
        return fail('TOGGLE_GROUP_SEGMENTS_CHANGED');
      break;
    }
    case 'form-field-generated-layout-host': {
      // This audited docs example wraps its FormField in a width-only div.
      // The canonical root remains that registry div; the field owns padding.
      const outer=children(layoutRoot);
      if (!div(layoutRoot) || outer.length!==1 || !div(outer[0]) || !role(outer[0],'group'))
        return fail('FORM_FIELD_EXAMPLE_SOURCE_CHANGED');
      field=outer[0];
      const seats=children(field);
      if (seats.length!==5 || !div(seats[0]) || children(seats[0]).length!==1 ||
          children(seats[0])[0].tagName!=='LABEL') return fail('FORM_FIELD_LAYOUT_SEATS_CHANGED');
      // Caller input and composed label/footer chrome remain opaque.
      break;
    }
    case 'form-label-generated-label-row-layout-host': {
      const seats=children(field);
      if (field.tagName!=='LABEL' || seats.length!==2 ||
          seats[1].tagName!=='SPAN' || seats[1].getAttribute('aria-hidden')!=='true')
        return fail('FORM_LABEL_ROW_SOURCE_CHANGED');
      break;
    }
    case 'listing-generated-rows-layout-host': {
      const seats=children(field);
      // Listing inserts default decorative Dividers (semantic=false).
      // Only those empty generated seats are inspected; whole rows stay opaque.
      const divider=node=>div(node) && children(node).length===0 &&
        !node.hasAttribute('role');
      if (!div(field) || !role(field,'list') || seats.length!==5 ||
          !divider(seats[1]) || !divider(seats[3]))
        return fail('LISTING_ROWS_SOURCE_CHANGED');
      // Whole ListRows, including their own row insets, are foreign.
      break;
    }
    case 'option-list-generated-layout-host': {
      if (!div(field) || !role(field,'group') || children(field).length!==3)
        return fail('OPTION_LIST_LAYOUT_SOURCE_CHANGED');
      // Every supplied OptionItem is a whole foreign subtree.
      break;
    }
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:field,
    authority:'Closed prevalidated form/collection recipe; exact source-owned track or arrangement host. Documentation width wrappers and supplied content cannot donate padding. No CSS value is read.'};
}
''';
