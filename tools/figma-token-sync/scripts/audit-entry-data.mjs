#!/usr/bin/env node
// Bounded safety audit. Runs real graphs/recipes/builders in temporary copies;
// reports existing shared-JSON omissions, and rejects any NEW omission/output
// difference from the structural refactor. It never changes the hash algorithm.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { withTree, probe, changed } from './measure-entry-dependencies.mjs';

const current = process.cwd();
const before = path.resolve(process.argv[2]);
const output = path.resolve(process.argv[3] ?? 'entry-data-audit');
fs.mkdirSync(output, { recursive: true });
const prefixes = ['typography', 'surfaceGlass', 'components.form_label', 'components.button', 'components.popup', 'components.chip'];
const scenarios = [
  { name: 'top-level typography data', prefix: 'typography', paths: ['typography.bodyMedium.letterSpacing'], edit: j => { j.typography.bodyMedium.letterSpacing += 0.01; } },
  { name: 'top-level surfaceGlass data', prefix: 'surfaceGlass', paths: ['surfaceGlass.refraction'], edit: j => { j.surfaceGlass.refraction = 0.7; } },
  { name: 'cross-read FormLabel data', prefix: 'components.form_label', paths: ['components.form_label.constants.size.choice'], edit: j => { j.components.form_label.constants.size.choice = 'lg'; } },
  { name: 'cross-read Button data', prefix: 'components.button', paths: ['components.button.variants.defaultsByVariant.plain.foregroundColor.ref'], edit: j => { j.components.button.variants.defaultsByVariant.plain.foregroundColor.ref = 'Semantic/color/error'; } },
  { name: 'cross-read Popup data', prefix: 'components.popup', paths: ['components.popup.fields.padding', 'components.popup.constants.contentPadding'], edit: j => {
    for (const insets of [j.components.popup.fields.padding, j.components.popup.constants.contentPadding]) {
      for (const side of Object.keys(insets)) insets[side] = { v: 20, ref: 'Primitives/space/20', via: 'CoreSpace.space20' };
    }
  } },
  { name: 'cross-read Chip data', prefix: 'components.chip', paths: ['components.chip.variants.defaultsByColor.neutral.lowUnselectedFg.ref'], edit: j => { j.components.chip.variants.defaultsByColor.neutral.lowUnselectedFg.ref = 'Semantic/color/error'; } },
];

