/// <reference types="@figma/plugin-typings" />

// Redrawing a component without remaking its inner nodes.
//
// A designer's override on an instance — a fill on the ✕ inside a Button, a
// label colour inside a Toggle — is stored against the main component's NODE,
// not against its name or its place. Measured in the file: editing a main's
// existing children in place (resize, fill) left an instance's overrides on
// them standing and the nested id (`I8175:8;8175:6;8175:3`) unchanged; removing
// the children and creating identical ones dropped every override and changed
// the id. `resetNode` used to do the second on every redraw, so every Generate
// of a set cost every copy that composed it its inner overrides.
//
// So the reset keeps the old children (hidden, in place — the only treatment
// measured to keep overrides) and lets the builder draw new ones beside them.
// Once the entry has drawn, `reconcileRedrawnMembers` walks each old child
// against the new child with the same type and name: where the two trees have
// the same shape, every value the new tree carries is written onto the old one,
// the old one is read back against the new, and the old one stays while the new
// one goes. Where the shapes differ, or a value does not read back the same, or
// a write is refused, the new subtree replaces the old one — what the reset did
// before, for that subtree only, and counted.
//
// The bar is the picture: the kept tree must read back exactly as the new one
// did, on every property the builders can set. A property this file does not
// list is a property it neither copies nor checks, so the list is the contract
// (`kOwnFields` and `kGeomFields`); a value it cannot carry across reliably is a
// reason to replace, never a reason to keep a node that looks different.
//
// This module imports nothing from the plugin but the leaf `growth.ts`:
// `identity.ts` parks through it
// and installs the hook that moves a pending set's references across, and the
// modules that hold per-node records register a listener for the handles that
// change hands. One direction of import, as `set-layout.ts` keeps it.

import { GrowthSampler, GrowthStats } from './growth';

// ─── switch and state ──────────────────────────────────────────────────────

// Off unless a caller that reconciles turns it on: a reset with no reconcile
// after it would leave the old children hidden in the member for good. The run
// loop turns it on around each builder (`generate.ts`).
let enabled = false;

/** Turns keeping on or off for the resets that follow. Off is the old reset:
 *  children removed before the builder draws. */
export function setRedrawKeepsNodes(on: boolean): void {
  enabled = on;
}

export function redrawKeepsNodes(): boolean {
  return enabled;
}

/** Old children waiting for the entry to finish, by the member they belong to,
 *  in their original order. */
let parkedByMember = new Map<ComponentNode, SceneNode[]>();
/** Every parked node — what `isParkedForRedraw` answers from. */
let parkedNodes = new Set<BaseNode>();

/**
 * Whether `node` is an old child waiting to be reconciled. A builder that finds
 * an existing layer of its own by name or marker (the surface material does)
 * must skip these: the old node is not the builder's to reuse — reusing it
 * would put it in both the old and the new tree.
 */
export function isParkedForRedraw(node: BaseNode): boolean {
  return parkedNodes.has(node);
}

export function hasParkedForRedraw(): boolean {
  return parkedByMember.size > 0;
}

/**
 * Called by `resetNode` in place of removing `member`'s children. Hides each
 * child so the builder's layout cannot see it and leaves it where it is.
 * Returns the children it could not park (the caller removes those, as before).
 *
 * Hidden rather than moved anywhere: hiding a main's child, drawing a sibling of
 * the same name, removing that sibling and showing the child again keeps an
 * instance's overrides on it, and so does reordering the main's children —
 * both measured in the file.
 *
 * A child whose `visible` is bound to a property is never hidden. In a main,
 * writing `visible` on a bound layer is not refused: it rewrites the BOOLEAN's
 * default (measured — `visible = false` turned the default false, and every
 * instance's value with it), so a hide and a restore would leave the slot's
 * default at whatever they happened to write. Such a child is drawn
 * transparent (`opacity = 0`) and, under a member with auto-layout, taken out of
 * the flow (`layoutPositioning = ABSOLUTE`); a member that lays out nothing
 * already places it by x/y. The reconcile writes both back from the new node. A
 * child that refuses either write is handed back and removed, as the old reset
 * did, and counted as replaced.
 *
 * What this does not cover: a builder that turns a member which laid out
 * nothing into an auto-layout one mid-draw would see the transparent child in
 * its flow while it measures. The reconcile reads the result back, so such a
 * tree is replaced rather than kept wrong.
 */
export function parkForRedraw(member: ComponentNode): SceneNode[] {
  clearDrawnChildren(member);
  const kids = member.children.slice() as SceneNode[];
  if (!enabled || kids.length === 0) return kids;
  const refused: SceneNode[] = [];
  const parked = parkedByMember.get(member) ?? [];
  for (const child of kids) {
    if (parkedNodes.has(child)) continue;
    if (!hide(member, child)) {
      refused.push(child);
      costReplaced += 1;
      noteReason('bound-visible');
      continue;
    }
    parked.push(child);
    parkedNodes.add(child);
  }
  if (parked.length > 0) parkedByMember.set(member, parked);
  return refused;
}

/** Whether `node`'s `visible` is bound to a component property — a write to
 *  it would rewrite that property's default. Unreadable counts as bound. */
export function visibleIsBound(node: SceneNode): boolean {
  try {
    const refs = node.componentPropertyReferences as Record<string, string | undefined> | null | undefined;
    return refs != null && refs.visible !== undefined;
  } catch {
    return true;
  }
}

function hide(member: ComponentNode, child: SceneNode): boolean {
  try {
    if (!visibleIsBound(child)) {
      child.visible = false;
      return true;
    }
    const placed = child as SceneNode & { layoutPositioning?: string; opacity?: number };
    // A member that lays out nothing places its children by x/y, so a child
    // there is out of any flow already — it is only made transparent.
    if (placed.layoutPositioning !== 'ABSOLUTE' && member.layoutMode !== 'NONE') {
      placed.layoutPositioning = 'ABSOLUTE';
    }
    placed.opacity = 0;
    return true;
  } catch {
    return false;
  }
}

/** What `hide` may write on a node, as the node has it now — for putting back. */
function parkFieldsOf(node: SceneNode): Map<string, unknown> {
  const out = new Map<string, unknown>();
  for (const key of kParkWritten) out.set(key, plainCopy(read(node, key)));
  return out;
}

/** Puts back what `hide` wrote, from the values read just before it. A refused
 *  write is not a reason to stop: the node stays drawn as hidden, which the
 *  run's own read-back (fingerprint) reports. */
