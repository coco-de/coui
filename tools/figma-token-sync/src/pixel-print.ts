/// <reference types="@figma/plugin-typings" />

// 픽셀 지문 — 생성된 컴포넌트가 **렌더된 모습**을 PNG 로 내보내 해시로 남긴다 (#5010).
//
// ## 왜 따로 있나
//
// 이 파이프라인의 다른 캡처는 전부 픽셀을 보지 않는다. 구조 스냅샷은 기하(x/y/w/h)
// 만, 충실도는 `components.json` 이 명시한 값과의 불일치만, 캔버스 지문은 손 편집을
// 가려내려고 파생 기하와 인스턴스 내부를 **일부러** 뺀다. 그래서 "두 실행이 같은
// 그림을 그렸나" 라는 질문 — 섹션을 나눠 그린 합집합이 한 번에 다 그린 것과 같은가
// — 에는 어느 것도 답하지 못한다. `needs` 폐포는 **무엇을** 그릴지를 보장하지
// **어떤 상태에서** 그릴지는 보장하지 않고, 그 차이는 그려 봐야 보인다.
//
// 이 모듈은 그 "그려 봐야" 를 기계적으로 한다: 문서의 생성된 세트 · 컴포넌트마다
// `exportAsync({ format: 'PNG' })` 를 받아 바이트 해시를 적는다. 두 실행 뒤에 한
// 번씩 내려받아 `npm run pixel:diff -- a.json b.json` 으로 견주면 차이가 세트
// 단위로 나온다.
//
// ## 바이트 해시가 픽셀 비교가 되는 조건
//
// 같은 세션 · 같은 렌더러가 같은 트리를 내보내면 PNG 바이트가 같다 — `verify.ts`
// 의 reset 완전성이 이미 이 전제로 새로 만든 노드와 재사용한 노드를 견준다.
// 다른 머신이나 Figma 버전 사이의 비교는 이 전제 밖이다: 차이가 나오면 먼저
// 두 파일의 `figmaSession` 이 같은지 본다.
//
// ## 무엇을 싣나
//
// 페이지 최상위의 COMPONENT · COMPONENT_SET 중 **이 플러그인이 그린 것**
// (`kHashDataKey` 가 있는 것)만. 디자이너 사본은 FRAME 이라 애초에 대상이 아니고,
// 손으로 만든 컴포넌트는 두 실행이 건드리지 않으니 비교할 이유가 없다.
//
// 한 변이 `kMaxWholeExportPx` 를 넘는 세트는 통째로 내보내지 않고 멤버마다
// 내보낸다 — 거대한 한 장은 느리고, 달라졌을 때 어느 변형인지 말하지 못한다.

import { kHashDataKey } from './content-hash';

export const PIXEL_PRINT_SCHEMA = 1;
export const CAPTURED_BY_PIXEL_PRINT = 'figma-plugin:pixel-print';

/** 이보다 큰 변이 있으면 세트를 멤버 단위로 내보낸다. */
export const kMaxWholeExportPx = 4096;

/** 내보낸 한 장. `key` 는 세트를 통째로 내보냈으면 `''`, 멤버면 그 변형 이름. */
export interface PixelPart {
  key: string;
  w: number;
  h: number;
  bytes: number;
  hash: string;
}

export interface PixelEntry {
  page: string;
  name: string;
  type: 'COMPONENT' | 'COMPONENT_SET';
  id: string;
  /** 통째로 내보냈으면 한 장, 멤버 단위면 멤버 수만큼. */
  parts: PixelPart[];
  /** 이 엔트리를 내보내는 데 든 밀리초 — 비교 대상이 아니라 참고용. */
  ms: number;
}

export interface PixelPrintDoc {
  schema: number;
  capturedBy: string;
  capturedAt: string;
  fileKey: string | null;
  /** 이 지문을 만든 플러그인 소스 해시 — 두 파일이 같은 번들에서 나왔는지. */
  sourceHash: string;
  entries: PixelEntry[];
}

/**
 * 바이트 배열의 64비트 해시 — FNV-1a 32비트 두 벌(서로 다른 시드)을 이어 붙인다.
 * 보안용이 아니라 변경 감지용이다. 길이를 앞에 붙여 길이만 다른 두 이미지가
 * 같은 해시로 접히지 않게 한다.
 */
