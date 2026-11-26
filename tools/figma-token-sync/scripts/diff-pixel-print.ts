// 픽셀 지문 두 파일을 견준다 (#5010). 플러그인 "픽셀 → .json" 이 내려준 파일.
//
// Usage:
//   npm run pixel:diff -- <A.json> <B.json>
//
// 종료 코드: 0 픽셀 동일 · 1 차이 있음 · 2 입력이 틀렸다(인자 · 파일 · schema).
// 이 레포의 다른 differ 와 같은 규약이다 — 자동화는 2 를 "파이프라인이 깨졌다",
// 1 을 "그림이 달라졌다" 로 읽는다.

import { diffPixelPrints, formatPixelDiff, parsePixelPrint } from '../src/pixel-print';

declare const process: { argv: string[]; exit(code: number): never };
declare const console: { log(...args: unknown[]): void; error(...args: unknown[]): void };
declare function require(id: string): unknown;

const { readFileSync } = require('node:fs') as { readFileSync(p: string, enc: string): string };

const args = process.argv.slice(2).filter((a) => a !== '--');
if (args.length !== 2) {
  console.error('usage: npm run pixel:diff -- <A.json> <B.json>');
  process.exit(2);
}
let a;
let b;
try {
  a = parsePixelPrint(readFileSync(args[0], 'utf8'));
  b = parsePixelPrint(readFileSync(args[1], 'utf8'));
} catch (e) {
  console.error(`입력을 읽지 못했다: ${String(e)}`);
  process.exit(2);
}
const diffs = diffPixelPrints(a, b);
for (const line of formatPixelDiff(a, b, diffs)) console.log(line);
process.exit(diffs.length === 0 ? 0 : 1);
