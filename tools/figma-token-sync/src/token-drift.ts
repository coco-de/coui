/// <reference types="@figma/plugin-typings" />

// Token drift check (#4536) — compares what `export_figma_tokens.dart`
// declares against what the live file actually holds, and reports the
// difference. Read-only: it changes nothing.
//
// WHY THIS EXISTS. Three unrelated-looking bugs in one day turned out to be
// one thing: the exporter was already emitting the right value and the live
// file had never been re-synced. A scrim rendered at 0.005 opacity (the
// `opacity/*` primitives were still 0–1 while Figma's opacity binding reads
// 0–100); `RadioGroup` failed to build at all (`variable not found:
// Semantic/color/focus-ring`, a variable the export had been declaring since
// the focus-ring slot landed); `opacity/16` was simply absent.
//
// Every one of them fails SILENTLY. The binding is present and well-formed,
// so an audit that checks "is this bound?" passes. What none of them had was
// anything comparing the two sides. All three were found by a designer
// hitting the wrong pixels and asking why.
//
// WHY IN THE PLUGIN RATHER THAN CI. CI cannot open the Figma file, and the
// live file is half of the comparison. The plugin already reads every local
// variable for its own binding work, and the Import flow already takes the
// exporter's JSON as a paste — so this reuses both sides of a comparison the
// tool was already holding, and adds no new access path.
//
// The two directions are NOT symmetric, and the report keeps them apart:
//
//   MISSING (export declares it, live lacks it) — the direction that breaks
//   things. A builder asking for that variable throws; a designer binding by
//   name cannot find it. This is what all three of today's bugs were.
//
//   EXTRA (live holds it, export does not declare it) — the direction that
//   drifts quietly. Nothing breaks today: `importTokens` upserts by name and
//   never deletes, so these survive every re-import. But a component bound to
//   one is bound to a value no resolver in `coui_core` knows about, and the
//   canvas and the code have then diverged with nothing to say so.
//
//   VALUE (both sides have it, the values differ) — reported per mode. This
//   is the `opacity/*` case: present on both sides, bound correctly, and
//   wrong by a factor of 100.

import { canonicalCollection } from './variables';

// The subset of the import schema this comparison needs. Deliberately a
// separate local shape rather than an import of `TokenDoc`: this reads the
// same JSON but asks less of it, and a stricter shared type would make the
// check fail on documents it could still meaningfully compare.
interface DriftDoc {
  collections: {
    name: string;
    modes: string[];
    variables: {
      name: string;
      type: string;
      valuesByMode: Record<string, unknown>;
    }[];
  }[];
}

export interface DriftReport {
  /** Declared by the export, absent from the live file. */
  missing: string[];
  /** Present in the live file, not declared by the export. */
  extra: string[];
  /** Present on both sides with differing values, one line per mode. */
  valueDrift: string[];
  /** Collections the export declares that the live file has no counterpart for. */
  missingCollections: string[];
  log: string[];
}

// A variable's identity for comparison: the canonicalised collection plus the
// variable name — the same key `VarLookup` indexes by, so a "missing" here is
// exactly a name a builder's `lk.get(...)` would throw on.
function keyOf(collectionName: string, variableName: string): string {
  return `${canonicalCollection(collectionName)}/${variableName}`;
}

