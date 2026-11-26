#!/usr/bin/env bash
#
# Ratchet: a size ladder states its text as a ROLE, not as a font size.
#
# `core/style-contract.md` ("크기 사다리의 텍스트는 역할로 적는다") — when a
# component's `defaultsBySize` gives a text slot a different look per size,
# that entry must be `CoreTextStyle.token(CoreTextStyles.<role>)`. An entry
# that only states `fontSize:` — the raw `CoreTextStyle(fontSize: …)` form,
# or a `.token(role, fontSize: …)` overlay — is a violation.
#
# ## Why
#
# A text style is an optically corrected bundle: size, letter-spacing and
# line-height move together along a curve (small sizes track looser, large
# sizes tighter). Letter-spacing is stored as an em ratio and multiplied by
# the font size at render time. So an entry that only overrides the size
# keeps the DEFAULT role's em and multiplies it by the NEW size — the label
# lands at the right pixel size with the wrong tracking, and nothing throws.
#
# Measured: two components rendering the same-size label disagreed on
# tracking — the one whose ladder used roles picked up that size's role
# spacing; the ones whose ladders used `fontSize:` multiplied the default
# role's (smaller-size) em into the larger size. Same size, different
# tracking, visible only side by side.
#
# A size that has no role is a DECISION (add the role, or rethink the
# ladder), not something to paper over with a literal — the literal is the
# exact shape that compiles, renders, and warns about nothing.
#
# ## What this counts
#
# Inside every `[Dd]efaultsBySize = { … }` body of
# `packages/coui_core/lib/src/component/contracts/**/*_style.dart` —
# including private split-ladder holders that stitch into a public
# `defaultsBySize` via `merge` (`_typographyDefaultsBySize`,
# `_dimensionalDefaultsBySize`; the case differs and there is no word
# boundary between the prefix and `D`, so a bare `defaultsBySize` pattern
# misses them) — each `CoreTextStyle(` / `CoreTextStyle.token(` call whose
# OWN argument list (depth-1, nested calls excluded) contains `fontSize:`,
# OR whose result is chained straight into a `.copyWith(fontSize: …)`
# overlay — whitespace/newlines between the call and `.copyWith(` are
# tolerated, since dartfmt wraps a too-long chain onto its own line
# (`.token(role).copyWith(fontSize: …)` bakes the identical value as
# `.token(role, fontSize: …)` — same role em, same new size, same defect).
# Comment lines are stripped first — a doc comment quoting the
# anti-pattern dims nothing.
#
# The guard sees the SHAPE of the declaration only. Whether the stated role
# is the right one for that size is review's job.
#
# ## What this does not count
#
# A ladder entry that points at a role by NAME instead of stating the
# violation inline — `labelStyle: _kLadderLabel18` where a file-scope
# `const _kLadderLabel18 = CoreTextStyle(fontSize: CoreFontSize.s18);`
# lives outside any `defaultsBySize` body — is invisible to this scanner.
# The scanner only walks call expressions inside a ladder's braces; a
# bare identifier reference does not re-enter the hoisted constant's own
# declaration. Nothing else in this repo currently hoists a size-ladder
# text style that way, so there is no fixture case for it, but a reviewer
# who sees a ladder entry that is a plain identifier (not a
# `CoreTextStyle(...)` / `CoreTextStyle.token(...)` call) should open the
# referenced constant and check it by hand.
#
# Usage: ./scripts/guards/tokens/check_size_ladder_uses_roles.sh
#        ./scripts/guards/tokens/check_size_ladder_uses_roles.sh --self-test

set -euo pipefail

# lib/ratchet.sh 는 source 될 때 `$1 == --self-test` 를 자기 self-test 로
# 가로채 exit 한다. 이 가드의 플래그를 먼저 집고 positional 을 비운 뒤 source.
SELF_TEST=0
[ "${1:-}" = "--self-test" ] && SELF_TEST=1
set --

# ratchet 기준값은 파일에 산다 — 이 스크립트 안의 상수가 아니다.
# 상수였을 때는 한 글자(`=0` → `=1`)가 위반 한 칸을 열었고, 그 한 글자가
# 통과 여부를 결정하는 **바로 그 PR 안에** 있었다. 파일이면 CODEOWNERS 의
# `/scripts/guards/**/*baseline*` 과 check_codeowners_ratchet_coverage.sh 가
# 그 diff 를 본다. 읽기 실패는 fail-closed 다 (lib/ratchet.sh 참조).
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/ratchet.sh
. "$_GUARD_DIR/../lib/ratchet.sh"

