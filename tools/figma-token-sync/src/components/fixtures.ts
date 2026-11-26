/// <reference types="@figma/plugin-typings" />

// fixtures.ts — sets the builders draw for their own use, not for the design
// system.
//
// A REGISTRY entry is normally a CoUI component: a contract in coui_core, a
// record in components.json, and a set the fidelity sweep compares against that
// record. A fixture is none of those. It exists because Figma needs a COMPONENT
// where the code has none — an INSTANCE_SWAP default has to point at one — and
// its name starts with `.`, which keeps it out of the published library.
//
// The entry carries `fixture` (helpers.ts `RegistryEntry`), which tells every
// reader that would look up a data slug to stand down, and names the selftest
// that checks what the builder draws.

import {
  ColorData,
  RegistryEntry,
  VarLookup,
  bestVariantName,
  bindRadiusN,
  bindSize,
  glyphOpts,
  instanceOf,
  lockWidth,
  makeIcon,
  makeLabel,
  mintPanelComp,
  mountSet,
  panel,
  setBorder,
  setInstanceTextNamed,
  textLabelOpts,
} from '../helpers';
import { enumerateAxisAssignments } from '../axis-combos';
import { dimVal, textStyleData } from '../compat/v1';
import {
  kDraggablePanelExample,
  kHoverCardExample,
  kMockupDeviceExample,
  kNavigationMenuExample,
  kPopoverExample,
  kRefreshTriggerExample,
} from '../default-examples';
import { COMPONENTS } from '../data';
import { kSlotShapes, kSlotStandInComponent } from '../slot-stand-in';

// `CoreDashedBorder`'s rhythm, read through the record that states it — the
// field's `via` names the constant. A slot outline dashes the way every other
// dashed CoUI border does, and follows when that rhythm changes: the entry
// declares `dataFrom: ['frame']`, so its content hash moves with that record.
const DASHED = COMPONENTS.frame.fields;

// ─── .Slot ───────────────────────────────────────────────────────────────────
//
// The empty slot. A contract slot typed `W` / `W?` takes any widget, and its
// Figma face is an INSTANCE_SWAP whose default must be some component — this is
// that component (`slot-stand-in.ts` is the one place builders reach it). It is
// a dashed outline over nothing: a mark that says "something goes here", not a
// picture of any particular something, so it reads neither as content nor as a
// loading state.
//
// `Shape` has the two outlines a slot's content can have — a box (corner 0) and
// a circle (full corner). Each member's box is a preview size: most callers size
// their slot (FILL, a fixed box, a scale), and the rest take the member's box.
// The outline is drawn inside, so the box is the slot's whole extent.
export function buildSlot(page: PageNode, lk: VarLookup): ComponentSetNode {
  const members = enumerateAxisAssignments([{ axis: 'Shape', values: kSlotShapes }]);
  const mount = mountSet(page, kSlotStandInComponent, members.map((m) => m.name));
  for (const { name, values } of members) {
    const c = mount.getOrCreate(name);
    c.layoutMode = 'NONE';
    c.fills = [];
    c.clipsContent = false;
    const circle = values.Shape === 'circle';
    // g7-preview-only: a slot's preview box — the stand-in has no contract, and a caller that does not size its slot takes this (a 40px circle, a 160×40 box).
    c.resize(circle ? 40 : 160, 40);
    // g7-preview-only: the two outlines the `Shape` axis names — corner 0 for a box and the full corner for a circle; `.Slot` is a builder fixture and no contract states a radius for it.
    bindRadiusN(c, lk, circle ? 9999 : 0);
    // g7-preview-only: the stand-in's outline — `outline` at `CoreStrokeWidth.stroke1`, the designer's choice for an empty slot (#5277); `.Slot` has no contract to state it.
    setBorder(c, lk, 'outline', 1, 1);
    c.strokeAlign = 'INSIDE';
    c.dashPattern = [dimVal(DASHED.dashLength), dimVal(DASHED.dashSpacing)];
  }
  return mount.finish();
}