async function capture(root, name) {
  const target = path.join(output, name + '.json');
  const script = fileURLToPath(new URL('./builder-runtime-artifact.mjs', import.meta.url));
  execFileSync(process.execPath, [script, root, target], { cwd: current, env: { ...process.env, COUI_TRACE_DATA_PREFIXES: JSON.stringify(prefixes) }, maxBuffer: 16 * 1024 * 1024 });
  return JSON.parse(fs.readFileSync(target, 'utf8'));
}
const ownsData = (entry, slug) => (entry.dataSlug ?? entry.name.replace(/([a-z0-9])([A-Z])/g, '$1_$2').toLowerCase()) === slug || entry.fixture?.dataFrom?.includes(slug);
function namedImports(root, mod) {
  const text = fs.readFileSync(path.join(root, mod), 'utf8'), imports = [];
  for (const m of text.matchAll(/import\s*\{([^}]*)\}\s*from\s*['"]([^'"]+)['"]/g)) {
    const target = path.posix.normalize(path.posix.join(path.posix.dirname(mod), m[2])) + '.ts';
    const names = m[1].split(',').map(s => s.trim().replace(/^type\s+/, '').split(/\s+as\s+/)[0]);
    imports.push({ target, names });
  }
  return imports;
}
// Exact old edges and the values they imported. This is an audit of concrete
// evidence, not a production allowlist or a per-symbol dependency compiler.
const edges = [
  ['overlay', 'primitives-chrome', ['elevationLayers', 'hidePopupContent', 'kPopupContentSlotName', 'popupInstance', 'popupPaddingOverride']],
  ['display-data', 'overlay', ['kPlainButtonForeground']],
  ['form-fields', 'display-data', ['forwardChipCloseBox', 'kChipPrefixLabelName']],
  ['form', 'form-fields', ['formLabelSizeCells']],
  ['form-controls', 'primitives-chrome', ['elevationLayers', 'hidePopupContent', 'popupInstance']],
  ['form-controls', 'form', ['caretLineBox', 'kToggleTrackName', 'statedRadius']],
  ['form-controls', 'overlay', ['bindLayoutBound', 'boundOrNull', 'setInstanceLabel']],
  ['form-controls', 'form-pickers', ['setFieldValue']],
  ['primitives-layout', 'primitives-chrome', ['clipsFor', 'elevationLayers']],
  ['display', 'primitives-chrome', ['clipsFor', 'elevationLayers']],
  ['navigation', 'primitives-chrome', ['popupInstance', 'popupPaddingOverride']],
];
const destinations = {
  elevationLayers: 'container-chrome', clipsFor: 'container-chrome', hidePopupContent: 'popup-composition', kPopupContentSlotName: 'popup-composition', popupInstance: 'popup-composition', popupPaddingOverride: 'popup-composition',
  kPlainButtonForeground: 'button-defaults', forwardChipCloseBox: 'chip-composition', kChipPrefixLabelName: 'chip-composition', formLabelSizeCells: 'form-label-sizes', caretLineBox: 'form-drawing', kToggleTrackName: 'form-drawing', statedRadius: 'form-drawing', bindLayoutBound: 'layout-bound', boundOrNull: 'layout-bound', setInstanceLabel: 'instance-label', setFieldValue: 'field-value',
};
function closureAudit(base, prototype, baseArtifact, artifact) {
  assert.deepEqual(baseArtifact.registry, artifact.registry, 'Registry metadata/real needs changed');
  const oldPairs = edges.map(([from, to]) => `src/components/${from}.ts->src/components/${to}.ts`).sort();
  assert.deepEqual(base.crossBuilderImports.map(e => `${e.from}->${e.to}`).sort(), oldPairs, 'Old edge audit is incomplete');
  for (const [from, to, symbols] of edges) {
    const imported = namedImports(before, `src/components/${from}.ts`).find(i => i.target === `src/components/${to}.ts`);
    assert(imported, `Missing original edge ${from}->${to}`);
    assert.deepEqual(imported.names.filter(Boolean).sort(), [...symbols].sort(), `Incomplete original symbols ${from}->${to}`);
  }
  const source = fs.readFileSync(path.join(current, 'src/registry.ts'), 'utf8');
  const groupModules = Object.fromEntries([...source.matchAll(/import\s*\{([^}]*)\}\s*from\s*'\.\/components\/([\w-]+)'/g)].flatMap(m => m[1].split(',').map(k => [k.trim(), 'src/components/' + m[2] + '.ts'])));
  const movedSymbols = edges.map(([from, to, symbols]) => ({ from: 'src/components/' + from + '.ts', to: 'src/components/' + to + '.ts', symbols: symbols.map(symbol => {
    const implementation = 'src/' + destinations[symbol] + '.ts';
    const consumers = Object.entries(groupModules).filter(([, mod]) => namedImports(current, mod).some(i => i.target === implementation && i.names.includes(symbol))).map(([group]) => group);
    assert(consumers.length, `${symbol}: no actual consuming group found`);
    for (const group of consumers) assert(prototype.filesByKey[group].includes(implementation), `${symbol}: ${group} lost the lower implementation from its real source closure`);
    return { symbol, implementation, protectedGroups: consumers };
  }) }));
  for (const [label, data, art] of [['base', base, baseArtifact], ['prototype', prototype, artifact]]) {
    for (const entry of art.registry) for (const child of entry.needs ?? []) {
      assert(data.entries[child], `${label}: unknown child ${child}`);
      for (const key of data.entries[child].keys) assert(data.entries[entry.name].keys.includes(key), `${label}: ${entry.name} lost child ${child} source key ${key}`);
    }
  }
  return { oldCrossBuilderEdges: edges.length, movedSymbolOccurrences: movedSymbols.reduce((n, e) => n + e.symbols.length, 0), edges: movedSymbols, registryMetadataEqual: true, allRealNeedsKeysProtectedBeforeAndAfter: true };
}

