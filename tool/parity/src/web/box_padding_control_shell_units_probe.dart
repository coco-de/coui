import 'dart:convert';

import 'package:coui_web/src/components/display/chip/chip_style.dart'
    show kChipBodyMarker;
import 'package:coui_web/src/util/web_constants.dart'
    show kWebTouchTargetMarker;

import '../model/box_observation_source_spec.dart';

/// Source references only, under the coordinator's validated entry/input.
///
/// Local shape/markers do not authenticate a constructor. No CSS, layout number,
/// expected value, global query, callback or DOM mutation is consulted here.
String get controlShellBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  if (!source || source.schemaVersion !== 1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  const adapters = {
    'number-input-generated-field-frame':'number-input-generated-field-frame-v1',
    'chip-generated-frame':'chip-generated-frame-v1'
  };
  const adapter = adapters[source.logicalUnitId];
  if (!adapter) return fail('UNREGISTERED_CONTROL_SHELL_SOURCE');
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)} ||
      source.nativeAdapterId !== adapter || source.webAdapterId !== adapter)
    return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot || layoutRoot.tagName !== 'DIV') return fail('CONTROL_SHELL_SOURCE_CHANGED');
  const capture = layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length !== 1 || capture.children[0] !== layoutRoot)
    return fail('MISMATCHED_COMPONENT_CAPTURE_ROOT');
  const all = root => [root,...Array.from(root.children).flatMap(all)];
  let frame, authority;
  if (adapter === 'number-input-generated-field-frame-v1') {
    if (layoutRoot.children.length !== 1 || layoutRoot.children[0].tagName !== 'DIV')
      return fail('NUMBER_INPUT_FIELD_ROOT_CHANGED');
    const field = layoutRoot.children[0];
    const inputs = all(field).filter(node => node.tagName === 'INPUT');
    if (inputs.length !== 1 || inputs[0].getAttribute('type') !== 'number')
      return fail('NUMBER_INPUT_GENERATED_INPUT_CHANGED');
    const input = inputs[0];
    frame = input.parentElement;
    const outline = frame && frame.parentElement;
    if (!frame || frame.tagName !== 'DIV' || !outline || outline.tagName !== 'DIV' ||
        outline.parentElement !== field || outline.children.length !== 1 ||
        outline.children[0] !== frame || !Array.from(frame.children).includes(input))
      return fail('NUMBER_INPUT_FIELD_FRAME_CHANGED');
    const fieldCells = Array.from(field.children);
    if (fieldCells.filter(node => node.tagName === 'DIV').length !== 1 ||
        fieldCells.some(node => !['STYLE','LABEL','DIV','P'].includes(node.tagName)))
      return fail('NUMBER_INPUT_FIELD_CELLS_CHANGED');
    const frameCells = Array.from(frame.children);
    const inputIndex = frameCells.indexOf(input);
    if (inputIndex !== 1 || frameCells.length !== 3 ||
        frameCells[0].tagName !== 'SPAN' || frameCells[2].tagName !== 'SPAN')
      return fail('NUMBER_INPUT_STEP_SLOTS_CHANGED');
    authority = 'Audited NumberInput -> generated TextField -> FocusOutline child affix frame; label/error and step Button frames excluded';
  } else {
    if (layoutRoot.getAttribute('role') !== 'button' ||
        !layoutRoot.classList.contains(${jsonEncode(kWebTouchTargetMarker)}))
      return fail('CHIP_INTERACTIVE_ROOT_CHANGED');
    const nodes = Array.from(layoutRoot.children);
    const own = nodes.filter(node => node.tagName !== 'STYLE');
    if (own.length !== 1 || nodes.length - own.length > 1 ||
        (nodes.length > 1 && nodes[0].tagName !== 'STYLE'))
      return fail('CHIP_GENERATED_BODY_CHANGED');
    frame = own[0];
    if (frame.tagName !== 'DIV' || !frame.classList.contains(${jsonEncode(kChipBodyMarker)}))
      return fail('CHIP_GENERATED_BODY_CHANGED');
    authority = 'Audited interactive Chip -> existing Clickable direct child own chip body; supplied content/close Button descendants excluded';
  }
  return {registryResultElement:layoutRoot, fieldUnitElement:frame,
    paddingSource:frame, frameSource:frame, authority};
}
''';
