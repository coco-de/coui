#!/usr/bin/env bash
#
# Gate: a field that can be obscured reaches no platform text service.
#
# Autocorrect, input-method suggestions, IME personalised learning and
# spell check all take the field's text somewhere it can be kept: the
# keyboard's user dictionary, or — for spell check — a platform service
# that may be remote. For an obscured field that text is a password.
#
# What makes this worth a gate rather than a review note is that it is
# invisible from every direction a reviewer normally looks. The field
# renders identically, the widget tree is identical, no test fails, and
# analysis is clean. The only evidence is a flag passed one level down.
#
# It has already gone wrong twice in this repository, in both directions:
#
#   Flutter — the three flags were forwarded from the constructor without
#   ever consulting the obscured state, and `autocorrect` was declared
#   non-null so the framework's own inference (which turns it off for a
#   password autofill hint) could never run. The fix was not inherited
#   from upstream because these widgets wire `EditableText` directly.
#
#   Web — the attributes were simply absent, and a browser defaults them
#   *on* for a text input. So the same password field was quiet on one
#   platform and spell-checked on the other, which is worse than either
#   default alone: a cross-platform kit had a leak on exactly one side.
#
# The check is per-file and deliberately blunt: a file that declares an
# obscured state must gate each service on it. It cannot prove the gate
# is correct — the tests do that — but it fails the shape the regression
# takes, which is a service reference with no obscured state near it.
#
# Comments do not count. That is not pedantry: the Web text area carried
# a comment claiming it mapped `autocorrect` to an attribute while
# nothing emitted it, and a reader checking where a text area's contents
# could reach would have stopped at that comment and found an answer.

set -euo pipefail

cd "$(dirname "$0")/../../.."

# Files that declare an obscured state — the ones where a leak is
# possible at all. A file that only mentions `obscureText` in prose or in
# an example is not in scope.
#
# A `<textarea>` IS in scope. HTML gives no masked multi-line *control*,
# but `-webkit-text-security` gives a masked *rendering*, so the Web text
# area declares `obscureText` and this guard targets it — four obscurable
# fields, two per platform. Do not narrow this back on the belief that a
# text area cannot be masked; it can, and the leak paths (spell check,
# autocorrect, the keyboard dictionary) are exactly the same there.
targets=$(
  grep -rlE '^[^/]*(this\.obscureText|final bool obscureText)' \
    packages/coui_flutter/lib packages/coui_web/lib --include='*.dart' |
    sort
)

if [ -z "$targets" ]; then
  echo "FAIL: no file declares an obscured state — the check is scoped to"
  echo "      nothing, which means it would pass whatever happened."
  exit 1
fi

# Each service, and the token that would appear where it is emitted.
services=(
  'spell check:spellCheckConfiguration|spellcheck'
  'autocorrect:autocorrect'
  'suggestions:enableSuggestions'
  'IME learning:enableIMEPersonalizedLearning'
  'capitalisation:textCapitalization|autocapitalize'
)

# The obscured state, however the file spells it. `_obscured` is the
# runtime one — it also covers a password type and the reveal toggle, so
# a gate written against the constructor parameter alone is not enough
# for a field that has a toggle.
obscured='_obscured|obscureText'

# How far above a service an `if (_obscured) {` may open. The web writes
# several attributes inside one such block.
readonly window=4

# 파이프로 `grep -q` 에 먹이지 않는다 — here-string 을 쓴다.
#
# `set -o pipefail` 아래에서 `echo "$x" | grep -q PAT` 는 **매치했을 때** 깨질 수
# 있다: `-q` 는 첫 매치에서 즉시 나가며 파이프를 닫고, 아직 쓰고 있던 `echo` 가
# EPIPE 로 실패하며, pipefail 이 그 실패를 파이프라인의 종료 상태로 삼는다.
# 그래서 "찾았다" 가 "실패했다" 로 뒤집히고, `! pipeline` 로 감싼 자리에서는
# 정확히 반대 결론이 나온다 — 이 가드가 CI 에서 `echo: write error: Broken pipe`
# 한 줄과 함께 "obscured 상태를 선언만 하고 읽지 않는다" 는 **거짓 고발**을 냈고,
# 같은 커밋이 로컬에서는 통과했다.
#
# 경주라서 매번 나지 않는다. 그게 이 버그의 최악인 지점이다 — 무작위로 빨개지는
# 가드는 고쳐지는 대신 무시되고, 무시되기 시작하면 진짜 위반도 같이 지나간다.
# here-string 은 파이프가 없어 쓰는 쪽이 존재하지 않는다.

