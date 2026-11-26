/// <reference types="@figma/plugin-typings" />
import { afterRedrawReconciled, redrawKeepsNodes } from './redraw-keep';
const pendingKey = 'coui-countdown-text-migration';

interface LegacyRow { block: FrameNode; digit: TextNode; caption: TextNode; }
interface SavedInstance { node: InstanceNode; parentId: string; values: (string | null)[]; }
export interface LegacyCountdown { main: ComponentNode; rows: LegacyRow[]; instances: SavedInstance[]; }

/** Read before mint/reset or property binding changes inherited values. */
export async function captureLegacyCountdown(main: ComponentNode | ComponentSetNode | null): Promise<LegacyCountdown | null> {
  if (!main || main.type !== 'COMPONENT') return null;
  if (main.getPluginData(pendingKey)) throw new Error('Countdown migration is incomplete; inspect saved consumer values before retry');
  if (Object.keys(main.componentPropertyDefinitions).length !== 0 || main.children.length === 0) return null;
  if (main.remote || main.parent?.type !== 'PAGE') throw new Error('Countdown migration requires a local standalone main');
  if (!redrawKeepsNodes()) throw new Error('Countdown migration requires keepInnerNodes');
  if (main.children.length !== 4) throw new Error('Unexpected legacy Countdown children; migration stopped');
  const rows = main.children.map(block => {
    if (block.type !== 'FRAME' || block.name !== 'block' || block.children.length !== 2) throw new Error('Unexpected legacy Countdown block; migration stopped');
    const [digit, caption] = block.children;
    if (digit.type !== 'TEXT' || caption.type !== 'TEXT' || !/^\d+$/.test(digit.characters) || !caption.characters ||
        Object.keys(digit.componentPropertyReferences ?? {}).length || Object.keys(caption.componentPropertyReferences ?? {}).length) {
      throw new Error('Unexpected legacy Countdown text; migration stopped');
    }
    return { block, digit, caption };
  });
  const sourceValues = rows.map(r => r.digit.characters);
  const sourceCaptions = rows.map(r => r.caption.characters);
  const instances: SavedInstance[] = [];
  const loaded = new Set<string>();
  for (const node of await main.getInstancesAsync()) {
    let page: BaseNode | null = node.parent;
    while (page && page.type !== 'PAGE') page = page.parent;
    if (!page || page.type !== 'PAGE') throw new Error('Countdown consumer has no live page');
    if (!loaded.has(page.id)) { await page.loadAsync(); loaded.add(page.id); }
    if (node.removed || !node.parent || (await node.getMainComponentAsync())?.id !== main.id || node.children.length !== 4) throw new Error('Legacy Countdown instance changed; migration stopped');
    const direct = new Map(node.overrides.map(o => [o.id, o.overriddenFields]));
    const values = rows.map((row, i) => {
      const block = node.children[i], digit = 'children' in block ? block.children[0] : null;
      if (block.type !== 'FRAME' || !block.id.endsWith(`;${row.block.id}`) || !digit || digit.type !== 'TEXT' || !digit.id.endsWith(`;${row.digit.id}`)) {
        throw new Error('Legacy Countdown instance text identity changed; migration stopped');
      }
      // Keep explicit same-as-default overrides explicit. Differing inherited
      // overrides matter too: the API lists only direct ones in `overrides`.
      return digit.characters !== sourceValues[i] || direct.get(digit.id)?.includes('characters') ? digit.characters : null;
    });
    instances.push({ node, parentId: node.parent.id, values });
  }
  if (Object.keys(main.componentPropertyDefinitions).length || main.children.length !== rows.length || main.children.some((b, i) =>
      b !== rows[i].block || rows[i].block.children[0] !== rows[i].digit || rows[i].block.children[1] !== rows[i].caption || rows[i].block.children.length !== 2 ||
      rows[i].digit.characters !== sourceValues[i] || rows[i].caption.characters !== sourceCaptions[i])) {
    throw new Error('Countdown changed while capturing consumers; migration stopped');
  }
  return { main, rows, instances };
}

/** Durable failure fence: a stopped migration must not be retried as a normal
 * four-property redraw and silently discard its saved legacy overrides. */
export function beginLegacyCountdown(legacy: LegacyCountdown): void {
  legacy.main.setPluginData(pendingKey, JSON.stringify({
    mainId: legacy.main.id,
    visibleTextIds: legacy.rows.flatMap(r => [r.digit.id, r.caption.id]),
    instances: legacy.instances.map(s => ({ id: s.node.id, parentId: s.parentId, values: s.values })),
  }));
}

/** One-time Generate migration, after retained leaves and references settle. */
export function restoreLegacyCountdown(legacy: LegacyCountdown, propertyKeys: readonly (string | null)[]): void {
  if (propertyKeys.length !== 4 || propertyKeys.some(k => k === null)) throw new Error('Countdown property migration keys missing');
  const keys = propertyKeys as readonly string[];
  afterRedrawReconciled(legacy.main, async () => {
    for (const saved of legacy.instances) {
      const instance = saved.node;
      if (instance.removed || instance.parent?.id !== saved.parentId || (await instance.getMainComponentAsync())?.id !== legacy.main.id) {
        throw new Error('Countdown consumer changed during migration; no recreation attempted');
      }
      const patch: Record<string, string> = {};
      saved.values.forEach((v, i) => { if (v !== null) patch[keys[i]] = v; });
      if (Object.keys(patch).length) instance.setProperties(patch);
      const props = instance.componentProperties, texts = instance.findAll(n => n.type === 'TEXT') as TextNode[];
      for (let i = 0; i < 4; i++) {
        const expected = saved.values[i] ?? legacy.main.componentPropertyDefinitions[keys[i]].defaultValue;
        const linked = texts.filter(t => t.componentPropertyReferences?.characters === keys[i]);
        if (props[keys[i]]?.value !== expected || linked.length !== 4 || linked.some(t => t.characters !== expected)) {
          throw new Error(`Countdown consumer ${instance.id} migration readback failed for ${keys[i]}`);
        }
      }
    }
    legacy.main.setPluginData(pendingKey, '');
  });
}
