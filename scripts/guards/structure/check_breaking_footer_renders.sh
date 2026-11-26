#!/usr/bin/env bash
# A breaking change that release-please cannot render is not announced.
#
# 0.131 shipped with this bullet in three CHANGELOGs:
#
#     * **core:**
#
# Nothing after the colon. Behind that blank line were five
# `BREAKING CHANGE:` footers — `Alert.title` flipping to required, Toast's
# default variant changing what it renders, `CoreToastVariant` gaining a
# member that breaks exhaustive switches, Button's three state-layer
# fields collapsing into one, `CoreFormattedInputStyle` gaining two.
# None of it reached a consumer. The tag is cut; CHANGELOG is append-only;
# that release is permanently silent about its own biggest change.
#
# Two distinct defects produced it, and this guard checks both because
# either one alone is enough to lose the announcement:
#
#   1. EMPTY SUMMARY — `BREAKING CHANGE:` with nothing on the rest of the
#      line. release-please takes the same-line text as the bullet, so an
#      indented list starting on the NEXT line renders as an empty string.
#
#   2. MULTIPLE FOOTERS — more than one `BREAKING CHANGE:` in one commit.
#      Only the first is read. The rest are dropped with no warning, which
#      is how four of those five vanished.
#
#   3. FOOTERS SPREAD ACROSS A PR — each commit carries one, so (2) passes
#      on every one of them, and then `--squash` concatenates the bodies
#      into a single commit carrying several. That commit is the one
#      release-please reads, and nothing ever checks it: this gate runs on
#      `pull_request`, so it sees the branch's commits, never the commit
#      the merge will mint. Every multi-footer commit in this repository's
#      history — six of them — was born exactly that way. So when the range
#      is one PR's commits, the count that matters is the range's total,
#      not each commit's.
#
#      The escape is not to silence this: consolidate the footers into one
#      commit, or rebase-merge so the commits stay separate. Writing the
#      squash message by hand works too, but it is a promise made at merge
#      time about text the gate cannot see.
#
# Scope: commits not yet released — the exact set whose footers the next
# release will render. Already-tagged history is out of reach (the
# CHANGELOG is written), so scanning it would only produce debt nobody
# can pay.
#
# This does NOT check that the text is true, or that a breaking change
# carries a footer at all — a `!` subject with no footer renders its
# subject line, which is legitimate. It checks the two shapes that
# silently discard text someone wrote on purpose.
set -uo pipefail

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

cd "$(dirname "$0")/../../.." || exit 1

BASELINE=$(ratchet_int "$_GUARD_DIR/breaking_footer_renders_baseline.txt") || exit 1

# Range override exists so the regression can be injected against real
# history: RANGE=<tag>..<sha> ./check_breaking_footer_renders.sh
RANGE="${RANGE:-}"
# Set when RANGE is one PR's commits — see defect 3. An explicit RANGE (the
# regression harness) states it with PR_SCOPE=1 rather than guessing.
PR_SCOPE="${PR_SCOPE:-0}"

