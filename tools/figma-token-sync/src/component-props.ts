/// <reference types="@figma/plugin-typings" />

import { parseVariantKey } from './variant-safety';
import {
  afterNodeBindLands,
  existingComponentOrSet,
  findComponentByName,
  pendingOwnerOf,
  recordPropRef,
} from './identity';
import {
  alignSlotIconMode,
  drawnIconOf,
  type GlyphPaint,
  iconVariantById,
  nearestSizeVariantOf,
  recordInexactSlotSwap,
  setIconGlyph,
  settleIconAfterBind,
  sizeStepsOf,
  slotSwapVariantFor,
} from './icon-nodes';

// Figma component properties — the TEXT / BOOLEAN / INSTANCE_SWAP declarations a
// set exposes, and the per-node references that bind them.
//
// Split out of `helpers.ts`, where this shared a divider with instance-subtree reach
// and node identity for 1082 lines. The divider said "Figma component properties";
// two thirds of what followed was something else.
// ─── Figma component properties ──────────────────────────────────────────────
//
// A CoUI widget's composition slots (`child` / `leading` / `title` / …) accept
// arbitrary widgets. Figma's equivalent is a component property: TEXT for a
// slot a caller fills with words, BOOLEAN for one it either shows or doesn't,
// INSTANCE_SWAP for one it fills with another component. Without them a
// generated component is a fixed picture — a designer can edit the copy by
// double-clicking into it, but nothing declares that the copy is a *slot*, and
// nothing lets them swap the icon for a different one.
//
// Properties live on the COMPONENT_SET when there is one, and on the COMPONENT
// when it stands alone — `addComponentProperty` on a set member throws.
export function propertyOwner(node: ComponentNode): ComponentNode | ComponentSetNode {
  // A member of a set whose reassembly is still pending (`identity.ts`) has
  // the page for a parent right now; its owner is the set all the same.
  const pending = pendingOwnerOf(node);
  if (pending) return pending;
  const parent = node.parent;
  return parent != null && parent.type === 'COMPONENT_SET' ? parent : node;
}

// The key of `owner`'s property called `name` of `type`, or undefined. Figma
// appends `#<id>` to the key; the human name is the prefix. One matcher for
// `defineProp` (which property a declaration reuses) and `iconSwapDefault`
// (which default that reused property carries), so the two cannot disagree
// about which property they are reading.
function matchingPropKey(
  defs: ComponentPropertyDefinitions | undefined,
  name: string,
  type: ComponentPropertyType,
): string | undefined {
  if (!defs) return undefined;
  for (const id of Object.keys(defs)) {
    if (id.split('#')[0] === name && defs[id].type === type) return id;
  }
  return undefined;
}

// The default each INSTANCE_SWAP key resolved to on its latest `defineProp`:
// the one the document already held, or the builder's for a new property.
// Overwritten on every declaration, and every bind follows the declaration of
// the property it binds, so a key read here was declared in the same run.
const swapDefaultByKey = new Map<string, string>();

/**
 * An INSTANCE_SWAP default that takes over from an earlier one.
 *
 * `defineProp` leaves an existing swap default alone: it is a node id, ids
 * differ per document, and a designer may have pointed it somewhere on purpose.
 * When the builder itself changes what a slot defaults to, that rule would keep
 * every existing file on the old default forever — so `replaces` names the ONE
 * id this default supersedes. A property still holding exactly that id was set
 * by the builder and nobody since, so it moves; one holding anything else is a
 * choice, so it stays and is reported (`drainKeptSwapDefaults`).
 *
 * Matched on the exact id, never on "any member of the old set": a designer who
 * picked a different member of that set made a choice too.
 *
 * Once per property. `replaces` names an id the builder USED to write; after the
 * first look at a property nothing the builder does writes it again, so any
 * later default equal to it is a designer's pick — `Skeleton` is a real
 * component now and a slot may well be set to it on purpose. The first look
 * leaves a mark on the owner (`kSwapAdoptedKey`) and from then on `replaces` is
 * not read. A document that never had the old default is marked on its first
 * look too, for the same reason.
 */
export interface SwapDefault {
  id: string;
  /** The default this one supersedes, or null when the document never had it. */
  replaces: string | null;
  /**
   * Names THIS takeover, for a property an earlier one already decided.
   *
   * The once-per-property mark answers "has a takeover looked at this
   * property", and a slot can be taken over twice: `Skeleton` → `.Slot`, then
   * `.Slot` → the slot's own example (#6473). Under one mark the second
   * `replaces` would never be read, and every file drawn before it would keep
   * the stand-in forever. A named takeover keeps its own mark, so it too gets
   * exactly one look — the rule above, per takeover rather than per property.
   */
  takeover?: string;
}

/** A swap default left on a designer's pick: the property, and the id it holds. */
export interface KeptSwapDefault {
  prop: string;
  id: string;
}

/** The mark an owner carries once a swap property's takeover was decided. */
export const kSwapAdoptedKey = (name: string, takeover?: string): string =>
  takeover === undefined ? `coui-swap-adopted:${name}` : `coui-swap-adopted:${name}@${takeover}`;

