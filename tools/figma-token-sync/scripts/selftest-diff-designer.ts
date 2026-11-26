// reverse/diff_designer.ts (Channel C — 디자이너 대조 렌더러) 의 계약을 실제로
// 돌려 확인한다: 봉투 검증 · 서술자 문법 → 축 파싱 · 사다리 분류 · 종료 코드 ·
// 잘림 문구.
//
// 왜 CLI 로만 재나: `selftest-reverse-contract.ts` 와 같은 이유다 — 내부 함수를
// 부르면 리팩터마다 빨개지고, 계약(플래그 · 종료 코드 · 본문)만 재면 **계약 변경**
// 에만 빨개진다. 예외 하나가 서술자 문법이다. 파서가 기대하는 형식은 플러그인의
// `collectLeaves` 템플릿이 정하는데, 그쪽이 바뀌면 이 파서는 `other` 로 조용히
// 떨어져 모든 차이가 `node-missing` 으로 뭉개진다 — 종료 코드는 그대로 1 이라
// 자동화는 아무것도 못 본다. 그래서 그 템플릿 조각을 **소스에서 직접** 확인해,
// 형식이 바뀌면 여기가 먼저 깨지게 한다.
//
// **가드마다 그 가드만 걸리는 픽스처를 세운다.** 봉투 거부는 종료 코드 2 로
// 전부 같아 보이므로 거부 문구로 어느 가드가 잡았는지 못 박는다 — 겨눈 가드를
// 지워도 이웃이 대신 잡으면 그 케이스는 이름과 다른 것을 재는 것이다.

// import/export 가 없는 파일은 루트 tsconfig 에서 전역 스크립트로 취급돼 다른
// selftest 의 `readFileSync` · `resolve` 로컬 ambient 와 한 네임스페이스에서
// 충돌한다 — 그래서 모듈로 만든다.
export {};

declare const process: {
  cwd(): string;
  exit(code: number): never;
};
declare function require(id: string): unknown;
declare const Buffer: { byteLength(s: string, enc: 'utf8'): number };

const { spawnSync } = require('child_process') as {
  spawnSync(
    cmd: string,
    args: string[],
    opts: { cwd: string; encoding: 'utf8' },
  ): { status: number | null; stdout: string; stderr: string };
};
const { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } = require(
  'fs',
) as {
  mkdtempSync(prefix: string): string;
  mkdirSync(p: string, o?: { recursive: boolean }): void;
  writeFileSync(p: string, data: string, enc: 'utf8'): void;
  readFileSync(p: string, enc: 'utf8'): string;
  readFileSync(p: string): { indexOf(v: number): number; length: number };
  existsSync(p: string): boolean;
  rmSync(p: string, o?: { recursive: boolean; force: boolean }): void;
};
const { join, resolve } = require('path') as {
  join(...parts: string[]): string;
  resolve(...parts: string[]): string;
};
const { tmpdir } = require('os') as { tmpdir(): string };

const ROOT = resolve(process.cwd());
const SCRIPT = 'reverse/diff_designer.ts';
const LOCAL_TSX = join(ROOT, 'node_modules', '.bin', 'tsx');
const RUNNER = existsSync(LOCAL_TSX) ? LOCAL_TSX : 'npx';
const RUNNER_PREFIX = RUNNER === 'npx' ? ['tsx'] : [];

let failures = 0;
const scratches: string[] = [];

interface Run {
  status: number | null;
  stdout: string;
  stderr: string;
}

function scratch(): string {
  const dir = mkdtempSync(join(tmpdir(), 'coui-diff-designer-selftest-'));
  scratches.push(dir);
  return dir;
}

function run(args: string[]): Run {
  return spawnSync(RUNNER, [...RUNNER_PREFIX, SCRIPT, ...args], { cwd: ROOT, encoding: 'utf8' });
}

function expectExit(label: string, args: string[], want: number): Run {
  const r = run(args);
  if (r.status === want) {
    console.log(`  ✅ ${label} → exit ${r.status}`);
    return r;
  }
  failures += 1;
  console.log(`  ❌ ${label} → exit ${String(r.status)} (기대 ${want})`);
  const tail = `${r.stdout}${r.stderr}`.trim().split('\n').slice(-6).join('\n      ');
  if (tail.length > 0) console.log(`      ${tail}`);
  return r;
}

function expectFailedWith(label: string, r: Run, needles: string[]): void {
  const said = `${r.stdout}${r.stderr}`;
  const missing = needles.filter((n) => !said.includes(n));
  if (missing.length === 0) {
    console.log(`  ✅ ${label}`);
    return;
  }
  failures += 1;
  console.log(`  ❌ ${label}`);
  console.log(`      다른 가드가 대신 잡았다 — 없는 문구: ${missing.join(' · ')}`);
  const tail = said.trim().split('\n').slice(0, 3).join('\n      ');
  if (tail.length > 0) console.log(`      실제로 난 실패: ${tail}`);
}

