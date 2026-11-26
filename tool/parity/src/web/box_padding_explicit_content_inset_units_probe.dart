import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// References after closed constructor/recipe prevalidation, not CSS values.
/// Shape checks alone do not authenticate the original public constructor.
String get explicitContentInsetBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  const tuples = ${jsonEncode(BoxObservationSourceSpec.explicitContentInsetFrames.map((s) => s.toJson()).toList())};
  const expected = source && tuples.find(t => t.logicalUnitId === source.logicalUnitId);
  if (!expected || Object.keys(expected).some(key => source[key] !== expected[key])) return fail('EXPLICIT_INSET_SOURCE_TUPLE_CHANGED');
  if (!layoutRoot || layoutRoot.tagName !== 'DIV') return fail('EXPLICIT_INSET_ROOT_CHANGED');
  const capture = layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') || capture.children.length !== 1 || capture.children[0] !== layoutRoot) return fail('EXPLICIT_INSET_CAPTURE_CHANGED');
  const children = parent => {
    const all = Array.from(parent.children);
    if (new Set(all).size !== all.length || all.some(n => n.parentElement !== parent)) return null;
    const styles = all.filter(n => n.tagName === 'STYLE');
    if (styles.length > 1 || (styles.length === 1 && all[0] !== styles[0])) return null;
    return all.filter(n => n.tagName !== 'STYLE');
  };
  let unit = layoutRoot;
  const menu = source.logicalUnitId === 'menu-item-generated-row-content-inset';
  if (menu) {
    // The audited Examples return this width wrapper, then their single row.
    if (layoutRoot.getAttribute('class') !== 'w-layout280') return fail('MENU_EXAMPLE_SOURCE_CHANGED');
    const wrapped = children(layoutRoot);
    if (!wrapped || wrapped.length !== 1 || wrapped[0].tagName !== 'DIV') return fail('MENU_ROW_SOURCE_CHANGED');
    unit = wrapped[0];
  }
  const all = children(unit);
  if (!all) return fail('EXPLICIT_INSET_CHILD_SOURCE_CHANGED');
  const has = name => unit.classList.contains(name);
  if (!has('flex') || !has('w-full') || !has('items-center')) return fail('EXPLICIT_INSET_LAYOUT_SOURCE_CHANGED');
  if (menu) {
    if (!has('co-menu-item-row') || unit.getAttribute('role') !== 'menuitem' || unit.hasAttribute('aria-haspopup')) return fail('MENU_ROW_SOURCE_CHANGED');
    // Source emits wash first, then optional seats/gaps and one text column.
    const wash = all.filter(n => n.classList.contains('co-menu-item-wash'));
    const text = all.filter(n => n.classList.contains('flex-col') && n.classList.contains('items-start') && n.classList.contains('flex-1'));
    if (wash.length !== 1 || all[0] !== wash[0] || wash[0].tagName !== 'DIV' || wash[0].children.length !== 0 || text.length !== 1 || text[0].tagName !== 'DIV') return fail('MENU_CONTENT_SOURCE_CHANGED');
  } else if (source.logicalUnitId === 'carousel-banner-generated-strip-content-inset') {
    if (!has('flex-row') || unit.hasAttribute('role') || unit.hasAttribute('tabindex')) return fail('CAROUSEL_STRIP_SOURCE_CHANGED');
    const text = all.filter(n => n.tagName === 'DIV' && n.classList.contains('flex-col') && n.classList.contains('flex-1'));
    if (text.length !== 1) return fail('CAROUSEL_CONTENT_SOURCE_CHANGED');
  } else {
    if (!has('flex-wrap') || all.length < 1 || all.length > 2 || !/^H[1-6]\$/.test(all[0].tagName) || (all.length === 2 && all[1].tagName !== 'DIV')) return fail('PANEL_CONTENT_SOURCE_CHANGED');
  }
  return {registryResultElement:layoutRoot, fieldUnitElement:unit, paddingSource:unit, frameSource:unit,
    authority:source.nativeAdapterId + ': audited prevalidated Example/producer route and actual generated root; CSS own padding, excluding supplied seats and wash'};
}
''';