const auditTree = (root, run) => withTree(root, tmp => {
  fs.cpSync(path.join(root, 'scripts'), path.join(tmp, 'scripts'), { recursive: true });
  return run(tmp);
});
const result = await auditTree(before, oldRoot => auditTree(current, async newRoot => {
  const base = await probe(oldRoot), prototype = await probe(newRoot);
  const baseArt = await capture(oldRoot, 'base-default'), art = await capture(newRoot, 'prototype-default');
  assert.deepEqual(baseArt.entries, art.entries, 'Unmodified renderer operations/identity changed');
  const sourceClosureAudit = closureAudit(base, prototype, baseArt, art), rows = [];
  for (let index = 0; index < scenarios.length; index++) {
    const scenario = scenarios[index], perTree = [];
    for (const [label, root, normal, normalArt] of [['base', oldRoot, base, baseArt], ['prototype', newRoot, prototype, art]]) {
      const file = path.join(root, 'src/data/components.json'), original = fs.readFileSync(file, 'utf8');
      try {
        const json = JSON.parse(original); scenario.edit(json); fs.writeFileSync(file, JSON.stringify(json));
        const recipe = await probe(root), drawn = await capture(root, `${label}-${index}`), hashAffected = changed(normal, recipe);
        const rendererAffected = Object.keys(drawn.entries).filter(n => drawn.entries[n].sha256 !== normalArt.entries[n].sha256);
        if (scenario.prefix === 'typography' || scenario.prefix === 'surfaceGlass') {
          assert(rendererAffected.length > 0, `${scenario.name}: artifact collector failed to observe changed drawing values`);
        }
        const readers = Object.entries(drawn.dataReads).filter(([name, paths]) => !name.startsWith('(') && paths.some(p => scenario.paths.some(target => p === target || p.startsWith(target + '.')))).map(([name]) => name).sort();
        const slug = scenario.prefix.startsWith('components.') ? scenario.prefix.split('.')[1] : null;
        const crossReaders = readers.filter(name => !ownsData(drawn.registry.find(e => e.name === name), slug));
        perTree.push({ label, hashAffected, rendererAffected, readers, crossReaders, untrackedDirectReaders: crossReaders.filter(n => !hashAffected.includes(n)), unknownFallbackChanged: normal.unknown !== recipe.unknown });
      } finally { fs.writeFileSync(file, original); }
    }
    assert.deepEqual(perTree[0].hashAffected, perTree[1].hashAffected, `${scenario.name}: data hashing changed`);
    assert.deepEqual(perTree[0].rendererAffected, perTree[1].rendererAffected, `${scenario.name}: NEW output-change scope`);
    assert.deepEqual(perTree[0].readers, perTree[1].readers, `${scenario.name}: NEW data-read scope`);
    assert.deepEqual(perTree[0].untrackedDirectReaders, perTree[1].untrackedDirectReaders, `${scenario.name}: NEW untracked data dependency`);
    const sameEditOld = JSON.parse(fs.readFileSync(path.join(output, `base-${index}.json`), 'utf8'));
    const sameEditNew = JSON.parse(fs.readFileSync(path.join(output, `prototype-${index}.json`), 'utf8'));
    assert.deepEqual(sameEditOld.entries, sameEditNew.entries, `${scenario.name}: production nonequivalence`);
    rows.push({ scenario: scenario.name, paths: scenario.paths, before: perTree[0], prototype: perTree[1], newOmissions: [], sameEditedOutput: true });
    console.log(`${scenario.name}: recipes ${perTree[1].hashAffected.length}, outputs ${perTree[1].rendererAffected.length}, direct readers ${perTree[1].readers.length}, unchanged-reader hashes ${perTree[1].untrackedDirectReaders.length}; no new omission`);
  }
  return { registryCount: Object.keys(base.entries).length, sourceClosureAudit, scenarios: rows, limits: 'Read instrumentation observes actual JSON leaf accesses in the fake builder drive. Full output includes composed instance clones and references, so output deltas alone do not mean every parent needs rebuilding. Existing own-subtree hashing omits top-level/shared cross-read data; unknown-source fallback does not generally cover those data. Native instance inheritance is not modeled as a warm Generate skip.' };
}));
fs.writeFileSync(path.join(output, 'summary.json'), JSON.stringify(result, null, 2) + '\n');
console.log('entry-data safety audit passed: no new omissions; existing limitations are recorded, not waived or repaired');
