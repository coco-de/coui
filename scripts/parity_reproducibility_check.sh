#!/usr/bin/env bash
# parity_reproducibility_check.sh
#
# #3618 Phase A's own completion definition: "동일 커밋 3회 반복 실행
# 스크립트로 재현 성공률 측정" — the 2-week false-positive-rate soak needs
# to distinguish "a real cross-platform difference" from "the pipeline
# itself is flaky" (a capture that occasionally times out, a browser
# launch that occasionally fails). This script runs the same manifest →
# capture → compare sequence `parity-gate` (ci.yaml) runs, N times against
# the *same* checked-out commit, and reports how many runs agreed with
# each other.
#
# Not wired into ci.yaml itself — running the full parity pipeline 3x on
# every PR would triple this job's cost for zero per-PR benefit. Run this
# manually (or from a periodic `workflow_dispatch`) during the Phase A/B
# soak and record the result in the tracking issue (#3619).
#
# Usage:
#   ./scripts/parity_reproducibility_check.sh [--runs N] [--components CSV]
#
#   --runs N            How many repeat runs (default: 3).
#   --components CSV    Restrict to these catalog slugs (default: whatever
#                        --changed-from=HEAD~1 selects — i.e. the last
#                        commit's own changed components, so this script
#                        is meaningful to run right after a real PR merge).
#
# Exit codes: 0 every run's exit code matched, 1 the runs disagreed (the
# reproducibility signal Phase A/B promotion needs), 2 usage/infra error.
set -uo pipefail

RUNS=3
COMPONENTS_FLAG=""
CHANGED_FROM="HEAD~1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runs)
      RUNS="$2"
      shift 2
      ;;
    --components)
      COMPONENTS_FLAG="--components=$2"
      CHANGED_FROM=""
      shift 2
      ;;
    --help | -h)
      sed -n '2,26p' "$0"
      exit 0
      ;;
    *)
      echo "❌ 알 수 없는 인자: $1" >&2
      exit 2
      ;;
  esac
done

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -lt 2 ]]; then
  echo "❌ --runs 는 2 이상의 정수여야 한다 (받은 값: $RUNS)." >&2
  exit 2
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "[repro] $RUNS 회 반복 실행 — 작업 디렉토리: $WORKDIR"

declare -a EXIT_CODES=()
declare -a FAILED_KEYS_FILES=()

for i in $(seq 1 "$RUNS"); do
  RUN_DIR="$WORKDIR/run-$i"
  mkdir -p "$RUN_DIR/captured" "$RUN_DIR/diff"

  echo "[repro] run $i/$RUNS — manifest"
  if [[ -n "$COMPONENTS_FLAG" ]]; then
    dart run tool/parity/manifest.dart $COMPONENTS_FLAG --tier=t1 \
      --out="$RUN_DIR/manifest.json"
  else
    dart run tool/parity/manifest.dart --tier=t1 \
      --changed-from="$CHANGED_FROM" --out="$RUN_DIR/manifest.json"
  fi

  echo "[repro] run $i/$RUNS — capture (web)"
  dart run tool/parity/capture_web.dart \
    --manifest="$RUN_DIR/manifest.json" --out="$RUN_DIR/captured"

  echo "[repro] run $i/$RUNS — report (property signal only — pixel is"
  echo "        blocked on #3657's dimension-normalization prerequisite,"
  echo "        see gate_phase.dart; Flutter capture is #3652's gap, so"
  echo "        every entry here infra-skips until that lands too — this"
  echo "        script still measures *Web-capture* reproducibility, which"
  echo "        is the piece most exposed to browser-launch flakiness)"
  dart run tool/parity/report.dart \
    --manifest="$RUN_DIR/manifest.json" \
    --captured="$RUN_DIR/captured" \
    --out="$RUN_DIR/diff" \
    --comment-out="$RUN_DIR/pr-comment.md" \
    --signal=property
  run_exit=$?
  EXIT_CODES+=("$run_exit")
  echo "[repro] run $i/$RUNS — exit $run_exit"
done

echo ""
echo "[repro] exit codes across $RUNS runs: ${EXIT_CODES[*]}"

FIRST="${EXIT_CODES[0]}"
DISAGREED=0
for code in "${EXIT_CODES[@]}"; do
  if [[ "$code" != "$FIRST" ]]; then
    DISAGREED=1
  fi
done

if [[ "$DISAGREED" -eq 1 ]]; then
  echo "❌ [repro] 재현 실패 — 동일 커밋인데 실행마다 결과가 다르다 (플레이키니스 의심)."
  echo "   #3619 이슈에 이 출력을 기록하고 오탐율 계산에서 이 커밋을 별도 표시할 것."
  exit 1
fi

echo "✅ [repro] $RUNS 회 모두 동일 결과 (exit $FIRST) — 재현 가능."
exit 0
