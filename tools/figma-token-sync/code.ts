/// <reference types="@figma/plugin-typings" />

// CoUI Token Sync — plugin entry. Routes UI messages to token, component,
// verification, brand-rebinding, and consumer collection-override commands.
//   1. import           → import-tokens.ts   (upsert build/tokens.figma.json)
//   2. generate         → generate.ts         (build all registered components)
//   3. theme-preview    → theme-preview.ts    (Light/Dark theme-bound frames)
//   4. export-dart      → export-dart.ts      (local Variables → figma_tokens.g.dart
//                                              + tokens.figma.json, one snapshot)
//   5. generate-palette → generate-palette.ts (color_palette.json → repaint
//                                              the 64 Primitives colors)
//   6. apply-brand-extension → collection-overrides.ts (open the library's
//                                              `Semantic/ Color` as an extension
//                                              and fill it with a code brand's
//                                              values — brand-table.ts)
//   7. mono-hangul      → mono-hangul.ts      (paint Hangul inside monospace
//                                              text in the text face)
//   8. consumer-audit   → consumer-audit.ts   (read-only: list a consumer file's
//                                              text that leaves CoUI's roles)
//                        + library-copies.ts   (same list: library variables the
//                                              file imported twice — stale copies)
//   9. rebind-library-copies → library-copies.ts (move every reference from a
//                                              stale copy to the current copy)
//  10. resync-collection-overrides → collection-overrides.ts (fill each extended
//                                              collection's missing overrides by
//                                              name: a code brand's extension from
//                                              its value table, any other with
//                                              aliases to same-named local tokens)
//
// Builders live in src/components/<section>.ts and are collected in
// src/registry.ts. esbuild --bundle inlines every module into code.js.

import { importTokens, TokenDoc } from './src/import-tokens';
import {
  formatParitySummary,
  parityReport,
  serialiseParityEnvelope,
  type ParitySetReport,
} from './src/designer-parity';
import { kSharedSourceHash } from './src/build-hash';
import { checkTokenDrift } from './src/token-drift';
import { checkTextStyleDrift } from './src/text-styles';
import { captureStructureSnapshot } from './src/structure-snapshot';
import { capturePixelPrint, serialisePixelPrint } from './src/pixel-print';
import { generateComponents, listRegistryEntries } from './src/generate';
import { formatStaleSets, listStaleSets } from './src/stale-sets';
import { formatOrphanNodes, listOrphanNodes } from './src/orphan-nodes';
import { formatOverlappingSiblings, listOverlappingSiblings } from './src/overlapping-siblings';
import { formatOrphanProps, listOrphanProps } from './src/orphan-props';
import { buildThemePreview } from './src/theme-preview';
import { exportDartTokens } from './src/export-dart';
import { generatePalette } from './src/generate-palette';
import { BRANDS } from './src/brand-table';
import { repaintMonoHangul } from './src/mono-hangul';
import {
  auditConsumerFile,
  formatConsumerAudit,
  revealAuditNodes,
} from './src/consumer-audit';
import { auditLibraryCopies, rebindLibraryCopies, withLibraryCopies } from './src/library-copies';
import { auditOldBrandCollections, rebindOldBrandCollections, withOldBrandCollections } from './src/brand-collections';
import { exportedMonoFamily } from './src/compat/v1';
import {
  applyBrandExtension,
  createCollectionOverrides,
  listOverrideCollections,
  resyncOverridesByName,
} from './src/collection-overrides';
import { pointScopeAtBrand } from './src/brand-scope-modes';
import { verifyIdentityIdempotence, verifyResetCompleteness } from './src/verify';
import { verifyFidelity, serialiseFidelityReport, lastFidelityEntry } from './src/fidelity';
import { runPerfProbe } from './src/perf-probe';
import { readLastGrowth, readLastStep } from './src/last-step';
import {
  RETIRED,
  RETIRED_PROPERTIES,
  RETIRED_VARIANTS,
  dryRunRetired,
  dryRunRetiredProperties,
  dryRunRetiredVariants,
  removeRetired,
  removeRetiredProperties,
  removeRetiredVariants,
} from './src/renames';

