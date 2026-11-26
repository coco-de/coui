# 문서 v2 프리뷰 입력·문맥 연결 검증 — 2026-11-18

실제 v2 문서의 props·라벨·demo·크기 표를 기존 프리뷰 선택기와 두 렌더러에 연결했다. 공개 CoUI API·Core 디자인값을 바꾸지 않고 원본 앱/사이트 렌더러를 공유한다. 전체 파리티는 미완료다.

## 실제 소스와 측정 범위

제품·새 촬영 소스는 `309d4f9c894c5c36cbaf2c0628b9e5dcf09aae73`, 포함 main은 `314bd9321cb56ee7e5dbea741741ef8cbbf74df9`다. 이후 `7480a307`은 Native 회귀 테스트 1파일만 통합했다. 뒤의 테스트/검증 문서 커밋을 새 촬영 소스로 부르지 않는다.

기존 legacy730행은 descriptor·판정이 같고, 네 default fallback을 실제43 reference×L/D86행으로 교체해 default816/all3814가 됐다. Card21개×L/D42행은 **whole Card**, SizeSpec은 표를 포함한 전체 블록, 나머지는 원본 프리뷰 무대다. 가용 폭은 캡처 계약이며 원 페이지의3열 카드 폭을 복사하지 않는다. 이전 fallback 또는 미완료 Card-stage 키 삭제를 해결 건수로 계산하지 않는다.

| 최종 default816 | pass | fail | infra | structural skip |
|---|---:|---:|---:|---:|
| pixel |582|234|0|0|
| property |402|356|12|46|

두 report exit1을 유지했다. 공통730의 pixel556/174, property402/270+infra12/structural46는 전후 동일하다. 새86은 pixel26/60·property86 fail이다. Native816과 Web 새86은309에서 새 촬영했고, Web legacy730은 입력·실행 경로 불변 근거로 명시 재사용했다. 최종 원본은 JSON1632+PNG1656=3288개, 누락0이다. 캡처 문맥 교정으로 얻은26 pass를 CoUI 결함26개 해결로 해석하지 않는다.

## 정식 렌더 경계

- 실제 Markdown AST가 frontmatter·주석·코드를 제외하고 입력을 도출한다. reference는 전체 입력을 보존하며 충돌·원문 누락/모호성·미지원 body를 기본 예제로 대체하지 않는다.
- Native Card는 기존 LayoutBuilder→Wrap→SizedBox 폭 할당, 실제 outlined Card와 원문 paragraph/inline 렌더러를 공유한다. 앱의 기존 import 경로·서명·const를 유지했다. Native parser 정책/문자열은 같고 Core120 formatter로1hunk만 달라999개 실행 token 및193문서 결과가 같다. 파일 바이트 동일 주장은 하지 않는다.
- Web은 public `Content.wrapTheme`/`Content`, 기존 standalone Card의1장 `docs-cards.not-content` 그룹과 Anatomy의 실제 outer/legend를 공유한다. SizeSpec에는 prose 표 문맥을 제공하고 전체를 not-content로 덮지 않는다.
- 새로운 문서 호스트만 실제 containing-block 폭을 받는다. 부모800/1000의5종 실제 검증에서 원래 내용폭 고정 음성→정상 양성을 확인했다. Native 측정206을 옮기는 보정·빈 형제·body 대체·CSS값 복사는 하지 않았다.
- Playground4건은 SSR key1/host1/client0/readyfalse→attach 뒤 key1/host1/client1/실제client probe1을 확인했다. SSR43장면은 자체VM reload 전후43/43·HTTP200/200이며 소유 PID/포트를 닫았다.

## 원본 앱·사이트 보존

동결072 원본 Native Card84건(21개×800/206×L/D)과 공유 앱84/새scene84를 별도로 실행했다.168쌍의 RGBA·전체/Stage bounds·오류가 같다. 원본은 새 shared layout0, 이후는1임도 확인했다.193문서 parser 덤프 동일, API/AST11항목 동일, 기존 before16 및 after+회귀19 테스트 통과다.

Root는309에서 O2 docs359를73.71초에 새 빌드했다. 추적22533파일 변화0·gitclean, 실제 두 경로26관측의 theme/props/입력 identity/복원/refresh/Native embed2 active 및 FontManifest2완료를 확인했다. runtime·console·request 오류0, 초기 DOM4쌍·raw PNG8쌍 byte/RGBA exact다. 소유 빌드 process group·브라우저·HTTP 포트 종료를 기록했다.

순수 선택기10·실제브라우저4, Root 통합 Dart42의 fatal-infos0, 추가 Native 회귀 파일 fatal0, format43 변경0, full contract exit0이다. 기존 비강제 WARN7은 숨기지 않았다. 정상 Flutter CLI의 실제 Card800×241/본문 frame→r reload→동일 frame→q 종료와 VM/PID 폐쇄도 확인했다. 이는 같은 소스 reload이며 이전 구현에서의 live-upgrade 보장은 아니다.

## 유지한 계약과 한계

공개 CoUI 세 패키지·Core 디자인값, 원문 MD, docs CSS/JS, Native generic 소비자/호스트/writer, MatrixEntry7필드, comparator/normalizer/threshold/skip/baseline/SDK constraints는 main과 같다. 공유 Native 링크 렌더러를 소유하는 DocsCore에 기존 url_launcher6.3.2 직접 연결1개만 추가했다. 새 node/버전/lock 변화0,232 package tuple은 같다.

초기 잘못된 fixture·Iconify 이동 취소·전체 SVG 상주 단언·내비게이션이 가린 screenshot·kernel 없는 testVM reload 거절은 별도 원본으로 보존했다. offscreen Iconify SVG는 실제 viewport 동작임을 확인해 SSR escape 추측을 철회했다. host-only/stage-only 중간 통계는 최종 결과로 재라벨하지 않는다. headless plugin symbol 제약은 전체 desktop 통합 성공으로 쓰지 않는다.

전체3814 스타일·모든 control 조합·전체 수동 CI·배포·Figma Generate는 실행한 것으로 표시하지 않는다. 복합 프레임/속성 attribution과 플랫폼 차이를 모두 CoUI 버그나 불가피한 AA로 단정하지 않는다. 역사적20 입력 복원은#6417, 전체 잔여는#6131에서 계속 추적한다. 상세 명령·소스·hash·원본 경로는 같은 이름의 JSON 및 연결된 ledger에 보관했다.
