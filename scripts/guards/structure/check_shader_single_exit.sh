#!/usr/bin/env bash
#
# 프래그먼트 셰이더의 `main()` 은 출구가 하나다.
#
# 텍스처를 샘플링하는 셰이더의 `main()` 에 `return;` 이 둘 이상 있으면 Flutter
# 3.50 의 셰이더 컴파일러(`impellerc`)가 경고한다. 경고로 끝나지 않을 수 있다 —
# liquid_glass_widgets 1.17.4 는 같은 모양에서 Windows Direct3D 와 Chrome ANGLE 의
# HLSL 컴파일(`d3dcompiler_47.dll`, FXC)이 실패한다고 보고했고, 같은 컴파일러가
# Windows 에서 죽는 크래시가 flutter/flutter#190809 로 올라와 있다(그 이슈는
# 원인 셰이더를 확정하지 못했다). 이 저장소에서 재현한 것은 아니다.
#
# 이 가드가 필요한 이유는 둘이다.
#
# 1. 이전 SDK(3.47)의 컴파일러는 같은 셰이더에 경고하지 않았다. 그래서 SDK 를
#    올리기 전에는 아무 신호도 없었고, 올린 뒤에야 `Shader Warning` 상자가
#    빌드마다 뜬다. 경고는 빌드를 깨지 않으므로(종료 코드 0) 누구도 막지 않는다.
# 2. `flutter test` 의 래스터라이저는 이 셰이더를 돌리지 않는다. 그래서 어떤
#    단위 테스트도 이 모양을 볼 수 없다 — 모양은 소스에서 직접 봐야 한다.
#
# 두 단계로 판정한다.
#
#   정적   SDK 없이 도는 근사. `sampler2D` 를 선언한 `.frag` 의 `void main()`
#          본문에서 맨 끝의 `return;` 하나를 뺀 나머지 `return` 을 센다. 주석과
#          전처리 줄은 보지 않고, 보조 함수의 `return` 은 세지 않는다 — 컴파일러가
#          세는 것도 `main()` 뿐이다.
#   컴파일 `impellerc` 로 플랫폼별 대상 묶음(`flutter_tools` 가 쓰는 것과 같다)을
#          실제로 컴파일해 `[WARNING]` 이나 비정상 종료가 있으면 실패한다. 정적
#          검사가 못 잡는 미래의 경고도 여기서 잡힌다.
#
# 컴파일 단계는 SDK 가 있을 때만 돈다. SDK 가 없는 잡에서는 건너뛰되 그 사실을
# 한 줄로 말한다 — 조용한 건너뜀은 통과처럼 읽히기 때문이다. SDK 가 있어야 하는
# 잡(CI 의 `flutter` 잡)은 `--require-compiler` 로 부른다: 컴파일러를 찾지 못하면
# "가드 위반 아님" 신호(종료 코드 3)로 실패해, 건너뛴 초록이 되지 않는다.
#
# 이 가드가 보지 못하는 것: 셰이더가 같은 그림을 그리는지. 그건 굴절 프로브
# 테스트들(`surface_refraction_parity_test.dart`, 실기기 프로브)의 일이다.
#
# 사용:
#   bash scripts/guards/structure/check_shader_single_exit.sh
#   bash scripts/guards/structure/check_shader_single_exit.sh --require-compiler
#   bash scripts/guards/structure/check_shader_single_exit.sh --self-test

set -euo pipefail

_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/require_tool.sh
. "$_GUARD_DIR/../lib/require_tool.sh"

REPO_ROOT="$(cd "$_GUARD_DIR/../../.." && pwd)"

# 정적 검사기. 파일 경로들을 받아 위반을 `경로: 사유` 로 낸다. 표준 입력으로
# 소스를 받는 `--stdin` 은 자기 시험이 쓴다.
_STATIC_CHECK_PY='
import re
import sys


def strip(src):
    src = re.sub(r"/\*.*?\*/", " ", src, flags=re.S)
    src = re.sub(r"//[^\n]*", " ", src)
    return "\n".join(l for l in src.split("\n") if not l.lstrip().startswith("#"))


