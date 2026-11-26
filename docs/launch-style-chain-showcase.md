# Launch — style-chain-showcase (간소화)

> 파이프라인 7단계 Launch 산출물 — **간소화 모드** (coui-live-docs 선례).
> 내부 개발자 문서 도구라 GTM/ICP/A-B 테스트·코호트 분석은 생략하고,
> 릴리스 노트 · 팀 공지 메시지 · 런칭 체크리스트만 담는다.
> 구현 기록: Epic #4007 (9 스토리, PR #4046~#4078) · 상태: `.pipeline/style-chain-showcase.yaml`

## 릴리스 노트

**coui docs — 스타일 슈거 체인 쇼케이스 + 랜덤 순열 토글 프리뷰**

대상: coui 를 소비하는 앱 개발자 (docs_site 이용자)

### 새로 생긴 것

- **모든 컴포넌트 문서에 chain 갤러리 자동 노출** — 문서 페이지의 variant 갤러리 끝에
  `chain` 항목이 추가됐다. 해당 컴포넌트의 슈거 체인(`withStyle(CoreXxxStyle(...))` +
  토큰-정확 getter `.radius8.primary` 류) 사용 예시를 Web·Flutter 프리뷰와 복사 가능한
  코드로 함께 보여준다.
- **체인 예시 전면 확충 (124종 × Web/Flutter)** — 기존 "getter 1개 시연" 수준이던 chain
  예제를 티어별 저작 규약으로 확충: T1(양축, 34종)은 축당 getter 정확 1회의 combo 체인 +
  full-control `withStyle` 1개, T2(단축, 19종)·T3(무축, 71종)은 조합/withStyle 체인.
- **⤨ Shuffle — 랜덤 토큰 순열 토글 (T1 34종)** — chain 갤러리의 Shuffle 버튼을 누르면
  radius 19종 × 색 11종 = 209 순열 좌표를 순회하며 **Web 팬 · Flutter 팬 · 코드 패널
  세 표면이 동시에** 갱신된다. 코드 복사 버튼도 현재 순열의 코드를 복사한다. 임의 값이
  아니라 등록된 디자인 토큰 좌표만 순회하므로 비주얼 테스트를 겸한다.
- **접근성** — Shuffle 버튼은 `aria-label` = 가시 텍스트 동일 문자열, 현재 순열은
  `aria-live=polite` 로 통지, 장식 아이콘은 `aria-hidden`.

### 바뀐 것

- date-picker · time-picker · tabs · resizable 처럼 같은 컴포넌트 태그가 여러 번 나오는
  페이지는 chain 갤러리를 첫 태그에만 노출한다 (`chain="off"` 저자 큐레이션).
  어느 페이지든 chain 표면은 최소 1개 유지된다 (테스트로 강제).

### 문서 저작자 (docs_core 기여자) 에게

- chain 관련 생성물(실측표 · tier1 name-set · 순열 렌더러 68 · registry 2)은
  `tool/generate_chain_artifacts.dart` 소유 — **손편집 금지**, `--check` 를 CI freshness
  가드가 강제한다. 체인 예제를 고치면 생성기를 다시 돌리고, Figma export
  (`components.json`) 재생성도 동반해야 한다.
- 새 페이지에서 chain 중복 노출을 끄려면 `<LivePreview … chain="off" />` — 단 페이지당
  chain ≥1 불변식 테스트(`chain_curation_invariant_test`)가 전 태그 off 를 거부한다.

## 팀 공지 메시지 (Slack)

> 📣 **coui docs 에 스타일 체인 쇼케이스가 출시됐습니다.**
> 이제 모든 컴포넌트 문서 페이지에서 `chain` 갤러리를 볼 수 있어요 — 슈거 체인
> (`withStyle` + `.radius8.primary` 류 getter) 사용 예시가 Web/Flutter 프리뷰 + 복사
> 가능한 코드로 나옵니다. 양축 컴포넌트 34종은 **⤨ Shuffle** 버튼으로 radius×색 209
> 순열을 돌려볼 수 있고, 코드·Web·Flutter 세 표면이 같이 바뀝니다. "coui 문서가 고정
> 쇼케이스일 뿐 플레이그라운드가 아니다"는 벤치마크 갭에 대한 답이에요.
> 피드백·후속 아이디어는 Icebox 이슈 #4027(순열 딥링크) · #4029(T2 확장) ·
> #4031(순열 스크린샷 회귀)로 부탁드립니다.

## 런칭 체크리스트

- [x] 전 스토리 머지 + Epic #4007 close (9/9, failed 0)
- [x] 릴리스 빌드 검증 — SSR 노출(대표 5페이지 + 큐레이션 4페이지) · CDP 셔플 종단 ·
      a11y · 콘솔 에러 0 (PR #4078 검증 절)
- [x] 회귀 게이트 상시화 — 저작 규약 게이트(4티어 124종) · drift 가드 3겹 ·
      큐레이션 불변식 · CI freshness 가드 (전부 main CI 에서 실행)
- [ ] docs_site 프로덕션 배포 후 실 URL 에서 chain 갤러리 + Shuffle 스팟체크
      (배포는 기존 docs_site 배포 절차를 따른다 — 본 기능 전용 절차 없음)
- [ ] 팀 공지 메시지 발송 (위 문안)

## 후속 (Icebox)

- #4027 — 순열 딥링크 (URL 로 특정 순열 공유)
- #4029 — 셔플 T2 확장 (단축 컴포넌트의 1축 순회)
- #4031 — 순열 스크린샷 회귀 (209 좌표 샘플링 비주얼 diff)
