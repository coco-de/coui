import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Refs only after closed constructor/variant operation prevalidation by Root.
/// Local DOM consistency alone does not attest a component constructor.
String get collectionLayoutHostBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  const adapters={
    'calendar-generated-layout-host':'calendar-generated-layout-host-v1',
    'definition-list-generated-layout-host':'definition-list-generated-layout-host-v1'
  };
  if (!source || source.schemaVersion!==1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  const adapter=adapters[source.logicalUnitId];
  if (!adapter || source.quantityId!==${jsonEncode(BoxObservationSourceSpec.quantity)} ||
      source.nativeAdapterId!==adapter || source.webAdapterId!==adapter)
    return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot) return fail('MISSING_COLLECTION_LAYOUT_HOST');
  const capture=layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length!==1 || capture.children[0]!==layoutRoot)
    return fail('MISMATCHED_COLLECTION_LAYOUT_CAPTURE');
  const has=(node,...names)=>names.every(name=>node.classList.contains(name));
  const ownedChildren=node=>Array.from(node.children).filter(child=>child.tagName!=='STYLE');
  let field=layoutRoot;
  // The frozen registry operation wraps only the columns recipe in its
  // existing width-filling DIV. Keep that capture root; declare its own DL
  // descendant explicitly. Local classes are not constructor authority
  // without the coordinator's closed operation prevalidation.
  if (source.logicalUnitId==='definition-list-generated-layout-host' && layoutRoot.tagName==='DIV') {
    const children=ownedChildren(layoutRoot);
    if (!has(layoutRoot,'w-full') || children.length!==1 || children[0].tagName!=='DL' ||
        !has(children[0],'grid')) return fail('DEFINITION_LIST_REGISTRY_WRAPPER_CHANGED');
    field=children[0];
  }
  const children=ownedChildren(field);
  let authority;
  if (source.logicalUnitId==='calendar-generated-layout-host') {
    if (layoutRoot.tagName!=='DIV' || !has(layoutRoot,'inline-flex') ||
        !layoutRoot.getAttribute('aria-label') || children.length!==1 ||
        children[0].tagName!=='DIV') return fail('CALENDAR_LAYOUT_HOST_SOURCE_CHANGED');
    authority='Prevalidated Calendar operation; actual outer layout root only. Navigation/date cells/markers remain below the content boundary.';
  } else {
    if (field.tagName!=='DL' ||
        !(has(field,'grid') || has(field,'flex','flex-col') || has(field,'flex','flex-wrap')) ||
        children.length%2!==0 || children.some((node,index)=>node.tagName!==(index%2===0?'DT':'DD')))
      return fail('DEFINITION_LIST_LAYOUT_HOST_SOURCE_CHANGED');
    // DD content is public and opaque; it cannot donate padding to this DL.
    authority='Prevalidated DefinitionList operation; actual DL layout root. Per-entry gaps/cell padding and rich description content are separate quantities.';
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:field,authority};
}
''';
