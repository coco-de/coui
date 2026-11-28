'use strict';
// Authored, UNEXECUTED controls. Each gets a fresh PROVIDED original normal
// canonical fixture. No positive DOM, receipt, marker or source input is built
// here. The future harness must retain source-indexed body/header provenance,
// run only original docs-shell.js normally, and supply its actual direct nodes.
const assert = require('node:assert/strict');
const requireHealthy = c => {
  const result = c.bind(c.request);
  assert.equal(result.applied, true, result.error);
  assert.equal(result.paddingSource, c.stage);
  assert.equal(result.frameSource, c.stage);
  assert.equal(result.fieldUnitElement, c.stage);
  assert.equal(result.registryResultElement, c.stage);
  assert.equal(result.registryIsLayoutRoot, true);
  assert.equal(result.validateCurrentBinding(), true);
  return result;
};
const requireMarker = c => {
  assert(c.markers.length > 0, 'PROVIDED_NORMAL_ROUTE_DIRECT_MARKER_REQUIRED');
  assert.equal(c.markers[0].parentNode, c.stage);
  return c.markers[0];
};
const reject = (name, mutation, expected) => ({
  name, kind: 'negative-before-CSS', run(c) {
    mutation(c);
    const result = c.bind(c.request);
    assert.equal(result.applied, undefined);
    assert.equal(result.error, expected);
    assert.equal(c.bindingCssReads(), 0);
    assert.equal(c.bindingGeometryReads(), 0);
  }
});
const jointAttr = (target, field, value) => c => {
  c[target].setAttribute(field, value);
  c[target + 'Record'].attributes[field] = value;
};
const grammar = 'DOCS_ANATOMY_EXACT_FACTORY_OWNED_GRAMMAR_CHANGED';
const current = 'DOCS_ANATOMY_EXACT_NORMAL_OWNED_TREE_CHANGED';
const jointKey=(c,key)=>{
 c.request.documentationSceneRoute.entryKey=key;c.request.currentSsrSource.entryKey=key;
 c.capture.setAttribute('data-parity-key',key);c.captureRecord.attributes['data-parity-key']=key;
};
const before = [
  reject('annotation NBSP is not an HTML class separator', c => {
    const n=requireMarker(c),index=Number(n.getAttribute('data-index'));
    const spec=c.request.currentSsrSource.currentRaw.originalSceneInput.anatomyParts[index];
    const at=spec.lastIndexOf('@'),what=at<0?spec:spec.slice(0,at),side=(at<0?'':spec.slice(at+1))||(what==='container'?'left':'top');
    n.setAttribute('class','docs-anatomy-marker\u00a0is-'+side);
  }, current),
  reject('annotation vertical-tab is not an HTML class separator', c => {
    const n=requireMarker(c),index=Number(n.getAttribute('data-index'));
    const spec=c.request.currentSsrSource.currentRaw.originalSceneInput.anatomyParts[index];
    const at=spec.lastIndexOf('@'),what=at<0?spec:spec.slice(0,at),side=(at<0?'':spec.slice(at+1))||(what==='container'?'left':'top');
    n.setAttribute('class','docs-anatomy-marker\u000bis-'+side);
  }, current),
  reject('joint stage padding', jointAttr('stage', 'style', 'padding: 91px'), grammar),
  reject('joint stage id', jointAttr('stage', 'id', 'forged-stage'), grammar),
  reject('joint target padding', jointAttr('target', 'style', 'padding: 91px'), grammar),
  reject('joint target id', jointAttr('target', 'id', 'forged-target'), grammar),
  reject('joint target extra class', jointAttr('target', 'class', 'docs-anatomy-target extra'), grammar),
  reject('missing required target', c => {
    c.target.remove(); c.stageRecord.children = [];
  }, grammar),
  reject('joint extra owned target wrapper', c => {
    // Explicit negative mutation, never a manufactured healthy body.
    const wrapper = c.document.createElement('div');
    c.target.replaceWith(wrapper); wrapper.append(c.target);
    const at = c.stageRecord.children.indexOf(c.targetRecord);
    assert(at >= 0, 'SOURCE_OWNED_TARGET_REQUIRED');
    c.stageRecord.children[at] = {nodeType:1,namespaceURI:'http://www.w3.org/1999/xhtml',
      localName:'div',attributes:{},children:[c.targetRecord]};
  }, grammar),
  reject('annotation duplicate index', c => {
    assert(c.markers.length >= 2, 'PROVIDED_NORMAL_ROUTE_TWO_MARKERS_REQUIRED');
    c.markers[1].setAttribute('data-index', c.markers[0].getAttribute('data-index'));
  }, current),
  reject('annotation out-of-range index', c => {
    requireMarker(c).setAttribute('data-index', String(c.request.currentSsrSource.currentRaw.originalSceneInput.anatomyParts.length));
  }, current),
  reject('annotation noncanonical index', c => {
    const marker = requireMarker(c); marker.setAttribute('data-index', '0' + marker.getAttribute('data-index'));
  }, current),
  reject('annotation foreign side class', c => {
    requireMarker(c).setAttribute('class', 'docs-anatomy-marker is-foreign');
  }, current),
  reject('annotation own layout style', c => {
    requireMarker(c).setAttribute('style', 'position: static; padding: 91px');
  }, current),
  reject('annotation id', c => { requireMarker(c).setAttribute('id', 'forged'); }, current),
  reject('extra immediate nonmarker child', c => {
    c.stage.append(c.document.createElement('div'));
  }, current),
  reject('nonformatter owned stage text', c => {
    const record = c.stageRecord.children.findLast(n => Object.hasOwn(n, 'ownedText'));
    assert(record, 'ACTUAL_TRAILING_FORMATTER_REQUIRED');
    const at = c.stageRecord.children.indexOf(record);
    record.ownedText = 'forged-owned-text'; c.stage.childNodes[at].data = record.ownedText;
  }, grammar),
  reject('joint foreign component key', c => jointKey(c,'foreign-component-'+c.request.currentSsrSource.currentRaw.sceneReference+'-light-defaultStyle'), 'DOCS_ANATOMY_CANONICAL_ENTRY_KEY_REQUIRED'),
  reject('joint foreign theme key', c => jointKey(c,c.request.documentationSceneRoute.entryKey.replace(/-(light|dark)-defaultStyle$/,'-sepia-defaultStyle')), 'DOCS_ANATOMY_CANONICAL_ENTRY_KEY_REQUIRED'),
  reject('joint foreign surface-style key', c => jointKey(c,c.request.documentationSceneRoute.entryKey.replace(/-defaultStyle$/,'-neumorphism')), 'DOCS_ANATOMY_CANONICAL_ENTRY_KEY_REQUIRED'),
  reject('joint prefixed noncanonical key', c => jointKey(c,'foreign-'+c.request.documentationSceneRoute.entryKey), 'DOCS_ANATOMY_CANONICAL_ENTRY_KEY_REQUIRED'),
  reject('joint suffixed noncanonical key', c => jointKey(c,c.request.documentationSceneRoute.entryKey+'-foreign'), 'DOCS_ANATOMY_CANONICAL_ENTRY_KEY_REQUIRED'),
  reject('wrong scene route', c => {
    c.request.documentationSceneRoute.sceneReference = 'docs-v2-' + '0'.repeat(32);
  }, 'DOCS_ANATOMY_COMPLETE_SOURCE_CHANGED'),
  reject('foreign adapter', c => {
    c.request.source.webAdapterId = 'foreign-owned-quantity';
  }, 'DOCS_ANATOMY_TUPLE_CHANGED')
];
const positives = [
  {name:'real original canonical normal completion', run(c) {
    requireHealthy(c);
    assert.equal(c.originalBuildCount(), 1);
    assert.equal(c.extraObserverBuilderCalls(), 0);
    assert.equal(c.extraObserverAnnotationCalls(), 0);
    assert.equal(c.bindingCssReads(), 0);
    assert.equal(c.bindingGeometryReads(), 0);
  }},
  {name:'opaque preview and legend interiors are not authority', run(c) {
    const held = requireHealthy(c);
    for (const node of [...c.previewRoots, ...c.legendRoots]) {
      if (node.nodeType === 1) node.append(c.document.createTextNode('opaque test-only mutation'));
    }
    assert.equal(held.validateCurrentBinding(), true);
  }},
  {name:'annotation interior is opaque', run(c) {
    const marker = requireMarker(c),held = requireHealthy(c);
    marker.append(c.document.createTextNode('opaque test-only annotation mutation'));
    assert.equal(held.validateCurrentBinding(), true);
  }},
  {name:'current left/top values do not supply expected geometry', run(c) {
    // Explicit fixture-only mutation BEFORE the binding baseline; the actual
    // original marker node remains the decoration. No owner or body is created.
    const marker = requireMarker(c);
    marker.setAttribute('style', 'left: -123.5px; top: 987.25px;');
    requireHealthy(c);
  }},
  {name:'canonical request ignores poisoned source', run(c) {
    const poison = new Proxy({}, {get() {throw Error('UNREQUESTED_SOURCE_READ');},ownKeys() {throw Error('UNREQUESTED_SOURCE_READ');}});
    const result = c.bind({requested:false,currentSsrSource:poison,source:poison});
    assert.deepEqual(result, {applied:false});
  }}
];
const heldMutations = [
  ['route extra field', c => {c.request.documentationSceneRoute.extra='forged';}],
  ['route tag value', c => {c.request.documentationSceneRoute.sceneTag='Preview';}],
  ['stage attr', c => c.stage.setAttribute('style','padding: 91px')],
  ['target attr', c => c.target.setAttribute('style','padding: 91px')],
  ['target detach', c => c.target.remove()],
  ['target same-shape replacement', c => c.target.replaceWith(c.target.cloneNode(true))],
  ['held annotation relocation into target', c => c.target.append(requireMarker(c))],
  ['held annotation detach', c => requireMarker(c).remove()],
  ['held annotation same-shape replacement', c => {const n=requireMarker(c);n.replaceWith(n.cloneNode(true));}],
  ['held annotation reorder', c => {assert(c.markers.length>=2);c.stage.insertBefore(c.markers[1],c.markers[0]);}],
  ['receipt clone', c => {c.request.currentSsrSource=JSON.parse(JSON.stringify(c.request.currentSsrSource));}]
];
const after = heldMutations.map(([name,mutate]) => ({name,kind:'held-negative',run(c) {
  const result=requireHealthy(c); mutate(c); assert.equal(result.validateCurrentBinding(),false);
}}));
const phases = ['legacy','own'].flatMap(phase => heldMutations.map(([name,mutate]) => ({
  name:phase+' CSS: '+name,kind:'real-phase-negative',async run(c) {
    // The future harness invokes the ACTUAL production combined/own sampler
    // and mutates during its real own-box getComputedStyle call. A stub after
    // the sampler or a new observer CSS callback does not qualify this control.
    const result=await c.runActualPhaseMutation(phase,()=>mutate(c));
    assert.equal(result.mutationApplied,true);
    assert.equal(result.sourceBindingRejected,true);
  }
})));
module.exports={before,positives,after,phases};
