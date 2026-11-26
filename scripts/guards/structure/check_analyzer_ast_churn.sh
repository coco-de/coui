#!/usr/bin/env bash
# The AST reader (`packages/coui_core/bin/figma_reader/`) has exactly one
# version-specific debt: analyzer 12→13 renamed/removed the AST node types
# below. The workspace resolves analyzer 12.1.0 today (pinned transitively
# by `analysis_server_plugin`'s exact-pin), but that pin moves the day
# `coui_lints` upgrades `analysis_server_plugin` — and analyzer 13.3.0 /
# 14.1.0 already exist on pub.dev, so the jump isn't hypothetical.
#
#   NamedExpression -> NamedArgument            (removed in analyzer 13)
#   SimpleFormalParameter, DefaultFormalParameter,
#   FunctionTypedFormalParameter, NormalFormalParameter -> RegularFormalParameter
#   visitNamedExpression                        (visitor method removed)
#   ClassDeclaration.name                        (removed in analyzer 11 — the
#                                                 reader already uses `.namePart`)
#
# The reader isolates named-argument and parameter access in adapters in
# `ast_value.dart` and `style_reader.dart`. The adapters never spell out
# either version-specific node name. A standalone compatibility fixture and
# the contracts reader corpus have been checked against analyzer 12.1.0,
# 13.3.0 and 14.1.0; this gate protects the adapter boundary, not the
# compatibility tests themselves.
#
# This guard holds that isolation at net-new zero: any of the identifiers
# below appearing anywhere in figma_reader/ again means someone reached
# for the version-specific type directly instead of the adapter, and the
# reader will compile today and break the day the pin moves.
#
# C1 (population floor): if the reader directory can't be found at all,
# this guard FAILS rather than silently reporting "0 violations" — a
# guard whose target moved or was deleted is not evidence of compliance.
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

READER_DIR="packages/coui_core/bin/figma_reader"
BASELINE=$(ratchet_int "$_GUARD_DIR/analyzer_ast_churn_baseline.txt") || exit 1

if [ ! -d "$READER_DIR" ]; then
  echo "❌ $READER_DIR not found — the AST reader moved or was deleted."
  echo "   This guard can't tell 'no violations' from 'nothing to check'."
  echo "   Update READER_DIR in this script if the reader moved."
  exit 1
fi

reader_files=$(find "$READER_DIR" -name '*.dart' 2>/dev/null)
if [ -z "$reader_files" ]; then
  echo "❌ $READER_DIR exists but has no .dart files — population floor failed."
  exit 1
fi

# Forbidden identifiers — analyzer AST churn between 12 / 13 / 14. Matched
# as whole-word so e.g. a local var named `defaultFormalParameterCount`
# doesn't false-positive, and excluding COMMENT lines — `///` and `//` alike —
# where the identifier is discussed rather than used.
#
# `//` was excluded after this guard reported two hits on a comment explaining
# why the code beneath it avoids the very type it named. A guard that scores
# prose reports something other than what it measures, and the reader learns to
# argue with it instead of fixing code; a comment cannot cause analyzer churn,
# so there is nothing here to score.
FORBIDDEN='NamedExpression|NamedArgument|SimpleFormalParameter|DefaultFormalParameter|FunctionTypedFormalParameter|NormalFormalParameter|visitNamedExpression'

violations=0
report=""

while IFS= read -r file; do
  while IFS=: read -r lineno content; do
    [ -z "$lineno" ] && continue
    violations=$((violations + 1))
    report="$report
  $file:$lineno: $(printf '%s' "$content" | sed 's/^[[:space:]]*//' | cut -c1-100)"
  done < <(grep -nE "\\b($FORBIDDEN)\\b" "$file" | grep -vE '^[0-9]+:[[:space:]]*//')
done <<<"$reader_files"

# `ClassDeclaration.name` — checked separately (a property-access pattern,
# not a bare identifier) since analyzer 11 already removed it and the
# reader already migrated to `.namePart`; this catches a regression back
# to the old getter, e.g. from a copy-pasted snippet.
while IFS= read -r file; do
  while IFS=: read -r lineno content; do
    [ -z "$lineno" ] && continue
    violations=$((violations + 1))
    report="$report
  $file:$lineno: $(printf '%s' "$content" | sed 's/^[[:space:]]*//' | cut -c1-100)"
  done < <(grep -nE '\.name\.lexeme' "$file" | grep -E 'ClassDeclaration|decl\.name\b' | grep -vE '^[0-9]+:[[:space:]]*//')
done <<<"$reader_files"

echo "analyzer AST churn identifiers in $READER_DIR: $violations  (baseline $BASELINE)"

if [ "$violations" -gt "$BASELINE" ]; then
  echo "$report"
  echo
  echo "❌ A version-specific analyzer AST type name was used directly."
  echo "   Route named-argument access through ast_value.dart#namedArg"
  echo "   (dynamic dispatch — see its doc comment) instead of matching"
  echo "   NamedExpression/NamedArgument by type. Route class-name access"
  echo "   through style_reader.dart's _classNameOf (.namePart), not"
  echo "   ClassDeclaration.name."
  exit 1
fi

echo "✔ analyzer-ast-churn gate passed."
