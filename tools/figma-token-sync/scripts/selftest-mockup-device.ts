// MockupDevice — the builder's transcription of `CoreMockupDeviceLayout` pinned
// against the canvas measurements.
//
// `src/mockup-device-geometry.ts` is a second copy of Core's layout rules (a TS
// plugin cannot call Dart), so the only thing keeping the two from drifting is a
// check that the copy reproduces the same numbers. Every expected value below is
// a canvas measurement — the `MockupDevice (리디자인)` set's four members —
// transcribed from the design measurements, none read back from the geometry or
// from a style default; the Dart side pins the same table
// (`mockup_device_figma_conformance_test.dart`), so a number that moves in one
// place and not the other fails in one of the two.
//
// The hardware colours are pinned the same way, against the designer copy's
// values, not against what the data or the builder says: each layer is a literal
// (no variable bound, so neither the mode nor a brand palette moves it) at the
// value the copy paints, and the optical layers stay literal too. The Figma API
// surface that matters to the paint helpers — a stop's variable alias, and the
// reset a write gives a freshly bound paint — runs through
// `fake-bound-paint.ts`, the same model the registry drive draws through.
//
// Runs under plain Node against the REAL components.json, the way the other pure
// selftests do. Lengths are logical px compared at 1e-3, the precision the
// canvas prints them to.
import {
  buttonDepthGradient,
  buttonLengthGradient,
  DeviceGeometry,
  DeviceRect,
  mockupDeviceGeometry,
  mockupDeviceSettings,
  safeAreaInsets,
  safeAreaSources,
} from '../src/mockup-device-geometry';
import { COMPONENTS } from '../src/data';
import {
  assignPaints,
  colorPaint,
  fillDataOnPaint,
  gradientPaint,
  kGradientAnchor,
  linearGradientTransform,
  GradientData,
  kPaintStrengthKey,
  paintOpacityNotHeld,
} from '../src/paint';
import { colorData, Dim } from '../src/compat/v1';
import { VarLookup } from '../src/variables';
import { bindPaint, fakeAlias, storePaints, trapStats } from './fake-bound-paint';

declare const process: { exit(code: number): never };

// ─── The slice of `figma` these tests reach ──────────────────────────────────
//
// `gradientPaint` makes a variable alias for each token stop and `solid` binds a
// paint; nothing else here touches the plugin API.
(globalThis as unknown as { figma: unknown }).figma = {
  variables: { createVariableAlias: fakeAlias, setBoundVariableForPaint: bindPaint },
};

// A real `VarLookup` over a catalog of the five fixed slots (and one ordinary
// semantic), so `lk.sem(name)` is the lookup the builder runs — including its
// refusal of a name the document does not hold. The device binds none of them;
// the paint helpers' own checks below do.
const kCatalog = [
  'primary-fixed-dim',
  'on-primary-fixed-variant',
  'on-primary-fixed',
  'secondary-fixed',
  'scrim',
  'surface',
];
const kVariableId = (name: string): string => `VariableID:sem/${name}`;
const lk = new VarLookup(
  kCatalog.map(
    (name) => ({ id: kVariableId(name), name: `color/${name}`, variableCollectionId: 'c-sem' }) as unknown as Variable,
  ),
  new Map([['c-sem', 'Semantic/ Color · CoUI']]),
);

const kTol = 1e-3;
let failures = 0;
function fail(label: string, detail: string): void {
  failures++;
  console.error(`  ✗ ${label} — ${detail}`);
}
function near(label: string, actual: number, expected: number, tol = kTol): void {
  if (Number.isNaN(actual) || Math.abs(actual - expected) > tol) {
    fail(label, `expected ${expected}, got ${actual}`);
  }
}
function rect(label: string, actual: DeviceRect | null, expected: [number, number, number, number]): void {
  if (actual == null) {
    fail(label, 'is null');
    return;
  }
  const got = [actual.x, actual.y, actual.w, actual.h];
  for (let i = 0; i < 4; i++) {
    if (Math.abs(got[i] - expected[i]) > kTol) {
      fail(label, `expected [${expected.join(', ')}], got [${got.map((v) => v.toFixed(4)).join(', ')}]`);
      return;
    }
  }
}

// The four canvas members: the body width the canvas draws each at.
const kMembers: { device: string; orientation: string; width: number }[] = [
  { device: 'phone', orientation: 'portrait', width: 160 },
  { device: 'phone', orientation: 'landscape', width: 328 },
  { device: 'tablet', orientation: 'portrait', width: 321 },
  { device: 'tablet', orientation: 'landscape', width: 455 },
];

const rows = COMPONENTS.mockup_device.variants.defaultsByDevice;
function geometryOf(m: { device: string; orientation: string; width: number }): DeviceGeometry {
  const d = Object.entries(rows).find(([name]) => name === m.device)?.[1];
  if (d == null) throw new Error(`no defaultsByDevice row for ${m.device}`);
  return mockupDeviceGeometry(mockupDeviceSettings({ ...m, d }));
}

const g = {
  pp: geometryOf(kMembers[0]),
  pl: geometryOf(kMembers[1]),
  tp: geometryOf(kMembers[2]),
  tl: geometryOf(kMembers[3]),
};

