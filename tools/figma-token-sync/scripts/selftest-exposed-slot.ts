/// <reference types="@figma/plugin-typings" />
import { exposeSlot } from '../src/component-props';

function instance(properties: ComponentProperties): InstanceNode {
  return { name: 'trigger', componentProperties: properties, isExposedInstance: false } as InstanceNode;
}
function rejected(run: () => void): void {
  let threw = false;
  try { run(); } catch { threw = true; }
  if (!threw) throw new Error('Missing or mistyped nested slots must fail');
}
const trigger = instance({ 'Suffix#123': { type: 'INSTANCE_SWAP', value: 'icon:1' } });
exposeSlot([trigger], 'Suffix', 'INSTANCE_SWAP');
if (!trigger.isExposedInstance) throw new Error('The native child property is not exposed');
const missing = instance({});
rejected(() => exposeSlot([missing], 'Suffix', 'INSTANCE_SWAP'));
if (missing.isExposedInstance) throw new Error('A missing slot was exposed');
rejected(() => exposeSlot([instance({ 'Suffix#123': { type: 'TEXT', value: 'wrong type' } })], 'Suffix', 'INSTANCE_SWAP'));
rejected(() => exposeSlot([], 'Suffix', 'INSTANCE_SWAP'));
console.log('Checked nested slot: present exposes, missing/type mismatch/empty fail');