figma.showUI(__html__, { width: 400, height: 660, themeColors: true });

// documentAccess "dynamic-page" requires loadAsync before reading a page's
// `.children` (plugin-api.d.ts:10423) — same up-front load generate.ts does.
async function loadAllPages(): Promise<PageNode[]> {
  for (const p of figma.root.children) await p.loadAsync();
  return figma.root.children.slice();
}

// `2026-08-13T04:12:33.123Z` → `20260813-041233`, for a filename.
//
// Derived from the very string the envelope carries rather than a second
// `new Date()`, so the name on disk and the `generatedAt` inside it cannot name
// different instants — two clock reads either side of a second boundary would
// describe one run as two, and the file is the only record left of that run.
// UTC, because the reports come from designers in whatever timezone and sorting
// them by name has to mean sorting them by time.
function utcFileStamp(iso: string): string {
  return iso
    .replace(/[-:]/g, '')
    .replace(/\.\d+Z$/, '')
    .replace('T', '-');
}

// 디자이너 대조 전체 결과를 파일로 내려보낸다 — Generate 끝에도, 읽기 전용
// 대조 버튼에서도 같은 봉투. 로그의 `⇄` 줄은 14 줄에서 잘리지만 이 파일은
// 잘리지 않으므로, 결함을 코드로 옮기는 쪽은 로그가 아니라 이것을 읽는다.
// `done` 뒤에 보낸다 — UI 가 `done` 으로 로그를 통째 그린 다음 이 메시지로
// 다운로드 줄만 덧붙인다(순서가 뒤집히면 다운로드 줄이 로그에 덮인다).
function postDesignerParityFile(sets: readonly ParitySetReport[]): void {
  const capturedAt = new Date().toISOString();
  figma.ui.postMessage({
    type: 'designer-parity-file',
    name: `designer-parity-${utcFileStamp(capturedAt)}.json`,
    content: serialiseParityEnvelope(sets, {
      capturedAt,
      fileKey: typeof figma.fileKey === 'string' ? figma.fileKey : null,
      sourceHash: kSharedSourceHash,
    }),
  });
}

// 지금 돌고 있는 명령의 수. 소비 파일 점검 목록의 항목은 명령이 끝난 뒤에도 남아
// 있어서, 다른 명령(Generate 같은)이 도는 중에 눌릴 수 있다. 그 선택은 현재 페이지를
// 옮기고, Generate 는 새 노드를 현재 페이지에 만들므로 반쯤 그린 엔트리가 다른
// 페이지에 떨어진다. UI 도 그동안 목록을 막지만, 이 수가 마지막 방어선이다.
let commandsInFlight = 0;

// 소비 파일 점검에서 건너뛸 레이어 이름 — 사용자의 이 컴퓨터에 기억해 두고 다음에
// 플러그인을 열 때 다시 채운다. 문서에는 쓰지 않는다.
const kConsumerAuditSkipKey = 'consumer-audit-skip-names';

