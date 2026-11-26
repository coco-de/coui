/// <reference types="@figma/plugin-typings" />

// Imports `build/tokens.figma.json` (from
// `dart run packages/coui_core/bin/export_figma_tokens.dart`) into Figma
// Variables. Idempotent: variables are upserted by name; aliases linked in a
// second pass once every primitive exists.
//
// Token schema:
//   { collections: [ { name, modes: string[],
//       variables: [ { name, type, valuesByMode: { <mode>: value },
//                       description?: string, scopes?: string[],
//                       hiddenFromPublishing?: boolean } ] } ] }
// where value is { r,g,b,a } | number | string | boolean | { alias: "<path>" }
// and an alias path is "<CollectionName>/<variable.name>".
//
// `description` (optional) is written to `Variable.description` on every
// upsert, so re-running the export after a wording change updates it in
// place rather than leaving the old text stuck to the variable.
//
// Degrades on files whose Figma plan allows fewer variable modes than the token
// file declares: the modes it can get are imported in full and the log names
// the ones it could not (see the `addMode` guard below). It never returns
// empty-handed over a mode it was refused.
//
// `scopes` (optional) is written to `Variable.scopes` the same way — it
// restricts which binding pickers offer the variable (WIDTH_HEIGHT for
// size/*, GAP for space/*, CORNER_RADIUS for radius/*, STROKE_FLOAT for
// stroke/*), making the Size/Space namespace boundary tool-enforced in
// Figma. A variable with no `scopes` key keeps whatever it has
// (ALL_SCOPES for new variables).
//
// `hiddenFromPublishing` (optional) is written to
// `Variable.hiddenFromPublishing` the same way. The exporter derives it from
// the document itself — a brand's colour ramp no Semantic slot aliases is
// kept for derivation but not offered in the published library — so the
// decision lives in code rather than as a flag someone toggled by hand once:
// a variable Import creates, or a brand added later, gets it too. The shared
// category ramps (`color/category/<hue>/…`) carry it by the same rule. A
// variable with no key keeps whatever the file says.

import { upsertTextStyles, TextStyleSpec } from './text-styles';
import { planCollectionRenames } from './variables';

// These shapes are the import contract, and `export-tokens-json.ts` writes the
// same shapes back out — so they are exported rather than kept file-local. One
// definition means the two directions cannot drift apart in the type system
// while still both compiling.
export type FigType = 'COLOR' | 'FLOAT' | 'STRING' | 'BOOLEAN';

export interface TokenDoc {
  collections: CollectionSpec[];
  /** Canvas text styles, one per typography role — see `text-styles.ts`. */
  textStyles?: TextStyleSpec[];
}
export interface CollectionSpec {
  name: string;
  modes: string[];
  variables: VariableSpec[];
}
export interface VariableSpec {
  name: string;
  type: FigType;
  valuesByMode: Record<string, ValueSpec>;
  description?: string;
  scopes?: VariableScope[];
  hiddenFromPublishing?: boolean;
}
export type ColorSpec = { r: number; g: number; b: number; a?: number };
export type AliasSpec = { alias: string };
export type ValueSpec = ColorSpec | AliasSpec | number | string | boolean;

function isAlias(v: ValueSpec): v is AliasSpec {
  return typeof v === 'object' && v !== null && 'alias' in v;
}
function isColor(v: ValueSpec): v is ColorSpec {
  return typeof v === 'object' && v !== null && 'r' in v;
}

function sameScopes(
  a: readonly VariableScope[],
  b: readonly VariableScope[],
): boolean {
  return a.length === b.length && a.every((s, i) => s === b[i]);
}

function toFigmaValue(v: ValueSpec): VariableValue {
  if (isColor(v)) {
    return { r: v.r, g: v.g, b: v.b, a: v.a == null ? 1 : v.a } as RGBA;
  }
  return v as VariableValue;
}

// One collection's modes that this file's Figma plan refused, so the log can
// name them. `kept` is what the collection actually ends up with.
interface SkippedModes {
  collection: string;
  kept: string[];
  skipped: string[];
  reasons: string[];
}

// Figma rejects with a plain `Error`; keep its message and drop the `Error: `
// prefix that `String(e)` would prepend, so the log line reads as a sentence.
function messageOf(e: unknown): string {
  return e instanceof Error ? e.message : String(e);
}

// Only name the plan when Figma itself did. The documented rejection is
// `in addMode: Limited to N modes only` (plugin-api.d.ts on `addMode`: "limited
// by the current file's pricing tier"); any other failure is reported with its
// own message and no invented cause.
function isModeLimit(reason: string): boolean {
  return /Limited to \d+ modes? only/.test(reason);
}

