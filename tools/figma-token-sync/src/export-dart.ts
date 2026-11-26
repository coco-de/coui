/// <reference types="@figma/plugin-typings" />

// Exports every local Figma Variable back out as generated Dart source
// (`figma_tokens.g.dart`) — the read-back counterpart to `import-tokens.ts`.
// Collection + group name → `abstract final class` (e.g. `CoUISpace`,
// `CoUIColors`), member name → CoUI-style token (`space16`, `primaryNormal`).
// Alias variables resolve to a Dart const reference on the target class so
// the single-source relationship survives the round trip. Multi-mode
// variables get a Pascal-case suffix from the second mode onward
// (`surfaceDark`).
//
// COLOR variables emit `coui_core`'s `CoreColor(0xAARRGGBB)` — not Flutter's
// `dart:ui` `Color` — because the round-trip target is `CoreColorScheme`
// (`packages/coui_core/lib/src/color/color_scheme.dart`), whose fields are
// all `CoreColor`. Emitting `Color` would force a `CoreColor(c.toARGB32())`
// bridge at every call site; emitting `CoreColor` directly lets
// `CoUIColors.xxx` drop straight into a `CoreColorScheme(...)` constructor.
//
// FLOAT variables emit `double`, except the two text values `CoreTextStyle`
// states differently from Figma — a font weight is `int`, a letter spacing is
// em with the unit in its member name (`…Em` / `…Px`). Both read straight into
// a `const CoreTextStyle(...)`; see `planTextNumbers`.

import {
  ExportedTokenDoc,
  buildTokenDoc,
  fingerprintCollections,
  serialiseTokenDoc,
} from './export-tokens-json';

const DART_RESERVED = new Set([
  'default', 'class', 'new', 'in', 'is', 'if', 'else', 'for', 'while', 'do',
  'switch', 'case', 'break', 'continue', 'return', 'true', 'false', 'null',
  'this', 'super', 'void', 'var', 'final', 'const', 'enum', 'extends',
  'with', 'implements', 'abstract', 'static',
]);

function words(s: string): string[] {
  // Strips emoji/punctuation, keeps alphanumeric runs (inner caps survive,
  // e.g. "SuperLight" stays intact).
  return String(s)
    .split(/[^a-zA-Z0-9]+/)
    .filter((w) => w.length > 0);
}
function cap(w: string): string {
  return w.charAt(0).toUpperCase() + w.slice(1);
}
function pascal(ws: string[]): string {
  return ws.map(cap).join('');
}
// Dart identifiers cannot start with a digit, and a Figma file may give its
// collections a sort prefix that is presentation rather than meaning —
// `0. Primitives`, `1.1 Semantic/Color`, `2. Component`. Feeding those
// straight through produced `0PrimitivesColors` / `11SemanticColorCoUIColors`,
// which is not valid Dart: the whole 39-class file failed to compile while
// the plugin still reported `✓ 667 variables → 39 Dart classes` (kobic#12765).
//
// Strip the prefix. What remains stays unique across collections
// (`Primitives*`, `SemanticColor*`, `SemanticTypography*`, `Component*`)
// because the sort number is not what distinguishes them. This mirrors the
// guard already applied to member names below (`space16`, `radius9999`) —
// only the class side was missing it.
function classIdent(ws: string[]): string {
  const p = pascal(ws).replace(/^[0-9]+/, '');
  // A collection named only with digits leaves nothing behind; fall back
  // rather than emit an empty segment.
  return p === '' ? 'Tokens' : p;
}
// Guards the finished identifier. `classIdent` handles the leading-digit case
// at the collection segment, but the group segment is appended afterwards and
// a future rename could reintroduce either failure mode.
const DART_IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;

