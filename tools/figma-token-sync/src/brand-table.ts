// The brand value tables the plugin carries (`src/data/brands.json`, written by
// `packages/coui_core/bin/export_figma_tokens.dart` from the code brands in
// `bin/figma_brands/brands.dart`) — and the pure parts of applying one.
//
// A brand is not a collection of the library. The library carries ONE colour
// collection (`library.collection`, `Semantic/ Color · CoUI`), and a brand is
// what a consumer file lays over it: an extension of that collection whose
// overrides are the values the brand states and nothing else, so the rest keeps
// following CoUI. The table is exactly that difference — per slot, per mode —
// so applying it is "write each entry into the extension variable of the same
// name", and re-applying it after the file was reopened (Figma drops the
// overrides of variables the file stopped using, `collection-overrides.ts`) is
// the same call.
//
// This file is data and planning only — no `figma` calls — so the selftest can
// drive every decision without a document. The writes are
// `collection-overrides.ts`.

import brandsJson from './data/brands.json';

/** A Figma colour, 0–1. */
export interface BrandColor {
  r: number;
  g: number;
  b: number;
  a: number;
}

/** One slot the brand states: its colour in the modes where it is not CoUI's. */
export interface BrandOverride {
  name: string;
  valuesByMode: Record<string, BrandColor>;
}

export interface BrandTable {
  id: string;
  displayName: string;
  overrides: BrandOverride[];
}

export interface BrandsDoc {
  library: {
    /** The code brand whose colours are the library collection's. */
    brand: string;
    /** The library collection every table extends. */
    collection: string;
    modes: string[];
  };
  brands: BrandTable[];
}

export const BRANDS: BrandsDoc = brandsJson as unknown as BrandsDoc;

/** The mark between the library collection's name and the brand's in an extension's name. */
export const BRAND_EXTENSION_SEPARATOR = ' → ';

/**
 * The name the brand's extension is created under — `Semantic/ Color · CoUI →
 * Medibooks`. The name is how the plugin recognises the extension later (the
 * resync reads the brand off it), so it is derived from the table, never typed.
 */
export function brandExtensionNameFor(
  brand: Pick<BrandTable, 'displayName'>,
  doc: BrandsDoc = BRANDS,
): string {
  return `${doc.library.collection}${BRAND_EXTENSION_SEPARATOR}${brand.displayName}`;
}

/** The brand an extension of this name belongs to, or `null` when it is not one of the code brands'. */
export function brandOfExtension(name: string, doc: BrandsDoc = BRANDS): BrandTable | null {
  return doc.brands.find((b) => brandExtensionNameFor(b, doc) === name) ?? null;
}

export function findBrand(idOrName: string, doc: BrandsDoc = BRANDS): BrandTable | null {
  const wanted = idOrName.trim().toLowerCase();
  return (
    doc.brands.find((b) => b.id.toLowerCase() === wanted || b.displayName.toLowerCase() === wanted) ??
    null
  );
}

/** An extension variable the table can write to. */
export interface BrandFillTarget {
  id: string;
  name: string;
  resolvedType: string;
}

export interface BrandFillMode {
  modeId: string;
  name: string;
}

export interface BrandFillWrite {
  variableId: string;
  name: string;
  modeId: string;
  modeName: string;
  value: BrandColor;
}

export interface BrandFillPlan {
  /** The (variable, mode) pairs to write — those not already holding the value. */
  set: BrandFillWrite[];
  /** Pairs that already hold the table's value. */
  alreadyRight: number;
  /** Table rows with no variable of that name in the extension: the file does not carry it (yet). */
  absent: string[];
  /** Table rows whose variable is not a COLOR in this file. */
  notColor: string[];
  /** Table modes the extension does not have. */
  noMode: string[];
  /** Overrides the extension holds that the table does not state (hand-set, or an older table's). */
  strayOverrides: number;
}

const EPSILON = 1e-6;

export function sameColor(a: unknown, b: BrandColor): boolean {
  if (a == null || typeof a !== 'object') return false;
  const c = a as Partial<BrandColor>;
  const alpha = c.a === undefined ? 1 : c.a;
  return (
    typeof c.r === 'number' &&
    typeof c.g === 'number' &&
    typeof c.b === 'number' &&
    Math.abs(c.r - b.r) < EPSILON &&
    Math.abs(c.g - b.g) < EPSILON &&
    Math.abs(c.b - b.b) < EPSILON &&
    Math.abs(alpha - b.a) < EPSILON
  );
}

/**
 * What writing [table] into an extension takes: for every row, the extension
 * variable of the same name, in every mode of the row the extension has.
 * Matching is by NAME — the one thing a library variable keeps across the
 * file being reopened and the variable being imported again.
 *
 * Nothing is guessed: a row with no variable of that name is `absent`, a row
 * whose variable is not a COLOR is `notColor`, and neither is written.
 * [overrides] is the extension's current `variableOverrides`, so a value that is
 * already in place is not written again and an override the table does not
 * state is counted, not removed.
 */
export function planBrandFill(
  table: BrandTable,
  variables: readonly BrandFillTarget[],
  modes: readonly BrandFillMode[],
  overrides: Readonly<Record<string, Readonly<Record<string, unknown>>>>,
): BrandFillPlan {
  const byName = new Map<string, BrandFillTarget>();
  for (const v of variables) if (!byName.has(v.name)) byName.set(v.name, v);
  const modeByName = new Map(modes.map((m) => [m.name, m]));

  const plan: BrandFillPlan = {
    set: [],
    alreadyRight: 0,
    absent: [],
    notColor: [],
    noMode: [],
    strayOverrides: 0,
  };
  const stated = new Set<string>(); // `${variableId}\u0000${modeId}`
  for (const row of table.overrides) {
    const target = byName.get(row.name);
    if (target == null) {
      plan.absent.push(row.name);
      continue;
    }
    if (target.resolvedType !== 'COLOR') {
      plan.notColor.push(row.name);
      continue;
    }
    for (const [modeName, value] of Object.entries(row.valuesByMode)) {
      const mode = modeByName.get(modeName);
      if (mode == null) {
        if (!plan.noMode.includes(modeName)) plan.noMode.push(modeName);
        continue;
      }
      stated.add(`${target.id}\u0000${mode.modeId}`);
      if (sameColor(overrides[target.id]?.[mode.modeId], value)) {
        plan.alreadyRight += 1;
      } else {
        plan.set.push({
          variableId: target.id,
          name: row.name,
          modeId: mode.modeId,
          modeName,
          value,
        });
      }
    }
  }
  for (const [variableId, byMode] of Object.entries(overrides)) {
    for (const modeId of Object.keys(byMode)) {
      if (!stated.has(`${variableId}\u0000${modeId}`)) plan.strayOverrides += 1;
    }
  }
  return plan;
}
