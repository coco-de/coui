import 'dart:convert';

import 'package:coui_web/src/util/web_constants.dart'
    show kWebLocalSurfaceMarker, kWebSurfaceMarker;

import '../model/box_observation_source_spec.dart';

/// Reference paths for the coordinator's prevalidated construction tuple.
///
/// Matching classes do not attest a constructor. The actual registry input,
/// source/variant and SSR transport must be bound before this function is used.
/// No CSS/numeric read, document search, DOM write or padding fallback occurs.
String get displayBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  if (!source || source.schemaVersion !== 1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)}) return fail('UNSUPPORTED_BOX_QUANTITY');
  const adapters = {
    'avatar-generated-frame':'avatar-generated-frame-v1',
    'code-snippet-generated-frame':'code-snippet-generated-frame-v1',
    'mockup-code-generated-frame':'mockup-code-generated-frame-v1',
    'stat-generated-frame':'stat-generated-frame-v1',
    'validation-badge-generated-frame':'validation-badge-generated-frame-v1'
  };
  const adapter = adapters[source.logicalUnitId];
  if (!adapter) return fail('UNREGISTERED_DISPLAY_CONSTRUCTION');
  if (source.nativeAdapterId !== adapter || source.webAdapterId !== adapter) return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!layoutRoot) return fail('MISSING_DISPLAY_LAYOUT_ROOT');
  const capture = layoutRoot.parentElement;
  if (!capture || !capture.hasAttribute('data-parity-key') || capture.children.length !== 1 || capture.children[0] !== layoutRoot) return fail('MISMATCHED_DISPLAY_CAPTURE_ROOT');
  const classes = (node, names) => node && names.every(name => node.classList.contains(name));
  const outlined = node => node && node.tagName === 'DIV' && ${jsonEncode([kWebSurfaceMarker, kWebLocalSurfaceMarker])}.some(name => node.classList.contains(name));
  const onlyDiv = node => node && node.children.length === 1 && node.children[0].tagName === 'DIV' ? node.children[0] : null;
  let frame = layoutRoot, padding = layoutRoot, authority;
  switch (adapter) {
    case 'avatar-generated-frame-v1':
      if (!outlined(layoutRoot) || !classes(layoutRoot,['inline-flex','items-center','justify-center'])) return fail('AVATAR_DECLARED_FRAME_CHANGED');
      authority = 'Avatar default/rounded no-ring/no-badge root OutlinedContainer; child/badge descendants excluded';
      break;
    case 'code-snippet-generated-frame-v1':
      if (!outlined(layoutRoot)) return fail('CODE_SNIPPET_DECLARED_FRAME_CHANGED');
      const content = onlyDiv(layoutRoot);
      if (!content || content.children.length < 1 || content.children[0].tagName !== 'PRE') return fail('CODE_SNIPPET_CONTENT_BOUNDARY_CHANGED');
      authority = 'CodeSnippet default own Outlined root; content wrapper/pre/gutter/actions are not root inset owners';
      break;
    case 'mockup-code-generated-frame-v1':
      if (layoutRoot.tagName !== 'DIV' || !classes(layoutRoot,['w-full'])) return fail('MOCKUP_CODE_WRAPPER_CHANGED');
      frame = onlyDiv(layoutRoot);
      padding = onlyDiv(frame);
      if (!outlined(frame) || !padding) return fail('MOCKUP_CODE_SPLIT_SOURCE_CHANGED');
      authority = 'MockupCode wrapper -> Outlined frame -> direct body inset source; split quantity pairing pending, not same-owner eligibility';
      break;
    case 'stat-generated-frame-v1':
      if (!outlined(layoutRoot) || !classes(layoutRoot,['w-full'])) return fail('STAT_DECLARED_FRAME_CHANGED');
      if (!onlyDiv(layoutRoot)) return fail('STAT_CONTENT_BOUNDARY_CHANGED');
      authority = 'Stat default/outlined/empty own Outlined root; supplied icon and generated cells excluded';
      break;
    case 'validation-badge-generated-frame-v1':
      if (layoutRoot.tagName !== 'SPAN' || layoutRoot.getAttribute('role') !== 'status' || layoutRoot.children.length !== 2 || layoutRoot.children[1].tagName !== 'SPAN') return fail('VALIDATION_BADGE_DECLARED_FRAME_CHANGED');
      authority = 'ValidationBadge status span own chip; icon and label are content';
      break;
    default: return fail('UNREGISTERED_DISPLAY_CONSTRUCTION');
  }
  return {registryResultElement:layoutRoot, fieldUnitElement:layoutRoot,
    paddingSource:padding, frameSource:frame, authority};
}
''';