// Renders a value for comparison and for the log.
//
// Aliases render as their TARGET PATH rather than as a variable id, because
// the ids differ between the export (which has none — it names paths) and the
// live file (which has only ids). Comparing ids would report every alias as
// drifted; comparing paths compares what the two sides actually mean.
//
// Colours render at 4 decimal places. Figma stores channels as floats and a
// round-trip through the import lands them a few ulps off (0.5 comes back as
// 0.5000000074505806), so an exact comparison would report drift on values
// that are the same colour. Four places is finer than 8-bit colour can
// express, so this cannot hide a real difference.
function renderValue(v: unknown, resolveAliasPath: (id: string) => string | undefined): string {
  if (v === null || v === undefined) return 'null';
  if (typeof v === 'object') {
    const o = v as Record<string, unknown>;
    if (o.type === 'VARIABLE_ALIAS' && typeof o.id === 'string') {
      return `→ ${resolveAliasPath(o.id) ?? o.id}`;
    }
    if (typeof o.alias === 'string') return `→ ${o.alias}`;
    if ('r' in o) {
      const c = o as { r: number; g: number; b: number; a?: number };
      const a = c.a === undefined ? 1 : c.a;
      return `rgba(${c.r.toFixed(4)}, ${c.g.toFixed(4)}, ${c.b.toFixed(4)}, ${a.toFixed(4)})`;
    }
    return JSON.stringify(o);
  }
  if (typeof v === 'number') {
    // Same reason as the colour rounding above — a float that round-tripped
    // through Figma is not bit-identical to the one the exporter wrote.
    return String(Math.round(v * 10000) / 10000);
  }
  return String(v);
}

// An alias target as the export spells it: `"Primitives/color/x"`. The
// live side yields the same string once its id is resolved and both are put
// through `canonicalCollection` — otherwise `"Semantic/ Color · CoUI/…"`
// and `"Semantic/…"` would compare unequal while naming one variable.
// SPLITTING THIS PATH IS NOT A STRING OPERATION. Both halves contain
// slashes — the collection (`"Semantic/ Color · CoUI"`) and the
// variable name (`"color/primary"`) — so neither the first `/` nor the last
// one is the boundary. Cutting at the first one produces
// `"Semantic/ Color · CoUI/color/primary"` where the live side says
// `"Semantic/color/primary"`, and every cross-collection alias then reports
// as drifted. Caught by running against the real file: the unit tests used
// slash-free collection names and passed.
//
// So the boundary is found by knowing which collection names exist, longest
// first — a shorter name that happens to prefix a longer one must not win.
function canonicalAliasPath(path: string, knownCollections: readonly string[]): string {
  for (const coll of knownCollections) {
    if (path.startsWith(`${coll}/`)) {
      return `${canonicalCollection(coll)}/${path.slice(coll.length + 1)}`;
    }
  }
  // No known collection matched — the alias names something this document
  // and this file both lack. Returned unchanged so it compares unequal and
  // shows up as drift, which is what an unresolvable alias target is.
  return path;
}

