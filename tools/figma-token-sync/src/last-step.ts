// ─── Last-step mark — a footprint that outlives the realm ────────────────────
//
// Twice now a large set has stopped two combos from the end with nothing in
// the log: no ✗, no `done`, the progress label frozen on the last tick the UI
// managed to paint. Figma itself stayed responsive, so the plugin was not in
// a long synchronous stretch — its realm was gone, and a realm that is gone
// cannot report where it was. The UI's last tick is not that place either:
// paints coalesce, so it can trail the truth by a combo or more (it read 478
// on a run whose 480th member was on the canvas).
//
// So the run writes where it is INTO THE DOCUMENT, on `figma.root`, at every
// point worth telling apart — each combo, each stage of reassembly, each
// stage of an entry. Shared plugin data because the private kind is
// invisible from outside the plugin, and the whole point is to read this
// after the plugin can no longer answer. One key, overwritten; the last
// value standing is the answer.
//
// A leaf module: `identity.ts` needs it and `helpers.ts` re-exports
// `identity.ts`, so it cannot live in `helpers.ts` without a cycle.
const kLastStepNamespace = 'coui';
const kLastStepKey = 'last-step';
// The second footprint, beside the first. `last-step` says WHERE a run was;
// this says what its clocks read there — one entry's `⏱ … 세부` line, written
// every few combos while a big builder is still inside its loop. The `⏱`
// lines only reach the log when an entry finishes, and a realm that dies
// mid-loop takes the whole log with it (it is posted once, at `done`) — so a
// run that stopped at combo 334 of 972 left the growth samplers' answer
// nowhere. This is that answer, as of the last footprint before the end.
const kLastGrowthKey = 'last-growth';

// ─── Where a mark sits against the clocks ───────────────────────────────────
//
// A mark is written at a boundary, and it is billed to nothing it names. One
// that opens a timed span is written before that span's clock starts
// (`:tints`, `:stamp`, `Button:props`). One that divides a span into parts is
// written with the clock stopped — the part before it ends, the mark is
// written, the part after it starts — so it is in neither part and not in the
// span's total (`:finish:post`, `:parity`). Either way its time falls to what
// encloses the span, which during a build is the `미계측` remainder.
//
// Both reasons are about reading numbers across runs. A total keeps measuring
// the work older logs measured, so adding a mark cannot move a number that is
// already being compared. And the write is not free on a large document — it
// is the whole of `yield`'s `mark` part — so a mark inside the part it names
// would inflate the very part it is there to locate.
//
// Marks a total already held before it was cut into parts stay inside that
// total, for the first reason: `:build` · `:built` · `:docs`, and `finish`'s
// own `:start` · `:appended` · `:layout` · `:done`. The one of those that
// names a part, `:layout`, is written before that part's clock starts.
export function markStep(step: string): void {
  try {
    figma.root.setSharedPluginData(kLastStepNamespace, kLastStepKey, `${step}|${Date.now()}`);
  } catch {
    // A document that refuses the write is not worth failing the run over.
  }
}

/** `markStep`'s twin for the growth line — same envelope (`text|epoch-ms`),
 *  same swallow of a refused write, same "last value standing" contract. */
export function markGrowth(line: string): void {
  try {
    figma.root.setSharedPluginData(kLastStepNamespace, kLastGrowthKey, `${line}|${Date.now()}`);
  } catch {
    // As `markStep`: a document that refuses the write is not worth failing the run over.
  }
}

// ─── The reading half ────────────────────────────────────────────────────────
//
// The plugin that could answer "where did it stop" is the one that is gone, so
// the answer has to be read by a later open of the plugin — the 관리 tab asks
// for it through `read-last-step` (code.ts).

/** The last mark as read back. `raw` is the stored value exactly, and empty
 *  when this document has never been marked. */
export interface LastStepRecord {
  raw: string;
  step: string | null;
  /** When the mark was written, epoch ms; null when there is no parsable time. */
  markedAt: number | null;
  /** How long ago, by the clock that read it; null whenever `markedAt` is. */
  ageMs: number | null;
}