console.log('frame');
near('phone portrait height', g.pp.height, 328);
near('phone landscape height', g.pl.height, 160);
near('tablet portrait height', g.tp.height, 455);
near('tablet landscape height', g.tl.height, 321);
rect('phone portrait bezel box', g.pp.bezelBox, [3, 3, 154, 322]);
rect('phone landscape bezel box', g.pl.bezelBox, [3, 3, 322, 154]);
rect('tablet portrait bezel box', g.tp.bezelBox, [3, 3, 315, 449]);
rect('tablet landscape bezel box', g.tl.bezelBox, [3, 3, 449, 315]);
rect('phone portrait screen box', g.pp.screenBox, [8, 8, 144, 312]);
rect('phone landscape screen box', g.pl.screenBox, [8, 8, 312, 144]);
rect('tablet portrait screen box', g.tp.screenBox, [11, 11, 299, 433]);
rect('tablet landscape screen box', g.tl.screenBox, [11, 11, 433, 299]);
near('phone bezel radius', g.pp.bezelRadius, 21);
near('phone screen radius', g.pp.screenRadius, 16);
near('tablet bezel radius', g.tp.bezelRadius, 13);
near('tablet screen radius', g.tp.screenRadius, 5);

console.log('rim');
rect('phone portrait rim highlight', g.pp.rimHighlight, [0, 0.4, 160, 327.2]);
rect('phone landscape rim highlight', g.pl.rimHighlight, [0, 0.4, 328, 159.2]);
rect('tablet portrait rim highlight', g.tp.rimHighlight, [0, 0.4, 321, 454.2]);
rect('tablet landscape rim highlight', g.tl.rimHighlight, [0, 0.4, 455, 320.2]);
rect('phone portrait rim glow', g.pp.rimGlow, [0, 0.8, 160, 326.8]);
rect('phone landscape rim glow', g.pl.rimGlow, [0, 0.8, 328, 158.8]);
rect('tablet portrait rim glow', g.tp.rimGlow, [0, 0.8, 321, 453.8]);
rect('tablet landscape rim glow', g.tl.rimGlow, [0, 0.8, 455, 319.8]);

console.log('camera set');
if (g.pp.cameraPlacement !== 'screen' || g.pp.cameraEdge !== 'top') fail('phone portrait camera', 'screen / top expected');
if (g.pl.cameraPlacement !== 'screen' || g.pl.cameraEdge !== 'left') fail('phone landscape camera', 'screen / left expected');
if (g.tp.cameraPlacement !== 'bezel' || g.tp.cameraEdge !== 'top') fail('tablet portrait camera', 'bezel / top expected');
if (g.tl.cameraPlacement !== 'bezel' || g.tl.cameraEdge !== 'top') fail('tablet landscape camera', 'bezel / top expected');
rect('phone portrait camera', g.pp.camera, [49.5, 4, 45, 13]);
rect('phone portrait lens', g.pp.lens, [84.75, 7.25, 6.5, 6.5]);
rect('phone portrait core', g.pp.core, [86.05, 8.55, 3.9, 3.9]);
rect('phone portrait lens highlight', g.pp.lensHighlight, [86.57, 8.81, 1.04, 1.04]);
rect('phone landscape camera', g.pl.camera, [4, 49.5, 13, 45]);
rect('phone landscape lens', g.pl.lens, [7.25, 52.75, 6.5, 6.5]);
rect('phone landscape core', g.pl.core, [8.55, 54.05, 3.9, 3.9]);
rect('phone landscape lens highlight', g.pl.lensHighlight, [9.07, 54.31, 1.04, 1.04]);
rect('tablet portrait camera', g.tp.camera, [155.5, 2, 4, 4]);
if (g.tp.lens != null) fail('tablet portrait lens', 'a tablet draws no lens ring');
rect('tablet portrait core', g.tp.core, [156.3, 2.8, 2.4, 2.4]);
rect('tablet portrait lens highlight', g.tp.lensHighlight, [156.62, 2.96, 0.64, 0.64]);
rect('tablet landscape camera', g.tl.camera, [222.5, 2, 4, 4]);
rect('tablet landscape core', g.tl.core, [223.3, 2.8, 2.4, 2.4]);
rect('tablet landscape lens highlight', g.tl.lensHighlight, [223.62, 2.96, 0.64, 0.64]);
if (g.pp.cameraIsLens || !g.tp.cameraIsLens) fail('cameraIsLens', 'a phone cut-out holds a ring, a tablet camera is the lens');

console.log('buttons');
rect('phone portrait power', g.pp.power, [159.5, 98.4, 2, 40]);
rect('phone portrait volume up', g.pp.volumeUp, [-1.5, 65.6, 2, 26]);
rect('phone portrait volume down', g.pp.volumeDown, [-1.5, 99.6, 2, 26]);
rect('phone landscape power', g.pl.power, [189.6, 159.5, 40, 2]);
rect('phone landscape volume up', g.pl.volumeUp, [65.6, -1.5, 26, 2]);
rect('phone landscape volume down', g.pl.volumeDown, [99.6, -1.5, 26, 2]);
rect('tablet portrait power', g.tp.power, [238.096, -1.5, 45.433, 2]);
rect('tablet portrait volume up', g.tp.volumeUp, [-1.5, 83.642, 2, 33.317]);
if (g.tp.volumeDown != null) fail('tablet portrait volume down', 'a tablet has one volume rocker');
rect('tablet landscape power', g.tl.power, [454.5, 49.748, 2, 49.522]);
rect('tablet landscape volume up', g.tl.volumeUp, [282.343, -1.5, 36.316, 2]);
const edges = (x: DeviceGeometry): string => `${x.powerEdge}/${x.volumeEdge}`;
if (edges(g.pp) !== 'right/left') fail('phone portrait button edges', edges(g.pp));
if (edges(g.pl) !== 'bottom/top') fail('phone landscape button edges', edges(g.pl));
if (edges(g.tp) !== 'top/left') fail('tablet portrait button edges', edges(g.tp));
if (edges(g.tl) !== 'right/top') fail('tablet landscape button edges', edges(g.tl));

