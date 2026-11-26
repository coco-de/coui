import 'dart:convert';

import 'package:coui_web/src/util/web_constants.dart'
    show kWebLocalSurfaceMarker, kWebSurfaceMarker;

import '../model/box_observation_source_spec.dart';

/// References only for four audited construction families and actual inputs.
/// A source-derived descriptor/input proof is required; classes alone do not
/// authenticate a constructor. No CSS/numeric read, global query or DOM write.
String get extendedComponentBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  if (!source || source.schemaVersion !== 1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)}) return fail('UNSUPPORTED_BOX_QUANTITY');
  const adapters = {
    'banner-generated-frame':'banner-generated-frame-v1',
    'description-card-generated-frame':'description-card-generated-frame-v1',
    'formatted-input-generated-frame':'formatted-input-generated-frame-v1',
    'frame-generated-content-inset':'frame-generated-content-inset-v1'
  };
  const adapter = adapters[source.logicalUnitId];
  if (!adapter) return fail('UNREGISTERED_EXTENDED_COMPONENT_SOURCE');
  if (source.nativeAdapterId !== adapter || source.webAdapterId !== adapter) return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot || layoutRoot.tagName !== 'DIV') return fail('EXTENDED_COMPONENT_LAYOUT_CHANGED');
  const capture = layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') || capture.children.length !== 1 || capture.children[0] !== layoutRoot) return fail('MISMATCHED_COMPONENT_CAPTURE_ROOT');
  const onlyDiv = node => node.children.length === 1 && node.children[0].tagName === 'DIV' ? node.children[0] : null;
  const outlined = node => node && ${jsonEncode([kWebSurfaceMarker, kWebLocalSurfaceMarker])}.some(name => node.classList.contains(name));
  let unit, owner, authority;
  switch (adapter) {
    case 'banner-generated-frame-v1':
      unit = layoutRoot.getAttribute('role') === 'banner' ? layoutRoot : onlyDiv(layoutRoot);
      if (!unit || unit.getAttribute('role') !== 'banner') return fail('BANNER_DECLARED_SOURCE_CHANGED');
      owner = unit;
      authority = 'Banner exact example -> own role=banner div; narrow source sizing wrapper retained';
      break;
    case 'description-card-generated-frame-v1':
      owner = outlined(layoutRoot) ? layoutRoot : onlyDiv(layoutRoot);
      if (!outlined(owner)) return fail('DESCRIPTION_CARD_DECLARED_FRAME_CHANGED');
      unit = owner;
      authority = 'Non-interactive DescriptionCard exact example -> own composed Outlined; optional source shadow wrapper';
      break;
    case 'formatted-input-generated-frame-v1':
      if (!outlined(layoutRoot) || !layoutRoot.classList.contains('flex') || !layoutRoot.classList.contains('items-center')) return fail('FORMATTED_INPUT_DECLARED_FRAME_CHANGED');
      unit = owner = layoutRoot;
      authority = 'FormattedInput exact example actual factory result -> root div; inner input and trailing content excluded';
      break;
    case 'frame-generated-content-inset-v1':
      unit = owner = layoutRoot;
      authority = 'Frame exact example -> own root div CSS inset; dash SVG and supplied children excluded';
      break;
    default: return fail('UNSUPPORTED_EXTENDED_COMPONENT_ADAPTER');
  }
  return {registryResultElement:layoutRoot, fieldUnitElement:unit,
    paddingSource:owner, frameSource:owner, authority};
}
''';