# 스캐너가 python3 이다. macOS 의 /usr/bin/python3 은 Xcode 심이라, 라이선스에
# 동의하지 않은 러너에서는 존재는 하는데 실행이 실패한다 — 그때 이 가드가
# `exit 1` 로 끝나면 "위반을 찾았다" 와 구별되지 않는다. 먼저 한 번 돌려 보고,
# 안 되면 러너 상태로 보고하고 위반과 다른 코드(3)로 끝낸다.
# shellcheck source=../lib/require_tool.sh
. "$_GUARD_DIR/../lib/require_tool.sh"
require_tool python3 -c 'print(1)'

cd "$(dirname "$0")/../../.."

CONTRACTS_DIR="packages/coui_core/lib/src/component/contracts"

# 스캐너 — 파일 목록(인자)을 읽어 위반을 `path:line:snippet` 한 줄씩 낸다.
# 괄호 균형을 세므로 `fontSize:` 가 여러 줄에 걸치거나 다른 named arg 뒤에
# 와도 잡히고, 인자 안에 중첩된 다른 생성자(`CoreColor.token(...)`)의
# 괄호는 depth 로 걸러진다. 단일 정규식으로는 두 경우 중 하나를 놓친다.
scan() {
  python3 - "$@" <<'PY'
import re, sys

CALL = re.compile(r'\bCoreTextStyle(?:\.token)?\(')
# `.token(role)` chained into a `.copyWith(...)` overlay — the overlay's
# own arg list gets the same top-level `fontSize:` check as a call's own
# args (see `findings()` below). `\s*` before the literal because dartfmt
# breaks a too-long chain onto its own line (`sortable_style.dart` does
# exactly this for `.bodyMedium\n.copyWith(color: …)`) — a bare
# `\.copyWith\(` anchored at `close + 1` would miss that shape entirely.
CHAIN = re.compile(r'\s*\.copyWith\(')
# Prefixed/private split-ladder holders (`_typographyDefaultsBySize`,
# `_dimensionalDefaultsBySize`) end in `[Dd]efaultsBySize` too — `\w*`
# absorbs any leading identifier chars (including none, for the bare
# `defaultsBySize` case) and `[Dd]` covers the case flip at the seam
# between a lowercase prefix and the capitalised holder name.
LADDER = re.compile(r'\b\w*[Dd]efaultsBySize\s*=')

def strip_comments(src: str) -> str:
    # `//` 줄 주석만 지운다 — 이 파일들은 문자열 안에 `//` 를 쓰지 않는다.
    # 줄 번호를 보존하려고 줄 자체는 남긴다.
    out = []
    for line in src.split("\n"):
        i = line.find("//")
        out.append(line[:i] if i >= 0 else line)
    return "\n".join(out)

def balanced_span(text: str, open_at: int, open_ch: str, close_ch: str) -> int:
    """text[open_at] 가 open_ch 일 때 짝이 되는 close_ch 의 인덱스."""
    depth = 0
    for i in range(open_at, len(text)):
        c = text[i]
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return i
    return len(text) - 1

def top_level_has_font_size(args: str) -> bool:
    depth = 0
    i = 0
    while i < len(args):
        c = args[i]
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif depth == 0 and args.startswith("fontSize:", i):
            return True
        i += 1
    return False

def findings(path: str, src: str):
    text = strip_comments(src)
    for m in LADDER.finditer(text):
        brace = text.find("{", m.end())
        if brace < 0:
            continue
        end = balanced_span(text, brace, "{", "}")
        body_start = brace
        for call in CALL.finditer(text, body_start, end):
            paren = call.end() - 1
            close = balanced_span(text, paren, "(", ")")
            args = text[paren + 1:close]
            has_font_size = top_level_has_font_size(args)
            # A call chained (whitespace-only gap allowed) into
            # `.copyWith(...)` is one baked value, not two — check its
            # overlay args too, and extend the reported snippet through
            # the chain.
            chain_end = close
            chain = CHAIN.match(text, close + 1)
            if chain:
                chain_paren = chain.end() - 1
                chain_close = balanced_span(text, chain_paren, "(", ")")
                chain_args = text[chain_paren + 1:chain_close]
                if top_level_has_font_size(chain_args):
                    has_font_size = True
                chain_end = chain_close
            if has_font_size:
                line = text.count("\n", 0, call.start()) + 1
                snippet = " ".join(text[call.start():chain_end + 1].split())
                yield f"{path}:{line}:{snippet}"

if sys.argv[1] == "--fixture":
    # self-test — 아래 bash 가 기대 개수와 대조한다.
    fixture = """
class CoreXStyle {
  /// doc: CoreTextStyle(fontSize: CoreFontSize.s10) must not count
  static const CoreTextStyle defaultLabelStyle =
      CoreTextStyle(fontSize: CoreFontSize.s14); // outside ladder: not counted
  static const Map<CoreComponentSize, CoreXStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreXStyle(
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s10),           // 1
      // CoreTextStyle(fontSize: CoreFontSize.s12) — comment, not counted
      descriptionStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onSurface),
        fontSize: CoreFontSize.s10,                                     // 2 (multi-line)
      ),
    ),
    CoreComponentSize.md: CoreXStyle(
      labelStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),       // role: ok
      hintStyle: CoreTextStyle.token(CoreTextStyles.bodySmall, fontSize: CoreFontSize.s12), // 3 overlay
      captionStyle: CoreTextStyle(color: CoreColor.token(CoreColors.x)), // no fontSize: ok
      titleStyle: CoreTextStyle.token(CoreTextStyles.labelLarge).copyWith(
        fontSize: CoreFontSize.s16,                                     // 4 chained .copyWith overlay
      ),
      weightOnlyStyle: CoreTextStyle.token(CoreTextStyles.labelLarge).copyWith(
        fontWeight: CoreFontWeight.semiBold,                            // chained, no fontSize: ok
      ),
      // dartfmt breaks a too-long chain onto its own line — same shape as
      // `sortable_style.dart`'s `defaultItemTextStyle` (`.bodyMedium` then
      // `.copyWith(...)` on the next line). A bare `close + 1` anchor
      // (no `\\s*`) would miss this.
      wrappedChainStyle: CoreTextStyle.token(CoreTextStyles.labelLarge)
          .copyWith(fontSize: CoreFontSize.s20),                        // 6 wrapped chain overlay
    ),
  };
  static const Map<CoreComponentSize, CoreXStyle> other = {
    CoreComponentSize.lg: CoreXStyle(labelStyle: CoreTextStyle(fontSize: CoreFontSize.s16)), // not a ladder
  };
  // Prefixed/private split ladder — same seam that a bare `defaultsBySize`
  // regex missed (case flip + no word boundary between `y` and `D`).
  static final Map<CoreComponentSize, CoreXStyle> _typographyDefaultsBySize = {
    CoreComponentSize.xs: CoreXStyle(
      labelStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),       // role: ok
    ),
    CoreComponentSize.md: CoreXStyle(
      labelStyle: CoreTextStyle(fontSize: CoreFontSize.s14),           // 5 prefixed-ladder violation
    ),
  };
}
"""
    for f in findings("fixture.dart", fixture):
        print(f)
    sys.exit(0)

for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as fh:
        for f in findings(path, fh.read()):
            print(f)
PY
}

