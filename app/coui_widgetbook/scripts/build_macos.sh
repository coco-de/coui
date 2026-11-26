#!/usr/bin/env bash
#
# Widgetbook 을 macOS 데스크톱 앱으로 빌드하고 팀 내부 배포용 zip 으로 묶는다.
#
# 산출물 (app/coui_widgetbook/build/desktop/):
#   CoUI-Widgetbook-macos.zip         ditto 로 묶은 .app (권한·서명 보존)
#   CoUI-Widgetbook-macos.zip.sha256  shasum -a 256 -c 로 검증하는 체크섬
#   CoUI-Widgetbook-macos.info        출처(커밋·런·버전·아키텍처) key=value
#
# 서명은 ad-hoc 이다. Developer ID 서명도 공증도 하지 않는다. 그래서 브라우저로
# 받은 zip 은 Gatekeeper 가 막고, gh 로 받은 것은 quarantine 속성이 없어 바로
# 실행된다. 설치는 scripts/install_macos.sh 가 맡는다.
#
# 사용법 (의존성 해석(melos bootstrap)이 끝난 뒤, 어느 디렉터리에서든):
#   app/coui_widgetbook/scripts/build_macos.sh
#
# 환경 변수:
#   BUILD_NAME    기본값은 pubspec.yaml 의 version
#   BUILD_NUMBER  기본값은 0 (로컬 빌드). CI 는 run_number 를 넘겨 단조 증가시킨다.
#
# CI 에서는 .github/workflows/deploy-desktop.yaml 이 이 스크립트를 부른다.
# 아티팩트 이름은 그 워크플로·install_macos.sh 와 같아야 한다.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

readonly ARTIFACT_BASENAME="CoUI-Widgetbook-macos"
readonly OUT_DIR="build/desktop"
readonly RELEASE_DIR="build/macos/Build/Products/Release"
readonly XCCONFIG="macos/Runner/Configs/AppInfo.xcconfig"

die() {
  echo "❌ $*" >&2
  exit 1
}

# AppInfo.xcconfig 의 `KEY = value` 에서 value 를 읽는다.
xcconfig_value() {
  awk -F' *= *' -v key="$1" '$1 == key { print $2; exit }' "$XCCONFIG"
}

[ "$(uname -s)" = "Darwin" ] || die "macOS 에서만 빌드할 수 있다 (uname=$(uname -s))"
command -v flutter >/dev/null || die "flutter 가 PATH 에 없다"

PRODUCT_NAME="$(xcconfig_value PRODUCT_NAME)"
BUNDLE_ID="$(xcconfig_value PRODUCT_BUNDLE_IDENTIFIER)"
[ -n "$PRODUCT_NAME" ] && [ -n "$BUNDLE_ID" ] ||
  die "$XCCONFIG 에서 PRODUCT_NAME / PRODUCT_BUNDLE_IDENTIFIER 를 읽지 못했다"

# `version: 0.1.0+5` 에서 `+` 앞만 빌드 이름이다. 빌드 번호는 따로 받는다.
BUILD_NAME="${BUILD_NAME:-$(awk '/^version:/ { sub(/\+.*/, "", $2); print $2; exit }' pubspec.yaml)}"
BUILD_NUMBER="${BUILD_NUMBER:-0}"
[ -n "$BUILD_NAME" ] || die "pubspec.yaml 의 version 을 읽지 못했다"
case "$BUILD_NUMBER" in
  '' | *[!0-9]*) die "BUILD_NUMBER 는 정수여야 한다: '$BUILD_NUMBER'" ;;
esac

echo "▶ $PRODUCT_NAME $BUILD_NAME+$BUILD_NUMBER ($BUNDLE_ID)"
echo "  flutter : $(flutter --version | awk 'NR == 1 { print $2 }')"
echo "  xcode   : $(xcodebuild -version | awk 'NR == 1 { print $2 }')"
echo "  pod     : $(pod --version 2>/dev/null || echo '없음')"

echo "▶ flutter build macos --release"
flutter build macos --release --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"

APP="$RELEASE_DIR/$PRODUCT_NAME.app"
[ -d "$APP" ] ||
  die "빌드 산출물이 없다: $APP (Release 디렉터리의 .app: $(find "$RELEASE_DIR" -maxdepth 1 -name '*.app' 2>/dev/null | tr '\n' ' '))"
