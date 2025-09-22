#!/bin/bash

# 통합 린트 검사 스크립트
# dart analyze와 dcm analyze를 한번에 실행

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Starting comprehensive lint analysis..."

# 패키지 목록
PACKAGES=("packages/coui_web" "packages/coui_flutter")

for package in "${PACKAGES[@]}"; do
  if [ -d "$package" ]; then
    echo ""
    echo "📦 Analyzing package: $package"
    echo "=================================="
    
    # Dart Analyze
    echo ""
    echo -e "${YELLOW}🔧 Running dart analyze...${NC}"
    echo "----------------------------"
    
    cd "$package"
    
    # Count dart analyze issues
    dart_issues_output=$(dart analyze --fatal-infos . 2>&1 || true)
    dart_issues=$(echo "$dart_issues_output" | grep -c "error\\|warning\\|info" || echo "0")
    # Sanitize potential multi-line output from the command substitution
    dart_issues=$(echo "$dart_issues" | head -n 1)

    if [ "$dart_issues" -eq 0 ]; then
      echo -e "${GREEN}✅ No dart analyze issues found${NC}"
    else
      echo -e "${RED}❌ Found $dart_issues dart analyze issues${NC}"
      echo ""
      echo "First 10 issues:"
      echo "$dart_issues_output" | head -10
    fi
    
    cd - > /dev/null
    
    # DCM Analyze
    echo ""
    echo -e "${YELLOW}🎯 Running dcm analyze...${NC}"
    echo "----------------------------"
    
    dcm_full_output=$(dcm analyze "$package" --reporter=console 2>/dev/null || true)
    echo "$dcm_full_output" | tail -n 4 # Show last 4 lines for summary
    
    # Extract DCM issue counts
    warning_count=$(echo "$dcm_full_output" | grep "warning issues" | sed 's/.*warning issues: \([0-9]*\).*/\1/' | head -n 1)
    style_count=$(echo "$dcm_full_output" | grep "style issues" | sed 's/.*style issues: \([0-9]*\).*/\1/' | head -n 1)
    
    # Default to 0 if empty
    warning_count=${warning_count:-0}
    style_count=${style_count:-0}
    
    echo ""
    echo "📊 Summary for $package:"
    echo "  • Dart analyze issues: $dart_issues"
    echo "  • DCM warning issues: $warning_count"
    echo "  • DCM style issues: $style_count"
    
    # Ensure all counts are integers before summing
    dart_issues=${dart_issues:-0}
    warning_count=${warning_count:-0}
    style_count=${style_count:-0}
    
    total_issues=$((dart_issues + warning_count + style_count))
    echo "  • Total issues: $total_issues"
    
  else
    echo "❌ Package directory not found: $package"
  fi
done

echo ""
echo "🏁 Analysis complete!"