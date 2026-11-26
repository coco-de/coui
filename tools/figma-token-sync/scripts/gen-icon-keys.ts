// Checks `src/data/icon-keys.json` against `ICON_NAMES` — the glyph vocabulary
// the plugin draws.
//
// What the file holds: Lucide glyph name → the *published component key* of
// that glyph in `CoUI Icons — Lucide`. `makeIcon` no longer draws path data; it
// instances a `Size=N` variant of the designer-owned `Icon` set and swaps in
// the library glyph, and `importComponentByKeyAsync` needs a key.
//
// Why this is a CHECKER and not a generator, unlike `gen-icons.ts`: the keys
// only exist inside the Figma file. There is no Plugin API that lists a
// library's components (`figma.teamLibrary` enumerates variable collections
// only) and no offline artifact to read them from, so a key cannot be derived
// from anything in this repo. Harvesting one means running a script *inside*
// the Lucide file. This keeps the pairing honest instead: it fails when the
// vocabulary and the key map disagree, and says exactly which names to harvest.
//
// To harvest, run this in the Lucide file (M6VfF2ctOkLsF82sYzCM3G) and paste
// the result into `src/data/icon-keys.json`:
//
//   const page = figma.root.children.find(p => p.name === 'Icons');
//   await figma.setCurrentPageAsync(page);
//   const out = {};
//   for (const c of page.findAllWithCriteria({ types: ['COMPONENT'] })) {
//     out[c.name.replace(/^lucide\//, '')] = c.key;
//   }
//   return out;   // then keep only the ICON_NAMES entries, sorted
//
// A key is stable across republish; it only changes if a glyph is deleted and
// recreated. A stale one fails loudly at import time (`Component with key "…"
// not found`) and is reported per name by the glyph prelude — never silently.
//
// Usage: npm run gen:icon-keys

// Minimal local ambients instead of `@types/node` — same reasoning as
// `gen-icons.ts`: `typeRoots` is pinned to `@figma/plugin-typings` so the
// plugin's own code cannot reach Node APIs.
declare const process: { cwd(): string; exit(code: number): never };
declare function require(id: string): unknown;

const { readFileSync } = require('node:fs') as {
  readFileSync(p: string, enc: string): string;
};
const { resolve } = require('node:path') as {
  resolve(...parts: string[]): string;
};

const KEYS = resolve(process.cwd(), 'src/data/icon-keys.json');
const GEN = resolve(process.cwd(), 'scripts/gen-icons.ts');

const keys = JSON.parse(readFileSync(KEYS, 'utf8')) as Record<string, string>;

// The vocabulary, read from the one place that declares it. Parsed rather than
// imported because `gen-icons.ts` is a script, not a module with exports — and
// duplicating the list here is exactly the drift this checks for.
const src = readFileSync(GEN, 'utf8');
const block = /const ICON_NAMES = \[([\s\S]*?)\n\];/.exec(src);
if (!block) {
  console.error('gen-icon-keys: could not find ICON_NAMES in scripts/gen-icons.ts');
  process.exit(1);
}
const names: string[] = [];
const re = /'([a-z0-9-]+)'/g;
let m = re.exec(block[1]);
while (m) {
  names.push(m[1]);
  m = re.exec(block[1]);
}

const missing = names.filter((n) => !keys[n]);
const extra = Object.keys(keys).filter((n) => names.indexOf(n) < 0);
const malformed = Object.keys(keys).filter((n) => !/^[0-9a-f]{40}$/.test(keys[n]));

if (missing.length) {
  console.error(
    `gen-icon-keys: ${missing.length} name(s) in ICON_NAMES have no key — ` +
      `${missing.join(', ')}. Harvest them from the Lucide file (see this ` +
      "file's header) and add them to src/data/icon-keys.json.",
  );
}
if (extra.length) {
  console.error(
    `gen-icon-keys: ${extra.length} key(s) are not in ICON_NAMES — ` +
      `${extra.join(', ')}. Either add the name to ICON_NAMES in ` +
      'scripts/gen-icons.ts or drop the key; an unused key still costs an ' +
      'import in the glyph prelude.',
  );
}
if (malformed.length) {
  console.error(
    `gen-icon-keys: ${malformed.length} key(s) are not 40-char hex — ` +
      `${malformed.join(', ')}. That is a node id or a truncated paste, not a ` +
      'component key; `importComponentByKeyAsync` would fail on it at run time.',
  );
}
if (missing.length || extra.length || malformed.length) process.exit(1);

console.log(
  `gen-icon-keys: ${names.length} name(s) ↔ ${Object.keys(keys).length} key(s) — in sync.`,
);

// Module scope, so this script's ambient declarations do not collide with
// `gen-icons.ts`'s identical ones at the global script scope.
export {};
