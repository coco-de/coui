#!/usr/bin/env bash
# 가드가 자기 자신을 무작위로 빨갛게 만드는 형태 하나를 센다 — `pipefail`
# 아래에서 **파이프로** `grep -q` 에 먹이는 것.
#
# ## 무엇이 잘못되나
#
# `-q` 는 첫 매치에서 즉시 나가며 파이프를 닫는다. 아직 쓰고 있던 왼쪽
# (`echo` / `printf` / `awk`)이 EPIPE 로 죽고, `set -o pipefail` 이 그 실패를
# 파이프라인의 종료 상태로 삼는다. 그래서 **매치했을 때** 파이프라인이 비-0 을
# 낸다 — "찾았다" 가 "실패했다" 로 뒤집히고, `! pipeline` 로 감싼 자리에서는
# 결론이 정확히 반대가 된다.
#
# 재현(입력이 커야 경주가 난다):
#
#     big=$(python3 -c "print('x\n'*200000, end='')")
#     ( set -o pipefail; echo "$big" | grep -q x ); echo $?   # → 141
#     ( set -o pipefail; grep -q x <<<"$big" );     echo $?   # → 0
#
# 실측(이 가드가 생긴 이유): `check_obscure_text_parity.sh` 가 CI 에서
# `echo: write error: Broken pipe` 한 줄과 함께 "obscured 상태를 선언만 하고
# 읽지 않는다" 는 **거짓 고발**을 냈고, 같은 커밋이 로컬에서는 통과했다. 무관한
# PR 이 그 red 로 막혔다.
#
# ## 왜 ratchet 인가
#
# 경주라서 매번 나지 않는다 — 그게 이 버그의 최악인 지점이다. 무작위로
# 빨개지는 가드는 고쳐지는 대신 무시되고, 무시되기 시작하면 그 가드가 잡던
# 진짜 위반도 같이 지나간다.
#
# 그런데 지금 열려 있는 자리가 한 곳이 아니다. 전부를 한 번에 바꾸는 것은
# 가드 여덟 개의 동작을 동시에 건드리는 일이라, 그 자체가 이 버그보다 큰
# 위험이다(중간에 `awk` 가 낀 3단 파이프는 단순 치환으로 안 끝난다). 그래서
# **새로 늘어나는 것만 막고** 남은 것은 세어 둔다 — 실제로 터진 자리는 이미
# 고쳤고, 나머지는 그 자리를 만질 때 같이 간다.
#
# ## 고치는 법
#
# 파이프를 없앤다 — `grep -q PAT <<<"$x"`. here-string 은 쓰는 쪽이 존재하지
# 않아 EPIPE 가 날 자리가 없다. 입력이 파일이면 `grep -q PAT file`.
set -euo pipefail

cd "$(dirname "$0")/../../.."

# 남은 자리. 줄이는 방향으로만 바꾼다.
readonly BASELINE=5

# 파이프(`|`) 바로 뒤의 `grep`/`egrep` 이 `q` 를 포함한 짧은 옵션 묶음을 받는
# 형태. `||` 는 파이프가 아니므로 제외한다 — 앞 문자가 `|` 가 아닐 때만.
readonly PATTERN='[^|]\|[[:space:]]*(command[[:space:]]+)?e?grep[[:space:]]+-[a-zA-Z]*q'

total=0
report=""
while IFS= read -r file; do
  # 자기 자신은 이 형태를 문서와 패턴으로 들고 있다.
  [ "$file" = "./scripts/guards/structure/check_guard_sigpipe.sh" ] && continue
  grep -qE '^[[:space:]]*set[[:space:]]+(-[a-zA-Z]*o[[:space:]]+pipefail|-o[[:space:]]+pipefail)' "$file" || continue
  found=$(grep -nE "$PATTERN" "$file" | grep -vE '^[0-9]+:[[:space:]]*#' || true)
  [ -z "$found" ] && continue
  n=$(printf '%s\n' "$found" | wc -l | tr -d ' ')
  total=$((total + n))
  report="${report}  ${file}
$(printf '%s\n' "$found" | sed 's/^/    /')
"
done < <(find ./scripts/guards -name '*.sh' -type f | sort)

if [ "$total" -gt "$BASELINE" ]; then
  echo "❌ pipefail 아래 파이프+\`grep -q\` ${total}건 (baseline ${BASELINE}) — 늘었다."
  echo "   매치했을 때 EPIPE 로 종료 상태가 뒤집혀 가드가 거짓 고발을 낸다."
  printf '%s' "$report"
  echo "   고치는 법: \`grep -q PAT <<<\"\$x\"\` (here-string — 파이프 없음)."
  exit 1
fi

if [ "$total" -lt "$BASELINE" ]; then
  echo "❌ ${total}건 — baseline(${BASELINE})보다 줄었다. 이 스크립트의"
  echo "   BASELINE 을 ${total} 로 내려 되돌아오지 못하게 하라."
  exit 1
fi

echo "✔ guard-sigpipe gate passed — pipefail 가드의 파이프+grep -q ${total}건 (baseline ${BASELINE}), net-new 없음."
