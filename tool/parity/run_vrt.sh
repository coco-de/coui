#!/usr/bin/env bash
# 로컬 VRT 실행기 — 지정한 컴포넌트를 두 빌드 환경(Flutter · Web)에서
# 캡처하고, 각 플랫폼을 자기 committed baseline 과 픽셀 비교한 뒤,
# 컴포넌트별 비주얼 회귀 리포트(vrt-report.md)를 쓴다.
#
#   melos run parity:vrt -- button card
#   bash tool/parity/run_vrt.sh button card
#
# 산출물 (기본 경로 — report.dart 의 default 와 동일):
#   test/parity/captured/            <key>.{flutter,web}.{png,json}
#   test/parity/diff/                실패 셀의 diff PNG
#   test/parity/report/vrt-report.md 영향 범위 · 회귀 상세 · 검증
#
# baseline 이 아직 없는 키는 "baseline 없음(첫 캡처)" 으로 보고된다 —
# 캡처를 검토한 뒤 `melos run parity:promote` 로 승격하면 다음 실행부터
# 회귀 비교가 돈다.
#
# `--signal=pixel --mode=regression` — 이 스크립트는 순수 VRT 루프다:
# 크로스플랫폼 property/parity 비교는 PR 게이트(parity-gate)의 몫이고,
# 여기서는 "같은 플랫폼이 어제와 같은 픽셀을 그리는가" 만 본다.
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "사용법: melos run parity:vrt -- <component> [component ...]" >&2
  echo "  예:   melos run parity:vrt -- button card" >&2
  exit 2
fi

root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"

components=$(IFS=,; echo "$*")
# mktemp -d — macOS(BSD) mktemp 는 XXXXXX 가 템플릿 **끝**에 있어야만
# 치환한다 (`prefix.XXXXXX.json` 은 리터럴 파일명이 되어 두 번째 실행부터
# "File exists" 로 죽는다). 디렉터리를 만들고 고정 이름을 그 안에 둔다.
workdir=$(mktemp -d /tmp/coui-vrt.XXXXXX)
manifest="$workdir/manifest.json"

echo "[vrt] manifest — components: $components"
dart run tool/parity/manifest.dart \
  --components="$components" \
  --out="$manifest"

echo "[vrt] capture — Flutter"
# cwd 는 packages/coui_flutter 여야 한다 — loadParityFonts() 가 vendored
# 폰트 디렉터리를 그 패키지 루트 기준으로 찾는다 (ci.yaml 과 동일).
(cd packages/coui_flutter &&
  PARITY_MANIFEST="$manifest" \
  PARITY_OUT="$root/test/parity/captured" \
  flutter test --tags parity test/parity/flutter_capture_matrix_test.dart)

echo "[vrt] capture — Web"
dart run tool/parity/capture_web.dart \
  --manifest="$manifest" \
  --out="$root/test/parity/captured"

echo "[vrt] compare + report"
# 이전 실행이 남긴 리포트를 먼저 지운다 — report.dart 가 쓰기 전에
# 죽으면(인프라 실패 exit 2) stale 리포트를 이번 실행 결과처럼 cat 하게
# 되는 것을 막는다.
rm -f test/parity/report/vrt-report.md
rc=0
dart run tool/parity/report.dart \
  --manifest="$manifest" \
  --signal=pixel \
  --mode=regression || rc=$?

if [ -f test/parity/report/vrt-report.md ]; then
  echo
  cat test/parity/report/vrt-report.md
else
  echo "[vrt] 리포트가 생성되지 않음 (exit=$rc) — 위 로그의 인프라 실패를 확인하라." >&2
fi
exit $rc
