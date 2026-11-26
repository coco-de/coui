import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// References only under the coordinator's prevalidated actual operation.
/// Existing host attributes/payload are authority; classes alone are not.
String get documentationPlaygroundBoxSourceResolverScript =>
    '''
(layoutRoot, source, operation) => {
  const fail = error => ({error});
  if (!source || source.schemaVersion !== 1 || source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)} || source.logicalUnitId !== 'documentation-playground-stage' || source.nativeAdapterId !== 'docs-playground-stage-frame-v1' || source.webAdapterId !== 'docs-playground-stage-frame-v1') return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  if (!operation || !operation.authority || !operation.payloadAuthority || !operation.payload) return fail('MISSING_PLAYGROUND_OPERATION');
  const {entryKey,component,variant,authority,payloadAuthority,payload,entryRoot,sceneHost,registryRoot} = operation;
  if (!entryKey || !component || typeof variant !== 'string' || !/^docs-v2-[0-9a-f]{32}\$/.test(variant) || authority.tag !== 'Playground' || authority.component !== component || authority.reference !== variant || payload.key !== entryKey || payload.component !== component || payload.variant !== variant || !payload.scene || payload.scene.tag !== 'Playground') return fail('PLAYGROUND_OPERATION_VALUE_MISMATCH');
  if (!authority.documentPath || !['documentSha256','sourceClosureSha256','manifestSha256','sceneValueSha256'].every(name=>typeof authority[name]==='string' && /^[0-9a-f]{64}\$/.test(authority[name]))) return fail('INVALID_SCENE_VALUE_AUTHORITY');
  if (!['component','reference','tag','documentPath','documentSha256','sourceClosureSha256','manifestSha256','sceneValueSha256'].every(name=>payloadAuthority[name] === authority[name])) return fail('PLAYGROUND_PAYLOAD_AUTHORITY_CHANGED');
  if (!entryRoot || !sceneHost || !registryRoot || entryRoot.getAttribute('data-parity-key') !== entryKey || entryRoot.getAttribute('data-parity-client-key') !== entryKey || sceneHost.getAttribute('data-docs-scene') !== variant || !entryRoot.contains(sceneHost) || !sceneHost.contains(registryRoot) || !registryRoot.contains(layoutRoot)) return fail('PLAYGROUND_OPERATION_HOST_MISMATCH');
  const content = registryRoot.parentElement;
  if (registryRoot.tagName !== 'DIV' || !registryRoot.classList.contains('docs-playground') || !content || !content.classList.contains('content') || content.parentElement !== sceneHost) return fail('PLAYGROUND_REGISTRY_ROOT_CHANGED');
  if (!layoutRoot || layoutRoot.tagName !== 'DIV' || !layoutRoot.classList.contains('docs-playground-stage') || layoutRoot.children.length !== 2) return fail('PLAYGROUND_STAGE_SOURCE_CHANGED');
  const [platforms,panes] = layoutRoot.children;
  if (!platforms.classList.contains('docs-playground-platforms') || !panes.classList.contains('docs-playground-panes') || panes.classList.contains('is-both') || panes.children.length !== 1) return fail('PLAYGROUND_PANE_SOURCE_CHANGED');
  const pane = panes.children[0];
  if (!pane.classList.contains('docs-playground-pane') || pane.classList.contains('is-flutter') || pane.classList.contains('is-hidden')) return fail('PLAYGROUND_PANE_SOURCE_CHANGED');
  const main = layoutRoot.parentElement, inner = main?.parentElement;
  if (!main || !inner || !main.classList.contains('docs-playground-main') || !inner.classList.contains('docs-playground-inner') || inner.children.length !== 1 || inner.children[0] !== main || main.children[0] !== layoutRoot) return fail('PLAYGROUND_VIEW_SOURCE_CHANGED');
  if (main.classList.contains('is-bare') ? main.children.length !== 1 : main.children.length !== 2 || !main.children[1].classList.contains('docs-playground-controls')) return fail('PLAYGROUND_VIEW_SOURCE_CHANGED');
  return {registryResultElement:registryRoot,fieldUnitElement:layoutRoot,paddingSource:layoutRoot,frameSource:layoutRoot,
    authority:'Existing runtime entry/client/scene host and frozen source-derived payload; renderWebScene single-Web-pane stage; CSS read remains coordinator-owned'};
}
''';
