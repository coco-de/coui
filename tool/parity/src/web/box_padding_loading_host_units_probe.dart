import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Source-route references after Root's closed constructor/recipe validation.
/// Local shape checks do not independently attest the constructor or variant.
String get loadingHostBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  const expected = ${jsonEncode(BoxObservationSourceSpec.loadingSizeHost.toJson())};
  if (!source || Object.keys(expected).some(key => source[key] !== expected[key]))
    return fail('LOADING_SOURCE_TUPLE_CHANGED');
  if (!layoutRoot || layoutRoot.tagName !== 'SPAN') return fail('LOADING_HOST_CHANGED');
  const capture = layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length !== 1 || capture.children[0] !== layoutRoot)
    return fail('LOADING_CAPTURE_CHANGED');
  if (layoutRoot.getAttribute('role') !== 'status' ||
      !layoutRoot.hasAttribute('aria-label')) return fail('LOADING_STATUS_SOURCE_CHANGED');
  const all = Array.from(layoutRoot.children);
  const styles = all.filter(node => node.tagName === 'STYLE');
  if (styles.length > 1 || (styles.length === 1 && all[0] !== styles[0]))
    return fail('LOADING_STYLE_SOURCE_CHANGED');
  const visuals = all.filter(node => node.tagName !== 'STYLE');
  if (new Set(visuals).size !== visuals.length) return fail('DUPLICATE_LOADING_SOURCE_CHILD');
  const spinner = visuals.length === 2 && visuals.every(node =>
    node.tagName.toUpperCase() === 'SVG' && node.children.length === 1 &&
    node.children[0].tagName.toUpperCase() === 'CIRCLE');
  const dots = visuals.length === 3 && visuals.every(node => node.tagName === 'SPAN' && node.children.length === 0);
  const bar = visuals.length === 1 && visuals[0].tagName === 'SPAN' && visuals[0].children.length === 0;
  const pulse = visuals.length === 2 && visuals.every(node => node.tagName === 'SPAN' && node.children.length === 0);
  if (!(spinner || dots || bar || pulse)) return fail('LOADING_VISUAL_SOURCE_CHANGED');
  return {registryResultElement:layoutRoot, fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot, frameSource:layoutRoot,
    authority:'Exact prevalidated Loading constructor/recipe root; generated optional leading STYLE and SVG/span branches; own size host only, private paint excluded'};
}
''';
