# 최신 main 기본 스타일 파리티 재측정 (2026-11-16)

Part of [#6131](https://github.com/coco-de/coui/issues/6131).

최신 main `0459dd702f2a66aa2c68b2046ab2c5c97f9e65dc`에서 Flutter와 Web을
모두 새로 촬영했다. 결과는 **451 통과·297 불일치·누락 0**이다. 앞선
main 통합 검증과 실패 키 297개가 정확히 같다. 새 실패와 해소된 실패는 각각
0개이며, **전체 파리티 작업은 아직 완료되지 않았다**.

## 측정 범위와 조건

- 기본 표면 스타일 `defaultStyle`, 162개 컴포넌트, 748개 variant/theme 조합.
  라이트와 다크 각각 374칸이다. 전체 스타일·상호작용·애니메이션 주기를
  검증한 결과로 확대하지 않는다.
- 2026-11-16 10:14~10:22 KST에 측정했다. 시작 전과 완료 후 fetch에서
  `origin/main`이 위 SHA와 같음을 확인했다. 측정 동안 제품 소스는 변경하지 않았다.
- 최신 registry에서 manifest를 다시 생성했다. 이전 748칸과 키·probe 사양이
  같으며, canonical JSON SHA-256은
  `835f2f61c7a9363fe613664e0b4dcda7b9b2024a86e187eb7bdc29a462ec95c6`이다.
- 이전 캡처를 재사용하지 않고 플랫폼별 PNG 748개·JSON 748개,
  합계 2,992개 파일을 새로 생성했다.
- Flutter 3.47.9 (`c197ca5199e9ee5661e865596c9c07294dfab51c`), Dart 3.13.7,
  Chrome 150.0.7871.24를 사용했다.
- 기존 픽셀 gate와 5% 임계값을 그대로 사용했다. 크기가 다르면 실패다.
  baseline·allowlist·임계값을 변경하지 않았다.

## 결과

| 구분 | 이전 main 통합 검증 | 최신 main 재측정 |
|---|---:|---:|
| 통과 | 451 | 451 |
| 불일치 | 297 | 297 |
| 인프라 누락 | 0 | 0 |
| 구조적 skip | 0 | 0 |

현재 실패는 **치수 불일치 110칸·같은 크기의 픽셀 차이 187칸**이며,
78개 컴포넌트에 걸쳐 있다. 297칸은 개별 버그 297개를 뜻하지 않는다.
각 원인의 실제 결함 여부를 더 확인해야 하며, 모두 불가피한 엔진 차이로
확정하지 않는다.

[키별 CSV](parity-remeasurement-2026-11-16.csv)에 748칸 전체의 이전/현재
판정, 양쪽 크기, 실패 측정값, 캡처 단계를 기록했다.
[기계 판독용 요약](parity-remeasurement-2026-11-16.json)도 함께 남긴다.
이전 판정은 직전 451/297 통합 report와 대조했다. 과거 리뷰 분류를 이번
측정의 원인 판정으로 복사하지 않았다.

같은 플랫폼의 이전 PNG와도 비교했다. 23개 이미지가 바뀌었지만 교차 플랫폼
통과/실패 판정은 모두 유지됐다(Calendar 20개, Tabs 2개, Command 1개).
따라서 실패 키가 같다는 결과를 모든 픽셀이 같다는 주장으로 읽지 않는다.
이 이미지 변화만으로 새 제품 결함을 확정하지 않았다.

## 통과 중 캡처 시점 재확인이 필요한 8칸

Flutter 메타데이터는 `settled-runtime` 718칸, 의도된 `initial-frame` 22칸,
`unsettled-runtime` 8칸이다. 마지막 8칸은 반복 애니메이션으로
`pumpAndSettle`이 정착하지 않은 상태다. 원시 픽셀 report에서는 모두
통과했지만, 비교 시점이 정합하다고 확정하지 않는다.

- `loading-region-default-{light,dark}-defaultStyle` — 2칸
- `skeleton-{default,circle,text}-{light,dark}-defaultStyle` — 6칸

CSV의 `capture_review=unsettled_animation`으로 이 8칸을 표시했다.
이 항목을 빼면 740칸에서 **443 통과·297 불일치**다. 이 보조 집계는
원래 gate의 451/297을 대체하지 않으며, 인프라 실패나 제품 버그 8개를
추가로 발견했다는 뜻도 아니다. 고정 phase 등 비교 시점의 근거를 보강한 뒤
재확인해야 한다. 나머지 정적 통과 역시 모든 런타임 상태의 보증은 아니다.

## 재현 명령과 실제 종료 상태

아래 명령은 측정 대상 SHA를 checkout한 상태에서 실행한다. `PARITY_RUN`은
새 빈 디렉터리여야 한다. 두 플랫폼 캡처가 모두 끝난 뒤 report를 실행한다.

```sh
PARITY_RUN=$(mktemp -d "${TMPDIR:-/tmp}/coui-parity-XXXXXXXX")
export PARITY_RUN
dart run tool/parity/manifest.dart --out="$PARITY_RUN/catalog.json"
python3 - <<'PY'
import json
import os
from pathlib import Path
p = Path(os.environ['PARITY_RUN'])
catalog = json.loads((p / 'catalog.json').read_text())
matrix = {'entries': [e for e in catalog['entries']
                      if e['surfaceStyle'] == 'defaultStyle']}
(p / 'manifest.json').write_text(json.dumps(matrix, indent=2) + '\n')
PY

dart run tool/parity/capture_web.dart \
  --manifest="$PARITY_RUN/manifest.json" --out="$PARITY_RUN/captured"
(
  cd packages/coui_flutter
  PARITY_MANIFEST="$PARITY_RUN/manifest.json" \
    PARITY_OUT="$PARITY_RUN/captured" \
    flutter test test/parity/flutter_capture_matrix_test.dart -r expanded
)

dart run tool/parity/report.dart \
  --manifest="$PARITY_RUN/manifest.json" --captured="$PARITY_RUN/captured" \
  --signal=pixel --mode=parity --out="$PARITY_RUN/diff" \
  --comment-out="$PARITY_RUN/comment.md" --vrt-out="$PARITY_RUN/vrt.md" \
  --report-json="$PARITY_RUN/report.json"
```

| 실행 | 실제 결과 |
|---|---|
| manifest 생성 | exit 0, 기본 스타일 748칸 |
| Flutter capture matrix | exit 0, `+748: All tests passed!` |
| Web capture | exit 0, 748칸 완료 |
| pixel report | exit 1, `451 passed, 297 failed, 0 infra-skipped, 0 structural-skipped` |

capture test의 성공은 촬영 성공을 뜻한다. 교차 플랫폼 파리티 gate는
실패 297칸 때문에 exit 1이다. 이번 재측정에서 제품 코드·디자인 값·공개 API를
수정하지 않았다. 전체 CI와 별도의 동작 회귀 검사는 이번 측정에서 실행하지 않았다.
