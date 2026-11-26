#!/usr/bin/env node
// Behavioral boundaries, not a snapshot of our graph: independent renderers must
// stay independent; real drawing/child/data/pipeline inputs must still invalidate.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { measure, withTree, probe, replace, changed, scenarios } from './measure-entry-dependencies.mjs';

const root = process.cwd();
const report = await measure(root);
const row = name => {
  const result = report.scenarios.find(r => r.scenario === name);
  assert(result, `missing scenario ${name}`);
  return result;
};
const affected = name => row(name).affected;
const assertIndependentPanel = moved => assert.deepEqual(moved, ['Command'], 'Parent-only Command drawing must not invalidate child masters or unrelated renderers');
const assertChild = moved => assert(moved.includes('Popup') && moved.includes('Popover') && moved.includes('PhoneInput'), 'Popup drawing must invalidate its transitive instance consumers');
const assertOwnData = moved => assert.deepEqual(moved, ['TextField'], 'Own data must change its recipe and leave unrelated entries alone');
assert.equal(report.registryCount, Object.keys(report.baseline.entries).length);
assert.equal(report.baseline.unresolved.length, 0);
// Registry modules own renderers; composition contracts and drawing operations
// belong below them. This detects NEW cross-builder coupling anywhere in the library.
assert.deepEqual(report.baseline.crossBuilderImports, [], 'Builder modules must not import another registry module for incidental helpers');
assertIndependentPanel(affected('Command panel only'));
assert.deepEqual(affected('CommandSearch drawing'), ['CommandSearch']);
assert.deepEqual([...affected('CommandItem child drawing')].sort(), ['Command', 'CommandItem']);
const textAffected = affected('SelectableText drawing');
assert(textAffected.includes('SelectableText'), 'SelectableText must react to its own drawing edit');
assert(textAffected.length <= 4, 'SelectableText must not exceed the reviewed four-entry cohort');
for (const unrelated of ['Button', 'Popup', 'Dialog', 'Menu', 'Command', 'CommandItem', 'CommandSearch', 'Carousel']) {
  assert(!textAffected.includes(unrelated), `SelectableText edit invalidated unrelated ${unrelated}`);
}
assertChild(affected('Popup child drawing'));
assertOwnData(affected('Own TextField data'));
for (const name of ['Global drawing pipeline', 'Global generate glue', 'Unknown source fallback (missing table)']) {
  assert.equal(affected(name).length, report.registryCount, name);
}
for (const name of ['Non-drawing logging', 'Non-drawing lock']) assert.deepEqual(affected(name), [], name);
for (const name of ['Shared field caret/radius drawing', 'Shared container elevation drawing', 'Chip composition helper', 'Shared instance label drawing']) {
  assert(affected(name).length > 0, `${name} lost drawing invalidation`);
  assert(!affected(name).includes('Icon'), `${name} invalidated reusable Icon in reverse`);
}
assert(affected('Shared field caret/radius drawing').includes('TextField'));
assert(affected('Shared container elevation drawing').includes('Card'));
assert(affected('Chip composition helper').includes('ChipInput'));
assert(row('Opaque Icon source fallback').unresolved.some(r => r.key === 'ICON_BUILDERS'));
assert(row('Opaque Icon source fallback').fallback.includes('Icon'));
assert(row('Opaque Icon source fallback').fallback.includes('Button'));
for (const r of report.scenarios.filter(r => !r.scenario.toLowerCase().includes('data'))) {
  assert(r.unknownChanged, `Unknown source lost whole-plugin fallback: ${r.scenario}`);
}

async function mutated(tmp, scenarioName) {
  const before = await probe(tmp), scenario = scenarios.find(s => s.name === scenarioName);
  const restore = scenario.mutate(tmp);
  try { return changed(before, await probe(tmp)); } finally { restore(); }
}
// Negative guard proof: reintroduce an accidental builder edge into the actual
// source, then regenerate the actual esbuild graph and bundled runtime hashes.
await withTree(root, async tmp => {
  const p = path.join(tmp, 'src/components/form.ts');
  fs.appendFileSync(p, "\nimport { COMMAND_BUILDERS } from './command';\n(globalThis as any).__regression = COMMAND_BUILDERS;\n");
  const moved = await mutated(tmp, 'Command panel only');
  assert(moved.includes('Button'), 'Regression injection did not actually reproduce reverse invalidation');
  assert.throws(() => assertIndependentPanel(moved), /Parent-only Command drawing/);
  const injected = await probe(tmp);
  assert.throws(() => assert.deepEqual(injected.crossBuilderImports, []));
  console.log(`entry-dependencies: accidental builder edge caught (${moved.length} affected entries)`);
});
// Positive guard proof: remove a real needs edge, keeping bundler imports intact.
await withTree(root, async tmp => {
  replace(tmp, "name: 'Popover', build: buildPopover, needs: ['Button', 'Popup', kPopoverExample]", "name: 'Popover', build: buildPopover, needs: ['Button', kPopoverExample]");
  const moved = await mutated(tmp, 'Popup child drawing');
  assert(!moved.includes('Popover'), 'Missing-child injection did not remove the dependency');
  assert.throws(() => assertChild(moved), /transitive instance consumers/);
  console.log('entry-dependencies: missing child needs caught');
});
// Positive guard proof: take own JSON data out of the actual runtime recipe.
await withTree(root, async tmp => {
  replace(tmp, 'return fnv1a(`closure:${source}${entryDataHashOf(e)}`);', 'return fnv1a(`closure:${source}`);');
  const moved = await mutated(tmp, 'Own TextField data');
  assert.deepEqual(moved, [], 'Missing-data injection did not remove data sensitivity');
  assert.throws(() => assertOwnData(moved), /Own data must change/);
  console.log('entry-dependencies: missing own data caught');
});
if (process.env.COUI_ENTRY_DEPENDENCY_REPORT) fs.writeFileSync(process.env.COUI_ENTRY_DEPENDENCY_REPORT, JSON.stringify(report, null, 2) + '\n');
console.log(`selftest: entry-dependencies — ${report.registryCount} entries, ${report.groupCount} closed groups, ${report.scenarios.length} scenarios, all ok`);