/** Every planned name that cannot be a Dart identifier, as `class X` / `X.member`.
 *
 * Exported so the selftest can reach the class-name branch directly. Today
 * `classIdent` guarantees a leading letter, so no Figma fixture can trip that
 * branch — and a check nothing exercises quietly rots into dead code. The
 * member branch is reachable (a punctuation-only variable name leaves an empty
 * member), so a fixture covers that one. */
export function findInvalidIdentifiers(
  names: Iterable<{ className: string; member: string }>,
): string[] {
  const invalid: string[] = [];
  for (const info of names) {
    if (!DART_IDENT.test(info.className)) invalid.push(`class ${info.className}`);
    if (!DART_IDENT.test(info.member)) {
      invalid.push(`${info.className}.${info.member}`);
    }
  }
  return Array.from(new Set(invalid));
}
function camel(ws: string[]): string {
  if (ws.length === 0) return '';
  const head = ws[0].charAt(0).toLowerCase() + ws[0].slice(1);
  return head + ws.slice(1).map(cap).join('');
}
function hex2(n: number): string {
  const s = Math.round(n).toString(16).toUpperCase();
  return s.length < 2 ? `0${s}` : s;
}
function colorLiteral(c: RGBA | RGB): string {
  const a = 'a' in c && c.a != null ? c.a : 1;
  return `CoreColor(0x${hex2(a * 255)}${hex2(c.r * 255)}${hex2(c.g * 255)}${hex2(c.b * 255)})`;
}
function numLiteral(n: number): string {
  return String(n);
}
function strLiteral(s: string): string {
  return `'${String(s).split('\\').join('\\\\').split("'").join("\\'")}'`;
}

interface NamePlan {
  className: string;
  member: string;
  variable: Variable;
  collection: VariableCollection;
}

// ─── Text values the code reads in another type or unit ──────────────────
//
// A FLOAT variable is a plain `double` unless its scopes say what it is bound
// to. Two text values need more than that, because the type a consumer wires
// them into (`CoreTextStyle`) states them differently from Figma:
//
//   · a font weight is the CSS 100–900 integer `CoreTextStyle.fontWeight`
//     takes (`int?`), so it is emitted as `int`;
//   · a letter spacing is px in Figma (a bound number is read as px) and an
//     em ratio in code (`CoreTextStyle.letterSpacing`, multiplied by the
//     rendered font size). It is emitted as em — divided by the font size
//     that pairs with it — and the unit is in the member name (`…Em`). When
//     no font size pairs with it the value stays px and the name says so
//     (`…Px`).
//
// The letter-spacing members are renamed rather than keeping their names with
// a new unit: a consumer that read the px and divided it by the font size
// itself would keep compiling and divide twice. A name that is gone is a
// compile error at the call site instead.
//
// What a variable is comes from its scopes — Figma's own statement of what it
// may be bound to — and is carried across alias edges: a semantic weight that
// aliases an unscoped primitive makes the primitive a weight too, or the
// reference would assign a `double` to an `int`.

/** What the code reads a FLOAT variable as, when its scopes say so. */
export type TextNumberKind = 'weight' | 'letterSpacing';

/** The unit a letter-spacing member is emitted in. */
export type TrackingUnit = 'em' | 'px';

/** Decimal places an em is rounded to — kills the float32 noise a division of
 * Figma's stored px leaves (`-0.8999999761581421 / 36`), and still states
 * every `CoreLetterSpacing` step (`-0.005`) exactly. */
const EM_DECIMALS = 4;

function declaredKind(v: Variable): TextNumberKind | 'conflict' | null {
  // `ALL_SCOPES` needs no case of its own: Figma allows no other scope beside
  // it, so a variable that has it names neither of these.
  const scopes = v.scopes;
  if (!scopes) return null;
  const weight = scopes.indexOf('FONT_WEIGHT') >= 0;
  const tracking = scopes.indexOf('LETTER_SPACING') >= 0;
  if (weight && tracking) return 'conflict';
  if (weight) return 'weight';
  if (tracking) return 'letterSpacing';
  return null;
}

