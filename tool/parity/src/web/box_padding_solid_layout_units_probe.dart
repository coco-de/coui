import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// DOM references for a coordinator-validated constructor/variant tuple.
///
/// Local DOM guards do not authenticate constructor provenance. There are no
/// CSS/numeric reads, global searches, callbacks, writes or zero fallback.
String get solidLayoutBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  if (!source || source.schemaVersion !== 1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)}) return fail('UNSUPPORTED_BOX_QUANTITY');
  const adapters = {
    'app-bar-solid-content-inset':'app-bar-solid-content-inset-v1',
    'empty-state-generated-content-inset':'empty-state-generated-content-inset-v1'
  };
  const adapter = adapters[source.logicalUnitId];
  if (!adapter) return fail('UNREGISTERED_SOLID_LAYOUT_CONSTRUCTION');
  if (source.nativeAdapterId !== adapter || source.webAdapterId !== adapter) return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot) return fail('MISSING_SOLID_LAYOUT_ROOT');
  const capture = layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') || capture.children.length !== 1 || capture.children[0] !== layoutRoot) return fail('MISMATCHED_SOLID_LAYOUT_CAPTURE');
  let unit = layoutRoot;
  if (adapter === 'empty-state-generated-content-inset-v1') {
    // _fillingTheStageWhereFlutterFills wraps these four prevalidated
    // EmptyState examples. This is not permission to unwrap arbitrary roots.
    if (layoutRoot.tagName !== 'DIV' ||
        layoutRoot.getAttribute('class') !== 'w-full' ||
        layoutRoot.children.length !== 1)
      return fail('EMPTY_STATE_REGISTRY_WRAPPER_CHANGED');
    unit = layoutRoot.children[0];
  }
  const has = name => unit.classList.contains(name);
  const children = Array.from(unit.children);
  if (layoutRoot.tagName !== 'DIV') return fail('SOLID_LAYOUT_ROOT_CHANGED');
  if (adapter === 'app-bar-solid-content-inset-v1') {
    if (!has('w-full') || !has('box-border') || !has('items-center') ||
        !(has('grid') || (has('flex') && has('flex-row'))) ||
        has('flex-col') || layoutRoot.hasAttribute('data-coui-app-bar-glass') ||
        children.some(child => child.hasAttribute('data-coui-app-bar-edge')))
      return fail('UNSUPPORTED_APP_BAR_SOURCE_BRANCH');
    // Source emits a single title block even when it has no title payload.
    // Leading/trailing and the hidden side anchor are distinct direct slots.
    const content = children.filter(child =>
      !child.hasAttribute('data-coui-app-bar-leading') &&
      !child.hasAttribute('data-coui-app-bar-trailing') &&
      !child.hasAttribute('hidden'));
    if (content.length !== 1 || content[0].tagName !== 'DIV') return fail('APP_BAR_CONTENT_BOUNDARY_CHANGED');
  } else {
    if (unit.tagName !== 'DIV' || !has('flex') || !has('flex-col') || !has('items-center') || !has('justify-center')) return fail('EMPTY_STATE_SOURCE_BRANCH_CHANGED');
    const text = children.filter(child => child.tagName === 'DIV' &&
      child.classList.contains('flex-col') && child.classList.contains('items-center'));
    if (text.length !== 1) return fail('EMPTY_STATE_TEXT_BOUNDARY_CHANGED');
  }
  return {registryResultElement:layoutRoot, fieldUnitElement:unit,
    paddingSource:unit, frameSource:unit,
    authority:adapter + ': exact prevalidated source root owns CSS content padding; foreign descendants excluded; not painted-edge distance'};
}
''';
