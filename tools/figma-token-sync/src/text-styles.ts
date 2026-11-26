/// <reference types="@figma/plugin-typings" />

// Canvas text styles — upserted BY NAME from the `textStyles` section of
// `build/tokens.figma.json`, one per `CoreTypography` role.
//
// Why the plugin owns these at all: the rule is "typography reaches a text
// node through a text style, never through a variable bound on the node"
// (design-tokens.md, Figma 캔버스 절). A style is therefore the only carrier
// that can move a role's weight/line-height onto the canvas, and it has to be
// regenerated from code the same way the variables are — otherwise the
// canvas keeps the weight the designer typed the day the style was made.
// That is exactly what happened: `label` went to 500 in code (#4556) and the
// five Label styles stayed Regular, with nothing to report the gap.
//
// What binds and what is written as a literal — measured, not assumed:
//   fontSize / letterSpacing / fontWeight / fontFamily → bound to the
//     semantic variable the export names (size + tracking follow the
//     responsive modes, weight follows the role group).
//   lineHeight → PERCENT literal. Figma reads a number variable bound to
//     line-height as PIXELS whatever unit the field held before binding
//     (`{PERCENT,140}` + bind(1.4) → `{PIXELS,1.4}` on a probe node), so a
//     ratio cannot reach a style through a variable. The literal is still
//     driven by the export, so re-running Import moves it.
//   lineHeight of a fixed-box role (the code roles' 21px grid) → a PIXELS
//     literal bound to the variable the export names. The same reading that
//     rules a ratio out is exactly what a box in pixels wants, so these are
//     the one line height a variable can carry. (The reading was measured on
//     a node; a style's binding follows it but was not probed on its own.)
//
// Idempotent and non-destructive like `importTokens`: an existing style is
// adopted by name (its id, and every node using it, survive), a missing one
// is created, nothing is deleted.

import { weightStyle } from './paint';
import { roleLeaf } from './text-nodes';

export interface TextStyleSpec {
  name: string;
  role: string;
  fontFamily: { variable: string; value: string };
  fontSize: { variable: string; value: number };
  fontWeight: { variable: string; value: number };
  letterSpacing: { variable: string; value: number };
  /** A multiplier role's line height, in percent — written as a literal. */
  lineHeightPercent?: number;
  /** A fixed-box role's line height in px and the variable that holds it.
   *  A spec states exactly one of the two. */
  lineHeightPx?: { variable: string; value: number };
  description?: string;
}

// `byPath` is the `<Collection>/<variable>` → Variable index `importTokens`
// builds while upserting — the styles are bound against the same objects the
// variables were just written to, so a style can never point at a variable
// the import did not declare.
/**
 * The style name a typography role is stored under (`labelXl2` → `Label/XL2`,
 * `codeSm` → `Code/SM`, `bodyMedium` → `Body/Medium`).
 *
 * A leaf that is a size code — one or two letters, then digits
 * (`xs` · `sm` · `md` · `xl` · `xl2`) — is uppercased; a word leaf (`large` ·
 * `medium` · `small`) is capitalised.
 *
 * This rule lives in the Dart exporter (`_textStyleNameOf`) and the names it
 * produces are what `upsertTextStyles` keys on. Reproducing it here is a
 * SECOND copy, which is a real cost — an exporter-side rename would not reach
 * this one, and the symptom is silent (the builder looks up a name nobody
 * created, finds nothing, and simply does not attach a style). So
 * `scripts/selftest-text-style-name.ts` reads the exporter's own source: every
 * role it declares must map to a name here, and the decisive fragments of the
 * Dart rule are pinned so that editing it fails the harness instead of
 * quietly desyncing this copy.
 *
 * Accepts either spelling: builders know roles as camelCase (`labelXl2`),
 * the exporter as kebab (`label-xl2`), and `roleLeaf` is idempotent on the
 * latter.
 */
