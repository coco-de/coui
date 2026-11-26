/// <reference types="@figma/plugin-typings" />

// #6214 — `_Docs / Examples` 의 상태 예시 블록: 세트에 상태 멤버가 없는 컴포넌트가
// hover · pressed 때 무엇을 그리는지 캔버스에 보이는 자리.
//
// ─── 왜 세트가 아니라 예시인가 ────────────────────────────────────────────
//
// Banner 와 Toast 는 상태 축이 없다. 둘이 담는 버튼의 hover · pressed 표시는 버튼
// 자신의 상태이고, 그 값은 부모가 버튼에 넘기는 `CoreButtonStyle.stateLayer` 다
// (Banner · Toast 의 `actionButtonStyle` · Banner 의 `closeButtonStyle`). 세트에
// 상태 축을 더하면 코드에 없는 축이 캔버스에 생기고(구조 변경), 인스턴스의 버튼 State
// 만 바꾸면 버튼 세트 자기 변형의 값이 나온다 — `plain` 에는 상태 레이어가 없고,
// 부모가 덮어쓴 글자색도 풀린다. 그래서 부모가 넘기는 값으로 그린 그림을 문서 블록에
// 따로 둔다.
//
// ─── 왜 버튼 위에 얹은 형제 레이어인가 ────────────────────────────────────
//
// 코드는 막을 버튼의 채움 자리, 글자 아래에 칠한다. 캔버스에서는 그 자리에 닿을 수
// 없다: 인스턴스 안에는 자식을 넣을 수 없고, 버튼 인스턴스의 채움을 변수에 묶으면
// Figma 가 칠의 알파를 변수의 1 로 덮어 3% 가 불투명한 면이 된다(`paint.ts` 의
// `solid` 실측). 그래서 막은 예시 무대 위, 버튼과 같은 자리 같은 모서리에 얹은
// 직사각형이고, 세기는 그 레이어의 불투명도다. 막의 색이 버튼의 글자색과 같으므로
// 글자 위에 얹어도 글자 픽셀은 그대로다 — 같은 색을 같은 색 위에 섞으면 같은 색이다.
//
// 값은 전부 export 에서 읽는다: 막의 세기는 `stateLayer`, 색은 변형 행의
// 글자색 · 아이콘색, Toast 닫기 버튼의 쉬는 · hover 세기는 변형 행의
// `closeForeground` · `closeHoverForeground` 다.

import { COMPONENTS } from './data';
import { Color, colorData } from './compat/v1';
import { VarLookup, autoFrame, makeLabel } from './helpers';
import { applyForwardedButtonStyle } from './instance-reach';
import { fillDataOnNode } from './paint';
import { bestVariantName } from './component-props';
import { mainComponentIdOf } from './identity';
import { parseVariantKey } from './variant-safety';

const BANNER = COMPONENTS.banner;
const TOAST = COMPONENTS.toast;

/** 블록 이름. 드릴과 대조가 같은 이름을 읽는다. */
export const kStateExamplesBlockName = 'Block / 상태 예시';

/** 예시 무대 위에 얹는 막의 이름 — 버튼 세트가 자기 멤버에 쓰는 이름과 같다. */
export const kStateExampleLayerName = 'state layer';

interface Ramp {
  hover: number;
  focus: number;
  pressed: number;
}

type Pose = 'enabled' | 'hover' | 'pressed';

export interface StateExamplesResult {
  block: FrameNode;
  /** 그린 무대 수 — 드릴이 세는 값. */
  cellCount: number;
}

/**
 * `name` 세트의 상태 예시 블록. 상태 예시를 그리는 세트가 아니거나 세트가 페이지에
 * 없으면 `null` — docs 드릴처럼 빈 페이지에서 부르는 자리는 블록 없이 지나간다.
 */
export function renderStateExamples(
  page: PageNode,
  lk: VarLookup,
  name: string,
): StateExamplesResult | null {
  const draw = kDrawers[name];
  if (draw === undefined) return null;
  const set = page.children.find(
    (n): n is ComponentSetNode => n.type === 'COMPONENT_SET' && n.name === name,
  );
  if (set === undefined) return null;
  return draw(page, lk, set);
}

const kDrawers: Record<
  string,
  (page: PageNode, lk: VarLookup, set: ComponentSetNode) => StateExamplesResult