function restoreParked(node: SceneNode, before: Map<string, unknown>): void {
  for (const [key, want] of before) {
    if (key === 'visible' && visibleIsBound(node)) continue;
    if (canon(read(node, key)) === canon(want)) continue;
    try {
      (node as unknown as Record<string, unknown>)[key] = want;
    } catch {
      // see above
    }
  }
}

/**
 * Plugin data on a redrawn member: the ids of its direct children once the
 * reconcile has settled them, comma-joined.
 *
 * Keeping mixes sessions inside one member on purpose — a kept child carries
 * the id band of the run that first drew it, a replaced one the band of this
 * run. Two children with the same name (a list's two dividers) can land one in
 * each, which is exactly the shape the overlapping-siblings check reads as a
 * late-synced duplicate (`overlapping-siblings.ts`). The record is what that
 * check reads first: a child listed here is one this plugin put there.
 *
 * Cleared by every redraw (`parkForRedraw`) and written only by a reconcile
 * that kept something, so a record never outlives the children it names; a
 * member without one is read by the id bands as before.
 */
export const kDrawnChildrenKey = 'coui-drawn-children';

function clearDrawnChildren(member: ComponentNode): void {
  try {
    if (member.getPluginData(kDrawnChildrenKey) !== '') member.setPluginData(kDrawnChildrenKey, '');
  } catch {
    // A member that refuses plugin data keeps no record and is read by bands.
  }
}

function recordDrawnChildren(member: ComponentNode): void {
  try {
    member.setPluginData(kDrawnChildrenKey, (member.children as readonly SceneNode[]).map((c) => c.id).join(','));
  } catch {
    // as above
  }
}

/** Forgets the parking without touching the canvas — a failed entry. Its old
 *  children stay hidden beside the half-drawn new ones; the next run parks
 *  both and pairs the old first, so the nodes instances point at survive it. */
export function abandonRedrawParking(): void {
  parkedByMember = new Map();
  parkedNodes = new Set();
  wrapperMigrations = new Map();
  afterRedraw = new Map();
}

// A builder may explicitly retain text leaves while adding a wrapper. This is
// opt-in: ordinary shape mismatches still replace, and a refused migration
// aborts the redraw instead of deleting the original leaves.
interface TextWrapperMigration {
  member: ComponentNode;
  oldParent: FrameNode;
  freshParent: FrameNode;
  wrapper: FrameNode;
  leaves: { old: TextNode; fresh: TextNode }[];
  freshChildren: readonly SceneNode[];
}
let wrapperMigrations = new Map<SceneNode, TextWrapperMigration>();
let afterRedraw = new Map<ComponentNode, (() => Promise<void>)[]>();

export function retainTextInRedrawWrapper(input: Omit<TextWrapperMigration, 'freshChildren'>): void {
  const plan: TextWrapperMigration = { ...input, freshChildren: input.freshParent.children.slice() };
  if (!enabled || !parkedByMember.get(plan.member)?.includes(plan.oldParent)) {
    throw new Error('Text wrapper migration requires a parked original parent');
  }
  validateTextWrapper(plan);
  if (wrapperMigrations.has(plan.freshParent)) throw new Error('Duplicate text wrapper migration');
  wrapperMigrations.set(plan.freshParent, plan);
}

export function afterRedrawReconciled(member: ComponentNode, finish: () => Promise<void>): void {
  if (!parkedByMember.has(member)) throw new Error('Migration requires redraw reconciliation');
  afterRedraw.set(member, [...(afterRedraw.get(member) ?? []), finish]);
}

function validateTextWrapper(p: TextWrapperMigration): void {
  const same = (have: readonly SceneNode[], want: readonly SceneNode[]): boolean =>
    have.length === want.length && have.every((n, i) => n === want[i]);
  if (p.oldParent === p.freshParent || p.oldParent.parent !== p.member ||
      p.freshParent.parent !== p.member || p.wrapper.parent !== p.freshParent ||
      !same(p.freshParent.children, p.freshChildren) ||
      !same(p.oldParent.children, p.leaves.map(x => x.old)) ||
      !same(p.wrapper.children, p.leaves.map(x => x.fresh)) ||
      p.leaves.length === 0 || new Set(p.leaves.flatMap(x => [x.old, x.fresh])).size !== 2 * p.leaves.length ||
      p.leaves.some(x => x.old.type !== 'TEXT' || x.fresh.type !== 'TEXT' || x.old.removed || x.fresh.removed)) {
    throw new Error('Text wrapper migration topology changed; originals retained');
  }
}

// ─── hooks ────────────────────────────────────────────────────────────────

/** What `identity.ts` tells this module about a member's set. */
export interface RedrawMemberHook {
  /** The member belongs to a set whose references are still staged (deferred
   *  reassembly): its references are written when it is staged, not now. */
  isPending(member: ComponentNode): boolean;
  /** Writing into the member costs in proportion to a large assembled set —
   *  keeping is skipped there and the old children are removed (the old
   *  reset), because the writes it takes would cost what the bulk detach exists
   *  to avoid. */
  expensive(member: ComponentNode): boolean;
  /** Hands a pending member's kept nodes their references: `refsByOld` holds
   *  what each kept node must carry (the new node's references, staged and
   *  written). `pairs` maps every new node to the old one that stays. */
  remap(
    member: ComponentNode,
    pairs: Map<SceneNode, SceneNode>,
    refsByOld: Map<SceneNode, Record<string, string>>,
  ): void;
}

let memberHook: RedrawMemberHook = {
  isPending: () => false,
  expensive: () => false,
  remap: () => undefined,
};

export function installRedrawMemberHook(hook: RedrawMemberHook): void {
  memberHook = hook;
}

type KeptListener = (from: SceneNode, to: SceneNode) => void;
const keptListeners: KeptListener[] = [];

/** Called for every new node that is dropped in favour of an old one — the
 *  modules that keep per-node records (a drawn icon's side) move them across. */
export function onRedrawNodeKept(listener: KeptListener): void {
  keptListeners.push(listener);
}

// ─── counters ─────────────────────────────────────────────────────────────

export interface RedrawKeepCost {
  /** Old top-level children kept (overrides on them survive). */
  kept: number;
  /** Old top-level children removed: no new child to pair with, a different
   *  shape, a refused write or a value that did not read back. */
  replaced: number;
  ms: number;
  /** Why a paired child was replaced, by reason. */
  reasons: Record<string, number>;
  /** Where `ms` went (#5009). Absent on a cost built by hand. */
  split?: RedrawKeepSplit;
}

/**
 * `ms` cut into the steps `reconcileMember` takes, so a slow keep says which
 * step is slow — the shape the `append` cut gave that bracket (#5009).
 * `snapshot` reads the new tree, `apply` compares it onto the old one and
 * writes what differs, `verify` reads the old tree back, `tidy` removes the
 * losers and puts the winners in order, `remap` hands references and per-node
 * records across. What the five leave out (parking, skipped sets) is the rest.
 */
