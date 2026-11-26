import { VarLookup, composedColorAlias } from '../src/variables';

// Exercise the real lookup, including regeneration and every semantic mode.
const values = { light: { r: 0.9, g: 0.9, b: 0.9 }, dark: { r: 0.1, g: 0.1, b: 0.1 } };
const base = { id: 'base', name: 'color/surface-container-low', variableCollectionId: 'semantic', valuesByMode: values } as unknown as Variable;
const made: Variable[] = [];
const collection = { id: 'semantic', name: 'Semantic/ Color · CoUI' } as VariableCollection;
(globalThis as any).figma = { variables: {
  createVariable(name: string, suppliedCollection: VariableCollection | string, type: string) {
    if (typeof suppliedCollection === 'string') throw new Error('dynamic-page forbids the collection-ID overload');
    if (suppliedCollection !== collection || type !== 'COLOR') throw new Error('wrong collection or type');
    const v = { id: `derived:${made.length}`, name, variableCollectionId: suppliedCollection.id, valuesByMode: {} as Record<string, VariableValue>,
      setValueForMode(mode: string, value: VariableValue) { this.valuesByMode[mode] = value; } };
    made.push(v as unknown as Variable);
    return v;
  },
  createVariableAlias(v: Variable) { return { type: 'VARIABLE_ALIAS', id: v.id }; },
} };
function assert(ok: boolean, message: string): void { if (!ok) throw new Error(message); }
const catalog = new Map([['semantic', 'Semantic/ Color · CoUI']]);
const collectionObjects = new Map([[collection.id, collection]]);
const lk = new VarLookup([base], catalog, collectionObjects);
const first = lk.semWithOpacity('surface-container-low', 0.88);
assert(made.length === 1, 'one alias must be created');
assert(lk.semWithOpacity('surface-container-low', 0.88) === first, 'same lookup must reuse the alias');
assert(new VarLookup([base, first], catalog, collectionObjects).semWithOpacity('surface-container-low', 0.88) === first, 'next Generate must reuse the persisted alias');
assert(Object.keys(first.valuesByMode).join() === Object.keys(values).join(), 'every semantic mode must be populated');
assert(composedColorAlias(first)?.baseId === base.id && composedColorAlias(first)?.alpha === 0.88, 'every mode must refer to the same base at 88%');
assert(lk.semWithOpacity('surface-container-low', 1) === base, 'opaque fill must bind the base directly');
let rejectedId = false;
try { figma.variables.createVariable('bad', collection.id, 'COLOR'); } catch { rejectedId = true; }
assert(rejectedId, 'the double must reject the old collection-ID call, as the desktop does');
let rejectedUnloaded = false;
try { new VarLookup([base], catalog).semWithOpacity('surface-container-low', 0.7); } catch { rejectedUnloaded = true; }
assert(rejectedUnloaded, 'a missing collection object must be reported before the native call');
assert(first.scopes.join() === 'FRAME_FILL,SHAPE_FILL', 'derived colors must only appear in background fill pickers');
for (const alpha of [NaN, -1, 2]) {
  let rejected = false;
  try { lk.semWithOpacity('surface-container-low', alpha); } catch { rejected = true; }
  assert(rejected, 'invalid alpha must be rejected');
}
first.setValueForMode('dark', { color: { type: 'VARIABLE_ALIAS', id: base.id }, opacity: 70 });
assert(composedColorAlias(first) === null, 'different alpha in one mode must not qualify for the fidelity exception');
lk.semWithOpacity('surface-container-low', 0.88);
assert(composedColorAlias(first)?.alpha === 0.88, 'Generate must restore every mode');
console.log('Composed color: modes, base alias, reuse, regeneration, and invalid opacity verified.');

// The opacity ladder is keyed by whole percents (`Primitives/opacity/<pct>`, value
// = percent), and `VarLookup.opacity` takes the Core alpha (0-1). The mapping has to
// survive float noise (`0.07 * 100` is 7.000000000000001) without ever binding a
// neighbouring step for an alpha that is not on the ladder.
const ladderCollection = { id: 'primitives', name: 'Primitives' } as VariableCollection;
const step = (pct: number): Variable =>
  ({ id: `opacity:${pct}`, name: `opacity/${pct}`, variableCollectionId: ladderCollection.id, valuesByMode: { Value: pct } }) as unknown as Variable;
const ladder = [7, 70, 100].map(step);
const ladderLookup = new VarLookup(ladder, new Map([[ladderCollection.id, ladderCollection.name]]));
assert(ladderLookup.opacity(0.7) === ladder[1], '0.7 must resolve to Primitives/opacity/70');
assert(ladderLookup.opacity(0.07) === ladder[0], '0.07 must resolve to Primitives/opacity/7 despite 0.07 * 100 = 7.000000000000001');
assert(ladderLookup.opacity(1) === ladder[2], '1 must resolve to Primitives/opacity/100');
for (const [alpha, why] of [
  [0.125, 'an alpha between two steps'],
  [0.705, 'an alpha half a percent off a step'],
  [NaN, 'NaN'],
  [Infinity, 'an infinite alpha'],
] as const) {
  let message = '';
  try { ladderLookup.opacity(alpha); } catch (e) { message = String(e); }
  assert(message.includes('not a whole percent'), `${why} must be refused as off the ladder, not bound to a neighbour (got: ${message || 'no throw'})`);
}
let absent = '';
try { ladderLookup.opacity(0.5); } catch (e) { absent = String(e); }
assert(absent.includes('variable not found: Primitives/opacity/50'), `a missing step must name the variable it asked for (got: ${absent || 'no throw'})`);
console.log('Opacity ladder: Core alpha -> whole-percent step, float noise absorbed, off-ladder and missing steps refused.');