// ─── .Example/* — the default content of a caller slot (#6473) ──────────────
//
// Each of these is what one component's caller slot shows until a designer
// swaps in their own: the popover's panel, the hover card's profile, a device
// frame's app screen. Why the default is an example and not the `.Slot`
// stand-in: `default-examples.ts`. They are fixtures for the reason `.Slot` is
// — Figma needs a COMPONENT for a swap default, and no CoUI contract has one
// to give — and their names start with `.`, so the published library never
// lists them.
//
// What each one draws is read off the designer's copy of its component
// (`<Name>(리디자인)` and its `.Example/…` in the design file), and it is
// built the way a screen would be built out of the kit: composed `Avatar` /
// `Button` / `Progress` instances rather than drawn circles, buttons and bars,
// text in the scale's roles, colours as semantic tokens. The values that belong
// to no component — the example's own width, a row's inset, the gap between
// two lines of sample copy — are preview geometry and are marked where they
// are written. No code reads an example: a widget's slot takes whatever the
// caller passes.
//
// A weight over a role (`labelLarge` at 600) is the copy's: the scale has no
// 14 / 13 / 12 SemiBold role and the copy's titles are SemiBold. Such a label
// keeps the role's size and line height bound and carries the weight itself;
// it does not take the role's text style, which states 500
// (`core/design-tokens.md`, "역할이 살아남은 라벨만").

/** Sample copy in a role, in a token's ink. */
function exampleText(
  text: string,
  lk: VarLookup,
  role: string,
  color: string,
  fontWeight?: number,
): TextNode {
  const ink: ColorData = { color: color };
  const style = textStyleData({ role: role, fontWeight: fontWeight });
  const node = makeLabel(text, lk, textLabelOpts(lk, style, ink));
  node.name = text;
  return node;
}

/** A line of copy that wraps across its column. Call after it is appended. */
function wrapAcross(text: TextNode): void {
  text.textAutoResize = 'HEIGHT';
  text.layoutSizingHorizontal = 'FILL';
}

/** The kit's own `Button`, holding a label. */
function exampleButton(page: PageNode, variant: string, size: string, label: string): InstanceNode {
  const axes = { Variant: variant, Size: size, State: 'enabled', Shape: 'rectangle' };
  const button = instanceOf(page, 'Button', bestVariantName(page, 'Button', axes));
  button.name = 'Button';
  setInstanceTextNamed(button, 'Child', label);
  return button;
}

/** The kit's own `Avatar`, showing initials. */
function exampleAvatar(page: PageNode, size: string, initials: string): InstanceNode {
  const axes = { Size: size, Shape: 'circle', Ring: 'false' };
  const avatar = instanceOf(page, 'Avatar', bestVariantName(page, 'Avatar', axes));
  avatar.name = 'Avatar';
  setInstanceTextNamed(avatar, 'Initials', initials);
  return avatar;
}

/** The kit's own `Progress` — the thin primary bar, its labels off. */
function exampleProgress(page: PageNode): InstanceNode {
  const axes = { Size: 'xs', Tone: 'primary', Segmented: 'false' };
  const bar = instanceOf(page, 'Progress', bestVariantName(page, 'Progress', axes));
  bar.name = 'Progress';
  return bar;
}

/** Title over a line, the two-line text block every example row carries. */
function titledLine(
  lk: VarLookup,
  title: string,
  titleRole: string,
  line: string,
  lineRole: string,
  titleWeight?: number,
  lineWeight?: number,
): FrameNode {
  const block = panel('text', 'VERTICAL', lk, {});
  block.appendChild(exampleText(title, lk, titleRole, 'on-surface', titleWeight));
  block.appendChild(exampleText(line, lk, lineRole, 'on-surface-variant', lineWeight));
  return block;
}