export interface RedrawKeepSplit {
  members: number;
  snapshotMs: number;
  /** Nodes read into snapshots. */
  snapshotNodes: number;
  applyMs: number;
  verifyMs: number;
  /** Nodes read back. */
  verifyNodes: number;
  /** Of `verifyNodes`, those with no write anywhere in the member from the
   *  moment `apply` first read them — their read-back re-reads values `apply`
   *  already found equal. The size of the room a fast path would have. */
  cleanNodes: number;
  tidyMs: number;
  remapMs: number;
  /** Field reads `snapshot` left out because the node's type has no such
   *  field (`kFieldOwners`) — each one is also a read `verify` does not make. */
  skippedReads: number;
  /** Node types whose first node read a value on a field the table says that
   *  type lacks — read in full from then on, and named here so the table gets
   *  fixed. */
  fullReadTypes: string[];
  /** One sample per reconciled member, in order: does a member cost more as
   *  the set fills? */
  memberGrowth: GrowthStats;
}

let costKept = 0;
let costReplaced = 0;
let costMs = 0;
let costReasons: Record<string, number> = {};

interface SplitAcc {
  members: number;
  snapshotMs: number;
  snapshotNodes: number;
  applyMs: number;
  verifyMs: number;
  verifyNodes: number;
  cleanNodes: number;
  tidyMs: number;
  remapMs: number;
  skippedReads: number;
  memberGrowth: GrowthSampler;
}

function freshSplit(): SplitAcc {
  return {
    members: 0,
    snapshotMs: 0,
    snapshotNodes: 0,
    applyMs: 0,
    verifyMs: 0,
    verifyNodes: 0,
    cleanNodes: 0,
    tidyMs: 0,
    remapMs: 0,
    skippedReads: 0,
    memberGrowth: new GrowthSampler(),
  };
}

let split = freshSplit();

function splitOut(): RedrawKeepSplit {
  const { memberGrowth, ...rest } = split;
  return { ...rest, fullReadTypes: [...fullReadTypes].sort(), memberGrowth: memberGrowth.stats() };
}

export function drainRedrawKeepCost(): RedrawKeepCost {
  const out: RedrawKeepCost = {
    kept: costKept,
    replaced: costReplaced,
    ms: costMs,
    reasons: costReasons,
    split: splitOut(),
  };
  costKept = 0;
  costReplaced = 0;
  costMs = 0;
  costReasons = {};
  split = freshSplit();
  return out;
}

export function peekRedrawKeepCost(): RedrawKeepCost {
  return { kept: costKept, replaced: costReplaced, ms: costMs, reasons: costReasons, split: splitOut() };
}

function noteReason(reason: string): void {
  costReasons[reason] = (costReasons[reason] ?? 0) + 1;
}

// ─── the fields ───────────────────────────────────────────────────────────
//
// Everything a builder or a helper writes on a node, from a grep of
// `src/components`, `helpers.ts`, `paint.ts`, `box.ts`, `surface-*.ts`,
// `icon-nodes.ts`, `text-*.ts`, `focus-ring.ts` and `component-props.ts`.
// Read off the new node, written on the old where the two differ, and read
// back off the old to prove it. A field a node type does not have reads
// `undefined` on both and is skipped.

interface Field {
  key: string;
  /** `figma.mixed` is legal and another field states the parts (corner radius,
   *  stroke weight): skipped. Otherwise a mixed value is a reason to replace. */
  mixedOk?: boolean;
  /** Not written inside an instance — Figma refuses the override there, and a
   *  layer's place in an instance follows from its main and its instance's box. */
  notInInstance?: boolean;
  /** TEXT only — loads fonts before writing. */
  text?: boolean;
}

// Written before the children: what the node is and how it lays them out.
const kOwnFields: readonly Field[] = [
  { key: 'visible' },
  { key: 'locked' },
  { key: 'opacity' },
  { key: 'blendMode' },
  { key: 'isMask' },
  { key: 'maskType' },
  { key: 'clipsContent' },
  { key: 'fills' },
  { key: 'strokes' },
  { key: 'strokeWeight', mixedOk: true },
  { key: 'strokeTopWeight' },
  { key: 'strokeBottomWeight' },
  { key: 'strokeLeftWeight' },
  { key: 'strokeRightWeight' },
  { key: 'strokeAlign' },
  { key: 'strokeCap', mixedOk: true },
  { key: 'strokeJoin', mixedOk: true },
  { key: 'strokeMiterLimit' },
  { key: 'dashPattern' },
  { key: 'cornerRadius', mixedOk: true },
  { key: 'topLeftRadius' },
  { key: 'topRightRadius' },
  { key: 'bottomLeftRadius' },
  { key: 'bottomRightRadius' },
  { key: 'cornerSmoothing' },
  { key: 'effects' },
  { key: 'layoutGrids' },
  { key: 'exportSettings' },
  { key: 'layoutMode' },
  { key: 'layoutWrap' },
  { key: 'itemSpacing' },
  { key: 'counterAxisSpacing' },
  { key: 'paddingLeft' },
  { key: 'paddingRight' },
  { key: 'paddingTop' },
  { key: 'paddingBottom' },
  { key: 'primaryAxisAlignItems' },
  { key: 'counterAxisAlignItems' },
  { key: 'counterAxisAlignContent' },
  { key: 'itemReverseZIndex' },
  { key: 'strokesIncludedInLayout' },
  { key: 'vectorPaths', notInInstance: true },
  { key: 'arcData' },
  { key: 'pointCount' },
  { key: 'innerRadius' },
  { key: 'booleanOperation' },
  // Typography. `fontName` first: every other text write needs the node's
  // current font loaded, and after this write that font is the new one.
  { key: 'fontName', text: true },
  { key: 'fontSize', text: true },
  { key: 'lineHeight', text: true },
  { key: 'letterSpacing', text: true },
  { key: 'textCase', text: true },
  { key: 'textDecoration', text: true },
  { key: 'textDecorationStyle', text: true },
  { key: 'textDecorationOffset', text: true },
  { key: 'textDecorationThickness', text: true },
  { key: 'textDecorationColor', text: true },
  { key: 'textDecorationSkipInk', text: true },
  { key: 'paragraphSpacing', text: true },
  { key: 'paragraphIndent', text: true },
  { key: 'listSpacing', text: true },
  { key: 'hangingPunctuation', text: true },
  { key: 'hangingList', text: true },
  { key: 'leadingTrim', text: true },
  { key: 'textAlignHorizontal', text: true },
  { key: 'textAlignVertical', text: true },
  { key: 'textTruncation', text: true },
  { key: 'maxLines', text: true },
  { key: 'characters', text: true },
];

