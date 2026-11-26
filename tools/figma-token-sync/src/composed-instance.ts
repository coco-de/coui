/// <reference types="@figma/plugin-typings" />

import { setInstanceBoolNamed } from './component-props';

// A composed `Button` whose code counterpart takes an `Icon` as its only child,
// and the two things every such composition has to do to that instance: take
// its words away, and hold it at the box the widget resolves.
//
// Both used to be written twice — once in `display-data.ts` (Banner's dismiss,
// Chip's close, CodeSnippet's copy) and once in `form-pickers.ts` (Calendar's
// nav arrows, ColorPicker's eyedropper) — and the two copies had already
// drifted: one picked the instance's label depth-first, the other direct
// children first. Both halves also failed on the canvas the same way
// (#4885): the label stayed visible, and the instance kept Button's own size-row
// height while the frame around it took the one asked for. One definition now,
// so a fix lands on all five call sites at once.

// A composed instance's own label node, or null.
//
// Direct children first, and only then a deep search: `Button`'s main component
// carries hidden leading/trailing icon frames and a state layer around its
// label, so a depth-first "first TEXT anywhere" pick would start returning
// whatever text one of those subtrees grows instead of the label.
//
// Not a general "the instance's label" — a deeper component does not keep its
// copy at the top. `TextField`'s first TEXT descendant is the one inside its
// hidden `FormLabel` instance, which is why the value written into a field goes
// through named properties and never through here.
export function instanceTextNode(inst: InstanceNode): TextNode | null {
  for (const child of inst.children) {
    if (child.type === 'TEXT') return child;
  }
  for (const node of inst.findAll((n) => n.type === 'TEXT')) {
    if (node.type === 'TEXT') return node;
  }
  return null;
}

// Drops the label out of a composed instance whose code counterpart has none —
// `Button(child: Icon(…))` passes no text at all.
//
// Through the child's own `Show child` BOOLEAN when it declares one, and only
// otherwise through the node. `Button` binds its label's `visible` to that
// property (`form.ts`), and a bound `visible` has one source of truth: writing
// the node inside an instance does not flip the property, so the label went on
// drawing "Button" in Chip's close and CodeSnippet's copy while this line
// reported nothing. The node write is kept as the fallback for a child that
// declares no such property — and for the runtime harness, which models
// component properties on a main component and not on an instance.
//
// Hidden rather than emptied: an auto-layout frame skips hidden children, and it
// asks nothing of Figma about whether a text property may hold `''`.
export function hideInstanceLabel(inst: InstanceNode): void {
  if (declaresBool(inst, kShowChildProp)) {
    setInstanceBoolNamed(inst, kShowChildProp, false);
    return;
  }
  const node = instanceTextNode(inst);
  if (node) node.visible = false;
}

/** The property `Button` binds its label's visibility to (`form.ts`). */
const kShowChildProp = 'Show child';

function declaresBool(inst: InstanceNode, name: string): boolean {
  const props: ComponentProperties | undefined = inst.componentProperties;
  if (!props || typeof inst.setProperties !== 'function') return false;
  for (const key of Object.keys(props)) {
    if (props[key].type === 'BOOLEAN' && key.split('#')[0] === name) return true;
  }
  return false;
}

// Holds a composed instance at exactly `width × height`.
//
// A bare `resize` was not enough. `Button`'s members lock their height to the
// size row (`form.ts` resizes each to `s.height`, and floors a shaped member's
// width at the same number), and the canvas showed the instance keeping that
// height — CodeSnippet's copy asked for 28×28 and drew 28×32 — while the width
// took. So the box is stated from every side an instance can carry it:
//
//   · both sizing modes FIXED, so neither axis is left for auto-layout to
//     recompute from the (now hidden) contents;
//   · an inherited `min*`/`max*` that would clamp the asked box is cleared on
//     the instance — the widget's `SizedBox(width:)` / `ConstrainedBox` on
//     a forwarded `buttonStyle` beats Button's own floor, and a Figma floor the
//     instance inherited would not;
//   · then the resize, LAST, after every other override on the instance, so
//     nothing written afterwards re-lays it out.
//
// And then it is READ BACK. Whether the height still reverts is a fact about
// Figma's layout engine that the runtime harness cannot see (its nodes have no
// layout engine), so the answer is recorded where a human reads it — one line
// per entry in the Generate log, the same drain the off-ladder icon sizes use —
// instead of the frame around the instance quietly taking the asked size while
// the instance does not.
export function pinInstanceBox(inst: InstanceNode, width: number, height: number): void {
  if (inst.layoutMode !== 'NONE') {
    inst.primaryAxisSizingMode = 'FIXED';
    inst.counterAxisSizingMode = 'FIXED';
  }
  if (inst.minWidth != null && inst.minWidth > width) inst.minWidth = null;
  if (inst.maxWidth != null && inst.maxWidth < width) inst.maxWidth = null;
  if (inst.minHeight != null && inst.minHeight > height) inst.minHeight = null;
  if (inst.maxHeight != null && inst.maxHeight < height) inst.maxHeight = null;
  inst.resize(width, height);
  const drift = Math.abs(inst.width - width) > kBoxTolerance || Math.abs(inst.height - height) > kBoxTolerance;
  if (drift) {
    unpinnedInstanceBoxes.push(
      `${inst.name} asked ${width}×${height}, holds ${inst.width}×${inst.height}`,
    );
  }
}

/** Sub-pixel slack for the read-back — Figma stores sizes as floats. */
const kBoxTolerance = 0.01;

/** One line per instance that did not take the box `pinInstanceBox` asked for. */
const unpinnedInstanceBoxes: string[] = [];

/** Reports the instances that kept a different box than asked, and clears the
 *  list. Drained per entry by `generate.ts`, beside the icon and spacing drains. */
export function drainUnpinnedInstanceBoxes(): string[] {
  return unpinnedInstanceBoxes.splice(0);
}
