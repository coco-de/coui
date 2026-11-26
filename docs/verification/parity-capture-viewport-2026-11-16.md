# 화면 밖의 프리뷰도 같은 viewport로 촬영 (2026-11-16)

Part of [#6131](https://github.com/coco-de/coui/issues/6131).

#6312는 main `9888109634877165960b0df027d32acd8bb75196`에 squash 머지됐다.
검증 head `221b4550923db3e30f4325ed8483f85bc2cd88ba`와 머지 결과의 tree SHA가
`f5b63bdf42aea460c8ccfb2b327dfd4995ff9593`로 같다. 머지 뒤 Release 실행
`43804843557`도 성공했다. 현재 전체 파리티의 기준은 460 통과·288 불일치다.

## 확인한 캡처 오류

Web backend는 페이지를 800×1200으로 설정하지만 실제 PNG에 쓰던
`ElementHandle.screenshot()`은 큰 요소를 찍을 때 viewport를 임시로 키운다.
설치된 Puppeteer의 `src/page/js_handle.dart`에서 이 분기를 확인했다.
요소의 폭이나 높이가 viewport를 넘으면 `setViewport(max(viewport, box))`를
호출하고, 촬영 뒤 원래 viewport로 복구한다.

따라서 촬영 전 메타데이터와 촬영 뒤 viewport가 모두 800×1200이어도 실제
PNG는 다른 미디어 쿼리·viewport 단위 조건에서 그려질 수 있었다. 캡처 후
viewport만 검사해서는 이 오류를 잡을 수 없다.

다음 두 fixture는 800×1200에서 초록색이며, 화면 조건이 커지면 빨간색이다.

| 실제 예제 크기 | 색이 바뀌는 미디어 쿼리 | 기존 실제 PNG | 수정 뒤 실제 PNG |
|---|---|---|---|
| 1000×40 | `min-width: 900px` | 빨강 — 실패 | 초록 — 통과 |
| 80×1400 | `min-height: 1300px` | 빨강 — 실패 | 초록 — 통과 |

새 helper 검사 두 개는 기존 함수로 실패했다. 실제 `captureWebEntry`에서도
같은 fixture를 registry builder로 주입해 metadata와 PNG를 함께 검사한다.
backend의 호출을 기존 함수로 되돌리는 변이에서 그 두 검사가 다시 실패했고,
복구 뒤 통과했다. 원본 제품 registry는 각 검사 종료 시 복구한다.

**기존 기본 스타일 748키의 root/stage PNG 중 800×1200을 넘는 것은 0개**다.
이 결함을 잔여 288키의 원인이나 해소 건수로 집계하지 않는다. 큰 프리뷰가
들어와도 같은 입력 조건을 지키도록 캡처를 보완한 것이다.

## 수정 범위

요소의 실제 bounding box에 현재 scroll offset을 더해 document clip을
구하고 `Page.screenshot(captureBeyondViewport: true)`으로 촬영한다.
페이지의 viewport·scroll position을 변경하지 않는다. 이 helper를 일반
root와 추가 stage 캡처 양쪽에서 사용한다.

- 현재 크기·미디어 쿼리 조건을 유지하며 화면 밖 픽셀도 실제 페이지에서
  촬영한다. 기존 non-empty root 검사는 유지한다.
- Page의 기존 소수점 clip 정수 처리를 그대로 쓴다. 소수점 위치·크기의
  작은 fixture에서 기존 캡처와 크기·픽셀이 정확히 같은지 확인했다.
- scroll이 `(100,1400)`인 페이지에서도 정확한 80×40 요소를 촬영하며
  viewport와 scroll이 유지되는지 확인했다.
- 이미지 패딩·마스크·스케일·offset 보정은 하지 않는다. PNG 크기를 맞추기
  위한 높이·폭 정수 처리 변경도 하지 않는다.
- 제품 라이브러리·Core·공개 패키지 API·예제·문서 UI·Figma 데이터·baseline·
  allowlist·픽셀 임계값은 변경하지 않는다. 내부 Web 캡처 helper와 검사만 바뀐다.

## 로컬 검사

| 실행 | 실제 결과 |
|---|---|
| helper·capture state·backend Chrome 검사 | 43 통과 |
| helper 진단 JS의 공백 정리 뒤 해당 파일 재검사 | 4 통과 |
| 변경 Dart 4개 `dart analyze --fatal-infos` | `No issues found!` |
| 같은 4개 `dart format --set-exit-if-changed --output=none` | `0 changed` |
| 기존 함수로 backend 호출을 바꾼 변이 | 실제 PNG 색 검사 2개 실패 |
| Flutter 기본 스타일 / 관련 모든 스타일 촬영 | 748 / 60 성공 |
| 관련 60키 교차 플랫폼 픽셀 비교 | 45 통과·15 실패·인프라/skip 0, exit 1 |
| 관련 60키 own-baseline | Web root 60 통과·Flutter root 범위 차이 60·stage 첫 캡처 120 |

관련 60키는 #6312의 본체·전체 stage 계약이 적용되는 6개 변형의 모든 등록
스타일이다. 해당 범위를 전체 컴포넌트의 모든 스타일 검증으로 확대하지 않는다.
별도 전체 수동 CI·jaspr build는 이 capture-only 변경에서 실행하지 않았다.
UI 경로 변경이 없어 `pr-evidence`의 이미지 첨부 대상은 아니다.

## 전체 재촬영 결과

동일한 748키·760 probe manifest로 Flutter와 Web을 모두 새로 촬영했다.
main `9888109`의 제품 소스와 변경한 실제 캡처 코드 2개의 지문을 확인했다.
촬영 중 바뀐 것은 검사 파일의 진단 JS 공백뿐이며, 캡처 코드 지문은 그대로다.

```text
[report] 469 passed, 291 failed, 0 infra-skipped, 0 structural-skipped
[matrix] 460 passed keys, 288 failed keys, 0 infra keys, 0 skipped keys (748 total)
```

실패 키·판정이 모두 같고 새 실패·해소는 각각 0개다. 288키는 치수 100·
같은 크기 픽셀 188이며, **전체 파리티는 여전히 미완료**다. report는 exit 1이다.

기존 #6312 캡처와 비교하면 기본 스타일의 모든 root/stage 1,520개 플랫폼
이미지와 관련 스타일 240개 플랫폼 이미지가 RGBA 픽셀까지 같다(최대 채널차 0).
새 기본 스타일 산출물은 PNG·JSON 합계 3,016개다. 단순히 실패 수가 같다는
것보다 강한 전후 픽셀 보존 증거이며, 큰 예제 조건의 오류를 고친 결과를
현재 288키의 감소로 읽지 않는다.

own-baseline은 1,496개 플랫폼 셀 중 1,369 통과·127 차이, 추가 stage 24개
셀은 첫 캡처다. #6312의 키·플랫폼·측정값이 모두 유지된다. 승인·skip·인프라
실패는 0이며 회귀 report도 exit 1이다. 기존 범위 변경 차이를 승인하거나
baseline을 승격하지 않았다.

[전체 키·역할 CSV](parity-capture-viewport-2026-11-16.csv)와
[소스 지문·요약 JSON](parity-capture-viewport-2026-11-16.json)에 결과를 남겼다.
기존 [재촬영 명령](parity-remeasurement-2026-11-16.md)으로 새 manifest를
생성하고 양 플랫폼 캡처 뒤 `--signal=pixel --mode=parity` 및
`--mode=regression`을 각각 실행하면 된다. 현재 캡처는 추가 stage PNG도 필요하다.