// Written after the children: the box, which a hugging frame takes from them.
// Size goes in through `resize` (below), before the modes, because a resize
// turns a hugging axis fixed and the mode written after it puts that back.
const kGeomFields: readonly Field[] = [
  { key: 'primaryAxisSizingMode' },
  { key: 'counterAxisSizingMode' },
  { key: 'textAutoResize', text: true },
  { key: 'layoutSizingHorizontal' },
  { key: 'layoutSizingVertical' },
  { key: 'layoutAlign' },
  { key: 'layoutGrow' },
  { key: 'minWidth' },
  { key: 'maxWidth' },
  { key: 'minHeight' },
  { key: 'maxHeight' },
  { key: 'constraints', notInInstance: true },
  { key: 'layoutPositioning', notInInstance: true },
  { key: 'relativeTransform', notInInstance: true },
  { key: 'x', notInInstance: true },
  { key: 'y', notInInstance: true },
];

// Read and compared, never written directly: they follow from the writes
// above (size from `resize`; scale from the instance's main and the builder's
// `rescale`, which a kept instance either already carries or is replaced over).
const kReadOnlyCompared: readonly string[] = ['width', 'height', 'scaleFactor', 'isExposedInstance'];

// `boundVariables` keys carried inside a value already copied (a paint, an
// effect, a grid) — copying the value copies the binding.
const kBoundInsideValue: ReadonlySet<string> = new Set([
  'fills',
  'strokes',
  'effects',
  'layoutGrids',
  'componentProperties',
  'textRangeFills',
]);

// What `parkForRedraw` writes to set an old child aside.
const kParkWritten: ReadonlySet<string> = new Set(['visible', 'opacity', 'layoutPositioning']);

// Shared styles a node links to; written through their async setters, before
// the values the style would otherwise overwrite.
const kStyleFields = ['effectStyleId', 'fillStyleId', 'strokeStyleId', 'gridStyleId'] as const;

// Which node types have a field, for the fields only some types have — from
// the mixins each node interface extends in `@figma/plugin-typings`
// (`AutoLayoutMixin` · `BaseFrameMixin` on the frame-like nodes, `CornerMixin`,
// `RectangleCornerMixin`, `IndividualStrokesMixin`, and the shape nodes' own
// fields). A field a node's type lacks reads `undefined` on the new node and the
// old alike, so it is neither written nor compared — reading it is a round
// trip into the editor that cannot change the verdict, and a Button redraw
// makes tens of thousands of them (#5009).
//
// A type not in `kTypesWithOwners` reads every field. A field not in
// `kFieldOwners` is read on every type. Both default to reading, so a gap in
// the table costs time and never a check.
const kFrameLike = ['FRAME', 'COMPONENT', 'COMPONENT_SET', 'INSTANCE'];
const kCornered = [...kFrameLike, 'RECTANGLE', 'ELLIPSE', 'POLYGON', 'STAR', 'VECTOR', 'BOOLEAN_OPERATION'];
const kRectCornered = [...kFrameLike, 'RECTANGLE'];
const kFieldOwners: ReadonlyMap<string, ReadonlySet<string>> = new Map(
  (
    [
      ...[
        'clipsContent',
        'layoutGrids',
        'layoutMode',
        'layoutWrap',
        'itemSpacing',
        'counterAxisSpacing',
        'paddingLeft',
        'paddingRight',
        'paddingTop',
        'paddingBottom',
        'primaryAxisAlignItems',
        'counterAxisAlignItems',
        'counterAxisAlignContent',
        'itemReverseZIndex',
        'strokesIncludedInLayout',
        'primaryAxisSizingMode',
        'counterAxisSizingMode',
      ].map((key) => [key, kFrameLike] as const),
      ['cornerRadius', kCornered] as const,
      ['cornerSmoothing', kCornered] as const,
      ...['topLeftRadius', 'topRightRadius', 'bottomLeftRadius', 'bottomRightRadius'].map((key) => [key, kRectCornered] as const),
      ...['strokeTopWeight', 'strokeBottomWeight', 'strokeLeftWeight', 'strokeRightWeight'].map((key) => [key, kRectCornered] as const),
      ['vectorPaths', ['VECTOR']] as const,
      ['arcData', ['ELLIPSE']] as const,
      ['pointCount', ['POLYGON', 'STAR']] as const,
      ['innerRadius', ['STAR']] as const,
      ['booleanOperation', ['BOOLEAN_OPERATION']] as const,
    ] as ReadonlyArray<readonly [string, readonly string[]]>
  ).map(([key, types]) => [key, new Set(types)]),
);
// The types the table speaks for — every type that appears as an owner above,
// plus TEXT, LINE and GROUP, which own none of these fields.
const kTypesWithOwners: ReadonlySet<string> = new Set([...kCornered, 'TEXT', 'LINE', 'GROUP']);

/** The fields `snapshot` reads on a node of `type`, own then geometry. */
interface FieldPlan {
  own: readonly Field[];
  geom: readonly Field[];
  /** Fields left out for this type, checked once per run (`checkPlan`). */
  skipped: readonly string[];
}

const plans = new Map<string, FieldPlan>();
/** Types whose plan has been checked against a real node this run. */
const checkedTypes = new Set<string>();
/** Types the table was wrong about this run — read in full. */
const fullReadTypes = new Set<string>();

function planFor(type: string): FieldPlan {
  const cached = plans.get(type);
  if (cached) return cached;
  const isText = type === 'TEXT';
  const known = kTypesWithOwners.has(type) && !fullReadTypes.has(type);
  const skipped: string[] = [];
  const keep = (f: Field): boolean => {
    if (f.text && !isText) return false;
    const owners = kFieldOwners.get(f.key);
    if (known && owners && !owners.has(type)) {
      skipped.push(f.key);
      return false;
    }
    return true;
  };
  const plan: FieldPlan = { own: kOwnFields.filter(keep), geom: kGeomFields.filter(keep), skipped };
  plans.set(type, plan);
  return plan;
}

/**
 * The first node of each type in a run reads the fields its plan leaves out.
 * One that reads a value means the table is wrong for that type: the type is
 * read in full from then on and named in the log, so a table gap costs one
 * slower run and is visible, never a skipped check.
 */
