/// <reference types="@figma/plugin-typings" />

import {
  APP_ICON_PLATFORMS,
  CANVAS,
  FLAVORS,
  GUIDE_COLOR,
  PlatformSpec,
  SPLASH_PLATFORMS,
  TINT_GRAY,
  variantName,
} from './spec';
import { hexToRgb, loadFonts, requireSelectedLogoComponent } from './helpers';

const PAGE_NAME = 'App Icon Export';

export interface GenerateOptions {
  bgLight: string; // hex, e.g. "#0A56DB" — used for every opaque platform except iOS
}

function addLogoInstance(
  parent: ComponentNode,
  master: ComponentNode,
  scale: number,
  grayscale: boolean,
): void {
  if (scale <= 0) return;
  const inst = master.createInstance();
  inst.name = 'logo';
  const size = Math.round(CANVAS * scale);
  inst.resize(size, size);
  parent.appendChild(inst);
  inst.x = Math.round((CANVAS - size) / 2);
  inst.y = Math.round((CANVAS - size) / 2);

  if (grayscale) {
    // iOS 18+ tinted icon requirement: single-tone source so the OS tint
    // blends correctly. Overrides every fill inside the instance in place —
    // preserves negative-space holes in the underlying vector (verified
    // against a real shipped ic_logo_rectangle_tinted.png).
    const shapeNodes = inst.findAll(
      (n) => 'fills' in n && Array.isArray((n as GeometryMixin).fills) && (n as GeometryMixin).fills !== figma.mixed,
    ) as SceneNode[];
    for (const n of shapeNodes) {
      (n as GeometryMixin).fills = [{ type: 'SOLID', color: TINT_GRAY }];
    }
  }
}

function addGuide(parent: ComponentNode, spec: PlatformSpec, guidePropName: string): void {
  if (spec.guide.kind === 'none') return;
  const node = spec.guide.kind === 'ellipse' ? figma.createEllipse() : figma.createRectangle();
  node.name = 'safezone_guide';
  const size = spec.guide.size;
  node.resize(size, size);
  const off = Math.round((CANVAS - size) / 2);
  node.fills = [];
  node.strokes = [{ type: 'SOLID', color: GUIDE_COLOR }];
  node.strokeWeight = 5;
  node.dashPattern = [16, 10];
  if (spec.guide.kind === 'roundedRect') {
    (node as RectangleNode).cornerRadius = spec.guide.cornerRadius;
    (node as RectangleNode).cornerSmoothing = spec.guide.cornerSmoothing;
  }
  parent.appendChild(node);
  node.x = off;
  node.y = off;
  node.componentPropertyReferences = { visible: guidePropName };
}

function addBadge(parent: ComponentNode, label: string, color: RGB): void {
  const badge = figma.createFrame();
  badge.name = `badge_${label.toLowerCase()}`;
  badge.layoutMode = 'HORIZONTAL';
  badge.primaryAxisSizingMode = 'AUTO';
  badge.counterAxisSizingMode = 'AUTO';
  badge.paddingLeft = 28;
  badge.paddingRight = 28;
  badge.paddingTop = 12;
  badge.paddingBottom = 12;
  badge.cornerRadius = 999;
  badge.fills = [{ type: 'SOLID', color }];
  parent.appendChild(badge);

  const text = figma.createText();
  text.fontName = { family: 'Inter', style: 'Bold' };
  text.fontSize = 40;
  text.characters = label;
  text.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  badge.appendChild(text);
  badge.layoutSizingHorizontal = 'HUG';
  badge.layoutSizingVertical = 'HUG';
  badge.x = 48;
  badge.y = 48;
}

