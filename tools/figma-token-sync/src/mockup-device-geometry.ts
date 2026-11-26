/// <reference types="@figma/plugin-typings" />

// MockupDevice's derived geometry — the Figma builder's transcription of
// `CoreMockupDeviceLayout.compute`, `CoreMockupStatusBarLayout.compute` and
// `CoreMockupDeviceLayout.safeAreaInsets`.
//
// Pure arithmetic over settled numbers, kept apart from the drawing so a Node
// selftest can pin every rectangle against the canvas measurements the Dart
// tests pin (`scripts/selftest-mockup-device.ts`) without a Figma double.
//
// This module owns no design value. Every number it computes from is read off
// `components.json` by `mockupDeviceSettings` — the per-device rows
// (`variants.defaultsByDevice`), the flat fields and the fixed constants — and
// the only literals below are the arithmetic's own (halves, a quarter turn).

import { Dim, dimVal } from './compat/v1';
import { COMPONENTS } from './data';
import { GradientData, kGradientAnchor } from './paint';

const MOCKUP_DEVICE = COMPONENTS.mockup_device;

export type DeviceEdge = 'left' | 'right' | 'top' | 'bottom';

export interface DeviceRect {
  x: number;
  y: number;
  w: number;
  h: number;
}

/** `CoreVectorGlyph` as the export carries it. */
export interface DeviceGlyph {
  path: string;
  width: number;
  height: number;
  /** `evenOdd` or `nonZero` — `CoreVectorFillRule`'s members. */
  fillRule: string;
}

/**
 * What a status bar item is for. Carried so the drawing can name and paint it —
 * Core states the geometry, not which glyph is the wifi fan.
 */
export type StatusBarRole =
  | 'clock'
  | 'meridiem'
  | 'date'
  | 'level'
  | 'cellular'
  | 'wifi'
  | 'battery';

export interface StatusBarTextItem {
  kind: 'text';
  role: StatusBarRole;
  text: string;
  gapAfter: number;
}

export interface StatusBarGlyphItem {
  kind: 'glyph';
  role: StatusBarRole;
  glyph: DeviceGlyph;
  w: number;
  h: number;
  gapAfter: number;
}

/** The phone's outline + level + nub, in one box. */
export interface StatusBarBatteryItem {
  kind: 'battery';
  role: StatusBarRole;
  w: number;
  h: number;
  border: DeviceRect;
  borderWidth: number;
  borderRadius: number;
  capacity: DeviceRect;
  capacityRadius: number;
  cap: DeviceRect;
  capGlyph: DeviceGlyph;
  gapAfter: number;
}

export type StatusBarItem = StatusBarTextItem | StatusBarGlyphItem | StatusBarBatteryItem;

export interface StatusBarGroup {
  /** Screen-space, symmetric about the bar's content line. */
  box: DeviceRect;
  /** Where the row sits along `box`'s width. */
  alignment: 'start' | 'center' | 'end';
  items: StatusBarItem[];
}

export interface StatusBarLayout {
  rect: DeviceRect;
  scale: number;
  contentCenter: number;
  leading: StatusBarGroup;
  trailing: StatusBarGroup;
}

export interface AntennaBand {
  edge: DeviceEdge;
  rect: DeviceRect;
  /** Which end of the edge the band was measured from — a pinned part holds to it. */
  fromFarEnd: boolean;
}

export interface DeviceGeometry {
  width: number;
  height: number;
  inset: number;
  screenWidth: number;
  screenHeight: number;
  bezelRadius: number;
  screenRadius: number;
  /** Body-space. */
  bezelBox: DeviceRect;
  screenBox: DeviceRect;
  rimHighlight: DeviceRect;
  rimGlow: DeviceRect;
  /** Which space `camera` / `lens` / `core` / `lensHighlight` are in. */
  cameraPlacement: 'screen' | 'bezel';
  cameraEdge: DeviceEdge;
  camera: DeviceRect;
  lens: DeviceRect | null;
  core: DeviceRect;
  lensHighlight: DeviceRect;
  // `CoreMockupDeviceLayout.cameraIsLens` — the cut-out with no ring IS the
  // lens, so it takes the lens fill; a cut-out holding a ring takes the
  // cut-out fill. There is no camera colour field to read.
  cameraIsLens: boolean;
  systemBarScale: number;
  /** Screen-space; `null` when the pose draws none (a phone on its side). */
  statusBar: StatusBarLayout | null;
  gestureBarArea: DeviceRect;
  gestureBar: DeviceRect;
  gestureBarRadius: number;
  /** Body-space; a button protrudes, so its coordinates may be negative. */
  power: DeviceRect;
  volumeUp: DeviceRect;
  volumeDown: DeviceRect | null;
  // Which body edge each button protrudes from. Carried out of the geometry
  // because a Figma part is pinned, not laid out: a slab on the bottom edge
  // has to hold to the bottom when the member resizes, and the rect alone
  // cannot say which edge it came from.
  powerEdge: DeviceEdge;
  volumeEdge: DeviceEdge;
  /**
   * `CoreMockupDeviceLayout.hasPowerButton` / `hasVolumeButton` — a device that
   * states a zero length has no such button, and no part is drawn for it
   * rather than a zero-sized one.
   */
  hasPowerButton: boolean;
  hasVolumeButton: boolean;
  antennaBands: AntennaBand[];
}

