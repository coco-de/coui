/// <reference types="@figma/plugin-typings" />

import type { RegistryEntry } from './helpers';
import { REGISTRY, SOURCE_GROUPS } from './registry';

/**
 * 엔트리가 그려지는 소스의 해시 — 번들러가 import 그래프에서 계산해 번들에 구운 표.
 *
 * `scripts/entry-source-hash.mjs` 가 키(`registry.ts` 의 `SOURCE_GROUPS` 키 = 레지스트리 배열의
 * 식별자)마다 해시를 낸다. 해시는 그 배열이 놓인 모듈의 import 닫힘 + 생성기가 엔트리마다
 * 적용하는 파이프라인 + 생성기 텍스트의 **소스 텍스트**다 — 번들 출력이 아니라 소스 파일이라
 * 다른 모듈이 추가되거나 최상위 이름이 겹쳐도 값이 움직이지 않는다.
 *
 * 하네스(`tsx`)는 define 이 없어 표가 `null` 이고, 그러면 모든 엔트리가 플러그인 전체 해시
 * (`kSharedSourceHash`)로 되돌아간다. 닫힘을 계산하지 못한 키도 표에서 빠지고 같은 길을 간다 —
 * 과잉 무효화는 이미 맞게 그려진 세트를 다시 그릴 뿐이고, 과소 무효화는 코드와 어긋난
 * 캔버스를 완성처럼 보이게 한다.
 */
declare const __ENTRY_SOURCE_HASHES__: string;

export const kEntrySourceHashes: Readonly<Record<string, string>> | null =
  typeof __ENTRY_SOURCE_HASHES__ === 'string'
    ? (JSON.parse(__ENTRY_SOURCE_HASHES__) as Record<string, string>)
    : null;

const keyOfEntry = new Map<RegistryEntry, string>();
for (const [key, group] of Object.entries(SOURCE_GROUPS)) {
  for (const e of group) keyOfEntry.set(e, key);
}
const entryByName = new Map<string, RegistryEntry>();
for (const e of REGISTRY) entryByName.set(e.name, e);

/**
 * 엔트리의 해시에 드는 키 — 자기 배열의 키와, `needs` 로 인스턴스를 만드는 엔트리들의 키(전이).
 * 부모는 자식의 변형 이름 · 속성을 빌드 중에 읽어 인스턴스를 놓으므로 자식의 소스가 움직이면
 * 부모의 그림도 움직일 수 있다. 레지스트리에 없는 엔트리(하네스의 대역)나 이름을 풀지 못하는
 * `needs` 는 `null` — 호출자가 전체 해시로 되돌린다.
 */
export function entrySourceKeysOf(e: RegistryEntry): string[] | null {
  const own = keyOfEntry.get(e);
  if (own === undefined) return null;
  const keys = new Set<string>([own]);
  const seen = new Set<string>([e.name]);
  const stack = [...(e.needs ?? [])];
  while (stack.length > 0) {
    const name = stack.pop() as string;
    if (seen.has(name)) continue;
    seen.add(name);
    const dep = entryByName.get(name);
    const key = dep === undefined ? undefined : keyOfEntry.get(dep);
    if (dep === undefined || key === undefined) return null;
    keys.add(key);
    for (const n of dep.needs ?? []) stack.push(n);
  }
  return [...keys].sort();
}

/**
 * 엔트리의 소스 해시 문자열. 표가 없거나 키 하나라도 표에 없으면 `null`.
 * `hashes` 는 셀프테스트가 번들에 구운 표를 대신 넣는 자리다.
 */
export function entrySourceHashOf(
  e: RegistryEntry,
  hashes: Readonly<Record<string, string>> | null = kEntrySourceHashes,
): string | null {
  if (hashes === null) return null;
  const keys = entrySourceKeysOf(e);
  if (keys === null) return null;
  const parts: string[] = [];
  for (const key of keys) {
    const hash = hashes[key];
    if (typeof hash !== 'string') return null;
    parts.push(`${key}=${hash}`);
  }
  return parts.join(',');
}