if [ "$SELF_TEST" -eq 1 ]; then
  # 실패시켜 보지 않은 가드는 가드가 아니다 — fixture 는 위반 6 + 함정 7:
  # 사다리 밖 raw 리터럴 · 주석 두 줄 · fontSize 없는 raw 생성자 ·
  # 역할만 적은 항목 · fontWeight 만 있는 `.copyWith` 체인 ·
  # 사다리가 아닌 이름의 맵(`other`) · 접두 사다리의 role-only 항목.
  got=$(scan --fixture)
  n=$(printf '%s\n' "$got" | grep -c . || true)
  echo "self-test: fixture violations = $n (expected 6)"
  printf '%s\n' "$got" | sed 's/^/    /'
  if [ "$n" -ne 6 ]; then
    echo "❌ 스캐너가 fixture 를 잘못 센다 — 가드 자체가 결함이다."
    exit 1
  fi
  echo "✅ scanner self-test passed."
  exit 0
fi

BASELINE=$(ratchet_int "$_GUARD_DIR/size_ladder_font_size_baseline.txt") || exit 1

files=$(find "$CONTRACTS_DIR" -name '*_style.dart' -type f | sort)
if [ -z "$files" ]; then
  echo "❌ contract style files not found under $CONTRACTS_DIR — the guard has nothing to gate."
  exit 1
fi

# shellcheck disable=SC2086 — 경로에 공백이 없는 레포 내부 파일 목록.
report=$(scan $files)
count=$(printf '%s\n' "$report" | grep -c . || true)

echo "[size-ladder] text entries in defaultsBySize that state fontSize: $count (baseline $BASELINE)"

if [ "$count" -gt "$BASELINE" ]; then
  echo "    ❌ net-new. A size ladder states its text as a ROLE —"
  echo "       CoreTextStyle.token(CoreTextStyles.<role>) — never as fontSize:."
  echo "       fontSize alone keeps the default role's em letter-spacing and"
  echo "       line-height and multiplies them into the new size (optical curve"
  echo "       violation). No role for that size? That is a design decision"
  echo "       (add the role / revisit the ladder), not a literal."
  echo "       → core/style-contract.md \"크기 사다리의 텍스트는 역할로 적는다\""
  echo
  printf '%s\n' "$report" | sed 's/^/       /'
  exit 1
fi

if [ "$count" -lt "$BASELINE" ]; then
  echo "    ✅ below baseline — lower the value in"
  echo "       scripts/guards/tokens/size_ladder_font_size_baseline.txt to $count"
  echo "       so it cannot creep back."
  exit 1
fi

echo "    ✅ no net-new."