// The popover's panel: a title, a sentence, and the two actions it asks for.
function buildPopoverExample(page: PageNode, lk: VarLookup): ComponentNode {
  // g7-preview-only: the gap between the sample copy and its actions (designer's copy) — the content is the caller's widget.
  const c = mintPanelComp(page, kPopoverExample, 'VERTICAL', lk, { gap: 14 });
  // g7-preview-only: the example's width (designer's copy, 248) — a popover's content sizes itself.
  lockWidth(c, 248);
  // g7-preview-only: title ↔ sentence gap of the sample copy (designer's copy).
  const copy = panel('copy', 'VERTICAL', lk, { gap: 4 });
  c.appendChild(copy);
  copy.layoutSizingHorizontal = 'FILL';
  copy.appendChild(exampleText('알림 설정', lk, 'labelLarge', 'on-surface', 600));
  const body = exampleText('새 댓글과 멘션이 오면 바로 알려 드려요.', lk, 'bodySmall', 'on-surface-variant');
  copy.appendChild(body);
  wrapAcross(body);
  // g7-preview-only: the gap between the two sample actions (designer's copy).
  const actions = panel('actions', 'HORIZONTAL', lk, { gap: 8 });
  actions.primaryAxisAlignItems = 'MAX';
  c.appendChild(actions);
  actions.layoutSizingHorizontal = 'FILL';
  actions.appendChild(exampleButton(page, 'ghost', 'sm', '나중에'));
  actions.appendChild(exampleButton(page, 'primary', 'sm', '알림 켜기'));
  return c;
}

// The hover card's profile: who it is, one line about them, two counts.
function buildHoverCardExample(page: PageNode, lk: VarLookup): ComponentNode {
  // g7-preview-only: the gap between the profile's three blocks (designer's copy).
  const c = mintPanelComp(page, kHoverCardExample, 'VERTICAL', lk, { gap: 12 });
  // g7-preview-only: the example's width (designer's copy, 248); the hover card fills its content to the card.
  lockWidth(c, 248);
  // g7-preview-only: avatar ↔ name gap (designer's copy).
  const who = panel('who', 'HORIZONTAL', lk, { gap: 12 });
  who.counterAxisAlignItems = 'CENTER';
  c.appendChild(who);
  who.appendChild(exampleAvatar(page, 'md', '코'));
  who.appendChild(titledLine(lk, '코코드', 'labelLarge', '@cocode', 'bodyXs', 600));
  const about = exampleText('앱과 웹을 만들고 CoUI를 운영해요.', lk, 'bodySmall', 'on-surface-variant');
  c.appendChild(about);
  wrapAcross(about);
  // g7-preview-only: the gap between the two counts (designer's copy).
  const counts = panel('counts', 'HORIZONTAL', lk, { gap: 16 });
  c.appendChild(counts);
  for (const [figure, unit] of [['48', '프로젝트'], ['12', '팀원']]) {
    // g7-preview-only: figure ↔ unit gap (designer's copy).
    const count = panel('count', 'HORIZONTAL', lk, { gap: 4 });
    counts.appendChild(count);
    count.appendChild(exampleText(figure, lk, 'labelSmall', 'on-surface', 600));
    count.appendChild(exampleText(unit, lk, 'bodyXs', 'on-surface-variant'));
  }
  return c;
}

// The corner of a link row in the dropdown example: `Popup`'s panel corner
// less its list inset, the concentric corner of a row inside a panel.
const kNavigationMenuExampleRowRadius =
  dimVal(COMPONENTS.popup.fields.borderRadius.topLeft) - dimVal(COMPONENTS.popup.constants.listPadding.l);

