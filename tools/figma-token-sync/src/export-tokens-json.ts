/// <reference types="@figma/plugin-typings" />

// Exports every local Figma Variable back out as the `TokenDoc` JSON that
// `import-tokens.ts` reads — the missing half of a round trip the tool has
// only ever had one direction of.
//
// WHY THIS EXISTS. The plugin could read tokens *into* Figma (Import) and
// emit Dart *out of* Figma (Export Dart Code), but nothing wrote the token
// JSON back out. That was fine while `export_figma_tokens.dart` was the
// source of truth and Figma only received. It stopped being fine when a
// design system was authored in Figma first: the 8-collection / 672-variable
// CoUI DS v1.0 exists only in the file, so `docs/design-tokens/*.json` in a
// consuming repo had no way to be anything but hand-assembled (kobic#12993).
//
// A hand-assembled copy of 672 variables is not a source of truth, it is a
// second thing to keep in sync — and the consuming repo's drift test reads
// exactly that file to check the `.g.dart` against. Feeding a drift guard a
// hand-maintained expectation makes it a test of transcription, not of the
// pipeline.
//
// WHY IT SHIPS WITH THE DART EXPORT RATHER THAN ITS OWN BUTTON. The two
// artefacts are only meaningful as a pair: the drift test compares them, so
// it must be able to assume they describe the same file at the same moment.
// Two buttons means two reads of a live document that a designer can edit in
// between, and a mismatch then reads as drift when it is only a stale half.
// `exportDartTokens` takes one snapshot and derives both, and both carry the
// same `export` fingerprint so the consuming side can *assert* they are a
// pair rather than trusting that they are.

import {
  AliasSpec,
  CollectionSpec,
  ColorSpec,
  FigType,
  ValueSpec,
  VariableSpec,
} from './import-tokens';
import { fnv1a } from './hash';

export interface TokenDocMeta {
  generator: string;
  collections: number;
  variables: number;
  /**
   * FNV-1a of the serialized `collections`, also stamped into the `.g.dart`
   * header. Equal fingerprints mean the two files came from one snapshot.
   */
  export: string;
}

export interface ExportedTokenDoc {
  meta: TokenDocMeta;
  collections: CollectionSpec[];
}

export interface BuildTokenDocResult {
  collections: CollectionSpec[];
  skipped: string[];
}

function isAliasValue(raw: unknown): raw is VariableAlias {
  return (
    raw !== null &&
    typeof raw === 'object' &&
    'type' in raw &&
    (raw as { type: unknown }).type === 'VARIABLE_ALIAS'
  );
}

function colorSpec(c: RGBA | RGB): ColorSpec {
  // Figma hands back float32 channel values; they are written through
  // unrounded. Rounding here would make every round trip lossy in a way the
  // consuming drift test would then have to be taught to forgive.
  const a = 'a' in c && c.a != null ? c.a : 1;
  return { r: c.r, g: c.g, b: c.b, a };
}

/**
 * Builds the `collections` half of a `TokenDoc` from a live variable snapshot.
 *
 * Pure — no `figma` global — so the selftest can drive it with fixtures.
 * Variables are emitted in name order so that re-exporting an unchanged file
 * produces an unchanged diff; collection order is left as Figma reports it,
 * because the numeric prefixes (`0.`, `1-1.`, `2.`) are the intended order.
 */