failures=""

for file in $targets; do
  # Code lines only, with their numbers, so a comment cannot satisfy the
  # check and a doc example cannot trip it.
  code=$(grep -nE '^[^/]*[^[:space:]]' "$file" | grep -vE '^[0-9]+:[[:space:]]*//')

  if ! grep -qE "$obscured" <<<"$code"; then
    failures="${failures}${file}: declares an obscured state but never reads it
"
    continue
  fi

  # Lines that open a block on the obscured state. The web writes several
  # attributes inside one of these.
  block_lines=$(
    echo "$code" | grep -E "if \(!?($obscured)\)" | cut -d: -f1 || true
  )

  for entry in "${services[@]}"; do
    label="${entry%%:*}"
    token="${entry#*:}"

    # Where the service is stated *to the platform* — a named argument or
    # an attribute write. A getter that only satisfies the interface is
    # not an emission: the web has no per-input switch for suggestions or
    # IME learning, so those getters exist to be a value nobody reads.
    # Requiring a gate around one would be asking for a condition on a
    # capability the platform does not have.
    #
    # A Web file may therefore not state every service at all. An absent
    # one is not a failure; an ungated one is.
    service_lines=$(
      echo "$code" | grep -E "$token" |
        grep -vE "(bool|String|int|Object)\??[[:space:]]+get[[:space:]]+($token)" |
        cut -d: -f1 || true
    )
    [ -z "$service_lines" ] && continue

    # One gated reference is enough, because the gate does not always sit
    # at the emission: spell check is decided into a local and the local
    # is forwarded a hundred lines later, so demanding every reference be
    # gated would fail correct code.
    #
    # What is *not* enough is proximity to any obscured line anywhere.
    # That was the first version of this check and it had two blind spots,
    # both found by injection rather than by reading: a neighbouring
    # service's gate sat within the window and satisfied the check for a
    # service whose own gate had just been deleted. So a reference counts
    # as gated only when the state is in its own statement, or an
    # `if (obscured)` opens the block it sits in.
    gated=""
    for sl in $service_lines; do
      # The whole statement the reference sits in. Dart's formatter wraps
      # a gate above the reference as often as beside it, so this walks
      # back to the statement's start rather than reading a fixed window.
      #
      # A trailing comma terminates it. Without that the walk runs into
      # the previous argument in the same call — which is another gated
      # service, and would satisfy the check for one that is not.
      start=$sl
      for _ in 1 2 3; do
        prev=$((start - 1))
        [ $prev -lt 1 ] && break
        prev_text=$(sed -n "${prev}p" "$file")
        grep -qE '[;{},][[:space:]]*$' <<<"$prev_text" && break
        grep -qE '^[[:space:]]*(//|$)' <<<"$prev_text" && break
        start=$prev
      done

      statement=$(sed -n "${start},$((sl + 1))p" "$file")
      if grep -qE "$obscured" <<<"$statement"; then
        gated="yes"
        break
      fi

      for bl in $block_lines; do
        delta=$((sl - bl))
        if [ $delta -ge 0 ] && [ $delta -le $window ]; then
          gated="yes"
          break 2
        fi
      done
    done

    if [ -z "$gated" ]; then
      failures="${failures}${file}: ${label} is stated without the obscured state gating it
"
    fi
  done
done

if [ -n "$failures" ]; then
  echo "An obscured field can reach a platform text service."
  echo
  printf '%s' "$failures"
  echo
  echo "Gate each service on the obscured state. The runtime state is the"
  echo "one to key on — a password type obscures too, and a reveal toggle"
  echo "flips it after the first build."
  exit 1
fi

echo "PASS: $(echo "$targets" | wc -l | tr -d " ") obscurable fields gate their text services."