function aliasTargetId(raw: unknown): string | null {
  if (raw !== null && typeof raw === 'object' && 'type' in raw) {
    const alias = raw as { type: string; id: string };
    if (alias.type === 'VARIABLE_ALIAS') return alias.id;
  }
  return null;
}

/** The mode of [coll] an alias read from a consumer mode named [modeName]
 * lands in — the same-named mode, or the first one (Figma's resolution). */
function targetModeId(coll: VariableCollection, modeName: string): string {
  const named = coll.modes.find((m) => m.name === modeName);
  return named ? named.modeId : coll.modes[0].modeId;
}

/** The number a variable resolves to in the mode named [modeName], following
 * aliases; null when the chain ends anywhere but a number. */
function resolveNumber(
  id: string,
  modeName: string,
  byId: Map<string, Variable>,
  collById: Map<string, VariableCollection>,
  hops = 0,
): number | null {
  if (hops > 16) return null;
  const v = byId.get(id);
  if (!v || v.resolvedType !== 'FLOAT') return null;
  const coll = collById.get(v.variableCollectionId);
  if (!coll) return null;
  const raw = v.valuesByMode[targetModeId(coll, modeName)];
  const target = aliasTargetId(raw);
  if (target !== null) {
    return resolveNumber(target, modeName, byId, collById, hops + 1);
  }
  return typeof raw === 'number' ? raw : null;
}

/** How each classified FLOAT variable is emitted. */
export interface TextNumberPlan {
  kind: Map<string, TextNumberKind>;
  /** Letter-spacing variables only. */
  unit: Map<string, TrackingUnit>;
  /** Letter-spacing variable id → the font-size variable its em divides by. */
  pair: Map<string, Variable>;
  notes: string[];
}

/** The font-size variable a letter spacing pairs with: the same name in the
 * same collection with its `letter-spacing` segment read as `font-size`
 * (`letter-spacing/body-medium` ↔ `font-size/body-medium`). */
function pairedFontSize(
  v: Variable,
  byCollectionAndName: Map<string, Variable>,
): Variable | null {
  const segs = v.name.split('/');
  const at = segs.indexOf('letter-spacing');
  if (at < 0) return null;
  const pairSegs = segs.slice();
  pairSegs[at] = 'font-size';
  const pair = byCollectionAndName.get(
    `${v.variableCollectionId}\u0000${pairSegs.join('/')}`,
  );
  return pair && pair.resolvedType === 'FLOAT' ? pair : null;
}

/** Classifies the FLOAT variables whose scopes name a text value, carries the
 * kind across alias edges, and picks each letter spacing's unit.
 *
 * Exported so the selftest can drive it directly. */