console.log('antenna bands');
const portraitBands: [string, [number, number, number, number]][] = [
  ['top', [122.441, 0, 1.9, 3]],
  ['left', [0, 35.782, 3, 1.9]],
  ['right', [157, 35.782, 3, 1.9]],
  ['left', [0, 290.355, 3, 1.9]],
  ['right', [157, 290.355, 3, 1.9]],
  ['bottom', [31.549, 325, 1.9, 3]],
];
const landscapeBands: [string, [number, number, number, number]][] = [
  ['right', [325, 122.441, 3, 1.9]],
  ['top', [35.782, 0, 1.9, 3]],
  ['bottom', [35.782, 157, 1.9, 3]],
  ['top', [290.355, 0, 1.9, 3]],
  ['bottom', [290.355, 157, 1.9, 3]],
  ['left', [0, 31.549, 3, 1.9]],
];
for (const [label, geometry, expected] of [
  ['phone portrait', g.pp, portraitBands],
  ['phone landscape', g.pl, landscapeBands],
] as const) {
  if (geometry.antennaBands.length !== expected.length) {
    fail(`${label} antenna bands`, `expected ${expected.length}, got ${geometry.antennaBands.length}`);
    continue;
  }
  expected.forEach(([edge, r], i) => {
    const band = geometry.antennaBands[i];
    if (band.edge !== edge) fail(`${label} band ${i} edge`, `expected ${edge}, got ${band.edge}`);
    rect(`${label} band ${i}`, band.rect, r);
  });
}
if (g.tp.antennaBands.length + g.tl.antennaBands.length !== 0) fail('tablet antenna bands', 'a tablet draws none');

console.log('status bar');
const barOf = (x: DeviceGeometry) => x.statusBar;
if (barOf(g.pl) != null) fail('phone landscape status bar', 'a phone on its side draws none');
const ppBar = barOf(g.pp);
const tpBar = barOf(g.tp);
const tlBar = barOf(g.tl);
if (ppBar == null || tpBar == null || tlBar == null) {
  fail('status bar', 'phone portrait and both tablet poses draw one');
} else {
  near('system bar scale (phone portrait)', g.pp.systemBarScale, 144 / 402);
  near('system bar scale (phone landscape)', g.pl.systemBarScale, 312 / 874);
  near('system bar scale (tablet portrait)', g.tp.systemBarScale, 144 / 402);
  near('system bar scale (tablet landscape)', g.tl.systemBarScale, 144 / 402);
  rect('phone portrait bar', ppBar.rect, [0, 0, 144, 21.134]);
  rect('tablet portrait bar', tpBar.rect, [0, 0, 299, 11.463]);
  rect('tablet landscape bar', tlBar.rect, [0, 0, 433, 11.463]);
  near('phone content line', ppBar.contentCenter, 11.642);
  near('tablet content line', tpBar.contentCenter, 5.731);
  rect('phone leading box', ppBar.leading.box, [8.597, 2.149, 36.179, 18.985]);
  rect('phone trailing box', ppBar.trailing.box, [99.224, 2.149, 35.463, 18.985]);
  if (ppBar.leading.alignment !== 'center' || ppBar.trailing.alignment !== 'center') {
    fail('phone group alignment', 'a wing centres its group');
  }
  rect('tablet portrait leading box', tpBar.leading.box, [5.731, 0, 287.537, 11.463]);
  rect('tablet portrait trailing box', tpBar.trailing.box, [5.731, 0, 287.537, 11.463]);
  rect('tablet landscape leading box', tlBar.leading.box, [5.731, 0, 421.537, 11.463]);
  if (tpBar.leading.alignment !== 'start' || tpBar.trailing.alignment !== 'end') {
    fail('tablet group alignment', 'the two groups hug the two edges');
  }
  const phoneTrailing = ppBar.trailing.items;
  if (phoneTrailing.length !== 3 || phoneTrailing[0].kind !== 'glyph' || phoneTrailing[2].kind !== 'battery') {
    fail('phone trailing items', 'cellular, wifi, battery');
  } else {
    const [cellular, wifi, battery] = phoneTrailing;
    if (cellular.kind === 'glyph') {
      near('cellular width', cellular.w, 6.878);
      near('cellular height', cellular.h, 4.38);
    }
    if (wifi.kind === 'glyph') {
      near('wifi width', wifi.w, 6.14);
      near('wifi height', wifi.h, 4.416);
    }
    if (battery.kind === 'battery') {
      near('battery width', battery.w, 9.789);
      near('battery height', battery.h, 4.657);
      near('battery outline stroke', battery.borderWidth, 0.358);
      near('battery outline radius', battery.borderRadius, 1.433);
      near('battery level radius', battery.capacityRadius, 0.716);
      // The canvas draws these three parts 0.015 px left of the ideal.
      near('battery level width', battery.capacity.w, 7.522);
      rect('battery level', battery.capacity, [0.716, 0.716, 7.522, 3.224]);
      near('battery nub left', battery.cap.x, 9.314, 0.02);
    }
    near('phone trailing gap', cellular.gapAfter, 2.149);
  }
  const tabletLeading = tpBar.leading.items;
  if (tabletLeading.length !== 3) {
    fail('tablet leading items', 'clock, meridiem, date');
  } else {
    near('clock → meridiem gap', tabletLeading[0].gapAfter, 0.716);
    near('meridiem → date gap', tabletLeading[1].gapAfter, 2.866);
  }
  const tabletTrailing = tpBar.trailing.items;
  if (tabletTrailing.length !== 3 || tabletTrailing[0].kind !== 'glyph' || tabletTrailing[2].kind !== 'glyph') {
    fail('tablet trailing items', 'wifi, percent, battery');
  } else {
    near('tablet wifi width', tabletTrailing[0].w, 4.836);
    near('tablet wifi height', tabletTrailing[0].h, 3.582);
    near('tablet battery width', tabletTrailing[2].w, 9.791);
    near('tablet battery height', tabletTrailing[2].h, 4.657);
    near('tablet trailing gap', tabletTrailing[0].gapAfter, 1.433);
    near('percent → battery gap', tabletTrailing[1].gapAfter, 1.433);
  }
}