function quoteList(names: string[]): string {
  return names.map((n) => `"${n}"`).join(', ');
}

export async function importTokens(doc: TokenDoc): Promise<string[]> {
  const log: string[] = [];

  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const variables = await figma.variables.getLocalVariablesAsync();

  const collByName = new Map<string, VariableCollection>();
  for (const c of collections) collByName.set(c.name, c);

  // A collection the file still names with an ordering prefix ("0. Primitives")
  // is renamed to the token file's name in place — see `planCollectionRenames`
  // for why renaming, not creating, is what keeps the bindings.
  const plan = planCollectionRenames(
    collections.map((c) => c.name),
    doc.collections.map((c) => c.name),
  );
  plan.rename.forEach((oldName, name) => {
    const coll = collByName.get(oldName)!;
    coll.name = name;
    collByName.delete(oldName);
    collByName.set(name, coll);
    log.push(`~ collection "${oldName}" → "${name}"`);
  });
  plan.ambiguous.forEach((candidates, name) => {
    log.push(
      `⚠ collection "${name}": ${quoteList(candidates)} all match it once their number is dropped — none renamed, a new one is created`,
    );
  });

  const existing = new Map<string, Variable>();
  for (const v of variables) {
    existing.set(`${v.variableCollectionId}::${v.name}`, v);
  }

  // `addMode` is the one call in this importer that a file's Figma plan can
  // refuse — `plugin-api.d.ts` marks it "limited by the current file's pricing
  // tier" and has it throw `in addMode: Limited to N modes only`. Mode setup is
  // a separate pass that runs entirely BEFORE the first variable is written, so
  // letting that throw escape aborted the import with both collections created
  // and ZERO variables in them. "Generate Components" then died in `loadFonts`
  // at `variable not found: Primitives/font-family/sans` — above the per-entry
  // try/catch, so not one of the 143 components was built, and neither message
  // named the plan or the modes.
  //
  // One mode is a usable library: bindings resolve a Variable by *name*
  // (`VarLookup`), never by mode, and the mode is chosen on the consuming
  // frame. So a refused mode degrades to "that mode is absent" — the variable
  // pass below already skips values whose mode is missing (`modeId == null`).
  // What must not degrade is the report, hence `skippedModes`.
  const modeIds = new Map<string, Record<string, string>>();
  const skippedModes: SkippedModes[] = [];
  for (const spec of doc.collections) {
    let coll = collByName.get(spec.name);
    if (!coll) {
      coll = figma.variables.createVariableCollection(spec.name);
      collByName.set(spec.name, coll);
      log.push(`+ collection "${spec.name}"`);
    }
    if (coll.modes[0].name !== spec.modes[0]) {
      coll.renameMode(coll.modes[0].modeId, spec.modes[0]);
    }
    const present = new Set(coll.modes.map((m) => m.name));
    const skipped: string[] = [];
    const reasons: string[] = [];
    for (let i = 1; i < spec.modes.length; i++) {
      const modeName = spec.modes[i];
      if (present.has(modeName)) continue;
      try {
        coll.addMode(modeName);
        present.add(modeName);
      } catch (e) {
        // Keep trying the rest: a plan cap refuses every remaining mode with
        // the same message (deduped into `reasons`), but a one-off rejection
        // must not cost the modes that follow it.
        skipped.push(modeName);
        const reason = messageOf(e);
        if (reasons.indexOf(reason) < 0) reasons.push(reason);
      }
    }
    const map: Record<string, string> = {};
    for (const m of coll.modes) map[m.name] = m.modeId;
    modeIds.set(spec.name, map);
    if (skipped.length > 0) {
      skippedModes.push({
        collection: spec.name,
        kept: coll.modes.map((m) => m.name),
        skipped,
        reasons,
      });
    }
  }

  if (skippedModes.length > 0) {
    const total = skippedModes.reduce((n, s) => n + s.skipped.length, 0);
    // `⚠` is what turns the log amber in the UI (ui.html) — this run finished,
    // but it produced fewer modes than the token file asked for.
    log.push(`⚠ ${total} variable mode(s) could not be created in this file.`);
    for (const s of skippedModes) {
      log.push(
        `  ${s.collection}: kept ${quoteList(s.kept)} — skipped ${quoteList(s.skipped)}`,
      );
      for (const r of s.reasons) log.push(`    ↳ Figma refused: ${r}`);
    }
    log.push(
      '  Values for the skipped modes are not written. The kept modes are complete, so ' +
        '"Generate Components" still builds the whole library — it just has no ' +
        'variables to flip for the missing modes.',
    );
    if (skippedModes.some((s) => s.reasons.some(isModeLimit))) {
      log.push(
        '  That cap is this file\'s Figma plan, not a token error. Re-running the import ' +
          'in a file whose plan allows more variable modes adds the rest in place; ' +
          'nothing here has to be undone first.',
      );
    }
  }

  const byPath = new Map<string, Variable>();
  let visibilityChanged = 0;
  const aliasJobs: { v: Variable; modeId: string; target: string }[] = [];

  for (const spec of doc.collections) {
    const coll = collByName.get(spec.name)!;
    const modeMap = modeIds.get(spec.name)!;
    for (const vs of spec.variables) {
      const key = `${coll.id}::${vs.name}`;
      let v = existing.get(key);
      if (!v) {
        v = figma.variables.createVariable(vs.name, coll, vs.type);
        existing.set(key, v);
      }
      byPath.set(`${spec.name}/${vs.name}`, v);
      if (vs.description != null && v.description !== vs.description) {
        v.description = vs.description;
      }
      if (vs.scopes != null && !sameScopes(v.scopes, vs.scopes)) {
        v.scopes = vs.scopes;
      }
      if (
        vs.hiddenFromPublishing != null &&
        v.hiddenFromPublishing !== vs.hiddenFromPublishing
      ) {
        v.hiddenFromPublishing = vs.hiddenFromPublishing;
        visibilityChanged++;
      }

      for (const modeName of Object.keys(vs.valuesByMode)) {
        const modeId = modeMap[modeName];
        if (modeId == null) continue;
        const val = vs.valuesByMode[modeName];
        if (isAlias(val)) {
          aliasJobs.push({ v, modeId, target: val.alias });
        } else {
          v.setValueForMode(modeId, toFigmaValue(val));
        }
      }
    }
  }
  log.push(`✓ upserted ${byPath.size} variables`);
  if (visibilityChanged > 0) {
    log.push(`✓ publish visibility: ${visibilityChanged} variable(s) changed`);
  }

  let linked = 0;
  let missing = 0;
  for (const job of aliasJobs) {
    const target = byPath.get(job.target);
    if (!target) {
      missing++;
      log.push(`! alias target not found: ${job.target}`);
      continue;
    }
    job.v.setValueForMode(
      job.modeId,
      figma.variables.createVariableAlias(target),
    );
    linked++;
  }
  log.push(`✓ aliases: ${linked} linked${missing ? `, ${missing} missing` : ''}`);

  // Styles last: they bind to variables, so every variable — and every alias
  // a weight resolves through — must already exist.
  if (doc.textStyles && doc.textStyles.length > 0) {
    log.push(...(await upsertTextStyles(doc.textStyles, byPath)));
  }
  log.push(...(await bindShadowStyles(byPath, specValueReader(doc))));

  return log;
}