function ok(label: string, cond: boolean, wrong: string): void {
  if (cond) {
    console.log(`  ✅ ${label}`);
    return;
  }
  failures += 1;
  console.log(`  ❌ ${label}`);
  console.log(`      ${wrong}`);
}

/** 표 행 하나가 본문에 있는가 — 축 · 디자이너 값 · 생성본 값 · 분류를 한 행에서 본다. */
function hasRow(body: string, axis: string, designer: string, generated: string, next: string): boolean {
  return body
    .split('\n')
    .some(
      (l) =>
        l.startsWith(`| ${axis} |`) &&
        l.includes(`| ${designer} |`) &&
        l.includes(`| ${generated} |`) &&
        l.endsWith(`| ${next} |`),
    );
}

// ─── 픽스처 ───────────────────────────────────────────────────────────────

type Hint = 'raw-paste' | 'bound' | 'n/a';

interface Line {
  variant: string;
  designer: string[];
  generated: string[];
}

interface SetFix {
  name: string;
  hint?: Hint;
  frame?: string | null;
  lines?: Line[];
  onlyDesigner?: string[];
  onlyGenerated?: string[];
}

function setOf(f: SetFix): Record<string, unknown> {
  const lines = f.lines ?? [];
  const hint = f.hint ?? 'bound';
  return {
    name: f.name,
    page: `❖ ${f.name}`,
    designerFrame: f.frame === undefined ? `${f.name}(디자이너)` : f.frame,
    freshness: { textNodes: 10, boundTextNodes: hint === 'bound' ? 10 : 0, hint },
    compared: 10,
    differing: lines.map((l) => l.variant),
    onlyDesigner: f.onlyDesigner ?? [],
    onlyGenerated: f.onlyGenerated ?? [],
    lines,
  };
}

function envelope(sets: SetFix[]): Record<string, unknown> {
  return {
    kind: 'coui-designer-parity',
    schema: 1,
    capturedAt: '2000-01-01T00:00:00.000Z',
    fileKey: 'FIXTURE',
    sourceHash: 'deadbeef',
    sets: sets.map(setOf),
  };
}

function writeEnvelope(env: unknown, name = 'designer-parity-20000101-000000.json'): { dir: string; file: string; out: string } {
  const dir = scratch();
  const file = join(dir, name);
  writeFileSync(file, JSON.stringify(env), 'utf8');
  return { dir, file, out: join(dir, 'out.md') };
}

/** 정상 봉투에서 **한 자리만** 망가뜨린다 — 손으로 적은 깨진 봉투는 다른 곳도 같이 틀리기 쉽다. */
function broken(patch: (env: Record<string, unknown>) => void): string {
  const env = envelope([{ name: 'Button' }]);
  patch(env);
  return writeEnvelope(env).file;
}

const V = 'Size=md, State=enabled';

// 아래 서술자들은 `src/designer-parity.ts` 의 `collectLeaves` 가 내는 형식 그대로다.
const kText14 = 'text "Label" 14 Regular lh160% ls-0.14 color/on-surface';
const kText16 = 'text "Label" 16 Regular lh160% ls-0.14 color/on-surface';
const kTextLs0 = 'text "Label" 18 Regular lh160% ls0 color/on-surface';
const kTextLs18 = 'text "Label" 18 Regular lh160% ls-0.18 color/on-surface';
const kTextLs27 = 'text "Label" 18 Regular lh160% ls-0.27 color/on-surface';
const kTextRed = 'text "Label" 14 Regular lh160% ls-0.14 color/error';
const kBox = 'box 18x18 r4 fill:color/surface stroke:color/outline w1';
const kBoxFillPrimary = 'box 18x18 r4 fill:color/primary stroke:color/outline w1';
const kBoxFillHex = 'box 18x18 r4 fill:#3366ff stroke:color/outline w1';
const kBoxStrokePrimary = 'box 18x18 r4 fill:color/surface stroke:color/primary w1';
const kBoxW2 = 'box 18x18 r4 fill:color/surface stroke:color/outline w2';
const kBoxW15 = 'box 18x18 r4 fill:color/surface stroke:color/outline w1.25';
const kBoxR8 = 'box 18x18 r8 fill:color/surface stroke:color/outline w1';
const kBoxR13 = 'box 18x18 r13 fill:color/surface stroke:color/outline w1';
const kBox20 = 'box 20x20 r4 fill:color/surface stroke:color/outline w1';
const kBox19 = 'box 19x19 r4 fill:color/surface stroke:color/outline w1';
const kIcon = 'icon check 16 color/on-primary';
const kVec = 'vec 12x9 none / color/on-primary';
// 아래 다섯은 spacing/layout · line-height · font-face · opacity 축 전용이다 —
// 위 18개 상수는 전부 lh160% · Regular · op 없음이라 이 네 축을 한 번도 태우지
// 않는다. 각 쌍은 그 축 하나만 다르고 나머지 필드는 전부 같다.
const kTextSemiBold = 'text "Label" 14 Semi Bold lh160% ls-0.14 color/on-surface';
const kTextLh140 = 'text "Label" 18 Regular lh140% ls-0.18 color/on-surface';
const kTextLh145 = 'text "Label" 18 Regular lh145% ls-0.18 color/on-surface';
const kBoxOp50 = 'box 18x18 r4 fill:color/surface stroke:color/outline w1 op50%';
const kLayout = 'layout pad8/12/8/12 gap4';
const kLayoutGap8 = 'layout pad8/12/8/12 gap8';
const kLayoutOff = 'layout pad9/12/9/12 gap4';

