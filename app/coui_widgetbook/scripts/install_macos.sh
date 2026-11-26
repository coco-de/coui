#!/usr/bin/env bash
#
# 팀 내부용 CoUI Widgetbook macOS 앱을 설치한다.
#
# 기본은 main 의 최신 성공 빌드(.github/workflows/deploy-desktop.yaml)를 gh 로
# 받아 /Applications 에 설치한다. gh 로 받은 파일에는 quarantine 속성이 붙지
# 않아서 ad-hoc 서명(공증 없음)인 이 앱도 Gatekeeper 에 막히지 않는다.
#
# 한 줄 설치 (gh 로그인이 필요하다. 이 저장소를 clone 하지 않아도 된다):
#   gh api repos/coco-de/coui/contents/app/coui_widgetbook/scripts/install_macos.sh \
#     -H 'Accept: application/vnd.github.raw' | bash
# 옵션을 넘기려면 `| bash -s -- --run 123456` 처럼 쓴다.
#
# macOS 기본 bash(3.2)에서도 돌아야 하므로 bash 4 이상의 기능을 쓰지 않는다.

set -euo pipefail

readonly REPO="coco-de/coui"
readonly WORKFLOW="deploy-desktop.yaml"
# 아래 두 이름은 deploy-desktop.yaml 의 아티팩트 이름, build_macos.sh 의 산출물
# 이름과 같아야 한다.
readonly ARTIFACT="coui-widgetbook-macos"
readonly ZIP_NAME="CoUI-Widgetbook-macos.zip"

die() {
  echo "❌ $*" >&2
  exit 1
}

# `curl | bash` 로 실행되면 $0 이 스크립트 파일이 아니므로 사용법은 본문에 둔다.
usage() {
  cat <<'EOF'
사용법: install_macos.sh [옵션]

  --run <id>       그 런의 빌드를 설치한다 (기본: --branch 의 최신 성공 런)
  --branch <이름>  그 브랜치의 최신 성공 런을 설치한다 (기본: main)
  --zip <경로>     이미 받은 zip 을 설치한다 (gh 불필요. 옆에 .sha256 이 있으면 검증)
  --dest <폴더>    설치 폴더 (기본: /Applications, 쓸 수 없으면 ~/Applications)
  --no-open        설치한 뒤 앱을 실행하지 않는다
  -h, --help       이 도움말

설치할 때 quarantine 속성을 제거한다. 팀 내부 빌드(ad-hoc 서명, 공증 없음)를
의도적으로 설치하는 경로라서 하는 일이고, 출처를 모르는 zip 에 쓰면 안 된다.
EOF
}

run_id=""
branch="main"
zip_path=""
dest=""
open_app=1

while [ $# -gt 0 ]; do
  case "$1" in
    --run)
      run_id="${2:?--run 에는 런 ID 가 필요하다}"
      shift 2
      ;;
    --branch)
      branch="${2:?--branch 에는 브랜치 이름이 필요하다}"
      shift 2
      ;;
    --zip)
      zip_path="${2:?--zip 에는 경로가 필요하다}"
      shift 2
      ;;
    --dest)
      dest="${2:?--dest 에는 폴더가 필요하다}"
      shift 2
      ;;
    --no-open)
      open_app=0
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "알 수 없는 옵션: $1"
      ;;
  esac
done

