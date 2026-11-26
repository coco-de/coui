/// <reference types="@figma/plugin-typings" />

import { APP_ICON_PLATFORMS, exportFilename, FLAVORS, SPLASH_PLATFORMS } from './spec';

export interface ExportedFile {
  name: string;
  bytes: Uint8Array;
}

const PAGE_NAME = 'App Icon Export';

async function exportSet(
  set: ComponentSetNode,
  platforms: typeof APP_ICON_PLATFORMS,
  files: ExportedFile[],
  log: string[],
): Promise<void> {
  for (const child of set.children) {
    const comp = child as ComponentNode;
    const m = comp.name.match(/Platform=(.+), Flavor=(.+)/);
    if (!m) continue;
    const platform = platforms.find((p) => p.key === m[1]);
    const flavor = FLAVORS.find((f) => f.key === (m[2] as (typeof FLAVORS)[number]['key']));
    if (!platform || !flavor) continue;

    const filename = exportFilename(platform, flavor);
    if (!filename) {
      log.push(`- ${comp.name}: no code asset mapping, skipped`);
      continue;
    }

    // Export always with the safe-zone guide hidden, regardless of the
    // property's current default — this is the whole point of the plugin
    // (never ship the red dashed guide baked into a real asset).
    const guide = comp.findOne((n) => n.name === 'safezone_guide');
    const guideWasVisible = guide ? guide.visible : null;
    if (guide) guide.visible = false;

    try {
      const bytes = await comp.exportAsync({
        format: 'PNG',
        constraint: { type: 'SCALE', value: 1 },
      });
      files.push({ name: filename, bytes });
      log.push(`✓ ${comp.name} → ${filename}`);
    } catch (err) {
      log.push(`✗ ${comp.name}: ${String(err)}`);
    } finally {
      if (guide && guideWasVisible !== null) guide.visible = guideWasVisible;
    }
  }
}

export async function exportIconSystem(): Promise<{ files: ExportedFile[]; log: string[] }> {
  const log: string[] = [];
  const files: ExportedFile[] = [];

  const page = figma.root.children.find((p) => p.name === PAGE_NAME) as PageNode | undefined;
  if (!page) {
    throw new Error(`"${PAGE_NAME}" page not found — run Generate first.`);
  }
  await figma.setCurrentPageAsync(page);

  const appIconSet = page.findOne((n) => n.type === 'COMPONENT_SET' && n.name === 'App Icon') as
    | ComponentSetNode
    | null;
  const splashSet = page.findOne((n) => n.type === 'COMPONENT_SET' && n.name === 'Splash Screen') as
    | ComponentSetNode
    | null;

  if (!appIconSet && !splashSet) {
    throw new Error('No "App Icon" or "Splash Screen" component set found — run Generate first.');
  }

  if (appIconSet) await exportSet(appIconSet, APP_ICON_PLATFORMS, files, log);
  if (splashSet) await exportSet(splashSet, SPLASH_PLATFORMS, files, log);

  log.push(`Done. ${files.length} PNG files ready for download.`);
  return { files, log };
}
