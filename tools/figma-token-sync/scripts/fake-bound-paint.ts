// The paint-binding half of a `figma` test double, shared by the selftests that
// draw through one.
//
// Two facts about Figma's paint API that a double has to reproduce, because the
// builder is written around them and a double that accepts anything cannot fail
// the builder that ignores them:
//
//   1. A paint bound to a variable comes out of the node's setter at opacity 100%
//      and blend mode NORMAL, whatever it asked for, the first time that binding
//      is written. A value set on the paint READ BACK from the node stays. (The
//      designer's account of the MockupDevice canvas: the write resets it, the
//      read-back overwrite keeps it.) So `bindPaint` returns a copy that already
//      reads at full strength, and `storePaints` — what a node's `fills` /
//      `strokes` setter calls — resets a paint whose colour binding is not the one
//      already stored at that index, and leaves a paint that re-states the binding
//      the node holds exactly as given.
//
//   2. A gradient stop rides a variable on its own: `ColorStop.boundVariables`
//      holds a `VariableAlias` made by `figma.variables.createVariableAlias`.
//      `fakeAlias` is that call; the alias carries the variable's id, and for a
//      double's own variable (`__fakeVariable`) an id built from what it was asked
//      for, so a test can read WHICH variable a stop ended up on.
//
// What this does not model: whether the real API honours the read-back
// overwrite on every paint kind. It is the account the builder is written
// against, and the one thing only a run in Figma can settle.

/**
 * How many times the double took an opacity away from a paint it stored. A suite
 * that asserts a stated strength survives is only testing something when this is
 * above zero — a model that never reset anything would pass every such assertion
 * by doing nothing.
 */
export const trapStats = { opacityLost: 0 };

/** The `figma.variables.setBoundVariableForPaint` of the double. */
export function bindPaint(paint: unknown, field: string, variable: unknown): unknown {
  return Object.assign({}, paint as object, {
    boundVariables: { [field]: variable },
    // The copy it returns already reads at full strength.
    opacity: (variable as { __paintOpacity?: number }).__paintOpacity ?? 1,
    blendMode: 'NORMAL',
  });
}

interface BoundPaint {
  opacity?: number;
  boundVariables?: { color?: unknown };
}

function colorBindingOf(paint: unknown): string | null {
  if (paint == null || typeof paint !== 'object') return null;
  const bound = (paint as BoundPaint).boundVariables?.color;
  return bound == null ? null : fakeAlias(bound).id;
}

/**
 * What a node's `fills` / `strokes` setter stores. A paint whose colour binding is
 * new at its index is reset to opacity 100% / NORMAL; one that re-states the
 * binding already stored there (a paint read back from the node and edited) is
 * stored as given.
 */
export function storePaints(paints: readonly unknown[], previous: readonly unknown[]): unknown[] {
  return paints.map((paint, i) => {
    const binding = colorBindingOf(paint);
    if (binding == null || binding === colorBindingOf(previous[i])) return paint;
    const asked = (paint as BoundPaint).opacity;
    if (asked != null && asked !== 1) trapStats.opacityLost += 1;
    // A composed COLOR variable supplies its own alpha on the initial write.
    const bound = (paint as BoundPaint).boundVariables?.color as { __paintOpacity?: number } | undefined;
    return Object.assign({}, paint, { opacity: bound?.__paintOpacity ?? 1, blendMode: 'NORMAL' });
  });
}

export interface FakeAlias {
  type: 'VARIABLE_ALIAS';
  id: string;
}

interface AliasableVariable {
  id?: unknown;
  __fakeVariable?: unknown;
  method?: unknown;
  arg?: unknown;
}

/** The `figma.variables.createVariableAlias` of the double. */
export function fakeAlias(variable: unknown): FakeAlias {
  const v = variable as AliasableVariable | null | undefined;
  if (v == null) throw new Error('createVariableAlias: received no Variable.');
  if (typeof v.id === 'string') return { type: 'VARIABLE_ALIAS', id: v.id };
  if (v.__fakeVariable === true) {
    return { type: 'VARIABLE_ALIAS', id: `fake:${String(v.method)}:${String(v.arg)}` };
  }
  throw new Error('createVariableAlias: the Variable has no id.');
}

/** The id `fakeAlias` gives the double's own `sem(name)` variable. */
export function fakeSemanticId(name: string): string {
  return `fake:sem:${name}`;
}