function checkPlan(node: SceneNode, plan: FieldPlan): FieldPlan {
  if (checkedTypes.has(node.type)) return plan;
  checkedTypes.add(node.type);
  if (plan.skipped.some((key) => read(node, key) !== undefined)) {
    fullReadTypes.add(node.type);
    plans.delete(node.type);
    return planFor(node.type);
  }
  return plan;
}

// ─── reading ──────────────────────────────────────────────────────────────

class Mismatch extends Error {
  constructor(readonly reason: string, detail: string) {
    super(`${reason}: ${detail}`);
  }
}

function mixedSymbol(): unknown {
  const f = (globalThis as unknown as { figma?: { mixed?: unknown } }).figma;
  return f ? f.mixed : undefined;
}

function isMixed(v: unknown): boolean {
  return typeof v === 'symbol' || (v !== undefined && v === mixedSymbol());
}

function read(node: SceneNode, key: string): unknown {
  try {
    return (node as unknown as Record<string, unknown>)[key];
  } catch {
    // A field the node type refuses to answer reads as absent.
    return undefined;
  }
}

/** A value as data, for comparing. Variables and aliases compare by id. */
function canon(v: unknown): string {
  if (v === undefined) return 'u';
  if (isMixed(v)) return 'mixed';
  try {
    return JSON.stringify(v, (_k, value: unknown) => {
      if (typeof value === 'function' || typeof value === 'symbol') return undefined;
      if (value != null && typeof value === 'object') {
        const o = value as Record<string, unknown>;
        // A bound variable reads as an alias in Figma and as the variable
        // itself in a double; either way its identity is its id.
        if (typeof o.id === 'string' && (o.type === 'VARIABLE_ALIAS' || 'resolvedType' in o || 'key' in o)) {
          return { variable: o.id };
        }
      }
      return value;
    });
  } catch {
    return `unreadable:${String(v)}`;
  }
}

function plainCopy<T>(v: T): T {
  if (v == null || typeof v !== 'object') return v;
  if (Array.isArray(v)) return v.map((x) => plainCopy(x)) as unknown as T;
  const out: Record<string, unknown> = {};
  for (const key of Object.keys(v as Record<string, unknown>)) {
    out[key] = plainCopy((v as Record<string, unknown>)[key]);
  }
  return out as T;
}

function variableIdOf(v: unknown): string | null {
  if (v == null || typeof v !== 'object') return null;
  const id = (v as { id?: unknown }).id;
  return typeof id === 'string' ? id : null;
}

interface Snap {
  node: SceneNode;
  type: string;
  name: string;
  props: Map<string, unknown>;
  styles: Map<string, unknown>;
  textStyleId: unknown;
  bound: Map<string, unknown>;
  refs: Record<string, string> | null;
  pluginData: Map<string, string>;
  componentProperties: Record<string, { type: string; value: unknown }> | null;
  modes: Record<string, string> | null;
  mainId: string | null;
  kids: Snap[];
}

async function mainIdOf(node: SceneNode): Promise<string | null> {
  if (node.type !== 'INSTANCE') return null;
  const inst = node as InstanceNode & { getMainComponentAsync?: () => Promise<ComponentNode | null> };
  if (typeof inst.getMainComponentAsync !== 'function') return null;
  const main = await inst.getMainComponentAsync();
  return main ? main.id : null;
}

function pluginDataOf(node: SceneNode): Map<string, string> {
  const out = new Map<string, string>();
  const keys = (node as unknown as { getPluginDataKeys?: () => string[] }).getPluginDataKeys;
  if (typeof keys !== 'function') return out;
  for (const key of keys.call(node)) {
    const value = node.getPluginData(key);
    if (value !== '') out.set(key, value);
  }
  return out;
}

function refsOf(node: SceneNode): Record<string, string> | null {
  const raw = read(node, 'componentPropertyReferences') as Record<string, string | undefined> | null | undefined;
  if (!raw) return null;
  const out: Record<string, string> = {};
  let any = false;
  for (const key of Object.keys(raw)) {
    const v = raw[key];
    if (typeof v === 'string') {
      out[key] = v;
      any = true;
    }
  }
  return any ? out : null;
}

function boundOf(node: SceneNode): Map<string, unknown> {
  const out = new Map<string, unknown>();
  const raw = read(node, 'boundVariables') as Record<string, unknown> | undefined;
  if (!raw) return out;
  for (const key of Object.keys(raw)) {
    if (kBoundInsideValue.has(key)) continue;
    const v = raw[key];
    if (v != null) out.set(key, v);
  }
  return out;
}

async function snapshot(node: SceneNode): Promise<Snap> {
  const props = new Map<string, unknown>();
  // Every read crosses into the editor, and a set like Button snapshots and
  // verifies thousands of nodes — a field is only read on the types that have
  // it (`planFor`). Absent from `props`, a field is neither written nor compared.
  const plan = checkPlan(node, planFor(node.type));
  for (const f of plan.own) props.set(f.key, plainCopy(read(node, f.key)));
  for (const f of plan.geom) props.set(f.key, plainCopy(read(node, f.key)));
  split.skippedReads += plan.skipped.length;
  for (const key of kReadOnlyCompared) props.set(key, plainCopy(read(node, key)));
  const styles = new Map<string, unknown>();
  for (const key of kStyleFields) styles.set(key, read(node, key));
  const cp = read(node, 'componentProperties') as Record<string, { type: string; value: unknown }> | undefined;
  const modes = read(node, 'explicitVariableModes') as Record<string, string> | undefined;
  const kids: Snap[] = [];
  const children = (node as unknown as { children?: readonly SceneNode[] }).children;
  if (children) for (const kid of children) kids.push(await snapshot(kid));
  return {
    node,
    type: node.type,
    name: node.name,
    props,
    styles,
    textStyleId: read(node, 'textStyleId'),
    bound: boundOf(node),
    refs: refsOf(node),
    pluginData: pluginDataOf(node),
    componentProperties: cp ? plainCopy(cp) : null,
    modes: modes ? plainCopy(modes) : null,
    mainId: await mainIdOf(node),
    kids,
  };
}

// ─── writing ──────────────────────────────────────────────────────────────

// Every write into the canvas this module makes, counted. A node `apply` read
// with no write anywhere after it reads back what `apply` saw — the count is
// how `verify` tells those nodes from the rest (`RedrawKeepSplit.cleanNodes`).
let writeCount = 0;
/** `writeCount` when `apply` reached each old node, this member only. */
let writesAtEntry = new Map<SceneNode, number>();

interface Ctx {
  /** Inside an instance: geometry is the instance's, and structure is its main's. */
  insideInstance: boolean;
  /** The member's references are staged, not written here (`RedrawMemberHook`). */
  pending: boolean;
}

