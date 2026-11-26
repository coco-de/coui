#!/bin/bash
# 파일명: fix_slang_gpt.sh
# GPT 번역 후 생성된 _default_ 접두사 파일들을 정리하는 스크립트

set -e  # 에러 발생 시 중단

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 GPT 번역 파일 정리 시작...${NC}"
echo ""

# i18n 디렉토리로 이동
cd "$(dirname "$0")/lib/src/json"

# _default_ 접두사가 붙은 파일 확인
if ! ls _default_*.i18n.json 1> /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  _default_ 파일을 찾을 수 없습니다.${NC}"
    echo "GPT 번역이 이미 실행되었거나 파일이 정리된 상태입니다."
    exit 0
fi

echo -e "${GREEN}발견된 _default_ 파일들:${NC}"
ls -1 _default_*.i18n.json
echo ""

# _default_ 접두사가 붙은 파일을 원래 파일로 이동
count=0
for file in _default_*.i18n.json; do
  if [ -f "$file" ]; then
    # _default_ 제거하여 목적 파일명 생성
    dest_file="${file/_default_/}"
    echo -e "${BLUE}→${NC} $file ${BLUE}→${NC} $dest_file"
    
    # 백업 없이 바로 이동 (덮어쓰기)
    mv -f "$file" "$dest_file"
    ((count++))
  fi
done

echo ""
echo -e "${GREEN}✓ $count 개 파일 처리 완료${NC}"

# GPT 로그 파일 삭제
if ls _gpt_*.txt 1> /dev/null 2>&1; then
    log_count=$(ls -1 _gpt_*.txt | wc -l)
    rm -f _gpt_*.txt
    echo -e "${GREEN}✓ $log_count 개 GPT 로그 파일 삭제${NC}"
fi

echo ""
echo -e "${GREEN}✅ 번역 파일 정리 완료!${NC}"
echo ""
echo -e "${BLUE}정리된 파일 목록:${NC}"
ls -1 *.i18n.json | grep -v "^_" || true