console.log('home indicator');
rect('phone portrait area', g.pp.gestureBarArea, [0, 299.821, 144, 12.179]);
rect('phone portrait bar', g.pp.gestureBar, [46.209, 307.343, 51.582, 1.791]);
near('phone portrait bar radius', g.pp.gestureBarRadius, 0.716);
rect('phone landscape area', g.pl.gestureBarArea, [0, 136.503, 312, 7.497]);
rect('phone landscape bar', g.pl.gestureBar, [118.696, 139.359, 74.609, 1.785]);
near('phone landscape bar radius', g.pl.gestureBarRadius, 0.714);
rect('tablet portrait area', g.tp.gestureBarArea, [0, 425.836, 299, 7.164]);
rect('tablet portrait bar', g.tp.gestureBar, [93.261, 428.343, 112.478, 1.791]);
rect('tablet landscape area', g.tl.gestureBarArea, [0, 291.836, 433, 7.164]);
rect('tablet landscape bar', g.tl.gestureBar, [160.261, 294.343, 112.478, 1.791]);

console.log('safe area');
const all = { camera: true, statusBar: true, gestureBar: true };
const none = { camera: false, statusBar: false, gestureBar: false };
function insets(
  label: string,
  geometry: DeviceGeometry,
  shown: { camera: boolean; statusBar: boolean; gestureBar: boolean },
  expected: [number, number, number, number],
): void {
  const got = safeAreaInsets(geometry, shown);
  const want = { top: expected[0], bottom: expected[1], left: expected[2], right: expected[3] };
  for (const side of ['top', 'bottom', 'left', 'right'] as const) {
    if (Math.abs(got[side] - want[side]) > kTol) {
      fail(label, `${side}: expected ${want[side]}, got ${got[side]}`);
    }
  }
}
// [top, bottom, left, right]
insets('phone portrait, all shown', g.pp, all, [21.134, 12.179, 0, 0]);
insets('phone portrait, camera only', g.pp, { ...none, camera: true }, [21, 0, 0, 0]);
insets('phone portrait, status bar only', g.pp, { ...none, statusBar: true }, [21.134, 0, 0, 0]);
insets('phone portrait, gesture bar only', g.pp, { ...none, gestureBar: true }, [0, 12.179, 0, 0]);
insets('phone portrait, none shown', g.pp, none, [0, 0, 0, 0]);
insets('phone landscape, all shown', g.pl, all, [0, 7.497, 21, 0]);
insets('phone landscape, camera hidden', g.pl, { ...all, camera: false }, [0, 7.497, 0, 0]);
insets('tablet portrait, all shown', g.tp, all, [11.463, 7.164, 0, 0]);
insets('tablet portrait, camera only', g.tp, { ...none, camera: true }, [0, 0, 0, 0]);
insets('tablet landscape, all shown', g.tl, all, [11.463, 7.164, 0, 0]);

console.log('safe area sources (what the Figma spacers are bound to)');
const flagsOn = (geometry: DeviceGeometry, side: string): string =>
  safeAreaSources(geometry)
    .filter((s) => s.side === side)
    .map((s) => s.flag)
    .sort()
    .join('+');
if (flagsOn(g.pp, 'top') !== 'camera+statusBar') fail('phone portrait top sources', flagsOn(g.pp, 'top'));
if (flagsOn(g.pl, 'top') !== '') fail('phone landscape top sources', flagsOn(g.pl, 'top'));
if (flagsOn(g.pl, 'left') !== 'camera') fail('phone landscape left sources', flagsOn(g.pl, 'left'));
if (flagsOn(g.tp, 'top') !== 'statusBar') fail('tablet top sources', flagsOn(g.tp, 'top'));
if (flagsOn(g.tp, 'bottom') !== 'gestureBar') fail('tablet bottom sources', flagsOn(g.tp, 'bottom'));

