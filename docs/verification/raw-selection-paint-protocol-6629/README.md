# Selectable·TextArea pseudo 페인트 생성 경로 (#6629)

Part of #6629 / #6131. 기존 raw 색상 값과 경계 계산을 유지하면서,
허용되지 않던 arbitrary VALUE/PROPERTY 출력 대신 실제 페인트 확장으로 연결한다.
원본 형식 테스트의 실패를 기존 사용자 색상이 틀렸다는 뜻으로 해석하지 않는다.

Selectable은 ThemeConfig의 표준 addVariant/addUtilities로 root 전용 selection과
기존 inline 색상 변수를 연결한다. Core 가짜 색상 토큰·특이도 강화·!important·
자손 전체 선택자는 추가하지 않는다. TextArea는 기존 변수와 별도 단일 frame 규칙을
연결하며 `:has(>:first-child>textarea:focus-visible)`를 그대로 유지한다.
푸터 버튼·별도 textarea는 제외하고 NoFooter·오류·비활성·읽기 전용 gate는 보존한다.
공개 API·Core·기본값·값 계산·DOM 구조·의존성·비교기·기준 이미지는 바꾸지 않았다.

## 실제 색상 우선순위와 검증

Git94d 원본 형식 검사는 Selectable 1PASS/6FAIL, TextArea 7PASS/7FAIL이었다.
초기 global CSS 후보는 SSR 검사 뒤 실제 Ego에서 중첩 raw와 일반 caller utility의
색상 회귀2개가 확인돼 채택하지 않았다. utility만 등록한 첫 prototype도 같은
arbitrary selector caller1개가 달라 13동일/1변경으로 보존하고 채택하지 않았다.

최종 named-root variant는 실제 의미가 다른 root-only selection을 표현한다.
선택15쌍 중14쌍은 유지되고, 같은 arbitrary selector/value 충돌1쌍은 달라졌다:
`[&::selection]:bg-[#070809]` caller가 원본의 raw(18,85,170) 대신
caller(7,8,9)로 적용된다. 옛 비공개 class 정렬 결과에 기대던 충돌을 caller 우선으로
정규화한 의도된 차이이며, 동작이 모두 같다고 주장하지 않는다.
중첩 raw/token·plain opaque/alpha/transparent·normal utility·late normal CSS·
같은 arbitrary selector의 token utility·ID·important 경로는 관측값을 유지했다.

WindowPanel main8d를 정상 통합한 code1df7d382에서 새로 검증했다:

- 기존11+WindowCore/Web2의13파일184PASS/0FAIL, fatal0/format0. Source9는 생산5+테스트4다.
- Root가 실제 새 소스의 공개 SSR15+TA17=32개를 Ego27/Chrome156으로 관측했다.
  선택14동일/hex충돌1변경, TA17은 관측값이 같다. main→푸터 버튼/별도 textarea→
  main 키보드 포커스와 같은 frame의 normal/important/ID CSS도 별도로 확인했다.
- 최종1df의9개 PNG는 직전362와 byte exact이며 원본대비8표본도 같다.
  이는 공개 custom fixture 표본이며 전체 스타일·baseline 통과 주장이 아니다.
- 정본 Web default4를 원본/후보에서 각각 새 촬영했다. 같은 backend의4쌍은 PNG
  byte exact/0diff다. 실제 Git own-baseline 비교는 원본4/후보4 모두8FAIL이고
  채널32·비율.001 기준을 유지했다. 새 기본화면 회귀가 관측되지 않은4표본일 뿐
  baseline 통과·Native 대체·전체 파리티 통과가 아니다. 원인을 profile로 단정하지 않는다.

## 빌드·출처·한계

최종 pinned CLI0.24beta1/FVM3.50 Web 빌드는 code1df7d382에서 CLI0/observer0,
실제 child108.9524155초·361/361경로였다. 산출물5044개/HTML365개(Jaspr363개)의
해시목록과 대표HTML3개만 남기고 whole build/cache는 회수했다.
Source25192 tracked/232config·graph·lock raw bytes와 job232 fields/실제 roots/
versions/pubspec/edges/lock은 동일하다. 사용 설치패키지256 source tree·hosted목록·
registry metadata도 그대로다. 직접 pub0과 내부 자동 처리는 구분하며 totalpub0은 주장하지 않는다.

이전2af/3da/fd1/362/feaa 결과는 실제 소스로 보존한다. 실제 SSR VM reloadSources는
true였지만 초기화된 static final CSS가 남아 전체 observer가 FAIL인 기록도 유지한다.
그 뒤 cold start를 hot restart나 client hydration이라고 바꾸어 쓰지 않는다.
첫 setup/초기 cache mirror의 observer 실패·경위 unknown도 원문으로 남긴다.
첫 browser postcheck의 viewport 불일치 FAIL과 이후 같은 환경의 paired 재측정을 구분한다.

브라우저 검증은 공개 SSR의 실제 CSSOM·선택·키보드 포커스 범위다. hydration/클라이언트
callback·모든 CSS 조합·전체 Native/Web 파리티를 증명하지 않는다. Managed Ego156의
software raster 여부는 확인하지 않았고 색·이미지·기준을 보정하지 않았다.
원본/후보/최종 source, 관측값, 한계는 verification.json의 출처에 연결한다.