def main_body(src):
    m = re.search(r"\bvoid\s+main\s*\(\s*(?:void)?\s*\)\s*\{", src)
    if m is None:
        return None
    depth, i = 1, m.end()
    while i < len(src) and depth:
        depth += (src[i] == "{") - (src[i] == "}")
        i += 1
    return src[m.end() : i - 1]


def extra_returns(src):
    """`main()` 의 `return` 중 맨 끝 하나를 뺀 개수. 샘플러가 없으면 0."""
    s = strip(src)
    if not re.search(r"\bsampler2D\b", s):
        return 0
    body = main_body(s)
    if body is None:
        return 0
    body = re.sub(r"\breturn\s*;\s*$", "", body.rstrip())
    return len(re.findall(r"\breturn\b", body))


args = sys.argv[1:]
if args == ["--stdin"]:
    print(extra_returns(sys.stdin.read()))
    sys.exit(0)

bad = 0
for path in args:
    with open(path, encoding="utf-8") as fh:
        n = extra_returns(fh.read())
    if n:
        bad += 1
        print(f"{path}: main() 에 맨 끝 말고도 return 이 {n}개 있다")
sys.exit(1 if bad else 0)
'

_static_check() { python3 -I -c "$_STATIC_CHECK_PY" "$@"; }

_self_test() {
  require_tool python3 -c 'print(1)'
  local fail=0 n

  _case() { # <기대: 0|1> <이름> <소스>
    local want="$1" name="$2" src="$3" got
    got="$(printf '%s' "$src" | _static_check --stdin)"
    [ "$got" -gt 0 ] && got=1 || got=0
    if [ "$got" != "$want" ]; then
      echo "  ✗ 자기 시험 실패: $name (기대 위반=$want, 실제=$got)"
      fail=1
    fi
  }

  # 이 가드가 막으려는 바로 그 모양 — 샘플 뒤의 이른 return.
  _case 1 "이른 return + 끝 return" 'uniform sampler2D t;
void main() {
  if (a) { c = texture(t, uv); return; }
  c = texture(t, uv2);
}'
  _case 1 "return 둘" 'uniform sampler2D t;
void main() {
  if (a) return;
  if (b) return;
  c = texture(t, uv);
  return;
}'
  _case 0 "끝의 return 하나" 'uniform sampler2D t;
void main() {
  c = texture(t, uv);
  return;
}'
  _case 0 "return 없음" 'uniform sampler2D t;
void main() {
  c = texture(t, uv);
}'
  _case 0 "보조 함수의 return 은 세지 않는다" 'uniform sampler2D t;
float f(float x) { if (x < 0.0) return 0.0; return x; }
void main() {
  c = vec4(f(1.0)) * texture(t, uv);
}'
  _case 0 "주석 속 return" 'uniform sampler2D t;
void main() {
  // if (a) return;
  /* return; return; */
  c = texture(t, uv);
}'
  _case 0 "샘플러가 없으면 보지 않는다" 'void main() {
  if (a) return;
  c = vec4(1.0);
}'

  if [ "$fail" = 1 ]; then
    echo "check_shader_single_exit: 자기 시험 실패 — 검출기가 죽었다"
    return 1
  fi
  n=7
  echo "check_shader_single_exit: 자기 시험 통과 ($n 케이스)"
}