export function textStyleNameOf(role: string): string | null {
  const parts = roleLeaf(role).split('-');
  if (parts.length < 2 || parts[0] === '' || parts[1] === '') return null;
  const cap = (v: string): string => v.charAt(0).toUpperCase() + v.slice(1);
  const leaf = /^[a-z]{1,2}\d*$/.test(parts[1]) ? parts[1].toUpperCase() : cap(parts[1]);
  return `${cap(parts[0])}/${leaf}`;
}

/**
 * Local text styles indexed by name. One place, because three callers want
 * the same Map and a third inline copy is how the two existing ones drift.
 */
export async function loadTextStyleIndex(): Promise<Map<string, TextStyle>> {
  const byName = new Map<string, TextStyle>();
  for (const s of await figma.getLocalTextStylesAsync()) byName.set(s.name, s);
  return byName;
}

export async function upsertTextStyles(
  specs: readonly TextStyleSpec[],
  byPath: ReadonlyMap<string, Variable>,
): Promise<string[]> {
  const log: string[] = [];
  const byName = await loadTextStyleIndex();

  let created = 0;
  let adopted = 0;
  let failed = 0;
  for (const spec of specs) {
    const family = spec.fontFamily.value;
    const face = weightStyle(spec.fontWeight.value);
    try {
      // Read before anything is written: a spec with no line height would
      // otherwise leave the style counted and half-written.
      const lineHeight = specLineHeight(spec);
      // Every text mutation needs the face loaded first — including binding
      // fontWeight, which swaps the face under the style.
      await figma.loadFontAsync({ family, style: face });
      let style = byName.get(spec.name);
      if (style) {
        adopted++;
      } else {
        style = figma.createTextStyle();
        style.name = spec.name;
        byName.set(spec.name, style);
        created++;
      }
      style.fontName = { family, style: face };
      style.fontSize = spec.fontSize.value;
      // A style that was a fixed box before keeps its binding, and a bound
      // variable overwrites the literal — the percent would never land.
      if (spec.lineHeightPx == null && style.boundVariables?.lineHeight != null) {
        style.setBoundVariable('lineHeight', null);
      }
      style.lineHeight = lineHeight;
      style.letterSpacing = { unit: 'PIXELS', value: spec.letterSpacing.value };
      if (spec.description != null && style.description !== spec.description) {
        style.description = spec.description;
      }
      bind(style, 'fontFamily', spec.fontFamily.variable, byPath, log);
      bind(style, 'fontSize', spec.fontSize.variable, byPath, log);
      bind(style, 'fontWeight', spec.fontWeight.variable, byPath, log);
      bind(style, 'letterSpacing', spec.letterSpacing.variable, byPath, log);
      if (spec.lineHeightPx != null) {
        bind(style, 'lineHeight', spec.lineHeightPx.variable, byPath, log);
      }
    } catch (e) {
      failed++;
      log.push(`! text style "${spec.name}": ${(e as Error).message ?? String(e)}`);
    }
  }
  log.push(
    `✓ text styles: ${adopted} adopted, ${created} created` +
      (failed ? `, ${failed} failed` : ''),
  );
  return log;
}

/** The line height a spec states — the fixed box when it has one. */
function specLineHeight(spec: TextStyleSpec): LineHeight {
  if (spec.lineHeightPx != null) return { unit: 'PIXELS', value: spec.lineHeightPx.value };
  if (spec.lineHeightPercent != null) return { unit: 'PERCENT', value: spec.lineHeightPercent };
  throw new Error('states neither lineHeightPercent nor lineHeightPx');
}

// The export writes the box as the same double the variable holds, so the two
// agree unless the style was edited; this only absorbs a float round trip.
const LINE_HEIGHT_PX_EPSILON = 1e-6;

function bind(
  style: TextStyle,
  field: VariableBindableTextField,
  path: string,
  byPath: ReadonlyMap<string, Variable>,
  log: string[],
): void {
  const v = byPath.get(path);
  if (!v) {
    log.push(`! text style "${style.name}": variable not found for ${field}: ${path}`);
    return;
  }
  style.setBoundVariable(field, v);
}