// ─── 서술자 문법이 플러그인 소스와 같은가 ─────────────────────────────────
//
// 파서의 다섯 정규식은 `collectLeaves` 의 템플릿 문자열을 뒤집은 것이다. 그
// 템플릿이 바뀌면 파서는 아무 소리 없이 `other` 로 떨어진다 — 그래서 템플릿
// 조각을 소스에서 직접 확인한다. 형식이 바뀌면 여기가 **먼저** 깨진다.
// ─── 소스가 grep 에 보이는가 ───────────────────────────────────────────────
//
// NUL 바이트가 한 개라도 있으면 `grep` 은 그 파일을 바이너리로 보고 **아무 줄도
// 내지 않는다**. 이 레포의 가드와 리뷰는 grep 위에 서 있으므로, 그런 파일 하나는
// 모든 그물을 조용히 빠져나간다 — 위반이 없는 것과 구별되지 않는 형태로.
//
// 실제로 그렇게 됐던 자리가 `foldSet` 의 접기 키다. 구분자로 NUL 을 **리터럴로**
// 적었더니 파일 전체가 `file(1)` 에 `data` 로 잡혔고, 편집 중 grep 이 빈 결과를
// 내자 그것을 파일이 깨진 신호로 잘못 읽었다. tsc 도 이 하네스의 나머지도 전부
// 통과한 채였다 — NUL 은 문법상 합법이라 컴파일러가 볼 이유가 없다. 그래서
// **바이트를 직접** 센다. `\u0000` 이스케이프는 런타임 키가 같으면서 파일을
// 텍스트로 남긴다.
console.log('소스에 NUL 없음 — grep 에 보이는가');
// `src/designer-parity.ts` 도 같은 그물에 넣는다 — 파서가 문법을 고정하는
// 바로 그 파일이고, 이미 눈에 안 보이는 구분자(`\u0001`/`\u0002`/`\u0003`)를
// 쓰는 습관이 있다. 오늘은 이스케이프뿐이라 통과하지만, 다음에 같은 습관에서
// 리터럴 바이트가 한 번 더 들어가는 걸 막는 건 이 목록뿐이다.
for (const rel of [SCRIPT, 'scripts/selftest-diff-designer.ts', 'src/designer-parity.ts']) {
  const bytes = readFileSync(join(ROOT, rel));
  ok(
    `${rel} 에 NUL 바이트가 없다`,
    bytes.indexOf(0) === -1,
    `${rel} 이 grep 에 바이너리로 보인다 — 구분자를 \\u0000 이스케이프로 적어라`,
  );
}

console.log('서술자 문법 — src/designer-parity.ts 와의 고정');
{
  const src = readFileSync(join(ROOT, 'src', 'designer-parity.ts'), 'utf8');
  const fragments: [string, string][] = [
    ['text', '`text "${node.characters}" ${fs} ${face} lh${lineHeightText(node.lineHeight)} ls${ls} ${await paintText(node.fills, varName)}`'],
    ['icon', '`icon ${glyph} ${half(node.width)} ${color}`'],
    ['vec', '`vec ${half(node.width)}x${half(node.height)} ${await paintText(node.fills, varName)} / ${await paintText(node.strokes, varName)}`'],
    ['layout', '`layout pad${pad.map(half).join(\'/\')} gap${half(gap)}`'],
    ['box', '`box ${half(node.width)}x${half(node.height)} r${radius} fill:${fills} stroke:${strokes} w${sw}${op}`'],
  ];
  for (const [kind, fragment] of fragments) {
    ok(
      `${kind} 서술자 템플릿이 소스에 그대로 있다`,
      src.includes(fragment),
      `src/designer-parity.ts 의 ${kind} 템플릿이 바뀌었다 — reverse/diff_designer.ts 의 ${kind.toUpperCase()}_RE 와 이 하네스의 픽스처를 같이 옮겨라`,
    );
  }
}