# impellerc 의 위치. PATH 에 있거나, `flutter` 가 가리키는 SDK 의 엔진 산출물에
# 있다(FVM 같은 심볼릭 링크는 따라간다).
_find_impellerc() {
  if command -v impellerc >/dev/null 2>&1; then
    command -v impellerc
    return 0
  fi
  local flutter_bin root cand
  flutter_bin="$(command -v flutter 2>/dev/null)" || return 1
  root="$(python3 -I -c 'import os,sys; print(os.path.dirname(os.path.dirname(os.path.realpath(sys.argv[1]))))' "$flutter_bin")"
  for cand in "$root"/bin/cache/artifacts/engine/*/impellerc "$root"/bin/cache/artifacts/engine/*/impellerc.exe; do
    if [ -f "$cand" ] && [ -x "$cand" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  return 1
}

_compile_check() { # <require: 0|1> <shader...>
  local require="$1"
  shift
  local impellerc out dir lib err rc i bad=0 result=0
  # `flutter_tools` 의 `_shaderTargetsFromTargetPlatform` 과 같은 묶음 — 플랫폼마다
  # 컴파일러가 가는 길이 달라 경고도 다른 길에서 나온다.
  local -a names=("android/linux/windows" "ios" "macos" "tester" "web")
  local -a flags=(
    "--sksl --runtime-stage-gles --runtime-stage-gles3 --runtime-stage-vulkan"
    "--runtime-stage-metal"
    "--sksl --runtime-stage-metal"
    "--sksl --runtime-stage-vulkan"
    "--sksl --json"
  )

  if ! impellerc="$(_find_impellerc)"; then
    if [ "$require" = 1 ]; then
      _require_tool_say error "impellerc 를 찾지 못했다 — Flutter SDK 가 PATH 에 있어야 한다 (--require-compiler)"
      return "$REQUIRE_TOOL_UNAVAILABLE"
    fi
    echo "  · 컴파일 단계 건너뜀: impellerc 없음 (Flutter SDK 가 있는 잡에서는 --require-compiler 로 부른다)"
    return 0
  fi

  out="$(mktemp -d)"
  dir="$(dirname "$impellerc")"
  lib="$dir/shader_lib"

  local shader
  for shader in "$@"; do
    for i in "${!names[@]}"; do
      rc=0
      # shellcheck disable=SC2086
      err="$("$impellerc" ${flags[$i]} --iplr --sl="$out/o" --spirv="$out/o.spirv" \
        --input="$REPO_ROOT/$shader" --input-type=frag \
        --include="$(dirname "$REPO_ROOT/$shader")" --include="$lib" 2>&1 >/dev/null)" || rc=$?
      if [ "$rc" != 0 ] || grep -q '\[WARNING\]' <<<"$err"; then
        bad=1
        echo "  ✗ $shader [${names[$i]}] rc=$rc"
        sed 's/^/      /' <<<"$err" | head -6
      fi
    done
  done

  rm -rf "$out"
  if [ "$bad" = 1 ]; then
    result=1
  else
    echo "  · impellerc $(basename "$dir")/$(basename "$impellerc"): $# 셰이더 × ${#names[@]} 대상, 경고 0"
  fi
  return "$result"
}

main() {
  local require=0
  case "${1:-}" in
    --self-test)
      _self_test
      return $?
      ;;
    --require-compiler) require=1 ;;
    "") ;;
    *)
      echo "사용: $0 [--require-compiler | --self-test]" >&2
      return 2
      ;;
  esac

  require_tool python3 -c 'print(1)'

  cd "$REPO_ROOT"
  # 추적되는 `.frag` 전부 — 선언 여부와 무관하게 소스 모양을 본다.
  local -a shaders=()
  local f
  while IFS= read -r f; do
    [ -n "$f" ] && shaders+=("$f")
  done < <(git ls-files '*.frag')

  if [ "${#shaders[@]}" = 0 ]; then
    echo "check_shader_single_exit: 추적되는 .frag 가 없다 — 가드가 아무것도 세지 않는다"
    return 1
  fi

  local fail=0
  if ! _static_check "${shaders[@]}"; then
    fail=1
    echo "    텍스처를 샘플링하는 셰이더는 main() 에서 return 을 맨 끝 하나만 쓴다."
    echo "    이른 return 은 분기 결과를 변수에 담아 끝에서 한 번 쓰는 모양으로 바꾼다."
  fi

  local rc=0
  _compile_check "$require" "${shaders[@]}" || rc=$?
  if [ "$rc" = "$REQUIRE_TOOL_UNAVAILABLE" ]; then
    return "$rc"
  fi
  [ "$rc" = 0 ] || fail=1

  if [ "$fail" = 1 ]; then
    return 1
  fi
  echo "check_shader_single_exit: 셰이더 ${#shaders[@]}개, main() 출구 하나"
}

main "$@"
