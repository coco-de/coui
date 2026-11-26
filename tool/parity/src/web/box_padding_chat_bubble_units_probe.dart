import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// References only, for the coordinator's closed eight Example tuples.
/// The tuple/source preparation, not DOM class shape, authenticates creation.
/// No CSS/numeric reads, document search, callbacks or value fallbacks.
String get chatBubbleBoxSourceResolverScript =>
    '''
(layoutRoot,source) => {
  const fail=error=>({error});
  if (!source || source.schemaVersion!==1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  if (source.quantityId!==${jsonEncode(BoxObservationSourceSpec.quantity)}) return fail('UNSUPPORTED_BOX_QUANTITY');
  if (source.logicalUnitId!=='documentation-chat-single-bubble-frame' ||
      source.nativeAdapterId!=='docs-chat-single-bubble-frame-v1' ||
      source.webAdapterId!=='docs-chat-single-bubble-frame-v1') return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot) return fail('MISSING_CHAT_EXAMPLE_ROOT');
  const capture=layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') ||
      capture.children.length!==1 || capture.children[0]!==layoutRoot)
    return fail('MISMATCHED_CHAT_EXAMPLE_CAPTURE');
  const has=(node,...names)=>node && names.every(name=>node.classList.contains(name));
  if (layoutRoot.tagName!=='DIV' || !has(layoutRoot,'flex','w-full','justify-start') ||
      layoutRoot.children.length!==1) return fail('CHAT_SINGLE_EXAMPLE_CHANGED');
  const column=layoutRoot.children[0];
  if (column.tagName!=='DIV' || !has(column,'flex','flex-col','w-full','items-start','min-w-0') ||
      column.children.length!==1) return fail('CHAT_SINGLE_COLUMN_CHANGED');
  const body=column.children[0];
  if (body.tagName!=='DIV' || !has(body,'inline-block','relative') ||
      body.children.length!==1 || body.children[0].tagName!=='SPAN')
    return fail('CHAT_BUBBLE_NO_TAIL_BODY_CHANGED');
  return {registryResultElement:layoutRoot,fieldUnitElement:body,
    paddingSource:body,frameSource:body,
    authority:'Exact prevalidated parameterless Example creates single Chat.bubble; direct body owns CSS padding, its child stays foreign; not row/whole-scene/tail spacing'};
}
''';