// Read-only drift for the style section — the counterpart of
// `checkTokenDrift` for the carrier that variables cannot reach. Reports a
// style the export declares that the file lacks, a field that should be
// bound but is not (or is bound to a different variable), and a literal
// (weight face / line height) that differs from what the export says. A
// fixed-box role's line height is a bound PIXELS value; a multiplier role's
// is a PERCENT literal with no binding over it.
export async function checkTextStyleDrift(
  specs: readonly TextStyleSpec[],
): Promise<string[]> {
  const lines: string[] = [];
  const live = await figma.getLocalTextStylesAsync();
  const byName = new Map<string, TextStyle>();
  for (const s of live) byName.set(s.name, s);

  const idToPath = new Map<string, string>();
  for (const coll of await figma.variables.getLocalVariableCollectionsAsync()) {
    for (const id of coll.variableIds) {
      const v = await figma.variables.getVariableByIdAsync(id);
      if (v) idToPath.set(v.id, `${coll.name}/${v.name}`);
    }
  }
  const boundPath = (style: TextStyle, field: VariableBindableTextField): string | undefined => {
    const b = style.boundVariables?.[field];
    return b ? idToPath.get(b.id) : undefined;
  };

  for (const spec of specs) {
    const style = byName.get(spec.name);
    if (!style) {
      lines.push(`  ✗ ${spec.name}: 스타일 없음 (Import 가 만든다)`);
      continue;
    }
    const fields: [VariableBindableTextField, string][] = [
      ['fontSize', spec.fontSize.variable],
      ['fontWeight', spec.fontWeight.variable],
      ['letterSpacing', spec.letterSpacing.variable],
      ['fontFamily', spec.fontFamily.variable],
    ];
    if (spec.lineHeightPx != null) fields.push(['lineHeight', spec.lineHeightPx.variable]);
    for (const [field, want] of fields) {
      const got = boundPath(style, field);
      if (got === undefined) lines.push(`  ✗ ${spec.name}.${field}: 바인딩 없음 (export → ${want})`);
      else if (got !== want) lines.push(`  ✗ ${spec.name}.${field}: export → ${want} · live → ${got}`);
    }
    const face = weightStyle(spec.fontWeight.value);
    if (style.fontName.style !== face) {
      lines.push(`  ✗ ${spec.name}.fontName: export ${face} · live ${style.fontName.style}`);
    }
    const lh = style.lineHeight;
    const live = lh.unit === 'AUTO' ? 'AUTO' : `${Math.round(lh.value)}${lh.unit === 'PERCENT' ? '%' : 'px'}`;
    if (spec.lineHeightPx != null) {
      const want = spec.lineHeightPx.value;
      if (lh.unit !== 'PIXELS' || Math.abs(lh.value - want) > LINE_HEIGHT_PX_EPSILON) {
        lines.push(`  ✗ ${spec.name}.lineHeight: export ${want}px · live ${live}`);
      }
    } else {
      if (lh.unit !== 'PERCENT' || Math.round(lh.value) !== spec.lineHeightPercent) {
        lines.push(`  ✗ ${spec.name}.lineHeight: export ${spec.lineHeightPercent}% · live ${live}`);
      }
      const boundLh = boundPath(style, 'lineHeight');
      if (boundLh !== undefined) {
        lines.push(`  ✗ ${spec.name}.lineHeight: 바인딩 ${boundLh} 이 리터럴을 덮는다 (export 는 바인딩 없음)`);
      }
    }
  }
  if (lines.length === 0) {
    return [`✓ 텍스트 스타일 드리프트 없음 — ${specs.length}개가 export 와 일치합니다.`];
  }
  return [`■ 텍스트 스타일 드리프트 ${lines.length}건`, ...lines];
}