export function planTextNumbers(
  collections: VariableCollection[],
  variables: Variable[],
): TextNumberPlan {
  const collById = new Map<string, VariableCollection>();
  for (const c of collections) collById.set(c.id, c);
  const byId = new Map<string, Variable>();
  const byCollectionAndName = new Map<string, Variable>();
  for (const v of variables) {
    byId.set(v.id, v);
    byCollectionAndName.set(`${v.variableCollectionId}\u0000${v.name}`, v);
  }

  // Alias edges between FLOAT variables, as connected components.
  const parent = new Map<string, string>();
  const find = (id: string): string => {
    let root = id;
    while (parent.has(root) && parent.get(root) !== root) {
      root = parent.get(root)!;
    }
    parent.set(id, root);
    return root;
  };
  const union = (a: string, b: string) => {
    const ra = find(a);
    const rb = find(b);
    if (ra !== rb) parent.set(ra, rb);
  };
  for (const v of variables) {
    if (v.resolvedType !== 'FLOAT') continue;
    find(v.id);
    for (const modeId of Object.keys(v.valuesByMode)) {
      const target = aliasTargetId(v.valuesByMode[modeId]);
      const t = target !== null ? byId.get(target) : undefined;
      if (t && t.resolvedType === 'FLOAT') union(v.id, t.id);
    }
  }
  const members = new Map<string, Variable[]>();
  for (const v of variables) {
    if (v.resolvedType !== 'FLOAT') continue;
    const root = find(v.id);
    if (!members.has(root)) members.set(root, []);
    members.get(root)!.push(v);
  }

  const kind = new Map<string, TextNumberKind>();
  const notes: string[] = [];
  members.forEach((group) => {
    let weight = false;
    let tracking = false;
    let conflict = false;
    for (const v of group) {
      const k = declaredKind(v);
      if (k === 'conflict') conflict = true;
      if (k === 'weight') weight = true;
      if (k === 'letterSpacing') tracking = true;
    }
    if (!weight && !tracking && !conflict) return;
    if (conflict || (weight && tracking)) {
      notes.push(
        `${group.map((v) => v.name).join(' · ')} (굵기와 자간 scope 가 한 별칭 사슬에 섞임: double 로 둔다)`,
      );
      return;
    }
    if (weight) {
      const fractional: string[] = [];
      for (const v of group) {
        for (const modeId of Object.keys(v.valuesByMode)) {
          const raw = v.valuesByMode[modeId];
          if (typeof raw === 'number' && !Number.isInteger(raw)) {
            fractional.push(`${v.name}=${raw}`);
          }
        }
      }
      if (fractional.length > 0) {
        notes.push(
          `${fractional.join(' · ')} (굵기인데 정수가 아님: double 로 둔다)`,
        );
        return;
      }
    }
    for (const v of group) kind.set(v.id, weight ? 'weight' : 'letterSpacing');
  });

  // A letter spacing is em when every one of its modes can be: a number with
  // a font size to divide it by, or an alias to an em member. Otherwise it
  // stays px — one unit per member, since the name carries it.
  const unit = new Map<string, TrackingUnit>();
  const pair = new Map<string, Variable>();
  const visiting = new Set<string>();
  const unitOf = (id: string): TrackingUnit => {
    const known = unit.get(id);
    if (known) return known;
    if (visiting.has(id)) return 'px';
    visiting.add(id);
    const v = byId.get(id)!;
    const coll = collById.get(v.variableCollectionId)!;
    const size = pairedFontSize(v, byCollectionAndName);
    let em = true;
    for (const mode of coll.modes) {
      const raw = v.valuesByMode[mode.modeId];
      if (raw === undefined) continue;
      const target = aliasTargetId(raw);
      if (target !== null) {
        if (!kind.has(target) || unitOf(target) !== 'em') em = false;
        continue;
      }
      const s = size
        ? resolveNumber(size.id, mode.name, byId, collById)
        : null;
      if (s === null || s <= 0) em = false;
    }
    visiting.delete(id);
    const result: TrackingUnit = em ? 'em' : 'px';
    unit.set(id, result);
    if (size) pair.set(id, size);
    return result;
  };
  kind.forEach((k, id) => {
    if (k === 'letterSpacing') unitOf(id);
  });

  return { kind, unit, pair, notes };
}