figma.ui.onmessage = async (msg: {
  type: string;
  json?: string;
  paletteJson?: string;
  entryName?: string;
  sections?: string[];
  entryNames?: string[];
  reorderPages?: boolean;
  force?: boolean;
  preserveHandEdits?: boolean;
  snapshotUnfingerprinted?: boolean;
  reassembleOffPage?: boolean;
  brandName?: string;
  collectionKeys?: string[];
  scope?: 'page' | 'all';
  skipNames?: string[];
  pageId?: string;
  ids?: string[];
}) => {
  if (msg.type === 'consumer-audit-select') {
    // 소비 파일 점검 목록의 한 항목 — 그 노드를 선택하고 화면을 옮긴다. 결과는
    // 알림 한 줄이고 UI 에는 답하지 않는다: 답이 `error` 면 UI 가 바쁨 상태를 풀고
    // 로그를 덮어 방금 그린 목록 위의 요약이 사라진다.
    if (commandsInFlight > 0) {
      figma.notify('다른 명령이 도는 중이라 선택하지 않았다 — 끝난 뒤 다시 누른다', { error: true });
      return;
    }
    try {
      figma.notify(await revealAuditNodes(msg.pageId ?? '', msg.ids ?? []));
    } catch (e) {
      figma.notify(`선택하지 못했다 — ${String(e)}`, { error: true });
    }
    return;
  }
  commandsInFlight += 1;
  try {
    if (msg.type === 'import' && msg.json) {
      const doc = JSON.parse(msg.json) as TokenDoc;
      const log = await importTokens(doc);
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'check-drift' && msg.json) {
      // #4536 — read-only comparison of the same JSON Import consumes.
      // Reuses the Import textarea rather than adding a second paste
      // surface: it is the same document, and asking for it twice would
      // let the two answers come from different builds.
      const doc = JSON.parse(msg.json) as TokenDoc;
      const report = await checkTokenDrift(doc);
      const styleLog = doc.textStyles ? await checkTextStyleDrift(doc.textStyles) : [];
      figma.ui.postMessage({ type: 'done', log: [...report.log, '', ...styleLog] });
    } else if (msg.type === 'generate') {
      // #4038 (C5) — 섹션 스코프, #4526 — 컴포넌트 스코프 (entryNames 가
      // 있으면 그쪽이 이긴다; 둘 다 없으면 전체 실행).
      //
      // #4836 — `done` used to repeat the WHOLE log over `postMessage`, on top
      // of everything `logTail` (#4822) had already streamed line-by-line
      // during the run. For a run this size (Display, 57 entries) that whole
      // array crossed whatever the plugin-sandbox↔UI-iframe channel can move
      // in one message: the build finished (`last-step.ts` marked
      // `run:done`), but the UI never rendered anything and the panel read
      // exactly like a mid-run crash — indistinguishable from one without
      // reading the document's own step mark. Every entry's line already
      // reached the UI through `logTail` by the time its `reportProgress`
      // call returns (`generate.ts`'s per-entry loop calls it last), so the
      // only lines `done` still owes the UI are the ones pushed AFTER the
      // loop — the "Done." summary, `Slowest`, the stale-set count, the NFR-E
      // report. Tracking how many lines this callback has already streamed
      // and sending just the remainder turns that final message from
      // O(registry size) back to O(summary size), regardless of how large the
      // run was.
      let paritySets: ParitySetReport[] | null = null;
      let streamedLines = 0;
      const log = await generateComponents(
        (p) => {
          streamedLines += p.logTail?.length ?? 0;
          figma.ui.postMessage({ type: 'progress', ...p });
        },
        {
          sections: msg.sections,
          entryNames: msg.entryNames,
          reorderPages: msg.reorderPages,
          force: msg.force,
          preserveHandEdits: msg.preserveHandEdits,
          snapshotUnfingerprinted: msg.snapshotUnfingerprinted,
          reassembleOffPage: msg.reassembleOffPage,
          onDesignerParity: (sets) => {
            paritySets = sets;
          },
        },
      );
      figma.ui.postMessage({
        type: 'done',
        log: log.slice(streamedLines),
        tail: true,
        hasWarning: log.some((line) => line.startsWith('⚠')),
      });
      if (paritySets) postDesignerParityFile(paritySets);
    } else if (msg.type === 'designer-parity') {
      // 읽기 전용 — 선택한 세트(없으면 전부)를 같은 페이지의 `<이름>(디자이너`
      // 손 사본과 값으로 대조한다. Generate 끝에 자동으로 도는 것과 같은 대조를
      // 그리기 없이 다시 보는 길: 디자이너가 사본을 고친 뒤, 코드를 고치기
      // 전에 "지금 무엇이 다른가" 를 묻는 자리다. 사본이 없는 세트도 한 줄로
      // 그렇다고 말한다 — 침묵은 "차이 없음" 과 구별되지 않는다.
      const pages = await loadAllPages();
      const wanted = msg.entryNames ? new Set(msg.entryNames) : null;
      const log: string[] = [];
      const sets: ParitySetReport[] = [];
      for (const page of pages) {
        for (const node of page.children) {
          if (node.type !== 'COMPONENT_SET' && node.type !== 'COMPONENT') continue;
          if (wanted && !wanted.has(node.name)) continue;
          const parity = await parityReport(node, page);
          for (const l of parity.lines) log.push(l);
          sets.push(parity.report);
        }
      }
      if (sets.length === 0) {
        log.push('대조할 세트가 없습니다 — 선택한 이름의 세트가 어느 페이지에도 없습니다.');
      } else {
        log.push(formatParitySummary(sets));
      }
      figma.ui.postMessage({ type: 'done', log });
      if (sets.length > 0) postDesignerParityFile(sets);
    } else if (msg.type === 'stale-sets') {
      // 읽기 전용 — 선택 불필요. 레지스트리 엔트리마다 캔버스의 세트가 든
      // `coui-content-hash` 를 현재 코드의 해시(Generate 의 스킵 판정과 같은
      // 함수)와 대조해 낡은/없음 을 센다. 머지·빌드가 끝나도 캔버스는 다시
      // 그리기 전까지 옛 코드라, 그리지 않고 그 사실을 물을 자리다.
      const log = formatStaleSets(await listStaleSets());
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'orphan-nodes') {
      // 읽기 전용 — 선택 불필요. 페이지 직계에 원점으로 떠 있는, 세트도 docs
      // 프레임도 디자이너 사본도 아닌 조각을 센다. 빌더가 만들고 어디에도
      // 붙이지 않은 노드가 남는 모양이고, 세트 밖이라 렌더에 영향이 없어 어떤
      // 로그도 그 사실을 말하지 않는다 — 21 개가 사람 손에 발견되기 전까지
      // 일곱 컴포넌트에 걸쳐 그렇게 쌓여 있었다. 세기만 하고 지우지 않는다.
      const log = formatOrphanNodes(await listOrphanNodes());
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'overlapping-siblings') {
      // 읽기 전용 — 선택 불필요. 세트 변형마다 같은 이름의 직계 자식이 다른
      // 세션의 id 대역으로 한 벌 더 들어 있는 것을 센다. 오래 열려 있던 탭이
      // 늦게 다시 연결될 때 멀티플레이어 병합이 남기는 모양이고, 렌더는 살짝
      // 겹쳐 보일 뿐이라 어떤 로그도 말하지 않는다. 세기만 하고 지우지 않는다.
      const log = formatOverlappingSiblings(await listOverlappingSiblings());
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'orphan-props') {
      // 읽기 전용 — 선택 불필요. 전 페이지 직계의 세트·컴포넌트마다 선언된
      // non-VARIANT 프로퍼티를 하위 트리(중첩 인스턴스 안쪽까지)의 참조와 대조해,
      // 패널에 손잡이만 있고 아무 노드도 움직이지 않는 것을 센다. 빌더가 만드는
      // 것은 CI 의 props drill 이 이미 막으므로, 여기서 잡히는 것은 캔버스에
      // 손으로 붙은 것이다. 정의를 읽을 수 없는 세트는 따로 센다.
      const log = formatOrphanProps(await listOrphanProps());
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'list-registry') {
      // Populates the UI's component tree (#4526) — one row per REGISTRY
      // entry, grouped by the same section a run itself resolves by
      // (`listRegistryEntries` shares `sectionOfEntry` with `generateComponents`
      // rather than answering the question a second time).
      figma.ui.postMessage({ type: 'registry', entries: listRegistryEntries() });
    } else if (msg.type === 'theme-preview') {
      const log = await buildThemePreview();
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'export-dart') {
      const { files, log } = await exportDartTokens();
      figma.ui.postMessage({ type: 'dart-files', files, log });
    } else if (msg.type === 'generate-palette' && msg.paletteJson) {
      const log = await generatePalette(msg.paletteJson);
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'verify-identity') {
      // Scoped like its siblings below. Unscoped this builds the whole
      // registry twice, and one component alone (Button, 972 variants) has
      // measured 549s — the whole-registry form is not something anyone can
      // sit through, which is what left #4026 unmeasurable.
      const entry = msg.entryName?.trim() || undefined;
      // `verify-reset` rejects an unknown name, but generate just filters it
      // away (src/generate.ts). Adding a scope without this guard would let a
      // typo build nothing and still finish "✓ identity idempotent".
      if (entry && !listRegistryEntries().some((e) => e.name === entry)) {
        figma.ui.postMessage({
          type: 'done',
          log: [
            `✗ No registry entry named "${entry}" — 항목 이름을 확인하세요 ` +
              `(비우면 전 범위, 다만 매우 오래 걸립니다).`,
          ],
        });
      } else {
        const scope = entry ? [entry] : undefined;
        // A check, not a tidy-up: verify must not rearrange the file's pages.
        // Pages its own runs create are still placed in their section.
        const { log } = await verifyIdentityIdempotence(
          () =>
            generateComponents(undefined, {
              ...(scope ? { entryNames: scope } : {}),
              reorderPages: false,
            }),
          scope,
        );
        figma.ui.postMessage({ type: 'done', log });
      }
    } else if (msg.type === 'verify-fidelity') {
      const { log } = await verifyFidelity(msg.entryName?.trim() || undefined);
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'export-fidelity') {
      // The same sweep as above, kept beside it rather than replacing it: the
      // log-only path is the quick look, and a command that always downloads a
      // file is a worse quick look. This one is for the findings that have to
      // reach the repo.
      const entry = msg.entryName?.trim() || undefined;
      const report = await verifyFidelity(entry);
      const generatedAt = new Date().toISOString();
      figma.ui.postMessage({
        type: 'fidelity-file',
        name: `fidelity-${utcFileStamp(generatedAt)}.json`,
        content: serialiseFidelityReport(report, {
          generatedAt,
          entryFilter: entry ?? null,
        }),
        log: report.log,
      });
    } else if (msg.type === 'export-structure') {
      // Channel A 의 캡처를 파일 안에서 만든다 — MCP 페이지별 호출이 예산·컨텍스트
      // 한계로 이 파일을 다 걷지 못하기 때문이다. 다운로드 경로는 fidelity 와 같다.
      const snap = await captureStructureSnapshot();
      figma.ui.postMessage({
        type: 'fidelity-file',
        name: `structure-${utcFileStamp(snap.generatedAt)}.json`,
        content: snap.content,
        log: snap.log,
      });
    } else if (msg.type === 'export-pixel-print') {
      // 픽셀 지문 (#5010) — 생성된 세트마다 PNG 를 받아 해시로 적는다. 두 실행
      // 뒤에 하나씩 내려받아 `npm run pixel:diff` 로 견준다. 다운로드 경로는
      // 구조 스냅샷과 같다.
      const startedAt = Date.now();
      const { doc, log } = await capturePixelPrint(kSharedSourceHash, (done, total, name) => {
        figma.ui.postMessage({
          type: 'progress',
          index: done,
          total,
          name: name || '픽셀 지문',
          elapsedMs: Date.now() - startedAt,
        });
      });
      figma.ui.postMessage({
        type: 'fidelity-file',
        name: `pixel-print-${utcFileStamp(doc.capturedAt)}.json`,
        content: serialisePixelPrint(doc),
        log,
      });
    } else if (msg.type === 'verify-reset') {
      const { log } = await verifyResetCompleteness(msg.entryName?.trim() || undefined);
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'retire-dry-run') {
      // Two kinds of phantom, and they live in different places. A whole retired
      // SET sits wherever its page is; a retired VARIANT sits inside a set that
      // component-per-page (#4023) may have moved. Both take the page list, so
      // both get every page loaded. What stood here filtered pages by a `🧩`
      // prefix and returns nothing under the new topology (`❖ {Name}`), which
      // made this command a silent no-op.
      const pages = await loadAllPages();
      const log = (await dryRunRetired(pages, RETIRED)).map(
        (c) =>
          `${c.found ? '●' : '○'} ${c.type} "${c.name}" — ${c.found ? 'present, would be removed' : 'not found (no-op)'}` +
          (c.replacement ? ` → migrate to "${c.replacement}"` : '') +
          ` (${c.reason})`,
      );
      for (const c of dryRunRetiredVariants(pages, RETIRED_VARIANTS)) {
        log.push(
          `${c.found ? '●' : '○'} ${c.component} variant "${c.name}" — ` +
            `${c.found ? 'present, would be removed (its key — and every instance of it — dies with it)' : 'not found (no-op)'}` +
            ` (${c.reason})`,
        );
      }
      for (const c of dryRunRetiredProperties(pages, RETIRED_PROPERTIES)) {
        log.push(
          `${c.found ? '●' : '○'} ${c.component} property "${c.name}" — ` +
            `${c.found ? 'present, would be removed (instances only lose an override that no longer toggles anything)' : 'not found (no-op)'}` +
            ` (${c.reason})`,
        );
      }
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'retire-execute') {
      const pages = await loadAllPages();
      const log = await removeRetired(pages, RETIRED);
      for (const line of removeRetiredVariants(pages, RETIRED_VARIANTS)) log.push(line);
      for (const line of removeRetiredProperties(pages, RETIRED_PROPERTIES)) log.push(line);
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'list-brands') {
      // Populates the UI's brand dropdown from the value tables this build
      // carries (`brand-table.ts`) — the code brands, not whatever collections
      // a file happens to have. Not `done` itself — it must not clear the busy
      // state.
      figma.ui.postMessage({
        type: 'brands',
        names: BRANDS.brands.map((b) => b.displayName),
      });
    } else if (msg.type === 'list-override-collections') {
      const collections = await listOverrideCollections();
      figma.ui.postMessage({ type: 'override-collections', collections });
    } else if (msg.type === 'perf-probe') {
      // Synthetic sets on scratch pages, one call timed at a time, everything
      // removed afterwards (`perf-probe.ts`). Progress rides the same message
      // Generate uses so the label shows which size and which call is running.
      const log = await runPerfProbe((p) => {
        figma.ui.postMessage({ type: 'progress', ...p });
      });
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'read-last-step') {
      // Where a run last marked itself (`last-step.ts`). Its own reply type,
      // not `done`, like the list replies above: it can be asked while a run is
      // still going, and must not clear that run's busy state or replace its log.
      figma.ui.postMessage({ type: 'last-step', record: readLastStep(), growth: readLastGrowth() });
    } else if (msg.type === 'create-collection-overrides') {
      const log = await createCollectionOverrides(msg.collectionKeys ?? []);
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'resync-collection-overrides') {
      // 확장 컬렉션마다 덮어쓰기가 빈 변수를 이름으로 다시 채운다 — 코드 브랜드의 확장은
      // 브랜드 값 표로, 그 밖의 확장은 같은 이름 · 같은 타입의 로컬 변수 별칭으로. 파일을
      // 다시 열면 쓰지 않던 라이브러리 변수가 덮어쓰기와 함께 정리되고, 컴포넌트와 함께 다시
      // 들어온 변수는 덮어쓰기 없이 CoUI 기본값으로 칠해진다.
      const log = await resyncOverridesByName();
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'rebind-library-copies') {
      // 「옛 사본 다시 연결」 — 같은 라이브러리 변수를 두 번 가져온 옛 사본의 참조를
      // 현재 사본으로 옮긴다. 문서를 바꾼다. 페이지를 옮겨 가며 고치고 원래 페이지로
      // 돌아온다.
      const log = await rebindLibraryCopies();
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'rebind-old-brand-collections') {
      // 「옛 브랜드 컬렉션 다시 연결」 — 브랜드마다 따로 게시되던 라이브러리 컬렉션
      // (`Semantic/ Color · <브랜드>`)에 묶인 참조를 같은 이름의 `Semantic/ Color · CoUI`
      // 변수로 옮긴다. 문서를 바꾼다. 짝이 없는 이름과 브랜드 원시값에 직접 묶인 곳은
      // 옮기지 않고 보고한다.
      const log = await rebindOldBrandCollections();
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'apply-brand-extension' && msg.brandName) {
      // 라이브러리의 `Semantic/ Color` 를 이 파일의 확장 컬렉션으로 열고 코드 브랜드의 값을
      // 채운다. 화면과 컴포넌트의 연결은 바꾸지 않는다 — 값만 확장 컬렉션이 덮는다.
      const log = await applyBrandExtension(msg.brandName);
      // 확장은 그 모드를 쓰는 노드에만 칠해지므로, 선택(없으면 현재 페이지)의 모드를 옮긴다.
      log.push(...(await pointScopeAtBrand(msg.brandName)));
      figma.ui.postMessage({ type: 'done', log });
    } else if (msg.type === 'consumer-audit') {
      // 읽기 전용 — 소비 파일(제품 화면 파일)의 보이는 글자 중 코드로 옮길 때 CoUI
      // 역할과 갈라질 것을 분류해 목록으로 돌려준다. CoUI 컴포넌트인지는 레지스트리의
      // 세트 이름으로 알아본다 — 소비 파일의 인스턴스가 가리키는 라이브러리 세트는
      // 그 이름으로 게시된다. 노드는 바꾸지 않는다.
      const skipNames = msg.skipNames ?? [];
      // 기억은 편의일 뿐이다 — 저장이 실패해도 점검은 돈다.
      await figma.clientStorage.setAsync(kConsumerAuditSkipKey, skipNames).catch(() => undefined);
      const report = withOldBrandCollections(
        withLibraryCopies(
          await auditConsumerFile({
            scope: msg.scope === 'all' ? 'all' : 'page',
            skipNames,
            couiComponents: listRegistryEntries().map((e) => e.name),
            mono: exportedMonoFamily(),
          }),
          // 가져온 사본 중복 — 글자가 아니라 변수를 본다. 범위와 상관없이 파일 전체다.
          await auditLibraryCopies(),
        ),
        // 옛 브랜드 컬렉션 — 이것도 변수를 보고, 파일 전체다.
        await auditOldBrandCollections(),
      );
      figma.ui.postMessage({
        type: 'consumer-audit-result',
        log: formatConsumerAudit(report),
        groups: report.groups,
        familyUnknown: report.familyUnknown,
      });
    } else if (msg.type === 'consumer-audit-read-skip') {
      // 플러그인을 열 때 UI 가 묻는다. 자기 답 타입이라 바쁨 상태와 로그를 건드리지
      // 않는다(목록 응답들과 같다).
      const stored: unknown = await figma.clientStorage.getAsync(kConsumerAuditSkipKey).catch(() => undefined);
      const names = Array.isArray(stored) ? stored.filter((n): n is string => typeof n === 'string') : [];
      figma.ui.postMessage({ type: 'consumer-audit-skip', skipNames: names });
    } else if (msg.type === 'mono-hangul') {
      // 소비 파일에서 디자이너가 쓴 고정폭 글의 한글 — 라이브러리를 다시 생성해도 닿지
      // 않는다. 글을 고쳐 쓰면 새 글자가 옆 글자의 글꼴을 따르므로 다시 돌린다.
      const log = await repaintMonoHangul();
      figma.ui.postMessage({ type: 'done', log });
    }
  } catch (e) {
    // The component the fidelity walk had reached, appended when there is one. A
    // runtime error names neither the component nor the check, and this command
    // reads 144 of them — without this the message is the same string every time.
    const where = lastFidelityEntry === '(none)' ? '' : ` (last component: ${lastFidelityEntry})`;
    figma.ui.postMessage({ type: 'error', message: `${String(e)}${where}` });
  } finally {
    commandsInFlight -= 1;
  }
};