/**
 * One `variants.defaultsByFinish` row — the keys a finish restates, laid over
 * the per-device row (and over the flat fields the row also names, such as
 * `railWidth`). `realistic` is the empty row. The values are the export's own
 * shapes (`Dim` · colour data · gradient), so the row is read key by key.
 */
export type FinishRow = Readonly<Record<string, unknown>>;

/** The per-device row of `variants.defaultsByDevice`, whichever device it is. */
export type DeviceRow =
  (typeof MOCKUP_DEVICE.variants.defaultsByDevice)[keyof typeof MOCKUP_DEVICE.variants.defaultsByDevice];

/** Everything `mockupDeviceGeometry` computes from — each a settled value. */
export interface DeviceSettings {
  device: string;
  orientation: string;
  width: number;
  railWidth: number;
  bezelWidth: number;
  borderRadius: number;
  screenAspectWidth: number;
  screenAspectHeight: number;
  cameraPlacement: string;
  cameraWidth: number;
  cameraHeight: number;
  cameraOffset: number;
  lensSize: number;
  lensOffset: number;
  cameraCoreSize: number;
  lensHighlightSizeRatio: number;
  lensHighlightOffsetXRatio: number;
  lensHighlightOffsetYRatio: number;
  buttonThickness: number;
  buttonProtrusion: number;
  powerButtonLength: number;
  powerButtonOffset: number;
  volumeButtonLength: number;
  volumeButtonOffset: number;
  volumeButtonSpacing: number;
  landscapePowerButtonLength: number;
  landscapePowerButtonOffset: number;
  landscapeVolumeButtonLength: number;
  landscapeVolumeButtonOffset: number;
  antennaBandLength: number;
  antennaSideNearOffset: number;
  antennaSideFarOffset: number;
  antennaTopOffset: number;
  antennaBottomOffset: number;
  rimHighlightInset: number;
  rimGlowTopInset: number;
  rimGlowBottomInset: number;
  systemBarReferenceWidth: number;
  systemBarReferenceScale: number;
  landscapeSystemBarReferenceWidth: number;
  landscapeSystemBarReferenceScale: number;
  statusBarHeight: number;
  landscapeStatusBarHeight: number;
  statusBarInset: number;
  statusBarContentCenter: number;
  statusBarWingWidth: number;
  statusBarTrailingInset: number;
  statusBarTrailingSpacing: number;
  statusBarClockSpacing: number;
  statusBarLeadingSpacing: number;
  gestureBarWidth: number;
  landscapeGestureBarWidth: number;
  gestureBarHeight: number;
  gestureBarOffset: number;
  gestureBarRadius: number;
  gestureBarAreaHeight: number;
  landscapeGestureBarAreaHeight: number;
  /** The sample content — a mockup draws an OS caught at one moment. */
  sample: { time: string; meridiem: string; date: string; batteryLevel: string };
  glyphs: {
    phoneCellular: DeviceGlyph;
    phoneWifi: DeviceGlyph;
    phoneBatteryCap: DeviceGlyph;
    tabletWifi: DeviceGlyph;
    tabletBattery: DeviceGlyph;
  };
  /** The phone's three-part battery, in iOS points. */
  battery: {
    width: number;
    height: number;
    borderWidth: number;
    radius: number;
    capacityInset: number;
    capacityRadius: number;
    capGap: number;
    capOffset: number;
  };
}

/**
 * The settled inputs for one device in one pose: the per-device row `d`, the
 * flat fields and the fixed constants, read in one place so the builder and its
 * selftest cannot disagree about where a number comes from.
 *
 * The preview `width` is the one input that is not Core's — see
 * `kDevicePreviewWidth` in the builder.
 */
export interface DeviceSettingsInput {
  device: string;
  orientation: string;
  width: number;
  d: DeviceRow;
  /**
   * The finish row laid over [d] — `CoreMockupDeviceStyle.defaultsByFinish`
   * sits above the per-device row in the merge chain, so a key it states wins.
   * Absent is `realistic`.
   */
  finish?: FinishRow;
}