console.log('resizing preserves system chrome dimensions and vertical alignment');
for (const factor of [0.5, 2, 3.7]) {
  for (const m of kMembers) {
    const wide = geometryOf({ ...m, width: m.width * factor });
    const base = geometryOf(m);
    near(`${m.device} ${m.orientation} ×${factor} bar height`,
      wide.statusBar?.rect.h ?? 0, base.statusBar?.rect.h ?? 0);
    near(`${m.device} ${m.orientation} ×${factor} content line`,
      wide.statusBar?.contentCenter ?? 0, base.statusBar?.contentCenter ?? 0);
    near(`${m.device} ${m.orientation} ×${factor} gesture width`, wide.gestureBar.w, base.gestureBar.w);
    near(`${m.device} ${m.orientation} ×${factor} gesture height`, wide.gestureBar.h, base.gestureBar.h);
  }
}
for (const width of [160, 240, 320]) {
  const device = geometryOf({ device: 'phone', orientation: 'portrait', width });
  near(`phone width ${width} camera top`, device.camera.y, 4);
  near(`phone width ${width} status content line`, device.statusBar!.contentCenter, 11.64179104);
  const wing = device.statusBar!.leading.box;
  near(`phone width ${width} leading centre`, wing.x + wing.w / 2,
    26.68656716);
}

console.log('gradient transforms (Figma maps a node point into gradient space; t = first row)');
const same = (a: number[][], b: number[][]): boolean =>
  a.every((row, i) => row.every((v, j) => Math.abs(v - b[i][j]) < 1e-9));
