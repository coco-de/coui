#!/usr/bin/env bash
# 가드가 존재한다는 것과 가드가 막는다는 것은 다른 문장이다 — 이 가드는 그
# 둘 사이의 틈을 센다: `scripts/guards/` 아래의 가드 진입점이 **어떤
# 워크플로에서도 불리지 않는** 상태.
#
# ## 무엇이 잘못되나
#
# 가드 디렉터리마다 CI 가 가드를 부르는 방식이 다르다. 어떤 디렉터리는
# glob 루프로 불러 새 가드가 들어오는 순간 자동으로 돌고, 어떤 디렉터리는
# 워크플로에 **이름을 한 줄씩** 적는다. 뒤의 방식은 가드를 추가하는 사람이
# 워크플로도 같이 고쳐야 하는데, 그 두 번째 편집을 요구하는 것이 아무것도
# 없다.
#
# 실제로 그렇게 새었다: z-index 리터럴을 막는 가드가 만들어진 뒤 워크플로에
# 줄이 없어 한 번도 돌지 않았고, 그 다섯 주 뒤 그 가드가 막았어야 할 리터럴
# 두 개가 초록 CI 를 통과해 들어왔다. 로컬에서 가드를 전부 돌려 보기 전까지
# 아무도 몰랐다 — 가드는 제자리에 얌전히 있었고, 위반은 초록 뒤에 있었다.
#
# ## 판정
#
# 가드 진입점(`check_*.sh` · `check_*.py` · `verify_*.sh`)마다 다음 중
# 하나가 참이어야 한다:
#
#   1. 어떤 워크플로 파일이 그 경로를 그대로 적는다.
#   2. 어떤 워크플로 파일이 그 경로에 맞는 glob(`scripts/guards/<dir>/check_*.sh`
#      같은 루프 대상)을 적는다.
#   3. 아래 면제 목록에 **사유와 함께** 있다.
#
# 면제는 드물어야 한다 — 돌지 않는 가드는 대개 지우거나 배선할 대상이다.
# 면제 항목이 가리키는 파일이 사라지면 그 항목도 실패로 센다: 죽은 면제는
# 다음 사람에게 "이 이름은 일부러 안 돈다" 는 거짓을 남긴다.
#
# ## 보지 않는 것
#
# 워크플로에 적혀 있다는 것이 그 스텝이 실제로 **실행**된다는 뜻은 아니다 —
# 경로 필터 · `if:` 조건 · 도구 설치 순서가 가드를 조용히 건너뛰게 할 수
# 있다. 설치 순서는 `check_ci_guard_deps_order.sh` 가 보고, 나머지는 리뷰가
# 본다.
set -uo pipefail

cd "$(dirname "$0")/../../.." || exit 1

readonly WORKFLOW_DIR=".github/workflows"
readonly GUARD_ROOT="scripts/guards"

# 면제 — "경로|사유". 사유가 비어 있으면 실패한다.
readonly EXEMPT=(
  "scripts/guards/tokens/check_tailwind_config_completeness.sh|check_tailwind_theme_config_parity.sh 가 같은 Tailwind config 맵 검사를 포함해 등록면 전부를 보는 엄격한 상위집합이라, 이 가드를 따로 돌리면 같은 위반을 두 번 보고할 뿐이다"
)

if [ ! -d "$WORKFLOW_DIR" ]; then
  echo "❌ $WORKFLOW_DIR 없음"
  exit 1
fi

workflow_files=()
while IFS= read -r f; do
  workflow_files+=("$f")
done < <(find "$WORKFLOW_DIR" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)

if [ "${#workflow_files[@]}" -eq 0 ]; then
  echo "❌ $WORKFLOW_DIR 에 워크플로 파일이 없음 — 판정할 수 없다"
  exit 1
fi

workflow_text=$(cat "${workflow_files[@]}")

# 워크플로에 적힌 가드 glob — `*` 를 포함한 scripts/guards/ 경로 토큰.
globs=()
while IFS= read -r g; do
  [ -n "$g" ] && globs+=("$g")
done < <(grep -oE "${GUARD_ROOT}/[A-Za-z0-9_./-]*\*[A-Za-z0-9_.*-]*" <<<"$workflow_text" | sort -u)

guards=()
while IFS= read -r g; do
  guards+=("$g")
done < <(find "$GUARD_ROOT" -type f \( -name 'check_*.sh' -o -name 'check_*.py' -o -name 'verify_*.sh' \) | sort)

if [ "${#guards[@]}" -eq 0 ]; then
  echo "❌ $GUARD_ROOT 에서 가드 진입점을 하나도 찾지 못함 — 판정할 수 없다"
  exit 1
fi

exempt_reason() {
  local path="$1" entry
  for entry in "${EXEMPT[@]}"; do
    if [ "${entry%%|*}" = "$path" ]; then
      printf '%s' "${entry#*|}"
      return 0
    fi
  done
  return 1
}

fail=0
wired=0
exempted=0
unwired=()

for guard in "${guards[@]}"; do
  if grep -qF -- "$guard" <<<"$workflow_text"; then
    wired=$((wired + 1))
    continue
  fi
  matched=0
  for glob in ${globs[@]+"${globs[@]}"}; do
    # shellcheck disable=SC2053 — 오른쪽을 패턴으로 쓰는 것이 의도다.
    if [[ "$guard" == $glob ]]; then
      matched=1
      break
    fi
  done
  if [ "$matched" -eq 1 ]; then
    wired=$((wired + 1))
    continue
  fi
  if reason=$(exempt_reason "$guard"); then
    if [ -z "$reason" ]; then
      echo "❌ 면제에 사유가 없다: $guard"
      fail=1
    fi
    exempted=$((exempted + 1))
    continue
  fi
  unwired+=("$guard")
done

for entry in "${EXEMPT[@]}"; do
  path="${entry%%|*}"
  if [ ! -f "$path" ]; then
    echo "❌ 면제가 가리키는 파일이 없다 — 항목을 지운다: $path"
    fail=1
  elif grep -qF -- "$path" <<<"$workflow_text"; then
    echo "❌ 면제된 가드가 이미 워크플로에 배선돼 있다 — 면제를 지운다: $path"
    fail=1
  fi
done

if [ "${#unwired[@]}" -gt 0 ]; then
  echo "❌ 어떤 워크플로에서도 불리지 않는 가드 ${#unwired[@]}개:"
  for g in "${unwired[@]}"; do
    echo "     $g"
  done
  echo "   → 워크플로에 한 줄 배선하거나(가드가 지금 red 면 위반을 같은 PR 에서"
  echo "     고친다), 돌 필요가 없으면 지운다. 정말 남겨야 하면 이 파일의 면제에"
  echo "     사유와 함께 적는다."
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "✅ 가드 진입점 ${#guards[@]}개 — 배선 ${wired} · 면제 ${exempted} · 미배선 0"
fi

exit "$fail"