const loadedFonts = new Set<string>();

async function loadFont(font: unknown): Promise<void> {
  if (font == null || typeof font !== 'object' || isMixed(font)) return;
  const f = font as FontName;
  if (typeof f.family !== 'string' || typeof f.style !== 'string') return;
  const key = `${f.family}\u0000${f.style}`;
  if (loadedFonts.has(key)) return;
  await figma.loadFontAsync(f);
  loadedFonts.add(key);
}

/** Forgets which fonts were loaded and which field plans were checked — a new
 *  run, a new document. */
export function resetRedrawFontCache(): void {
  loadedFonts.clear();
  plans.clear();
  checkedTypes.clear();
  fullReadTypes.clear();
}

function write(node: SceneNode, key: string, value: unknown): void {
  writeCount += 1;
  try {
    (node as unknown as Record<string, unknown>)[key] = plainCopy(value);
  } catch (err) {
    throw new Mismatch(`refused:${key}`, `${node.name}: ${String(err)}`);
  }
}

/** Paints go in twice when the first write does not hold them: a paint bound to
 *  a variable is reset to full strength the first time that binding lands on an
 *  index (`assignPaints`), and the second write, carrying the binding the node
 *  now holds, keeps what it is given. */
function writePaints(node: SceneNode, key: string, want: unknown): void {
  write(node, key, want);
  if (canon(read(node, key)) !== canon(want)) write(node, key, want);
}

async function setStyleId(node: SceneNode, key: string, id: unknown): Promise<void> {
  const setter = `set${key.charAt(0).toUpperCase()}${key.slice(1)}Async`;
  const fn = (node as unknown as Record<string, unknown>)[setter];
  writeCount += 1;
  try {
    if (typeof fn === 'function') {
      await (fn as (id: string) => Promise<void>).call(node, typeof id === 'string' ? id : '');
    } else {
      (node as unknown as Record<string, unknown>)[key] = id;
    }
  } catch (err) {
    throw new Mismatch(`refused:${key}`, `${node.name}: ${String(err)}`);
  }
}

async function variableFor(value: unknown): Promise<Variable | null> {
  if (value == null) return null;
  const id = variableIdOf(value);
  const o = value as { type?: unknown };
  // A double hands the variable itself back; Figma hands an alias.
  if (o.type !== 'VARIABLE_ALIAS') return value as Variable;
  if (id === null) return null;
  const v = await figma.variables.getVariableByIdAsync(id);
  if (v == null) throw new Mismatch('variable-missing', id);
  return v;
}

function firstOf(value: unknown): unknown {
  return Array.isArray(value) ? value[0] : value;
}

async function writeBound(node: SceneNode, want: Map<string, unknown>): Promise<void> {
  const have = boundOf(node);
  const keys = new Set<string>([...want.keys(), ...have.keys()]);
  for (const key of keys) {
    const w = want.get(key);
    if (canon(w) === canon(have.get(key))) continue;
    // A per-range binding the node states more than once is not one value.
    if (Array.isArray(w) && w.length > 1 && new Set(w.map((x) => variableIdOf(x))).size > 1) {
      throw new Mismatch('mixed-binding', `${node.name}.${key}`);
    }
    const variable = await variableFor(firstOf(w));
    writeCount += 1;
    try {
      (node as unknown as { setBoundVariable(f: string, v: Variable | null): void }).setBoundVariable(key, variable);
    } catch (err) {
      throw new Mismatch(`refused:bound:${key}`, `${node.name}: ${String(err)}`);
    }
  }
}

async function writeModes(node: SceneNode, want: Record<string, string> | null): Promise<void> {
  const have = (read(node, 'explicitVariableModes') as Record<string, string> | undefined) ?? {};
  const w = want ?? {};
  const ids = new Set<string>([...Object.keys(w), ...Object.keys(have)]);
  for (const id of ids) {
    if (w[id] === have[id]) continue;
    const collection = await figma.variables.getVariableCollectionByIdAsync(id);
    if (collection == null) throw new Mismatch('collection-missing', id);
    writeCount += 1;
    try {
      if (w[id] === undefined) {
        (node as unknown as { clearExplicitVariableModeForCollection(c: VariableCollection): void })
          .clearExplicitVariableModeForCollection(collection);
      } else {
        (node as unknown as { setExplicitVariableModeForCollection(c: VariableCollection, m: string): void })
          .setExplicitVariableModeForCollection(collection, w[id]);
      }
    } catch (err) {
      throw new Mismatch('refused:mode', `${node.name}: ${String(err)}`);
    }
  }
}

function writePluginData(node: SceneNode, want: Map<string, string>): void {
  const have = pluginDataOf(node);
  for (const [key, value] of want) {
    if (have.get(key) === value) continue;
    writeCount += 1;
    node.setPluginData(key, value);
  }
  for (const key of have.keys()) {
    if (want.has(key)) continue;
    writeCount += 1;
    node.setPluginData(key, '');
  }
}

function writeComponentProperties(
  node: SceneNode,
  want: Record<string, { type: string; value: unknown }> | null,
): void {
  if (!want) return;
  const have = (read(node, 'componentProperties') as Record<string, { type: string; value: unknown }> | undefined) ?? {};
  const patch: Record<string, string | boolean> = {};
  let any = false;
  for (const key of Object.keys(want)) {
    if (want[key].type === 'VARIANT') continue;
    const current = have[key];
    if (current && canon(current.value) === canon(want[key].value)) continue;
    patch[key] = want[key].value as string | boolean;
    any = true;
  }
  if (!any) return;
  writeCount += 1;
  try {
    (node as InstanceNode).setProperties(patch);
  } catch (err) {
    throw new Mismatch('refused:setProperties', `${node.name}: ${String(err)}`);
  }
}

function writeFields(node: SceneNode, fields: readonly Field[], snap: Snap, ctx: Ctx): void {
  for (const f of fields) {
    if (f.notInInstance && ctx.insideInstance) continue;
    const want = snap.props.get(f.key);
    // The fields the parking itself wrote are put back even when the new node
    // does not state them (a double's fresh node; Figma's always reads a value).
    if (want === undefined && !kParkWritten.has(f.key)) continue;
    if (isMixed(want)) {
      if (f.mixedOk) continue;
      throw new Mismatch('mixed', `${snap.name}.${f.key}`);
    }
    // A bound `visible` is the property's default — writing it would change
    // the default for every instance. Left alone; a difference fails `verify`
    // and the subtree is replaced instead.
    if (f.key === 'visible' && visibleIsBound(node)) continue;
    const have = read(node, f.key);
    if (canon(have) === canon(want)) continue;
    if (f.key === 'fills' || f.key === 'strokes') writePaints(node, f.key, want);
    else write(node, f.key, want);
  }
}