function transform(label: string, actual: readonly (readonly number[])[], expected: number[][]): void {
  if (!same(actual as number[][], expected)) fail(label, `expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
}
// The canvas states the body gradient as top to bottom: `[[0,1,0],[-1,0,1]]`.
transform('top → bottom', linearGradientTransform(kGradientAnchor.topCenter, kGradientAnchor.bottomCenter), [[0, 1, 0], [-1, 0, 1]]);
// Left to right is the identity (the ColorPicker spectrum draws it that way).
transform('left → right', linearGradientTransform(kGradientAnchor.centerStart, kGradientAnchor.centerEnd), [[1, 0, 0], [0, 1, 0]]);
// Reversed runs read t = 1 − y and t = 1 − x.
transform('bottom → top', linearGradientTransform(kGradientAnchor.bottomCenter, kGradientAnchor.topCenter), [[0, -1, 1], [1, 0, 0]]);
transform('right → left', linearGradientTransform(kGradientAnchor.centerEnd, kGradientAnchor.centerStart), [[-1, 0, 1], [0, -1, 1]]);
const f = COMPONENTS.mockup_device.fields;
transform('rail gradient (exported begin / end)', gradientPaint(f.railGradient, { lk }).gradientTransform, [[0, 1, 0], [-1, 0, 1]]);
const core = gradientPaint(f.coreGradient, { lk });
if (core.type !== 'GRADIENT_RADIAL') fail('core gradient', `type ${core.type}`);
transform('core gradient (radial, centred)', core.gradientTransform, [[1, 0, 0], [0, 1, 0]]);
// The two button gradients are pointed per edge.
for (const edge of ['left', 'right', 'top', 'bottom'] as const) {
  const gloss = gradientPaint(buttonLengthGradient(f.buttonLengthGradient, edge)).gradientTransform;
  transform(`gloss on a ${edge} button`, gloss, edge === 'left' || edge === 'right' ? [[0, 1, 0], [-1, 0, 1]] : [[1, 0, 0], [0, 1, 0]]);
}
// The shade is darkest at the side nearest the body: stop 0 is the dark end, and
// it sits where the body is — right of a left-edge button, left of a right-edge
// one, below a top-edge one, above a bottom-edge one.
const nearBody: Record<string, [number, number]> = {
  left: [1, 0.5], // x grows toward the body
  right: [0, 0.5],
  top: [0.5, 1],
  bottom: [0.5, 0],
};
for (const edge of ['left', 'right', 'top', 'bottom'] as const) {
  const depth = gradientPaint(buttonDepthGradient(f.buttonDepthColor, edge)).gradientTransform;
  const [px, py] = nearBody[edge];
  const t = depth[0][0] * px + depth[0][1] * py + depth[0][2];
  if (Math.abs(t) > 1e-9) fail(`shade on a ${edge} button`, `the body-side point reads t = ${t}, not 0 (the dark stop)`);
}
const stops = gradientPaint(f.buttonLengthGradient).gradientStops;
if (stops.length !== 8 || Math.abs(stops[1].color.a - 0xad / 255) > 1e-9 || Math.abs(stops[2].color.a - 0x80 / 255) > 1e-9) {
  fail('button gloss stops', 'eight stops with the canvas alphas (#ffffffad, #00000080) expected');
}
const glowPaint = gradientPaint(f.rimGlowGradient, { opacity: f.rimGlowOpacity });
if (glowPaint.opacity !== 0.5 || glowPaint.gradientStops[1].color.a !== 0) {
  fail('rim glow paint', 'paint opacity 0.5 over a ramp that ends transparent white');
}

console.log('hardware colours (the designer copy\'s literals — no variable bound)');
// The value the copy paints for each hardware colour.
const leafTable: [string, { ref: string | null; argb: number; opacity: number }, number][] = [
  ['railColor', f.railColor, 0xff7d7f82],
  ['borderColor', f.borderColor, 0xff646568],
  ['rimHighlightColor', f.rimHighlightColor, 0xffffffff],
  ['bezelColor', f.bezelColor, 0xff000000],
  ['bezelBorderColor', f.bezelBorderColor, 0xff27282b],
  ['buttonColor', f.buttonColor, 0xffaeafb2],
  ['lensColor', f.lensColor, 0xff000000],
  ['cutoutColor', f.cutoutColor, 0xff000000],
  ['lensHighlightColor', f.lensHighlightColor, 0xffffffff],
];
for (const [field, leaf, argb] of leafTable) {
  if (leaf.ref !== null) fail(`${field}`, `a hardware colour is a literal, but names ${String(leaf.ref)}`);
  if (leaf.argb >>> 0 !== argb) fail(`${field} value`, `expected ${argb.toString(16)}, got ${(leaf.argb >>> 0).toString(16)}`);
  near(`${field} strength`, leaf.opacity, 1);
}
near('antenna strength (the paint\'s)', f.antennaOpacity.v, 0.7);
// The optical layers carry no slot either: translucent white and black laid over
// each other, the same in every mode.
const literalLeaves: [string, { ref: string | null }][] = [
  ['bezelInnerShadowColor', f.bezelInnerShadowColor],
  ['buttonDepthColor', f.buttonDepthColor],
  ...f.buttonLengthGradient.colors.map((c, i): [string, { ref: string | null }] => [`buttonLengthGradient[${i}]`, c]),
  ...f.rimGlowGradient.colors.map((c, i): [string, { ref: string | null }] => [`rimGlowGradient[${i}]`, c]),
];
for (const [field, leaf] of literalLeaves) {
  if (leaf.ref !== null) fail(`${field}`, `an optical layer stays literal, but names ${String(leaf.ref)}`);
}

const stopArgb = (stop: ColorStop): number =>
  ((Math.round(stop.color.a * 255) << 24) |
    (Math.round(stop.color.r * 255) << 16) |
    (Math.round(stop.color.g * 255) << 8) |
    Math.round(stop.color.b * 255)) >>> 0;

// A ramp: each stop is the copy's literal — no alias — and sits where the copy
// puts it.
function ramp(
  label: string,
  g: GradientData,
  type: 'GRADIENT_LINEAR' | 'GRADIENT_RADIAL',
  values: number[],
  positions: number[],
  opacity?: number | Dim,
): GradientPaint {
  const paint = gradientPaint(g, { lk, opacity });
  if (paint.type !== type) fail(`${label} type`, `${paint.type}`);
  if (paint.gradientStops.length !== values.length) {
    fail(`${label} stops`, `expected ${values.length}, got ${paint.gradientStops.length}`);
    return paint;
  }
  paint.gradientStops.forEach((stop, i) => {
    if (stop.boundVariables != null) fail(`${label} stop ${i}`, `a literal stop binds nothing, got ${JSON.stringify(stop.boundVariables)}`);
    near(`${label} stop ${i} position`, stop.position, positions[i]);
    const argb = stopArgb(stop);
    if (argb !== values[i]) fail(`${label} stop ${i} colour`, `expected ${values[i].toString(16)}, got ${argb.toString(16)}`);
  });
  return paint;
}
ramp('body ramp', f.railGradient, 'GRADIENT_LINEAR', [0xffc3c4c6, 0xff7d7f82, 0xff7d7f82, 0xffaeafb2], [0, 0.1, 0.9, 1]);
ramp(
  'lens core',
  f.coreGradient,
  'GRADIENT_RADIAL',
  [0xff000000, 0xff0a3348, 0xff0c3b52, 0xff105171, 0xff0c3b52, 0xff000000],
  [0.2, 0.35, 0.5, 0.62, 0.8, 1],
);
// The antenna ramp's 70% is the paint's.
near('antenna paint opacity', ramp('antenna', f.antennaGradient, 'GRADIENT_LINEAR', [0xfffcfcfd, 0xffe4e5e7], [0, 1], f.antennaOpacity).opacity ?? 1, 0.7);

// Optical ramps carry no binding on any stop.
for (const [label, paint] of [
  ['button gloss', gradientPaint(buttonLengthGradient(f.buttonLengthGradient, 'left'))],
  ['button shade', gradientPaint(buttonDepthGradient(f.buttonDepthColor, 'left'))],
  ['rim glow', gradientPaint(f.rimGlowGradient, { opacity: f.rimGlowOpacity })],
] as const) {
  if (paint.gradientStops.some((stop) => stop.boundVariables != null)) fail(`${label}`, 'an optical ramp\'s stops stay literal');
}

// ── a ramp whose stops are tokens ──
// No MockupDevice default states one, so the paint helper's handling of a token
// stop runs on a ramp made for it: the antenna's shape with both stops on the
// slot `secondary-fixed`. What it pins is the helper, not a colour of the product.
const slotRef = (name: string): string => `Semantic/color/${name}`;
const tokenRamp: GradientData = {
  ...f.antennaGradient,
  colors: f.antennaGradient.colors.map((c) => ({ ...c, ref: slotRef('secondary-fixed'), argb: 0xffe4e5e7 })),
};
const bound = gradientPaint(tokenRamp, { lk });
bound.gradientStops.forEach((stop, i) => {
  const alias = stop.boundVariables?.color;
  if (alias == null || alias.type !== 'VARIABLE_ALIAS' || alias.id !== kVariableId('secondary-fixed')) {
    fail(`token ramp stop ${i}`, `expected the alias of secondary-fixed, got ${JSON.stringify(alias)}`);
  }
  if (stopArgb(stop) !== 0xffe4e5e7) fail(`token ramp stop ${i} colour`, `expected the value beneath its binding, got ${stopArgb(stop).toString(16)}`);
});

// A token stop cannot be painted without a lookup to bind it, a slot the document
// does not hold stops the build, and a token stop below full strength has nothing
// to bind — each refuses rather than painting a hex where the design put a token.
function refuses(label: string, run: () => unknown, mentions: string): void {
  try {
    run();
  } catch (e) {
    if (!String((e as Error).message).includes(mentions)) fail(label, `threw "${(e as Error).message}", expected it to mention "${mentions}"`);
    return;
  }
  fail(label, 'did not throw');
}
refuses('token ramp without a lookup', () => gradientPaint(tokenRamp), 'no VarLookup');
refuses(
  'slot missing from the document',
  () => gradientPaint({ ...tokenRamp, colors: [{ ...tokenRamp.colors[0], ref: slotRef('no-such-slot') }, tokenRamp.colors[1]] }, { lk }),
  'variable not found',
);
refuses(
  'token stop below full strength',
  () => gradientPaint({ ...tokenRamp, colors: [{ ...tokenRamp.colors[0], opacity: 0.5 }, tokenRamp.colors[1]] }, { lk }),
  'alpha',
);

// ── a stated strength survives the write ──
// A node that stores what it is given the way the double does: a paint bound to a
// variable is reset on its first write, a paint that re-states the stored binding
// is kept.
interface PaintNode {
  name: string;
  fills: unknown;
  strokes: unknown;
  getPluginData(key: string): string;
}
function paintNode(name: string, resetsEverything = false): PaintNode & SceneNode & MinimalFillsMixin & MinimalStrokesMixin {
  let fills: unknown[] = [];
  let strokes: unknown[] = [];
  const data: Record<string, string> = {};
  const store = (v: unknown[], previous: unknown[]): unknown[] =>
    resetsEverything ? v.map((p) => ({ ...(p as object), opacity: 1, blendMode: 'NORMAL' })) : storePaints(v, previous);
  return {
    name,
    get fills() { return fills; },
    set fills(v: unknown) { fills = store(v as unknown[], fills); },
    get strokes() { return strokes; },
    set strokes(v: unknown) { strokes = store(v as unknown[], strokes); },
    getPluginData(key: string) { return data[key] ?? ''; },
    setPluginData(key: string, value: string) { data[key] = value; },
  } as unknown as PaintNode & SceneNode & MinimalFillsMixin & MinimalStrokesMixin;
}
const strokeOf = (n: PaintNode): { opacity?: number; blendMode?: string; boundVariables?: { color?: unknown } } =>
  (n.strokes as unknown as { opacity?: number; blendMode?: string; boundVariables?: { color?: unknown } }[])[0];

// No MockupDevice layer is a bound solid below full strength, so the checks of the
// write itself run on a leaf made for them: the slot `secondary-fixed` stated at 60%.
// What they pin is the platform's behaviour and the builder's answer to it, not a
// colour of the product.
const kStatedStrength = 0.6;
const statedLeaf = { color: 'secondary-fixed', argb: 0xffe4e5e7, opacity: kStatedStrength };

// The control: without the read-back the double really takes the strength away,
// so the assertions below are not passing because nothing was reset.
const naive = paintNode('naive');
const lostBefore = trapStats.opacityLost;
naive.strokes = [colorPaint(lk, statedLeaf, naive)];
near('control: a freshly bound stroke reads full strength after a plain write', strokeOf(naive).opacity ?? 1, 1);
if (trapStats.opacityLost !== lostBefore + 1) fail('control', 'the model did not count the strength it took away');

const kept = paintNode('stated stroke');
assignPaints(kept, 'strokes', [colorPaint(lk, statedLeaf, kept)]);
near('stated stroke strength after assignPaints', strokeOf(kept).opacity ?? 1, kStatedStrength);
if ((strokeOf(kept).blendMode ?? 'NORMAL') !== 'NORMAL') fail('stated stroke blend', `${strokeOf(kept).blendMode}`);
if (strokeOf(kept).boundVariables?.color == null) fail('stated stroke binding', 'the write kept the strength and lost the variable');
// The node says its strength is deliberate, so the fidelity readback judges it
// against the alphas the component states instead of refusing a bound paint below 100%.
if (kept.getPluginData(kPaintStrengthKey) !== '1') fail('stated stroke marker', 'a bound stroke below full strength marks its node');

const statedFill = paintNode('stated fill');
fillDataOnPaint(statedFill, lk, statedLeaf);
const statedFillPaint = (statedFill.fills as unknown as { opacity?: number; boundVariables?: { color?: unknown } }[])[0];
near('stated fill strength after fillDataOnPaint', statedFillPaint.opacity ?? 1, kStatedStrength);
if (statedFill.getPluginData(kPaintStrengthKey) !== '1') fail('stated fill marker', 'a bound fill below full strength marks its node');
if (statedFillPaint.boundVariables?.color == null) fail('stated fill binding', 'the write kept the strength and lost the variable');

// The product path: the rim highlight and the lens highlight are white at full
// strength, literals, so both bind nothing, state no strength and mark nothing.
const rimNode = paintNode('rim highlight');
assignPaints(rimNode, 'strokes', [colorPaint(lk, colorData(f.rimHighlightColor)!, rimNode)]);
near('rim highlight strength', strokeOf(rimNode).opacity ?? 1, 1);
if (strokeOf(rimNode).boundVariables?.color != null) fail('rim highlight binding', 'the highlight is a literal and binds nothing');
if (rimNode.getPluginData(kPaintStrengthKey) !== '') fail('rim highlight marker', 'a literal stroke states no strength to mark');

const glintNode = paintNode('lens highlight');
fillDataOnPaint(glintNode, lk, colorData(f.lensHighlightColor));
const glintPaint = (glintNode.fills as unknown as { opacity?: number; boundVariables?: { color?: unknown } }[])[0];
near('lens highlight strength', glintPaint.opacity ?? 1, 1);
if (glintPaint.boundVariables?.color != null) fail('lens highlight binding', 'the highlight is a literal and binds nothing');
if (glintNode.getPluginData(kPaintStrengthKey) !== '') fail('lens highlight marker', 'a literal fill states no strength to mark');

// A bound paint at full strength costs no second write, and a literal paint is
// stored as given.
const full = paintNode('full');
assignPaints(full, 'fills', [colorPaint(lk, { color: 'scrim', argb: 0xff000000, opacity: 1 }, full)]);
near('bound paint at full strength', (full.fills as unknown as { opacity?: number }[])[0].opacity ?? 1, 1);
if (full.getPluginData(kPaintStrengthKey) !== '') fail('full-strength marker', 'a bound paint at full strength states no strength to mark');
const lit = paintNode('lit');
assignPaints(lit, 'fills', [colorPaint(lk, { color: null, argb: 0x80ffffff }, lit)]);
near('literal paint keeps its own alpha', (lit.fills as unknown as { opacity?: number }[])[0].opacity ?? 1, 128 / 255, 1e-6);
if (lit.getPluginData(kPaintStrengthKey) !== '') fail('literal marker', 'a literal paint is not a bound strength');

// A node that never holds the strength is recorded, not thrown over.
const stubborn = paintNode('stubborn', true);
paintOpacityNotHeld.length = 0;
assignPaints(stubborn, 'strokes', [colorPaint(lk, statedLeaf, stubborn)]);
if (paintOpacityNotHeld.join('|') !== 'stubborn strokes[0]') {
  fail('strength the node will not hold', `recorded [${paintOpacityNotHeld.join(', ')}]`);
}
paintOpacityNotHeld.length = 0;

// ─── The flat finish — a frame, not a picture of a device ─────────────────────
//
// `defaultsByFinish.flat` restates the device as one 8-thick ring around a
// 1 : 2 screen, for every device kind: body radius 32 (so the screen's, derived
// by the ring, is 24), no rail, no buttons, no antenna band. The numbers are the
// finish's own statement transcribed from the design, not read back from the
// geometry; the body is 256 wide upright (a 240 screen and a ring each side) and
// the long edge — 240 + 256 — turned.
console.log('flat finish');
const flatRow = COMPONENTS.mockup_device.variants.defaultsByFinish.flat as Record<string, unknown>;
for (const device of ['phone', 'tablet']) {
  const d = Object.entries(rows).find(([name]) => name === device)?.[1];
  if (d == null) throw new Error(`no defaultsByDevice row for ${device}`);
  const upright = mockupDeviceGeometry(
    mockupDeviceSettings({ device, orientation: 'portrait', width: 256, d, finish: flatRow }),
  );
  const turned = mockupDeviceGeometry(
    mockupDeviceSettings({ device, orientation: 'landscape', width: 496, d, finish: flatRow }),
  );
  near(`flat ${device} portrait height`, upright.height, 496);
  near(`flat ${device} landscape height`, turned.height, 256);
  rect(`flat ${device} portrait bezel box`, upright.bezelBox, [0, 0, 256, 496]);
  rect(`flat ${device} portrait screen box`, upright.screenBox, [8, 8, 240, 480]);
  rect(`flat ${device} landscape screen box`, turned.screenBox, [8, 8, 480, 240]);
  near(`flat ${device} bezel radius`, upright.bezelRadius, 32);
  near(`flat ${device} screen radius`, upright.screenRadius, 24);
  for (const [label, geo] of [['portrait', upright], ['landscape', turned]] as const) {
    if (geo.hasPowerButton || geo.hasVolumeButton || geo.volumeDown != null) {
      fail(`flat ${device} ${label} buttons`, 'a flat frame has no hardware button');
    }
    if (geo.antennaBands.length !== 0) fail(`flat ${device} ${label} antenna`, 'a flat frame has no antenna band');
  }
}
// The realistic finish is the empty row: it must not move a single rectangle.
{
  const d = rows.phone;
  const plain = mockupDeviceGeometry(mockupDeviceSettings({ device: 'phone', orientation: 'portrait', width: 160, d }));
  const realistic = mockupDeviceGeometry(
    mockupDeviceSettings({
      device: 'phone',
      orientation: 'portrait',
      width: 160,
      d,
      finish: COMPONENTS.mockup_device.variants.defaultsByFinish.realistic,
    }),
  );
  if (JSON.stringify(plain) !== JSON.stringify(realistic)) {
    fail('realistic finish', 'the empty row changed the geometry');
  }
  if (!realistic.hasPowerButton || !realistic.hasVolumeButton) fail('realistic buttons', 'a phone has both buttons');
}

if (failures > 0) {
  console.error(`\n${failures} mockup-device geometry self-test(s) failed.`);
  process.exit(1);
}
console.log('\nAll mockup-device geometry self-tests passed.');