export function mockupDeviceSettings(o: DeviceSettingsInput): DeviceSettings {
  const f = MOCKUP_DEVICE.fields;
  const k = MOCKUP_DEVICE.constants;
  const fin = o.finish ?? {};
  // The finish row restates per-device keys and, for the rail, a flat field:
  // both are read through it. A key the row does not state falls through.
  const d = { ...o.d, ...fin } as DeviceRow;
  return {
    device: o.device,
    orientation: o.orientation,
    width: o.width,
    railWidth: dimVal((fin.railWidth as Dim | undefined) ?? f.railWidth),
    bezelWidth: dimVal(d.bezelWidth),
    borderRadius: dimVal(d.borderRadius.topLeft),
    screenAspectWidth: dimVal(d.screenAspectWidth),
    screenAspectHeight: dimVal(d.screenAspectHeight),
    cameraPlacement: d.cameraPlacement.choice,
    cameraWidth: dimVal(d.cameraWidth),
    cameraHeight: dimVal(d.cameraHeight),
    cameraOffset: dimVal(d.cameraOffset),
    lensSize: dimVal(d.lensSize),
    lensOffset: dimVal(d.lensOffset),
    cameraCoreSize: dimVal(d.cameraCoreSize),
    lensHighlightSizeRatio: dimVal(f.lensHighlightSizeRatio),
    lensHighlightOffsetXRatio: dimVal(f.lensHighlightOffsetXRatio),
    lensHighlightOffsetYRatio: dimVal(f.lensHighlightOffsetYRatio),
    buttonThickness: dimVal(f.buttonThickness),
    buttonProtrusion: dimVal(f.buttonProtrusion),
    powerButtonLength: dimVal(d.powerButtonLength),
    powerButtonOffset: dimVal(d.powerButtonOffset),
    volumeButtonLength: dimVal(d.volumeButtonLength),
    volumeButtonOffset: dimVal(d.volumeButtonOffset),
    volumeButtonSpacing: dimVal(d.volumeButtonSpacing),
    landscapePowerButtonLength: dimVal(d.landscapePowerButtonLength),
    landscapePowerButtonOffset: dimVal(d.landscapePowerButtonOffset),
    landscapeVolumeButtonLength: dimVal(d.landscapeVolumeButtonLength),
    landscapeVolumeButtonOffset: dimVal(d.landscapeVolumeButtonOffset),
    antennaBandLength: dimVal(d.antennaBandLength),
    antennaSideNearOffset: dimVal(f.antennaSideNearOffset),
    antennaSideFarOffset: dimVal(f.antennaSideFarOffset),
    antennaTopOffset: dimVal(f.antennaTopOffset),
    antennaBottomOffset: dimVal(f.antennaBottomOffset),
    rimHighlightInset: dimVal(f.rimHighlightInset),
    rimGlowTopInset: dimVal(f.rimGlowTopInset),
    rimGlowBottomInset: dimVal(f.rimGlowBottomInset),
    systemBarReferenceWidth: dimVal(d.systemBarReferenceWidth),
    systemBarReferenceScale: dimVal(d.systemBarReferenceScale),
    landscapeSystemBarReferenceWidth: dimVal(d.landscapeSystemBarReferenceWidth),
    landscapeSystemBarReferenceScale: dimVal(d.landscapeSystemBarReferenceScale),
    statusBarHeight: dimVal(d.statusBarHeight),
    landscapeStatusBarHeight: dimVal(d.landscapeStatusBarHeight),
    statusBarInset: dimVal(d.statusBarInset),
    statusBarContentCenter: dimVal(d.statusBarContentCenter),
    statusBarWingWidth: dimVal(d.statusBarWingWidth),
    statusBarTrailingInset: dimVal(d.statusBarTrailingInset),
    statusBarTrailingSpacing: dimVal(d.statusBarTrailingSpacing),
    statusBarClockSpacing: dimVal(f.statusBarClockSpacing),
    statusBarLeadingSpacing: dimVal(f.statusBarLeadingSpacing),
    gestureBarWidth: dimVal(d.gestureBarWidth),
    landscapeGestureBarWidth: dimVal(d.landscapeGestureBarWidth),
    gestureBarHeight: dimVal(f.gestureBarHeight),
    gestureBarOffset: dimVal(f.gestureBarOffset),
    gestureBarRadius: dimVal(f.gestureBarRadius),
    gestureBarAreaHeight: dimVal(d.gestureBarAreaHeight),
    landscapeGestureBarAreaHeight: dimVal(d.landscapeGestureBarAreaHeight),
    sample: {
      time: k.sampleTime.choice,
      meridiem: k.sampleMeridiem.choice,
      date: k.sampleDate.choice,
      batteryLevel: k.sampleBatteryLevel.choice,
    },
    glyphs: {
      phoneCellular: k.phoneCellularGlyph,
      phoneWifi: k.phoneWifiGlyph,
      phoneBatteryCap: k.phoneBatteryCapGlyph,
      tabletWifi: k.tabletWifiGlyph,
      tabletBattery: k.tabletBatteryGlyph,
    },
    battery: {
      width: dimVal(k.phoneBatteryWidth),
      height: dimVal(k.phoneBatteryHeight),
      borderWidth: dimVal(k.phoneBatteryBorderWidth),
      radius: dimVal(k.phoneBatteryRadius),
      capacityInset: dimVal(k.phoneBatteryCapacityInset),
      capacityRadius: dimVal(k.phoneBatteryCapacityRadius),
      capGap: dimVal(k.phoneBatteryCapGap),
      capOffset: dimVal(k.phoneBatteryCapOffset),
    },
  };
}