[ "$(uname -s)" = "Darwin" ] || die "macOS 전용이다 (uname=$(uname -s))"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ -z "$zip_path" ]; then
  command -v gh >/dev/null || die "gh 가 필요하다: brew install gh && gh auth login"
  gh auth status >/dev/null 2>&1 || die "gh 로그인이 필요하다: gh auth login"

  if [ -z "$run_id" ]; then
    # 워크플로가 기본 브랜치에 아직 없으면 gh 가 404 로 실패한다. 그 오류는 그대로
    # 보여 주고, 아래 안내(먼저 빌드한다)까지 이어지도록 여기서 멈추지 않는다.
    run_id="$(gh run list -R "$REPO" -w "$WORKFLOW" -b "$branch" -s success -L 1 \
      --json databaseId -q '.[0].databaseId // empty' || true)"
    [ -n "$run_id" ] ||
      die "$branch 에 성공한 $WORKFLOW 런이 없다. 먼저 빌드한다: gh workflow run $WORKFLOW -R $REPO --ref $branch"
  fi

  echo "▶ 런 $run_id 의 빌드를 받는다"
  gh run download "$run_id" -R "$REPO" -n "$ARTIFACT" -D "$tmp/download" ||
    die "아티팩트를 받지 못했다. 보관 기간(30일)이 지났다면 다시 빌드한다: gh workflow run $WORKFLOW -R $REPO --ref $branch"
  zip_path="$tmp/download/$ZIP_NAME"
fi

[ -f "$zip_path" ] || die "zip 이 없다: $zip_path"
zip_dir="$(cd "$(dirname "$zip_path")" && pwd)"
zip_file="$(basename "$zip_path")"

if [ -f "$zip_dir/$zip_file.sha256" ]; then
  (cd "$zip_dir" && shasum -a 256 -c "$zip_file.sha256" >/dev/null) ||
    die "체크섬이 맞지 않는다: $zip_dir/$zip_file"
  echo "  ✓ sha256"
else
  echo "  ⚠ $zip_file.sha256 이 없어 체크섬 검증을 건너뛴다"
fi

ditto -x -k "$zip_dir/$zip_file" "$tmp/extracted"
app_path="$(find "$tmp/extracted" -maxdepth 1 -name '*.app' -type d)"
[ -n "$app_path" ] && [ "$(printf '%s\n' "$app_path" | wc -l | tr -d ' ')" = "1" ] ||
  die "zip 안에 .app 이 정확히 하나여야 한다"
app_name="$(basename "$app_path")"

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$app_path/Contents/Info.plist"
}
version="$(plist_value CFBundleShortVersionString)+$(plist_value CFBundleVersion)"

if [ -z "$dest" ]; then
  if [ -w /Applications ]; then
    dest="/Applications"
  else
    dest="$HOME/Applications"
  fi
fi
mkdir -p "$dest"
[ -w "$dest" ] || die "$dest 에 쓸 수 없다. --dest 로 다른 폴더를 지정한다"
target="$dest/$app_name"

# 실행 중인 앱을 덮어쓰면 떠 있는 바이너리가 바뀐다. 먼저 종료한다. osascript 의
# quit 은 처음 쓰는 Mac 에서 Automation 권한 팝업을 띄우므로 SIGTERM 을 쓴다 —
# 저장할 상태가 없는 카탈로그 뷰어라 이것으로 충분하다.
running_pids() {
  pgrep -f -- "$target/Contents/MacOS/" || true
}
pids="$(running_pids)"
if [ -n "$pids" ]; then
  echo "▶ 실행 중인 앱을 종료한다"
  for pid in $pids; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -z "$(running_pids)" ] && break
    sleep 1
  done
  [ -z "$(running_pids)" ] || die "앱이 종료되지 않았다. 직접 종료한 뒤 다시 실행한다"
fi

# 복사가 끝난 뒤에 바꿔치기한다. 복사가 중간에 실패해도 기존 설치본이 남는다.
staging="$dest/.$app_name.installing"
previous="$dest/.$app_name.previous"
rm -rf "$staging" "$previous"
ditto "$app_path" "$staging"
xattr -dr com.apple.quarantine "$staging" 2>/dev/null || true
if [ -e "$target" ]; then
  mv "$target" "$previous"
fi
mv "$staging" "$target"
rm -rf "$previous"

codesign --verify --deep --strict "$target" || die "설치본의 서명 검증에 실패했다: $target"

echo "✅ 설치했다: $target ($version)"
if [ -f "$zip_dir/${zip_file%.zip}.info" ]; then
  grep -E '^(git_sha|git_ref|built_at)=' "$zip_dir/${zip_file%.zip}.info" | sed 's/^/   /'
fi

if [ "$open_app" = "1" ]; then
  open "$target"
fi
