// Drives `planCollectionRenames` — what Import does with a file whose
// collections still carry an ordering prefix ("0. Primitives") once the
// exporter names them without one ("Primitives").
//
// What this proves that nothing else does: Import upserts collections by
// exact name. Matching exactly, every one of the exporter's unprefixed names
// misses, so Import would create eight new collections beside the numbered
// ones, every existing binding would stay on the old set, and the run would
// still report success — a clean log over a doubled panel. The fix renames
// in place, which keeps each collection's id and library key; the assertions
// below pin which collections it renames and which it must leave alone.
import { canonicalCollection, planCollectionRenames, withoutOrderingPrefix } from '../src/variables';

declare const process: { exit(code: number): never };

let failures = 0;
function check(label: string, cond: boolean, detail?: string) {
  if (cond) console.log(`  ✓ ${label}`);
  else {
    console.log(`  ✗ ${label}${detail ? ' — ' + detail : ''}`);
    failures++;
  }
}

function entries(m: Map<string, string>): string {
  const out: string[] = [];
  m.forEach((v, k) => out.push(`${v} → ${k}`));
  return out.join(', ');
}

// The library file's collections as `getLocalVariableCollectionsAsync`
// returned them (creation order): the seven the exporter writes, the Unibook
// brand it also writes, and six brand collections only the canvas has.
const kLiveFile = [
  '0. Primitives',
  '1-1. Semantic/ Color · CoUI',
  '1-2. Semantic/ Typography',
  '1-3. Semantic/ Dimension',
  '1-4. Semantic/ Effect',
  '1-5. Semantic/ Motion',
  '2. Component',
  '1-1. Semantic/ Color · Unibook',
  '1-1. Semantic/ Color · Medibooks',
  '1-1. Semantic/ Color · Demo Roen',
  '1-1. Semantic/ Color · Demo Seum',
  '1-1. Semantic/ Color · Demo Onnuri',
  '1-1. Semantic/ Color · Demo Hanul',
  '1-1. Semantic/ Color · Demo SafeCheck',
];

// What `export_figma_tokens.dart` names them (collection order of its output).
const kExported = [
  'Primitives',
  'Semantic/ Color · CoUI',
  'Semantic/ Color · Unibook',
  'Semantic/ Typography',
  'Semantic/ Dimension',
  'Semantic/ Effect',
  'Semantic/ Motion',
  'Component',
];

console.log('numbered file, unprefixed export');
{
  const plan = planCollectionRenames(kLiveFile, kExported);
  check('every exported collection finds its numbered original', plan.rename.size === kExported.length, entries(plan.rename));
  check(
    'each rename only drops the number',
    kExported.every((n) => {
      const old = plan.rename.get(n);
      return old !== undefined && old !== n && withoutOrderingPrefix(old) === n;
    }),
    entries(plan.rename),
  );
  check('no ambiguity', plan.ambiguous.size === 0);
  const renamedOld = new Set<string>();
  plan.rename.forEach((old) => renamedOld.add(old));
  check(
    'brand collections the exporter does not write are left alone',
    kLiveFile.filter((n) => /Medibooks|Demo /.test(n)).every((n) => !renamedOld.has(n)),
  );
  // Injected regression: an exact-name matcher — what Import did before —
  // finds none of them, which is the eight-duplicate run described above.
  const exactOnly = kExported.filter((n) => kLiveFile.indexOf(n) >= 0);
  check('an exact-only matcher would have matched nothing (the test has teeth)', exactOnly.length === 0);
}

console.log('already renamed');
{
  const renamed = kLiveFile.map(withoutOrderingPrefix);
  const plan = planCollectionRenames(renamed, kExported);
  check('nothing to rename on a second run', plan.rename.size === 0 && plan.ambiguous.size === 0, entries(plan.rename));
}

console.log('both spellings present');
{
  // A file where someone already made an unprefixed `Primitives` beside the
  // numbered one: the exact match is the collection Import updates, and the
  // numbered one is not renamed onto a name that is taken.
  const plan = planCollectionRenames(['0. Primitives', 'Primitives'], ['Primitives']);
  check('the exact match wins, nothing renamed', plan.rename.size === 0 && plan.ambiguous.size === 0, entries(plan.rename));
}

console.log('two numbered candidates');
{
  // Renaming the wrong one would move a whole collection's bindings onto the
  // wrong name, so neither is guessed.
  const plan = planCollectionRenames(['0. Primitives', '3. Primitives'], ['Primitives']);
  check('not renamed', plan.rename.size === 0, entries(plan.rename));
  const c = plan.ambiguous.get('Primitives');
  check('reported as ambiguous with both names', c !== undefined && c.length === 2, JSON.stringify(c));
}

console.log('lookups agree across the rename');
{
  // Generate binds by canonical name, so a numbered file and a renamed one
  // must resolve to the same collection on every name the exporter writes.
  check(
    'canonical names match before and after',
    kExported.every((n) => {
      const old = kLiveFile.find((o) => withoutOrderingPrefix(o) === n)!;
      return canonicalCollection(old) === canonicalCollection(n);
    }),
  );
}

console.log(failures === 0 ? '\nAll collection-rename self-tests passed.' : `\n${failures} FAILED`);
process.exit(failures === 0 ? 0 : 1);