export function hashBytes(bytes: Uint8Array): string {
  let a = 0x811c9dc5;
  let b = 0x01000193 ^ bytes.length;
  for (let i = 0; i < bytes.length; i++) {
    a ^= bytes[i];
    a = Math.imul(a, 0x01000193);
    b ^= bytes[i];
    b = Math.imul(b, 0x5bd1e995);
    b ^= b >>> 13;
  }
  const hex = (n: number): string => (n >>> 0).toString(16).padStart(8, '0');
  return `${bytes.length.toString(16)}:${hex(a)}${hex(b)}`;
}

/** 세트를 한 장이 아니라 멤버 단위로 내보낼지. */
export function exportsPerMember(type: PixelEntry['type'], w: number, h: number): boolean {
  return type === 'COMPONENT_SET' && (w > kMaxWholeExportPx || h > kMaxWholeExportPx);
}

/** 엔트리 한 줄에 하나 — 두 파일의 `git diff` 가 "바뀐 세트 = 바뀐 줄" 로 읽힌다. */
export function serialisePixelPrint(doc: PixelPrintDoc): string {
  const head = {
    schema: doc.schema,
    capturedBy: doc.capturedBy,
    capturedAt: doc.capturedAt,
    fileKey: doc.fileKey,
    sourceHash: doc.sourceHash,
  };
  const headJson = JSON.stringify(head);
  const lines = doc.entries.map((e) => `    ${JSON.stringify(e)}`);
  return (
    `${headJson.slice(0, -1)},\n  "entries": [\n` + lines.join(',\n') + (lines.length ? '\n' : '') + '  ]\n}\n'
  );
}

export function parsePixelPrint(text: string): PixelPrintDoc {
  const doc = JSON.parse(text) as PixelPrintDoc;
  if (doc.schema !== PIXEL_PRINT_SCHEMA || doc.capturedBy !== CAPTURED_BY_PIXEL_PRINT) {
    throw new Error(
      `픽셀 지문 파일이 아니거나 schema 가 다르다 (schema ${String(doc.schema)}, capturedBy ${String(doc.capturedBy)})`,
    );
  }
  return doc;
}

/** 두 지문의 차이 한 건. */
export interface PixelDiff {
  kind: 'only-a' | 'only-b' | 'split-changed' | 'size' | 'pixels';
  /** `페이지 / 이름` 또는 `페이지 / 이름 / 변형`. */
  where: string;
  detail: string;
}

function entryKey(e: PixelEntry): string {
  return `${e.page} / ${e.name}`;
}

/**
 * 두 지문을 페이지 · 이름으로 짝지어 견준다. id 가 아니라 이름인 이유: 두 실행
 * 사이에 세트가 다시 만들어졌다면 id 는 바뀌어도 그림은 같을 수 있고, 이 비교가
 * 묻는 것은 그림이다(id 안정성은 identity 멱등 검사의 몫이다).
 */
export function diffPixelPrints(a: PixelPrintDoc, b: PixelPrintDoc): PixelDiff[] {
  const out: PixelDiff[] = [];
  const byKey = (doc: PixelPrintDoc): Map<string, PixelEntry> => {
    const m = new Map<string, PixelEntry>();
    for (const e of doc.entries) m.set(entryKey(e), e);
    return m;
  };
  const am = byKey(a);
  const bm = byKey(b);
  for (const [key, ea] of Array.from(am.entries())) {
    const eb = bm.get(key);
    if (!eb) {
      out.push({ kind: 'only-a', where: key, detail: `${ea.type} — B 에 없다` });
      continue;
    }
    const aWhole = ea.parts.length === 1 && ea.parts[0].key === '';
    const bWhole = eb.parts.length === 1 && eb.parts[0].key === '';
    if (aWhole !== bWhole) {
      out.push({
        kind: 'split-changed',
        where: key,
        detail: `A 는 ${aWhole ? '통째' : `멤버 ${ea.parts.length}장`}, B 는 ${bWhole ? '통째' : `멤버 ${eb.parts.length}장`} — 크기가 경계를 넘었다`,
      });
      continue;
    }
    const bParts = new Map<string, PixelPart>();
    for (const p of eb.parts) bParts.set(p.key, p);
    const seen = new Set<string>();
    for (const pa of ea.parts) {
      seen.add(pa.key);
      const where = pa.key ? `${key} / ${pa.key}` : key;
      const pb = bParts.get(pa.key);
      if (!pb) {
        out.push({ kind: 'only-a', where, detail: '변형이 B 에 없다' });
      } else if (pa.w !== pb.w || pa.h !== pb.h) {
        out.push({ kind: 'size', where, detail: `${pa.w}×${pa.h} → ${pb.w}×${pb.h}` });
      } else if (pa.hash !== pb.hash) {
        out.push({ kind: 'pixels', where, detail: `같은 ${pa.w}×${pa.h}, 픽셀 다름 (${pa.hash} → ${pb.hash})` });
      }
    }
    for (const pb of eb.parts) {
      if (!seen.has(pb.key)) out.push({ kind: 'only-b', where: `${key} / ${pb.key}`, detail: '변형이 A 에 없다' });
    }
  }
  for (const [key, eb] of Array.from(bm.entries())) {
    if (!am.has(key)) out.push({ kind: 'only-b', where: key, detail: `${eb.type} — A 에 없다` });
  }
  return out;
}