// One quarter turn clockwise: left → top → right → bottom → left. The single
// rule that places every button and antenna band in landscape.
const kTurned: Record<DeviceEdge, DeviceEdge> = {
  left: 'top',
  top: 'right',
  right: 'bottom',
  bottom: 'left',
};

export function isVerticalEdge(edge: DeviceEdge): boolean {
  return edge === 'left' || edge === 'right';
}

// `CoreMockupStatusBarLayout.compute`, transcribed. Lengths in `s` are iOS
// points; `scale` turns them into logical px.
function statusBarLayout(s: DeviceSettings, screenWidth: number, scale: number, heightPoints: number): StatusBarLayout {
  const barHeight = heightPoints * scale;
  const centerY = s.statusBarContentCenter * scale;
  // The part of the bar symmetric about the content line, reaching the nearer
  // of the bar's two edges.
  const half = Math.max(Math.min(centerY, barHeight - centerY), 0);
  const boxTop = centerY - half;
  const boxHeight = half * 2;
  const edge = s.statusBarInset * scale;

  let leadingBox: DeviceRect;
  let trailingBox: DeviceRect;
  let leadingAlignment: StatusBarGroup['alignment'];
  let trailingAlignment: StatusBarGroup['alignment'];
  if (s.statusBarWingWidth > 0) {
    // Each group is centred in a wing: the leading wing is wingWidth wide at
    // the leading edge, the trailing one wingWidth minus its extra outer
    // inset, at the trailing edge.
    const wing = s.statusBarWingWidth * scale;
    leadingBox = { x: edge, y: boxTop, w: wing, h: boxHeight };
    trailingBox = {
      x: screenWidth - edge - wing,
      y: boxTop,
      w: Math.max(wing - s.statusBarTrailingInset * scale, 0),
      h: boxHeight,
    };
    leadingAlignment = 'center';
    trailingAlignment = 'center';
  } else {
    // One box between the two insets; the groups are pushed to its ends.
    const box = { x: edge, y: boxTop, w: Math.max(screenWidth - edge * 2, 0), h: boxHeight };
    leadingBox = box;
    trailingBox = box;
    leadingAlignment = 'start';
    trailingAlignment = 'end';
  }

  const glyphItem = (role: StatusBarRole, glyph: DeviceGlyph, gap: number): StatusBarItem => ({
    kind: 'glyph',
    role,
    glyph,
    w: glyph.width * scale,
    h: glyph.height * scale,
    gapAfter: gap * scale,
  });
  const textItem = (role: StatusBarRole, text: string, gap: number): StatusBarItem => ({
    kind: 'text',
    role,
    text,
    gapAfter: gap * scale,
  });

  let leadingItems: StatusBarItem[];
  let trailingItems: StatusBarItem[];
  switch (s.device) {
    case 'phone':
      leadingItems = [textItem('clock', s.sample.time, 0)];
      trailingItems = [
        glyphItem('cellular', s.glyphs.phoneCellular, s.statusBarTrailingSpacing),
        glyphItem('wifi', s.glyphs.phoneWifi, s.statusBarTrailingSpacing),
        phoneBattery(s, scale),
      ];
      break;
    case 'tablet':
      leadingItems = [
        textItem('clock', s.sample.time, s.statusBarClockSpacing),
        textItem('meridiem', s.sample.meridiem, s.statusBarLeadingSpacing),
        textItem('date', s.sample.date, 0),
      ];
      trailingItems = [
        glyphItem('wifi', s.glyphs.tabletWifi, s.statusBarTrailingSpacing),
        textItem('level', s.sample.batteryLevel, s.statusBarTrailingSpacing),
        glyphItem('battery', s.glyphs.tabletBattery, 0),
      ];
      break;
    default:
      throw new Error(
        `MockupDevice: no status bar items for device "${s.device}" — ` +
          '`CoreMockupStatusBarLayout.compute` has to state them before this builder can draw it.',
      );
  }

  return {
    rect: { x: 0, y: 0, w: screenWidth, h: barHeight },
    scale,
    contentCenter: centerY,
    leading: { box: leadingBox, alignment: leadingAlignment, items: leadingItems },
    trailing: { box: trailingBox, alignment: trailingAlignment, items: trailingItems },
  };
}

