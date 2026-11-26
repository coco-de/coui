import 'dart:convert';

import '../model/box_observation_source_spec.dart';

/// Source references only, evaluated inside the coordinator's single task.
/// No CSS, layout numeric values, global document queries or DOM writes.
String get documentationBoxSourceResolverScript =>
    '''
(layoutRoot, source) => {
  const fail = error => ({error});
  if (!source || source.schemaVersion !== 1) return fail('UNSUPPORTED_BOX_SOURCE_VERSION');
  if (source.quantityId !== ${jsonEncode(BoxObservationSourceSpec.quantity)}) return fail('UNSUPPORTED_BOX_QUANTITY');
  if (!layoutRoot || !layoutRoot.classList) return fail('MISSING_DOCUMENTATION_UNIT');
  if (source.logicalUnitId === 'documentation-size-preview-frame') {
    if (source.nativeAdapterId !== 'docs-size-preview-frame-v1' || source.webAdapterId !== 'docs-size-preview-frame-v1') return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
    if (layoutRoot.tagName !== 'DIV' || !layoutRoot.classList.contains('docs-size-spec') || layoutRoot.children.length !== 2) return fail('DOCS_SIZE_SPEC_SOURCE_CHANGED');
    const preview = layoutRoot.children[0], table = layoutRoot.children[1];
    if (preview.tagName !== 'DIV' || !['docs-stage','docs-stage--hug','docs-stage--row'].every(name=>preview.classList.contains(name))) return fail('DOCS_SIZE_PREVIEW_SOURCE_CHANGED');
    if (table.tagName !== 'DIV' || !table.classList.contains('docs-table') || table.children.length !== 1 || table.children[0].tagName !== 'TABLE') return fail('DOCS_SIZE_TABLE_SOURCE_CHANGED');
    const tableSections = table.children[0].children;
    if (tableSections.length !== 2 || tableSections[0].tagName !== 'THEAD' || tableSections[1].tagName !== 'TBODY') return fail('DOCS_SIZE_TABLE_SOURCE_CHANGED');
    if (!Array.from(preview.children).every(figure=>figure.tagName==='FIGURE' && figure.classList.contains('docs-size-item') && figure.children.length && figure.children[figure.children.length-1].tagName==='FIGCAPTION')) return fail('DOCS_SIZE_PREVIEW_CONTENT_CHANGED');
    return {registryResultElement:layoutRoot, fieldUnitElement:preview, paddingSource:preview, frameSource:preview,
      authority:'buildWebSizeSpec: direct generated preview child[0]; direct table child[1] excluded; original layout root retained'};
  }
  if (source.logicalUnitId === 'registry-scene-frame') {
    if (source.nativeAdapterId !== 'docs-stage-current-container-v1' || source.webAdapterId !== 'matched-docs-stage-v1') return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
    if (layoutRoot.tagName !== 'DIV' || !layoutRoot.classList.contains('docs-stage') || layoutRoot.classList.contains('docs-stage--row')) return fail('DOCS_STAGE_SOURCE_CHANGED');
    let authority = 'buildWebDocsStage: direct docs-stage preview frame';
    if (layoutRoot.classList.contains('docs-anatomy-stage')) {
      const children = Array.from(layoutRoot.children);
      const targets = children.filter(child=>child.classList.contains('docs-anatomy-target'));
      if (targets.length !== 1 || targets[0] !== children[0] || targets[0].tagName !== 'DIV') return fail('DOCS_ANATOMY_SOURCE_CHANGED');
      const markers = children.slice(1);
      const text = layoutRoot.getAttribute('data-docs-anatomy');
      if (markers.length && typeof text !== 'string') return fail('DOCS_ANATOMY_MARKER_SOURCE_CHANGED');
      // docs-shell.js appends annotations; they never select the stage owner.
      // A marker may have no position class before placement or for a missing
      // part. Once placed, only its own declared side class is source-owned.
      const specs = typeof text === 'string' ? text.split(';').map(spec=>{
        const at = spec.lastIndexOf('@');
        const what = at < 0 ? spec : spec.slice(0, at);
        const side = (at < 0 ? '' : spec.slice(at + 1)) || (what === 'container' ? 'left' : 'top');
        return {what,side};
      }) : [];
      const used = new Set();
      for (const marker of markers) {
        if (marker.tagName !== 'SPAN' || !marker.classList.contains('docs-anatomy-marker') || marker.getAttribute('aria-hidden') !== 'true') return fail('DOCS_ANATOMY_MARKER_SOURCE_CHANGED');
        const raw = marker.getAttribute('data-index');
        const index = Number(raw);
        if (raw === null || !Number.isSafeInteger(index) || String(index) !== raw || index < 0 || index >= specs.length || !specs[index].what || used.has(index)) return fail('DOCS_ANATOMY_MARKER_SOURCE_CHANGED');
        used.add(index);
        if (Array.from(marker.classList).some(name=>name !== 'docs-anatomy-marker' && name !== 'is-' + specs[index].side)) return fail('DOCS_ANATOMY_MARKER_SOURCE_CHANGED');
      }
      authority = 'buildWebAnatomyStage: exact direct target plus docs-shell.js spec-indexed annotation siblings; same stage owner';
    } else if (layoutRoot.classList.contains('docs-stage--compact')) {
      authority = 'buildWebDocsStage(compact:true): direct VariantRow docs-stage';
    }
    return {registryResultElement:layoutRoot, fieldUnitElement:layoutRoot, paddingSource:layoutRoot, frameSource:layoutRoot, authority};
  }
  if (source.logicalUnitId !== 'whole-documentation-card' || source.nativeAdapterId !== 'whole-doc-card-frame-v1' || source.webAdapterId !== 'whole-doc-card-frame-v1') return fail('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  const group = layoutRoot.parentElement;
  if (!layoutRoot.classList.contains('docs-card') || !group || !group.classList.contains('docs-cards')) return fail('DOCS_CARD_DIRECT_GROUP_CHANGED');
  if (group.children.length !== 1 || group.children[0] !== layoutRoot) return fail('DOCS_CARD_CARDINALITY_CHANGED');
  if (layoutRoot.tagName !== 'DIV' && layoutRoot.tagName !== 'A') return fail('DOCS_CARD_HREF_BRANCH_CHANGED');
  if ((layoutRoot.tagName === 'A') !== layoutRoot.hasAttribute('href')) return fail('DOCS_CARD_HREF_BRANCH_CHANGED');
  return {registryResultElement:group, fieldUnitElement:layoutRoot, paddingSource:layoutRoot, frameSource:layoutRoot,
    authority:'DocsScene Card/whole-card/cardIndex0; buildWebStandaloneDocsCard -> direct docs-cards > docs-card ' + layoutRoot.tagName};
}
''';
