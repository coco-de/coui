import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Source paths for prevalidated constructor/variant transport, not CSS owners
/// inferred from paint or value. The shared sampler reads caller CSS normally.
String get proxyHostBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  const units = ['mask-generated-clip-host',
    'hover-generated-effect-host','indicator-generated-overlay-host'];
  if (!source || source.schemaVersion !== 1 ||
      source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)} ||
      !units.includes(source.logicalUnitId) ||
      source.nativeAdapterId !== source.logicalUnitId+'-v1' ||
      source.webAdapterId !== source.logicalUnitId+'-v1')
    return fail('PROXY_HOST_TUPLE_CHANGED');
  if (!layoutRoot || layoutRoot.tagName !== 'DIV') return fail('PROXY_HOST_ROOT_CHANGED');
  const capture = layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length !== 1 || capture.children[0] !== layoutRoot)
    return fail('PROXY_HOST_CAPTURE_CHANGED');
  const children = Array.from(layoutRoot.children);
  if (source.logicalUnitId === 'mask-generated-clip-host') {
    if (!layoutRoot.classList.contains('co-mask') || children.length !== 1)
      return fail('MASK_SOURCE_ROUTE_CHANGED');
  } else if (source.logicalUnitId === 'hover-generated-effect-host') {
    if (children.length !== 1) return fail('HOVER_SOURCE_ROUTE_CHANGED');
  } else {
    if (!layoutRoot.classList.contains('relative') ||
        !layoutRoot.classList.contains('inline-block') ||
        children.length !== 2 || children[1].tagName !== 'DIV' ||
        !children[1].classList.contains('absolute') ||
        !children[1].classList.contains('inline-flex') ||
        children[1].children.length !== 1 ||
        children[0] === children[1].children[0])
      return fail('INDICATOR_SOURCE_ROUTE_CHANGED');
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot,frameSource:layoutRoot,
    authority:source.logicalUnitId + ': exact prevalidated source host; foreign child/overlay/clip contour excluded; CSS values not used for eligibility'};
}
''';