/**
 * `"Button:finish:appended:50|1757570000000"` → step, time and age.
 *
 * Split at the LAST `|`: a step is free text built from component and phase
 * names, and only the time suffix is known not to contain one. A value with no
 * parsable time comes back with its step and no age rather than an invented
 * one — the step alone still says where a run was.
 *
 * Pure, so the parse is checked off-sandbox (selftest-nfr-e-report).
 */
export function parseLastStep(raw: string, now: number): LastStepRecord {
  if (!raw) return { raw, step: null, markedAt: null, ageMs: null };
  const bar = raw.lastIndexOf('|');
  const suffix = bar < 0 ? '' : raw.slice(bar + 1);
  if (!/^\d+$/.test(suffix)) return { raw, step: raw, markedAt: null, ageMs: null };
  const markedAt = Number(suffix);
  return { raw, step: raw.slice(0, bar), markedAt, ageMs: now - markedAt };
}

export function readLastStep(): LastStepRecord {
  let raw = '';
  try {
    raw = figma.root.getSharedPluginData(kLastStepNamespace, kLastStepKey);
  } catch {
    // Same stance as the write: a document that refuses reads as never marked.
  }
  return parseLastStep(raw, Date.now());
}

/** The last growth footprint, parsed with the same rule — `step` carries the
 *  `⏱`-shaped line. Empty `raw` means no big builder has left one yet. */
export function readLastGrowth(): LastStepRecord {
  let raw = '';
  try {
    raw = figma.root.getSharedPluginData(kLastStepNamespace, kLastGrowthKey);
  } catch {
    // As above.
  }
  return parseLastStep(raw, Date.now());
}

// ─── A footprint that went backwards ────────────────────────────────────────
//
// A Figma tab left open from an old session can reconnect days later, and the
// multiplayer merge then APPLIES that tab's writes — without deleting anything
// that happened since. `last-step` is one of those writes: it was found showing
// a step from two days earlier than the run that had finished after it. That
// rewind was the first sign that the same merge had also pushed the old
// session's nodes into thirteen current sets (`overlapping-siblings.ts`).
//
// So a finished run also stamps WHEN it finished, under its own key, and the
// next run compares: a `last-step` older than the last finished run cannot have
// been written by any run since — something replayed it. Warned, never
// blocking: the plugin cannot see the other client, and the remedy (close the
// old tab) is the designer's.
const kLastDoneKey = 'last-done';

/** Stamps the end of a finished run. Called right after `markStep('run:done')`,
 *  and stamps THAT mark's own time rather than a fresh clock read — a later
 *  clock would sit a millisecond past the mark and make every clean finish
 *  read as a rewind on the next run. */
export function markLastDone(): void {
  try {
    const done = readLastStep().markedAt ?? Date.now();
    figma.root.setSharedPluginData(kLastStepNamespace, kLastDoneKey, `${done}`);
  } catch {
    // As `markStep`: a document that refuses the write is not worth failing the run over.
  }
}

/** Epoch ms of the last finished run, or `null` when none was stamped. */
export function readLastDoneAt(): number | null {
  let raw = '';
  try {
    raw = figma.root.getSharedPluginData(kLastStepNamespace, kLastDoneKey);
  } catch {
    // As above.
  }
  return /^\d+$/.test(raw) ? Number(raw) : null;
}

/**
 * The warning line when `last-step` is older than the last finished run, else
 * `null`. Pure — the comparison and the wording are pinned off-sandbox
 * (selftest-overlapping-siblings).
 */
export function formatLastStepRewind(
  lastStep: LastStepRecord,
  lastDoneAt: number | null,
): string | null {
  if (lastDoneAt === null || lastStep.markedAt === null) return null;
  if (lastStep.markedAt >= lastDoneAt) return null;
  const at = (ms: number): string => new Date(ms).toISOString().slice(0, 16).replace('T', ' ');
  return (
    `⚠ last-step 가 되감겼다 — "${lastStep.step ?? ''}" (${at(lastStep.markedAt)}Z) 는 마지막으로 ` +
    `끝난 실행(${at(lastDoneAt)}Z)보다 과거다. 오래 열려 있던 다른 탭의 늦은 동기화로 보인다: ` +
    '그 탭을 닫고, "겹친 형제 보기" 로 세트에 옛 노드가 끼었는지 확인한다'
  );
}
