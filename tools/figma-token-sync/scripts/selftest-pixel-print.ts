// 픽셀 지문(#5010)의 순수한 절반 — 해시 · 분할 경계 · 직렬화 왕복 · 대조 · 리포트 —
// 과 `pixel:diff` CLI 의 종료 코드를 캔버스 없이 고정한다. 캔버스를 걷는
// `capturePixelPrint` 는 Figma 안에서만 돈다.
//
// 대조가 "차이 0" 을 말하는 것이 이 도구의 결론이므로, 결론을 뒤집는 케이스마다
// 그 케이스만 걸리는 픽스처를 세운다 — 조용히 0 을 내는 differ 는 없는 differ 보다
// 나쁘다.

import {
  CAPTURED_BY_PIXEL_PRINT,
  PIXEL_PRINT_SCHEMA,
  PixelEntry,
  PixelPrintDoc,
  diffPixelPrints,
  exportsPerMember,
  formatPixelDiff,
  hashBytes,
  kMaxWholeExportPx,
  parsePixelPrint,
  serialisePixelPrint,
} from '../src/pixel-print';

declare const process: { cwd(): string; exit(code: number): never };
declare function require(id: string): unknown;

const { spawnSync } = require('child_process') as {
  spawnSync(cmd: string, args: string[], opts: { encoding: 'utf8'; cwd: string }): {
    status: number | null;
    stdout: string;
    stderr: string;
  };
};
const { mkdtempSync, writeFileSync } = require('fs') as {
  mkdtempSync(prefix: string): string;
  writeFileSync(p: string, data: string, enc: string): void;
};
const { join } = require('path') as { join(...parts: string[]): string };
const { tmpdir } = require('os') as { tmpdir(): string };

let failures = 0;
function check(label: string, cond: boolean, detail?: string): void {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    failures++;
    console.error(`  ✗ ${label}${detail ? ` — ${detail}` : ''}`);
  }
}

function doc(entries: PixelEntry[], sourceHash = 'abc'): PixelPrintDoc {
  return {
    schema: PIXEL_PRINT_SCHEMA,
    capturedBy: CAPTURED_BY_PIXEL_PRINT,
    capturedAt: '2026-09-28T05:00:00.000Z',
    fileKey: null,
    sourceHash,
    entries,
  };
}
function whole(name: string, hash: string, w = 100, h = 40): PixelEntry {
  return { page: `❖ ${name}`, name, type: 'COMPONENT_SET', id: '1:1', parts: [{ key: '', w, h, bytes: 10, hash }], ms: 5 };
}

console.log('hashBytes — deterministic, sensitive to one byte and to length');
{
  const x = new Uint8Array([1, 2, 3, 4]);
  check('same bytes → same hash', hashBytes(x) === hashBytes(new Uint8Array([1, 2, 3, 4])));
  check('one byte flipped → different hash', hashBytes(x) !== hashBytes(new Uint8Array([1, 2, 3, 5])));
  check('trailing zero → different hash', hashBytes(x) !== hashBytes(new Uint8Array([1, 2, 3, 4, 0])));
  check('empty is a hash too', /^0:[0-9a-f]{16}$/.test(hashBytes(new Uint8Array(0))), hashBytes(new Uint8Array(0)));
}

console.log('exportsPerMember — only a set past the edge is cut into members');
{
  check('a set within the edge exports whole', !exportsPerMember('COMPONENT_SET', kMaxWholeExportPx, kMaxWholeExportPx));
  check('a set one pixel past exports per member', exportsPerMember('COMPONENT_SET', kMaxWholeExportPx + 1, 10));
  check('a component is never cut', !exportsPerMember('COMPONENT', kMaxWholeExportPx * 2, 10));
}

console.log('serialise → parse round-trips, and parse refuses what is not a pixel print');
{
  const d = doc([whole('Badge', 'h1'), { ...whole('Button', 'x'), parts: [
    { key: 'Size=sm', w: 60, h: 28, bytes: 9, hash: 'a' },
    { key: 'Size=md', w: 72, h: 32, bytes: 9, hash: 'b' },
  ] }]);
  const text = serialisePixelPrint(d);
  check('round trip', JSON.stringify(parsePixelPrint(text)) === JSON.stringify(d), text);
  check('one line per entry', text.split('\n').filter((l) => l.startsWith('    {')).length === 2, text);
  check('an empty print is still valid JSON', parsePixelPrint(serialisePixelPrint(doc([]))).entries.length === 0);
  let refused = '';
  try {
    parsePixelPrint(JSON.stringify({ ...d, capturedBy: 'figma-plugin:structure-snapshot' }));
  } catch (e) {
    refused = String(e);
  }
  check('a structure snapshot is refused', refused.indexOf('픽셀 지문 파일이 아니') >= 0, refused);
}

