#!/usr/bin/env bash
# 코드가 내보내는 컴포넌트가 문서 카탈로그에 있는가 — 반대편에서 본다.
#
# 왜 이 가드가 따로 필요한가: docs_core 의 catalog_single_source_test.dart 는
# 카탈로그 ↔ md ↔ 코드 스니펫 레지스트리의 **대응**을 강제한다. 그래서 세
# 곳에서 **동시에** 빠진 컴포넌트는 그 테스트에 보이지 않는다 — 불일치는
# 잡지만 누락은 못 잡는다. 실제로 그 사각으로 DefinitionList 와
# DisclosureBadge 가 들어왔고, 카탈로그 142 == md 142 가 맞아떨어지는 동안
# 두 컴포넌트가 문서 없이 살았다. 개수가 맞는다는 것이 빠진 게 없다는 뜻이
# 아니었다.
#
# 그래서 이 가드는 카탈로그끼리 대조하지 않고 **배럴 export 에서 출발**한다.
# 사용자가 import 할 수 있는 컴포넌트가 문서에 없으면 그게 갭이다.
#
# 문서는 컴포넌트 카탈로그만이 아니다. 블록으로 옮긴 항목도 페이지가 있다 —
# slug 는 `block_catalog.dart` 에 있고 본문은 `content/blocks/<slug>.md` 다.
# 그 slug 는 컴포넌트 카탈로그와 **같은 존재 검사**로 덮인 문서로 친다.
# Hero 가 그렇다. 앞으로 컴포넌트가 블록으로 옮겨도 baseline 에 넣지 않는다.
#
# 무엇을 빼는가는 **목록이 아니라 규칙**이다: `src/components/infra/**` 와
# `src/components/locale/**` 는 카테고리 자체가 "사용자에게 직접 노출하지
# 않는 부속품" 이라 통째로 대상 밖이다. 새 infra 가 추가돼도 자동으로 빠지므로
# 목록이 낡지 않는다 — 오늘의 목록을 박아두면 다음에 추가되는 것에서 조용히
# 갈라진다.
#
# 이 가드가 보지 않는 것: 페이지의 **내용**이 맞는지. 그건 docs_api_sync_test
# 와 리뷰의 몫이다. 여기서는 "페이지가 존재하는가" 하나만 본다 —
# 문자열 대조로 실제로 판정할 수 있는 것.
set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

readonly BARREL="packages/coui_flutter/lib/coui_flutter.dart"
readonly CATALOG="docs_core/lib/shared/component_catalog.dart"
readonly BLOCK_CATALOG="docs_core/lib/shared/block_catalog.dart"
readonly BASELINE="scripts/guards/structure/docs_catalog_uncovered_baseline.txt"

for f in "$BARREL" "$CATALOG" "$BLOCK_CATALOG" "$BASELINE"; do
  if [ ! -f "$f" ]; then
    echo "❌ 없는 파일: $f"
    echo "   없는 파일을 빈 값으로 읽으면 '파일을 지우는 것' 이 게이트를 끄는 길이 된다."
    exit 1
  fi
done

# 디렉터리명 ↔ 카탈로그 slug 가 갈리는 경우. 사실이지 부채가 아니라 여기 산다.
# 여러 디렉터리가 한 페이지로 묶이는 경우(mockup_*, drag_*)도 포함한다.
# bash 3.2 (macOS 기본) 에는 `declare -A` 가 없어 평문 목록으로 둔다.
readonly NAME_MAP="
stacks=stack-layout
bar_action=app-bar
selectable=selectable-text
sidebar_group=sidebar
sidebar_header=sidebar
sidebar_item=sidebar
sidebar_rail_item=sidebar
sidebar_search=sidebar
sidebar_section=sidebar
mockup_browser=mockup
mockup_code=mockup
mockup_phone=mockup
mockup_device=mockup
drag_item=drag
drag_overlay=drag
drag_scope=drag
drop_zone=drag
"

slug_for() {
  local dir="$1" line mapped=''
  # 파이프 없이 읽는다 — `set -o pipefail` 아래 파이프 + `grep -q` 는
  # 매치했을 때 앞 단계에 SIGPIPE 를 보내 거짓 실패를 만든다
  # (check_guard_sigpipe.sh 가 그 패턴을 센다).
  while IFS= read -r line; do
    case "$line" in
      "${dir}="*) mapped="${line#*=}"; break ;;
    esac
  done <<EOF