function planNames(
  collections: VariableCollection[],
  variables: Variable[],
  textNumbers: TextNumberPlan,
): Map<string, NamePlan> {
  const plan = new Map<string, NamePlan>();
  const usedByClass = new Map<string, Set<string>>();
  const collById = new Map<string, VariableCollection>();
  for (const c of collections) collById.set(c.id, c);

  for (const v of variables) {
    const coll = collById.get(v.variableCollectionId);
    if (!coll) continue;
    const segs = v.name.split('/');
    const groupSeg = segs.length > 1 ? segs[0] : 'misc';
    const rest = segs.length > 1 ? segs.slice(1) : segs;

    const collWords = words(coll.name);
    const groupWords = words(groupSeg);
    const groupPascal =
      groupSeg.toLowerCase() === 'color' ? 'Colors' : pascal(groupWords);
    const className = classIdent(collWords) + groupPascal;

    const restWords: string[] = [];
    // A nested loop rather than `push(...words(seg))`. This file is in the
    // plugin's bundle (`code.ts` imports `exportDartTokens`), and a spread in
    // call position is the shape the plugin VM refused with `InternalError:
    // stack underflow` — it passes each element as its own argument, and the
    // target is es2016, so esbuild leaves the spread in place rather than
    // lowering it. Every other one in this tool was already a loop for this
    // reason; this was the last.
    for (const seg of rest) {
      for (const w of words(seg)) restWords.push(w);
    }
    let member = camel(restWords);
    if (member === '') member = camel(groupWords);
    if (/^[0-9]/.test(member)) member = camel(groupWords) + member; // space16, radius9999
    if (DART_RESERVED.has(member)) member = `${member}_`;
    // The unit rides in a letter spacing's name (see the section above).
    if (textNumbers.kind.get(v.id) === 'letterSpacing') {
      member += textNumbers.unit.get(v.id) === 'em' ? 'Em' : 'Px';
    }

    if (!usedByClass.has(className)) usedByClass.set(className, new Set());
    const used = usedByClass.get(className)!;
    let unique = member;
    let n = 2;
    while (used.has(unique)) {
      unique = member + n;
      n++;
    }
    used.add(unique);

    plan.set(v.id, { className, member: unique, variable: v, collection: coll });
  }
  return plan;
}

function dartType(
  resolvedType: VariableResolvedDataType,
  kind: TextNumberKind | undefined,
): string {
  if (resolvedType === 'COLOR') return 'CoreColor';
  if (resolvedType === 'FLOAT') return kind === 'weight' ? 'int' : 'double';
  if (resolvedType === 'BOOLEAN') return 'bool';
  return 'String';
}

function emLiteral(px: number, fontSize: number): string {
  // `toFixed` then `Number` drops the trailing zeros and a `-0`.
  return String(Number((px / fontSize).toFixed(EM_DECIMALS)) + 0);
}

function modeSuffix(coll: VariableCollection, modeId: string): string {
  // First mode gets no suffix; the rest get a Pascal-case suffix from the
  // mode name (Light/Dark, ...).
  if (coll.modes.length < 2 || coll.modes[0].modeId === modeId) return '';
  const mode = coll.modes.find((m) => m.modeId === modeId);
  return mode ? pascal(words(mode.name)) : '';
}

/**
 * Suffix for an alias *target*, whose modes are its own collection's.
 *
 * The consumer's suffix cannot be reused here. It is derived from the
 * consumer's collection, and the target may have an entirely different mode
 * set — `Primitives` is single-mode ("Value"), so every reference from a
 * four-mode Semantic collection was emitting `…Dark` / `…HCLight` names that
 * the Primitives class never declares. 452 dangling references; the whole
 * file failed to compile (kobic#12993).
 *
 * Resolution is by mode *name*: Figma reads an alias through the target's own
 * modes, so a "Dark" consumer takes the target's "Dark" when it has one and
 * its only mode when it does not.
 */
function aliasSuffix(
  targetColl: VariableCollection,
  consumerModeName: string,
): string {
  if (targetColl.modes.length < 2) return '';
  const mode = targetColl.modes.find((m) => m.name === consumerModeName);
  // No same-named mode: the alias resolves through the target's first mode,
  // which is the unsuffixed member.
  return mode ? modeSuffix(targetColl, mode.modeId) : '';
}

/** Every `Class.member` reference that no `Class.member` declaration answers.
 *
 * Exported so the selftest can drive it directly. This is the reference-level
 * counterpart to `findInvalidIdentifiers`: that one checks a name is spellable
 * as Dart, this one checks the name resolves to something. #4607 added the
 * former, and the export still emitted a file whose 452 references pointed at
 * nothing — a name can be perfectly legal and still be a dangling reference. */