console.log('diffPixelPrints — zero only when every image matches');
{
  const a = doc([whole('Badge', 'h1'), whole('Chip', 'h2')]);
  check('identical → no diffs', diffPixelPrints(a, a).length === 0);
  const px = diffPixelPrints(a, doc([whole('Badge', 'h1'), whole('Chip', 'h9')]));
  check('one image differs → one pixels diff naming the set', px.length === 1 && px[0].kind === 'pixels' && px[0].where === '❖ Chip / Chip', JSON.stringify(px));
  const size = diffPixelPrints(a, doc([whole('Badge', 'h1'), whole('Chip', 'h2', 101, 40)]));
  check('a size change is reported as size, not pixels', size.length === 1 && size[0].kind === 'size', JSON.stringify(size));
  const gone = diffPixelPrints(a, doc([whole('Badge', 'h1')]));
  check('a set missing from B', gone.length === 1 && gone[0].kind === 'only-a', JSON.stringify(gone));
  const extra = diffPixelPrints(doc([whole('Badge', 'h1')]), a);
  check('a set only in B', extra.length === 1 && extra[0].kind === 'only-b', JSON.stringify(extra));
  const moved = diffPixelPrints(a, doc([{ ...whole('Badge', 'h1'), page: '❖ Other' }, whole('Chip', 'h2')]));
  check('the same set on another page is not the same entry', moved.length === 2, JSON.stringify(moved));
  const idOnly = diffPixelPrints(a, doc([{ ...whole('Badge', 'h1'), id: '9:9' }, whole('Chip', 'h2')]));
  check('a new id with the same picture is not a difference', idOnly.length === 0, JSON.stringify(idOnly));

  const members = (hashes: string[]): PixelEntry => ({
    ...whole('Button', ''),
    parts: hashes.map((hash, i) => ({ key: `Size=${i}`, w: 60, h: 28, bytes: 9, hash })),
  });
  const m = diffPixelPrints(doc([members(['a', 'b', 'c'])]), doc([members(['a', 'x', 'c'])]));
  check('per-member: the one variant that differs is named', m.length === 1 && m[0].where === '❖ Button / Button / Size=1', JSON.stringify(m));
  const lost = diffPixelPrints(doc([members(['a', 'b', 'c'])]), doc([members(['a', 'b'])]));
  check('per-member: a variant missing from B', lost.length === 1 && lost[0].kind === 'only-a', JSON.stringify(lost));
  const split = diffPixelPrints(doc([whole('Button', 'h')]), doc([members(['a'])]));
  check('whole in A, per-member in B → split-changed, not a pile of variants', split.length === 1 && split[0].kind === 'split-changed', JSON.stringify(split));
}

console.log('formatPixelDiff — the verdict is the first line, and a bundle mismatch is called out');
{
  const a = doc([whole('Badge', 'h1')]);
  check('no diffs → ✓ first', formatPixelDiff(a, a, [])[0].startsWith('✓ 픽셀 동일'));
  const b = doc([whole('Badge', 'h2')], 'def');
  const lines = formatPixelDiff(a, b, diffPixelPrints(a, b));
  check('diffs → ✗ first', lines[0].startsWith('✗ 차이 1건'), lines.join('\n'));
  check('different source hash is warned', lines.some((l) => l.indexOf('소스 해시가 다르다') >= 0), lines.join('\n'));
}

console.log('pixel:diff CLI — exit 0 same · 1 different · 2 bad input');
{
  const dir = mkdtempSync(join(tmpdir(), 'pixel-print-'));
  const write = (name: string, body: string): string => {
    const p = join(dir, name);
    writeFileSync(p, body, 'utf8');
    return p;
  };
  const a = write('a.json', serialisePixelPrint(doc([whole('Badge', 'h1')])));
  const same = write('same.json', serialisePixelPrint(doc([whole('Badge', 'h1')])));
  const diff = write('diff.json', serialisePixelPrint(doc([whole('Badge', 'h2')])));
  const bad = write('bad.json', '{"schema":1,"capturedBy":"nope","entries":[]}');
  const run = (...args: string[]) =>
    spawnSync('npx', ['tsx', 'scripts/diff-pixel-print.ts', ...args], { encoding: 'utf8', cwd: process.cwd() });
  const r0 = run(a, same);
  check('same → 0', r0.status === 0 && r0.stdout.indexOf('✓ 픽셀 동일') >= 0, `${r0.status} ${r0.stdout}${r0.stderr}`);
  const r1 = run(a, diff);
  check('different → 1', r1.status === 1 && r1.stdout.indexOf('pixels') >= 0, `${r1.status} ${r1.stdout}${r1.stderr}`);
  const r2 = run(a, bad);
  check('not a pixel print → 2', r2.status === 2, `${r2.status} ${r2.stdout}${r2.stderr}`);
  const r3 = run(a);
  check('one argument → 2', r3.status === 2, `${r3.status} ${r3.stdout}${r3.stderr}`);
}

if (failures > 0) {
  console.error(`\n${failures} pixel-print self-test(s) failed.`);
  process.exit(1);
}
console.log('\nAll pixel-print self-tests passed.');