function resizeTo(node: SceneNode, snap: Snap, ctx: Ctx): void {
  const w = snap.props.get('width');
  const h = snap.props.get('height');
  if (typeof w !== 'number' || typeof h !== 'number') return;
  if (read(node, 'width') === w && read(node, 'height') === h) return;
  if (ctx.insideInstance) return; // the instance's box decides; compared below
  const r = node as unknown as { resize?: (w: number, h: number) => void; resizeWithoutConstraints?: (w: number, h: number) => void };
  writeCount += 1;
  try {
    if (typeof r.resizeWithoutConstraints === 'function') r.resizeWithoutConstraints(w, h);
    else if (typeof r.resize === 'function') r.resize(w, h);
  } catch (err) {
    throw new Mismatch('refused:resize', `${node.name}: ${String(err)}`);
  }
}

async function apply(old: SceneNode, snap: Snap, ctx: Ctx): Promise<void> {
  writesAtEntry.set(old, writeCount);
  if (old.removed) throw new Mismatch('removed', snap.name);
  if (old.type !== snap.type) throw new Mismatch('type', `${old.type} → ${snap.type}`);
  if (old.name !== snap.name) throw new Mismatch('name', `${old.name} → ${snap.name}`);
  if (snap.type === 'INSTANCE') {
    if (snap.mainId === null || (await mainIdOf(old)) !== snap.mainId) {
      throw new Mismatch('main', snap.name);
    }
    // The builder's own overrides on a composed instance: its properties,
    // then its layers' values (below, through the children).
    writeComponentProperties(old, snap.componentProperties);
  }
  if (snap.type === 'TEXT') {
    await loadFont(read(old, 'fontName'));
    await loadFont(snap.props.get('fontName'));
    // A style attaches the whole typography; writing a field after it would
    // detach it again. Detached here when the new node carries none, attached
    // last otherwise.
    if (snap.textStyleId === '' && read(old, 'textStyleId') !== '') await setStyleId(old, 'textStyleId', '');
  }
  for (const key of kStyleFields) {
    const want = snap.styles.get(key);
    if (want === undefined || isMixed(want)) continue;
    if (read(old, key) !== want) await setStyleId(old, key, want);
  }
  writeFields(old, kOwnFields, snap, ctx);
  if (snap.type === 'TEXT' && typeof snap.textStyleId === 'string' && snap.textStyleId !== '') {
    if (read(old, 'textStyleId') !== snap.textStyleId) await setStyleId(old, 'textStyleId', snap.textStyleId);
  }
  await writeModes(old, snap.modes);

  const oldKids = ((old as unknown as { children?: readonly SceneNode[] }).children ?? []) as readonly SceneNode[];
  if (oldKids.length !== snap.kids.length) {
    throw new Mismatch('children', `${snap.name}: ${oldKids.length} → ${snap.kids.length}`);
  }
  const inner: Ctx = { insideInstance: ctx.insideInstance || snap.type === 'INSTANCE', pending: ctx.pending };
  for (let i = 0; i < snap.kids.length; i++) await apply(oldKids[i], snap.kids[i], inner);

  resizeTo(old, snap, ctx);
  writeFields(old, kGeomFields, snap, ctx);
  await writeBound(old, snap.bound);
  if (!ctx.insideInstance) {
    writePluginData(old, snap.pluginData);
    if (!ctx.pending && canon(refsOf(old)) !== canon(snap.refs)) {
      write(old, 'componentPropertyReferences', snap.refs ?? {});
    }
  }
}

function verify(old: SceneNode, snap: Snap, ctx: Ctx): void {
  split.verifyNodes += 1;
  if (writesAtEntry.get(old) === writeCount) split.cleanNodes += 1;
  const check = (key: string, have: unknown, want: unknown): void => {
    if (isMixed(want)) return;
    if (canon(have) !== canon(want)) {
      throw new Mismatch(`differs:${key}`, `${snap.name}: ${canon(have).slice(0, 80)} ≠ ${canon(want).slice(0, 80)}`);
    }
  };
  for (const [key, want] of snap.props) check(key, read(old, key), want);
  for (const [key, want] of snap.styles) check(key, read(old, key), want);
  check('textStyleId', read(old, 'textStyleId'), snap.textStyleId);
  check('boundVariables', [...boundOf(old)].sort(), [...snap.bound].sort());
  check('explicitVariableModes', read(old, 'explicitVariableModes') ?? null, snap.modes);
  if (snap.type === 'INSTANCE') {
    const cp = read(old, 'componentProperties') as Record<string, { value: unknown }> | undefined;
    const want = snap.componentProperties ?? {};
    for (const key of Object.keys(want)) check(`componentProperties.${key}`, cp?.[key]?.value, want[key].value);
  }
  if (!ctx.insideInstance) {
    check('pluginData', [...pluginDataOf(old)].sort(), [...snap.pluginData].sort());
    if (!ctx.pending) check('componentPropertyReferences', refsOf(old), snap.refs);
  }
  const oldKids = ((old as unknown as { children?: readonly SceneNode[] }).children ?? []) as readonly SceneNode[];
  if (oldKids.length !== snap.kids.length) throw new Mismatch('children', snap.name);
  const inner: Ctx = { insideInstance: ctx.insideInstance || snap.type === 'INSTANCE', pending: ctx.pending };
  for (let i = 0; i < snap.kids.length; i++) {
    if (oldKids[i].name !== snap.kids[i].name || oldKids[i].type !== snap.kids[i].type) {
      throw new Mismatch('children', `${snap.name}[${i}]`);
    }
    verify(oldKids[i], snap.kids[i], inner);
  }
}

function pairUp(old: SceneNode, snap: Snap, pairs: Map<SceneNode, SceneNode>, refsByOld: Map<SceneNode, Record<string, string>>): void {
  if (snap.node !== old) {
    pairs.set(snap.node, old);
    refsByOld.set(old, snap.refs ?? {});
  }
  const oldKids = ((old as unknown as { children?: readonly SceneNode[] }).children ?? []) as readonly SceneNode[];
  for (let i = 0; i < snap.kids.length && i < oldKids.length; i++) pairUp(oldKids[i], snap.kids[i], pairs, refsByOld);
}