export function findDanglingReferences(
  declared: Iterable<string>,
  referenced: Iterable<{ from: string; to: string }>,
): string[] {
  const have = new Set(declared);
  const missing: string[] = [];
  for (const ref of referenced) {
    if (!have.has(ref.to)) missing.push(`${ref.from} → ${ref.to}`);
  }
  return missing;
}

interface GenerateDartResult {
  content: string;
  classCount: number;
  skipped: string[];
  /** One line each for the text numbers the export typed (see
   * `planTextNumbers`), then what it could not type. */
  textNumbers: string[];
}

function generateDart(
  collections: VariableCollection[],
  variables: Variable[],
  fingerprint: string,
): GenerateDartResult {
  const textNumbers = planTextNumbers(collections, variables);
  const plan = planNames(collections, variables, textNumbers);
  const byId = new Map<string, Variable>();
  for (const v of variables) byId.set(v.id, v);
  const collById = new Map<string, VariableCollection>();
  for (const c of collections) collById.set(c.id, c);

  // Refuse to emit source that cannot compile.
  //
  // The export used to report success for a file whose every class name began
  // with a digit — `✓ 667 variables → 39 Dart classes` while not one of the 39
  // was a legal Dart identifier (kobic#12765). A "successful" export nobody can
  // build is worse than a failed one: the breakage surfaces downstream, far
  // from its cause. `classIdent` now prevents the known case; this check is the
  // backstop for the ones a future rename invents.
  const invalid = findInvalidIdentifiers(plan.values());
  if (invalid.length > 0) {
    const head = invalid.slice(0, 5).join(', ');
    throw new Error(
      `Dart 식별자로 쓸 수 없는 이름 ${invalid.length}건: ${head}` +
        `${invalid.length > 5 ? ' …' : ''}. ` +
        'Figma 컬렉션/그룹 이름을 확인하세요 (식별자는 문자 또는 _ 로 시작해야 합니다).',
    );
  }

  let hasColor = false;
  const skipped: string[] = [];

  const classes = new Map<string, string[]>();
  const classOrder: string[] = [];

  // Collected across the whole pass, not per-variable: a reference may be
  // emitted before the member it names, so resolution can only be judged once
  // every declaration is in.
  const declared = new Set<string>();
  const referenced: { from: string; to: string }[] = [];

  for (const v of variables) {
    const info = plan.get(v.id);
    if (!info) continue;
    if (Object.values(v.valuesByMode).some((value) =>
      typeof value === 'object' && 'color' in value && 'opacity' in value)) {
      skipped.push(`${v.name} (composed color: TokenDoc v1 미지원)`);
      continue;
    }
    const coll = info.collection;
    if (v.resolvedType === 'COLOR') hasColor = true;

    for (const mode of coll.modes) {
      const raw = v.valuesByMode[mode.modeId];
      if (raw === undefined) continue;
      const suffix = modeSuffix(coll, mode.modeId);
      const memberName = info.member + suffix;
      declared.add(`${info.className}.${memberName}`);

      const kind = textNumbers.kind.get(v.id);
      const unit = textNumbers.unit.get(v.id);
      let unitNote: string | null = null;
      let valueExpr: string | null = null;
      if (raw !== null && typeof raw === 'object' && 'type' in raw && raw.type === 'VARIABLE_ALIAS') {
        const target = plan.get(raw.id);
        if (
          target &&
          kind === 'letterSpacing' &&
          unit === 'px' &&
          textNumbers.unit.get(raw.id) === 'em'
        ) {
          // A px member cannot name an em one; the px the alias resolves to
          // is written instead.
          const px = resolveNumber(raw.id, mode.name, byId, collById);
          if (px === null) {
            skipped.push(`${v.name} (자간 별칭이 숫자로 풀리지 않음)`);
            continue;
          }
          valueExpr = numLiteral(px);
          textNumbers.notes.push(
            `${v.name} (px 자간이 em 대상을 가리켜 그 px 값을 적었다: 별칭 관계는 Dart 에 남지 않는다)`,
          );
        } else if (target) {
          // The target's own modes decide its suffix — not the consumer's.
          valueExpr = `${target.className}.${target.member}${aliasSuffix(target.collection, mode.name)}`;
          referenced.push({
            from: `${info.className}.${memberName}`,
            to: valueExpr,
          });
        } else {
          skipped.push(`${v.name} (alias → 미해석: 외부 라이브러리?)`);
          continue;
        }
        if (kind === 'letterSpacing') {
          unitNote = unit === 'em'
            ? 'em — 별칭 대상의 em 을 따른다. `CoreTextStyle.letterSpacing` 에 그대로 넣는다.'
            : 'px — Figma 값 그대로. `CoreTextStyle.letterSpacing` 에는 글자 크기로 나눠 넣는다.';
        }
      } else if (v.resolvedType === 'COLOR') {
        valueExpr = colorLiteral(raw as RGBA | RGB);
      } else if (v.resolvedType === 'FLOAT' && kind === 'weight') {
        valueExpr = String(Math.round(raw as number));
      } else if (v.resolvedType === 'FLOAT' && kind === 'letterSpacing') {
        const size = textNumbers.pair.get(v.id);
        const fontSize = size
          ? resolveNumber(size.id, mode.name, byId, collById)
          : null;
        if (unit === 'em' && size && fontSize !== null && fontSize > 0) {
          valueExpr = emLiteral(raw as number, fontSize);
          unitNote =
            `em — Figma 의 px 를 \`${size.name}\` (${numLiteral(fontSize)}) 로 나눈 값. ` +
            '`CoreTextStyle.letterSpacing` 에 그대로 넣는다.';
        } else {
          valueExpr = numLiteral(raw as number);
          unitNote =
            'px — Figma 값 그대로(짝이 되는 `font-size` 가 없다). ' +
            '`CoreTextStyle.letterSpacing` 에는 글자 크기로 나눠 넣는다.';
        }
      } else if (v.resolvedType === 'FLOAT') {
        valueExpr = numLiteral(raw as number);
      } else if (v.resolvedType === 'BOOLEAN') {
        valueExpr = raw ? 'true' : 'false';
      } else {
        valueExpr = strLiteral(raw as string);
      }

      if (!classes.has(info.className)) {
        classes.set(info.className, []);
        classOrder.push(info.className);
      }
      // The unit line goes above the `Figma:` line: a consumer that pairs a
      // member with its source reads that line and the `static const` right
      // after it as one, so nothing may stand between them.
      classes.get(info.className)!.push(
        (unitNote ? `  /// ${unitNote}\n` : '') +
        `  /// Figma: \`${coll.name} / ${v.name}\`${suffix ? ` (mode: ${suffix})` : ''}\n` +
        `  static const ${dartType(v.resolvedType, kind)} ${memberName} = ${valueExpr};`,
      );
    }
  }

  // Refuse to emit source whose references point at nothing.
  //
  // #4607 added the identifier check above, and the export still produced a
  // file that could not compile: every name was legal Dart, but 452 alias
  // references named members no class declared (kobic#12993). A legal name is
  // not a resolved one, so the two checks are separate — this is the second.
  const dangling = findDanglingReferences(declared, referenced);
  if (dangling.length > 0) {
    const head = dangling.slice(0, 5).join(', ');
    throw new Error(
      `해소되지 않는 alias 참조 ${dangling.length}건: ${head}` +
        `${dangling.length > 5 ? ' …' : ''}. ` +
        '컬렉션 간 모드 구성이 어긋났을 수 있습니다.',
    );
  }

  const lines: string[] = [
    '// GENERATED by figma-token-sync (Export Dart Code) — do not edit by hand.',
    // The `export` fingerprint is the same value `meta.export` carries in the
    // JSON emitted alongside this file. A consumer comparing the two can then
    // assert they are one snapshot instead of assuming it.
    `// Source: Figma local variables (${collections.length} collections, ${variables.length} variables, export ${fingerprint})`,
    '// ignore_for_file: public_member_api_docs',
    '',
  ];
  if (hasColor) {
    lines.push("import 'package:coui_core/coui_core.dart' show CoreColor;", '');
  }
  for (const cn of classOrder) {
    lines.push(`abstract final class ${cn} {`, ...classes.get(cn)!, '}', '');
  }

  let weights = 0;
  let em = 0;
  let px = 0;
  textNumbers.kind.forEach((k, id) => {
    if (!plan.has(id)) return;
    if (k === 'weight') weights++;
    else if (textNumbers.unit.get(id) === 'em') em++;
    else px++;
  });
  const typed: string[] = [];
  if (weights + em + px > 0) {
    typed.push(
      `✓ 굵기 ${weights}개 → int · 자간 ${em}개 → em(…Em)` +
        (px > 0 ? ` · ${px}개 → px(…Px, 짝이 되는 font-size 없음)` : ''),
    );
  }
  for (const n of textNumbers.notes) typed.push(`! ${n}`);

  return {
    content: lines.join('\n'),
    classCount: classOrder.length,
    skipped,
    textNumbers: typed,
  };
}