// The phone's three-part battery at `scale`.
function phoneBattery(s: DeviceSettings, scale: number): StatusBarBatteryItem {
  const b = s.battery;
  const cap = s.glyphs.phoneBatteryCap;
  return {
    kind: 'battery',
    role: 'battery',
    w: (b.width + b.capGap + cap.width) * scale,
    h: b.height * scale,
    border: { x: 0, y: 0, w: b.width * scale, h: b.height * scale },
    borderWidth: b.borderWidth * scale,
    borderRadius: b.radius * scale,
    capacity: {
      x: b.capacityInset * scale,
      y: b.capacityInset * scale,
      w: (b.width - b.capacityInset * 2) * scale,
      h: (b.height - b.capacityInset * 2) * scale,
    },
    capacityRadius: b.capacityRadius * scale,
    cap: {
      x: (b.width + b.capGap) * scale,
      y: b.capOffset * scale,
      w: cap.width * scale,
      h: cap.height * scale,
    },
    capGlyph: cap,
    gapAfter: 0,
  };
}

/** `CoreMockupDeviceLayout.compute`, transcribed — owns no default of its own. */
export function mockupDeviceGeometry(o: DeviceSettings): DeviceGeometry {
  // ─── Frame — bezel uniform, radii concentric ──────────
  // The aspect states proportions, not a direction: it is read long-side-first
  // and `orientation` alone decides which way that long side runs.
  const landscape = o.orientation === 'landscape';
  const longAspect = Math.max(o.screenAspectWidth, o.screenAspectHeight);
  const shortAspect = Math.min(o.screenAspectWidth, o.screenAspectHeight);
  const aspectWidth = landscape ? longAspect : shortAspect;
  const aspectHeight = landscape ? shortAspect : longAspect;

  const inset = o.railWidth + o.bezelWidth;
  const screenWidth = Math.max(o.width - inset * 2, 0);
  const screenHeight = aspectWidth === 0 ? 0 : (screenWidth * aspectHeight) / aspectWidth;
  const height = screenHeight + inset * 2;

  // The bezel box sits one rail in from the body edge; the screen sits one
  // bezel in from the bezel box (so one whole inset in from the body).
  const bezelBox: DeviceRect = {
    x: o.railWidth,
    y: o.railWidth,
    w: Math.max(o.width - o.railWidth * 2, 0),
    h: Math.max(height - o.railWidth * 2, 0),
  };
  const screenBox: DeviceRect = { x: inset, y: inset, w: screenWidth, h: screenHeight };

  // ─── Rim — two strokes over the body, inset top and bottom only ──
  const rimHighlight: DeviceRect = {
    x: 0,
    y: o.rimHighlightInset,
    w: o.width,
    h: Math.max(height - o.rimHighlightInset * 2, 0),
  };
  const rimGlow: DeviceRect = {
    x: 0,
    y: o.rimGlowTopInset,
    w: o.width,
    h: Math.max(height - o.rimGlowTopInset - o.rimGlowBottomInset, 0),
  };

  // ─── Camera — the upright pose, then turned ───────────
  // A camera in the bezel strip stays on the top strip in both orientations. A
  // camera cut out of the screen rests against the screen's top edge upright
  // and, when the body turns clockwise, against its leading (left) edge — the
  // upright pose turned a quarter turn counter-clockwise, so the pill stands on
  // end and the lens, at the pill's right end upright, sits at its top end.
  if (o.cameraPlacement !== 'screen' && o.cameraPlacement !== 'bezel') {
    throw new Error(
      `MockupDevice: unknown camera placement "${o.cameraPlacement}" ` +
        '(`CoreMockupCameraPlacement` states screen and bezel).',
    );
  }
  const onScreen = o.cameraPlacement === 'screen';
  const cameraEdge: DeviceEdge = onScreen && landscape ? 'left' : 'top';
  const standing = cameraEdge === 'left';
  const hostWidth = onScreen ? screenWidth : bezelBox.w;
  const camera: DeviceRect = standing
    ? { x: o.cameraOffset, y: (screenHeight - o.cameraWidth) / 2, w: o.cameraHeight, h: o.cameraWidth }
    : { x: (hostWidth - o.cameraWidth) / 2, y: o.cameraOffset, w: o.cameraWidth, h: o.cameraHeight };
  // `lensSize == 0` is how a device says its cut-out IS the lens.
  const lens: DeviceRect | null =
    o.lensSize > 0
      ? standing
        ? {
            x: camera.x + (camera.w - o.lensSize) / 2,
            y: camera.y + o.lensOffset,
            w: o.lensSize,
            h: o.lensSize,
          }
        : {
            x: camera.x + camera.w - o.lensOffset - o.lensSize,
            y: camera.y + (camera.h - o.lensSize) / 2,
            w: o.lensSize,
            h: o.lensSize,
          }
      : null;
  const coreHost = lens ?? camera;
  const core: DeviceRect = {
    x: coreHost.x + (coreHost.w - o.cameraCoreSize) / 2,
    y: coreHost.y + (coreHost.h - o.cameraCoreSize) / 2,
    w: o.cameraCoreSize,
    h: o.cameraCoreSize,
  };
  // The glint sits up and to the left of the core whichever way the pill turns,
  // so its offsets are not rotated with the camera.
  const lensHighlight: DeviceRect = {
    x: core.x + o.cameraCoreSize * o.lensHighlightOffsetXRatio,
    y: core.y + o.cameraCoreSize * o.lensHighlightOffsetYRatio,
    w: o.cameraCoreSize * o.lensHighlightSizeRatio,
    h: o.cameraCoreSize * o.lensHighlightSizeRatio,
  };

  // ─── System bars — iOS points at the authored reference scale ──
  const referenceWidth = landscape ? o.landscapeSystemBarReferenceWidth : o.systemBarReferenceWidth;
  const referenceScale = landscape ? o.landscapeSystemBarReferenceScale : o.systemBarReferenceScale;
  const systemBarScale = referenceWidth > 0 ? Math.max(referenceScale, 0) : 0;

  // A device that draws no status bar in this pose states a height of `0`.
  const barHeightPoints = landscape ? o.landscapeStatusBarHeight : o.statusBarHeight;
  const statusBar =
    barHeightPoints > 0 ? statusBarLayout(o, screenWidth, systemBarScale, barHeightPoints) : null;

  // The gesture bar sits `gestureBarOffset` above the bottom edge, centred,
  // inside an area along the bottom whose height is the device's own bottom
  // safe-area inset.
  const gestureBarPoints = landscape ? o.landscapeGestureBarWidth : o.gestureBarWidth;
  const gestureBarWidthPx = gestureBarPoints * systemBarScale;
  const gestureBarHeightPx = o.gestureBarHeight * systemBarScale;
  const gestureBarGap = o.gestureBarOffset * systemBarScale;
  const gestureBar: DeviceRect = {
    x: (screenWidth - gestureBarWidthPx) / 2,
    y: screenHeight - gestureBarGap - gestureBarHeightPx,
    w: gestureBarWidthPx,
    h: gestureBarHeightPx,
  };
  const gestureBarAreaPoints = landscape ? o.landscapeGestureBarAreaHeight : o.gestureBarAreaHeight;
  const gestureBarAreaPx = gestureBarAreaPoints * systemBarScale;
  const gestureBarArea: DeviceRect = {
    x: 0,
    y: screenHeight - gestureBarAreaPx,
    w: screenWidth,
    h: gestureBarAreaPx,
  };

  // ─── Buttons — the upright pose, then turned ──────────
  // Each device states where its buttons sit when held upright; landscape is
  // that pose turned a quarter turn clockwise, never a second table. How long
  // a button is and how far along its edge it sits are authored per
  // orientation, because the canvas measures them afresh after the turn.
  let volumeEdge: DeviceEdge;
  let powerEdge: DeviceEdge;
  if (o.device === 'phone') {
    volumeEdge = 'left';
    powerEdge = 'right';
  } else if (o.device === 'tablet') {
    volumeEdge = 'left';
    powerEdge = 'top';
  } else {
    throw new Error(
      `MockupDevice: no button placement for device "${o.device}" — ` +
        '`CoreMockupDeviceLayout.compute` has to state one before this builder can draw it.',
    );
  }
  if (landscape) {
    volumeEdge = kTurned[volumeEdge];
    powerEdge = kTurned[powerEdge];
  }
  const onEdge = (edge: DeviceEdge, fraction: number, length: number, fromRightEnd: boolean): DeviceRect => {
    if (edge === 'left') {
      return { x: -o.buttonProtrusion, y: height * fraction, w: o.buttonThickness, h: length };
    }
    if (edge === 'right') {
      return {
        x: o.width - (o.buttonThickness - o.buttonProtrusion),
        y: height * fraction,
        w: o.buttonThickness,
        h: length,
      };
    }
    return {
      x: fromRightEnd ? o.width - o.width * fraction - length : o.width * fraction,
      y: edge === 'top' ? -o.buttonProtrusion : height - (o.buttonThickness - o.buttonProtrusion),
      w: length,
      h: o.buttonThickness,
    };
  };
  // Power hugs the top-right corner: measured from the top on a vertical edge,
  // from the right end on the top edge. Volume hugs the top-left corner.
  const powerLength = landscape ? o.landscapePowerButtonLength : o.powerButtonLength;
  const powerOffset = landscape ? o.landscapePowerButtonOffset : o.powerButtonOffset;
  const volumeLength = landscape ? o.landscapeVolumeButtonLength : o.volumeButtonLength;
  const volumeOffset = landscape ? o.landscapeVolumeButtonOffset : o.volumeButtonOffset;
  const power = onEdge(powerEdge, powerOffset, powerLength, true);
  const volumeUp = onEdge(volumeEdge, volumeOffset, volumeLength, false);
  // A second volume button only when the style states a gap between the two —
  // `0` is how a device says "one rocker".
  const hasPowerButton = powerLength > 0;
  const hasVolumeButton = volumeLength > 0;
  const volumeDown: DeviceRect | null =
    hasVolumeButton && o.volumeButtonSpacing > 0
      ? isVerticalEdge(volumeEdge)
        ? { ...volumeUp, y: volumeUp.y + volumeLength + o.volumeButtonSpacing }
        : { ...volumeUp, x: volumeUp.x + volumeLength + o.volumeButtonSpacing }
      : null;

  // ─── Antenna bands — the upright set, carried one edge clockwise ──
  // Each band is stated by its edge, which end of that edge it is measured
  // from, and how far from that end. The turned set keeps the end and the
  // distance and only moves the edge: the canvas draws it that way, which is a
  // rotation of the edges but not of the distances. A band is as thick as the
  // rail, so it spans exactly the band of body outside the bezel.
  const band = (portraitEdge: DeviceEdge, fromFarEnd: boolean, distance: number): AntennaBand => {
    const edge = landscape ? kTurned[portraitEdge] : portraitEdge;
    const along = isVerticalEdge(edge) ? height : o.width;
    const start = fromFarEnd ? along - distance - o.antennaBandLength : distance;
    let rect: DeviceRect;
    switch (edge) {
      case 'left':
        rect = { x: 0, y: start, w: o.railWidth, h: o.antennaBandLength };
        break;
      case 'right':
        rect = { x: o.width - o.railWidth, y: start, w: o.railWidth, h: o.antennaBandLength };
        break;
      case 'top':
        rect = { x: start, y: 0, w: o.antennaBandLength, h: o.railWidth };
        break;
      case 'bottom':
        rect = { x: start, y: height - o.railWidth, w: o.antennaBandLength, h: o.railWidth };
        break;
    }
    return { edge, rect, fromFarEnd };
  };
  // `0` is how a device says "no antenna bands".
  const antennaBands: AntennaBand[] =
    o.antennaBandLength > 0
      ? [
          band('top', true, o.antennaTopOffset),
          band('left', false, o.antennaSideNearOffset),
          band('right', false, o.antennaSideNearOffset),
          band('left', true, o.antennaSideFarOffset),
          band('right', true, o.antennaSideFarOffset),
          band('bottom', false, o.antennaBottomOffset),
        ]
      : [];

  return {
    width: o.width,
    height,
    inset,
    screenWidth,
    screenHeight,
    bezelRadius: Math.max(o.borderRadius - o.railWidth, 0),
    screenRadius: Math.max(o.borderRadius - inset, 0),
    bezelBox,
    screenBox,
    rimHighlight,
    rimGlow,
    cameraPlacement: o.cameraPlacement,
    cameraEdge,
    camera,
    lens,
    core,
    lensHighlight,
    cameraIsLens: lens == null,
    systemBarScale,
    statusBar,
    gestureBarArea,
    gestureBar,
    gestureBarRadius: o.gestureBarRadius * systemBarScale,
    power,
    volumeUp,
    volumeDown,
    powerEdge,
    volumeEdge,
    hasPowerButton,
    hasVolumeButton,
    antennaBands,
  };
}

