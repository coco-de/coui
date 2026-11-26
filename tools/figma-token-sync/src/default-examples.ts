/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { instanceOf, mainComponentIdOf } from './identity';
import type { SwapDefault } from './component-props';

// ─── The example a caller slot shows by default (#6473) ──────────────────────
//
// A `W` / `W?` slot is drawn as the `.Slot` stand-in — a dashed outline that
// says "something goes here" (slot-stand-in.ts). For most slots that is the
// honest picture. For eight components it is the whole component: a popover,
// a hover card or a device frame whose only content is a dashed box reads as
// empty, not as "your content goes here", and a designer placing one has to
// build a sample before the component shows what it is for.
//
// So those slots default to an EXAMPLE instead: a `.Example/<Name> content`
// component the builders draw out of CoUI's own components (Avatar, Button,
// Progress) and text roles, and the slot's INSTANCE_SWAP defaults to it. The
// example is still only a default — the swap takes any component — and its
// name starts with `.`, which keeps it out of the published library. The code
// does not change: these are caller slots, and the example is the canvas's.
//
// Where each one is drawn is `components/fixtures.ts`; this module only names
// them, so a builder that composes one never imports another builder.

export const kPopoverExample = '.Example/Popover content';
export const kHoverCardExample = '.Example/HoverCard content';
export const kNavigationMenuExample = '.Example/NavigationMenu content';
export const kDraggablePanelExample = '.Example/DraggablePanel content';
export const kRefreshTriggerExample = '.Example/RefreshTrigger content';
export const kMockupDeviceExample = '.Example/MockupDevice screen';

/** An instance of an example, named for the slot it fills. */
export function exampleInstance(page: PageNode, example: string, name: string): InstanceNode {
  const instance = instanceOf(page, example);
  instance.name = name;
  return instance;
}

/** The example's main component — what a slot that holds it swaps to. */
export function exampleMainId(page: PageNode, example: string): string {
  return mainComponentIdOf(page, example);
}

/**
 * A slot's swap default once it shows `example`, taking over from the
 * stand-in default it held before (`previous`).
 *
 * The takeover is named after the example: the property was already taken
 * over once (`Skeleton` → `.Slot`), and under that mark this `replaces` would
 * never be read (`SwapDefault.takeover`). A property still on exactly the
 * stand-in moves; one a designer pointed anywhere else stays.
 */
export function exampleSwapDefault(
  page: PageNode,
  example: string,
  previous: SwapDefault,
): SwapDefault {
  return { id: exampleMainId(page, example), replaces: previous.id, takeover: example };
}
