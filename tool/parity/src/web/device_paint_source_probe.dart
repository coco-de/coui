import 'box_padding_framed_collection_units_probe.dart';

/// Binds the Device's separate current paint witness without reading CSS.
/// The source-selected node is not the layout host used for padding absence.
String get devicePaintSourceResolverScript =>
    '''
(request) => {
  const fail = error => ({error});
  const unit = 'mockup-device-generated-body-frame-content-inset';
  if (request?.source?.logicalUnitId !== unit) return {applied:false};
  const exact = (value, keys) => value && typeof value === 'object' && !Array.isArray(value) &&
    Object.keys(value).length === keys.length && keys.every(key => Object.hasOwn(value,key));
  const receipt = request.currentSsrSource;
  const header = ['kind','entryKey','source','currentRaw','completeRawSlotCount','rawOrderFromPublicProducerLists','harnessURL'];
  if (request.requiredCurrentSsrKind !== 'canonical-ssr-framed-collection-v1' ||
      !exact(receipt,header) || receipt.kind !== 'canonical-ssr-framed-collection-v1' ||
      receipt.rawOrderFromPublicProducerLists !== true || receipt.harnessURL !== location.href ||
      !exact(receipt.source,['schemaVersion','logicalUnitId','quantityId','nativeAdapterId','webAdapterId']) ||
      Object.keys(receipt.source).some(key => receipt.source[key] !== request.source[key]))
    return fail('DEVICE_PAINT_CURRENT_RECEIPT_CHANGED');
  if (typeof request.selector !== 'string' || request.layoutSelector !== request.selector)
    return fail('DEVICE_PAINT_CANONICAL_SELECTOR_CHANGED');
  const selected = document.querySelectorAll(request.selector);
  if (selected.length !== 1) return fail('DEVICE_PAINT_CANONICAL_ROOT_CHANGED');
  const layoutRoot = selected[0], registry = layoutRoot?.parentElement, capture = registry?.parentElement;
  if (![capture,registry,layoutRoot].every(node => node?.isConnected === true) ||
      capture.getAttribute('data-parity-key') !== receipt.entryKey ||
      receipt.completeRawSlotCount !== receipt.currentRaw?.rawSlotCount)
    return fail('DEVICE_PAINT_CAPTURE_CHANGED');
  const binding = ($framedCollectionBoxSourceResolverScript)(layoutRoot,request.source,receipt.currentRaw);
  if (binding.error) return fail(binding.error);
  if (binding.registryResultElement !== registry || binding.fieldUnitElement !== layoutRoot ||
      binding.paddingSource !== layoutRoot || binding.frameSource !== layoutRoot)
    return fail('DEVICE_PAINT_LAYOUT_AUTHORITY_CHANGED');
  const paint = receipt.currentRaw.bodyPaintSource;
  if (!paint) return fail('DEVICE_PAINT_SOURCE_REQUIRED');
  const path = paint.ownerPathFromRegistry;
  // The path is observed from the typed producer. These checks constrain it
  // to that declared direct composed child; they do not choose a child index.
  if (path.length !== 2 || path[0] !== 0)
    return fail('DEVICE_PAINT_SOURCE_PATH_CHANGED');
  let node = registry, witness = receipt.currentRaw.generatedTree;
  for (const index of path) {
    if (!node || !witness || Object.hasOwn(witness,'foreignSlot') ||
        !Array.isArray(witness.children) || index >= witness.children.length || index >= node.children.length)
      return fail('DEVICE_PAINT_SOURCE_PATH_CHANGED');
    node = node.children[index]; witness = witness.children[index];
  }
  const hasForeign = tree => !tree || Object.hasOwn(tree,'foreignSlot') ||
    (Array.isArray(tree.children) && tree.children.some(hasForeign));
  if (!node || node.namespaceURI !== 'http://www.w3.org/1999/xhtml' || node.localName !== 'div' ||
      node === layoutRoot || node === registry || node === capture ||
      node.parentElement !== layoutRoot || hasForeign(witness))
    return fail('DEVICE_PAINT_FOREIGN_OWNER');
  const identityMatches = (actual, identity) => {
    if (!exact(identity,['namespaceURI','localName','attributes','childNodes']) ||
        !actual || actual.nodeType !== 1 || actual.namespaceURI !== identity.namespaceURI ||
        actual.localName !== identity.localName || !identity.attributes ||
        typeof identity.attributes !== 'object' || Array.isArray(identity.attributes) ||
        !Array.isArray(identity.childNodes)) return false;
    const attrs = Array.from(actual.attributes);
    if (attrs.length !== Object.keys(identity.attributes).length ||
        attrs.some(attribute => typeof identity.attributes[attribute.name] !== 'string' ||
          identity.attributes[attribute.name] !== attribute.value)) return false;
    const children = Array.from(actual.childNodes);
    if (children.length !== identity.childNodes.length) return false;
    return children.every((child,index) => {
      const declared = identity.childNodes[index];
      if (child.nodeType === 1) return identityMatches(child,declared);
      return exact(declared,['nodeType','data']) && [3,8].includes(child.nodeType) &&
        declared.nodeType === child.nodeType && typeof declared.data === 'string' && declared.data === child.data;
    });
  };
  if (!identityMatches(node,paint.ownerIdentity)) return fail('DEVICE_PAINT_SOURCE_IDENTITY_CHANGED');
  const receiptBefore = JSON.stringify(receipt), sourceBefore = JSON.stringify(request.source), selectorBefore = request.selector;
  const validateCurrentBinding = () => {
    const current = document.querySelectorAll(request.selector);
    if (current.length !== 1 || current[0] !== layoutRoot ||
        request.selector !== selectorBefore || request.layoutSelector !== selectorBefore ||
        request.requiredCurrentSsrKind !== 'canonical-ssr-framed-collection-v1' ||
        capture.getAttribute('data-parity-key') !== receipt.entryKey || receipt.harnessURL !== location.href ||
        ![capture,registry,layoutRoot,node].every(element => element.isConnected === true) ||
        layoutRoot.parentElement !== registry || registry.parentElement !== capture ||
        node.isConnected === false || node.parentElement !== layoutRoot ||
        JSON.stringify(request.currentSsrSource) !== receiptBefore || JSON.stringify(request.source) !== sourceBefore)
      return false;
    const now = ($framedCollectionBoxSourceResolverScript)(layoutRoot,request.source,receipt.currentRaw);
    return !now.error && now.registryResultElement === registry &&
      path.reduce((parent,index) => parent?.children[index],registry) === node &&
      identityMatches(node,paint.ownerIdentity);
  };
  if (!validateCurrentBinding()) return fail('DEVICE_PAINT_SOURCE_STALE');
  return {applied:true,sourcePaintElement:node,validateCurrentBinding,
    paintAuthorityId:paint.paintAuthorityId,fieldScope:paint.fieldScope.slice(),ownerPathFromRegistry:path.slice()};
}
''';
