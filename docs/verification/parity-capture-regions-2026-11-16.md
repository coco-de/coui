# 본체와 바깥 영역의 캡처 범위 정합성 (2026-11-16)

Part of [#6131](https://github.com/coco-de/coui/issues/6131).

기본 스타일 748칸을 양 플랫폼 모두 다시 촬영했다. 결과는 **460 통과·288
불일치·인프라 누락 0**이다. 기존 297개 실패 중 비교 범위가 달랐던 9칸이
해소됐고 새 실패는 없다. **전체 파리티는 여전히 미완료**다.

## 기준 main과 선행 머지의 통합 검증

#6307을 main `a5b51346059a82c13db39c5e3776a9232ab3d058`에 머지한 뒤,
후속 소스 수정 전에 기존 manifest로 748칸을 새로 촬영했다. #6308·#6309·
#6310까지 포함한 실제 통합 트리에서 **451 통과·297 불일치**였고, #6307의
검증 head와 실패 키 297개가 같았다. 같은 플랫폼의 전후 PNG도 기존 회귀
기준을 넘는 변화가 없었다. own-baseline은 1,381 통과·115 기존 차이다.
머지 결과의 전체 파일 트리가 #6307 head와 같다고 간주하지 않았다.

이후 #6283의 Figma Icon 처리와 #6305 릴리스가 들어온 main
`5bb8661c581476905605bc91db8441e096cb98d8`을 작업 브랜치에 반영했다.
그 두 변경은 Figma 도구·버전·CHANGELOG이며 패키지 렌더 라이브러리를
바꾸지 않았다. 아래 최종 748칸 촬영·빌드는 이 main에 이번 변경을 적용한
상태다. 촬영 뒤 fetch에서도 같은 origin/main을 확인했다.

## 서로 다른 상자를 비교하던 12칸

대상은 `mockup/{phone,tablet,landscape}`, `mockup-device/{default,flat}`,
`responsive-container/default`의 라이트·다크다. Flutter는 폭 800의 바깥
Align을, Web은 폭 320·256·640의 실제 본체를 root로 측정했다.

실제 문서와 캡처가 함께 읽는 Web preview registry에 Flutter와 같은
전체 폭의 가운데 정렬 host를 둔다. 기존 공유 `kDocsFillWidthPreviews`에
해당 6개 변형을 등록하며, 컴포넌트 자체의 크기·색·타이포·동작은 바꾸지
않는다. 양 플랫폼에서 root는 실제 본체, 추가 stage는 바깥 전체 영역이다.

| 검사 | 측정 범위 | 보존하는 검증 |
|---|---|---|
| root | 실제 본체의 가로 열과 원래 PNG 높이 전체 | 기존 root 속성 전부·본체 픽셀 |
| stage | 정렬 host 전체와 원래 PNG 높이 전체 | 크기·가운데 배치·본체 밖 하드웨어와 그림자 |

본체 PNG는 같은 stage PNG에서 실제 측정한 가로 열만 복사한다. 가로 경계는
`floor(left)..ceil(left+width)`이며 세로 픽셀은 전부 유지한다. 이미지 확대·
축소, 패딩, 마스크, 색 변경, 높이 보정은 없다. 범위가 원본을 벗어나거나
본체가 host 가운데·전체 높이를 차지하지 않으면 캡처 오류다.

**두 검사 중 하나라도 실패하면 그 키는 실패**다. 넓은 빈 배경으로 본체
차이를 희석할 수 없고, root만 잘라서 돌출부 검증을 잃지도 않는다.
기존 root 속성 17개를 그대로 선언한다. 기본 스타일 12칸의 전후 raw 속성은
삭제 0개, Web 변경 0개, Flutter는 root 폭만 실제 본체 폭으로 바뀌었다.
속성 입력 보존을 모든 속성 파리티 통과라는 뜻으로 확대하지 않는다.

제품 `coui_core/flutter/web`의 `lib/`, Core 계약, 공개 패키지 API, 예제 내용,
Figma 데이터는 변경하지 않았다. 문서 preview host와 내부 측정 도구의 변경이다.
디자인 수치나 기본값을 새로 정하지 않으며 디자이너 승인을 대신하지 않는다.

## 내부 산출물 계약

- 기존 `<key>.<platform>.png`는 root 본체, 추가
  `<key>.stage.<platform>.png`는 전체 stage다. JSON은 기존 파일의
  `byRole.root`를 유지하고 `byRole.stage`를 더한다.
- 일반 컴포넌트의 manifest와 파일명은 유지된다. 해당 6개 변형은 공통
  manifest 생산자 세 곳에서 root·stage를 함께 선언한다.
- 이 변형을 root만 선언한 낡은 manifest로 새로 캡처하면 재생성을 요구하는
  오류가 난다. 과거 report를 읽는 경로는 유지한다.
- stage 파일이 빠지면 root로 대체하지 않고 인프라 실패다. stage baseline이
  없으면 기존 root baseline으로 대체하지 않고 `첫 캡처`로 남긴다.
- report JSON의 기존 필드는 유지하며 키 단위 `matrix.counts/entries`를
  추가한다. 기존 headline은 probe 수다. 두 수를 섞지 않는다.

## 전체 기본 스타일 재촬영

새 catalog에서 만든 defaultStyle manifest는 748키·760 probe다. 기존과
같은 162개 컴포넌트, 라이트·다크 각 374키다. 캡처 직전 고정한 Dart 소스
18개 SHA-256을 촬영 뒤 다시 확인했고 변경은 없었다. 새로 생성한 PNG·JSON은
3,016개다. 이전 이미지를 최종 캡처로 재사용하지 않았다.

| 키 단위 | 수정 전 통합 main | 수정 후 |
|---|---:|---:|
| 통과 | 451 | **460** |
| 불일치 | 297 | **288** |
| 치수 불일치 | 110 | 100 |
| 같은 크기 픽셀 차이 | 187 | 188 |
| 새 실패 / 해소 | — | **0 / 9** |
| 인프라 누락 / skip | 0 / 0 | 0 / 0 |

실제 CLI 출력은 다음과 같다. report는 **exit 1**이며 통과로 기록하지 않는다.

```text
[report] 469 passed, 291 failed, 0 infra-skipped, 0 structural-skipped
[matrix] 460 passed keys, 288 failed keys, 0 infra keys, 0 skipped keys (748 total)
```

통과로 바뀐 것은 Mockup phone/tablet 4칸, MockupDevice default/flat 4칸,
ResponsiveContainer 라이트 1칸이다. 수정하지 않은 736키의 판정은 유지됐다.

대상 12칸 중 남는 실패는 다음과 같다.

- `mockup-landscape-{light,dark}-defaultStyle`: Flutter 본체 320×157,
  Web 320×156, stage도 800×157↔800×156이다. 실측 본체 높이는 Flutter
  156.30769230769232, Web 156.296875다. PNG 높이를 맞춰 지우지 않았다.
- `responsive-container-default-dark-defaultStyle`: 본체 7.226%, stage
  5.780%의 픽셀 차이로 둘 다 실패다. 비교 범위가 같아져 치수 실패에서
  같은 크기 픽셀 실패로 바뀌었으므로 픽셀 실패 수는 1 늘어난다.

[전체 760 probe CSV](parity-capture-regions-2026-11-16.csv)와
[요약·소스 지문 JSON](parity-capture-regions-2026-11-16.json)에 키·역할별
판정, 원본 크기, 차이 비율, 비교 범위와 검증 한계를 남겼다.

## 영향받는 모든 등록 스타일

위 6개 변형의 `defaultStyle/liquidGlass/neoBrutalism/claymorphism/neumorphism`
라이트·다크 60키·120 probe를 별도로 새로 촬영했다. **45키 통과·15키
불일치·누락 0**, probe는 90 통과·30 실패다. 남는 실패는 가로 Mockup
10키와 다크 ResponsiveContainer 5키다. report는 exit 1이다.
[스타일별 CSV](parity-capture-regions-styles-2026-11-16.csv)에 전부 남겼다.
이 결과를 다른 컴포넌트·상호작용·모든 스타일의 전체 검증으로 확대하지 않는다.

## own-baseline과 범위 변경의 영향

baseline·allowlist·임계값은 바꾸지 않았다. 교차 플랫폼 5%, 동일 플랫폼
0.1%, 채널차 32와 크기 불일치 실패 규칙이 그대로다.

| 기본 스타일 own-baseline | 수정 전 | 수정 후 |
|---|---:|---:|
| 비교 수행 | 1,496 | 1,496 |
| 통과 | 1,381 | 1,369 |
| 차이 | 115 | 127 |
| 추가 stage의 baseline 없음 | 0 | 24 |
| 승인 / skip / 인프라 실패 | 0 / 0 / 0 | 0 / 0 / 0 |

115개 기존 차이는 키·플랫폼·측정값이 모두 그대로다. 추가된 12개 차이는
Flutter root가 기존 800폭 캔버스에서 실제 본체 폭으로 바뀐 것이다.
양쪽 report는 exit 1이다. 이 127개를 교차 플랫폼 288키에 더하지 않는다.
[baseline 전후 CSV](parity-capture-regions-baseline-2026-11-16.csv)에 기존
115개·범위 변경 12개·stage 첫 캡처 24개 플랫폼 셀을 구분했다.

기본 스타일의 새 Flutter stage 12개는 수정 전 Flutter root와 RGBA 픽셀이
같다(최대 채널차 0). 원래 장식이 바뀌지 않았음을 별도로 확인했다.
영향받는 모든 스타일에서는 Web root 60개가 own-baseline 통과, Flutter root
60개가 범위 변경 차이, stage 120개 플랫폼 셀이 첫 캡처다. Flutter 전체
stage를 과거 root baseline과 대조한 진단도 60개 모두 기존 회귀 기준 안이다
(채널 임계값을 넘는 픽셀은 전체 합계 5개). 새 stage baseline의 통과로
간주하지 않으며 baseline 승격은 하지 않았다.

## 검사 자체의 검증과 빌드

| 실행 | 실제 결과 |
|---|---|
| 변경 Dart 18개 `dart analyze --fatal-infos` | `No issues found!` |
| 같은 18개 `dart format --set-exit-if-changed --output=none` | `0 changed` |
| 도구 model/report/manifest 및 Web capture 검사 | 202 통과·기존 skip 1 |
| Flutter 본체 geometry 검사 | 5 통과 |
| docs registry/fill-width 검사 | 31 통과 |
| Flutter 전체 capture / 대상 모든 스타일 capture | 748 / 60 촬영 성공 |
| Web 전체 capture / 대상 모든 스타일 capture | 748 / 60 촬영 성공 |
| `cd docs_site && jaspr build` | exit 0, 356 routes 생성 |

기존 skip은 catalog에 deprecated 컴포넌트가 없어 해당 제외 검사의 대상이
없는 경우다. 전체 수동 CI는 실행하지 않았다. 이 workspace의 실행 중 앱은
없어 hot reload 대신 새 Flutter 테스트 프로세스와 정적 빌드로 확인했다.

검사 우회 방지 증거:

- 본체가 완전히 틀려도 넓은 빈 배경 때문에 stage 픽셀 차이가 0.5%에
  그치는 fixture를 사용한다. 본체는 100% 차이이고 CLI 키 판정은 exit 1이다.
- 본체 열 대신 오른쪽 빈 배경까지 비교하도록 일부러 망가뜨리면 픽셀 보존,
  본체 실패, CLI 키 실패 검사 **3개가 실패**한다. 복구 뒤 관련 검사를 포함한
  위 202개가 통과했다.
- 실제 Web 캡처는 host 400/800에서 본체 열의 모든 픽셀이 stage 원본과
  같은지 확인한다. 현실적인 기기의 본체 밖 하드웨어 픽셀도 stage에 남는다.
- 낡은 root-only manifest는 캡처 오류다. 실제 stage 파일 하나를 뺀 별도
  fixture에서 report는 `0 passed keys, 1 infra keys`, exit 2로 끝났다.

재현할 때는 현재 manifest를 새로 만들고 defaultStyle 748키와 위 6개 변형의
모든 등록 스타일 60키를 각각 고른다. 두 플랫폼의 fresh capture가 끝난 뒤
같은 manifest로 `report.dart --signal=pixel --mode=parity`와
`--mode=regression`을 별도로 실행한다. 추가 stage PNG를 빼면 검증 완료가 아니다.
기존 [재촬영 명령](parity-remeasurement-2026-11-16.md)의 manifest/capture/report
절차를 그대로 쓰되, 오래된 manifest를 복사하지 않는다.