// ─── 봉투 검증 (2) ─────────────────────────────────────────────────────────
console.log('봉투 검증 — 인프라 실패는 2');
{
  {
    const r = expectExit('--file 이 없는 파일', [`--file=${join(scratch(), 'nope.json')}`], 2);
    expectFailedWith('  거부한 것이 파일 부재 가드다', r, ['대조 파일이 없음']);
  }
  {
    const r = expectExit('디렉터리에 대조 파일이 없음', [`--dir=${scratch()}`], 2);
    expectFailedWith('  거부한 것이 목록 부재 가드다', r, ['designer-parity-*.json 이 없음']);
  }
  {
    const r = expectExit('디렉터리 없음', [`--dir=${join(scratch(), 'gone')}`], 2);
    expectFailedWith('  거부한 것이 디렉터리 부재 가드다', r, ['디렉터리가 없음']);
  }
  {
    const dir = scratch();
    writeFileSync(join(dir, 'designer-parity-20000101-000000.json'), '{ not json', 'utf8');
    const r = expectExit('JSON 깨짐', [`--dir=${dir}`], 2);
    expectFailedWith('  거부한 것이 파싱 가드다', r, ['JSON 파싱 실패']);
  }
  {
    const r = expectExit('kind 불일치', [`--file=${broken((e) => (e.kind = 'coui-figma-fidelity'))}`], 2);
    expectFailedWith('  거부한 것이 kind 가드다', r, ['kind 가']);
  }
  {
    const r = expectExit('schema 불일치', [`--file=${broken((e) => (e.schema = 2))}`], 2);
    expectFailedWith('  거부한 것이 schema 가드다', r, ['schema 가']);
  }
  {
    const r = expectExit('sets 가 배열이 아님', [`--file=${broken((e) => (e.sets = {}))}`], 2);
    expectFailedWith('  거부한 것이 sets 가드다', r, ['sets 가 배열이 아님']);
  }
  {
    const r = expectExit(
      'freshness.hint 가 셋 중 하나가 아님',
      [`--file=${broken((e) => ((e.sets as Record<string, unknown>[])[0].freshness = { textNodes: 1, boundTextNodes: 0, hint: 'fresh' }))}`],
      2,
    );
    expectFailedWith('  거부한 것이 freshness 가드다', r, ['freshness 가']);
  }
  {
    const r = expectExit(
      'designerFrame 이 문자열도 null 도 아님',
      [`--file=${broken((e) => ((e.sets as Record<string, unknown>[])[0].designerFrame = 7))}`],
      2,
    );
    expectFailedWith('  거부한 것이 designerFrame 가드다', r, ['designerFrame 이']);
  }
  {
    const r = expectExit(
      'differing 이 문자열 배열이 아님',
      [`--file=${broken((e) => ((e.sets as Record<string, unknown>[])[0].differing = [1]))}`],
      2,
    );
    expectFailedWith('  거부한 것이 목록 가드다', r, ['differing / onlyDesigner / onlyGenerated']);
  }
  {
    const r = expectExit(
      'lines 원소가 서술자를 실을 모양이 아님',
      [`--file=${broken((e) => ((e.sets as Record<string, unknown>[])[0].lines = [{ variant: V, designer: 'x', generated: [] }]))}`],
      2,
    );
    expectFailedWith('  거부한 것이 lines 가드다', r, ['lines 에']);
  }
  // 사다리를 잃으면 판정을 건너뛰지 않고 멈춘다 — 사다리 없는 "결정 필요" 는
  // 판정이 아니라 파일 부재의 다른 이름이다.
  {
    const { file } = writeEnvelope(envelope([{ name: 'Button' }]));
    const r = expectExit('사다리 디렉터리가 없음', [`--file=${file}`, `--ladder-dir=${join(scratch(), 'no-core')}`], 2);
    expectFailedWith('  거부한 것이 사다리 가드다', r, ['사다리를 읽지 못함']);
  }
  {
    const fake = scratch();
    mkdirSync(join(fake, 'typography'), { recursive: true });
    mkdirSync(join(fake, 'shape'), { recursive: true });
    mkdirSync(join(fake, 'spacing'), { recursive: true });
    mkdirSync(join(fake, 'size'), { recursive: true });
    for (const rel of [
      'typography/font_size.dart',
      'typography/letter_spacing.dart',
      'typography/line_height.dart',
      'shape/stroke_width.dart',
      'shape/radius_scale.dart',
      'spacing/spacing.dart',
      'size/size.dart',
    ]) {
      writeFileSync(join(fake, rel), '// no constants here\n', 'utf8');
    }
    const { file } = writeEnvelope(envelope([{ name: 'Button' }]));
    const r = expectExit('사다리 파일이 있는데 상수가 0', [`--file=${file}`, `--ladder-dir=${fake}`], 2);
    expectFailedWith('  거부한 것이 빈 사다리 가드다', r, ['상수를 한 개도 읽지 못함']);
  }
  // `pickFile()` 은 대조 파일이 없는 것을 인프라 실패로 다룬다 — 대조할 세트가
  // 없는 것은 차이가 없다는 뜻이 아니라 아무도 대조하지 않았다는 뜻이라는 같은
  // 논증이 파일 수준이 아니라 세트 수준에서도 참이어야 한다. `sets: []` 가
  // "✅ 차이 없음" 으로 새면 캡처가 통째로 깨져 세트를 하나도 못 실은 주기가
  // 초록으로 보고된다.
  {
    const r = expectExit('sets 가 빈 배열', [`--file=${broken((e) => (e.sets = []))}`], 2);
    expectFailedWith('  거부한 것이 빈 세트 가드다', r, ['sets 가 비어 있음']);
  }
}

