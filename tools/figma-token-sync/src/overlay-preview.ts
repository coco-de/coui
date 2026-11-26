/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { autoFrame, bindSwapProp, bindVisibleProp, slotStandIn, type SlotStandInShape } from './helpers';
// One slot's two nodes.
//
// Two, because a node carries a single `componentPropertyReferences` map: the
// BOOLEAN ("did a caller pass one") and the INSTANCE_SWAP ("which component
// fills it") cannot both sit on the instance. The holder frame takes the
// first, the instance the second — the same split `avatarBadgeSlot`
// (display.ts) makes for the same reason.
export interface SlotNodes {
  holder: FrameNode;
  instance: InstanceNode;
}

// The instance is renamed `<slot> content`, whatever component fills it — the
// layer names the slot it marks, never the component standing in it (the same
// naming `slotNodes` in display.ts gives its slots).
export function slotNodes(name: string, instance: InstanceNode): SlotNodes {
  const holder = autoFrame(name, 'HORIZONTAL');
  instance.name = `${name} content`;
  holder.appendChild(instance);
  return { holder: holder, instance: instance };
}

// A slot whose default is the shared stand-in. The instance's name comes from
// `slotNodes` alone (`<slot> content`), so the stand-in call cannot hand it a
// second, diverging one.
export function standInSlotNodes(page: PageNode, name: string, shape: SlotStandInShape): SlotNodes {
  return slotNodes(name, slotStandIn(page, `${name} content`, shape));
}

// Points a required slot's INSTANCE_SWAP at the instance that draws it.
//
// Declaring without binding is the failure this whole pass exists to remove: a
// property with nothing pointing at it shows in the panel and changes nothing
// when a designer edits it. That is why the `defineProp` stays at the call
// site and its result is passed in — the declaration and the binding are one
// expression, and neither can be added without the other.
//
// ⚠️ Call only AFTER `nodes.holder` is already inside the component. Figma
// rejects `componentPropertyReferences` on a detached node ("Can only set
// component property references on symbol sublayer"), nothing rolls that
// throw back, and the entry is reported as failed with a half-drawn
// component left on the page until the next mint blanks it.
export function bindSlot(nodes: SlotNodes, swapId: string | null): void {
  bindSwapProp(nodes.instance, swapId);
}

// The same, for a `W?` slot, whose `null` the BOOLEAN models.
//
// The holder starts hidden because that IS the widget default — the slot is
// null unless a caller passes one — so the preview asserts no content the
// contract does not give it, and the property is how a designer turns it on.
export function bindOptionalSlot(
  nodes: SlotNodes,
  swapId: string | null,
  showId: string | null,
): void {
  bindSwapProp(nodes.instance, swapId);
  nodes.holder.visible = false;
  bindVisibleProp(nodes.holder, showId);
}
