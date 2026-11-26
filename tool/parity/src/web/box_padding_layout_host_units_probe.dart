import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Refs for the closed, independently prevalidated construction operations.
/// DOM shape is a route guard, not independent constructor attestation.
String get layoutHostBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  const specs = ${jsonEncode(BoxObservationSourceSpec.layoutHostFrames.map((s) => s.toJson()).toList())};
  const expected = specs.find(s => s.logicalUnitId === source?.logicalUnitId);
  if (!expected || Object.keys(expected).some(k => source[k] !== expected[k]))
    return fail('LAYOUT_HOST_TUPLE_CHANGED');
  const capture = layoutRoot?.parentElement;
  if (!layoutRoot || layoutRoot.tagName !== 'DIV' || !capture ||
      !capture.hasAttribute('data-parity-key') || capture.children.length !== 1 ||
      capture.children[0] !== layoutRoot) return fail('LAYOUT_HOST_CAPTURE_CHANGED');
  const children = node => Array.from(node.children);
  const interactionChild = node => {
    const all = children(node);
    const content = all.filter(n => n.tagName !== 'STYLE');
    if (node.tagName !== 'DIV' || node.getAttribute('role') !== 'button' ||
        content.length !== 1 || all.length > 2 ||
        (all.length === 2 && all[0].tagName !== 'STYLE')) return null;
    return content[0];
  };
  let field = layoutRoot;
  switch(source.logicalUnitId) {
    case 'steps-generated-sequence-host': {
      if (!field.classList.contains('flex')) {
        if (field.children.length !== 1 || field.children[0].getAttribute('role') !== 'list')
          return fail('STEPS_WIDTH_WRAPPER_CHANGED');
        field = field.children[0];
      }
      if (field.tagName !== 'DIV' || !field.classList.contains('flex') ||
          field.children.length === 0) return fail('STEPS_HOST_CHANGED');
      if (field.getAttribute('role') === 'list' &&
          children(field).some(n => n.getAttribute('role') !== 'listitem'))
        return fail('STEPS_LIST_SLOTS_CHANGED');
      break;
    }
    case 'stepper-vertical-sequence-host':
      if (!field.classList.contains('flex') || !field.classList.contains('flex-col') ||
          field.children.length === 0) return fail('STEPPER_VERTICAL_CHANGED');
      break;
    case 'aspect-ratio-generated-layout-host': {
      if (field.children.length !== 1 || field.children[0].tagName !== 'DIV')
        return fail('ASPECT_EXAMPLE_WRAPPER_CHANGED');
      field = field.children[0];
      const cells = children(field);
      if (!field.classList.contains('relative') || cells.length !== 2 ||
          cells.some(n => n.tagName !== 'DIV') || cells[0].children.length !== 0 ||
          !cells[1].classList.contains('absolute') || cells[1].children.length !== 1)
        return fail('ASPECT_SOURCE_CHANGED');
      break;
    }
    case 'clickable-generated-interaction-host':
      if (!interactionChild(field)) return fail('CLICKABLE_SOURCE_CHANGED');
      break;
    case 'focus-outline-generated-pass-through-host':
      if (field.children.length !== 1) return fail('FOCUS_FLOW_SOURCE_CHANGED');
      break;
    case 'switch-field-generated-control-row': {
      const row = interactionChild(field);
      if (!row || row.tagName !== 'DIV' || !row.classList.contains('flex') ||
          row.children.length !== 3 || row.children[0].tagName !== 'DIV' ||
          row.children[2].tagName !== 'DIV' || row.children[2].children.length !== 1)
        return fail('SWITCH_ROW_SOURCE_CHANGED');
      field = row;
      break;
    }
    default: return fail('LAYOUT_HOST_UNKNOWN');
  }
  return {registryResultElement:layoutRoot,fieldUnitElement:field,
    paddingSource:field,frameSource:field,
    authority:source.logicalUnitId + ': actual prevalidated source route; own host parameter only; foreign content and paint excluded'};
}
''';