if [ -z "$RANGE" ]; then
  # The branch the PR merges into. A sub-PR of an epic squashes into the
  # epic, not main — counting from main would add every epic commit
  # already merged, each with its own footer, and fail every sub-PR for
  # commits it does not own. Off a PR (push, local) it is main.
  BASE_REF="${GITHUB_BASE_REF:-main}"
  BASE="origin/$BASE_REF"
  git rev-parse --verify -q "$BASE" >/dev/null || BASE=origin/main
  # A branch's own commits, not "everything since the nearest tag".
  # `git describe` walks ancestors, so a branch cut before the last
  # release resolves to the release before it and the guard would flag
  # commits that already shipped — a failure nobody can fix, which is how
  # a gate gets turned off instead of obeyed.
  if git rev-parse --verify -q "$BASE" >/dev/null &&
    [ -n "$(git rev-list --count "$BASE"..HEAD 2>/dev/null)" ] &&
    [ "$(git rev-list --count "$BASE"..HEAD 2>/dev/null)" != "0" ]; then
    RANGE="$(git merge-base "$BASE" HEAD)..HEAD"
    # These commits become ONE commit when the PR is squashed, so their
    # footers have to be counted together as well as apart.
    PR_SCOPE=1
    # Except an epic's promotion to main: it lands as a merge commit, so
    # each sub-PR's squash commit keeps its own footer and release-please
    # reads every one. Only the per-commit checks apply. The promise is
    # the merge button — squashing this PR would lose all but one.
    case "${GITHUB_HEAD_REF:-}" in
      epic/*) [ "$BASE_REF" = main ] && PR_SCOPE=0 ;;
    esac
  elif tag=$(git describe --tags --abbrev=0 --match 'coui_core-v*' 2>/dev/null) &&
    [ -n "$tag" ]; then
    # On main itself: everything since the last release. Empty right
    # after a release, which is correct — those commits were checked
    # when their PR ran.
    RANGE="$tag..HEAD"
  else
    # Fail closed. A shallow checkout with no tags and no origin/main
    # cannot answer this question, and answering "0 violations" from a
    # range that contains no commits is the false green this repository
    # keeps getting burned by.
    echo "❌ 검사할 커밋 범위를 정할 수 없다 — 릴리스 태그도 origin/main 도 없다."
    echo "   CI 라면 checkout 에 fetch-depth: 0 이 필요하다."
    exit 1
  fi
fi

if ! git rev-parse --verify -q "${RANGE%%..*}" >/dev/null; then
  echo "❌ 범위의 시작점을 해석할 수 없다: $RANGE"
  echo "   얕은 체크아웃이면 fetch-depth: 0 이 필요하다."
  exit 1
fi

violations=0
report=""
footers_total=0
commits_with_footers=0

while IFS= read -r sha; do
  [ -z "$sha" ] && continue
  body=$(git log -1 --format='%b' "$sha")
  subject=$(git log -1 --format='%s' "$sha")

  footers=$(printf '%s\n' "$body" | grep -cE '^BREAKING CHANGE:')
  [ "$footers" -eq 0 ] && continue
  footers_total=$((footers_total + footers))
  commits_with_footers=$((commits_with_footers + 1))

  # 1. empty same-line summary
  if grep -qE '^BREAKING CHANGE:[[:space:]]*$' <<<"$body"; then
    violations=$((violations + 1))
    report="$report
  ${sha:0:9}  $subject
    → \`BREAKING CHANGE:\` 뒤 같은 줄이 비었다 — 빈 불릿으로 렌더된다."
  fi

  # 2. more than one footer in a single commit
  if [ "$footers" -gt 1 ]; then
    violations=$((violations + 1))
    report="$report
  ${sha:0:9}  $subject
    → BREAKING CHANGE 푸터가 $footers 개다 — 첫 개만 실리고 나머지는 조용히 버려진다."
  fi
done < <(git rev-list "$RANGE" 2>/dev/null)

# 3. footers spread across a PR — the squash will mint one commit holding
#    all of them, and release-please will read only the first. Counted
#    once for the branch rather than per commit: the loss is one event.
if [ "$PR_SCOPE" = "1" ] && [ "$commits_with_footers" -gt 1 ]; then
  violations=$((violations + 1))
  report="$report
  이 브랜치  $commits_with_footers 개 커밋이 BREAKING 푸터를 나눠 갖고 있다 (총 $footers_total 개)
    → squash 하면 한 커밋이 되고, 그중 첫 푸터만 릴리스 노트에 실린다."
fi

echo "렌더되지 않을 BREAKING 푸터: $violations  (baseline $BASELINE, 범위 $RANGE)"

if [ "$violations" -gt "$BASELINE" ]; then
  echo "$report"
  echo
  echo "❌ 이 커밋의 breaking 고지는 릴리스 노트에 도달하지 못한다."
  echo "   빈 요약  → \`BREAKING CHANGE: <내용>\` 을 **같은 줄에서** 시작해라."
  echo "   푸터 여럿 → 하나로 합치거나, squash 대신 rebase 로 머지해 커밋을 나눠라."
  echo "   브랜치에 흩어짐 → 같은 처방이다. 커밋마다 하나씩이어도 squash 가 합친다."
  echo "   CHANGELOG 는 append-only 라, 태그가 찍히면 되돌릴 수 없다."
  exit 1
fi

if [ "$violations" -lt "$BASELINE" ]; then
  echo "   ✅ baseline 아래 — scripts/guards/structure/breaking_footer_renders_baseline.txt 를"
  echo "      $violations 로 낮춰 그 이득을 고정해라."
else
  echo "   ✅ at baseline (no net-new)."
fi

echo "✔ breaking-footer-renders gate passed."