$NAME_MAP
EOF
  if [ -n "$mapped" ]; then printf '%s' "$mapped"; else printf '%s' "${dir//_/-}"; fi
}

# 카탈로그 slug 집합. 컴포넌트와 블록을 한 집합으로 본다 — 어느 쪽에
# slug 가 있어도 그 페이지는 있는 것이다 (블록은 content/blocks/<slug>.md).
catalog_slugs=$(grep -h -oE "slug: '[a-z0-9-]+'" "$CATALOG" "$BLOCK_CATALOG" | sed "s/slug: '//;s/'$//" | sort -u)

# 배럴이 export 하는 컴포넌트 디렉터리
# 사용자에게 직접 노출하지 않는 카테고리는 규칙으로 뺀다 (위 헤더 참조).
readonly EXCLUDED_CATEGORIES='infra|locale'
export_dirs=$(grep -oE "export 'src/components/[a-z_]+/[a-z0-9_]+/" "$BARREL" \
  | sed -E "s|export 'src/components/||;s|/$||" \
  | grep -vE "^($EXCLUDED_CATEGORIES)/" \
  | cut -d/ -f2 | sort -u)

# baseline (주석·빈 줄 제외)
baseline_dirs=$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$BASELINE" | sed 's/[[:space:]]//g' | sort -u)

uncovered=""
for dir in $export_dirs; do
  slug=$(slug_for "$dir")
  case "
$catalog_slugs
" in *"
$slug
"*) continue ;; esac
  uncovered="$uncovered$dir
"
done
uncovered=$(printf '%s' "$uncovered" | grep -v '^$' | sort -u)

# baseline 에 없는 것 = net-new
netnew=$(comm -23 <(printf '%s\n' "$uncovered" | grep -v '^$') <(printf '%s\n' "$baseline_dirs" | grep -v '^$'))
# baseline 에는 있는데 이제 덮인 것 = 이득
fixed=$(comm -13 <(printf '%s\n' "$uncovered" | grep -v '^$') <(printf '%s\n' "$baseline_dirs" | grep -v '^$'))

n_unc=$(printf '%s\n' "$uncovered" | grep -c . || true)
n_base=$(printf '%s\n' "$baseline_dirs" | grep -c . || true)
echo "문서 카탈로그(컴포넌트·블록)에 없는 export 컴포넌트: $n_unc  (baseline $n_base)"

if [ -n "$netnew" ]; then
  echo
  echo "$netnew" | sed 's/^/    /'
  echo
  echo "❌ 배럴이 export 하는데 문서 카탈로그에 페이지가 없는 컴포넌트가 늘었다."
  echo "   컴포넌트는 component_catalog, 블록은 block_catalog 의 slug 로 덮인다."
  echo "   등록하려면 (docs-site.md 참조):"
  echo "     1. docs_core/lib/shared/component_catalog.dart — DocsComponentEntry"
  echo "        또는 docs_core/lib/shared/block_catalog.dart — DocsBlockEntry (블록으로 옮긴 경우)"
  echo "     2. docs_core/content/components/<slug>.md"
  echo "        또는 docs_core/content/blocks/<slug>.md"
  echo "     3. docs_core/lib/previews/examples/{flutter,web}/<comp>/ 예제 + _code.dart"
  echo "     4. 레지스트리 4종 + preview_constraints.dart"
  echo "   slug 가 디렉터리명과 다르면 이 스크립트의 NAME_MAP 에 추가하라."
  echo "   정말 문서 대상이 아니면 $BASELINE 에 사유와 함께 추가하라."
  exit 1
fi

if [ -n "$fixed" ]; then
  echo "   ✅ baseline 보다 낮다 — 아래 항목이 이제 문서화됐다. baseline 에서 지워 이득을 고정하라:"
  echo "$fixed" | sed 's/^/      /'
else
  echo "   ✅ baseline 그대로 (net-new 없음)."
fi

echo "✔ docs-catalog-coverage gate passed."