// Plugin data is the one thing the plugin may write to a node the designer owns
// without it being a visible edit. Older document doubles have none.
function isAdopted(owner: ComponentNode | ComponentSetNode, key: string): boolean {
  try {
    return owner.getPluginData(key) === '1';
  } catch {
    return false;
  }
}

function markAdopted(owner: ComponentNode | ComponentSetNode, key: string): void {
  try {
    owner.setPluginData(key, '1');
  } catch {
    // No plugin data on this owner: the takeover then repeats, as it did before
    // the mark existed — a default left alone is never the loss.
  }
}

/** Swap defaults left on a designer's pick — drained per entry. */
const keptSwapDefaults: KeptSwapDefault[] = [];

/** Reports the swap defaults `defineProp` left alone this entry, once each, and
 *  clears the list. Drained by `generate.ts` beside the icon and spacing drains;
 *  the id is named there, where a node can be looked up asynchronously. */
export function drainKeptSwapDefaults(): KeptSwapDefault[] {
  const seen = new Set<string>();
  return keptSwapDefaults.splice(0).filter((k) => {
    const key = `${k.prop}\u0000${k.id}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

// Adds a property and returns its id, or null when this owner already has one
// by that name (a set's members share the owner, so the second variant through
// a loop must reuse rather than re-add).
export function defineProp(
  owner: ComponentNode | ComponentSetNode,
  name: string,
  type: 'TEXT' | 'BOOLEAN' | 'INSTANCE_SWAP',
  defaultValue: string | boolean | SwapDefault,
): string | null {
  const given = typeof defaultValue === 'object' ? defaultValue : null;
  const value = given !== null ? given.id : (defaultValue as string | boolean);
  // Only the first look at a property may take over from the old default.
  const adoptedKey = given !== null ? kSwapAdoptedKey(name, given.takeover) : null;
  const swap =
    given !== null && adoptedKey !== null && isAdopted(owner, adoptedKey)
      ? { ...given, replaces: null }
      : given;
  const existing = owner.componentPropertyDefinitions;
  const id = matchingPropKey(existing, name, type);
  if (existing && id) {
    const def = existing[id];
    // What this run's binds will find in the property, unless it is moved below.
    if (type === 'INSTANCE_SWAP' && typeof def.defaultValue === 'string') {
      swapDefaultByKey.set(id, def.defaultValue);
    }
    if (adoptedKey !== null) markAdopted(owner, adoptedKey);
    // The one swap default the builder may still move — see `SwapDefault`.
    if (swap !== null && swap.replaces !== null && def.defaultValue !== value) {
      if (def.defaultValue === swap.replaces && value !== '') {
        try {
          const moved = owner.editComponentProperty(id, { defaultValue: value });
          // The default the binds find is the one just written.
          if (typeof value === 'string') swapDefaultByKey.set(moved, value);
          return moved;
        } catch {
          return id;
        }
      }
      keptSwapDefaults.push({ prop: name, id: String(def.defaultValue) });
      return id;
    }
    // Reuse the id — that is what keeps a designer's instance overrides
    // pointing at the same property. But bring the DEFAULT up to what
    // the builder states, because a default is a value and values come
    // from the code (the same rule every colour and inset follows).
    //
    // Without this, changing a declared default in a builder did
    // nothing on any file that already had the property: the flip was
    // committed, the run reported success, and the canvas kept the old
    // value. That is how `FocusOutline` shipped `Focused` and
    // `Show child` at `true` — the placeholder glyph turned up inside
    // every dot and every empty slide, and re-running Generate could
    // not clear it.
    //
    // Not for INSTANCE_SWAP: its default is a node id, and ids differ
    // per document. Snapping one back would repoint a designer's
    // swapped-in component at whatever this run happened to mint — the
    // one exception being a default the builder itself supersedes, above.
    if (type !== 'INSTANCE_SWAP' && def.defaultValue !== value) {
      try {
        return owner.editComponentProperty(id, {
          defaultValue: value,
        });
      } catch {
        // Older document doubles have no editor; the id still stands.
        return id;
      }
    }
    return id;
  }
  // An INSTANCE_SWAP with no default is not a property Figma will take — it
  // answers `Property value is incompatible with component property type`, and
  // that throw is not rolled back: the entry is reported as failed and a
  // half-drawn component is left on the page.
  //
  // Callers pass `''` on purpose when the child set is absent, on the reasoning
  // that declaring the property keeps the slot swappable with no default rather
  // than failing the entry. The reasoning is right and the mechanism was wrong:
  // Figma refuses the declaration, so the entry failed anyway and left half a
  // component behind — which is what `AvatarBadge` and `Chat` were doing.
  // Skipping the declaration keeps the component whole; the slot is simply not
  // swappable until its child exists.
  if (type === 'INSTANCE_SWAP' && value === '') return null;
  if (adoptedKey !== null) markAdopted(owner, adoptedKey);
  const added = owner.addComponentProperty(name, type, value);
  if (type === 'INSTANCE_SWAP' && typeof value === 'string') {
    swapDefaultByKey.set(added, value);
  }
  return added;
}

/** A definition `freePropName` removed so its name could carry another kind. */
export interface RetypedProp {
  owner: string;
  name: string;
  /** The kind the removed definition had. */
  from: string;
  /** The kind the name is being freed for. */
  to: string;
  /** The removed definition's default, as it held it. */
  defaultValue: string;
}

/** Definitions `freePropName` removed this entry — drained by `generate.ts`. */
const retypedProps: RetypedProp[] = [];

/** The definitions `freePropName` removed since the last drain, and the clear. */
export function drainRetypedProps(): RetypedProp[] {
  return retypedProps.splice(0);
}

/** One log line per removal. Pure — the wording is tested. */
export function formatRetypedProps(list: readonly RetypedProp[]): string[] {
  return list.map(
    (r) =>
      `🧹 ${r.owner}: 속성 종류가 바뀌어 같은 이름의 옛 속성 제거 — "${r.name}" ` +
      `(${r.from} → ${r.to}, 옛 기본값 ${JSON.stringify(r.defaultValue)})`,
  );
}

/**
 * Frees `name` for a property of `type`: removes the owner's definition of that
 * name under any OTHER kind, unless a layer this entry bound uses it.
 *
 * Figma holds one property per name whatever the kinds — `addComponentProperty`
 * rejects a second `Child` beside an existing one, and that throw is not rolled
 * back: the entry fails and leaves its set half-drawn. `defineProp` reuses a
 * definition only when name AND kind match, so a slot whose property changes
 * kind (a TEXT stand-in becoming an INSTANCE_SWAP) runs into the old
 * definition on every document generated before the change. By the time this
 * runs the old one drives nothing — the reset re-minted every layer that
 * referenced it — so removing it is what `unbound-props.ts` does after the draw
 * anyway, only early enough for the new declaration to land. Each removal is
 * recorded for the run log; nothing is removed silently.
 *
 * A definition this entry DID bind stays, and the declaration after it then
 * fails as loudly as it would have. Call after `finish()`, right before the
 * `defineProp` it clears the way for.
 */
export function freePropName(
  owner: ComponentNode | ComponentSetNode,
  name: string,
  type: 'TEXT' | 'BOOLEAN' | 'INSTANCE_SWAP',
): void {
  // Nothing to free on an owner whose definitions cannot be read — a document
  // double that models none, or a set `variant-safety.ts` reports separately.
  let defs: ComponentPropertyDefinitions | undefined;
  try {
    defs = owner.componentPropertyDefinitions;
  } catch {
    return;
  }
  if (!defs) return;
  for (const key of Object.keys(defs)) {
    const def = defs[key];
    if (key.split('#')[0] !== name || def.type === type) continue;
    // VARIANT is the set's members, not a definition; nothing here removes one.
    if (!kRefBoundTypes.has(def.type) || boundCountByKey.has(key)) continue;
    owner.deleteComponentProperty(key);
    retypedProps.push({
      owner: owner.name,
      name: name,
      from: def.type,
      to: type,
      defaultValue: String(def.defaultValue),
    });
  }
}

/**
 * The default an icon slot's INSTANCE_SWAP property will carry this run, and
 * the `Icon` variant behind it.
 *
 * `defineProp` keeps a default the document already holds (ids differ per
 * document, so a builder's id cannot replace it). That kept default is what
 * the first bind puts in place of the slot's icon, so the icon has to be drawn
 * from it, or the bind redraws it at the default's size (#5247). Several sets
 * on the live file carry an older default than the builder's (`Size=14`,
 * `Size=16`), and a builder that drew from its own intended variant drew a
 * different icon from the one the canvas ended up with.
 *
 * Read off the owner `mountSet` will reuse (`existingComponentOrSet`, with no
 * side effects), with the same matcher `defineProp` uses, so a builder may
 * call it before or after mounting. `variant` is null when the default is not
 * a local `Icon` `Size=N` variant (a remote library node, a bare glyph). The
 * icon then falls back to the nearest step, and `bindSwapProp` rescales it
 * once the bind lands.
 */
export function iconSwapDefault(
  page: PageNode,
  ownerName: string,
  propName: string,
  intendedId: string,
): { id: string; variant: ComponentNode | null } {
  let id = intendedId;
  const owner = existingComponentOrSet(page, ownerName);
  if (owner) {
    let defs: ComponentPropertyDefinitions | undefined;
    try {
      defs = owner.componentPropertyDefinitions;
    } catch {
      // A COMPONENT that is some set's variant has no definitions of its own.
      defs = undefined;
    }
    const key = matchingPropKey(defs, propName, 'INSTANCE_SWAP');
    const held = key && defs ? defs[key].defaultValue : undefined;
    if (typeof held === 'string' && held !== '') id = held;
  }
  return { id, variant: iconVariantById(id) };
}

// Points a node's own field at a property. `characters` for text, `visible`
// for boolean, `mainComponent` for an instance swap — Figma rejects any other
// pairing, which is why the three are separate functions rather than one with
// a field argument a caller could get wrong.
// The `Icon` variant node id an INSTANCE_SWAP slot defaults to.
//
// Returns a `Size=N` VARIANT of the Icon set, never a bare Lucide glyph. A
// slot in this library holds an *Icon*, and the glyph rides on that instance's
// own swap override — so a slot pointed at a bare glyph would hand the
// designer something with no `Size` axis and no stroke-weight mode.
//
// It does not take a glyph, because the default cannot express one: the
// property's default is a single main component, and the glyph is a nested
// override on the instance that fills the slot. `makeIcon` puts the right
// glyph on that instance; this only answers "what does the slot reset to".
//
// Which step: the set's own default variant, because these properties are
// declared once per COMPONENT_SET while the sizes differ per variant — there
// is no single right answer at the declaration site, and the reset value is
// the only thing this affects.
//
// Read off the COMPONENT, never off an instance: `manifest.json` sets
// `documentAccess: "dynamic-page"`, which makes `InstanceNode.mainComponent`
// write-only — reading it throws `Cannot call with documentAccess:
// dynamic-page. Use node.getMainComponentAsync instead`, and a builder is
// synchronous so it cannot await that.
export function iconMainId(page: PageNode): string {
  const found = findComponentByName(page, 'Icon');
  if (!found || found.type !== 'COMPONENT_SET') {
    throw new Error(
      'iconMainId: the `Icon` COMPONENT_SET is not in the document. It is ' +
        'designer-owned and the plugin no longer builds it, so build order ' +
        'cannot fix this — restore the `❖ Icon` page from Figma version ' +
        'history, or open a document that has it.',
    );
  }
  const steps = sizeStepsOf(found);
  if (steps.length === 0) throw new Error('iconMainId: Icon has no `Size=N` variants.');
  // `defaultVariant` is the variant Figma hands out on reset; fall back to the
  // smallest step only if the set somehow has none.
  const preferred = found.defaultVariant;
  if (preferred && /^Size=/.test(preferred.name)) return preferred.id;
  const first = found.children.find(
    (c): c is ComponentNode => c.type === 'COMPONENT' && c.name === `Size=${steps[0]}`,
  );
  if (!first) throw new Error('iconMainId: Icon has no usable `Size=N` variant.');
  return first.id;
}

// The `Icon` variant id for a slot whose size the PARENT states.
//
// `iconMainId` answers "what does the slot reset to" — the set's default
// variant, one step for every declaration site. That is the right value for
// a `defineProp` default and the wrong value for a swap: a slot swapped to it
// renders at the default step whatever the parent said. A composed child's
// glyph (Select's chevron, whose `trailingIconStyle.size` is 14 · 16 · 18
// across its rungs) takes its step from the size the parent states for that
// reason: the rescale `stateSlotGlyphSize` does is refused on an instance
// descendant (its own comment says why), so a swap that took the default
// would draw the wrong step on every rung and nothing would fail.
//
// So the step is chosen where the id is minted. Nearest rather than exact,
// the way `makeIcon` picks a step for a size it draws itself: a stated size
// the axis has no rung for should land on a real variant, not throw
// mid-build and leave the component half-drawn. Throws only for what
// `iconMainId` refuses — no `Icon` set, or a set with no `Size=N` at all.
export function iconMainIdAt(page: PageNode, size: number): string {
  if (typeof size !== 'number' || !Number.isFinite(size) || size <= 0) {
    throw new Error(
      `iconMainIdAt: size ${String(size)} is not a positive number — the caller ` +
        'read a slot size that never arrived (a missing size row, or a field ' +
        'the export no longer carries).',
    );
  }
  const found = findComponentByName(page, 'Icon');
  if (!found || found.type !== 'COMPONENT_SET') {
    throw new Error(
      'iconMainIdAt: the `Icon` COMPONENT_SET is not in the document. It is ' +
        'designer-owned and the plugin no longer builds it, so build order ' +
        'cannot fix this — restore the `❖ Icon` page from Figma version ' +
        'history, or open a document that has it.',
    );
  }
  return nearestSizeVariantOf(found, size).node.id;
}

// ─── Which properties this entry bound ───────────────────────────────────────
//
// Figma's publish dialog silently leaves out a component set that declares a
// property no layer references (#5323): a new set is never published and a
// published one stops receiving its edits. Nothing in Figma says so, so the
// only signal there can be is the builder's own, right after it drew the set.
//
// The question is asked of what the OWNER declares, not of what the builder
// defined. `defineProp` adds or reuses and never deletes, and Generate re-mints
// a recycled set's layers while leaving its definitions alone — so a property a
// designer added by hand, or renamed (`Show label (deprecated · …)`), is
// declared on the owner, was never passed through `defineProp`, and binds to
// nothing. Tracking only the builder's own definitions would miss exactly the
// ones that blocked twelve sets.
//
// The other half is cheap on purpose. Reading `componentPropertyReferences` back
// off a 972-member set walks every member's subtree; every write to it already
// passes through `addPropRef`, so the bound keys are counted there as they land.
// A node carries one property per field, and a second write to the same field
// replaces the first — `Show x` then `Show y` on one node's `visible` leaves
// `Show x` unbound — so the count follows the replacement.
//
// Reset by `drainUnboundProps`, which `generate.ts` calls once per entry. A
// property key carries Figma's id (`Show label#12:0`), unique within the file,
// so one count map serves every owner built in the entry.
let boundFieldsByNode = new WeakMap<object, Map<string, string>>();
const boundCountByKey = new Map<string, number>();

function noteBinding(node: SceneNode, field: string, propId: string): void {
  let fields = boundFieldsByNode.get(node);
  if (!fields) {
    fields = new Map();
    boundFieldsByNode.set(node, fields);
  }
  const replaced = fields.get(field);
  if (replaced === propId) return;
  if (replaced !== undefined) {
    const left = (boundCountByKey.get(replaced) ?? 1) - 1;
    if (left > 0) boundCountByKey.set(replaced, left);
    else boundCountByKey.delete(replaced);
  }
  fields.set(field, propId);
  boundCountByKey.set(propId, (boundCountByKey.get(propId) ?? 0) + 1);
}

const kRefBoundTypes: ReadonlySet<string> = new Set(['BOOLEAN', 'TEXT', 'INSTANCE_SWAP']);

/** A property the owner declares and no layer bound this entry. */
export interface UnboundProp {
  /** The full key, `Show label#12:0` — what `deleteComponentProperty` takes. */
  key: string;
  /** The human name — the key's prefix before `#`. */
  name: string;
  type: string;
  /** The default as the definition holds it (an INSTANCE_SWAP's is a node id). */
  defaultValue: string;
}

/** Forgets what was bound. Called at the top of every entry so a builder that
 *  threw before its drain cannot leak its counts into the next one. */
export function resetUnboundTracking(): void {
  boundFieldsByNode = new WeakMap();
  boundCountByKey.clear();
}

/**
 * The non-VARIANT properties `owner` declares that no layer bound this entry,
 * and the reset of the tracking for the next entry.
 *
 * `owner` is the entry's result. An owner whose definitions cannot be read
 * (a COMPONENT that is some set's variant, or a set with duplicate members —
 * `variant-safety.ts`) answers `null`: that is a different defect with its own
 * report, and "nothing unbound" would be a claim this check did not earn.
 */
export function drainUnboundProps(
  owner: ComponentNode | ComponentSetNode,
): UnboundProp[] | null {
  const bound = new Set(boundCountByKey.keys());
  resetUnboundTracking();
  let defs: ComponentPropertyDefinitions;
  try {
    defs = owner.componentPropertyDefinitions;
  } catch {
    return null;
  }
  const unbound: UnboundProp[] = [];
  for (const key of Object.keys(defs)) {
    // The three kinds a builder defines and a layer references by field. VARIANT is
    // the set's members, not a definition; SLOT is bound to a slot node through a
    // channel this tracking does not see, so an absence of a count says nothing.
    if (!kRefBoundTypes.has(defs[key].type) || bound.has(key)) continue;
    unbound.push({
      key: key,
      name: key.split('#')[0],
      type: defs[key].type,
      defaultValue: String(defs[key].defaultValue),
    });
  }
  return unbound;
}

// Each adds ONE field to whatever the node already carries, rather than
// replacing the whole record. A node can be the target of two properties at
// once — an optional text slot is driven by a BOOLEAN through `visible` and a
// TEXT through `characters` — and assigning a fresh object for the second one
// dropped the first, leaving a definition in the panel wired to nothing.
//
// Explicit field copy rather than object spread: the plugin runtime rejects
// `...` (see this file's header).
//
// A node under a set that is still being reassembled does not take the write
// here at all: `recordPropRef` stages its member in the anchored set and notes
// the reference, and the map is written once per node when the member goes
// back out (`identity.ts`, deferred reassembly). The read-then-write below is
// for everything else — a standalone component, or a set that has completed.
function addPropRef(node: SceneNode, field: string, propId: string): void {
  noteBinding(node, field, propId);
  if (recordPropRef(node, field, propId)) return;
  const next: Record<string, string> = {};
  const existing = node.componentPropertyReferences;
  if (existing) {
    for (const key of Object.keys(existing)) {
      const value = (existing as Record<string, string | undefined>)[key];
      if (value !== undefined) next[key] = value;
    }
  }
  next[field] = propId;
  node.componentPropertyReferences = next;
}

export function bindTextProp(node: TextNode, propId: string | null): void {
  if (propId) addPropRef(node, 'characters', propId);
}

export function bindVisibleProp(node: SceneNode, propId: string | null): void {
  if (propId) addPropRef(node, 'visible', propId);
}

export function bindSwapProp(node: InstanceNode, propId: string | null): void {
  if (!propId) return;
  addPropRef(node, 'mainComponent', propId);
  // An icon `makeIcon` drew from a variant other than this property's default
  // gets redrawn at the default by the bind (#5246 / #5247). Put it back at its
  // own side once the bind has landed — the way it was fitted: by size alone for
  // a slot icon that wears a stroke mode, by rescale for any other
  // (`settleIconAfterBind`). Icons drawn from the default
  // (`IconOpts.fromVariant`) are left alone by the bind and need nothing here.
  const drawn = drawnIconOf(node);
  const defaultId = swapDefaultByKey.get(propId);
  if (drawn && defaultId !== undefined && drawn.mainId !== defaultId) {
    const side = drawn.side;
    afterNodeBindLands(node, (n) => settleIconAfterBind(n as InstanceNode, side));
  }
}

// Turns on a composed instance's optional slot and points its swap at an icon.
//
// The library's convention is a pair per slot: a BOOLEAN named `Show <slot>`
// and an INSTANCE_SWAP named `<Slot>`. Two builders grew their own copies of
// this loop against a slot naming that no longer exists — one looked for a
// BOOLEAN literally named `leading` and a swap named `leading icon` — so the
// patch came out empty, `setProperties` was never called, and Carousel's
// prev/next rendered as two identical glyph-less circles. Nothing failed: an
// empty patch is a legal no-op, and the harness counts the call that never
// happened as a call that had nothing to do.
//
// Matching lives here, once, so a rename in the child's builder breaks one
// place instead of silently emptying every caller's patch. Both halves are
// optional — a slot with no swap still gets revealed, and an unknown slot
// produces no patch at all rather than a wrong one.
//
// Never writes `.visible` on a descendant as a fallback. A node bound to a
// property is driven by that property; assigning around it is the exact way
// the Select trigger lost its chevron once already.
/**
 * The node a given INSTANCE_SWAP property drives, inside `host`.
 *
 * `mainComponent` is unreadable under `documentAccess: "dynamic-page"`, so the
 * binding is read off `componentPropertyReferences` instead — which survives
 * the swap, because `setProperties` re-points the node's main component and
 * leaves the node itself in place.
 */
function nodeDrivenBy(host: InstanceNode, propKey: string): SceneNode | null {
  for (const node of host.findAll(() => true)) {
    const refs = node.componentPropertyReferences;
    if (refs && refs.mainComponent === propKey) return node;
  }
  return null;
}

/**
 * Turns a child's slot on and puts the requested icon in it.
 *
 * `iconId` chooses the *wrapper* — a `Size=N` variant of the `Icon` set —
 * and `glyph` chooses what that Icon draws. They are two writes because the
 * glyph is a nested override one level down, not a value of the host's own
 * property: swapping only the host's slot lands on the Icon set's own default
 * glyph, which is how two carousel arrows became the same shape.
 *
 * Unlike a `defineProp` default (see `iconMainId`), this is the value that
 * actually renders, so the glyph is required — and so is its `paint`, because
 * a swap that leaves the colour to Figma's override carry-over is how a slot
 * renders the right glyph in the wrong colour (`setIconGlyph` says why).
 * Every slot swap therefore ends in the same repaint `makeIcon` does.
 *
 * `iconId` names the step the glyph is to DRAW at, not necessarily the variant
 * that ends up in the property: a slot a child scaled to its own side keeps
 * that scale through the swap, so the variant is the one whose step times the
 * scale lands on the named step (`slotSwapVariantFor` says why, and what is
 * measured). A slot that cannot land on it is reported for the entry's log.
 *
 * A slot a child fitted by size alone also wears a stroke mode named for the
 * CHILD's side, and the swap keeps it. The parent's step is written over it last
 * (`alignSlotIconMode`), so a 20 glyph in a 24 field's seat strokes at the 20
 * rule and not the 24 one.
 */
export function setSlotIcon(
  instance: InstanceNode,
  slot: string,
  iconId: string,
  glyph: string,
  paint: GlyphPaint,
): void {
  const props: ComponentProperties | undefined = instance.componentProperties;
  if (!props || typeof instance.setProperties !== 'function') return;
  const wanted = slot.toLowerCase();
  // The variant the slot is swapped TO. The child's slot node carries the scale
  // its own icon was drawn with, and a swap keeps it (`slotSwapVariantFor`), so
  // the variant is chosen to cancel it. Read off the node BEFORE the swap: the
  // factor does not change with it, and nothing on the instance can reset it.
  const swapKeysAhead = Object.keys(props).filter(
    (k) => k.split('#')[0].toLowerCase() === wanted && props[k].type === 'INSTANCE_SWAP',
  );
  let swapTo = iconId;
  // The step the parent states and the scale the swap keeps, for the stroke mode
  // once the swap has landed (`alignSlotIconMode`). Null when `iconId` is no
  // `Icon` variant: nothing states a step, so nothing to align.
  let stated: { step: number; scale: number } | null = null;
  if (swapKeysAhead.length === 1) {
    const ahead = nodeDrivenBy(instance, swapKeysAhead[0]);
    if (ahead !== null && ahead.type === 'INSTANCE') {
      const scale = typeof ahead.scaleFactor === 'number' ? ahead.scaleFactor : 1;
      const choice = slotSwapVariantFor(iconId, scale);
      if (choice !== null) {
        swapTo = choice.id;
        stated = { step: choice.wanted, scale };
        if (!choice.exact) recordInexactSlotSwap(glyph, choice, scale);
      }
    }
  }
  const patch: { [key: string]: string | boolean } = {};
  for (const key of Object.keys(props)) {
    const label = key.split('#')[0].toLowerCase();
    if (label === `show ${wanted}` && props[key].type === 'BOOLEAN') {
      patch[key] = true;
    }
    if (label === wanted && props[key].type === 'INSTANCE_SWAP') {
      patch[key] = swapTo;
    }
  }
  if (Object.keys(patch).length === 0) {
    // Throws for the same reason `instanceOf` throws rather than returning
    // null: an empty patch is a legal no-op, so the caller, the harness and
    // every guard stay green while the slot never turns on. That is how
    // Carousel shipped two glyph-less circles. A builder asking for a slot its
    // child does not declare is a programming error, and the loud version is
    // one failing entry with a name on it instead of a component that looks
    // finished and is not.
    throw new Error(
      `setSlotIcon('${slot}'): ${instance.name} declares no 'Show ${slot}' ` +
        `BOOLEAN and no '${slot}' INSTANCE_SWAP. Its properties are ` +
        `[${Object.keys(props).map((k) => k.split('#')[0]).join(', ')}] — ` +
        'the child renamed the pair, or this is the wrong slot name.',
    );
  }
  instance.setProperties(patch);

  const swapKeys = Object.keys(props).filter(
    (k) => k.split('#')[0].toLowerCase() === wanted && props[k].type === 'INSTANCE_SWAP',
  );
  if (swapKeys.length !== 1) {
    throw new Error(
      `setSlotIcon('${slot}', glyph '${glyph}'): ${instance.name} declares ` +
        `${swapKeys.length} '${slot}' INSTANCE_SWAP propert(ies) — the glyph has ` +
        'no single slot to land in.',
    );
  }
  const target = nodeDrivenBy(instance, swapKeys[0]);
  if (!target || target.type !== 'INSTANCE') {
    throw new Error(
      `setSlotIcon('${slot}', glyph '${glyph}'): nothing inside ${instance.name} ` +
        `references its '${slot}' property, so the glyph has nowhere to go. A ` +
        'silent return here is how a slot ships with the wrong icon.',
    );
  }
  setIconGlyph(target, glyph, paint);
  // Last, after the glyph write, for the reason `makeIcon` writes its own mode
  // last: nothing that follows can then be what undoes it.
  if (stated !== null) alignSlotIconMode(target, stated.step, stated.scale);
}

// Writes a NAMED TEXT property on a composed child instance — by the key's
// human prefix, never "the first TEXT property" (`setInstanceLabel`'s rule in
// navigation.ts). A child's property list belongs to its own builder and grows
// in that builder's order, so "first" is not a name: `Badge` declares one TEXT
// today (`Child`) and a second would silently receive the caller's copy.
//
// Returns silently when the instance surfaces no properties at all (a platform
// that models none), and THROWS when it has properties but not this one: the
// key came from the child's own table, so a miss means the child changed shape
// underneath the caller, and one loudly failing entry with a name on it beats
// a composed badge that looks finished and reads "Badge".
export function setInstanceTextNamed(
  instance: InstanceNode,
  name: string,
  text: string,
): void {
  const props: ComponentProperties | undefined = instance.componentProperties;
  if (!props || typeof instance.setProperties !== 'function') return;
  for (const key of Object.keys(props)) {
    if (props[key].type !== 'TEXT' || key.split('#')[0] !== name) continue;
    const patch: { [key: string]: string } = {};
    patch[key] = text;
    instance.setProperties(patch);
    return;
  }
  throw new Error(
    `setInstanceTextNamed('${name}'): ${instance.name} has no \`${name}\` TEXT ` +
      `property (has: ${Object.keys(props).map((k) => k.split('#')[0]).join(', ')}).`,
  );
}

// Writes a NAMED INSTANCE_SWAP property on a composed child instance — the
// by-name rule and the loud miss of `setInstanceTextNamed`. A composer whose
// child draws a caller slot uses it to state what that slot holds in the
// composition (`Popover` puts its example content in the `Popup` it composes).
export function setInstanceSwapNamed(
  instance: InstanceNode,
  name: string,
  componentId: string,
): void {
  const props: ComponentProperties | undefined = instance.componentProperties;
  if (!props || typeof instance.setProperties !== 'function') return;
  for (const key of Object.keys(props)) {
    if (props[key].type !== 'INSTANCE_SWAP' || key.split('#')[0] !== name) continue;
    const patch: { [key: string]: string } = {};
    patch[key] = componentId;
    instance.setProperties(patch);
    return;
  }
  throw new Error(
    `setInstanceSwapNamed('${name}'): ${instance.name} has no \`${name}\` INSTANCE_SWAP ` +
      `property (has: ${Object.keys(props).map((k) => k.split('#')[0]).join(', ')}).`,
  );
}

// Writes a NAMED BOOLEAN property on a composed child instance — the same
// by-name rule and the same loud miss as `setInstanceTextNamed`. The value a
// composer most often writes is `false` on a child's `Show <slot>`: a `Button`
// shows its `child` label by default (`Show child`), and a composer whose code
// counterpart passes no text — `Button(child: Icon(…))` — turns it off
// (`composed-instance.ts#hideInstanceLabel`).
export function setInstanceBoolNamed(
  instance: InstanceNode,
  name: string,
  value: boolean,
): void {
  const props: ComponentProperties | undefined = instance.componentProperties;
  if (!props || typeof instance.setProperties !== 'function') return;
  for (const key of Object.keys(props)) {
    if (props[key].type !== 'BOOLEAN' || key.split('#')[0] !== name) continue;
    const patch: { [key: string]: boolean } = {};
    patch[key] = value;
    instance.setProperties(patch);
    return;
  }
  throw new Error(
    `setInstanceBoolNamed('${name}'): ${instance.name} has no \`${name}\` BOOLEAN ` +
      `property (has: ${Object.keys(props).map((k) => k.split('#')[0]).join(', ')}).`,
  );
}

// Surfaces a composed instance's own properties on the parent's panel.
//
// Deferred on purpose. Figma rejects `isExposedInstance = true` on an instance
// with no COMPONENT ancestor ("Instance must be contained within a component or
// component set to be exposed"), and the instance usually is not there yet at
// the moment a helper mints it — the helper returns it, the caller appends it,
// and something further up appends THAT. Six sites wrote the flag where the
// instance was created, and five components failed in the real Figma file
// while the harness reported 143/143 (the double had no accessor, so a plain
// assignment always succeeded).
//
// So callers collect and flush: push during construction, call this once the
// root is assembled. Same shape as `display.ts`'s `SlotPair`, and for the same
// reason — the moment the write is legal is later than the moment it is known.
export function exposeAll(instances: readonly InstanceNode[]): void {
  for (const instance of instances) instance.isExposedInstance = true;
}

// A parent slot can be composed through an exposed child's native property.
// Validate the property first: exposing a renamed/missing child slot must not
// silently claim that a designer can replace it. No duplicate parent property
// is needed, and the nested instance retains its original swap binding.
export function exposeSlot(
  instances: readonly InstanceNode[],
  name: string,
  type: ComponentPropertyType,
): void {
  if (instances.length === 0) throw new Error(`No instances expose ${name}`);
  for (const instance of instances) {
    const matches = Object.entries(instance.componentProperties).filter(
      ([key, property]) => key.split('#')[0] === name && property.type === type,
    );
    if (matches.length !== 1) {
      throw new Error(`${instance.name}: expected one ${type} property ${name}, got ${matches.length}`);
    }
  }
  exposeAll(instances);
}

// An instance of a REGISTRY component already on the page.
//
// Throws rather than returning null: a builder that composes a child needs it,
// and a silent null would produce a component missing a whole region while
// every other signal stayed green. Declare `needs: ['<Name>']` on the REGISTRY
// entry so `topoSortRegistry` builds the child first.
// The variant of `setName` that best matches `prefs`, by name.
//
// Why "best" and not "exact": a child set's axis vocabulary grows. Button had
// `Variant, Size`; it now also has `Selected, Hover, Disabled`. A parent that
// spelled the full name would break on the next axis added, and a parent that
// passed no name at all got the set's FIRST variant — which is how a banner
// whose widget documents an outline action ended up showing a filled primary
// pill. Scoring lets the parent state only the axes it cares about.
//
// A requested axis the child does not have scores nothing, so a renamed or
// removed axis degrades to "ignored" rather than to a wrong match on the axes
// that do still exist. That is deliberate: the alternative — throwing — would
// fail the parent's entry over a child's refactor and leave the parent
// half-drawn on the canvas until the next run blanks it.
export function bestVariantName(
  page: PageNode,
  setName: string,
  prefs: Record<string, string>,
): string | undefined {
  const found = findComponentByName(page, setName);
  if (!found || found.type !== 'COMPONENT_SET') return undefined;
  const set = found;
  let best: string | undefined;
  let bestScore = -1;
  for (const kid of set.children) {
    if (kid.type !== 'COMPONENT') continue;
    const axes = parseVariantKey(kid.name);
    let score = 0;
    for (const axis of Object.keys(prefs)) {
      if (axes[axis] === prefs[axis]) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      best = kid.name;
    }
  }
  return best;
}

// Suppresses a composed field instance's own chrome from a chromeless style.
//
// A component that puts a `TextField` inside its own bordered box owns the single
// visible boundary, and the widgets say so by forwarding a chromeless
// `CoreTextFieldStyle` into the field. On a canvas the composed INSTANCE arrives
// with the field's own border and fill instead, and the result is a field drawn
// inside a field — a second rounded outline sitting inside the first. Both
// `PhoneInput` and `ChipInput` were in that state.
//
// Driven by the style rather than by a literal `transparent`: the values come from
// the const the widget actually forwards, so a designer who gives inner fields a
// hairline gets one here too, and a reader can see WHERE the transparency is
// decided. The alpha test is `argb` 0 — that is what `CoreColor.transparent`
// exports (`opacity` stays 1, and a consumer combines both).
//
// Every write is an ordinary instance override. The walk tolerates finding
// nothing: if `TextField` ever stops drawing its own boundary this leaves the
// instance alone rather than throwing and leaving the host half-drawn.