// ─── 차이 없음 (0) ─────────────────────────────────────────────────────────
console.log('차이 없음 — 0');
{
  const { file, out } = writeEnvelope(envelope([{ name: 'Button' }, { name: 'Chip', frame: null, hint: 'n/a' }]));
  expectExit('차이 없는 봉투', [`--file=${file}`, `--out=${out}`], 0);
  const body = existsSync(out) ? readFileSync(out, 'utf8') : '';
  ok('본문이 차이 없음이라고 말한다', body.includes('✅ 차이 없음'), body.slice(0, 200));
  ok(
    '기준 없는 세트는 "정보 없음" 으로 적힌다 (차이 없음이 아니라)',
    body.includes('대조 기준 없음') && body.includes('정보 없음'),
    '기준 없이 대조하지 않은 세트가 초록으로 읽힌다',
  );
  ok('기준 없는 세트는 대조 수에서 빠진다', body.includes('대조 1개'), body.split('\n')[2] ?? '');
}

// ─── 축 파싱 · 분류 · 종료 코드 (1) ─────────────────────────────────────────
console.log('축 파싱 · 분류 — 차이는 1');
{
  const { file, out } = writeEnvelope(
    envelope([
      {
        name: 'Checkbox',
        hint: 'bound',
        lines: [
          { variant: 'Size=xs', designer: [kText14], generated: [kText16] },
          { variant: 'Size=sm', designer: [kTextLs27], generated: [kTextLs18] },
          { variant: 'Size=md', designer: [kTextRed], generated: [kText14] },
          { variant: 'Size=lg', designer: [kBoxFillPrimary], generated: [kBox] },
          { variant: 'State=hover', designer: [kBoxStrokePrimary], generated: [kBox] },
          { variant: 'State=focus', designer: [kBoxW2], generated: [kBox] },
          { variant: 'State=pressed', designer: [kBoxW15], generated: [kBox] },
          { variant: 'State=disabled', designer: [kBoxR8], generated: [kBox] },
          { variant: 'Checked=true', designer: [kBoxR13], generated: [kBox] },
          { variant: 'Checked=mixed', designer: [kBox20], generated: [kBox] },
          { variant: 'Checked=half', designer: [kBox19], generated: [kBox] },
          { variant: 'Checked=none', designer: [kIcon], generated: [] },
          { variant: 'Checked=vec', designer: [], generated: [kVec] },
          { variant: 'Fill=hex', designer: [kBoxFillHex], generated: [kBox] },
        ],
      },
    ]),
  );
  expectExit('차이 있는 봉투', [`--file=${file}`, `--out=${out}`], 1);
  const body = existsSync(out) ? readFileSync(out, 'utf8') : '';

  // 축 파싱 — 한 서술자 줄에서 **달라진 필드만** 축으로 나온다.
  ok('text-size 축 — 사다리 위(14) → Core 값 수정', hasRow(body, 'text-size', '14', '16', 'Core 값 수정'), body);
  ok(
    'letter-spacing 축 — px 를 em 으로 환산해 사다리(tight15) 위 → Core 값 수정',
    hasRow(body, 'letter-spacing', 'ls-0.27 @18px', 'ls-0.18 @18px', 'Core 값 수정'),
    body,
  );
  ok('text-color 축 — 토큰 → Core 값 수정', hasRow(body, 'text-color', 'color/error', 'color/on-surface', 'Core 값 수정'), body);
  ok('fill 축 — 토큰 → Core 값 수정', hasRow(body, 'fill', 'color/primary', 'color/surface', 'Core 값 수정'), body);
  ok('fill 축 — 로우 hex → 결정 필요', hasRow(body, 'fill', '#3366ff', 'color/surface', '결정 필요 — 사다리 밖'), body);
  ok('stroke-color 축', hasRow(body, 'stroke-color', 'color/primary', 'color/outline', 'Core 값 수정'), body);
  ok('stroke-width 축 — 사다리 위(2) → Core 값 수정', hasRow(body, 'stroke-width', '2', '1', 'Core 값 수정'), body);
  ok('stroke-width 축 — 획 1.25 는 사다리 밖 → 결정 필요', hasRow(body, 'stroke-width', '1.25', '1', '결정 필요 — 사다리 밖'), body);
  ok('radius 축 — 사다리 위(8) → Core 값 수정', hasRow(body, 'radius', '8', '4', 'Core 값 수정'), body);
  ok('radius 축 — 모서리 13 은 사다리 밖 → 결정 필요', hasRow(body, 'radius', '13', '4', '결정 필요 — 사다리 밖'), body);
  ok('size 축 — 20x20 은 사다리 위 → Core 값 수정', hasRow(body, 'size', '20x20', '18x18', 'Core 값 수정'), body);
  ok('size 축 — 19x19 는 사다리 밖 → 결정 필요', hasRow(body, 'size', '19x19', '18x18', '결정 필요 — 사다리 밖'), body);
  ok('node-missing 축 — 디자이너에만 있는 잎', hasRow(body, 'node-missing', kIcon, '(없음)', '결정 필요 — 사다리 밖'), body);
  ok('node-missing 축 — 생성본에만 있는 잎', hasRow(body, 'node-missing', '(없음)', kVec, '결정 필요 — 사다리 밖'), body);
  // 같은 줄이 두 값만 다르면 그 줄에서 나오는 축은 **정확히** 그 둘이다 — 달라지지
  // 않은 필드가 축으로 새면 표가 거짓 차이로 부푼다.
  ok(
    '달라지지 않은 필드는 축으로 나오지 않는다',
    !body.split('\n').some((l) => l.startsWith('| line-height |') || l.startsWith('| font-face |') || l.startsWith('| opacity |')),
    '한 필드만 다른 서술자 쌍에서 다른 축이 함께 나왔다',
  );
  // 꼬리말 범례는 raw-paste 를 **설명**하므로 그 낱말 자체는 남는다 — 경고 문장으로 본다.
  ok(
    'bound 사본에는 raw-paste 경고가 없다',
    !body.includes('사본 신선도: raw-paste') && !body.includes('raw-paste 사본 '),
    '신선한 사본에 경고가 붙으면 경고가 매번 나와 읽히지 않는다',
  );
  ok('bound 사본은 신선도를 bound 로 적는다', body.includes('사본 신선도: bound'), body.slice(0, 800));
}