> = {
  Banner: drawBannerStates,
  Toast: drawToastStates,
};

// ─── Banner ──────────────────────────────────────────────────────────────────

function drawBannerStates(
  _page: PageNode,
  lk: VarLookup,
  set: ComponentSetNode,
): StateExamplesResult {
  const actionRamp = BANNER.fields.actionButtonStyle.stateLayer as Ramp;
  const closeRamp = BANNER.fields.closeButtonStyle.stateLayer as Ramp;
  const rows = new Map(Object.entries(BANNER.variants.defaultsByVariant));
  const block = blockFrame(
    lk,
    '상태 예시 — 액션 · 닫기 버튼 (enabled · hover · pressed)',
    `막 = 버튼 글자색 · hover ${pct(actionRamp.hover)} · pressed ${pct(actionRamp.pressed)}. ` +
      '글자색은 상태와 무관하게 그대로다. 두 버튼에 같은 값을 각각 얹어 그렸다.',
  );
  let cellCount = 0;
  for (const member of membersOf(set)) {
    const combo = parseVariantKey(member.name);
    const row = rows.get(`${combo['Variant']}/${combo['Style']}`);
    if (row === undefined) continue;
    const text = colorData(row.textColor as Color);
    const icon = colorData(row.iconColor as Color);
    const line = poseRow(lk, `${combo['Variant']} · ${combo['Style']}`);
    for (const pose of ['enabled', 'hover', 'pressed'] as const) {
      const stage = stageOf(member, `${combo['Variant']} · ${combo['Style']} · ${pose}`);
      const inst = stage.children[0] as InstanceNode;
      if (pose !== 'enabled') {
        washButton(stage, lk, buttonIn(inst, 'action'), text, weightOf(actionRamp, pose), pose);
        washButton(stage, lk, buttonIn(inst, 'dismiss'), icon, weightOf(closeRamp, pose), pose);
      }
      line.appendChild(captioned(lk, pose, stage));
      cellCount++;
    }
    block.appendChild(line);
  }
  return { block, cellCount };
}

// ─── Toast ───────────────────────────────────────────────────────────────────

// 쉬는 상태 · 액션 hover · 액션 pressed · 닫기 hover. 닫기 버튼은 상태 레이어가 없고
// (이 이슈가 바꾸지 않았다) 쉴 때 글자색의 70% 에서 hover 에 100% 로 오른다.
type ToastPose = 'rest' | 'action hover' | 'action pressed' | 'close hover';

function drawToastStates(
  page: PageNode,
  lk: VarLookup,
  set: ComponentSetNode,
): StateExamplesResult {
  const ramp = TOAST.fields.actionButtonStyle.stateLayer as Ramp;
  const rows = new Map(Object.entries(TOAST.variants.defaultsByVariant));
  // 액션 자리에 넣는 버튼 — 이슈가 다루는 `plain`. Toast 가 크기를 말하지 않으므로
  // 버튼 자신의 기본 크기다.
  const plain = bestVariantName(page, 'Button', { Variant: 'plain' });
  const plainId = plain === undefined ? null : mainComponentIdOf(page, 'Button', plain);
  const resting = rows.get(TOAST.axes.variant.default);
  const restPct = pct(colorData(resting?.closeForeground as Color)?.opacity ?? 1);
  const hoverPct = pct(colorData(resting?.closeHoverForeground as Color)?.opacity ?? 1);
  const block = blockFrame(
    lk,
    '상태 예시 — 액션 · 닫기 버튼',
    `액션: 막 = 버튼 글자색 · hover ${pct(ramp.hover)} · pressed ${pct(ramp.pressed)}, 글자색은 그대로. ` +
      `닫기: 상태 레이어 없음, 쉴 때 글자색의 ${restPct} → hover ${hoverPct}.`,
  );
  let cellCount = 0;
  for (const member of membersOf(set)) {
    const combo = parseVariantKey(member.name);
    if (combo['Dismissible'] !== 'true') continue;
    const row = rows.get(combo['Variant']);
    if (row === undefined) continue;
    const ink = colorData(row.foregroundColor as Color);
    const closeRest = colorData(row.closeForeground as Color);
    const closeHover = colorData(row.closeHoverForeground as Color);
    const line = poseRow(lk, combo['Variant']);
    const poses: ToastPose[] = ['rest', 'action hover', 'action pressed', 'close hover'];
    for (const pose of poses) {
      const stage = stageOf(member, `${combo['Variant']} · ${pose}`);
      const inst = stage.children[0] as InstanceNode;
      const action = showAction(inst, plainId);
      if (action !== null && ink !== null) {
        // The example's action is `plain`, so it wears the Toast's plain inset
        // (`plainActionButtonStyle` states 6 a side so the wash is not exactly
        // the word wide), forwarded the way the widget forwards it.
        applyForwardedButtonStyle(action, lk, {
          foregroundColor: ink,
          padding: TOAST.fields.plainActionButtonStyle.padding,
        });
      }
      fitStage(stage);
      if (action !== null && (pose === 'action hover' || pose === 'action pressed')) {
        washButton(
          stage,
          lk,
          action,
          ink,
          pose === 'action hover' ? ramp.hover : ramp.pressed,
          pose === 'action hover' ? 'hover' : 'pressed',
        );
      }
      const glyph = closeGlyphIn(inst);
      const strength = (pose === 'close hover' ? closeHover : closeRest)?.opacity ?? 1;
      if (glyph !== null) (glyph as SceneNode & BlendMixin).opacity = strength;
      line.appendChild(captioned(lk, pose, stage));
      cellCount++;
    }
    block.appendChild(line);
  }
  return { block, cellCount };
}