/**
 * Rebuilds the document's `shadow/<step>` effect styles from the `Semantic/
 * Surface` cast rows, so a component wearing one follows the surface style its
 * frame pins — the same casts the two platforms bend for that style.
 *
 * It creates no style: the file's styles are where designers' components point,
 * and a second family would be a second place for a cast to live. It rebuilds
 * what is there, to the layers the code exports — not to the layers the style
 * happens to hold. A step whose export lost a layer would otherwise keep its
 * old layer, bound to rows Import never deletes, and stay two layers where the
 * code draws one. Each exported layer `<i>` (one `<i>/x` row per layer)
 * becomes a cast whose offset, blur, colour and spread bind to its rows; a
 * layer with no `<i>-mirror` rows is an inset one. Each cast is followed by
 * its mirror layer (the twin a mirroring style throws the other way) — present
 * under every style, drawing at zero alpha under the ones that do not mirror,
 * because a mode cannot add a layer.
 *
 * The values are the code's. A style a designer edited is rebuilt to the
 * code's layers, as a re-Import does for a variable edited by hand.
 */
async function bindShadowStyles(
  byPath: Map<string, Variable>,
  valueOf: (path: string) => ValueSpec | undefined,
): Promise<string[]> {
  const row = (step: string, layer: string, field: string): Variable | undefined =>
    byPath.get(`Semantic/ Surface/shadow/${step}/${layer}/${field}`);
  const styles = (await figma.getLocalEffectStylesAsync()).filter((s) => s.name.startsWith('shadow/'));
  let bound = 0;
  const skipped: string[] = [];
  for (const style of styles) {
    const step = style.name.slice('shadow/'.length);
    const effects: Effect[] = [];
    let complete = true;
    let layers = 0;
    for (let i = 0; row(step, `${i}`, 'x') !== undefined; i++) {
      layers++;
      const x = row(step, `${i}`, 'x')!;
      const y = row(step, `${i}`, 'y');
      const blur = row(step, `${i}`, 'blur');
      const color = row(step, `${i}`, 'color');
      const spread = row(step, `${i}`, 'spread');
      if (!y || !blur || !color || !spread) {
        complete = false;
        break;
      }
      const mx = row(step, `${i}-mirror`, 'x');
      const inset = mx === undefined;
      const layer = (name: string, type: 'DROP_SHADOW' | 'INNER_SHADOW') =>
        castLayer(type, valueOf, `Semantic/ Surface/shadow/${step}/${name}`, `Semantic/ Surface/shadow/${step}/${i}/spread`);
      effects.push(bindEffect(layer(`${i}`, inset ? 'INNER_SHADOW' : 'DROP_SHADOW'), x, y, blur, color, spread));
      if (inset) continue;
      const my = row(step, `${i}-mirror`, 'y');
      const mb = row(step, `${i}-mirror`, 'blur');
      const mc = row(step, `${i}-mirror`, 'color');
      if (!my || !mb || !mc) {
        complete = false;
        break;
      }
      effects.push(bindEffect(layer(`${i}-mirror`, 'DROP_SHADOW'), mx, my, mb, mc, spread));
    }
    if (layers === 0 || !complete) {
      skipped.push(style.name);
      continue;
    }
    style.effects = effects;
    bound++;
  }
  const out = [`✓ shadow styles: ${bound} rebuilt from Semantic/ Surface casts`];
  if (skipped.length > 0) {
    out.push(
      `! shadow styles left as they were (no complete rows for the step — a step the export does ` +
        `not carry, or a document from before the spread rows): ${skipped.join(', ')}`,
    );
  }
  return out;
}