// ─── 축 파싱 — spacing/layout · line-height · font-face · opacity (2) ───────
//
// 위 "축 파싱 · 분류" 블록의 18개 상수는 전부 lh160% · Regular · op 없음이고
// `layout` 서술자 픽스처가 아예 없었다 — 그래서 `LAYOUT_RE` 가 깨지거나
// `spacing` 분류가 무조건 한 값으로 고정돼도, 또는 `line-height`/`font-face`/
// `opacity` 방출이 `pairDiffs` 에서 통째로 빠져도 저 블록은 초록인 채였다.
// 이 블록이 그 네 그물이다 — 축마다 사다리 위/밖(사다리가 있는 축) 또는
// 항상 결정 필요(사다리가 없는 축) 한 쌍씩 세운다.
console.log('축 파싱 — spacing/layout · line-height · font-face · opacity');
{
  const { file, out } = writeEnvelope(
    envelope([
      {
        name: 'LayoutAxes',
        lines: [
          // spacing(layout) — designer 문자열의 숫자가 전부 사다리 위인지로 판정.
          { variant: 'Pad=onladder', designer: [kLayoutGap8], generated: [kLayout] },
          { variant: 'Pad=offladder', designer: [kLayoutOff], generated: [kLayout] },
          // line-height — designer 값만 사다리에 놓고 판정, 나머지 필드는 동일.
          { variant: 'Lh=onladder', designer: [kTextLs18], generated: [kTextLh140] },
          { variant: 'Lh=offladder', designer: [kTextLh145], generated: [kTextLs18] },
          // font-face — 사다리 없는 축, 값 무관 항상 결정 필요.
          { variant: 'Face', designer: [kTextSemiBold], generated: [kText14] },
          // opacity — 사다리 없는 축, 값 무관 항상 결정 필요.
          { variant: 'Opacity', designer: [kBoxOp50], generated: [kBox] },
        ],
      },
    ]),
  );
  expectExit('네 축 봉투', [`--file=${file}`, `--out=${out}`], 1);
  const body = existsSync(out) ? readFileSync(out, 'utf8') : '';

  ok(
    'spacing 축 — 패딩·간격이 전부 사다리 위 → Core 값 수정',
    hasRow(body, 'spacing', 'pad8/12/8/12 gap8', 'pad8/12/8/12 gap4', 'Core 값 수정'),
    body,
  );
  ok(
    'spacing 축 — 패딩 9 는 사다리 밖 → 결정 필요 (LAYOUT_RE 파손 시 node-missing 으로 뭉개져 여기서 걸린다)',
    hasRow(body, 'spacing', 'pad9/12/9/12 gap4', 'pad8/12/8/12 gap4', '결정 필요 — 사다리 밖'),
    body,
  );
  ok(
    'line-height 축 — 사다리 위(1.6) → Core 값 수정',
    hasRow(body, 'line-height', '160%', '140%', 'Core 값 수정'),
    body,
  );
  ok(
    'line-height 축 — 1.45 는 사다리 밖 → 결정 필요',
    hasRow(body, 'line-height', '145%', '160%', '결정 필요 — 사다리 밖'),
    body,
  );
  ok(
    'font-face 축 — 사다리가 없어 값과 무관하게 항상 결정 필요',
    hasRow(body, 'font-face', 'Semi Bold', 'Regular', '결정 필요 — 사다리 밖'),
    body,
  );
  ok(
    'opacity 축 — 사다리가 없어 값과 무관하게 항상 결정 필요',
    hasRow(body, 'opacity', '50%', '100%', '결정 필요 — 사다리 밖'),
    body,
  );
}