function buildComponentSet(
  setName: string,
  platforms: PlatformSpec[],
  master: ComponentNode,
  bgLightRgb: RGB,
  log: string[],
): ComponentSetNode {
  const built: ComponentNode[] = [];

  for (const platform of platforms) {
    for (const flavor of FLAVORS) {
      try {
        const comp = figma.createComponent();
        comp.name = variantName(platform.key, flavor.key);
        comp.resize(CANVAS, CANVAS);
        comp.clipsContent = true;

        if (platform.opaqueBg) {
          const bg = platform.fixedBg ? hexToRgb(platform.fixedBg.light) : bgLightRgb;
          comp.fills = [{ type: 'SOLID', color: bg }];
        } else {
          comp.fills = [];
        }

        addLogoInstance(comp, master, platform.logoScale, !!platform.grayscaleLogo);
        built.push(comp);

        if (flavor.badge) addBadge(comp, flavor.badge.label, flavor.badge.color);
      } catch (err) {
        log.push(`✗ ${setName} / ${platform.key}, ${flavor.key}: ${String(err)}`);
      }
    }
  }

  const set = figma.combineAsVariants(built, figma.currentPage);
  set.name = setName;

  const guidePropName = set.addComponentProperty('Show Safe Zone Guide', 'BOOLEAN', false);
  const logoPropName = set.addComponentProperty('Logo', 'INSTANCE_SWAP', master.id);

  for (const child of set.children) {
    const comp = child as ComponentNode;
    const logoInst = comp.findOne((n) => n.type === 'INSTANCE' && n.name === 'logo') as InstanceNode | null;
    if (logoInst) logoInst.componentPropertyReferences = { mainComponent: logoPropName };

    const platformKey = comp.name.replace(/^Platform=(.+), Flavor=.+$/, '$1');
    const platform = platforms.find((p) => p.key === platformKey);
    if (platform) addGuide(comp, platform, guidePropName);
  }

  // Grid layout: columns = flavor, rows = platform.
  const gap = 120;
  const cell = CANVAS + gap;
  const flavorOrder = FLAVORS.map((f) => f.key);
  for (const child of set.children) {
    const m = child.name.match(/Platform=(.+), Flavor=(.+)/);
    if (!m) continue;
    const row = platforms.findIndex((p) => p.key === m[1]);
    const col = flavorOrder.indexOf(m[2] as (typeof flavorOrder)[number]);
    child.x = col * cell;
    child.y = row * cell;
  }
  set.resize(
    flavorOrder.length * CANVAS + (flavorOrder.length - 1) * gap,
    platforms.length * CANVAS + (platforms.length - 1) * gap,
  );

  log.push(`✓ ${setName}: ${set.children.length} variants`);
  return set;
}

export async function generateIconSystem(opts: GenerateOptions): Promise<string[]> {
  const log: string[] = [];
  await loadFonts();

  const master = requireSelectedLogoComponent();
  const bgLightRgb = hexToRgb(opts.bgLight);

  let page = figma.root.children.find((p) => p.name === PAGE_NAME) as PageNode | undefined;
  if (!page) {
    page = figma.createPage();
    page.name = PAGE_NAME;
  }
  await figma.setCurrentPageAsync(page);

  // Idempotency: remove our own previously-generated sets by name.
  for (const node of page.children.slice()) {
    if (node.type === 'COMPONENT_SET' && (node.name === 'App Icon' || node.name === 'Splash Screen')) {
      node.remove();
    }
  }

  const appIconSet = buildComponentSet('App Icon', APP_ICON_PLATFORMS, master, bgLightRgb, log);
  appIconSet.x = 0;
  appIconSet.y = 0;

  const splashSet = buildComponentSet('Splash Screen', SPLASH_PLATFORMS, master, bgLightRgb, log);
  splashSet.x = 0;
  splashSet.y = appIconSet.height + 300;

  log.push(
    `Done. ${APP_ICON_PLATFORMS.length * FLAVORS.length + SPLASH_PLATFORMS.length * FLAVORS.length} ` +
      `variants on "${PAGE_NAME}" page. Logo = "${master.name}". ` +
      'Select a variant and use Export to download correctly-named PNGs.',
  );
  return log;
}