// ─── Safe area ───────────────────────────────────────────────────────────────
//
// `CoreMockupDeviceLayout.safeAreaInsets` states each side as the deepest of the
// things that reserve it, each released by its own `Show …` flag. The builder
// needs those things SEPARATELY — a Figma spacer is bound to one boolean — so
// they are returned as sources, and `safeAreaInsets` below folds them the way
// Core does so the transcription can be checked against Core's numbers.

export type SafeAreaFlag = 'camera' | 'statusBar' | 'gestureBar';
export type SafeAreaSide = 'top' | 'bottom' | 'left' | 'right';

export interface SafeAreaSource {
  flag: SafeAreaFlag;
  side: SafeAreaSide;
  /** Screen-space logical px, before the clamp to the screen. */
  inset: number;
}

export function safeAreaSources(g: DeviceGeometry): SafeAreaSource[] {
  const out: SafeAreaSource[] = [];
  // The camera's far reach in each direction: an oversized lens or core
  // contributes, so style overrides cannot intrude into the child.
  const cameraBottom = Math.max(
    g.camera.y + g.camera.h,
    g.core.y + g.core.h,
    g.lens == null ? 0 : g.lens.y + g.lens.h,
  );
  const cameraRight = Math.max(
    g.camera.x + g.camera.w,
    g.core.x + g.core.w,
    g.lens == null ? 0 : g.lens.x + g.lens.w,
  );
  if (g.cameraPlacement === 'screen' && g.cameraEdge === 'top') {
    out.push({ flag: 'camera', side: 'top', inset: cameraBottom + g.camera.y });
  }
  if (g.cameraPlacement === 'screen' && g.cameraEdge === 'left') {
    out.push({ flag: 'camera', side: 'left', inset: cameraRight + g.camera.x });
  }
  if (g.statusBar != null) {
    out.push({ flag: 'statusBar', side: 'top', inset: g.statusBar.rect.h });
  }
  out.push({
    flag: 'gestureBar',
    side: 'bottom',
    inset: Math.max(g.gestureBarArea.h, g.screenHeight - g.gestureBar.y),
  });
  return out;
}