// 예시 인스턴스의 `Show action` 을 켜고 `Action` 을 버튼으로 바꾼다. 바꾼 버튼
// 인스턴스를 돌려준다 — 속성을 찾지 못하면 `null`(세트가 그 속성을 잃은 날).
function showAction(inst: InstanceNode, buttonId: string | null): InstanceNode | null {
  const props = inst.componentProperties;
  const patch: Record<string, string | boolean> = {};
  for (const key of Object.keys(props)) {
    if (key.startsWith('Show action#')) patch[key] = true;
    if (key.startsWith('Action#') && buttonId !== null) patch[key] = buttonId;
  }
  if (Object.keys(patch).length === 0) return null;
  inst.setProperties(patch);
  return buttonIn(inst, 'action');
}

function closeGlyphIn(inst: InstanceNode): SceneNode | null {
  const host = (firstIn(inst, (n) => n.type === 'FRAME' && n.name === 'close') as FrameNode | null);
  if (host === null) return null;
  // 직사각 버튼이면 `closeButton` 이 버튼 뒤에 글리프를 얹는다 — 마지막 자식이 글리프다.
  if (host.children.length >= 2) return host.children[host.children.length - 1];
  // 정사각 버튼(Toast 닫기, #6214)은 글리프를 버튼 자신의 `leading` 칸에 넣는다.
  const button = firstIn(host, (n) => n.type === 'INSTANCE') as InstanceNode | null;
  const leading = button === null ? null : (firstIn(button, (n) => n.type === 'FRAME' && n.name === 'leading') as FrameNode | null);
  return leading === null ? null : firstIn(leading, (n) => n.type === 'INSTANCE');
}

// ─── 공통 ────────────────────────────────────────────────────────────────────

function membersOf(set: ComponentSetNode): ComponentNode[] {
  return set.children.filter((c): c is ComponentNode => c.type === 'COMPONENT');
}

function weightOf(ramp: Ramp, pose: Pose): number {
  return pose === 'pressed' ? ramp.pressed : ramp.hover;
}

function pct(weight: number): string {
  return `${Math.round(weight * 100)}%`;
}

// 슬롯 holder(`name`) 안의 첫 인스턴스 — 슬롯이 담은 버튼.
function buttonIn(inst: InstanceNode, holder: string): InstanceNode | null {
  const frame = firstIn(inst, (n) => n.type === 'FRAME' && n.name === holder) as FrameNode | null;
  if (frame === null) return null;
  return firstIn(frame, (n) => n.type === 'INSTANCE') as InstanceNode | null;
}

// `findAll` 의 첫 결과 — 하네스의 대역이 `findOne` 을 갖지 않는다.
function firstIn(root: ChildrenMixin, p: (n: SceneNode) => boolean): SceneNode | null {
  return root.findAll(p)[0] ?? null;
}