readonly PLIST="$APP/Contents/Info.plist"

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST"
}

check_eq() {
  [ "$2" = "$3" ] || die "$1 불일치: 실제 '$2' ≠ 기대 '$3'"
  echo "  ✓ $1 = $2"
}

# CI 의 초록을 믿으려면 산출물을 직접 확인해야 한다 — 신원이 바뀌었거나 한쪽
# 아키텍처가 빠졌거나 서명이 깨진 앱도 빌드 자체는 성공한다.
echo "▶ 산출물 검증"
check_eq "CFBundleIdentifier" "$(plist_value CFBundleIdentifier)" "$BUNDLE_ID"
check_eq "CFBundleShortVersionString" "$(plist_value CFBundleShortVersionString)" "$BUILD_NAME"
check_eq "CFBundleVersion" "$(plist_value CFBundleVersion)" "$BUILD_NUMBER"

ARCHS="$(lipo -archs "$APP/Contents/MacOS/$(plist_value CFBundleExecutable)")"
for arch in arm64 x86_64; do
  case " $ARCHS " in
    *" $arch "*) ;;
    *) die "아키텍처 $arch 가 없다 (lipo: $ARCHS)" ;;
  esac
done
echo "  ✓ 아키텍처 = $ARCHS"

for framework in App.framework FlutterMacOS.framework; do
  [ -d "$APP/Contents/Frameworks/$framework" ] || die "프레임워크가 없다: $framework"
done
echo "  ✓ App.framework · FlutterMacOS.framework"

codesign --verify --deep --strict "$APP" || die "codesign 검증 실패"
echo "  ✓ codesign --verify --deep --strict"

# 샌드박스 앱이 사용자가 고른 파일을 읽으려면 이 권한이 서명에 실려야 한다.
ENTITLEMENTS="$(codesign -d --entitlements :- "$APP" 2>/dev/null)"
for entitlement in com.apple.security.app-sandbox com.apple.security.files.user-selected.read-write; do
  case "$ENTITLEMENTS" in
    *"$entitlement"*) ;;
    *) die "entitlement 가 서명에 없다: $entitlement" ;;
  esac
done
echo "  ✓ entitlements (app-sandbox · files.user-selected.read-write)"

echo "▶ 패키징 → $OUT_DIR/"
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR/$ARTIFACT_BASENAME.zip" \
  "$OUT_DIR/$ARTIFACT_BASENAME.zip.sha256" \
  "$OUT_DIR/$ARTIFACT_BASENAME.info"
ditto -c -k --norsrc --keepParent "$APP" "$OUT_DIR/$ARTIFACT_BASENAME.zip"

# zip 을 한 번 풀어 서명이 살아 있는지 본다. 풀 때 권한이나 심볼릭 링크가
# 깨지는 압축 방식은 서명을 조용히 무효로 만든다.
VERIFY_DIR="$(mktemp -d)"
trap 'rm -rf "$VERIFY_DIR"' EXIT
ditto -x -k "$OUT_DIR/$ARTIFACT_BASENAME.zip" "$VERIFY_DIR"
codesign --verify --deep --strict "$VERIFY_DIR/$PRODUCT_NAME.app" ||
  die "zip 을 푼 뒤 서명 검증 실패"
echo "  ✓ zip 왕복 뒤 서명 유지"

(cd "$OUT_DIR" && shasum -a 256 "$ARTIFACT_BASENAME.zip" >"$ARTIFACT_BASENAME.zip.sha256")

{
  echo "app=$PRODUCT_NAME.app"
  echo "bundle_id=$BUNDLE_ID"
  echo "version=$BUILD_NAME"
  echo "build=$BUILD_NUMBER"
  echo "git_sha=${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}"
  echo "git_ref=${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)}"
  echo "run_id=${GITHUB_RUN_ID:-local}"
  echo "archs=$ARCHS"
  echo "min_macos=$(plist_value LSMinimumSystemVersion)"
  echo "flutter=$(flutter --version | awk 'NR == 1 { print $2 }')"
  echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >"$OUT_DIR/$ARTIFACT_BASENAME.info"

echo "✅ 완료"
for artifact in "$OUT_DIR/$ARTIFACT_BASENAME".*; do
  printf '  %s  %s\n' "$(du -h "$artifact" | cut -f1)" "$artifact"
done