/** 사람이 읽는 리포트. 첫 줄이 판정이다. */
export function formatPixelDiff(a: PixelPrintDoc, b: PixelPrintDoc, diffs: readonly PixelDiff[]): string[] {
  const parts = (d: PixelPrintDoc): number => d.entries.reduce((n, e) => n + e.parts.length, 0);
  const lines: string[] = [];
  lines.push(
    diffs.length === 0
      ? `✓ 픽셀 동일 — 엔트리 ${a.entries.length}개 · 이미지 ${parts(a)}장`
      : `✗ 차이 ${diffs.length}건 — A 엔트리 ${a.entries.length}개 · B 엔트리 ${b.entries.length}개`,
  );
  lines.push(`  A: ${a.capturedAt} · source ${a.sourceHash}`);
  lines.push(`  B: ${b.capturedAt} · source ${b.sourceHash}`);
  if (a.sourceHash !== b.sourceHash) {
    lines.push('  ⚠ 두 파일의 플러그인 소스 해시가 다르다 — 다른 번들로 그린 것을 견주고 있다');
  }
  for (const d of diffs) lines.push(`  ${d.kind.padEnd(13)} ${d.where} — ${d.detail}`);
  return lines;
}

/** 캔버스 전체를 걷는다. 이 모듈에서 Figma 를 만지는 유일한 함수다. */
export async function capturePixelPrint(
  sourceHash: string,
  onProgress?: (done: number, total: number, name: string) => void,
): Promise<{ doc: PixelPrintDoc; log: string[] }> {
  const capturedAt = new Date().toISOString();
  const targets: { page: PageNode; node: ComponentNode | ComponentSetNode }[] = [];
  for (const page of figma.root.children) {
    await page.loadAsync();
    for (const node of page.children) {
      if (node.type !== 'COMPONENT' && node.type !== 'COMPONENT_SET') continue;
      if (node.getPluginData(kHashDataKey) === '') continue;
      targets.push({ page, node });
    }
  }
  const entries: PixelEntry[] = [];
  const startedAt = Date.now();
  let images = 0;
  for (let i = 0; i < targets.length; i++) {
    const { page, node } = targets[i];
    onProgress?.(i, targets.length, node.name);
    const t0 = Date.now();
    const parts: PixelPart[] = [];
    const members: SceneNode[] = exportsPerMember(node.type, node.width, node.height)
      ? node.children.slice()
      : [node];
    for (const m of members) {
      const png = await m.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: 1 } });
      parts.push({
        key: m === node ? '' : m.name,
        w: Math.round(m.width),
        h: Math.round(m.height),
        bytes: png.length,
        hash: hashBytes(png),
      });
      images += 1;
    }
    entries.push({ page: page.name, name: node.name, type: node.type, id: node.id, parts, ms: Date.now() - t0 });
  }
  onProgress?.(targets.length, targets.length, '');
  const doc: PixelPrintDoc = {
    schema: PIXEL_PRINT_SCHEMA,
    capturedBy: CAPTURED_BY_PIXEL_PRINT,
    capturedAt,
    fileKey: typeof figma.fileKey === 'string' ? figma.fileKey : null,
    sourceHash,
    entries,
  };
  const slowest = entries
    .slice()
    .sort((x, y) => y.ms - x.ms)
    .slice(0, 3)
    .map((e) => `${e.name} ${(e.ms / 1000).toFixed(1)}s`)
    .join(' · ');
  return {
    doc,
    log: [
      `✓ 픽셀 지문: 엔트리 ${entries.length}개 · 이미지 ${images}장 · ${((Date.now() - startedAt) / 1000).toFixed(1)}s (${capturedAt})`,
      `  가장 느린 것: ${slowest || '—'}`,
      '  두 파일을 `npm run pixel:diff -- <A.json> <B.json>` 으로 견준다.',
    ],
  };
}
