import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Refs only, under the coordinator's closed Example/variant prevalidation.
/// DOM consistency is not constructor authority. No CSS/numeric reads or search.
String get contentParameterBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  const adapters={
    'kbd-single-keycap-content-inset':'kbd-single-keycap-content-inset-v1',
    'app-bar-medium-toolbar-content-inset':'app-bar-medium-toolbar-content-inset-v1',
    'documentation-refresh-viewport-content-inset':'documentation-refresh-viewport-content-inset-v1'
  };
  if (!source || source.schemaVersion!==1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  const adapter=adapters[source.logicalUnitId];
  if (!adapter || source.quantityId!==${jsonEncode(BoxObservationSourceSpec.quantity)} ||
      source.nativeAdapterId!==adapter || source.webAdapterId!==adapter)
    return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot) return fail('MISSING_CONTENT_PARAMETER_ROOT');
  const capture=layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length!==1 || capture.children[0]!==layoutRoot)
    return fail('MISMATCHED_CONTENT_PARAMETER_CAPTURE');
  const has=(node,...names)=>node && names.every(name=>node.classList.contains(name));
  let field,authority;
  if (source.logicalUnitId==='kbd-single-keycap-content-inset') {
    if (layoutRoot.tagName!=='SPAN' || !has(layoutRoot,'inline-flex','items-center') ||
        layoutRoot.children.length!==1) return fail('KBD_SINGLE_ROOT_CHANGED');
    field=layoutRoot.children[0];
    if (field.tagName!=='SPAN' || !has(field,'inline-flex','shrink-0','justify-center') ||
        field.children.length!==0) return fail('KBD_SINGLE_CAP_CHANGED');
    authority='Prevalidated single text-key Kbd Example; direct generated cap owns CSS padding; sequence gap/min-square and border are separate';
  } else if (source.logicalUnitId==='app-bar-medium-toolbar-content-inset') {
    if (layoutRoot.tagName!=='DIV' || !has(layoutRoot,'flex','flex-col') ||
        layoutRoot.hasAttribute('data-coui-app-bar-glass') ||
        layoutRoot.children.length!==2 || layoutRoot.children[1].tagName!=='DIV')
      return fail('APP_BAR_MEDIUM_ROOT_CHANGED');
    field=layoutRoot.children[0];
    if (field.tagName!=='DIV' || !has(field,'flex','items-center') ||
        field.children.length!==3 || Array.from(field.children).some(node=>node.tagName!=='DIV') ||
        field.children[1].children.length!==0)
      return fail('APP_BAR_MEDIUM_TOOLBAR_CHANGED');
    authority='Prevalidated medium AppBar Example; direct topRow CSS padding only; title block/public actions and outer divider are separate';
  } else {
    if (layoutRoot.tagName!=='DIV' || layoutRoot.children.length!==1)
      return fail('REFRESH_VIEWPORT_SOURCE_CHANGED');
    const supplied=layoutRoot.children[0];
    if (supplied.tagName!=='DIV' || !supplied.hasAttribute('data-refresh-direction'))
      return fail('REFRESH_VIEWPORT_CHILD_CHANGED');
    field=layoutRoot;
    authority='Exact prevalidated parameterless RefreshTriggerDefaultExample creates outer Outlined viewport; entire supplied Refresh subtree stays foreign; docs viewport only, no legacy component-root repair';
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:field,authority};
}
''';