/**
 * A cast layer holding its rows' values in the document's first mode, ready
 * for [bindEffect] to bind.
 *
 * The values are written before the binding so the style's own numbers agree
 * with what its variables say — the canvas reads a style's layers by value
 * (`shadow-style.ts` links a node's shadow to the style that states the same
 * layers), and a layer left at placeholders would match nothing.
 */
function castLayer(
  type: 'DROP_SHADOW' | 'INNER_SHADOW',
  valueOf: (path: string) => ValueSpec | undefined,
  layerPath: string,
  spreadPath: string,
): DropShadowEffect | InnerShadowEffect {
  const num = (path: string): number => {
    const v = valueOf(path);
    return typeof v === 'number' ? v : 0;
  };
  const tint = valueOf(`${layerPath}/color`);
  const color = tint !== undefined && isColor(tint)
    ? { r: tint.r, g: tint.g, b: tint.b, a: tint.a ?? 1 }
    : { r: 0, g: 0, b: 0, a: 0 };
  const base = {
    color,
    offset: { x: num(`${layerPath}/x`), y: num(`${layerPath}/y`) },
    radius: num(`${layerPath}/blur`),
    spread: num(spreadPath),
    visible: true,
    blendMode: 'NORMAL' as const,
  };
  return type === 'DROP_SHADOW' ? { type, ...base } : { type, ...base };
}

/**
 * Reads a row's value in its collection's first mode — the mode Import makes
 * the collection's default — following aliases through the document.
 */
function specValueReader(doc: TokenDoc): (path: string) => ValueSpec | undefined {
  const rows = new Map<string, ValueSpec>();
  for (const spec of doc.collections) {
    const first = spec.modes[0];
    if (first === undefined) continue;
    for (const v of spec.variables) {
      const value = v.valuesByMode[first];
      if (value !== undefined) rows.set(`${spec.name}/${v.name}`, value);
    }
  }
  return (path) => {
    let value = rows.get(path);
    for (let hops = 0; value !== undefined && isAlias(value) && hops < 8; hops++) {
      value = rows.get(value.alias);
    }
    return value !== undefined && isAlias(value) ? undefined : value;
  };
}

function bindEffect(
  e: DropShadowEffect | InnerShadowEffect,
  x: Variable,
  y: Variable,
  blur: Variable,
  color: Variable,
  spread: Variable,
): Effect {
  let bound = figma.variables.setBoundVariableForEffect(e, 'offsetX', x);
  bound = figma.variables.setBoundVariableForEffect(bound, 'offsetY', y);
  bound = figma.variables.setBoundVariableForEffect(bound, 'radius', blur);
  bound = figma.variables.setBoundVariableForEffect(bound, 'spread', spread);
  return figma.variables.setBoundVariableForEffect(bound, 'color', color);
}
