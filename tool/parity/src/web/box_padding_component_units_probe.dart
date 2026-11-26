import 'dart:convert';

import 'package:coui_web/src/util/web_constants.dart'
    show kWebLocalSurfaceMarker, kWebSurfaceMarker;

import '../model/box_observation_source_spec.dart';

/// Source references for six audited registry construction recipes only.
///
/// The closed descriptor and actual generated input are the provenance
/// boundary; DOM tags/classes alone do not authenticate a constructor. This
/// resolver performs no CSS/numeric reads, global searches or DOM writes.
String get componentBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  if (!source || source.schemaVersion !== 1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)}) return fail('UNSUPPORTED_BOX_QUANTITY');
  const adapters = {
    'code-diff-generated-frame':'code-diff-generated-frame-v1',
    'command-panel-generated-frame':'command-panel-generated-frame-v1',
    'fieldset-generated-frame':'fieldset-generated-frame-v1',
    'item-picker-generated-frame':'item-picker-generated-frame-v1',
    'mockup-browser-generated-frame':'mockup-browser-generated-frame-v1',
    'object-input-generated-frame':'object-input-generated-frame-v1'
  };
  const adapter = adapters[source.logicalUnitId];
  if (!adapter) return fail('UNREGISTERED_COMPONENT_CONSTRUCTION');
  if (source.nativeAdapterId !== adapter || source.webAdapterId !== adapter) return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot || layoutRoot.tagName !== 'DIV') return fail('COMPONENT_LAYOUT_ROOT_CHANGED');
  const capture = layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') || capture.children.length !== 1 || capture.children[0] !== layoutRoot) return fail('MISMATCHED_COMPONENT_CAPTURE_ROOT');
  const onlyDiv = node => node.children.length === 1 && node.children[0].tagName === 'DIV' ? node.children[0] : null;
  const classes = (node, names) => node && names.every(name => node.classList.contains(name));
  const outlined = node => node && ${jsonEncode([kWebSurfaceMarker, kWebLocalSurfaceMarker])}.some(name => node.classList.contains(name));
  let unit, frame, authority;
  switch (adapter) {
    case 'code-diff-generated-frame-v1':
      if (!classes(layoutRoot,['w-full'])) return fail('CODE_DIFF_WIDTH_WRAPPER_CHANGED');
      frame = onlyDiv(layoutRoot);
      if (!outlined(frame)) return fail('CODE_DIFF_DECLARED_FRAME_CHANGED');
      unit = frame;
      authority = 'registry width wrapper -> CodeDiffDefaultExample -> CodeDiff composed Outlined root';
      break;
    case 'command-panel-generated-frame-v1':
      if (layoutRoot.getAttribute('role') !== 'combobox' || !classes(layoutRoot,['flex','flex-col'])) return fail('COMMAND_PANEL_SOURCE_CHANGED');
      unit = frame = layoutRoot;
      authority = 'Command default/scrollable/empty example -> Command root div; closed dialog excluded';
      break;
    case 'fieldset-generated-frame-v1':
      frame = onlyDiv(layoutRoot);
      if (!classes(frame,['flex','flex-col','items-stretch','border'])) return fail('FIELDSET_DECLARED_FRAME_CHANGED');
      unit = frame;
      authority = 'Fieldset default/outlined/plain example width wrapper -> Fieldset root div';
      break;
    case 'item-picker-generated-frame-v1':
      if (!classes(layoutRoot,['flex','flex-col','border'])) return fail('ITEM_PICKER_PANEL_SOURCE_CHANGED');
      unit = frame = layoutRoot;
      authority = 'ItemPickerDefaultExample -> ItemPicker root div; title/items/options excluded';
      break;
    case 'mockup-browser-generated-frame-v1':
      unit = onlyDiv(layoutRoot);
      if (!classes(unit,['w-full','h-full'])) return fail('MOCKUP_BROWSER_COMPONENT_ROOT_CHANGED');
      frame = onlyDiv(unit);
      if (!outlined(frame)) return fail('MOCKUP_BROWSER_DECLARED_FRAME_CHANGED');
      authority = 'MockupBrowserExample sizing div -> MockupBrowser root -> composed Outlined frame';
      break;
    case 'object-input-generated-frame-v1':
      if (!classes(layoutRoot,['inline-flex','items-center'])) return fail('OBJECT_INPUT_PANEL_SOURCE_CHANGED');
      unit = frame = layoutRoot;
      authority = 'ObjectInputDefaultExample -> ObjectInput root div; fields and separator excluded';
      break;
    default: return fail('UNSUPPORTED_COMPONENT_BOX_ADAPTER');
  }
  return {registryResultElement:layoutRoot, fieldUnitElement:unit,
    paddingSource:frame, frameSource:frame, authority};
}
''';
