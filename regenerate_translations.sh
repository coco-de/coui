#!/bin/bash
set -e

echo "🔄 번역 파일 재생성 중..."
cd "$(dirname "$0")/packages/coui_i10n"

echo "📝 slang 실행..."
dart run slang

echo ""
echo "✅ 완료!"
echo ""
echo "생성된 파일 확인:"
ls -lh lib/src/translations/translations*.g.dart | head -5
echo ""
echo "번역 키 개수:"
grep -c "String get" lib/src/translations/translations_ko.g.dart || true