function migrateTextWrapper(plan: TextWrapperMigration, snap: Snap): void {
  validateTextWrapper(plan);
  const wrapperSnap = snap.kids.find(k => k.node === plan.wrapper);
  if (!wrapperSnap || wrapperSnap.kids.length !== plan.leaves.length ||
      plan.leaves.some((pair, i) => wrapperSnap.kids[i].node !== pair.fresh)) {
    throw new Error('Text wrapper migration snapshot changed; originals retained');
  }
  // Reparent before the normal apply/verify: auto-layout positions must be
  // checked in the final wrapper, not in the legacy padded parent. Only fresh
  // generated leaves are removed; original IDs survive even a later refusal.
  for (const pair of plan.leaves) {
    pair.old.name = pair.fresh.name;
    plan.wrapper.appendChild(pair.old);
  }
  for (const pair of plan.leaves) pair.fresh.remove();
  for (const child of plan.freshParent.children.slice()) plan.oldParent.appendChild(child);
}

// ─── one member ───────────────────────────────────────────────────────────

function countNodes(snap: Snap): number {
  let n = 1;
  for (const kid of snap.kids) n += countNodes(kid);
  return n;
}

function keyOf(node: SceneNode): string {
  return `${node.type}\u0000${node.name}`;
}

async function reconcileMember(member: ComponentNode, parked: SceneNode[]): Promise<void> {
  const parkedSet = new Set<SceneNode>(parked);
  const old = parked.filter((n) => !n.removed && n.parent === member);
  const fresh = (member.children as readonly SceneNode[]).filter((n) => !parkedSet.has(n));
  if (memberHook.expensive(member)) {
    if (fresh.some(n => wrapperMigrations.has(n))) throw new Error('Wrapper migration cannot replace assembled members');
    for (const n of old) n.remove();
    costReplaced += old.length;
    if (old.length > 0) noteReason('skipped:assembled-set');
    return;
  }
  const pending = memberHook.isPending(member);
  writesAtEntry = new Map();
  // Taken before any write, so a value the reconcile changes elsewhere (an
  // instance of a member reconciled earlier) is read as the builder left it.
  const snapAt = Date.now();
  const snaps = new Map<SceneNode, Snap>();
  for (const n of fresh) {
    const snap = await snapshot(n);
    snaps.set(n, snap);
    split.snapshotNodes += countNodes(snap);
  }
  split.snapshotMs += Date.now() - snapAt;
  const used = new Set<SceneNode>();
  const attempted = new Set<SceneNode>();
  const final: SceneNode[] = [];
  const dropNew: SceneNode[] = [];
  const pairs = new Map<SceneNode, SceneNode>();
  const refsByOld = new Map<SceneNode, Record<string, string>>();
  for (const n of fresh) {
    const candidate = old.find((o) => !used.has(o) && keyOf(o) === keyOf(n));
    if (!candidate) {
      if (wrapperMigrations.has(n)) throw new Error('Migration original parent changed; no replacement attempted');
      final.push(n);
      continue;
    }
    used.add(candidate);
    attempted.add(candidate);
    const snap = snaps.get(n)!;
    // Only one of the pair may be in the member's flow at a time. With both in
    // it the member hugs both while the old node is written, and a child pinned
    // to the member (a STRETCH focus ring) is sized against that wider box —
    // then shrinks with it when the new node is removed (measured: an 88-wide
    // member kept a 42-wide ring). Siblings placed by the flow land elsewhere too.
    const beforeHide = parkFieldsOf(n);
    const outOfFlow = hide(member, n);
    try {
      if (!outOfFlow) throw new Mismatch('refused:park-new', snap.name);
      const ctx: Ctx = { insideInstance: false, pending };
      const migration = wrapperMigrations.get(n);
      if (migration) {
        if (migration.oldParent !== candidate) throw new Error('Migration parent pairing changed');
        try { migrateTextWrapper(migration, snap); }
        catch (err) { throw new Error(`Text wrapper migration failed; original IDs retained: ${String(err)}`); }
      }
      const applyAt = Date.now();
      try {
        await apply(candidate, snap, ctx);
      } finally {
        split.applyMs += Date.now() - applyAt;
      }
      const verifyAt = Date.now();
      try {
        verify(candidate, snap, ctx);
      } finally {
        split.verifyMs += Date.now() - verifyAt;
      }
      final.push(candidate);
      dropNew.push(n);
      pairUp(candidate, snap, pairs, refsByOld);
      costKept += 1;
    } catch (err) {
      if (wrapperMigrations.has(n) || !(err instanceof Mismatch)) throw err;
      noteReason(err.reason.split(':').slice(0, 2).join(':'));
      used.delete(candidate);
      // The old node leaves the flow before the new one returns, for the same
      // reason as above: the children written after this one see the final box.
      hide(member, candidate);
      restoreParked(n, beforeHide);
      final.push(n);
    }
  }
  const tidyAt = Date.now();
  for (const o of old) {
    if (final.indexOf(o) >= 0) continue;
    // Never attempted: the new tree has no child of its type and name.
    if (!attempted.has(o)) noteReason('unpaired');
    o.remove();
    costReplaced += 1;
  }
  for (const n of dropNew) n.remove();
  // Into the builder's order. Nothing moves when every old child was kept in
  // order — the kept nodes are already first and the new ones have gone.
  for (let i = 0; i < final.length; i++) {
    if (member.children[i] !== final[i]) member.insertChild(i, final[i]);
  }
  if (pairs.size > 0) recordDrawnChildren(member);
  split.tidyMs += Date.now() - tidyAt;
  if (pairs.size > 0) {
    const remapAt = Date.now();
    memberHook.remap(member, pairs, refsByOld);
    for (const [from, to] of pairs) for (const listener of keptListeners) listener(from, to);
    split.remapMs += Date.now() - remapAt;
  }
}

/**
 * Settles every member this entry redrew: keeps the old child wherever the new
 * one has its shape and values, replaces it otherwise. Called by the run loop
 * after the entry's tints and text styles are on the new nodes and before its
 * fingerprint and reassembly — the last moment the new tree is complete and the
 * members are still loose.
 */
export async function reconcileRedrawnMembers(): Promise<RedrawKeepCost> {
  const startedAt = Date.now();
  const work = parkedByMember;
  parkedByMember = new Map();
  try {
    for (const [member, parked] of work) {
      if (member.removed) continue;
      const memberAt = Date.now();
      await reconcileMember(member, parked);
      for (const finish of afterRedraw.get(member) ?? []) await finish();
      afterRedraw.delete(member);
      split.members += 1;
      split.memberGrowth.add(Date.now() - memberAt);
    }
  } finally {
    for (const [member, parked] of work) {
      for (const n of parked) parkedNodes.delete(n);
      afterRedraw.delete(member);
    }
    wrapperMigrations = new Map();
    costMs += Date.now() - startedAt;
  }
  return peekRedrawKeepCost();
}
