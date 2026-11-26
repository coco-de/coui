import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Source-only DOM binding. The actual SSR receipt supplies the complete
/// generated order and opaque foreign roots. No CSS value chooses an owner.
/// Browser continues through the existing component reader owned by Root.
String get framedCollectionBoxSourceResolverScript =>
    '''
(layoutRoot, source, currentRaw) => {
  const fail = error => ({error});
  const sameKeys = (value, keys) => value && typeof value === 'object' &&
    !Array.isArray(value) && Object.keys(value).length === keys.length &&
    keys.every(key => Object.prototype.hasOwnProperty.call(value,key));
  if (!sameKeys(source,['schemaVersion','logicalUnitId','quantityId','nativeAdapterId','webAdapterId']) || source.schemaVersion !== 1) return fail('FRAMED_COLLECTION_SOURCE_CHANGED');
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)}) return fail('UNSUPPORTED_BOX_QUANTITY');
  const adapters = {
    'mockup-device-generated-body-frame-content-inset':'mockup-device-generated-body-frame-content-inset-v1',
    'join-generated-strip-layout-host':'join-generated-strip-layout-host-v1',
    'table-generated-grid-content-inset':'table-generated-grid-content-inset-v1'
  };
  const adapter = adapters[source.logicalUnitId];
  if (!adapter || source.nativeAdapterId !== adapter || source.webAdapterId !== adapter) return fail('FRAMED_COLLECTION_CLOSED_ADAPTER_CHANGED');
  const device = source.logicalUnitId === 'mockup-device-generated-body-frame-content-inset';
  const join = source.logicalUnitId === 'join-generated-strip-layout-host';
  const extra = device ? (Object.hasOwn(currentRaw || {},'bodyPaintSource') ? ['bodyPaintSource'] : []) : join ? ['vertical'] : ['resizable','rows'];
  if (!sameKeys(currentRaw,['kind','logicalUnitId','rawSlotCount','slotPresence','route','generatedTree',...extra]) ||
      currentRaw.kind !== 'current-framed-collection-raw-v1' || currentRaw.logicalUnitId !== source.logicalUnitId ||
      !Number.isInteger(currentRaw.rawSlotCount) || currentRaw.rawSlotCount < 0 ||
      !Array.isArray(currentRaw.slotPresence) || currentRaw.slotPresence.length !== currentRaw.rawSlotCount ||
      !currentRaw.slotPresence.every(value => value === true) ||
      currentRaw.route !== (device ? 'device' : join ? 'join' : 'table')) return fail('FRAMED_COLLECTION_CURRENT_RAW_REQUIRED');
  // This optional Device record grants no padding authority. The separate
  // closed paint resolver validates its actual node before reading paint CSS.
  if (device && extra.length) {
    const paint = currentRaw.bodyPaintSource;
    const fields = ['backgroundColor','borderColor','borderWidthPx','borderRadiusPx','boxShadow'];
    if (!sameKeys(paint,['kind','paintAuthorityId','fieldScope','ownerPathFromRegistry','ownerIdentity']) ||
        paint.kind !== 'mockup-device-body-outlined-paint-v1' ||
        paint.paintAuthorityId !== 'public-generated-outlined-body-paint-v1' ||
        !Array.isArray(paint.fieldScope) || paint.fieldScope.length !== fields.length ||
        !fields.every((name,index) => paint.fieldScope[index] === name) ||
        !Array.isArray(paint.ownerPathFromRegistry) || !paint.ownerPathFromRegistry.length ||
        !paint.ownerPathFromRegistry.every(index => Number.isInteger(index) && index >= 0) ||
        !paint.ownerIdentity || typeof paint.ownerIdentity !== 'object' || Array.isArray(paint.ownerIdentity))
      return fail('FRAMED_COLLECTION_DEVICE_PAINT_RECORD_CHANGED');
  }
  const htmlNS = 'http://www.w3.org/1999/xhtml';
  const isDiv = node => node && node.namespaceURI === htmlNS && node.localName === 'div';
  const elementSeatsOnly = node => Array.from(node.childNodes).every(child =>
    child.nodeType === 1 || (child.nodeType === 3 && /^[\\t\\n\\f\\r ]*\$/.test(child.data)));
  const registry = device && layoutRoot ? layoutRoot.parentElement : layoutRoot;
  const capture = registry && registry.parentElement;
  if (!isDiv(layoutRoot) || !isDiv(registry) || !elementSeatsOnly(layoutRoot) || !elementSeatsOnly(registry) || !capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length !== 1 || capture.children[0] !== registry ||
      Array.from(capture.childNodes).some(node => node !== registry &&
        !(node.nodeType === 3 && /^[\\t\\n\\f\\r ]*\$/.test(node.data)))) return fail('FRAMED_COLLECTION_CAPTURE_CHANGED');
  if (device && (registry.children.length !== 1 || registry.children[0] !== layoutRoot ||
      !['w-full','flex','justify-center'].every(name => registry.classList.contains(name)) || currentRaw.rawSlotCount !== 1)) return fail('FRAMED_COLLECTION_DEVICE_WIDTH_WRAPPER_CHANGED');
  const match = (node, witness) => {
    if (sameKeys(witness,['foreignSlot'])) {
      return node && node !== registry && node !== layoutRoot && Number.isInteger(witness.foreignSlot) && witness.foreignSlot >= 0 &&
        witness.foreignSlot < currentRaw.rawSlotCount && currentRaw.slotPresence[witness.foreignSlot] === true;
    }
    if (!sameKeys(witness,['namespaceURI','localName','role','nodeKinds','children']) || !node ||
        node.namespaceURI !== witness.namespaceURI || node.localName !== witness.localName ||
        node.getAttribute('role') !== witness.role || !Array.isArray(witness.children) ||
        node.children.length !== witness.children.length) return false;
    const kinds = Array.from(node.childNodes).filter(child =>
      !(child.nodeType === 3 && /^[\\t\\n\\f\\r ]*\$/.test(child.data))).map(child => child.nodeType);
    if (!Array.isArray(witness.nodeKinds) || kinds.length !== witness.nodeKinds.length ||
        !witness.nodeKinds.every((kind,index) => Number.isInteger(kind) && [1,3,8].includes(kind) && kind === kinds[index])) return false;
    return witness.children.every((child,index) => match(node.children[index],child));
  };
  if (!match(registry,currentRaw.generatedTree)) return fail('FRAMED_COLLECTION_GENERATED_TREE_CHANGED');
  if (join) {
    if (typeof currentRaw.vertical !== 'boolean' || layoutRoot.children.length !== currentRaw.rawSlotCount + 1 ||
        layoutRoot.children[0].namespaceURI !== htmlNS || layoutRoot.children[0].localName !== 'style' ||
        Array.from(layoutRoot.children).slice(1).some(node => !isDiv(node))) return fail('FRAMED_COLLECTION_JOIN_ORDER_CHANGED');
  } else if (!device) {
    if (typeof currentRaw.resizable !== 'boolean' || !Array.isArray(currentRaw.rows) ||
        layoutRoot.getAttribute('role') !== 'table' || layoutRoot.children.length !== currentRaw.rows.length) return fail('FRAMED_COLLECTION_TABLE_ROWS_CHANGED');
    let count = 0;
    for (let r = 0; r < currentRaw.rows.length; r++) {
      const row = currentRaw.rows[r], element = layoutRoot.children[r];
      if (!sameKeys(row,['kind','cells']) || !['header','body','footer'].includes(row.kind) || !Array.isArray(row.cells) ||
          !isDiv(element) || !elementSeatsOnly(element) || element.getAttribute('role') !== 'row' || element.children.length !== row.cells.length) return fail('FRAMED_COLLECTION_TABLE_ROW_ORDER_CHANGED');
      for (let c = 0; c < row.cells.length; c++) {
        const cell = row.cells[c], node = element.children[c];
        if (!sameKeys(cell,['columnSpan','rowSpan','resizers']) ||
            !Number.isInteger(cell.columnSpan) || cell.columnSpan < 1 || !Number.isInteger(cell.rowSpan) || cell.rowSpan < 1 ||
            !Number.isInteger(cell.resizers) || cell.resizers < 0 || cell.resizers > 2 ||
            (!currentRaw.resizable && cell.resizers !== 0) || !isDiv(node) ||
            node.getAttribute('role') !== (row.kind === 'header' ? 'columnheader' : 'cell') ||
            node.getAttribute('aria-colspan') !== (cell.columnSpan > 1 ? String(cell.columnSpan) : null) ||
            node.getAttribute('aria-rowspan') !== (cell.rowSpan > 1 ? String(cell.rowSpan) : null)) return fail('FRAMED_COLLECTION_TABLE_CELL_CHANGED');
        count++;
      }
    }
    if (count !== currentRaw.rawSlotCount) return fail('FRAMED_COLLECTION_TABLE_RAW_COUNT_CHANGED');
  }
  return {registryResultElement:registry,fieldUnitElement:layoutRoot,
    paddingSource:layoutRoot,frameSource:layoutRoot,
    registryIsLayoutRoot:registry === layoutRoot,
    authority:'original public SSR producer -> complete generated DOM and whole foreign roots -> exact own frame'};
}
''';
