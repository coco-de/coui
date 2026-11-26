#!/usr/bin/env bash
# A deprecation that does not say when it started cannot be counted.
#
# The policy is "removable two minors after the announcement" (see
# .claude/rules/process/deprecation.md). That is only checkable if the
# announcement records the version it went out in — otherwise the only
# way to find out is `git log`, and the answer is one blame away from
# whoever is deciding whether it is safe to remove.
#
# This is deliberately narrow. It does NOT check that the named
# replacement exists or that the stated reason is true; both need a
# reader, and a guard that pretends to check them would be the kind of
# false green this repository has been burned by. It checks the one
# thing a string match can actually settle.
#
# Ratchet: the deprecations that predate the policy stay as a baseline
# and only net-new violations fail.
set -uo pipefail

# ratchet 기준값은 파일에 산다 — 이 스크립트 안의 상수가 아니다.
# 상수였을 때는 한 글자(`=0` → `=1`)가 위반 한 칸을 열었고, 그 한 글자가
# 통과 여부를 결정하는 **바로 그 PR 안에** 있었다. 파일이면 CODEOWNERS 의
# `/scripts/guards/**/*baseline*` 과 check_codeowners_ratchet_coverage.sh 가
# 그 diff 를 본다. 읽기 실패는 fail-closed 다 (lib/ratchet.sh 참조).
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

cd "$(dirname "$0")/../../.." || exit 1

BASELINE=$(ratchet_int "$_GUARD_DIR/deprecation_policy_baseline.txt") || exit 1

# Print the message of every `@Deprecated(...)` in a file, one per line.
#
# The argument list is matched as a balanced-parenthesis group that steps
# over string literals and comments, and only the literals' contents are
# kept — that is the message. Taking everything up to the first `)`
# followed by a newline or a letter cut `'Use Foo (the new one) instead
# (since 0.130).'` at `one)`, so the marker after it was never read: a
# false violation that authors worked around by rewording their messages
# rather than the guard being fixed. The same shortcut could also run past
# an annotation into the next one and borrow its marker.
#
# A message that is not a literal (`@Deprecated(kMessage)`) has nothing to
# read, so its raw argument text is reported instead — it fails unless the
# marker is spelled out where the annotation is.
extract_messages() {
  perl -0777 -ne '
    my $args = qr{
      ( \(
        (?: [^()\x27"/]++
          | \x27 (?: [^\x27\\\n] | \\. )* \x27
          | "    (?: [^"\\\n]    | \\. )* "
          | //[^\n]*
          | /\*.*?\*/
          | /
          | (?1)
        )*
      \) )
    }sx;
    while (/\@Deprecated\s*$args/g) {
      my $list = substr($1, 1, -1);
      $list =~ s{//[^\n]*|/\*.*?\*/}{}gs;
      my @parts = $list =~ /\x27((?:[^\x27\\\n]|\\.)*)\x27|"((?:[^"\\\n]|\\.)*)"/g;
      my $m = join("", grep { defined } @parts);
      $m = $list if $m eq "";
      $m =~ s/\s+/ /g;
      $m =~ s/^ | $//g;
      print "$m\n";
    }
  ' "$1"
}

# Self-test — runs on every invocation, before the scan. An extractor that
# silently stops matching reports "0 missing", exactly like a clean tree,
# so it proves itself on known shapes first: each annotation in the fixture
# is paired with the message the guard must read out of it, in order.
selftest() {
  local fixture expected got
  fixture="$_GUARD_DIR/fixtures/deprecation_messages.dart.txt"
  expected="$_GUARD_DIR/fixtures/deprecation_messages.expected.txt"
  got=$(extract_messages "$fixture")
  if [ "$got" != "$(cat "$expected")" ]; then
    echo "❌ deprecation-policy self-test: the extractor misread a fixture."
    echo "--- expected ($expected)"
    cat "$expected"
    echo "--- got"
    printf '%s\n' "$got"
    return 1
  fi
}

selftest || exit 1

missing=0
report=""

while IFS= read -r file; do
  messages=$(extract_messages "$file")
  [ -z "$messages" ] && continue

  while IFS= read -r message; do
    [ -z "$message" ] && continue
    # `since 0.128` / `since 1.4` — a major.minor the window counts from.
    if ! grep -qE 'since [0-9]+\.[0-9]+' <<<"$message"; then
      missing=$((missing + 1))
      report="$report
  $file
    $(printf '%s' "$message" | cut -c1-90)"
    fi
  done <<<"$messages"
done < <(find packages/*/lib -name '*.dart' 2>/dev/null)

echo "@Deprecated without a countable start: $missing  (baseline $BASELINE)"

if [ "$missing" -gt "$BASELINE" ]; then
  echo "$report"
  echo
  echo "❌ A new deprecation does not record the version it started in."
  echo "   Add \`(since <major>.<minor>)\` to the message — the removal"
  echo "   window is counted from it, and nothing else records it."
  echo "   See docs/contributing/upgrading.md#deprecation"
  exit 1
fi

if [ "$missing" -lt "$BASELINE" ]; then
  echo "   ✅ below baseline — lower the value in"
  echo "      scripts/guards/structure/deprecation_policy_baseline.txt to $missing"
  echo "      to hold the gain."
else
  echo "   ✅ at baseline (no net-new)."
fi

echo "✔ deprecation-policy gate passed."