// The navigation menu's open dropdown: three links, each a title over a line,
// the first under the pointer.
function buildNavigationMenuExample(page: PageNode, lk: VarLookup): ComponentNode {
  // g7-preview-only: the gap between links (designer's copy).
  const c = mintPanelComp(page, kNavigationMenuExample, 'VERTICAL', lk, { gap: 2 });
  // g7-preview-only: the example's width (designer's copy, 248); the dropdown's content is the caller's widget.
  lockWidth(c, 248);
  const links = [
    ['디자인 시스템', 'CoUI 컴포넌트와 토큰'],
    ['앱 개발', 'iOS, Android, Flutter'],
    ['웹 개발', '반응형 웹과 운영 어드민'],
  ];
  for (let i = 0; i < links.length; i++) {
    // The first link is the one under the pointer — the copy washes it in
    // `surface-container`, the hover fill the menu states for its triggers.
    const hovered = i === 0;
    // g7-preview-only: a link row's inset and title ↔ line gap, and the hovered row's wash (designer's copy) — the links are the caller's content.
    const link = panel('link', 'VERTICAL', lk, { gap: 2, pl: 10, pr: 10, pt: 8, pb: 8, bg: hovered ? 'surface-container' : undefined });
    // A row inside a panel takes the panel's corner less its list inset, so
    // the two corners share a centre (`core/design-tokens.md`) — 12 − 6 = 6,
    // read off `Popup` and bound to the radius step (#6473, designer).
    bindRadiusN(link, lk, kNavigationMenuExampleRowRadius);
    c.appendChild(link);
    link.layoutSizingHorizontal = 'FILL';
    link.appendChild(exampleText(links[i][0], lk, 'labelLarge', 'on-surface'));
    link.appendChild(exampleText(links[i][1], lk, 'bodyXs', 'on-surface-variant'));
  }
  return c;
}

// The draggable panel's surface content: an upload in progress — a thumbnail,
// what is uploading, how far along.
function buildDraggablePanelExample(page: PageNode, lk: VarLookup): ComponentNode {
  // g7-preview-only: thumbnail ↔ text gap and the example's top/bottom inset (designer's copy draws a 64 box around 44 of content).
  const c = mintPanelComp(page, kDraggablePanelExample, 'HORIZONTAL', lk, { gap: 12, pt: 10, pb: 10 });
  c.counterAxisAlignItems = 'CENTER';
  // g7-preview-only: the example's width (designer's copy, 222) — the panel fills its width with it.
  lockWidth(c, 222);
  // g7-preview-only: the thumbnail tile — corner and fill of the sample image (designer's copy).
  const thumb = panel('thumbnail', 'HORIZONTAL', lk, { radius: 10, bg: 'surface-container-high' });
  thumb.primaryAxisAlignItems = 'CENTER';
  thumb.counterAxisAlignItems = 'CENTER';
  // g7-preview-only: the thumbnail tile's side (designer's copy).
  bindSize(thumb, lk, 40, 40);
  // g7-preview-only: the sample image glyph (designer's copy draws it at 18, the nearest icon step is 20).
  thumb.appendChild(makeIcon('image', lk, glyphOpts(lk, { color: 'on-surface-variant' }, 20, 'size')));
  c.appendChild(thumb);
  // g7-preview-only: text ↔ bar gap (designer's copy).
  const column = panel('upload', 'VERTICAL', lk, { gap: 6 });
  c.appendChild(column);
  column.layoutSizingHorizontal = 'FILL';
  // The caption reads the bar's own default value (60%), so copy and bar agree (#6473, designer).
  column.appendChild(titledLine(lk, '시안 업로드 중', 'labelMedium', '3개 중 2개 · 60%', 'bodyXs', 600));
  const bar = exampleProgress(page);
  column.appendChild(bar);
  bar.layoutSizingHorizontal = 'FILL';
  return c;
}