// ─── hasDiff — 요약이 아니라 증거(lines) ────────────────────────────────────
//
// 봉투의 differing/onlyDesigner/onlyGenerated 는 플러그인이 낸 **요약**이고
// `lines` 는 이 스크립트가 서술자를 직접 파싱해 얻은 **증거**다. 둘은 다른
// 경로로 계산되므로(해시 비교 대 잎 수집) 어긋날 수 있다 — 어느 방향으로
// 어긋나든 hasDiff 는 증거 쪽을 봐야 한다.
console.log('hasDiff — 요약과 증거가 어긋나는 두 방향');
{
  // 방향 1 — 요약은 "차이 없음"(differing: []) 인데 lines 안에는 실제
  // stroke-width 차이(w1 → w1.25)가 있다. 요약만 믿으면 이 채널이 존재하는
  // 이유인 바로 그 결함 종류가 "✅ 차이 없음" 으로 지나간다.
  const env1 = envelope([
    { name: 'Ghost', lines: [{ variant: 'State=focus', designer: [kBoxW15], generated: [kBox] }] },
  ]);
  (env1.sets as Record<string, unknown>[])[0].differing = [];
  const { file: file1, out: out1 } = writeEnvelope(env1);
  expectExit('요약은 차이 없다는데 lines 안에 실제 차이가 있음', [`--file=${file1}`, `--out=${out1}`], 1);
  const body1 = existsSync(out1) ? readFileSync(out1, 'utf8') : '';
  ok(
    '차이 없음 으로 렌더되지 않는다',
    !body1.includes('✅ 차이 없음'),
    body1.slice(0, 400),
  );
  ok(
    '실제 stroke-width 차이가 표에 실린다',
    hasRow(body1, 'stroke-width', '1.25', '1', '결정 필요 — 사다리 밖'),
    body1,
  );

  // 방향 2 — 요약은 "차이 2 변형" 이라는데 lines 가 비어 그 변형의 잎 서술자가
  // 없다. 표도 표 머리도 없이 곧장 범례로 넘어가면 "차이 있는데 잘렸다" 와
  // "차이 있는데 증거가 없다" 가 구별되지 않는다.
  const env2 = envelope([{ name: 'Wisp' }]);
  (env2.sets as Record<string, unknown>[])[0].differing = ['State=focus', 'State=hover'];
  const { file: file2, out: out2 } = writeEnvelope(env2);
  expectExit('differing 은 2개인데 그 변형의 잎 서술자가 없음', [`--file=${file2}`, `--out=${out2}`], 1);
  const body2 = existsSync(out2) ? readFileSync(out2, 'utf8') : '';
  ok(
    '차이 없음이 아니라 증거 없음이라고 적는다',
    body2.includes('차이 2 변형이 보고됐지만') && body2.includes('증거 없음이다'),
    body2.slice(0, 800),
  );
}

// ─── 사본 신선도 — raw-paste 는 자간 · 크기 축을 의심으로 ─────────────────
console.log('사본 신선도 — raw-paste');
{
  const { file, out } = writeEnvelope(
    envelope([
      {
        name: 'Checkbox',
        hint: 'raw-paste',
        lines: [
          { variant: 'Size=xs', designer: [kText14], generated: [kText16] },
          { variant: 'Size=sm', designer: [kTextLs0], generated: [kTextLs18] },
          { variant: 'State=focus', designer: [kBoxW2], generated: [kBox] },
        ],
      },
    ]),
  );
  expectExit('raw-paste 봉투', [`--file=${file}`, `--out=${out}`], 1);
  const body = existsSync(out) ? readFileSync(out, 'utf8') : '';
  ok('text-size 는 사본 의심', hasRow(body, 'text-size', '14', '16', '사본 의심'), body);
  ok('letter-spacing 은 사본 의심 (사다리 위여도)', hasRow(body, 'letter-spacing', 'ls0 @18px', 'ls-0.18 @18px', '사본 의심'), body);
  ok('자간 · 크기가 아닌 축은 그대로 판정된다', hasRow(body, 'stroke-width', '2', '1', 'Core 값 수정'), body);
  // 경고는 표보다 **먼저** 와야 한다 — 표를 먼저 읽고 자간 행을 캔버스의 결정으로
  // 받아들인 뒤에 경고를 만나면 이미 늦다.
  const warnAt = body.indexOf('자간 · 크기 축은 신뢰 불가');
  const tableAt = body.indexOf('| 축 |');
  ok('raw-paste 경고가 표보다 앞에 있다', warnAt >= 0 && tableAt > warnAt, `경고 ${warnAt} · 표 ${tableAt}`);
  ok('리포트 머리말에도 raw-paste 세트가 이름으로 실린다', body.indexOf('raw-paste 사본 1개') < body.indexOf('## Checkbox'), body.slice(0, 600));
}

