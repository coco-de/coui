#!/bin/bash

# 위젯북 린트 이슈 일괄 수정 스크립트

echo "🔧 Widgetbook 린트 이슈 일괄 수정 시작..."

WIDGETBOOK_DIR="/Users/dongwoo/Development/cocode/uiux/coui/app/coui_widgetbook/lib/component"

# 1. 빈 onPressed 블록을 로그로 대체
echo "📝 Step 1: 빈 onPressed 블록 수정..."

find "$WIDGETBOOK_DIR" -name "*.dart" -type f -exec sed -i '' \
  's/onPressed: () {},/onPressed: () {\
      \/\/ ignore: avoid_print\
      print('\''Button pressed'\'');\
    },/g' {} \;

# 2. 사용하지 않는 context 파라미터를 _ 로 변경
echo "📝 Step 2: 사용하지 않는 context 파라미터 수정..."

# 이건 수동으로 확인이 필요하므로 스킵

# 3. 포맷팅 적용
echo "📝 Step 3: 포맷팅 적용..."
cd /Users/dongwoo/Development/cocode/uiux/coui/app/coui_widgetbook
dart format lib/

echo "✅ 수정 완료!"
echo ""
echo "📊 다시 린트 분석 실행 중..."
dcm analyze lib --reporter=console