export function buildTokenDoc(
  collections: VariableCollection[],
  variables: Variable[],
): BuildTokenDocResult {
  const skipped: string[] = [];

  const byId = new Map<string, Variable>();
  for (const v of variables) byId.set(v.id, v);

  const collById = new Map<string, VariableCollection>();
  for (const c of collections) collById.set(c.id, c);

  // `alias` is resolved to `<CollectionName>/<variable.name>` — the exact key
  // `importTokens` indexes by. It looks up that string whole (a Map get, not a
  // split), so a collection name containing `/` — `Semantic/ Color · CoUI`
  // is one — stays unambiguous.
  const pathById = new Map<string, string>();
  for (const v of variables) {
    const coll = collById.get(v.variableCollectionId);
    if (coll) pathById.set(v.id, `${coll.name}/${v.name}`);
  }

  const byCollection = new Map<string, Variable[]>();
  for (const v of variables) {
    if (!collById.has(v.variableCollectionId)) {
      skipped.push(`${v.name} (컬렉션 미해석)`);
      continue;
    }
    const list = byCollection.get(v.variableCollectionId);
    if (list) list.push(v);
    else byCollection.set(v.variableCollectionId, [v]);
  }

  const out: CollectionSpec[] = [];
  for (const coll of collections) {
    const vars = byCollection.get(coll.id);
    if (!vars || vars.length === 0) continue;
    vars.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));

    const specs: VariableSpec[] = [];
    for (const v of vars) {
      // TokenDoc v1 cannot round-trip Figma's composed COLOR values. Report
      // them instead of casting their {color, opacity} object to RGB and
      // emitting undefined channels. Generated paint aliases regenerate from
      // the base token and are not independent Core semantic tokens.
      if (Object.values(v.valuesByMode).some((value) =>
        typeof value === 'object' && 'color' in value && 'opacity' in value)) {
        skipped.push(`${v.name} (composed color: TokenDoc v1 미지원)`);
        continue;
      }
      const valuesByMode: Record<string, ValueSpec> = {};
      let emitted = 0;

      for (const mode of coll.modes) {
        const raw = v.valuesByMode[mode.modeId];
        // A mode a variable has no value for is absent, not null — writing a
        // placeholder would import as a real value and overwrite the alias
        // the file actually holds.
        if (raw === undefined) continue;

        if (isAliasValue(raw)) {
          const target = pathById.get(raw.id);
          if (!target) {
            // Same policy as the Dart export: an alias into a library the
            // local file does not hold cannot be expressed as a local path.
            skipped.push(`${v.name} (alias → 미해석: 외부 라이브러리?)`);
            continue;
          }
          const alias: AliasSpec = { alias: target };
          valuesByMode[mode.name] = alias;
        } else if (v.resolvedType === 'COLOR') {
          valuesByMode[mode.name] = colorSpec(raw as RGBA | RGB);
        } else {
          valuesByMode[mode.name] = raw as number | string | boolean;
        }
        emitted++;
      }

      // Every value was an unresolvable alias — the variable would import as
      // a name with no value at all, so it is dropped and reported instead.
      if (emitted === 0) continue;

      const spec: VariableSpec = {
        name: v.name,
        type: v.resolvedType as FigType,
        valuesByMode,
      };
      if (v.description) spec.description = v.description;
      // `ALL_SCOPES` is the default a new variable already gets, so writing it
      // adds a key to 672 entries that says nothing. Anything narrower is a
      // deliberate restriction and has to survive the round trip.
      if (v.scopes && !(v.scopes.length === 1 && v.scopes[0] === 'ALL_SCOPES')) {
        spec.scopes = v.scopes.slice();
      }
      // `false` is the default every variable already has, so only a hidden
      // variable carries the key — the same rule as `ALL_SCOPES` above.
      if (v.hiddenFromPublishing) spec.hiddenFromPublishing = true;
      specs.push(spec);
    }

    if (specs.length === 0) continue;
    out.push({
      name: coll.name,
      modes: coll.modes.map((m) => m.name),
      variables: specs,
    });
  }

  return { collections: out, skipped };
}

/**
 * Fingerprint of the token content, excluding `meta` — `meta` carries this
 * value, so including it would be self-referential.
 */
export function fingerprintCollections(collections: CollectionSpec[]): string {
  return fnv1a(JSON.stringify(collections));
}

export function serialiseTokenDoc(doc: ExportedTokenDoc): string {
  return `${JSON.stringify(doc, null, 2)}\n`;
}