/**
 * Emits both token artefacts from one snapshot: `figma_tokens.g.dart` and the
 * `tokens.figma.json` that `importTokens` reads back.
 *
 * They ship together because a consumer's drift test compares them, and that
 * comparison is only meaningful if both describe the same file at the same
 * moment — see the header of `export-tokens-json.ts`. Both carry the same
 * `export` fingerprint so that "same snapshot" is checkable rather than
 * assumed. The Dart file stays at `files[0]`.
 */
export async function exportDartTokens(): Promise<{
  files: { name: string; content: string }[];
  log: string[];
}> {
  const [collections, variables] = await Promise.all([
    figma.variables.getLocalVariableCollectionsAsync(),
    figma.variables.getLocalVariablesAsync(),
  ]);
  if (variables.length === 0) {
    throw new Error('로컬 Variables 가 없습니다. 먼저 Import to Variables 를 실행하세요.');
  }

  // JSON is built first: the Dart header stamps its fingerprint.
  const json = buildTokenDoc(collections, variables);
  const fingerprint = fingerprintCollections(json.collections);
  const out = generateDart(collections, variables, fingerprint);

  let emitted = 0;
  for (const c of json.collections) emitted += c.variables.length;

  const doc: ExportedTokenDoc = {
    meta: {
      generator: 'figma-token-sync (Export Dart Code)',
      collections: json.collections.length,
      variables: emitted,
      export: fingerprint,
    },
    collections: json.collections,
  };

  const log = [
    `✓ ${variables.length} variables → ${out.classCount} Dart classes`,
    `✓ ${emitted} variables → ${json.collections.length} JSON collections`,
    // The fingerprint is printed on its own line and named, because the user
    // is the one who has to notice a half-download. Both files carry it, so
    // "do these two belong together?" is answerable by eye.
    `✓ export ${fingerprint} — .dart 헤더와 .json 의 meta.export 가 이 값으로 같아야 짝입니다`,
  ];
  // The two passes reject the same unresolvable aliases, so the union is
  // reported once rather than twice.
  const skipped: string[] = [];
  for (const s of out.skipped) if (skipped.indexOf(s) < 0) skipped.push(s);
  for (const s of json.skipped) if (skipped.indexOf(s) < 0) skipped.push(s);
  for (const s of skipped) log.push(`! skipped: ${s}`);
  for (const t of out.textNumbers) log.push(t);

  return {
    files: [
      { name: 'figma_tokens.g.dart', content: out.content },
      { name: 'tokens.figma.json', content: serialiseTokenDoc(doc) },
    ],
    log,
  };
}