// The refresh trigger's scrollable: a short feed of three rows, the first two
// ruled off.
function buildRefreshTriggerExample(page: PageNode, lk: VarLookup): ComponentNode {
  // g7-preview-only: the feed's top rule (designer's copy) — the list is the caller's widget.
  const c = mintPanelComp(page, kRefreshTriggerExample, 'VERTICAL', lk, { bg: 'surface', border: 'outline-variant', strokeSides: { top: true } });
  c.strokeAlign = 'INSIDE';
  // g7-preview-only: the example's width (designer's copy, 280); the feed's height is its rows.
  lockWidth(c, 280);
  const rows: [string, string, string][] = [
    ['디', '디자인 리뷰', '새 댓글 2개'],
    ['배', '배포 알림', 'v2.4.0 배포 완료'],
    ['회', '주간 회의', '오늘 오후 3시'],
  ];
  for (let i = 0; i < rows.length; i++) {
    const ruled = i < rows.length - 1;
    // g7-preview-only: a feed row's inset and gap, and the rule under every row but the last (designer's copy).
    const row = panel('row', 'HORIZONTAL', lk, { gap: 12, pl: 16, pr: 16, pt: 10, pb: 10, border: ruled ? 'outline-variant' : undefined, strokeSides: { bottom: true } });
    row.counterAxisAlignItems = 'CENTER';
    if (ruled) row.strokeAlign = 'INSIDE';
    c.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
    row.appendChild(exampleAvatar(page, 'sm', rows[i][0]));
    const text = titledLine(lk, rows[i][1], 'labelLarge', rows[i][2], 'bodyXs');
    row.appendChild(text);
    text.layoutSizingHorizontal = 'FILL';
  }
  return c;
}

// The device frame's app screen: a greeting, today's progress, recent activity.
// Drawn at the flat phone's screen (240 × 480) and clipped, because the frame
// gives its child the whole safe area — the screen grows with a bigger device
// and is cut at the edge of a smaller one.
function buildMockupDeviceExample(page: PageNode, lk: VarLookup): ComponentNode {
  // g7-preview-only: the screen's inset and section gap (designer's copy) — the screen is the caller's widget.
  const c = mintPanelComp(page, kMockupDeviceExample, 'VERTICAL', lk, { gap: 16, pl: 16, pr: 16, pt: 16, pb: 16, bg: 'surface' });
  // g7-preview-only: the example screen's box (designer's copy, the flat phone's 240 × 480 screen).
  c.resize(240, 480);
  c.primaryAxisSizingMode = 'FIXED';
  c.counterAxisSizingMode = 'FIXED';
  c.clipsContent = true;

  const header = panel('header', 'HORIZONTAL', lk, {});
  header.primaryAxisAlignItems = 'SPACE_BETWEEN';
  header.counterAxisAlignItems = 'CENTER';
  c.appendChild(header);
  header.layoutSizingHorizontal = 'FILL';
  const greeting = panel('greeting', 'VERTICAL', lk, {});
  header.appendChild(greeting);
  greeting.appendChild(exampleText('좋은 아침이에요', lk, 'bodyXs', 'on-surface-variant'));
  greeting.appendChild(exampleText('코코드님', lk, 'titleMedium', 'on-surface'));
  header.appendChild(exampleAvatar(page, 'sm', '코'));

  // g7-preview-only: the summary card's inset, gap, corner and fill (designer's copy).
  const today = panel('today', 'VERTICAL', lk, { gap: 4, pl: 14, pr: 14, pt: 14, pb: 14, radius: 12, bg: 'surface-container' });
  c.appendChild(today);
  today.layoutSizingHorizontal = 'FILL';
  today.appendChild(exampleText('오늘 할 일', lk, 'bodyXs', 'on-surface-variant'));
  today.appendChild(exampleText('3개 남았어요', lk, 'titleSmall', 'on-surface'));
  const bar = exampleProgress(page);
  today.appendChild(bar);
  bar.layoutSizingHorizontal = 'FILL';

  // g7-preview-only: heading ↔ row gap of the activity list (designer's copy).
  const recent = panel('recent', 'VERTICAL', lk, { gap: 4 });
  c.appendChild(recent);
  recent.layoutSizingHorizontal = 'FILL';
  recent.appendChild(exampleText('최근 활동', lk, 'labelMedium', 'on-surface', 600));
  const activity: [string, string][] = [
    ['디자인 리뷰', '새 댓글 2개'],
    ['배포 알림', 'v2.4.0 배포 완료'],
    ['주간 회의', '오늘 오후 3시'],
  ];
  for (const [title, line] of activity) {
    // g7-preview-only: an activity row's gap and inset (designer's copy).
    const row = panel('row', 'HORIZONTAL', lk, { gap: 10, pt: 8, pb: 8 });
    row.counterAxisAlignItems = 'CENTER';
    recent.appendChild(row);
    row.layoutSizingHorizontal = 'FILL';
    // g7-preview-only: the row's app-icon tile — corner and fill (designer's copy).
    const tile = panel('icon', 'HORIZONTAL', lk, { radius: 8, bg: 'surface-container-high' });
    // g7-preview-only: the app-icon tile's side (designer's copy).
    bindSize(tile, lk, 32, 32);
    row.appendChild(tile);
    row.appendChild(titledLine(lk, title, 'labelMedium', line, 'labelXs', undefined, 400));
  }
  return c;
}

