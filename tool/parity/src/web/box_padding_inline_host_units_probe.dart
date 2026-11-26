import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Actual DOM references under the coordinator's validated entry/input.
///
/// This local route is not constructor authentication. The existing capture
/// operation must first prove the exact frozen public example/producer input.
/// No CSS value is read or synthesized: caller padding remains observable by
/// the existing Web sampler, even when Native has supported own-inset absence.
String get inlineHostBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  if (!source || source.schemaVersion !== 1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  const adapters = {
    'label-generated-inline-host':'label-generated-inline-host-v1',
    'link-generated-inline-host':'link-generated-inline-host-v1'
  };
  const adapter = adapters[source.logicalUnitId];
  if (!adapter) return fail('UNREGISTERED_INLINE_HOST_SOURCE');
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)} ||
      source.nativeAdapterId !== adapter || source.webAdapterId !== adapter)
    return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  const capture = layoutRoot && layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length !== 1 || capture.children[0] !== layoutRoot)
    return fail('MISMATCHED_COMPONENT_CAPTURE_ROOT');
  let authority;
  if (adapter === 'label-generated-inline-host-v1') {
    if (layoutRoot.tagName !== 'SPAN') return fail('LABEL_INLINE_HOST_CHANGED');
    const tags = Array.from(layoutRoot.children).map(node => node.tagName).join(',');
    if (!['SPAN','SPAN,DIV,SPAN','SPAN,DIV,SPAN,DIV,SPAN'].includes(tags))
      return fail('LABEL_GENERATED_CELLS_CHANGED');
    authority = 'Frozen Label constructor root span; supplied icon descendants and source Gap cells excluded';
  } else {
    if (layoutRoot.tagName !== 'A' || !layoutRoot.hasAttribute('href') ||
        layoutRoot.hasAttribute('data-href')) return fail('LINK_NAVIGATION_HOST_CHANGED');
    const children = Array.from(layoutRoot.children);
    const styles = children.filter(node => node.tagName === 'STYLE');
    if (styles.length > 1 || (styles.length === 1 && children[0] !== styles[0]))
      return fail('LINK_SCOPED_STYLE_CELL_CHANGED');
    authority = 'Frozen navigation Link constructor root anchor; scoped style and supplied content excluded, no navigation invoked';
  }
  return {registryResultElement:layoutRoot, fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot, frameSource:layoutRoot, authority};
}
''';
