#!/usr/bin/env bash
# Gate: a GatePhase promotion must actually block merges, or the comment
# that promises it is a lie.
#
# `tool/parity/src/gate/gate_phase.dart`'s `GatePhase.current` drives
# `ci.yaml`'s `parity-gate` job — the "Compare + Report" step's *step-level*
# `continue-on-error` is a live expression reading `GatePhase.current`
# (`requires_property`/`requires_pixel`), so promoting the Dart constant
# really does turn that one step blocking. `ci.yaml:239-246`'s comment reads
# that live wiring and concludes a promotion needs "no workflow edit" — but
# the *job-level* `continue-on-error: true` (`ci.yaml:215`) unconditionally
# forces the job's own conclusion to success regardless of any step's
# result, and no `needs: parity-gate` job exists to propagate a failure
# either. So a promoted phase can fail its now-blocking step and the
# workflow run still finishes green — "required" only on paper. #3663 item 1
# found this by reading both files; this gate makes the mismatch a build
# failure instead of something that has to be rediscovered by audit.
#
# What this checks: IF `GatePhase.current` is anything other than
# `GatePhase.a` (i.e. promoted to b/c, meaning at least one signal is
# supposed to be required), THEN `ci.yaml`'s `parity-gate` job must NOT
# still carry a job-level `continue-on-error: true` — that flag is what
# swallows the step's now-real failure. This is a necessary condition for
# the promotion to actually block anything, not a sufficient one: removing
# the job-level flag still leaves the job un-registered as a GitHub
# required status check (a repo-settings decision, not something a text
# file can assert), so this gate does not claim merges are blocked — only
# that the workflow itself no longer contradicts the promotion.
#
# What this deliberately does NOT do: touch or remove the job-level
# `continue-on-error: true` while `GatePhase.current` is still `a` — Phase A
# is advisory by design, and removing the flag is a decision that belongs
# together with registering the required status check (human call), not a
# side effect of adding this gate.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

CI_YAML=".github/workflows/ci.yaml"
GATE_PHASE_DART="tool/parity/src/gate/gate_phase.dart"

if [ ! -f "$CI_YAML" ]; then
  echo "❌ gate-phase-wiring gate: $CI_YAML 를 찾지 못함."
  exit 1
fi
if [ ! -f "$GATE_PHASE_DART" ]; then
  echo "❌ gate-phase-wiring gate: $GATE_PHASE_DART 를 찾지 못함."
  exit 1
fi

# 1. GatePhase.current 추출 — "static const GatePhase current = GatePhase.X;"
current_phase=$(
  grep -oE 'static const GatePhase current = GatePhase\.[a-z]+;' "$GATE_PHASE_DART" \
    | sed -E 's/.*GatePhase\.([a-z]+);/\1/'
)

if [ -z "$current_phase" ]; then
  echo "❌ gate-phase-wiring gate: GatePhase.current 를 $GATE_PHASE_DART 에서 파싱하지 못함."
  echo "   'static const GatePhase current = GatePhase.<phase>;' 형태를 기대함 —"
  echo "   선언이 리네임/재포맷됐다면 이 가드도 함께 갱신할 것."
  exit 1
fi

# 2. ci.yaml 의 parity-gate 잡 블록만 추출 — 다음 2-space-indent 잡 키(또는
#    파일 끝)까지. 이 경계 없이 전체 파일에서 grep 하면 다른 잡의
#    continue-on-error 나 이 잡 자신의 스텝 레벨 continue-on-error 까지
#    같이 잡혀 오탐/누락이 생긴다.
job_block=$(awk '
  /^  parity-gate:[[:space:]]*$/ { capture=1; print; next }
  capture && /^  [A-Za-z_-]+:[[:space:]]*$/ { exit }
  capture { print }
' "$CI_YAML")

if [ -z "$job_block" ]; then
  echo "❌ gate-phase-wiring gate: $CI_YAML 에서 'parity-gate:' 잡을 찾지 못함."
  echo "   잡 이름이 바뀌었다면 이 가드의 awk 패턴도 함께 갱신할 것."
  exit 1
fi

# 3. 잡 블록 안, 정확히 4-space indent 인 continue-on-error: 만 = 잡
#    레벨(현재 파일에서 job 프로퍼티는 4-space, 그 안 스텝은 6-space
#    '- name:' 아래 8-space 이상). 스텝 레벨 continue-on-error(예:
#    "Compare + Report" 의 라이브 표현식)는 8-space라 이 패턴에 안 걸린다.
job_level_coe=$(
  printf '%s\n' "$job_block" \
    | grep -E '^    continue-on-error:[[:space:]]*true[[:space:]]*$' || true
)

echo "GatePhase.current = $current_phase"
if [ -n "$job_level_coe" ]; then
  echo "parity-gate job-level continue-on-error: true"
else
  echo "parity-gate job-level continue-on-error: (absent/false)"
fi

if [ "$current_phase" != "a" ] && [ -n "$job_level_coe" ]; then
  echo
  echo "❌ gate-phase-wiring gate 실패."
  echo "   GatePhase.current 가 '$current_phase' 로 승격됐는데(Phase A 아님)"
  echo "   $CI_YAML 의 parity-gate 잡은 여전히 잡 레벨"
  echo "   continue-on-error: true 를 갖고 있다 — 이 플래그가 잡 결론을"
  echo "   항상 success 로 바꾸므로, 스텝 레벨 게이팅(Compare + Report 의"
  echo "   continue-on-error 표현식)이 실제로 블로킹이 되어도 워크플로"
  echo "   실행 전체는 초록으로 끝난다. ci.yaml:239-246 주석이 약속하는"
  echo "   'Dart 상수 1개 변경'과 실제 배선이 어긋난다 (#3663 item 1)."
  echo
  echo "   승격 시 다음을 함께 할 것:"
  echo "     (a) $CI_YAML 의 parity-gate 잡 레벨 continue-on-error: true 제거"
  echo "     (b) 그 잡을 GitHub main 브랜치의 required status check 로 등록"
  echo "         (저장소 설정에서 하는 사람의 결정 — 이 가드는 (a)만 강제한다)"
  exit 1
fi

echo "✔ gate-phase-wiring gate passed — GatePhase.current(=$current_phase) 와"
echo "  $CI_YAML 의 parity-gate 잡 레벨 continue-on-error 배선이 어긋나지 않는다."