function clamp(v: number, lo: number, hi: number): number {
  return Math.min(Math.max(v, lo), hi);
}

/** `safeAreaInsets` — each flag releases exactly its own inset. */
export function safeAreaInsets(
  g: DeviceGeometry,
  shown: { camera: boolean; statusBar: boolean; gestureBar: boolean },
): { top: number; bottom: number; left: number; right: number } {
  const deepest = (side: SafeAreaSide): number =>
    safeAreaSources(g)
      .filter((s) => s.side === side && shown[s.flag])
      .reduce((m, s) => Math.max(m, s.inset), 0);
  const top = clamp(deepest('top'), 0, g.screenHeight);
  const bottom = clamp(deepest('bottom'), 0, g.screenHeight - top);
  const left = clamp(deepest('left'), 0, g.screenWidth);
  const right = clamp(deepest('right'), 0, g.screenWidth);
  return { top, bottom, left, right };
}

// ─── Button shading ──────────────────────────────────────────────────────────
//
// A hardware button is three fills: the base colour, a gloss along its length
// and a shade across its thickness. The two gradients are authored once and
// pointed per edge by `CoreMockupDeviceLayout.buttonLengthGradient` /
// `buttonDepthGradient`; these are those two statics, transcribed.

/**
 * The gloss along a button's length on `edge`: top to bottom for a button on a
 * vertical edge, left to right for one on a horizontal edge. Colours and stops
 * are `authored`'s; its own `begin` / `end` are not read.
 */