// ─── 접기 — 같은 차이가 여러 변형에 반복되면 한 행 ─────────────────────────
console.log('접기');
{
  const lines: Line[] = ['sm', 'md', 'lg'].map((s) => ({
    variant: `Size=${s}, State=focus`,
    designer: [kBoxStrokePrimary],
    generated: [kBox],
  }));
  const { file, out } = writeEnvelope(envelope([{ name: 'Select', lines }]));
  expectExit('세 변형이 같은 값 차이', [`--file=${file}`, `--out=${out}`], 1);
  const body = existsSync(out) ? readFileSync(out, 'utf8') : '';
  const rows = body.split('\n').filter((l) => l.startsWith('| stroke-color |'));
  ok('한 행으로 접힌다', rows.length === 1, `${rows.length} 행: ${rows.join(' | ')}`);
  ok('접힌 행이 변형 수 3 과 "외 2" 를 단다', rows[0]?.includes('| 3 (') === true && rows[0]?.includes('외 2') === true, rows[0] ?? '');
}

// ─── 사전순 마지막 파일 + 그 사실이 본문에 ─────────────────────────────────
console.log('파일 선택');
{
  const dir = scratch();
  writeFileSync(join(dir, 'designer-parity-20000101-000000.json'), JSON.stringify(envelope([{ name: 'Old', lines: [{ variant: V, designer: [kBoxR8], generated: [kBox] }] }])), 'utf8');
  writeFileSync(join(dir, 'designer-parity-20000102-000000.json'), JSON.stringify(envelope([{ name: 'New' }])), 'utf8');
  const out = join(dir, 'out.md');
  expectExit('두 파일 중 사전순 마지막을 읽는다 (그 파일은 차이 없음)', [`--dir=${dir}`, `--out=${out}`], 0);
  const body = existsSync(out) ? readFileSync(out, 'utf8') : '';
  ok('읽은 파일이 마지막 것이다', body.includes('## New') && !body.includes('## Old'), body.slice(0, 400));
  ok('읽지 않은 파일 수를 본문이 말한다', body.includes('대조 파일이 2개') && body.includes('나머지 1개'), body.slice(0, 600));
}

// ─── 잘림 — 예산 안에서 잘리고, 감춘 수를 문장으로 ─────────────────────────
console.log('잘림');
{
  const sets: SetFix[] = [];
  for (let s = 0; s < 40; s += 1) {
    const lines: Line[] = [];
    for (let i = 0; i < 60; i += 1) {
      lines.push({
        variant: `v${i}`,
        designer: [`box ${i + 100}x${i + 100} r4 fill:color/surface stroke:color/outline w1`],
        generated: [kBox],
      });
    }
    sets.push({ name: `Set${String(s).padStart(2, '0')}`, lines });
  }
  const { file, out } = writeEnvelope(envelope(sets));
  expectExit('큰 봉투', [`--file=${file}`, `--out=${out}`], 1);
  const body = existsSync(out) ? readFileSync(out, 'utf8') : '';
  const bytes = Buffer.byteLength(body, 'utf8');
  ok('본문이 예산(28000) 근처에서 멈춘다', bytes <= 28000 + 512, `${bytes} 바이트`);
  ok('표가 행 상한에서 잘렸다고 말한다', body.includes('행에서 잘렸다'), '표 잘림 문구가 없다');
  const m = /리포트가 \d+ 바이트에서 잘렸다 — (\d+) 행을 실었고 (\d+) 행이 더 있다 \(총 (\d+)\)/.exec(body);
  ok('감춘 행 수를 문장으로 적는다', m !== null, '절 잘림 문구가 없다');
  if (m) {
    const [, shown, dropped, total] = m.map(Number);
    ok('실은 수 + 감춘 수 = 총수', shown + dropped === total, `${shown} + ${dropped} ≠ ${total}`);
    ok('총수가 픽스처와 같다 (40 × 60)', total === 2400, `총 ${total}`);
  }
  ok('세트를 이름조차 못 실은 수를 말한다', body.includes('이름조차 싣지 못했다'), '세트 단위 잘림이 조용하다');
}

for (const dir of scratches) rmSync(dir, { recursive: true, force: true });

if (failures > 0) {
  console.log(`\n❌ diff_designer 계약 ${failures}건 불일치`);
  process.exit(1);
}
console.log('\n✅ diff_designer 계약 OK');