export async function checkTokenDrift(doc: DriftDoc): Promise<DriftReport> {
  const log: string[] = [];
  const missing: string[] = [];
  const extra: string[] = [];
  const valueDrift: string[] = [];
  const missingCollections: string[] = [];

  const liveCollections = await figma.variables.getLocalVariableCollectionsAsync();

  // Live index: key → { variable, collection }, plus an id → path map so
  // alias targets can be rendered as paths on both sides.
  const liveByKey = new Map<string, { v: Variable; coll: VariableCollection }>();
  const idToPath = new Map<string, string>();
  for (const coll of liveCollections) {
    for (const id of coll.variableIds) {
      const v = await figma.variables.getVariableByIdAsync(id);
      if (!v) continue;
      liveByKey.set(keyOf(coll.name, v.name), { v, coll });
      idToPath.set(v.id, keyOf(coll.name, v.name));
    }
  }
  const resolveAliasPath = (id: string): string | undefined => idToPath.get(id);

  // Every collection name either side knows, longest first — see
  // `canonicalAliasPath` for why the length order matters. Both sides are
  // needed: the export names collections the file may lack (that is one of
  // the things being reported) and the file holds collections the export
  // does not declare.
  const knownCollections = [
    ...new Set([...liveCollections.map((c) => c.name), ...doc.collections.map((c) => c.name)]),
  ].sort((a, b) => b.length - a.length);
  const canonicalAlias = (p: string): string => canonicalAliasPath(p, knownCollections);

  const declaredKeys = new Set<string>();

  for (const coll of doc.collections) {
    const liveColl = liveCollections.find(
      (c) => canonicalCollection(c.name) === canonicalCollection(coll.name),
    );
    if (!liveColl) {
      missingCollections.push(coll.name);
      // Every variable in a collection that does not exist is missing too,
      // but listing them all would bury the one line that matters.
      continue;
    }

    // Mode names, not ids: the export names modes (`"Light"`), the live file
    // keys them by id. Comparing values per mode needs the two joined by name.
    const liveModeIdByName = new Map<string, string>();
    for (const m of liveColl.modes) liveModeIdByName.set(m.name, m.modeId);

    for (const spec of coll.variables) {
      const key = keyOf(coll.name, spec.name);
      declaredKeys.add(key);
      const live = liveByKey.get(key);
      if (!live) {
        missing.push(key);
        continue;
      }

      for (const [modeName, declaredValue] of Object.entries(spec.valuesByMode)) {
        const modeId = liveModeIdByName.get(modeName);
        if (modeId === undefined) {
          valueDrift.push(`${key} [${modeName}]: mode absent in live collection`);
          continue;
        }
        const liveValue = live.v.valuesByMode[modeId];
        let want = renderValue(declaredValue, resolveAliasPath);
        let got = renderValue(liveValue, resolveAliasPath);
        // Both sides render an alias as `→ <path>`; canonicalise the path so
        // brand-suffixed and numbered collection names compare equal.
        if (want.startsWith('→ ')) want = `→ ${canonicalAlias(want.slice(2))}`;
        if (got.startsWith('→ ')) got = `→ ${canonicalAlias(got.slice(2))}`;
        if (want !== got) {
          valueDrift.push(`${key} [${modeName}]: export ${want} · live ${got}`);
        }
      }
    }
  }

  for (const [key] of liveByKey) {
    if (!declaredKeys.has(key)) extra.push(key);
  }

  missing.sort();
  extra.sort();
  valueDrift.sort();

  // The summary line first, so a clean run is one line and a dirty one says
  // how dirty before the list starts.
  if (
    missing.length === 0 &&
    extra.length === 0 &&
    valueDrift.length === 0 &&
    missingCollections.length === 0
  ) {
    log.push(`✓ 드리프트 없음 — export 선언 ${declaredKeys.size}개가 라이브 파일과 일치합니다.`);
    return { missing, extra, valueDrift, missingCollections, log };
  }

  log.push(
    `드리프트: 누락 ${missing.length} · 값 불일치 ${valueDrift.length} · ` +
      `라이브 전용 ${extra.length}` +
      (missingCollections.length > 0 ? ` · 컬렉션 누락 ${missingCollections.length}` : ''),
  );

  if (missingCollections.length > 0) {
    log.push('');
    log.push('■ 컬렉션 누락 — export 가 선언한 컬렉션이 라이브에 없음');
    for (const c of missingCollections) log.push(`  ✗ ${c}`);
  }

  if (missing.length > 0) {
    log.push('');
    log.push('■ 누락 — export 가 선언했으나 라이브에 없음 (빌더가 이 이름을 찾으면 throw)');
    for (const m of missing) log.push(`  ✗ ${m}`);
  }

  if (valueDrift.length > 0) {
    log.push('');
    log.push('■ 값 불일치 — 양쪽에 있으나 값이 다름 (조용히 틀린 채 렌더됨)');
    for (const d of valueDrift) log.push(`  ≠ ${d}`);
  }

  if (extra.length > 0) {
    log.push('');
    log.push(
      '■ 라이브 전용 — 코드가 모르는 변수. Import 는 삭제하지 않으므로 그대로 남지만, ' +
        '여기 바인딩된 컴포넌트는 coui_core 가 모르는 값을 쓰는 것이다.',
    );
    for (const e of extra) log.push(`  + ${e}`);
  }

  log.push('');
  log.push('※ 이 검사는 아무것도 바꾸지 않습니다. 누락/값 불일치는 "변수로 가져오기"로 해소됩니다.');

  return { missing, extra, valueDrift, missingCollections, log };
}