export function buttonLengthGradient(authored: GradientData, edge: DeviceEdge): GradientData {
  const vertical = isVerticalEdge(edge);
  return {
    type: authored.type,
    colors: authored.colors,
    stops: authored.stops,
    begin: vertical ? kGradientAnchor.topCenter : kGradientAnchor.centerStart,
    end: vertical ? kGradientAnchor.bottomCenter : kGradientAnchor.centerEnd,
  };
}

// `CoreColor.transparent`, as the export writes it: `argb: 0`.
const kTransparentArgb = 0;

/**
 * The shade across a button's thickness on `edge`: `depth` at the side nearest
 * the body, clear at the far side. The body lies on the opposite side of the
 * button from the edge's name — a button on the left edge has the body to its
 * right.
 */
export function buttonDepthGradient(
  depth: { argb: number; opacity: number },
  edge: DeviceEdge,
): GradientData {
  let begin: { x: number; y: number };
  let end: { x: number; y: number };
  switch (edge) {
    case 'left':
      begin = kGradientAnchor.centerEnd;
      end = kGradientAnchor.centerStart;
      break;
    case 'right':
      begin = kGradientAnchor.centerStart;
      end = kGradientAnchor.centerEnd;
      break;
    case 'top':
      begin = kGradientAnchor.bottomCenter;
      end = kGradientAnchor.topCenter;
      break;
    case 'bottom':
      begin = kGradientAnchor.topCenter;
      end = kGradientAnchor.bottomCenter;
      break;
  }
  return {
    type: 'linear',
    colors: [
      { ref: null, argb: depth.argb, opacity: depth.opacity },
      { ref: null, argb: kTransparentArgb, opacity: 1 },
    ],
    // Two stops, the ends of the ramp.
    stops: [0, 1],
    begin,
    end,
  };
}