// 인스턴스 하나를 담은 무대 — 자리 계산을 좌표로 하려고 레이아웃이 없다.
function stageOf(member: ComponentNode, name: string): FrameNode {
  const stage = figma.createFrame();
  stage.name = name;
  stage.layoutMode = 'NONE';
  stage.fills = [];
  stage.clipsContent = false;
  const inst = member.createInstance();
  stage.appendChild(inst);
  inst.x = 0;
  inst.y = 0;
  fitStage(stage);
  return stage;
}

function fitStage(stage: FrameNode): void {
  const inst = stage.children[0];
  stage.resize(Math.max(inst.width, 1), Math.max(inst.height, 1));
}

// `node` 의 자리를 `stage` 기준으로 — 부모를 따라 올라가며 더한다.
function offsetIn(stage: FrameNode, node: SceneNode): { x: number; y: number } {
  let x = 0;
  let y = 0;
  let cur: BaseNode | null = node;
  while (cur !== null && cur !== stage && 'x' in cur) {
    x += (cur as SceneNode).x;
    y += (cur as SceneNode).y;
    cur = cur.parent;
  }
  return { x, y };
}

function washButton(
  stage: FrameNode,
  lk: VarLookup,
  button: InstanceNode | null,
  ink: ReturnType<typeof colorData>,
  weight: number,
  role: 'hover' | 'pressed',
): void {
  if (button === null || ink === null || ink.color == null) return;
  const at = offsetIn(stage, button);
  const layer = figma.createRectangle();
  layer.name = kStateExampleLayerName;
  layer.resize(Math.max(button.width, 1), Math.max(button.height, 1));
  layer.cornerRadius =
    typeof button.cornerRadius === 'number' ? button.cornerRadius : button.topLeftRadius;
  stage.appendChild(layer);
  layer.x = at.x;
  layer.y = at.y;
  // 글자색 토큰을 그대로 묶고 세기는 레이어의 불투명도로 — 버튼 세트의 상태 레이어와
  // 같은 배치다.
  fillDataOnNode(layer, lk, { ...ink, opacity: weight });
  bindStateOpacity(layer, lk, weight, role);
}

// The layer's strength is a STATE, so it binds to the semantic role
// (`Semantic/ Effect` › `opacity/hover` · `opacity/pressed`), not to the
// primitive rung that happens to hold the same number: the `subtle` ramp is
// `CoreOpacity.hover` / `.pressed` by definition, and a binding to `opacity/3`
// would stay at 3 when the role's value moves. The role is used only when it
// resolves to the weight the code states — a role whose value has drifted from
// the ramp keeps the primitive binding `fillDataOnNode` wrote, so the picture is
// never wrong to keep a name right.
function bindStateOpacity(
  layer: RectangleNode,
  lk: VarLookup,
  weight: number,
  role: 'hover' | 'pressed',
): void {
  const semantic = lk.stateOpacityOrNull(role);
  if (semantic === undefined) return;
  layer.setBoundVariable('opacity', semantic);
  if (Math.abs(layer.opacity - weight) <= 1e-3) return;
  // The role reads another number: back to the rung (or the literal) the
  // weight names.
  const rung = lk.opacityOrNull(weight);
  layer.setBoundVariable('opacity', rung ?? null);
  layer.opacity = weight;
}

function blockFrame(lk: VarLookup, title: string, note: string): FrameNode {
  const f = autoFrame(kStateExamplesBlockName, 'VERTICAL');
  f.setBoundVariable('itemSpacing', lk.space(12));
  f.appendChild(
    makeLabel(title, lk, { size: 12, colorVar: lk.sem('on-surface-variant'), style: 'SemiBold' }),
  );
  f.appendChild(makeLabel(note, lk, { size: 12, colorVar: lk.sem('on-surface-variant') }));
  return f;
}

function poseRow(lk: VarLookup, name: string): FrameNode {
  const r = autoFrame(`Row / ${name}`, 'HORIZONTAL');
  r.counterAxisAlignItems = 'MIN';
  r.setBoundVariable('itemSpacing', lk.space(16));
  return r;
}

function captioned(lk: VarLookup, caption: string, stage: FrameNode): FrameNode {
  const cell = autoFrame(`Cell / ${stage.name}`, 'VERTICAL');
  cell.setBoundVariable('itemSpacing', lk.space(4));
  cell.appendChild(makeLabel(caption, lk, { size: 12, colorVar: lk.sem('on-surface-variant') }));
  cell.appendChild(stage);
  return cell;
}
