import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Refs only after the coordinator's closed operation/recipe prevalidation.
/// Local DOM consistency does not independently attest a constructor.
String get displayParameterBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  const adapters={
    'status-generated-dot-content-inset':'status-generated-dot-content-inset-v1',
    'tag-generated-label-content-inset':'tag-generated-label-content-inset-v1',
    'skeleton-circular-block-content-inset':'skeleton-circular-block-content-inset-v1'
  };
  if (!source || source.schemaVersion!==1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  const adapter=adapters[source.logicalUnitId];
  if (!adapter || source.quantityId!==${jsonEncode(BoxObservationSourceSpec.quantity)} ||
      source.nativeAdapterId!==adapter || source.webAdapterId!==adapter)
    return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot) return fail('MISSING_DISPLAY_PARAMETER_ROOT');
  const capture=layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length!==1 || capture.children[0]!==layoutRoot)
    return fail('MISMATCHED_DISPLAY_PARAMETER_CAPTURE');
  const has=(node,...names)=>node && names.every(name=>node.classList.contains(name));
  const children=Array.from(layoutRoot.children);
  let authority;
  if (source.logicalUnitId==='status-generated-dot-content-inset') {
    if (layoutRoot.tagName!=='SPAN' || layoutRoot.getAttribute('role')!=='status' ||
        children.length!==0) return fail('STATUS_DOT_SOURCE_CHANGED');
    authority='Prevalidated plain Status dot operation; own root span only, no visible label/pulse/bar or foreign padding';
  } else if (source.logicalUnitId==='tag-generated-label-content-inset') {
    if (layoutRoot.tagName!=='SPAN' || !has(layoutRoot,'inline-flex','items-center','justify-center','select-none') ||
        children.length!==1) return fail('TAG_LABEL_SOURCE_CHANGED');
    // Public Tag.child is opaque. Its contents/classes/styles never select owner.
    authority='Prevalidated Tag operation; actual root span owns padding; entire supplied child stays foreign';
  } else {
    if (layoutRoot.tagName!=='DIV' || !has(layoutRoot,'animate-pulse') ||
        children.length>1 || children.some(node=>node.tagName!=='SPAN' || !has(node,'sr-only','fixed')))
      return fail('SKELETON_CIRCLE_SOURCE_CHANGED');
    authority='Prevalidated circular Skeleton operation; current block root padding, optional generated announcer is not owner';
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot,frameSource:layoutRoot,authority};
}
''';