export const FIXTURE_BUILDERS: RegistryEntry[] = [
  {
    section: 'Infra',
    name: '.Slot',
    sizing: { width: 'fixed', height: 'fixed', why: '빈 슬롯의 외곽선 — 담을 내용이 없어 자기 상자가 전부이고, 호출부가 슬롯 크기를 정한다(FILL · 고정 상자 · 배율)' },
    fixture: {
      description:
        '빌더 전용 대역 — 계약의 W / W? 슬롯이 비어 있음을 나타낸다. 교체 속성의 ' +
        '기본값이고, 라이브러리에 게시되지 않는다.',
      checkedBy: 'slot fixture drill',
      dataFrom: ['frame'],
    },
    build: buildSlot,
  },
  {
    section: 'Overlay',
    name: '.Example/Popover content',
    fixture: {
      description: 'Popover 의 내용 슬롯 기본 예시 — 알림 설정 패널. 라이브러리에 게시되지 않는다.',
      checkedBy: 'default example drill',
    },
    build: buildPopoverExample,
    needs: ['Button'],
  },
  {
    section: 'Overlay',
    name: '.Example/HoverCard content',
    fixture: {
      description: 'HoverCard 의 내용 슬롯 기본 예시 — 프로필 카드. 라이브러리에 게시되지 않는다.',
      checkedBy: 'default example drill',
    },
    build: buildHoverCardExample,
    needs: ['Avatar'],
  },
  {
    section: 'Navigation',
    name: '.Example/NavigationMenu content',
    fixture: {
      description: 'NavigationMenu 드롭다운의 내용 슬롯 기본 예시 — 링크 세 개. 라이브러리에 게시되지 않는다.',
      checkedBy: 'default example drill',
      dataFrom: ['popup'],
    },
    build: buildNavigationMenuExample,
    needs: [],
  },
  {
    section: 'Overlay',
    name: '.Example/DraggablePanel content',
    fixture: {
      description: 'DraggablePanel 의 Panel 슬롯 기본 예시 — 업로드 진행 미니 패널. 라이브러리에 게시되지 않는다.',
      checkedBy: 'default example drill',
    },
    build: buildDraggablePanelExample,
    needs: ['Icon', 'Progress'],
  },
  {
    section: 'Layout',
    name: '.Example/RefreshTrigger content',
    fixture: {
      description: 'RefreshTrigger 의 Child 슬롯 기본 예시 — 목록 세 행. 라이브러리에 게시되지 않는다.',
      checkedBy: 'default example drill',
    },
    build: buildRefreshTriggerExample,
    needs: ['Avatar'],
  },
  {
    section: 'Display',
    name: '.Example/MockupDevice screen',
    sizing: { height: 'fixed', why: '앱 화면 예시 — 한 기기 화면의 크기로 그리고, MockupDevice 가 FILL 로 각 기기의 안전 영역에 맞춰 늘이거나 자른다' },
    fixture: {
      description: 'MockupDevice 의 Child 슬롯 기본 예시 — 앱 홈 화면. 기기 화면에 맞춰 늘고 넘치면 잘린다. 라이브러리에 게시되지 않는다.',
      checkedBy: 'default example drill',
    },
    build: buildMockupDeviceExample,
    needs: ['Avatar', 'Progress'],
  },
];
